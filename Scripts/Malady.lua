local DFGraphics = require('DFCommon.Graphics')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local MiscUtil = require('MiscUtil')
local Base = require('Base')
local GameRules = require('GameRules')
local MaladyData = require('MaladyData')
local ActivityOption = require('Utility.ActivityOption')
local Character = require('CharacterConstants')
local CharacterManager = require('CharacterManager')
local Log = require('Log')
local GridUtil = require('GridUtil')
local Room = require('Room')
local Zone = require('Zones.Zone')
local ObjectList = require('ObjectList')
local Class=require('Class')

local Malady = {}

Malady.MEMORY_HP_HEALED_RECENTLY = 'bGotHPHealedRecently'
Malady.FIELD_HP_COOLDOWN = 60*10

Malady.CHECKUP_COOLDOWN = 60*4
Malady.TIME_TO_WORRY = 60*6
Malady.INV_TIME_TO_WORRY = 1/Malady.TIME_TO_WORRY
Malady.MAX_SKILL = -1
-- multiple scrubbers can only make infection chance this low
Malady.MIN_SPREAD_CHANCE = 0.1

Malady.INCAPACITATED_ACTIVITIES_ALLOWED = {
    IncapacitatedOnFloor=true,
    GetFieldScanned=true,
}

Malady.ANIM_SNEEZE = 'sneeze'
Malady.ANIM_SNEEZE_RANGE = {45,90}
Malady.LOG_RANGE = {60*2,60*6}

function Malady.reset()
    Malady.tS = { tResearch={}, tMaladyStrains={}, tUsedNames={} }

    local gatherFn = function(rChar) 
        local tIncapacitatedActivities = rChar:_getSelfUtilityOptions()
        table.insert(tIncapacitatedActivities, ActivityOption.new('IncapacitatedOnFloor', {bInfinite=true}) )
        return { {tUtilityOptions=tIncapacitatedActivities} }
    end

    Malady._incapacitatedGatherers = {}
    Malady._incapacitatedGatherers.IncapacitatedActivities=
    {
        gatherFn=gatherFn,
    }
    Malady._updateMaladySaveData()
end

function Malady.fromSaveData(tSaveData)
    Malady.tS = tSaveData
    Malady._updateMaladySaveData()
end

-- Updates Malady.tS to get new malady types etc.
function Malady._updateMaladySaveData()
    if not Malady.tS.tResearch then Malady.tS.tResearch = {} end    
    if not Malady.tS.tMaladyStrains then Malady.tS.tMaladyStrains = {} end
    if not Malady.tS.tUsedNames then Malady.tS.tUsedNames = {} end
    for sMaladyType,tMaladySpec in pairs(MaladyData) do
        tMaladySpec.sMaladyType = sMaladyType
        if not tMaladySpec.bNoCreate then
            -- Create the single instance of no-strain maladies, such as Incapacitated.
            if not tMaladySpec.bCreateStrains and not Malady.tS.tMaladyStrains[sMaladyType] then
                Malady.tS.tMaladyStrains[sMaladyType] = { sMaladyType=sMaladyType, sFriendlyName=g_LM.line(tMaladySpec.sFriendlyName) }
            end
        end
    end
    for sMaladyName,tResearchData in pairs(Malady.tS.tResearch) do
        if not tResearchData.nCureProgress then
            tResearchData.nCureProgress = 0
        end
        if not tResearchData.nResearchCure then
            tResearchData.nResearchCure = 0
        end
        tResearchData.bMalady = true
    end
end

local tDiseaseAdjectives = { 'DISEAS004TEXT', 'DISEAS005TEXT', 'DISEAS006TEXT',
							 'DISEAS011TEXT', 'DISEAS012TEXT', 'DISEAS014TEXT',
							 'DISEAS015TEXT', 'DISEAS016TEXT', 'DISEAS018TEXT',
						 }
local tDiseaseNouns = { 'DISEAS007TEXT', 'DISEAS008TEXT', 'DISEAS009TEXT',
						'DISEAS010TEXT', 'DISEAS013TEXT', 'DISEAS017TEXT',
						'DISEAS019TEXT', 'DISEAS020TEXT', 
					}

local tDiseaseSpecials = { 'DISEAS021TEXT', }

function Malady.getDiseaseName()
    -- pattern: [Provenance] Adjective Name
    -- examples: Orange Flu, Venusian Crawling Hives
    local sName = ''
    if math.random() < 0.75 then
        sName = require('Topics').getRandomProvenance() .. ' '
    end
    sName = sName .. g_LM.randomLine(tDiseaseAdjectives) .. ' '
    sName = sName .. g_LM.randomLine(tDiseaseNouns)
    -- small chance for a special name
    if math.random() < 0.025 then
        sName = g_LM.randomLine(tDiseaseSpecials)
    end
    return sName
end

function Malady.getNewDiseaseName()
    local nTries = 0
    local nNumSuffixes = 0
    while true do
        -- put core name generation logic in its own function so that
        -- citizens can talk about made-up (ie not "real") diseases
        local sName = Malady.getDiseaseName()

        for i=1,nNumSuffixes do
            sName = sName..' '..g_LM.randomLine(Zone.greekLetters)
        end

        if not Malady.tS.tUsedNames[sName] then
            Malady.tS.tUsedNames[sName] = 1
	        return sName
        end

        nTries = nTries+1
        if nTries > 20+nNumSuffixes*20 then
            nNumSuffixes = nNumSuffixes + 1
        end
    end
end

function Malady.getSaveData()
    return Malady.tS
end

-- Updates a character's saved malady table to get newer default values.
function Malady.updateSavedMaladies(tMaladies)
    if tMaladies then
        for sMaladyName,tMalady in pairs(tMaladies) do
            for k,v in pairs(MaladyData.Default) do
                if not tMalady[k] and k ~= 'bNoCreate' then
                    tMalady[k] = v
                end
            end
        end
    end
end

function Malady.getNextUndiagnosedMalady(rChar)
    local tMaladies = rChar.tStatus.tMaladies
    if not tMaladies then return end
    
    for sMaladyName,tData in pairs(tMaladies) do
        if not tData.bDiagnosed then
            return sMaladyName,tData
        end
    end
end

function Malady.getNextCurableMalady(rChar,nSkillLevel)
    local tMaladies = rChar.tStatus.tMaladies
    if not tMaladies then return end
    
    for sMaladyName,tData in pairs(tMaladies) do
        if not tData.bIncurable and Malady.hasDiscoveredCure(sMaladyName) and (nSkillLevel == Malady.MAX_SKILL or nSkillLevel >= tData.nFieldTreatSkill) then
            return sMaladyName,tData
        end
    end
end

function Malady.isIncapacitated(rChar)
    if not rChar.tStatus.tMaladies then return false end
    if rChar:spacewalking() then return false end
    
    for sMaladyName,tMalady in pairs(rChar.tStatus.tMaladies) do
        if tMalady.bSymptomatic and tMalady.bIncapacitated then
            return true
        end
    end
end

function Malady.diseaseEncountered(tMaladyData,rChar)
    local sMaladyName = tMaladyData.sMaladyName
    if not Malady.tS.tResearch[sMaladyName] then Malady.tS.tResearch[sMaladyName] = { nResearchCure=0, nCureProgress=0, bMalady=true } end
    if not Malady.tS.tResearch[sMaladyName].bEncountered then
		-- never show malady alerts for hostiles
		if not Malady.isInjury(sMaladyName) and rChar:isPlayersTeam() then
			Base.eventOccurred(Base.EVENTS.MaladyEncountered,{rReporter=rChar, tMalady=tMaladyData})
		end
		-- only make new malady available for research if a citizen has it
		if rChar:isPlayersTeam() then
			Malady.tS.tResearch[sMaladyName].bEncountered = true
		end
    end
end

function Malady.hasEncounteredDisease(sMaladyName)
    return Malady.tS.tResearch[sMaladyName] and Malady.tS.tResearch[sMaladyName].bEncountered
end

function Malady.hasIdentifiedDisease(sMaladyName)
    -- MTF: not using this functionality. As soon as you encounter a disease, you know its name.
    return true
end

function Malady.hasDiscoveredCure(sMaladyName)
    if not Malady.tS.tResearch[sMaladyName] or not Malady.tS.tResearch[sMaladyName].nResearchCure then
        return true
    end
    if Malady.tS.tResearch[sMaladyName].nCureProgress < Malady.tS.tResearch[sMaladyName].nResearchCure then
        return false
    end
    return true
end

function Malady.reproduceMalady(tMaladyData)
    local tMalady = DFUtil.deepCopy(tMaladyData)
    assert(not tMalady.bNoCreate)
    for k,v in pairs(MaladyData.Default) do
        if not tMalady[k] and k ~= 'bNoCreate' then
            tMalady[k] = v
        end
    end
    tMalady.nMaladyStart = GameRules.elapsedTime-.01
    if not tMalady.tSymptomStages then
        tMalady.nMaladyEnd = Malady._nextTime(tMalady.tDurationRange)
    end
    if tMalady.tTimeToContagious then
        tMalady.nContagiousStart = Malady._nextTime(tMalady.tTimeToContagious)
    elseif not tMalady.tSymptomStages and (tMalady.bSpreadSneeze or tMalady.bSpreadTouch) then
        tMalady.bContagious = true
    end
    if tMalady.tTimeToSymptoms then
        tMalady.nSymptomStart = Malady._nextTime(tMalady.tTimeToSymptoms)
    elseif not tMalady.tSymptomStages then
        tMalady.nSymptomStart = GameRules.elapsedTime-.01
    end
    if tMalady.preSymptomaticLog then
        tMalady.nNextPreSymptomLog = Malady._nextTime(Malady.LOG_RANGE)
    end

    if tMalady.tSymptomStages then
        Malady._initSymptomStarts(tMalady)
    end

    return tMalady
end

function Malady._initSymptomStarts(tMalady)
    tMalady.tSymptomStarts = {}
    for i,v in ipairs(tMalady.tSymptomStages) do
        tMalady.tSymptomStarts[i] = Malady._nextTime(v.tTimeToSymptoms)
    end
    tMalady.nCurrentStage = 0
end

-- TODO / HACKY STRAIN-NAME CREATION:
-- For now just takes an existing friendly name and adds a number to the end. Need something more like Topic.tTopics.
function Malady._createNewStrain(tMaladySpec, bRequireResearch, nResearchTimeOverride)
    local i = 0
    
    assert(tMaladySpec.bCreateStrains)
    local sMaladyType = tMaladySpec.sMaladyType
    local sMaladyName = sMaladyType .. i
    while Malady.tS.tMaladyStrains[sMaladyName] do
        i = i+1
        sMaladyName = sMaladyType .. i
    end
    local sFriendlyName = Malady.getNewDiseaseName()
    Malady.tS.tMaladyStrains[sMaladyName] = { sMaladyName=sMaladyName, sMaladyType=sMaladyType, sFriendlyName=sFriendlyName }
    if bRequireResearch then
        local nResearchCure = math.floor(nResearchTimeOverride)
        if nResearchCure == nil then
            nResearchCure = math.floor(math.random()*14)
            nResearchCure = 200 + nResearchCure*100
        end
        nResearchCure = math.floor(nResearchCure)
        Malady.tS.tResearch[sMaladyName] = { nResearchCure = nResearchCure, nCureProgress=0, bMalady=true }
    end
    return sMaladyName
end

function Malady.getFriendlyName(sMaladyName)
    return Malady.tS.tMaladyStrains[sMaladyName] and Malady.tS.tMaladyStrains[sMaladyName].sFriendlyName
end

function Malady.isInjury(sMaladyName)
	-- returns true if this malady has the "injury" flag used to distinguish
	-- things like broken legs
    local sMaladyType = Malady.tS.tMaladyStrains[sMaladyName] and Malady.tS.tMaladyStrains[sMaladyName].sMaladyType
	return sMaladyType and MaladyData[sMaladyType] and MaladyData[sMaladyType].bIsInjury
end

function Malady.getDescription(sMaladyName)
    local sMaladyType = Malady.tS.tMaladyStrains[sMaladyName].sMaladyType
    return sMaladyType and MaladyData[sMaladyType].sDesc
end

-- Rough guess at the badness of a malady. Should maybe just pick a number to hardcode in MaladyData?
-- returns 0-1.
function Malady.getMaladyDifficulty(tMalady)
    local nRemainingResearch = 0
    local sMaladyName = tMalady.sMaladyName

    if not Malady.hasDiscoveredCure(sMaladyName) then
        nRemainingResearch = Malady.tS.tResearch[sMaladyName].nResearchCure - Malady.tS.tResearch[sMaladyName].nCureProgress
    end
    nRemainingResearch = math.min(.2, .2 * nRemainingResearch / 1500)

    local nSeverity = math.min(.4, .35 * (tMalady.nSeverity + (tMalady.nAdditionalDeadliness or 0)))

    local nPerceptionGap = math.max(0,math.min(.1, 0.25 * (tMalady.nSeverity - tMalady.nPerceivedSeverity)))

    local nContagiousness = 0
    if tMalady.bSpreadSneeze then nContagiousness = nContagiousness + .15 end
    if tMalady.bSpreadTouch then nContagiousness = nContagiousness + .15 end

    --print('contag',nContagiousness,'sev',nSeverity,'percept',nPerceptionGap,'resrch',nRemainingResearch)

    return nContagiousness + nSeverity + nPerceptionGap + nRemainingResearch
end

function Malady.createNewMaladyInstance(sMaladyType, bUseExistingStrain, bRequireResearch, nResearchTimeOverride)
    local tMaladySpec = DFUtil.deepCopy( MaladyData[sMaladyType] )
    tMaladySpec.sMaladyName = nil
    
    if tMaladySpec.bCreateStrains then
        if bUseExistingStrain then
            -- gather strains for choosing
            local tStrains = {}
            if Malady.tS and Malady.tS.tMaladyStrains then
                for sStrainName, tStrainData in pairs(Malady.tS.tMaladyStrains) do
                    if tStrainData.sMaladyType == sMaladyType then
                        table.insert(tStrains, sStrainName)
                    end
                end
            end
            if #tStrains > 0 then
                -- choose a random strain
                tMaladySpec.sMaladyName = Malady.tS.tMaladyStrains[tStrains[math.random(1,#tStrains)]].sMaladyName
            end
        end
        if not tMaladySpec.sMaladyName then
            -- don't reuse strain, or no existing strain found above (fall-through case).
            tMaladySpec.sMaladyName = Malady._createNewStrain(tMaladySpec, bRequireResearch, nResearchTimeOverride)
        end
    else
        tMaladySpec.sMaladyName = sMaladyType
    end
    tMaladySpec.sMaladyType = sMaladyType
    
    return Malady.reproduceMalady(tMaladySpec)
end

function Malady._nextTime(tRange)
    return GameRules.elapsedTime+math.random(tRange[1],tRange[2])-.01
end

function Malady.getNeedsReduceMods(rChar,sNeedName)
    local tMaladies = rChar.tStatus.tMaladies
    local tReduceMods = nil
    if tMaladies then
        local nReduceModsSev = -1
        for sMaladyName,tMalady in pairs(tMaladies) do
            if tMalady.tReduceMods and tMalady.bSymptomatic then
                if tMalady.tReduceMods and tMalady.nSeverity > nReduceModsSev then
                    tReduceMods = tMalady.tReduceMods
                end
            end
        end
    end
    return tReduceMods
end

function Malady.tickMaladies(rChar)
    if rChar:getCurrentTaskName() == 'CheckInToHospital' then 
        return 
    end
    local tMaladies = rChar.tStatus.tMaladies
    if tMaladies then
        for sMaladyName,tMalady in pairs(tMaladies) do
            Malady._tickMalady(rChar,tMalady)
        end
    end
end

function Malady._tickMalady(rChar,tMalady)
	if tMalady.nMaladyEnd and tMalady.nMaladyEnd < GameRules.elapsedTime then
		rChar:cure(tMalady.sMaladyName)
		return
	end
	assertdev(tMalady.nMaladyEnd or tMalady.tSymptomStarts)

	-- Check for stage increment of staged diseases.
	-- When we get to a new stage, just copy all the new data from the symptom stage
	-- into the running malady.
	if tMalady.tSymptomStarts then
		local nNextStage = tMalady.nCurrentStage+1

		if nNextStage > #tMalady.tSymptomStarts and tMalady.bStagesLoop then
			Malady._initSymptomStarts(tMalady)
			nNextStage = 1
		end

		if tMalady.tSymptomStarts[nNextStage] and tMalady.tSymptomStarts[nNextStage] < GameRules.elapsedTime then
			tMalady.nCurrentStage = nNextStage
			tMalady.nSymptomStart = GameRules.elapsedTime-1
			
			for k,v in pairs(tMalady.tSymptomStages[nNextStage]) do
				if k ~= 'tTimeToSymptoms' then
					tMalady[k] = v
				end
			end
		end
		if not tMalady.tSymptomStarts[tMalady.nCurrentStage+1] and not tMalady.nMaladyEnd and not tMalady.bStagesLoop then
			-- Default end time for staged maladies that don't specify a final stage duration.
			tMalady.nMaladyEnd = Malady._nextTime(MaladyData.Default.tDurationRange)
		end
	end

	if not tMalady.bContagious and tMalady.nContagiousStart and tMalady.nContagiousStart < GameRules.elapsedTime then
		tMalady.bContagious = true
	end
	if not tMalady.bSymptomatic and tMalady.nSymptomStart and tMalady.nSymptomStart < GameRules.elapsedTime then
		tMalady.bSymptomatic = true
		Malady.diseaseEncountered(tMalady,rChar)
	end
	if tMalady.bSymptomatic and tMalady.bSpreadSneeze and not tMalady.nNextSneezeTime then
		tMalady.nNextSneezeTime = GameRules.elapsedTime
	end

	if tMalady.bSymptomatic then
		-- symptom log type can be in top-level data OR in stage-specific data
        local logtype = tMalady.sSymptomLog or (tMalady.tSymptomStages and tMalady.nCurrentStage and tMalady.tSymptomStages[tMalady.nCurrentStage+1].sSymptomLog)
		if logtype and (not tMalady.nNextSymptomLog or tMalady.nNextSymptomLog < GameRules.elapsedTime) then
			Log.add(logtype, rChar)
			tMalady.nNextSymptomLog = Malady._nextTime(Malady.LOG_RANGE)
		end
		if tMalady.sSpecial == 'parasite' and (not tMalady.nNextSpawnAttempt or tMalady.nNextSpawnAttempt < GameRules.elapsedTime) then
			tMalady.nNextSpawnAttempt = GameRules.elapsedTime + 15
			rChar:spawnMonster()
		end
		if tMalady.sSpecial == 'death' then
			CharacterManager.killCharacter(rChar, Character.CAUSE_OF_DEATH.DISEASE, {sDiseaseName=Malady.getFriendlyName(tMalady.sMaladyName)})
		end
	elseif tMalady.preSymptomaticLog and (tMalady.nNextPreSymptomLog < GameRules.elapsedTime) then
		Log.add(tMalady.preSymptomaticLog, rChar)
		tMalady.nNextPreSymptomLog = Malady._nextTime(Malady.LOG_RANGE)
	end
end

function Malady.getSymptomAnim(rChar)
    local tMaladies = rChar.tStatus.tMaladies
    if tMaladies then
        for sMaladyName,tMalady in pairs(tMaladies) do
            if tMalady.bSymptomatic and tMalady.bSpreadSneeze then
                if tMalady.nNextSneezeTime < GameRules.elapsedTime then
                    tMalady.nNextSneezeTime = Malady._nextTime(Malady.ANIM_SNEEZE_RANGE)
                    return Malady.ANIM_SNEEZE,tMalady
                end
            end
        end
    end
end

function Malady.playedSymptomAnim(rChar,sAnim,tMalady)
    if sAnim == 'sneeze' then
        if rChar:wearingSpacesuit() then
            -- MTF: if we had real spacesuits, that got stored in lockers, we could interact with the spacesuit
            -- here to help spread disease.
            -- But for now, spacesuits are magical things that are created and destroyed by the lockers, so we
            -- can do no such thing.
        else
            local rRoom = rChar:getRoom()
            if rRoom then
                local tx,ty,tw = rChar:getTileLoc()
		        local tSpreadTiles = GridUtil.GetTilesForIsoRectangle(tx-2,ty,tx+2,ty)
                local tTypes = {[ObjectList.ENVOBJECT]=1,[ObjectList.CHARACTER]=1,[ObjectList.WORLDOBJECT]=1}
                for addr,coord in pairs(tSpreadTiles) do
                    -- instead of goofing around with line of sight, just spread within a room.
                    local rSpreadRoom = Room.getRoomAtTile(coord.x,coord.y,tw,false)
                    if rSpreadRoom == rRoom or g_World._getTileValue(coord.x,coord.y,tw) == g_World.logicalTiles.DOOR then
                        local tList = ObjectList.getObjectsOfTypesAtTile(tx,ty,tTypes)
                        for rObj,_ in pairs(tList) do
                            Malady._testSpread(tMalady,rChar,rObj)
--                            if rObj ~= rChar and rObj.diseaseInteraction then
--                                rObj:diseaseInteraction(rChar,tMalady)
--                            end
                        end
                    end
                end
            end
        end
    end
end

-- rChar is interacting with rTarget. Test disease spread both ways.
function Malady.interactedWith(rChar,rTarget)
    if not rTarget.diseaseInteraction then return end

    local tMaladies = rChar.getMaladies and rChar:getMaladies()
    if tMaladies then
        for sMaladyName,tMalady in pairs(tMaladies) do
            Malady._testSpread(tMalady,rChar,rTarget)
        end
    end
    tMaladies = rTarget.getMaladies and rTarget:getMaladies()
    if tMaladies then
        for sMaladyName,tMalady in pairs(tMaladies) do
            Malady._testSpread(tMalady,rChar,rTarget)
        end
    end
end

function Malady._getEnvironmentSpreadMod(tx,ty)
	local tScrubbers = require('EnvObjects.EnvObject').getObjectsOfType('AirScrubber', true, true)
	local nChance = 1
	for _,rScrubber in pairs(tScrubbers) do
		-- only active, powered scrubbers work
		if rScrubber:isFunctioning() and MiscUtil.isoDist(tx,ty,rScrubber:getTileLoc()) <= rScrubber.tData.nRange then
			-- more scrubbers = lower chance of infection, down to a minimum
			nChance = nChance / 2
		end
	end
	return math.max(nChance, Malady.MIN_SPREAD_CHANCE)
end

function Malady._testSpread(tMalady, rSource,rTarget)
    local bSpread = tMalady.bContagious and (tMalady.bSpreadTouch or (tMalady.bSymptomatic and tMalady.bSpreadSneeze))
    if bSpread then
        if not rTarget.isImmuneTo or not rTarget:isImmuneTo(tMalady) then
            local nInfectChance
            if ObjectList.getObjType(rTarget) == ObjectList.CHARACTER then
                nInfectChance = tMalady.nChanceToInfectCharacter
                if rTarget:getJob() == Character.DOCTOR then
                    nInfectChance = nInfectChance * .5
                    if rTarget:getCurrentTaskName() == 'FieldScanAndHeal' or rTarget:getCurrentTaskName() == 'BedHeal' then
                        nInfectChance = 0
                    end
                end
            else
                nInfectChance = tMalady.nChanceToInfectObject
            end
            local nEnvironmentMod = Malady._getEnvironmentSpreadMod(rSource:getTileLoc())
            nInfectChance = nInfectChance * nEnvironmentMod
            if math.random() < nInfectChance then
                rTarget:diseaseInteraction(rSource,tMalady)
            end
        end
    end
end

function Malady.shouldInterruptCurrentTask(rChar)
    if Malady.getGathererOverride(rChar) ~= nil then
        local sName = rChar:getCurrentTaskName()
        if sName then
            return Malady.INCAPACITATED_ACTIVITIES_ALLOWED[sName] == nil
        end
    end
    return false
end

function Malady.getGathererOverride(rChar)
    if Malady.isIncapacitated(rChar) then
        return Malady._incapacitatedGatherers
    end
end

-- Add between 0 and 4 duty to the base score.
function Malady.diseaseHealNeedsOverride(rDoctor,rAO,rPatient)
    local nDuty = rAO.tBaseAdvertisedNeeds['Duty']
    if rAO.name == 'BedHeal' then
        -- give the max possible bump to bed heals
        nDuty = nDuty + 4
    else
        -- add between 0 and 4 based on severity and time since last checkup.
        local nSev = 0
        if Malady.getNextUndiagnosedMalady(rPatient) then
            nSev = rPatient:getPerceivedDiseaseSeverity(rPatient:retrieveMemory(Malady.MEMORY_HP_HEALED_RECENTLY) == nil)
        end
        local nLastCheckup = rPatient:retrieveMemory('LastCheckup') or -100000
        local nTimeSince = math.min(60*60, GameRules.elapsedTime-nLastCheckup)
        nTimeSince = nTimeSince / (60*60)
        nDuty = nDuty + 3 * nSev + nTimeSince
    end
    return {Duty=nDuty}
end

function Malady.addResearch(sMaladyName, nAmount)
    if Malady.tS.tResearch[sMaladyName] then
        Malady.tS.tResearch[sMaladyName].nCureProgress = math.min(Malady.tS.tResearch[sMaladyName].nCureProgress + nAmount, Malady.tS.tResearch[sMaladyName].nResearchCure)
        if Malady.tS.tResearch[sMaladyName].nCureProgress == Malady.tS.tResearch[sMaladyName].nResearchCure then
            return true
        end
    end
    return false
end

function Malady.getCompletedResearch()
    local tOptions = {}
    local nOptions = 0
    for sMaladyName, tMaladyData in pairs(Malady.tS.tMaladyStrains) do
        local tResearchData = Malady.tS.tResearch[sMaladyName]
        if tResearchData and tResearchData.bEncountered and tResearchData.nCureProgress >= tResearchData.nResearchCure then
            tOptions[sMaladyName] = tResearchData or {}
            nOptions = nOptions+1
        end
    end
    return tOptions,nOptions
end

function Malady.getAvailableResearch()
    local tOptions = {}
    local nOptions = 0
    for sMaladyName, tResearchData in pairs(Malady.tS.tResearch) do
        if tResearchData.bEncountered and tResearchData.nCureProgress < tResearchData.nResearchCure then
            tOptions[sMaladyName] = tResearchData
            nOptions = nOptions+1
        end
    end
    return tOptions,nOptions
end

function Malady.DBG_testMalady()
    local rSelected = g_GuiManager.getSelected()
    local objType = ObjectList.getObjType(rSelected)
    local tMs = {}
    for k,v in pairs(MaladyData) do
        if not v.bNoCreate then
            table.insert(tMs,k)
        end
    end
    local sMaladyType = MiscUtil.randomValue(tMs)
    local tMalady = Malady.createNewMaladyInstance(sMaladyType)
    if objType == ObjectList.CHARACTER then
        rSelected:diseaseInteraction(nil,tMalady)
    elseif objType == ObjectList.ENVOBJECT then
        rSelected:diseaseInteraction(nil,tMalady)
    end
end

return Malady
