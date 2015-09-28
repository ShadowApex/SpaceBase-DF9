local World=require('World')
local Character=require('CharacterConstants')
local Oxygen=require('Oxygen')
local Room=require('Room')
local MiscUtil=require('MiscUtil')
--local TreeWrapTask = require('Utility.Tasks.TreeWrapTask')
local OptionData = require('Utility.OptionData')
local DFMath = require('DFCommon.Math')
local InventoryData=require('InventoryData')
local ObjectList=require('ObjectList')
local ActivityOption=nil
local ActivityOptionList=nil

local GlobalObjects = {
}

function GlobalObjects.reset()
    ActivityOption=require('Utility.ActivityOption')
    ActivityOptionList=require('Utility.ActivityOptionList')
    GlobalObjects.envObjBuildList = ActivityOptionList.new(GlobalObjects)
end

-- random is allowed, because rooms are pre-scored during sort.
local roomScoreFn=function(rChar,rRoom)
    local nScore = 10 + DFMath.randomFloat(-2,2)
    nScore = nScore + 5*rChar:getNormalizedAffinity('Room '..rRoom.id)
    if rRoom:getZoneName() == 'RESIDENCE' and rRoom.zoneObj.getAssignmentSlots then
        local tSlots,nAssigned=rRoom.zoneObj:getAssignmentSlots()
        local nUnassigned=#tSlots-nAssigned
        if rRoom.zoneObj:isCharAssigned(rChar) then
            nScore=nScore+4
        else
            if nAssigned > 0 then
                if nUnassigned == 0 then
                    nScore = -1 -- room invalid; < 0 score indicates 'do not pick'
                elseif nAssigned >= nUnassigned then
                    nScore = nScore - 4
                else
                    nScore = nScore - 2
                end
            end
        end
    end
    return nScore
end

-- Utility functions for activities that don't care where they take place, as long
-- as it's in a safe, player-owned room.
-- Can be used as targetLocationFn.
-- Prefers to avoid residences that are assigned to other characters.
function GlobalObjects.getNearbySafeLoc(rChar,rAO)

    local r = rChar:getRoom()
    if r then
        local tRooms = {}
        if r ~= Room.getSpaceRoom() and not r:isDangerous() then
            table.insert(tRooms, {rRoom=r,nScore=roomScoreFn(rChar,r)})
        end
        local tAdjoining=r:getAdjoiningRooms()
        for rAdj,_ in pairs(tAdjoining) do
            if rAdj ~= Room.getSpaceRoom() and not rAdj:isDangerous() then
                table.insert(tRooms,{rRoom=rAdj,nScore=roomScoreFn(rChar,rAdj)})
            end
        end
        if #tRooms > 0 then
            table.sort(tRooms, function(tA,tB) 
                if tA.nScore == tB.nScore then
                    -- tiebreaker
                    return tA.rRoom.id < tB.rRoom.id
                else
                    return tA.nScore < tB.nScore
                end
            end)
            if tRooms[1].nScore > 0 then
                return r:randomLocInRoom(false,true,true)
            end
        end
        -- fallback.
        if r.tContiguousRooms then
            for id,rRoom in pairs(r.tContiguousRooms) do
                if not rRoom:isDangerous() then
                    return r:randomLocInRoom(false,true,true)
                end
            end
        end
    end
    
    return GlobalObjects._getReturnToBaseLocation(rChar,rAO)
end

function GlobalObjects.getGlobalUtilityObjects(rChar)
    local tOptions = {}

    table.insert(tOptions, ActivityOption.new('Starve', {bInfinite=true,
        targetLocationFn=GlobalObjects.getNearbySafeLoc,
        utilityGateFn=function(rChar,rAO) return rChar:starving(), 'not starving' end,
        }))
    table.insert(tOptions, ActivityOption.new('SleepOnFloor', {bInfinite=true,
        targetLocationFn=GlobalObjects.getNearbySafeLoc,
        --utilityGateFn=function(rChar,rAO) return not rChar:inHazardousLoc(),'hazardous' end 
        }))

    -- rampage
    table.insert(tOptions, ActivityOption.new('ViolentRampagePatrol', {bInfinite=true,bDestroyDoors=true,bAllowHostilePathing=true}))
    table.insert(tOptions, ActivityOption.new('NonviolentRampageSabotage', {bInfinite=true,bDestroyDoors=false,bAllowHostilePathing=false}))

    table.insert(tOptions, ActivityOption.new('WanderAround', {
        targetLocationFn=GlobalObjects.getNearbySafeLoc,
        bInfinite=true}
        ))
    table.insert(tOptions, ActivityOption.new('WanderAroundSpace', {bInfinite=true,bSpace=true}))
    table.insert(tOptions, ActivityOption.new('WorkOutNoGym', {bInfinite=true, 
        targetLocationFn=GlobalObjects.getNearbySafeLoc,
        utilityGateFn=function(rChar,rAO) 
--            if rChar:inHazardousLoc() then return false,'hazardous' end
            if rChar:retrieveMemory('bWorkedOutRecently') then return false, 'worked out recently' end
            return true end}))
    table.insert(tOptions, ActivityOption.new('PlayGameSystem', {bInfinite=true, 
        targetLocationFn=GlobalObjects.getNearbySafeLoc,
        utilityGateFn=function(rChar,rAO) 
--            if rChar:inHazardousLoc() then return false,'hazardous' end
            if rChar:retrieveMemory('bPlayedGameRecently') then return false,'played game recently' end
            return true end}))
    table.insert(tOptions, ActivityOption.new('Breathe', {bInfinite=true}))
    table.insert(tOptions, ActivityOption.new('VoluntarilyWalkToBrig', {bInfinite=true, 
        targetLocationFn=function(rChar)
            local rRoom = rChar.tStatus.tAssignedToBrig and ObjectList.getObject(rChar.tStatus.tAssignedToBrig)
            if rRoom then return rRoom:randomLocInRoom(false,true) end
        end,
        utilityGateFn=function(rChar,rAO) 
            local rRoom = rChar.tStatus.tAssignedToBrig and ObjectList.getObject(rChar.tStatus.tAssignedToBrig)
            if not rRoom then return false,'not assigned to brig' end
            if rChar:inPrison() then return false, 'already in brig' end
            return true end}))
    table.insert(tOptions, ActivityOption.new('VoluntarilyGetCuffed', {bInfinite=true, 
        utilityGateFn=function(rChar,rAO) 
            if rChar.tStatus.bMarkedForCuff and not rChar.tStatus.bCuffed then
                return true
            end
            return false, 'already cuffed or not marked for cuff'
            end}))
    
    local tData={ 
        utilityGateFn=function(rChar, rAO) 
            if rChar.tStatus.bCuffed then return false,'cuffed' end
            return rChar:heldItem() ~= nil, 'nothing in hands' 
        end,
		bInfinite=true
	}
    table.insert(tOptions,  ActivityOption.new('DropEverything', tData))
    
    table.insert(tOptions, ActivityOption.new('PutResearchDatacubeWherever', {bInfinite=true, 
        targetLocationFn=function(rChar,rAO)
            local tRooms, nNumRooms, nOtherTeamRooms = Room.getSafeRoomsOfTeam(rChar:getTeam(),false,'RESEARCH')
            if nNumRooms > 0 then
                local rRoom = MiscUtil.randomKey(tRooms)
                return rRoom:randomLocInRoom(false,true)
            end
            return GlobalObjects._getReturnToBaseLocation(rChar,rAO)
        end
        })
    )
    -- MTF HACK TODO: this is a good fallback for when the character has nothing to do with their held item,
    -- and would otherwise just hang out in breathe until hitting a survival level threat because they
    -- don't want to hit the usual DropEverything penalties.
    -- The hack is the test for Rock, since this is a build-day fix and I don't want to screw up mining.
    -- If we have time to remove the Rock check and test, then do so.
    tData={ 
        utilityGateFn=function(rChar, rAO) 
            if rChar.tStatus.bCuffed then return false,'cuffed' end
            if rChar:heldItem() and rChar:heldItem().sTemplate ~= InventoryData.MINE_PICKUP_NAME then
                return true
            end
            return false, 'nothing/rock in hands'
        end,
                    bInfinite=true}
    table.insert(tOptions,  ActivityOption.new('FallbackDropEverything', tData))

    -- Prereq is set in OptionData.
    table.insert(tOptions,  ActivityOption.new('DropRocksOnFloor', {bInfinite=true}))

    tData={ 
		targetLocationFn=function(rChar,rAO)
			if rChar:getRoom() and rChar:getRoom():getTeam() == rChar:getTeam() then
				return rChar:getLoc()
			end
			local tRooms, nNumRooms = Room.getRoomsOfTeam(rChar:getTeam())
			if nNumRooms > 0 then
				local rRoom = MiscUtil.randomKey(tRooms)
				return rRoom:randomLocInRoom(false,true)
			end
		end,
		bInfinite=true
	}
    table.insert(tOptions,  ActivityOption.new('Patrol', tData))

    local tObjects = { {tUtilityOptions=tOptions} }

    -- local rAO = g_ERBeacon:getActivityOption()
    -- if rAO then
        -- table.insert(tObjects, { tUtilityOptions = { rAO } })
    -- end
	local tActivityOptions = g_ERBeacon:getActivityOptions()
	for k,v in pairs(tActivityOptions) do
		table.insert(tObjects, { tUtilityOptions = { v } })
	end

    return tObjects
end

function GlobalObjects.getVacuumActivityOption()
    if not GlobalObjects.rVacuum then
        GlobalObjects.rVacuum = ActivityOption.new('VacuumPull', {bInfinite=true})
    end
    return GlobalObjects.rVacuum
end

function GlobalObjects.getFireActivityOption()
    if not GlobalObjects.rFire then
        GlobalObjects.rFire = ActivityOption.new('PanicOnFire', {bInfinite=true})
    end
    return GlobalObjects.rFire
end

function GlobalObjects._getReturnToBaseLocation(rChar,rAO)
    local tRooms, nNumRooms, nOtherTeamRooms = Room.getSafeRoomsOfTeam(rChar:getTeam())
    if nNumRooms > 0 then
        local rRoom = MiscUtil.randomKey(tRooms)
        return rRoom:randomLocInRoom(false,true)
    end
end

return GlobalObjects
