local Class = require('Class')
local Event = require('GameEvents.Event')
local EventData = require('GameEvents.EventData')
local ImmigrationEvent = Class.create(Event)

local GameRules = require('GameRules')
local Renderer = require('Renderer')
local DFGraphics = require('DFCommon.Graphics')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local SoundManager = require('SoundManager')
local Docking = require('Docking')
local Base = require('Base')
local AlertEntry = require('UI.AlertEntry')
local CharacterManager = require('CharacterManager')
local Character = require('Character')
local MiscUtil = require('MiscUtil')
local GenericDialog = require('UI.GenericDialog')
local Portraits = require('UI.Portraits')
local Malady = require('Malady')
local Room = require('Room')

-- static, constant variables
ImmigrationEvent.tNumSpawnsRange={1,2}
ImmigrationEvent.sEventType = 'immigrationEvents'
ImmigrationEvent.bSkipAlert = false
ImmigrationEvent.sAlertLC = 'ALERTS028TEXT'
ImmigrationEvent.sFailureLC = 'ALERTS024TEXT'
ImmigrationEvent.sDialogSet = 'immigrationEvents'
ImmigrationEvent.nPostDialogAlertTotalTime = 4
ImmigrationEvent.nAllowedSetupFailures = 0

-- if population is below threshold within early game, weight immigration higher
ImmigrationEvent.EARLY_POPULATION_THRESHOLD = 8
ImmigrationEvent.EARLY_POPULATION_TIME = 25 * 60

ImmigrationEvent.sRejectionFailAlert='ALERTS025TEXT'
ImmigrationEvent.sRejectionSuccessAlert='ALERTS024TEXT'
ImmigrationEvent.sAcceptedSuccessAlert='ALERTS030TEXT'
ImmigrationEvent.sDialogSkippedAlert='ALERTS041TEXT'
ImmigrationEvent.DEFAULT_WEIGHT = 50
ImmigrationEvent.nMinPopulation = -1
ImmigrationEvent.nMaxPopulation = g_nPopulationCap
ImmigrationEvent.nMinTime = -1
ImmigrationEvent.nMaxTime = -1

function ImmigrationEvent.getSpawnLocationModifier()
    return Event.getPopulationMod() * Event.getHostilityMod(false)
end

function ImmigrationEvent.getWeight(nPopulation, nElapsedTime)
    -- if popcap reached, 0 chance of immigration
    if nPopulation >= g_nPopulationCap then
        return 0
    end
    -- in early game try to help player get to a minimum viable population size
    if nElapsedTime < ImmigrationEvent.EARLY_POPULATION_TIME and nPopulation < ImmigrationEvent.EARLY_POPULATION_THRESHOLD then
        return ImmigrationEvent.DEFAULT_WEIGHT * 1.5
    end
    return ImmigrationEvent.DEFAULT_WEIGHT
end

function ImmigrationEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    Event.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)

    local tRange = rController.tEventClasses[tUpcomingEventPersistentState.sEventType].tNumSpawnsRange
    tUpcomingEventPersistentState.nNumSpawns = math.random(tRange[1],tRange[2])

    Event._preRollMalady(rController,tUpcomingEventPersistentState, nElapsedTime)

    tUpcomingEventPersistentState.nNumMaladies = 0
    for i=1,tUpcomingEventPersistentState.nNumSpawns do
        if math.random(0,100) <= rController.tEventClasses[tUpcomingEventPersistentState.sEventType].nChanceOfMalady then
            tUpcomingEventPersistentState.nNumMaladies = tUpcomingEventPersistentState.nNumMaladies + 1
        end
    end
end

function ImmigrationEvent.preAlertSetup(rController, tUpcomingEventPersistentState)
    if not (tUpcomingEventPersistentState.bHostile or tUpcomingEventPersistentState.bTrader) and CharacterManager.getOwnedCitizenPopulation() >= g_nPopulationCap then
        return false
    end
    return true
end

function ImmigrationEvent.onAlertShown(rController, tUpcomingEventPersistentState)
    AlertEntry.dOnClick:register(ImmigrationEvent.onAlertClick, tUpcomingEventPersistentState)

    if GameRules.getTimeScale() > 1 and g_Config:getConfigValue('normal_speed_on_alerts') then
        GameRules.setTimeScale(1)
    end
end

function ImmigrationEvent.onAlertClick(tUpcomingEventPersistentState)
    tUpcomingEventPersistentState.bClickedAlert = true
    -- have event start up immediately.
    tUpcomingEventPersistentState.nStartTime = GameRules.elapsedTime
end

function ImmigrationEvent.preExecuteSetup(rController, tUpcomingEventPersistentState)
    Event.preExecuteSetup(rController, tUpcomingEventPersistentState)

    local rClass = rController.tEventClasses[tUpcomingEventPersistentState.sEventType]

    -- if didn't click on alert, treat as a "no."
    if not tUpcomingEventPersistentState.bClickedAlert then
        if rClass._ignoreRefusal(tUpcomingEventPersistentState) or tUpcomingEventPersistentState.bSkipDialog then
        else
            AlertEntry.dOnClick:unregister(ImmigrationEvent.onAlertClick,
                                           tUpcomingEventPersistentState)
            return false, ImmigrationEvent.sRejectionSuccessAlert
        end
    end

    -- popcap if not a hostile event
    if not (tUpcomingEventPersistentState.bHostile or tUpcomingEventPersistentState.bTrader) and CharacterManager.getOwnedCitizenPopulation() >= g_nPopulationCap then
        AlertEntry.dOnClick:unregister(ImmigrationEvent.onAlertClick,
                                       tUpcomingEventPersistentState)
        return false, ImmigrationEvent.sRejectionSuccessAlert
    end

    tUpcomingEventPersistentState.tx, tUpcomingEventPersistentState.ty = Event._getTileInOpenSpace()

    if not tUpcomingEventPersistentState.tx then
        return false, ImmigrationEvent.sRejectionSuccessAlert
    end

    return true
end

function ImmigrationEvent.skipDialog(rController, tPersistentState, tTransientState)
    tPersistentState.bChoseDialog = true
    tPersistentState.bSkipDialog = true
    tPersistentState.bClickedAlert = true
end

function ImmigrationEvent.tick(rController, dT, tCurrentEventPersistentState, tCurrentEventTransientState)
    local tPersistentState, tTransientState = tCurrentEventPersistentState, tCurrentEventTransientState

    local z = -10000

    if not tTransientState.bStarted then
        tTransientState.nStartingTimeScale = GameRules.getTimeScale()
        tTransientState.tDialogStatus = {}
        tTransientState.bStarted = true
        if tPersistentState.bSkipDialog then
            tTransientState.bChoseDialog=true
            tTransientState.bSpawn=true
            tTransientState.nPostDialogAlertTime = 0
            tTransientState.bWaitingOnDialog = false
            tTransientState.bDialogAccepted = true
            local rClass = rController.tEventClasses[tPersistentState.sEventType]
            local wx,wy = g_World._getWorldFromTile(tPersistentState.tx, tPersistentState.ty)
            Base.eventOccurred(Base.EVENTS.EventAlert,{sLineCode=rClass.sDialogSkippedAlert, wx=wx, wy=wy, tPersistentData=tPersistentState, nLogVisibleTime=15, nPriority=0,})
        else
            GameRules.setTimeScale(0)
        end
        return
    end

    if not tTransientState.bChoseDialog then
        if ImmigrationEvent.dialogTick(rController, tPersistentState, tTransientState, dT) then
            tTransientState.bChoseDialog = true
        end
        return
    end

    -- Wait a period of time before spawning after dialog is dismissed
    if tTransientState.bSpawn then
        if not tTransientState.wxEnd then
            tTransientState.wxEnd,tTransientState.wyEnd = g_World._getWorldFromTile(tPersistentState.tx, tPersistentState.ty)
        end

        if tTransientState.nPostDialogAlertTime < ImmigrationEvent.nPostDialogAlertTotalTime then
            tTransientState.nPostDialogAlertTime = tTransientState.nPostDialogAlertTime + dT
            return
        end
    else
        -- if not spawning, don't wait, just end the event
        if GameRules.getTimeScale() < tTransientState.nStartingTimeScale then
            GameRules.setTimeScale(tTransientState.nStartingTimeScale)
        end
        return true
    end

    -- bSpawn set by dialogTick... kind o kludgey
    if tTransientState.bSpawn and not tTransientState.bStartedSpawn then
        local tx, ty = tPersistentState.tx, tPersistentState.ty

        tTransientState.nFlip = 1
        if math.random() > 0.5 then
            --ndx,ndy = .5,-.87
            tTransientState.ndx,tTransientState.ndy = 0.87, -.5
            tTransientState.nFlip=-1
        else
            tTransientState.ndx,tTransientState.ndy = -0.87, -.5
        end

        local nDist=4000
        local wx, wy = g_World._getWorldFromTile(tx, ty)
        tTransientState.shipStartX = wx - nDist * tTransientState.ndx
        tTransientState.shipStartY = wy - nDist * tTransientState.ndy
        tTransientState.rShip = DFGraphics.newSprite3D('spacebus',
                                                       Renderer.getRenderLayer(rController.RENDER_LAYER_BG),
                                                       'Environments/Objects',
                                                       tTransientState.shipStartX,
                                                       tTransientState.shipStartY)
        tTransientState.rShip:setScl(tTransientState.nFlip, 1, 1)
        tTransientState.rShip:setPriority(-10000)

        --local rot = DFMath.getAngleBetween( 0, 1, ndx,ndy)
        --tTransientState.rShip:setRot(rot,0,0)

        tTransientState.nDuration = 1.5
        tTransientState.nElapsed = 0

        SoundManager.playSfx3D('spacetaxi', tTransientState.shipStartX,
                               tTransientState.shipStartY, 0)
        tTransientState.bStartedSpawn = true
        return
    end

    if not tTransientState.bFinishedSpawning then
        if tTransientState.nElapsed < tTransientState.nDuration then
            local nStep = dT
            tTransientState.nElapsed = tTransientState.nElapsed + nStep
            local t = tTransientState.nElapsed / tTransientState.nDuration
            local newX = DFMath.lerp(tTransientState.shipStartX,
                                     tTransientState.wxEnd, t)
            local newY = DFMath.lerp(tTransientState.shipStartY,
                                     tTransientState.wyEnd, t)
            tTransientState.rShip:setLoc(newX,newY,z)

            return
        end

        local nNumFailures = 0
        local nFactionBehavior = (tPersistentState.bHostile
                                      and Character.FACTION_BEHAVIOR.EnemyGroup)
            or (tPersistentState.bTrader and Character.FACTION_BEHAVIOR.Trader)
            or Character.FACTION_BEHAVIOR.Citizen
        local nTeam = require('EventController').getTeamForEvent(nFactionBehavior)

        local nSpawns = tPersistentState.nNumSpawns
        while nSpawns > 0 and nNumFailures < 20 do
            local dx, dy = math.random(100,300), math.random(200,350)
            dx = dx * tTransientState.nFlip
            local nwx = tTransientState.wxEnd + dx
            local nwy = tTransientState.wyEnd + dy
            local tv = g_World.getTileValueFromWorld(nwx, nwy)
            if tv == g_World.logicalTiles.SPACE or g_World.countsAsFloor(tv) then
                local tData = { }
                tData.tStatus = { bSpacewalking = true }
                if g_World.countsAsFloor(tv) then
                    tData.tStatus.bElevatedSpacewalk = true
                end
                -- hostile immigration: nearly identical, just pass in hostile spawn data
                if tPersistentState.tCharSpawnStats then
                    tData.tStats = DFUtil.deepCopy(tPersistentState.tCharSpawnStats[nSpawns])
                end
                local rNewChar = CharacterManager.addNewCharacter(nwx,nwy, tData, nTeam)

                -- afflict with malady if necessary
                if tPersistentState.tPrerolledMalady and nSpawns <= tPersistentState.nNumMaladies then
                    local tMaladyInstance = Malady.reproduceMalady(tPersistentState.tPrerolledMalady)
                    rNewChar:diseaseInteraction(nil, tMaladyInstance)
                end
                nSpawns = nSpawns - 1
            else
                nNumFailures = nNumFailures + 1
            end
        end

        tTransientState.bFinishedSpawning = true

        rController.clearCurrentEventFromSaveTable(tCurrentEventPersistentState.nUniqueID)

        tTransientState.sPhase = 'wait'
        tTransientState.nEndTime = GameRules.elapsedTime+2
        return
    end

    if GameRules.elapsedTime < tTransientState.nEndTime then
        if tTransientState.sPhase == 'flyAway' then
            local t = (GameRules.elapsedTime - tPersistentState.nStartTime) /
                (tTransientState.nEndTime-tPersistentState.nStartTime)
            local newX = DFMath.lerp(tTransientState.shipStartX, tTransientState.shipEndX, t)
            local newY = DFMath.lerp(tTransientState.shipStartY, tTransientState.shipEndY, t)
            tTransientState.rShip:setLoc(newX,newY,z)
            tTransientState.rShip:setScl(tTransientState.nFlip*(1-t),1-t,1)
            tTransientState.rShip:setColor(1-t,1-t,1-t)
            return
        elseif tTransientState.sPhase == 'wait' then
            -- nothing
        end
        return
    end

    if tTransientState.sPhase == 'wait' then
        tTransientState.sPhase = 'flyAway'
        tTransientState.nEndTime = GameRules.elapsedTime+6
        tPersistentState.nStartTime = GameRules.elapsedTime
        tTransientState.nDist=6000
        tTransientState.shipStartX = tTransientState.wxEnd
        tTransientState.shipStartY= tTransientState.wyEnd
        tTransientState.shipEndX = tTransientState.shipStartX +
            tTransientState.nDist * tTransientState.ndx
        tTransientState.shipEndY = tTransientState.shipStartY +
            tTransientState.nDist * tTransientState.ndy
        return
    else
        assertdev(tTransientState.sPhase == 'flyAway')
        Renderer.getRenderLayer(rController.RENDER_LAYER_BG):removeProp(tTransientState.rShip)
        return true
    end
end

function ImmigrationEvent._ignoreRefusal(tPersistentEventState)
    return math.random() > 0.66
end

-- TODO: move this somewhere else
function ImmigrationEvent.dialogTick(rController, tPersistentEventState, tTransientEventState, dt)
    if tTransientEventState.bWaitingOnDialog then
        return
    end

    if not tTransientEventState.tDialogStatus.tDlgSet then
        tTransientEventState.tDialogStatus.tDlgSet = DFUtil.arrayRandom(EventData[tPersistentEventState.sEventType])
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

        tTransientEventState.bSpawn = bSpawn
        tTransientEventState.bWaitingOnDialog = true

        local function onDialogClick(bAccepted)
            tTransientEventState.bWaitingOnDialog = false
            tTransientEventState.bDialogAccepted = bAccepted
            local wx,wy = g_World._getWorldFromTile(tPersistentEventState.tx, tPersistentEventState.ty)
            Base.eventOccurred(Base.EVENTS.EventAlert,{sLineCode=sOnClickAlert, wx=wx, wy=wy, tPersistentData=tPersistentEventState, nLogVisibleTime=15, nPriority=0,})
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

return ImmigrationEvent
