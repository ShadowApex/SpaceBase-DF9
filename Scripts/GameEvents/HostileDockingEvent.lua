local Class = require('Class')
local ImmigrationEvent = require('GameEvents.ImmigrationEvent')
local DockingEvent = require('GameEvents.DockingEvent')
local Event = require('GameEvents.Event')
local HostileDockingEvent = Class.create(DockingEvent)

local GameRules = require('GameRules')
local Docking = require('Docking')
local DFUtil = require('DFCommon.Util')
local GenericDialog = require('UI.GenericDialog')
local DialogSets = require('DialogSets')
local Portraits = require('UI.Portraits')
local AlertEntry = require('UI.AlertEntry')
local CharacterManager = require('CharacterManager')
local MiscUtil = require('MiscUtil')

HostileDockingEvent.sEventType = 'hostileDockingEvents'

function HostileDockingEvent.getSpawnLocationModifier()
    return Event.getPopulationMod() * Event.getHostilityMod(true)
end

function HostileDockingEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    tUpcomingEventPersistentState.bHostile = true
    DockingEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
end

function HostileDockingEvent.getWeight()
    return 5.0
end

function HostileDockingEvent._ignoreRefusal(tPersistentEventState)
    return math.random() > 0.33
end

function HostileDockingEvent._getDialogSet()
    local sKey = 'ambiguous'
    if math.random() > .3 then
        sKey = 'hostile'
    end
    return DFUtil.arrayRandom(DialogSets['dockingEvents'][sKey])
end

return HostileDockingEvent
