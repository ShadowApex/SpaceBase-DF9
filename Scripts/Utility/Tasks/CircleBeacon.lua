local Task=require('Utility.Task')
local Class=require('Class')
local Room=require('Room')
local ObjectList=require('ObjectList')
local GameRules=require('GameRules')
local DFMath=require('DFCommon.Math')
local EmergencyBeacon=require('Utility.EmergencyBeacon')

local CircleBeacon = Class.create(Task)

--CircleBeacon.emoticon = 'work'
CircleBeacon.DURATION = 200

function CircleBeacon:init(rChar, tPromisedNeeds, rActivityOption)
    Task.init(self, rChar, tPromisedNeeds, rActivityOption)
    self.duration = DFMath.randomFloat(self.DURATION*.9,self.DURATION*1.1)
    self.bGoingToBeacon = true
    self.anchorX,self.anchorY,self.anchorZ,self.anchorW = rActivityOption.tData.pathX,rActivityOption.tData.pathY,0,1
    self.bInside = rActivityOption.tData.bInside
    self.rTargetObject = rActivityOption.tData.rTargetObject
    self.bInterruptOnPathFailure = true
    self.nRepathTime = 1
    self.sWalkOverride = 'run'
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function CircleBeacon:_startIdle()
    self.nIdleTime = DFMath.randomFloat(.5,1.5)
    self.rChar:playAnim('breathe')
end

function CircleBeacon:onComplete(bSuccess)
    -- do not remove; used by subclasses.
    Task.onComplete(self,bSuccess)
end

function CircleBeacon:_pathToPointInRange()
    -- time till repathing if we have a target object
    self.nRepathTime = 2
    
    local cx,cy = self.rChar:getLoc()
    local targetWX, targetWY, targetWZ = self.anchorX, self.anchorY, self.anchorZ
    if self.rTargetObject then
        targetWX, targetWY, targetWZ = self.rTargetObject:getLoc()
        self.bInside = not self.rTargetObject:inSpace()
    end
    if self.bInside then

        local rRoom = Room.getRoomAt(targetWX, targetWY, targetWZ, self.anchorW, true)
        if rRoom then
            local wx,wy = rRoom:randomLocInRoom(false,true)
            self:createPath(cx,cy, wx,wy, false, rRoom:getTeam() ~= self.rChar:getTeam())
            return
        end
    end

    local randomX, randomY = math.random(-g_World.tileWidth*6,g_World.tileWidth*6), math.random(-g_World.tileHeight*8,g_World.tileHeight*8)
    randomX, randomY = targetWX + randomX, targetWY + randomY
    if self.bInside then
        if not g_World._isPathable(randomX,randomY,true) then
            return
        end
    end
    --if g_World.isPathable(randomX,randomY) then
        self:createPath(cx, cy, randomX, randomY, true)
    --end
end

function CircleBeacon:onUpdate(dt)
    if not g_ERBeacon:stillActive(self.rChar, self.anchorX,self.anchorY,self.rTargetObject,EmergencyBeacon.MODE_TRAVELTO) then
        -- MTF TODO: pro-rate the needs fulfilled here by time spent.
        return true
    end

    if self.bGoingToBeacon then
        if self:tickWalk(dt) then
            self.bGoingToBeacon = false
            self.sWalkOverride = nil
            self:_startIdle()
        else
            -- if seeking a moving target object, regenerate path every
            -- so often
            if self.rTargetObject and self.nRepathTime < 0 then
                self:_pathToPointInRange()
            end
            self.nRepathTime = self.nRepathTime - dt
        end
    else
        self.duration = self.duration - dt
        if self.duration < 0 then
            return true
        end
        if self.nIdleTime > 0 then
            self.nIdleTime = self.nIdleTime - dt
            if self.nIdleTime <= 0 then
                self:_pathToPointInRange()
            end
        elseif self:tickWalk(dt) then
            self:_startIdle()
        end
    end
end

return CircleBeacon
