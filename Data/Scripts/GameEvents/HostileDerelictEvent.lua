local Class = require('Class')
local Event = require('GameEvents.Event')
local EventData = require('GameEvents.EventData')
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
HostileDerelictEvent.DEFAULT_WEIGHT = 10.0
HostileDerelictEvent.nMinPopulation = 4
HostileDerelictEvent.nMaxPopulation = -1
HostileDerelictEvent.nMinTime = 10*60
HostileDerelictEvent.nMaxTime = -1
HostileDerelictEvent.bHostile = true
HostileDerelictEvent.nChanceObey = 0.00
HostileDerelictEvent.nChanceHostile = 1.00
HostileDerelictEvent.sExpMod = 'population'

function HostileDerelictEvent.getWeight(nPop,nElapsed,bForecast)
    if bForecast then
        return HostileDerelictEvent.DEFAULT_WEIGHT
    end

    local _,nPlayerRooms,nHiddenRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    local bAllowDerelict = nHiddenRooms < DerelictEvent.nMaxUndiscoveredRooms
    if bAllowDerelict then
        return HostileDerelictEvent.DEFAULT_WEIGHT
    end
    if nHiddenRooms > DerelictEvent.nMaxUndiscoveredRooms * .5 then
        return 6.0
    end
    return 0
end

function HostileDerelictEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    tUpcomingEventPersistentState.bHostile=HostileDerelictEvent.bHostile
    DerelictEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
end

return HostileDerelictEvent
