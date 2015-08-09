local GameRules = require('GameRules')
local CharacterManager = require('CharacterManager')
local Character = require('CharacterConstants')
local ObjectList = require('ObjectList')
local EnvObject = require('EnvObjects.EnvObject')
local CommandObject = require('Utility.CommandObject')
local Room = require('Room')
local Door = require('EnvObjects.Door')
local Character = require('Character')
local DFUtil=require('DFCommon.Util')
local HydroPlant=require('EnvObjects.HydroPlant')
local Base=require('Base')
local Malady=require('Malady')
local InventoryData=require('InventoryData')

local HintChecks = {}

HintChecks.log = false

-- tunables
HintChecks.LOW_MATTER_WARNING = 500
HintChecks.ACCIDENT_TIMEOUT = 20
HintChecks.DERELICT_WARN_DELAY = 20
HintChecks.REC_PLANTS_PER_BOTANIST = 6

function HintChecks.waitingAtBeacon()
    if g_ERBeacon and g_ERBeacon:timeWaited() > 30 then
        return true
    end
end

function HintChecks.dontPutNormalDoorsOnAnAirlock()
    if HintChecks.noFunctioningAirlocks() then
	    for _,room in pairs(Room.tRooms) do
		    if room.zoneName == 'AIRLOCK' then
                if room.zoneObj.bBadDoor then
                    return true
                end
            end
        end
    end
end

function HintChecks.youCanForceOpenADoor()
    if HintChecks.noFunctioningAirlocks() and not HintChecks.dontPutNormalDoorsOnAnAirlock() then
	    for _,room in pairs(Room.tRooms) do
		    if room.zoneName == 'AIRLOCK' then
                local zo = room.zoneObj
                if zo and zo.rSpaceDoor and not zo.rSpaceDoor.bDestroyed and zo.rSpaceDoor.bValidAirlock and zo.rSpaceDoor.doorState == Door.doorStates.LOCKED then
                    return true
                end
            end
        end
    end
end

function HintChecks.notEnoughTechnicians()
	-- true when: damaged objects in base, fewer than recommended # of techs
	local techs = CharacterManager.tJobCount[Character.TECHNICIAN]
    if EnvObject.nDamagedObjects > techs/6 and EnvObject.nTotalDecay > techs * .5 then
		return true
    end
	return false
end

function HintChecks.lowMatter()
	return GameRules.nMatter < HintChecks.LOW_MATTER_WARNING
end

function HintChecks.pendingConstruction()
	-- true when: any sort of pending construction
	-- (wall/floor, envobj build/teardown)
	-- check world (wall, floor) construction
	for addr,cmdObj in pairs(CommandObject.tCommands) do
		if cmdObj.param ~= -1 and (cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE or cmdObj.commandAction == CommandObject.COMMAND_VAPORIZE) then
			return true
		end
	end
	-- check envobjects slated for construction or teardown
	-- don't use Room.tPendingObjectBuilds; it only contains objects before
	-- they're confirmed in construct menu
	for _,rRoom in pairs(Room.tRooms) do
		if not rRoom.bDestroyed then
			for addr,rProp in pairs(rRoom.tPropPlacements) do
				return true
			end
			for rProp,_ in pairs(rRoom.tProps) do
				if rProp.bSlatedForVaporize then
					return true
				end
			end
		end
	end
	return false
end

function HintChecks.noBuilders()
	-- true when: build order outstanding, no builders
	CharacterManager.updateOwnedCharacters()
	if CharacterManager.tJobCount[Character.BUILDER] ~= 0 then
		return false
	end
	return HintChecks.pendingConstruction()
end

function HintChecks.noMiners()
	-- true when: mining order outstanding, no miners
	local miners = CharacterManager.tJobCount[Character.MINER]
	-- mine orders?
	for addr,cmdObj in pairs(CommandObject.tCommands) do
		if cmdObj.param ~= -1 and cmdObj.commandAction == CommandObject.COMMAND_MINE and miners == 0 then
			return true
		end
	end
	return false
end

function HintChecks.minersNoMining()
	-- true when: miners and refineries, no mining orders
	if CharacterManager.tJobCount[Character.MINER] == 0 then
		return false
	end
	local tRefineries,nRefineries = EnvObject.getObjectsOfFunctionality('Shelving', true)
	if nRefineries == 0 then
		return false
	end
	for addr,cmdObj in pairs(CommandObject.tCommands) do
		if cmdObj.param ~= -1 and cmdObj.commandAction == CommandObject.COMMAND_MINE then
			return false
		end
	end
	return true
end

function HintChecks.noRefineries()
	-- true when: a miner has a rock, but no refinery
	-- bail out early if no miners (what if player just reassigned duty?)
	if CharacterManager.tJobCount[Character.MINER] == 0 then
		return false
	end
	local hasRock = false
	local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	for _,char in pairs(tChars) do
		if char:getInventoryCountByTemplate(InventoryData.MINE_PICKUP_NAME) > 0 then
			hasRock = true
			break
		end
	end
	-- bail if nobody gotz any rockz
	if not hasRock then
		return false
	end
	local hasRefinery = false
	local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
	for room,_ in pairs(tRooms) do
		if room.zoneName == 'REFINERY' then
			hasRefinery = true
			break
		end
	end
	return not hasRefinery
end

function HintChecks.lowOxygen()
    -- true when: half of the population has low morale levels of oxygen (or if 1 dude, check him)
	-- early out: player hasn't even built a room yet
	if HintChecks.noRooms() then
		return false
	end
    CharacterManager.updateOwnedCharacters()
	local tChars = CharacterManager.getOwnedCharacters()
    local nSadDudes = 0
    if #tChars == 1 then
        return tChars[1].nAverageOxygen <= Character.MORALE_LOW_OXYGEN_THRESHOLD
    else
        for _, char in pairs(tChars) do
            if char.nAverageOxygen < Character.MORALE_LOW_OXYGEN_THRESHOLD then nSadDudes = nSadDudes + 1 end
        end
        return nSadDudes >= (#tChars/2)
    end
end

function HintChecks.roomsButNoOxygen()
	-- true when: at least one enclosed room, no oxygen recyclers
	if HintChecks.noEnclosedRooms() then
		return false
	end
	local nRecyclers = EnvObject.getNumberOfObjects('OxygenRecycler', true)
	local nLvl2Recyclers = EnvObject.getNumberOfObjects('OxygenRecyclerLevel2', true)
	return (nRecyclers + nLvl2Recyclers) == 0
end

function HintChecks.notEnoughBeds()
    -- true when: someone is sleeping on the floor, and there are not enough beds
	local tFloorSleepers = CharacterManager.getOwnedCharactersWithTask('SleepOnFloor')
	if #tFloorSleepers == 0 then
		return false
	end
	local beds = EnvObject.getNumberOfObjects('Bed')
	local chars = CharacterManager.getOwnedCharacters()
	return beds < DFUtil.tableSize(chars)
end

function HintChecks.noFunctioningAirlocks()
	-- true when: no functioning airlocks anywhere
	if HintChecks.noRooms() and not HintChecks.roomsButNoOxygen() then
		return false
	elseif not GameRules.bHasHadEnclosedRooms then
		return false
	end
	for _,room in pairs(Room.tRooms) do
		if room.zoneName == 'AIRLOCK' and room.zoneObj.bFunctional then
			return false
		end
	end
	return true
end

function HintChecks.noRooms()
	-- helper function, used for basic building sanity checks
	return DFUtil.tableSize(Room.tRooms) == 0
end

function HintChecks.noEnclosedRooms()
	local nBreachedRooms = 0
	for _,room in pairs(Room.tRooms) do
		if room:isBreached() then
			nBreachedRooms = nBreachedRooms + 1
		end
	end
	if not GameRules.bHasHadEnclosedRooms and nBreachedRooms < DFUtil.tableSize(Room.tRooms) then
		GameRules.bHasHadEnclosedRooms = true
	end
	return nBreachedRooms == DFUtil.tableSize(Room.tRooms)
end	

function HintChecks.noBuilding()
	-- true when: no rooms (oxygenated or not) and no build orders
	if not HintChecks.noRooms() then
		return false
	end
	for addr,cmdObj in pairs(CommandObject.tCommands) do
		if cmdObj.commandAction == CommandObject.COMMAND_BUILD_TILE then
			return false
		end
	end
	return true
end

function HintChecks.everyoneDead()
	CharacterManager.updateOwnedCharacters()
	local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	return #tChars == 0
end

function HintChecks.pubAtCapacity()
	-- true when: base has a pub, but it's at capacity
	local tRooms = Room.getSafeRoomsOfTeam(Character.TEAM_ID_PLAYER)
	for room,idx in pairs(tRooms) do
		if room.zoneName == 'PUB' and room.zoneObj:getCapacity() > 0 and room.zoneObj:atCapacity() then
			return true
		end
	end
	return false
end

function HintChecks.pubButNoBar()
	-- true when: base has a pub, but it lacks a bar
	local tRooms = Room.getSafeRoomsOfTeam(Character.TEAM_ID_PLAYER)
	for room,idx in pairs(tRooms) do
		if room.zoneName == 'PUB' then
			if not room.zoneObj:hasBar() then
				return true
			end
		end
	end
	return false
end

function HintChecks.editMode()
    return GameRules.inEditMode
end

function HintChecks.failedDutyAccident()
	-- true when: a citizen has recently caused a fire due to duty failure
	-- (low morale / low competence)
	if GameRules.nLastDutyAccident == 0 then
		return false
	end
	return GameRules.nLastDutyAccident + HintChecks.ACCIDENT_TIMEOUT > GameRules.elapsedTime
end

function HintChecks.derelictNoBeacon()
	-- true when: a derelict has docked (but after a delay) but player hasn't
	-- placed a beacon
	if GameRules.nLastNewShip == 0 then
		return false
	end
	return not g_ERBeacon.tx and GameRules.nLastNewShip + HintChecks.DERELICT_WARN_DELAY > GameRules.elapsedTime
end

function HintChecks.beaconNoSecurity()
	-- true when: beacon placed, no citizens on security duty
	return g_ERBeacon.tx and CharacterManager.tJobCount[Character.EMERGENCY] == 0
end

function HintChecks.fireNoExtinguisher()
	-- true when: a citizen is doing ExtinguishFireBareHanded in a room without
	-- an extinguisher
	local tFireStompers = CharacterManager.getOwnedCharactersWithTask('ExtinguishFireBareHanded')
	if #tFireStompers == 0 then
		return false
	end
	for _,char in pairs(tFireStompers) do
        local rRoom = char:getRoom()
		if rRoom and rRoom ~= Room.getSpaceRoom() and not rRoom:hasObjectOfType('FirePanel') then
			return true
		end
	end
	return false
end

function HintChecks.roomButNeverZoned()
	-- true when: >=1 fully enclosed room, no zoning, first time only
	if GameRules.bHasZoned or HintChecks.noEnclosedRooms() then
		return false
	end
	local nZonedRooms = 0
	local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
	for room,_ in pairs(tRooms) do
		if room.zoneName ~= 'PLAIN' then
			nZonedRooms = nZonedRooms + 1
			if not GameRules.bHasZoned then
				GameRules.bHasZoned = true
			end
		end
	end
	return nZonedRooms == 0
end

function HintChecks.getNumSeededPlants()
	local tPlants = EnvObject.getObjectsOfType('HydroPlant', true)
	local nSeeded = 0
	for _,plant in pairs(tPlants) do
		if plant.bSeeded then
			nSeeded = nSeeded + 1
		end
	end
	return nSeeded
end

function HintChecks.starvingNoMatter()
	-- true when: starving people, replicators, but no matter
	local tStarvers = CharacterManager.getOwnedCharactersWithTask('Starve')
	if #tStarvers == 0 then
		return false
	end
	local tReplicators = EnvObject.getObjectsOfType('FoodReplicator', true)
	for _,rReplicator in pairs(tReplicators) do
		local bCanBuy, sReason = rReplicator:canBuyFood()
		if not bCanBuy and sReason == 'insufficient matter' then
			return true
		end
	end
	return false
end

function HintChecks.starvingNoFood()
	-- true when: >=1 citizen at critical hunger, no replicators or prepared food capability
	local nReplicators = EnvObject.getNumberOfObjects('FoodReplicator', true)
	if nReplicators > 0 then
		return false
	end
	local nHydroPlants = EnvObject.getNumberOfObjects('HydroPlant', true)
	if nHydroPlants > 0 and HintChecks.getNumSeededPlants() > 0 then
		return false
	end
    CharacterManager.updateOwnedCharacters()
	local tChars = CharacterManager.getOwnedCharacters()
	for _,char in pairs(tChars) do
		if char.tStatus.nStarveTime > 0 then
			return true
		end
	end
	return false
end

function HintChecks.gardenNoBotanist()
	-- true when: >=1 hydroponic trays, nobody on botanist duty
	local nHydroPlants = EnvObject.getNumberOfObjects('HydroPlant', true)
	if nHydroPlants == 0 then
		return false
	end
	if CharacterManager.tJobCount[Character.BOTANIST] == 0 then
		return true
	end
	return false
end

function HintChecks.notEnoughBotanists()
	-- true when: plants at low health, not enough botanists
	local nHydroPlants = EnvObject.getNumberOfObjects('HydroPlant', true)
	if nHydroPlants == 0 then
		return false
	end
	local nBotanists = CharacterManager.tJobCount[Character.BOTANIST]
	local tPlants = EnvObject.getObjectsOfType('HydroPlant', true)
	for _,plant in pairs(tPlants) do
		if plant.bSeeded and plant.nPlantHealth <= HydroPlant.DEAD_PLANT_HEALTH then
			if nBotanists == 0 or nBotanists / nHydroPlants < HintChecks.REC_PLANTS_PER_BOTANIST then
				return true
			end
		end
	end
	return false
end

function HintChecks.haveFoodPrepObjects()
	local nBotanists = CharacterManager.tJobCount[Character.BOTANIST]
	local nBartenders = CharacterManager.tJobCount[Character.BARTENDER]
	local nStoves = EnvObject.getNumberOfObjects('Stove', true)
	local nFridges = EnvObject.getNumberOfObjects('Fridge', true)
	return nBotanists > 0 and nBartenders > 0 and nStoves > 0 and nFridges > 0
end

function HintChecks.noFoodPathable()
	-- true when: starving citizen, food exists but isn't pathable
	local tStarvers = CharacterManager.getOwnedCharactersWithTask('Starve')
	return not HintChecks.starvingNoFood() and not HintChecks.starvingNoMatter() and #tStarvers > 0
end

function HintChecks.cropsNoFoodPrep()
	-- true when: harvestable food, missing >=1 food prep objects (stove, fridge, table, bartender)
	local nHydroPlants = EnvObject.getNumberOfObjects('HydroPlant', true)
	if nHydroPlants == 0 then
		return false
	end
	-- ripe plants?
	local tPlants = EnvObject.getObjectsOfType('HydroPlant', true)
	local nRipePlants = 0
	for _,plant in pairs(tPlants) do
		if plant.nPlantAge == plant.rPlantData.nLifeTime then
			nRipePlants = nRipePlants + 1
		end
	end
	return nRipePlants > 0 and not HintChecks.haveFoodPrepObjects()
end

function HintChecks.mealNoTables()
	-- true when: everything needed to serve meals except tables
	local nTables = EnvObject.getNumberOfObjects('StandingTable', true)
	return nTables == 0 and HintChecks.haveFoodPrepObjects()
end

-- research stuff

function HintChecks.activeResearch()
	local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
	for room,_ in pairs(tRooms) do
		if room.zoneName == 'RESEARCH' then
			if room.zoneObj.sCurrentResearch then
				return true
			end
		end
	end
	return false
end

function HintChecks.researchReadyNoResearch()
	-- true when: scientists and desks but no active research project
    -- (and player has never researched anything)
	-- update: always tell player when they could be researching
--[[
    if GameRules.bHasStartedResearch then
        return false
    end
]]--
	local nScientists = CharacterManager.tJobCount[Character.SCIENTIST]
	if nScientists == 0 then
		return false
	end
	local nDesks = EnvObject.getNumberOfObjects('ResearchDesk', true)
	if nDesks == 0 then
		return false
	end
	local _,nProjects = Base.getAvailableResearch()
	return nProjects > 0 and not HintChecks.activeResearch()
end

function HintChecks.researchNoDesks()
	-- true when: active research project, no desks
	local nScientists = CharacterManager.tJobCount[Character.SCIENTIST]
	if nScientists == 0 then
		return false
	end
	local nDesks = EnvObject.getNumberOfObjects('ResearchDesk', true)
	return HintChecks.activeResearch() and nDesks == 0
end

function HintChecks.researchNoScientists()
	-- true when: active research project, no scientists
	local nScientists = CharacterManager.tJobCount[Character.SCIENTIST]
	return HintChecks.activeResearch() and nScientists == 0
end

function HintChecks.unclaimedResearchDatacubes()
	-- true when: unclaimed datacube hasn't been marked for collection
	local tCubes = EnvObject.getObjectsOfType('ResearchDatacube', true, true)
	for _,cube in pairs(tCubes) do
		-- only include datacubes in revealed rooms
		if not cube:slatedForTeardown(true) and cube.rRoom and cube.rRoom.nLastVisibility == g_World.VISIBILITY_FULL then
			return true
		end
	end
	return false
end

function HintChecks.claimedResearchDatacubesNoScientists()
	-- true when: claimed datacube, but no scientists to collect it
	local nScientists = CharacterManager.tJobCount[Character.SCIENTIST]
	if nScientists > 0 then
		return false
	end
	local tCubes = EnvObject.getObjectsOfType('ResearchDatacube', true, true)
	for _,cube in pairs(tCubes) do
		if not cube:slatedForTeardown(true) then
			return true
		end
	end
	return false
end

function HintChecks.claimedResearchDatacubesNoDesks()
	-- true when: claimed datacube, but no desks to take it to
	local nDesks = EnvObject.getNumberOfObjects('ResearchDesk', true)
	if nDesks > 0 then
		return false
	end
	local tCubes = EnvObject.getObjectsOfType('ResearchDatacube', true, true)
	for _,cube in pairs(tCubes) do
		if not cube:slatedForTeardown(true) then
			return true
		end
	end
	return false
end

function HintChecks.haveCorpse()
    return EnvObject.getNumberOfObjects('Corpse') > 0
end

function HintChecks.corpseNoRefinery()
    -- true when: corpse, no refinery
    if not HintChecks.haveCorpse() then
        return false
    end
	local nRefineries = EnvObject.getNumberOfObjects('RefineryDropoff')
    nRefineries = nRefineries + EnvObject.getNumberOfObjects('RefineryDropoffLevel2')
    return nRefineries == 0
end

function HintChecks.haveDoctor()
    -- returns # of /non-incapacitated/ doctors
    -- (if all your doctors are incapacitated, you effectively have none
    -- because they can't heal themselves!)
    if CharacterManager.tJobCount[Character.DOCTOR] == 0 then
        return false
    end
    local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
    local nDoctors = 0
	for _,rChar in pairs(tChars) do
        if rChar:getJob() == Character.DOCTOR and not Malady.isIncapacitated(rChar) then
            return true
        end
    end
    return false
end

function HintChecks.corpseNoDoctor()
    -- true when: corpse, no doctor
    if HintChecks.haveDoctor() then
        return false
    end
    return HintChecks.haveCorpse()
end

function HintChecks.patientNoDoctor()
    -- true when: citizen has reported to infirmary, no doctor
    if HintChecks.haveDoctor() then
        return false
    end
    local tPatients = CharacterManager.getOwnedCharactersWithTask('CheckInToHospital')
    return #tPatients > 0
end

function HintChecks.illnessNoDoctor()
    -- true when: citizen is ill and exhibiting symptoms, no doctor
    if HintChecks.haveDoctor() then
        return false
    end
	local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	for _,rChar in pairs(tChars) do
        for sName,tMalady in pairs(rChar.tStatus.tMaladies) do
            if tMalady.bSymptomatic then
                -- (later, non-exclusive state: tMalady.bDiagnosed)
                return true
            end
        end
    end
    return false
end

function HintChecks.illnessNoCureResearched()
    -- true when: citizen is ill and exhibiting symptoms, cure undiscovered
	local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	for _,rChar in pairs(tChars) do
        for sName,tMalady in pairs(rChar.tStatus.tMaladies) do
            if tMalady.bDiagnosed and not Malady.hasDiscoveredCure(sName) then
                return true
            end
        end
    end
    return false
    --Malady.hasEncounteredDisease(sMaladyName)
end

function HintChecks.citizenIncapacitatedNoDoctor()
    -- true when: citizen is incapacitated, no doctor
    if HintChecks.haveDoctor() then
        return false
    end
	local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	for _,rChar in pairs(tChars) do
        -- alt approach, use:
        -- local _,nInjuries = rChar:getInjuries()
        
        if Malady.isIncapacitated(rChar) then
            return true
        end
    end
    return false
end

function HintChecks.noPower()
	-- true when: no player-controlled rooms are receiving >0 power
	local tRooms,nRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
	if nRooms == 0 then
		return false
	end
	for rRoom,_ in pairs(tRooms) do
		if rRoom:hasPower() then
			return false
		end
	end
	return true
end

function HintChecks.lowPower()
	-- true when: any player-controlled room receiving less than its power draw
	local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
	-- don't show if no power is up
	if HintChecks.noPower() then
		return false
	end
	for rRoom,_ in pairs(tRooms) do
        -- begin changes for mod HintFixUnpowered
        if not rRoom:hasFullPower() and not rRoom.bBreach then
			return true
		end
        -- end changes for mod HintFixUnpowered
	end
	return false
end

function HintChecks.airlockNoLocker()
	-- true when: player has any airlock without a suit locker
	local tAirlocks,nAirlocks = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER, false, 'AIRLOCK')
	if nAirlocks == 0 then
		return false
	end
	for rRoom,_ in pairs(tAirlocks) do
		local bHasLocker = false
		for rProp,_ in pairs(rRoom.tProps) do
			if rProp.sName == 'AirlockLocker' and not rProp.bSlatedForVaporize then
				bHasLocker = true
			end
		end
		if not bHasLocker then
			return true
		end
	end
	return false
end

function HintChecks.citizenLowDutyAffinity()
	-- true when: citizen assigned to duty for which their affinity is below a threshold
	local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	for _,rChar in pairs(tChars) do
		if rChar:getJobAffinity(rChar.tStats.nJob) <= -8 then
			-- return table with replacement
			return true, {CITIZEN = rChar.tStats.sName}
		end
	end
	return false
end

function HintChecks.unassignedResidences()
	-- true when: # free beds > # citizens AND haven't assigned
	local tBeds,nBeds = EnvObject.getObjectsOfType('Bed', true)
	if nBeds == 0 then
		return false
	end
	local tChars,nChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
    -- begin changes for mod HintFixAssignResidence
    if nBeds < nChars then
        return false
    end
    local nUsed = 0
    for _,rBed in pairs(tBeds) do
        if rBed:getOwner() ~= nil then
            nUsed = nUsed + 1
        end
        if rBed:getRoom():getZoneName() == 'BRIG' then
            nBeds = nBeds - 1
        end
    end
    if nUsed < nChars and nBeds >= nChars then
        return true
    else
        return false
    end
    -- end changes for mod HintFixAssignResidence
end

function HintChecks.noShelving()
	-- true when: decent amount of stuff in world AND more stuff than shelving capacity
	local tChars,nChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	local nStuffInWorld = 0
	for _,rChar in pairs(tChars) do
		nStuffInWorld = nStuffInWorld + rChar:getNumOwnedStuff()
	end
	-- TODO: get stuff on ground too?
	-- don't bother if base is not populous enough to worry about material needs
	if nStuffInWorld <= 8 then
		return false
	end
	-- compare shelving capacity to stuff
	local tShelves,nShelves = EnvObject.getObjectsOfFunctionality('Shelving', true)
	if nShelves == 0 then
		return true
	end
	local nCapacity = 0
	for _,rShelf in pairs(tShelves) do
		if rShelf.tData.tDisplaySlots then
			nCapacity = nCapacity + #rShelf.tData.tDisplaySlots
		end
	end
	-- stash need and capacity in Base so characters can refer to it
	Base.nCurrentStuff = nStuffInWorld
	Base.nCurrentShelvingCapacity = nCapacity
	return nStuffInWorld > nCapacity
end

function HintChecks.powerHoliday()
	-- true when: power holiday in effect and power demands not fully met
	return g_PowerHoliday and HintChecks.lowPower()
end

function HintChecks.incapacitatedTroublemaker()
	-- true when: incapacitated rampager isn't assigned to brig
	local tChars = CharacterManager.getCharacters()
	for _,rChar in pairs(tChars) do
		if rChar:hasUtilityStatus(Character.STATUS_RAMPAGE) and Malady.isIncapacitated(rChar) and not rChar.tStatus.tAssignedToBrig then
			return true
		end
	end
	return false
end

return HintChecks
