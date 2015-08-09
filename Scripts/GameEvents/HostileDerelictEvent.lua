local Class = require('Class')
local Event = require('GameEvents.Event')
local DerelictEvent = require('GameEvents.DerelictEvent')
local HostileDerelictEvent = Class.create(DerelictEvent)
local Base = require('Base')
local GameRules = require('GameRules')
local Docking = require('Docking')
local Room = require('Room')
local Character = require('Character')
local CharacterManager = require('CharacterManager')
local MiscUtil = require('MiscUtil')

HostileDerelictEvent.sEventType = 'hostileDerelictEvents'

function HostileDerelictEvent.getSpawnLocationModifier()
    return Event._getExpMod('derelict') * Event.getHostilityMod(true)
end

function HostileDerelictEvent.getWeight(nPop,nElapsed,bForecast)
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

function HostileDerelictEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    tUpcomingEventPersistentState.bHostile=true
    DerelictEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
end

return HostileDerelictEvent
