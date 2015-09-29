local Class = require('Class')
local Event = require('GameEvents.Event')
local EventData = require('GameEvents.EventData')
local ImmigrationEvent = require('GameEvents.ImmigrationEvent')
local HostileImmigrationEvent = Class.create(ImmigrationEvent)

local Docking = require('Docking')
local CharacterManager = require('CharacterManager')
local Character = require('Character')
local AlertEntry = require('UI.AlertEntry')
local GameRules = require('GameRules')
local Malady = require('Malady')
local MiscUtil = require('MiscUtil')

HostileImmigrationEvent.sEventType = 'hostileImmigrationEvents'
HostileImmigrationEvent.sAlertLC = 'ALERTS028TEXT'
HostileImmigrationEvent.sFailureLC = 'ALERTS024TEXT'
HostileImmigrationEvent.sDialogSet = 'hostileImmigrationEvents'
HostileImmigrationEvent.DEFAULT_WEIGHT = 15.0
HostileImmigrationEvent.nMinPopulation = 6
HostileImmigrationEvent.nMaxPopulation = -1
HostileImmigrationEvent.nMinTime = 60*12
HostileImmigrationEvent.nMaxTime = -1

function HostileImmigrationEvent.getSpawnLocationModifier()
    return Event.getPopulationMod() * Event.getHostilityMod(true)
end

function HostileImmigrationEvent.allowEvent(nPopulation, nElapsedTime)
    return nPopulation > HostileImmigrationEvent.nMinPopulation or GameRules.elapsedTime > HostileImmigrationEvent.nMinTime
end

function HostileImmigrationEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    ImmigrationEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)

    tUpcomingEventPersistentState.bHostile = true

    HostileImmigrationEvent._prerollRaiders(rController, tUpcomingEventPersistentState)
end

function HostileImmigrationEvent._prerollRaiders(rController, tUpcomingEventPersistentState)
    -- choose how many raiders, and how tuff
    local nDifficulty = tUpcomingEventPersistentState.nDifficulty
    tUpcomingEventPersistentState.tCharSpawnStats = require('EventController').rollRandomRaiders(nDifficulty,false)
    tUpcomingEventPersistentState.nNumSpawns = #tUpcomingEventPersistentState.tCharSpawnStats
end

function HostileImmigrationEvent._ignoreRefusal(tPersistentEventState)
    if tPersistentEventState.tModuleData and tPersistentEventState.tModuleData.bHostile then
        return math.random() > 0.33
    else
        return false
    end
end

function HostileImmigrationEvent.getModuleContentsDebugString(rController, tPersistentState)
    local s = "Challenge Lvls: "
    local s2 = nil
    local tAtkStances = {}
    for i=1,tPersistentState.nNumSpawns do
        if tPersistentState.tCharSpawnStats then
            s = s..tostring(tPersistentState.tCharSpawnStats[i].nChallengeLevel)..', '
        end
    end
    if tPersistentState.nNumMaladies > 0 and tPersistentState.tPrerolledMalady then
        s2 = Event.getMaladyDebugString(tPersistentState, tPersistentState.nNumMaladies)
    end
    return s .. " ", s2
end

return HostileImmigrationEvent
