local Docking=require('Docking')
local GameRules=require('GameRules')
local Character=require('Character')
local Base = require('Base')
local Inventory = require('Inventory')
local Room=require('Room')
local Renderer=require('Renderer')
local CharacterManager=require('CharacterManager')
local DFMath = require('DFCommon.Math')
local DFGraphics = require('DFCommon.Graphics')
local SoundManager = nil
local MiscUtil = require('MiscUtil')
local Gui = require('UI.Gui')
local Delegate = require('DFMoai.Delegate')
local ModuleData = require('ModuleData')
local Malady = require('Malady')
local AutoSave=require('AutoSave')

local EventController= {}
g_EventController = EventController
-- increment this when you need a completely new forecast generated from scratch
-- because old events do not contain required data that you don't want to make
-- up.
EventController.nSaveVersion = 1.6

EventController.dForecastGenerated = Delegate.new()

-- number of events to forecast into the future
EventController.nEventForecastMax = 15
-- number of previous events to retain details of in the save file
EventController.nPrevEventsCount = 10

-- final siege after 4 hours
EventController.nFinalSiegeTime = 60 * 60 * 6
-- Cap playtime at 8 hours with regard to difficulty and various curves
EventController.nMaxPlaytime = 60 * 60 * 16

EventController.tFirstEventTimeRange = { 400, 440 }
EventController.tAlertTimeRange = { 45, 45 }

EventController.RENDER_LAYER = 'WorldFloor'
EventController.RENDER_LAYER_BG = 'WorldFloor' --'WorldBackground'

-- all event types that can occur in-game must be placed here.
local ImmigrationEvent = require('GameEvents.ImmigrationEvent')
local DerelictEvent = require('GameEvents.DerelictEvent')
local HostileImmigrationEvent = require('GameEvents.HostileImmigrationEvent')
local DockingEvent = require('GameEvents.DockingEvent')
local BreachingEvent = require('GameEvents.BreachingEvent')
local MeteorEvent = require('GameEvents.MeteorEvent')
local HostileDockingEvent = require('GameEvents.HostileDockingEvent')
local HostileDerelictEvent = require('GameEvents.HostileDerelictEvent')
local CompoundEvent = require('GameEvents.CompoundEvent')
--local TraderEvent = require('GameEvents.TraderEvent')
EventController.tEventClasses = {
    [ImmigrationEvent.sEventType]         = ImmigrationEvent,
    [HostileImmigrationEvent.sEventType]  = HostileImmigrationEvent,
    [BreachingEvent.sEventType]           = BreachingEvent,
    [DerelictEvent.sEventType]            = DerelictEvent,
    [DockingEvent.sEventType]             = DockingEvent,
    [MeteorEvent.sEventType]              = MeteorEvent,
    [HostileDockingEvent.sEventType]      = HostileDockingEvent,
    [HostileDerelictEvent.sEventType]     = HostileDerelictEvent,
    [CompoundEvent.sEventType]            = CompoundEvent,
    --[TraderEvent.sEventType] = TraderEvent,
}

--- Initializes the event controller.
function EventController.init()
    EventController.nEventsThisPlaySession = 0

    EventController.hideMeteorStrikeIndicator()
    SoundManager = require('SoundManager')
    Docking.init()
    EventController.fromSaveData({})
end

--- Calculate modifiers for each event type based on base spawn loc in galaxy.
function EventController.setBaseSeeds()
    local tLandingZone = GameRules.getLandingZone()
    EventController.tS.tSpawnModifiers = {}
    local nTotal = 0.0
    local nClasses = 0
    for _, rClass in pairs(EventController.tEventClasses) do
        local nMod = rClass.getSpawnLocationModifier()
        EventController.tS.tSpawnModifiers[rClass.sEventType] = nMod
        -- While storing our modifiers, also calc a weighted average of all event likelihoods.
        -- Use that to scale event frequency.
        local nWeight = rClass.getWeight(25, 60*60*2, true)
        nTotal = nTotal + nMod * nWeight
        nClasses = nClasses + nWeight
        print('EVENTCONTROLLER.LUA:     ',rClass.sEventType,nMod,'weight:',nWeight)
    end
    print('EVENTCONTROLLER.LUA: total',nTotal,'out of',nClasses)
    local nAvg = nTotal / nClasses
    -- perfectly average is about

    -- We're probably looking at something around nMinAvg - nMaxAvg
    -- We want to map this to a time-between-events of between 600 seconds and 135 seconds, average
    -- around... 200 seconds.

    -- These averages are just what I found to be rough bounds while clicking around the map.
    -- An "average" spot, reasonably proximal warpgate etc., scores around 134, which comes out to 1/3 of the range.
    local nMinAvg = 78/130
    local nMaxAvg = 244/130
    local nRange = nMaxAvg-nMinAvg

    nAvg = math.min(math.max(nMinAvg,nAvg),nMaxAvg)
    nAvg = (nAvg-nMinAvg)/nRange -- remap to 0-1
    nAvg = 1-nAvg
    nAvg = nAvg*nAvg*nAvg*nAvg -- curve it out! still 0-1, but the av
    local nTimeBetween = 135 + nAvg * 465
    print('EVENTCONTROLLER.LUA: avg time between events',nTimeBetween)
    EventController.tS.tSpawnModifiers.nAvgTimeBetweenEvents = nTimeBetween
end

function EventController.getTeamForEvent(eFactionBehavior)

    if EventController.tCurrentEventPersistentState then
        if eFactionBehavior == Character.FACTION_BEHAVIOR.EnemyGroup and EventController.tCurrentEventPersistentState.nEnemyFactionTeam then
            return EventController.tCurrentEventPersistentState.nEnemyFactionTeam
        end
        if eFactionBehavior == Character.FACTION_BEHAVIOR.Friendly and EventController.tCurrentEventPersistentState.nFriendlyFactionTeam then
            return EventController.tCurrentEventPersistentState.nFriendlyFactionTeam
        end
        --Trader Stuff
        --if eFactionBehavior == Character.FACTION_BEHAVIOR.Trader and EventController.tCurrentEventPersistentState.nTraderFactionTeam then
        --    return EventController.tCurrentEventPersistentState.nTraderFactionTeam
        --end
    end
    local nTeam = Base.createNewTeamID(eFactionBehavior)
    if EventController.tCurrentEventPersistentState then
        if eFactionBehavior == Character.FACTION_BEHAVIOR.EnemyGroup then
            EventController.tCurrentEventPersistentState.nEnemyFactionTeam = nTeam
        end
        if eFactionBehavior == Character.FACTION_BEHAVIOR.Friendly then
            EventController.tCurrentEventPersistentState.nFriendlyFactionTeam = nTeam
        end
        --Trader Stuff
        --if eFactionBehavior == Character.FACTION_BEHAVIOR.Trader then
        --    EventController.tCurrentEventPersistentState.nTraderFactionTeam = nTeam
        --end
    end
    return nTeam
end

function EventController._portOldSaves(tSaveData)
    if not tSaveData.nSaveVersion or tSaveData.nSaveVersion < EventController.nSaveVersion then
        tSaveData = {}
        return tSaveData
    end

    local updateEventSave = function(t)
        if t and t.tModuleData then
            t.sModuleName=t.tModuleData.sModuleName
            t.sSetName=t.tModuleData.sSetName
            t.sModuleEventName = t.tModuleData.sModuleEventName
            if not Docking.tLoadedModules[t.sSetName] then
                -- Bug in old saves saved off the module name as the set name. Try to dig up the correct set name.
                local tSets={'hostileDerelictEvents','hostileDockingEvents','friendlyDerelictEvents','friendlyDockingEvents'}
                for _,sSet in ipairs(tSets) do
                    if Docking.tLoadedModules[sSet][t.sModuleName] then
                        t.sSetName = sSet
                        break
                    end
                end
            end
            t.tModuleData = nil
        end
        if t and t.tRaiderChallengeLevels then
            return false
        end
        return true
    end

    if not updateEventSave(tSaveData.tPrevEventData) then tSaveData.tPrevEventData = nil end
    if not updateEventSave(tSaveData.tNextEventData) then tSaveData.tNextEventData = nil end
    for i,v in ipairs(tSaveData.tEventForecast) do
        if not updateEventSave(v) then
            table.remove(tSaveData.tEventForecast,i)
        end
    end

    return tSaveData
end

--- Restores state of the EventController from saved data.
-- @param tSaveData the data to load from
function EventController.fromSaveData(tSaveData)
    EventController.fnOngoingEventTick = nil
    EventController.tCurrentEventPersistentState = nil

    if tSaveData then
        tSaveData = EventController._portOldSaves(tSaveData)
    end

    EventController.tS = tSaveData or {}
    EventController.tS.nSaveVersion = EventController.nSaveVersion

    local defaults = {
        tEventForecast = {},
        tPrevEventInfo = {},
        tSpawnModifiers = {},
    }

    local bRegenSeeds = EventController.tS.tSpawnModifiers == nil
    if not bRegenSeeds then
        for _, rClass in pairs(EventController.tEventClasses) do
            if not EventController.tS.tSpawnModifiers[rClass.sEventType] then
                bRegenSeeds = true
                break
            end
        end
    end

    for k,v in pairs(defaults) do
        if not EventController.tS[k] then EventController.tS[k] = v end
    end

    if bRegenSeeds then
        EventController.setBaseSeeds()
    end

    -- determine the next event unique id
    if EventController.tS.tEventForecast and #EventController.tS.tEventForecast > 0 then
        local n = #EventController.tS.tEventForecast
        EventController.stNextEventID = math.max(
            EventController.stNextEventID or 1,
            (EventController.tS.tEventForecast[n].nUniqueID or 1) + 1)
    elseif EventController.tS.tNextEventData then
        EventController.stNextEventID = math.max(
            EventController.stNextEventID or 1,
            (EventController.tS.tNextEventData.nUniqueID or 1) + 1)
    else
        EventController.stNextEventID = 1
    end

    -- forecast if necessary!
    if #EventController.tS.tEventForecast == 0 then
        EventController.generateEventForecast()
    end
    if EventController.tS.tNextEventData == nil then
        EventController.tS.tNextEventData = table.remove(EventController.tS.tEventForecast, 1)
        EventController.bAlertedNextEvent = false
    end
    if #EventController.tS.tEventForecast == 0 then
        EventController.generateEventForecast()
    end

    if EventController.tS.tNextEventData then
        EventController.tS.tNextEventData.bAlertedNextEvent = false
    end
end

function EventController.getSaveData()
    return EventController.tS
end

function EventController.DBG_forceForecastRegen()
    if EventController.tS and EventController.tS.tEventForecast then
        EventController.generateEventForecast()
        EventController._eventCompleted({sEventType = 'CompoundEvent'})
    end
end

function EventController.DBG_forceNextEvent()
    EventController._forceNextEvent()
end

function EventController._forceNextEvent()
    if EventController.tS and EventController.tS.tNextEventData then
        local nDelta = 0
        local nOldStart = EventController.tS.tNextEventData.nStartTime
        EventController.tS.tNextEventData.nStartTime = GameRules.elapsedTime + EventController.tAlertTimeRange[2]
        EventController.tS.tNextEventData.nAlertTime = GameRules.elapsedTime
        EventController.tS.tNextEventData.bDebugQueued = true
        nDelta = nOldStart - EventController.tS.tNextEventData.nStartTime

        if nDelta > 0 then
            for idx, tEvent in ipairs(EventController.tS.tEventForecast) do
                tEvent.nStartTime = tEvent.nStartTime - nDelta
                tEvent.nAlertTime = tEvent.nStartTime - math.random(EventController.tAlertTimeRange[1],EventController.tAlertTimeRange[2])
            end
        end
    end
end

function EventController.DBG_forceQueue(sEventName, bDBGForceHostile, nDelay)
    nDelay = nDelay or 0

    local nStartTime = GameRules.elapsedTime + nDelay

    local nAlert = nStartTime - math.random(EventController.tAlertTimeRange[1],EventController.tAlertTimeRange[2])
    EventController.tS.tNextEventData = {
        sEventType = sEventName,
        nStartTime = nStartTime,
        nAlertTime = nAlert,
        nUniqueID = EventController.stNextEventID,
    }
    -- Increment the controller's unique id counter
    EventController.stNextEventID = EventController.stNextEventID + 1
    EventController.tS.tNextEventData.bDBGForceHostile = bDBGForceHostile
    EventController.tS.tNextEventData.bAlertedNextEvent = false

    EventController.tEventClasses[sEventName].onQueue(
        EventController, EventController.tS.tNextEventData,
        CharacterManager.getOwnedCitizenPopulation(), nStartTime)

    return EventController.tS.tNextEventData
end

function EventController._failed(tNextEventState, sOptionalFailMsg)
    tNextEventState.nFailures = (tNextEventState.nFailures and tNextEventState.nFailures + 1) or 1

    if tNextEventState.nFailures > EventController.tEventClasses[tNextEventState.sEventType].nAllowedSetupFailures then
        if sOptionalFailMsg then
            Base.eventOccurred(Base.EVENTS.EventFailure, {sLineCode=sOptionalFailMsg, tPersistentData=tNextEventState})
        end
        tNextEventState.bFailed=true
        tNextEventState.sFailureMessage=sOptionalFailMsg
        EventController._eventCompleted(tNextEventState)
    end
end

--- Attempt to set up the next event to start execution.
-- @param tNextEventData the persistent state table for the next event
function EventController.attemptExecuteEvent(tNextEventData)
    local rEventClass = EventController.tEventClasses[tNextEventData.sEventType]

    local tTransientState = {}
    -- pre execute setup can fail, e.g. cannot find suitable docking point.
    local bSuccess, sFailMsg = rEventClass.preExecuteSetup(EventController, tNextEventData, tTransientState)
    if bSuccess then
        if GameRules.elapsedTime - AutoSave.nTimeSinceLastSave > 45 then
            AutoSave.saveGame()
        end

        -- handle to the event tick func
        EventController.fnOngoingEventTick = rEventClass.tick
        -- Events have a persistent state and a transient state. Persistent
        -- state is placed in the save file and has the core information about
        -- the event, like type name, spawn position(s), etc
        EventController.tCurrentEventPersistentState = tNextEventData
        -- Transient state does not get put in the save file, so it should
        -- contain either objects that cannot be easily serialized, or state
        -- that we want to reset if the player exits during the event.
        EventController.tCurrentEventTransientState = tTransientState
        -- this event is for sure going to exec now, so increment counter
        EventController.nEventsThisPlaySession = EventController.nEventsThisPlaySession + 1
    else
        EventController._failed(tNextEventData, sFailMsg)
    end
end

---
-- @param id the event's unique ID
function EventController.clearCurrentEventFromSaveTable(id)
    if EventController.tS.tNextEventData and EventController.tS.tNextEventData.nUniqueID == id then
        EventController.tS.tNextEventData = nil
    else
        if EventController.tS.tNextEventData and EventController.tS.tNextEventData.sEventType == 'CompoundEvent' then
        else
            Print(TT_Warning, 'EVENTCONTROLLER.LUA: not clearing event id',id)
            --assertdev(false)
            EventController.tS.tNextEventData = nil
        end
    end
end

function EventController._eventCompleted(tEventPersistentState)
    EventController.clearCurrentEventFromSaveTable(tEventPersistentState.nUniqueID)
    local rClass = EventController.tEventClasses[tEventPersistentState.sEventType]
    if rClass then
        rClass.cleanup(EventController, tEventPersistentState)

        -- save out pertinent info about the event
        while #EventController.tS.tPrevEventInfo >= EventController.nPrevEventsCount do
            -- pop off very old events if we are at capacity of prev events table
            table.remove(EventController.tS.tPrevEventInfo, 1)
        end
        local tPrevEventInfo = {
            sEventType = tEventPersistentState.sEventType,
            tx = tEventPersistentState.tx,
            ty = tEventPersistentState.ty,
            nCompletionTime = GameRules.elapsedTime
        }
        table.insert(EventController.tS.tPrevEventInfo, tPrevEventInfo)
    end

    EventController.fnOngoingEventTick = nil
    EventController.tCurrentEventPersistentState = nil
    EventController.tCurrentEventTransientState = nil

    -- generate more current/relevant events.
    -- For debug purposes, allow that queue to stay static for forced events.
    if not tEventPersistentState.bDebugQueued then
        EventController.generateEventForecast()
    end
    -- pop event off of the forecast list for the next event
    EventController.tS.tNextEventData = table.remove(EventController.tS.tEventForecast, 1)
    if EventController.tS.tNextEventData then EventController.tS.tNextEventData.bAlertedNextEvent = false end

    -- in case of silent failures, try out another event immediately.
    if tEventPersistentState.bFailed and not tEventPersistentState.sFailureMessage then
        EventController._forceNextEvent()
    end
end

--- Begins a camera movement towards the given location.
-- Creates a tCutscene table to track the animation progress.
-- @param tx Coordinate of location to move camera focus
-- @param ty Coordinate of location to move camera focus
function EventController.initCameraMove(tx,ty)
    local tCutscene={}
    local rCamera = Renderer.getGameplayCamera()
    tCutscene.xEnd,tCutscene.yEnd = g_World._getWorldFromTile(tx,ty)
    tCutscene.xStart,tCutscene.yStart,tCutscene.zStart=rCamera:getLoc()
    local dx,dy = tCutscene.xEnd-tCutscene.xStart,tCutscene.yEnd-tCutscene.yStart
    tCutscene.dx,tCutscene.dy=dx,dy
    tCutscene.nDist = math.sqrt(dx*dx+dy*dy)+1
    tCutscene.nDuration = math.max(0.5, math.min(1.5, tCutscene.nDist / 5000))
    tCutscene.nElapsed = 0
    tCutscene.t = 0
    return tCutscene
end

--- Moves the camera an increment towards the new location.
-- Updates the tCutscene object accordingly.
-- @param dt time delta for the move
-- @param tCutscene
function EventController.tickCamera(dt,tCutscene)
    tCutscene.nElapsed=tCutscene.nElapsed+dt
    local t = math.min(tCutscene.nElapsed / tCutscene.nDuration, 1)
    local newX,newY =  DFMath.lerp(tCutscene.xStart, tCutscene.xEnd, t),
    DFMath.lerp(tCutscene.yStart, tCutscene.yEnd, t)
    GameRules.setCameraLoc(newX,newY,tCutscene.zStart)
    tCutscene.t = t
    return t == 1
end

function EventController._doAlert(tEventData)
    local rNextEventClass = EventController.tEventClasses[tEventData.sEventType]

    if rNextEventClass.preAlertSetup then
        if not rNextEventClass.preAlertSetup(EventController, tEventData) then
            EventController._failed(tEventData)
            return false
        end
    end
    if not rNextEventClass.bSkipAlert then
        EventController.tEventClasses[tEventData.sEventType].onAlertShown(EventController, tEventData)
        local wx, wy = nil,nil
        if tEventData.tx then
            wx, wy = g_World._getWorldFromTile(tEventData.tx, tEventData.ty)
        end
        Base.eventOccurred(Base.EVENTS.EventAlert,
                           {
                               sLineCode = rNextEventClass.sAlertLC,
                               tPersistentData = tEventData,
                               nPriority = rNextEventClass.nAlertPriority,
                               wx=wx,wy=wy,
                           })
    end
    return true
end

--- Trigger per-tick event activities.
-- This operates event execution, alerts, and event setup
-- @param dt time delta
function EventController.onTick(dt)
    -- pulse meteor indicator
    -- TODO generalize this into a table of sprites needed by the event manager,
    -- not just a specific indicator sprite for a single event
    if EventController.rMeteorIndicator then
        local r,g,b = unpack(Gui.RED)
        local a = math.abs(math.sin(GameRules.elapsedTime * 4)) / 2 + 0.5
        r,g,b = r*a, g*a, b*a
        EventController.rMeteorIndicator:setColor(r, g, b)
    end

    if CharacterManager.getOwnedCitizenPopulation() > 0 then
        if EventController.fnOngoingEventTick then
            if EventController.fnOngoingEventTick(EventController, dt, EventController.tCurrentEventPersistentState, EventController.tCurrentEventTransientState) then
                EventController._eventCompleted(EventController.tCurrentEventPersistentState)
            end
        elseif EventController.tS.tNextEventData then
            local tNextEvent = EventController.tS.tNextEventData
            local rNextEventClass = EventController.tEventClasses[EventController.tS.tNextEventData.sEventType]
            if GameRules.elapsedTime >= EventController.tS.tNextEventData.nStartTime then
                EventController.attemptExecuteEvent(EventController.tS.tNextEventData)
            elseif not EventController.tS.tNextEventData.bAlertedNextEvent and GameRules.elapsedTime > EventController.tS.tNextEventData.nAlertTime then
                if EventController._doAlert(EventController.tS.tNextEventData) then
                    EventController.tS.tNextEventData.bAlertedNextEvent = true
                end
            end
            if tNextEvent == EventController.tS.tNextEventData and not EventController.tS.tNextEventData.bFailed and GameRules.elapsedTime < EventController.tS.tNextEventData.nStartTime and rNextEventClass.preExecuteTick then
                rNextEventClass.preExecuteTick(EventController,EventController.tS.tNextEventData)
            end
        else
            Trace(TT_Error, "No next event ready?")
            assert(false)
        end
    end
end

function EventController._getNextEventTimeDelta()
    local nElapsedTime = math.min(GameRules.elapsedTime, EventController.nMaxPlaytime)
    local x = nElapsedTime / EventController.nMaxPlaytime

    -- this is a curve that is used to get a time by weighting between min and max
    local alpha = 1.0 - (0.5 + 0.54 * x * math.sin(6.0 * math.pi * x))
    alpha = math.max(0, math.min(1, alpha))

    local t

    local nTimeBetween = EventController.tS.tSpawnModifiers.nAvgTimeBetweenEvents
    if not nTimeBetween then
        local tBetweenEventTimeRange = { 100, 240 }
        t = tBetweenEventTimeRange[1] * alpha +
            tBetweenEventTimeRange[2] * (1.0 - alpha) +
            math.random(-30, 30)
    else
        local nMin = .6 * nTimeBetween
        local nMax = 1.4 * nTimeBetween
        t = nMin * alpha +
            nMax * (1.0 - alpha) +
            math.random(-20,20)
    end

    return t
end

function EventController.DBG_fakeLateForecast()
    EventController.tS.tEventForecast = {}
    if #EventController.tS.tPrevEventInfo == 0 then
        table.insert(EventController.tS.tPrevEventInfo, {})
    end
    EventController.generateEventForecast(30,60*60*2)
    print("EVENTCONTROLLER.LUA: "..EventController.getForecastDebugText())
end

--- Create upcoming events
-- @param nForcePop population level to use for estimation calculations
-- @param nForceTime extra time delta for estimation calculations
function EventController.generateEventForecast(nForcePop,nForceTime)
    EventController.tS.tEventForecast = {}

    -- disallow 4 same events in a row
    local nAllowedConsecutiveEvents = 3
    local nConsecutiveEvents = 1

    -- these are passed into the onQueue function of the events for difficulty
    local nPopulationDeltaEstimate = nForcePop or CharacterManager.getOwnedCitizenPopulation()
    local nTimeDeltaEstimate = nForceTime or 0

    for i=1,EventController.nEventForecastMax do
        -- how much time between this event and previous?
        local nEventTimeDelta = EventController._getNextEventTimeDelta()
        -- we have a special time for first event ever
        if i == 1 and #EventController.tS.tPrevEventInfo == 0 then
            nEventTimeDelta = math.random(EventController.tFirstEventTimeRange[1],EventController.tFirstEventTimeRange[2])
        end

        -- produce game state estimates that will affect difficulty weighting
        local nPopulationEstimate = nPopulationDeltaEstimate
        local nTimeEstimate = GameRules.elapsedTime + nTimeDeltaEstimate + nEventTimeDelta

        -- generate weights of the various event types
        local tWeights = {}
        local nCount = 0
        for sEventType, rClass in pairs(EventController.tEventClasses) do
            if (nConsecutiveEvents < 3 or (i > 1 and sEventType ~= EventController.tS.tEventForecast[i-1].sEventType))
            and rClass.allowEvent(nPopulationEstimate, nTimeEstimate) then

                if rClass.DEFAULT_WEIGHT then
                    weight = rClass.DEFAULT_WEIGHT
                else
                    weight = rClass.getWeight(nPopulationEstimate, nTimeEstimate)
                end
                --print('weight for',sEventType,'is',weight)
                tWeights[sEventType] = weight * EventController.tS.tSpawnModifiers[sEventType]
                nCount = nCount + 1
            end
        end
        if nCount == 0 then
            tWeights[ImmigrationEvent.sEventType] = 1
            nCount = 1
        end

        local sNextEventType = MiscUtil.weightedRandom(tWeights)

        if i > 1 and sNextEventType == EventController.tS.tEventForecast[i-1].sEventType then
            nConsecutiveEvents = nConsecutiveEvents + 1
        else
            nConsecutiveEvents = 1
        end

        -- create a table to depict this event's persistent state
        local tEventData = {
            sEventType = sNextEventType,
            nStartTime = nTimeEstimate,
            nAlertTime = nTimeEstimate - math.random(EventController.tAlertTimeRange[1],EventController.tAlertTimeRange[2]),
            nUniqueID = EventController.stNextEventID,
        }

        -- Increment the controller's unique id counter
        EventController.stNextEventID = EventController.stNextEventID + 1

        -- prep the persistent state with attributes specific to the event type
        EventController.tEventClasses[sNextEventType].onQueue(
            EventController,
            tEventData,
            nPopulationEstimate,
            nTimeEstimate)

        -- push onto forecast list
        table.insert(EventController.tS.tEventForecast, tEventData)

        -- update estimates used by weighting and event setup
        if sNextEventType == ImmigrationEvent.sEventType then
            nPopulationDeltaEstimate = nPopulationDeltaEstimate + tEventData.nNumSpawns
        elseif sNextEventType == DockingEvent.sEventType
        or sNextEventType == DerelictEvent.sEventType then
            if tEventData.bValidDockingData then
                for _, sLoc in pairs(tEventData.tCrewData) do
                    nPopulationDeltaEstimate = nPopulationDeltaEstimate + 1
                end
            end
        elseif sNextEventType == HostileDockingEvent.sEventType
            or sNextEventType == HostileDerelictEvent.sEventType
            or sNextEventType == HostileImmigrationEvent.sEventType
        or sNextEventType == CompoundEvent.sEventType then
            nPopulationDeltaEstimate = nPopulationDeltaEstimate - 1
        end
        nTimeDeltaEstimate = nTimeDeltaEstimate + nEventTimeDelta
    end

    EventController.dForecastGenerated:dispatch()
end

--- Draw the meteor_highlight sprite at given location
-- @param tx Coordinate to draw meteor highlight
-- @param ty Coordinate to draw meteor highlight
function EventController.showMeteorStrikeIndicator(tx, ty)
    local p = MOAIProp.new()
    local spriteSheet = DFGraphics.loadSpriteSheet('UI/UIMisc')
    p:setDeck(spriteSheet)
    local idx = spriteSheet.names['meteor_highlight']
    p:setIndex(idx)
    DFGraphics.alignSprite(spriteSheet, idx, "center", "center")
    p:setColor(unpack( Gui.RED ))
    local r = spriteSheet.rects[idx]
    local wx,wy,wz = g_World._getWorldFromTile(tx, ty)
    -- scale element to size of meteor
    local w,h = r.origWidth, r.origHeight
    local nScale = MeteorEvent.METEOR_STRIKE_RADIUS / w
    nScale = nScale * 1.2
    p:setScl(nScale, nScale)
    p:setLoc(wx, wy, wz)
    Renderer.getRenderLayer('Cursor'):insertProp(p)
    EventController.rMeteorIndicator = p
end

--- Removes the meteor indicator.
function EventController.hideMeteorStrikeIndicator()
    if not EventController.rMeteorIndicator then
        return
    end
    Renderer.getRenderLayer('Cursor'):removeProp(EventController.rMeteorIndicator)
    EventController.rMeteorIndicator = nil
    EventController.tMeteorEventIndicated = nil
end

function EventController.rollRandomRaiders(nDifficulty, bAllowKillbots)
    -- choose how many raiders, and how tuff
    local nRaiders = 1
    if nDifficulty > .4 then
        nRaiders = math.random(1,3)
    elseif nDifficulty > .2 then
        nRaiders = math.random(1,2)
    end

    -- slightly nerf each raider's difficulty for multiple spawns
    if nRaiders > 2 then
        nDifficulty = nDifficulty * .75
    elseif nRaiders > 1 then
        nDifficulty = nDifficulty * .85
    end


    local tCharSpawnStats = {}
    local Event=require('GameEvents.Event')
    -- difficulty of each raider is difficulty of event +/- 15%
    for i=1,nRaiders do
        tCharSpawnStats[i] =
            {
                nChallengeLevel = Event.getChallengeLevel(nDifficulty),
                sName = 'Raider',
                nJob = Character.RAIDER
            }

        if tCharSpawnStats[i].nChallengeLevel > .75 and bAllowKillbots and math.random() > .5 then
            tCharSpawnStats[i].nRace = Character.RACE_KILLBOT
            tCharSpawnStats[i].sName = 'Kill Bot'
        end
    end
    return tCharSpawnStats
end

function EventController.rollRandomTrader( )
    local Event=require('GameEvents.Event')
    tCharSpawnStats = {
        {
            sName = 'Trader',
            nJob = Character.TRADER,
        },
    }
    return tCharSpawnStats
end


--- Used by docking and derelict events that spawn a module.
function EventController.spawnModuleEntities(tEventData, tModuleData, tTeams)
    local tCrewData = tEventData.tCrewData
    local tObjectData = tEventData.tObjectData
    local tMaladyData = tEventData.tPrerolledMalady
    if not tModuleData or not (tCrewData or tObjectData) then
        return
    end
    local sEventType = tEventData.sEventType

    local Spawner = require('EnvObjects.Spawner')
    local EnvObject = require('EnvObjects.EnvObject')
    local ShipModules = require('ModuleData')
    local Pickup = require('Pickups.Pickup')
    local Base = require('Base')

    local tLocs = Spawner.getAllOnTeam(tTeams.nDefaultTeam)
    if not tLocs then
        return
    end

    local fnGetTeam = function(tSpawnData,tTeams)
        -- Use the default team if it's compatible with the spawn data's specified faction behavior.
        -- Otherwise, grab/create a team compatible with that faction behavior.
        local nTeam = tTeams.nDefaultTeam
        if tSpawnData.nFactionBehavior and tSpawnData.nFactionBehavior ~= tTeams.nDefaultFactionBehavior then
            if not tTeams[tSpawnData.nFactionBehavior] then
                tTeams[tSpawnData.nFactionBehavior] = Base.createNewTeamID(tSpawnData.nFactionBehavior)
            end
            nTeam = tTeams[tSpawnData.nFactionBehavior]
        end
        return nTeam
    end

    -- spawn crew and objects from the module
    local tSpawnTypes = {
        crew = tCrewData, objects = tObjectData
    }
    for sDataType, tCrewOrObjectDataTable in pairs(tSpawnTypes) do
        -- spawnData has been prerolled
        for sLocName, spawnData in pairs(tCrewOrObjectDataTable) do
            if tLocs[sLocName] then
                if sDataType == "crew" then
                    local tData = {}
                    local tCopiedTables={'tStatus','tStats','tNeeds',}
                    for _,tblName in ipairs(tCopiedTables) do
                        if spawnData[tblName] then
                            tData[tblName] = {}
                            for k,v in pairs(spawnData[tblName]) do
                                tData[tblName][k] = v
                            end
                        end
                    end
                    tData.x,tData.y = tLocs[sLocName]:getLoc()
                    local tx,ty = g_World._getTileFromWorld(tData.x,tData.y)
                    if g_World._getTileValue(tx,ty) == g_World.logicalTiles.SPACE then
                        tData.tStatus.bSpacewalking = true
                    end
                    local nTeam = fnGetTeam(spawnData,tTeams)
                    local rNewChar = CharacterManager.addNewCharacter(nil, nil, tData, nTeam)
                    -- afflict with malady if necessary
                    if tMaladyData and spawnData.bSpawnWithMalady then
                        local tMaladyInstance = Malady.reproduceMalady(tMaladyData)
                        rNewChar:diseaseInteraction(nil, tMaladyInstance)
                    end
                elseif sDataType == "objects" then
                    local wx,wy = tLocs[sLocName]:getLoc()
                    local bFlipX, bFlipY = tLocs[sLocName].bFlipX, tLocs[sLocName].bFlipY
                    if spawnData.bInvItem then
                        local tItem
                        if spawnData.sTemplate then
                            tItem = Inventory.createItem(spawnData.sTemplate, spawnData.tSaveData)
                        else
                            tItem = Inventory.createRandomStartingStuff()
                        end
                        Pickup.dropInventoryItemAt(tItem,wx,wy)
                    else
                        -- nothing in module data seems to use sType?
                        -- keep it in for possible save back compat
                        local tData, bPickup = EnvObject.getObjectData(spawnData.sType or spawnData.sTemplate)
                        if tData then
                            local nTeam = fnGetTeam(spawnData,tTeams)
                            if bPickup then
                                Pickup.createPickupAt(spawnData.sType, wx,wy, spawnData.tSaveData, nTeam)
                            else
                                EnvObject.createEnvObject(spawnData.sType or spawnData.sTemplate, wx, wy, bFlipX, bFlipY, true, spawnData.tSaveData, nTeam)
                            end
                        else
                            Print(TT_Error, "EVENTCONTROLLER.LUA: Invalid object type in save data: "..tostring(spawnData.sType))
                        end
                    end
                end
            end
        end
    end

    -- remove spawners
    for sName,rLoc in pairs(tLocs) do
        rLoc:remove()
    end
end

function EventController.getForecastDebugText()
    local s = ""
    if EventController.tS and EventController.tS.tEventForecast then
        -- current event coming up
        local tNextEvent = EventController.tS.tNextEventData
        s = s .. "Next Event"
        s = s .. " | CurTime: " .. MiscUtil.formatTime(GameRules.elapsedTime)
        s = s .. " | Use ^ to force event\n"
        s = s ..  "-------------------------------------------------\n"
        if tNextEvent then
            s = s .. string.format(" 0) %s\n\n", EventController.tEventClasses[tNextEvent.sEventType].getDebugString(EventController, tNextEvent))
        else
            s = s .. "None\n"
        end

        -- next events in forecast
        s = s .. string.format("Event Forecast", #EventController.tS.tEventForecast)
        -- hotkeys
        s = s .. " | Use ! to regen forecast\n"
        s = s ..  "-------------------------------------------------\n"
        for idx, tEventState in ipairs(EventController.tS.tEventForecast) do
            local sLine = EventController.tEventClasses[tEventState.sEventType].getDebugString(EventController, tEventState)
            s = s .. string.format("%2d) %s\n", idx, sLine)
        end
    end

    return s
end

return EventController
