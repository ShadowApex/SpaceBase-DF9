local Class = require('Class')

local Event = Class.create(nil)

local CharacterManager = require('CharacterManager')
local Character = require('Character')
local GameRules = require('GameRules')
local ModuleData = require('ModuleData')
local Base = require('Base')
local Malady = require('Malady')
local MiscUtil = require('MiscUtil')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')

-- TODO make DockingEvent subclass
local Docking = require('Docking')
local Room = require('Room')

Event.nAllowedSetupFailures = 30

Event.nDebugLineLength = 40

-- Chance of a newly spawned character having a disease, out of 100
Event.nChanceOfMalady = 15
-- if a new strain is discovered, the probability that it requires research.
Event.PROBABILITY_REQUIRES_RESEARCH = .66
-- affliction probabilities are used in a MiscUtil.weightedRandom
-- new strain probabilities are used as out of 100
Event.tMaladyProbabilities = {
    Parasite = {
        nChanceOfAffliction = 4,
        nChanceOfNewStrain = 0,
    },
    SpaceFlu = {
        nChanceOfAffliction = 50,
        nChanceOfNewStrain = 50,
    },
    SlackersDisease = {
        nChanceOfAffliction = 15,
        nChanceOfNewStrain = 50,
    },
    AntisocialDisease = {
        nChanceOfAffliction = 10,
        nChanceOfNewStrain = 50,
    },
    HighEnergyLowEnergy = {
        nChanceOfAffliction = 15,
        nChanceOfNewStrain = 50,
    },
    Plague = {
        nChanceOfAffliction = 4,
        nChanceOfNewStrain = 50,
    },
}

Event.nAlertPriority = 1

function Event._getExpMod(sMod)
    -- map 0-1 hostility to .5 to 2x, where 0.5 hostility = 1x.
    local tLandingZone = GameRules.getLandingZone()
    local nSpawnLocModifier = MiscUtil.getGalaxyMapValue(tLandingZone.x,tLandingZone.y,sMod)
    nSpawnLocModifier = 2*nSpawnLocModifier
    nSpawnLocModifier = 2^nSpawnLocModifier
    nSpawnLocModifier = .5*nSpawnLocModifier
    return nSpawnLocModifier
end

function Event.getPopulationMod()
    return Event._getExpMod('population')
end

function Event.getHostilityMod(bHostile)
    local nMod = Event._getExpMod('hostility')
    if not bHostile then nMod = 1/nMod end
    return nMod
end

function Event.spawnsCharacters()
    return false, 0
end

-- Weighting for this event type
-- we pipe in these two arguments because we are likely generating a weight
-- for a future event.
function Event.getWeight(nPopulation, nElapsedTime)
    return 5
end

-- Is it ok to run this event given these attributes about the world?
-- we pipe in these two arguments because we are likely generating a weight
-- for a future event.
function Event.allowEvent(nPopulation, nElapsedTime)
    return true
end


function Event._difficultyCurve(x)
    -- TODO make this non linear?
    -- maybe just keep this linear, then have the internals of each event
    -- respond to difficulty non-linearly
    return x
end


-- Called when the event is placed on the event queue. E.g. turn on meteor indicator
function Event.onQueue(rController, tUpcomingEventPersistentState, nPopulation, nElapsedTime)
    tUpcomingEventPersistentState.nDifficulty = Event.getDifficulty(nElapsedTime,nPopulation)
    tUpcomingEventPersistentState.nTargetTime = nElapsedTime
end

function Event.getDifficulty(nOptionalTime,nOptionalPopulation)
    if not nOptionalTime then nOptionalTime = GameRules.elapsedTime end
    if not nOptionalPopulation then nOptionalPopulation = CharacterManager.getOwnedCitizenPopulation() end
    nOptionalTime = math.min(nOptionalTime, g_EventController.nMaxPlaytime)
    nOptionalPopulation = math.min(nOptionalPopulation, g_nPopulationCap)

    -- TODO weight these two attributes.
    -- I am guessing time should affect difficulty the most
    local nTimeWeight = 0.75
    local nPopulationWeight = 1.0 - nTimeWeight
    -- Where on the difficulty curve are we
    local x = ((nOptionalTime / g_EventController.nMaxPlaytime) * nTimeWeight) + ((nOptionalPopulation / g_nPopulationCap) * nPopulationWeight)
    -- this should be in [0,1], but just in case
    x = math.min(1.0, math.max(0.0, x))

    return Event._difficultyCurve(x)
end

-- Called when the alert for this event is displayed.
-- Note not all events have alerts.
-- Note event is not executing yet, it is still in queue.
function Event.onAlertShown(rController, tUpcomingEventPersistentState)
end

-- called when the event is about to be popped off the queue and executed for the first time.
-- Return true if you want the event to go forward with execution.
-- Return false if event cannot execute and you want it discarded.
function Event.preExecuteSetup(rController, tUpcomingEventPersistentState)
    return true
end

-- called during event execution.
-- Return true when event is completed.
function Event.tick(rController, dT, tCurrentEventPersistentState, tCurrentEventTransientState)
    assertdev(false)
end

function Event.cleanup(rController)
end

-- attempts to get a tile of open space that is relatively near the base
-- !!NOT guaranteed to be an open space tile. We attempt nAttempt tries!!
function Event._getTileInOpenSpace(nAttempts)
    nAttempts = nAttempts or 5

    -- Grab exterior room, and trace out into space a certain distance.
    -- If you can't get an exterior room, choose a random direction
    -- from a random room
    local tExteriorRooms = {}
    local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    for room,id in pairs(tRooms) do
        if room.bExterior and not room:isDangerous() then
            table.insert(tExteriorRooms, room)
        end
    end
    local rRoomToTraceFrom = nil
    local tTileToTraceFrom = nil
    local nEmptySpaceDirection = nil
    local nMaxTraceDist = 20
    if #tExteriorRooms > 0 then
        rRoomToTraceFrom = DFUtil.arrayRandom(tExteriorRooms)
        local nExteriorTiles = DFUtil.tableSize(rRoomToTraceFrom.tExteriors)
        tTileToTraceFrom = DFUtil.tableRandom(rRoomToTraceFrom.tExteriors, nExteriorTiles)
        if not tTileToTraceFrom then return end
        nEmptySpaceDirection = g_World.getOppositeDirection(tTileToTraceFrom.nRoomDirection)
    else
        -- not an exterior room, but we can select a random room and
        -- trace from a border tile in the room
        local nRooms = DFUtil.tableSize(tRooms)
        _, rRoomToTraceFrom = DFUtil.tableRandom(tRooms, nRooms)
        if rRoomToTraceFrom then
            local nBorderTiles = DFUtil.tableSize(rRoomToTraceFrom.tExteriors)
            tTileToTraceFrom = DFUtil.tableRandom(rRoomToTraceFrom.tBorders, nBorderTiles)
            if not tTileToTraceFrom then return end
            nEmptySpaceDirection = g_World.getOppositeDirection(tTileToTraceFrom.nRoomDirection)
            -- trace farther out into space to be safe
            nMaxTraceDist = 30
        end
    end

    if not tTileToTraceFrom then return end

    -- trace out into space (hopefully)
    local tx, ty = tTileToTraceFrom.x, tTileToTraceFrom.y
    for nAttempt = 1, nAttempts do
        local nDist = math.random(15, nMaxTraceDist)
        for i = 1, nDist do
            tx, ty = g_World._getAdjacentTile(tx, ty, nEmptySpaceDirection)
        end
        tx, ty = g_World.clampTileToBounds(tx, ty)

        -- if we got an open tile of space, stop and return what we have
        if g_World._getTileValue(tx, ty, 1) == g_World.logicalTiles.SPACE then
            break
        else
            -- we're going to try this again! Try tracing out a little farther
            nMaxTraceDist = nMaxTraceDist + 5
            -- if not tracing from an exterior room, try a different direction as well
            if #tExteriorRooms == 0 then
                nEmptySpaceDirection = math.random(2, 9)
            end
        end
    end

    return tx, ty
end

-- HACK: Both DockingEvent and DerelictEvent need this, so it's in this file.
function Event._attemptDock(rController, tPersistentState)
    local tDockingData = Docking.attemptQueueEvent(
        tPersistentState.sEventType,
        tPersistentState.nDifficulty)
    
    if tDockingData then
        for k, v in pairs(tDockingData) do
            tPersistentState[k] = v
        end
        tPersistentState.bValidDockingData = true
        if not tPersistentState.bPrerolledSpawns then
            Event._prerollModuleSpawns(rController, tPersistentState)
            Event._preRollMalady(rController, tPersistentState, tPersistentState.nTargetTime or GameRules.elapsedTime)
        end
        if not tPersistentState.bPrerolledSpawns then
            tPersistentState.bValidDockingData = false
        end
    else
        tPersistentState.bValidDockingData = false
    end
    return tPersistentState.bValidDockingData
end

-- Once it comes time to preExecute, check if docking data is still valid.
-- TODO place this in a subclass of Event, DockingEvent
function Event._verifyDockingData(rController, tPersistentState)
    if tPersistentState.bValidDockingData and tPersistentState.bPrerolledSpawns then
        if Docking.testModuleFitAtOffset(tPersistentState.sEventType, 
                ModuleData[tPersistentState.sEventType][tPersistentState.sModuleEventName], 
                tPersistentState.sSetName,
                tPersistentState.sModuleName,
                tPersistentState.tx, tPersistentState.ty) then
            return true
        else
            return Event._attemptDock(rController, tPersistentState)
        end
    else
        -- didnt have valid docking data to begin with, so try and get
        -- some now
        return Event._attemptDock(rController, tPersistentState)
    end
end

function Event._getRandomDatacubeResearch()
    local tOptions,nOptions = Base.getAvailableDiscoveries()
    if nOptions == 0 then
        tOptions,nOptions = Base.getAvailableResearch()
    end
    if nOptions > 0 then
        return MiscUtil.randomKey(tOptions)
    end
end

function Event.getChallengeLevel(nOptionalDifficulty)
    if not nOptionalDifficulty then nOptionalDifficulty = Event.getDifficulty() end
    local nChallenge = math.min(1, math.max(0, nOptionalDifficulty - 0.15 + (math.random(0,30)/100.0)))
    return nChallenge
end

function Event._prerollModuleSpawns(rController, tPersistentState)
    if tPersistentState and tPersistentState.bValidDockingData then
        -- Preroll crew and objects if applicable.
        local tModule = Docking.getModule(tPersistentState.sSetName,tPersistentState.sModuleName)
        if tModule.tCrewSpawns then
            local tPrerolledCrew = {}
            for sLocName, tSpawnOptions in pairs(tModule.tCrewSpawns) do
                local spawnName = MiscUtil.weightedRandom(tSpawnOptions)
                if ModuleData.characterSpawns[spawnName] then
                    tPrerolledCrew[sLocName] = DFUtil.deepCopy( ModuleData.characterSpawns[spawnName] )
                    tPrerolledCrew[sLocName].sSpawnName = spawnName

                    -- if raider, pre-roll how difficult they are ie rifle?
                    if tPrerolledCrew[sLocName].tStats and tPrerolledCrew[sLocName].tStats.nRace == Character.RACE_RAIDER then
                        tPrerolledCrew[sLocName].tStats.nChallengeLevel = Event.getChallengeLevel(tPersistentState.nDifficulty)
                    end

                    -- preroll if they will have a malady
                    local rEventClass = rController.tEventClasses[tPersistentState.sEventType]
                    local nChanceOfMalady = (rEventClass and rEventClass.nChanceOfMalady) or 0
                    tPrerolledCrew[sLocName].bSpawnWithMalady = math.random(0,100) <= nChanceOfMalady
                end
            end
            tPersistentState.tCrewData = tPrerolledCrew
        end
        if tModule.tObjectSpawns then
            local tPrerolledObjects = {}
            for sLocName, tSpawnOptions in pairs(tModule.tObjectSpawns) do
                local spawnName = MiscUtil.weightedRandom(tSpawnOptions)
                if ModuleData.objectSpawns[spawnName] then
                    local sResearchData = nil
                    local sTemplate = ModuleData.objectSpawns[spawnName].sTemplate
                    if sTemplate == 'ResearchDatacube' then
                        sResearchData = Event._getRandomDatacubeResearch()
                    end
                    -- if no new research is found, we don't spawn it.
                    if sTemplate ~= 'ResearchDatacube' or sResearchData ~= nil then
                        tPrerolledObjects[sLocName] = ModuleData.objectSpawns[spawnName]
                        tPrerolledObjects[sLocName].sSpawnName = spawnName
                        if sResearchData then
                            if not tPrerolledObjects[sLocName].tSaveData then tPrerolledObjects[sLocName].tSaveData = {} end
                            tPrerolledObjects[sLocName].tSaveData.sResearchData = sResearchData
                            tPrerolledObjects[sLocName].tSaveData.bHasResearchData = true
                            local sFriendlyName = Base.getResearchName(sResearchData)
                            if sFriendlyName then
                                tPrerolledObjects[sLocName].tSaveData.sDesc = g_LM.line('PROPSX071TEXT') .. sFriendlyName
                            end
                        end
                    end
                end
            end
            tPersistentState.tObjectData = tPrerolledObjects
        end
        tPersistentState.bPrerolledSpawns = true
    end
end

function Event._preRollMalady(rController, tPersistentState, nElapsedTime)
    assertdev(nElapsedTime)
    if not nElapsedTime then nElapsedTime = 0 end
    -- choose which malady
    local tChoices = {}
    for sName, tData in pairs(rController.tEventClasses[tPersistentState.sEventType].tMaladyProbabilities) do
        tChoices[sName] = tData.nChanceOfAffliction or 0
    end
    local sMaladyTypeChoice = MiscUtil.weightedRandom(tChoices)
    -- decide if you should make a new strain
    local bMakeNewStrain = math.random(1,100) <= (rController.tEventClasses[tPersistentState.sEventType].tMaladyProbabilities[sMaladyTypeChoice].nChanceOfNewStrain or 0)

    local bRequireResearch = false
    local nResearchTime = nil
    if bMakeNewStrain then
        if nElapsedTime > 15 * 60 and (tPersistentState.nDifficulty or 0) > 0.15 then
            bRequireResearch = math.random() < Event.PROBABILITY_REQUIRES_RESEARCH
            nResearchTime = tPersistentState.nDifficulty * 1200
        end
    end
    
    tPersistentState.tPrerolledMalady = Malady.createNewMaladyInstance(sMaladyTypeChoice, not bMakeNewStrain, bRequireResearch, nResearchTime)
end

function Event.getModuleContentsDebugString(rController, tPersistentState)
    local s = ""
    local s2 = nil
    
    if tPersistentState.bValidDockingData and tPersistentState.bPrerolledSpawns then
        if tPersistentState.tCrewData then
            local tCrewTypes = {}
            local nNumSick = 0
            for sLoc, tData in pairs(tPersistentState.tCrewData) do
                local sName = tData.sSpawnName
                if tData.bSpawnWithMalady then
                    nNumSick = nNumSick+1
                end
                if not tCrewTypes[sName] then
                    tCrewTypes[sName] = 1
                else
                    tCrewTypes[sName] = tCrewTypes[sName] + 1
                end
            end
            local cs = ""
            for sCrewType, nNum in pairs(tCrewTypes) do
                if #sCrewType > 6 then
                    sCrewType = string.sub(sCrewType, 1, 6)
                end
                cs = cs .. tostring(nNum) .. " " .. sCrewType .. ", "
            end
            cs = string.sub(cs, 1, #cs - 2)
            s = s .. cs
            if nNumSick > 0 and tPersistentState.tPrerolledMalady then
                s2 = Event.getMaladyDebugString(tPersistentState, nNumSick)
            elseif nNumSick > 0 then
                s2 = 'ERROR: NO GENERATED MALADY'
            end
        end
        if tPersistentState.tObjectData then
            local tObjTypes = {}
            local nNumSick = 0
            for sLoc, tData in pairs(tPersistentState.tObjectData) do
                local sName = tData.sSpawnName
                if not tObjTypes[sName] then
                    tObjTypes[sName] = 1
                else
                    tObjTypes[sName] = tObjTypes[sName] + 1
                end

                -- Objects with maladies.
                if tData.bSpawnWithMalady then
                    nNumSick = nNumSick + 1
                end
            end
            local obs = ""
            for sObjType, nNum in pairs(tObjTypes) do
                if #sObjType > 5 then
                    sObjType = string.sub(sObjType, 1, 5)
                end
                obs = obs .. tostring(nNum) .. " " .. sObjType .. ", "
            end
            obs = string.sub(obs, 1, #obs - 2)
            if #s > 0 then
                s = s .. "; "
            end
            s = s .. obs
            if nNumSick > 0 and tPersistentState.tPrerolledMalady then
                if s2 then s2 = s2..'\n' else s2 = '' end
                s2 = s2.."ObjectMaladies: " .. Event.getMaladyDebugString(tPersistentState, nNumSick)
            elseif nNumSick > 0 then
                if s2 then s2 = s2..'\n' else s2 = '' end
                s2 = s2..'ERROR: NO GENERATED MALADY'
            end
        end
    elseif tPersistentState.nNumSpawns then
        local sType = "Friend"
        if tPersistentState.bHostile then
            sType = "Raider"
        end
        s = s .. string.format("%d %s", tPersistentState.nNumSpawns, sType)
        if tPersistentState.nNumMaladies > 0 and tPersistentState.tPrerolledMalady then
            s2 = Event.getMaladyDebugString(tPersistentState, tPersistentState.nNumMaladies)
        elseif tPersistentState.nNumMaladies > 0 then
            s2 = 'ERROR: NO GENERATED MALADY'
        end
    else
        s = "<no module data>"
    end
    return s .. " ", s2
end

function Event.getMaladyDebugString(tPersistentState, n)
    local s2 = string.format("{ %d /w %s ", n, tPersistentState.tPrerolledMalady.sMaladyName)
    local sStrainName = tPersistentState.tPrerolledMalady.sMaladyName
    if Malady.tS.tResearch[sStrainName] then
        local nResearchTime = Malady.tS.tResearch[sStrainName].nResearchCure - Malady.tS.tResearch[sStrainName].nCureProgress
        s2 = s2 .. string.format("rsrch %d }", nResearchTime)
    else
        s2 = s2 .. "no rsrch }"
    end
    return s2
end

function Event.getDebugString(rController, tPersistentState, tTransientState)
    local s = ""
    if tPersistentState then
        local n = tPersistentState.nStartTime - GameRules.elapsedTime
        local name = string.gsub(tPersistentState.sEventType, "Events", "")
        name = string.sub(name, 1, math.min(#name, 11))
        name = MiscUtil.padString(name, 11, true)
        local sModuleInfo1, sModuleInfo2 = rController.tEventClasses[tPersistentState.sEventType].getModuleContentsDebugString(rController, tPersistentState)
        s = string.format("%s [%1.2f] %s", name, tPersistentState.nDifficulty, sModuleInfo1)
		s = MiscUtil.padString(s, Event.nDebugLineLength, true)
		s = s .. MiscUtil.formatTime(n)
        if sModuleInfo2 then
            s = s .. string.format("\n    %s", sModuleInfo2)
        end
    end
    return s
end

function Event.pauseGame()
    GameRules.timePause()
end

function Event.resumeGame()
    if GameRules.getTimeScale() == 0 then
        GameRules.setTimeScale(1)
    end
end

return Event
