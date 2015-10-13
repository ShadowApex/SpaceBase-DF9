local Class = require('Class')
local Event = require('GameEvents.Event')
local EventData = require('GameEvents.EventData')
local ImmigrationEvent = require('GameEvents.ImmigrationEvent')
local DockingEvent = require('GameEvents.DockingEvent')
local HostileDockingEvent = Class.create(DockingEvent)

local GameRules = require('GameRules')
local Docking = require('Docking')
local DFUtil = require('DFCommon.Util')
local GenericDialog = require('UI.GenericDialog')
local Portraits = require('UI.Portraits')
local AlertEntry = require('UI.AlertEntry')
local CharacterManager = require('CharacterManager')
local MiscUtil = require('MiscUtil')

HostileDockingEvent.sEventType = 'hostileDockingEvents'
HostileDockingEvent.DEFAULT_WEIGHT = 5.0
HostileDockingEvent.nMinPopulation = 4
HostileDockingEvent.nMaxPopulation = -1
HostileDockingEvent.nMinTime = 60*10
HostileDockingEvent.nMaxTime = -1
HostileDockingEvent.bHostile = true
HostileDockingEvent.nChanceObey = 0.33
HostileDockingEvent.nChanceHostile = 0.66
HostileDockingEvent.sExpMod = 'population'

function HostileDockingEvent.getSpawnLocationModifier()
    local hostileMultiplier = 1
    if HostileDockingEvent.nChanceObey + HostileDockingEvent.nChanceHostile == 0 then
        hostileMultiplier = 1
    elseif HostileDockingEvent.bHostile then
        hostileMultiplier = 1/Event._getExpMod('hostility')
    else
        hostileMultiplier = Event._getExpMod('hostility')
    end
    return Event._getExpMod(HostileDockingEvent.sExpMod) * hostileMultiplier
end

return HostileDockingEvent
