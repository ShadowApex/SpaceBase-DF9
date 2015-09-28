local GameRules = require('GameRules')
local Base = require('Base')
local EnvObject = require('EnvObjects.EnvObject')
local EnvObjectData = require('EnvObjects.EnvObjectData')
local Room = require('Room')
local ResearchData = require('ResearchData')
local CharacterManager = require('CharacterManager')
local Character = require('CharacterConstants')
local InventoryData = require('InventoryData')
local EventController = require('EventController')
local Malady = require('Malady')

local GoalData = {}

GoalData.TARGET_CITIZENS = 50
GoalData.TARGET_MATTER = 50000
GoalData.TARGET_HOSTILES_KILLED = 50
GoalData.TARGET_BASE_TILES = 3000
-- following number is for UI display, real # derived from EnvObjectData (I have included items that need to be researched)
GoalData.TARGET_ENVOBJECT_TYPES = 41
GoalData.TARGET_MEALS = 1000
GoalData.TARGET_CURES = 10
GoalData.TARGET_TECHS = 18 -- derived from ResearchData
GoalData.TARGET_HAPPY_CITIZENS = 30
GoalData.TARGET_BREACH_SHIPS = 5
GoalData.TARGET_POSSESSIONS = 30 -- derived from InventoryData
GoalData.TARGET_RAIDERS_CONVERTED = 10
GoalData.TARGET_HOSTILES_ASPHYXIATED = 10
GoalData.TARGET_HOSTILE_TURRET_KILLS = 20
GoalData.TARGET_BODIES = 100
GoalData.TARGET_HOSTILE_MONSTER_KILLS = 10

--
-- goal check functions
--
-- each return a bool for completion and a # for progress
function GoalData.citizens()
	local _,nCitizens = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	return nCitizens >= GoalData.TARGET_CITIZENS, nCitizens
end

function GoalData.matter()
	return GameRules.nMatter >= GoalData.TARGET_MATTER, GameRules.nMatter
end

function GoalData.builtEverything()
	-- one of each type of envobject, not counting unplaceable stuff
	local nTotalTypes,nTypesBuilt = 0,0
	for sObj,tObjData in pairs(EnvObjectData.tObjects) do
		if tObjData.showInObjectMenu ~= false then
			nTotalTypes = nTotalTypes + 1
			local tObjects,nObjects = EnvObject.getObjectsOfType(sObj, true)
			if nObjects > 0 then
				nTypesBuilt = nTypesBuilt + 1
			end
		end
	end
	return nTypesBuilt >= nTotalTypes, nTypesBuilt
end

function GoalData.hostilesKilled()
	return Base.tS.tStats.nHostilesKilled >= GoalData.TARGET_HOSTILES_KILLED, Base.tS.tStats.nHostilesKilled
end

function GoalData.baseTiles()
	local nTiles = Room.getNumOwnedTiles()
	return nTiles >= GoalData.TARGET_BASE_TILES, nTiles
end

function GoalData.mealsServed()
	return Base.tS.tStats.nMealsServed >= GoalData.TARGET_MEALS, Base.tS.tStats.nMealsServed
end

function GoalData.curesResearched()
	return Base.tS.tStats.nCuresResearched >= GoalData.TARGET_CURES, Base.tS.tStats.nCuresResearched
end

function GoalData.allTechs()
	local nTotalTechs,nTechsResearched = 0,0
	for sProject,tProjectData in pairs(ResearchData) do
		if not tProjectData.bDiscoverOnly then
			nTotalTechs = nTotalTechs + 1
			if Base.hasCompletedResearch(sProject) then
				nTechsResearched = nTechsResearched + 1
			end
		end
	end
	return nTechsResearched >= nTotalTechs, nTechsResearched
end

function GoalData.happyCitizens()
	local tCitizens = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	local nHappyCitizens = 0
	local nHappyThreshold = 90
	for _,rChar in pairs(tCitizens) do
		if rChar.tStats.nMorale > nHappyThreshold then
			nHappyCitizens = nHappyCitizens + 1
		end
	end
	return nHappyCitizens >= GoalData.TARGET_HAPPY_CITIZENS, nHappyCitizens
end

function GoalData.breachShipsDestroyed()
	return Base.tS.tStats.nBreachShipsDestroyed >= GoalData.TARGET_BREACH_SHIPS, Base.tS.tStats.nBreachShipsDestroyed
end

function GoalData.allPossessions()
	-- build list of all items to check
	local nTotalItems,nItemsCollected = 0,0
	local tItems = {}
	for sItemType,tItemData in pairs(InventoryData.tTemplates) do
		-- only stuff citizens can display
		if tItemData.bStuff and tItemData.bDisplayable then
			nTotalItems = nTotalItems + 1
			tItems[sItemType] = nTotalItems
		end
	end
	-- check storage/pickups in every player-owned room
	for id,rRoom in pairs(Room.tRooms) do
		if rRoom:playerOwned() then
			for rProp,_ in pairs(rRoom.tProps) do
				if rProp.tInventory then
					for sItem,tInvData in pairs(rProp.tInventory) do
						if tItems[tInvData.sTemplate] then
							-- item found, stop checking for it
							tItems[tInvData.sTemplate] = nil
							nItemsCollected = nItemsCollected + 1
						end
					end
				end
			end
		end
	end
	return nItemsCollected >= nTotalItems, nItemsCollected
end

function GoalData.raidersConverted()
	return Base.tS.tStats.nRaidersConverted >= GoalData.TARGET_RAIDERS_CONVERTED, Base.tS.tStats.nRaidersConverted
end

function GoalData.hostilesAsphyxiated()
	return Base.tS.tStats.nHostilesAsphyxiated >= GoalData.TARGET_HOSTILES_ASPHYXIATED, Base.tS.tStats.nHostilesAsphyxiated
end

function GoalData.hostilesKilledByTurrets()
	return Base.tS.tStats.nHostilesKilledByTurret >= GoalData.TARGET_HOSTILE_TURRET_KILLS, Base.tS.tStats.nHostilesKilledByTurret
end

function GoalData.bodiesRefined()
	return Base.tS.tStats.nCorpsesRecycled >= GoalData.TARGET_BODIES, Base.tS.tStats.nCorpsesRecycled
end

function GoalData.hostilesFedToMonster()
	return Base.tS.tStats.nHostilesKilledByParasite >= GoalData.TARGET_HOSTILE_MONSTER_KILLS, Base.tS.tStats.nHostilesKilledByParasite
end

function GoalData.finalSiege()
	if not EventController.tS.bRanMegaEvent then
		return false, 0
	end
	-- wait a while for hostile forces to show up
	if GameRules.elapsedTime < EventController.tS.nMegaEventStartTime + 120 then
		return false, 0
	end
	-- at least one non-incapacitated friendly in a safe room
	local tCitizens = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
	local bFriendlySurvivor = false
	for _,rChar in pairs(tCitizens) do
		if not Malady.isIncapacitated(rChar) and not rChar:isDead() then
			if rChar.rCurrentRoom and not rChar.rCurrentRoom:isDangerous() then
				bFriendlySurvivor = true
				break
			end
		end
	end
	if not bFriendlySurvivor then
		return false, 0
	end
	-- all raiders dead or incapacitated
	local tHostiles = CharacterManager.getHostileCharacters(tCitizens[1])
	for _,rChar in pairs(tHostiles) do
		if not Malady.isIncapacitated(rChar) or not rChar:isDead() then
			return false, 0
		end
	end
	return true, 1
end

--
-- goal definitions
--
GoalData.tGoals =
{
    {
		sName = 'Citizens',
        sNameLC = 'GOALSS001TEXT',
        sDescLC = 'GOALSS002TEXT',
		checkFn = GoalData.citizens,
		nTarget = GoalData.TARGET_CITIZENS,
    },
	{
		sName = 'Matter',
		sNameLC = 'GOALSS003TEXT',
        sDescLC = 'GOALSS004TEXT',
		checkFn = GoalData.matter,
		nTarget = GoalData.TARGET_MATTER,
    },
	{
		sName = 'BuiltEverything',
		sNameLC = 'GOALSS005TEXT',
        sDescLC = 'GOALSS006TEXT',
		checkFn = GoalData.builtEverything,
		nTarget = GoalData.TARGET_ENVOBJECT_TYPES,
    },
	{
		sName = 'HostilesKilled',
		sNameLC = 'GOALSS007TEXT',
        sDescLC = 'GOALSS008TEXT',
		checkFn = GoalData.hostilesKilled,
		nTarget = GoalData.TARGET_HOSTILES_KILLED,
	},
	{
		sName = 'BaseTiles',
		sNameLC = 'GOALSS010TEXT',
        sDescLC = 'GOALSS011TEXT',
		checkFn = GoalData.baseTiles,
		nTarget = GoalData.TARGET_BASE_TILES,
	},
	{
		sName = 'MealsServed',
		sNameLC = 'GOALSS017TEXT',
        sDescLC = 'GOALSS018TEXT',
		checkFn = GoalData.mealsServed,
		nTarget = GoalData.TARGET_MEALS,
	},
	{
		sName = 'CuresResearched',
		sNameLC = 'GOALSS015TEXT',
        sDescLC = 'GOALSS016TEXT',
		checkFn = GoalData.curesResearched,
		nTarget = GoalData.TARGET_CURES,
	},
	{
		sName = 'AllTechs',
		sNameLC = 'GOALSS019TEXT',
        sDescLC = 'GOALSS020TEXT',
		checkFn = GoalData.allTechs,
		nTarget = GoalData.TARGET_TECHS,
	},
	{
		sName = 'HappyCitizens',
		sNameLC = 'GOALSS021TEXT',
        sDescLC = 'GOALSS022TEXT',
		checkFn = GoalData.happyCitizens,
		nTarget = GoalData.TARGET_HAPPY_CITIZENS,
	},
	{
		sName = 'BreachShipsDestroyed',
		sNameLC = 'GOALSS023TEXT',
        sDescLC = 'GOALSS024TEXT',
		checkFn = GoalData.breachShipsDestroyed,
		nTarget = GoalData.TARGET_BREACH_SHIPS,
	},
	{
		sName = 'AllPossessions',
		sNameLC = 'GOALSS025TEXT',
        sDescLC = 'GOALSS026TEXT',
		checkFn = GoalData.allPossessions,
		nTarget = GoalData.TARGET_POSSESSIONS,
	},
	{
		sName = 'RaidersConverted',
		sNameLC = 'GOALSS027TEXT',
        sDescLC = 'GOALSS028TEXT',
		checkFn = GoalData.raidersConverted,
		nTarget = GoalData.TARGET_RAIDERS_CONVERTED,
	},
	{
		sName = 'HostilesAsphyxiated',
		sNameLC = 'GOALSS029TEXT',
        sDescLC = 'GOALSS030TEXT',
		checkFn = GoalData.hostilesAsphyxiated,
		nTarget = GoalData.TARGET_HOSTILES_ASPHYXIATED,
	},
	{
		sName = 'HostilesKilledByTurrets',
		sNameLC = 'GOALSS035TEXT',
        sDescLC = 'GOALSS036TEXT',
		checkFn = GoalData.hostilesKilledByTurrets,
		nTarget = GoalData.TARGET_HOSTILE_TURRET_KILLS,
	},
	{
		sName = 'BodiesRefined',
		sNameLC = 'GOALSS031TEXT',
        sDescLC = 'GOALSS032TEXT',
		checkFn = GoalData.bodiesRefined,
		nTarget = GoalData.TARGET_BODIES,
	},
--[[
	{
		sName = 'HostilesFedToMonster',
		sNameLC = 'GOALSS033TEXT',
        sDescLC = 'GOALSS034TEXT',
		checkFn = GoalData.hostilesFedToMonster,
		nTarget = GoalData.TARGET_HOSTILE_MONSTER_KILLS,
	},
]]--
	{
		sName = 'FinalSiege',
		sNameLC = 'GOALSS037TEXT',
        sDescLC = 'GOALSS038TEXT',
		checkFn = GoalData.finalSiege,
		nTarget = 1,
	},
}

return GoalData
