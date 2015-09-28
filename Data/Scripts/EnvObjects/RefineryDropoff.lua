local Class=require('Class')
local GameRules=require('GameRules')
local Character=require('CharacterConstants')
local EnvObject=require('EnvObjects.EnvObject')
local ObjectList=require('ObjectList')
local CharacterManager=require('CharacterManager')
local ActivityOptionList=require('Utility.ActivityOptionList')
g_ActivityOption=g_ActivityOption or require('Utility.ActivityOption')

local RefineryDropoff = Class.create(EnvObject, MOAIProp.new)

RefineryDropoff.nRefineryCount=0

function RefineryDropoff:init(sName, wx, wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)
    EnvObject.init(self,sName, wx,wy, bFlipX, bFlipY, bForce, tSaveData, nTeam)

	RefineryDropoff.nRefineryCount=RefineryDropoff.nRefineryCount+1

    local tData=
    {
        rTargetObject=self,
        bInfinite=true, -- Prevent miners from hanging out in space forever. Instead, we need to add some queueing at the refinery dropoff.
        utilityGateFn=function(rChar)
            return rChar:getJob() == Character.MINER, 'not a miner, or no rocks' 
        end,
    }
    self.rDropOffOption = g_ActivityOption.new('DropOffRocks',tData)
	-- doctor corpse dropoff task
	-- (modifying tData in place will change the rock task!)
	local tCorpseDropData = {
        rTargetObject=self,
		utilityGateFn=function(rChar) return rChar:getJob() == Character.JANITOR, 'not a doctor' end, --utilityGateFn=function(rChar) return rChar:getJob() == Character.DOCTOR, 'not a doctor' end,
	}
    self.rCorpseDropOption = g_ActivityOption.new('DropOffCorpse', tCorpseDropData)

    local tData=
    {
        rTargetObject=self,
        utilityGateFn=function(rChar,rAO)
            local sItemKey = rChar:getWorstItem(true)
            if sItemKey then
                return Character.discardItemGate(rChar,rAO,sItemKey,false)
            end
            return false,'nothing to incinerate'
        end,
        utilityOverrideFn=function(rChar,rAO,nOriginalUtility)
            local sItemKey = rChar:getWorstItem(true)
            if sItemKey then
                return Character.discardItemUtility(rChar,rAO,nOriginalUtility,false,sItemKey)
            end
            return -1
        end
    }
    self.rIncinerateStuffOption = g_ActivityOption.new('IncinerateStuff',tData)
end

function RefineryDropoff:getAvailableActivities()
    local tActivities = EnvObject.getAvailableActivities(self)
	if self:isFunctioning() then
		table.insert(tActivities, self.rDropOffOption)
		table.insert(tActivities, self.rCorpseDropOption)
		table.insert(tActivities, self.rIncinerateStuffOption)
	end
    return tActivities
end

function RefineryDropoff:remove()
    if self.bDestroyed then return end

	EnvObject.remove(self)

	RefineryDropoff.nRefineryCount=RefineryDropoff.nRefineryCount-1
end

return RefineryDropoff
