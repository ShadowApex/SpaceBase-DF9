local Task=require('Utility.Task')
local World=require('World')
local Class=require('Class')
local Room=require('Room')
local Malady=require('Malady')
local Log=require('Log')
local Character=require('CharacterConstants')

local ListenToJukebox = Class.create(Task)

ListenToJukebox.DURATION_MIN = 8
ListenToJukebox.DURATION_MAX = 18
ListenToJukebox.sDanceAnim = 'yawn'

function ListenToJukebox:init(rChar,tPromisedNeeds,rActivityOption)
	Task.init(self, rChar, tPromisedNeeds, rActivityOption)
	self.nDanceDuration = math.random(ListenToJukebox.DURATION_MIN, ListenToJukebox.DURATION_MAX)
	self.duration = nDanceDuration
	self.bInterrputOnPathFailure = true
	self.rTarget = rActivityOption.tData.rTargetObject
	if rActivityOption.tBlackboard.tPath then
		self:setPath(rActivityOption.tBlackboard.tPath)
	end
    assert(rActivityOption.tBlackboard.rChar == rChar)
    assert(rActivityOption.tBlackboard.rTargetObject == self.rTarget)
end

function ListenToJukebox:onComplete( bSuccess )
	self.rTarget:setOn(false)
	Task.onComplete(self, bSuccess)
	if not bSuccess then
		return
	end
	self.rChar:alterMorale(Character.MORALE_DID_HOBBY, self.activityName)
	tType = Log.tTypes.JUKEBOX_GENERIC
	Log.add(tType, self.rChar)
end

function ListenToJukebox:onUpdate( dt )
	if not self.rTarget:isOn() then
		self.rTarget:setOn(true)
	elseif self.rTarget:isOn() and self:interacting() then
		--print("Interacting with jukebox")
		if self:tickInteraction(dt) then
			return true
		end
	elseif self:tickWalk(dt) then
		--print("walking to jukebox")
		--print(self.sDanceAnim)
		--print(self.rTarget)
		--print(self.nDanceDuration)
        if not self:attemptInteractWithObject(self.sDanceAnim, self.rTarget, self.nDanceDuration, true) then
            self:interrupt('Failed to reach the Jukebox.')
        end
        --print("end walking")
    end
end

return ListenToJukebox