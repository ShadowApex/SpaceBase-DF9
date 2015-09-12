local Class = require('Class')
local Event = require('GameEvents.Event')
local DerelictEvent = Class.create(Event)
local Base = require('Base')
local GameRules = require('GameRules')
local Docking = require('Docking')
local Room = require('Room')
local Character = require('Character')
local CharacterManager = require('CharacterManager')
local MiscUtil = require('MiscUtil')

-- if there are at least this many undiscovered rooms, no more
-- new (non immigrant shuttle) ships will show up
DerelictEvent.nMaxUndiscoveredRooms = 15

DerelictEvent.sEventType = 'friendlyDerelictEvents'
DerelictEvent.sAlertLC = 'ALERTS023TEXT'
--DerelictEvent.sFailureLC = 'ALERTS024TEXT'
DerelictEvent.nCharactersToSpawn= { 1, 3 }
DerelictEvent.bSkipAlert = true
DerelictEvent.nAlertPriority = 0

function DerelictEvent.getSpawnLocationModifier()
    return Event._getExpMod('derelict') * Event.getHostilityMod(false)
end

function DerelictEvent.getWeight(nPopulation, nElapsedTime, bForecast)
    if nPopulation >= g_nPopulationCap then
        return 0
    end
    if bForecast then return 10.0 end
    local _,nPlayerRooms,nHiddenRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    local bAllowDerelict = nHiddenRooms < DerelictEvent.nMaxUndiscoveredRooms
    if bAllowDerelict then
        return 10.0
    end
    if nHiddenRooms > DerelictEvent.nMaxUndiscoveredRooms * .5 then
        return 6.0
    end
    return 0
end

function DerelictEvent.allowEvent(nPopulation, nElapsedTime)
    return (nPopulation > 4 or GameRules.elapsedTime > 10*60)
end

function DerelictEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    Event.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)

    Event._attemptDock(rController, tUpcomingEventPersistentState)
end

function DerelictEvent.preExecuteSetup(rController, tUpcomingEventPersistentState)
    Event.preExecuteSetup(rController, tUpcomingEventPersistentState)

    local _,nPlayerRooms,nHiddenRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    local bAllowDerelict = nHiddenRooms < DerelictEvent.nMaxUndiscoveredRooms
    if not bAllowDerelict then
        Print(TT_Info, 'EventController: at undiscovered room limit, no derelicts')
        return false
    end
    local bPopcapFail = not tUpcomingEventPersistentState.bHostile and CharacterManager.getOwnedCitizenPopulation() >= g_nPopulationCap
    if bPopcapFail then
        Print(TT_Info, 'EventController: at undiscovered room limit, no derelicts')
        return false
    end

    -- check if the module data from onqueue is still valid
    return Event._verifyDockingData(rController, tUpcomingEventPersistentState)
end


function DerelictEvent.tick(rController, dT, tPersistentState, tTransientState)
    Docking.spawnModule(tPersistentState)
    local wx,wy = g_World._getWorldFromTile(tPersistentState.tx, tPersistentState.ty)
    Base.eventOccurred(Base.EVENTS.EventAlert,{wx=wx,wy=wy,sLineCode="ALERTS032TEXT", tPersistentData=tPersistentState, nPriority = DerelictEvent.nAlertPriority})
    GameRules.nLastNewShip = GameRules.elapsedTime
    return true
end

return DerelictEvent
