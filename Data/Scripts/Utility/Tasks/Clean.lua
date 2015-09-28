local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')
local World=require('World')

local Clean = Class.create(Task)

--Clean.emoticon = 'clean' --doesn't exist yet

function Clean:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
	self.FindBlood()
end

function Clean:FindBlood()

end

function Clean:onUpdate(dt)
    if not self.bDone then
        -- try to finish
    else
        -- be done
        return true    
    end
end

function Clean:cleanBlood()
	local wx,wy = World.getLoc()

	local sDecal = nil
	
	g_World.pathGrid:getTileValue(tx,ty)
	local tx,ty = World._getTileFromWorld(wx,wy)
	local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    World.setFloorDecal(tx,ty,sDecal)
return Clean

