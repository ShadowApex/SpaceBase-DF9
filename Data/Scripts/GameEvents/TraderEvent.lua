local Class = require('Class')
local Event = require('GameEvents.Event')
local EventData = require('GameEvents.EventData')
local ImmigrationEvent = require('GameEvents.ImmigrationEvent')
local TraderEvent = Class.create(ImmigrationEvent)

local GameRules = require('GameRules')

TraderEvent.sEventType = 'traderEvents'
TraderEvent.bSkipAlert = false
TraderEvent.sAlertLC = 'ALERTS028TEXT'
TraderEvent.sFailureLC = 'ALERTS024TEXT'
TraderEvent.sDialogSet = 'traderEvents'
TraderEvent.DEFAULT_WEIGHT = 25.0

function TraderEvent.allowEvent( nPopulation, nElapsedTime)
	--print("Checking if traderEvents is allowed",nPopulation > 6 or GameRules.elapsedTime > 60*12)
	return nPopulation > 6 or GameRules.elapsedTime > 60*12
end

function  TraderEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
	--print("traderEvent queued")
	ImmigrationEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)

	tUpcomingEventPersistentState.bTrader = true

	TraderEvent._prerollTrader(rController, tUpcomingEventPersistentState)
end

function TraderEvent._prerollTrader( rController, tUpcomingEventPersistentState )
	tUpcomingEventPersistentState.tCharSpawnStats = require('EventController').rollRandomTrader()
	tUpcomingEventPersistentState.nNumSpawns = 1
end

return TraderEvent
