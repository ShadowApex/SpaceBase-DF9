-- Repurposed for incinerating anything.
--
local Task=require('Utility.Task')
local Class=require('Class')
local Log=require('Log')
local Character=require('CharacterConstants')
local GameRules = require('GameRules')
local Corpse = require('Pickups.Corpse')

local DropOffCorpse = Class.create(Task)

function DropOffCorpse:init(rChar,tPromisedNeeds,rActivityOption)
    self.super.init(self,rChar,tPromisedNeeds,rActivityOption)
    self.nDuration = 2
    if rActivityOption.name == 'IncinerateStuff' then
        self.sObjectKey = self.rChar:getWorstItem(true)
    else
        self.sObjectKey = self.rChar:heldItemName()
    end
    assertdev(self.sObjectKey)

    self.rTarget = rActivityOption.tData.rTargetObject
    self:setPath(rActivityOption.tBlackboard.tPath)
end

function DropOffCorpse:onUpdate(dt)
    if self:interacting() then
        if self:tickInteraction(dt) then
            local tItemData = self.rChar:destroyItem(self.sObjectKey)
            if not tItemData then
                self:interrupt('item to incinerate is gone')
                return
            elseif tItemData.sTemplate == 'Corpse' then
                self.rChar:alterMorale(Character.MORALE_MINE_ASTEROID, 'DroppedOffCorpse')
                local tLogData = { sDeceased = tItemData.sOccupantName }
                -- different logs for friendly, monster, raider
                local sLogType = Log.tTypes.DUTY_JANITOR_REFINE_CORPSE_FRIENDLY
                if tItemData.nType == Corpse.TYPE_RAIDER then
                    sLogType = Log.tTypes.DUTY_JANITOR_REFINE_CORPSE_RAIDER
                elseif tItemData.nType == Corpse.TYPE_MONSTER then
                    sLogType = Log.tTypes.DUTY_JANITOR_REFINE_CORPSE_MONSTER
                end
                print("Type",sLogType)
                print("Char",self.rChar)
                print("Data",tLogData)
                Log.add(sLogType, self.rChar, tLogData)
                -- people are made of matter :/
                local nYield = math.random(GameRules.MAT_CORPSE_MIN, GameRules.MAT_CORPSE_MAX)
                GameRules.addMatter(nYield)
				require('Base').incrementStat('nCorpsesRecycled')
            else
                GameRules.addMatter(1)
            end
            return true
        end
    elseif self.tPath then
        self:tickWalk(dt)
    else
        if self:attemptInteractWithObject('drop_off_corpse',self.rTarget,self.nDuration) then
            -- wait until completion
        else
            self:interrupt('Unable to reach dropoff point.')
        end
    end
end

return DropOffCorpse
