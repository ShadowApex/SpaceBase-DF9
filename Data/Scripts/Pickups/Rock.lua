local Class=require('Class')
local ObjectList=require('ObjectList')
local EnvObject=require('EnvObjects.EnvObject')
local Pickup=require('Pickups.Pickup')

local Rock = Class.create(Pickup, MOAIProp.new)

function Rock:init(sName, wx, wy, bFlipX, rRoom, bForce, tSaveData)
    Pickup.init(self, sName, wx, wy, bFlipX, rRoom, bForce, tSaveData)
end

function Pickup:pickedUp(rChar)
	self:remove()
end

return Pickup
