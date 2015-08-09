local Class=require('Class')
local DFMath=require('DFCommon.Math')
local Pathfinder=require('Pathfinder')
local MiscUtil=require('MiscUtil')
local OptionData = require('Utility.OptionData')
local Needs = require('Utility.Needs')
local Prerequisites = require('Utility.Prerequisites')
local World=require('World')
local Room=require('Room')
local Character=require('CharacterConstants')
local Profile = require('Profile')

local ActivityOption = Class.create()

ActivityOption.DEBUG_DRAW_NONE = 1
ActivityOption.DEBUG_DRAW_JOBS = 2
ActivityOption.DEBUG_DRAW_MAX = 2
ActivityOption.debugDraw = 1
ActivityOption.DEBUG_PROFILE = true

ActivityOption.DISTANCE_ADJUST_START = 5 --
ActivityOption.DISTANCE_ADJUST_END = 50 --
-- begin changes for mod TaskUtilityTravelPenalty
ActivityOption.DISTANCE_ADJUST_SCORE = -1
-- end changes for mod TaskUtilityTravelPenalty
ActivityOption.DISTANCE_ADJUST_SEVERE_SCORE = -3

--ActivityOption.TAG_WORK_SHIFT_BONUS = 10
ActivityOption.TAG_WORK_SHIFT_ADD = 0
ActivityOption.TAG_WORK_SHIFT_SCALE = 2

function ActivityOption.cycleDebugDraw()
    ActivityOption.debugDraw = ActivityOption.debugDraw+1
    if ActivityOption.debugDraw > ActivityOption.DEBUG_DRAW_MAX then
        ActivityOption.debugDraw = ActivityOption.DEBUG_DRAW_NONE
    end
end

-- Special entries for tData:
--   pathX,pathY: if set, the character must be able to path to this point, or the option is unavailable (world coords).
--   targetLocationFn: calls a function to get a single target world location.
--          Return 'stay' to skip path generation.
--   pathToNearest: applied to above. allows pathing to adjacent tile.
--   bNoPathToNearestDiagonal: disallows pathing to a diagonally adjacent tile.
--   rTargetObject: as above, but with a MOAIProp in the world. NOTE: pathToNearest is always true if this is used for path location.
--          Cases where this can be specified but pathToNearest is NOT auto-set to true include: targetLocationFn taking precedence.
--   targetTileListFn: calls a function to get a list of possible target tiles (world coords, t[addr] = {x=x,y=y,addr=adddr}).
--      Option: if targetTileListFn returns true as 2nd arg, same as targetTileListFn, but returns isodist-sorted array of tiles.
--   bInfinite: doesn't allow exclusive reservation of the option.
--   nMaxReservations: allows only n reservations. (default 1) (does nothing if bInfinite set)
--   utilityGateFn: called with ([optional self], rChar, rThisActivityOption), if it fails to return true then utility for this AO is 0.
--   utilityGateSelf: optional first arg to utilityGateFn, for convenience.
--   utilityOverrideFn: ([optional self], rChar,rAO,nOriginalUtility) calls this function for a utility score, instead of the usual utility scoring.
--      (called after all the other gating functionality listed above is met)
--   customNeedsFn: (rChar,rAO, tBaseAdvertisedNeeds) calls this function to get a Needs table returned. Often a superior way to get dynamic scoring,
--      rather than using utilityOverrideFn, since this is before the needs curves are applied.
--   utilityOverrideSelf: optional first arg to utilityOverrideFn, for convenience.
--   priorityOverrideFn: calls this function for priority, called with fn(rChar, rThisAO, unmodifiedPri).
--   tSatisfies: additional/override satisfies for this option, on top of what's already in OptionData.
--   tagOverrideFn: called with (rChar, rThisAO, sTagName). Return a value for that tag name. e.g. you can override MyTag='SomeVal' to return MyTag='AnotherVal' by returning 'AnotherVal'.
function ActivityOption:init(name, tData, utilityScoreFn)
    assert(name)
    self.name = name
    self.tData = tData or {}
    self.tBlackboard = {}
    self.utilityScoreFn = utilityScoreFn

    self.nReservations = 0
    self.tReservations = {}
    
    local tAdvertisedData =  OptionData.tAdvertisedActivities[self.name]

    self.tData.bAllowHostilePathing = tData.bAllowHostilePathing or (tAdvertisedData and tAdvertisedData.bAllowHostilePathing)
    self.tData.bTestMemoryBreach = tData.bTestMemoryBreach or (tAdvertisedData and tAdvertisedData.bTestMemoryBreach)
    self.tData.bTestMemoryCombat = tData.bTestMemoryCombat or (tAdvertisedData and tAdvertisedData.bTestMemoryCombat)

    self.tBaseAdvertisedNeeds = (tAdvertisedData and tAdvertisedData.Needs) or {}
    self.tBaseAdvertisedData = tAdvertisedData
    self.tBaseTags = (tAdvertisedData and tAdvertisedData.Tags) or {}
    self.tMods = (tAdvertisedData and tAdvertisedData.ScoreMods) or {}
    self.tPersonality = (tAdvertisedData and tAdvertisedData.PersonalityMods)
end

function ActivityOption:getTag(rChar, sTagName)
    if self.tData.tagOverrideFn then
        local val = self.tData.tagOverrideFn(rChar,self,sTagName)
        if val ~= nil then return val end
    end
    return self.tBaseTags[sTagName]
end

function ActivityOption:reserve(rChar)
    if self.tData.bInfinite then 
        -- Can be useful to track characters performing this activity, even if not for reservations.
        self.tReservations[rChar] = rChar
        self.nReservations = self.nReservations+1
        return 
    end

	if self.tData.targetTileListFn then
		assert(self.tBlackboard.tileX and self.tBlackboard.tileY)
		local addr = World.pathGrid:getCellAddr(self.tBlackboard.tileX, self.tBlackboard.tileY)
		if not self.tReservedTiles then self.tReservedTiles = {} end
		self.tReservedTiles[addr] = rChar
	else
        assert(not self.tReservations[rChar])
        self.nReservations = self.nReservations+1
        self.tReservations[rChar] = rChar
        assert(self.nReservations <= (self.tData.nMaxReservations or 1))
    end
end

function ActivityOption:updateTileReservation(rChar,newTX,newTY)
    self:unreserve(rChar)
	local addr = World.pathGrid:getCellAddr(newTX,newTY)
	if not self.tReservedTiles then self.tReservedTiles = {} end
	self.tReservedTiles[addr] = rChar
end

function ActivityOption:unreserve(rChar)
    if self.tData.bInfinite then 
        if self.tReservations[rChar] then
            self.tReservations[rChar] = nil
            self.nReservations = self.nReservations-1
        end
        return 
    end

	if self.tData.targetTileListFn then
		for addr,char in pairs(self.tReservedTiles) do
			if rChar == char then
				self.tReservedTiles[addr] = nil
				return
			end
		end
		assert(false)
	else
        self.nReservations = self.nReservations-1
        assert(self.tReservations[rChar])
        self.tReservations[rChar] = nil
        assert(self.nReservations >= 0)
	end
end

function ActivityOption:getPriority(rChar)
    local nPri = self.tData.nPriorityOverride or self.tMods.Priority or OptionData.tPriorities.NORMAL
    if self.tData.priorityOverrideFn then return self.tData.priorityOverrideFn(rChar, self, nPri) end

    if self.tBaseAdvertisedNeeds['Hunger'] and rChar:starving() and nPri < OptionData.tPriorities.SURVIVAL_NORMAL then
        nPri = OptionData.tPriorities.SURVIVAL_NORMAL
    end

    return nPri
end

function ActivityOption:getAdvertisedData()
    return OptionData.tAdvertisedActivities[self.name]
end

-- tx and ty are optional, and only used in the case of a targetTileListFn
-- rChar is optional; if provided, ao will only return true if it's reserved by someone other than rchar
function ActivityOption:reserved(tx,ty,rChar)
	if not self.tData.bInfinite and self.tData.targetTileListFn then
		if self.tReservedTiles then
            if tx then
			    local addr = World.pathGrid:getCellAddr(tx,ty)
                if self.tReservedTiles[addr] then
                    return rChar ~= self.tReservedTiles[addr]
                end
            else
                assert(not rChar) -- not supported
			    for addr,_ in pairs(self.tReservedTiles) do
				    return true
			    end
            end
		end
	else
    	return self.nReservations > 0
	end
end

function ActivityOption:fillOutBlackboard(rChar)
    local bSuccess, sReason = self:earlyGates(rChar,self:getPriority(rChar))
    if not bSuccess then
        print('Early failure filling out blackboard',sReason)
        return bSuccess,sReason
    end
    bSuccess, sReason = self:lateGates(rChar)
    if not bSuccess then
        print('Late failure filling out blackboard',sReason)
        return bSuccess,sReason
    end
    if self.tBlackboard.nPathDist then
        self.tBlackboard.tPath = Pathfinder.getPath(self.tBlackboard.nPathStartWX, self.tBlackboard.nPathStartWY, self.tBlackboard.nPathEndWX, self.tBlackboard.nPathEndWY, rChar, self.tBlackboard.tPathParams)
        
        assert(self.tBlackboard.tPath)

        local nStartPathTX,nStartPathTY = g_World._getTileFromWorld(self.tBlackboard.nPathStartWX,self.tBlackboard.nPathStartWY)
        assertdev(self.tBlackboard.tPath.tPathNodes[1].tx == nStartPathTX)
        assertdev(self.tBlackboard.tPath.tPathNodes[1].ty == nStartPathTY)
        
    end
    return bSuccess, sReason
end

-- return: bValid, nMaxPotentialScore, sReason
function ActivityOption:earlyGates(rChar, nMinPriority)
    self.tBlackboard.rChar = rChar

    local sReason = self:_gateActivity(rChar, nMinPriority)
    if sReason then 
        return false, sReason
    end
    return true
end

function ActivityOption:getMaxPotentialScore(rChar)
    return self:_computeMaxScore(rChar)
end

function ActivityOption:getSatisfies()
    if not self.tSatisfies then
        self.tSatisfies = {}
        if OptionData.tAdvertisedActivities[self.name].Satisfies then
            for k,v in pairs(OptionData.tAdvertisedActivities[self.name].Satisfies) do
                self.tSatisfies[k] = v
            end
        end
        if self.tData.tSatisfies then
            for k,v in pairs(self.tData.tSatisfies) do
                self.tSatisfies[k] = v
            end
        end
    end
    return self.tSatisfies
end

-- MTF HACK:
-- Prereqs such as GoInside/GoOutside are added by something (Airlock) that does the path test for the later activities.
-- So we don't need to do our Mine/BuildSpace/etc. path test, because Airlock has done so.
-- Furthermore, we can't do real path tests, even from the character's dest location, because the airlock door is closed.
-- So for now, the airlock just says "everything's fine, I'll figure it out," and runs its own utility calculation to apply
-- the distance cost.
-- Which all works fine and accurately, but burdens Airlock with a lot of scoring logic.
function ActivityOption:overridesPathTest()
    return OptionData.tAdvertisedActivities[self.name].Satisfies and OptionData.tAdvertisedActivities[self.name].OverridePathTest
end

-- SATISFIERS ONLY
-- Allows a satisfier to pass a path start location to the satisfied activity's pathing evaluation,
-- so that it can path from where the satisfier thinks the character will be at the end of the satisfier,
-- rather than at this moment in time.
function ActivityOption:getPathStartOverride(rChar)
	local wx,wy,reason = nil,nil,nil
	if self.tData.pathStartOverrideFn then
		if self.tData.pathStartOverrideSelf then
			wx,wy = self.tData.pathStartOverrideFn(self.tData.pathStartOverrideSelf, rChar, self)
		else
			wx,wy = self.tData.pathStartOverrideFn(rChar, self)
		end
		if not wx then
			reason = 'pathStartOverrideFn failed'
		end
	end
	return wx,wy,reason
end

function ActivityOption:getUnsatisfiedPrereqs(rChar)
    --assert(tBlackboard.rChar == rChar)
    local tPrereqs = OptionData.tAdvertisedActivities[self.name].Prerequisites
    local tUnsatisfied = {}
    if tPrereqs then
        for k,v in pairs(tPrereqs) do
            if Prerequisites[k](rChar,self,v) ~= v then
                tUnsatisfied[k] = v
            end
        end
    end
    return tUnsatisfied
end

-- return: bValid, sReason
function ActivityOption:lateGates(rChar, bOverridePathTest, nOverrideStartWX, nOverrideStartWY)
    local sReason
	if not bOverridePathTest then
    	sReason = self:_computeActivityPath(rChar, nOverrideStartWX, nOverrideStartWY)
	end
    if sReason then return false, sReason end
    return true
end

-- return: nScore
function ActivityOption:getRealScore(rChar)
    assert(rChar == self.tBlackboard.rChar)
    local score = self:_computeMaxScore(rChar)

    --[[
    if self.tBlackboard.tPath then
        local cx,cy = rChar:getLoc()
        self.tBlackboard.nPathDist = self.tBlackboard.tPath:pathDist(rChar)
    end
    ]]--
    if self.tBlackboard.nPathDist then
        score = self:distanceAdjust(rChar, score,self.tBlackboard.nPathDist)
    end
    if self.tMods.MinimumScore then 
        score = math.max(score,self.tMods.MinimumScore) 
    end
    return score
end

function ActivityOption:_computeMaxScore(rChar)
    self.tBlackboard.tAdvertisedNeeds = self:_computeNeeds(rChar)

    local score = self:scoreNeedsChange(rChar)
    if self.tMods.BaseScore then
        score = score+self.tMods.BaseScore
    end

    if self.tData.utilityOverrideFn then
		if self.tData.utilityOverrideSelf then
        	score = self.tData.utilityOverrideFn(self.tData.utilityOverrideSelf, rChar, self, score)
		else
        	score = self.tData.utilityOverrideFn(rChar, self, score)
		end
    end

    -- This was a straight add for duty tasks when the char wanted duty tasks.
    -- Instead, I'm trying a needs-based multiplier in scoreNeedsChange.
    -- MTF: For now, custom-scoring a tag here. If we widely use the tag system to modify
    -- scores, we may want to move the logic somewhere better.
    --[[
    local bWantsWorkShift = rChar:wantsWorkShiftTask() or false
    local bWorkShiftTask = self:getTag(self.rChar,'WorkShift') or false
    local nWorkShiftBonus = 0
    if bWantsWorkShift == bWorkShiftTask then
        nWorkShiftBonus = ActivityOption.TAG_WORK_SHIFT_BONUS
    end
    ]]--
	
	-- affinity for this activity influences score
	local nAffinity = rChar:getAffinityForActivity(self.name)
	if nAffinity then
		local nAffinityBonus = nAffinity / Character.STARTING_AFFINITY
		score = score + score * (Character.ACTIVITY_AFFINITY_CHANGE_PCT * nAffinityBonus)
	end
	
    if self.tMods.MinimumScore then 
        score = math.max(score,self.tMods.MinimumScore) 
    end

    return score
end

function ActivityOption:_getPathParams(rChar,startWX,startWY,destWX,destWY)
    local tPathParams = {bPathToNearest=self.tData.pathToNearest or self.bForcePathToNearest, bNoPathToNearestDiagonal=self.tData.bNoPathToNearestDiagonal}

    tPathParams.bTestMemoryBreach = self.tData.bTestMemoryBreach
    tPathParams.bTestMemoryCombat = self.tData.bTestMemoryCombat
    
    local startTX,startTY = g_World._getTileFromWorld(startWX,startWY)
    local destTX,destTY = g_World._getTileFromWorld(destWX,destWY)

    if not self.tData.bAllowHostilePathing then
        -- If the activity doesn't allow hostile pathing, then require the character to stay in rooms of their own
        -- team. Unless the character is already in hostile territory, in which case they need to be able to path 
        -- through hostile territory or they'll never escape.
        -- (Similarly for a hostile dest.)
        local nCharTeam = rChar:getTeam()
        local nTileTeam = Room.getTeamAtTile(startTX,startTY,1,nCharTeam)
        local nDestTeam = Room.getTeamAtTile(destTX,destTY,1,nCharTeam)
        
        if nTileTeam == nCharTeam and nDestTeam == nCharTeam then 
            tPathParams.nRequiredTeam = rChar:getTeam()
        end
    end
    local nPri = self:getPriority(rChar)
    if nPri <= OptionData.tPriorities.NORMAL then
        if tPathParams.bTestMemoryBreach == nil then
            tPathParams.bTestMemoryBreach = true
        end
        if tPathParams.bTestMemoryCombat == nil and not self.tData.bAllowHostilePathing then
            tPathParams.bTestMemoryCombat = true
        end
    end
    return tPathParams
end

function ActivityOption:createTask(rChar, promisedUtility, DEBUG_PROFILE, tSaveData)
    --print('Creating task',self.name,'for',rChar:getUniqueID())
    if DEBUG_PROFILE then Profile.enterScope("Create"..self.name) end

    -- better finally get that path figured out.
    if self.tBlackboard.nPathDist then
        -- todo: should probably use char current loc, not stored coords.
                
        self.tBlackboard.tPath = Pathfinder.getPath(self.tBlackboard.nPathStartWX, self.tBlackboard.nPathStartWY, self.tBlackboard.nPathEndWX, self.tBlackboard.nPathEndWY, rChar, self.tBlackboard.tPathParams)
        if not self.tBlackboard.tPath then
            Print(TT_Error,"Got a path distance without a path? How does that happen?")
--            local tParams = self:_getPathParams(rChar)
            local txStart, tyStart = g_World._getTileFromWorld(self.tBlackboard.nPathStartWX, self.tBlackboard.nPathStartWY)
            local txDest, tyDest = g_World._getTileFromWorld(self.tBlackboard.nPathEndWX, self.tBlackboard.nPathEndWY)
            local startAddr = g_World.pathGrid:getCellAddr(txStart, tyStart)
            local endAddr = g_World.pathGrid:getCellAddr(txDest, tyDest)
            local bSuited=(rChar and rChar:spacewalking()) or self.tBlackboard.tPathParams.bForceSpacewalking
            local nSrcRoomID = Room.getRoomAtTile(txStart,tyStart,1)
            local nDestRoomID = Room.getRoomAtTile(txDest,tyDest,1)
            local pfinder = Pathfinder
            local dummyPath = Pathfinder.getPath(self.tBlackboard.nPathStartWX, self.tBlackboard.nPathStartWY, self.tBlackboard.nPathEndWX, self.tBlackboard.nPathEndWY, rChar, self.tBlackboard.tPathParams)
            assertdev(self.tBlackboard.tPath)
            return
        end

        local nStartPathTX,nStartPathTY = g_World._getTileFromWorld(self.tBlackboard.nPathStartWX,self.tBlackboard.nPathStartWY)
        assertdev(self.tBlackboard.tPath.tPathNodes[1].tx == nStartPathTX)
        assertdev(self.tBlackboard.tPath.tPathNodes[1].ty == nStartPathTY)
    end
    
    local classPath = OptionData.tAdvertisedActivities[self.name].ClassPath
    local rTask = nil
    local nPri = self:getPriority(rChar)
    local rClass = require(classPath)
	-- if class file doesn't contain class data, require will return "true"
	if type(rClass) == 'boolean' then
		print('ActivityOption:createTask(): rClass is empty')
        if DEBUG_PROFILE then Profile.leaveScope("Create"..self.name) end
		return nil
	end
    rTask = rClass.new(rChar, self.tBlackboard.tAdvertisedNeeds or self.tBaseAdvertisedNeeds, self, tSaveData)
    rTask.bInitialized = true

    rTask.nPromisedUtility = promisedUtility

    if not rTask.bComplete then -- in case of early interrupts in the task.
        self:reserve(rChar)
    end

    if DEBUG_PROFILE then Profile.leaveScope("Create"..self.name) end

    return rTask
end

function ActivityOption:scoreNeedsChange(rChar)
    local score = 0

    if rChar:getFactionBehavior() ~= Character.FACTION_BEHAVIOR.Citizen and rChar:getFactionBehavior() ~= Character.FACTION_BEHAVIOR.Friendly then
        -- Only citizens and friendlies use need scoring. Everyone else just uses base score & custom functions.
        return 0
    end

    for needName,needValue in pairs(self.tBlackboard.tAdvertisedNeeds) do
        local curVal = rChar:getNeedValue(needName,self)
        --print(needName,curVal)
        local promisedIncrease = Needs.getAdjustedPromise(rChar.tStats.tPersonality, needValue, self.name, needName)
        local futureVal = curVal + promisedIncrease
        local tNeedData = Needs.tNeedList[needName]

        local nNeedScore = tNeedData.scoreFn(curVal, futureVal, tNeedData.curveFn)
        -- MTF NOTE: eventually we may want to separate this out, and allow different
        -- need scores to be scaled based on various character traits and statuses.
        -- But for now we just do the WorkShift/Duty tweak.
        if needName == 'Duty' then 
            nNeedScore = rChar:getScaledDutyScore(nNeedScore, self:getTag(rChar,'WorkShift'))
            --and self:getTags().WorkShift == true and rChar:wantsWorkShiftTask() then
            --nNeedScore = ActivityOption.TAG_WORK_SHIFT_ADD + nNeedScore * ActivityOption.TAG_WORK_SHIFT_SCALE 
        end

        score = score + nNeedScore
    end

    return score
end

function ActivityOption:_computeNeeds(rChar)
	if self.tData.customNeedsFn then
        return self.tData.customNeedsFn(rChar, self)
    else
        return self.tBaseAdvertisedNeeds
    end
end

function ActivityOption:distanceAdjust(rChar, score,dist)
    if self:getTag(rChar,'HighDistPenalty') then
        dist = math.min(dist,ActivityOption.DISTANCE_ADJUST_END)
        dist = dist / ActivityOption.DISTANCE_ADJUST_END
        return score + dist * ActivityOption.DISTANCE_ADJUST_SEVERE_SCORE
    end

    if dist < ActivityOption.DISTANCE_ADJUST_START then return score end

    dist = math.min(dist, ActivityOption.DISTANCE_ADJUST_END)
    dist = dist-ActivityOption.DISTANCE_ADJUST_START 

    dist = dist/(ActivityOption.DISTANCE_ADJUST_END-ActivityOption.DISTANCE_ADJUST_START)

    return score + dist * ActivityOption.DISTANCE_ADJUST_SCORE 
end

function ActivityOption:_locationGates(rChar,wx,wy,rObj)
    if self:getTag(rChar,'DestOwned') then
        local nTeam = rChar:getTeam()
        if rChar:inPrison() then nTeam = Character.TEAM_ID_PLAYER end
        
        if not wx and not rObj then
            assert(not self.tData.targetTileListFn)
            wx,wy = rChar:getLoc()
        end

        if rObj then
            if nTeam ~= rObj:getTeam() then 
                return 'wrong dest object team'
            end
        else
            local _,tRooms = Room.getRoomAt(wx,wy,0,1,true)
            local bOwned=false
            for id,rRoom in pairs(tRooms) do
                if rRoom:getTeam() == nTeam then
                    bOwned=true
                    break
                end
            end
            if not bOwned then
                return 'DestOwned not fulfilled'
            end
            --[[
            local tx,ty = World._getTileFromWorld(wx,wy)
            if World._getTileValue(tx,ty) == World.logicalTiles.SPACE then
                return 'dest in space'
            end
            if World._getVisibility(tx,ty,1) ~= World.VISIBILITY_FULL then
                return 'dest tile not visible'
            end
            ]]--
        end
    end
    local destSafe = self:getTag(rChar,'DestSafe') 
    if destSafe == true or destSafe == 'AllowAirlock' then
        if not wx and not rObj then
            assert(not self.tData.targetTileListFn)
            wx,wy = rChar:getLoc()
        elseif not wx then
            wx,wy = rObj:getLoc()
        end
        local _,tRooms = Room.getRoomAt(wx,wy,0,1,true)
        if not next(tRooms) then return 'DestSafe not fulfilled: no room dest.' end
        for _,rRoom in pairs(tRooms) do
            if rRoom:getVisibility() == World.VISIBILITY_HIDDEN then
                return 'DestSafe not fulfilled: room entirely hidden.'
            end
            if rChar:retrieveMemory(Character.MEMORY_ROOM_FIRE_PREFIX..rRoom.id) then
                return 'DestSafe not fulfilled: room on fire.'
            end
            if destSafe ~= 'AllowAirlock' and rRoom.zoneObj and rRoom.zoneObj:isFunctionalAirlock() then
                return 'DestSafe not fulfilled: dest is an airlock.'
            end
            -- MTF: it would be cool to use character memory here, but then we'd want to model
            -- knowledge more thoroughly. Including communication between characters etc.. Main problem being
            -- that if you use memory, characters will try to go work out in a fitness room as soon as one tile
            -- of it is built, because they don't have a memory of it being breached.
            -- (Also, once they DO start that, the work out activity doesn't know to cancel out once it reaches
            -- the breached room.)
            if rRoom.bBreach then
                return 'DestSafe not fulfilled: room breached.'
            end
            --[[
            if rChar:retrieveMemory(Character.MEMORY_ROOM_BREACHED_PREFIX..rRoom.id) then
                return 'DestSafe not fulfilled: room breached.'
            end
            ]]--
            if rChar:retrieveMemory(Character.MEMORY_ROOM_COMBAT_PREFIX..rRoom.id) then
                return 'DestSafe not fulfilled: room in combat.'
            end
            -- See note above about character memory and breaches.
            if rRoom:getOxygenScore() < Character.OXYGEN_LOW then
--            if rChar:retrieveMemory(Character.MEMORY_ROOM_LOWO2_PREFIX..rRoom.id) then
                return 'DestSafe not fulfilled: room low oxygen.'
            end
        end
    end
end

function ActivityOption:_computeActivityPath(rChar, nOverrideStartWX, nOverrideStartWY)
	local cx, cy = nOverrideStartWX, nOverrideStartWY
	if not cx then
		cx,cy = rChar:getLoc()    
	end
    local nPathDist = nil
    local targetX,targetY,targetObj
    if self.tData.targetLocationFn then
        targetX,targetY = self.tData.targetLocationFn(rChar,self)
        if not targetX then
			return 'no target location'
		end
    elseif self.tData.pathX then
        targetX,targetY = self.tData.pathX,self.tData.pathY
    elseif self.tData.rTargetObject then
        self.bForcePathToNearest = true
        targetX,targetY = self.tData.rTargetObject:getLoc()
        targetObj = self.tData.rTargetObject
        if not targetX or not targetY then
			return 'no target object location'
		end
    end

    if targetX == 'stay' then
    elseif targetX then
        local sError = self:_locationGates(rChar,targetX,targetY,targetObj)
        if sError then return sError end

        self.tBlackboard.tPathParams = self:_getPathParams(rChar,cx,cy,targetX,targetY)
        nPathDist = Pathfinder.testPath(cx, cy, targetX,targetY, rChar, self.tBlackboard.tPathParams)
        if not nPathDist then
            return 'no path'
        end
        self.tBlackboard.nPathDist = nPathDist
        
        self.tBlackboard.nPathStartWX,self.tBlackboard.nPathStartWY=cx,cy
        self.tBlackboard.nPathEndWX,self.tBlackboard.nPathEndWY=targetX,targetY
        
        self.tBlackboard.rTargetObject = self.tData.rTargetObject
    elseif self.tData.targetTileListFn then
        local tTilesByAddr, bSorted = self.tData.targetTileListFn(rChar, self)

        -- MTF TODO:
        -- we currently cap the path search at 5 tiles.
        -- If we're going to keep a cap, then we don't need to sort the whole list, we can just
        -- grab the 5 closest values and sort that shortened list.

        local tTiles = {}
        if not bSorted then
    	    if ActivityOption.DEBUG_PROFILE then Profile.enterScope("ActivityOption.Sort") end

            for addr,data in pairs(tTilesByAddr) do
                table.insert(tTiles,data)
            end
    
            table.sort(tTiles, function(a, b)
                return MiscUtil.isoDist(cx,cy,a.x,a.y) < MiscUtil.isoDist(cx,cy,b.x,b.y)
            end)    

    	    if ActivityOption.DEBUG_PROFILE then Profile.leaveScope("ActivityOption.Sort") end
        else
            tTiles = tTilesByAddr
        end

		local tileX,tileY
		local pathTests = 0
        for i, tile in ipairs(tTiles) do
            local wx,wy = tile.x,tile.y
            local tempTileX,tempTileY = World._getTileFromWorld(wx,wy)
			local addr = World.pathGrid:getCellAddr(tempTileX,tempTileY)


			if self.tData.bInfinite or not self.tReservedTiles or not self.tReservedTiles[addr] then
            
                local sError = self:_locationGates(rChar,wx,wy,nil)
                if not sError then
                    pathTests = pathTests+1

                    self.tBlackboard.tPathParams = self:_getPathParams(rChar,cx,cy,wx,wy)
                    nPathDist = Pathfinder.testPath(cx, cy, wx, wy, rChar, self.tBlackboard.tPathParams)
                    self.tBlackboard.nPathStartWX,self.tBlackboard.nPathStartWY=cx,cy
                    self.tBlackboard.nPathEndWX,self.tBlackboard.nPathEndWY=wx,wy
                    tileX,tileY = tempTileX,tempTileY
                    if nPathDist or pathTests == 5 then
                        break
                    end
                end
			end
        end
        if not nPathDist then
            return 'no path'
        end
        self.tBlackboard.nPathDist = nPathDist
        self.tBlackboard.tileX,self.tBlackboard.tileY = tileX,tileY
    end
end

function ActivityOption:_personalityGate(rChar)
    if self:getTag(rChar,'Job') ~= nil and rChar:getJob() ~= self:getTag(rChar,'Job') then return 'wrong job' end
    
    if self.tPersonality then
        for k,v in pairs(self.tPersonality) do
            local nStat = rChar:getPersonalityStat(k)
            if nStat <= v[1] or nStat > v[2] then
                return 'personality gate: '..k
            end
        end
    end
end

function ActivityOption:_gateActivity(rChar, nMinPriority)
    if not self.tData.bInfinite and self.nReservations >= (self.tData.nMaxReservations or 1) then
        return 'reserved'
    end

    local nPri = self:getPriority(rChar)
    if nPri < nMinPriority then
        return 'lower priority'
    end

    local eStatus = self:getTag(self,'Status')
    if eStatus and not rChar:hasUtilityStatus(eStatus) then
        return 'incorrect status'
    end

    local sReason = self:_personalityGate(rChar)
    if sReason then return sReason end

    if rChar:onDuty() and self:getTag(self,'WorkShift') == false then
        return 'task blacklisted for on-duty characters'
    end

    if rChar:inPrison() and self:getTag(self,'WorkShift') == true then
        return 'work shift tasks not performed in prison'
    end

    if self.tData.utilityGateFn then
		local gated
        if self.tData.utilityGateSelf then
            gated,sReason = self.tData.utilityGateFn(self.tData.utilityGateSelf, rChar, self)
        else
            gated,sReason = self.tData.utilityGateFn(rChar, self)
        end
        if not gated then
            return sReason or 'no reason given'
        end
    end
end


function ActivityOption.testCurve(taskName, step)
	if not step then
		step = 5
	end
	-- dump list of scores for a task sampled from a need's curve
	-- generic overview, doesn't take into account specific citizen variables
	print('============================')
	print('needs curve data dump for task ' .. taskName .. ':')
	print('----------------------------')
	local taskNeeds = OptionData.tAdvertisedActivities[taskName].Needs
    if taskNeeds then
	    for needName,benefit in pairs(taskNeeds) do
		    print('fulfillment of ' .. needName .. ' need (benefit ' .. benefit .. '):')
		    local need = Needs.tNeedList[needName]
		    for curVal=-100,100,step do
			    local futureVal = curVal + benefit
			    futureVal = Needs.clamp(futureVal)
			    local score = need.scoreFn(curVal, futureVal, need.curveFn)
			    print(curVal .. ' -> ' .. futureVal .. ' = ' .. score)
		    end
	    end
    end
	print(taskName .. ' dump complete.')
	print('============================')
end

return ActivityOption
