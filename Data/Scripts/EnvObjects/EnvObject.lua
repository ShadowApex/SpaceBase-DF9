local Class=require('Class')
local DFGraphics = require('DFCommon.Graphics')
local EnvObjectData=require('EnvObjects.EnvObjectData')
local PickupData=require('Pickups.PickupData')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')
local Lighting = require('Lighting')
local Renderer=require('Renderer')
local Malady=require('Malady')
local Character=require('CharacterConstants')
local GameRules=require('GameRules')
local OptionData=require('Utility.OptionData')
local ObjectList=require('ObjectList')
local Room=require('Room')
local SoundManager = require('SoundManager')
local DFMath = require("DFCommon.Math")
local DFUtil = require("DFCommon.Util")
local MiscUtil = require("MiscUtil")
local Inventory = require("Inventory")
local Effect=require('Effect')
local Gui = require('UI.Gui')
local Zone = require('Zones.Zone')
local CharacterManager = require('CharacterManager')
local Base = require('Base')
local ResearchData = require('ResearchData')
local World = require('World')

local EnvObject = Class.create(nil, MOAIProp.new)

-- Decay per hour is set per-object in EnvObjectData.lua
EnvObject.MIN_PCT_HEALED_PER_MAINTAIN = 2
EnvObject.MAX_PCT_HEALED_PER_MAINTAIN = 25
-- amount damaged on failure
EnvObject.MAINTAIN_FAILURE_DAMAGE = 0
EnvObject.PROBABILITY_FIRE_ON_DESTROY = 0
EnvObject.PROBABILITY_FIRE_ON_DANGER_ZONE_MAINTAIN_FAILURE = 0.2
EnvObject.DANGER_ZONE = 20
-- if object stays at 0 condition for too long, chance to catch fire
EnvObject.DESTROYED_FIRE_CHECK_DELAY = 30
EnvObject.DESTROYED_FIRE_CHECK_INTERVAL = 60
EnvObject.DESTROYED_FIRE_CHANCE = 0.05

EnvObject.DEFAULT_SABOTAGE_DURATION = 60

EnvObject.CONDITION_NEEDED_TO_MAINTAIN = 80
EnvObject.DAMAGED_CONDITION = 50
EnvObject.DANGER_SPARK_FREQUENCY = 6
EnvObject.sSparkFX = 'Effects/Props/BuildSparks'

EnvObject.spriteSheetPath='Environments/Objects'

EnvObject.sFlipYSuffix='_flipY'

-- X and Y offset for "no power" icon
EnvObject.DEFAULT_ICON_OFFSET = {0, 100}

EnvObject.ghostColor = require('UI/Gui').AMBER
EnvObject.ghostColor[4] = 0.52
EnvObject.pendingVaporizeColor = Gui.RED

EnvObject.sOnFireLineCode = 'INSPEC078TEXT'

EnvObject.tConditions=
{
    {nBelow=101, sSuffix='', linecode = "INSPEC051TEXT" },
    {nBelow=EnvObject.DAMAGED_CONDITION, sSuffix='_damaged', linecode = "INSPEC052TEXT" },
    {nBelow=1, sSuffix='_destroyed', linecode = "INSPEC053TEXT" },
}

EnvObject.tConditionColors=
{
	{nBelow=101, tBarColor = {0,   0.6,  0} },
	{nBelow=75, tBarColor  = {0.4, 0.5,  0} },
	{nBelow=50, tBarColor  = {0.7, 0.5,  0} },
	{nBelow=25, tBarColor  = {0.6, 0.25, 0} },
	{nBelow=1, tBarColor   = {0.7, 0,    0} },
}

-- start at 2 to help find array vs. table bugs faster.
EnvObject.propCounter = 2

function EnvObject.getObjectData(sName)
    if EnvObjectData.tObjects[sName] then return EnvObjectData.tObjects[sName] end
    if EnvObjectData.tAliases[sName] then return EnvObjectData.tObjects[ EnvObjectData.tAliases[sName] ] end
    return PickupData.tObjects[sName], true
end

function EnvObject.getEnvObjectJobs(rChar)
    -- MTF TODO PERF:
    -- We have envobjects per room. We can find the ones most in need of maintenance and
    -- just add their maintain option.
    -- Similarly, we can pick the best option of all same-named inherentActivities.
    local tUtilityOptions = {}

    local tTags = ObjectList.getTagsOfType(ObjectList.ENVOBJECT)
    for _,objData in pairs(tTags) do
        table.insert(tUtilityOptions, objData.obj.activityOptionList:getListAsUtilityOptions())
    end
    return tUtilityOptions
end

function EnvObject.getEnemyEnvObjectJobs(rChar)
	-- like getEnvObjectJobs, but returns only options applicable to hostiles
    local tUtilityOptions = {}
    local tTags = ObjectList.getTagsOfType(ObjectList.ENVOBJECT)
    for _,objData in pairs(tTags) do
		table.insert(tUtilityOptions, objData.obj.enemyActivityOptionList:getListAsUtilityOptions())
    end
    return tUtilityOptions
end

-- Used as a gating function in ActivityOption's utility calculation.
function EnvObject.gateJobActivity(propName, rChar, bBuilding, rObj)
    if rObj and rObj:getTeam() ~= rChar:getTeam() then return false, 'wrong team' end

    local tData = EnvObject.getObjectData(propName)
    local jobReq = nil
    if bBuilding then
        jobReq = tData.createJob or Character.BUILDER
    else
        jobReq = tData.maintainJob or Character.TECHNICIAN
    end
    
    if jobReq == rChar:getJob() then
        return true
    else
        return false, 'wrong job'
    end
end

function EnvObject.getSpriteLoc(propName,wx,wy,bFlipX,bFlipY)
    local spriteX
    spriteX = g_World.getTileJustifiedWorldPos(wx, wy, MOAIGridSpace.TILE_LEFT_TOP)
    local tData,bPickup = EnvObject.getObjectData(propName)

    if bFlipX then
        local spriteName = tData.spriteName
        local spriteSheetPath = tData.spriteSheetPath or ((bPickup and require('Pickups.Pickup').spriteSheetPath) or EnvObject.spriteSheetPath)
        if not spriteName then
             spriteName = tData.commandSpriteName
             spriteSheetPath = tData.commandSpriteSheet
        end
        if spriteName then
            local spriteSheet = DFGraphics.loadSpriteSheet(spriteSheetPath, false, false, false)
            local r = spriteSheet.rects[ spriteSheet.names[spriteName] ]
            spriteX = spriteX + r.origWidth
        end
        --spriteX = spriteX - (data.width-1)*g_World.tileWidth*.5
    end

    if not bFlipX and tData.spriteOffsetX then
        spriteX = spriteX + tData.spriteOffsetX
    elseif bFlipX and tData.spriteOffsetXFlipped then
        spriteX = spriteX + tData.spriteOffsetXFlipped
    end

    local _,spriteY = g_World.getPropMinY(wx,wy,propName,bFlipX)
    local spriteZ = g_World.getHackySortingZ(wx,wy)

    if propName == 'SpaceshipEngine' then
        -- post-1.0 hack due to incorrect flip info on SpaceshipEngine
        local offset = -40
        if not bFlipY then
            spriteZ = spriteZ - offset
        else
            spriteZ = spriteZ + offset
        end
    elseif tData.againstWall then
        -- Bias objects that are against the wall in the direction of their wall to help sorting issues.
        -- sqrt(2)/2 * 64 * .5  minus a tiny bit to avoid flicker
        local offset = 20    -- Just enough to fix sorting
        if not bFlipY then
            spriteZ = spriteZ - offset
        else
            spriteZ = spriteZ + offset
        end
    end

    return spriteX,spriteY,spriteZ
end

function EnvObject.getSpriteLocFromTile(propName,tx,ty,bFlipX,bFlipY)
    local wx,wy = g_World._getWorldFromTile(tx,ty)
    return EnvObject.getSpriteLoc(propName,wx,wy,bFlipX,bFlipY)
end

function EnvObject.canFlipX(propName)
    local tData = EnvObject.getObjectData(propName)
    return not tData.bDisallowFlip
end

function EnvObject.canFlipY(propName)
    local tData = EnvObject.getObjectData(propName)
    return tData.bCanFlipY
end

function EnvObject.globalShutdown()
    local tTags = ObjectList.getTagsOfType(ObjectList.ENVOBJECT)
    for _,objData in pairs(tTags) do
        objData.obj:remove()
    end
    EnvObject.tDamagedObjects = {}
    EnvObject.nTotalDecay = 0
    EnvObject.nDamagedObjects = 0
    EnvObject.tObjectsInSpace = {}
end

function EnvObject.globalInit()
    EnvObject.tObjectsInSpace = {}
    EnvObject.tDamagedObjects = {}
    EnvObject.nTotalDecay = 0
    EnvObject.nDamagedObjects = 0
end

function EnvObject:_updateStuffDisplaySprite(idx)
    local tDisplaySlot = self.tDisplaySlots[idx]
    -- Delete props if the item to display has changed or gone away.
    if tDisplaySlot.rProp and (not tDisplaySlot.invKey or tDisplaySlot.invKey ~= tDisplaySlot.rProp.invKey) then
        tDisplaySlot.rProp:removeFromRenderLayer(require('Character').RENDER_LAYER)
        tDisplaySlot.rProp.rEnvObjParent = nil
        tDisplaySlot.rProp = nil
    end

    if not tDisplaySlot.invKey then return end

    -- Create new prop now that we're displaying something.
    -- Or if we already have the prop (and it's correct as noted above) just update loc and be done.
    if not tDisplaySlot.rProp then
        local tItem = self.tInventory[tDisplaySlot.invKey]
        local rProp = Inventory.createDisplayProps(tItem,self.bFlipX)
        if rProp then
            rProp:addToRenderLayer(require('Character').RENDER_LAYER)
            tDisplaySlot.tAmbientLightColor = nil
            tDisplaySlot.rProp = rProp
            rProp.invKey = tDisplaySlot.invKey
            rProp.rEnvObjParent = self
            if rProp.rTintProp then rProp.rTintProp.rEnvObjParent = self end
        end
    end
    
    local rRoom = self:getRoom()
    
    local bTeardown = self:slatedForTeardown()
    
    local tAmbientLightColor = rRoom and rRoom:getEnvObjectColor()
    if (tAmbientLightColor and tDisplaySlot.rProp.tAmbientLightColor ~= tAmbientLightColor) or tDisplaySlot.rProp.bMarkedForTeardown ~= bTeardown then
        if not tAmbientLightColor then tAmbientLightColor = {1,1,1,1} end
        local rV,gV,bV = 1,1,1
        if bTeardown and not tDisplaySlot.rProp.rTintProp then
            rV,gV,bV = unpack(self.pendingVaporizeColor)
        end
        tDisplaySlot.rProp:setColor(tAmbientLightColor[1]*rV,tAmbientLightColor[2]*gV,tAmbientLightColor[3],1*bV)
        
        if tDisplaySlot.rProp.rTintProp then
            local r,g,b = unpack(tDisplaySlot.rProp.rTintProp.tColor)
            r,g,b=r*tAmbientLightColor[1],g*tAmbientLightColor[2],b*tAmbientLightColor[3]
            if bTeardown then
                rV,gV,bV = unpack(self.pendingVaporizeColor)
            end
            
            tDisplaySlot.rProp.rTintProp:setColor(r*rV,g*gV,b*bV,1)
        end
        tDisplaySlot.rProp.tAmbientLightColor = tAmbientLightColor 
        tDisplaySlot.rProp.bMarkedForTeardown = bTeardown
    end
    
    local tPosData = self.tData.tDisplaySlots[idx]
    local x,y,z = self:getLoc()
    if self.bFlipX then
        x = x-tPosData.x
    else
        x = x+tPosData.x
    end
    y=y+tPosData.y
    z=z+tPosData.z
    tDisplaySlot.rProp:setLoc(x,y,z)
end

function EnvObject.createBuildGhost(propName, tx, ty, bFlipX, bFlipY)
    local tData,bPickup = EnvObject.getObjectData(propName)
    local spriteSheet
    if tData.spriteSheetPath then
        spriteSheet = DFGraphics.loadSpriteSheet(tData.spriteSheetPath, false, false, false)
    elseif bPickup then
        spriteSheet = DFGraphics.loadSpriteSheet(require('Pickups.Pickup').spriteSheetPath, false, false, false)
    else
        spriteSheet = DFGraphics.loadSpriteSheet( tData.spriteSheetPath or EnvObject.spriteSheetPath, false, false, false)
    end
    local spriteName = tData.spriteName
    if bFlipX and tData.spriteNameFlipX then
		spriteName = tData.spriteNameFlipX 
    end
	if bFlipY then
		spriteName = spriteName .. EnvObject.sFlipYSuffix
	end
    local prop = MOAIProp.new()
    prop:setDeck(spriteSheet)

    if bFlipX then
        if not tData.bManualFlip then
            prop:setScl(-1,1)
        end
    end

    prop:setIndex(spriteSheet.names[spriteName])
    Renderer.getRenderLayer(require('Character').RENDER_LAYER):insertProp(prop)
    prop:setColor(unpack(EnvObject.ghostColor))
    prop:setLoc(EnvObject.getSpriteLocFromTile(propName, tx, ty,bFlipX,bFlipY))
    return prop
end

-- returns: {sName=rObject, sName=rObject, ...}, nObjects
function EnvObject.getObjectsOfType(sType, bOnlyWorking, bIncludeNonOwned)
	-- "type" here means object name, ie its entry in EnvObjectData
	-- see EnvObject.getObjectsOfFunctionality for the old, er, functionality
	local tObjects = {}
    local tTags = ObjectList.getTagsOfType(ObjectList.ENVOBJECT)
    local n = 0
    for _,objData in pairs(tTags) do
        local obj = objData.obj
		if obj.sName == sType and (obj:isOwnedByPlayer() or bIncludeNonOwned) then
			if not bOnlyWorking or (bOnlyWorking and obj:isFunctioning()) then
                if not obj or not obj.sUniqueName then
                    Trace(TT_Warning, "Object does not have unique name: " .. obj.sName)
                else
                    tObjects[obj.sUniqueName] = obj
                end
                n=n+1
			end
		end
	end
	return tObjects,n
end

function EnvObject.getObjectsOfFunctionality(sFunctionality, bOnlyWorking, bIncludeNonOwned)
	local tObjects = {}
    local tTags = ObjectList.getTagsOfType(ObjectList.ENVOBJECT)
	local n = 0
    for _,tag in pairs(tTags) do
        local obj = tag.obj
		if obj.sFunctionality == sFunctionality and (obj:isOwnedByPlayer() or bIncludeNonOwned) then
			if not bOnlyWorking or (bOnlyWorking and obj:isFunctioning()) then
				table.insert(tObjects, obj)
				n = n + 1
			end
		end
	end
	return tObjects,n
end

function EnvObject.getNumberOfObjects(sType, bOnlyWorking, bIncludeNonOwned)
    local _,n = EnvObject.getObjectsOfType(sType, bOnlyWorking, bIncludeNonOwned)
    return n
end

function EnvObject.destroyBuildGhost(prop)
    Renderer.getRenderLayer(require('Character').RENDER_LAYER):removeProp(prop)
end

function EnvObject.allowObjInRoom(tData,rRoom)
    if tData.noRoom then return true end
    if not rRoom then return false end
    if rRoom.zoneName == tData.zoneName then return true end
    if tData.additionalZones and tData.additionalZones[rRoom.zoneName] then return true end
    return false
end

function EnvObject.createEnvObject(propName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    local rRoom = Room.getRoomAt(wx,wy,0,1)
    local tData = EnvObject.getObjectData(propName)

    if bFlipX and not EnvObject.canFlipX(propName) then
        Print(TT_Warning, "ENVOBJECT.LUA: Prop not allowed to be flipped. Overriding.",propName)
        bFlipX = false
    end

    if bForce or EnvObject.allowObjInRoom(tData,rRoom) then
        -- clear the reservation
		if not rRoom then rRoom = Room.getSpaceRoom() end
		g_World.clearPropReservation(wx, wy, propName, rRoom.id)
		
        -- try to place it.
        local tx, ty = g_World._getTileFromWorld(wx,wy)
        local bFits = g_World._checkPropFit(tx, ty, propName, bFlipX, bFlipY, false)

        if bFits or bForce then
            local rProp = nil
            if tData.customClass then
                rProp = require(tData.customClass).new(propName,wx,wy,bFlipX,bFlipY,bForce, tSaveData, nTeam)
            else
                rProp = EnvObject.new(propName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
            end
            -- Some envobjects create their activityoptionlist in envobject:init, after calling the superclass init,
            -- meaning their option list needs to be updated once more.
            if rProp then rProp:updateActivityOptionList() end

            return rProp
        else
            Print(TT_Warning,'ENVOBJECT.LUA: Failed to build prop.',propName,wx,wy)
            return
        end
    end
end

function EnvObject:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    self.layer = require('Character').RENDER_LAYER
    self.tData = EnvObject.getObjectData(sName)

    if self.tData.bInventory then
        self.tInventory = (tSaveData and tSaveData.tInventory) or {}
        for sItemName, tItem in pairs(self.tInventory) do    
            self.tInventory[sItemName] = Inventory.portFromSave(sItemName, tItem)
        end
        if self.tData.tDisplaySlots then
            self.tDisplaySlots = {}
            for i,v in ipairs(self.tData.tDisplaySlots) do
                table.insert(self.tDisplaySlots, {idx=i})
            end
        end
    end

    self.nVisibility = g_World.VISIBILITY_FULL
	
	self.bSlatedForResearchTeardown = false
	-- "can demolish" defaults true
	self.bCanDemolish = true
	if self.tData.bCanDemolish == false then
		self.bCanDemolish = false
	end
	
	-- by default a thing is attackable
	self.bAttackable = self.tData.bAttackable
	if self.bAttackable == nil then
		self.bAttackable = true
	end
	
    self.bFlipX,self.bFlipY = bFlipX,bFlipY
    self.tag = ObjectList.addObject(ObjectList.ENVOBJECT, sName, self, tSaveData, self.tData.bBlocksPathing, self.tData.bBlocksOxygen, nil, nil, false)
    self.nTeam = nTeam or Character.TEAM_ID_PLAYER

    self.sCustomInspector = self.tData.customInspector
    assert(self.tData)
    self.decayPerSecond = self.tData.decayPerSecond or 0

    if self.decayPerSecond > 0 then
        EnvObject.nTotalDecay = EnvObject.nTotalDecay + self.decayPerSecond
    end
	
	-- activated/deactivated (player controlled in command tab)
	self.bActive = true
	
    self.sName = sName
    self.sFunctionality = self.tData.sFunctionality or sName
    self.sUniqueName = sName .. EnvObject.propCounter
    EnvObject.propCounter = EnvObject.propCounter + 1
	self.sBuilderName = nil -- set proper from BuildEnvObject
	self.sBuildTime = '????.??' -- only base seed should show this
	self.sLastMaintainer = nil
	self.sLastMaintainTime = 'n/a'
	self.nBrokenTimer = 0
    self.sFriendlyName = g_LM.line(self.tData.friendlyNameLinecode)
    self.sDescription = g_LM.line(self.tData.description)

    self.lastUpdate = GameRules.simTime
    self.activityOptionList = ActivityOptionList.new(self)
	self.enemyActivityOptionList = ActivityOptionList.new(self)
	
    self.spriteSheet = DFGraphics.loadSpriteSheet( self.tData.spriteSheetPath or self.spriteSheetPath )
    self:setDeck(self.spriteSheet)
    self.spriteName = self.tData.spriteName
    
    if self.tData.portrait then
        self.sPortrait = self.tData.portrait
    else
        self.sPortrait = 'portrait_generic'
    end    
    self.sPortraitPath = self.tData.sPortraitPath or 'UI/Portraits'
    self.bUsePortraitOffsetHack = self.sPortraitPath == 'Environments/Objects'
    if self.tData.bUsePortraitOffsetHack ~= nil then
        self.bUsePortraitOffsetHack = self.tData.bUsePortraitOffsetHack
    end
    
    --start object ambience
    if self.tData.ambientSound then self.ambientSound = SoundManager.playSfx3D(self.tData.ambientSound, wx, wy, 0) end
    
    if bFlipX then
        if not self.tData.bManualFlip then
            self:setScl(-1,1)
        end
    end
    
    if self.spriteName then
		if self.bFlipY then
			self.spriteName = self.spriteName .. EnvObject.sFlipYSuffix
		end
        for i=1,#EnvObject.tConditions do
            DFGraphics.alignSprite(self.spriteSheet, self.spriteName..EnvObject.tConditions[i].sSuffix, "left", "bottom")
        end
    end
    
    -- move this prop and any lighting props
    self:setLoc(wx,wy)
	
	-- "low power" icon
	if self.tData.nPowerDraw or self.tData.nPowerOutput then
		self.rPowerIcon = MOAIProp.new()
		local spriteSheet = DFGraphics.loadSpriteSheet('UI/UIMisc', false, false, false)
		self.rPowerIcon:setDeck(spriteSheet)
		self.rPowerIcon:setIndex(spriteSheet.names['no_power'])
        self.rPowerIcon:setColor( unpack(Gui.RED) )
		if self.tData.tIconOffset then
			self:setIconOffset(unpack(self.tData.tIconOffset))
		else
			self:setIconOffset(unpack(EnvObject.DEFAULT_ICON_OFFSET))
		end
		Renderer.getRenderLayer(self.layer):insertProp(self.rPowerIcon)
		self.rPowerIcon:setVisible(false)
	end
	
    self:_updateRoomAssignment()
    
    self:_setCondition(100)
	self.nLastSparkTime = GameRules.simTime
	
    Renderer.getRenderLayer(self.layer):insertProp(self)
        
    if self.tData.oxygenLevel and not self:shouldDestroy() then
        self.bGeneratingOxygen = true
        require('Oxygen').addGenerator(wx,wy,self.tData.oxygenLevel)
    end
end

function EnvObject:canDeactivate()
    if not self.tData or not self.tData.bCanDeactivate then return false end
    if not self:getRoom() then return true end
    if self:getTeam() ~= Character.TEAM_ID_PLAYER then return false end
    if self:_isSabotaged() then return false end
    return true
end

function EnvObject:getVisibility()
    local r = self:getRoom()
    if r then
        return r:getVisibility()
    else
        return g_World.VISIBILITY_FULL
    end
end

function EnvObject:getFlavorText()
    return self.tData.sFlavorText and g_LM.line(self.tData.sFlavorText)
end

function EnvObject:getTeam()
    if self.rRoom and self.rRoom ~= Room.getSpaceRoom() then
        return self.rRoom:getTeam()
    else
        return self.nTeam
    end
end

function EnvObject.flipToFacing(bFlipX,bFlipY)
    if bFlipY then
        return (bFlipX and g_World.directions.NW) or g_World.directions.NE
    else
        return (bFlipX and g_World.directions.SW) or g_World.directions.SE
    end
end

function EnvObject:getFacing()
    return EnvObject.flipToFacing(self.bFlipX,self.bFlipY)
end

function EnvObject:onInteract(bStart,rChar)
    if self.tData.interactSprite then
        self.bUseInteractSprite = bStart
        self:_setCondition(self.nCondition)
    end
    if not bStart and self.rUser then
        assertdev(self.rUser == rChar)
    end
    
    if bStart and self.rUser then
        Print(TT_Error, "ENVOBJECT.LUA: New user A clobbering old user B",rChar.tStats.sUniqueID,self.rUser.tStats.sUniqueID)
    end
    
    self.rUser = (bStart and rChar) or nil
end

function EnvObject:getUser()
    return self.rUser
end

function EnvObject:getMaladies()
    return self.tMaladies
end

function EnvObject:getTileInFrontOf(bBehind)
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    local facing = self:getFacing()
    if bBehind then facing = g_World.oppositeDirections[facing] end
    return g_World._getAdjacentTile(tx,ty, facing)
end

function EnvObject:getTilesInFrontOf(bBehind)
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    local facing = self:getFacing()
    if bBehind then facing = g_World.oppositeDirections[facing] end
    local tTiles = {}
    local walkDir = g_World.directions.NE
    if facing == g_World.directions.SW then
        walkDir = g_World.directions.NW
    end

    if bBehind then
        for i=2,self.tData.height do
            tx,ty = g_World.getAdjacentTile(tx,ty,facing)
        end
    end

    for i=1,self.tData.width do
        local ax,ay = g_World._getAdjacentTile(tx,ty, facing)
        local addr = g_World.pathGrid:getCellAddr(ax,ay)
        tTiles[addr] = {x=ax,y=ay,addr=addr}
        tx,ty = g_World.getAdjacentTile(tx,ty,walkDir)
    end
    return tTiles
end

function EnvObject:isHostileTo(rChar)
    return false
end

function EnvObject:getWorldInFrontOf(bBehind)
    return g_World._getWorldFromTile(self:getTileInFrontOf(bBehind))
end

function EnvObject:getFootprint(bMargin,bIndexByAddr)
    local tx,ty = self:getTileLoc()
    return g_World._getPropFootprint(tx,ty, self.sName, bMargin, self.bFlipX, self.bFlipY,bIndexByAddr)
end

function EnvObject:getTileCoords()
    return g_World._getTileFromWorld(self:getLoc())
end

function EnvObject:getRoom()
    return self.rRoom
end

function EnvObject:onAddedToRoom(rRoom)
    self:lightingChanged()
end

function EnvObject:lightingChanged(rRoom)
    if rRoom then 
        if Lighting.bEnable then
            local tAmbientLightColor = rRoom:getEnvObjectColor()
            self:setBaseColor(tAmbientLightColor[1], tAmbientLightColor[2], tAmbientLightColor[3])
            self:_refreshDisplaySlots()
        end
    end
end

function EnvObject:setBaseColor(r,g,b)
    self.baseColor = {r, g, b, 1.0}
    if self:slatedForTeardown(false,true) then
        self:setColor(unpack(self.pendingVaporizeColor))
    else
        self:setColor(r,g,b,1.0)
    end
end

-- this object is going to be destroyed, so don't use it.
function EnvObject:slatedForTeardown(bResearchOnly,bDemolishOnly)
    if bResearchOnly then return self.bSlatedForResearchTeardown end
    if bDemolishOnly then return self.bSlatedForVaporize or self:shouldDestroy() end
    return self.bSlatedForResearchTeardown or self.bSlatedForVaporize or self:shouldDestroy()
end

function EnvObject:setSlatedForDemolition(bSlated)
    self.bSlatedForVaporize=bSlated
    self:_refreshDisplaySlots()
    self:unHover()
end

function EnvObject:addItem(tData)
--    print('EnvObject '..self.sName..' picked up a new: '..tData.sName)
    if self.tInventory[tData.sName] then
        self.tInventory[tData.sName].nCount = self.tInventory[tData.sName].nCount + (tData.nCount or 1)
    else
        self.tInventory[tData.sName] = tData
        tData.tContainer = ObjectList.getTag(self)
    end
    self:_refreshDisplaySlots()
end

function EnvObject:destroyItem(sObjectKey,nCount)
    local tItem = self:_removeItem(sObjectKey,nCount)
    local tTag = ObjectList.getTag(tItem)
    if tTag then 
        ObjectList.removeObject(tTag) 
    end
end

function EnvObject:dropItemOnFloor(sObjectKey,nCount,wx,wy)
    local tItem = self:_removeItem(sObjectKey,nCount)
    if not wx then
        wx,wy = self:getLoc()
    end
    if tItem then
        local rPickup = require('Pickups.Pickup').dropInventoryItemAt(tItem,wx,wy)
        return rPickup,tItem
    end
end

function EnvObject:transferItemTo(rDestObj,sObjectKey,nCount)
    local tItem = self:_removeItem(sObjectKey,nCount)
    if not tItem then return end
    local sObjType = ObjectList.getObjType(rDestObj)

    if sObjType == ObjectList.CHARACTER then
        rDestObj:pickUpItem(tItem)
    elseif sObjType == ObjectList.ENVOBJECT then
        rDestObj:addItem(tItem)
    else
        -- MTF NOTE: we could implement INVENTORYITEM and WORLDOBJECT if necessary
        assertdev(false)
    end
    return tItem
end

-- nCount specifies how many to remove. Default is "all".
function EnvObject:_removeItem(sObjectKey,nCount)
    local tItem = Inventory.removeItemFromContainer(self.tInventory,sObjectKey,nCount)
    if tItem then tItem.tContainer = nil end
    self:_refreshDisplaySlots()
    return tItem
end

function EnvObject:getDisplayingChar()
    if not self.tDisplaySlots then return nil end
    if self.nItemsDisplayed == 0 then return nil end
    for idx,data in ipairs(self.tDisplaySlots) do
        local obj = self.tInventory[data.invKey]
        if obj then
            local rOwner = Inventory.getOwner(obj)
            if rOwner then return rOwner end
        end
    end
    return nil
end

function EnvObject:numOpenDisplaySlots()
    if not self.tDisplaySlots then return 0 end
    return #self.tDisplaySlots - self.nItemsDisplayed
end

function EnvObject:_refreshDisplaySlots()
    if not self.tDisplaySlots then return end
    self.nItemsDisplayed = 0

    local tProcessed={}
    -- Clear out stale displays, and re-count # of items displayed.
    for idx,data in ipairs(self.tDisplaySlots) do
        local invKey = data.invKey
        if not invKey then
            -- NOTHING
        elseif not self.tInventory[invKey] or tProcessed[invKey] then 
            data.invKey = nil
            tProcessed[invKey] = true
        else
            --tProcessed[invKey] = true
            tProcessed[invKey] = true
            self.nItemsDisplayed = self.nItemsDisplayed+1
        end
    end

    -- Look for new items that can be displayed, and mark them for display.
    for objKey,tItem in pairs(self.tInventory) do
        if self.nItemsDisplayed >= #self.tDisplaySlots then break end
        if not tProcessed[objKey] then
            local sDisplaySprite = Inventory.getDisplaySprite(tItem)
            if sDisplaySprite then
                for idx,displayData in ipairs(self.tDisplaySlots) do
                    if not displayData.invKey then
                        displayData.invKey = objKey
                        self.nItemsDisplayed=self.nItemsDisplayed+1
                        break
                    end
                end
            end
        end
    end

    -- Add sprites for new displays.
    for idx,_ in ipairs(self.tDisplaySlots) do
        self:_updateStuffDisplaySprite(idx)
    end
end

function EnvObject:getSaveTable(xShift,yShift)
    local tInventory = self.tInventory
    
    xShift = xShift or 0
    yShift = yShift or 0
    -- don't use IDs. needs to work with modules.
    return {wx=self.wx+xShift,wy=self.wy+yShift, condition=self.nCondition, name=self.sName, bActive=self.bActive,
        uniqueName=self.sUniqueName, bFlipX=self.bFlipX,  bFlipY=self.bFlipY, nStackCount=self.nStackCount,
		sBuilderName=self.sBuilderName, sBuildTime=self.sBuildTime, nBrokenTimer=self.nBrokenTimer,
		sLastMaintainer=self.sLastMaintainer, sLastMaintainTime=self.sLastMaintainTime, sFriendlyName=self.sFriendlyName,
		tInventory=tInventory, sResearchData=self.sResearchData, bSlatedForResearchTeardown=self.bSlatedForResearchTeardown, 
        nDecayResume=self.nDecayResume, nDecayMult=self.nDecayMult,
        tMaladies=self.tMaladies}
end

function EnvObject.fromSaveTable(t, xOff, yOff, nTeam)
    local tData,bPickup = EnvObject.getObjectData(t.name)
    
    if not tData then
        -- Probably an object that used to exist, from an old savegame.
        return nil
    end
    
    local eo = nil

    if bPickup then
        eo = require('Pickups.Pickup').createPickupAt(t.name, t.wx+(xOff or 0),t.wy+(yOff or 0), t, nTeam)
    else
        eo = EnvObject.createEnvObject(t.name,t.wx+(xOff or 0),t.wy+(yOff or 0), t.bFlipX, t.bFlipY, true, t, nTeam)
    end
    if eo then
		if t.bActive == nil then
			eo.bActive = true
		else
			eo.bActive = t.bActive
		end
        eo:_setCondition(t.condition or 100)
        eo.sUniqueName = t.uniqueName
        eo.tMaladies = t.tMaladies
        eo.sBuilderName = t.sBuilderName
        eo.sBuildTime = t.sBuildTime
        eo.nBrokenTimer = t.nBrokenTimer or 0
        eo.sLastMaintainer = t.sLastMaintainer
        eo.sLastMaintainTime = t.sLastMaintainTime
        if t.sFriendlyName then        
            eo.sFriendlyName = t.sFriendlyName
        end
        eo.bSlatedForResearchTeardown = t.bSlatedForResearchTeardown
        eo.nDecayResume = t.nDecayResume
        eo.nDecayMult = t.nDecayMult

        if g_World.bLoadingModule and tData.GenerateStartingInventory and next(eo.tInventory) == nil then
            --eo:_generateStartingInventory()
        end
    end
    return eo
end

--[[
function EnvObject:postLoad()
    if self.tTempInventory then
        for k,v in pairs(self.tTempInventory) do
            self.tInventory[k] = ObjectList.getObj(v)
        end
    end
end
]]--

function EnvObject:blocksOxygen()
    return false
end

function EnvObject:getLoc()
    return self.wx,self.wy,self.wz,self.nLevel
end

function EnvObject:getTileLoc()
    local tx, ty = g_World._getTileFromWorld(self:getLoc())
    return tx,ty,1
end

function EnvObject:getUniqueName()
    return self.sUniqueName
end

function EnvObject:getUniqueID()
    return self.sUniqueName
end

function EnvObject:getDescription()
    return self.sDescription 
end

function EnvObject:getBuilderName()
	local sBuilder = CharacterManager.getCharacterByUniqueID(self.sBuilderName)
	if not sBuilder then
		-- return default "UNKNOWN"
		return self.sBuilderName or "UNKNOWN"
	else
		return sBuilder.tStats.sName
	end
end

function EnvObject:getMaintainerName()
	local sMaintainer = CharacterManager.getCharacterByUniqueID(self.sLastMaintainer)
	if not sMaintainer then
		return self.sLastMaintainer or "UNKNOWN"
	else
		return sMaintainer.tStats.sName
	end
end

function EnvObject:setLoc(x,y,nLevel)
    self.wx, self.wy = x,y
    self.nLevel = nLevel or 1

    local spriteX,spriteY,spriteZ = EnvObject.getSpriteLoc(self.sName,x,y,self.bFlipX,self.bFlipY)
    local bOccupied = ObjectList.occupySpace(x,y,self.tag,self.bFlipX,self.bFlipY)
    assert(bOccupied)
    
    if self.bSortBack or self.tData.bSortBack then
        spriteZ = spriteZ - 100
    elseif self.bSortDownOneTile then
        spriteZ = spriteZ + 100
    end
    
    self.wz = spriteZ
    self._UserData:setLoc(spriteX,spriteY,spriteZ)
    self:_refreshDisplaySlots()
    self:_updateRoomAssignment()
end

function EnvObject:_updateRoomAssignment()
    local x,y,z = self:getLoc()
    local rRoom, _, bOnWall = require('Room').getRoomAt(x,y,z,self.nLevel,true)
    if bOnWall then
        -- If the prop is on a wall, we want to see what room it's facing toward.
        -- If nothing, then we'll assign it to space room.
        local tx,ty,tw = self:getTileLoc()
        local dir = self:getFacing()
        local tWall = Room.getWallAtTile(tx,ty,tw)
        if tWall and tWall.tDirs[dir] then
            rRoom = Room.tRooms[ tWall.tDirs[dir] ]
        else
            rRoom = nil
        end
    end
    if not rRoom and (self.tData.bCanBuildInSpace or self.bPickup) then
        local nTileValue = g_World._getTileValue(self:getTileLoc())
        if nTileValue == g_World.logicalTiles.SPACE or nTileValue == g_World.logicalTiles.WALL or nTileValue == g_World.logicalTiles.WALL_DESTROYED then
            rRoom = Room.getSpaceRoom()
        end
    end

    if self.rRoom ~= rRoom then
        if self.rPowerRoom then
            if not self.rPowerRoom.bDestroyed and self.rPowerRoom.zoneObj then
                self.rPowerRoom.zoneObj:powerUnrequest(self)
            end
            --self.rPowerRoom = nil
        end
        if self.rRoom then
            self.rRoom:removeProp(self)
        end
        if rRoom then
            rRoom:addProp(self)
        end
        self.rRoom = rRoom
    end
end

function EnvObject:takeDamage(rSource, tDamage)
    local nDamageReduction = 0
    if tDamage.nDamageType == Character.DAMAGE_TYPE.Laser then
        nDamageReduction = .5
    elseif tDamage.nDamageType == Character.DAMAGE_TYPE.Acid then
        nDamageReduction = .25
    end
	if g_GameRules.bFriendliesInvincible and self:isOwnedByPlayer() then
		nDamageReduction = 1
	end
    local nDamage = tDamage.nDamage * (1-nDamageReduction)
    self:_setCondition(self.nCondition-nDamage)
end

function EnvObject:isDead()
    return self.nCondition == 0
end

function EnvObject:getPowerDraw()
    return (self.bActive and self.nCondition > 0 and self.tData.nPowerDraw) or 0
end

-- Some special-case pri elevations.
function EnvObject:getMaintainPriority(rChar,nOriginalPri)
    if self.sName == 'OxygenRecycler' then
        -- Broken o2 cyclers return the character's current threat level as priority, in case the low o2 is 
        -- the thing causing high threat.
        if self.nCondition == 0 then
            return rChar.nThreat
        end
    end
    return nOriginalPri
end

-- prioritize busted stuff
function EnvObject:getMaintainUtility(rChar,nOriginalUtility)
    local adjust = .5 - self.nCondition / 100
    return nOriginalUtility + nOriginalUtility * adjust
end

function EnvObject:updateActivityOptionList()
    local tActivities
    
    if self:shouldDestroy() then
        tActivities = {}
        table.insert(tActivities, g_ActivityOption.new('DestroyEnvObject', { rTargetObject=self,
                utilityGateFn=function(rChar,rAO) return EnvObject.gateJobActivity(rAO.tData.rTargetObject.sName, rChar, true, rAO.tData.rTargetObject) end, 
        }))
    elseif self:slatedForTeardown(false,true) then
        tActivities = {}
    else
        if self:isFunctioning() then
            tActivities = self:getAvailableActivities()
        else
            tActivities = {}
        end
        self:_addMaintenanceActivities(tActivities)
    end
    self.activityOptionList:set(tActivities)
	
	local tEnemyActivities = self:getAvailableEnemyActivities()
	if tEnemyActivities then
		self.enemyActivityOptionList:set(tEnemyActivities)
	end
end

function EnvObject:getAvailableEnemyActivities()
	return {}
end

function EnvObject:_addMaintenanceActivities(tActivities)
    -- The test for decayPerSecond keeps some of the clutter out of the option lists, by excluding objects that don't
    -- decay normally. But since they can still be damaged, we have to add them when their condition drops low.
    if self.decayPerSecond > 0 or self.nCondition <= EnvObject.CONDITION_NEEDED_TO_MAINTAIN then
        table.insert(tActivities, g_ActivityOption.new('MaintainEnvObject', { rTargetObject=self, 
            utilityGateFn=function(rChar,rAO) 
                if self.bSlatedForVaporize then return false, 'object slated for vaporization' end
                if self.nCondition > EnvObject.CONDITION_NEEDED_TO_MAINTAIN then return false,'object healthy' end
                return EnvObject.gateJobActivity(rAO.tData.rTargetObject.sName, rChar, false, rAO.tData.rTargetObject) 
            end, 
            priorityOverrideFn=function(rChar,rAO,nOriginalPri) return self:getMaintainPriority(rChar,nOriginalPri) end,
            utilityOverrideFn=function(rChar,rAO,nOriginalUtility) return self:getMaintainUtility(rChar,nOriginalUtility) end,
            tagOverrideFn=function(rChar,rAO,sTagName)
                if sTagName == 'DestSafe' and self:getMaintainPriority(rChar,OptionData.tPriorities.NORMAL) > OptionData.tPriorities.NORMAL then
                    return false
                end
                if sTagName == 'Job' then
                    return self.tData.maintainJob or Character.TECHNICIAN
                end
            end,
        } ))
    end
end

function EnvObject:getAvailableActivities()
    local tActivities = {}
    if self.tDisplaySlots then
        table.insert(tActivities, g_ActivityOption.new('DisplayInventoryItem', { rTargetObject=self, 
            utilityGateFn=function(rChar,rAO) 
                if not rChar:getDisplayItem() then return false, 'nothing to display' end
                if self.nItemsDisplayed >= #self.tDisplaySlots then return false, 'display slots full' end
                if self.bSlatedForVaporize then return false, 'object slated for vaporization' end
                if self.nCondition == 0 then return false, 'object broken' end
                if not rChar:canUseDresser(self) then return false, 'character not a match for the dresser' end
                return true
            end, 
            priorityOverrideFn=function(rChar,rAO,nOriginalPri) return self:getMaintainPriority(rChar,nOriginalPri) end,
            utilityOverrideFn=function(rChar,rAO,nOriginalUtility) return self:getMaintainUtility(rChar,nOriginalUtility) end,
        } ))
    end

    self:_addInvItemOptions(tActivities)
    
    if self.tData.inherentActivities then
            for _,name in pairs(self.tData.inherentActivities) do
                local tData = { rTargetObject=self }
                tData.utilityGateFn=
                    function(rChar, rThisActivityOption)
                        if not self.rRoom or self.rRoom:isDangerous(rChar) then 
                            return false, 'dangerous room' 
                        end
                        if self.rRoom and self.rRoom:getZoneName() == 'BRIG' and not rChar:inPrison() then
                            return false, 'character not in prison'
                        end
                        return true
                    end
                table.insert(tActivities, g_ActivityOption.new(name, tData))
            end
    end
    return tActivities
end

function EnvObject:_addInvItemOptions(tActivities)
    if self.tInventory then
        for k,tItem in pairs(self.tInventory) do
            if Inventory.isStuff(tItem) then
                -- "acquire this thing"
                table.insert(tActivities, g_ActivityOption.new('PickUpStuff', { rTargetObject=self, sObjectKey=k,
                        utilityGateFn=EnvObject.gatePickUpStuff,
                        utilityOverrideFn=EnvObject.stuffUtility,
                        } ))
            end
        end
    end
end

function EnvObject:onFire()
    if self.nCondition ~= 0 then
        self.bCaughtFire = true
        self:_setCondition(0)
    end
end

function EnvObject:_shouldGenerateOxygen()
    return self.tData.oxygenLevel and not self:shouldDestroy() and self:isFunctioning()
end

-- This used to be a way to tick objects in space.
-- Now with spaceroom, we don't need it.
function EnvObject.staticTick()
    --[[
    for rObj,_ in pairs(EnvObject.tObjectsInSpace) do
        rObj:onTick()
    end
    ]]--
end

function EnvObject:getWallTile()
    if not self.tData.againstWall then return nil end
    return self:getTileInFrontOf(true)
end

function EnvObject:onTick()
    local diff = GameRules.simTime - self.lastUpdate

    -- tick condition down once per second.
    if diff <= 1 then
		return
	end
    
    -- rPowerRoom is only for objects on walls in space, that get individually-assigned power.
    -- If we have a room, we no longer need to get power through this custom path.
    if self.rRoom and self.rRoom ~= g_SpaceRoom and self.rPowerRoom and self.rPowerRoom.zoneObj then
        self.rPowerRoom.zoneObj:powerUnrequest(self)
        --self.rPowerRoom = nil
    end
    
	self.lastUpdate = GameRules.simTime
	local oldc = self.nCondition
	-- MTF HACK TODO:
	-- EnvObjects need to be rewritten to always add their activities, and then gate appropriately.
	-- Right now most of them add their activities based on a variety of conditions.
	-- So we need to call updateActivityOptionList regularly, for now.
	-- Note: damageCondition calls updateActivityOptionList.
    local bUpdate = true
	if self:isFunctioning() and self.rRoom and self.rRoom:getVisibility() ~= g_World.VISIBILITY_HIDDEN then
		if self.decayPerSecond > 0 and not GameRules.inEditMode then
            if self.nDecayResume then
                if self.nDecayResume < GameRules.elapsedTime then
                    self.nDecayResume = nil
                end
            else
			    self:damageCondition((self.nDecayMult or 1) * self.decayPerSecond * math.floor(diff))
			    bUpdate = false
            end
		end
    end
    if bUpdate then
        self:updateActivityOptionList()
    end
	
	-- show/hide "no power" icon
	if self.rPowerIcon then
		-- always-on if object is deactivated
		if not self.bActive then
			self.rPowerIcon:setVisible(true)
		else
			self.rPowerIcon:setVisible(false)
			if not self:hasPower() then
				-- make it blink
				local nBlink = math.abs(math.sin(GameRules.elapsedTime * 200))
				if nBlink > 0.5 then
					self.rPowerIcon:setVisible(true)
				end
			end
		end
	end
	
	-- spark if condition is in the "danger zone"
	if self:hasPower() and self.nCondition <= EnvObject.DANGER_ZONE and GameRules.simTime - self.nLastSparkTime > EnvObject.DANGER_SPARK_FREQUENCY then
		self.nLastSparkTime = GameRules.simTime
		local wx, wy = self:getLoc()
		Effect.new(EnvObject.sSparkFX, wx, wy, nil, nil, {0,64,0})
	end

	if self.decayPerSecond > 0 and self:hasPower() then
		if self:getTeam() ~= Character.TEAM_ID_PLAYER then
			if EnvObject.tDamagedObjects[self] then
				EnvObject.tDamagedObjects[self] = nil
				EnvObject.nDamagedObjects = EnvObject.nDamagedObjects - 1
			end
		elseif self.nCondition <= EnvObject.DAMAGED_CONDITION then
			if not EnvObject.tDamagedObjects[self] then
				EnvObject.tDamagedObjects[self] = 1
				EnvObject.nDamagedObjects = EnvObject.nDamagedObjects + 1
			end
		else
			if EnvObject.tDamagedObjects[self] then
				EnvObject.tDamagedObjects[self] = nil
				EnvObject.nDamagedObjects = EnvObject.nDamagedObjects - 1
			end
		end
	end
	
	-- chance for object to catch fire if condition is at zero long enough
	if self:isDead() and self:hasPower() then
		self.nBrokenTimer = self.nBrokenTimer + diff
		-- initial wait has passed
		if self.nBrokenTimer > EnvObject.DESTROYED_FIRE_CHECK_DELAY then
			-- time to check
			if self.tData.explodeOnFailure and self.nBrokenTimer > EnvObject.DESTROYED_FIRE_CHECK_DELAY + EnvObject.DESTROYED_FIRE_CHECK_INTERVAL then
				if math.random() < EnvObject.DESTROYED_FIRE_CHANCE and not self.bCaughtFire then
					self:_dieInAFire()
				end
				-- reset counter
				self.nBrokenTimer = EnvObject.DESTROYED_FIRE_CHECK_DELAY
			end
		end
	end
	
	if self.bGeneratingOxygen and not self:_shouldGenerateOxygen() then
		require('Oxygen').removeGenerator(self:getLoc())
		self.bGeneratingOxygen=false
	elseif not self.bGeneratingOxygen and self:_shouldGenerateOxygen() then
		self.bGeneratingOxygen = true
		local wx,wy = self:getLoc()
		require('Oxygen').addGenerator(wx,wy,self.tData.oxygenLevel)
	end
	
	if self.tMaladies then
		for sName,tMaladyData in pairs(self.tMaladies) do
			if tMaladyData.nEndTime < GameRules.elapsedTime then
				self.tMaladies[sName] = nil
			end
		end
		if not next(self.tMaladies) then
			self.tMaladies = nil
		end
	end
end

function EnvObject:getEmergencyString()
    if self:_isSabotaged() then
        local nDuration = self.nTempPowerLossEnd - GameRules.elapsedTime
        return g_LM.line('INSPEC170TEXT') ..' ('..MiscUtil.formatTime(nDuration)..')'
    end
end

function EnvObject:getThreatLevel()
    return Character.THREAT_LEVEL.None
end

function EnvObject:_isSabotaged()
    if self.nTempPowerLossEnd then
        if self.nTempPowerLossEnd < GameRules.elapsedTime then
            self.nTempPowerLossEnd = nil
        else
            return true
        end
    end
    return false
end

function EnvObject:hasPower()
    return self.bActive and (not self.tData.nPowerDraw or self.tData.nPowerDraw == 0 or (not self:_isSabotaged() and (self.bHasPower or g_PowerHoliday)))
end

function EnvObject:isFunctioning()
    assertdev(self.nCondition ~= nil)
	return self:hasPower() and self.nCondition and self.nCondition > 0 and not self.bDestroyed
end

function EnvObject:sabotagePowerLoss()
    self.nTempPowerLossEnd = GameRules.elapsedTime + (self.tData.nSabotageDuration or EnvObject.DEFAULT_SABOTAGE_DURATION)
end

function EnvObject:_getCurConditionTextureSuffix()
    local suffix = ''
    for i=1,#EnvObject.tConditions do
        if self.nCondition < EnvObject.tConditions[i].nBelow then
            suffix = EnvObject.tConditions[i].sSuffix
        end
    end
    return suffix
end

function EnvObject:slateForResearchTeardown(bSlated)
	self.bSlatedForResearchTeardown = bSlated
    self:_refreshDisplaySlots()
end

function EnvObject:getCustomInspectorName()
    return self.tData.customInspector
end

function EnvObject:_setCondition(c)
    self.nCondition = c
    if self.nCondition < 1 then
        self.nCondition = 0

        if self.tData.oxygenLevel and self.bGeneratingOxygen then
            self.bGeneratingOxygen = false
            require('Oxygen').removeGenerator(self:getLoc())
        end
    else
        self.bCaughtFire = false
    end
    local suffix = self:_getCurConditionTextureSuffix()
    if self.spriteName then
        local spriteName = self.spriteName .. suffix
        local index = self.spriteSheet.names[spriteName] 
        if index then
            if self.bUseInteractSprite then
                self:setIndex(self.spriteSheet.names[self.tData.interactSprite])
            else
                self:setIndex(index)
            end
            if self.rShadowProp then
                self.rShadowProp:setIndex(index)
            end
        end
    end
    
    self:updateActivityOptionList()

    if self.onConditionSet then
        self:onConditionSet()
    end
end

function EnvObject:damageCondition(amt, bMaintainFailure)
    self:_setCondition(math.max(0, self.nCondition - amt))
    if self.nCondition < 1 then
        if self.tData.explodeOnFailure and math.random() < self.PROBABILITY_FIRE_ON_DESTROY then
            self:_dieInAFire()
            return true
        end
        if self.ambientSound and self.ambientSound:isValid() then
            self.ambientSound:stop()
            self.ambientSound = nil
        end
    else
        if not self.ambientSound and self.tData.ambientSound then
            self.ambientSound = SoundManager.playSfx3D(self.tData.ambientSound, self.wx, self.wy, 0)
        end
        if bMaintainFailure then
            if self.nCondition <= EnvObject.DANGER_ZONE and self.tData.explodeOnFailure then
                if math.random() < EnvObject.PROBABILITY_FIRE_ON_DANGER_ZONE_MAINTAIN_FAILURE then
                    self:_dieInAFire()
                    return true
                end
            end
        end
    end
end

function EnvObject:_dieInAFire()
    self.nCondition=0
    local Fire=require('Fire')
    Fire.startFire(self.wx,self.wy)
    g_World.playExplosion(self:getLoc())
end

function EnvObject:maintain(conditionAtStartOfMaintain, nMaintainerCompetence)
    -- little hack: give back the object's condition that decayed during maintenance.
    if conditionAtStartOfMaintain and self.nCondition < conditionAtStartOfMaintain then
        self.nCondition = conditionAtStartOfMaintain
    end
    
    -- condition improved based on maintainer competence
    local nConditionRaised = DFMath.lerp(EnvObject.MIN_PCT_HEALED_PER_MAINTAIN, EnvObject.MAX_PCT_HEALED_PER_MAINTAIN, nMaintainerCompetence)

    if Base.hasCompletedResearch('MaintenanceLevel2') then
        nConditionRaised = nConditionRaised * ResearchData['MaintenanceLevel2'].nConditionMultiplier
    end

    local newCondition = math.min(self.nCondition+nConditionRaised, 100)
    local nImprovement = newCondition - self.nCondition
    self:_setCondition(newCondition)
    return nImprovement
    --print('Object',self.sName,'was maintained up to condition',self.nCondition)
end

function EnvObject:preventDecayFor(nSeconds)
    self.nDecayResume = GameRules.elapsedTime+nSeconds
end

-- return true if the envobject requires a certain zone and we're not in that zone.
function EnvObject:shouldDestroy()
    if self.bDestroyed or not self.rRoom or self:getTeam() ~= Character.TEAM_ID_PLAYER then return false end
    if not EnvObject.allowObjInRoom(self.tData,self.rRoom) then return true end
    return false
end

function EnvObject:isDoor()
    return false
end

function EnvObject:vaporize()
    self:remove()
end

function EnvObject:remove()
    if self.bDestroyed then return end
    
    if self.ambientSound then
        self.ambientSound:stop()
        self.ambientSound = nil
    end
    
    self.bDestroyed = true
    self.nCondition = 0
    
    if self.tInventory then
        while next(self.tInventory) do
            local sKey = next(self.tInventory)
            self:destroyItem(sKey)
        end
    end
    
    if self.rPowerRoom and self.rPowerRoom.zoneObj then
        self.rPowerRoom.zoneObj:powerUnrequest(self)
        --self.rPowerRoom = nil
    end
    if self.rPowerIcon then
		self.rPowerIcon:setVisible(false)
 		Renderer.getRenderLayer(self.layer):removeProp(self.rPowerIcon)
        self.rPowerIcon = nil
    end
   
    if self.tData.oxygenLevel and self.bGeneratingOxygen then
        self.bGeneratingOxygen = false
        require('Oxygen').removeGenerator(self:getLoc())
    end
    if EnvObject.tDamagedObjects[self] then
        EnvObject.tDamagedObjects[self] = nil
        EnvObject.nDamagedObjects = EnvObject.nDamagedObjects - 1
    end
    if self.decayPerSecond > 0 then
        EnvObject.nTotalDecay = EnvObject.nTotalDecay - self.decayPerSecond
    end

    ObjectList.removeObject(self.tag)
    self.tag=nil
    Renderer.getRenderLayer(self.layer):removeProp(self)
    if self.rRoom then
        self.rRoom:removeProp(self)
        self.rRoom = nil
    end
    EnvObject.tObjectsInSpace[self] = nil
end

function EnvObject:getVaporizeCost()
    local nCost = 0
    local rData = EnvObject.getObjectData(self.sName)
    if rData and rData.matterCost then
        nCost = rData.matterCost * g_GameRules.MAT_VAPE_OBJECT_PCT
    elseif self.sName == 'Door' then
		nCost = g_GameRules.MAT_BUILD_DOOR * g_GameRules.MAT_VAPE_OBJECT_PCT
	elseif self.sName == 'Airlock' then
		nCost = g_GameRules.MAT_BUILD_AIRLOCK_DOOR * g_GameRules.MAT_VAPE_OBJECT_PCT
	elseif self.sName == 'HeavyDoor' then
		nCost = g_GameRules.MAT_BUILD_HEAVY_DOOR * g_GameRules.MAT_VAPE_OBJECT_PCT
	end
    return nCost
end

function EnvObject:isOwnedByPlayer()
    return self.rRoom and self.rRoom:playerOwned()
end

function EnvObject:hover(hoverTime)
    local alpha = math.abs(math.sin(hoverTime * 4)) / 2 + 0.5
    self:setColor(g_GuiManager.AMBER[1]*alpha, g_GuiManager.AMBER[2]*alpha, g_GuiManager.AMBER[3]*alpha, 1.0)
end

function EnvObject:unHover()
    if self:slatedForTeardown(false,true) then
        self:setColor(unpack(self.pendingVaporizeColor))
    elseif self.baseColor then
        self:setColor(unpack(self.baseColor))
    else
        self:setColor(1, 1, 1, 1)
    end
end

function EnvObject:setToolTipBulletPoint(tSlot, sString, sBulletTexture, tColor)
	tSlot.sString = sString
	tSlot.sTexture = sBulletTexture or 'ui_icon_bulletpoint'
	tSlot.sTextureSpriteSheet = 'UI/Inspector'
	tSlot.tTextureColor = tColor or Gui.AMBER
end

function EnvObject:getContentsTextTable()
    if self.tInventory and next(self.tInventory) ~= nil then
        local t = {}
        for k,tItem in pairs(self.tInventory) do
            local sString = nil
			-- datacubes: show the blueprint we have
			if tItem.bHasResearchData and tItem.sResearchData then
				local sResearchLC = ResearchData[tItem.sResearchData].sName
				sString = g_LM.line(sResearchLC)
            else
                sString = tItem.sName
                if tItem.nCount > 1 then
                    sString = sString .. ' ('..tItem.nCount..')'
                end
                local rOwner = Inventory.getOwner(tItem)
                if rOwner and rOwner.getNiceName then
                    sString = sString .. ' ('..rOwner:getNiceName()..')'
                end
            end
            table.insert(t,{str=sString,key=k})
        end
        return t
    end
    return nil
end

function EnvObject:getContentsText()
    if not self.tInventory then return nil end
    local nItems = 0
    local sString = ''
    if self.tInventory and next(self.tInventory) ~= nil then
        for k,tItem in pairs(self.tInventory) do
			-- datacubes: show the blueprint we have
			if tItem.bHasResearchData and tItem.sResearchData then
				local sResearchLC = ResearchData[tItem.sResearchData].sName
				sString = g_LM.line(sResearchLC)
				nItems = 1
				break
			end
            sString = sString .. tItem.sName
            if tItem.nCount > 1 then
                sString = sString .. ' ('..tItem.nCount..')'
            end
			-- don't show owner name here, shelving shows it
            sString = sString..'\n'
			nItems = nItems + 1
        end
    else
        sString = sString .. g_LM.line('INSPEC141TEXT')..'\n'
    end
    return sString, nItems
end

function EnvObject:getContentsList()
	-- similar to above, but returns a list of strings of this object's contents
	if not self.tInventory then return nil end
	local tItems = {}
	if self.tInventory and next(self.tInventory) ~= nil then
		for k,tItem in pairs(self.tInventory) do
			-- datacubes: show the blueprint we have
			if tItem.bHasResearchData and tItem.sResearchData then
				local s = g_LM.line(ResearchData[tItem.sResearchData].sName)
				s = s .. ' (' .. g_LM.line('PROPSX072TEXT') .. ')'
				table.insert(tItems, s)
				break
			end
            local sString = tItem.sName
            if tItem.nCount > 1 then
                sString = sString .. ' ('..tItem.nCount..')'
            end
            local rOwner = Inventory.getOwner(tItem)
            if rOwner and rOwner.getNiceName then
                sString = sString .. ' ('..rOwner:getNiceName()..')'
            end
			table.insert(tItems, sString)
        end
    else
        table.insert(tItems, g_LM.line('INSPEC141TEXT'))
    end
    return tItems
end

function EnvObject:getToolTipTextInfos()
    if not self.tToolTipTextInfos then
        self.tToolTipTextInfos = {}
	end
	self.tToolTipTextInfos[1] = {}
	self.tToolTipTextInfos[2] = {}
	self.tToolTipTextInfos[3] = {}
	self.tToolTipTextInfos[4] = {}
	self.tToolTipTextInfos[5] = {}
	self.tToolTipTextInfos[6] = {}
	self.tToolTipTextInfos[7] = {}
	self.tToolTipTextInfos[8] = {}
	local nCurrentIndex = 1
    self.tToolTipTextInfos[nCurrentIndex].sString = ""
    if self.tParams and self.tParams.spawnerName then
        self.tToolTipTextInfos[nCurrentIndex].sString = 'Spawner: '..self.tParams.spawnerName
    elseif self.sFriendlyName then
        self.tToolTipTextInfos[nCurrentIndex].sString = self.sFriendlyName
    end
	nCurrentIndex = nCurrentIndex + 1
	-- line 2: condition/health
	local sString = g_LM.line('INSPEC054TEXT')..' '..EnvObject.getConditionUIString(self.nCondition)
	-- color according to condition
	-- TODO: use EnvObject.tConditionColors for this
    local tColor = Gui.AMBER
    if self.nCondition <= 25 then
        tColor = Gui.RED
    else
        tColor = Gui.AMBER 
    end
    if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
		self:setToolTipBulletPoint(self.tToolTipTextInfos[nCurrentIndex], sString, nil, tColor)
	end
	nCurrentIndex = nCurrentIndex + 1
	-- line 3: power draw/output (if applicable)
	if self.tData.nPowerDraw or self.tData.nPowerOutput then
		local sLabel = g_LM.line('INSPEC164TEXT')
		if self.tData.nPowerOutput then
			sLabel = g_LM.line('INSPEC165TEXT')
		end
		local nPower = self.tData.nPowerDraw or self.tData.nPowerOutput
		sString = string.format('%s %s %s', sLabel, nPower, g_LM.line('INSPEC166TEXT'))
		self:setToolTipBulletPoint(self.tToolTipTextInfos[nCurrentIndex], sString, nil, Gui.AMBER)
		nCurrentIndex = nCurrentIndex + 1
	end
	-- bed or inventory? show owner
	if self.getOwner then
		local rOwner = self:getOwner()
		if rOwner then
			local sString = g_LM.line('INSPEC176TEXT') .. ' ' .. rOwner.tStats.sName
			self:setToolTipBulletPoint(self.tToolTipTextInfos[nCurrentIndex], sString, nil, Gui.AMBER)
			nCurrentIndex = nCurrentIndex + 1
		end
	end
	-- container/inventory contents
	local tContents = self:getContentsList()
    if tContents then
		self:setToolTipBulletPoint(self.tToolTipTextInfos[nCurrentIndex], g_LM.line('INSPEC114TEXT'))
		nCurrentIndex = nCurrentIndex + 1
		for _,line in ipairs(tContents) do
			-- add some spaces to cheapo-indent
			self.tToolTipTextInfos[nCurrentIndex].sString = '     ' .. line
			nCurrentIndex = nCurrentIndex + 1
		end
    end
    return self.tToolTipTextInfos
end

--Malady calls this to remove diseases from objects after a certain amount of time, consider moving
function EnvObject:diseaseInteraction(rSource,tMalady)
    if not self.tMaladies then self.tMaladies = {} end
    if not self.tMaladies[tMalady.sMaladyName] then
        self.tMaladies[tMalady.sMaladyName] = Malady.reproduceMalady(tMalady)
    end
    self.tMaladies[tMalady.sMaladyName].nEndTime = GameRules.elapsedTime + tMalady.nBacteriaLifetime
end

function EnvObject:getPowerOutput()
    if self:_isSabotaged() or not self.bActive or self.nCondition == 0 then return 0 end
    return self.tData.nPowerOutput or 0
end

function EnvObject:_generateStartingInventory()
    local nCount=math.random(unpack(self.tData.GenerateStartingInventory.tRange))
    local i=0
    while i < nCount do
        local tItem
        if self.tData.GenerateStartingInventory.tWhitelist then
            local sKey = self.tData.GenerateStartingInventory.tWhitelist[ math.random(1,#self.tData.GenerateStartingInventory.tWhitelist) ]
            tItem = Inventory.createItem(sKey)
            if Inventory.getMaxStacks(tItem) > 1 and self.tData.GenerateStartingInventory.tStackRange then
                tItem.nCount = math.random( unpack(self.tData.GenerateStartingInventory.tStackRange) )
            end
        elseif self.tData.GenerateStartingInventory.bStuff then
            tItem = Inventory.createRandomStartingStuff()
        end
        self:addItem(tItem)

        i=i+1
    end
end

function EnvObject.updateSavegame(nSavegameVersion, saveData)
end

function EnvObject.getConditionUIString(nCondition)
    local sString = ""
    if not nCondition then return sString end
    local tBarColor = {1, 0, 0}
    for i=1,#EnvObject.tConditions do
        if nCondition < EnvObject.tConditions[i].nBelow then
            sString = g_LM.line(EnvObject.tConditions[i].linecode)
			sString = sString .. ' ('..math.floor(nCondition)..'%)'
        end
    end
	for i=1,#EnvObject.tConditionColors do
		if nCondition < EnvObject.tConditionColors[i].nBelow then
			tBarColor = EnvObject.tConditionColors[i].tBarColor
		end
	end
    return sString, tBarColor
end

function EnvObject:setIconOffset(nOffX, nOffY)
	local x,y = self:getLoc()
	x = x + nOffX
	y = y + nOffY
	self.rPowerIcon:setLoc(x, y)
end

function EnvObject.stuffUtility(rChar,rAO,nOriginalUtility)
    local rObj = rAO.tData.rTargetObject
    local sKey = rAO.tData.sObjectKey
    local tItem = rObj.tInventory[sKey]
    if tItem then
        local nAff = rChar:getObjectAffinity(tItem)
        local bDiscardOperation = false
        local rOwner = Inventory.getOwner(tItem)
        if nAff < Character.STUFF_AFFINITY_DISCARD_THRESHOLD and rObj.tDisplaySlots and (rOwner == rChar or not rOwner) then
            -- this is a 'pick it up to get rid of it' operation. Score differently.
            -- Weigh by how much we don't like it, and how dissatisfied we are with our stuff.
            nAff = Character.STUFF_AFFINITY_DISCARD_THRESHOLD - nAff
            local nSatisfaction = math.max(0,-rChar:getStuffSatisfaction())
            return nOriginalUtility + nSatisfaction*Character.SATISFACTION_UTILITY_SCALE + nAff*.5
        else
            local nNewSatisfaction = rChar:getStuffSatisfaction(tItem)
            local nOldSatisfaction = rChar:getStuffSatisfaction()
            if nNewSatisfaction > nOldSatisfaction + 3 then
                return nOriginalUtility + (nNewSatisfaction-nOldSatisfaction) * Character.SATISFACTION_UTILITY_SCALE
            end
        end
    end
    return -1
end

function EnvObject.gatePickUpStuff(rChar,rAO)
    if rChar:getNumOwnedStuff() > Character.MAX_OWNED_STUFF then
        return false, 'too much stuff'
    end
    if rChar:getNumCarriedItems() >= Character.MAX_INVENTORY then
        return false, 'inventory full'
    end
    local rObj = rAO.tData.rTargetObject
    local sKey = rAO.tData.sObjectKey
    local tItem = rObj.tInventory[sKey]

    if tItem then
        if Inventory.getMaxStacks(tItem) and rChar.tInventory[sKey] then
            return false, "I've already got one."
        end
        if Inventory.alreadyHasSingleton(tItem,rChar) then
            return false, "I've already got something of that template."
        end
        
        local nAff = rChar:getObjectAffinity(tItem)

        local rOwner = Inventory.getOwner(tItem)
        if rOwner then
            if rOwner == rChar and rObj.tDisplaySlots then
                -- Owner may pick up the item if they don't like it much any more, to discard or trade.
                -- Only take this option if the item is on display.
                if nAff > Character.STUFF_AFFINITY_DISCARD_THRESHOLD then
                    return false,'Character enjoys the item and does not want to get rid of it'
                end
            elseif rOwner ~= rChar then
                -- Ban thievery for now.
                return false, 'not yours'
            end
        else
            if nAff < Character.STUFF_AFFINITY_DISCARD_THRESHOLD then
                -- Pick up just to incinerate?
                if not Inventory.allowIncinerate(tItem) then
                    return false, 'Item has not been waiting long enough for destruction.'
                end
            elseif nAff < Character.STUFF_AFFINITY_PICKUP_THRESHOLD then
                return false, 'Does not want to own or incinerate item.'
            end
        end

        return true
    else
        return false, 'Item gone'
    end
end

function EnvObject.DBG_repairEverything(nTargetCondition, sObjectType)
	for id,rRoom in pairs(Room.tRooms) do
		for rProp,_ in pairs(rRoom.tProps) do
			if not sObjectType then
				rProp.nCondition = nTargetCondition or 100
			elseif sObjectType == rProp.sName then
				rProp.nCondition = nTargetCondition or 100
			end
		end
	end
end

return EnvObject
