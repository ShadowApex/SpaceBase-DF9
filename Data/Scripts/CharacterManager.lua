local DFUtil = require('DFCommon.Util')
local DFMath = require('DFCommon.Math')
local GameRules = require('GameRules')
local World = require('World')
local Base = require('Base')
local MiscUtil = require('MiscUtil')
local SoundManager = require('SoundManager')
local ObjectList = require('ObjectList')
local DataCache = require("DFCommon.DataCache")
local DFFile = require('DFCommon.File')
local Character = require('CharacterConstants')
local Topics = require('Topics')
local Log = require('Log')
local Profile = require('Profile')

local CharacterManager = 
{
    profilerName='CharacterManager',
}

CharacterManager.bDBGExtendedProfiler = false

local tCharacters
local tOwnedCharacters
local tDeadCharacters
local tDecisionNeededHash
local tDecisionNeeded


-- simulation details
local UPDATES_PER_TICK = 10

function CharacterManager.init()
    tCharacters = {}
    tOwnedCharacters = {}
    tDeadCharacters = {}
    tDecisionNeededHash = {}
    tDecisionNeeded = {}
    CharacterManager.tJobCount = {}
    CharacterManager.DBG_tCharacters = tCharacters
    CharacterManager.DBG_tOwnedCharacters = tOwnedCharacters
    CharacterManager.DBG_tDeadCharacters = tDeadCharacters

    -- preload anims
    for _, t in pairs(Character.RIG_TYPE) do
        local sAnimFile = t.sAnimPath
        local tAnimations = require(sAnimFile)
        for _,tAnimData in pairs(tAnimations) do
            if tAnimData.sFilename then
                DataCache.getData('anim',DFFile.getAssetPath(tAnimations.sBasePath..tAnimData.sFilename))
            end
            if tAnimData.tFilenames then
                for _,filename in pairs(tAnimData.tFilenames) do
                    DataCache.getData('anim',DFFile.getAssetPath(tAnimations.sBasePath..filename))
                end
            end
        end
    end

    for k,v in pairs(Character.JOB_NAMES_CAPS) do
        CharacterManager.tJobCount[k] = 0
    end    
    
    CharacterManager.bFirstTime = true
end

--------------------------------------------------------
-- PUBLIC
--------------------------------------------------------

function CharacterManager.debugDrawRigs()
    if not tCharacters then return end
    for i,v in ipairs(tCharacters) do
        if v.rCurrentRig then
            v.rCurrentRig:debugDraw(true, true) --, bDebugDrawSubsetBounds, bDebugDrawSubsetNames)
        end
    end
end

function CharacterManager.debugDrawPathing()
	local rChar = g_GuiManager.getSelectedCharacter()
	if not rChar then
		return
	end
	rChar:drawDebugPath()
end

function CharacterManager.addNewCharacter(x,y,tData,nTeam)
    local bGenerateStartingStuff = not tData or not tData.tInventory or (next(tData.tInventory) == nil)
    if bGenerateStartingStuff and tData and tData.bNoStuff then bGenerateStartingStuff = false end

    local rChar = CharacterManager.loadCharacter(DFUtil.deepCopy(tData or {}),x,y,nTeam)
	-- if we're just starting, don't log
    if rChar:isPlayersTeam() and GameRules.elapsedTime > 2 then
        Base.eventOccurred(Base.EVENTS.CitizenJoined, {rReporter=rChar})
		-- small chance to create a new topic
		if math.random() < Character.IMMIGRATION_ADD_TOPIC_CHANCE then
			local category = Topics.getRandomCategory()
			-- some topics, such as people, shouldn't be auto-generated
			while not Topics.TopicList[category].bCanGenerateOnImmigration do
				category = Topics.getRandomCategory()
			end
			Topics.addTopic(category)
			Print(TT_Info, 'New topic created in category '..category)
		end
    end
	-- remember "join date"
	rChar.tStats.nJoinTime = GameRules.elapsedTime
	-- add new character to topic list & everyone's affinity map
	Topics.addTopic('People', rChar.tStats.sUniqueID)
	-- make this new character like and hate stuff
	Topics.generateCharacterAffinities(rChar)
    if bGenerateStartingStuff then
        rChar:generateStartingStuff()
    end
    return rChar
end

function CharacterManager.getCharacters()
    return tCharacters
end

function CharacterManager.getOwnedCharacters()
    return tOwnedCharacters
end

function CharacterManager.getDeadCharacters()
    return tDeadCharacters
end

function CharacterManager.getOwnedCharactersWithTask(sTaskName)
	local tChars = {}
	for _,char in pairs(CharacterManager.getOwnedCharacters()) do
		if char.rCurrentTask and char.rCurrentTask.activityName == sTaskName then
			table.insert(tChars, char)
		end
	end
	return tChars
end

-- Convenience mode, grabs first player-run character.
function CharacterManager.getPlayerCharacter()
    for _,rChar in ipairs(tOwnedCharacters) do
		if rChar.tStats.nTeam == Character.TEAM_ID_PLAYER then
            return rChar
        end
    end
end

function CharacterManager.getTeamCharacters(nTeam,bAll)
	local tChars = {}
    local tSource = (bAll and tCharacters) or tOwnedCharacters
    for _,rChar in ipairs(tSource) do
		if rChar.tStats.nTeam == nTeam then
			table.insert(tChars,rChar)
		end
	end
	return tChars,#tChars
end

function CharacterManager.getHostileCharacters(rAsking)
	local tHostiles = {}
	for _,rChar in pairs(tCharacters) do
		if not rChar:isDead() and not Base.isFriendly(rAsking,rChar) then
			table.insert(tHostiles, rChar)
		end
	end
	return tHostiles
end

function CharacterManager.getCharactersInRange(wx, wy, nMaxRange, tChars)
    nMaxRange = nMaxRange * nMaxRange
	local tRanges = {}
	for _,rChar in pairs(tChars) do
		local wx1, wy1 = rChar:getLoc()
		local nDist = DFMath.distance2DSquared(wx,wy,wx1,wy1)
		if nDist <= nMaxRange then
			table.insert(tRanges, {rEnt=rChar, nDist2=nDist})
		end
	end
    return tRanges
end

function CharacterManager.getLivingCharactersInRange(wx, wy, nMaxRange)
	local tChars = CharacterManager.getCharacters()
	return CharacterManager.getCharactersInRange(wx, wy, nMaxRange, tChars)
end

function CharacterManager.getHostileCharactersInRange(wx, wy, nMaxRange, rAsking)
	local tHostiles = CharacterManager.getHostileCharacters(rAsking)
	return CharacterManager.getCharactersInRange(wx, wy, nMaxRange, tHostiles)
end

function CharacterManager.updateOwnedCharacters()
    if not tCharacters then
        tCharacters = {}
    end
    tOwnedCharacters = {}
    for i,v in ipairs(tCharacters) do
        if v.tStatus.bForceSim or World.getVisibility(v:getLoc()) == World.VISIBILITY_FULL then
            table.insert(tOwnedCharacters, v)
            if not v.tStatus.bForceSim then
                v:onSimStart()
            end
            v.tStatus.bForceSim = true
            v:setColor(1,1,1,1)
        end
    end
end

function CharacterManager._updateJobCounts()
    CharacterManager.tCharsByJob = {}
    for k,v in pairs(Character.JOB_NAMES_CAPS) do
        CharacterManager.tJobCount[k] = 0
        CharacterManager.tCharsByJob[k] = {}
    end

    for i,v in ipairs(tOwnedCharacters) do
        -- let's count ONLY the player owner characters
        if v:isPlayersTeam() then
            local idx = v:getJob()
            CharacterManager.tJobCount[idx] = CharacterManager.tJobCount[idx] + 1
            CharacterManager.tCharsByJob[idx][v] = 1
        end
    end
end

function CharacterManager.getCitizenPopulation()
    return #tCharacters
end

function CharacterManager.getOwnedCitizenPopulation()
    tOwnedCharacters = CharacterManager.getOwnedCharacters()
    return #tOwnedCharacters
end

function CharacterManager.deleteCharacter( rCharacter )
    CharacterManager.destroyCharacter( rCharacter )    
	tDeadCharacters[rCharacter] = nil
	rCharacter:_remove()
end

function CharacterManager.killCharacter(rCharacterProp, cause, tAdditionalInfo)
    assert(ObjectList.getObjType(rCharacterProp) == ObjectList.CHARACTER)
	rCharacterProp:unHover()
    -- let the character know they're being destroyed and have them do a callback
    rCharacterProp:_kill( CharacterManager.destroyCharacter, false, cause, tAdditionalInfo or {})
	tDeadCharacters[rCharacterProp] = GameRules.elapsedTime
	-- morale hit if death is non-debug + for a friendly
	if rCharacterProp.tStats.nTeam ~= Character.TEAM_ID_PLAYER then
		return
	end
	local sID = rCharacterProp.tStats.sUniqueID
	local sName = rCharacterProp.tStats.sName
	local sOtherID
	for _,char in pairs(tOwnedCharacters) do
		sOtherID = char.tStats.sUniqueID
		if sID ~= sOtherID then
			local tLogData = { sDeceased = sName }
			-- friend dying = extra bummer :[
            if char:isPlayersTeam() then
                if rCharacterProp:isPlayersTeam() then
					-- morale loss on death based on familiarity and affinity
					local nFamiliarity = math.min(char:getFamiliarity(sID), Character.MORALE_MAX_FAMILIARITY_DEATH)
					-- negative affinity == 0 bonus
					local nAffinity = DFMath.clamp(char:getAffinity(sID), 0, Character.MORALE_MAX_AFFINITY_DEATH)
					local nLossPct = (nFamiliarity * nAffinity) / (Character.MORALE_MAX_FAMILIARITY_DEATH * Character.MORALE_MAX_AFFINITY_DEATH)
					local nLoss = DFMath.lerp(Character.MORALE_CITIZEN_DIES_MIN, Character.MORALE_CITIZEN_DIES_MAX, nLossPct)
					if nAffinity > 0 and nFamiliarity >= 5 then
						Log.add(Log.tTypes.DEATH_REACT_FRIEND, char, tLogData)
					else
						Log.add(Log.tTypes.DEATH_REACT_CITIZEN, char, tLogData)
					end
					char:alterMorale(nLoss, 'CitizenDied')
				else
					Log.add(Log.tTypes.DEATH_REACT_ENEMY, char, tLogData)
				end
			else --enemy comments
                if rCharacterProp:isPlayersTeam() then
					Log.add(Log.tTypes.DEATH_REACT_RAIDER_TO_CITZ, char, tLogData)
				else
					Log.add(Log.tTypes.DEATH_REACT_RAIDER_TO_RAIDER, char, tLogData)
				end
			end
		end
	end
end

function CharacterManager.destroyCharacter( rCharacterProp )    
    -- remove it from our table
    for i, rCharacter in ipairs( tCharacters ) do
        if rCharacter == rCharacterProp then
            table.remove( tCharacters, i )
            break
        end
    end
    for i, rCharacter in ipairs( tOwnedCharacters ) do
        if rCharacter == rCharacterProp then
            table.remove( tOwnedCharacters, i )            
            break
        end
    end
end

function CharacterManager.getCaptainsLog()
    local sCaptainsLog = "--------------------------------------"
    for _, rCharacter in ipairs( tOwnedCharacters ) do
        sCaptainsLog = sCaptainsLog..rCharacter:getLogAsString()
        local sCaptainsLog = "--------------------------------------"
    end
    
    return sCaptainsLog
end

function CharacterManager.shutdown()
    if not tCharacters then
        return
    end

    local tKillList = DFUtil.copyi( tCharacters )
    for _,rCharacter in ipairs( tKillList ) do
		CharacterManager.deleteCharacter( rCharacter )
    end
    for rCharacter,_ in pairs(tDeadCharacters) do
        rCharacter:_remove()
        tDeadCharacters[rCharacter] = nil
    end
    tKillList = nil

    tCharacters = nil
	tDeadCharacters = nil
	tOwnedCharacters = nil
	tDecisionNeededHash = nil
	tDecisionNeeded = nil
    CharacterManager.DBG_tCharacters = tCharacters
    CharacterManager.DBG_tOwnedCharacters = tOwnedCharacters
    CharacterManager.DBG_tDeadCharacters = tDeadCharacters
end

function CharacterManager.loadCharacter( tData, xOff, yOff, nTeam )
    --ObjectList.reconstructTagsOnLoad(tData)
	tData.tStats = tData.tStats or {}
    if nTeam then tData.tStats.nTeam = nTeam end
    
    --[[
    if tData.tInventory then
        ObjectList.reconstructTagsOnLoad(tData.tInventory)
    else
        tData.tInventory = {}
    end
    ]]--
    
    tData.x, tData.y = (tData.x or 0) + (xOff or 0), (tData.y or 0) + (yOff or 0)
    local rCharacter = require('Character').new( tData )
    table.insert( tCharacters, rCharacter )
	rCharacter:setJob(rCharacter.tStats.nJob, true)
    if rCharacter:isDead() then
        -- SPECIAL CASE for generating corpses.
        -- TODO: Will need to fix for derelicts, so they don't decay until the derelict is discovered.
        rCharacter:_kill( CharacterManager.destroyCharacter, true, nil, {})
        rCharacter:playAnim('death_pose')
        tDeadCharacters[rCharacter] = 1
    end
    return rCharacter
end

function CharacterManager.getCharacterNamed( sName, bExcludeDeadCharacters )
	-- names are not guaranteed to be unique, so make sure you want this and not
	-- CharacterManager.getCharacterByUniqueID below!
    for _,rCharacter in ipairs( tCharacters ) do
        if rCharacter:getUniqueID() == sName and rCharacter.tStatus.health ~= Character.STATUS_DEAD then
			return rCharacter
        end
    end
	if not bExcludeDeadCharacters then
		for rChar,_ in pairs( tDeadCharacters ) do
			if rChar.tStats.sName == sName then
				return rChar
			end
		end
	end
    return nil
end

function CharacterManager.getCharacterByUniqueID( sUniqueID, bExcludeDeadCharacters )
    for _,rCharacter in ipairs( tCharacters ) do
        if rCharacter:getUniqueID() == sUniqueID then
            return rCharacter
        end
    end
	if not bExcludeDeadCharacters then
		for rChar,_ in pairs( tDeadCharacters ) do
			if rChar.tStats.sUniqueID == sUniqueID then
				return rChar
			end
		end
	end
    return nil
end

--------------------------------------------------------
-- PRIVATE
--------------------------------------------------------

function CharacterManager.onTick( dt )
    CharacterManager._updateJobCounts()

    if CharacterManager.bFirstTime then
        for _,rCharacter in ipairs( tOwnedCharacters ) do
           rCharacter:updateAI(0)
        end
        CharacterManager.bFirstTime = false
        local b= CharacterManager.getCharacterByUniqueID('Kill Bot9')
        g_GuiManager.setSelectedCharacter(b)
    end
    
    Profile.enterScope("CharacterUpdate")
    for _,rCharacter in ipairs( tOwnedCharacters ) do
       rCharacter:updateAI(dt)
    end
    Profile.leaveScope("CharacterUpdate")
    
    Profile.enterScope("CharacterMover")
    -- update all moves (and oxygen, too)
    for k=1, #tOwnedCharacters do
        local rCharacter = tOwnedCharacters[k]
        
        if not tDecisionNeededHash[rCharacter] and rCharacter:needsNewTask() then
            -- Double list: hash to avoid dupes, and array to offer FIFO queueing.
            tDecisionNeededHash[rCharacter] = 1
            table.insert(tDecisionNeeded,rCharacter)
        end

        rCharacter:updateAnimation(dt)
        if CharacterManager.bDBGExtendedProfiler then
            Profile.enterScope("CharacterLights")
        end
        rCharacter:updateLights(dt)
        if CharacterManager.bDBGExtendedProfiler then
            Profile.leaveScope("CharacterLights")
        end
    end
    Profile.leaveScope("CharacterMover")
    
    Profile.enterScope("CharacterSelectTask")
    if #tDecisionNeeded > 0 then
        local rCharDecide = tDecisionNeeded[1]
        tDecisionNeededHash[rCharDecide] = nil
        table.remove(tDecisionNeeded,1)
        if not rCharDecide:isDead() then
            rCharDecide:_selectTask()
        end
    end
    Profile.leaveScope("CharacterSelectTask")
    
    Profile.enterScope("CharacterCorpser")
    for rCharacter,_ in pairs(tDeadCharacters) do
        if rCharacter.deathTick then
            rCharacter:deathTick(dt)
        end
    end
    Profile.leaveScope("CharacterCorpser")
end

--------------------------------------------------------
-- DEBUG
--------------------------------------------------------

-- spawns a monster out of this dude's chest, which is a mean thing to do
function CharacterManager.DBG_spawnMonster()
    local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    local worldLayer = g_World.getWorldRenderLayer()
    local wx, wy = worldLayer:wndToWorld(x, y)
    local tx, ty = g_World._getTileFromWorld(wx,wy)
    
    local Malady = require('Malady')
    local rChar = ObjectList.getObjAtTile(tx,ty,ObjectList.CHARACTER)
    if rChar and not rChar:isDead() then
        local tMalady = Malady.createNewMaladyInstance('Parasite')
        tMalady.tTimeToSymptoms={0,0}
        rChar:diseaseInteraction(nil,tMalady)
    end
end

function CharacterManager.DBG_addExperience()
    local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    local worldLayer = g_World.getWorldRenderLayer()
    local wx, wy = worldLayer:wndToWorld(x, y)
    local tx, ty = g_World._getTileFromWorld(wx,wy)
    
    local rChar = ObjectList.getObjAtTile(tx,ty,ObjectList.CHARACTER)
    if rChar and not rChar:isDead() then
        rChar:DBG_increaseCurrentJobLevel()
    end
end

function CharacterManager.DBG_randomizeMorale()
	for _,rChar in pairs(tCharacters) do
		rChar.tStats.nMorale = math.random(Character.MORALE_MIN, Character.MORALE_MAX)
	end
end

function CharacterManager.DBG_randomizeQuirks()
	-- DEBUG: randomizes personality quirks for all citizens
	for _,rChar in pairs(tCharacters) do
		for k,_ in pairs(Character.PERSONALITY_TRAITS) do
			if string.find(k, 'b') == 1 then
				-- some boolean traits should be more or less common
				local nChance = Character.PERSONALITY_LIKELIHOOD[k] or 0.5
				local bCoinFlip = false
				if math.random() < nChance then
					bCoinFlip = true
				end
				rChar.tStats.tPersonality[k] = bCoinFlip
			end
		end
	end
end

return CharacterManager
