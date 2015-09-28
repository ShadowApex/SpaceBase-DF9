local Class = require('Class')
local Event = require('GameEvents.Event')
local BreachingEvent = Class.create(Event)

local DFMath = require('DFCommon.Math')
local DFGraphics = require('DFCommon.Graphics')
local GameRules = require('GameRules')
local Renderer = require('Renderer')
local CharacterManager = require('CharacterManager')
local SoundManager = require('SoundManager')
local Character = require('Character')
local Room = require('Room')
local EnvObject=require('EnvObjects.EnvObject')
local Base = require('Base')
local EnvObject = require('EnvObjects.EnvObject')
local Malady = require('Malady')
local MiscUtil = require('MiscUtil')

local HostileImmigrationEvent = require('GameEvents.HostileImmigrationEvent')

BreachingEvent.sEventType = "breachingEvents"
BreachingEvent.sAlertString = "ALERTS031TEXT"
BreachingEvent.nCharactersToSpawn = { 1, 3 }
BreachingEvent.bSkipAlert = true
BreachingEvent.nMinPopulation = 6
BreachingEvent.nMaxPopulation = -1
BreachingEvent.nMinTime = 60 * 10
BreachingEvent.nMaxPopulation = -1

function BreachingEvent.getSpawnLocationModifier()
    return Event.getPopulationMod() * Event.getHostilityMod(true)
end

function BreachingEvent.allowEvent(nPopulation, nElapsedTime)
    return nPopulation > BreachingEvent.nMinPopulation or GameRules.elapsedTime > BreachingEvent.nMinTime
end

function BreachingEvent.getWeight(nPopulation, nElapsedTime, bForecast)
    if bForecast then return 10.0 end
    -- increase chance of breach attacks if no exterior rooms for docking
    local nExteriorRooms = 0
    local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    for room,id in pairs(tRooms) do
        if room.bExterior then
            nExteriorRooms = nExteriorRooms + 1
        end
    end
    if nExteriorRooms > 0 then
        return 10.0
    else
        return 16.0
    end
end

function BreachingEvent.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    Event.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)

    tUpcomingEventPersistentState.bHostile = true

    local nDifficulty = tUpcomingEventPersistentState.nDifficulty
    tUpcomingEventPersistentState.tCharSpawnStats = require('EventController').rollRandomRaiders(nDifficulty,true)
    tUpcomingEventPersistentState.nNumSpawns = #tUpcomingEventPersistentState.tCharSpawnStats

    tUpcomingEventPersistentState.nNumMaladies = 0
    for i=1,tUpcomingEventPersistentState.nNumSpawns do
        if math.random(0,100) <= rController.tEventClasses[tUpcomingEventPersistentState.sEventType].nChanceOfMalady then
            tUpcomingEventPersistentState.nNumMaladies = tUpcomingEventPersistentState.nNumMaladies + 1
        end
    end

    Event._preRollMalady(rController, tUpcomingEventPersistentState, nElapsedTime)
end

function BreachingEvent._getBreachLoc()
    local tRooms, nPlayerRooms, nHiddenRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    local tWeightedChoices = {}
    local tx, ty = nil, nil
    for rRoom,id in pairs(tRooms) do
        if not rRoom:isDangerous() then
            tWeightedChoices[rRoom] = rRoom.nTiles
        end
    end
    local rSelectedRoom = MiscUtil.weightedRandom(tWeightedChoices)
    if rSelectedRoom then
        tx, ty = rSelectedRoom:randomLocInRoom(true, true)
    end
    return tx, ty
end

function BreachingEvent._lineWorldBoundsIntersect(x1,y1,x2,y2, nMinDist)
    local wx1, wy1, wx2, wy2 = g_World.getBounds()
    local tIntersections = {}
    if nMinDist then nMinDist = nMinDist * nMinDist end
    for i=1,4 do
        local testX1,testY1,testX2,testY2
        if i == 1 then testX1,testY1,testX2,testY2 = wx1,wy1,wx2,wy1 -- bottom
        elseif i == 2 then testX1,testY1,testX2,testY2 = wx1,wy1,wx1,wy2 -- left
        elseif i == 3 then testX1,testY1,testX2,testY2 = wx1,wy2,wx2,wy2 -- top
        else testX1,testY1,testX2,testY2 = wx2,wy1,wx2,wy2 end -- right
        local ix,iy = DFMath.lineIntersection(x1,y1,x2,y2, testX1,testY1,testX2,testY2)
        if ix then
            if ix > wx1-1 and ix < wx2+1 and iy > wy1-1 and iy < wy2+1 then
                local bInsert = nMinDist == nil
                local nDist2 = DFMath.distance2DSquared(x1, y1, ix, iy)
                if not nMinDist or nDist2 > nMinDist then
                    table.insert(tIntersections, {x=ix,y=iy,d=nDist2})
                end
            end
        end
    end
    table.sort(tIntersections, function(a,b) return a.d < b.d end)
    return tIntersections
end

function BreachingEvent.preExecuteSetup(rController, tUpcomingEventPersistentState)
    local bValid = Event.preExecuteSetup(rController, tUpcomingEventPersistentState)

    -- choose where to breach
    tUpcomingEventPersistentState.tx, tUpcomingEventPersistentState.ty = BreachingEvent._getBreachLoc()
    if not tUpcomingEventPersistentState.tx then
        return false
    end

    return bValid
end

function BreachingEvent.tick(rController, dT, tCurrentEventPersistentState, tCurrentEventTransientState)
    local tPersistentState, tTransientState = tCurrentEventPersistentState, tCurrentEventTransientState

    if tTransientState.rShip and tTransientState.rShip.bExploded then
        return true
    end

    if not tTransientState.sPhase then
        tTransientState.sPhase = 'flyIn'
        tTransientState.txDest,tTransientState.tyDest = tCurrentEventPersistentState.tx, tCurrentEventPersistentState.ty
        tTransientState.wxDest,tTransientState.wyDest = g_World._getWorldFromTile(tTransientState.txDest,tTransientState.tyDest)

        local x1, y1, x2, y2 = g_World.getBounds()
        local midpointX,midpointY = (x2-x1)*.5, (y2-y1)*.5

        -- Pick a path to the dest.
        -- Pick a random angle. If the dist from world bounds to the dest loc is sufficient, use that angle.
        -- Otherwise, use the opposite angle.

        local angle = math.random(0,360)
        local dx,dy = math.cos(angle),math.sin(angle)
        local tPoints = BreachingEvent._lineWorldBoundsIntersect(tTransientState.wxDest,tTransientState.wyDest,tTransientState.wxDest+dx*100,tTransientState.wyDest+dy*100, g_World.height*.3)
        local tPoint = MiscUtil.randomValue(tPoints)
        tTransientState.wxStart,tTransientState.wyStart = tPoint.x,tPoint.y

        tTransientState.nTeam = require('EventController').getTeamForEvent(Character.FACTION_BEHAVIOR.EnemyGroup)
        tTransientState.rShip = require('WorldObjects.BreachShip').new(tTransientState.wxStart,tTransientState.wyStart,nil,tTransientState.nTeam)
        local dx,dy = tTransientState.wxDest-tTransientState.wxStart, tTransientState.wyDest-tTransientState.wyStart
        local dist = math.sqrt(dx*dx+dy*dy)
        tTransientState.rShip:setFacingVec(dx,dy)

        local nDuration = dist * .0075
        tTransientState.nStartTime = GameRules.elapsedTime
        tTransientState.nEndTime = GameRules.elapsedTime + nDuration

        Base.eventOccurred(Base.EVENTS.EventAlert, {rReporter=tTransientState.rShip,sLineCode=BreachingEvent.sAlertString, tPersistentData=tCurrentEventPersistentState})
        if GameRules.getTimeScale() > 1 and g_Config:getConfigValue('normal_speed_on_alerts') then
            GameRules.setTimeScale(1)
        end

        tTransientState.curve = MOAIAnimCurve.new()
        tTransientState.curve:reserveKeys(2)
        tTransientState.curve:setKey(1, 0, 0, MOAIEaseType.EASE_IN)
        tTransientState.curve:setKey(2, nDuration, 1, MOAIEaseType.EASE_IN)
        tTransientState.nLastT = 0
    end

    if tTransientState.rShip then tTransientState.rShip:setVelocity(0,0) end

    -- TICKING CURRENT PHASE
    if GameRules.elapsedTime < tTransientState.nEndTime then
        if tTransientState.sPhase == 'flyIn' then
            local nElapsed=GameRules.elapsedTime - tTransientState.nStartTime
            local t = tTransientState.curve:getValueAtTime(nElapsed)
            local newX,newY = DFMath.lerp(tTransientState.wxStart, tTransientState.wxDest, t), DFMath.lerp(tTransientState.wyStart, tTransientState.wyDest, t)
            tTransientState.rShip:setLoc(newX,newY,-8500)

            local dt = t-tTransientState.nLastT
            if dt > 0.001 then
                local oldX,oldY = DFMath.lerp(tTransientState.wxStart, tTransientState.wxDest, tTransientState.nLastT), DFMath.lerp(tTransientState.wyStart, tTransientState.wyDest, tTransientState.nLastT)
                tTransientState.nLastT = t
                local dx,dy = newX-oldX,newY-oldY
                tTransientState.rShip:setVelocity(dx/dt,dy/dt)
            end
        elseif tTransientState.sPhase == 'spawn' then
        elseif tTransientState.sPhase == 'drill' then
            if not tTransientState.bPlayedDrillSound and GameRules.elapsedTime - tTransientState.nEndTime < 1.5 then
                local wx,wy = tTransientState.rShip:getLoc()
                SoundManager.playSfx3D('raiderdrill', wx, wy, 0)
                tTransientState.bPlayedDrillSound = true
            end
        elseif tTransientState.sPhase == 'ladder' then
        else
            assertdev(false)
        end
        return
    end

    -- SWITCHING TO NEXT PHASE
    if tTransientState.sPhase == 'flyIn' then
        local wx,wy = tTransientState.rShip:getLoc()
        SoundManager.playSfx3D('raiderdocking', wx, wy)
        tTransientState.sPhase = 'drill'
        local wx,wy = EnvObject.getSpriteLoc('Spawner',tTransientState.wxDest,tTransientState.wyDest,false)
        DFGraphics.alignSprite('Environments/Objects', 'breach_drill', 'left', 'bottom')
        tTransientState.nEndTime = GameRules.elapsedTime + 3

        tTransientState.rDrill = require('AnimatedSprite').new(Renderer.getRenderLayer("WorldWall"), nil, "breach_hole_", {nFPS=15, sAlignH='left',sAlignV='bottom', bHoldLastFrame=true })
        local wz = g_World.getHackySortingZ(wx,wy-g_World.tileHeightH)
        tTransientState.rDrill:setLoc(wx,wy,wz)
        tTransientState.rDrill:play(true, 0)
        return
    elseif tTransientState.sPhase == 'drill' then
        tTransientState.sPhase = 'ladder'
        tTransientState.rDrill:die()
        tTransientState.rDrill = nil
        local wx,wy = EnvObject.getSpriteLoc('Spawner',tTransientState.wxDest,tTransientState.wyDest,false)
        DFGraphics.alignSprite('Environments/Objects', 'breach_ladder', 'left', 'bottom')
        local wz = g_World.getHackySortingZ(wx,wy)
        tTransientState.sRenderLayer = "WorldWall"
        tTransientState.rLadder = DFGraphics.newSprite3D('breach_ladder', Renderer.getRenderLayer(tTransientState.sRenderLayer), 'Environments/Objects', wx,wy, wz)
        tTransientState.tSpawns = tTransientState.rShip:getRaiderStats(tPersistentState.nNumSpawns)
        tTransientState.nEndTime = GameRules.elapsedTime + 1
        tTransientState.nNumSpawned = 0
        return
    elseif tTransientState.sPhase == 'ladder' then
        tTransientState.sPhase = 'spawn'
        tTransientState.nEndTime = GameRules.elapsedTime + .5
    elseif tTransientState.sPhase == 'spawn' then
        if tTransientState.nNumSpawned < #tTransientState.tSpawns then
            -- MTF TODO: would be nice to queue these guys up with a task to step one tile away.
            tTransientState.nEndTime = GameRules.elapsedTime + 5
            tTransientState.nNumSpawned = tTransientState.nNumSpawned + 1
            local tData = tTransientState.tSpawns[tTransientState.nNumSpawned]
            local tRaiderSpawnStats = tPersistentState.tCharSpawnStats[tTransientState.nNumSpawned] or tPersistentState.tCharSpawnStats[1]
            for k,v in pairs(tRaiderSpawnStats) do
                tData.tStats[k] = v
            end
            local rNewChar = CharacterManager.addNewCharacter(tTransientState.wxDest, tTransientState.wyDest, tData, tTransientState.nTeam)

            -- afflict raider with malady if necessary
            if tPersistentState.tPrerolledMalady and tTransientState.nNumSpawned <= tPersistentState.nNumMaladies then
                local tMaladyInstance = Malady.reproduceMalady(tPersistentState.tPrerolledMalady)
                rNewChar:diseaseInteraction(nil, tMaladyInstance)
            end
            rController.clearCurrentEventFromSaveTable(tCurrentEventPersistentState.nUniqueID)
            return
        else
            Renderer.getRenderLayer(tTransientState.sRenderLayer):removeProp(tTransientState.rLadder)
            tTransientState.rShip:fadeAway()
            return true
        end
    else
        assertdev(false)
    end
end

return BreachingEvent
