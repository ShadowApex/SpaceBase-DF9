local GameRules = require('GameRules')
local Class = require('Class')
local Room = nil
local ObjectList = require('ObjectList')
local Character = require('CharacterConstants')
local ResearchData = require('ResearchData')
local CharacterManager = nil
local Malady = nil

local Base = {}

Base.EVENTS=
{
    CitizenAttacked="CitizenAttacked",
    Breach="Breach",
    CitizenSuffocating="CitizenSuffocating",
    Default="Default",
    CitizenDied="CitizenDied",
    CitizenSkillUp="CitizenSkillUp",
    CitizenJoined="CitizenJoined",
    EventAlert="EventAlert",
    EventFailure="EventFailure",
    Fire="Fire",
    MaladyEncountered="MaladyEncountered",
    HostileInBase='HostileInBase',
    ResearchCompleted='ResearchCompleted',
    MaladyResearchCompleted='ResearchCompleted',
    DerelictFloataway='DerelictFloataway',
    CitizensBrawling='CitizensBrawling',
    CitizenTantrum='CitizenTantrum',
    CitizenRampage='CitizenRampage',
    GoalCompleted='GoalCompleted',
	BrigEscaped='BrigEscaped',
}

Base.EVENT_DATA = {
    CitizenAttacked=
    {
        sLineCode='ALERTS011TEXT',
        nPriority=1,
    },
    Breach=
    {
        sLineCode='ALERTS009TEXT',
        nPriority=1,
    },
    CitizenSuffocating=
    {
        sLineCode='ALERTS012TEXT',
        nPriority=1,
    },
    CitizenDied=
    {
        sLineCode="ALERTS007TEXT",
        nPriority=1,
    },
    CitizenSkillUp=
    {
        sLineCode='ALERTS013TEXT',
    },
    CitizenJoined=
    {
        sLineCode='ALERTS002TEXT',
    },
    EventAlert={ nPriority=1, },
    EventFailure={},
    Fire={ nPriority=1, },
    MaladyEncountered={nPriority=1,},
    ResearchCompleted=
    {
        sLineCode='ALERTS019TEXT',
    },
    MaladyResearchCompleted=
    {
        sLineCode='ALERTS034TEXT',
    },
    HostileInBase=
    {
        sLineCode='ALERTS017TEXT',
        nPriority=1,
    },
    DerelictFloataway=
    {
        sLineCode='ALERTS035TEXT',
    },
    CitizensBrawling=
    {
        sLineCode='ALERTS036TEXT',
    },
    CitizenTantrum = { sLineCode='ALERTS037TEXT' },
    CitizenRampage = { sLineCode='ALERTS038TEXT' },
	GoalCompleted = { sLineCode='ALERTS039TEXT' },
	BrigEscaped = { sLineCode='ALERTS042TEXT' },
    
    Default=
    {
        nLogVisibleTime=30,
        nPriority=0,
    },
}

local tInitialStats = {
	nMealsServed = 0,
	nCuresResearched = 0,
	nCorpsesRecycled = 0,
	nBreachShipsDestroyed = 0,
	nHostilesKilled = 0,
	nHostilesAsphyxiated = 0,
	nHostilesKilledByTurret = 0,
	nHostilesKilledByParasite = 0,
	nRaidersConverted = 0,
}

function Base.init()
    Room=require('Room')
    Malady=require('Malady')
    CharacterManager = require('CharacterManager')
    Base.tS = Base.tS or {}
    Base.tBedToChar = Base.tBedToChar or {}
    Base.tCharToBed = Base.tCharToBed or {}
    Base.tS.tResearch = Base.tS.tResearch or {}
    Base.tCurrentEvents = {}
	Base.tS.tGoals = Base.tS.tGoals or {}
	Base.tS.tStats = Base.tS.tStats or {}
	for sStat,nInitialValue in pairs(tInitialStats) do
		Base.tS.tStats[sStat] = Base.tS.tStats[sStat] or nInitialValue
	end
    Base.nNextTeamID = Character.TEAM_ID_FIRST_USABLE+1
    Base.tS.tTeamIDToFactionBehavior = {}
    Base.tS.tTeamIDToFactionBehavior[Character.TEAM_ID_PLAYER] = Character.FACTION_BEHAVIOR.Citizen
    Base.tS.tTeamIDToFactionBehavior[Character.TEAM_ID_DEBUG_ENEMYGROUP] = Character.FACTION_BEHAVIOR.EnemyGroup
    Base.tS.tTeamIDToFactionBehavior[Character.TEAM_ID_DEBUG_FRIENDLY] = Character.FACTION_BEHAVIOR.Friendly
    Base.tS.tTeamIDToFactionBehavior[Character.TEAM_ID_DEBUG_MONSTER] = Character.FACTION_BEHAVIOR.Monster
    Malady.reset()
    require('Zones.BrigZone').reset()
end

function Base.assignBed(rChar,rBed)
    Base._assign(rChar,rBed,Base.tCharToBed,Base.tBedToChar)
end

function Base._assign(rChar,rObj,tChar,tObj)
    if rChar and tChar[rChar.tag] then
        tObj[ tChar[rChar.tag] ] = nil
    end
    if rObj and tObj[rObj.tag] then
        tChar[ tObj[rObj.tag] ] = nil
    end
    
    if rObj then
        tObj[rObj.tag] = rChar and rChar.tag
    end
    if rChar then
        tChar[rChar.tag] = rObj and rObj.tag
    end
end

function Base.fromSaveData(tSaveData)
    Base.nNextTeamID = Character.TEAM_ID_FIRST_USABLE+1
    Base.tS = tSaveData
    Base.tS.tResearch = Base.tS.tResearch or {}
    Base.tS.tTeamIDToFactionBehavior = tSaveData.tTeamIDToFactionBehavior or {}
    for id,_ in pairs(Base.tS.tTeamIDToFactionBehavior) do
        Base.nNextTeamID = math.max(id+1,Base.nNextTeamID)
    end
    Base.tS.tTeamIDToFactionBehavior[Character.TEAM_ID_PLAYER] = Character.FACTION_BEHAVIOR.Citizen
    Malady.fromSaveData(tSaveData.tMalady or {})
    Base.tBedToChar = Base.tS.tBedToChar or {}
    Base.tCharToBed = Base.tS.tCharToBed or {}
	Base.tS.tGoals = Base.tS.tGoals or {}
	Base.tS.tStats = Base.tS.tStats or {}
	for sStat,nInitialValue in pairs(tInitialStats) do
		Base.tS.tStats[sStat] = Base.tS.tStats[sStat] or nInitialValue
	end
    -- savegame porting: handle changing research reqs.
    for k,tResearchInfo in pairs(ResearchData) do
        local tProgressData = Base.tS.tResearch[k]
        if tProgressData and tProgressData.bComplete then
            tProgressData.nResearchUnits = tResearchInfo.nResearchUnits
        end
    end
end

function Base.getSaveData()
    if not Base.tS then Base.tS = {} end
	--Base.tBaseName = Basename.getSaveData() -------------------------------- BASENAME
    Base.tS.tMalady = Malady.getSaveData()
    Base.tS.tBedToChar = Base.tBedToChar
    Base.tS.tCharToBed = Base.tCharToBed
    Base.tS.tBeacon = g_ERBeacon:getSaveTable()
    return Base.tS
end

function Base.incrementStat(sStatName)
	Base.tS.tStats[sStatName] = Base.tS.tStats[sStatName] + 1
end

function Base.getCurrentEvents()
    return Base.tCurrentEvents
end

-- rReporter: entity reporting the event.
-- nLogVisibleTime: optional: time to display the message
-- CitizenAttacked
--  rAttacker: hostile attacker
-- CitizenSkillUp:
--  nJob
-- CitizenDied
--  nCause
function Base.eventOccurred(eventType, tParams)
    local tExistingEvent = Base._getRelatedEvent(eventType,tParams)
    local tEventClassData = Base.EVENT_DATA[eventType]

    -- Combine with ongoing event or create a new one.
    --local bReused = tExistingEvent ~= nil
    if not tExistingEvent then 
        tExistingEvent = { eventType = eventType, nStartTime=GameRules.elapsedTime }
        table.insert(Base.tCurrentEvents, tExistingEvent)
    end
    if tParams.rReporter then 
        tExistingEvent.wx,tExistingEvent.wy = tParams.rReporter:getLoc()
        tExistingEvent.sReporterID = tParams.rReporter.getUniqueID and tParams.rReporter:getUniqueID()
        tExistingEvent.reporterTag = tParams.rReporter.tag
    end
    if tParams.wx then 
        tExistingEvent.wx,tExistingEvent.wy=tParams.wx,tParams.wy
    end
    if tParams.tPersistentData then 
        tExistingEvent.nUniqueEventID = tParams.tPersistentData.nUniqueID
    end
    
    -- Memories can be useful for other (non-log) systems.
    local tMemory = {wx=tExistingEvent.wx, wy=tExistingEvent.wy, sSource=tExistingEvent.sReporterID}

    if eventType == Base.EVENTS.CitizenAttacked then
        tMemory.sAttackerID=tParams.rAttacker and tParams.rAttacker:getUniqueID()
    end
    
    -- Post the log to the screen.
    local nVisibleDuration = (tParams.nLogVisibleTime or tEventClassData.nLogVisibleTime) or Base.EVENT_DATA.Default.nLogVisibleTime
    tExistingEvent.nEndTime = math.max(GameRules.elapsedTime+nVisibleDuration, tExistingEvent.nEndTime or 0)
    tExistingEvent.nLastUpdated = GameRules.elapsedTime
    tExistingEvent.nLastUpdatedStarDate = GameRules.sStarDate
    tExistingEvent.nPriority = tParams.nPriority or Base.EVENT_DATA[eventType].nPriority or Base.EVENT_DATA.Default.nPriority
    tExistingEvent.sCurrentAlertString = Base._getEventString(eventType, tParams, tExistingEvent)

    Base.storeMemory(eventType, tMemory )
end

Base._tDeathAlerts=
{
    [Character.CAUSE_OF_DEATH.UNSPECIFIED]="ALERTS007TEXT",
    [Character.CAUSE_OF_DEATH.DEBUG]="ALERTS008TEXT",
    [Character.CAUSE_OF_DEATH.SUFFOCATION]="ALERTS004TEXT",
    [Character.CAUSE_OF_DEATH.FIRE]="ALERTS005TEXT",
    [Character.CAUSE_OF_DEATH.DISEASE]="ALERTS006TEXT",
    [Character.CAUSE_OF_DEATH.COMBAT_RANGED]="ALERTS015TEXT",
    [Character.CAUSE_OF_DEATH.SUCKED_INTO_SPACE]="ALERTS014TEXT",
    [Character.CAUSE_OF_DEATH.PARASITE]="ALERTS016TEXT",
    [Character.CAUSE_OF_DEATH.STARVATION]="ALERTS018TEXT",
    [Character.CAUSE_OF_DEATH.COMBAT_MELEE]="ALERTS015TEXT",
    [Character.CAUSE_OF_DEATH.THING]="ALERTS043TEXT",
}

-- TEMP VERSION: just creates the single-event string. 
-- TODO: create a cool combined string, like "3 citizens have skilled up" or
-- "2 citizens have been shot and killed."
function Base._getEventString(eventType, tParams, tExistingEvent)
    local sText
    local tEventClassData = Base.EVENT_DATA[eventType]
    local sSourceName = (tParams.rReporter and tParams.rReporter.getNiceName and tParams.rReporter:getNiceName()) or 'NAME_MISSING'
    if eventType == Base.EVENTS.EventAlert or eventType == Base.EVENTS.EventFailure then
        sText = g_LM.line(tParams.sLineCode,{name=sSourceName})
    elseif eventType == Base.EVENTS.CitizenDied then
        local sLineCode = Base._tDeathAlerts[tParams.nCause or Character.UNSPECIFIED]
        if not sLineCode then 
            sLineCode = Base._tDeathAlerts[Character.UNSPECIFIED] 
        end
        sText = g_LM.line(sLineCode, {name=sSourceName, diseaseName=tParams.sDiseaseName})
    elseif eventType == Base.EVENTS.Fire then
        local zoneName = tParams.rRoom and tParams.rRoom:getZoneName()
        if zoneName and zoneName ~= 'PLAIN' then
            sText = g_LM.line('ALERTS001TEXT', {name=tParams.rRoom.uniqueZoneName})
        else
            sText = g_LM.line('ALERTS003TEXT')
        end
    elseif eventType == Base.EVENTS.CitizenSkillUp then
        sText = g_LM.line(tEventClassData.sLineCode, {name=sSourceName, job=g_LM.line(Character.JOB_NAMES[tParams.nJob])})
    elseif eventType == Base.EVENTS.MaladyEncountered then
        if Malady.isInjury(tParams.tMalady.sMaladyName) then
            -- let's just not alert about these. Looks silly.
        elseif Malady.hasDiscoveredCure(tParams.tMalady.sMaladyName) then
            sText = g_LM.line('ALERTS022TEXT',{name=Malady.getFriendlyName(tParams.tMalady.sMaladyName)})
        elseif Malady.hasIdentifiedDisease(tParams.tMalady.sMaladyName) then
            sText = g_LM.line('ALERTS021TEXT',{name=Malady.getFriendlyName(tParams.tMalady.sMaladyName)})
        else
            sText = g_LM.line('ALERTS020TEXT')
        end
    elseif eventType == Base.EVENTS.ResearchCompleted or eventType == Base.EVENTS.MaladyResearchCompleted then
        sText = g_LM.line(tEventClassData.sLineCode, {research=Base.getResearchName(tParams.sKey)})
    elseif eventType == Base.EVENTS.CitizensBrawling then
        sText = g_LM.line(tEventClassData.sLineCode, {name=tParams.sRoom})
    elseif eventType == Base.EVENTS.CitizenTantrum then
        sText = g_LM.line(tEventClassData.sLineCode, {name=tParams.sName, place=tParams.sRoom})
    elseif eventType == Base.EVENTS.CitizenRampage then
        sText = g_LM.line(tEventClassData.sLineCode, {name=tParams.sName, place=tParams.sRoom})
	elseif eventType == Base.EVENTS.GoalCompleted then
		sText = g_LM.line(tEventClassData.sLineCode, {name=tParams.sGoal})
	elseif eventType == Base.EVENTS.BrigEscaped then
		sText = g_LM.line(tEventClassData.sLineCode, {name=tParams.sName, place=tParams.sRoom})
    else
		sText = g_LM.line(tEventClassData.sLineCode, {name=sSourceName})
    end
    return sText
end

-- TEMP VERSION:
-- returns event of the same type.
-- TODO: intelligently combine.
function Base._getRelatedEvent(eventType,tParams)
    for i,v in ipairs(Base.tCurrentEvents) do
        if eventType == Base.EVENTS.EventAlert or eventType == Base.EVENTS.EventFailure then
            if v.nUniqueEventID and tParams.tPersistentData and tParams.tPersistentData.nUniqueID == v.nUniqueEventID then
                return v
            end
        elseif v.eventType == eventType then
            return v
        end
    end
end

function Base.storeMemory(key, val, nDuration)
    Base.tS.tMemory = Base.tS.tMemory or {}

    nDuration = nDuration or 10
    Base.tS.tMemory[key] = {val=val, nTime=GameRules.simTime, nDuration=nDuration}
end

function Base.clearMemory(key)
    Base.tS.tMemory = Base.tS.tMemory or {}
    
    Base.tS.tMemory[key] = nil
end

function Base.retrieveMemory(key)
    Base.tS.tMemory = Base.tS.tMemory or {}
    
    local tMemory = Base.tS.tMemory[key]
    if tMemory then
        if GameRules.simTime - tMemory.nTime > tMemory.nDuration then
            Base.tS.tMemory[key] = nil
            return nil
        else
            return tMemory.val,tMemory.nTime
        end
    end
end

function Base.createNewTeamID(nFactionBehavior)
    if nFactionBehavior == Character.FACTION_BEHAVIOR.Citizen then return Character.TEAM_ID_PLAYER end
    
    while Base.tS.tTeamIDToFactionBehavior[Base.nNextTeamID] ~= nil do
        Base.nNextTeamID = Base.nNextTeamID+1
    end
    
    local nTeam = Base.nNextTeamID
    Base.nNextTeamID = Base.nNextTeamID + 1
    Base.tS.tTeamIDToFactionBehavior[nTeam] = nFactionBehavior
    return nTeam
end

function Base._fillInTeamBehaviorForOldSaves(rEnt,nTeam)
    if rEnt.tStats and rEnt.tStats.nFactionBehavior then 
        Base.tS.tTeamIDToFactionBehavior[nTeam] = rEnt.tStats.nFactionBehavior
        print('Writing faction behavior for team ',nTeam,' Setting to: ',rEnt.tStats.nFactionBehavior)
    else
        if nTeam == Character.TEAM_ID_PLAYER then 
            Base.tS.tTeamIDToFactionBehavior[nTeam] = Character.FACTION_BEHAVIOR.Citizen
            --print('Writing player faction behavior for team ',nTeam)
        else
            Base.tS.tTeamIDToFactionBehavior[nTeam] = Character.FACTION_BEHAVIOR.EnemyGroup
            print('Guessing at faction behavior',(rEnt.getUniqueID and rEnt:getUniqueID()) or 'unnamed',nTeam)
        end
    end
    return Base.tS.tTeamIDToFactionBehavior[nTeam]
end

function Base._getFactionBehavior(rEnt)
    local nTeam = rEnt:getTeam()
    local nFactionBehavior = Base.tS.tTeamIDToFactionBehavior[nTeam]
    -- Old save support. With new saves, all team IDs should get faction behaviors assigned at creation time.
    if not nFactionBehavior then
        nFactionBehavior = Base._fillInTeamBehaviorForOldSaves(rEnt,nTeam)
    end
    return nFactionBehavior 
end

function Base.getTeamFactionBehavior(nTeam)
    local nFactionBehavior = Base.tS.tTeamIDToFactionBehavior[nTeam]
    if nFactionBehavior then return nFactionBehavior end
    
    return nFactionBehavior or Character.FACTION_BEHAVIOR.EnemyGroup
end

function Base._characterInit(tStats)
    if not tStats or not tStats.nTeam or not tStats.nFactionBehavior then return end
    
    if tStats.nTeam > Character.TEAM_ID_PLAYER and tStats.nTeam < Character.TEAM_ID_FIRST_USABLE then
        Print(TT_Warning, "Character initializing with debug team ID.", tStats.sUniqueID, tStats.nTeam, tStats.nFactionBehavior)
    end
    
    if not Base.tS.tTeamIDToFactionBehavior[tStats.nTeam] then
        Base.tS.tTeamIDToFactionBehavior[tStats.nTeam] = tStats.nFactionBehavior
    end
    Base.nNextTeamID = math.max(Base.nNextTeamID,tStats.nTeam+1)
end

function Base.setTeamFactionBehavior(nTeam,nBehavior)
    Base.tS.tTeamIDToFactionBehavior[nTeam] = nBehavior
end

function Base.isFriendlyToPlayer(rEnt)
    local nTeam = rEnt:getTeam()
    local nFactionBehavior = Base._getFactionBehavior(rEnt)
    return nFactionBehavior == Character.FACTION_BEHAVIOR.Citizen or nFactionBehavior == Character.FACTION_BEHAVIOR.Friendly
end

function Base.isFriendly(rA,rB)
    local nTeamA = rA:getTeam()
    local nTeamB = rB:getTeam()
    if nTeamA == nTeamB then return true end

    local nFactionBehaviorA = Base._getFactionBehavior(rA)
    local nFactionBehaviorB = Base._getFactionBehavior(rB)

    -- If A is friendly or citizen, then we like anyone else who's friendly or citizen.
    if nFactionBehaviorA == Character.FACTION_BEHAVIOR.Citizen or nFactionBehaviorA == Character.FACTION_BEHAVIOR.Friendly then
        return nFactionBehaviorB == Character.FACTION_BEHAVIOR.Citizen or nFactionBehaviorB == Character.FACTION_BEHAVIOR.Friendly
    end
    -- So A is monster, enemy group, or killbot.
    -- Current heuristic: 
    -- Raiders hate raiders on other teams.
    -- Monsters hate raiders but love monsters.
    -- Killbots are treated identically to raiders.
    if nFactionBehaviorA == Character.FACTION_BEHAVIOR.Monster then
        return nFactionBehaviorB == Character.FACTION_BEHAVIOR.Monster
    end
    return nTeamA == nTeamB
end

function Base.isHostileInBase(bIncludeIncapacitated)
    local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    
    for rRoom,_ in pairs(tRooms) do
        local tChars = rRoom:getCharactersInRoom(true)
        for rChar,_ in pairs(tChars) do
            if not Base.isFriendlyToPlayer(rChar) then
                if bIncludeIncapacitated or (not Malady.isIncapacitated(rChar) and not rChar.tStatus.bCuffed and not rChar:inPrison()) then
                    return true,rChar
                end
            end
        end
    end
    
    return false
end

function Base.freeShelving()
	-- returns free shelving capacity relative to how much stuff people have
	-- these values are computed in HintChecks.noShelving and cached here
	if Base.nCurrentStuff and Base.nCurrentShelvingCapacity then
		return Base.nCurrentShelvingCapacity - Base.nCurrentStuff
	else
		-- probably HintChecks.noShelving just hasn't run yet
		return 0
	end
end

function Base.onTick(dt)
    if dt <= 0 then return end
    
    if Base.retrieveMemory(Base.EVENTS.HostileInBase) == nil then
        local isHostile,rChar = Base.isHostileInBase()
        if isHostile then
            Base.storeMemory(Base.EVENTS.HostileInBase, rChar:getUniqueID(), 60)
            Base.eventOccurred(Base.EVENTS.HostileInBase, {rReporter=rChar})
        end
    end
    for i=#Base.tCurrentEvents,1,-1 do
        local t = Base.tCurrentEvents[i]
        if t.nEndTime < GameRules.elapsedTime then
            table.remove(Base.tCurrentEvents,i)
        end
    end
end

function Base.getAvailableDiscoveries()
    return Base._getAvailableResearch(true)
end

function Base.getAvailableResearch()
    return Base._getAvailableResearch(false)
end

function Base.getDiscoveredResearch()
	-- returns all research that is discovered, even if locked behind a
	-- non-discovery prereq
    local tOptions = {}
    local nOptions = 0
    for k,tResearchInfo in pairs(ResearchData) do
		local tProgressData = Base.tS.tResearch[k]
        if Base.isDiscovered(k) then
			tOptions[k] = tProgressData or {}
			nOptions = nOptions + 1
		end
	end
    return tOptions,nOptions
end

function Base._getAvailableResearch(bOnlyDiscoveries)
    local tOptions = {}
    local nOptions = 0
    for k,tResearchInfo in pairs(ResearchData) do
        local tProgressData = Base.tS.tResearch[k]
        if (bOnlyDiscoveries and tResearchInfo.bDiscoverOnly) or (not bOnlyDiscoveries and not tResearchInfo.bDiscoverOnly) then
            if not tProgressData or not tProgressData.bComplete then
                local bCanResearch = true
                for _,sPrereqName in ipairs(tResearchInfo.tPrereqs) do
                    if not Base.hasCompletedResearch(sPrereqName) then
                        bCanResearch = false
                        break
                    end
                end
                if bCanResearch then
                    tOptions[k] = tProgressData or {}
                    nOptions = nOptions+1
                end
            end
        end
    end
    return tOptions,nOptions
end

function Base.hasCompletedResearch(sProject)
	local tData = Base.getCompletedResearch()
	for sOtherProject,_ in pairs(tData) do
		if sOtherProject == sProject then
			return true
		end
	end
end

function Base.canResearch(sKey)
    local tOptions = Base.getAvailableResearch()
    if tOptions[sKey] then
        return true
    end
    tOptions = Malady.getAvailableResearch()
    if tOptions[sKey] then
        return true
    end
    return false
end

-- returns name,desc from a key into the ResearchData table.
function Base.getResearchName(sKey)
    local tResearchData = ResearchData[sKey]
    assertdev(sKey)
    
    local sName, sDesc

    if not tResearchData then
        sName = Malady.getFriendlyName(sKey)
        if sName then
            return sName,Malady.getDescription(sKey)
        end
        assertdev(false)
        return
    end

    if tResearchData.sItemForDesc then
        local tEOData = require('EnvObjects.EnvObject').getObjectData(tResearchData.sItemForDesc)
        assertdev(tEOData)
        if not tEOData then return sName,sDesc end
		sName = tEOData.friendlyNameLinecode
		sDesc = tEOData.description
    else
		sName = tResearchData.sName
		sDesc = tResearchData.sDesc
    end
    if sName then sName = g_LM.line(sName) else sName = '' end
    if sDesc then sDesc = g_LM.line(sDesc) else sDesc = '' end
    
	-- add [Blueprint] if it's a blueprint (ie only exists to be a prereq)
	if tResearchData.bDiscoverOnly then
		sName = string.format('%s [%s]', sName, g_LM.line('PROPSX072TEXT'))
	end

    return sName, sDesc
end

function Base.addResearch(sKey, nAmount)
    assertdev(sKey)
    if not sKey then return end
    
    if Malady.getCompletedResearch()[sKey] then
        -- nothing
    elseif Malady.getAvailableResearch()[sKey] then
        if Malady.addResearch(sKey,nAmount) then
            Base.eventOccurred(Base.EVENTS.MaladyResearchCompleted, {sKey=sKey})
			Base.incrementStat('nCuresResearched')
        end
    else
        local tProgressData = Base.tS.tResearch[sKey]
        nAmount = math.floor(nAmount+.5)
        if not tProgressData then
            tProgressData = {}
            Base.tS.tResearch[sKey] = tProgressData
            tProgressData.nResearchUnits = 0
        end
        if not tProgressData.bComplete then
            tProgressData.nResearchUnits = tProgressData.nResearchUnits+nAmount
            if tProgressData.nResearchUnits >= ResearchData[sKey].nResearchUnits then
                tProgressData.nResearchUnits = ResearchData[sKey].nResearchUnits
                tProgressData.bComplete = true
                -- alert announcement
                if ResearchData[sKey].bDiscoverOnly then
                    -- JPL TODO: display "X unlocked for research" for discoveries,
                    -- but only if all other prereqs are met
                else
                    Base.eventOccurred(Base.EVENTS.ResearchCompleted, {sKey=sKey})
                end
            end
        end
    end
end

function Base.isDiscovered(sKey)
	-- returns true if the research topic is known about, ie all discovery prereqs met
	local tResearchInfo = ResearchData[sKey]
	if not tResearchInfo then
		return false
	end
	-- exclude meta "discovery" research projects
	if tResearchInfo.bDiscoverOnly then
		return false
	end
	for _,sPrereq in pairs(tResearchInfo.tPrereqs) do
		if ResearchData[sPrereq].bDiscoverOnly and not Base.hasCompletedResearch(sPrereq) then
			return false
		end
	end
	return true
end

function Base.isUnlocked(sKey)
	-- returns true if all prereqs are complete (including discovery)
	local tResearchInfo = ResearchData[sKey]
	if not tResearchInfo then
		return false
	end
	for _,sPrereq in pairs(tResearchInfo.tPrereqs) do
		if not Base.hasCompletedResearch(sPrereq) then
			return false
		end
	end
	return true
end

function Base.getCompletedResearch()
    local tOptions = {}
	local nOptions = 0
    for k,tResearchInfo in pairs(ResearchData) do
        local tProgressData = Base.tS.tResearch[k]
        if tProgressData and tProgressData.bComplete then
            tOptions[k] = tProgressData
			nOptions = nOptions + 1
        end
    end
    return tOptions, nOptions
end

return Base
