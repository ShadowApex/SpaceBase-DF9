local Task=require('Utility.Task')
local Class=require('Class')
local Room=require('Room')
local DFMath=require('DFCommon.Math')
local MiscUtil=require('MiscUtil')
local Character=require('CharacterConstants')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')
local EmergencyBeacon=require('Utility.EmergencyBeacon')
local OptionData = require('Utility.OptionData')
local Log=require('Log')

local Explore = Class.create(Task)

--Explore.emoticon = 'work'
Explore.DURATION = 200

function Explore:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.nTargetTeam = g_ERBeacon:getTargetTeam(rChar)
    --print('Starting explore task; team',self.nTargetTeam)
    assert(self.nTargetTeam)
    g_ERBeacon:charResponded(self.rChar)
	self.bGoingToBeacon = true
    self.nBeaconDist=math.random(2,6)
    self.anchorX,self.anchorY = rActivityOption.tData.pathX,rActivityOption.tData.pathY
    self.rChar:setWeaponDrawn(true)
    self:_pathToUnexploredRoom()
end

function Explore:_pathToUnexploredRoom()
    local rTarget = self:_selectUnexploredRoom()
    if not rTarget then
        return true
    end
    local cx,cy = self.rChar:getLoc()
    local tx,ty = rTarget:getCenterTile(true,true)
    if tx then
        local wx,wy = g_World._getWorldFromTile(tx,ty)
        self:createPath(cx,cy,wx,wy)
    else
        return true
    end
end

-- Returns an adjacent unexplored room, or otherwise the nearest one (iso dist).
-- Doesn't perform a path test.
-- returns true as second argument if the room is adjacent & connected by door.
function Explore:_selectUnexploredRoom()
    Room.visibilityBlip(self.rChar:getTileLoc())
    local tRooms = Room.getRoomsOfTeam(self.nTargetTeam)
    local rRoom = Room.getRoomAt(self.rChar:getLoc())
    local tx,ty
    if rRoom then
        tx,ty = rRoom:getCenterTile()
    else
        tx,ty = g_World._getTileFromWorld(self.rChar:getLoc())
    end
    local tAccessible = rRoom and rRoom:getAccessibleByDoor()
    local rNearestRoom = nil
    local nBestDist = 100000
	local nRooms,nExploredRooms = 0,0
    for rUnexploredRoom,nID in pairs(tRooms) do
		nRooms = nRooms + 1
        if rUnexploredRoom:getVisibility() == g_World.VISIBILITY_HIDDEN then
			if tAccessible and tAccessible[rUnexploredRoom] then
				return rUnexploredRoom,true
			else
				local centerX,centerY = rUnexploredRoom:getCenterTile()
				local dist = MiscUtil.isoDist(tx,ty,centerX,centerY)
				if dist < nBestDist then
					-- MTF TODO: path test
					rNearestRoom = rUnexploredRoom
					nBestDist = dist
				end
			end
		else
			nExploredRooms = nExploredRooms + 1
		end
    end
	-- "done exploring" log
	if nExploredRooms == nRooms and self.nExploreStartTime and not self.rChar:retrieveMemory(Character.MEMORY_EXPLORED_RECENTLY) then
		-- saw combat vs didn't see combat variants
		local tLogType = Log.tTypes.DUTY_SECURITY_EXPLORED_NOCOMBAT
		local _,nLastCombat = self.rChar:retrieveMemory(Character.MEMORY_ENTERED_COMBAT_RECENTLY)
		if nLastCombat and nLastCombat > self.nExploreStartTime then
			tLogType = Log.tTypes.DUTY_SECURITY_EXPLORED_COMBAT
		end
		Log.add(tLogType, self.rChar)
		self.rChar:storeMemory(Character.MEMORY_EXPLORED_RECENTLY, true, 60)
	end
    if not rNearestRoom then
        rNearestRoom = MiscUtil.randomKey(tRooms)
    end
    return rNearestRoom, (rNearestRoom and tAccessible and tAccessible[rNearestRoom])
end

function Explore:onComplete(bSuccess)
    self.rChar:setWeaponDrawn(false)
    Task.onComplete(self,bSuccess)
    g_ERBeacon:charAbandoned(self.rChar)
end

function Explore:queueTask(sTaskName,tData)
    if self.bWaitingAtBeacon then
        self.tInterceptedTask = tData
        self.sInterceptedTask = sTaskName
    else
        Task.queueTask(self,sTaskName,tData)
    end
end

-- Test to see if we're close to the target area. Once we are, we wait until everyone's here.
function Explore:_enteredNewTile()
	Task._enteredNewTile(self)
	if self.bGoingToBeacon then
        local tx,ty = g_World._getTileFromWorld(self.rChar:getLoc())
        local nStartRoomID,nStartTX,nStartTY,nEndRoomID,nEndTX,nEndTY = self.tPath:getSegmentData()
        if nEndRoomID then
            local rNextRoom = Room.tRooms[nEndRoomID]
            if rNextRoom and rNextRoom.nTeam ~= Character.TEAM_ID_PLAYER then
                -- Our next path segment will take us to hostile territory.
                local dist = MiscUtil.isoDist(tx,ty,nEndTX,nEndTY)
                if dist <= self.nBeaconDist then
                    self.bGoingToBeacon = false
                end
            end
        end

		if not self.bGoingToBeacon then
			self:_waitAtBeacon()
		end
	end
end

function Explore:_waitAtBeacon()
    self.bGoingToBeacon = false
    self.bWaitingAtBeacon = true
	self.tPath = nil
	g_ERBeacon:charArrived(self.rChar)
	self:_startIdle()
end

function Explore:_startIdle()
    self.nIdleTime = DFMath.randomFloat(.5,1.5)
    self.rChar:playAnim('patrol_idle') 
end

function Explore:onUpdate(dt)
    if not g_ERBeacon:stillActive(self.rChar, self.anchorX,self.anchorY, nil, EmergencyBeacon.MODE_EXPLORE) then
		-- MTF TODO: award partial duty
        self:interrupt('Beacon went away')
        return
    end

    if self.bGoingToBeacon then
        if self:tickWalk(dt) then
--			Print(TT_Warning, "Character should not complete path in going to beacon stage.")
            self:interrupt("Character should not complete path in going to beacon stage.")
--			self:_waitAtBeacon()
        end
    elseif self.bWaitingAtBeacon then
        if g_ERBeacon:charShouldWait(self.rChar) then
            --self.nTimeWaited = self.nTimeWaited+dt
            g_ERBeacon:charWaiting(self.rChar, dt)
			-- tutorial derelict
			--GameRules.completeTutorialCondition('ExploredDerelict')
        else
            self.bWaitingAtBeacon = false
			-- remember when we started exploring to track combat
			self.nExploreStartTime = g_GameRules.elapsedTime
			-- "i'm going in" log
			if not self.rChar:retrieveMemory(Character.MEMORY_EXPLORED_RECENTLY) then
				Log.add(Log.tTypes.DUTY_SECURITY_START_EXPLORE, self.rChar)
			end
			GameRules.completeTutorialCondition('ExploredDerelict')
            if self.sInterceptedTask then
                local sName,tData = self.sInterceptedTask,self.tInterceptedTask
                Task.queueTask(self,sName,tData)
            end
        end
    else
        -- let's explore!
        if self.nIdleTime > 0 then
            self.nIdleTime = self.nIdleTime - dt
            if self.nIdleTime <= 0 then
                if self:_pathToUnexploredRoom() then
                    --log
                    local tLogData = { sKeyName = "", }        
                    Log.add(Log.tTypes.EXPLORED_ROOM, self.rChar, tLogData)  
                    return true
                end
            end
        elseif self:tickWalk(dt) then
            self:_startIdle()
        end
    end
end

function Explore:getActivityFriendlyName()
	local sLC = OptionData.tAdvertisedActivities[self.activityName].UIText
	if self.bWaitingAtBeacon then
		sLC = 'UITASK073TEXT'
	end
	return g_LM.line(sLC)
end

return Explore
