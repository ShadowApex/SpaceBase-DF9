local Class=require('Class')
local DFUtil = require("DFCommon.Util")
local EnvObject=require('EnvObjects.EnvObject')
local Gui = require('UI.Gui')
local SoundManager=require('SoundManager')

local Jukebox = Class.create(EnvObject, MOAIProp.new)

function Jukebox:init(sName, wx, wy, bFlipX, bForce, tSaveData, nTeam)
	EnvObject.init(self, sName, wx, wy, bFlipX, bForce, tSaveData, nTeam)
	self.bIsOn = false
	print("Jukebox created!")
end

function Jukebox:setOn(isOn)
	print("Trying to switch jukebox")
	if self.bIsOn == isOn then return end

	self.bIsOn = isOn

	SoundManager.playSfx3D("jukebox_music", self.wx, self.wy, 0)

	print(string.format("Jukebox status changed to %s", self.bIsOn))
	--return self.bIsOn
end

function Jukebox:isOn()
	--print("Checking if Jukebox is on")
	if self.bDestoryed or self.nCondition < 1 then
		--print("Junkebox isn't active")
		return false
	end

	if self.bIsOn then
		--print("Junkebox is active")
		return true
	end

	--print("Things aren't right")
	return false
end


function Jukebox:_listenGate(rChar)
	--print("Using listen gate")
	if not self:isOn() then
		return false, 'Jukebox insn\'t on or wrong zone'
	end
	return true
end

return Jukebox
