-- Characters have the following variables:
local DFGraphics = require('DFCommon.Graphics')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local Projectile=require('Projectile')
local BrigZone=require('Zones.BrigZone')
local EmergencyBeacon=require('Utility.EmergencyBeacon')
local MiscUtil = require('MiscUtil')
local Renderer = require('Renderer')
local World = require('World')
local GameRules = require('GameRules')
local Oxygen = require('Oxygen')
local Inventory = require('Inventory')
local InventoryData = require('InventoryData')
local EnvObject = require('EnvObjects.EnvObject')
local Entity = require('Entity')
local MonsterUtility = require('Utility.MonsterUtility')
local GlobalObjects = require('Utility.GlobalObjects')
local CommandObject = require('Utility.CommandObject')
local Log = require('Log')
local Task = require('Utility.Task')
--local Animation = require('Animation')
local Rig = require('Rig')
local CitizenNames = require('CitizenNames')
local CharacterManager = nil
local Class=require('Class')
local Malady=require('Malady')
local Corpse=require('Pickups.Corpse')
--local BehaviorTree=require('AI.BehaviorTree')
--local TreeWalker=require('AI.TreeWalker')
local UtilityAI=require('Utility.UtilityAI')
local Needs=require('Utility.Needs')
local OptionData=require('Utility.OptionData')
local GridUtil=require('GridUtil')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')
local Room=require('Room')
local ObjectList=require('ObjectList')
local SoundManager = require('SoundManager')
local Lighting=require('Lighting')
local Fire=require('Fire')
local Gui = require('UI.Gui')
local Portraits = require('UI.Portraits')
local Base = require('Base')
local PickupData = require('Pickups.PickupData')
local Pickup = require('Pickups.Pickup')
local Topics = require('Topics')
local Profile = require('Profile')

local Character = require('CharacterConstants')

kMAX_BUBBLE_BG_SEGMENTS = 12

Character.staticCounter=1

function Character:init( tData )
    self.NO_DEEP_COPY = true

	CharacterManager = require( 'CharacterManager' )
	-- basic setup

	self.sDirection = 'SE'
	self.rAssetSet = GameRules.worldAssets

	self.tag = ObjectList.addObject(ObjectList.CHARACTER, nil, self, tData, false, false, nil, nil, false)

	self.tVariations = {}
	self.tAnimations = {}

	self.needsReduce = Character.NEEDS_REDUCE_TICK
	self.moraleTimer = Character.MORALE_TICK + math.random()*Character.MORALE_TICK
	self.graphTimer = Character.GRAPH_TICK_RATE
--	self.survivalTimer = Character.SURVIVAL_TICK + math.random()*Character.SURVIVAL_TICK
	self.oxygenTimer = Character.OXYGEN_TICK + math.random()*Character.OXYGEN_TICK
	self.roomMoraleTimer = Character.ROOM_MORALE_TICK

	self:_setStats( tData )

    -- hacky old save support.
    Base._characterInit(tData and tData.tStats)
    
	self.tAffinity = tData.tAffinity or {}
	self.tFamiliarity = tData.tFamiliarity or {}

	local rRenderLayer = Renderer.getRenderLayer(Character.RENDER_LAYER)
	self.tHackEntity = Entity.new(self, rRenderLayer, self.tStats.sUniqueID)

	self:_setUpBlobShadow()
	self:_setRig( tData, self.tHackEntity )

	-- load log (init happens on first updateAI)
	self:_setLog( tData )

	--self:setScl(.5,.5,.5)

	self.rRig:activate()

    self.nLastFaction = nil
	self:_factionSetup(true)

	self:setJob(self.tStats.nJob, true)
	self:_setPortrait( tData )

	-- insert into the character layer
	rRenderLayer:insertProp( self )
	self.bVisible = true

	-- set up location
	local z = World.getHackySortingZ(tData.x,tData.y)
	self:setLoc( tData.x, tData.y, math.floor(z), nil, true )

	-- set up emoticon
	if not self:isDead() then
		self:_setUpEmoticon()
	end

	self:setRot(30,0,0)
	self:setDirection('SE')
	self.nWaitingTime = 0
	self.nThreat = OptionData.tPriorities.NORMAL

    for _,tItem in pairs(self.tInventory) do
        self:pickUpItem(tItem)
    end
	self:_refreshHeldItemVisibility()

	self:_selectVoice()

	-- start hobbies with a cooldown, so everyone isn't doing it all at once at the start
	if not self:retrieveMemory(Character.MEMORY_WORKED_OUT_RECENTLY) and math.random() > .3 then
		self:storeMemory(Character.MEMORY_WORKED_OUT_RECENTLY, true, math.random(1,30))
	end
	if not self:retrieveMemory(Character.MEMORY_PLAYED_GAME_RECENTLY) and math.random() > .3 then
		self:storeMemory(Character.MEMORY_PLAYED_GAME_RECENTLY, true, math.random(1,30))
	end

	self.tAccessories = {}
	for name,data in pairs(Character.AccessoryDefs) do
		local accessoryEntity = Entity.new(self, rRenderLayer, self.tStats.sUniqueID..name)

		local tRigArgs = {}
		tRigArgs.sResource = data.sRig
		tRigArgs.sMaterial = "meshSingleTexture"
		tRigArgs.sTextureOverride = data.sTexture
		local rAccRig = Rig.new(accessoryEntity, tRigArgs, self.rAssetSet)

		rAccRig.name = name
		rAccRig.tEntity = accessoryEntity
		rAccRig.tOff = data.tOff
		self.tAccessories[name] = rAccRig
	end

	if self.tStatus.bSpacewalking then
		self:spacesuitOn(true)
	end

	self:setElevatedSpacewalk(self.tStatus.bElevatedSpacewalk,true)

    if self.tStatus.bCuffed then self:cuff() end
    self:_testInPrison()
	self:_refreshHeldItemVisibility()

	self:_selectVoice()

	self.nLifetime = 0

	self:setVisibility(World.VISIBILITY_FULL)

    if tData.tTaskSaveData then
        local rTask = Task.fromSaveData(self, tData.tTaskSaveData)
        if rTask then 
            self:forceTask(rTask)
        end
    end
    
	self.bInitialized = true
	
	------------------------------------------------------------------
	self.squadName = tData.squadName or nil
    
	------------------------------------------------------------------
    local tx,ty = self:getTileLoc()
    if not World._isInBounds(tx,ty,true) then
        CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE)
        return
    end    
end

function Character:postLoad()
    if self.tStatus.tAssignedToBrig then
        local rRoom = ObjectList.getObject(self.tStatus.tAssignedToBrig)
        if rRoom and rRoom:getZoneName() == 'BRIG' then
            rRoom:getZoneObj():charAssigned(self)
        end
    end
end

-------------------------------------------------------------
function Character:setSquadName(squadName)
	self.squadName = squadName
end

function Character:getSquadName()
	return self.squadName or nil
end
------------------------------------------------------------

------------------------------------------------------------------
-- PUBLIC --------------------------------------------------------
------------------------------------------------------------------

-- MISC --------------------------------------------------------------------------------------------------

function Character:getLoc()
	local x,y,z = self._UserData.getLoc(self)
	return x,y,z,(self.tStatus.bElevatedSpacewalk and 2) or 1
end

function Character:setTileLoc(tx,ty,tw)
    local wx,wy = World._getWorldFromTile(tx,ty)
    local wz = World.getHackySortingZ(wx,wy)
    self:setLoc(wx,wy,wz)
end

function Character:getTileLoc()
	local x,y = self._UserData.getLoc(self)
	local tx, ty = World._getTileFromWorld(x,y)
	return tx,ty,(self.tStatus.bElevatedSpacewalk and 2) or 1
end

function Character:getLevel()
	return (self.tStatus.bElevatedSpacewalk and 2) or 1
end

function Character:enteredNewTile()
    local tx,ty = self:getTileLoc()
    if not World._isInBounds(tx,ty,true) then
        CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE)
        return
    end
    local nCharVisibility = World.VISIBILITY_FULL
    if self:getTeam() == Character.TEAM_ID_PLAYER then
    else
        local r = Room.getRoomAtTile(self:getTileLoc()) or g_SpaceRoom
        nCharVisibility = r:getVisibility()
    end
    if nCharVisibility ~= self:getVisibility() then
		self:setVisibility(nCharVisibility)
	end
	if self.rBlobShadow then
        local bBlobShadowVisible = false
        if nCharVisibility == World.VISIBILITY_FULL then
            local tileValue = World.getTileValueFromWorld( self:getLoc() )
            if tileValue ~= World.logicalTiles.SPACE then
                bBlobShadowVisible = true
            end
        end
        self.rBlobShadow:setVisible(bBlobShadowVisible)
	end
	self:_testSurvivalThreats()
end

function Character:getVisibility()
	return self.nVisibility
end

function Character:setVisibilityOverride(bVisible)
    self.bVisibilityOverride = bVisible
    self:setVisibility(self.nVisibility,true)
end

function Character:setVisibility(nVisibility,bForce)
	if self.nVisibility ~= nVisibility or bForce then
		self.nVisibility = nVisibility
        if self.bVisibilityOverride ~= nil then
            self:setVisible(self.bVisibilityOverride)
        else
            self:setVisible(nVisibility == World.VISIBILITY_FULL)
        end
	end
end

function Character:setLoc(x,y,z,bForce,bLoading)
	local tx, ty = World._getTileFromWorld(x,y)
	local tileValue = World._getTileValue(tx, ty)

	local bIsDestroyedTile = tileValue == World.logicalTiles.WALL_DESTROYED

	if bIsDestroyedTile then
		self._UserData.setLoc(self,x,y,z)
		return true
	elseif ObjectList.occupySpace(x,y,self.tag) then
		if not self:isElevated() then
			-- MTF TODO / TEMP DEBUG CODE
			-- Need to figure out how dudes are getting into walls, and stop that.

			--local bHidden = World.pathGrid:checkTileFlag(tx, ty, MOAIGridSpace.TILE_HIDE)
			local bHidden = not bForce and World._isPathBlocked(tx,ty,true)
			if bHidden then
				--                print(TT_Warning, "Attempt to put character into a wall.",self:getUniqueID())
				if bLoading then
					Print(TT_Warning, "CHARACTER.LUA: Invalid position was stored in savegame. Attempting to fix.")

					local testFn = function(testTX,testTY)
									   return World._isPathable(testTX,testTY) and Oxygen.getOxygen(World._getWorldFromTile(testTX,testTY)) > Character.OXYGEN_SUFFOCATING
								   end
					local newTX,newTY = World.isAdjacentToFn(tx,ty, testFn, true)
					if newTX and newTY then
						local newWX,newWY = World._getWorldFromTile(newTX,newTY)
						Print(TT_Gameplay,'CHARACTER.LUA: Moving character to new tile.',newTX,newTY,"World:",newWX,newWY)
						self:setLoc(newWX,newWY,z)
						return true
					end
					return false
				else
					local oldTX,oldTY = self:getTileLoc()
					if tx ~= oldTX or ty ~= oldTY then
						ObjectList.unoccupySpace(self.tag)
						return false
					end
					-- Fall through: we allow grandfathering of "bad" positions in case they were intentionally placed
					-- there with bForce previously.
				end
			end
		end

		if x == math.inf or y == math.inf or x ~= x or y ~= y or (z and (z == math.inf or z ~= z)) then
			Print(TT_Error, 'CHARACTER.LUA: Attempt to move character to NaN.')
			assertdev(false)
			return false
		end

		self._UserData.setLoc(self,x,y,z)
		return true
	end
	return false
end

function Character:getUniqueID()
	return self.tStats.sUniqueID
end

function Character:getNiceName()
	return self.tStats.sName
end

function Character:setName(sName)
	local bRefresh = Character.PremadePortraits[self.tStats.sName] or Character.PremadePortraits[sName]
	self.tStats.sName = sName
	if bRefresh then
		self.tStats.sPortrait = nil
		self:_setPortrait( self )
	end
end

function Character:isDead()
	return self.tStatus.health == Character.STATUS_DEAD
end

function Character:_remove()
	assertdev(not self.bDestroyed)
    if self.bDestroyed then
        return
    end
	self.bDestroyed=true
    self.tStatus.health = Character.STATUS_DEAD
    
    while next(self.tInventory) do
        local sKey = next(self.tInventory)
        self:destroyItem(sKey)
    end
    
    if self.rCorpse then
        self.rCorpse:remove()
        self.rCorpse = nil
    end
    
    if self.rCurrentTask and not self.rCurrentTask.bComplete then self.rCurrentTask:interrupt('removing character') end

    -- unload rigs
	self.rRig:unload()
	self.rRig = nil
	if self.rSpacesuitRig then
		self.rSpacesuitRig:unload()
		self.rSpacesuitRig = nil
	end
	if self.tAccessories then
		for k, v in pairs(self.tAccessories) do
			v:unload()
		end
	end
	if self.tAttachedEntity then
		self.tAttachedEntity.rRig:unload()
	end

	-- clean up emoticon
	if self.rEmoticon then
		self:setEmoticon(nil)
		self.rEmoticon = nil
	end
	self.rEmoticonSpriteSheet = nil
	if self.rBlobShadow then
		local rRenderLayer = Renderer.getRenderLayer("WorldFloor")
		rRenderLayer:removeProp( self.rBlobShadow )
		self.rBlobShadow = nil
	end
	local rGameLayer = Renderer.getRenderLayer(Character.RENDER_LAYER)
	local rBGLayer = Renderer.getRenderLayer(Character.BACKGROUND_RENDER_LAYER)
	rGameLayer:removeProp( self )
	rBGLayer:removeProp( self )
	ObjectList.removeObject(self.tag)
	self.tag = nil
end

function Character:setVisible(bVisible)
	if bVisible ~= self.bVisible then
		self.bVisible = bVisible
		local rGameLayer = Renderer.getRenderLayer(Character.RENDER_LAYER)
		local rBGLayer = Renderer.getRenderLayer(Character.BACKGROUND_RENDER_LAYER)
		if bVisible then
			rGameLayer:insertProp( self )
			rBGLayer:insertProp( self )
			self.tHackEntity:setRenderLayer(self.rTargetRenderLayer or rGameLayer)
		else
			self.tHackEntity:setRenderLayer(nil)
			rGameLayer:removeProp( self )
			rBGLayer:removeProp( self )
		end
	end
end

function Character:_vacuumDisappear(dt)
	self.nScale = self.nScale - dt * .2
	self:setScl(self.nScale,self.nScale,self.nScale)
	local xRot, yRot, zRot = self:getRot()
	local rotDelta = 120 * dt
	self:setRot( xRot, yRot + rotDelta, zRot + rotDelta )
	local x,y,z
	if self.vacuumVecX then
		x,y,z = self:getLoc()
		x,y = x+self.vacuumVecX, y+self.vacuumVecY
		self:setLoc(x,y)
	end
	if self.nScale < 0.001 or (x and not g_World.isInBounds(x,y)) then
		self.deathTick = nil
		CharacterManager.deleteCharacter(self)
	end
end

function Character:_kill( callback, bStartDead, cause, tAdditionalInfo )
	-- character won't tick anymore, give them one last chance to log :[
	self:postLogFromQueue()
	if self.rCurrentTask and not self.rCurrentTask.bComplete then
		self.rCurrentTask:interrupt("death")
	end
    while next(self.tInventory) do
        local sKey = next(self.tInventory)
        self:dropItemOnFloor(sKey)
    end
    assertdev(not self.rCurrentTask or self.rCurrentTask.bComplete)
	if self.rCurrentRoom then
		self.rCurrentRoom:removeCharacter(self)
		self.rCurrentRoom = nil
	end
	ObjectList.unoccupySpace(self.tag)
	-- Do not remove the object: the corpse sticks around for a bit.
	--ObjectList.removeObject(self.tag)
	if not bStartDead then
		assert(self.tStatus.health ~= Character.STATUS_DEAD)
	end
    -- spawn a pick-up-able corpse object, so janitors can inter our remains
    if cause ~= Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE and not self.tStatus.bCreatedCorpse then
        self.tStatus.bCreatedCorpse = true
        local nCorpseType = nil
		if Base.isFriendlyToPlayer(self) then
			nCorpseType = Corpse.TYPE_FRIENDLY
		elseif self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then
			nCorpseType = Corpse.TYPE_MONSTER
		else
			nCorpseType = Corpse.TYPE_RAIDER
		end
        local tCorpse = Inventory.createItem('Corpse', { tOccupant=self._ObjectList_ObjectMarker, sOccupantID=self:getUniqueID(), 
                            sOccupantName=self:getNiceName(), nType=nCorpseType })
        self.rCorpse = require('Pickups.Pickup').dropInventoryItemAt(tCorpse, self:getLoc())
        self.tStatus.tCorpseProp = ObjectList.getTag(self.rCorpse)
    end
    local rCorpse = self.tStatus.tCorpseProp and ObjectList.getObject(self.tStatus.tCorpseProp)
    if rCorpse then rCorpse:hideBodybag() end
	local bHostile = not Base.isFriendlyToPlayer(self)
	if self.tStatus.health ~= Character.STATUS_DEAD then -- there's a hack that loaded dead characters are killed again to generate corpses
		local wx,wy = self:getLoc()
		local tx,ty = World._getTileFromWorld(wx,wy)
		if bHostile then
			Base.incrementStat('nHostilesKilled')
		end
		if cause ~= nil and not bStartDead then
			local bBloodDecal = false
            local sDeathAnim = nil
			if cause == Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE then
                sDeathAnim = 'space_flail'
				-- count "sucked into space" as asphyxiated also
				if bHostile then
					Base.incrementStat('nHostilesAsphyxiated')
				end
			elseif cause == Character.CAUSE_OF_DEATH.FIRE then
				sDeathAnim = 'death_fire'
			elseif cause == Character.CAUSE_OF_DEATH.SUFFOCATION then
				sDeathAnim = 'death_suffocate'
				if bHostile then
					Base.incrementStat('nHostilesAsphyxiated')
				end
			elseif cause == Character.CAUSE_OF_DEATH.COMBAT_RANGED or cause == Character.CAUSE_OF_DEATH.COMBAT_MELEE then
				sDeathAnim = 'death_shot'
				bBloodDecal = true
			elseif cause == Character.CAUSE_OF_DEATH.PARASITE then
				sDeathAnim = 'death_shot'
				bBloodDecal = true
			elseif cause == Character.CAUSE_OF_DEATH.THING then
				sDeathAnim = 'death_shot'
				bBloodDecal = true
			elseif cause == Character.CAUSE_OF_DEATH.STARVATION then
				sDeathAnim = 'death_suffocate'
			else
				sDeathAnim = 'death_shot'
				bBloodDecal = true
			end
			if bBloodDecal and g_Config:getConfigValue("show_blood") and self.tStats.nRace ~= Character.RACE_KILLBOT and g_World.pathGrid:getTileValue(tx,ty) ~= g_World.logicalTiles.SPACE then
				World.setFloorDecal(tx, ty, self:_getBloodTile())
			end
            if sDeathAnim then
                self:playAnim(sDeathAnim,true)
            end
		end
		-- remember cause of death
		self.tStatus.nDeathCause = cause or Character.CAUSE_OF_DEATH.UNSPECIFIED
		if self:isPlayersTeam() then
            Base.eventOccurred(Base.EVENTS.CitizenDied, { rReporter=self, nCause=cause, sDiseaseName=tAdditionalInfo.sDiseaseName })
        end
	end

	self.tStatus.health = Character.STATUS_DEAD

	if not bStartDead and cause == Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE then
		self.nScale = 0.5
		self.deathTick = self._vacuumDisappear
	end

	self.tStats.timeOfDeath = self.tStats.timeOfDeath or GameRules.elapsedTime
	
	-- clean up emoticon
	if self.rEmoticon then
		self:setEmoticon(nil)
		self.rEmoticon = nil
	end
	
	-- remove player from squad if they are a member of one
	if self:getSquadName() then
		local rSquadList = World.getSquadList()
		if rSquadList.getSquad(self:getSquadName()) then
			World.getSquadList().getSquad(self:getSquadName()).remMember(self:getUniqueID())
			self:setSquadName(nil)
		end
	end
	
	callback( self )
end

function Character:_getBloodTile()
	return DFUtil.arrayRandom(Character.BLOOD_DECALS)
end
-- returns 0-1
function Character:getJobCompetency(enum)
	local c = self:getBaseJobCompetency(enum) * .95
	c = c * self:getMoraleCompetencyModifier()
	c = math.min(math.max(0,c),1)
	return c
end

-- returns 0-1
function Character:getBaseJobCompetency(enum)
	-- starting competency is 0-2
	-- level is 1-10
	-- but max competency should be awarded at a combined value of 10.
	local competency = self.tStats.tJobCompetency[enum] + self:getCurrentLevelByJob(enum)
	competency = math.min(1, competency / 10)
	return competency
end

function Character:getJobLevel(enum)
	-- return a value of 1 - 5 for use in the UI
	local nCompetency = self:getBaseJobCompetency(enum)
	local nLevel
	for i, rCompetencyInfo in ipairs(Character.tJobLevels) do
		if nCompetency > rCompetencyInfo.nMinCompetency then
			nLevel = rCompetencyInfo.nLevel
		end
	end
	return nLevel
end

function Character:getCurrentLevelByJob(nJobID)
	return Character.getCurrentLevelByXP(self.tStats.tJobExperience[nJobID])
end

function Character:addJobExperience(nJobID, nXP)
	if nXP == 0 then
		return
	end
	-- affinity for duty affects advancement rate
	local nAff = self:getJobAffinity(nJobID)
	-- good morale = skills go up faster
	local nMoraleThreshold = 50
	if self.tStats.nMorale > nMoraleThreshold then
		-- if bonus starts at 50, 25% bonus at 100
		local nBonus = (self.tStats.nMorale - nMoraleThreshold) / Character.MORALE_MAX
		nAff = nAff + (nAff * nBonus / 2)
	end
	-- normalize affinity for lerp
	nAff = (Character.STARTING_AFFINITY + nAff) / (Character.STARTING_AFFINITY * 2)
	local nXPMin = 1 - Character.DUTY_AFFINITY_XP_MAX_RATE
	local nXPMax = 1 + Character.DUTY_AFFINITY_XP_MAX_RATE
	nXP = nXP * DFMath.lerp(nXPMin, nXPMax, nAff)
	local previousLevel = self:getCurrentLevelByJob(nJobID)
	self.tStats.tJobExperience[nJobID] = self.tStats.tJobExperience[nJobID] + nXP
	-- leveled?
	if self:isPlayersTeam() and previousLevel < self:getCurrentLevelByJob(nJobID) then
        Base.eventOccurred(Base.EVENTS.CitizenSkillUp, {rReporter=self, nJob=nJobID})
	end
end

function Character:DBG_increaseCurrentJobLevel()
	self:addJobExperience(self:getJob(), Character.EXPERIENCE_PER_LEVEL)
end

function Character:getJob()
	return self.tStats.nJob
end

function Character:getFactionBehavior()
    return  Base.getTeamFactionBehavior(self.tStats.nTeam)
end

function Character:getTeam()
	return self.tStats.nTeam
end

function Character:isPlayersTeam()
	return self.tStats.nTeam == Character.TEAM_ID_PLAYER
end

function Character:isHostileToPlayer()
	return not Base.isFriendlyToPlayer(self)
end

function Character:setTeam(nTeam)
	self.tStats.nTeam = nTeam
	self:_factionSetup()
end

function Character:setJob(job, bLoading)
	if self:getJob() == Character.EMERGENCY and self:getSquadName() and job ~= Character.EMERGENCY then
		local rSquadList = World.getSquadList()
		if rSquadList then
			local rSquad = rSquadList.getSquad(self:getSquadName())
			if rSquad then
				rSquad.remMember(self:getUniqueID())
			else
				print('CHARACTER.LUA: Character:setJob() rSquad == nil')
			end
		else
			print('CHARACTER.LUA: Character:setJob() rSquadList == nil')
		end
--		World.getSquadList().getSquad(self:getSquadName()).remMember(self:getUniqueID())
		self:setSquadName(nil)
	end
    assertdev(Character.JOB_NAMES[job])
    if not Character.JOB_NAMES[job] then
        job = Character.UNEMPLOYED
    end
	self.tStats.nJob = job

	self:_setJobOutfit( bLoading )
	-- don't make a log entry if we're loading save data
	if bLoading then
		return
	end
	local tType = Log.tTypes.DUTY_UNEMPLOYED
	-- affinity for new duty affects response via lovesjob/hatesjob tags
	if job ~= Character.UNEMPLOYED then
		tType = Log.tTypes.DUTY_ASSIGNED
	end
	Log.add(tType, self)
end

-- ANIMATION AND DIRECTION -----------------------------------------------------------------------------

function Character:getAnimDuration(sAnimName, rRig)
	-- rRig: get an anim's duration for a rig besides our current one
	local rig = rRig or self.rCurrentRig
	local tAnimSetData = self.tAnimations[rig]
    if not tAnimSetData then
		--Print(TT_Warning, "Missing anim for rig.")
        assertdev(false)
        return
    end
	local tAnimData = tAnimSetData[sAnimName]
    if not tAnimData then
		Print(TT_Warning, "CHARACTER.LUA: Missing anim:"..sAnimName)
        return
    end
	if tAnimData.sFilename then
		tAnimData.sAnimPath = tAnimSetData.sBasePath .. tAnimData.sFilename
	end
	return rig:getAnimDuration(tAnimData)
end

function Character:_getBestWeaponInInventory(bLethal)
    local nBest=-1
    local sBest=nil
    for k,tItem in pairs(self.tInventory) do
        local nDmg,damageType = Inventory.getWeaponData(tItem)
        if nDmg and nDmg > nBest then
            if (bLethal and damageType ~= Character.DAMAGE_TYPE.Stunner) or
                    (not bLethal and damageType == Character.DAMAGE_TYPE.Stunner) then
                nBest = nDmg
                sBest=k
            end
        end
    end
    return sBest
end

function Character:_getAutocreateWeaponTemplate(bLethal)
    local sAutocreate
        if self.tStatus.tImprisonedIn then
            -- no autocreate in prison
        elseif self.tStats.nJob == Character.EMERGENCY then
            if bLethal then
                sAutocreate = (Base.hasCompletedResearch('LaserRifles') and 'LaserRifle') or 'Pistol'
            else
                sAutocreate = 'Stunner'
            end
        elseif self.tStats.nRace == Character.RACE_KILLBOT then
            sAutocreate = 'KillbotRifle'
        end
        return sAutocreate
end

function Character:_autocreateWeapon(bLethal)
    local sAutocreate = self:_getAutocreateWeaponTemplate(bLethal)
    if sAutocreate then
        local tItem = Inventory.createItem(sAutocreate)
        tItem.bAutocreated = true
        sAutocreate = self:pickUpItem(tItem)
    end
    return sAutocreate
end

function Character:_shouldAttackLethal(rTarget)
    local bLethal = true
        local bTargetIsCharacter = rTarget and ObjectList.getObjType(rTarget) == ObjectList.CHARACTER 
	    if self.tStats.nJob == Character.EMERGENCY then
            local bHuman = bTargetIsCharacter and rTarget.nRace ~= Character.RACE_MONSTER and rTarget.nRace ~= Character.RACE_KILLBOT
            if not bHuman then
                bLethal = true
            elseif g_ERBeacon:getViolence(self.squadName) == g_ERBeacon.VIOLENCE_LETHAL or self:hasUtilityStatus(Character.STATUS_RAMPAGE_VIOLENT) then
                bLethal = true
            elseif g_ERBeacon:getViolence(self.squadName) == g_ERBeacon.VIOLENCE_NONLETHAL then
                bLethal = false
            else
                bLethal = not rTarget or not bTargetIsCharacter or self:_hates(rTarget)
            end
			-- security use lethal force for those marked, ignoring beacon state
			if bTargetIsCharacter and rTarget.tStatus.bMarkedForExecution then
				bLethal = true
			end
            if bTargetIsCharacter and bLethal then
                -- security only try to incapacitate brawlers
                for otherTag,_ in pairs(rTarget.tStatus.tBrawlingWith) do
					local rOther = ObjectList.getObject(otherTag)
                    -- only if they're attacking a citizen
                    if rOther and not self:_hates(rOther) then
                        bLethal = false
                    end
                end
            end
        else
            -- brawlers never try to kill their opponent
            if bTargetIsCharacter and not self:_hates(rTarget) and self:isBrawling(rTarget) then
                bLethal = false
            end
        end
    return bLethal
end

-- rTarget: a character or envobject or worldobject.
function Character:setWeaponDrawn(bDrawn,rTarget)
    if bDrawn then
        local bLethal = self:_shouldAttackLethal(rTarget)
        local sItemKey = self:_getBestWeaponInInventory(bLethal)
        if not sItemKey then
            sItemKey = self:_autocreateWeapon(bLethal)
        end
        self.sDrawnWeapon = sItemKey
        local tWeapon = sItemKey and self.tInventory[sItemKey]
        local sStance
        if tWeapon then
            _,_,_,sStance = Inventory.getWeaponData(tWeapon)
        end
        if not sStance then
	        local tAnimSetData = self.tAnimations[self.rCurrentRig]
	        if tAnimSetData and tAnimSetData['stance'] and tAnimSetData['stance']['melee'] then
		        sStance = 'melee'
	        end
        end
        self:_setStance(sStance)
    else
        if self.tStatus.bCuffed then
            self:_setStance('cuffed')
        else
            self:_setStance(nil)
        end

        if self.sDrawnWeapon then
            local tItem = self.tInventory[self.sDrawnWeapon]
            if tItem and tItem.bAutocreated then
                self:destroyItem(self.sDrawnWeapon)
            end
        end

        self.sDrawnWeapon = nil
    end
end

function Character:_setStance(sStance)
	self.sStance = sStance
end

function Character:playAnim(sAnimName, bPlayOnce)
	local tAnimSetData = self.tAnimations[self.rCurrentRig]
	local tAnimData
	if self.sStance and tAnimSetData['stance'] and tAnimSetData['stance'][self.sStance] then
		tAnimData = tAnimSetData['stance'][self.sStance][sAnimName]
	end
	tAnimData = tAnimData or tAnimSetData[sAnimName]
	if not tAnimData then return end

	tAnimData.bPlayOnce = bPlayOnce

	if tAnimData.tFilenames then
		tAnimData.sFilename = DFUtil.arrayRandom(tAnimData.tFilenames)
	end

	if tAnimData.tRaceOverrides and tAnimData.tRaceOverrides[self.tStats.nRace] then
		tAnimData.sFilename = tAnimData.tRaceOverrides[self.tStats.nRace]
	end

	if tAnimData.sFilename then
		tAnimData.sAnimPath = tAnimSetData.sBasePath .. tAnimData.sFilename
	end

	if self.currentAccessory and (not tAnimData.sAccessory or tAnimData.sAccessory ~= self.currentAccessory.name) then
		self.rCurrentRig:detach(self.currentAccessory)
		self.currentAccessory:deactivate()
		self.currentAccessory = nil
	end

	-- hack to always hold a spaceboy
	--tAnimData.sAccessory = "GameSystem"

	if tAnimData.sAccessory and not self.currentAccessory then
		self.currentAccessory = self.tAccessories[tAnimData.sAccessory]
		local sAccessoryJoint = tAnimData.sAccessoryJoint or 'Rt_Prop'
		local tOff = self.currentAccessory.tOff or {0,0,0}
		self.rCurrentRig:attach(self.currentAccessory, sAccessoryJoint, tOff)
		self.currentAccessory:activate()
	end

	if tAnimData.sAnimPath then
		self.rCurrentRig:playAnimation(tAnimData)
	else
		Print(TT_Warning, "CHARACTER.LUA: Failed to play animation",sAnimName,"on",self:getUniqueID())
	end
end

function Character:playOverlayAnim(sAnimName, bPlayOnce)
	local tAnimSetData = self.tAnimations[self.rCurrentRig]
	local tAnimData = tAnimSetData[sAnimName]
	if not tAnimData then return end

	tAnimData.bPlayOnce = bPlayOnce

	if tAnimData.tFilenames then
		tAnimData.sFilename = DFUtil.arrayRandom(tAnimData.tFilenames)
	end

	if tAnimData.sFilename then
		tAnimData.sAnimPath = tAnimSetData.sBasePath .. tAnimData.sFilename
	end

	if tAnimData.sAnimPath then
		tAnimData.animPriority = DFAnimController.PRIORITY_OVERLAY
		self.rCurrentRig:playAnimation(tAnimData)
	else
		Print(TT_Warning, "CHARACTER.LUA: Failed to play OVERLAY animation",sAnimName,"on",self:getUniqueID())
	end
end

function Character:clearOverlayAnim()
	self.rCurrentRig:clearOverlayAnims()
end

function Character:isPlayingAnim( sAnimName )
	local tData = self:getAnimData(sAnimName)
	if not tData or not self.rCurrentRig or not self.rCurrentRig.rAnimController then
		return false
	end
    
    local tCurrentData = self.rCurrentRig.tCurrentAnimationData
    if tCurrentData and tCurrentData.sAnimName == sAnimName then
        return ( self.rCurrentRig.rAnimController:getNumAnimsPlaying(tCurrentData.animPriority) > 0 )
    end
    return false
	--return self.rCurrentRig:isAnimPlaying(tData.sFilename)
end

function Character:getAnimData( sAnimName )
	local tAnimSetData = self.tAnimations[self.rCurrentRig]
	return tAnimSetData[sAnimName]
end

function Character:setDirection( sDirection )
	self.sDirection = sDirection
	local rot = Character.DIR_ROT[sDirection]
	assert(rot)
	self.nCharRotation = rot
	--self:setRot(0,rot,0)
	self.rCurrentRig.rUnscaledRootJointProp:setRot(0,rot,0)
end

function Character:getDirection()
	return self.sDirection
end

function Character:faceWorld(wx,wy, bCompassDirectionOnly)
	if bCompassDirectionOnly == nil then bCompassDirectionOnly = true end -- Default to only face compass directions
	local x,y = self:getLoc()
	local dx,dy = wx-x,wy-y
	local deg = DFMath.getAngleBetween(0,-1,dx,dy)
	if deg < 0 then deg = deg+360 end

	if bCompassDirectionOnly == true then

		local dir = 'S'
		for _,pair in ipairs(Character.ROT_DIR) do
			if deg < pair[1] then
				break
			end
			dir = pair[2]
		end

		--[[
		local dir = nil
		if dx > 0.0001 then dir = 'E'
		else dir = 'W' end
		if dy > 0.0001 then dir = 'N'..dir
		else dir = 'S'..dir end
		]]--

		self:setDirection(dir)
	else
		self.nCharRotation = deg
		self.rCurrentRig.rUnscaledRootJointProp:setRot(0,deg,0)
	end
end

function Character:faceTile(tx,ty)
	local x, y = World._getWorldFromTile(tx,ty)
	self:faceWorld(x,y)
end

function Character:isAdjacentToObj(rObj)
	if self:isElevated() and (not rObj.isElevated or not rObj:isElevated()) then return false end

	local cx,cy = self:getLoc()
	local tx,ty = rObj:getLoc()
	return World.areWorldCoordsAdjacent(cx,cy,tx,ty, true, true)
end

function Character:faceDir(dir)
	local tx, ty = World._getTileFromWorld(self:getLoc())
	local faceX, faceY = World._getAdjacentTile(tx, ty, dir)
	self:faceTile(faceX, faceY)
end

-- AI -------------------------------------------------------------------------------------------------
function Character:getNeedValue(needName,rAO)
	-- MTF SEMI-HACK: when we are evaluating work tasks, never let our Duty appear to be higher than 90.
	-- May want a more systematic way to do this down the line, but for now the rationale is that
	-- a character shouldn't seem "maxed out" on duty if they're on a work shift.
	if rAO and rAO:getTag(self,'WorkShift') and self:wantsWorkShiftTask() and needName == 'Duty' then
		return math.min(self.tNeeds[needName],90)
	end
	return self.tNeeds[needName]
end

function Character:setNeedValue(needName, value)
	self.tNeeds[needName] = value
end

function Character:storeMemory(key, val, nDuration)
	nDuration = nDuration or 15
	self.tMemory[key] = {val=val, nTime=GameRules.simTime, nDuration=nDuration}
end

function Character:clearMemory(key)
	self.tMemory[key] = nil
end

function Character:retrieveMemory(key)
	local tMemory = self.tMemory[key]
	if tMemory then
		if GameRules.simTime - tMemory.nTime > tMemory.nDuration then
			self.tMemory[key] = nil
			return nil
		else
			return tMemory.val,tMemory.nTime
		end
	end
end

-- return: tile pairs
function Character:_getNearbyZoneDestination(sZoneType)
	-- returns a reasonably near (current or adjacent room) pair of
	-- points in the specified zone type
	local rCurrentRoom = self.rCurrentRoom
	if not rCurrentRoom or rCurrentRoom == Room.getSpaceRoom() or rCurrentRoom.bDestroyed then return end

	if rCurrentRoom:getZoneName() == sZoneType then
		return rCurrentRoom:getPathableTilePairs()
	end
	local tNearbyRooms = rCurrentRoom:getAccessibleByDoor()
	for room,_ in pairs(tNearbyRooms) do
		if room.zoneObj and room:getZoneName() == sZoneType then
			return room:getPathableTilePairs()
		end
	end
end

-- does self hate rChar?
function Character:_hates(rChar)
    return not Base.isFriendly(self,rChar)
end

function Character:getRoom()
	if self.rCurrentRoom and self.rCurrentRoom.bDestroyed then
        self:_updateRoom()
	end
	return self.rCurrentRoom
end

function Character:getNearbyTile()
	local tx,ty,tw = self:getTileLoc()
    if Malady.isIncapacitated(self) then
        return tx,ty,tw
    end
	local ntx,nty,ntw
	if self.rCurrentRoom and self.rCurrentRoom ~= Room.getSpaceRoom() then
		ntx,nty,ntw = self.rCurrentRoom:randomLeashedTileInRoom(tx,ty,tw,nil,true)
	elseif self:spacewalking() then
		ntx,nty = tx+math.random(-5,5), ty+math.random(-5,5)
		ntw = tw
	end
	if not ntx then
		ntx,nty,ntw = tx,ty,tw
	end
	return ntx,nty,ntw
end

function Character:inHazardousLoc(wx,wy)
	if not wx then wx,wy = self:getLoc() end
	local rRoom = Room.getRoomAt(wx,wy,0,self:getLevel(),true)
	if rRoom and rRoom:isDangerous(self) then
		return true
	end
	if ObjectList.getReservationAt(World._getTileFromWorld(wx,wy)) then
		return true
	end
end

function Character:_addCoopTaskOption(sMyTaskName,sYourTaskName,rAskingChar,tDest)
    local rOption = self:_getCoopTaskOption(sMyTaskName,sYourTaskName,rAskingChar)
    if rOption then
        table.insert(tDest, rOption)
    end
end

function Character:_getCoopTaskOption(sMyTaskName,sYourTaskName,rAskingChar)
	--MTF: testing removing "onDuty" characters from the available chat partner list.
    local bAllowOnDuty = sMyTaskName ~= 'ChatPartner'
    local bNearbyOnly = sMyTaskName == 'ChatPartner'
    local bAllowDanger = sMyTaskName == 'GetFieldScanned' and Malady.isIncapacitated(self)

	local r = self:getRoom()
    if not r then return end
    local rOtherRoom = rAskingChar:getRoom() 
    if not bAllowDanger and (r == Room.getSpaceRoom() or r:isDangerous(self)) then return end
    if not rOtherRoom or rOtherRoom == Room.getSpaceRoom() then return end

    if not self.rCurrentTask or (self.rCurrentTask:availableForInterruption(sMyTaskName) and (bAllowOnDuty or not self:onDuty())) then
		-- I can be your partner! Add task for the asking character.
		local wx,wy,wz,nLevel = self:getLoc()
		local bAdjacent=false

		if not bNearbyOnly or rOtherRoom:inOrAdjoining(wx,wy,wz,nLevel, true) then
			bAdjacent=true
		end

        local fnAttractorRoom
        if sMyTaskName == 'ChatPartner' then
		    fnAttractorRoom=function(r)
                if r.zoneObj and r:getZoneName()=='PUB' and not r.zoneObj:atCapacity() and r.zoneObj:hasBar() then
                    return r
                end
            end
        elseif sMyTaskName == 'GetFieldScanned' and not Malady.isIncapacitated(self) then
		    fnAttractorRoom=function(r)
                if r.zoneObj and r:getZoneName()=='INFIRMARY' then
                    return r
                end
            end
        end
        local rAttractorRoom
        if fnAttractorRoom then
			rAttractorRoom=fnAttractorRoom(r)
			if not rAttractorRoom then
				local tNearbyRooms = r:getAccessibleByDoor()
				for room,_ in pairs(tNearbyRooms) do
					rAttractorRoom=fnAttractorRoom(room)
					if rAttractorRoom then break end
				end
			end
        end

		if bAdjacent or rAttractorRoom then
			local tData = {}
			tData.rTargetRoom=rAttractorRoom
			tData.rTargetObject = self
            if sYourTaskName == 'Chat' then
			    tData.utilityGateFn=function(rChar, rThisActivityOption) return self:_chatGate(rChar, rThisActivityOption) end
			    tData.utilityOverrideFn=function(rChar, rAO, nScore) return self:_chatUtilityOverride(rAO,nScore) end
			    tData.targetLocationFn=function(rChar, rAO) return self:_coopTaskLocationCallback(rChar,rAO) end
            elseif sYourTaskName == 'FieldScanAndHeal' then
			    tData.utilityGateFn=function(rChar, rThisActivityOption) 
					--If a character has the refuse doctor bool, refuse to have a checkup
					if self.tStats.bRefuseDoctor and self.tStats.bRefuseDoctor==true  then
						return false
					end
                    -- don't get a checkup too often, but if stuff is real bad, we can get fixed up.
	
                    if self:getPerceivedDiseaseSeverity(self:retrieveMemory(Malady.MEMORY_HP_HEALED_RECENTLY) == nil) == 1 and Malady.getNextCurableMalady(self,rChar:getJobLevel(Character.DOCTOR)) then
                        return true
                    end
                    local nLastCheckup = self:retrieveMemory('LastCheckup')
                    return not nLastCheckup or GameRules.elapsedTime - nLastCheckup > Malady.CHECKUP_COOLDOWN, 'scanned character recently'
                end
                tData.customNeedsFn=function(rDoctor,rAO) return Malady.diseaseHealNeedsOverride(rDoctor,rAO,self) end
			    tData.targetLocationFn=function(rChar, rAO) return self:_coopTaskLocationCallback(rChar,rAO) end
            end
            local rOption = g_ActivityOption.new(sYourTaskName, tData)
            return rOption
		end
	end
end

function Character:_clearPendingTask()
    self.sPendingTaskName = nil
    self.rPendingTaskPartner = nil
end

function Character:_addAllFactionUtilityOptions(tUtilityOptions)
    if self:getFactionBehavior() == Character.FACTION_BEHAVIOR.EnemyGroup then
        local gateFn = function(rChar,rAO)
            if Malady.isIncapacitated(rChar) then return false,'incapacitated' end
            if rChar:_ignoreBreachThreats() then return false, 'ignore breaches' end
            local rRoom = rChar:getRoom()
            if rChar.tStatus.suffocationTime > 0 or (rRoom and (rRoom:getOxygenScore() < Character.OXYGEN_LOW or rRoom:isBreached())) then
                return true
            end
            return false, 'air is fine'
        end
        self:_addFleeOption('RaiderOxygenFleeArea',nil,tUtilityOptions,true,gateFn)
        gateFn = function(rChar,rAO)
            local bCombat,nThreat,rThreat = rChar:hasCombatAwarenessIn(self.rCurrentRoom)
            if bCombat then
                return true
            end
            return false,'no threat'
        end
        self:_addFleeOption('RaiderFleeThreat',nil,tUtilityOptions, true)
    end
    -- Advertise pending tasks.
    --[[
    if self.tStatus.bCuffed then
        local tData={}
        table.insert(tUtilityOptions, g_ActivityOption.new('CuffedIdle', tData))
    end
    ]]--
end

function Character:_shouldRespondToTantrum()
        local tChar = self:retrieveMemory(Character.MEMORY_SAW_TANTRUM_RECENTLY) 
        if not tChar then return false end
        local rChar = ObjectList.getObject(tChar)
        if rChar and rChar ~= self and not rChar:isDead() and rChar.tStatus.bRampageNonviolent then
            if not self:getJob() == Character.EMERGENCY or not self:isPerformingWorkShiftTask() then
                return true
            end
        end
    return false
end

-- We self-advertise options that don't have a room, partner, envobject, etc. to advertise them to us.
function Character:_getSelfUtilityOptions()
	local tUtilityOptions = {}
	local rRoom = self:getRoom()

    -- Advertise pending tasks.
	if self.rPendingTaskPartner then
		local partnerTask = self.rPendingTaskPartner.rCurrentTask
        if not partnerTask then
            self:_clearPendingTask()
         else
		    local tData={}
		    tData.rTargetObject = self.rPendingTaskPartner
		    tData.rTargetRoom = partnerTask.rActivityOption.tData.rTargetRoom
		    -- reverse pathX/Y and partnerX/Y
		    tData.pathX,tData.pathY = partnerTask.rActivityOption.tData.partnerX,partnerTask.rActivityOption.tData.partnerY
		    tData.partnerX,tData.partnerY = partnerTask.rActivityOption.tData.pathX,partnerTask.rActivityOption.tData.pathY
		    table.insert(tUtilityOptions, g_ActivityOption.new(self.sPendingTaskName, tData))
        end
	end

    if not Malady.isIncapacitated(self) then
        -- Advertise flee options.
	    if not self:_ignoreBreachThreats() then
		    if self.tStatus.suffocationTime > 0 or (rRoom and (rRoom:getOxygenScore() < Character.OXYGEN_LOW or rRoom:isBreached())) then
			    self:_addFleeOption('OxygenFleeArea','PanicOxygen',tUtilityOptions,true)
			    --elseif self:inHazardousLoc() then
			    --self:_addFleeOption('FleeMinorDanger',nil,tUtilityOptions)
		    end
	    end
        -- MTF: does it make sense to have different tasks for emergency alarm and pending breach?
        -- For now it seems okay to have them both use the same code.
        if self:getJob() == Character.EMERGENCY and self:isPerformingWorkShiftTask() then
            -- ignore alarm if we're performing emergency work
        elseif rRoom and rRoom:isEmergencyAlarmOn() then
		    self:_addFleeOption('FleeEmergencyAlarm',nil,tUtilityOptions)
        elseif rRoom and rRoom.bPendingBreach and not self:wearingSpacesuit() then
		    self:_addFleeOption('FleeEmergencyAlarm',nil,tUtilityOptions)
	    end
        
        if self:_shouldRespondToTantrum() then
            self:_addFleeOption('FleeTemperTantrum',nil,tUtilityOptions)
            -- only attempt this option once.
            self:clearMemory(Character.MEMORY_SAW_TANTRUM_RECENTLY)
        end

        -- Advertise inventory tasks.
        for sName,tItem in pairs(self.tInventory) do
            if Inventory.isStuff(tItem) then
                table.insert(tUtilityOptions, g_ActivityOption.new('DropStuffOnFloor', { 
                    sObjectKey=sName,
                    utilityGateFn=function(rChar,rAO,sItemKey,bLittering) return Character.discardItemGate(rChar,rAO,sItemKey,true) end,
                    utilityOverrideFn=function(rChar,rAO,nOriginalUtility) return Character.discardItemUtility(rChar,rAO,nOriginalUtility,true) end,
                } ))
            end
        end
    end
    return tUtilityOptions
end

function Character.discardItemUtility(rChar,rAO,nOriginalUtility,bLittering,sItemKey)
    local tItem = rChar.tInventory[ sItemKey or rAO.tData.sObjectKey ]
    assertdev(tItem)
    if not tItem then return false, 'item missing' end
    local nAffDiff = Character.STUFF_AFFINITY_DISCARD_THRESHOLD - rChar:getObjectAffinity(tItem)
    local nTimeMult = GameRules.elapsedTime - tItem.nTimeTradeDesired - Character.STUFF_MIN_HOLD_TIME
    nTimeMult = math.min(2,math.max(0,nTimeMult / 300))
    local nLitterPenalty = 0
    
    local nIncinerateBias = Inventory.getIncinerateBias(tItem)
    if bLittering then
        nIncinerateBias = 1-nIncinerateBias
        nLitterPenalty = math.max(0,rChar:getPersonalityStat('nNeatness') - .3)
    end    
    
    return nTimeMult * math.max(nOriginalUtility, nOriginalUtility + nAffDiff - nLitterPenalty + nIncinerateBias)
end

function Character.discardItemGate(rChar,rAO,sItemKey,bLittering)
    sItemKey = sItemKey or rAO.tData.sObjectKey
    local tItem = rChar.tInventory[sItemKey]
    assertdev(tItem)
    if not tItem then return false, 'item missing' end

    if not bLittering and not Inventory.allowIncinerate(tItem) then
        return false, 'Item not allowed to be incinerated.'
    end
    local nAff = rChar:getObjectAffinity(tItem)
    if nAff > Character.STUFF_AFFINITY_DISCARD_THRESHOLD then
        return false, 'Character likes the item'
    end
    if not tItem.nTimeTradeDesired then
        tItem.nTimeTradeDesired = GameRules.elapsedTime 
    end
    if GameRules.elapsedTime - tItem.nTimeTradeDesired < Character.STUFF_MIN_HOLD_TIME then
        return false, 'Character is going to hang onto it to trade'
    end
    return true
end

function Character:hasUtilityStatus(eStatus)
    if eStatus == Character.STATUS_RAMPAGE then
        return self.tStatus.bRampageViolent or self.tStatus.bRampageNonviolent
    end
    if eStatus == Character.STATUS_RAMPAGE_VIOLENT then
        return self.tStatus.bRampageViolent
    end
    if eStatus == Character.STATUS_RAMPAGE_NONVIOLENT then
        return self.tStatus.bRampageNonviolent
    end
end

function Character:inPrison()
    return self.tStatus.tImprisonedIn ~= nil
end

function Character:cuff()
    if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return end
    
    self.tStatus.bCuffed = true
    self.tStatus.bMarkedForCuff = true
    self:endRampage()

    -- reevaluates stance.
    self:setWeaponDrawn(false)

    if Malady.isIncapacitated(self) then
        self:playAnim("incapacitated_cuffed")
    end

    for k,v in pairs(self.tInventory) do
        local nDamage, nDamageType = Inventory.getWeaponData(v)
        local nDamageReduction = Inventory.getArmorData(v)
        if nDamage or nDamageReduction then
            if v.bAutocreated then
                self:destroyItem(k)
            else
                self:dropItemOnFloor(k)
            end
        end
    end

    if Malady.isIncapacitated(self) then
        self:reevaluateTask()
    elseif self.rCurrentTask then
        self.rCurrentTask:interrupt("cuffed")
    end
end

function Character:_testInPrison()
    if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return end

    if self.tStatus.bCuffed then
        local rRoom = BrigZone.getBrigRoomForChar(self)
        if self:getRoom() == rRoom and rRoom then
            self:uncuff()
        end
    end

    if not self.tStatus.bCuffed and self.tStatus.tAssignedToBrig and not self.tStatus.tImprisonedIn then
        local rIn = self:getRoom()
        local rAssigned = ObjectList.getObject(self.tStatus.tAssignedToBrig)
        if rIn == rAssigned then
            self.tStatus.tImprisonedIn = ObjectList.getTag(rIn)
            self.tStatus.bMarkedForCuff = false
        end
    end
end

function Character:uncuff()
    if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return end
    
    self.tStatus.bCuffed = false
    self.tStatus.bMarkedForCuff = false
    self:_testInPrison()
    self:_updateGatherers()
    -- reevaluates stance.
    self:setWeaponDrawn(false)
end

-- cuff overhaul
-- * can indicate incapacitated targets for cuffing
-- * hmm... but what about send to brig equivalent.
-- * could just treat same as assign to brig.
--   potentially useful if you don't have a brig
-- * or we could only offer it to incapacitated targets
--

function Character:canMarkForCuff()
    if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return false end
    if self:inPrison() then return false end
    return true
end

function Character:isCuffed()
    return self.tStatus.bCuffed
end

function Character:isMarkedForCuff()
    return self.tStatus.bMarkedForCuff or false
end

function Character:setMarkedForCuff(bMarked)
    if bMarked == nil then bMarked = false end
    if self.tStatus.bMarkedForCuff == nil then self.tStatus.bMarkedForCuff = false end
    if self.tStatus.bMarkedForCuff == bMarked then return end

    self.tStatus.bMarkedForCuff = bMarked
    if bMarked then

        if self:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen and not self:inPrison() and not self:retrieveMemory(Character.MEMORY_PRISON_ANGER_RECENTLY) then
            self:storeMemory(Character.MEMORY_PRISON_ANGER_RECENTLY, true, 120)
            self:angerEvent(Character.ANGER_MAX * (1-self:getPersonalityStat('nAuthoritarian')))
        end
		-- log as if we're assigned to brig
		local tLogType = Log.tTypes.BRIG_ASSIGN_INCAPACITATED
		if not Malady.isIncapacitated(self) then
			tLogType = Log.tTypes.BRIG_ASSIGN_NOT_INCAPACITATED
		end
		Log.add(tLogType, self)
    else
        if self.tStatus.bCuffed then
            self:uncuff()
        end
    end
end

-- should I cuff the target.
function Character:_shouldCuff(rTarget)
    if self:getJob() ~= Character.EMERGENCY then return false end
    if not rTarget.tStatus.bMarkedForCuff then return false end
    if rTarget == self or rTarget.tStatus.bCuffed or rTarget:isDead() or rTarget:inPrison() then return false end
    if Malady.isIncapacitated(rTarget) or rTarget:getCurrentTaskName() == 'VoluntarilyGetCuffed' then
        return true
    end
    return false
end

function Character:_addCuffOption(rAskingChar,tUtilityOptions)
    if not self.rCuffOption then
        local tData = {rTargetObject=self}
        tData.utilityGateFn=function(rChar, rThisActivityOption)
            return rChar.tStats.nJob == Character.EMERGENCY
        end
        self.rCuffOption = g_ActivityOption.new('Cuff', tData)
    end
    table.insert(tUtilityOptions, self.rCuffOption)    
end

-- We advertise some options to other characters. For example,
-- "attack me" or "chat with me."
function Character:_getOtherCharacterUtilityOptions(rAskingChar)
	local tUtilityOptions = {}

	if rAskingChar:shouldTargetForAttack(self) then
        -- if you hate me, i will advertise the opportunity to attack me.
		self:_addAttackerOptions(rAskingChar,tUtilityOptions)
	else
        if rAskingChar:_shouldCuff(self) then
            self:_addCuffOption(rAskingChar,tUtilityOptions)
        end
        if not self:hasUtilityStatus(Character.STATUS_RAMPAGE) then
            if rAskingChar:getTeam() == self:getTeam() then
                if not self.rPendingTaskPartner and not self:spacewalking() then
                    self:_addCoopTaskOption('ChatPartner','Chat',rAskingChar,tUtilityOptions)
                end
            end
            if rAskingChar:getJob() == Character.DOCTOR and not self.rPendingTaskPartner then
                if self.tStats.nRace ~= Character.RACE_MONSTER and self.tStats.nRace ~= Character.RACE_KILLBOT then 
                    if rAskingChar:getTeam() == self:getTeam() or self.tStatus.bCuffed or self.tStatus.tImprisonedIn then
                        self:_addCoopTaskOption('GetFieldScanned','FieldScanAndHeal',rAskingChar,tUtilityOptions)
                    end
                end
            end
        end
    end
    return tUtilityOptions
end

function Character:getUtilityOptions(rAskingChar)
	if rAskingChar ~= self then
        return self:_getOtherCharacterUtilityOptions(rAskingChar)
	else
        local t
        if self:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen then
            t = self:_getSelfUtilityOptions()
        else
            t = {}
        end
        self:_addAllFactionUtilityOptions(t)
        return t
	end
end

function Character:_addFleeOption(sOptionName, sPanicName, tUtilityOptions, bPanicking, leaveGateFn, panicGateFn)
	local targetX,targetY = self:getFleeLocation(sOptionName)
	if targetX then
		local leaveActivity = g_ActivityOption.new(sOptionName, {pathX=targetX,pathY=targetY,bPanic=bPanicking, bRun=true, utilityGateFn=leaveGateFn})
		table.insert(tUtilityOptions, leaveActivity)
	end

	if sPanicName then
		local panic = g_ActivityOption.new(sPanicName, {utilityGateFn=panicGateFn})
		table.insert(tUtilityOptions, panic)
	end
end

function Character:getFleeLocation(sOptionName)
	local r = self:getRoom()
	local bestRoom = nil
	local bestScore = -100000
	local bestDist = 100000
    local bestO2 = -10000
    -- MTF TODO: handle fleeing in space.
	if r and r ~= Room.getSpaceRoom() then
		local tx,ty,tw = self:getTileLoc()
		if sOptionName ~= 'FleeEmergencyAlarm' then -- and not r:isBreached() and r:getOxygenScore() > Character.OXYGEN_SUFFOCATING then
			bestRoom = r
			bestScore = r:getRoomScore(self)
            bestO2 = r:getOxygenScore()
            bestDist = 0
		end
		local tAdjoining = r:getAccessibleByDoor()
		for rOption,tOptionData in pairs(tAdjoining) do
			local doorCoord = tOptionData.tDoorCoords and tOptionData.tDoorCoords[1]

			local rDoor = doorCoord and ObjectList.getDoorAtTile(doorCoord.x,doorCoord.y)
			if rDoor and not rDoor:locked(self) and not rOption:isBreached() then
				local score = rOption:getRoomScore(self)
				local o2score = rOption:getOxygenScore()

				if o2score > Character.OXYGEN_SUFFOCATING and score > bestScore-0.5 then
                    -- if o2 is worse and we're in an o2-critical situation, don't consider the room.
                    if o2score > Character.OXYGEN_LOW or o2score > bestO2-10 then
                        -- if in an o2-critical situation, prioritize o2 as a selector.
                        local bBetterO2 = (o2score < Character.OXYGEN_LOW or bestO2 < Character.OXYGEN_LOW) and o2score > bestO2+10
                        local nEscapeDist = MiscUtil.isoDist(doorCoord.x,doorCoord.y,tx,ty)
                        -- If they're almost the same, pick the closest one.
                        -- Otherwise, it's worth going across the room for a better escape.
                        if bBetterO2 or nEscapeDist < bestDist or (score-bestScore > .5) then
                            bestRoom = rOption
                            bestScore = score
                            bestDist = nEscapeDist
                        end
                    end
				end
			end
		end
	end
	if not bestRoom then
		local tRooms, nNumRooms, nOtherTeamRooms = Room.getSafeRoomsOfTeam(self:getTeam())
		if nNumRooms then
			bestRoom = MiscUtil.randomKey(tRooms)
		end
	end
    -- we let "FleeTemperTantrum" flee to the same room, because it's really more about visual impact 
    -- than avoiding any real danger.
	if bestRoom and (not r or bestRoom ~= r or sOptionName == 'FleeTemperTantrum') then
		return bestRoom:randomLocInRoom(false,true,true)
	end
end

function Character:addNeed(needName,needValue)
	self.tNeeds[needName] = Needs.clamp(self.tNeeds[needName]+needValue)
	--print('Need adjustment',needName,needValue,'new score',self.tNeeds[needName])
end

function Character:updateLights(dt)
	-- TODO: get closest N lights, pass them to shader as directional light

	-- get color for current tile
	local curX,curY = self:getLoc()

    -- only update lighting if we move or once per second
	if not self.lastLoc or self.lastLoc.x ~= curX or self.lastLoc.y ~= curY or not self.nLastLightUpdateTime or GameRules.elapsedTime - self.nLastLightUpdateTime > 1 then 
        self.nLastLightUpdateTime = GameRules.elapsedTime
	    self.lastLoc = {x=curX,y=curY}

	    local ambientLightColor = Lighting.getLightColorForWorld(self:getLoc())

	    -- pass light colors down to shaders
	    self.rCurrentRig:setRigShaderValue('g_vAmbLightColor', ambientLightColor)
	    if self.currentAccessory then
		    self.currentAccessory:setRigShaderValue('g_vAmbLightColor', ambientLightColor)
	    end
    end
end

function Character:_getOxygen()
	if self:isElevated() then return 0 end
	return Oxygen.getOxygen(self:getLoc())
end

function Character:updateOxygen(dt)
    if self.tStats.nRace == Character.RACE_KILLBOT then return end

	local o2 = self:_getOxygen()
	local wx,wy,wz = self:getLoc()
	self:_updateSpacewalking(o2 < Character.OXYGEN_LOW)

	if not GameRules.bProhibitSuffocation and (not self.rSpacesuitRig or not self.rSpacesuitRig:isActive()) then
		local newO2 = o2 - (Character.OXYGEN_PER_SECOND * dt)
		-- MTF TODO: put this back in, but spread out so we don't cause a vacuum when we breathe. :P
		--Oxygen.setOxygen(wx,wy,math.max(0, newO2))

		local tileValue = World.getTileValueFromWorld(wx,wy,wz)
		if tileValue == World.logicalTiles.SPACE then
			-- bonus suffocation while in space
			self.tStatus.suffocationTime = self.tStatus.suffocationTime + 15
			newO2 = 0
		elseif self.tStats.bDoesNotBreathe then
			-- special case: monsters only suffocate in space, not in low-o2 environments. Killbots don't breathe.
			newO2 = math.max(Character.OXYGEN_SUFFOCATING + 1, newO2)
		end

		-- update rolling oxygen average
		local oldestOxygenValue = 0

		if #self.tRecentOxygen < Character.OXYGEN_AVERAGE_SAMPLE then
			self.tRecentOxygen[#self.tRecentOxygen+1] = newO2
		else
			oldestOxygenValue = self.tRecentOxygen[1]
			table.remove(self.tRecentOxygen, 1)
			self.tRecentOxygen[Character.OXYGEN_AVERAGE_SAMPLE] = newO2
		end
		--[[local totalO2 = 0
		for _,o2 in pairs(self.tRecentOxygen) do
		totalO2 = totalO2 + o2
		end]]--
		local totalO2 = self.lastOxygenTotal or 0
		totalO2 = totalO2 - oldestOxygenValue + newO2
		self.lastOxygenTotal = totalO2

		self.nAverageOxygen = totalO2 / #self.tRecentOxygen
		local tLogData = nil
		if newO2 < Character.OXYGEN_SUFFOCATING then
			if self.tStatus.suffocationTime == 0 then
				--spacebase log suffocation
				tLogData = { sOxygenLevel = tostring(totalO2)}
				Log.add(Log.tTypes.DEATH_SUFFOCATION, self, tLogData)
			end
			self.tStatus.suffocationTime = self.tStatus.suffocationTime + dt
			self.tStatus.bLowOxygen = true

			if self.tStatus.suffocationTime >= Character.OXYGEN_SUFFOCATION_UNTIL_DEATH then
				local nCause = Character.CAUSE_OF_DEATH.SUFFOCATION
				if tileValue == World.logicalTiles.SPACE or World.isDestroyedWallAdjacentToSpaceFromWorld(wx,wy,wz) then nCause = Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE end
				CharacterManager.killCharacter(self, nCause)
            else
				if tileValue == World.logicalTiles.SPACE then 
				    CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE)
                end
			end
		elseif newO2 < Character.OXYGEN_LOW then
			if not self.tStatus.bLowOxygen then
				self.tStatus.bLowOxygen = true
				-- spaceface log low oxygen
				if not self:retrieveMemory(Character.MEMORY_LOGGED_MORALE_RECENTLY) then
					tLogData = { sOxygenLevel = tostring(totalO2) }
					Log.add(Log.tTypes.MORALE_LOW_OXYGEN, self, tLogData)
					self:storeMemory(Character.MEMORY_LOGGED_MORALE_RECENTLY, true, Character.LOG_MORALE_NEEDS_RATE)
				end
			end
		else
			if self.tStatus.suffocationTime > 0 then
				if self.tStatus.suffocationTime == 0 then
					--spacebase log suffocation relief
					tLogData = { sOxygenLevel = tostring(totalO2)}
					Log.add(Log.tTypes.MORALE_HIGH_OXYGEN, self, tLogData)
				end
			end
			self.tStatus.bLowOxygen = false
			self.tStatus.suffocationTime = 0
		end
	end
	-- MTF: hack until we implement a general 'remove this outfit when it's no longer necessary' system
	-- for all job outfits.
	if self.tStatus.nUnnecessarySpacesuit ~= nil then
		self.tStatus.nUnnecessarySpacesuit = self.tStatus.nUnnecessarySpacesuit + dt
		if self.tStatus.nUnnecessarySpacesuit > self.UNNECESSARY_SPACESUIT_REMOVE or (self.tStatus.suffocationTime and self.tStatus.suffocationTime > 0) then
			self:spacesuitOff()
		end
		-- tick suit oxygen
	elseif self:wearingSpacesuit() and not GameRules.bProhibitSuffocation then
		local nPreviousSuitOxygen = self.tStatus.suitOxygen
		self.tStatus.suitOxygen = self.tStatus.suitOxygen - Character.OXYGEN_PER_SECOND * dt
		-- start suffocating if depleted
		local bLowSuitOxygen = self.tStatus.bLowOxygen or self.tStatus.suitOxygen < Character.SPACESUIT_OXYGEN_SUFFOCATING
		if not bLowSuitOxygen then
			local nNearest
			local tAirlocks = Room.getPlayerOwnedFunctionalAirlocks()
			local tx,ty = self:getTileLoc()

			for rAirlockRoom,_ in pairs(tAirlocks) do
				local _,_,atx,aty = rAirlockRoom.zoneObj:_getTileOutsideAirlock(true)
				if atx then 
					local awx,awy = World._getWorldFromTile(atx,aty)
					local nDist = DFMath.distance2DSquared(wx,wy,awx,awy)
					if not nNearest or nDist < nNearest then
						nNearest = nDist
					end
				end
			end
			if nNearest then
				local nTime = math.sqrt(nNearest) / self:getAdjustedSpeed()
				if nTime + 45 > self.tStatus.suitOxygen / Character.OXYGEN_PER_SECOND then
					bLowSuitOxygen = true
				end
			end
		end
		if bLowSuitOxygen then
			self.tStatus.bLowOxygen = true
			if self.tStatus.suitOxygen < Character.SPACESUIT_OXYGEN_SUFFOCATING then
				self.tStatus.suffocationTime = self.tStatus.suffocationTime + dt
				-- alert?
				if nPreviousSuitOxygen > Character.SPACESUIT_OXYGEN_SUFFOCATING then
                    Base.eventOccurred(Base.EVENTS.CitizenSuffocating, {rReporter=self})
				end
			end
		end
		-- die if fully suffocated
		if self.tStatus.suffocationTime >= Character.OXYGEN_SUFFOCATION_UNTIL_DEATH then
			CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.SUFFOCATION)
		end
	end
end

function Character:_updateSpacewalking(bLowOxygen)
	--local oldVal = self.tStatus.bSpacewalking
	local bSpacesuitActive = self:wearingSpacesuit()
	--self.tStatus.bSpacewalking = bLowOxygen and bSpacesuitActive
	self.tStatus.bSpacewalking = bSpacesuitActive
	if self.tStatus.bSpacewalking or not bLowOxygen then self.tStatus.bLowOxygen = false end

	if not bLowOxygen and bSpacesuitActive then
		local r = self:getRoom()
		if r and r ~= Room.getSpaceRoom() and r.zoneName ~= 'AIRLOCK' and not r:isBreached() and not (self.rCurrentTask and self.rCurrentTask:requireSpacesuit()) then
			if not self.tStatus.nUnnecessarySpacesuit then
				self.tStatus.nUnnecessarySpacesuit = 0
			end
		else
			self.tStatus.nUnnecessarySpacesuit = nil
		end
	else
		self.tStatus.nUnnecessarySpacesuit = nil
	end
end

function Character:canDeElevate()
	if not self:isElevated() then return false end
	local val = World.getTileValueFromWorld(self:getLoc())
	if val ~= World.logicalTiles.SPACE then
		return false
	end
	return true
end

function Character:setElevatedSpacewalk(bElevated, bForce)
	if bElevated == self.tStatus.bElevatedSpacewalk and not bForce then return end

	if self.tStatus.bElevatedSpacewalk and not bElevated and not self:canDeElevate() then
		Print(TT_Warning, 'CHARACTER.LUA: Ignoring request to de-elevate character inside.')
		return
	end

	if bElevated then assert(self:spacewalking()) end
	local rOldRenderLayer
	local rNewRenderLayer
	local nPri = 0
	if bElevated then
		--self:_setHighlightColor(1,0,1,1)
		rOldRenderLayer = Renderer.getRenderLayer(Character.RENDER_LAYER)
		rNewRenderLayer = Renderer.getRenderLayer(Character.BACKGROUND_RENDER_LAYER)
		--self:setScl(self.nScale*.75)
	else
		--self:_setHighlightColor()
		rOldRenderLayer = Renderer.getRenderLayer(Character.BACKGROUND_RENDER_LAYER)
		rNewRenderLayer = Renderer.getRenderLayer(Character.RENDER_LAYER)
		self:setScl(self.nScale)
	end
	self.rTargetRenderLayer = rNewRenderLayer
	if self.bVisible then self.tHackEntity:setRenderLayer(rNewRenderLayer) end
	self.rCurrentRig:deactivate()
	self.rCurrentRig:activate()

	self.tStatus.bElevatedSpacewalk = bElevated
end

function Character:_setColor(r,g,b,a)
	if self.rRig and self.rRig.rMainMesh then
		self.rRig.rMainMesh:setColor(r,g,b,a)
	end
end

function Character:isElevated()
	return self.tStatus.bElevatedSpacewalk
end

function Character:spacewalking()
	return self.tStatus.bSpacewalking
end

function Character:wearingSpacesuit()
	return self.rSpacesuitRig and self.rSpacesuitRig:isActive()
end

function Character:inSpace()
	local tileValue = World.getTileValueFromWorld(self:getLoc())
	return tileValue == World.logicalTiles.SPACE
end

function Character:inVacuum()
	-- MTF TODO / TEMP HACK
	-- Vacuum currently forms in airlocks, and it shouldn't.
	-- Need to fix vacuum calculation.
	-- In the meantime, dudes in spacesuits are immune.
	if self:wearingSpacesuit() then
		self.bWasInVacuum = false
		return false
	end

	local bInVacuum = false

	local tileValue = World.getTileValueFromWorld(self:getLoc())
	if tileValue == World.logicalTiles.SPACE or World.isDestroyedWallAdjacentToSpaceFromWorld(self:getLoc()) then
		bInVacuum = true
	elseif GameRules.bProhibitSuffocation then
	else
		if CharacterManager.bDBGExtendedProfiler then
			Profile.enterScope("InVacuum")
		end
		local vx,vy,mag = Oxygen.getVacuumVec(self:getLoc())

		if self.bWasInVacuum then
			bInVacuum = not (mag < Oxygen.VACUUM_THRESHOLD_END)
		else
			bInVacuum = (mag > Oxygen.VACUUM_THRESHOLD)
		end

		if CharacterManager.bDBGExtendedProfiler then
			Profile.leaveScope("InVacuum")
		end
	end

	self.bWasInVacuum = bInVacuum

	return bInVacuum
end

function Character:isBrawling(rOther)
	local otherTag = ObjectList.getTag(rOther)
	return otherTag and self.tStatus.tBrawlingWith[otherTag]
end

function Character:startBrawling(rOther)
	-- use tags for save safety
	local otherTag = ObjectList.getTag(rOther)
	if otherTag then
		self.tStatus.tBrawlingWith[otherTag] = GameRules.elapsedTime
	end
	-- increase anger of other people in room
	local rRoom = self:getRoom()
	if not rRoom or rRoom == Room.rSpaceRoom then
		return
	end
	local tChars,_ = rRoom:getCharactersInRoom()
	for rChar,_ in pairs(tChars) do
		if rChar ~= self and rChar ~= rOther then
			-- divide by two, as this will run twice (once for each brawler)
			rChar:angerEvent(Character.ANGER_NEARBY_BRAWL / 2)
		end
	end
end

function Character:stopBrawling(rOther)
	local otherTag = ObjectList.getTag(rOther)
	if otherTag then
		self.tStatus.tBrawlingWith[otherTag] = nil
	end
	-- if the other person thinks they're brawling with us, stop them brawling
	if rOther:isBrawling(self) then
		rOther:stopBrawling(self)
	end
end

-- should self attack target
function Character:shouldTargetForAttack(rTarget)
    if rTarget == self or rTarget:isDead() or self.tStatus.bCuffed or self:inPrison() then return false end
    
    local nFactionBehavior = self:getFactionBehavior()
    if nFactionBehavior == Character.FACTION_BEHAVIOR.Citizen or nFactionBehavior == Character.FACTION_BEHAVIOR.Friendly then
        -- Friendly characters don't attack imprisoned or cuffed people.
        if rTarget.tStatus.bCuffed or rTarget:inPrison() then return false end
    end

	-- only security targets marked
	if self.tStats.nJob == Character.EMERGENCY and rTarget.tStatus.bMarkedForExecution then
		return true
	end
	-- marked citizens fight back once attacked
	if self.tStatus.bMarkedForExecution and rTarget.tStats.nJob == Character.EMERGENCY then
		if self:retrieveMemory(Character.MEMORY_TOOK_DAMAGE_RECENTLY) then
			return true
		end
	end
	
    if self:hasUtilityStatus(Character.STATUS_RAMPAGE_VIOLENT) then return true end
    
    local bIncapacitated = Malady.isIncapacitated(rTarget)
    local bHuman = rTarget.nRace ~= Character.RACE_MONSTER and rTarget.nRace ~= Character.RACE_KILLBOT
    local bHates = self:_hates(rTarget)
    if bHates then
        if nFactionBehavior ~= Character.FACTION_BEHAVIOR.Citizen and nFactionBehavior ~= Character.FACTION_BEHAVIOR.Friendly then
            return true
        end
        return not bIncapacitated or not bHuman or g_ERBeacon:getViolence(self.squadName) == EmergencyBeacon.VIOLENCE_LETHAL
    end
    
    -- brawlers only try to incapacitate their opponent
    if self:isBrawling(rTarget) then
		-- stop brawling, don't kill em!
        if bIncapacitated or rTarget:isDead() then
			self:stopBrawling(rTarget)
            return false
        else
            return true
        end
        -- if we get incapacitated, stop brawling
        if Malady.isIncapacitated(self) then
			self:stopBrawling(rTarget)
            return false
        end
    end

    if rTarget:hasUtilityStatus(Character.STATUS_RAMPAGE) and rTarget.tStatus.bRampageObserved then 
        if bIncapacitated then 
            return g_ERBeacon:getViolence(self.squadName) == EmergencyBeacon.VIOLENCE_LETHAL 
        end
        return true
    end

    if (rTarget:hasUtilityStatus(Character.STATUS_RAMPAGE) or rTarget.tStatus.tAssignedToBrig) and not bIncapacitated then
        if rTarget:getCurrentTaskTag('NonThreatening') then return false end
        -- Target should be in brig but isn't there, isn't cuffed, isn't incapacitated.
        -- They're probably doing survival-level stuff. But if we're beaconed onto them
        -- let's go ahead and beat them up.
        if g_ERBeacon.rTargetObject == rTarget and self:getJob() == Character.EMERGENCY then
            return true
        end
    end
        
    return false
end

-- how big of a threat am I to someone else?
function Character:_getThreatLevel(rVictim)
    if rVictim:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen then
        if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return Character.THREAT_LEVEL.Monster end
    end
    
--    if self.tStats.nJob == Character.RAIDER then return Character.THREAT_LEVEL.Raider end
    if self:getFactionBehavior() ~= rVictim:getFactionBehavior() then return Character.THREAT_LEVEL.Raider end
    if self:hasUtilityStatus(Character.STATUS_RAMPAGE_VIOLENT) then return Character.THREAT_LEVEL.BadCitizen end
    return Character.THREAT_LEVEL.NormalCitizen
end

-- Looks for characters in site radius w/in current room.
-- If it sees one, it'll add that to the combat memories.
function Character:_lookForEnemies(rRoom, bTestSightRadius, bStoreMemory)
	rRoom = rRoom or self.rCurrentRoom
    local nThreatLevel = 0
    local rLastThreat = nil
	if rRoom and not rRoom.bDestroyed then
		local tChars = rRoom:getCharactersInRoom(false)
		local tx,ty,tw = self:getTileLoc()
		for rChar,_ in pairs(tChars) do
            local etx,ety = rChar:getTileLoc()
			if not bTestSightRadius or MiscUtil.isoDist(tx,ty, etx,ety) < Character.SIGHT_RADIUS then
                if self:shouldTargetForAttack(rChar) then
                    local nCharThreat = rChar:_getThreatLevel(self)
                    if nCharThreat > nThreatLevel then
                        nThreatLevel = nCharThreat
                        rLastThreat = rChar
                        self:combatAlert(rRoom,rChar,rChar:getTileLoc())
                    end
                    if nThreatLevel > Character.THREAT_LEVEL.NormalCitizen then
                        return nThreatLevel,rLastThreat
                    end
                end
			end
		end
        if nThreatLevel < Character.THREAT_LEVEL.Turret then
            for rProp,_ in pairs(rRoom.tProps) do
                if rProp:isHostileTo(self) then
                    local nPropThreat = rProp:getThreatLevel()
                    local etx,ety = rProp:getTileLoc()
                    if nPropThreat >= Character.THREAT_LEVEL.Turret and (not bTestSightRadius or MiscUtil.isoDist(tx,ty, etx,ety) < Character.SIGHT_RADIUS) then
                        if bStoreMemory then
                            self:combatAlert(rRoom,rProp,rProp:getTileLoc())
                        end
                        return nPropThreat, rProp
                    end
                end
            end
        end
	end
    return nThreatLevel,rLastThreat
end

function Character:_testFireVisibility(r)
	if r.bBurning then
		local tFires = r:getFiresInRoom()
		if not tFires then return end
		local tx,ty,tw = self:getTileLoc()
		for addr,_ in pairs(tFires) do
			if MiscUtil.isoDist(tx,ty, World.pathGrid:cellAddrToCoord(addr)) < Character.SIGHT_RADIUS then
				return true
			end
		end
	end
end

-- return: flamingRoomRef, bCurrentRoom
function Character:_lookForFire()
	local r = self:getRoom()
	if r and r ~= Room.getSpaceRoom() then
		if self:_testFireVisibility(r) then return r,true end
		local tAdjoining = r:getAccessibleByDoor()
		for r,_ in pairs(tAdjoining) do
			if self:_testFireVisibility(r) then
				return r, false
			end
		end
	end
end

function Character:forceTask(rTask)
	if self.rCurrentTask == rTask
	or self:getCurrentTaskPriority() == OptionData.tPriorities.PUPPET or self:isDead() then
		return
	end

	if self.rCurrentTask and not self.rCurrentTask.bComplete then
		self.rCurrentTask:interrupt(self.tStats.sUniqueID .. " forcing "..rTask.activityName)
	end

	self.rCurrentTask = rTask
	self:_newTaskStarted(rTask)
end

function Character:_updateRoom()
	if self.rCurrentRoom and self.rCurrentRoom.bDestroyed then
		self.rCurrentRoom = nil
	end

	local tx,ty,tw = self:getTileLoc()
	local rRoom = Room.getRoomAtTile(tx,ty,tw)

	if tw == 1 and not rRoom then
		local rDoor = ObjectList.getDoorAtTile(tx,ty)
		if rDoor then
			local rE,rW = rDoor:getRooms()
			if self.rCurrentRoom then
				if self.rCurrentRoom == rE then rRoom = rE
				elseif self.rCurrentRoom == rW then rRoom = rW
				else
					rRoom = rE or rW
				end
			else
				rRoom = rE or rW
			end
		end
	end
    rRoom = rRoom or Room.getSpaceRoom()
	-- room on fire?
	if rRoom.bBurning and not self:logTypePostedRecently('DISASTER_FIRE', 10) then
		Log.add(Log.tTypes.DISASTER_FIRE, self)
	end
	-- rooms clear out their characters list in setTiles.
	-- We could fix it up there, but instead we just allow this function
	-- to re-add the character to the room by checking the room's bookkeeping here.
	if rRoom == self.rCurrentRoom and self.rCurrentRoom.tCharacters[self] then return end

	if self.rCurrentRoom and self.rCurrentRoom ~= rRoom then
		self.rCurrentRoom:removeCharacter(self)
	end
	self.rCurrentRoom = rRoom
	self.rCurrentRoom:addCharacter(self)
	self.tMemory.tRooms[rRoom.id] = GameRules.simTime
	-- log about breached room if we haven't
	if self.rCurrentRoom:isBreached() and not self:spacewalking() and not self:logTypePostedRecently('DISASTER_BREACH') then
        Log.add(Log.tTypes.DISASTER_BREACH, self)
	end
end

function Character:getAttackRange(rTarget)
    local bLethal = self:_shouldAttackLethal(rTarget)
    local sBest = self:_getBestWeaponInInventory(bLethal)
    local sTemplate
    if sBest then
        sTemplate = self.tInventory[sBest].sTemplate
    end
    if not sTemplate then sTemplate = self:_getAutocreateWeaponTemplate(bLethal) end
    if sTemplate then
        return InventoryData.tTemplates[sTemplate].nRange
    end
    return Character.MELEE_RANGE
end

-- Returns a damage table:
--  nDamage: amount
--  nAttackType: ranged or melee
--  nDamageType
--  sWeapon: weapon name
function Character:getAttackDamage()
    local tDmg = {}
    tDmg.nAttackType = self:getAttackType()
    tDmg.sWeapon = self.sDrawnWeapon
    local tWeapon = self.tInventory[self.sDrawnWeapon]

    if tWeapon then
        tDmg.nDamage,tDmg.nDamageType = Inventory.getWeaponData(tWeapon)
	elseif self.tStats.nRace == Character.RACE_MONSTER then
		tDmg.nDamage = Character.MONSTER_MELEE_DAMAGE
        tDmg.nDamageType = Character.DAMAGE_TYPE.Melee
	else
	    tDmg.nDamage = Character.HUMAN_MELEE_DAMAGE
        tDmg.nDamageType = Character.DAMAGE_TYPE.Melee
	end

    -- Can increase damage up to 1.5x
    local nTeamTacticsBonus = self:_getTeamTacticsCount()
    nTeamTacticsBonus = 1 + nTeamTacticsBonus * .1
	tDmg.nDamage = tDmg.nDamage * nTeamTacticsBonus

    return tDmg
end

function Character:shootAt(rVictim, sAttachJointName, tOffset)
    -- look at target
    local tx,ty = rVictim:getLoc()
    self:faceWorld(tx,ty, false)
    
    -- Get the attach joint, use default if needed
    local rJointProp = self.rCurrentRig:getJointProp( sAttachJointName or self.DEFAULT_PROJECTILE_ATTACH_JOINT )
    
    -- location for the joint
    local jointX,jointY,jointZ = rJointProp:getWorldLoc()
    local cx,cy = self:getLoc()
    
    -- Add offset to move from the joint to the muzzle
    tOffset = tOffset or self.DEFAULT_PROJECTILE_ATTACH_OFFSET
    local offsetX,offsetY = tOffset[1], tOffset[2]
    jointX, jointY = jointX + offsetX, jointY + offsetY
    
    -- Initialize the damage information for the projectile
    local tDamage = self:getAttackDamage()
    
    -- Create projectile and send it on its way
    local bullet = Projectile.new(jointX,jointY, nil, true, nil)
    local sSpriteName = Character.SPRITE_NAME_FRIENDLY
	-- "good guy bullets" vs "bad guy bullets" :]
    if not Base.isFriendlyToPlayer(self) then
        local tWeapon = self.sDrawnWeapon and self.tInventory[self.sDrawnWeapon]
        local nDmg = tWeapon and Inventory.getWeaponData(tWeapon)
        if nDmg and nDmg >= 25 then
            sSpriteName = Character.SPRITE_NAME_ENEMY_RIFLE
        else
            sSpriteName = Character.SPRITE_NAME_ENEMY_PISTOL
        end
    else
        local tWeapon = self.sDrawnWeapon and self.tInventory[self.sDrawnWeapon]
        local nDmg = tWeapon and Inventory.getWeaponData(tWeapon)
        if nDmg and nDmg >= 25 then
            sSpriteName = Character.SPRITE_NAME_FRIENDLY_RIFLE
        else
            sSpriteName = Character.SPRITE_NAME_FRIENDLY_PISTOL
        end
    end
	bullet:setSprite(sSpriteName,'SpriteAnims/Effects')
    -- Constrain to path
    local ctx,cty = self:getTileLoc()
    local ttx,tty = rVictim:getTileLoc()
    local tPathConstraint = GridUtil.GetTilesForLine(ctx,cty, ttx,tty)
    bullet:setPathConstraint({jointX-cx, jointY-cy}, tPathConstraint)
    bullet:fireAtTarget(rVictim, self, tDamage)
    return bullet
end

-- ranged or grapple.
function Character:getAttackType()
    local tWeapon = self.sDrawnWeapon and self.tInventory[self.sDrawnWeapon]
    if tWeapon then
        local _,_,nRange = Inventory.getWeaponData(tWeapon)
        if nRange and nRange > 0 then
            return Character.ATTACK_TYPE.Ranged
        end
    end
	return Character.ATTACK_TYPE.Grapple
end

function Character:canMelee()
	if self.tStats.nRace == Character.RACE_KILLBOT then
		return false
	end
	return true
end

function Character:getNeedsReduceRate()
    local tMod = Malady.getNeedsReduceMods(self)
    if self:inPrison() then
        tMod = tMod or {}
        tMod['Duty'] = 0
    end
    return tMod or {}
end

function Character:_updateObjectAffinities()
    for sName,tItemTag in pairs(self.tOwnedStuff) do
        local tItem = ObjectList.getObject(tItemTag)
        if tItem then
            local nAff = self:getObjectAffinity(tItem)
            nAff = nAff - Inventory.getAffinityDecay(tItem)
            self.tAffinity[tItem.sName] = math.max(nAff,0)
        else
            self.tOwnedStuff[sName] = nil
        end
    end
end

function Character:assignedToBrig(rRoom)
    if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return end
    local bReassignment = self.tStatus.tAssignedToBrig ~= nil
    local tag = rRoom and ObjectList.getTag(rRoom)
    if tag == self.tStatus.tAssignedToBrig then return end

    local rPrev = ObjectList.getObject(self.tStatus.tAssignedToBrig)
    if rPrev and rPrev:getZoneName() == 'BRIG' then
        rPrev:getZoneObj():unassignChar(self)
    end

    if not rRoom then
        self.tStatus.tAssignedToBrig = nil
        return
    end

    self.tStatus.tAssignedToBrig = tag
    rRoom:getZoneObj():charAssigned(self)

    if not bReassignment then
		local bIncapacitated = Malady.isIncapacitated(self)
        if not self.tStatus.bCuffed and not self:retrieveMemory(Character.MEMORY_PRISON_ANGER_RECENTLY) then
            self:storeMemory(Character.MEMORY_PRISON_ANGER_RECENTLY, true, 120)
            self:angerEvent(Character.ANGER_MAX * (1-self:getPersonalityStat('nAuthoritarian')))
        end
		local tLogType = Log.tTypes.BRIG_ASSIGN_INCAPACITATED
		if not Malady.isIncapacitated(self) then
			tLogType = Log.tTypes.BRIG_ASSIGN_NOT_INCAPACITATED
		end
		Log.add(tLogType, self)
    end
    self:reevaluateTask()
end

function Character:updateAI(dt)
	if not self:isDead() then self.nLifetime = (self.nLifetime or 0) + dt end

    if self:getFactionBehavior() ~= self.nLastFactionBehavior then
        self:_factionSetup()
    end

	-- do spaceface log spawn on first update instead of init, as some
	-- important things haven't happened at that point.
	if #self.tLogQueue == 0 and #self.tLog == 0 then
		if self:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen or self:getFactionBehavior() == Character.FACTION_BEHAVIOR.Friendly then
			Log.add(Log.tTypes.JOINED, self)
		else
			Log.add(Log.tTypes.ENEMY_JOINED, self)
		end
	end
	
	self:_updateRoom()

    Malady.tickMaladies(self)

    if not self.survivalTimer then
    else
        self.survivalTimer = self.survivalTimer - dt
    end
	if not self.survivalTimer or self.survivalTimer < dt then
        if self.tStats.nTimeToConvert and self:inPrison() and self:getRoom() and self:getRoom():getVisibility() == World.VISIBILITY_FULL and self.tStatus.nAnger < .7 * Character.ANGER_MAX then
            self.tStats.nTimeToConvert = self.tStats.nTimeToConvert - 1
            if self.tStats.nTimeToConvert < 0 then
                self:_convert()
            end
        end

		Profile.enterScope("SurvivalThreats")
		self:_testSurvivalThreats()
		Profile.leaveScope("SurvivalThreats")
        if self.tStatus.bRampageViolent then
            local _,nChars = CharacterManager.getTeamCharacters(self:getTeam())
            if nChars <= 1 then
                self:endRampage()
            end
        end
        if CharacterManager.bFirstTime then
            self.survivalTimer = nil
        end
	end

	self.tStatus.nRemainingDutyTime = self.tStatus.nRemainingDutyTime - dt

	self.needsReduce = self.needsReduce - dt
	if self.needsReduce < 0 and 
            (
                self:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen or
                (self:getRoom() and self:getRoom():getVisibility() == World.VISIBILITY_FULL)
            ) then
		self.needsReduce = Character.NEEDS_REDUCE_TICK
        local tNeedsReduceMods = self:getNeedsReduceRate()
        for k,_ in pairs(Needs.tNeedList) do
			if self.rCurrentTask and self.rCurrentTask.tPromisedNeeds[k] then
				-- don't modify needs that are going to be modified by this activity
			else
                local nMod = tNeedsReduceMods[k] or 1
				self.tNeeds[k] = Needs.clamp(self.tNeeds[k] - 1*nMod)
			end
		end

        -- hack: while in prison, tend duty towards 0.
        if self:inPrison() then
            if math.abs(self.tNeeds['Duty']) < 1 then self.tNeeds['Duty'] = 0
            elseif self.tNeeds['Duty'] > 0 then self.tNeeds['Duty'] = self.tNeeds['Duty'] - 1 
            else self.tNeeds['Duty'] = self.tNeeds['Duty'] + 1 end
        end

        self:_updateObjectAffinities()
	end

	self.moraleTimer = self.moraleTimer - dt
	if self.moraleTimer < 0 then
		self.moraleTimer = Character.MORALE_TICK
		self:tickMorale()
	end

	self.graphTimer = self.graphTimer - dt
	if self.graphTimer < 0 then
		self.graphTimer = Character.GRAPH_TICK_RATE
		self:tickGraph()
	end

	self.roomMoraleTimer = self.roomMoraleTimer - dt
	if self.roomMoraleTimer < 0 then
		self.roomMoraleTimer = Character.ROOM_MORALE_TICK
		self:tickRoomMorale()
	end
	
	if not self:retrieveMemory(Character.MEMORY_LOGGED_RECENTLY) then
		local bLogged = self:postLogFromQueue()
		if bLogged then
			local nRate = DFMath.lerp(Character.LOG_RATE_MAX, Character.LOG_RATE_MIN, self.tStats.tPersonality.nChattiness)
			self:storeMemory(Character.MEMORY_LOGGED_RECENTLY, true, nRate)
			-- flush queue
			self.tLogQueue = {}
		end
	end
	
	self.oxygenTimer = self.oxygenTimer - dt
	if self.oxygenTimer < 0 then
		if CharacterManager.bDBGExtendedProfiler then
			Profile.enterScope("CharacterOxygen")
		end
		self:updateOxygen(Character.OXYGEN_TICK + math.abs(self.oxygenTimer))
		if CharacterManager.bDBGExtendedProfiler then
			Profile.leaveScope("CharacterOxygen")
		end
		self.oxygenTimer = Character.OXYGEN_TICK
	end

	-- starving?
	local bIsRobot = self.tStats.nRace == Character.RACE_KILLBOT
	if not bIsRobot and self:starving() then
		self.tStatus.nStarveTime = self.tStatus.nStarveTime + dt
		-- die of starvation :[
		if not self:isDead() and self.tStatus.nStarveTime > Character.TIME_BEFORE_STARVATION then
			-- spaceface
			Log.add(Log.tTypes.DEATH_STARVATION, self)
			-- die
			CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.STARVATION)
		end
		-- not starving now, yei
	elseif self.tStatus.nStarveTime > 0 then
		self.tStatus.nStarveTime = 0
	end

	self:tickHealOverTime(dt)
	self:tickFireDamage(dt)
	-- give job experience for doing the job, don't give xp to raiders and the unemployed
	if self.tStats.tJobExperience[self.tStats.nJob] and self:isPerformingWorkShiftTask() then
		self:addJobExperience(self.tStats.nJob, Character.JOB_EXPERIENCE_RATE * dt)
		self.tStats.tHistory['TotalTimeAs'..self.tStats.nJob] = dt + (self.tStats.tHistory['TotalTimeAs'..self.tStats.nJob] or 0)
	end

	if not self.rCurrentTask then
		self.nWaitingTime = self.nWaitingTime+dt
		-- FIXME: Too spammy due to Trader
		--if self.nWaitingTime > 5 then
		--	print(TT_Warning,'Character stalled waiting on task update.',self:getUniqueID(),self.nWaitingTime)
		--end
		-- waiting for CharacterManager to get around to updating us.
	else
		--local key = "Task"..self.rCurrentTask.activityName
		--Profile.enterScope(key)
		if self.rCurrentTask:update(dt) then
			self.rCurrentTask = nil
			self:selectNewTask()
		end
		--Profile.leaveScope(key)
	end

	--JM: check if in space for blob shadows. If this is evil, please delete

	if self.rBlobShadow then
        local spaceTile = World.getTileValueFromWorld(self:getLoc())
		if spaceTile == World.logicalTiles.SPACE then
			self.rBlobShadow.bVisible = false
		else
			self.rBlobShadow.bVisible = true
		end
	end
	
    self:_dutyTick()
end

function Character:_dutyTick(dt)
    local job = self:getJob()
    if job == Character.EMERGENCY then
	    -- security log about patrolling
	    if self.rCurrentTask and self.rCurrentTask.activityName == 'Patrol' and not self:retrieveMemory(Character.MEMORY_LOGGED_PATROL_RECENTLY) then
		    Log.add(Log.tTypes.DUTY_SECURITY_PATROL, self)
		    self:storeMemory(Character.MEMORY_LOGGED_PATROL_RECENTLY, true, Character.PATROL_LOG_FREQUENCY)
	    end
    end
end

function Character:_convert()
	-- raider becoming a citizen
    self.tStats.nTimeToConvert = nil
	self.tStats.sName = CitizenNames.getNewUniqueName(self.tStats.nRace, self.sSex)
    self:setTeam(Character.TEAM_ID_PLAYER)
	Base.incrementStat('nRaidersConverted')
end

-- MTF HACK: This is a hack to allow builders to fix breaches.
-- Specifically, it tests if the character is trying to put on a suit already, and if so it
-- ignores the breach threat.
-- Should possibly be a more explicit system to allow tasks to ignore certain threat types.
function Character:_ignoreBreachThreats()
    if self.tStats.bIgnoreBreachThreats then return true end
	if not self.rCurrentRoom or self.rCurrentRoom == Room.getSpaceRoom() then return true end
	if self:wearingSpacesuit() then return true end
	if not self.rCurrentTask then return false end
	local rTask = self.rCurrentTask:getLeafTask()
	local tSatisfies = rTask.rActivityOption and rTask.rActivityOption.tSatisfies
	return tSatisfies and tSatisfies['WearingSuit']
end

-- adjusts our threat level.
-- can also force vacuum.
-- MTF TODO: this can find survival threats that are non-actionable. So we'll flag that we need a new
-- task assigned, but then UtilityAI will run and not find anything. That forces decision thrashing
-- that can hurt framerate and delay decision-making for other characters.
function Character:_testSurvivalThreats()
	self.survivalTimer = .5 * Character.SURVIVAL_TICK + math.random()*Character.SURVIVAL_TICK
	if self:getCurrentTaskPriority() == OptionData.tPriorities.PUPPET then
		return
	end

	local nThreat = OptionData.tPriorities.NORMAL

    if Malady.isIncapacitated(self) then
        -- nothing we can do about it!
        self.nThreat = OptionData.tPriorities.NORMAL
        return
    end
    
    if self.tStatus.tAssignedToBrig then
        local rRoom = ObjectList.getObject(self.tStatus.tAssignedToBrig)
        if not rRoom or rRoom:getZoneName() ~= 'BRIG' then
            self.tStatus.tAssignedToBrig = nil
			-- "i'm breaking out" log
			Log.add(Log.tTypes.BRIG_ESCAPE, self)
        end
    end
    if self.tStatus.tImprisonedIn then
        local rRoom = self:getRoom()
        if self.tStatus.tAssignedToBrig ~= self.tStatus.tImprisonedIn or not rRoom or ObjectList.getTag(rRoom) ~= self.tStatus.tImprisonedIn or rRoom:getZoneName() ~= 'BRIG' then
            local rOldBrig = ObjectList.getObject(self.tStatus.tImprisonedIn)
            if rOldBrig and rOldBrig:getZoneName() == 'BRIG' then
                rOldBrig:getZoneObj():unassignChar(self)
            end
            self.tStatus.tImprisonedIn = nil
            self:_updateGatherers()
        end
        if self.tStatus.tImprisonedIn then
            local bCanEscape = false
            -- still in prison? let's do a test to see if we can escape.
            -- Rather hacky, but so many things gate on inPrison that we need to look for ways
            -- to get the character out of the room.
            local rBrigRoom = ObjectList.getObject(self.tStatus.tImprisonedIn)
            if rBrigRoom then
                local tx,ty = self:getTileLoc()
                local tDoors = rBrigRoom:getReachableDoors(tx,ty)
                for rDoor,_ in pairs(tDoors) do
                    if not rDoor:locked(self) then
                        bCanEscape = true
                    end
                end
            end
            if bCanEscape then
                if not self.nEscapeTicks then self.nEscapeTicks = 1
                else self.nEscapeTicks = self.nEscapeTicks + 1 end
                if self.nEscapeTicks > 10 then
                    self.tStatus.tAssignedToBrig = nil
                    self.tStatus.tImprisonedIn = nil
                    rBrigRoom:getZoneObj():unassignChar(self)
                    self:_updateGatherers()
					-- "i'm breaking out" log
					Log.add(Log.tTypes.BRIG_ESCAPE, self)
					-- alert
					local tParams = {
						rReporter = self,
						sName = self.tStats.sName,
						sRoom = rBrigRoom.uniqueZoneName,
					}
					Base.eventOccurred(Base.EVENTS.BrigEscaped, tParams)
                end
            else
                self.nEscapeTicks = nil
            end
        end
    end

	if CharacterManager.bDBGExtendedProfiler then
		Profile.enterScope("look for enemies")
	end
	self:_lookForEnemies(nil, true, true)
	if CharacterManager.bDBGExtendedProfiler then
		Profile.leaveScope("look for enemies")
	end

	local bBreached = self.rCurrentRoom and self.rCurrentRoom:isBreached()
	if bBreached then
		self:storeMemory(Character.MEMORY_ROOM_BREACHED_PREFIX..self.rCurrentRoom.id, true, 60)
	end
	local bLowO2 = self.rCurrentRoom and (self.rCurrentRoom.bPendingBreach or self.rCurrentRoom:getOxygenScore() < Character.OXYGEN_LOW)
	if bLowO2 then
		self:storeMemory(Character.MEMORY_ROOM_LOWO2_PREFIX..self.rCurrentRoom.id, true, 60)
	end

	if self:inVacuum() then
		-- Special case: vacuum doesn't wait for CharacterManager.
		self.nThreat = nThreat
		self.sThreatSource='vacuum'
		local rTask = GlobalObjects.getVacuumActivityOption():createTask(self, 0)
		self:forceTask(rTask)
		return
	elseif self.tStatus.bLowOxygen then
		nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
		self.sThreatSource='low oxygen'
	elseif (bBreached or bLowO2) and not self:_ignoreBreachThreats() then
		nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
		self.sThreatSource='breach or low o2'
	elseif self.rCurrentRoom and self.rCurrentRoom:isEmergencyAlarmOn() and self:getTeam() == Character.TEAM_ID_PLAYER then
		nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
		self.sThreatSource='alarm'
	elseif self:starving() then
		nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
		self.sThreatSource='starving'
	else
		local bThreat,nThreatLevel,rThreat = self:hasCombatAwarenessIn(self.rCurrentRoom)
		if bThreat and nThreatLevel > Character.THREAT_LEVEL.NormalCitizen then
			nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
			self.sThreatSource='combat, current room'
		elseif self.rCurrentRoom then
			local tNearbyRooms = self.rCurrentRoom:getAccessibleByDoor()
			for room,_ in pairs(tNearbyRooms) do
		        local bAdjThreat,nAdjThreatLevel,rAdjThreat = self:hasCombatAwarenessIn(room)
		        if bAdjThreat and nAdjThreatLevel > Character.THREAT_LEVEL.NormalCitizen then
					nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
					self.sThreatSource='combat, nearby room'
					break
				end
			end
		end
        if nThreat < OptionData.tPriorities.SURVIVAL_LOW and bThreat then
            nThreat = OptionData.tPriorities.SURVIVAL_LOW
            self.sThreatSource='brawl,current or nearby room'
        end

		if CharacterManager.bDBGExtendedProfiler then
			Profile.enterScope("FireThreat")
		end
		if nThreat < OptionData.tPriorities.SURVIVAL_NORMAL and not self.tStats.bIgnoreFire then
			local rFireRoom, bFireCurrentRoom = self:_lookForFire()
			if bFireCurrentRoom then
				self:storeMemory(Character.MEMORY_ROOM_FIRE_PREFIX..self.rCurrentRoom.id, true, 60)
				nThreat = OptionData.tPriorities.SURVIVAL_NORMAL
				self.sThreatSource='fire, current room'
			end
		end
		if CharacterManager.bDBGExtendedProfiler then
			Profile.leaveScope("FireThreat")
		end
	end

    if nThreat < OptionData.tPriorities.SURVIVAL_LOW and self:_shouldRespondToTantrum() then
        nThreat = OptionData.tPriorities.SURVIVAL_LOW
    end
    
    -- some lower pri threats
    if nThreat < OptionData.tPriorities.SURVIVAL_LOW then
	    if self:getSquadName() and g_ERBeacon:needsMoreResponders(self:getSquadName()) and self:getJob() == Character.EMERGENCY then
	    	nThreat = OptionData.tPriorities.SURVIVAL_LOW
	    	self.sThreatSource ='beacon'
        end
    end
    --[[
    -- Not doing this, because we don't know if there's anything actionable.
    if nThreat < OptionData.tPriorities.SURVIVAL_LOW then
        if rChar:getPerceivedDiseaseSeverity() == 1 or rChar:retrieveMemory(Character.MEMORY_SENT_TO_HOSPITAL) then
        end
    end
    ]]--

	self.nThreat = nThreat
end

function Character:getCurrentTaskName()
	return self.rCurrentTask and self.rCurrentTask.activityName
end

function Character:getCurrentTaskTag(sTag)
    return self.rCurrentTask and self.rCurrentTask:getTag(self,sTag)
end

function Character:getCurrentTaskPriority()
	return (self.rCurrentTask and self.rCurrentTask:getPriority()) or OptionData.tPriorities.NO_ACTIVITY
end

function Character:needsNewTask()
	return self:getCurrentTaskPriority() < self.nThreat or self.bOneTimeReevaluate
end

-- Hacky method: forces a one-time redecide to see if there's a higher pri task we could be doing.
-- To be used when testSurvivalThreats won't deal with it appropriately.
-- TODO: move to a system that occasionally evaluates survival-level tasks while we perform our
-- lower pri tasks.
function Character:reevaluateTask()
    self.bOneTimeReevaluate = true
end

function Character:isPerformingWorkShiftTask()
	if self.rCurrentTask and self.rCurrentTask.rActivityOption then
		return self.rCurrentTask:getTag('WorkShift')
	else
		return self.tStatus.bOldTaskWorkShift

	end
end

function Character:getScaledDutyScore(nNeedScore, workShiftTagVal)
	-- If the character wants WorkShift tasks, scale up their utility based on their duty.
	if workShiftTagVal == true and self:wantsWorkShiftTask() then
		-- Allow some screwing around while on-duty to mix things up.
		-- MTF: disabling screwing around for now, for clarity.
		local nLastTaskThreshold = (self:onDuty() and 60) or 30
		if false and (not self.tStatus.nLastNonWorkTask or GameRules.elapsedTime - self.tStatus.nLastNonWorkTask > nLastTaskThreshold) then
			-- No duty bonus for now-- let the character have a few seconds off.
		else
			nNeedScore = g_ActivityOption.TAG_WORK_SHIFT_ADD + nNeedScore * g_ActivityOption.TAG_WORK_SHIFT_SCALE
		end
	end
	return nNeedScore
end

function Character:wantsWorkShiftTask()
    if self:inPrison() then return false end
	if self.tStatus.nRemainingDutyTime > 0 then return true end
	if self.tStatus.bOldTaskWorkShift then return true end
	if self.rCurrentTask and self.rCurrentTask:getTag('WorkShift') then
		return true
	end

	if self.tStatus.nRemainingDutyTime < -Character.SHIFT_COOLDOWN * 1.5 then
		-- After we've been off work for a while, let's start favoring work tasks.
		return true
	end

	return false
end

function Character:onDuty()
	if self.tStatus.nRemainingDutyTime > 0 then return true end
end

function Character:catchFire()
	if not self.onFire then
		self.onFire = true
		self.tStats.tHistory.nTotalTimesOnFire = 1 + (self.tStats.tHistory.nTotalTimesOnFire or 0)
		--spaceface log
		local tLogData = {sTimesBurned = tostring(self.tStats.tHistory.nTotalTimesOnFire)}
		if self.tStats.tHistory.nTotalTimesOnFire > 1 then
			Log.add(Log.tTypes.CAUGHT_FIRE, self, tLogData)
		else
			Log.add(Log.tTypes.CAUGHT_FIRE_MANY, self, tLogData)
		end
	end
	if self.nThreat <= OptionData.tPriorities.SURVIVAL_NORMAL then
		local rTask = GlobalObjects.getFireActivityOption():createTask(self, OptionData.tPriorities.SURVIVAL_NORMAL)
		self:forceTask(rTask)
	end
end

function Character:douseFire()
	self.onFire = false
end

function Character:extinguishedFire()
	self.tStats.tHistory.nTotalFiresExtinguished = 1 + (self.tStats.tHistory.nTotalFiresExtinguished or 0)
end

function Character:tickFireDamage(dt)
	if self.onFire or Fire.isFireAtWorld(self:getLoc()) then
		local tDamage = {}
		tDamage.nDamage =  dt * Character.FIRE_DAMAGE_RATE
		tDamage.nDamageType = Character.DAMAGE_TYPE.Fire
		self:takeDamage(nil, tDamage)
	end
end

function Character:builtBase()
	self:alterMorale(Character.MORALE_BUILD_BASE, 'BuildBase')
	self.tStats.tHistory.nTotalBaseTilesBuilt = 1 + (self.tStats.tHistory.nTotalBaseTilesBuilt or 0)
end

function Character:releasePuppet()
	assert(self:isDead() or (self.rCurrentTask and self.rCurrentTask.activityName == 'Puppet'))
	if self.rCurrentTask then
		self.rCurrentTask:release()
	end
end

function Character:forcePuppet(rMarionette, bErrorOnFailure)
	if self:getCurrentTaskPriority() <= OptionData.tPriorities.SURVIVAL_NORMAL then
		local tData = {}
		tData.rMarionette = rMarionette
		local ao = g_ActivityOption.new('Puppet',tData)
		local rTask = ao:createTask(self, OptionData.tPriorities.SURVIVAL_PUPPET)
		self:forceTask(rTask)
		return true
	elseif bErrorOnFailure then
		Print(TT_Error, 'CHARACTER.LUA: Failed to move character to puppet priority.')
	end
end

function Character:setPendingCoopTask(sTaskName,rPartner)
    assertdev(rPartner and sTaskName)
	if self.tStatus.health ~= Character.STATUS_DEAD and rPartner and sTaskName then
		assert(rPartner ~= self)
        self.rPendingTaskPartner = rPartner
        self.sPendingTaskName = sTaskName
	end
end

function Character:getPendingTaskName()
    return self.sPendingTaskName
end

function Character:getPendingTaskPartner()
    return self.rPendingTaskPartner
end

function Character:chatComplete(rTarget, bSuccess)
	if self.rCurrentTask and self:isChatting() and self.rCurrentTask.rTargetObject == rTarget and not self.rCurrentTask.bComplete then
		if bSuccess then
			self.rCurrentTask:complete()
		else
			self.rCurrentTask:interrupt("chat termination")
		end
		self.rCurrentTask = nil
		self:selectNewTask()
	elseif self.rPendingTaskPartner == rTarget then
        self:_clearPendingTask()
	end
end

function Character:isChatting()
	return self.rCurrentTask and (self.rCurrentTask.activityName == 'Chat' or self.rCurrentTask.activityName == 'ChatPartner') and self.rCurrentTask.bChatting
end

-- MTF TODO: ditch this function; set up a callback for when
-- tasks are completed or interrupted to clear out the values that are cleared out below.
function Character:selectNewTask()
	if self.rCurrentTask and not self.rCurrentTask.bComplete then
		self.rCurrentTask:interrupt("unexpected?")
	end
	self.rCurrentTask = nil
	self.nWaitingTime = 0
end

function Character:_finishOldTask()
	if not self.rCurrentTask or self.rCurrentTask:isChildTask() then return end

	self.tStatus.sOldTaskName = self.rCurrentTask.activityName
	self.tStatus.bOldTaskWorkShift = self.rCurrentTask:getTag('WorkShift')

	self.rCurrentTask = nil
end

-- MTF HACK:
-- There are some useful tests to do while we still have pathfinding cached, so I throw them in here.
-- It might be better implemented as an action every time the pathfinding finds a new accessible room,
-- or perhaps we stop caring about when it happens once I make pathfinding a lot cheaper overall.
function Character:_postPathfind()
    if self:getJob() == Character.DOCTOR and self:onDuty() and self:getTeam() == Character.TEAM_ID_PLAYER then
        local tHospitalRooms = Room.getSafeRoomsOfTeam(Character.TEAM_ID_PLAYER, false, 'INFIRMARY')
        for rRoom,_ in pairs(tHospitalRooms) do
            if not (rRoom.zoneObj and rRoom.zoneObj.addDoctor) then
                assertdev(false)
            else
                rRoom.zoneObj:addDoctor(self)
            end
        end
    end
end

local Profile = require('Profile')
--Profile.shinyStart("select_task", 100)

-- Only causes the task to change if we don't have a task, or if we find a task with a
-- higher pri than our current one.
function Character:_selectTask()
    self.bOneTimeReevaluate = false
	if self:getCurrentTaskPriority() == OptionData.tPriorities.PUPPET then return end
    
    assertdev(not self:isDead())
    if self:isDead() then return end

	local bPrintLog = DFSpace.isDev() and g_GuiManager.getSelectedCharacter() == self
	-- uncomment to enable logging - don't check in; bad perf
	-- bPrintLog = true

	--[[
	if bPrintLog then
	Print(TT_Info,'-- DECISION START',self.tStats.sUniqueID)
	Print(TT_Info,'Current need values:')
	for k,v in pairs(self.tNeeds) do
	Print(TT_Info,'    ',k,v)
	end
	end
	]]--

	Profile.shinyBeginLoop('select_task')

	local nRequiredPri = self:getCurrentTaskPriority() + 1
	local rNewOption,nNewUtility, logStr = UtilityAI.getBestTask(self, nRequiredPri, bPrintLog, Malady.getGathererOverride(self))
    self:_postPathfind()

	if bPrintLog then
		Print(TT_Gameplay,logStr)
		Print(TT_Gameplay,'CHARACTER.LUA: -- DECISION COMPLETE',self.tStats.sUniqueID,g_GameRules.elapsedTimeRaw)
		if rNewOption then
			Print(TT_Gameplay,'CHARACTER.LUA:   - Selected:',rNewOption.name,nNewUtility)
		else
			Print(TT_Gameplay,'CHARACTER.LUA:   - No option found.')
		end
	end

	if rNewOption then
		self.lastDecisionLog = logStr

		if self.rCurrentTask and not self.rCurrentTask.bComplete then
			self.rCurrentTask:interrupt("pri interrupt " .. (self.sThreatSource or 'unknown'))
		end
		self.rCurrentTask = rNewOption:createTask(self, nNewUtility, UtilityAI.DEBUG_PROFILE)
		self:_newTaskStarted(self.rCurrentTask)
	end

	Profile.shinyEndLoop('select_task')
end

function Character:taskCompleting(rTask,bSuccess,bChildTask)
	if not bChildTask then
		local rAO = rTask.rActivityOption
		if rAO then
			if rAO:getTag('WorkShift') then
				self.tStatus.nLastWorkTask = GameRules.elapsedTime
			else
				self.tStatus.nLastNonWorkTask = GameRules.elapsedTime
			end
		end
	end
    self:_testInPrison()
end

function Character:_newTaskStarted(rTask)
	if rTask.rParentTask then return end

    self:_clearPendingTask()
	-- MTF: first pass on duty cycle logic.
	-- Let's start your work shift, say... whenever you start a job, but at least SHIFT_COOLDOWN after the
	-- end of your last shift, and have it last SHIFT_DURATION.

	if self.tStatus.nRemainingDutyTime < -Character.SHIFT_COOLDOWN and
	rTask:getTag('WorkShift') then
		self.tStatus.nRemainingDutyTime = Character.SHIFT_DURATION
	end

	self:_setJobOutfit()
end

-- MOVEMENT ---------------------------------------------------------------------------------------------
function Character:updateAnimation(dt)
	self.rCurrentRig:update(dt)
end
---------------------------------------------------------------------------------------------------------

function Character:getSaveData(xOff,yOff)
	local tData = {}

	-- log
	tData.tLog = self.tLog
	tData.tLogQueue = self.tLogQueue
	-- stats
	tData.tStats = self.tStats
	tData.tNeeds = self.tNeeds
	tData.tStatus = self.tStatus
	tData.tMemory = self.tMemory
	tData.tAffinity = self.tAffinity
	tData.tFamiliarity = self.tFamiliarity
	tData.squadName = self.squadName or nil
    
    --local tInventory = DFUtil.deepCopy(self.tInventory)
    --ObjectList.convertTagsForSaving(tInventory)
    --tData.tInventory = tInventory
    --[[
    tData.tInventory = {}
    for k,v in pairs(self.tInventory) do
        tData.tInventory[k] = v.tag
    end
    ]]--
    tData.tInventory = self.tInventory

    if self.rCurrentTask and self.rCurrentTask.getSaveData and not xOff then
        tData.tTaskSaveData = self.rCurrentTask:getSaveData()
    end
    
	-- misc sim setup
	tData.sSpriteBody = self.sSpriteBody
	local x,y = self:getLoc()
	tData.x = x+(xOff or 0)
	tData.y = y+(yOff or 0)
	-- TODO save current task
	--if self.rCurrentTask then tData.tCurrentTask = self.rCurrentTask:getSaveData() end

    --tData = DFUtil.deepCopy(tData)
    --ObjectList.convertTagsForSaving(tData)
    
	return tData
end

function Character:_setPortrait( tData )
	if not tData.tStats.sPortrait or not Portraits.isValidPortrait( tData.tStats.sPortrait ) then

		tData.tStats.sPortraitHair = nil
		tData.tStats.sPortraitFacialHair = nil

		if Character.PremadePortraits[self.tStats.sName] then
			tData.tStats.sPortrait = Character.PremadePortraits[self.tStats.sName]
		elseif self.tStats.nRace == Character.RACE_SHAMON then
			tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.SHAMON_MALE )
		elseif self.tStats.nRace == Character.RACE_JELLY then
			if self.tStats.nBodyVariation == Character.BODY_JELLY_BLUE_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.JELLY_FEMALE_BLUE )
			elseif self.tStats.nBodyVariation == Character.BODY_JELLY_PURPLE_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.JELLY_FEMALE_PURPLE )
			elseif self.tStats.nBodyVariation == Character.BODY_JELLY_PINK_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.JELLY_FEMALE_PINK )
			else tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.JELLY_FEMALE_MAUVE ) end
		elseif self.tStats.nRace == Character.RACE_CHICKEN then
			if self.sSex == "M" then
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.CHICKEN_MALE )
			else
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.CHICKEN_FEMALE )
			end
		elseif self.tStats.nRace == Character.RACE_BIRDSHARK then
			if self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_MALE_01 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_MALE )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_MALE_02 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_MALE )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_FEMALE_01 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_FEMALE )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_FEMALE_02 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_FEMALE )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_FAT_MALE_01 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_MALE_FAT )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_FAT_MALE_02 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_MALE_FAT )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_FAT_FEMALE_01 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_FEMALE_FAT )
			elseif self.tStats.nBodyVariation == Character.BODY_BIRDSHARK_FAT_FEMALE_02 then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_FEMALE_FAT )
			else tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.BIRDSHARK_MALE ) end
		elseif self.tStats.nRace == Character.RACE_TOBIAN then
			local skinColor = 'Blue'
			--derive skin color
			if self.tStats.nBodyVariation == Character.BODY_TOBIAN_BLUE_ALIEN_01 then skinColor = 'Blue'
			elseif self.tStats.nBodyVariation == Character.BODY_TOBIAN_BLUE_ALIEN_02 then skinColor = 'Light_Teal'
			elseif self.tStats.nBodyVariation == Character.BODY_TOBIAN_BLUE_ALIEN_03 then skinColor = 'Light_Blue'
			elseif self.tStats.nBodyVariation == Character.BODY_TOBIAN_BLUE_ALIEN_04 then skinColor = 'Teal'
			else skinColor = 'Purple' end
			if self.tStats.nHairVariation == Character.TOBIAN_DONG_01
			or self.tStats.nHairVariation == Character.TOBIAN_DONG_02
			or self.tStats.nHairVariation == Character.TOBIAN_DONG_03
			or self.tStats.nHairVariation == Character.TOBIAN_DONG_04
			or self.tStats.nHairVariation == Character.TOBIAN_DONG_05 then
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.TOBIAN_DONG_HEAD[skinColor] )
			elseif self.tStats.nHairVariation == Character.TOBIAN_MUSTACHE_01
			or self.tStats.nHairVariation == Character.TOBIAN_MUSTACHE_02
			or self.tStats.nHairVariation == Character.TOBIAN_MUSTACHE_03
			or self.tStats.nHairVariation == Character.TOBIAN_MUSTACHE_04
			or self.tStats.nHairVariation == Character.TOBIAN_MUSTACHE_05 then
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.TOBIAN_EYESTALK_MUSTACHE_HEAD[skinColor] )
			elseif self.tStats.nHairVariation == Character.TOBIAN_ELEPHANT_01
			or self.tStats.nHairVariation == Character.TOBIAN_ELEPHANT_02
			or self.tStats.nHairVariation == Character.TOBIAN_ELEPHANT_03
			or self.tStats.nHairVariation == Character.TOBIAN_ELEPHANT_04
			or self.tStats.nHairVariation == Character.TOBIAN_ELEPHANT_05 then
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.TOBIAN_ELEPHANT_HEAD[skinColor] )
			end
		elseif self.tStats.nRace == Character.RACE_CAT then
			if self.sSex == "M" then
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.CAT_MALE )
			else
				tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.CAT_FEMALE )
			end
		elseif self.tStats.nRace == Character.RACE_HUMAN then
			if self.sSex == "M" then
				if self.tStats.nBodyVariation == Character.BODY_HUMAN_BROWN_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_BROWN )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_YELLOWISH_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_YELLOWISH )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_REDDISH_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_REDDISH )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_BLACK_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_BLACK )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_BROWN_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_BROWN_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_YELLOWISH_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_YELLOWISH_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_REDDISH_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_REDDISH_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_BLACK_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_BLACK_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_WHITE_MALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_WHITE_FAT )
				else tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_MALE_WHITE ) end
				--detect fat
				local sFatText, sFaceNum
				if string.find(tData.tStats.sPortrait, 'Large') then sFatText = 'Large_' else sFatText = '' end
				sFaceNum = string.sub(tData.tStats.sPortrait, -2)
				--hair
				if self.tStats.nHairVariation and self.tStats.nHairVariation ~= Character.BALD then
					tData.tStats.sPortraitHair = 'Human_' .. sFatText .. 'Male_' .. sFaceNum .. '_Hair_' .. Character.HAIR_TYPE[self.tStats.nHairVariation].sPortraitColor .. '_01'
				end
				--facial hair
				if self.tStats.nFaceBottomVariation and self.tStats.nFaceBottomVariation ~= Character.FACE_BOTTOM_CLEAR then
					local hairColor = string.sub(Character.FACE_BOTTOM_TYPE[self.tStats.nFaceBottomVariation], -2)
					if hairColor == '01' then hairColor = 'Brown'
					elseif hairColor == '02' then hairColor = 'Red'
					elseif hairColor == '03' then hairColor = 'Yellow'
					elseif hairColor == '05' then hairColor = 'Gray'
					else hairColor = 'Black' end
					if string.find(tData.tStats.sPortrait, 'Large') then sFatText = 'Large_' else sFatText = '' end
					local hairType = math.random(1,2)
					if hairType == 1 then hairType = '_Mustache_' else hairType = '_Beard_' end
					tData.tStats.sPortraitFacialHair = 'Human_'..sFatText..'Male_'.. sFaceNum .. hairType .. hairColor ..'_01'
				end
			else
				if self.tStats.nBodyVariation == Character.BODY_HUMAN_BROWN_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_BROWN )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_YELLOWISH_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_YELLOWISH )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_REDDISH_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_REDDISH )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_BLACK_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_BLACK )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_BROWN_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_BROWN_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_YELLOWISH_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_YELLOWISH_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_REDDISH_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_REDDISH_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_BLACK_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_BLACK_FAT )
				elseif self.tStats.nBodyVariation == Character.BODY_HUMAN_FAT_WHITE_FEMALE then tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_WHITE_FAT )
				else tData.tStats.sPortrait = DFUtil.arrayRandom( Portraits.HUMAN_FEMALE_WHITE ) end
				--hair
				if self.tStats.nHairVariation and self.tStats.nHairVariation ~= Character.BALD then
					local sFatText
					if string.find(tData.tStats.sPortrait, 'Large') then sFatText = 'Large_' else sFatText = '' end
					tData.tStats.sPortraitHair = 'Human_' .. sFatText .. 'Female_' .. string.sub(tData.tStats.sPortrait, -2) .. '_Hair_' .. Character.HAIR_TYPE[self.tStats.nHairVariation].sPortraitColor .. '_01'
				end
			end
		elseif self.tStats.nRace == Character.RACE_MURDERFACE then
			tData.tStats.sPortrait = DFUtil.arrayRandom(Portraits.MURDERFACE)
		elseif self.tStats.nRace == Character.RACE_MONSTER then
			tData.tStats.sPortrait = DFUtil.arrayRandom(Portraits.MONSTER)
		elseif self.tStats.nRace == Character.RACE_KILLBOT then
			tData.tStats.sPortrait = DFUtil.arrayRandom(Portraits.KILLBOT)
		else
			tData.tStats.sPortrait = GENERIC_PORTRAIT
		end
		tData.tStats.sPortraitPath = Portraits.PORTRAIT_PATH
	end
end

function Character:setEmoticon( sIcon, sText, bIsWordType )
	if not self.rEmoticon and not self.rEmoticonText then
		return
	end
	local rRenderLayer = Renderer.getRenderLayer("WorldCeiling")

	if sText and string.len(sText) == 0 then sText = nil end

	if sIcon or sText then
		self.sEmoticon = sIcon
		self.sEmoticonText = sText

		-- bubble setup
		-- set bubble (derive type from sprite name)
		local bubbleType = 'ui_dialog_thought_'
		if bIsWordType then
			bubbleType = 'ui_dialog_dialog_'
		end
		--bubble tail
		self.rEmoticonBubbleTail:setIndex( self.rEmoticonSpriteSheet.names[bubbleType..'bubbletail'] )
		rRenderLayer:insertProp( self.rEmoticonBubbleTail )
		self.rEmoticonBubbleTail:setVisible(true)

		--left end cap
		if sIcon then
			self.rEmoticonBubbleLeftCap:setIndex( self.rEmoticonSpriteSheet.names[bubbleType..'iconframe'] )
			self.rEmoticonBubbleLeftCap:setScl(1,1)
			self.rEmoticonBubbleLeftCap:setLoc(-54, 335)
		else
			self.rEmoticonBubbleLeftCap:setIndex( self.rEmoticonSpriteSheet.names[bubbleType..'endcap'] )
			self.rEmoticonBubbleLeftCap:setScl(-1,1)
			self.rEmoticonBubbleLeftCap:setLoc(-14, 335)
		end
		rRenderLayer:insertProp( self.rEmoticonBubbleLeftCap )
		self.rEmoticonBubbleLeftCap:setVisible(true)

		--right end cap
		self.rEmoticonBubbleRightCap:setIndex( self.rEmoticonSpriteSheet.names[bubbleType..'endcap'] )
		rRenderLayer:insertProp( self.rEmoticonBubbleRightCap )
		self.rEmoticonBubbleRightCap:setVisible(true)

		-- text setup
		rRenderLayer:insertProp( self.rEmoticonText )
		if sText then
			local bubbleBGWidth = 40
			--local nXSize = string.len(sText) * 16

			self.rEmoticonText:setString(sText)
			self.rEmoticonText:setRect( 0, 100, 1000, 0 )

			local kPADDING = 4
			local x0, y0, x1, y1 = self.rEmoticonText:getStringBounds(1, string.len(sText))
			if y1 then
				local nXSize = DFMath.roundDecimal(math.abs(x1 - x0), 0) + kPADDING
				if nXSize < bubbleBGWidth then nXSize = bubbleBGWidth end
				local CurrentBGWidth = 0

				for i=1,kMAX_BUBBLE_BG_SEGMENTS do
					if CurrentBGWidth < nXSize then
						CurrentBGWidth = CurrentBGWidth + bubbleBGWidth
					end

					if i * bubbleBGWidth < nXSize then
						self.tEmoticonBubbleBGSegments[i]:setIndex( self.rEmoticonSpriteSheet.names[bubbleType..'bubblebg'] )
						rRenderLayer:insertProp( self.tEmoticonBubbleBGSegments[i] )
						self.tEmoticonBubbleBGSegments[i]:setVisible(true)

						self.rEmoticonBubbleRightCap:setLoc(60 + (bubbleBGWidth*(i - 1)) - ((i+1)*0.1), 335, -20)
					else
						self.tEmoticonBubbleBGSegments[i]:setVisible(false)
					end
				end

				self.rEmoticonText:setVisible(true)
			end
		end

		--emoticon setup
		if not self.rEmoticon then
		elseif sIcon then
			self.rEmoticon:setIndex( self.rEmoticonSpriteSheet.names['ui_dialogicon_'..sIcon] )
			rRenderLayer:insertProp( self.rEmoticon )
			self.rEmoticon:setVisible(true)
		else
			if self.rEmoticon then
				rRenderLayer:removeProp( self.rEmoticon )
			end
			self.rEmoticon:setVisible(false)
		end

		-- text setup
		rRenderLayer:insertProp( self.rEmoticonText )
		if sText then
			self.rEmoticonText:setVisible(true)
			self.rEmoticonText:setString(sText) --g_LM.line
		end
	else
		self.sEmoticon = nil
		self.sEmoticonText = nil
		rRenderLayer:removeProp( self.rEmoticonBubbleTail )
		rRenderLayer:removeProp( self.rEmoticonBubbleLeftCap )

		for i=1,kMAX_BUBBLE_BG_SEGMENTS do
			rRenderLayer:removeProp( self.tEmoticonBubbleBGSegments[i] )
			self.tEmoticonBubbleBGSegments[i]:setVisible(false)
		end

		rRenderLayer:removeProp( self.rEmoticonBubbleRightCap )
		if self.rEmoticon then
			rRenderLayer:removeProp( self.rEmoticon )
			self.rEmoticon:setVisible(false)
		end
		self.rEmoticonBubbleTail:setVisible(false)
		if self.rEmoticonText then
			rRenderLayer:removeProp( self.rEmoticonText )
			self.rEmoticonText:setVisible(false)
		end
		self.rEmoticonBubbleLeftCap:setVisible(false)
		self.rEmoticonBubbleRightCap:setVisible(false)
	end
end

function Character:getAffinityEmoticon( affinity )
	if affinity > 0 then
		return 'thumbsup'
	else
		return 'thumbsdown'
	end
end

function Character:getAffChangeEmoticon( change )
	if change > 0 then
		return 'arrowup'
	else
		return 'arrowdown'
	end
end

------------------------------------------------------------------
-- PRIVATE -------------------------------------------------------
------------------------------------------------------------------

function Character:_setCharacterVisuals( tData )
end

function Character:_setStats( tData )
	-- try to load from save
	if tData then
		self.tStats = tData.tStats or {}
        --new data for maladies to modify, could do this from within the maladies themselves, but that would get messy fast.
        --nSpeed is simply a speed multiplier
        if not self.tStats.nspeed then self.tStats.nspeed = 1 end
        if not self.tStats.bRefuseDoctor then self.tStats.bRefuseDoctor = false end 
        if not self.tStats.bHideSigns then self.tStats.bHideSigns = false end 
        --done
		if not self.tStats.tPersonality then self.tStats.tPersonality = {} end
		if not self.tStats.tHistory then self.tStats.tHistory = {} end
		if not self.tStats.tHistory.tMoraleEvents then self.tStats.tHistory.tMoraleEvents = {} end
		if not self.tStats.tHistory.tTaskLog then self.tStats.tHistory.tTaskLog = {} end
		-- graph items: all needs + morale
		if not self.tStats.tHistory.tGraphItems then
			self.tStats.tHistory.tGraphItems = {}
		end
		for needName,_ in pairs(Needs.tNeedList) do
			if not self.tStats.tHistory.tGraphItems[needName] then
				self.tStats.tHistory.tGraphItems[needName] = {}
			end
		end
		if not self.tStats.tHistory.tGraphItems.Morale then
			self.tStats.tHistory.tGraphItems['Morale'] = {}
		end
		if not self.tStats.tHistory.tGraphItems.XP then
			self.tStats.tHistory.tGraphItems['XP'] = {}
		end
		if not self.tStats.tHistory.tGraphItems.Stuff then
			self.tStats.tHistory.tGraphItems['Stuff'] = {}
		end
		-- room morale scores
		if not self.tStats.tHistory.tRoomScores then
			self.tStats.tHistory.tRoomScores = {}
		end
		self.tNeeds = tData.tNeeds
		if not self.tNeeds then self.tNeeds = {} end
        if not self.tNeeds.tReduceMods then self.tNeeds.tReduceMods = {} end
		-- ensure all needs are initialized, even if a new need has been added since the savegame was created.
		for needName,_ in pairs(Needs.tNeedList) do
			if not self.tNeeds[needName] then
				-- default range if not specified
				local nMin = Needs.tNeedList[needName].initMin or 0.1*Needs.MIN_VALUE
				local nMax = Needs.tNeedList[needName].initMax or 0.1*Needs.MAX_VALUE
				self.tNeeds[needName] = math.random(nMin, nMax)
			end
		end
		self.tStatus = tData.tStatus or {}
		self.tMemory = tData.tMemory or {}
        self.tStatus.tBrawlingWith = (tData.tStatus and tData.tStatus.tBrawlingWith) or {}
        
		self.tOwnedStuff = tData.tOwnedStuff or {}
        self.nOwnedStuff = DFUtil.tableSize(self.tOwnedStuff)
        
		self.tInventory = tData.tInventory or {}        
		self:_updateOldInventorySaves()
        
		if self.tStatus.sHeldItemName and not self.tInventory[self.tStatus.sHeldItemName] then
			self.tStatus.sHeldItemName = nil
		end
	else
		self.tStats = {}
		self.tStats.tHistory = {}
		self.tStats.tPersonality = {}
		self.tStats.tHistory.tMoraleEvents = {}
		self.tStats.tHistory.tGraphItems = {}
		self.tStats.tHistory.tRoomScores = {}
		self.tStats.tHistory.tTaskLog = {}
		self.tStatus = {}
        self.tStatus.tBrawlingWith = {}
		self.tMemory = {}
		self.tInventory = {}
	end

	-- static attributes ---------------------------------
	self.tStats.nTeam = self.tStats.nTeam or Character.TEAM_ID_PLAYER
	self.tStats.nOriginalTeam = self.tStats.nOriginalTeam or self.tStats.nTeam

	self.tStats.nRace = self:_getValidRace()
	self.tStats.sRaceName = Character.RACE_TYPE[self.tStats.nRace].sName
	self.tStats.nBodyVariation = self:_getValidBody()

	if not Character.BODY_TYPE[self.tStats.nBodyVariation].bNoReplacements then
        self.tStats.nHeadVariation = self:_getValidHead()
        self.tStats.nFaceTopVariation = self:_getValidFaceTopLayer()
        self.tStats.nFaceBottomVariation = self:_getValidFaceBottomLayer()
        self.tStats.nHairVariation = self:_getValidHair()
        self.tStats.nBottomAccessoryVariation,self.tStats.nTopAccessoryVariation = self:_getValidAccessories()
		self.sMaterial = 'meshDefault'
	else
		self.sMaterial = 'meshSingleTexture'
	end

	self.sSex = Character.BODY_TYPE[self.tStats.nBodyVariation].sSex

	--        Print(TT_Info,"race:",self.tStats.nRace,"body:"..self.tStats.nBodyVariation..", head: "..(self.tStats.nHeadVariation or 'nil')..", hair:"..(self.tStats.nHairVariation or 'nil'))

	-- set name
	if not self.tStats.sName then
		self.tStats.sName = CitizenNames.getNewUniqueName(self.tStats.nRace, self.sSex)
	end

	if not self.tStats.sUniqueID then
		self.tStats.sUniqueID = self.tStats.sName..Character.staticCounter
		Character.staticCounter = Character.staticCounter+1
	end

	-- mutable attributes --------------------------------
	-- job competency
	self.tStats.tJobCompetency = self.tStats.tJobCompetency or {}
	
	-- builder was one of the original jobs, so if we don't have a value
	-- for that, we must be a new citizen - distribute points randomly.
	if not self.tStats.tJobCompetency[Character.BUILDER] then
		-- get a copy of job list we can write to
		local tJobs = {}
		for nJob,nValue in pairs(Character.DISPLAY_JOBS) do
			tJobs[nJob] = nValue
		end
		-- remove "unemployed"
		table.remove(tJobs, 1)
		local nPoints = Character.STARTING_SKILL_POINTS
		-- pop a random job off the list and assign points
		local nNumJobs = #tJobs
		while nNumJobs > 0 do
			-- tableRandom returns value,key NOT key,value!
			local nJob,i = DFUtil.tableRandom(tJobs)
			table.remove(tJobs, i)
			if nPoints > 0 then
				local nCompetency
				-- if last item, use up all remaining points (up to max allowed)
				if nNumJobs == 1 then
					nCompetency = math.min(nPoints, Character.MAX_STARTING_COMPETENCY)
				else
					nCompetency = math.random(0, Character.MAX_STARTING_COMPETENCY)
				end
				self.tStats.tJobCompetency[nJob] = math.min(nCompetency, nPoints)
				-- star rating is base 1 while competency is base 0
				nPoints = nPoints - (nCompetency + 1)
			else
				self.tStats.tJobCompetency[nJob] = 0
			end
			nNumJobs = nNumJobs - 1
		end
		if nPoints > 0 then
			Print(TT_Info, 'CHARACTER.LUA: Duty skill point distribution for '..self.tStats.sUniqueID..' completed with '..nPoints..' points remaining.')
		end
	else
		-- if we added a new job since this savegame was made, just randomize
		-- competency in the new job
		for _,nJob in pairs(Character.tJobs) do
			self.tStats.tJobCompetency[nJob] = self.tStats.tJobCompetency[nJob] or math.random(0, Character.MAX_STARTING_COMPETENCY)
		end
	end
	self.tStats.nJob = self.tStats.nJob or self.tStats.job or Character.UNEMPLOYED
	
	-- job experience
	self.tStats.tJobExperience = self.tStats.tJobExperience or {}
	for _,nJob in pairs(Character.tJobs) do
		self.tStats.tJobExperience[nJob] = self.tStats.tJobExperience[nJob] or 0
	end
	
	self.tStats.nMorale = self.tStats.nMorale or 0

	-- start with average maxed to avoid tripping warnings
	self.nAverageOxygen = Oxygen.TILE_MAX
	self.tRecentOxygen = {}

	for k,_ in pairs(Character.PERSONALITY_TRAITS) do
		-- move trait data in old savegames from tStats to tStats.tPersonality
		-- (avoids mass mind-wipe when people update to alpha 4)
		if k == 'nBravery' and self.tStats.Bravery then
			self.tStats.tPersonality[k] = self.tStats.Bravery
			self.tStats.Bravery = nil
		elseif k == 'nGregariousness' and self.tStats.Gregariousness then
			self.tStats.tPersonality[k] = self.tStats.Gregariousness
			self.tStats.Gregariousness = nil
		elseif k == 'nChattiness' and self.tStats.Chattiness then
			self.tStats.tPersonality[k] = self.tStats.Chattiness
			self.tStats.Chattiness = nil
		elseif k == 'nNeatness' and self.tStats.Neatness then
			self.tStats.tPersonality[k] = self.tStats.Neatness
			self.tStats.Neatness = nil
		else
			-- numeric or boolean trait?
			if string.find(k, 'n') == 1 then
				self.tStats.tPersonality[k] = self.tStats.tPersonality[k] or math.random()
			elseif string.find(k, 'b') == 1 then
				if self.tStats.tPersonality[k] == nil then
					-- some boolean traits should be more or less common
					self.tStats.tPersonality[k] = math.random() < (Character.PERSONALITY_LIKELIHOOD[k] or 0.5)
				else
					self.tStats.tPersonality[k] = self.tStats.tPersonality[k]
				end
			end
		end
	end

	-- movement stats
	self.tStats.speed = Character.BASE_SPEED * .5 * (World.tileWidth+World.tileHeight)
	self.tStats.runSpeed = Character.RUN_SPEED * .5 * (World.tileWidth+World.tileHeight)

	-- raw health stats that influence life signs
	self.tStats.nToughness = self.tStats.nToughness or math.random()
	self.tStats.nMaxHitPoints = self.tStats.nMaxHitPoints or Character.STARTING_HIT_POINTS
    -- tStats used to (erroneously) store hp, so port over to tStatus
	self.tStatus.nHitPoints = self.tStatus.nHitPoints or self.tStats.nHitPoints or self.tStats.nMaxHitPoints

	-- up-to-the-minute status goes into tStatus
	-- life signs
	self.tStatus.suffocationTime = self.tStatus.suffocationTime or 0
	self.tStatus.suitOxygen = self.tStatus.suitOxygen or Character.SPACESUIT_MAX_OXYGEN
	self.tStatus.nStarveTime = self.tStatus.nStarveTime or 0
	self.tStatus.nRemainingDutyTime = self.tStatus.nRemainingDutyTime or -Character.SHIFT_COOLDOWN * math.random(.1,1)
	self.tStatus.nAnger = self.tStatus.nAnger or 0

	self.tMemory.tTaskChat = self.tMemory.tTaskChat or {}
	self.tMemory.tRooms = self.tMemory.tRooms or {}
    
    -- yes, immunities are in tStats and maladies are in tStatus.
    if not self.tStats.tImmunities then self.tStats.tImmunities = {} end
    if not self.tStatus.tMaladies then self.tStatus.tMaladies = {} end
    
    Malady.updateSavedMaladies(self.tStatus.tMaladies)
end

function Character:getPersonalityStat(sName)
    if self.tStatus.bRampageViolent and sName == 'nBravery' then 
        return 1 
    end
    return self.tStats.tPersonality[sName]
end

function Character:getRaceName()
	return g_LM.line(Character.tRaceNames[self.tStats.nRace])
end

function Character:getSuitOxygenSeconds()
	return self.tStatus.suitOxygen / Character.OXYGEN_PER_SECOND
end

function Character:getSuitOxygenPct()
	return math.floor((self.tStatus.suitOxygen / Character.SPACESUIT_MAX_OXYGEN) * 100)
end

function Character:_updateVariation()
	-- compile all of the various model variatons and turn them on
	self.tVariations = {}
	if self.tStats.bShowBody then if self.tBodyVariation then table.insert(self.tVariations, self.tBodyVariation) end end
	if self.tStats.bShowHead then if self.tHeadVariation then table.insert(self.tVariations, self.tHeadVariation) end end
	if self.tStats.bShowHair then if self.tHairVariation then table.insert(self.tVariations, self.tHairVariation) end end
	if self.tStats.bShowHelmet then if self.tHelmetVariation then table.insert(self.tVariations, self.tHelmetVariation) end end
	if self.tJobVariation then table.insert(self.tVariations, self.tJobVariation) end
	if self.tJobToolVariation then table.insert(self.tVariations, self.tJobToolVariation) end
	if self.tBottomAccessoryVariation then table.insert(self.tVariations, self.tBottomAccessoryVariation) end
	if self.tTopAccessoryVariation then table.insert(self.tVariations, self.tTopAccessoryVariation) end
	if self.tTopConflictVariation then table.insert(self.tVariations, self.tTopConflictVariation) end
	if self.tBottomConflictVariation then table.insert(self.tVariations, self.tBottomConflictVariation) end
	--[[if self.tToggleVariations then
	for _,tToggleVariant in ipairs(self.tToggleVariations) do
	table.insert(self.tVariations, tToggleVariant)
	end
	end]]--

	self.rRig:setVariationLayer(self.tVariations)
end

function Character:_updateSpacesuitVariation()
	if not self.rSpacesuitRig then return end
	-- compile all of the various model variatons and turn them on
	self.tVariations = {}
	if self.tSpacesuitJobVariation then table.insert(self.tVariations, self.tSpacesuitJobVariation) end
	if self.tSpaceHelmetVariation then table.insert(self.tVariations, self.tSpaceHelmetVariation) end
	self.rSpacesuitRig:setVariationLayer(self.tVariations)
end

function Character:_setRig( tData, tHackEntity )
	--char rig

	local tRigData = Character.RIG_TYPE[Character.RACE_TYPE[self.tStats.nRace]["nRig"]]
	local sRigResource, sAnimDefPath,nScl = tRigData.sRigPath,tRigData.sAnimPath,tRigData.nScl
	self.nScale = nScl
	local tSubsetReplacements={}
	self:_setBody( tSubsetReplacements )

	if not Character.BODY_TYPE[self.tStats.nBodyVariation].bNoReplacements then
		self:_setHead( tSubsetReplacements )
		self:_setHair( tSubsetReplacements )
		self:_setOutfit( tSubsetReplacements )
		self:_setAccessories( tSubsetReplacements )
		--self:_setHandAccessoryTextures( tSubsetReplacements )
	end

	local tRigArgs = {}
	tRigArgs.sResource = sRigResource
	tRigArgs.sVariationPrefix = Character.BODY_PREFIX
	tRigArgs.sVariationFull = self.sBodySubsetId
	tRigArgs.sMaterial = self.sMaterial

	-- cubehax
	--tRigArgs.sResource = 'Props/Asteroid/AsteroidChunk/Rig/AsteroidChunk.rig' --'Characters/Primitives/Rig/Sphere.rig'
	--tRigArgs.sResource = 'Characters/Bad_Alien/Rig/Bad_Alien.rig'
	--tRigArgs.sMaterial = "meshSingleTexture"

	self.rRig = Rig.new(tHackEntity, tRigArgs, self.rAssetSet)

	self:_updateVariation() --turn on/off model subsets

	if not self.rRig:setTexturePath( tSubsetReplacements ) then
		Print(TT_Warning,'CHARACTER.LUA: Bad texture replacements for',self:getUniqueID())
	end

	self.tAnimations[self.rRig] = DFUtil.deepCopy( require(sAnimDefPath) )

	self.rCurrentRig = self.rRig
	if not Character.BODY_TYPE[self.tStats.nBodyVariation].bNoSpacesuit then
		--spacesuit rig
		local tSuitRigArgs = {}
		tSuitRigArgs.sResource = Character.RIG_SPACESUIT
		tSuitRigArgs.sMaterial = self.sMaterial
		self.rSpacesuitRig = Rig.new(tHackEntity, tSuitRigArgs, self.rAssetSet)
		self.tAnimations[self.rSpacesuitRig] = DFUtil.deepCopy( require('Animations.Spacesuit') )
		local tSpaceSuitReplacements = {}
		table.insert(tSpaceSuitReplacements, {Character.SPACESUIT_JOB_EQUIPMENT_PREFIX..Character.SPACESUIT_JOB_EQUIPMENT[Character.BUILDER]["sModel"], "g_samTop", Character.SPACESUIT_JOB_EQUIPMENT[Character.BUILDER]["sTexture"]})
		table.insert(tSpaceSuitReplacements, {Character.SPACESUIT_PREFIX..Character.SPACESUITS[Character.BUILDER]["sModel"], "g_samTop", Character.SPACESUITS[Character.BUILDER]["sTexture"]})
		self:_setSpacesuitHandAccessoryTextures( tSpaceSuitReplacements )

		if not self.rSpacesuitRig:setTexturePath( tSpaceSuitReplacements ) then
			Print(TT_Warning,'CHARACTER.LUA: Bad spacesuit texture replacements for',self:getUniqueID())
		end
	end
	self:setScl(nScl)
    
    for rRig, tAnimList in pairs(self.tAnimations) do
        for k,v in pairs(tAnimList) do
            if k == 'stance' then
                for sStanceName,tStanceAnimList in pairs(v) do
                    for sStanceAnimName,tStanceAnimData in pairs(tStanceAnimList) do
                        if type(tStanceAnimData) == 'table' then
                            tStanceAnimData.sAnimName = sStanceAnimName
                        end
                    end
                end
            elseif type(v) == 'table' then
                v.sAnimName = k
            end
        end
    end
end

function Character:_getValidBody()
	if self.tStats.nBodyVariation and MiscUtil.arrayIndexOf(Character.RACE_TYPE[self.tStats.nRace].tBodies,self.tStats.nBodyVariation) then
		return self.tStats.nBodyVariation
	else
		return DFUtil.arrayRandom(Character.RACE_TYPE[self.tStats.nRace]["tBodies"])
	end
end

function Character:_setBody( tSubsetReplacements )
	local sBase
	sBase = Character.BODY_TYPE[self.tStats.nBodyVariation]["sBodyTexture"]
	if Character.BODY_TYPE[self.tStats.nBodyVariation]["sBodyModel"] then
		self.sBodySubsetId = Character.BODY_PREFIX..Character.BODY_TYPE[self.tStats.nBodyVariation]["sBodyModel"]
	else
		self.sBodySubsetId = nil
	end
	--texture
	if sBase and self.sBodySubsetId then
		table.insert(tSubsetReplacements, {self.sBodySubsetId, "g_samBase", sBase})
		table.insert(tSubsetReplacements, {self.sBodySubsetId, "g_samTop", sBase}) --temp on top until we get alien accessories
	end
	--model
	if self.sBodySubsetId then
		self.tBodyVariation = { prefix = Character.BODY_PREFIX, full = self.sBodySubsetId }
	else
		self.tBodyVariation = {}
	end
	self.tStats.bShowBody = true
end

function Character:hideBody()
	self.tStats.bShowBody = false
	self:hideHead()
	self:_updateVariation()
end

function Character:showBody()
	self.tStats.bShowBody = true
	self:showHead()
	self:_updateVariation()
end

function Character:_getValidRace()
	if self.tStats.nRace and Character.RACE_TYPE[self.tStats.nRace] then
		if self.tStats.nRace == Character.RACE_KILLBOT or self.tStats.nRace == Character.RACE_MONSTER then
			self.tStats.bDoesNotBreathe = true
		end
		return self.tStats.nRace
	else
		if self:getFactionBehavior() == Character.FACTION_BEHAVIOR.EnemyGroup then
			if math.random() < .5 then
				return Character.RACE_MURDERFACE
			end
		end
		local nRand = math.random(1,100)
		if nRand <= Character.HUMAN_RACE_PCT then return Character.RACE_HUMAN
		elseif nRand <= Character.HUMAN_RACE_PCT + Character.CAT_RACE_PCT then return Character.RACE_CAT
		else
			return MiscUtil.randomKey(Character.RACE_TYPE, {[Character.RACE_HUMAN]=1,[Character.RACE_MONSTER]=1,[Character.RACE_CAT]=1,[Character.RACE_MURDERFACE]=1,[Character.RACE_KILLBOT]=1,})
		end
	end
end

function Character:_getValidFaceBottomLayer()
	if self.tStats.nFaceBottomVariation and MiscUtil.arrayIndexOf(Character.HEAD_TYPE[self.tStats.nHeadVariation].tFaceBottom, self.tStats.nFaceBottomVariation) then
		return self.tStats.nFaceBottomVariation
	else
		if math.random() <= 0.4 then -- % of assigning facial hair
			--human males have facial hair, this is to match their face hair color with their head hair color
			local sHairColor = 'Black' --default to black
			local tBeardBodies = { Character.BODY_HUMAN_BROWN_MALE,Character.BODY_HUMAN_BROWN_MALE,Character.BODY_HUMAN_YELLOWISH_MALE, Character.BODY_HUMAN_YELLOWISH_MALE,
								   Character.BODY_HUMAN_REDDISH_MALE,Character.BODY_HUMAN_WHITE_MALE,Character.BODY_HUMAN_BLACK_MALE,Character.BODY_HUMAN_FAT_BROWN_MALE,Character.BODY_HUMAN_FAT_BROWN_MALE,Character.BODY_HUMAN_YELLOWISH_MALE, Character.BODY_HUMAN_YELLOWISH_MALE,
								   Character.BODY_HUMAN_FAT_REDDISH_MALE,Character.BODY_HUMAN_FAT_WHITE_MALE,Character.BODY_HUMAN_FAT_BLACK_MALE, }
			if MiscUtil.arrayIndexOf(tBeardBodies,self.tStats.nBodyVariation) and self.tStats.nHairVariation then
				if Character.HAIR_TYPE[self.tStats.nHairVariation].sPortraitColor then
					sHairColor = Character.HAIR_TYPE[self.tStats.nHairVariation].sPortraitColor
				end
				if sHairColor == 'Blonde' then
					local tBeards = {Character.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE, Character.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE, Character.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,Character.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,Character.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,}
					return DFUtil.arrayRandom(tBeards)
				elseif sHairColor == 'Brown' then
					local tBeards = {Character.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE, Character.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE, Character.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,Character.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,Character.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,}
					return DFUtil.arrayRandom(tBeards)
				elseif sHairColor == 'Red' then
					local tBeards = {Character.FACE_BOTTOM_HUMAN_BEARD_01_RED, Character.FACE_BOTTOM_HUMAN_BEARD_02_RED, Character.FACE_BOTTOM_HUMAN_BEARD_03_RED,Character.FACE_BOTTOM_HUMAN_BEARD_04_RED,Character.FACE_BOTTOM_HUMAN_BEARD_05_RED,}
					return DFUtil.arrayRandom(tBeards)
				elseif sHairColor == 'Gray' then
					local tBeards = {Character.FACE_BOTTOM_HUMAN_BEARD_01_GRAY, Character.FACE_BOTTOM_HUMAN_BEARD_02_GRAY, Character.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,Character.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,Character.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,}
					return DFUtil.arrayRandom(tBeards)
				else
					local tBeards = {Character.FACE_BOTTOM_HUMAN_BEARD_01_BLACK, Character.FACE_BOTTOM_HUMAN_BEARD_02_BLACK, Character.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,Character.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,Character.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,}
					return DFUtil.arrayRandom(tBeards)
				end
			end
			-- if not human male, just do this simple shiz
			return DFUtil.arrayRandom(Character.HEAD_TYPE[self.tStats.nHeadVariation]["tFaceBottom"])
		else  --no facial hair
			self.tStats.nFaceBottomVariation = Character.FACE_BOTTOM_CLEAR
			return self.tStats.nFaceBottomVariation
		end
	end
end

function Character:_getValidFaceTopLayer()
	if self.tStats.nFaceTopVariation and MiscUtil.arrayIndexOf(Character.HEAD_TYPE[self.tStats.nHeadVariation].tFaceTop, self.tStats.nFaceTopVariation) then
		return self.tStats.nFaceTopVariation
	else
		return DFUtil.arrayRandom(Character.HEAD_TYPE[self.tStats.nHeadVariation]["tFaceTop"])
	end
end

function Character:_getValidHead()
	if self.tStats.nHeadVariation and MiscUtil.arrayIndexOf(Character.BODY_TYPE[self.tStats.nBodyVariation]['tHeads'],self.tStats.nHeadVariation) then
		return self.tStats.nHeadVariation
	else
		return DFUtil.arrayRandom(Character.BODY_TYPE[self.tStats.nBodyVariation]["tHeads"])
	end
end

function Character:_setHead( tSubsetReplacements )
	local sHeadName, sBase, sTop, sBottom
	sHeadName = Character.HEAD_TYPE[self.tStats.nHeadVariation]["sHeadModel"]
	if sHeadName then
		sBase = Character.HEAD_TYPE[self.tStats.nHeadVariation]["sHeadTexture"]
		sTop = Character.FACE_TOP_TYPE[self.tStats.nFaceTopVariation]
		sBottom = Character.FACE_BOTTOM_TYPE[self.tStats.nFaceBottomVariation]
		local sHeadSubsetId = Character.HEAD_PREFIX..sHeadName
		table.insert(tSubsetReplacements, {sHeadSubsetId, "g_samBase", sBase})
		table.insert(tSubsetReplacements, {sHeadSubsetId, "g_samTop", sTop})
		table.insert(tSubsetReplacements, {sHeadSubsetId, "g_samBottom", sBottom})
	end
	self.tStats.bShowHead = true
	self.tHeadVariation = { prefix = Character.HEAD_PREFIX, full = Character.HEAD_PREFIX..sHeadName }--self:_getHeadVariationTable(true)
end

function Character:hideHead()
	self.tStats.bShowHead = false
	self:hideHair()
	self:_updateVariation()
end

function Character:showHead()
	self.tStats.bShowHead = true
	self:showHair()
	self:_updateVariation()
end

function Character:_getValidHair()
	if self.tStats.nHairVariation and MiscUtil.arrayIndexOf(Character.HAIR_SET_TYPE[Character.HEAD_TYPE[self.tStats.nHeadVariation].nHairSetType].tHairs, self.tStats.nHairVariation) then
		return self.tStats.nHairVariation
	else
		return DFUtil.arrayRandom(Character.HAIR_SET_TYPE[Character.HEAD_TYPE[self.tStats.nHeadVariation].nHairSetType].tHairs)
	end
end

function Character:_setHair( tSubsetReplacements )
	local sBase, sHairName
	sHairName = Character.HAIR_TYPE[self.tStats.nHairVariation]["sHairModel"]
	sBase = Character.HAIR_TYPE[self.tStats.nHairVariation]["sHairTexture"]
	-- this is an optional setting: 'bald' doesn't specify.
	if sHairName and sBase then
		local sHairSubsetId = Character.HAIR_PREFIX..sHairName
		table.insert(tSubsetReplacements, {sHairSubsetId, "g_samBase", sBase})
		table.insert(tSubsetReplacements, {sHairSubsetId, "g_samTop", sBase})
		table.insert(tSubsetReplacements, {sHairSubsetId, "g_samBottom", sBase})
		self.tHairVariation = { prefix = Character.HAIR_PREFIX, full = sHairSubsetId }
	else
		self.tHairVariation = { prefix = Character.HAIR_PREFIX, full = "" }
	end
	self.tStats.bShowHair = true
end

function Character:showHair()
	self.tStats.bShowHair = true
end

function Character:hideHair()
	self.tStats.bShowHair = false
end

function Character:_setOutfit( tSubsetReplacements ) -- sets up base layers on body
	if not self.sBodySubsetId then return end

	local sTop, sBottom
	if not self.tStats.nOutfitTopVariation then
		self.tStats.nOutfitTopVariation = math.random(1,5)
	end
	if not self.tStats.nOutfitBottomVariation then
		self.tStats.nOutfitBottomVariation = math.random(1,5)
	end
	if self.sSex == 'M' then
		self.tStats.sBodyTopId = "Characters/Citizen_Base/Textures/Human_Body_Male01_top_0"..self.tStats.nOutfitTopVariation
		self.tStats.sBodyBottomId = "Characters/Citizen_Base/Textures/Human_Body_Male01_bottom_0"..self.tStats.nOutfitBottomVariation
	else
		self.tStats.sBodyTopId = "Characters/Citizen_Base/Textures/Human_Body_Male01_top_0"..self.tStats.nOutfitTopVariation
		self.tStats.sBodyBottomId = "Characters/Citizen_Base/Textures/Human_Body_Male01_bottom_0"..self.tStats.nOutfitBottomVariation
	end
	table.insert(tSubsetReplacements, {self.sBodySubsetId, "g_samTop", self.tStats.sBodyTopId})
	table.insert(tSubsetReplacements, {self.sBodySubsetId, "g_samBottom", self.tStats.sBodyBottomId})
end

--[[
function Character:setHelmet()
local nHelmetVariation = Character.HEAD_TYPE[self.tStats.nHeadVariation].tJobHelmets[self.tStats.nJob]
if Character.JOB_EQUIPMENT[self.tStats.nJob]["bHasHelmet"] and nHelmetVariation ~= Character.NO_HELMET then
self.tHelmetVariation = { prefix = Character.JOB_HELMET_PREFIX, full = Character.JOB_HELMET_PREFIX..Character.JOB_HELMET_TYPE[nHelmetVariation]["sModel"] }
end
self:_updateVariation()
end
]]--

function Character:hideHelmet()
	self.tStats.bShowHelmet = false
	self:showHead()
	self:_updateVariation()
end

function Character:showHelmet()
	self.tStats.bShowHelmet = true
	if self.tStats.nJob == Character.EMERGENCY or self.tStats.nJob == Character.MINER then
		self:hideHead()
	else
		self:hideHair()
	end
	self:_updateVariation()
end

function Character:_getArmor(bAutocreate)
    for k,tItem in pairs(self.tInventory) do
        local sKey,eJob = Inventory.getOutfitOverride(tItem)
        if eJob == Character.EMERGENCY then
            return k,tItem
        end
    end
    if bAutocreate and not self.tStatus.tImprisonedIn then
        -- Don't have armor in inventory, but we can autocreate it.
        local sAutocreate
        if self.tStats.nJob == Character.EMERGENCY and Base.hasCompletedResearch('ArmorLevel2') then
            sAutocreate = 'ArmorLevel2'
        elseif self.tStats.nJob == Character.EMERGENCY or self.tStats.nJob == Character.RAIDER then
            sAutocreate = 'ArmorLevel1'
        end
        if sAutocreate then
            local tItem = Inventory.createItem(sAutocreate)
            tItem.bAutocreated = true
            local sKey = self:pickUpItem(tItem)
            return sKey,tItem
        end
    end
end

function Character:_setJobOutfit( bLoading, nJobOverride ) -- sets up job related clothing/equipment
	if Character.BODY_TYPE[self.tStats.nBodyVariation].bNoReplacements then return end

	local nJob = Character.UNEMPLOYED
	if self:onDuty() or self:isPerformingWorkShiftTask() or self:getFactionBehavior() == Character.FACTION_BEHAVIOR.EnemyGroup then
		nJob = self.tStats.nJob
	end
	if nJobOverride ~= nil then 
		nJob = nJobOverride 
	end

    -- Don't change out of work clothes for survival threats.
    if nJob == Character.UNEMPLOYED and self.nLastOutfitJob and self:getCurrentTaskPriority() > OptionData.tPriorities.NORMAL then
        nJob = self.nLastOutfitJob
    end
    
    -- We're going to autocreate and autodestroy some armor and weapons for now, since
    -- we don't have time to implement proper AI involving duty lockers.
    local sArmorKey, tArmorItem = self:_getArmor()
    if tArmorItem and tArmorItem.bAutocreated then
        self:destroyItem(sArmorKey)
    end
    -- early check for valid armor, so we can default to UNEMPLOYED if we've lost our armor.
    local sArmorKey,tArmor,sArmorOutfitKey
    if nJob == Character.EMERGENCY or nJob == Character.RAIDER then
        sArmorKey, tArmor = self:_getArmor(true)
        sArmorOutfitKey = tArmor and Inventory.getOutfitOverride(tArmor)
        if not sArmorOutfitKey then
            nJob = Character.UNEMPLOYED
        end
    end

	local tSpacesuitJobSubsetReplacements = {}
	local tJobSubsetReplacements = {}
	if nJob ~= Character.UNEMPLOYED then
		--self:setHelmet()
		local tJobDefs = Character.BODY_TYPE[self.tStats.nBodyVariation].tJobOutfits
		local nJobOutfit = nil
		if tJobDefs then
			nJobOutfit = tJobDefs[nJob]
		end
		if not nJobOutfit then
			nJobOutfit = Character.getDefaultJobOutfit( nJob, Character.BODY_TYPE[self.tStats.nBodyVariation].bFat )
		end
		--base layers
		if Character.JOB_EQUIPMENT[nJob]["sTopLayer"] then
			table.insert(tJobSubsetReplacements, {self.sBodySubsetId, "g_samTop", Character.JOB_EQUIPMENT[nJob]["sTopLayer"] })
		end
		if Character.JOB_EQUIPMENT[nJob]["sBottomLayer"] then
			table.insert(tJobSubsetReplacements, {self.sBodySubsetId, "g_samBottom", Character.JOB_EQUIPMENT[nJob]["sBottomLayer"]})
		end
		--job suit (boots, shoulder pads, belt, etc)
		if Character.JOB_EQUIPMENT[nJob]["bHasSuit"] then
			local sJobOutfitModel
			local sJobOutfitTexture
			if nJob == Character.EMERGENCY or nJob == Character.RAIDER then
                -- use the armor that we looked up earlier
                sJobOutfitModel = Character.JOB_EQUIPMENT_PREFIX..Character.JOB_OUTFIT_TYPE[nJobOutfit][sArmorOutfitKey]["sModel"]
                sJobOutfitTexture = Character.JOB_OUTFIT_TYPE[nJobOutfit][sArmorOutfitKey]["sTexture"]
			else
				sJobOutfitModel = Character.JOB_EQUIPMENT_PREFIX..Character.JOB_OUTFIT_TYPE[nJobOutfit]["sModel"]
				sJobOutfitTexture = Character.JOB_OUTFIT_TYPE[nJobOutfit]["sTexture"]
			end
			self.tJobVariation = { prefix = Character.JOB_EQUIPMENT_PREFIX, full = sJobOutfitModel }
			table.insert(tJobSubsetReplacements, { sJobOutfitModel, "g_samTop", sJobOutfitTexture })
		else
			self.tJobVariation = { prefix = Character.JOB_EQUIPMENT_PREFIX, full = "" }
		end
		-- helmet
		if Character.JOB_EQUIPMENT[nJob]["bHasHelmet"] then
			local nHelmetVariation = Character.HEAD_TYPE[self.tStats.nHeadVariation].tJobHelmets[nJob]
			if nHelmetVariation ~= Character.NO_HELMET then
				local sJobHelmetModel
				local sJobHelmetTexture
				if nJob == Character.EMERGENCY then
                    local sItemKey,tItem = self:_getArmor(true)
                    local sOutfitKey = Inventory.getOutfitOverride(tItem)
					sJobHelmetModel = Character.JOB_HELMET_PREFIX..Character.JOB_HELMET_TYPE[nHelmetVariation][sOutfitKey]["sModel"]
					sJobHelmetTexture = Character.JOB_HELMET_TYPE[nHelmetVariation][sOutfitKey]["sTexture"]
				else
					sJobHelmetModel = Character.JOB_HELMET_PREFIX..Character.JOB_HELMET_TYPE[nHelmetVariation]["sModel"]
					sJobHelmetTexture = Character.JOB_HELMET_TYPE[nHelmetVariation]["sTexture"]
				end
				table.insert(tJobSubsetReplacements, { sJobHelmetModel, "g_samTop", sJobHelmetTexture })
			end
		end
	else
		self.tJobVariation = { prefix = Character.JOB_EQUIPMENT_PREFIX, full = "" }
		table.insert(tJobSubsetReplacements, {self.sBodySubsetId, "g_samTop", self.tStats.sBodyTopId})
		table.insert(tJobSubsetReplacements, {self.sBodySubsetId, "g_samBottom", self.tStats.sBodyBottomId})
	end

	--setup spacesuit job outfits
	local sSpacesuitJobModel = Character.SPACESUIT_PREFIX..Character.SPACESUITS[nJob]["sModel"]
	local sSpacesuitJobTexture = Character.SPACESUITS[nJob]["sTexture"]
	self.tSpacesuitJobVariation = { prefix = Character.SPACESUIT_PREFIX, full = sSpacesuitJobModel }
	table.insert(tSpacesuitJobSubsetReplacements, {sSpacesuitJobModel, "g_samTop", sSpacesuitJobTexture})
	--setup spacesuit equipment (includes helmets)
	local sSpacesuitEquipmentModel = Character.SPACESUIT_JOB_EQUIPMENT_PREFIX..Character.SPACESUIT_JOB_EQUIPMENT[nJob]["sModel"]
	local sSpacesuitEquipmentTexture = Character.SPACESUIT_JOB_EQUIPMENT[nJob]["sTexture"]
	self.tSpaceHelmetVariation = { prefix = Character.SPACESUIT_JOB_EQUIPMENT_PREFIX, full = sSpacesuitEquipmentModel }
	table.insert(tSpacesuitJobSubsetReplacements, {sSpacesuitEquipmentModel, "g_samTop", sSpacesuitEquipmentTexture})

    self.nLastOutfitJob = nJob

	if nJob == Character.EMERGENCY then
		self:hideBody()
		self:showHead()
	elseif nJob == Character.MINER then
		if not bLoading then
			self:showBody()
		end
	else
		if not bLoading then
			self:showBody()
			self:showHead()
		end
	end

	local flipConflicts = function(sOutfitType, sPrefix, tConflictTable, sSubsetID)
							  --used below to flip model conflicts on/off
							  if tConflictTable then
								  for i,v in ipairs(tConflictTable) do
									  if v == nJob then
										  --turn conflicts off
										  if sOutfitType == "top" then
											  self.tTopConflictVariation = { prefix = sPrefix, full = "" }
										  else
											  self.tBottomConflictVariation = { prefix = sPrefix, full = "" }
										  end
										  break
									  else
										  --turn conflicts on
										  if sOutfitType == "top" then
											  self.tTopConflictVariation = { prefix = sPrefix, full = sSubsetID }
										  else
											  self.tBottomConflictVariation = { prefix = sPrefix, full = sSubsetID }
										  end
									  end
								  end
							  end
						  end

	--check to see if there are any model conflicts, turn them on/off
	local tTopTable, tBottomTable = {}
	if self.tStats.nTopAccessoryVariation and self.tStats.nTopAccessoryVariation ~= 0 then
		tTopTable = Character.TOP_ACCESSORY_TYPE[self.tStats.nTopAccessoryVariation]["tJobModelConflicts"]
		flipConflicts("top", Character.TOP_ACCESSORY_PREFIX, tTopTable, self.sTopAccessorySubsetId)
	end
	if self.tStats.nBottomAccessoryVariation and self.tStats.nBottomAccessoryVariation ~= 0 then
		tBottomTable = Character.BOTTOM_ACCESSORY_TYPE[self.tStats.nBottomAccessoryVariation]["tJobModelConflicts"]
		flipConflicts("bottom", Character.BOTTOM_ACCESSORY_PREFIX, tBottomTable, self.sBottomAccessorySubsetId)
	end

	self:_updateVariation()
	self:_updateSpacesuitVariation()
	if not self.rRig:setTexturePath( tJobSubsetReplacements ) then --set textures for model subsets
		Print(TT_Warning,'CHARACTER.LUA: Bad job texture replacements for',self:getUniqueID())
	end
	if self.rSpacesuitRig and not self.rSpacesuitRig:setTexturePath( tSpacesuitJobSubsetReplacements ) then --set textures for model subsets
		Print(TT_Warning,'CHARACTER.LUA: Bad spacesuit job texture replacements for',self:getUniqueID())
	end
end

function Character:_getValidAccessories( )
	local nBottom, nTop = self.tStats.nBottomAccessoryVariation, self.tStats.nTopAccessoryVariation

	if nBottom == Character.NO_REPLACE or not MiscUtil.arrayIndexOf(Character.ACCESSORY_SET_TYPE[Character.BODY_TYPE[self.tStats.nBodyVariation].nAccessorySetType].tBottomAccessories, nBottom) then nBottom = nil end
	if nTop == Character.NO_REPLACE or not MiscUtil.arrayIndexOf(Character.ACCESSORY_SET_TYPE[Character.BODY_TYPE[self.tStats.nBodyVariation].nAccessorySetType].tTopAccessories, nTop) then nTop = nil end

	if not nBottom then
		if math.random(0, 100) < 60 then
			nBottom = Character.ACCESSORY_SET_TYPE[Character.BODY_TYPE[self.tStats.nBodyVariation].nAccessorySetType]["tBottomAccessories"][math.random(1, #Character.ACCESSORY_SET_TYPE[Character.BODY_TYPE[self.tStats.nBodyVariation].nAccessorySetType]["tBottomAccessories"])]
		else
			nBottom = Character.NO_REPLACE
		end
	end
	if not nTop then
		if math.random(0,100) < 60 then
			nTop = Character.ACCESSORY_SET_TYPE[Character.BODY_TYPE[self.tStats.nBodyVariation].nAccessorySetType]["tTopAccessories"][math.random(1, #Character.ACCESSORY_SET_TYPE[Character.BODY_TYPE[self.tStats.nBodyVariation].nAccessorySetType]["tTopAccessories"])]
		else
			nTop = Character.NO_REPLACE
		end
	end
	return nBottom, nTop
end

function Character:_setAccessories( tSubsetReplacements )
	if self.tStats.nBottomAccessoryVariation ~= Character.NO_REPLACE then
		self.sBottomAccessorySubsetId = Character.BOTTOM_ACCESSORY_PREFIX..Character.BOTTOM_ACCESSORY_TYPE[self.tStats.nBottomAccessoryVariation]["sModel"]
		local sBottom = Character.BOTTOM_ACCESSORY_TYPE[self.tStats.nBottomAccessoryVariation]["sTexture"]
		if sBottom then
			table.insert(tSubsetReplacements, {self.sBottomAccessorySubsetId, "g_samBase", sBottom})
			table.insert(tSubsetReplacements, {self.sBottomAccessorySubsetId, "g_samTop", sBottom})
			table.insert(tSubsetReplacements, {self.sBottomAccessorySubsetId, "g_samBottom", sBottom})
		end
		self.tBottomAccessoryVariation = { prefix = Character.BOTTOM_ACCESSORY_PREFIX, full = self.sBottomAccessorySubsetId }
		self.tStats.bBottomTopAccessory = true
	else
		--turn off all bottom accessories
		self.tBottomAccessoryVariation = { prefix = Character.BOTTOM_ACCESSORY_PREFIX, full = "" }
	end
	if self.tStats.nTopAccessoryVariation ~= Character.NO_REPLACE then
		self.sTopAccessorySubsetId = Character.TOP_ACCESSORY_PREFIX..Character.TOP_ACCESSORY_TYPE[self.tStats.nTopAccessoryVariation]["sModel"]
		local sTop = Character.TOP_ACCESSORY_TYPE[self.tStats.nTopAccessoryVariation]["sTexture"]
		if sTop then
			table.insert(tSubsetReplacements, {self.sTopAccessorySubsetId, "g_samBase", sTop})
			table.insert(tSubsetReplacements, {self.sTopAccessorySubsetId, "g_samTop", sTop})
			table.insert(tSubsetReplacements, {self.sTopAccessorySubsetId, "g_samBottom", sTop})
		end
		self.tTopAccessoryVariation = { prefix = Character.TOP_ACCESSORY_PREFIX, full = self.sTopAccessorySubsetId }
	else
		--turn off all top accessories
		self.tTopAccessoryVariation = { prefix = Character.TOP_ACCESSORY_PREFIX, full = "" }
	end
end

--[[function Character:_setHandAccessoryTextures( tSubsetReplacements )
for i,v in ipairs(Character.JOB_HAND_ACCESSORIES) do
local sModel, sTexture
sModel = Character.JOB_HAND_ACCESSORY_PREFIX..v.sModel
sTexture = v.sTexture
if sTexture then
table.insert( tSubsetReplacements, {sModel, "g_samTop", sTexture })
end
end
end]]--

function Character:_setSpacesuitHandAccessoryTextures( tSpacesuitReplacements )
	for i,v in ipairs(Character.SPACESUIT_JOB_HAND_ACCESSORIES) do
		local sModel, sTexture
		sModel = Character.JOB_HAND_ACCESSORY_PREFIX..v.sModel
		sTexture = v.sTexture
		table.insert( tSpacesuitReplacements, {sModel, "g_samTop", sTexture })
	end
end

--[[function Character:hideHandAccessory()
self.tHandVariations = {}
self.tHandAccessoryVariation = { prefix = Character.JOB_HAND_ACCESSORY_PREFIX, full = "" }
table.insert(self.tHandVariations, self.tHandAccessoryVariation)
self.rRig:setVariationLayer( self.tHandVariations )
end]]--

function Character:toggleSpacesuit()
	if self.rRig:isActive() then
		self:spacesuitOn()
	else
		self:spacesuitOff()
	end
end

function Character:spacesuitOn(bInitializing)
	if not self.rSpacesuitRig then return end

	self.rRig:deactivate()
	self.rSpacesuitRig:activate()
	self:_setSpacesuitRigActive(true)
	self.tStatus.nUnnecessarySpacesuit = nil

	-- (re)fill suit oxygen
	if not bInitializing then
		self.tStatus.suitOxygen = Character.SPACESUIT_MAX_OXYGEN
	end

	local o2 = self:_getOxygen()
	self:_updateSpacewalking(o2 < Character.OXYGEN_LOW)

	local wx, wy = self:getLoc()
	SoundManager.playSfx3D("spacesuit", wx, wy)
	self:playAnim("breathe")
end

function Character:spacesuitOff()
	if not self.rSpacesuitRig then return end

	self.rRig:activate()
	self.rSpacesuitRig:deactivate()
	self:_setSpacesuitRigActive(false)
	self.tStatus.nUnnecessarySpacesuit = nil

	local o2 = self:_getOxygen()
	self:_updateSpacewalking(o2 < Character.OXYGEN_LOW)

	assert(o2 > Character.OXYGEN_LOW)
	local r = self:getRoom()
	if not r or r.bBreach or r == Room.getSpaceRoom() then
		print(TT_Warning, 'CHARACTER.LUA: Taking off spacesuit in a breached room.')
	end

	local ctx, cty = self:getLoc()
	SoundManager.playSfx3D("spacesuit", ctx, cty)
	self:playAnim("breathe")
end

function Character:_setSpacesuitRigActive(bActive)
	if not self.rSpacesuitRig then return end

	if (bActive and self.rCurrentRig == self.rSpacesuitRig) or
	(not bActive and self.rCurrentRig == self.rRig) then
		return
	end

	if self.tAttachedEntity then
		self.rCurrentRig:detach(self.tAttachedEntity.rRig)
		self.tAttachedEntity.rRig:deactivate()
		self.tAttachedEntity = nil
	end

	if self.currentAccessory then
		self.rCurrentRig:detach(self.currentAccessory)
		self.currentAccessory:deactivate()
		self.currentAccessory = nil
	end

	self.rCurrentRig = (bActive and self.rSpacesuitRig) or self.rRig

	self:_refreshHeldItemVisibility()
end

function Character:addAffinity(sKey,nChange)
    local nAff = self:getAffinity(sKey)
    nAff = DFMath.clamp(nAff+nChange, -Character.MAX_AFFINITY, Character.MAX_AFFINITY)
    self.tAffinity[sKey] = nAff
end

function Character:addRoomAffinity(nChange)
    local r = self:getRoom()
    if r then self:addAffinity('Room '..r.id,nChange or Character.AFFINITY_CHANGE_MINOR) end
end

function Character:getRoomAffinity(rRoom)
    return self:getAffinity('Room'..rRoom.id) or 0
end

function Character:addObjectAffinity(rObj,nChange)
    local tTag = rObj and rObj._ObjectList_ObjectMarker 
    if not tTag then return end
    if ObjectList.getObject(tTag) then
        self:addAffinity(tTag,nChange)
    else
        self.tAffinity[tTag] = nil
    end
end

function Character:getAffinity(topic)
	if not self.tAffinity[topic] then
		assertdev(type(topic) == 'string' or type(topic) == 'number' or (type(topic) == 'table' and topic.objID))
		self:generateAffinityFor(topic)
	end
	return self.tAffinity[topic]
end

function Character:generateAffinityFor(topic)
	local nMin,nMax = -Character.STARTING_AFFINITY,Character.STARTING_AFFINITY
	-- if topic is a person, get object reference from string
	local bIsPerson = false
	local rOther
	for _,sPerson in pairs(Topics.tTopicsByCategory.People) do
		if topic == sPerson then
			bIsPerson = true
			rOther = CharacterManager.getCharacterByUniqueID(topic)
			break
		end
	end
	-- special case: base founders all get along and enjoy building
	if self.tStatus.bBaseFounder then
		if topic == 'DUTY_Builder' then
			nMin = 2
		elseif bIsPerson and rOther and rOther.tStatus.bBaseFounder then
			nMin = 3
		end
	end
	self.tAffinity[topic] = math.random(nMin, nMax)
end

function Character:getNormalizedAffinity(topic)
    return .5 + .5 * self:getAffinity(topic) * self.MAX_AFFINITY_INVERSE
end

function Character:getJobAffinity(nJob)
	-- string concat here should match what's done in Topics.addTopic
	local sJobTopic = 'DUTY_' .. g_LM.line(Character.JOB_NAMES[nJob])
	return self:getAffinity(sJobTopic)
end

function Character:getAffinityIconAndColor(nAff)
	-- returns a smiley/frowny icon and color appropriate for given affinity
	local sIcon = 'ui_dialogicon_bigfrown'
    local tColor = Gui.RED 
	for _,tData in ipairs(Character.AFFINITY_ICONS) do
		if nAff >= tData.nAffMin then
			sIcon = tData.sIconName
			tColor = tData.tColor
		end
	end
	return sIcon, tColor
end

function Character:getAffinityForActivity(sActivityName)
	local topic = Topics.getTopicForActivity(sActivityName)
	-- don't getAffinity for activity unless it's also a topic, else
	-- we'll get a bogus affinity for it
	if topic then
		return self:getAffinity(topic)
	end
end

function Character:getPeopleOfAffinity(nAffinity, bGreaterThan)
	if not nAffinity then
		return {}
	end
	local tResults = {}
	local bPlayersTeam = self:isPlayersTeam()
	local Topics = require('Topics')
	for topic,tData in pairs(Topics.tTopics) do
		local nAff = self:getAffinity(topic)
		if tData.category == 'People' and nAff and topic ~= self.tStats.sUniqueID then
			-- if the category is 'People', topic is the unique Id
			local rOtherChar = CharacterManager.getCharacterByUniqueID(topic)
			if rOtherChar and bPlayersTeam == rOtherChar:isPlayersTeam() then
				-- store familiarity, affinity so we can sort intelligently
				local tOtherData = {
					sID = topic,
					sName = rOtherChar.tStats.sName,
					nFamiliarity = self:getFamiliarity(topic),
					nAffinity = nAff,
				}
				if bGreaterThan and nAff >= nAffinity then
					table.insert(tResults, tOtherData)
				elseif not bGreaterThan and nAff < nAffinity then
					table.insert(tResults, tOtherData)
				end
			end
		end
	end
	-- sort results by affinity * (familiarity * familiarity_scale_factor)
	local function getScaledAffinity(tData)
		return tData.nAffinity * (tData.nFamiliarity * 0.1)
	end
	local f = function(x,y) return getScaledAffinity(x) > getScaledAffinity(y) end
	-- sort in reverse (worst enemies first) if checking below given affinity
	if not bGreaterThan then
		f = function(x,y) return getScaledAffinity(x) < getScaledAffinity(y) end
	end
	table.sort(tResults, f)
	return tResults
end

function Character:getFavorite(category)
	local Topics = require('Topics')
	local favorite, favAff = nil, -Character.MAX_AFFINITY

	for topic,tData in pairs(Topics.tTopics) do
		if tData.category == category and self:getAffinity(topic) and self:getAffinity(topic) > favAff then
			favorite = topic
			favAff = self:getAffinity(topic)
		end
	end
	return favorite
end

function Character:getSortedAffinityList(category)
	-- returns table of topics for category, sorted by our affinities
	local Topics = require('Topics')
	local tAff = {}
	for topic,tData in pairs(Topics.tTopics) do
		if tData.category == category and self:getAffinity(topic) then
			table.insert(tAff, {topic=topic, name=tData.name, aff=self:getAffinity(topic), id=topic})
		end
	end
	local f = function(x,y) return self:getAffinity(x.topic) > self:getAffinity(y.topic) end
	table.sort(tAff, f)
	return tAff
end

function Character:getFamiliarity(sID)
	-- as with getAffinity, old savegames / bugs will cause gaps
	-- in this table we cover here
	if not self.tFamiliarity[sID] then
		self:setFamiliarity(sID, 0)
	end
	return self.tFamiliarity[sID]
end

function Character:setFamiliarity(sID, amount)
	self.tFamiliarity[sID] = amount
end

function Character:addFamiliarity(sID, amount)
	self:setFamiliarity(sID, self:getFamiliarity(sID) + amount)
end

function Character:queueLog(tEntry)
	-- only queue line if it isn't already
	if not self:isLineCodeQueued(tEntry.linecode) then
		table.insert(self.tLogQueue, tEntry)
	end
    self:_capLogSize()
end

function Character:isLineCodeQueued(sLC)
	for _,log in pairs(self.tLogQueue) do
		if log.linecode == sLC then
			return true
		end
	end
end

function Character:getRecentLogs(nCount)
	local tRecentLogs = {}
	local nLogs = #self.tLog
	nCount = nCount or Character.LOG_RECENT_HISTORY
	local startSlice, endSlice = nLogs - nCount, nLogs
	for i=startSlice,endSlice do
		table.insert(tRecentLogs, self.tLog[i])
	end
	return tRecentLogs
end

function Character:lineCodeUsedRecently(sLineCode)
	-- returns true if we used this linecode recently
	local tRecentLogs = self:getRecentLogs()
	-- check for our linecode in the slice
	for _,log in pairs(tRecentLogs) do
		if log.linecode == sLineCode then
			return true
		end
	end
	return false
end

function Character:logTypePostedRecently(sType, nCount, bDontCheckQueue)
	local tRecentLogs = self:getRecentLogs(nCount)
	for _,log in pairs(tRecentLogs) do
		if log.logType == sType then
			return true
		end
	end
	if not bDontCheckQueue then
		for _,log in pairs(self.tLogQueue) do
			if log.logType == sType then
				return true
			end
		end
	end
	return false
end

function Character:postLogFromQueue()
	-- post one or more logs from queue based on priority, tag score
	if not self.tLogQueue or #self.tLogQueue == 0 then
		return false
	end
	-- sort log queue by priority
	local f = function(x,y) return x.priority > y.priority end
	table.sort(self.tLogQueue, f)
	-- build a list of logs to consider posting
	local tLogs = {}
	local nHighestPri = self.tLogQueue[1].priority or Log.DEFAULT_PRIORITY
	local nHighestTagScore = 0
	for _,tEntry in pairs(self.tLogQueue) do
		local nPri = tEntry.priority or Log.DEFAULT_PRIORITY
		-- above a certain priority, immediately post
		if nPri >= Log.PRIORITY_ALWAYS_POST then
			self:addLog(tEntry)
		elseif nPri >= nHighestPri then
			nHighestPri = nPri
			if tEntry.nTagScore > nHighestTagScore then
				nHighestTagScore = tEntry.nTagScore
			end
			table.insert(tLogs, tEntry)
		end
	end
	-- sort list by tag score
	local f = function(x,y) return x.nTagScore > y.nTagScore end
	table.sort(tLogs, f)
	-- drop all but highest tag score
	for i,tEntry in pairs(tLogs) do
		if tEntry.nTagScore < nHighestTagScore then
			table.remove(tLogs, i)
		end
	end
	-- pick randomly from remaining logs (usually just one remains)
	self:addLog(DFUtil.arrayRandom(tLogs))
	return true
end

function Character:addLog(tEntry)
	self.tStats.nLastLogTime = GameRules.simTime
	table.insert(self.tLog, tEntry)
    self:_capLogSize()
end

function Character:_setLog( tData )
	-- if tLog or tLogQueue is nil, first log will be made in updateAI
	self.tLog = tData.tLog or {}
	self.tLogQueue = tData.tLogQueue or {}
    self:_capLogSize()
end

function Character:_capLogSize()
	-- remove from beginning of list, ie oldest entries
    while #self.tLog > Character.MAX_LOG_ENTRIES do
        table.remove(self.tLog, 1)
    end
    while #self.tLogQueue > Character.MAX_LOG_ENTRIES do
        table.remove(self.tLogQueue, 1)
    end
end

function Character:_setUpBlobShadow()
	self.rBlobShadow = MOAIProp.new()
	local blobShadowSpriteSheet = DFGraphics.loadSpriteSheet( 'UI/UIMisc' )
	for sSprite, _ in pairs( blobShadowSpriteSheet.names ) do
		DFGraphics.alignSprite(blobShadowSpriteSheet, sSprite, "center", "center", 1, 1)
	end
	self.rBlobShadow:setDeck(blobShadowSpriteSheet)
	self.rBlobShadow:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	self.rBlobShadow:setLoc(0, -25, -50)
	self.rBlobShadow:setScl(1, 1)
	self.rBlobShadow:setIndex(blobShadowSpriteSheet.names['blobshadow'])
	self.rBlobShadow.bVisible = true
	local rRenderLayer = Renderer.getRenderLayer("WorldFloor")
	rRenderLayer:insertProp( self.rBlobShadow )
end

function Character:_setUpEmoticon()
	--
	-- thought / word bubble, drawn beneath emoticon
	--
	local bubbleX, bubbleY = -16, 335
	local bubbleBGX, bubbleBGY = bubbleX + 40, bubbleY
	local bubbleLeftCapX, bubbleLeftCapY = -40, bubbleY
	local bubbleRightCapX, bubbleRightCapY = bubbleX + 88, bubbleY
	local emoticonX, emoticonY = bubbleX - 36, bubbleY + 14
	local textX, textY = bubbleX + 2, bubbleY + 20

	self.rEmoticonBubbleTail = MOAIProp2D.new()
	self.rEmoticonSpriteSheet = DFGraphics.loadSpriteSheet( 'UI/Emoticons' )
	for sSprite, _ in pairs( self.rEmoticonSpriteSheet.names ) do
		DFGraphics.alignSprite(self.rEmoticonSpriteSheet, sSprite, "left", "top", 1, 1)
	end
	self.rEmoticonBubbleTail:setVisible(false)
	self.rEmoticonBubbleTail:setDeck(self.rEmoticonSpriteSheet)
	self.rEmoticonBubbleTail:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	self.rEmoticonBubbleTail:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1.0)
	self.rEmoticonBubbleTail:setLoc(bubbleX - 0.1, bubbleY, -20)
	--self.rEmoticonBubbleTail:setScl(1.5, 1.5)

	self.rEmoticonBubbleLeftCap = MOAIProp2D.new()
	self.rEmoticonSpriteSheet = DFGraphics.loadSpriteSheet( 'UI/Emoticons' )
	for sSprite, _ in pairs( self.rEmoticonSpriteSheet.names ) do
		DFGraphics.alignSprite(self.rEmoticonSpriteSheet, sSprite, "left", "top", 1, 1)
	end
	self.rEmoticonBubbleLeftCap:setVisible(false)
	self.rEmoticonBubbleLeftCap:setDeck(self.rEmoticonSpriteSheet)
	self.rEmoticonBubbleLeftCap:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	self.rEmoticonBubbleLeftCap:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1.0)
	self.rEmoticonBubbleLeftCap:setLoc(bubbleLeftCapX, bubbleLeftCapY, -20)
	--self.rEmoticonBubbleLeftCap:setScl(1.5, 1.5)

	local bubbleBGWidth = 40

	self.tEmoticonBubbleBGSegments = {}
	for i=1,kMAX_BUBBLE_BG_SEGMENTS do
		local segment = MOAIProp2D.new()
		segment:setVisible(false)
		segment:setDeck(self.rEmoticonSpriteSheet)
		segment:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
		segment:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1.0)
		segment:setLoc(bubbleBGX + (bubbleBGWidth * (i - 1)) - i * 0.1, bubbleBGY, -20)
		table.insert(self.tEmoticonBubbleBGSegments, segment)
	end

	self.rEmoticonBubbleRightCap = MOAIProp2D.new()
	self.rEmoticonSpriteSheet = DFGraphics.loadSpriteSheet( 'UI/Emoticons' )
	for sSprite, _ in pairs( self.rEmoticonSpriteSheet.names ) do
		DFGraphics.alignSprite(self.rEmoticonSpriteSheet, sSprite, "left", "top", 1, 1)
	end
	self.rEmoticonBubbleRightCap:setVisible(false)
	self.rEmoticonBubbleRightCap:setDeck(self.rEmoticonSpriteSheet)
	self.rEmoticonBubbleRightCap:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	self.rEmoticonBubbleRightCap:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1.0)
	self.rEmoticonBubbleRightCap:setLoc(bubbleRightCapX, bubbleRightCapY, -20)
	--self.rEmoticonBubbleRightCap:setScl(1.5, 1.5)
	-- offset
	-- set Z loc for sorting
	--self.rEmoticonBubble:setLoc(0, 375, 10)

	-- the bit with the actual emoticon
	--
	self.rEmoticon = MOAIProp2D.new()
	self.rEmoticon:setVisible(false)
	self.rEmoticon:setDeck(self.rEmoticonSpriteSheet)
	self.rEmoticon:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	self.rEmoticon:setLoc(emoticonX, bubbleLeftCapY + 1, -19.99)
	self.rEmoticon:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1.0)
	--self.rEmoticon:setScl(1.5, 1.5)
	self.rEmoticon:setDepthMask(true)
	self.rEmoticon:setDepthTest(MOAIProp.DEPTH_TEST_LESS_EQUAL)

	-- text
	self.rEmoticonText = Gui.createTextBox('dosissemibold30', MOAITextBox.LEFT_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
	self.rEmoticonText:setRect(0,100,800,0)
	self.rEmoticonText:setString("thinkin'...")
	self.rEmoticonText:setColor(Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1.0)
	self.rEmoticonText:setLoc(textX, textY, -19.99)
	self.rEmoticonText:setAttrLink( MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT )
	self.rEmoticonText:setDepthMask(true)
	self.rEmoticonText:setDepthTest(MOAIProp.DEPTH_TEST_GREATER_EQUAL)
end

function Character:hover(hoverTime)
	local alpha = math.abs(math.sin(hoverTime * 4)) / 2 + 0.5
	self.rCurrentRig:setRigShaderValue('g_vHighlightColor', {g_GuiManager.AMBER[1], g_GuiManager.AMBER[2], g_GuiManager.AMBER[3], alpha})
	-- don't stomp word bubble if chatting
	if not self:isChatting() and self.rCurrentTask then
		self.rCurrentTask:showEmoticon()
	end
end

function Character:unHover()
	self.rCurrentRig:setRigShaderValue('g_vHighlightColor', self.tHighlightColor or {0, 0, 0, 0})
	if not self:isChatting() and self.rCurrentTask then
		self.rCurrentTask:dismissEmoticon()
	end
end

function Character:_setHighlightColor(r,g,b,a)
	if not r then
		self.tHighlightColor=nil
	else
		self.tHighlightColor={r,g,b,a}
	end
	self.rCurrentRig:setRigShaderValue('g_vHighlightColor', self.tHighlightColor or {0,0,0,0})
end

function Character:playVoiceCue(sCueType)
	local x,y,z = self:getLoc()

	local sVoiceCue = self.sVoicePathPrefix .. sCueType

	--print("playing voice cue: " .. sVoiceCue)

	local rEvent = MOAIFmodEventMgr.playEvent3D( sVoiceCue, x, y, 0)

	--[[
	if rEvent == nil or not rEvent:isValid() then
	Trace("Couldn't play audio cue: " .. sVoiceCue)
	end
	]]--

	return rEvent
end

function Character:_selectVoice()
	local bIsMale = self.sSex == "M"
	local nRace = self.tStats.nRace

	local tCharDef = Character.RACE_TYPE[nRace]
	local tVoices = tCharDef.tMaleVoices
	if not bIsMale then
		tVoices = tCharDef.tFemaleVoices
	end

	self.sVoicePathPrefix = DFUtil.arrayRandom(tVoices)
end


--
-- Held Items
--

-- Satisfaction uses log base 10, to make it easy to become reasonably satisfied and then hit diminishing returns.
-- Returns a number between -100,100
-- tOptionalNewObj: add this object's satisfaction into the mix, e.g. pretend we own it.
-- tOptionalOldObj: DO NOT add this object's satisfaction into the mix, e.g. pretend we DO NOT own it.
function Character:getStuffSatisfaction(tOptionalNewObj,tOptionalOldObj)
    local nTotal = 1 
    for sName,tItemTag in pairs(self.tOwnedStuff) do
        local rObj = ObjectList.getObject(tItemTag)
        if not rObj or Inventory.getOwner(rObj) ~= self then
            self.tOwnedStuff[sName] = nil
            self.nOwnedStuff = DFUtil.tableSize(self.tOwnedStuff)
        else
            if rObj ~= tOptionalOldObj and rObj ~= tOptionalNewObj then
                nTotal = nTotal + self:getObjectAffinity(rObj) * .1
            end
        end
    end
    if tOptionalNewObj then
        nTotal = nTotal + self:getObjectAffinity(tOptionalNewObj) * .1
    end
    nTotal = math.max(math.min(nTotal,10),1)
    -- log over the range 1-10, giving us a satisfaction 0-1
    nTotal = math.log10(nTotal)
    -- remap that to -100,100 to match our other satisfactions.
    nTotal = nTotal*200-100
    return nTotal
end

function Character:getWorstItem(bForIncinerate)
    local nBestDiscard,sBestDiscard
    for sObjectKey,tItem in pairs(self.tInventory) do
        if Inventory.isStuff(tItem) then
            local job,bJobTool = Inventory.getItemJob(tItem)
            local nAff = self:getObjectAffinity(tItem)
            if (not bForIncinerate or Inventory.allowIncinerate(tItem)) and (not nBestDiscard or nBestDiscard > nAff) then
                nBestDiscard = nAff
                sBestDiscard = sObjectKey
            end
        end
    end
    return sBestDiscard
end

function Character:getObjectAffinity(tItem,bNormalize)
    if not self.tAffinity[tItem.sName] then
        local nAff = 0
        local nTags = 0
        for k,v in pairs(InventoryData.tTags) do
            nTags = nTags+1
            if tItem[k] then
                nAff = nAff + self:getAffinity('TAG_' .. tItem[k])
            end
        end
        
        -- Give a random addition to items with few/no tags, so they still get picked up & traded.
        -- Plus a small random factor to all items, so that all items are slightly unequal.
        if nTags == 1 then nAff = nAff * 2 + (-3 + 6*math.random())
        elseif nTags == 0 then nAff = nAff + -8+16*math.random()
        else nAff = nAff + -1+2*math.random() end
        
        nAff = math.max(-Character.MAX_AFFINITY, math.min(Character.MAX_AFFINITY, nAff))
        self.tAffinity[tItem.sName] = nAff
    end
    
    local job,bJobTool = Inventory.getItemJob(tItem)
    if bJobTool then
        local nAff = self:getNormalizedAffinity(tItem.sName)
        -- For job tools, I just use affinity to lerp between -max,0 or 5,max based on whether it fits your job or not.
        -- This handles changing jobs gracefully.
        if job == self:getJob() then
            if bNormalize then return DFMath.lerp(.5+5/40,1,nAff) end
		    return DFMath.lerp(5,Character.MAX_AFFINITY,nAff)
        else
            if bNormalize then return DFMath.lerp(0,.5,nAff) end
		    return DFMath.lerp(-Character.MAX_AFFINITY,0,nAff)
        end
    end
    if bNormalize then return self:getNormalizedAffinity(tItem.sName) end
    return self:getAffinity(tItem.sName)
end

function Character:getSortedTagAffinities()
    -- returns list of tags sorted by our affinity for them
    local tTagList = {}
    for sTagType,tTags in pairs(InventoryData.tTags) do
        for sTag,tTagData in pairs(tTags) do
            local t = {
				sType = sTagType,
                sTag = sTag,
                nAff = self:getAffinity('TAG_' .. sTag),
                -- include linecode
                sLC = tTagData.lc
            }
            table.insert(tTagList, t)
        end
    end
    local f = function(x,y) return x.nAff > y.nAff end
    table.sort(tTagList, f)
    return tTagList
end

function Character:getMostLikedTag(tItem)
	-- returns most liked tag for selected item
	local tTagAffinities = self:getSortedTagAffinities()
	-- list is sorted in order of affinity, first item we find is most loved
	for _,tTagData in pairs(tTagAffinities) do
		-- item has this tag?
		if tItem[tTagData.sType] == tTagData.sTag then
			-- return tag + this tag's InventoryData.tTags entry
			for sTagType,tTags in pairs(InventoryData.tTags) do
				if sTagType == tTagData.sType then
					return tTagData.sTag, tTags[tTagData.sTag]
				end
			end
		end
	end
end

function Character:getNumOwnedStuff()
    return self.nOwnedStuff
end

function Character:getInventoryCountByTemplate(sTemplate)
    local tItem = self:getInventoryItemOfTemplate(sTemplate)
	return (tItem and tItem.nCount) or 0
end

function Character:getInventoryItemOfTemplate(sTemplateName)
	for k,tItem in pairs(self.tInventory) do
        if tItem.sTemplate == sTemplateName then
            return tItem
        end
    end
end

function Character:getInventoryString()
	local sString = ""
	for k,tItem in pairs(self.tInventory) do
        sString = sString..tItem.sName..'\n'
	end
	if sString == "" then
		sString = g_LM.line('INSPEC075TEXT') -- None by default
	end
	return sString
end

function Character:_updateOldInventorySaves()
	for sItemName, tItem in pairs(self.tInventory) do    
        self.tInventory[sItemName] = Inventory.portFromSave(sItemName, tItem)
        if self.tInventory[sItemName] then
            self.tInventory[sItemName].tContainer = ObjectList.getTag(self)
        end
	end
end

function Character:_refreshHeldItemVisibility()
    if self.tStatus.sHeldItemName and not self.tInventory[self.tStatus.sHeldItemName] then
        self.tStatus.sHeldItemName = nil
    end
	if (not self.tStatus.sHeldItemName and not self.tAttachedEntity) or
	(self.tAttachedEntity and self.tStatus.sHeldItemName and (self.tStats.sUniqueID..'_'..self.tStatus.sHeldItemName) == self.tAttachedEntity.sName) then
		return
	end

	if self.tAttachedEntity then
		self.rCurrentRig:detach(self.tAttachedEntity.rRig)
		self.tAttachedEntity.rRig:deactivate()
		self.tAttachedEntity = nil
	end

	if self.tStatus.sHeldItemName then
		local rRenderLayer = Renderer.getRenderLayer(Character.RENDER_LAYER)
        local tHeldItem = self.tInventory[self.tStatus.sHeldItemName]
        
        assertdev(tHeldItem)
        if not tHeldItem then return end
        local sPickupName = Inventory.getPickupName(tHeldItem)
        assertdev(sPickupName)
        local tData = PickupData.tObjects[sPickupName]
        assertdev(tData)
        if not sPickupName or not tData then return end
		
		self.tAttachedEntity = Entity.new(self, rRenderLayer, self.tStats.sUniqueID..'_'..self.tStatus.sHeldItemName)
		local tRigArgs = {}
		tRigArgs.sResource = tData.sRigPath
		tRigArgs.sMaterial = "meshSingleTexture"
		tRigArgs.sTexture = tData.sTexture
		local rRig = Rig.new(self.tAttachedEntity, tRigArgs, self.rAssetSet)
		self.tAttachedEntity.rRig = rRig
		rRig:activate()
		self.rCurrentRig:attach(rRig, tData.sTargetAttachJointName or 'Rt_Prop',
								tData.tOffsetPosition, tData.tOffsetRotation, tData.tScale)
		--self:playOverlayAnim('carry')
	else
		--self:clearOverlayAnim()
	end
end

function Character:getWalkAnim()
    local _,nIllnesses = self:getIllnesses()
    local tHeldItem = self:heldItem()
    local sWalk = nil
	if tHeldItem then
		local tPickupData = PickupData.tObjects[Inventory.getPickupName(tHeldItem)]
		return tPickupData.sCustomCarryAnim or 'carry_walk'
    -- use low o2 walk if sick also
	elseif self:hasUtilityStatus(Character.STATUS_RAMPAGE) then
		sWalk = 'walk_tantrum'
	elseif self.tStatus.bLowOxygen or nIllnesses > 0 then
        if self.tStats.bHideSigns and self.tStats.bHideSigns==true then
        sWalk= 'walk'
        else
         sWalk = 'walk_low_oxygen'
        end
	elseif self.tStats.nMorale > Character.MORALE_SPEED_THRESHOLD then
		sWalk = 'walk_happy'
	elseif self.tStats.nMorale < -Character.MORALE_SPEED_THRESHOLD then
		sWalk = 'walk_sad'
	else
		return 'walk'
	end
    -- if we're in a stance, verify we have the special walk before trying to use it.
    if sWalk then
        if self.sStance then
            local tAnimSetData = self.tAnimations[self.rCurrentRig]
            if tAnimSetData['stance'] and tAnimSetData['stance'][self.sStance] and tAnimSetData['stance'][self.sStance][sWalk] then
                return sWalk
            end
            return 'walk'
        end
        return sWalk
    end
    return 'walk'
end

function Character:getBreatheAnim()
    local tHeldItem = self:heldItem()
	if tHeldItem then
		local tPickupData = PickupData.tObjects[Inventory.getPickupName(tHeldItem)]
		return tPickupData.sCustomBreatheAnim or 'carry_breathe'
	end
	return 'breathe'
end

function Character:getIdleAnim()
    if not self.tStatus.nLastIdleAnimTime then
        self.tStatus.nLastIdleAnimTime = GameRules.elapsedTime
    end
    local sAnim,tAnimData = Malady.getSymptomAnim(self)
    if sAnim then return sAnim,tAnimData end

    local nTimeBetween = Character.TIME_BETWEEN_IDLE_ANIMS
    if self.tStatus.bRampageNonviolent or self.tStatus.bRampageViolent then
        nTimeBetween = Character.TIME_BETWEEN_IDLE_ANIMS_RAMPAGE
        sAnim = 'tantrum'
    elseif self.tNeeds['Energy'] < Character.NEEDS_ENERGY_TIRED then
        nTimeBetween = Character.TIME_BETWEEN_IDLE_ANIMS_TIRED
        sAnim = 'yawn'
    end
    if sAnim and GameRules.elapsedTime - self.tStatus.nLastIdleAnimTime > nTimeBetween then
        return sAnim
    end
end

function Character:playedIdleAnim(sAnimName,tAnimData)
    self.tStatus.nLastIdleAnimTime = GameRules.elapsedTime
    if tAnimData then
        Malady.playedSymptomAnim(self,sAnimName,tAnimData)
    end
end

function Character:heldItemName()
    if self.tStatus.sHeldItemName and not self.tInventory[self.tStatus.sHeldItemName] then
        self.tStatus.sHeldItemName = nil
    end
    return self.tStatus.sHeldItemName
end

function Character:heldItem()
	if self.tStatus.sHeldItemName then 
        local tItem = self.tInventory[self.tStatus.sHeldItemName] 
        if not tItem then self.tStatus.sHeldItemName = nil end
        return tItem
    end
end

function Character:getDisplayItem()
    for objKey,tItem in pairs(self.tInventory) do
        if Inventory.getDisplaySprite(tItem) and Inventory.isStuff(tItem) then
            return objKey,tItem
        end
    end
end

function Character:destroyItem(sObjectKey,nCount)
    if not sObjectKey then return end
    local tItem = self:_removeItem(sObjectKey,nCount,false)
    if tItem then
        Inventory.assignOwner(tItem,nil)
        local tTag = ObjectList.getTag(tItem)
        if tTag then 
            ObjectList.removeObject(tTag) 
        end
        return tItem
    end
end

function Character:dropItemOnFloor(sObjectKey,nCount,wx,wy)
    if not sObjectKey then return end
    local tItem = self:_removeItem(sObjectKey,nCount,false)
    if tItem then
        Inventory.assignOwner(tItem,nil)
        if not wx then
            wx,wy = self:getLoc()
        end
        local rPickup = Pickup.dropInventoryItemAt(tItem,wx,wy)
        return rPickup,tItem
    end
end

function Character:transferItemTo(rDestObj,sObjectKey,nCount)
    if not sObjectKey then return end
    local sObjType = ObjectList.getObjType(rDestObj)

    local tItem
    if sObjType == ObjectList.CHARACTER then
        tItem = self:_removeItem(sObjectKey,nCount,false)
        if tItem then
        	rDestObj:pickUpItem(tItem)
       		return tItem
       	else
       		return nil
       	end
    elseif sObjType == ObjectList.ENVOBJECT then
        tItem = self:_removeItem(sObjectKey,nCount,true)
        if tItem then
        	rDestObj:addItem(tItem)
        	return tItem
       	else
        	return nil
        end
    else
        -- MTF NOTE: we could implement INVENTORYITEM and WORLDOBJECT if necessary
        assertdev(false)
    end
end

-- nCount specifies how many to remove. Default is "all".
function Character:_removeItem(sObjectKey,nCount,bRetainOwnership)
    local tItem = Inventory.removeItemFromContainer(self.tInventory,sObjectKey,nCount)
    if not tItem then
    	return nil
    end

    if not bRetainOwnership and not self.tInventory[sObjectKey] then
        self.tOwnedStuff[sObjectKey] = nil
        self.nOwnedStuff = DFUtil.tableSize(self.tOwnedStuff)
        Inventory.assignOwner(tItem,nil)
    end
    tItem.nTimeTradeDesired = nil
    if self.tStatus.sHeldItemName == sObjectKey then 
        self.tStatus.sHeldItemName = nil 
    end
    if self.sDrawnWeapon == sObjectKey then
        self:setWeaponDrawn(false)
    end
	self:_refreshHeldItemVisibility()
    return tItem
end

function Character:_addHeldItem(tItem)
	if self.tStatus.sHeldItemName ~= tItem.sName then
        if self.tStatus.sHeldItemName then
            -- This first check is because some items changed keys across savegames. We don't want to 
            -- drop the held item when it's actually what we're adding.
            if self.tInventory[self.tStatus.sHeldItemName] == tItem then
                self.tInventory[self.tStatus.sHeldItemName] = nil
            else
                self:dropItemOnFloor(self.tStatus.sHeldItemName)
            end
        end
		self.tStatus.sHeldItemName = tItem.sName
		self:_refreshHeldItemVisibility()
	end
end

function Character:generateStartingStuff()
    if self.tStats.nRace == Character.RACE_MONSTER or self.tStats.nRace == Character.RACE_KILLBOT then return end
    
    local n
    if self.tStats.nJob == Character.RAIDER then
        n = (math.random() > .5 and 1) or 0
    else
        n = (math.random() > .5 and 2) or 1
    end
    for i=1,n do
        -- It's possible to generate an item we already have.
        local tItem = Inventory.createRandomStartingStuff()
        if self.tInventory[tItem.sName] then
            ObjectList.removeObject(ObjectList.getTag(tItem))
            tItem = Inventory.createRandomStartingStuff()
        end
        if not self.tInventory[tItem.sName] then
            self:pickUpItem(tItem)
        end
    end
end

-- bForceInHands: true forces into hands; false forces into backpack; nil uses default behavior from InventoryData.
function Character:pickUpItem(tItem, bForceInHands)
    assertdev(tItem)
    if not tItem then return end
    
	local sName = tItem.sName

	if self.tInventory[sName] == tItem then
        -- already got it.
    elseif self.tInventory[sName] then
        if Inventory.getMaxStacks(tItem) == 1 then
            Print(TT_Warning, "CHARACTER.LUA: Character attempted to pick up non-stackable item they already had: "..tItem.sName)
            ObjectList.removeObject(ObjectList.getTag(tItem))
            return sName
        end
        
		self.tInventory[sName].sName = sName
		self.tInventory[sName].nCount = self.tInventory[sName].nCount + tItem.nCount
	else
        -- If we actually like this item, let's reset the time (if any) we should wait before we try to trade.
        -- If we don't like it, leave the timer at whatever it was (built up by sitting on the floor for a while).
        -- Also, mark the last time something was picked up favorably, for record-keeping.
        local nAff = self:getObjectAffinity(tItem)
        if nAff > Character.STUFF_AFFINITY_DISCARD_THRESHOLD then        
            tItem.nTimeTradeDesired = nil
            tItem.bEligibleForIncinerate = nil
            tItem.nTimeUnwanted = nil
        end
        self.tInventory[sName] = tItem
	end
    self.tInventory[sName].tContainer = ObjectList.getTag(self)

    if bForceInHands or Inventory.heldOnly(tItem) then
        self:_addHeldItem(tItem)
    end
    
    -- NOTE: doesn't handle stacked objects, which is fine because Stuff doesn't stack.
    -- NOTE: leave outside the 'already got it' test above, because we use this on load to
    -- reconstruct the ownership table.
    if Inventory.isStuff(tItem) then
        self.tOwnedStuff[tItem.sName] = ObjectList.getTag(tItem)
        self.nOwnedStuff = DFUtil.tableSize(self.tOwnedStuff)
        Inventory.assignOwner(tItem,self)
    end

    return sName
end

function Character:getNumCarriedItems()
    return DFUtil.tableSize(self.tInventory)
end

-- rAskingChar is looking to attack self
function Character:_addAttackerOptions(rAskingChar,tUtilityOptions)
    -- disallow spacesuit fighting for now.
--    if self:spacewalking() or rAskingChar:spacewalking() then return end

    -- Add a fight task if in same room or if we know about nearby combat.
    local bCombat,nThreat,rThreat = rAskingChar:hasCombatAwarenessIn(self.rCurrentRoom)
    if bCombat and nThreat > Character.THREAT_LEVEL.NormalCitizen then
        local tData = {rVictim=self}
        if rAskingChar:getRoom() ~= self:getRoom() then
            -- If they're not in the same room, set rTargetObject so that the ActivityOption will verify
            -- we can reach the target.
            tData.rTargetObject = self
        end
        tData.utilityOverrideFn = function(rChar,rAO,nOriginalUtility)
            if self.tStatus.bCuffed or self:inPrison() or Malady.isIncapacitated(self) then
                return nOriginalUtility*.8
            end
            return nOriginalUtility
        end

        -- adding the "attack me" options.
        table.insert(tUtilityOptions, g_ActivityOption.new('AttackThreat', tData))
        -- kind of hacky: just a less appealing attack when there are no other options.
        table.insert(tUtilityOptions, g_ActivityOption.new('AttackThreatFallback', tData))

        --self:_addFleeOption('FleeThreat','PanicThreat',tUtilityOptions, true)
        rAskingChar:_addFleeOption('FleeThreat','PanicThreat',tUtilityOptions, true)

        tData = {rVictim=self}
        if rAskingChar:getRoom() ~= self:getRoom() then
            -- If they're not in the same room, set rTargetObject so that the ActivityOption will verify
            -- we can reach the target.
            tData.rTargetObject = self
        end
		tData.utilityGateFn=function(rChar, rThisActivityOption)
            if rChar:getAttackRange(self) > Character.MELEE_RANGE then
                return true
            end
            return false, 'melee weapon equipped '..rChar.tStats.sUniqueID..' '..(rChar.sDrawnWeapon or 'nil')
        end
        tData.nAttackType = Character.ATTACK_TYPE.Ranged
        table.insert(tUtilityOptions, g_ActivityOption.new('RangedAttackThreat', tData))
    end
    if nThreat == Character.THREAT_LEVEL.NormalCitizen and self:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen then
        local tData = {rVictim=self}
        if rAskingChar:getRoom() ~= self:getRoom() then
            -- If they're not in the same room, set rTargetObject so that the ActivityOption will verify
            -- we can reach the target.
            tData.rTargetObject = self
        end
        table.insert(tUtilityOptions, g_ActivityOption.new('Brawl', tData))
    end
end

function Character:onSimStart()
    self:_randomChanceInfect()
end

-- MTF TODO: this should be pulled into the new event system, and choose from a bunch of diseases, not just parasites.
function Character:_randomChanceInfect()
    if self.tStatus.bTriedToInfestWithParasite then return end
    self.tStatus.bTriedToInfestWithParasite = true

    if self.tStats.nRace ~= Character.RACE_MONSTER and not self.tStatus.bImmuneToParasite and not g_Config:getConfigValue('disable_hostiles') then
        local bInfect = math.random() < Character.INFESTATION_CHANCE
        if bInfect then
            self:diseaseInteraction(nil,Malady.createNewMaladyInstance('Parasite'))
        end
    end
end

function Character:_updateGatherers()
    self.tActivityOptionGatherers = {}

    local nTeam = self:getTeam()
    local nBehavior = Base.getTeamFactionBehavior(nTeam)
    if self.tStatus.tImprisonedIn then
        self.tActivityOptionGatherers.Characters=
        {
            gatherFn=UtilityAI.getNearbyCharacters,
        }
        self.tActivityOptionGatherers.RoomJobs=
        {
            gatherFn=Room.getRoomJobs,
        }
        self.tActivityOptionGatherers.EnvObjJobs=
        {
            gatherFn=EnvObject.getEnvObjectJobs,
        }
        self.tActivityOptionGatherers.GlobalObjects=
        {
            gatherFn=GlobalObjects.getGlobalUtilityObjects,
        }
    elseif self.tStats.nRace == Character.RACE_MONSTER then
        self.tActivityOptionGatherers.Characters=
        {
            gatherFn=UtilityAI.getNearbyCharacters,
        }
        self.tActivityOptionGatherers.GlobalMonsterActivities=
        {
            gatherFn=MonsterUtility.getGlobalMonsterUtilityObjects,
        }
    elseif nBehavior == Character.FACTION_BEHAVIOR.Citizen then
        self.tActivityOptionGatherers.Characters=
        {
            gatherFn=UtilityAI.getNearbyCharacters,
        }
        self.tActivityOptionGatherers.RoomJobs=
        {
            gatherFn=Room.getRoomJobs,
        }
        self.tActivityOptionGatherers.EnvObjJobs=
        {
            gatherFn=EnvObject.getEnvObjectJobs,
        }
        self.tActivityOptionGatherers.GlobalObjects=
        {
            gatherFn=GlobalObjects.getGlobalUtilityObjects,
        }
        self.tActivityOptionGatherers.CommandObject=
        {
            gatherFn=CommandObject.getActivityOptions,

        }
    elseif nBehavior == Character.FACTION_BEHAVIOR.EnemyGroup then
        self.tActivityOptionGatherers.RoomJobs=
        {
            gatherFn=Room.getRoomJobs,
        }
        self.tActivityOptionGatherers.Characters=
        {
            gatherFn=UtilityAI.getNearbyCharacters,
        }
		-- enemies only care about a subset of env object jobs, eg attacking
        self.tActivityOptionGatherers.EnvObjJobs=
        {
            gatherFn=EnvObject.getEnemyEnvObjectJobs,
        }
        self.tActivityOptionGatherers.GlobalRaiderActivities=
        {
            gatherFn=MonsterUtility.getGlobalRaiderUtilityObjects,
        }
        self.tActivityOptionGatherers.GlobalObjects=
        {
            gatherFn=GlobalObjects.getGlobalUtilityObjects,
        }
    elseif nBehavior == Character.FACTION_BEHAVIOR.Friendly then
        self.tActivityOptionGatherers.GlobalMonsterActivities=
        {
            gatherFn=MonsterUtility.getGlobalFriendlyUtilityObjects,
        }
        self.tActivityOptionGatherers.GlobalObjects=
        {
            gatherFn=GlobalObjects.getGlobalUtilityObjects,
        }
    end
end

function Character:_factionSetup(bLoading)
    local nTeam = self:getTeam()
    local nBehavior = Base.getTeamFactionBehavior(nTeam)
    self.nLastFactionBehavior = nBehavior
    if nBehavior ~= Character.FACTION_BEHAVIOR.Citizen then
        self.sCustomInspector = 'Hostile'
    end
    
    if self.tStats.nRace == Character.RACE_MONSTER then
        self.tStats.bIgnoreBreachThreats = true
        self.tStats.bIgnoreFire = true
		self.tStats.tPersonality.nBravery = 1 -- monsters are brave
        self.tStatus.nHitPoints = 2 * Character.STARTING_HIT_POINTS
        self.tStats.nMaxHitPoints = 2 * Character.STARTING_HIT_POINTS
        self.tStats.nToughness = (math.random()*.25) + .75 -- monsters are really tough
        self.tStatus.tAssignedToBrig = nil -- bugfix
        self.tStatus.tImprisonedIn = nil -- bugfix
        self.tStatus.bCuffed = nil -- bugfix
    elseif nBehavior == Character.FACTION_BEHAVIOR.Citizen then
        if self:getJob() == Character.RAIDER then
            self:setJob(Character.UNEMPLOYED,bLoading)
        end
    elseif nBehavior == Character.FACTION_BEHAVIOR.EnemyGroup then

        self.tStats.tPersonality.nBravery = (math.random() *.3) + .7 -- raiders are brave
        self.tStats.nToughness = (math.random() *.5) + 0.5 -- raiders are tougher than normal NOTE: may be overridden in equipment handout below

        self.tStats.nTimeToConvert = (1-self.tStats.tPersonality.nAuthoritarian) * 600

        -- Starting equipment for raider spawns.
        if self:getJob() == Character.RAIDER and self.tStats.nChallengeLevel then
            -- Just hard-coding this for now.
            -- Weapon options: Melee, Pistol, Laser Rifle, Plasma Rifle
            -- Armor options: ArmorLevel0,ArmorLevel1,ArmorLevel2,ArmorLevel3
            -- Toughness: 0,.4,.7,1
            -- Point buy!
            local tWeapons={'Melee','Pistol','LaserRifle','PlasmaRifle'}
            local tOptions={'weapon','armor','toughness'}
            local tAllocation={weapon=1,armor=1,toughness=1}
            local nPoints=math.min(9, math.floor(self.tStats.nChallengeLevel * 17 + .5))
            while nPoints > 0 do
                nPoints = nPoints-1
                local randIdx = math.random(1,#tOptions)
                local sCat = tOptions[randIdx]
                tAllocation[sCat] = tAllocation[sCat] + 1
                if tAllocation[sCat] >= 4 then
                    table.remove(tOptions, randIdx)
                end
            end

            if tWeapons[tAllocation['weapon']] ~= 'Melee' then
                self:pickUpItem(Inventory.createItem(tWeapons[tAllocation['weapon']]))
            end
            self:pickUpItem(Inventory.createItem('ArmorLevel'..(tAllocation['armor']-1)))
            self.tStats.nToughness = 0
            if tAllocation['toughness'] > 0 then self.tStats.nToughness = .1 + tAllocation['toughness']*.3 end

            self.tStats.nSpawnedWithChallenge = self.tStats.nChallengeLevel
            self.tStats.nChallengeLevel = nil -- so we don't add new equipment on load.
            -- Raiders are hella brave. Mostly so they'll punch fools to death even if they don't have a weapon.
            self.tStats.tPersonality.nBravery = .8+.2*math.random()
        elseif self:getJob() == Character.RAIDER then
            if not self.tStats.nSpawnedWithChallenge then
                Print(TT_Warning, 'CHARACTER.LUA: Spawning a raider without a challenge level.')
            end
        end
        
        if self.tStats.nRace == Character.RACE_KILLBOT then
            self.tStatus.nHitPoints = 2 * Character.STARTING_HIT_POINTS
            self.tStats.nMaxHitPoints = 2 * Character.STARTING_HIT_POINTS
            self.tStats.bIgnoreBreachThreats = true
            self.tStats.bIgnoreFire = true
        end

        if self.tStats.nTeam == 1 then
            Print(TT_Error, "CHARACTER.LUA: Attempt to spawn enemy on player's team. Hackily setting to team 2.")
            self.tStats.nTeam = 2
            self.tStats.nOriginalTeam = 2
        end

    elseif nBehavior == Character.FACTION_BEHAVIOR.Friendly then
        if self.tStats.nTeam == 1 then
            Print(TT_Error, "CHARACTER.LUA: Attempt to spawn enemy on player's team. Hackily setting to team 2.")
            self.tStats.nTeam = 2
            self.tStats.nOriginalTeam = 2
        end
    end

    self:_updateGatherers()
end

-- returns 0 to 1 of self's chance to dodge an attack
function Character:dodgeAttackChance(rAttacker, nAttackType)
    -- TODO, factor in attackers aim skill
    if nAttackType == Character.ATTACK_TYPE.Grapple then return 0 end
    local sArmorKey,tItem = self:_getArmor()
    if tItem then
        local _,nDodgeChance = Inventory.getArmorData(tItem)
        return nDodgeChance
    end
    if self.tStats.nRace == Character.RACE_MONSTER then
        return .3
    end

    return .1
end

-- returns 0 to 1, self's armor value
function Character:currentArmorValue()
    local sArmorKey,tItem = self:_getArmor()
    if tItem then return Inventory.getArmorData(tItem) end
    if self.tStats.nRace == Character.RACE_MONSTER then
        return 0.75
    end
    
    return 0
end

-- capped at 5. self not counted. hence returns 0-5.
function Character:_getTeamTacticsCount()
    if Base.hasCompletedResearch('TeamTactics') and self.tStats.nJob == Character.EMERGENCY and self:getTeam() == Character.TEAM_ID_PLAYER then
        if not self.nTeamTacticsCount or GameRules.elapsedTime - self.nTeamTacticsLastTest > 5 then
            self.nTeamTacticsLastTest = GameRules.elapsedTime
            local nCount=0
            local tSec = CharacterManager.tCharsByJob[Character.EMERGENCY]
            local tx,ty = self:getTileLoc()
            for rChar,_ in pairs(tSec) do
                if rChar ~= self and MiscUtil.isoDist(tx,ty, rChar:getTileLoc()) < 20 then
                    nCount=nCount+1
                end
            end
            self.nTeamTacticsCount = math.min(nCount,5)
        end
    else
        self.nTeamTacticsCount = nil
    end
    return self.nTeamTacticsCount or 0
end

-- returns 0 to max reduction, 50% normally or 75% with team tactics
function Character:currentDamageReductionValue()
    local toughness = self.tStats.nToughness or 0
    local armor = self:currentArmorValue()
    local currentResistance = toughness + armor

    return currentResistance / (currentResistance + 2) + self:_getTeamTacticsCount() * .05
end

function Character:_getCauseOfDeathFromDamageTable(tDamage)
    local eCOD = Character.CAUSE_OF_DEATH.UNSPECIFIED
    if not tDamage then return eCOD end
    
    if tDamage.nDamageType == Character.DAMAGE_TYPE.Fire then
        eCOD = Character.CAUSE_OF_DEATH.FIRE
    elseif tDamage.nAttackType == Character.ATTACK_TYPE.Grapple then
		eCOD = Character.CAUSE_OF_DEATH.COMBAT_MELEE
    elseif tDamage.nAttackType == Character.ATTACK_TYPE.Ranged then
		eCOD = Character.CAUSE_OF_DEATH.COMBAT_RANGED
    end

    return eCOD
end

--Quick and dirty function for infecting, without worrying about the details too much.
function Character:infestFromObject(rSource, sDiseaseName)
	--I am creating this for other maladies we might want to infect people with, like zombisim for example.
	if rSource and rSource.tStats then
		if rSource.tStats.sMaladyHolder then
		--Grab the disease if it exists, if not create a new strain
		self:diseaseInteraction(nil,Malady.getMalady(sDiseaseName,rSource.tStats.sMaladyHolder))
		end
	end
end

-- NOTE: rAttacker may be null, e.g. in cases of fire, and may not be a character
-- tDamage
-- nDamage = damage amount
-- nAttackType = CharacterConstants.ATTACK_TYPE
-- nDamageType = CharacterConstants.DAMAGE_TYPE
function Character:takeDamage(rAttacker, tDamage)
    if self:isDead() then return end
    -- Ensure values are set
    local nDamage = (tDamage and tDamage.nDamage) or 1
    local bKill = false

    self:storeMemory(Character.MEMORY_TOOK_DAMAGE_RECENTLY, true, Character.SELF_HEAL_COOLDOWN)

    local nDamageReduction = self:currentDamageReductionValue()
	--Infect it with "Thing" if Thing, even if the creature "misses"
	if rAttacker and  rAttacker.tStats then
		if rAttacker.tStats.nRace == Character.RACE_MONSTER and rAttacker.tStats.sName == "Thing" then
			self:infestFromObject(rAttacker, 'Thing')
		end
	end

    -- Ensure damage is always positive
    nDamage = math.max(nDamage * (1 - nDamageReduction), 0)
	-- debug cheat
	if self.bInvincible or (g_GameRules.bFriendliesInvincible and Base.isFriendlyToPlayer(self)) then
		nDamage = 0
		tDamage.nDamage = 0
		self.tStatus.nHitPoints = Character.STARTING_HIT_POINTS
	end
    
    if self.tStatus.nHitPoints then
        self.tStatus.nHitPoints = self.tStatus.nHitPoints - nDamage
        
        local  nInjury =  math.random()
        
        --Minor injuries, fairly common
       if nDamage > 1 and  nInjury > .25 then
       local tInjuries, num = Malady.getMinorInjuryFromList() 
           local sMalady = tInjuries[math.random(num)]
            if self:diseaseInteraction(nil,Malady.createNewMaladyInstance(sMalady)) then
                if self:retrieveMemory(Character.MEMORY_TOOK_DAMAGE_RECENTLY) then
                    -- log about being hurt :[
                    Log.add(Log.tTypes.HEALTH_CITIZEN_MINOR_INJURY, self)
                end
            end
        end
        
        local bIncapacitate = math.random() * 1.5 * Character.STARTING_HIT_POINTS < nDamage
       --Injuries, for incapacitated indivduals,
        if bIncapacitate then
       local tInjuries, num = Malady.getInjuryFromList() 
           local sMalady = tInjuries[math.random(num)]
            if self:diseaseInteraction(nil,Malady.createNewMaladyInstance(sMalady)) then
                if self:retrieveMemory(Character.MEMORY_TOOK_DAMAGE_RECENTLY) then
                    -- log about being incapacitated :[
                    Log.add(Log.tTypes.HEALTH_CITIZEN_INCAPACITATED_INJURY, self)
                end
            end
        end
        
        local bDestroyItem = math.random() < .5 * nDamage/Character.STARTING_HIT_POINTS
        if bDestroyItem then
            local sKey = MiscUtil.randomKey(self.tInventory)
            if sKey then 
                self:destroyItem(sKey)
            end
        end
        
    end
    if not self.tStatus.nHitPoints or self.tStatus.nHitPoints <= 0 then
        local bStunDamage = tDamage.nDamageType == Character.DAMAGE_TYPE.Stunner 
        -- cheat: if we're in nonlethal mode, melee is also an incapacitator.
        if self:isPlayersTeam() and g_ERBeacon:getViolence(self.squadName) == g_ERBeacon.VIOLENCE_NONLETHAL and tDamage.nDamageType == Character.DAMAGE_TYPE.Melee then
            bStunDamage = true
        end
		-- brawlers always do stun damage
        if rAttacker and ObjectList.getObjType(rAttacker) == ObjectList.CHARACTER then
		    if self:isBrawling(rAttacker) or rAttacker:isBrawling(self) then
			    bStunDamage = true
		    end
        end
		-- extra chance for melee to do stun damage
		if not bStunDamage and tDamage.nDamageType == Character.DAMAGE_TYPE.Melee then
			bStunDamage = math.random() < 0.5
		end
        if bStunDamage and self:diseaseInteraction(nil,Malady.createNewMaladyInstance('KnockedOut')) then
            self.tStatus.nHitPoints = 10
        else
            -- For stat tracking later, refund back the over-kill damage dealt
            if self.tStatus.nHitPoints and self.tStatus.nHitPoints < 0 then
                nDamage = nDamage - self.tStatus.nHitPoints
            end
            local nDeathCause = self:_getCauseOfDeathFromDamageTable(tDamage)
            CharacterManager.killCharacter(self, nDeathCause)
            bKill = true
        end
    end

    if tDamage and tDamage.nDamageType and tDamage.nDamageType ~= Character.DAMAGE_TYPE.Fire then --Doesn't play if its fire damage
        local ctx, cty = self:getLoc()
        if tDamage.nDamageType == Character.DAMAGE_TYPE.Laser then
            SoundManager.playSfx3D("takedamagelaser", ctx, cty)
        elseif tDamage.nDamageType == Character.DAMAGE_TYPE.Stunner then
            SoundManager.playSfx3D("takedamagetaser", ctx, cty)
        else
            SoundManager.playSfx3D("takedamagedefault", ctx, cty)
        end
    end

    if rAttacker and rAttacker.dealtDamage then rAttacker:dealtDamage(tDamage, bKill, self) end
    if rAttacker and self:isPlayersTeam() then 
        Base.eventOccurred(Base.EVENTS.CitizenAttacked, {rAttacker=rAttacker,rReporter=self})
    end
	--        Base.citizenAttacked({sAttacker=rAttacker:getUniqueID(),sAttacked=self:getUniqueID(),tDamage=tDamage,bKill=bKill}) end
	-- log "killed by turret/parasite/etc" stats while we still know attacker
	if rAttacker and bKill and not Base.isFriendlyToPlayer(self) then
		if rAttacker.sFunctionality and rAttacker.sFunctionality == 'Turret' then
			Base.incrementStat('nHostilesKilledByTurret')
		elseif rAttacker.tStats and rAttacker.tStats.nRace == Character.RACE_MONSTER and Base.isFriendlyToPlayer(rAttacker) then
			Base.incrementStat('nHostilesKilledByParasite')
		end
	end
end

-- Handles keeping of history for kills and total damage dealt
function Character:dealtDamage(tDamage, bKill, rTarget)
    -- Set Total Damage Dealt
    if tDamage.nDamage and tDamage.nDamage > 0 then self.tStats.tHistory.nTotalDamageDealt = (self.tStats.tHistory.nTotalDamageDealt or 0) + tDamage.nDamage end

    -- Set kills data
    if bKill then
        -- Set Total Kills
        self.tStats.tHistory.nTotalKills = (self.tStats.tHistory.nTotalKills or 0) + 1
        self:addJobExperience(Character.EMERGENCY, Character.XP_COMBAT_KILL)

        -- Track kills by name of Character killed
        if rTarget and rTarget.getNiceName then
            if not self.tStats.tHistory.tCharactersKilled then self.tStats.tHistory.tCharactersKilled  = {} end
            self.tStats.tHistory.tCharactersKilled[rTarget:getNiceName()] = (self.tStats.tHistory.tCharactersKilled[rTarget:getNiceName()] or 0) + 1
            --log kill
            local tLogData = {
                sThingKilled = rTarget:getNiceName()
            }
            if tDamage.nAttackType == 1 then --melee kill
                if self.tStats.nJob == Character.EMERGENCY then
                    Log.add(Log.tTypes.ER_KILLED_A_THING_MELEE, self, tLogData)
                elseif self.tStats.nJob == Character.RAIDER then
                    Log.add(Log.tTypes.RAIDER_KILLED_A_THING_MELEE, self, tLogData)
                else
                     Log.add(Log.tTypes.KILLED_A_THING_MELEE, self, tLogData)
                end
            else --ranged kill
                if self.tStats.nJob == Character.EMERGENCY then
                    Log.add(Log.tTypes.ER_KILLED_A_THING_RANGED, self, tLogData)
                elseif self.tStats.nJob == Character.RAIDER then
                    Log.add(Log.tTypes.RAIDER_KILLED_A_THING_RANGED, self, tLogData)
                else
                    Log.add(Log.tTypes.KILLED_A_THING_RANGED, self, tLogData)
                end
            end
        end
    else
        --TODO: log shoot target
        self:addJobExperience(Character.EMERGENCY, Character.XP_COMBAT_DAMAGE)
    end
end

function Character:getHP()
    return self.tStatus.nHitPoints or Character.STARTING_HIT_POINTS, self.tStats.nMaxHitPoints or Character.STARTING_HIT_POINTS
end

function Character:tickHealOverTime(dt)
    -- If the character remembers taking damage recently, don't tick healing
    if self:retrieveMemory(Character.MEMORY_TOOK_DAMAGE_RECENTLY) ~= nil then return end

    local nHP,nMaxHP = self:getHP()
    -- Can't auto heal out of Character.STATUS_HURT
    if self.tStatus.nHitPoints > Character.HURT_THRESHOLD then 
        nHP = nHP + (math.max(Character.HEAL_RATE, 0) * dt)
        self.tStatus.nHitPoints = math.min(nHP, nMaxHP)
    end
end

function Character:healHP(nHealHP)
    assertdev(nHealHP >= 0)
    if self:isDead() then return end

    local nHP,nMaxHP = self:getHP()
    self.tStatus.nHitPoints = math.min(nMaxHP, math.max(0,nHP+nHealHP))

    -- should never happen, but just in case.
    if self.tStatus.nHitPoints == 0 then
        CharacterManager.killCharacter(self)
    end
end

function Character:combatAlert(rRoom,rAttacker,tx,ty)
    if not rRoom or (rRoom and not rRoom.bDestroyed) and MiscUtil.isoDist(tx,ty, self:getTileLoc()) < Character.SIGHT_RADIUS then
        local id = (rRoom and rRoom.id) or -1
        self:storeMemory(Character.MEMORY_ROOM_COMBAT_PREFIX..id, true, 15)
    end
end

-- return: false, or true,nMaxThreatLevel,rHighestThreat
-- (where rHighestThreat may be a prop like a turret)
function Character:hasCombatAwarenessIn(rRoom)
    if rRoom and not rRoom.bDestroyed then 
        if self:retrieveMemory(Character.MEMORY_ROOM_COMBAT_PREFIX..rRoom.id) then
            -- HACK: test to see if the memory is up to date. This is because we don't have a task to go check out
            -- the room regardless, so we have to give characters a bit of telepathy.
            -- The correct solution is to rewrite the survival threat code so that it generates a list of
            -- high-pri tasks, and do away with the self.nThreat variable, so there isn't a bad decoupling between
            -- self.nThreat and our list of activityoptions.
            local nThreatLevel,rThreat = self:_lookForEnemies(rRoom, false, false)
            if nThreatLevel > 0 then
                return true,nThreatLevel,rThreat
            else
                self:clearMemory(Character.MEMORY_ROOM_COMBAT_PREFIX..rRoom.id)
            end
        end
    end
    return false
end

function Character:getMaladies()
    return self.tStatus.tMaladies
end

function Character:getIllnesses()
	-- returns subset of self.tStatus.tMaladies that are illnesses, ie not injuries
	local tIllnesses = {}
	local nIllnesses = 0
	for sID,tMalady in pairs(self.tStatus.tMaladies) do
		if not Malady.isInjury(sID) then
			tIllnesses[sID] = tMalady
			nIllnesses = nIllnesses + 1
		end
	end
	return tIllnesses, nIllnesses
end


function Character:getInjuries()
	local tInjuries = {}
	local nInjuries = 0
	for sID,tMalady in pairs(self.tStatus.tMaladies) do
		if Malady.isInjury(sID) then
			tInjuries[sID] = tMalady
			nInjuries = nInjuries + 1
		end
	end
	return tInjuries, nInjuries
end

-- return 0-1, where 0 is not sick and 1 is survival-level threat.
function Character:getPerceivedDiseaseSeverity(bIncludeHP)
    local nSev = 0
    if bIncludeHP then
        local nHP,nMaxHP = self:getHP()
        if nHP < Character.SCUFFED_UP_THRESHOLD then
            nSev = .8*math.max(0, math.min(1, nHP/nMaxHP))
        end
    end
    if not self.tStatus.tMaladies then
        return nSev
    end
    for sName,tMalady in pairs(self.tStatus.tMaladies) do
        if tMalady.bDiagnosed then
            if tMalady.nSeverity >= 1 then
                nSev = 1
                break
            else
                nSev = math.min(.95, nSev+tMalady.nSeverity)
            end
        elseif tMalady.bSymptomatic then
            local nTimeSick = GameRules.elapsedTime - tMalady.nSymptomStart
            local nPerceivedSeverity = tMalady.nPerceivedSeverity
            if nPerceivedSeverity >= 1 then
                nSev = 1
                break
            else
                nPerceivedSeverity = nPerceivedSeverity * math.min(2, nTimeSick * Malady.INV_TIME_TO_WORRY)
                nSev = math.min(.95, nSev+nPerceivedSeverity)
            end
        end
    end
	--for maladies that refuse doctors
    if self.tStats.bRefuseDoctor and self.tStats.bRefuseDoctor==true then
        nSev=0
        return nSev
    end
    return nSev
end

function Character:angerEvent(nAmt)
    -- remap morale to [2,.4]
    local nMoraleMult = 2-1.6*self.tStats.nMorale / 100
    nAmt = nAmt * nMoraleMult
    -- Instead of scaling by temper, use temper to randomize whether or not the event causes sharply reduced anger.
    -- Gives us spikier behavior which may be more fun.
    if math.random() > self.tStats.tPersonality.nTemper then
        nAmt = nAmt * .25
    end
    self.tStatus.nAnger = math.min(Character.ANGER_MAX, self.tStatus.nAnger + nAmt)        

    if self.tStatus.nAnger == Character.ANGER_MAX and not self:hasUtilityStatus(Character.STATUS_RAMPAGE) and not self:inPrison() and not self.tStatus.bCuffed then
        self:beginRampage((math.random() < Character.VIOLENT_RAMPAGE_CHANCE and Character.STATUS_RAMPAGE_VIOLENT) or Character.STATUS_RAMPAGE_NONVIOLENT)
    end
end

function Character:beginRampage(eStatusType)
    self.tStatus.nAnger = Character.ANGER_MAX
    local tLogType,tEventType
    local tLogData = {}
    if eStatusType == Character.STATUS_RAMPAGE_NONVIOLENT then
        if not self.tStatus.bRampageViolent then
            self.tStatus.bRampageNonviolent = true
        end
        Log.add(Log.tTypes.TANTRUM_START, self)
        -- log data for nearby citizens
        tLogType = Log.tTypes.TANTRUM_NEARBY
        tLogData.sSaboteur = self.tStats.sName
        tEventType = Base.EVENTS.CitizenTantrum
    elseif eStatusType == Character.STATUS_RAMPAGE_VIOLENT then
        self.tStatus.bRampageViolent = true
        self.tStatus.bRampageNonviolent = false
        Log.add(Log.tTypes.RAMPAGE_START, self)
        tLogType = Log.tTypes.RAMPAGE_NEARBY
        tLogData.sRampager = self.tStats.sName
        tEventType = Base.EVENTS.CitizenRampage
    else
        assertdev(false)
    end
    -- post alert
    local wx,wy = self:getLoc()
    local rRoom = self:getRoom()
    local tEventData = {
        sName = self.tStats.sName,
        sRoom = (rRoom and rRoom.uniqueZoneName) or '',
        rReporter=self,
    }
    Base.eventOccurred(tEventType, tEventData)
    -- everyone in this room and nearby rooms, log about rampage start
    if rRoom and rRoom ~= Room.rSpaceRoom then
        for rAdjoiningRoom,nAdjoining in pairs(rRoom.tAdjoining) do
            local tChars,nChars = rRoom:getCharactersInRoom()
            for rChar,_ in pairs(tChars) do
                if rChar ~= self and not rChar:_hates(self) then
                    Log.add(tLogType, rChar, tLogData)
                    -- also increase anger
                    -- JPL TODO: WTF? why does this cause everyone to freak out?
					-- diminishing returns if other anger events recently?
                    --rChar:angerEvent(Character.ANGER_NEARBY_RAMPAGE)
                end
            end
        end
    end
	if self.rCurrentTask and not self.rCurrentTask.bComplete then
		self.rCurrentTask:interrupt("rampage time")
	end
end            

function Character:endRampage()
    self.tStatus.bRampageViolent = false
    self.tStatus.bRampageNonviolent = false
    self.tStatus.bRampageObserved = false
end

function Character:angerReduction(nReductionAmt)
    if self.tStatus.bRampageViolent and not self:inPrison() then
        return
    end

    -- remap morale to [.7,1.3)
    local nMoraleMult = .7 + .6 * self.tStats.nMorale / 100
    self.tStatus.nAnger = math.max(0, self.tStatus.nAnger-nReductionAmt*nMoraleMult)
    if self.tStatus.nAnger == 0 and self:hasUtilityStatus(Character.STATUS_RAMPAGE) then
        self:endRampage()
    end
end

function Character:alterMorale(amount, reason)
	local logMorale = false
	local m = self.tStats.nMorale + amount
	-- keep in range
	m = math.min(math.max(m, Character.MORALE_MIN), Character.MORALE_MAX)
	self.tStats.nMorale = m
	if logMorale then
		Print(TT_Info,'CHARACTER.LUA: MORALE '..self.tStats.sUniqueID..': '..amount..' ('..reason..') boost:' .. math.abs(amount))
	end
    -- add to "recent morale events" log
    local timestamp = GameRules.sStarDate .. ':' .. GameRules.getStardateMinuteString()
    local t = {time=timestamp, amount=amount, reason=reason}
    table.insert(self.tStats.tHistory.tMoraleEvents, t)
    -- if list gets too big, remove oldest item
    if #self.tStats.tHistory.tMoraleEvents > Character.MORALE_EVENTS_LOG_MAX then
        table.remove(self.tStats.tHistory.tMoraleEvents, 1)
    end
end

function Character:logTask(tTaskData)
	table.insert(self.tStats.tHistory.tTaskLog, tTaskData)
    -- if list gets too big, remove oldest item
    if #self.tStats.tHistory.tTaskLog > Character.TASK_LOGS_MAX then
        table.remove(self.tStats.tHistory.tTaskLog, 1)
    end
end

function Character:tickRoomMorale()
	-- sample room morale periodically
	local nRoomMorale = 0
	if self.rCurrentRoom and self.rCurrentRoom ~= Room.getSpaceRoom() then
		nRoomMorale = self.rCurrentRoom.nMoraleScore
	end
	table.insert(self.tStats.tHistory.tRoomScores, nRoomMorale)
	if #self.tStats.tHistory.tRoomScores > Character.ROOM_MORALE_SAMPLES then
		table.remove(self.tStats.tHistory.tRoomScores, 1)
    end
end

function Character:getAverageRoomMorale()
	local nAverageScore = 0
	for _,nScore in pairs(self.tStats.tHistory.tRoomScores) do
		nAverageScore = nAverageScore + nScore
	end
	return nAverageScore / Character.ROOM_MORALE_SAMPLES
end

function Character:canUseDresser(rDresser)
    -- if the dresser already has stuff, we have an easy answer.
    local rDisplayingChar = rDresser:getDisplayingChar()
    if rDisplayingChar == self then return true end
    if rDisplayingChar and rDisplayingChar ~= self then return false end

    local rRoom = rDresser:getRoom()
    if not rRoom then return false end
    local rZone = rRoom:getZoneObj()

    local tProps = rRoom.tProps
    for rEnvObject,_ in pairs(tProps) do
        if rEnvObject ~= rDresser then
            if rEnvObject:numOpenDisplaySlots() > 0 then
                rDisplayingChar = rEnvObject:getDisplayingChar()
                if rDisplayingChar == self then
                    return false
                end
            end
        end
    end

	if rRoom:getZoneName() == 'RESIDENCE' then
        local rBed = Base.tCharToBed[ObjectList.getTag(self)]
        rBed = rBed and ObjectList.getObject(rBed)
        if rBed then
            if rBed:getRoom() ~= rRoom then return false end
        else
            local rLastBed = self:retrieveMemory(Character.MEMORY_LAST_BED)
            rLastBed = rLastBed and ObjectList.getObject(rLastBed)
            if rLastBed and rLastBed:getRoom() ~= rRoom then return false end
            tProps = rRoom:getPropsOfName('Bed')
            for rProp,_ in pairs(tProps) do
                if not Base.tCharToBed[ObjectList.getTag(rProp)] then
                    return true
                end
            end
        end
    else
        local nAff = self:getRoomAffinity(rRoom)
        if nAff <= 0 then return false end
        if self:getJob() ~= rZone:getAssociatedJob() then return false end
        return true
    end
end

function Character:tickMorale()
    if self:inPrison() then
        self:angerReduction(Character.ANGER_REDUCTION_PER_MORALE_TICK_BRIG)
    elseif not Malady.isIncapacitated(self) then
        self:angerReduction(Character.ANGER_REDUCTION_PER_MORALE_TICK)
    end
	-- hostiles don't bother with morale (dehumanizing the enemy, eh?)
	if self:isHostileToPlayer() then
		return
	end
	-- don't tick morale while asleep
	if self.rCurrentTask then
		if (self.rCurrentTask.activityName == 'SleepInBed' and self.rCurrentTask.bSnoozing) or self.rCurrentTask.activityName == 'SleepOnFloor' then
			return
		end
	end
    -- don't tick morale or log about stuff while rampaging
    if self.tStatus.bRampageViolent or self.tStatus.bRampageNonviolent then
        return
	end
	-- if average needs are exceptionally high/low, increase/decrease morale
	local bAllNeedsMet = true
	local sLowestNeed, sHighestNeed
	local nLowestNeedVal, nHighestNeedVal = 0, 0
	local nAvg = 0
	for sNeedName,_ in pairs(Needs.tNeedList) do
		local nValue = self.tNeeds[sNeedName]
		nAvg = nAvg + nValue
		-- determine our highest and lowest needs
		if nValue < Character.MORALE_NEEDS_LOW and nValue < nLowestNeedVal then
			sLowestNeed = sNeedName
			nLowestNeedVal = nValue
			bAllNeedsMet = false
		elseif nValue > Character.MORALE_NEEDS_HIGH and nValue > nHighestNeedVal then
			sHighestNeed = sNeedName
			nHighestNeedVal = nValue
		end
	end
	nAvg = nAvg / DFUtil.tableSize(Needs.tNeedList)
	if nAvg < Character.MORALE_NEEDS_LOW then
		self:alterMorale(Character.MORALE_NEEDS_DECREASE, 'Low'..sLowestNeed)
	elseif nAvg > Character.MORALE_NEEDS_HIGH then
		self:alterMorale(Character.MORALE_NEEDS_INCREASE, 'High'..sHighestNeed)
	end
	-- store average for debug info, etc
	self.tStats.nAllNeedsAverage = nAvg
	-- after morale but before logging, bail if incapacitated
    if Malady.isIncapacitated(self) then
		return
	end
	-- log if we have a notably low or high need, but only the most extreme
	-- need and prefer low (things are bad) to high (things are good)
	local bLogged = false
	if (sLowestNeed or sHighestNeed) and not self:retrieveMemory(Character.MEMORY_LOGGED_MORALE_RECENTLY) then
		if sLowestNeed then
			Log.add(Needs.tNeedList[sLowestNeed].tLowMoraleLogType, self)
			bLogged = true
		elseif sHighestNeed then
			Log.add(Needs.tNeedList[sHighestNeed].tHighMoraleLogType, self)
			bLogged = true
		end
		-- only log once in a while
		if bLogged then
			self:storeMemory(Character.MEMORY_LOGGED_MORALE_RECENTLY, true, Character.LOG_MORALE_NEEDS_RATE)
		end
	end
	-- low oxygen is uncomfortable
	if not GameRules.bProhibitSuffocation and self.rSpacesuitRig and not self.rSpacesuitRig:isActive() and self.nAverageOxygen < Character.MORALE_LOW_OXYGEN_THRESHOLD then
		self:alterMorale(Character.MORALE_LOW_OXYGEN, 'LowOxygen')
		-- skip "room morale" check, low oxygen is no fun
		return
	-- if our needs our met but we're still bummed, be a little less bummed
	elseif bAllNeedsMet and self.tStats.nMorale < 0 then
		self:alterMorale(Character.MORALE_NEEDS_MET_BONUS, 'NeedsMet')
	end
    -- log about low stuff need?
    local nStuffNeed = self:getStuffSatisfaction()
    if nStuffNeed < Character.NEEDS_STUFF_LOW and not self:retrieveMemory(Character.MEMORY_STUFF_NEED) and math.random() < self.tStats.tPersonality.nChattiness then
        self:storeMemory(Character.MEMORY_STUFF_NEED, true, Character.STUFF_NEED_LOG_FREQUENCY)
        Log.add(Log.tTypes.MORALE_LOW_STUFF, self)
    end
	-- if we didn't log something about needs, maybe do a random generic log
	if not bLogged and math.random() < self.tStats.tPersonality.nChattiness and not self:retrieveMemory(Character.MEMORY_GENERIC_LOG) then
		-- chance of generic log vs char-in-room log vs object-in-room log
		local rOther,nOtherAff = self:getInterestingCharacterInRoom()
		local rObject = self:getInterestingObjectInRoom()
		local nRoll = math.random()
		local tLogData = {}
		local tLogType = Log.tTypes.GENERIC
		-- 10% chance: comment on shelving need or object in room
		if nRoll > 0.9 and rObject then
			-- not enough shelving? log about it
			if self:getNumOwnedStuff() > 0 and Base.freeShelving() < 0 then
				tLogType = Log.tTypes.NEED_SHELVING
			-- otherwise just talk about a nearby object
			else
				tLogData.sObject = rObject.sFriendlyName
				-- (no envobject affinities; anger tag handles like/dislike)
				tLogType = Log.tTypes.NEARBY_OBJECT
			end
		-- 40% chance: comment on person in room
		elseif nRoll > 0.5 and rOther then
			tLogData.sCharacter = rOther.tStats.sName
			if nOtherAff >= 0 then
				tLogType = Log.tTypes.LIKE_NEARBY_PERSON
			else
				tLogType = Log.tTypes.DISLIKE_NEARBY_PERSON
			end
		end
		-- (50% chance: generic thought/observation log)
		Log.add(tLogType, self, tLogData)
		self:storeMemory(Character.MEMORY_GENERIC_LOG, true, Character.GENERIC_LOG_FREQUENCY)
	end
	-- affinity for current duty influences morale
	-- in addition to onDuty, check if current task is tagged with our duty
    local bDutyTask = false
    if self.rCurrentTask then
        local rAO = self.rCurrentTask.rActivityOption
        if rAO and rAO.tBaseTags and rAO.tBaseTags.Job and rAO.tBaseTags.Job == self.tStats.nJob then
            bDutyTask = true
        end
    end
	if self:onDuty() or bDutyTask then
		local nAff = self:getJobAffinity(self.tStats.nJob)
		-- normalize for lerp
		nAff = nAff * Character.MAX_AFFINITY_INVERSE
		local nJobSatisfaction = DFMath.lerp(-Character.DUTY_AFFINITY_MORALE_MAX, Character.DUTY_AFFINITY_MORALE_MAX, nAff)
		self:alterMorale(nJobSatisfaction, 'JobAffinity')

	end
	-- room morale score = average room score
	local nAverageScore = self:getAverageRoomMorale()
	-- normalize and lerp for resulting morale change
	nAverageScore = nAverageScore / Character.MAX_ROOM_MORALE_SCORE
	local nRoomMoraleBonus = nAverageScore * Character.MAX_ROOM_MORALE_BOOST

    -- MTF TEMP: quick and dirty way to start generating room affinities.
    -- Need to be careful not to feed this back into morale!
    if nRoomMoraleBonus > 0 then
        self:addRoomAffinity(Character.AFFINITY_CHANGE_MINOR)
    elseif nRoomMoraleBonus < 0 then
        self:addRoomAffinity(-Character.AFFINITY_CHANGE_MINOR)
    end

	-- diminishing returns for room bonus if morale is high enough
	local nMin, nMax = Character.ROOM_MORALE_FALLOFF_START, Character.ROOM_MORALE_FALLOFF_END
	if self.tStats.nMorale > nMax then
		nRoomMoraleBonus = 0
	elseif self.tStats.nMorale > nMin then
		-- at min get full bonus as calculated, at max get zero
		local nNormalizedMoraleInRange = (self.tStats.nMorale - nMin) / (nMax - nMin)
		nRoomMoraleBonus = DFMath.lerp(nRoomMoraleBonus, 0, nNormalizedMoraleInRange)
	end
	if nRoomMoraleBonus ~= 0 then
		self:alterMorale(nRoomMoraleBonus, 'RoomMorale')
	end
	-- log if the room we're in is really awesome
	if not bLogged and self.rCurrentRoom and self.rCurrentRoom ~= Room.getSpaceRoom() and nAverageScore > Character.ROOM_MORALE_LOG_THRESHOLD then
        -- if this is your duty room and you're on duty, less likely to log
		if self.rCurrentRoom:getZoneName() == 'PUB' then
            -- if we're on duty in the room where we do duty, less likely to log
            if not (self:inDutyRoom() and math.random() > 0.25) then
                Log.add(Log.tTypes.MORALE_COOL_PUB, self)
            end
		elseif self.rCurrentRoom:getZoneName() == 'GARDEN' then
            if not (self:inDutyRoom() and math.random() > 0.25) then
                Log.add(Log.tTypes.MORALE_COOL_GARDEN, self)
            end
		else
			Log.add(Log.tTypes.MORALE_COOL_ROOM_GENERIC, self)
		end
	end
end

function Character:getInterestingObjectInRoom(rRoom)
	if not rRoom and self.rCurrentRoom ~= Room.getSpaceRoom() then
		rRoom = self.rCurrentRoom
	end
	if not rRoom or rRoom.nProps == 0 then
		return
	end
	local rPick = MiscUtil.randomKey(rRoom.tProps)
	assert(rPick ~= nil)
	return rPick
end

function Character:getInterestingCharacterInRoom(rRoom)
	if not rRoom and self.rCurrentRoom ~= Room.getSpaceRoom() then
		rRoom = self.rCurrentRoom
	end
	if not rRoom then
		return
	end
	local tChars,nChars = rRoom:getCharactersInRoom()
	-- bail if we're the only person in the room
	if nChars == 1 then
		return
	end
	-- create copy of tChars with weight values
	local tPicks = {}
	for rChar,_ in pairs(tChars) do
		-- exclude self from selection
		if rChar ~= self then
			-- random weight = affinity * familiarity (someone you love or hate)
			local nAff = self:getAffinity(rChar.tStats.sUniqueID)
			-- familiarity counts less than affinity
			local nFam = self:getFamiliarity(rChar.tStats.sUniqueID) * 0.5
			tPicks[rChar] = math.abs(nAff * nFam)
		end
	end
	-- return character and our affinity for them
	local rPick = MiscUtil.weightedRandom(tPicks)
	return rPick, self:getAffinity(rPick.tStats.sUniqueID)
end

function Character:inDutyRoom()
    -- returns true if we're on duty in a room appropriate to that duty
    if not self:onDuty() then
        return false
    end
    local sZone = self.rCurrentRoom:getZoneName()
    if sZone == 'GARDEN' and self.tStats.nJob == Character.BOTANIST then
        return true
    elseif sZone == 'PUB' and self.tStats.nJob == Character.BARTENDER then
        return true
    elseif sZone == 'RESEARCH' and self.tStats.nJob == Character.SCIENTIST then
        return true
    elseif sZone == 'INFIRMARY' and self.tStats.nJob == Character.DOCTOR then
        return true
    else
        return false
    end
end

function Character:tickGraph()
    -- update running list with current values for DebugInfoPane graph drawing
    for needName,_ in pairs(Needs.tNeedList) do
        table.insert(self.tStats.tHistory.tGraphItems[needName], self.tNeeds[needName])
        -- remove from beginning of list if it's full
        if #self.tStats.tHistory.tGraphItems[needName] > Character.GRAPH_MAX_ENTRIES then
            table.remove(self.tStats.tHistory.tGraphItems[needName], 1)
        end
    end
    -- track morale as we do needs
    table.insert(self.tStats.tHistory.tGraphItems.Morale, self.tStats.nMorale)
    if #self.tStats.tHistory.tGraphItems.Morale > Character.GRAPH_MAX_ENTRIES then
        table.remove(self.tStats.tHistory.tGraphItems.Morale, 1)
    end
	-- duty xp too
	if not self.tStats.tJobExperience[self.tStats.nJob] then
		return
	end
	local xp = self.tStats.tJobExperience[self.tStats.nJob] % Character.EXPERIENCE_PER_LEVEL
    table.insert(self.tStats.tHistory.tGraphItems.XP, xp)
    if #self.tStats.tHistory.tGraphItems.XP > Character.GRAPH_MAX_ENTRIES then
        table.remove(self.tStats.tHistory.tGraphItems.XP, 1)
    end
	-- also "stuff need"
	local nStuffNeed = self:getStuffSatisfaction()
	table.insert(self.tStats.tHistory.tGraphItems.Stuff, nStuffNeed)
    if #self.tStats.tHistory.tGraphItems.Stuff > Character.GRAPH_MAX_ENTRIES then
        table.remove(self.tStats.tHistory.tGraphItems.Stuff, 1)
    end
end

function Character:getMoraleCompetencyModifier()
    if self.tStats.nMorale > Character.MORALE_COMPETENCY_THRESHOLD then return 1 + Character.MORALE_COMPETENCY_MODIFIER
    elseif self.tStats.nMorale < -Character.MORALE_COMPETENCY_THRESHOLD then return 1 - Character.MORALE_COMPETENCY_MODIFIER
    else return 1 end
end

function Character:isHealthy()
    local sStatus = self:getHealth()
    return sStatus == Character.STATUS_HEALTHY or sStatus == Character.STATUS_SCUFFED_UP
end

function Character:getHealth()
    if self:isDead() then
        return Character.STATUS_DEAD
    end
    if Malady.isIncapacitated(self) then
        return Character.STATUS_INCAPACITATED
    end
    local hp = self:getHP()
    if hp < Character.HURT_THRESHOLD then
        return Character.STATUS_HURT 
    end
    if hp < Character.SCUFFED_UP_THRESHOLD then
        return Character.STATUS_SCUFFED_UP
    end
    
    if self.tStats.nRace ~= Character.RACE_KILLBOT then
        if self:getHasMaladyOfTier(0) then
            return Character.STATUS_INJURED
        end
    end
    
    if self:getPerceivedDiseaseSeverity() > .1 and self.tStats.nRace ~= Character.RACE_MONSTER then
        if self.tStats.bHideSigns and self.tStats.bHideSigns==true then
        return Character.STATUS_HEALTHY
        else
        return Character.STATUS_ILL
		end
    end
    
    return Character.STATUS_HEALTHY
end

function Character:getMorale()
    if self.tStats then
        return self.tStats.nMorale
    end
    return Character.MORALE_MAX
end

function Character:getMoraleText()
    local nMorale = self:getMorale()
    local sString = ""
    if self:isDead() or self:isHostileToPlayer() then
        sString = g_LM.line("INSPEC079TEXT")
    else
        for i, tTextInfo in ipairs(Character.MORALE_UI_TEXT) do
            if nMorale >= tTextInfo.nMinMorale then
                sString = g_LM.line(tTextInfo.linecode)
            end
        end
		-- show anger if applicable
		if self.tStatus.nAnger > 0 then
			local sLC
			for i, tTextInfo in ipairs(Character.ANGER_UI_TEXT) do
				if self.tStatus.nAnger >= tTextInfo.nMinAnger then
					sLC = tTextInfo.linecode
				end
			end
			assert(sLC ~= nil)
			sString = sString .. ', ' .. g_LM.line(sLC)
		end
		-- rampaging / tantruming? show that instead of either
		if self.tStatus.bRampageViolent then
			sString = g_LM.line('INSPEC189TEXT')
		elseif self.tStatus.bRampageNonviolent then
			sString = g_LM.line('INSPEC190TEXT')
		end
    end
    return sString
end

function Character:getCurrentTask()
    return self.rCurrentTask
end

function Character:starving()
    return self.tNeeds['Hunger'] < Character.NEEDS_HUNGER_STARVATION
end

function Character:getVelocity()
    local rCurrentTask = self:getCurrentTask()
    local tPath = rCurrentTask and rCurrentTask.tPath
    if tPath then return tPath:getVelocity() end
    return 0,0,0
end

function Character:getAdjustedSpeed()
    if self.rCurrentRig.tCurrentAnimationData and self.rCurrentRig.tCurrentAnimationData.bUseRunSpeed then
    --if self:isPlayingAnim('run') then
        return self.tStats.runSpeed * self.tStats.nspeed
    end
	
    local nMoraleMod = 1
    if self.tStats.nMorale > Character.MORALE_SPEED_THRESHOLD then
		nMoraleMod = 1 + Character.MORALE_HIGH_SPEED_MODIFIER
    elseif self.tStats.nMorale < -Character.MORALE_SPEED_THRESHOLD then
		nMoraleMod = 1 + Character.MORALE_LOW_SPEED_MODIFIER
	end
	local speed = self.tStats.speed * nMoraleMod * self.tStats.nspeed

    return speed
end

------------------------------------------------
-- MALADIES
------------------------------------------------

function Character:getHasMaladyOfTier(nTier)
--Linear checks for tier
	bInfected=false
	local tIllList, nNum = self:getIllnesses()
	for i, tStrainData in pairs (tIllList) do
          if  tStrainData.nDifficultyTier == nTier then
			bInfected=true
          end
	end
	return bInfected
end

function Character:spawnThing()

    if self:wearingSpacesuit() then
        --Print(TT_Info,"Tried to spawn Monster in spacesuit, not gonna happen.")
        return false
    end
    if g_Config:getConfigValue('disable_hostiles')  or not self then
        return false
    end
	--Loop through the illness list to find a specific malady type
	local tIllList, nNum = self:getIllnesses()
	sMName = ''
	for i, tStrainData in pairs (tIllList) do
          if tStrainData.sMaladyType == 'Thing' then
			sMName = tStrainData.sMaladyName
          end
	end
	if sMName == '' then 
	--if it cant find it default it so that "Malady.getMalady will create  a new one
	sMName = 'Thing'
	end
    local nwx,nwy = self:getLoc()
	--Lua tables are dictionaries as-well, so this is legal
    local tData = { tStats={ sMaladyHolder = sMName, nRace = Character.RACE_MONSTER, sName = 'Thing' } }
    CharacterManager.addNewCharacter(nwx,nwy,tData,Character.TEAM_ID_DEBUG_ENEMYGROUP)
    if not self:isDead() then
    local tLogData = {}
		--Kill and delete for "things".
		Log.add(Log.tTypes.DEATH_THING, self, tLogData)
		CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.THING)
    end
    CharacterManager.deleteCharacter(self)

    return true
end

function Character:spawnMonster()

    if self:wearingSpacesuit() then
        --Print(TT_Info,"Tried to spawn Monster in spacesuit, not gonna happen.")
        return false
    end
    if self:isDead() then
        --Print(TT_Info,"Can't spawn a monster out of a dead citizen.")
        return false
    end
    if g_Config:getConfigValue('disable_hostiles') then
        return false
    end
    CharacterManager.killCharacter(self, Character.CAUSE_OF_DEATH.PARASITE)
    local nwx,nwy = self:getLoc()
    local tData = { tStats={ nRace = Character.RACE_MONSTER, sName = 'Parasite' } }
    CharacterManager.addNewCharacter(nwx,nwy,tData,Character.TEAM_ID_DEBUG_ENEMYGROUP)

    local tLogData = {}
    Log.add(Log.tTypes.DEATH_CHESTBURST, self, tLogData)

    return true

end

function Character:isImmuneTo(tMalady)
    if self.tStats.tImmunities[tMalady.sMaladyName] == nil then
        self.tStats.tImmunities[tMalady.sMaladyName] = math.random() < tMalady.nImmuneChance 
    end
    if self.tStats.tImmunities[tMalady.sMaladyName] then
        return true
    end
    -- disallowing infection with multiple strains of the same disease.
    for sMaladyName,tMaladyData in pairs(self.tStatus.tMaladies) do
        if tMaladyData.sMaladyType == tMalady.sMaladyType then
            return true
        end
    end
end

-- infects the character.
function Character:diseaseInteraction(rSource,tMalady)
	--It seems rSource is unused in this right now consider removing...
    -- no diseases for robots
	if self.tStats.nRace == Character.RACE_KILLBOT then return false end

    if not self.tStatus.tMaladies then self.tStatus.tMaladies = {} end
    -- We ignore maladies we already have.
    if not self.tStatus.tMaladies[tMalady.sMaladyName] then
        self.tStatus.tMaladies[tMalady.sMaladyName] = Malady.reproduceMalady(tMalady)
        -- one tick to get instant-symptom maladies active before we do more tests below.
        Malady._tickMalady(self,self.tStatus.tMaladies[tMalady.sMaladyName])
    end
    if Malady.shouldInterruptCurrentTask(self) then
	    if self.rCurrentTask and not self.rCurrentTask.bComplete then
            self:_clearPendingTask()
		    self.rCurrentTask:interrupt("malady")
	    end
    end
    return true
end

function Character:cure(sName)
    if self.tStatus.tMaladies[sName] then
        local tMalady = self.tStatus.tMaladies[sName]
        self.tStatus.tMaladies[sName] = nil
        --set speed multiplier to 1 immediately if the person has another disease that mods it it will appear next tick
        self.tStats.nspeed=1
        self.tStats.bRefuseDoctor=false
        self.tStats.bHideSigns =false
    end
    self.tStats.tImmunities[sName] = GameRules.elapsedTime
    
end

function Character:DBG_cureAllMaladies()
	for sName,tMalady in pairs(self.tStatus.tMaladies) do
		self:cure(sName)
	end
end

------------------------------------------------------
-- SPECIFIC TASKS
------------------------------------------------------

function _getOpenAdjacentTile(tx,ty,rRoom)
	if not rRoom then return end
	for i=2,9 do
		local bx,by = World._getAdjacentTile(tx, ty, i)
		if Room.getRoomAtTile(bx,by,1,false) == rRoom and World._isPathable(bx,by) and not ObjectList.getReservationAt(bx,by) then
			return bx,by
		end
	end
end

function Character:_coopTaskLocationCallback(rPartner,rAO)
    local bIncapacitatedSelf = Malady.isIncapacitated(self)
    local bIncapacitatedPartner = Malady.isIncapacitated(rPartner)
    if bIncapacitatedSelf and bIncapacitatedPartner then return false end

    local tx,ty,t2x,t2y
    local rRoom
    if bIncapacitatedSelf then
        rRoom = self:getRoom()
        tx,ty = self:getTileLoc()
        t2x,t2y = _getOpenAdjacentTile(tx,ty,rRoom)
    elseif bIncapacitatedPartner then
        rRoom = rPartner:getRoom()
        t2x,t2y = self:getTileLoc()
        tx,ty = _getOpenAdjacentTile(t2x,t2y,rRoom)
    else
        local tRooms = {}
        if rAO.tData.rTargetRoom then table.insert(tRooms,rAO.tData.rTargetRoom) end
        if self:getRoom() then table.insert(tRooms,self:getRoom()) end
        if rPartner:getRoom() then table.insert(tRooms,rPartner:getRoom()) end
        for i=1,#tRooms do
            rRoom = tRooms[i]
	        if not rRoom:isDangerous() and not rRoom.bDestroyed and rRoom ~= Room.getSpaceRoom() then
                tx,ty,t2x,t2y = rRoom:getPathableTilePairs()
            end
            if tx and t2x then
                break
            end
        end
    end

    if not (tx and t2x) then return end

	rAO.tData.pathX,rAO.tData.pathY = g_World._getWorldFromTile(tx,ty)
	rAO.tData.partnerX,rAO.tData.partnerY = g_World._getWorldFromTile(t2x,t2y)

	return rAO.tData.pathX,rAO.tData.pathY
end

function Character:_chatGate(rChar, rThisActivityOption)
	if self:spacewalking() or rChar:spacewalking() then return false, 'spacewalking' end
    if Malady.isIncapacitated(self) then return false, 'incapacitated' end

	-- pub chat related gates
	if rThisActivityOption.tData.pathX then
		local rRoom = Room.getRoomAt(rThisActivityOption.tData.pathX, rThisActivityOption.tData.pathY,rThisActivityOption.tData.pathLevel or 1)
		if rRoom and rRoom:getZoneName() == 'PUB' then
			if rRoom.zoneObj:atCapacity() then
				return false, 'pub at capacity'
			end
		end
	end

	local lastPartner = self.tMemory.tTaskChat.sPartnerID and CharacterManager.getCharacterByUniqueID(self.tMemory.tTaskChat.sPartnerID)
	if not lastPartner then return true end

	local partnersLast = CharacterManager.getCharacterByUniqueID(lastPartner.tMemory.tTaskChat.sPartnerID)
	if not partnersLast then return true end

	if rChar == lastPartner and self == partnersLast and GameRules.elapsedTime - self.tMemory.tTaskChat.lastTime < Character.CHAT_COOLDOWN then
		return false, 'just chatted with same citizen'
	end
	return true
end

function Character:_chatUtilityOverride(rActivityOption, nScore)
	-- NOTE: this is for a DIFFERENT character evaluating whether to Chat with this character.
	-- (This character has advertised the Chat task as an option.)
	-- That's why we can't rely on standard WorkShift utility mods in ActivityOption
	-- to handle this case, and have to do it here.
	if self:wantsWorkShiftTask() then
		return nScore * .5
	end

    -- pub chat
	if rActivityOption.tData.rTargetRoom then
		return nScore * 1.1
	end
	return nScore
end

------------------------------------------------
-- UI
------------------------------------------------
function Character:getActivityText()
    if self:isDead() then
        return self:getDeathText()
	end
    local rCurrentTask = self:getCurrentTask()
	if not rCurrentTask then
		return ''
	end
	local sString = rCurrentTask:getActivityFriendlyName()
	local tTaskData = OptionData.tAdvertisedActivities[rCurrentTask.activityName]
	if tTaskData.bShowDuration then
		sString = sString..' ('..MiscUtil.formatTime(rCurrentTask:estimatedTimeRemaining())..')'
	end
    return sString
end

function Character:getDeathText()
    if not self.tStats.sDeathLine then

        --local tDeathLines = {"UITASK041TEXT","UITASK042TEXT","UITASK043TEXT","UITASK044TEXT","UITASK045TEXT","UITASK046TEXT","UITASK047TEXT","UITASK048TEXT","UITASK049TEXT","UITASK050TEXT","UITASK051TEXT", }
        self.tStats.sDeathLine = 'N/A' --g_LM.line(DFUtil.arrayRandom(tDeathLines))
    end
    return self.tStats.sDeathLine
end

function Character:getToolTipOxygenText()
    local s = ""
    if self.tStatus and self.tStatus.bSpacewalking and not self:isDead() then
        local sOxygenLabel = g_LM.line('INSPEC059TEXT')
        local nOxygenSeconds = self:getSuitOxygenSeconds()
        local nOxygenPct = self:getSuitOxygenPct()
        s = string.format('%s %s (%i%%)', sOxygenLabel, MiscUtil.formatTime(nOxygenSeconds), nOxygenPct)
    end
    return s
end

function Character:getHealthText(bIncludeOxygen)
	-- used for inspector and tooltips
	local bIsRobot = self.tStats.nRace == Character.RACE_KILLBOT
	local status_line = Character.HEALTH_STATUS_LINE
	-- special health status lines for robots
	if bIsRobot then
		status_line = Character.ROBOT_HEALTH_STATUS_LINE
	end
	local s = g_LM.line(status_line[self:getHealth()])
	if bIsRobot then
		return s
	end
	-- oxygen if spacewalking
	if self.tStatus.bSpacewalking and bIncludeOxygen then
		-- show suit oxygen remaining, eg "Healthy (Oxygen Left: 1:45)"
		local sOxygenLabel = g_LM.line('INSPEC059TEXT')
		local nOxygenSeconds = self:getSuitOxygenSeconds()
		local nOxygenPct = self:getSuitOxygenPct()
		--s = string.format('%s - %s %i%% (%s)', s, sOxygenLabel, nOxygenPct, MiscUtil.formatTime(nOxygenSeconds))
		--s = string.format('%s (%s %i%%)', s, sOxygenLabel, nOxygenPct)
		s = string.format('%s (%s %s)', s, sOxygenLabel, MiscUtil.formatTime(nOxygenSeconds))
	end
	if self:starving() then
		local sStarvingLC = 'INSPEC088TEXT'
		-- if unhurt but starving, health is "starving"
		if self:getHealth() == Character.STATUS_HEALTHY or self:getHealth() == Character.STATUS_SCUFFED_UP then
			s = g_LM.line(sStarvingLC)
			-- if hurt and starving, health is "hurt, starving"
		elseif self:getHealth() == Character.STATUS_HURT then
			s = s .. ', ' .. g_LM.line(sStarvingLC)
		end
	end
	-- suffocating?
	if self.tStatus.suffocationTime > 0 then
		local sSuffocating = g_LM.line('INSPEC107TEXT')
		local nTimeLeft = Character.OXYGEN_SUFFOCATION_UNTIL_DEATH - self.tStatus.suffocationTime
		sSuffocating = sSuffocating..' ('..MiscUtil.formatTime(nTimeLeft)..')'
        local sHealth = self:getHealth()
		if (sHealth == Character.STATUS_HEALTHY or sHealth == Character.STATUS_SCUFFED_UP) and not self:starving() then
			s = sSuffocating
		elseif self:getHealth() == Character.STATUS_HURT or self:starving() then
			s = s .. ', ' .. sSuffocating
		end
	end
	return s
end

function Character:getToolTipTextInfos()
	-- reset tooltip lines
	self.tToolTipTextInfos = {}
	self.tToolTipTextInfos[1] = {}
	self.tToolTipTextInfos[2] = {}
	self.tToolTipTextInfos[3] = {}
	self.tToolTipTextInfos[4] = {}
	self.tToolTipTextInfos[5] = {}
	self.tToolTipTextInfos[6] = {}
	local nCurrentIndex = 1
    --name
    self.tToolTipTextInfos[nCurrentIndex].sString = self:getNiceName()
    self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/JobRoster'
    self.tToolTipTextInfos[nCurrentIndex].sTexture = Character.JOB_ICONS[self.tStats.nJob]
	-- beacon: suggest nature of security action, response level
	if GameRules.currentMode == GameRules.MODE_BEACON then
		nCurrentIndex = nCurrentIndex + 1
		local s = g_LM.line('UIMISC029TEXT')
		if not Base.isFriendlyToPlayer(self) then
			s = g_LM.line('UIMISC030TEXT')
		end
		local sTypeLC = g_ERBeacon.tBeaconTypeLinecodes[g_ERBeacon:getViolence(self.squadName)]
		s = s .. ' (' .. g_LM.line(sTypeLC) .. ')'
		self.tToolTipTextInfos[nCurrentIndex].sString = s
        self.tToolTipTextInfos[nCurrentIndex].sTexture = nil
	end
    --health
	nCurrentIndex = nCurrentIndex + 1
	self.tToolTipTextInfos[nCurrentIndex].sString = self:getHealthText()
	local bSuffocating = self.tStatus.suffocationTime > 0
    local tColor = Gui.AMBER
    if not self:isHealthy() or self:starving() or bSuffocating then
        tColor = Gui.RED
    else
        tColor = Gui.AMBER
    end
    self.tToolTipTextInfos[nCurrentIndex].tColor = tColor
    if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
        self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_health'
        self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
        self.tToolTipTextInfos[nCurrentIndex].tTextureColor = tColor
    end
    -- 3rd line: cause of death, if dead
	nCurrentIndex = nCurrentIndex + 1
	if self:getHealth() == Character.STATUS_DEAD then
		self.tToolTipTextInfos[nCurrentIndex].sString = g_LM.line(Character.tDeathCauses[self.tStatus.nDeathCause])
		if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
			self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_enemy'
			self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
			self.tToolTipTextInfos[nCurrentIndex].tTextureColor = tColor
		end
	-- 3rd line: morale, color-coded, if alive
	else
		self.tToolTipTextInfos[nCurrentIndex].sString = self:getMoraleText()
		local nMorale = self:getMorale()
		if nMorale < 0 then
			nMorale = math.abs(nMorale)/100
			tColor = { DFMath.lerp(Gui.AMBER[1], Gui.RED[1], nMorale), DFMath.lerp(Gui.AMBER[2], Gui.RED[2], nMorale), DFMath.lerp(Gui.AMBER[3], Gui.RED[3], nMorale), 1 }
		else
			nMorale = math.abs(nMorale)/100
			tColor = { DFMath.lerp(Gui.AMBER[1], Gui.GREEN[1], nMorale), DFMath.lerp(Gui.AMBER[2], Gui.GREEN[2], nMorale), DFMath.lerp(Gui.AMBER[3], Gui.GREEN[3], nMorale), 1 }
		end
		self.tToolTipTextInfos[nCurrentIndex].tColor = tColor
		if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
			self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_morale'
			self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
			self.tToolTipTextInfos[nCurrentIndex].tTextureColor = tColor
		end
	end
    --activity
	nCurrentIndex = nCurrentIndex + 1
    self.tToolTipTextInfos[nCurrentIndex].sString = self:getActivityText()
    -- if activity is effed, make red
    --if self.tStats.sDeathLine or string.find(self.tToolTipTextInfos[nCurrentIndex].sString, "Panic") or string.find(self.tToolTipTextInfos[nCurrentIndex].sString, "Dying") or string.find(self.tToolTipTextInfos[nCurrentIndex].sString, "Running") or string.find(self.tToolTipTextInfos[nCurrentIndex].sString, "Flee") then
    --    tColor = Gui.RED
    --else
        tColor = Gui.AMBER
    --end
    self.tToolTipTextInfos[nCurrentIndex].tColor = tColor
    if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
        self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_activity'
        self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
        self.tToolTipTextInfos[nCurrentIndex].tTextureColor = tColor
    end
    --oxygen
	nCurrentIndex = nCurrentIndex + 1
    self.tToolTipTextInfos[nCurrentIndex].sString = self:getToolTipOxygenText()
    if self:getSuitOxygenPct() <= 25 then
        tColor = Gui.RED
    else
        tColor = Gui.AMBER
    end
    self.tToolTipTextInfos[nCurrentIndex].tColor = tColor
    if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
        self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_bulletpoint'
        self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
        self.tToolTipTextInfos[nCurrentIndex].tTextureColor = tColor
    end

    return self.tToolTipTextInfos
end

------------------------------------------------
-- DEBUG
------------------------------------------------
function Character:drawDebugPath()
	-- debug pathing display
	if not self.rCurrentTask or not self.rCurrentTask.tPath or not self.rCurrentTask.tPath.tPathNodes then
		return
	end
	local tPathNodes = self.rCurrentTask.tPath.tPathNodes
	local rRenderLayer = g_World.getWorldRenderLayer()
	MOAIGfxDevice.setPenColor(1, 0, 1, 1)
	-- start lines from character
	local cx,cy,cz = self:getLoc()
	local x0,y0 = 0,0
	local x1,y1 = rRenderLayer:worldToWnd(tPathNodes[1].wx, tPathNodes[1].wy, cz)
	for i,node in pairs(tPathNodes) do
		local wx,wy = node.wx, node.wy
		-- data in tPathNodes doesn't always have the same format
		if not wx then
			wx,wy = g_World._getWorldFromTile(node.tx, node.ty)
		end
		x0,y0 = rRenderLayer:worldToWnd(wx, wy, cz)
		MOAIDraw.drawLine( x0, y0, x1, y1 )
		x1,y1 = x0,y0
	end
end

------------------------------------------------
-- CLASS METHODS
------------------------------------------------
function Character.updateSavegame(nSavegameVersion, saveData)
    if saveData and nSavegameVersion <= 3 then
        for i,t in ipairs(saveData) do
            if t.tMemory then
                for k,v in pairs(t.tMemory) do
                    if type(v) ~= 'table' then
                        t.tMemory[k] = nil
                    end
                end
            end
        end
    end
end

function Character.getCurrentLevelByXP(nCurrentXP)
	return 1+math.min(9, math.floor(nCurrentXP/Character.EXPERIENCE_PER_LEVEL))
end

return Character
