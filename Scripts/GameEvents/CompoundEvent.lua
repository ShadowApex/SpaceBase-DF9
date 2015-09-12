local Class = require('Class')
local Event = require('GameEvents.Event')
local CompoundEvent = Class.create(Event)

local DFMath = require('DFCommon.Math')
local DFGraphics = require('DFCommon.Graphics')
local GameRules = require('GameRules')
local Renderer = require('Renderer')
local CharacterManager = require('CharacterManager')
local DFUtil = require('DFCommon.Util')
local SoundManager = require('SoundManager')
local GenericDialog = require('UI.GenericDialog')
local DialogSets = require('DialogSets')
local Portraits = require('UI.Portraits')
local Character = require('Character')
local Room = require('Room')
local EnvObject=require('EnvObjects.EnvObject')
local Base = require('Base')
local EnvObject = require('EnvObjects.EnvObject')
local Malady = require('Malady')
local MiscUtil = require('MiscUtil')

local HostileImmigrationEvent = require('GameEvents.HostileImmigrationEvent')
local BreachingEvent = require('GameEvents.BreachingEvent')

CompoundEvent.sEventType = "CompoundEvent"
CompoundEvent.sAlertLC = 'ALERTS040TEXT'
CompoundEvent.sDialogSet = 'CompoundEvent'
CompoundEvent.bSkipAlert = true

function CompoundEvent.getSpawnLocationModifier()
    return Event.getPopulationMod() * Event.getHostilityMod(true)
end

function CompoundEvent.allowEvent(nPopulation, nElapsedTime)
    return not g_Config:getConfigValue('disable_hostiles') and not g_Config:getConfigValue('disable_hostile_events') and (nPopulation > 15 or GameRules.elapsedTime > 60*20)
end

function CompoundEvent.getWeight(nPopulation, nElapsedTime)
    local rController = require('EventController')
	-- next compound event will be the mega event
    if nElapsedTime > rController.nFinalSiegeTime and not rController.tS.bRanMegaEvent then
        return 60
    end
    return 15
end

function CompoundEvent.selectEvents(rController, tPersistentState, nPopulation, nElapsedTime, bMega)
    -- raiders: 1-3 points, depending on challenge level
    -- breach ship: extra 2 points
    -- killbots: 4 points
    -- meteor shower: 4 points
    local nPoints = (bMega and 100) or tPersistentState.nDifficulty * 40 * (.7+.3*math.random())
    local bMeteorStrike = false

    tPersistentState.tEvents = {}
    local tChoices={
        meteorEvents=1,
        breachingEvents=4,
        hostileImmigrationEvents=5,
    }
    --print('Compound event running with points:',nPoints)
    local bFirst = true
    while nPoints > 0 or (not bMeteorStrike and bMega) do
        local nStartTime = tPersistentState.nStartTime
        if not bFirst then
            nStartTime = nStartTime + 60*math.random()
        end
        bFirst = false
        local sChoice = nil

        if not bMeteorStrike and bMega and nPoints <= 4 then
            sChoice = 'meteorEvents'
        else
            sChoice = MiscUtil.weightedRandom(tChoices)
        end

        if sChoice == 'meteorEvents' then
            bMeteorStrike = true
            nPoints = nPoints-4
            tChoices['meteorEvents'] = nil
        elseif sChoice == 'breachingEvents' then
            nPoints = nPoints-1
        end

        local tEvent = {
            sEventType = sChoice,
            nStartTime = nStartTime,
            nAlertTime = nStartTime - math.random(rController.tAlertTimeRange[1],rController.tAlertTimeRange[2]),
            nUniqueID = rController.stNextEventID,
        }
        --print('new event, type',sChoice,'new total:',nPoints)
        rController.stNextEventID = rController.stNextEventID + 1
        local rClass = rController.tEventClasses[sChoice]
        rClass.onQueue(rController, tEvent, nPopulation, nStartTime)
        table.insert(tPersistentState.tEvents, tEvent)

        if tEvent.nNumSpawns then
            for i,v in ipairs(tEvent.tCharSpawnStats) do
                local sEnemy = 'raider'
                if v.nRace == Character.RACE_KILLBOT then
                    nPoints = nPoints-4
                    sEnemy = 'killbot'
                elseif v.nChallengeLevel > .6 then
                    nPoints = nPoints-3
                    sEnemy = 'raiderbig'
                elseif v.nChallengeLevel > .2 then
                    nPoints = nPoints-2
                    sEnemy = 'raidermed'
                else
                    nPoints = nPoints-1
                    sEnemy = 'raidersmall'
                end
                --print('new enemy',sEnemy,'new total:',nPoints)
            end
        elseif sChoice ~= 'meteorEvents' then
            assertdev(false)
            --print('ZEROING OUT POINTS')
            nPoints = 0
        end
    end
end

CompoundEvent.showAlertsFor={meteorEvents=true}

function CompoundEvent._tickAlerts(rController, tPersistentState, tTransientState)
    for i,v in ipairs(tPersistentState.tEvents) do
        if CompoundEvent.showAlertsFor[v.sEventType] and not v.bAlertedNextEvent and GameRules.elapsedTime > v.nAlertTime then
            if rController._doAlert(v) then
                v.bAlertedNextEvent = true
            end
        end
    end
end

function CompoundEvent.preExecuteTick(rController, tPersistentState, tTransientState)
    CompoundEvent._tickAlerts(rController, tPersistentState, tTransientState)
end

function CompoundEvent.onQueue(rController, tPersistentState, nPopulation, nElapsedTime)
    Event.onQueue(rController, tPersistentState, nPopulation, nElapsedTime)

    local bMega = false
    if tPersistentState.nStartTime > rController.nFinalSiegeTime and not rController.tS.bRanMegaEvent then
        bMega = true
        tPersistentState.bMega = true
    end

    tPersistentState.bHostile = true
    CompoundEvent.selectEvents(rController, tPersistentState, nPopulation, nElapsedTime, bMega)
    tPersistentState.tFinishedEvents = {}
end

function CompoundEvent.preExecuteSetup(rController, tPersistentState, tTransientState)
    if tPersistentState.bMega and rController.tS.bRanMegaEvent then
        return false
    end
        
    local bValid = Event.preExecuteSetup(rController, tPersistentState)
    if not bValid then return false end
    
    tTransientState.tEvents = {}

    for i,v in ipairs(tPersistentState.tEvents) do
        local rClass = rController.tEventClasses[v.sEventType]

        if rClass.skipDialog then 
            rClass.skipDialog(rController, v, tTransientState.tEvents[i])
        end        

        bValid = rClass.preExecuteSetup(rController, v)
        if not bValid then return false end
        
        tTransientState.tEvents[i] = {}        
    end
    
    return true
end

function CompoundEvent.tick(rController, dt, tPersistentState,tTransientState)
    CompoundEvent._tickAlerts(rController, tPersistentState, tTransientState)
    
    if not tTransientState.bStarted and tPersistentState.bMega then
        if GameRules.getTimeScale() > 0 then
            tTransientState.nStartingTimeScale = GameRules.getTimeScale()
            tTransientState.tDialogStatus = {}
            tTransientState.bStarted = true
            tTransientState.nStartingTimeScale = GameRules.getTimeScale()
            GameRules.setTimeScale(0)
        end
        return
    end

    if not tTransientState.bChoseDialog and tPersistentState.bMega then
        if CompoundEvent.dialogTick(rController, tPersistentState, tTransientState, dt) then
            tTransientState.bChoseDialog = true
            if GameRules.getTimeScale() < tTransientState.nStartingTimeScale then
                GameRules.setTimeScale(tTransientState.nStartingTimeScale)
            end
        end
        return
    end
    
    local n=#tPersistentState.tEvents
    for i=n,1,-1 do
        local v = tPersistentState.tEvents[i]
        local rEventClass = rController.tEventClasses[v.sEventType]
        if GameRules.elapsedTime > v.nStartTime and rEventClass.tick then
            if rEventClass.tick(rController, dt, v, tTransientState.tEvents[i]) then
                
                table.insert(tPersistentState.tFinishedEvents,v)
                table.remove(tPersistentState.tEvents,i)
                table.remove(tTransientState.tEvents,i)
                rEventClass.cleanup(rController, v)
            end
        end
    end
    
    if not next(tPersistentState.tEvents) then
        if tPersistentState.bMega then
            rController.tS.bRanMegaEvent = true
            rController.tS.nMegaEventStartTime = GameRules.elapsedTime
        end
        return true
    end
end

function CompoundEvent._ignoreRefusal(tPersistentEventState)
    if tPersistentEventState.bMega then return false end
    return math.random() > 0.33
end

function CompoundEvent.dialogTick(rController, tPersistentEventState, tTransientEventState, dt)
    if tTransientEventState.bWaitingOnDialog then
        return
    end

    if not tTransientEventState.tDialogStatus.tDlgSet then
        tTransientEventState.tDialogStatus.tDlgSet = DFUtil.arrayRandom(DialogSets[tPersistentEventState.sEventType])
        local tDlgSet = tTransientEventState.tDialogStatus.tDlgSet
        tTransientEventState.bWaitingOnDialog = true
        tTransientEventState.tDialogStatus.sPortrait = Portraits.getRandomPortrait()
        local function onDialogClick(bAccepted)
            tTransientEventState.bWaitingOnDialog = false
            tTransientEventState.bDialogAccepted = bAccepted
        end
        local rRequestUI = GenericDialog.new('UILayouts/DockingRequestLayout',
            onDialogClick, 'DockingButton')
        rRequestUI:setTemplateUITexture('Picture',
            tTransientEventState.tDialogStatus.sPortrait, Portraits.PORTRAIT_PATH)
        local tReplacements= {
            Title = tDlgSet.title,
            DockMessage = tDlgSet.request,
            DockingLabel = tDlgSet.acceptButton,
            DeclineLabel = tDlgSet.rejectButton
        }
        rRequestUI:replaceText(tReplacements)
        g_GuiManager.addToPopupQueue(rRequestUI, true)

        return
    elseif not tTransientEventState.tDialogStatus.bRequestUI then
        local tDlgSet = tTransientEventState.tDialogStatus.tDlgSet
        local bSpawn = tTransientEventState.bDialogAccepted
        local tReplacements = nil
        local sOnClickAlert = nil
        local rClass = rController.tEventClasses[tPersistentEventState.sEventType]
        if not bSpawn and rClass._ignoreRefusal(tPersistentEventState) then
            bSpawn = true
            tReplacements = {
                DockMessage = tDlgSet.screwYouResponse,
                AcceptLabel = tDlgSet.screwYouResponseButton
            }
            sOnClickAlert = rClass.sRejectionFailAlert
        elseif not bSpawn then
            tReplacements = {
                DockMessage = tDlgSet.rejectedResponse,
                AcceptLabel = tDlgSet.rejectedResponseButton
            }
            sOnClickAlert = rClass.sRejectionSuccessAlert
        else
            tReplacements = {
                DockMessage = tDlgSet.acceptedResponse,
                AcceptLabel = tDlgSet.acceptedResponseButton
            }
            sOnClickAlert = rClass.sAcceptedSuccessAlert
        end
        sOnClickAlert = 'ALERTS040TEXT'
        
        tTransientEventState.bSpawn = bSpawn
        tTransientEventState.bWaitingOnDialog = true

        local function onDialogClick(bAccepted)
            tTransientEventState.bWaitingOnDialog = false
            tTransientEventState.bDialogAccepted = bAccepted
            Base.eventOccurred(Base.EVENTS.EventAlert,{sLineCode=sOnClickAlert, tPersistentData=tPersistentEventState, nLogVisibleTime=15, nPriority=0,})
        end
        local rRequestUI = GenericDialog.new('UILayouts/DockingResponseLayout', onDialogClick)        
        rRequestUI:setTemplateUITexture('Picture',
            tTransientEventState.tDialogStatus.sPortrait, Portraits.PORTRAIT_PATH)
        rRequestUI:replaceText(tReplacements)
        g_GuiManager.addToPopupQueue(rRequestUI, true)
        tTransientEventState.tDialogStatus.bRequestUI = true

        return
    end

    tTransientEventState.nPostDialogAlertTime = 0
    return true
end

return CompoundEvent
