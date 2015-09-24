local Class = require('Class')
local ImmigrationEvent = require('GameEvents.ImmigrationEvent')
local TraderEvent = Class.create(ImmigrationEvent)

local GameRules = require('GameRules')
local Event = require('GameEvents.Event')

TraderEvent.sEventType = 'traderEvents'
TraderEvent.bSkipAlert = false
TraderEvent.sAlertLC = 'ALERTS028TEXT'
TraderEvent.sFailureLC = 'ALERTS024TEXT'
TraderEvent.sDialogSet = 'traderEvents'
TraderEvent.DEFAULT_WEIGHT = 25.0
TraderEvent.nMinPopulation = 6
TraderEvent.nMaxPopulation = -1
TraderEvent.nMinTime = 60*12
TraderEvent.nMaxTime = 0

function TraderEvent.allowEvent( nPopulation, nElapsedTime)
	print("Checking if traderEvents is allowed ",
	      nPopulation > TraderEvent.nMinPopulation or GameRules.elapsedTime > TraderEvent.nMinTime)
	return nPopulation > TraderEvent.nMinPopulation or GameRules.elapsedTime > TraderEvent.nMinTime
end

function  TraderEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
	print("traderEvent queued")
	ImmigrationEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)

	tUpcomingEventPersistentState.bTrader = true

	TraderEvent._prerollTrader(rController, tUpcomingEventPersistentState)
end

function TraderEvent._prerollTrader( rController, tUpcomingEventPersistentState )
	tUpcomingEventPersistentState.tCharSpawnStats = require('EventController').rollRandomTrader()
	tUpcomingEventPersistentState.nNumSpawns = 1
end

return TraderEvent
