local DFGraphics = require('DFCommon.Graphics')
local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')
local DFMath = require('DFCommon.Math')
local DFMoaiDebugger = require("DFMoai.Debugger")
local Renderer = require('Renderer')
local Character = require('CharacterConstants')
local SeqCommand = require('SeqCommand')
local DataCache = require('DFCommon.DataCache')
local AssetSet = require('DFCommon.AssetSet')
local Profile = require('Profile')

local Rig = {}

Rig.bDBGExtendedProfiler = false

local gAllRigs = {}
setmetatable(gAllRigs, {__mode = 'k'})

-- CONSTRUCTOR --
function Rig.new( rEntity, tRigArgs, rAssetSet )
	
	-- PRE-CONSTRUCTOR --
    local self = DFUtil.deepCopy( Rig )	
    self.NO_DEEP_COPY = true
    
	self.rEntity = rEntity
	self.sResource = tRigArgs.sResource

	if not self.sResource then
		Trace(TT_Warning, "RIG.LUA: No rig file specified!" )
	else 
		self:_init(rAssetSet, tRigArgs)
	end
    
    return self
end

function Rig:_init(rAssetSet, tRigArgs)

    assert(gAllRigs[self] == nil)
    gAllRigs[self] = 1

	-- Load the definition of the rig
    local filePath = DFFile.getAssetPath( self.sResource )
	local tData = DataCache.getData("rig", filePath)
	if tData == nil then
        Trace(TT_Error, "RIG.LUA: Trying to load invalid rig: " .. self.sResource)
		return
	end
    
    if tData.rRigData == nil then
    
        local binaryRigFilename = DFFile.stripSuffix(filePath)
        binaryRigFilename = binaryRigFilename .. ".brig"
    
        tData.rRigData = DFRigData.new()
        tData.rRigData:loadAsync(binaryRigFilename)
    end
	
	self._bIsActive = false
	
	self.tJointMap = {}
	self.tMeshMap = {}
	self.tTextures = {}
    self.tMaterials = {}
	
	self.rMainMesh = nil
	
    self.tMeshVisibilityOverrides = {}
    self.numMeshVisibilityOverrides = 0
    
	self.tAnimationAttachments = {}
    self.tAnimationEvents = {}
    self.nextAnimEventIdx = 0
    
    self.tActiveAnims = {}
	
	-- Setup the scale
	if not tData.tScale then
		if tData.scale then
			self.tScale = { tData.scale, tData.scale, tData.scale }
		else
			self.tScale = { 1, 1, 1 }
		end
	end
	self.scaleX = 1
	
	-- Create the root joints, which apply the various base transformations to the rig
	self.rUnscaledRootJointProp = MOAITransform.new()
    self.rUnscaledRootJointProp:setAttrLink(MOAIProp.INHERIT_LOCROT, self.rEntity.rProp, MOAIProp.TRANSFORM_TRAIT)
    
	self.rScaleJointProp = MOAITransform.new()
    self.rScaleJointProp:setScl(self.tScale[1], self.tScale[2], self.tScale[3])
    self.rScaleJointProp:setAttrLink(MOAIProp.INHERIT_LOCROT, self.rUnscaledRootJointProp, MOAIProp.TRANSFORM_TRAIT)
    self.rScaleJointProp:setAttrLink(MOAIProp.OFFSET_SCL, self.rEntity.rProp, MOAIProp.OFFSET_TRANSFORM_TRAIT)
    
    self.bUseEntityOffsetScale = true
    self.bAllowEntityNavigation = true
    
    self.rRootJoint = {}
	self.rRootJoint.rProp = MOAITransform.new()
    self.rRootJoint.rProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rScaleJointProp, MOAIProp.TRANSFORM_TRAIT)
    
    -- Setup the tracker joints that are responsible for moving the entity (instead of the delta-trans)
	self.rTrackerOriginTrans = MOAITransform.new()
    self.rTrackerOriginTrans:setScl(self.tScale[1], -self.tScale[2], self.tScale[3])
    
	self.rTrackerTrans = MOAITransform.new()
    self.rTrackerTrans:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rTrackerOriginTrans, MOAIProp.TRANSFORM_TRAIT)
    
    self.bHasRootMotion = false
    
    self.numJoints = 0
    self.numMeshes = 0
    self.numSubsets = 0
    
    -- Wait for the rig data to be available
    tData.rRigData:sync()
    
    -- Create the anim controller and setup the joint hierarchy
    self:_initializeJointHierarchy(tData)
    
	-- Create the meshes
	self:_createMeshes(tData, tRigArgs, rAssetSet)
	
    -- Setup the animation controller
    self:_initializeAnimController(tData, tRigArgs)
    
    self:_setTextureReplacements(tRigArgs)
end

-- PUBLIC FUNCTIONS --
function Rig:onAnalyzeAssets(rClump, sID)

    -- Add textures
	local numTextures = #self.tTextures
	for i=1,numTextures do
        local rTexture = self.tTextures[i]
        rClump:addTexture(rTexture.path, sID)
	end
    
    -- Add materials
	local numMaterials = #self.tMaterials
    for i=1,numMaterials do
        local rMaterial = self.tMaterials[i]
        rClump:addMaterial(rMaterial.path, sID)
    end
    
    -- Add subset textures / materials
    local sFilename = DFFile.getAssetPath(self.sResource)
    if MOAIFileSystem.checkFileExists(sFilename) then
    
        local tData = dofile(sFilename)
        if tData then
        
            local tMeshDescs = tData.tMeshes	
            local numMeshes = #tMeshDescs
            for i=1,self.numMeshes do
            
                local tMesh = tMeshDescs[i]
                if tMesh.tTriMesh then
                
                    local tSubsets = tMesh.tTriMesh.tSubsets
                    local numSubsets = #tSubsets
                    for j=1,numSubsets do
                    
                        local tSubset = tSubsets[j]
                        rClump:addTexture(tSubset.sTexture, sID)
                        
                        if tSubset.materialIdx then
                        
                            local sMaterial = tMesh.tTriMesh.tMaterials[tSubset.materialIdx]
                            rClump:addMaterial(sMaterial, sID)
                        end
                    end
                end
            end
        end
    end
end

function Rig:unload()

    assert(gAllRigs[self])
    gAllRigs[self] = nil

	-- Remove all joint and mesh props
	self:deactivate()

	self.tJointMap = {}
	self.tMeshMap = {}

	-- Dereference textures
	local numTextures = #self.tTextures
	for i=1,numTextures do
        -- We don't actually load the textures, we only preload them so the AssetSet will release the texture
		--DFGraphics.unloadTexture(self.tTextures[i])
	end
	self.tTextures = {}
    
    -- Dereference materials
	local numMaterials = #self.tMaterials
    for i=1,numMaterials do
        local rMaterial = self.tMaterials[i]
        DFGraphics.unloadMaterial(rMaterial)
    end
    self.tMaterials = {}
	
    self.rMainMesh:setAnimController(nil)
	self.rMainMesh = nil
	
	self.tAnimationAttachments = {}
    
    self.tActiveAnims = {}

    -- Clear all animation layers
    self.rAnimController:stop()
    self.rAnimController:clearLayers(DFAnimController.PRIORITY_MIN)
    self.rAnimController:setTrackerTransform(nil)
    self.rAnimController = nil
end

function Rig:activate( )

	-- Already active?
	if self._bIsActive then
		return
	end
	
	-- Add mesh props
    if self.tMeshMap ~= nil then
        for sMeshName, tMeshData in pairs(self.tMeshMap) do
            tMeshData.rMesh:setCullMode(MOAIProp.CULL_BACK)
            self.rEntity:addProp(tMeshData.rMesh)
            tMeshData.rMesh:start()
            tMeshData.rMesh:setVisible(true)
        end
    end

    self:resumeAnimations()
	
	-- Make sure the props are in place
	self:update(0)
	
	self._bIsActive = true
end

function Rig:deactivate( )

	-- Already deactivated?
	if not self._bIsActive then
		return
	end

	-- Make sure we aren't wasting CPU cycles on curve updates
    local tAnimNames = {}
    if self.tActiveAnims then --accessory rigs don't necessarily have active anims
        for sAnimName,rAnim in pairs(self.tActiveAnims) do
            table.insert(tAnimNames, sAnimName)
        end
    end
    local numAnims = #tAnimNames
    for i=1,numAnims do
        self:stopAnimation(tAnimNames[i])
    end
	
	-- Remove mesh props
    if self.tMeshMap then
        for sMeshName, tMeshData in pairs(self.tMeshMap) do
            tMeshData.rMesh:stop()
            tMeshData.rMesh:setVisible(false)
            self.rEntity:removeProp(tMeshData.rMesh)
        end
    end

    self:pauseAnimations()
	
	self._bIsActive = false
end

function Rig:isActive()

	return self._bIsActive
end

-- PUBLIC FUNCTIONS - JOINT --
function Rig:getJointProp( sName )

    local tJointData = self.tJointMap[sName]
    if tJointData ~= nil then
    
        if tJointData.rTransform == nil then
            tJointData.rTransform = self.rAnimController:getLinkedJointTransform(tJointData.idx)
            if tJointData.rTransform == nil then
                tJointData.rTransform = MOAITransform.new()
                self.rAnimController:setLinkedJointTransform(tJointData.idx, tJointData.rTransform)
            end
        end
    
        return tJointData.rTransform
    end
    
    return nil
end

function Rig:getJointIndex( sName )

    local tJointData = self.tJointMap[sName]
    if tJointData ~= nil then
        return tJointData.idx
    end
    
    return nil
end

function Rig:setJointLoc( sName, tLoc, sLayerName )

    local tJointData = self.tJointMap[sName]
    if tJointData ~= nil then
        local x, y, z
        if type(tLoc) == 'table' then
            x, y, z = unpack(tLoc)
        else
            x = tLoc
        end
        self.rAnimController:setJointLoc(sLayerName, tJointData.idx, x, y, z)
    end
end

function Rig:setJointRot( sName, tRot, sLayerName )

    local tJointData = self.tJointMap[sName]
    if tJointData ~= nil then
        local x, y, z
        if type(tRot) == 'table' then
            x, y, z = unpack(tRot)
        else
            x = tRot
        end
        self.rAnimController:setJointRot(sLayerName, tJointData.idx, x, y, z)
    end
end

function Rig:setJointScl( sName, tScl, sLayerName )

    local tJointData = self.tJointMap[sName]
    if tJointData ~= nil then
        local x, y, z
        if type(tScl) == 'table' then
            x, y, z = unpack(tScl)
        else
            x = tScl
        end
        self.rAnimController:setJointScl(sLayerName, tJointData.idx, x, y, z)
    end
end

-- PUBLIC FUNCTIONS - ANIMATIONS --
function Rig:playAnimation(tAnimationData)

    if Rig.bDBGExtendedProfiler then
        Profile.enterScope( "Rig:playAnimation" )
    end

    -- Get the type of animation
    local animPriority = DFAnimController.PRIORITY_NORMAL
    if tAnimationData.animPriority ~= nil then
        animPriority = tAnimationData.animPriority
    end
    
	-- Should the animation be flipped?
    if animPriority == DFAnimController.PRIORITY_NORMAL then
        self.scaleX = 1
        if tAnimationData.bFlipX then
            self.scaleX = -1
        end
    end
    
    -- Should the animation play once?
    if tAnimationData.bPlayOnce then
        tAnimationData.playbackMode = MOAITimer.NORMAL
    else
        tAnimationData.playbackMode = MOAITimer.LOOP
    end
	
	-- Don't restart the animation
    local sAnimName = tAnimationData.sAnimPath
    if not tAnimationData.bPlayOnce and self.tActiveAnims[sAnimName] ~= nil then
        if Rig.bDBGExtendedProfiler then
            Profile.leaveScope( "Rig:playAnimation" )
        end
        return
    end
    
	-- Load the animation data
	local sAnimFile = DFFile.getAssetPath(tAnimationData.sAnimPath)	
	local tAnimData = DataCache.getData("anim", sAnimFile)
	if tAnimData == nil then
        if Rig.bDBGExtendedProfiler then
            Profile.leaveScope( "Rig:playAnimation" )
        end
		return
	end
    
    if not tAnimData.rAnimData then
    
        if tAnimData.sRig ~= self.sResource then
            Trace(TT_Error, string.format("RIG.LUA: Rig and animation don't match!\nRig : %s\nAnim: %s", tostring(self.sResource), tostring(tAnimData.sRig)))
            self.bDBG_NoAnim = true
        end
    
        local binaryAnimFilename = DFFile.stripSuffix(sAnimFile)
        binaryAnimFilename = binaryAnimFilename .. ".banim"
        
        tAnimData.rAnimData = DFAnimData.new()
        tAnimData.rAnimData:loadAsync(binaryAnimFilename)
    end
	
    -- Is this a base (or non-overlay) animation
    if animPriority == DFAnimController.PRIORITY_NORMAL then
    
        -- Reset the rig
        self:_resetToBindPosition()
        
        -- Reset the final location
        self.tInitialTrackerLoc = nil
        self.tFinalTrackerLoc = nil
    
        -- Setup the entity scaling
        local bUseEntityScaling = tAnimationData.bUseEntityScaling
        if tAnimData.bIsScaled == true and not tAnimationData.fnMoveHandler then
            if not bUseEntityScaling then
                self:_enableEntityScaling(false)
            end
            self:_enableEntityNavigation(false)           
        end
    else
        self:clearOverlayAnims()
    end
    
    tAnimationData.animPriority = animPriority
    self.tCurrentAnimationData = DFUtil.deepCopy(tAnimationData)

    -- Launch the requested animation
    self.tActiveAnims[sAnimName] = self:_addAnimationLayer(tAnimationData, tAnimData, animPriority)
    
    -- Only base (or non-overlay) animation can have attachments and/or animation events
    if animPriority == DFAnimController.PRIORITY_NORMAL then
    
        -- Store the speed of the delta-trans, so that proportional speed control can be used
        if tAnimData.deltaTransSpeed ~= nil then
            self.tActiveAnims[sAnimName].deltaTransSpeed = tAnimData.deltaTransSpeed * 300
            self.tActiveAnims[sAnimName].curAnimSpeed = 1.0
        end
    
        -- Load external props and/or anim events
        local rAssetSet = AssetSet.new()
        
        -- Add the props
        assert(#self.tAnimationAttachments == 0)
        
        local tAnimAttachments = {}
        if tAnimData.tProps ~= nil and #tAnimData.tProps > 0 then
        
                -- MTF: This was initially written to spawn the rig here, but now we seem to be doing that in
                -- Character, with tAccessories. So... don't spawn the rig.

                --[[
            local numProps = #tAnimData.tProps
            for i=1,numProps do
            
                local tProp = tAnimData.tProps[i]

                local tRigArgs = {}
                tRigArgs.sResource = tProp.sRig                
                local rPropRig = Rig.new(self.rEntity, tRigArgs, rAssetSet)
                rPropRig.rOwnerRig = self
                rPropRig.tPropData = tProp
                
                table.insert(tAnimAttachments, rPropRig)
            end
            ]]--
        end
        
        -- Get the animation events ready
        assert(#self.tAnimationEvents == 0)
        
        self.nextAnimEventIdx = 0
        
        if tAnimData.tAnimEvents and #(tAnimData.tAnimEvents) > 0 then
        
            for _, tMetaCommand in ipairs( tAnimData.tAnimEvents ) do
                for sCommandType,tCommandAttributes in pairs(tMetaCommand) do
                    local rCmd = SeqCommand.createCommand(sCommandType, tCommandAttributes, self)
                    if rCmd ~= nil then
                        rCmd:setRig(self)
                        table.insert(self.tAnimationEvents, rCmd)
                        rCmd:preloadCutscene(rAssetSet)
                    end
                end
            end
            
            self.nextAnimEventIdx = 1
        end
        
        
        -- Wait for all the assets of the attachments to load
        -- ToDo: Add pre-loading for animations, so that we don't stall here
        local numFramesStalled = 0
        while not rAssetSet:isLoaded() do
            coroutine.yield()
            numFramesStalled = numFramesStalled + 1
        end
        if numFramesStalled > 0 then
            Trace(TT_Warning, "RIG.LUA: Prop assets or anim events aren't preloaded for animation: " .. sAnimFile)
        end
        
        -- Attach the external props
        local numAnimAttachments = #tAnimAttachments
        for i=1,numAnimAttachments do
        
            local rPropRig = tAnimAttachments[i]
            rPropRig:activate()
            
            local tOffsetLoc = rPropRig.tPropData.tLoc
            if tOffsetLoc == nil then
                tOffsetLoc = { 0, 0, 0 }
            end
            
            local tOffsetRot = rPropRig.tPropData.tRot
            if tOffsetRot == nil then
                tOffsetRot = { 0, 0, 0 }
            end
            
            local tScale = rPropRig.tPropData.tScale
            if tScale == nil then
                tScale = { 1, 1, 1 }
            end
            
            self:_attach(true, rPropRig, rPropRig.tPropData.sJoint, tOffsetLoc, tOffsetRot, tScale)
        end
    end
    
    if Rig.bDBGExtendedProfiler then
        Profile.leaveScope( "Rig:playAnimation" )
    end
end

function Rig:stopAnimation(sAnimationFile)

    local sAnimName = sAnimationFile
    if self.tActiveAnims[sAnimName] == nil then
        return
    end

    local animPriority = self.rAnimController:getLayerPriority(sAnimName)
    self.rAnimController:removeLayer(sAnimName)	
    
    if animPriority == DFAnimController.PRIORITY_NORMAL then
    
        -- Disable root-motion and delete the attachments and anim events only for the base animation
        self:_unlinkTracker()
        self:_enableEntityScaling(true)
        self:_enableEntityNavigation(true)
        
        -- Remove all the props that were attached for the animation
        while #self.tAnimationAttachments > 0 do
            local rPropRig = self.tAnimationAttachments[1]
            self:_detach(true, rPropRig)
            -- Release the assets
            rPropRig:unload()
        end
        
        -- Delete all anim events
        local numAnimEvents = #self.tAnimationEvents
        if numAnimEvents > 0 then
            for i=1,numAnimEvents do
                local rAnimEvent = self.tAnimationEvents[i]
                rAnimEvent:cleanup()
                rAnimEvent.rSequence = nil
            end
            self.tAnimationEvents = {}
        end
    end
    
    self.tActiveAnims[sAnimName] = nil
end

function Rig:forceAnimLoad(tAnimationData)
	local sAnimFile = DFFile.getAssetPath(tAnimationData.sAnimPath)
	local tAnimData = DataCache.getData("anim", sAnimFile)
    if tAnimData == nil then
        assertdev(false)
        return
    end
    if not tAnimData.rAnimData then
        if tAnimData.sRig ~= self.sResource then
            Trace(TT_Error, string.format("RIG.LUA: Rig and animation don't match!\nRig : %s\nAnim: %s", tostring(self.sResource), tostring(tAnimData.sRig)))
            self.bDBG_NoAnim = true
        end
        local binaryAnimFilename = DFFile.stripSuffix(sAnimFile)
        binaryAnimFilename = binaryAnimFilename .. ".banim"
        tAnimData.rAnimData = DFAnimData.new()
        tAnimData.rAnimData:loadAsync(binaryAnimFilename)
	end
	tAnimData.rAnimData:sync()
	return tAnimData
end

function Rig:getAnimDuration(tAnimationData)
	local tAnimData = self:forceAnimLoad(tAnimationData)
	return tAnimData.rAnimData:getDuration()
end

function Rig:clearOverlayAnims()
    -- Remove the previous overlay
    for sAnimName,_ in pairs(self.tActiveAnims) do
        local animPriority = self.rAnimController:getLayerPriority(sAnimName)
        if animPriority == DFAnimController.PRIORITY_OVERLAY then
            self.rAnimController:removeLayer(sAnimName)
            self.tActiveAnims[sAnimName] = nil
        end
    end
end

function Rig:pauseAnimations()
    self.rAnimController:stop()
end

function Rig:resumeAnimations()
    self.rAnimController:start()
end

function Rig:setAnimSpeed(animSpeed, bDeltaTransRelative)
    for sAnimName,tAnim in pairs(self.tActiveAnims) do
        local animPriority = self.rAnimController:getLayerPriority(sAnimName)
        if animPriority == DFAnimController.PRIORITY_NORMAL then
            
            local bSetSpeed = not bDeltaTransRelative
            
            -- Speed of the animation should be relative to the given target speed
            if bDeltaTransRelative == true and tAnim.deltaTransSpeed ~= nil then
                local relativeSpeed = animSpeed / tAnim.deltaTransSpeed
                if math.abs(tAnim.curAnimSpeed - relativeSpeed) > 0.00001 then
                    -- Relative speed has changed, so let's apply it
                    animSpeed = relativeSpeed
                    tAnim.curAnimSpeed = relativeSpeed
                    bSetSpeed = true
                end
            end
            
            if bSetSpeed then
                self.rAnimController:setAnimSpeed(DFAnimController.PRIORITY_NORMAL, animSpeed)
            end
        end
    end
end

function Rig:setAnimMode(animMode)
    self.rAnimController:setAnimSpeed(DFAnimController.PRIORITY_NORMAL, animMode)
end

function Rig:isAnimPlayingOnLayer(sLayerName)
    local animPriority = DFAnimController.PRIORITY_NORMAL
    if sLayerName ~= nil then
        animPriority = self.rAnimController:getLayerPriority(sLayerName)
    end

    return ( self.rAnimController:getNumAnimsPlaying(animPriority) > 0 )
end

function Rig:setRigFlipped(bSetting)
    local bRigFlipped = self.scaleX == -1
    if bRigFlipped == bSetting then
        return
    end
    
    self.scaleX = 1
    if bSetting then
        self.scaleX = -1
    end
    
    self:_updateRootProp()
end

-- PUBLIC FUNCTIONS - MESH --
function Rig:getDynamicMesh()
    return self.rMainMesh
end

-- PUBLIC FUNCTIONS - MESH VISIBILITY --
function Rig:addMeshVisibilityOverrides(tMeshVisibilityOverrides)

    -- Add visibility overrides for subsets of the meshes used by this rig
    for sMeshName,tSubsetVisibility in pairs(tMeshVisibilityOverrides) do
        
        if self.tMeshVisibilityOverrides[sMeshName] == nil then
            self.tMeshVisibilityOverrides[sMeshName] = {}
        end
        
        local tSubsetVisibilityOverrides = self.tMeshVisibilityOverrides[sMeshName]
        for sSubsetName,visibilityCondition in pairs(tSubsetVisibility) do
            
            if tSubsetVisibilityOverrides[sSubsetName] == nil and visibilityCondition ~= nil then
                self.numMeshVisibilityOverrides = self.numMeshVisibilityOverrides + 1
            end
            tSubsetVisibilityOverrides[sSubsetName] = visibilityCondition
        end
    end
end

function Rig:removeMeshVisibilityOverrides(tMeshVisibilityOverrides)

    -- Remove visibility overrides for subsets of the meshes used by this rig
    for sMeshName,tSubsetVisibility in pairs(tMeshVisibilityOverrides) do
        
        if self.tMeshVisibilityOverrides[sMeshName] == nil then
            return
        end
        
        local tSubsetVisibilityOverrides = self.tMeshVisibilityOverrides[sMeshName]
        for sSubsetName,_ in pairs(tSubsetVisibility) do
            
            if tSubsetVisibilityOverrides[sSubsetName] ~= nil then
                self.numMeshVisibilityOverrides = self.numMeshVisibilityOverrides - 1
                tSubsetVisibilityOverrides[sSubsetName] = nil
            end
        end
    end
end

function Rig:clearMeshVisibilityOverrides()

    -- Clear all visibility overrides
    -- Note: This does not affect the currently playing animations
    self.tMeshVisibilityOverrides = {}
    self.numMeshVisibilityOverrides = 0
end

-- PUBLIC FUNCTIONS - EXTERNAL MESHES --
function Rig:addExternalMeshes(otherRig)

    -- Combine the dynamic meshes
    if self.rMainMesh ~= nil then
        for _, tMeshData in pairs(otherRig.tMeshMap) do
            if tMeshData.rMesh ~= nil then
                self.rMainMesh:addExternalMesh(tMeshData.rMesh)
            end
        end
    end
end

function Rig:removeExternalMeshes(otherRig)

	-- Remove the meshes from the draw context
	if self.rMainMesh ~= nil then
		for _, tMeshData in pairs(otherRig.tMeshMap) do
			if tMeshData.rMesh ~= nil then
				self.rMainMesh:removeExternalMesh(tMeshData.rMesh)
			end
		end
	end
end

-- PUBLIC FUNCTIONS - ATTACHMENTS --
function Rig:attach(otherRig, sJointName, tOffsetPosition, tOffsetRotation, tScale)
	self:_attach(false, otherRig, sJointName, tOffsetPosition, tOffsetRotation, tScale)
end

function Rig:detach(otherRig)
	self:_detach(false, otherRig)
end

-- PROTECTED FUNCTIONS - ANIMATIONS --
function Rig:_addAnimationLayer(tAnimationData, tAnimData, layerPriority)

    if self.bDBG_NoAnim then return end

    -- Wait for the load to finish
    tAnimData.rAnimData:sync()
    
    -- Get playback mode
    local playbackMode = MOAITimer.NORMAL
    if tAnimationData.playbackMode then
        playbackMode = tAnimationData.playbackMode
    end
    if tAnimData.playbackMode then
        playbackMode = tAnimData.playbackMode
    end
    
    -- Compute the number of additional animation tracks required by visiblity overrides
    local numExtraAnimTracks = 0
    --[[
    if tAnimationData.tMeshVisibility ~= nil then
        for sMeshName,tSubsetVisibility in pairs(tAnimationData.tMeshVisibility) do
            for sSubsetName,visibilityCondition in pairs(tSubsetVisibility) do
                numExtraAnimTracks = numExtraAnimTracks + 1
            end
        end
    end
    
    numExtraAnimTracks = numExtraAnimTracks + self.numMeshVisibilityOverrides
    ]]--
    
    -- Check if we need tracker curves
    local omitDeltaTransTracks = false
    if not tAnimationData.bUseEntityScaling then
        -- Move the tracker instead of the delta-trans, which means that the entire entity will move and not just the rig
        self:_linkTracker(tAnimationData.fnMoveHandler)
        omitDeltaTransTracks = true
    end
    
    -- Build the command buffer for the animation controller
    local tAnimLayerCmds = {}
    table.insert( tAnimLayerCmds, { tAnimationData.sAnimPath, tAnimData.rAnimData, playbackMode, numExtraAnimTracks, layerPriority, omitDeltaTransTracks } )
    
    -- Apply the visibility overrides
    --[[
    for i=1,2 do
    
        -- Animation overrides have priority over the static visiblity
        local tMeshVisibility = nil
        if i == 1 and self.numMeshVisibilityOverrides > 0 then
            tMeshVisibility = self.tMeshVisibilityOverrides
        elseif i == 2 and tAnimationData.tMeshVisibility ~= nil then
            tMeshVisibility = tAnimationData.tMeshVisibility
        end
        
        if tMeshVisibility ~= nil then
            for sMeshName,tSubsetVisibility in pairs(tMeshVisibility) do
                local tMeshData = self.tMeshMap[sMeshName]
                if tMeshData ~= nil then
                    for sSubsetName,visibilityCondition in pairs(tSubsetVisibility) do
                        local bVisible = true
                        local conditionalSubsetIndex = -1
                        if type(visibilityCondition) == "boolean" then
                            bVisible = visibilityCondition
                        else
                            conditionalSubsetIndex = self:_getSubsetIndex(tMeshData, visibilityCondition)
                            
                            if conditionalSubsetIndex == nil then
                                Trace(TT_Warning, "Unknown visibility condition: " .. visibilityCondition)
                            end
                        end
                        local subsetIndex = self:_getSubsetIndex(tMeshData, sSubsetName)
                        if subsetIndex then
                            table.insert( tAnimLayerCmds, { self:_boolToFloat(bVisible), DFAnimController.TARGET_SUBSET_VISIBILITY, tMeshData.rMesh, subsetIndex, conditionalSubsetIndex } )
                        else
                            Trace(TT_Warning, "Unknown subset: " .. sSubsetName)
                        end
                    end
                else
                    Trace(TT_Warning, "Unknown mesh: " .. sMeshName)
                end
            end
        end
    end
                        ]]--
    
    -- Add the layer and all of the tracks
    local layerID = self.rAnimController:addLayerAndTracks(tAnimLayerCmds)

    if tAnimationData.bApplyFinalTrackerLocation == true then
        -- Extract final tracker location
        self.tFinalTrackerLoc = tAnimData.tFinalDeltaTransLoc        
    end
    
    local tAnim = {}
    tAnim.layerID = layerID    
    return tAnim 
end

-- PROTECTED FUNCTIONS - ATTACHMENTS --
function Rig:_attach(bIsAnimAttachment, otherRig, sJointName, tOffsetPosition, tOffsetRotation, tScale)

    if not otherRig.rRootJoint then return end
    
    tOffsetPosition = tOffsetPosition or {0,0,0}
    tOffsetRotation = tOffsetRotation or {0,0,0}
    tScale = tScale or {1,1,1}

    local rAttachmentJointProp = self:getJointProp(sJointName)
    if rAttachmentJointProp ~= nil then
        
        -- Attach the root joint of the given rig to the given joint of this rig
        local rOtherAttachmentJointProp = otherRig.rRootJoint.rProp
        rOtherAttachmentJointProp:clearAttrLink(MOAIProp.INHERIT_TRANSFORM)
        rOtherAttachmentJointProp:clearAttrLink(MOAIProp.INHERIT_LOCROT)
        
        rOtherAttachmentJointProp:setLoc(unpack(tOffsetPosition))
        rOtherAttachmentJointProp:setRot(unpack(tOffsetRotation))
        tScale = tScale or {1,1,1}
        rOtherAttachmentJointProp:setScl(unpack(tScale))
            
        rOtherAttachmentJointProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, rAttachmentJointProp, MOAIProp.TRANSFORM_TRAIT)
        
        rOtherAttachmentJointProp:forceUpdate()
        otherRig.rAnimController:updateLast()
        
        -- Combine the dynamic meshes
		if self.rMainMesh ~= nil then
            for _, tMeshData in pairs(otherRig.tMeshMap) do
				if tMeshData.rMesh ~= nil then
					self.rMainMesh:addExternalMesh(tMeshData.rMesh)
				end
			end
		end
		
		if bIsAnimAttachment then
			table.insert(self.tAnimationAttachments, otherRig)
		end
        
    else
        Trace(TT_Warning, "RIG.LUA: Attachment failed. Couldn't find joint: " .. sJointName)
    end

end

function Rig:_detach(bIsAnimAttachment, otherRig)
    
	if bIsAnimAttachment then
		local idxPropRig = self:_findAnimationAttachment(otherRig)
		if idxPropRig > 0 then
			table.remove(self.tAnimationAttachments, idxPropRig)
		else
			Trace(TT_Warning, "RIG.LUA: Couldn't find animation attachment")
			assert(0)
		end
	end

    -- Detach the root joint of the given rig from the hierarchy of this joint...
    local rOtherAttachmentJointProp = otherRig.rRootJoint.rProp
    rOtherAttachmentJointProp:clearAttrLink(MOAIProp.INHERIT_TRANSFORM)
    rOtherAttachmentJointProp:clearAttrLink(MOAIProp.INHERIT_LOCROT)
    if not bIsAnimAttachment then
        -- ... and re-attach it to the entity
        local rOtherAttachmentParentJointProp = otherRig.rScaleJointProp
        rOtherAttachmentJointProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, rOtherAttachmentParentJointProp, MOAIProp.TRANSFORM_TRAIT)
    end
    
    rOtherAttachmentJointProp:forceUpdate()
    
	-- Remove the meshes from the draw context
	if self.rMainMesh ~= nil then
        for _, tMeshData in pairs(otherRig.tMeshMap) do
			if tMeshData.rMesh ~= nil then
				self.rMainMesh:removeExternalMesh(tMeshData.rMesh)
			end
		end
	end
	
    -- ToDo: Set the transform of the entity to match the root joint?
end

function Rig:_findAnimationAttachment(otherRig)

	local numAnimAttachments = #self.tAnimationAttachments
	for i=1,numAnimAttachments do
		local rPropRig = self.tAnimationAttachments[i]
		if rPropRig == otherRig then
			return i
		end
	end
	
	return 0
end

-- PUBLIC FUNCTIONS - MISC --
function Rig:update(deltaTime)
    if Rig.bDBGExtendedProfiler then
        Profile.enterScope( "Rig:update" )
    end

    if not self.rRootJoint then return end
    
    -- Update all the shader values (e.g. entity pivot, lighting values)
    self:_updateShaderValues()
    
    -- Update the scaling
	self:_updateRootProp()
    
    -- Update the attached rigs too
    local numAnimAttachments = #self.tAnimationAttachments
    for i=1,numAnimAttachments do
        local rPropRig = self.tAnimationAttachments[i]
        rPropRig:update(deltaTime)
    end
    
    -- Update the animation events    
    if self.nextAnimEventIdx > 0 then
        local numAnimEvents = #self.tAnimationEvents
        
        local animTime = self.rAnimController:getAnimTime(DFAnimController.PRIORITY_NORMAL)
        local animLoopCount = self.rAnimController:getAnimLoopCount(DFAnimController.PRIORITY_NORMAL)
        
        -- if we have looped, we need to restart the nextAnimEventIdx
        if animLoopCount ~= self.prevAnimLoopCount then
            self.nextAnimEventIdx = 1
            self.prevAnimLoopCount = animLoopCount
        end
        
        if self.nextAnimEventIdx <= numAnimEvents then    
            for i=self.nextAnimEventIdx,numAnimEvents do
                local rAnimEvent = self.tAnimationEvents[i]
                if rAnimEvent.StartTime < animTime then
                    rAnimEvent:execute()
                    self.nextAnimEventIdx = self.nextAnimEventIdx + 1
                else
                    break
                end
            end
        end
    end
    
    -- Update the tracker
    self:_updateTracker()
    
    if Rig.bDBGExtendedProfiler then
        Profile.leaveScope( "Rig:update" )
    end
end

function Rig:getProp()
    return self.rUnscaledRootJointProp
end

function Rig:getDeltaTransProp()

    if self.rDeltaTransJointProp == nil then
        self.rDeltaTransJointProp = self:getJointProp("DeltaTrans")
    end

    return self.rDeltaTransJointProp
end

function Rig:getWorldBounds(bDynamicBounds)
    local x0, y0, z0 = self.rEntity.rProp:modelToWorld()
    local x1, y1, z1 = x0, y0, z0
    if self.rMainMesh ~= nil then
        local cx0, cy0, cz0, cx1, cy1, cz1 = self.rMainMesh:getWorldBounds(bDynamicBounds)
        
        -- When entity scaling is disabled (e.g. in cutscenes) the bounds are incorrect, because ignores the scale
        -- In order to counter that (and avoid camera pops) reapply the scale of the entity to the stable bounding box
        if bDynamicBounds == false and self.bUseEntityOffsetScale == false then
        
            -- Apply pivot-relative scaling to the bounding box            
            cx0 = cx0 - x0
            cy0 = cy0 - y0
            cz0 = cz0 - z0
            cx1 = cx1 - x0
            cy1 = cy1 - y0
            cz1 = cz1 - z0
            
            local sx, sy, sz = self.rEntity.rProp:getScl()
            cx0 = cx0 * sx
            cy0 = cy0 * sy
            cz0 = cz0 * sz
            cx1 = cx1 * sx
            cy1 = cy1 * sy
            cz1 = cz1 * sz
            
            cx0 = cx0 + x0
            cy0 = cy0 + y0
            cz0 = cz0 + z0
            cx1 = cx1 + x0
            cy1 = cy1 + y0
            cz1 = cz1 + z0
            
        end
        
        x0, y0, z0 = math.min(x0, cx0), math.min(y0, cy0), math.min(z0, cz0)
        x1, y1, z1 = math.max(x1, cx1), math.max(y1, cy1), math.max(z1, cz1)
        
        
    end
    return x0, y0, z0, x1, y1, z1
end

function Rig:hitTest(x, y)
    if self.rMainMesh ~= nil then
        local x0, y0, z0, x1, y1, z1 = self.rMainMesh:getWorldBounds(true)
        if x0 <= x and x <= x1 and y0 <= y and y <= y1 then
            return true
        end
    end
end

-- PUBLIC FUNCTIONS - MISC --
function Rig:getMaterials()
    return self.tMaterials
end

function Rig:setTargetSceneLayer(rTargetSceneLayer, targetSceneLayerAlpha)
    self.rTargetSceneLayer = rTargetSceneLayer
    self.targetSceneLayerAlpha = targetSceneLayerAlpha
end

function Rig:_setTextureReplacements( tRigData )
    local tTextureReplacements = tRigData.tTextureReplacements
    
    -- replace textures on the global level (no longer used)
    self.tTextureReplacements = {}
    
    if tTextureReplacements then
        for _,v in ipairs(tTextureReplacements) do
            self.tTextureReplacements[ v[1] ] = v[2]
        end
    end
end


function Rig:setTexturePath( tReplacements )   
    -- replace textures within the subset material
	local bSuccess = true
    for _,v in ipairs(tReplacements) do
        local rTexture = DFGraphics.loadTexture( v[3], false )
        
        local rMaterial = self.rMainMesh.tSubsetMaterials[ v[1] ]
        if rMaterial == nil then 
            print("RIG.LUA: nil material for subset:"..v[1]..", texture:"..v[3]) 
			bSuccess = false
        else
            rMaterial:setShaderValue(v[2], MOAIMaterial.VALUETYPE_TEXTURE, rTexture)
        end
    end
	return bSuccess
end

-- PROTECTED FUNCTIONS --
function Rig:_resetToBindPosition()

    -- Remove the base animation but keep the overlay
    for sAnimName,_ in pairs(self.tActiveAnims) do
        local animPriority = self.rAnimController:getLayerPriority(sAnimName)
        if animPriority == DFAnimController.PRIORITY_NORMAL then
            self:stopAnimation( sAnimName )
            assert( self.tActiveAnims[sAnimName] == nil )
        end
    end
    
    -- Disable root motion
	self:_unlinkTracker()
    self.rTrackerTrans:setLoc(0, 0, 0)
    
    -- Reset the scaling
    self.prevScaleX = nil
    self:_updateRootProp()
end

function Rig:_createMeshes( tDataDesc, tRigArgs, rAssetSet )
	
	local tMeshDescs = tDataDesc.tMeshes	
	self.numMeshes = #tMeshDescs
	for i=1,self.numMeshes do
	
		local tMeshDesc = tMeshDescs[i]
		assert(self.tMeshMap[tMeshDesc.sName] == nil)
		
		local tMeshData = {}
		tMeshData.tMeshDesc = tMeshDesc		
		self.tMeshMap[tMeshDesc.sName] = tMeshData
		
		-- Create the mesh
		if tMeshDesc.tTriMesh then
			self:_createTriMesh(tDataDesc, tMeshDesc, tMeshData, tRigArgs, rAssetSet)
			
			if tMeshData.rMesh ~= nil then
				if self.rMainMesh == nil then
					self.rMainMesh = tMeshData.rMesh
                    self.rMainMesh.rEntity = self.rEntity
				else
					self.rMainMesh:addExternalMesh(tMeshData.rMesh)
				end
			end
		end
		
		-- Create a attachment prop
		local rMeshProp = tMeshData.rMesh
		rMeshProp:setAttrLink(MOAIProp.INHERIT_TRANSFORM, self.rRootJoint.rProp, MOAIProp.TRANSFORM_TRAIT)

	end
end

function Rig:_createTriMesh( tDataDesc, tMeshDesc, tMeshData, tRigArgs, rAssetSet )

	local tTriMeshDesc = tMeshDesc.tTriMesh
	
	-- Create mesh
	local rMesh = DFDynamicMesh.new()
    rMesh:setName(tMeshDesc.sName)
    rMesh:setAnimController(self.rAnimController)
    
    -- Setup reflection
    rMesh:setReflectable(tRigArgs.bIsReflectable)
    rMesh:setReflectionOffset(tRigArgs.reflectionOffset)
    if tRigArgs.sReflectionOffsetJointName and #tRigArgs.sReflectionOffsetJointName > 0 then
    
        local rReflectionOffset = nil
        
        local tJointData = self.tJointMap[tRigArgs.sReflectionOffsetJointName]
        if tJointData ~= nil then
            rReflectionOffset = self:getJointProp(tRigArgs.sReflectionOffsetJointName)
        end
        
        if rReflectionOffset ~= nil then
            rMesh:setReflectionOffset(rReflectionOffset)
        else
            Trace(TT_Warning, "RIG.LUA: Couldn't find reflection offset joint: " .. tRigArgs.sReflectionOffsetJointName)
        end
    end
    
    -- Setup mesh data
	tMeshData.rMesh = rMesh
    tMeshData.tSubsetIndices = {}
    
    -- Load and set global material
    local rMaterial = Renderer.getGlobalMaterial("meshBase")
    rMaterial = self:_getMaterial( tRigArgs.sMaterial, rAssetSet, rMaterial )
    rMesh:setMaterial( rMaterial )
    rMesh:setDepthMask(true)
    rMesh:setDepthTest(MOAIProp.DEPTH_TEST_LESS_EQUAL)
    
    -- Load subset materials
    local tSubsetMaterials = {}
    if tTriMeshDesc.tMaterials ~= nil and #tTriMeshDesc.tMaterials > 0 then
        local numSubsetMaterials = #tTriMeshDesc.tMaterials
        for i=1,numSubsetMaterials do
            local sSubsetMaterial = tTriMeshDesc.tMaterials[i]
            -- Apply the material remapping (if specified)
            if tRigArgs.tMaterialMap ~= nil then
                if tRigArgs.tMaterialMap[sSubsetMaterial] ~= nil then
                    sSubsetMaterial = tRigArgs.tMaterialMap[sSubsetMaterial]
                end
            end
            local rSubsetMaterial = self:_getMaterial( sSubsetMaterial, rAssetSet )
            table.insert(tSubsetMaterials, rSubsetMaterial)
        end
    end
    
    -- Initialize the mesh
    rMesh:setRigData(tDataDesc.rRigData)
	
	-- Setup subsets
    local tSubsetAppearance = {}
    local numSubsets = #tTriMeshDesc.tSubsets
	for i=1,numSubsets do
	
		local tSubset = tTriMeshDesc.tSubsets[i]
		
        local subsetIndex = i-1
        local sName = rMesh:getSubsetName(subsetIndex)
        
        tSubset.sName = sName
        tSubset.nIndex = subsetIndex
        
        local sTexture = tRigArgs.sTextureOverride or tSubset.sTexture
		local rTexture = self:_getTexture( sTexture, rAssetSet )
        
        local rSubsetMaterial = nil -- Use default material
        if tSubset.materialIdx ~= nil and tSubsetMaterials ~= nil then
            rSubsetMaterial = tSubsetMaterials[tSubset.materialIdx]
        else
            -- hax
            local sMaterial = tRigArgs.sMaterial
            if not sMaterial then
                sMaterial = "meshDefault"
            end
            rSubsetMaterial = Renderer.loadMaterialInstance(sMaterial)
        end
        
        table.insert(tSubsetAppearance, { rTexture, rSubsetMaterial })
        
        if nil == rMesh.tSubsetMaterials then
            rMesh.tSubsetMaterials = {}
        end
        rMesh.tSubsetMaterials[sName] = rSubsetMaterial
        rMesh:addSubsetMaterial(rSubsetMaterial)
	end

    rMesh:setSubsetAppearance(tSubsetAppearance)
	
    -- Mesh will be made visible in activate(), but rigs are deactivated by default
    rMesh:setVisible(false)

	return rMesh
	
end

function Rig:_getTexture( sTexture, rAssetSet )

	local rTexture = nil
	
	if sTexture then
		rTexture = rAssetSet:preloadTexture(sTexture)
        rTexture:setWrap(true)
		table.insert( self.tTextures, sTexture )
	else
		rTexture = Renderer.getGlobalTexture( "white" )
	end
	
	return rTexture
end

function Rig:_getMaterial( sMaterial, rAssetSet, rDefaultMaterial )

    local rMaterial = rDefaultMaterial
    
    if sMaterial ~= nil and #sMaterial > 0 then
        local extension = DFFile.getSuffix(sMaterial)
        if extension and #extension > 0 then
            -- Use a custom material
            rMaterial = DFGraphics.loadMaterial(sMaterial)
            table.insert(self.tMaterials, rMaterial)
        else
            -- Use a shared material
            rMaterial = Renderer.getGlobalMaterial(sMaterial)
            if rMaterial == nil then
                Trace(TT_Warning, "RIG.LUA: Undefined shared material: " .. sMaterial)
                rMaterial = Renderer.getGlobalMaterial("meshBase")
            end
        end
    end
    
    return rMaterial
end

function Rig:_getSubsetIndex( tMeshData, sSubsetName )

    if not tMeshData.tSubsetIndices[sSubsetName] then
        tMeshData.tSubsetIndices[sSubsetName] = {}
        tMeshData.tSubsetIndices[sSubsetName].idx = tMeshData.rMesh:getSubsetIndex(sSubsetName)
    end

    return tMeshData.tSubsetIndices[sSubsetName].idx
end

function Rig:_boolToFloat(value)
    if value == true then
        return 1
    else
        return 0
    end
end

function Rig:_initializeJointHierarchy(tData)

    self.rAnimController = DFAnimController.new()

    self.rAnimController:setDebugName(self.rEntity.sName)
    self.rAnimController:setRootTransform(self.rRootJoint.rProp)
    self.rAnimController:initJointHierarchy(tData.rRigData)

    -- Stop animation by default.  Animation will be re-enabled when the rigt is made active.
    self.rAnimController:stop()

    -- Create joint map
    -- ToDo: Remove this once the animation data is binary
    local numJoints = #tData.tJoints
    for i=1,numJoints do
        local tJointData = {}
        tJointData.idx = i
        local sJointName = tData.tJoints[i]
        self.tJointMap[sJointName] = tJointData
    end
end

function Rig:_initializeAnimController(tData, tRigArgs)
    
    self.rAnimController:reserveLayers(4) -- Rest position + Animation + Overlay = 3
    self.rAnimController:initRestPose(1, self.rMainMesh)
end

function Rig:_insertVisCommand(tSubset, tVariations, tVisTable)
    local sSubsetName = tSubset.sName
    
    -- We only insert a visibility command, true or false, if:
    --  * the 'prefix' field in a variation matches part of the subset name. In that case, we
    --    insert true/false based on whether the subset name starts with the 'full' field.
    --  * If there is no 'prefix' field, we will insert a true if the 'full' field is contained in the subset name.
    --  * If there is a 'prefix' and 'full' == "", we will show no subsets with that prefix
    if tVariations then
        for k,v in pairs(tVariations) do
            if v.prefix then
                if string.sub(sSubsetName, 1, #v.prefix) == v.prefix then
                    local bShow = string.sub(sSubsetName, 1, #v.full) == v.full
                    if v.full == "" then bShow = false end 
                    table.insert(tVisTable, {tSubset,bShow})
                end
            elseif v.full then
                if string.find(sSubsetName, v.full) then
                    table.insert(tVisTable, {tSubset, true})
                end
            end
        end
        return false
    end
end

function Rig:setVariationLayer(tVariations)
    if self.bDBG_NoAnim then return end

    self.rAnimController:removeLayer('Variation')
    
    local variationSubsets = {}

    -- Mesh tracks
	for sMeshName,tMeshData in pairs(self.tMeshMap) do
        local tTriMeshData = tMeshData.tMeshDesc.tTriMesh
    
        for idx,subset in ipairs(tTriMeshData.tSubsets) do
            self:_insertVisCommand(subset, tVariations, variationSubsets)
        end
       

        -- Create 'variation'
        --local variationPriority = 10 -- Priority is higher than rest but below animations
        local variationPriority = DFAnimController.PRIORITY_NORMAL+1 -- Artists are having trouble with the authoring pipeline, so putting this above normal.
        local numSubsets = #variationSubsets

        local tAnimLayerCmds = {}
        table.insert( tAnimLayerCmds, { "Variation", {}, MOAITimer.NORMAL, numSubsets, variationPriority, true } )

        for i=1,numSubsets do
            local sSubsetName = variationSubsets[i][1].sName
            local subsetIndex = variationSubsets[i][1].nIndex
            local bIsVisible = variationSubsets[i][2]
            table.insert( tAnimLayerCmds, { self:_boolToFloat(bIsVisible), DFAnimController.TARGET_SUBSET_VISIBILITY, tMeshData.rMesh, subsetIndex } )
        end
    
        self.rAnimController:addLayerAndTracks(tAnimLayerCmds)
    end
end

function Rig:_enableEntityScaling( bEnable )

    if bEnable == false and self.bUseEntityOffsetScale == true then
        self.rScaleJointProp:clearAttrLink(MOAIProp.OFFSET_SCL, self.rEntity.rProp)
        self.bUseEntityOffsetScale = false
    end
    if bEnable == true and self.bUseEntityOffsetScale == false then
        self.rScaleJointProp:setAttrLink(MOAIProp.OFFSET_SCL, self.rEntity.rProp, MOAIProp.OFFSET_TRANSFORM_TRAIT)
        self.bUseEntityOffsetScale = true
    end
    
    self.rAnimController:enableAnimationRootScaling(not bEnable)
end

function Rig:_enableEntityNavigation( bEnable )

    if bEnable == false and self.bAllowEntityNavigation == true then
        if self.rEntity.CoNavigator ~= nil and self.rEntity.CoNavigator.bUsePathing == true then
            self.rEntity.CoNavigator:cancelNavigation()
            self.rEntity.CoNavigator.bUsePathing = false
            self.bAllowEntityNavigation = false
        end
    end
    if bEnable == true and self.bAllowEntityNavigation == false then
        if self.rEntity.CoNavigator ~= nil and self.rEntity.CoNavigator.bUsePathing == false then
            self.rEntity.CoNavigator.bUsePathing = true
            self.bAllowEntityNavigation = true
        end
    end
end

function Rig:_linkTracker(fnMoveHandler)

    if not self.bHasRootMotion or ( fnMoveHandler and fnMoveHandler ~= self.fnMoveHandler ) then
    
        self.bHasRootMotion = true
        
        local rEntityProp = self.rEntity:getProp()    
        rEntityProp:clearAttrLink(MOAIProp.OFFSET_LOC)
        if not fnMoveHandler then
            
            self.rAnimController:setTrackerTransform(self.rTrackerTrans)
            
            local x, y, z = rEntityProp:getLoc()
            self.tInitialTrackerLoc = { x, y, z }
        
            rEntityProp:setAttrLink(MOAIProp.OFFSET_LOC, self.rTrackerTrans, MOAIProp.OFFSET_TRANSFORM_TRAIT)
        else
            self.fnMoveHandler = fnMoveHandler
            self._movePrevX, self._movePrevY, self._movePrevZ = nil, nil, nil
        end
        
        -- Make sure the changes get applied immediately
        rEntityProp:forceUpdate()     
    end
end

function Rig:_unlinkTracker()

    if self.bHasRootMotion == true or self.tFinalTrackerLoc then
    
        self.bHasRootMotion = false
        
        local rEntityProp = self.rEntity:getProp()
        rEntityProp:clearAttrLink(MOAIProp.OFFSET_LOC)
        
        if self.fnMoveHandler == nil then
        
            self.rAnimController:setTrackerTransform(nil)
            
            if self.tFinalTrackerLoc ~= nil then
            
                -- Apply the final location of the tracker to the entity
                local cx, cy, cz = rEntityProp:getLoc()
                local ex, ey, ez = unpack(self.tFinalTrackerLoc)
                
                local x = ex * 300
                local y = ey * -300
                -- NOTE:
                -- setting z to the current-z fixes an issue (Cloud Colony Sacrifice intro) where the final z is non-zero and there is
                -- a one-frame pop in the Girl's position.
                -- are there any cases where we would not want z to be current-z?  if we find one, then a possible solution is to
                -- have the final z be relative to the first animation frame's z.
                local z = ez * 300
                z = cz
                
                rEntityProp:setLoc(x, y, z)
            end
        end
        
        self.fnMoveHandler = nil
        self.tFinalTrackerLoc = nil
        
        -- Make sure the changes get applied immediately
        self.rMainMesh:forceUpdate()
    end
end

function Rig:_updateRootProp()
    
    local rProp = self.rRootJoint.rProp
    
    -- Get the offset scaling applied to the base entity
    -- ToDo: Walk up the tree for recursive attachments?
    if self.rOwnerRig and self.rOwnerRig.rEntity and self.rOwnerRig.rEntity.rProp then
        local sx, sy, sz = self.rOwnerRig.rEntity.rProp:getScl()
        rProp:setScl(self.scaleX * sx, sy, sz)
    else
     
        -- Apply left/right direction
        if self.prevScaleX ~= self.scaleX then
            rProp:setScl(self.scaleX, 1, 1)
            self.prevScaleX = self.scaleX
        end
    end
end

function Rig:_updateTracker()
    if self.fnMoveHandler then
        local rTracker = self.rTrackerTrans
        local x, y, z = rTracker:modelToWorld()
        if self._movePrevX then
            local dx, dy, dz = x - self._movePrevX, y - self._movePrevY, z - self._movePrevZ
            self.fnMoveHandler(dx, dy, dz)
        end
        self._movePrevX, self._movePrevY, self._movePrevZ = x, y, z
    end
end

function Rig:_updateShaderValues()

    if Rig.bDBGExtendedProfiler then
        Profile.enterScope( "Rig:_updateShaderValues" )
    end
    
    local tShaderValues = {}
    
    -- Update the entity pivot if it has changed
    local bUpdateEntityLoc = false
    local x, y, z = self.rEntity.rProp:modelToWorld()
    if not self.tLastEntityLoc then
        bUpdateEntityLoc = true
    else
        local distSqr = DFMath.distanceSquared( x, y, z, self.tLastEntityLoc[1], self.tLastEntityLoc[2], self.tLastEntityLoc[3] )
        if distSqr > 1 then
            bUpdateEntityLoc = true
        end
    end
    if bUpdateEntityLoc then
        self.rMainMesh:setEntityPivot(x, y, z)
    end
    self.tLastEntityLoc = {x, y, z}
    
    -- Update the light binding
    if self.rEntity.CoLightProbeSampler ~= nil then
        local rSceneLayer = self.rEntity:getSceneLayer()
        if self.sLastSceneLayerName ~= rSceneLayer.Name then
        
            self.rMainMesh:setLightLayerName(rSceneLayer.Name)
            self.sLastSceneLayerName = rSceneLayer.Name
            
            self.rTargetSceneLayer = nil
            self.targetSceneLayerAlpha = 0
        end
        
        if self.rTargetSceneLayer then
            -- This should only be called when the character is on a layer bridge
            -- Don't bother with cached state updates, because the alpha will change every frame anyway
            self.rMainMesh:setTargetLightLayerName(self.rTargetSceneLayer.Name, self.targetSceneLayerAlpha)
            self.sLastTargetSceneLayerName = self.rTargetSceneLayer.Name
        else
            if self.sLastTargetSceneLayerName then
                self.rMainMesh:setTargetLightLayerName()
                self.sLastTargetSceneLayerName = nil
            end
        end
    end
    
    if Rig.bDBGExtendedProfiler then
        Profile.leaveScope( "Rig:_updateShaderValues" )
    end
end

-- DEBUG DRAW --
function Rig.debugDrawBox(rSceneLayer, x0, y0, z0, x1, y1, z1)

    local a0, b0 = rSceneLayer:worldToWnd(x0, y0, z0)
    local a1, b1 = rSceneLayer:worldToWnd(x1, y0, z0)
    local a2, b2 = rSceneLayer:worldToWnd(x1, y1, z0)
    local a3, b3 = rSceneLayer:worldToWnd(x0, y1, z0)
    
    local c0, d0 = rSceneLayer:worldToWnd(x0, y0, z1)
    local c1, d1 = rSceneLayer:worldToWnd(x1, y0, z1)
    local c2, d2 = rSceneLayer:worldToWnd(x1, y1, z1)
    local c3, d3 = rSceneLayer:worldToWnd(x0, y1, z1)
    
    MOAIDraw.drawLine( a0, b0, a1, b1 )
    MOAIDraw.drawLine( a1, b1, a2, b2 )
    MOAIDraw.drawLine( a2, b2, a3, b3 )
    MOAIDraw.drawLine( a3, b3, a0, b0 )
    
    MOAIDraw.drawLine( c0, d0, c1, d1 )
    MOAIDraw.drawLine( c1, d1, c2, d2 )
    MOAIDraw.drawLine( c2, d2, c3, d3 )
    MOAIDraw.drawLine( c3, d3, c0, d0 )
    
    MOAIDraw.drawLine( a0, b0, c0, d0 )
    MOAIDraw.drawLine( a1, b1, c1, d1 )
    MOAIDraw.drawLine( a2, b2, c2, d2 )
    MOAIDraw.drawLine( a3, b3, c3, d3 )
end

function Rig:debugDraw(bDebugDrawJoints, bDebugDrawBounds, bDebugDrawSubsetBounds, bDebugDrawSubsetNames)
	
	local rSceneLayer = self.rEntity:getSceneLayer() or Renderer.getRenderLayer(Character.RENDER_LAYER)
	
	if bDebugDrawJoints and rSceneLayer then
	
		self.rAnimController:debugDrawJointHierarchy(rSceneLayer)
	end
    
	if bDebugDrawBounds and self.rMainMesh ~= nil and rSceneLayer then
    
        if bDebugDrawSubsetBounds then
            local idx = 0
            while true do
                idx = idx + 1
                local isVisible, x0, y0, z0, x1, y1, z1, subsetName = self.rMainMesh:getSubsetInfo( idx )
                if isVisible == nil then
                    break
                end
                if isVisible == true then
                
                    MOAIGfxDevice.setPenColor ( 1, 0, 0, 1 )
                    Rig.debugDrawBox( rSceneLayer, x0, y0, z0, x1, y1, z1 )
                    
                    if bDebugDrawSubsetNames then
                    
                        local x = (x0 + x1) * 0.5
                        local y = (y0 + y1) * 0.5
                        local z = (z0 + z1) * 0.5
                        
                        local cx, cy = rSceneLayer:worldToWnd(x, y, z)	
                       
                        cx = math.floor( cx )
                        cy = math.floor( cy ) 
                        
                        local rFont = Renderer.getGlobalFont("debug")
                        MOAIGfxDevice.setPenColor( 1, 1, 1, 1 )
                        MOAIDraw.drawText(rFont, 30, subsetName, cx, cy, 1, 2, 2)
                    end
                end
            end
        end
        
        MOAIGfxDevice.setPenColor ( 0, 1, 0, 1 )        
        local x0, y0, z0, x1, y1, z1 = self:getWorldBounds(false)
        if x0 ~= nil then
        
            local offset = 5
            x0 = x0 - offset
            y0 = y0 - offset
            z0 = z0 - offset
            
            x1 = x1 + offset
            y1 = y1 + offset
            z1 = z1 + offset
            
            Rig.debugDrawBox( rSceneLayer, x0, y0, z0, x1, y1, z1 )
        end
        
        MOAIGfxDevice.setPenColor ( 0, 0, 1, 1 )        
        local x0, y0, z0, x1, y1, z1 = self.rMainMesh:getWorldBounds(true)
        if x0 ~= nil then
        
            local offset = 5
            x0 = x0 - offset
            y0 = y0 - offset
            z0 = z0 - offset
            
            x1 = x1 + offset
            y1 = y1 + offset
            z1 = z1 + offset
            
            Rig.debugDrawBox( rSceneLayer, x0, y0, z0, x1, y1, z1 )
        end
    end
end

function Rig:setRigShaderValue(valueName, value)
    if Rig.bDBGExtendedProfiler then
        Profile.enterScope("setRigShaderValue per mesh")
    end
    
    -- try to handle different types, even if they
    -- don't work for the shader value being set
    local valueType = nil
    if type(value) == 'number' then
        valueType = MOAIMaterial.VALUETYPE_FLOAT
    elseif type(value) == 'table' then
        if #value == 2 then
            valueType = MOAIMaterial.VALUETYPE_VEC2
        elseif #value == 3 then
            valueType = MOAIMaterial.VALUETYPE_VEC3
        elseif #value == 4 then
            valueType = MOAIMaterial.VALUETYPE_VEC4
        end
    end
    if not valueType then
        print('RIG.LUA: setRigShaderValue: unrecognized value type for ' .. value)
        return
    end
    
    self.rMainMesh:setShaderValue(valueName, valueType, value)
    
    if Rig.bDBGExtendedProfiler then
        Profile.leaveScope("setRigShaderValue per mesh")
    end
end

-- HOT RELOAD STUFF: need to support new .anim and .animevent files
function Rig.hotReloadAnim(assetPath)
    print("RIG.LUA: doing a hot reload for anim: " .. assetPath)
    
    -- this is a pretty heavy hammer; we need to add a DataCache.removeItem() and then figure out specifically which anim to kill
    DataCache.clear( "anim" )
    
    -- also as a big hammer, we restart all animations (we might be able to just restart anims if they match this anim event path)
    for rig, _ in pairs(gAllRigs) do
        if rig.tCurrentAnimationData then
            rig:playAnimation(rig.tCurrentAnimationData)
        end
    end
end

function Rig.hotReloadAnimEvents(assetPath)
    print("RIG.LUA: anim event reload requested, clearing cache for anims and hopefully that's good enough dawg. : " .. assetPath)   
    
    Rig.hotReloadAnim(assetPath)
end

function Rig.hotReloadRig(assetPath)
    print("RIG.LUA: hot reload not implemented for rig: " .. assetPath)
end

local assetRoot = DFFile.getAssetPath('')
function Rig.onFileChange(path)
    -- Treat cache paths a munged paths
    path = path:gsub('/_Cache/', '/Munged/')
    if string.find(path, assetRoot) == 1 then
        local assetPath = string.sub(path, #assetRoot + 1)
        local sExtension = DFFile.getSuffix( assetPath )
        if sExtension == "anim" then
            Rig.hotReloadAnim(assetPath)
        elseif sExtension == "animevents" then
            Rig.hotReloadAnimEvents(assetPath)
        elseif sExtension == "rig" then
            Rig.hotReloadRig(assetPath)
        end
    end
end

-- Monitor file changes so that we can hot reload particle data
DFMoaiDebugger.dFileChanged:register(Rig.onFileChange)

return Rig
