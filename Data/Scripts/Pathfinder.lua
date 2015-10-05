local Class=require('Class') 
local DFUtil = require('DFCommon.Util')
local MiscUtil = require('MiscUtil')
local DFMath = require('DFCommon.Math')
local Room = require('Room')
local Asteroid = require('Asteroid')
local Character = require('CharacterConstants')
local Oxygen = require('Oxygen')
local Airlock = nil
local ObjectList = require('ObjectList')
local Profile = require('Profile')

-- While generating a path, Pathfinder creates nodes with members:
--      f, g, nConnectionCost: information about path cost.
--      wx,wy,tx,ty,addr: the starting position at this node.
--      nDestRoomID: the room at this loc, or in the case of a door traversal, the target room at this loc.
--      nSrcRoomID,sourceRoomDirection: the room we came from (not always applicable)
--      tParentNode: previous node, if applicable.
--      bPathToNearest: set only on the final node, if bPathToNearest is allowed.
--      bBreach: whether this is a room breach transition (e.g. through a hole in a room, not through a door).
--      bSuited: whether the character is theoretically suited at this point in the path.
--  When we turn all of this work into a path, we create an array using these nodes, in the order of intended traversal. We add these members:
--      sNodeType: can be spacewalk, subpathfind, or terminator at path generation time. During path execution, depending on intercepts (see: airlock), can also be 'task'.
--                  Once 'subpathfind' is hit in pathing, it turns into a series of 'tilestep' nodes to move from tile to tile.
--                  'spacewalk' is expanded to spacewalkLerp, plus potential tilesteps to get into/out of position.
--                  'tilestep' is a lerp between two adjacent tiles.
--                  'spacewalkLerp' is a lot like tilestep, but the lerp can be between non-adjacent tiles.
--                  'terminator' is the final node, and does not get expanded. It is just the destination point, so once the character reaches it, the path is done.
--  In addition, all of the 'backwards' nodes (part of the dest-backwards search) get nSrcRoomID, etc. swapped to be forward-facing.
--
local Pathfinder = Class.create()

function Pathfinder.staticInit()
    Pathfinder.moaiPathFinder = MOAIPathFinder.new()
    Pathfinder.moaiPathTerrain = MOAIPathTerrainDeck.new()
    Pathfinder.moaiPathTerrain:reserve(g_World.logicalTiles.ASTEROID_VALUE_END, 3)
    --Pathfinder.moaiPathTerrain:setMask(g_World.logicalTiles.DOOR, MOAIGridSpace.TILE_HIDE)
    Pathfinder.moaiPathTerrain:setMask(g_World.logicalTiles.DOOR, 0)
	Pathfinder.moaiPathGraph = DFOxygenGridPathGraph.new()
	Pathfinder.moaiPathGraph:setGrid(g_World.pathGrid:getMOAIGrid())
	Pathfinder.moaiPathGraph:setOxygenGrid(g_World.oxygenGrid:getMOAIGrid())
    Pathfinder.moaiPathFinder:setGraph(Pathfinder.moaiPathGraph)
    Pathfinder.moaiPathFinder:setHeuristic ( MOAIGridPathGraph.DIAGONAL_DISTANCE )
    Pathfinder.moaiPathFinder:setTerrainDeck(Pathfinder.moaiPathTerrain)
    Pathfinder.tTaggedTiles = {}

    Pathfinder.tStats = {}
    Pathfinder.tStats.locNodesPushed = 0
    Pathfinder.tStats.totalNodesPushed = 0
    Pathfinder.tStats.doorNodesPushed = 0
    Pathfinder.tStats.totalNodesEvaluated = 0
    Pathfinder.tStats.doorsEvaluated = 0

    Pathfinder.stPathCache = {}
    
    Airlock = require('Zones.Airlock')
end

function Pathfinder.tagTile(addr,tTagSpec,tAdditionalData)
    Pathfinder.tTaggedTiles[addr] = (tTagSpec and {tTagSpec=tTagSpec,tAdditionalData=tAdditionalData or {}}) or nil
end

function Pathfinder.pathSoftBlocked(tx,ty)
    local addr = g_World.pathGrid:getCellAddr(tx,ty)
    local tag = Pathfinder.tTaggedTiles[addr] 
    if tag and tag.tTagSpec.fnSoftBlock then return tag.tTagSpec.fnSoftBlock(tag.tTagSpec,tag.tAdditionalData) end
    return false
end

function Pathfinder._setDest(t, tx, ty, bPathToNearest, bNoPathToNearestDiagonal)
    local tRooms = {}

    t.tDestInfo = {}
    t.tDestInfo.bPathToNearest=bPathToNearest
    t.tDestInfo.bNoPathToNearestDiagonal = bNoPathToNearestDiagonal
    t.tDestInfo.tx = tx
    t.tDestInfo.ty = ty
    local addr = g_World.pathGrid:getCellAddr(tx,ty)
    t.tDestInfo.addr = addr
    t.tDestInfo.tDoors = {}
    t.tDestInfo.tBreaches = {}
    

    local rRoom = Room.getRoomAtTile(tx,ty,1)
    if rRoom then
        tRooms[rRoom] = {tx=tx,ty=ty,bPathToNearest=bPathToNearest}
        -- Special case: if we're pathing to adjacent, and the dest tile is a breach,
        -- then we can add space as a dest.
        if bPathToNearest and rRoom.tBreaches[addr] and rRoom.tBreaches[addr].bSpaceBreach then
            t.tDestInfo.tSpace = {tx=tx,ty=ty,bPathToNearest=true}
        end
    else
        local tileVal = g_World.pathGrid:getTileValue(tx,ty)
        if tileVal == g_World.logicalTiles.SPACE then
            t.tDestInfo.tSpace={tx=tx,ty=ty,bPathToNearest=bPathToNearest}
        elseif Asteroid.isAsteroid(tileVal) or g_World.countsAsWall(tileVal) or (tileVal == g_World.logicalTiles.DOOR and bPathToNearest) then
            -- NOTE RE ABOVE: if we're pathing to nearest, treat a door just like a wall, since we just want to get next to it
            -- but not go through it.
            if not bPathToNearest then
                Print(TT_Warning, 'PATHFINDER.LUA: Pathing to a wall or asteroid, without bPathToNearest.')
                return false
            end
            -- Test all adjacencies.
            local bSpaced=false
            t.tDestInfo.tNearRooms = {}
            for i=2,5 do
                local atx, aty = g_World._getAdjacentTile(tx,ty,i)
                local r = Room.getRoomAtTile(atx,aty,1)
                -- we'll push space once as well
                if not r then 
                    if not bSpaced and g_World.pathGrid:getTileValue(atx,aty) == g_World.logicalTiles.SPACE then
                        t.tDestInfo.tSpace = {tx=atx,ty=aty,bPathToNearest=false}
                        bSpaced=true
                    end
                else 
                    tRooms[r] = {tx=atx,ty=aty,bPathToNearest=false} 
                    t.tDestInfo.tNearRooms[r.id] = 1
                end
            end
        elseif tileVal == g_World.logicalTiles.DOOR then
            local rDoor = ObjectList.getDoorAtTile(tx,ty)
            if rDoor then
                local dtx,dty = rDoor:getTileLoc()
                local doorAddr = g_World.pathGrid:getCellAddr(dtx,dty)
                t.tDestInfo.tDoors[doorAddr] = {tx=dtx,ty=dty,bPathToNearest=bPathToNearest}
            end
        else
            Print(TT_Warning, 'PATHFINDER.LUA: Did not find a room at tile val',tileVal,'May disrupt pathfinding.')
            assertdev(false)
            return false
        end
    end
    
    if t.tDestInfo.tSpace then
        for roomID, rSpaceAdjRoom in pairs(Room.tRooms) do
            if rSpaceAdjRoom.bDoorToSpace then
                local tDoorsToPush = {}
                for doorAddr,coord in pairs(rSpaceAdjRoom.tDoors) do
                    local rDoor = ObjectList.getDoorAtTile(coord.x,coord.y)
                    if rDoor and rDoor.bTouchesSpace then
                        t.tDestInfo.tDoors[doorAddr] = {tx=t.tDestInfo.tSpace.tx,ty=t.tDestInfo.tSpace.ty,bPathToNearest=t.tDestInfo.tSpace.bPathToNearest}
                    end
                end
            end
            if rSpaceAdjRoom.bBreach then
                for breachAddr, coord in pairs(rSpaceAdjRoom.tBreaches) do
                    -- test to verify the breach is space: it can also be a broken wall.
                    if coord.bSpaceBreach then
                        t.tDestInfo.tBreaches[breachAddr] = {tx=t.tDestInfo.tSpace.tx,ty=t.tDestInfo.tSpace.ty,bPathToNearest=t.tDestInfo.tSpace.bPathToNearest}
                    end
                end
            end
        end
    end
    
    for rRoomToReach,coordToReach in pairs(tRooms) do
        -- MTF NOTE AND TODO:
        -- This is somewhat wrong, because the character may be suited by the time they reach the room.
        local tDoors = rRoomToReach:getReachableDoors(coordToReach.tx, coordToReach.ty)
        for rDoor,_ in pairs(tDoors) do
            local dtx,dty = rDoor:getTileLoc()
            local doorAddr = g_World.pathGrid:getCellAddr(dtx,dty)
            t.tDestInfo.tDoors[doorAddr] = {tx=coordToReach.tx,ty=coordToReach.ty,bPathToNearest=coordToReach.bPathToNearest}
        end
        
        for addr, coord in pairs(rRoomToReach.tBreaches) do
            -- test to verify the breach is space: it can also be a broken wall.
            if coord.bSpaceBreach then
                t.tDestInfo.tBreaches[addr] = {tx=coordToReach.tx,ty=coordToReach.ty,bPathToNearest=coordToReach.bPathToNearest,bBreach=true}
                -- just do one
                break
            end
        end
    end

    return true
end

function Pathfinder._pushNodeLoc(t, tx,ty, g, tParentNode, tParams)
    local addr = g_World.pathGrid:getCellAddr(tx,ty)
    if t.tClosedNodesByAddr[addr] then return end

                --Profile.enterScope("Pathfinder.pushNodeLoc")
    Pathfinder.tStats.locNodesPushed = Pathfinder.tStats.locNodesPushed + 1
    assertdev(g)
    if not g then g = 0 end
    local tPushedNodes={}
    local nDestRoomID = tParams.nDestRoomID
    if not nDestRoomID then
        if tParams.bElevated then
            nDestRoomID=1
        else
            local rRoom = Room.getRoomAtTile(tx,ty,1)
            nDestRoomID = rRoom and rRoom.id
        end
    end
    
    local bCharacterStartOnWallCheat = nil
    if not nDestRoomID then
        local tileVal=g_World.pathGrid:getTileValue(tx,ty)
        if tileVal == g_World.logicalTiles.SPACE then
            nDestRoomID = 1
        elseif Asteroid.isAsteroid(tileVal) then
            nDestRoomID = 1
            if not tParams.bPathToNearest then
                Print(TT_Warning, 'PATHFINDER.LUA: Pathing to or from asteroid, without bPathToNearest.')
            end
        elseif (not tParams.bFirst and g_World.countsAsWall(tileVal)) or (tileVal == g_World.logicalTiles.DOOR and tParams.bPathToNearest) then
            -- NOTE RE ABOVE: if we're pathing to nearest, treat a door just like a wall, since we just want to get next to it
            -- but not go through it.
            if not tParams.bPathToNearest then
                Print(TT_Warning, 'PATHFINDER.LUA: Pathing to or from a wall, without bPathToNearest.')
            end
            -- When we attempt to push a wall loc, we need to push all adjacent rooms.
            local tPushed={}
            for i=2,5 do
                local atx, aty = g_World._getAdjacentTile(tx,ty,i)
                local rRoom = Room.getRoomAtTile(atx,aty,1)
                local id = rRoom and rRoom.id
                    
                if id and not tPushed[id] then
                    tPushed[id] = 1
                    -- Set bPathToNearest=false here, because we're pushing the adjacent tiles manually.
                    local tPushed = Pathfinder._pushNodeLoc(t, atx,aty, g, tParentNode, {bPathToNearest=false, bSuited=tParams.bSuited, bElevated=false,
                                                    nSrcRoomID=id})
                    if tPushed then
                        for _,t in ipairs(tPushed) do
                            table.insert(tPushedNodes,t)
                        end
                    end
                end
            end
                --Profile.leaveScope("Pathfinder.pushNodeLoc")
            -- NOTE: this case doesn't fall through.
            return tPushedNodes
        elseif tileVal == g_World.logicalTiles.DOOR or (tParams.bFirst and g_World.countsAsWall(tileVal)) then
            -- Special case: character is on a door tile.
            -- Currently only reachable if the start or end loc is a door tile.
            local rDoor = ObjectList.getDoorAtTile(tx,ty)
            local bForceFallbackPush = false
            if rDoor then
                local tNode,bNew
                tNode,bNew = Pathfinder._pushNodeDoor(t, addr, g_World.directions.SAME, g, tParentNode, rDoor)
                if tNode and bNew then
                    tNode.bPathToNearest=tParams.bPathToNearest
                    tNode.bSuited = tParams.bSuited
                    table.insert(tPushedNodes,tNode)
                    if tNode.nDestRoomID == 1 and not tParams.bSuited then
                        assertdev(false)
                    end
                end
            else
                -- Occasionally happens after prop or wall destruction.
                bForceFallbackPush = true
            end
            if bForceFallbackPush then
                -- Just pick an adjacent room at random if found.
                nDestRoomID = 1
                for i=2,9 do
                    local atx,aty = g_World._getAdjacentTile(tx,ty,i)
                    local rRoom = Room.getRoomAtTile(atx,aty,1)
                    if rRoom then
                        nDestRoomID = rRoom.id
                        break
                    end
                end
                if (tParams.bFirst and g_World.countsAsWall(tileVal)) then
                    -- Sometimes characters can find themselves on walls or broken walls etc., as a result of
                    -- fires, construction, and such. They can still try to path off. 
                    bCharacterStartOnWallCheat = true
                end
            else
                --Profile.leaveScope("Pathfinder.pushNodeLoc")
                return tPushedNodes
            end
        else
            if tileVal == g_World.logicalTiles.ZONE_LIST_START then
                -- Typically a dirty tile waiting for next world tick.
                -- Just fail the pathfind and it should be fixed shortly.
            else
                Print(TT_Warning, 'PATHFINDER.LUA: Did not find a room at tile val',tileVal,'May disrupt pathfinding.')
                assertdev(false)
            end
            return {}
        end
    end
    
    if nDestRoomID == 1 and not tParams.bSuited then
        Print(TT_Warning, 'PATHFINDER.LUA: Attempting to start pathing in space without a spacesuit.')
        return {}
    end

    local nSrcRoomID = tParams.nSrcRoomID or nDestRoomID
    
    local tNewNode = {g=g, tx=tx,ty=ty, addr=addr, nDestRoomID=nDestRoomID, tParentNode=tParentNode, bPathToNearest=tParams.bPathToNearest, 
        bSuited=tParams.bSuited, bElevated=tParams.bElevated, bBreach=tParams.bBreach,
        nSrcRoomID=nSrcRoomID, sourceRoomDirection=tParams.sourceRoomDirection,
        bLocNode=true, bCharacterStartOnWallCheat=bCharacterStartOnWallCheat }

    -- only test to allow the transition if we have a source room.
    -- don't need to test transition on the start or end nodes.
    local bAllow,nAdditionalCost
    --if tParams.nSrcRoomID and nDestRoomID then
        bAllow,nAdditionalCost = Pathfinder._allowTransition(t,tNewNode)
    --else
        --bAllow,nAdditionalCost=true,0
    --end
    if not bAllow then
        return {}
    end
    tNewNode.g = tNewNode.g+(nAdditionalCost or 0)
    
    tNewNode = Pathfinder._pushNode(t, tNewNode)
    if tNewNode then
        table.insert(tPushedNodes,tNewNode)
    end
                --Profile.leaveScope("Pathfinder.pushNodeLoc")
    return tPushedNodes
end

--function Pathfinder._allowTransition(t,nSrcRoomID,nDestRoomID)
function Pathfinder._allowTransition(t,tNewNode)
    local nDestRoomID = tNewNode.nDestRoomID
    local nSrcRoomID = tNewNode.nSrcRoomID

    if not nSrcRoomID or not nDestRoomID then
        Print(TT_Error, 'PATHFINDER.LUA: _allowTransition called without src/dest room:',nSrcRoomID,nDestRoomID)
        return true,0
    end
    if nDestRoomID == nSrcRoomID then return true,0 end

    local nAdditionalCost = 0
    -- Wrong team.
    if t.nRequiredTeam and Room.tRooms[nDestRoomID] and Room.tRooms[nDestRoomID]:getTeam() ~= t.nRequiredTeam then
        return
    end
    -- Not visible enough.
    if Room.tRooms[nDestRoomID] and t.nMinimumVisibility > Room.tRooms[nDestRoomID]:getVisibility() then
        return
    end
    
    -- Breach: Character would rather avoid the room.
    -- In some cases they are prohibited from pathing to it; in other cases just discouraged.
    if t.bTestMemoryBreach and not tNewNode.bSuited and t.rChar:retrieveMemory('bRoomBreached'..nDestRoomID) and Room.tRooms[nSrcRoomID] and not Room.tRooms[nSrcRoomID].bBreach then
        return
    end
    if not tNewNode.bSuited and Room.tRooms[nSrcRoomID] and not Room.tRooms[nSrcRoomID].bBreach and Room.tRooms[nDestRoomID] and Room.tRooms[nDestRoomID].bBreach then
        nAdditionalCost=60
    end
    
    -- Some path tests want to prohibit combat.
    if t.bTestMemoryCombat then
        if t.rChar:retrieveMemory('bCombatInRoom'..nDestRoomID) and 
                not t.rChar:retrieveMemory('bCombatInRoom'..nSrcRoomID) and 
                Room.tRooms[nSrcRoomID] and not Room.tRooms[nSrcRoomID].bBreach then
            return
        end
    end

    return true, nAdditionalCost
end

function Pathfinder._pushNodeDoor(t, addr, srcDir, g, tParentNode, rDoor)
    if t.tClosedNodesByAddr[addr] then return end

                --Profile.enterScope("Pathfinder.pushNodeDoor")
    Pathfinder.tStats.doorNodesPushed = Pathfinder.tStats.doorNodesPushed + 1
    assert(g)
    if not Room.tWallsByAddr[addr] then
        Print(TT_Warning, "PATHFINDER.LUA: Door not found at addr",addr)
                --Profile.leaveScope("Pathfinder.pushNodeDoor")
        return
    end

    local tx, ty = g_World.pathGrid:cellAddrToCoord(addr)

    local srcRoomID = nil
    local destRoomID = nil
    if srcDir == g_World.directions.SAME then
        local rSrcRoom = Room.getRoomAtTile(tx,ty,1,true)
        local id = (rSrcRoom and rSrcRoom.id) or -1
        -- Special case for starting on a door. We don't have a source/dest direction.
        srcRoomID = id
        destRoomID = id
    else
        srcRoomID = Room.tWallsByAddr[addr].tDirs[srcDir] or 1
        destRoomID = Room.tWallsByAddr[addr].tDirs[ g_World.oppositeDirections[srcDir] ] or 1
        if srcRoomID == destRoomID then
            -- It's a door standing in the middle of a room.
            -- Probably useless, but at least useful if we're standing on it. 
            -- I'm trying out this approach of just jacking up the cost to make it undesirable.
            -- We can see how it goes.
            g = g+20
        end        
    end
    
    local tNewNode = {addr=addr, nDestRoomID=destRoomID, nSrcRoomID=srcRoomID, 
            bSuited = tParentNode and tParentNode.bSuited,
            sourceRoomDirection=srcDir, g=g, tParentNode=tParentNode, tx=tx,ty=ty, bDoorNode=true}

    local bAllow,nAdditionalCost = Pathfinder._allowTransition(t,tNewNode)
    if not bAllow then
        return
    end
    tNewNode.g = tNewNode.g+nAdditionalCost

    return Pathfinder._pushNode(t, tNewNode)
                --Profile.leaveScope("Pathfinder.pushNodeDoor")
end

function Pathfinder._pushNode(tPathfinderState, tNewNode)
                --Profile.enterScope("Pathfinder.pushnode")
    assert(tNewNode.bLocNode or tNewNode.bDoorNode)
    Pathfinder.tStats.totalNodesPushed = Pathfinder.tStats.totalNodesPushed + 1
    local nDestRoomID = tNewNode.nDestRoomID
    local addr = tNewNode.addr
    local g = tNewNode.g
    local tOpenList = tPathfinderState.tOpenNodesByAddr

    assert(not tPathfinderState.tClosedNodesByAddr[addr])
    
    if tOpenList[addr] then
        local tExistingNode = tOpenList[addr]
        -- We found the node already in our open list.
        -- Update the g.
        -- NOTE: if the 'room' is space, testing for a better g isn't quite correct. Testing for a better f might be better.
        if tExistingNode.g > g then
            tOpenList[addr] = tNewNode
        else
                --Profile.leaveScope("Pathfinder.pushnode")
            -- We already pushed a better path to this node. Ignore this push.
            return tExistingNode, false
        end
    end

    tOpenList[addr] = tNewNode
    local destX,destY = tPathfinderState.txDest,tPathfinderState.tyDest
    local h = MiscUtil.isoDist(tNewNode.tx,tNewNode.ty,destX,destY) +1
    tNewNode.h = h
    tNewNode.bSuited = tNewNode.bSuited or (tNewNode.tParentNode and tNewNode.tParentNode.bSuited)
    
                --Profile.leaveScope("Pathfinder.pushnode")
    return tNewNode, true
end

function Pathfinder._getBestF(t,nBestF)
    -- TODO: store in a sorted list so we don't loop every time.
    local tOpenNodes = t.tOpenNodesByAddr
    local tx,ty = t.txDest,t.tyDest

    local bestF = nBestF or 65536
    local bestNode = nil

    for id,tNode in pairs(tOpenNodes) do
        local f = tNode.g + tNode.h
        if f < bestF then
            bestF = f
            bestNode = tNode
        end
    end
    return bestNode,bestF
end

function Pathfinder._getNextOpenNode(t)
    local tSrcNode,fS = Pathfinder._getBestF(t,t.tBestPath and t.tBestPath.f)
    return tSrcNode
end

-- Return a cached path from rChar's current loc to the tDestInfo stored in t.
function Pathfinder._getCachedPath(rChar,t,tAdditionalParams)
    local idx
    local nearestAddr
    local tFoundDest
    
    local tAddrs = {}
    local tx,ty = rChar:getTileLoc()
    local srcAddr = g_World.pathGrid:getCellAddr(tx,ty)

    -- tDestInfo stores a variety of ways to reach the dest:
    -- a location, as well as doors and breaches that reach the room containing the loc.
    -- Iterate over all those potential dests to see if there's a cached path that hits one.
    -- (In this way we can use any cached path that reached the room.)
    -- We also add our current loc, if it reaches the dest.
    if Pathfinder._testReachedDest(t,srcAddr,false) then
        table.insert(tAddrs,{srcAddr})
    else
        -- I only add all this other stuff if the above test failed. Otherwise, we already
        -- have a great path to the dest above.
        for addr,tData in pairs(t.tDestInfo.tDoors) do
            table.insert(tAddrs,{addr})
        end
        for addr,tData in pairs(t.tDestInfo.tBreaches) do
            table.insert(tAddrs,{addr})
        end
    end
    
    for i,tPotentialDest in ipairs(tAddrs) do
        local addr = tPotentialDest[1]
        idx = Pathfinder._getCachedPathIndex(rChar, srcAddr,addr,tAdditionalParams)
        if idx then
            -- note: _testReachedDest is just to find bugs. It SHOULD always return true.
            tFoundDest = Pathfinder._testReachedDest(t,addr,false)
            if tFoundDest then
                local tPathArray = {}
                local tNode = Pathfinder.stPathCache[rChar][srcAddr][addr][idx].tPath
                if tNode == 'FAILED' then
                    return 'FAILED'
                end
                while tNode do
                    table.insert(tPathArray, 1, tNode)
                    tNode = tNode.tParentNode
                end
                return tPathArray,tFoundDest
            else
                Print(TT_Warning, 'PATHFINDER.LUA: Caching error: retrieved a path that does not reach the dest.')
                local dbgidx = Pathfinder._getCachedPathIndex(rChar, srcAddr,addr, tAdditionalParams)
                local dbgroom = Room.getRoomAtTile(t.tDestInfo.tx, t.tDestInfo.ty,1)
                if dbgroom then
                    local dbgdoors = dbgroom:getReachableDoors(t.tDestInfo.tx, t.tDestInfo.ty)
                end
                Pathfinder._testReachedDest(t,addr,false)
                assertdev(false)
            end
        end
    end        
end

function Pathfinder._cachePathFailure(rChar,srcAddr,tDestSpec,tAdditionalParams)
    local tFailedAddrs = {}
    if tDestSpec.tSpace then tFailedAddrs[-1] = tDestSpec end
    for addr,data in pairs(tDestSpec.tDoors) do
        tFailedAddrs[addr] = data
    end
    for addr,data in pairs(tDestSpec.tBreaches) do
        tFailedAddrs[addr] = data
    end

    if not Pathfinder.stPathCache[rChar] then Pathfinder.stPathCache[rChar] = {} end
    if not Pathfinder.stPathCache[rChar][srcAddr] then Pathfinder.stPathCache[rChar][srcAddr] = {} end

    for addr,tData in ipairs(tFailedAddrs) do
        if not Pathfinder._getCachedPathIndex(rChar, srcAddr,addr, tAdditionalParams) then
            if not Pathfinder.stPathCache[rChar][srcAddr][addr] then Pathfinder.stPathCache[rChar][srcAddr][addr] = {} end
            table.insert(Pathfinder.stPathCache[rChar][srcAddr][addr], {bPathToNearest=tData.bPathToNearest, nRequiredTeam=tAdditionalParams.nRequiredTeam, 
                nMinimumVisibility=tAdditionalParams.nMinimumVisibility or g_World.VISIBILITY_HIDDEN,
                tPath='FAILED'})
        end
    end
end

function Pathfinder._getCachedPathIndex(rChar, srcAddr, destAddr, tParams)
    local tNodeCacheData = Pathfinder.stPathCache[rChar] and Pathfinder.stPathCache[rChar][srcAddr] and Pathfinder.stPathCache[rChar][srcAddr][destAddr]
    if not tNodeCacheData then return nil end
    for n,tCache in ipairs(tNodeCacheData) do
        if not tCache.bPathToNearest or tCache.bPathToNearest == tParams.bPathToNearest then
            if tCache.nRequiredTeam == tParams.nRequiredTeam and (tParams.nMinimumVisibility or g_World.VISIBILITY_HIDDEN) <= tCache.nMinimumVisibility then
                return n
            end
        end
    end
end

function Pathfinder._cachePathNodes(rChar, tPathArray, tParams)
    local n=#tPathArray
    local srcAddr = tPathArray[1].addr
    if not Pathfinder.stPathCache[rChar] then Pathfinder.stPathCache[rChar] = {} end
    if not Pathfinder.stPathCache[rChar][srcAddr] then Pathfinder.stPathCache[rChar][srcAddr] = {} end
    local tCharCache = Pathfinder.stPathCache[rChar][srcAddr]
    for i=1,n do
        local tNode = tPathArray[i]
        local addr = tNode.addr
        if tNode.nDestRoomID == 1 then addr = -1 end
        if not tCharCache[addr] then
            tCharCache[addr] = {}
        end
        if not Pathfinder._getCachedPathIndex(rChar, srcAddr,addr, tParams) then
            table.insert(tCharCache[addr], {tPath=tNode, nRequiredTeam=tParams.nRequiredTeam,
                nMinimumVisibility=tParams.nMinimumVisibility or g_World.VISIBILITY_HIDDEN})
        else
            -- should we warn? shouldn't be re-finding paths to cached paths.
        end
    end
end

function Pathfinder._testReachedDest(t,addr,bElevated)
    local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
    local rRoom = not bElevated and Room.getRoomAtTile(tx,ty,1)
    local tDest

    if rRoom then
        local rDestRoom = Room.getRoomAtTile(t.tDestInfo.tx,t.tDestInfo.ty,1)
        -- BUILD DAY HACK: we're not properly detecting pathability within a room, without hitting a door.
        -- So here's a special-case to do just that.
        -- Easy repro case: trap a builder in a room with no doors and attempt to build a door.
        -- TODO: determine a better way to resolve same-room pathToNearest successes.
        if t.tDestInfo.bPathToNearest then
            if t.tDestInfo.tNearRooms and rRoom.id and t.tDestInfo.tNearRooms[rRoom.id] then
                tDest = {tx=t.tDestInfo.tx,ty=t.tDestInfo.ty,bPathToNearest=t.tDestInfo.bPathToNearest,bNoPathToNearestDiagonal=t.tDestInfo.bNoPathToNearestDiagonal}
            end
        end
        -- Here's the normal non-hack code.
        if not tDest and rRoom == rDestRoom then
            -- reached dest
            tDest = {tx=t.tDestInfo.tx,ty=t.tDestInfo.ty,bPathToNearest=t.tDestInfo.bPathToNearest,bNoPathToNearestDiagonal=t.tDestInfo.bNoPathToNearestDiagonal}
        end
    elseif t.tDestInfo.tSpace then
        local tileVal = (bElevated and g_World.logicalTiles.SPACE) or g_World._getTileValue(tx,ty)
        if tileVal == g_World.logicalTiles.SPACE then
            tDest = {tx=t.tDestInfo.tSpace.tx,ty=t.tDestInfo.tSpace.ty,bPathToNearest=t.tDestInfo.tSpace.bPathToNearest}
        end
    end

    if not tDest and not bElevated then
        local coord = t.tDestInfo.tDoors[addr] or t.tDestInfo.tBreaches[addr] 
        if coord then
            -- reached dest.
            tDest = {tx=coord.tx,ty=coord.ty,bPathToNearest=coord.bPathToNearest,bBreach=coord.bBreach}
        end
    end
    
    if tDest then
        local rDestRoom = Room.getRoomAtTile(tDest.tx, tDest.ty, 1)
        if rDestRoom and not rDestRoom:isReachable(tx,ty,tDest.tx,tDest.ty) then
            tDest = nil
        end
    end

    return tDest
end

function Pathfinder._pushReachableDoors(t, nSrcRoomID, tReachableDoors, tOpenNode)
    local rRoom = Room.tRooms[nSrcRoomID]
    if not rRoom and nSrcRoomID ~= 1 then
        Print(TT_Error, 'PATHFINDER.LUA: Invalid room ID.')
        assertdev(false)
        return
    end
    for rDoor,_ in pairs(tReachableDoors) do
        if rDoor then
        local dtx,dty = rDoor:getTileLoc()
        local addr = g_World.pathGrid:getCellAddr(dtx,dty)
        local tWall = Room.tWallsByAddr[addr]
        if tWall and not t.tClosedNodesByAddr[addr] then
            Pathfinder.tStats.doorsEvaluated = Pathfinder.tStats.doorsEvaluated + 1
            local bPush = false
            local g = tOpenNode.g
            local bAirlock = rDoor.bValidAirlock and rDoor:functioningAsOuterAirlockDoor()
            if bAirlock then
                bPush = true
            elseif not rDoor:locked(t.rChar) or rDoor:getScriptController() then
                -- assume locked doors with a script controller will get unlocked eventually
                bPush = true
            end
            if bPush then
            --Profile.enterScope("Pathfinder.doors")
                local nEastID,nWestID = tWall.tDirs[rDoor.eastDir],tWall.tDirs[rDoor.westDir]
                if not nEastID and g_World._getTileValue( g_World._getAdjacentTile(dtx,dty,rDoor.eastDir) ) == g_World.logicalTiles.SPACE then
                    nEastID = 1
                end
                if not nWestID and g_World._getTileValue( g_World._getAdjacentTile(dtx,dty,rDoor.westDir) ) == g_World.logicalTiles.SPACE then
                    nWestID = 1
                end
                local rE,rW = (nEastID and Room.tRooms[nEastID]),(nWestID and Room.tRooms[nWestID])
                local srcDir
                local nRoomToPush
                if nSrcRoomID == nEastID then
                    srcDir = rDoor.eastDir
                    nRoomToPush = nWestID
                elseif nSrcRoomID == nWestID then
                    srcDir = rDoor.westDir
                    nRoomToPush = nEastID
                end

                -- Failure cases.
                -- 1: room claims this door, but it has no floor adjacent to the door. Probably because of a diagonal adjacency.
                -- 2: Door leads to same room, i.e. it's just standing in the middle of the room (or space).
                if not nRoomToPush or nRoomToPush == tOpenNode.nSrcRoomID then
                    bPush = false
                elseif nRoomToPush == 1 and not bAirlock and not tOpenNode.bSuited then
                    -- Failure case: don't push space from a non-airlock door when we're not suited.
                    -- That would be a poor choice for the citizen.
                    bPush = false
                end
                
                -- MTF TODO: We favor breaches to doors, when going to space.
                -- Solves using an airlock to go in and out of breached rooms.
                -- You actually should be able to use open doors, which might give shorter paths.
                -- But currently you'd get terrible behavior of going from space, into an airlock, 
                -- just to get to some fully breached tiles you could have walked to much faster.
                if nRoomToPush == 1 and rRoom and rRoom.bBreach then
                    bPush = false
                end

                if bPush then
                    -- Doing a bit of work to calculate g here. It should probably be done in _pushNodeDoor.
                    g = g+Pathfinder._getDist(tOpenNode.tx,tOpenNode.ty, dtx,dty, nSrcRoomID, nRoomToPush)                        
                    -- Add a cost for using an airlock, because it takes time.
                    if bAirlock then
                        if nRoomToPush == 1 then
                            g=g+15
                        else
                                -- Trying out random costing for going inside an airlock, to spread out airlock
                                -- use a little.
                                -- MTF NOTE: haven't yet figured out a way to keep this. The problem is that GoInside performs a small
                                -- pathfind to walk inside of the airlock. That's usually just a few steps-- but with this 
                                -- random costing, it can sometimes cause the airlock user to try to go into a different 
                                -- airlock than the one used.
                                -- GoInside and GoOutside shouldn't really use full pathfind. More like a subpathfind-only version.
                            g = g + 15 -- math.random(10,50)
                        end
                    end

                    local tPushed = Pathfinder._pushNodeDoor(t, addr, srcDir, g, tOpenNode, rDoor)

                    if bAirlock and tPushed then
                        if nSrcRoomID == 1 and tPushed.nDestRoomID ~= 1 then
                            tPushed.bSuited = false 
                        else
                            tPushed.bSuited = true 
                        end
                    end
                end
            --Profile.leaveScope("Pathfinder.doors")
            end
        end
        end
    end
end

function Pathfinder._getDist(tx1,ty1, tx2,ty2, room1, room2)
    local nDist = MiscUtil.isoDist(tx1,ty1,tx2,ty2)
    -- make spacewalking more expensive.
    if room2 == 1 then
        nDist = nDist*2
    end
    return nDist+1
end

function Pathfinder._pushRoomBreaches(t, tOpenNode, rRoom, bEnteringRoom)
    if not tOpenNode.bSuited or not rRoom.bBreach then return end

    for addr, coord in pairs(rRoom.tBreaches) do
        -- test to verify the breach is space: it can also be a broken wall.
        if coord.bSpaceBreach then
            -- Just using first pathable one for each room for now.
            -- Room breaches are stored by floor tile index (adjacent to space).
            -- So a non-pathable breach simply means that floor tile is not pathable: it is probably occupied by an envobject.
            local g = tOpenNode.g
            if not g_World._isPathBlocked(coord.roomX,coord.roomY,true) then
                if bEnteringRoom then
                    g=g+Pathfinder._getDist(tOpenNode.tx,tOpenNode.ty, coord.roomX,coord.roomY, 1, rRoom.id)
                    Pathfinder._pushNodeLoc(t, coord.roomX,coord.roomY, g, tOpenNode, {bSuited=true,
                        bBreach=true, nSrcRoomID=1, sourceRoomDirection=coord.dirFromRoom, nDestRoomID=rRoom.id })
                else
                    g=g+Pathfinder._getDist(tOpenNode.tx,tOpenNode.ty, coord.roomX,coord.roomY, rRoom.id, 1)
                    Pathfinder._pushNodeLoc(t, coord.roomX,coord.roomY, g, tOpenNode, {bSuited=true,
                        bBreach=true, nSrcRoomID=rRoom.id, sourceRoomDirection=g_World.oppositeDirections[coord.dirFromRoom], nDestRoomID=1 })
                end
                break
            end
        end
    end
end

function Pathfinder._pushSpace(t, tx, ty, tOpenNode)
    if not tOpenNode.bSuited then return end
        -- push all breaches, airlocks
        for roomID, rSpaceAdjRoom in pairs(Room.tRooms) do
            if rSpaceAdjRoom.bDoorToSpace then
                local tDoorsToPush = {}
                for addr,coord in pairs(rSpaceAdjRoom.tDoors) do
                    local rDoor = ObjectList.getDoorAtTile(coord.x,coord.y)
                    if rDoor and rDoor.bTouchesSpace then
                        tDoorsToPush[rDoor] = 1
                    end
                end
                Pathfinder._pushReachableDoors(t, 1, tDoorsToPush, tOpenNode)
            end
            Pathfinder._pushRoomBreaches(t, tOpenNode, rSpaceAdjRoom, true)
        end
end

-- Tests for reached dest.
-- Moves node from open to closed.
-- Pushes neighbors.
function Pathfinder._evaluateNode(t, tOpenNode)
                --Profile.enterScope("Pathfinder.evaluateNode")
    Pathfinder.tStats.totalNodesEvaluated = Pathfinder.tStats.totalNodesEvaluated + 1
    -- Move from open to closed.
    assert(not t.tClosedNodesByAddr[tOpenNode.addr])
    -- Remove from open list.
    t.tOpenNodesByAddr[tOpenNode.addr] = nil
    t.tClosedNodesByAddr[tOpenNode.addr] = tOpenNode

    local tDest = Pathfinder._testReachedDest(t,tOpenNode.addr, tOpenNode.bElevated)

    if tDest then
        local f = tOpenNode.g + tOpenNode.h
        if not t.tBestPath or t.tBestPath.f > f then
            t.tBestPath = { f=f, g=tOpenNode.h, tSeedNode=tOpenNode, tx=tDest.tx, ty=tDest.ty, bPathToNearest=tDest.bPathToNearest, bNoPathToNearestDiagonal=tDest.bNoPathToNearestDiagonal }
        end
        return true
    end

    local tileVal = g_World._getTileValue(tOpenNode.tx,tOpenNode.ty)
    local rRoom = Room.getRoomAtTile(tOpenNode.tx,tOpenNode.ty,1)
    if tOpenNode.bElevated or tileVal == g_World.logicalTiles.SPACE then
        Pathfinder._pushSpace(t, tOpenNode.tx,tOpenNode.ty, tOpenNode)
    elseif tileVal == g_World.logicalTiles.DOOR then
        -- push reachable doors in all connected rooms
        local rDoor = ObjectList.getDoorAtTile(tOpenNode.tx,tOpenNode.ty) 
        if not rDoor then
            assertdev(false)
            return
        end
        local rEastRoom,rWestRoom = rDoor:getRooms()
        local nEastRoom,nWestRoom = rDoor:getRoomIDs()
        if rEastRoom then 
            local tReachableDoors = rEastRoom:getReachableDoors(tOpenNode.tx,tOpenNode.ty,tOpenNode.bSuited)
            Pathfinder._pushReachableDoors(t, rEastRoom.id, tReachableDoors, tOpenNode)
            Pathfinder._pushRoomBreaches(t, tOpenNode, rEastRoom, false)
        elseif nEastRoom == 1 then
            Pathfinder._pushSpace(t, tOpenNode.tx,tOpenNode.ty, tOpenNode)
        end
        if rWestRoom then 
            local tReachableDoors = rWestRoom:getReachableDoors(tOpenNode.tx,tOpenNode.ty,tOpenNode.bSuited)
            Pathfinder._pushReachableDoors(t, rWestRoom.id, tReachableDoors, tOpenNode)
            Pathfinder._pushRoomBreaches(t, tOpenNode, rWestRoom, false)
        elseif nWestRoom == 1 then
            Pathfinder._pushSpace(t, tOpenNode.tx,tOpenNode.ty, tOpenNode)
        end
    elseif rRoom then
        -- push all reachable doors
        local tReachableDoors = rRoom:getReachableDoors(tOpenNode.tx,tOpenNode.ty,tOpenNode.bSuited)
        Pathfinder._pushReachableDoors(t, rRoom.id, tReachableDoors, tOpenNode)

        if rRoom.tBreaches[tOpenNode.addr] and rRoom.tBreaches[tOpenNode.addr].bSpaceBreach then
            local tBreachData = rRoom.tBreaches[tOpenNode.addr]
            -- This node is on a breach transition tile, so push space.
            --tOpenNode.sourceRoomDirection = g_World.oppositeDirections[tBreachData.dirFromRoom]
            --tOpenNode.nDestRoomID = 1
            Pathfinder._pushSpace(t, tOpenNode.tx, tOpenNode.ty, tOpenNode)
        else
            Pathfinder._pushRoomBreaches(t, tOpenNode, rRoom, false)
        end
    elseif tOpenNode.bCharacterStartOnWallCheat then
        for i=2,5 do
            local atx, aty = g_World._getAdjacentTile(tOpenNode.tx,tOpenNode.ty,i)
            local r = Room.getRoomAtTile(atx,aty,1)
            local bPushedSpace=false
            local tPushed={}
            -- we'll push space once as well
            if not r then 
                if not bPushedSpace and tOpenNode.bElevated and g_World.pathGrid:getTileValue(atx,aty) == g_World.logicalTiles.SPACE then
                    bPushedSpace = true
                end
            elseif not tPushed[r] then
                tPushed[r] = true
                Pathfinder._pushNodeLoc(t, atx, aty, tOpenNode.g+1, tOpenNode, {bSuited=tOpenNode.bSuited,
                    bBreach=false, nSrcRoomID=tOpenNode.nDestRoomID, sourceRoomDirection=g_World.oppositeDirections[i], nDestRoomID=r.id })
            end
        end
    else
        -- huh, we're standing on a wall or asteroid, that's no good.
        Print(TT_Error, 'PATHFINDER.LUA: Attempt to evaluate a non-pathable node.')
        assertdev(false)
        return
    end
end

function Pathfinder._createPathFromCache(rChar,tBestPathInfo,dbgWX,dbgWY)
    -- NOTE: properly setting 'nDestRoomID' for tPenultimateNode.
    -- Since we cache at doors, we can't be positive the exit direction
    -- for the cached node is towards our end point.
    -- So when creating a path from the cache, fix up the dest room.
    -- (Only applicable for paths starting from a door, ending in the same room.)
    if not tBestPathInfo.nDestRoomID then
        local rDestRoom = Room.getRoomAtTile(tBestPathInfo.tx,tBestPathInfo.ty, 1, true)
        tBestPathInfo.nDestRoomID = (rDestRoom and rDestRoom.id) or 1
    end
    tBestPathInfo.tPenultimateNode.nDestRoomID = tBestPathInfo.nDestRoomID
    
    local tDestNode = Pathfinder._createTerminusNode(tBestPathInfo)
    local tNode = tBestPathInfo.tPenultimateNode

    local tPathArray = {}
    while tNode do
        table.insert(tPathArray,1,tNode)
        tNode = tNode.tParentNode
    end
    table.insert(tPathArray,tDestNode)
    if tPathArray[1].sNodeType == 'spacewalk' and not rChar:spacewalking() then
        Print(TT_Error, 'PATHFINDER.LUA: Character attempting to path starting in space, but not in a spacesuit.')
        assertdev(false)
    end
    
    local txStart, tyStart = g_World._getTileFromWorld(dbgWX,dbgWY)
    assertdev(txStart == tPathArray[1].tx)
    assertdev(tyStart == tPathArray[1].ty)
    
    return Pathfinder.new(tPathArray)
end

function Pathfinder._convertPathfinderDataToPathArray(rChar, tBestPath)
    local tPathArray = {}
    local tNode = tBestPath.tSeedNode
    local tPrevProcessed = nil
    while tNode do
        -- HACK: when we push a node at a location, we don't know its dest node.
        -- We fix it up here. Might be a better idea to fix up when we first create the path?
        if tPrevProcessed then
            tNode.nDestRoomID = tPrevProcessed.nSrcRoomID
        end
    
        local tProcessedNode = Pathfinder._getPathNodeFromDataNode(tNode)
        table.insert(tPathArray, 1, tProcessedNode)
        if tPrevProcessed then tPrevProcessed.tParentNode = tProcessedNode end
        tPrevProcessed = tProcessedNode
        tNode = tNode.tParentNode
    end
    if tPathArray[2] then
        if tPathArray[1].nDestRoomID ~= tPathArray[2].nSrcRoomID then
            tPathArray[1].nDestRoomID = tPathArray[2].nSrcRoomID
        end
    end
    
    return tPathArray
end

function Pathfinder._createTerminusNode(tPathInfo)
    local tPathNode={}
    local tParentNode = tPathInfo.tPenultimateNode
    tPathNode.tx,tPathNode.ty = tPathInfo.tx,tPathInfo.ty
    tPathNode.addr = tPathInfo.addr
    tPathNode.wx,tPathNode.wy = g_World._getWorldFromTile(tPathNode.tx,tPathNode.ty)
    tPathNode.nDestRoomID = tPathInfo.nDestRoomID
    tPathNode.nSrcRoomID = tPathInfo.nDestRoomID
    tPathNode.sourceRoomDirection = tParentNode.sourceRoomDirection
    tPathNode.g = tPathInfo.g
    tPathNode.f = tPathInfo.f
    tPathNode.h = 0
    tPathNode.bPathToNearest=tPathInfo.bPathToNearest
    tPathNode.bNoPathToNearestDiagonal=tPathInfo.bNoPathToNearestDiagonal
    tPathNode.bSuited=tParentNode.bSuited
    tPathNode.tParentNode=tParentNode
    tPathNode.bBreach=tPathInfo.bBreach
    tPathNode.sNodeType='terminus'
    return tPathNode
end

function Pathfinder._getPathNodeFromDataNode(tDataNode)
    local tPathNode={}
    tPathNode.tx,tPathNode.ty = tDataNode.tx,tDataNode.ty
    tPathNode.addr = tDataNode.addr
    tPathNode.wx,tPathNode.wy = g_World._getWorldFromTile(tPathNode.tx,tPathNode.ty)
    tPathNode.nDestRoomID = tDataNode.nDestRoomID
    tPathNode.nSrcRoomID = tDataNode.nSrcRoomID
    tPathNode.sourceRoomDirection = tDataNode.sourceRoomDirection
    tPathNode.g = tDataNode.g
    tPathNode.f = tDataNode.f
    tPathNode.bPathToNearest=tDataNode.bPathToNearest
    tPathNode.bSuited=tDataNode.bSuited
    tPathNode.bBreach=tDataNode.bBreach
    tPathNode.bDoorNode = tDataNode.bDoorNode
    
    if tPathNode.nDestRoomID == 1 and not tPathNode.bSuited then
        assertdev(false)
    end
    
    if tPathNode.nDestRoomID == 1 then
        tPathNode.sNodeType = 'spacewalk'
    else
        tPathNode.sNodeType='subpathfind'
    end
    return tPathNode
end

-- Utility function: creates a spacewalk path between two points.
function Pathfinder.createSpacewalkPath(x0,y0,x1,y1,rChar)
    local txStart, tyStart = g_World._getTileFromWorld(x0, y0)
    local txEnd, tyEnd = g_World._getTileFromWorld(x1, y1)
    local startAddr = g_World.pathGrid:getCellAddr(txStart, tyStart)
    local destAddr = g_World.pathGrid:getCellAddr(txEnd,tyEnd)
    
    local tStartNode={addr=startAddr, nDestRoomID=1, nSrcRoomID=1, bSuited=true, bElevated=rChar:isElevated(), bBreach=false,
                        bLocNode=true, wx=x0,wy=y0, g=0,f=0, tx=txStart,ty=tyStart, sNodeType='spacewalk' }

    local tTerminus={ tParentNode=tStartNode, tx=txEnd,ty=tyEnd, addr=destAddr, wx=x1,wy=y1, nDestRoomID=1, nSrcRoomID=1, g=0,f=0,h=0, bSuited=true, bBreach=false,
                        sNodeType='terminus' }
                        
    local tPathArray={}
    table.insert(tPathArray,tStartNode)
    table.insert(tPathArray,tTerminus)
    return Pathfinder.new(tPathArray)
end

-- tAdditionalParams can contain:
--   * bPathToNearest
--   * bPathToNearestDiagonal
--   * nRequiredTeam: path will only use space, or rooms on this team
--   * nMinimumVisibility: path will only use space, or rooms this visible or more visible
--   * bTestMemoryBreach: try to avoid breached rooms (unless you're in a spacesuit)
--   * bTestMemoryCombat: try to avoid rooms with combat
function Pathfinder.getPath(x0, y0, x1, y1, rChar, tAdditionalParams)
    --Profile.enterScope("Pathfinder.GetPath")
    local nDist,tBestPathInfo = Pathfinder.testPath(x0, y0, x1, y1, rChar, tAdditionalParams)
    local rPathObj = nil
    if nDist then
        --t.tBestPath = { f=f, g=tOpenNode.h, tSeedNode=tOpenNode, tx=tDest.tx, ty=tDest.ty, bPathToNearest=tDest.bPathToNearest }
        rPathObj = Pathfinder._createPathFromCache(rChar,tBestPathInfo, x0,y0)
    end
    --[[
    if not rPathObj and bForce then
        Pathfinder.stPathCache = {}
        nDist,tPenultimateNode,tFinalNode = Pathfinder.testPath(x0, y0, x1, y1, rChar, tAdditionalParams)
        assert(false)
    end
    ]]--
    --Profile.leaveScope("Pathfinder.GetPath")
    return rPathObj
end

--[[
function Pathfinder._isPathable(tx,ty, bAllowSpace)
    if not g_World.isPathable(x1, y1) then return false end
        Pathfinder.moaiPathGraph:setAllowVacuumPathing(false,Oxygen.VACUUM_THRESHOLD_END)
end
]]--

function Pathfinder.testPath(x0, y0, x1, y1, rChar, tAdditionalParams)
    tAdditionalParams = tAdditionalParams or {}
    
    if not tAdditionalParams.bPathToNearest and not g_World.isPathable(x1, y1) then
        -- nothing
    else
        Profile.enterScope("Pathfinder.TestPath")
        local txStart, tyStart = g_World._getTileFromWorld(x0, y0)
        local txDest, tyDest = g_World._getTileFromWorld(x1, y1)
        
        local startAddr = g_World.pathGrid:getCellAddr(txStart, tyStart)
        local endAddr = g_World.pathGrid:getCellAddr(txDest, tyDest)
        local bSuited=(rChar and rChar:spacewalking()) or tAdditionalParams.bForceSpacewalking
        local tFinalNode
        
        if not bSuited and g_World._getTileValue(txStart,tyStart) == g_World.logicalTiles.SPACE then
            Profile.leaveScope("Pathfinder.TestPath")
            -- Character's just floating out in space. Sorry buddy, you're out of luck.
            return
        end

        local tPathfinderState = { tOpenNodesByAddr={}, tClosedNodesByAddr={}, txStart=txStart,tyStart=tyStart, txDest=txDest,tyDest=tyDest, nRequiredTeam=tAdditionalParams.nRequiredTeam, nMinimumVisibility=tAdditionalParams.nMinimumVisibility or g_World.VISIBILITY_HIDDEN, rChar=rChar }

        if tAdditionalParams.bTestMemoryBreach or tAdditionalParams.bTestMemoryCombat then 
            tPathfinderState.bTestMemoryBreach = tAdditionalParams.bTestMemoryBreach
            tPathfinderState.bTestMemoryCombat = tAdditionalParams.bTestMemoryCombat
        end

        --Profile.enterScope("Pathfinder.tp1")
        -- Push dest nodes. Then see if there's a cached path to one of them.

        if not Pathfinder._setDest(tPathfinderState, txDest, tyDest, tAdditionalParams.bPathToNearest, tAdditionalParams.bNoPathToNearestDiagonal) then
            Profile.leaveScope("Pathfinder.TestPath")
            return
        end

        local tCachedPathArray,tDestSpec = Pathfinder._getCachedPath(rChar,tPathfinderState,tAdditionalParams)

        if tCachedPathArray then 
            if tCachedPathArray == 'FAILED' then
                Profile.leaveScope("Pathfinder.TestPath")
                return
            end
            local tLastNode = tCachedPathArray[#tCachedPathArray]
            local nLastNodeDist = Pathfinder._getDist(tLastNode.tx,tLastNode.ty,tDestSpec.tx,tDestSpec.ty, tLastNode.nDestRoomID, tLastNode.nDestRoomID)
            local f = tLastNode.g+nLastNodeDist
            local tPathData = { f=f, g=f, tPenultimateNode=tLastNode, tx=tDestSpec.tx, ty=tDestSpec.ty, bPathToNearest=tDestSpec.bPathToNearest,
                                bNoPathToNearestDiagonal=tDestSpec.bNoPathToNearestDiagonal}
            Profile.leaveScope("Pathfinder.TestPath")            
            return f,tPathData
        end

        Pathfinder._pushNodeLoc(tPathfinderState, txStart,tyStart, 0, nil, {bStartingNode=true, bPathToNearest=false, bSuited=bSuited, 
                                    bElevated=(rChar and rChar:isElevated()), bFirst=true})
        local tOpenNodeSrc = Pathfinder._getNextOpenNode(tPathfinderState)

        while tOpenNodeSrc do
            Pathfinder._evaluateNode(tPathfinderState, tOpenNodeSrc)
            tOpenNodeSrc = Pathfinder._getNextOpenNode(tPathfinderState)
        end

        local tPathArray = nil
        if tPathfinderState.tBestPath then
            --Profile.enterScope("Pathfinder.tp4")
            tPathArray = Pathfinder._convertPathfinderDataToPathArray(rChar, tPathfinderState.tBestPath)
            tPathfinderState.tBestPath.tPenultimateNode = tPathArray[#tPathArray]
            assertdev(txStart == tPathArray[1].tx)
            assertdev(tyStart == tPathArray[1].ty)
            Pathfinder._cachePathNodes(rChar,tPathArray,tAdditionalParams)
            --Profile.leaveScope("Pathfinder.tp4")
        else
            Pathfinder._cachePathFailure(rChar,startAddr,tPathfinderState.tDestInfo,tAdditionalParams)
        end
        Profile.leaveScope("Pathfinder.TestPath")
        if tPathfinderState.tBestPath then
            return tPathfinderState.tBestPath.f, tPathfinderState.tBestPath
        end
    end
end

function Pathfinder:init(tPathNodes)
    self.tPathNodes = tPathNodes
    --[[
    print('We got a path.')
    for idx, elem in ipairs(self.tPathNodes) do
        if elem.addr then
            print('   ',elem.sNodeType, 'door node. room',elem.nDestRoomID,'loc',elem.tx,elem.ty)
        else
            print('   ',elem.sNodeType, 'loc node. room',elem.nDestRoomID,'loc',elem.tx,elem.ty)
        end
    end
    ]]--
end

function Pathfinder:start(rChar,sWalkOverride,sBreatheOverride)
    assert(not self.rChar)
    self.rChar = rChar
    self.sWalkOverride = sWalkOverride
    self.sBreatheOverride = sBreatheOverride
    local x, y = self.rChar:getLoc()
    local tx,ty = g_World._getTileFromWorld(x,y)
    local addr = g_World.pathGrid:getCellAddr(tx,ty)
end

function Pathfinder:getCurrentStepData()
    return self.tCurrentStepData
end

function Pathfinder:pathDist(rChar)
    return self.tPathNodes[ #self.tPathNodes ].g * 100
end

function Pathfinder:_addSpecialNode(tSpecialNode)
    local nReplacementStart = math.max(tSpecialNode.nReplacementStart or 0,self.tCurrentStepData.nCurrentStep)
    local nReplacementEnd = tSpecialNode.nReplacementEnd or nReplacementStart
    self.tPathNodes[nReplacementStart].tSpecialNode = tSpecialNode

    for rmv=nReplacementStart+1,nReplacementEnd do
        table.remove(self.tPathNodes,rmv)
    end
    return nReplacementStart
end

function Pathfinder:_expandSubpathNode()
    local tSubpathNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    local tNextNode = self.tPathNodes[self.tCurrentStepData.nNextStep]
    

    -- MTF TODO: If we're in a spacesuit and going through a breach, we may want to try
    -- going directly to node after tNextNode. Current behavior can inefficiently route
    -- through a particular breach rather than going straight to dest.

    local tx0,ty0 = tSubpathNode.tx,tSubpathNode.ty
    local tx1,ty1 = tNextNode.tx,tNextNode.ty
    
    local ctx,cty,ctw = self.rChar:getTileLoc()
    if tx0 ~= ctx or ty0 ~= cty then
        -- Special-case fix: allow the airlock GoInside task to drop the character off somewhere else in the room,
        -- rather than where the pathing system initially planned (which was right on the door tile). Results in much
        -- nicer-looking behavior.
        -- Actually, in general, this is a useful way to allow graceful recovery.
        local _,tFoundRooms = Room.getRoomAtTile(ctx,cty,ctw,true)
        if tFoundRooms[tSubpathNode.nDestRoomID] then
            tx0,ty0 = ctx,cty
        else
            -- MTF TODO: make this an assertdev when there's time to track down who fails to start at the right spot.
            --assertdev(false)
            return false, tx0,ty0,tx1,ty1,tSubpathNode.nDestRoomID,'character attempting to start from a location they are not standing in, and unable to recover'
        end
    end
    
    local startAddr = g_World.pathGrid:getCellAddr(tx0,ty0)
    local endAddr = g_World.pathGrid:getCellAddr(tx1,ty1)

    if self.rChar:wearingSpacesuit() then
        Pathfinder.moaiPathTerrain:setMask(g_World.logicalTiles.SPACE, 0xFFFFFFFF)
        Pathfinder.moaiPathGraph:setAllowVacuumPathing(true,0)
    else
        Pathfinder.moaiPathTerrain:setMask(g_World.logicalTiles.SPACE, 0)
        Pathfinder.moaiPathGraph:setAllowVacuumPathing(false,Oxygen.VACUUM_THRESHOLD_END)
    end

    Pathfinder.moaiPathFinder:init( startAddr, endAddr )
    local pathFlags = MOAIGridPathGraph.NO_DIAGONALS

    local rDoor = ObjectList.getDoorAtTile(tx1,ty1)
    local bStopAtNeighbor = false
    local bNoDiagonal = false
    if tNextNode.bPathToNearest or tNextNode.bBreach then
        bStopAtNeighbor = true
    end
    if rDoor then --and (not rDoor:locked() or rDoor:getScriptController()) then
        bStopAtNeighbor = true
        bNoDiagonal = true
    end
    if tNextNode.bNoPathToNearestDiagonal or tNextNode.bBreach then
        bNoDiagonal = true
    end
    if bStopAtNeighbor then
        pathFlags = pathFlags + MOAIGridPathGraph.STOP_AT_NEIGHBOR
    end
    if bNoDiagonal then
        pathFlags = pathFlags + MOAIGridPathGraph.NO_DIAGONAL_STOP_AT_NEIGHBOR
    end
    
    Pathfinder.moaiPathFinder:setFlags(pathFlags)
    local maxIterations = 1000 -- I have no idea what this should actually be!
    Pathfinder.moaiPathFinder:findPath(maxIterations)
        
    local nPathSize = Pathfinder.moaiPathFinder:getPathSize()
    if nPathSize == 0 then
        if tx0 ~= tx1 or ty0 ~= ty1 then 
            return false, tx0,ty0,tx1,ty1,tNextNode.nSrcRoomID,'path size 0'
        end
    else
        self.nCurrentTilestepSource = self.tCurrentStepData.nCurrentStep
        local nInsertAt = self.tCurrentStepData.nCurrentStep+1
        local bFirst = true
        -- Our pathfind goes adjacent to the door, not into it.
        -- Add the final tilestep into the door.
        if not tNextNode.bPathToNearest and (rDoor or tSubpathNode.bBreach) then
            local wx, wy = g_World._getWorldFromTile(tx1,ty1)
            local addr = g_World.pathGrid:getCellAddr(tx1,ty1)
            table.insert(self.tPathNodes, nInsertAt, {wx = wx, wy = wy, addr=addr, tx=tx1,ty=ty1, nDestRoomID=tNextNode.nDestRoomID, sNodeType='tilestep'})
            bFirst = false
        end
        self.nFirstPostTilestepNode = nInsertAt+nPathSize
        --self.tPathNodes = {}
        for j = nPathSize,1,-1 do
            local addr = Pathfinder.moaiPathFinder:getPathEntry ( j )
            local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
            local wx, wy = g_World._getWorldFromTile(tx,ty)
            table.insert(self.tPathNodes, nInsertAt, {wx = wx, wy = wy, addr=addr, tx=tx,ty=ty, sNodeType='tilestep', nDestRoomID=((bFirst and tNextNode.nDestRoomID) or tSubpathNode.nDestRoomID)})
            bFirst = false
        end
    end
    return true, tx0,ty0,tx1,ty1
end

function Pathfinder:_insertTilestep(txFrom,tyFrom,bSpacewalk)
    local nInsertAt = self.tCurrentStepData.nCurrentStep+1
    local tNextNode = self.tPathNodes[self.tCurrentStepData.nNextStep]
    local addr = g_World.pathGrid:getCellAddr(txFrom,tyFrom)
    local wx, wy = g_World._getWorldFromTile(txFrom,tyFrom)
    local sNodeType = (bSpacewalk and 'spacewalkLerp') or 'tilestep'
    table.insert(self.tPathNodes, nInsertAt, {wx = wx, wy = wy, addr=addr, tx=txFrom, ty=tyFrom, nDestRoomID=tNextNode.nDestRoomID, sNodeType=sNodeType})    
end

function Pathfinder:_expandSpacewalkNode()
    local tCurrentNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    local tNextNode = self.tPathNodes[self.tCurrentStepData.nNextStep]

    local txSpacewalkDest,tySpacewalkDest = tNextNode.tx,tNextNode.ty
    --local txSpacewalkSrc,tySpacewalkSrc = tCurrentNode.tx,tCurrentNode.ty
    local ctx,cty,ctw = self.rChar:getTileLoc()
    local txSpacewalkSrc,tySpacewalkSrc = ctx,cty
    
    if(txSpacewalkDest == txSpacewalkSrc and tySpacewalkDest == tySpacewalkSrc) then
        return true
    end
    
    if g_World._getTileValue(txSpacewalkSrc, tySpacewalkSrc,ctw) ~= g_World.logicalTiles.SPACE then
        -- We don't always start spacewalking in space. We could be in the airlock doorway, or on the room breach tile.
        -- Add a one-tile step into space if necessary.
        local dirToSpace
        local rDoor = ObjectList.getDoorAtTile(ctx,cty)
        if rDoor and tCurrentNode.sourceRoomDirection then
            dirToSpace = g_World.oppositeDirections[tCurrentNode.sourceRoomDirection]
        end
        if dirToSpace == g_World.directions.SAME then dirToSpace = nil end
        if not dirToSpace and tCurrentNode.nSrcRoomID then
            local rRoom = Room.tRooms[tCurrentNode.nSrcRoomID]
            if rRoom then
                local addr = g_World.pathGrid:getCellAddr(txSpacewalkSrc,tySpacewalkSrc)
                local tBreach = rRoom.tBreaches[addr]
                dirToSpace = tBreach and tBreach.dirFromRoom
                
                -- MTF NOTE / UGLY
                -- We didn't get the dir to space at path creation time, probably because we started on a door.
                -- So we look up the direction to the room, and take the opposite direction.
                if not dirToSpace then
                    local tDoor = rRoom.tDoors[addr]
                    local tDoorInfo = Room.tWallsByAddr[addr]
                    if tDoor and tDoorInfo then
                        for i=2,5 do
                            if tDoorInfo.tDirs[i] == rRoom.id then
                                dirToSpace = g_World.oppositeDirections[i]
                                break
                            end 
                        end
                    end
                end
            end
        end
        if dirToSpace then
            txSpacewalkSrc, tySpacewalkSrc = g_World._getAdjacentTile(txSpacewalkSrc,tySpacewalkSrc,dirToSpace)
            if g_World._getTileValue(txSpacewalkSrc, tySpacewalkSrc) ~= g_World.logicalTiles.SPACE then
                return false, 'Character not in or adjacent to space.'
            end
        else
            return false, 'Character not in or adjacent to space.'
        end
    end

    local rDoor = ObjectList.getDoorAtTile(tNextNode.tx,tNextNode.ty)
    if not tNextNode.bPathToNearest and (rDoor or tNextNode.bBreach) then
        local dir = tNextNode.sourceRoomDirection
        if dir then
            txSpacewalkDest, tySpacewalkDest = g_World._getAdjacentTile(tNextNode.tx,tNextNode.ty,dir)
        end
    end

    if txSpacewalkDest ~= tNextNode.tx or tySpacewalkDest ~= tNextNode.ty then
        if not g_World.isAdjacentToTile(txSpacewalkDest, tySpacewalkDest, tNextNode.tx, tNextNode.ty, true) then
            assertdev(false)
            return false, 'Malformed spacewalk node.'
        end
        self:_insertTilestep(txSpacewalkDest,tySpacewalkDest,false)
    end
    self:_insertTilestep(txSpacewalkSrc,tySpacewalkSrc,true)
    if txSpacewalkSrc ~= ctx or tySpacewalkSrc ~= cty then
        if not g_World.isAdjacentToTile(txSpacewalkSrc, tySpacewalkSrc, ctx, cty, true) then
            return false, 'Failed dropoff from previous node.'
        end        
        self:_insertTilestep(ctx,cty,false)
    end

    return true
end

function Pathfinder:_processSpacewalkLerp()
    local tCurrentNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    local txCurrent,tyCurrent = tCurrentNode.tx,tCurrentNode.ty
    local tNext = self.tPathNodes[self.tCurrentStepData.nNextStep]
    
    if (tNext.tx == txCurrent and tNext.ty == tyCurrent) then
        local sStepName,tStepData = self:increment()
--        print('redundant spacewalk lerp, incrementing at',txCurrent,tyCurrent)
        return sStepName,tStepData
    end
    
    local sStepName,tStepData = self:_initWalkStep()
    return sStepName,tStepData
end

function Pathfinder:_processTilestepNode()
    -- Tilestep nodes move to the tx,ty of the next node.
    local tCurrentNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    local txCurrent,tyCurrent = tCurrentNode.tx,tCurrentNode.ty
    local tNext = self.tPathNodes[self.tCurrentStepData.nNextStep]
    
    if (tNext.tx == txCurrent and tNext.ty == tyCurrent) or tNext.bPathToNearest then
        local sStepName,tStepData = self:increment()
--        print('redundant tilestep, incrementing at',txCurrent,tyCurrent)
        return sStepName,tStepData
    end
    
	    -- I removed diagonal movement, but that led to some pretty ugly zigzagging. So...
	    -- if current and nextnext are adjacent
	    -- but through a corner (dir nsew)
	    -- if both diags are clear, just cut through the corner.
	    local nextNext = self.tCurrentStepData.nNextStep+1
	    if self.tPathNodes[self.tCurrentStepData.nNextStep].sNodeType == 'tilestep' and nextNext <= #self.tPathNodes 
                and not self.tPathNodes[nextNext].bPathToNearest then
		    local txNextNext,tyNextNext = self.tPathNodes[nextNext].tx,self.tPathNodes[nextNext].ty
		    local _,_,dir = g_World.isAdjacentToTile(txCurrent,tyCurrent, txNextNext, tyNextNext, true, false)
		    if dir then
			    local bCheat = false
			    local dirA,dirB = nil,nil
			    if dir == g_World.directions.N then
				    dirA = g_World.directions.NW
				    dirB = g_World.directions.NE
			    elseif dir == g_World.directions.E then
				    dirA = g_World.directions.SE
				    dirB = g_World.directions.NE
			    elseif dir == g_World.directions.W then
				    dirA = g_World.directions.NW
				    dirB = g_World.directions.SW
			    elseif dir == g_World.directions.S then
				    dirA = g_World.directions.SW
				    dirB = g_World.directions.SE
			    end
			    if dirA then
				    if g_World._isPathable(g_World._getAdjacentTile(txCurrent,tyCurrent,dirA)) and 
						    g_World._isPathable(g_World._getAdjacentTile(txCurrent,tyCurrent,dirB)) then
					    self.tCurrentStepData.nNextStep = nextNext
				    end
			    end
		    end
	    end

    local sStepName,tStepData = self:_initWalkStep()
    return sStepName,tStepData
end

function Pathfinder:_complete(sErrorCode)
    self.bComplete = true
    if sErrorCode then
        Print(TT_Error, "PATHFINDER.LUA: ErrorCode - " .. sErrorCode)
    end
        
    self.rChar:playAnim(self.sBreatheOverride or self.rChar:getBreatheAnim())
    return 'complete',sErrorCode
end

function Pathfinder:_testForSegmentIntercept()
    local tNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    local tNextNode = self.tPathNodes[self.tCurrentStepData.nNextStep]
    local destTX,destTY = tNextNode.tx,tNextNode.ty
    local tTaskNode = Airlock.interceptSegment(self.rChar,destTX,destTY,tNode.nDestRoomID,tNextNode.nDestRoomID,tNextNode.bPathToNearest)
    if tTaskNode then
        local nInsertAt = self.tCurrentStepData.nCurrentStep+1
        table.insert(self.tPathNodes, nInsertAt, tTaskNode)

        if tTaskNode.tx ~= tNode.tx or tTaskNode.ty ~= tNode.ty then
            -- New node's start loc is not the current start loc. 
            -- Preserve the current node, with the new dest loc.
            -- Needs a bit of extra info so the current node can path to the newly inserted node.
            if not tTaskNode.sourceRoomDirection then tTaskNode.sourceRoomDirection = tNextNode.sourceRoomDirection end
            if not tTaskNode.nDestRoomID then tTaskNode.nDestRoomID = tNextNode.nDestRoomID end
            if not tTaskNode.nSrcRoomID then tTaskNode.nSrcRoomID = tNextNode.nSrcRoomID end
            return false
        else
            return true
        end
    end
end


function Pathfinder:increment()
    if self.rChar:isElevated() then
        if self.rChar:canDeElevate() then
            return 'deelevate', self.tCurrentStepData
        end
        -- MTF TODO: should verify that the next step is a spacewalk; otherwise there's going to be trouble.
    end

    local tLastStepData = self.tCurrentStepData or {}
    local sLastNodeType = '(none)'
    if tLastStepData.nCurrentStep and self.tPathNodes[tLastStepData.nCurrentStep] then
        sLastNodeType = self.tPathNodes[tLastStepData.nCurrentStep].sNodeType 
    end
    self.tCurrentStepData = {}
    self.tCurrentStepData.nCurrentStep = tLastStepData.nNextStep or 1
    self.tCurrentStepData.nNextStep = self.tCurrentStepData.nCurrentStep + 1
    if self.tCurrentStepData.nCurrentStep >= #self.tPathNodes then
        return self:_complete()
    end

    local sNodeType = self.tPathNodes[self.tCurrentStepData.nCurrentStep].sNodeType 

    if sNodeType == 'subpathfind' or sNodeType == 'spacewalk' then
        if self:_testForSegmentIntercept() then
            local sStepName,tStepData = self:increment()
            return sStepName,tStepData
        end
    end

    if sNodeType == 'subpathfind' then
        if self.rChar:isElevated() then
            return self:_complete("Abnormal path termination: attempting to walk while elevated.")
        end
    
        local bSuccess, tx0,ty0,tx1,ty1,nDestRoomID,sFailureReason = self:_expandSubpathNode()
        if bSuccess then
            -- re-increments, because the subpathfind node just turns into a series of tilesteps, which
            -- we can begin immediately.
            local sStepName,tStepData = self:increment()
            return sStepName,tStepData
        else
            local rFailureRoom = Room.tRooms[nDestRoomID]
            if rFailureRoom then
                print('PATHFINDER.LUA: caching failure in room ',nDestRoomID,'from',tx0,ty0,'to',tx1,ty1)
                rFailureRoom:pathfindFailed(tx0,ty0,tx1,ty1)
            end

            return self:_complete("Abnormal path completion: subpath find failure. Previous node type "..sLastNodeType..". Reason: "..(sFailureReason or 'none'))
        end
    elseif sNodeType == 'tilestep' then
        local sStepName,tStepData = self:_processTilestepNode()
        return sStepName,tStepData
    elseif sNodeType == 'spacewalkLerp' then
        local sStepName,tStepData = self:_processSpacewalkLerp()
        return sStepName,tStepData
    elseif sNodeType == 'spacewalk' then
        local bSuccess,sFailureMessage = self:_expandSpacewalkNode()
        if bSuccess then
            -- re-increments, because the subpathfind node just turns into a series of tilesteps, which
            -- we can begin immediately.
            local sStepName,tStepData = self:increment()
            return sStepName,tStepData
        else
            return self:_complete("Abnormal path completion: unable to begin spacewalk after previous node type "..sLastNodeType..'\n Error: '..(sFailureMessage or 'nil'))
        end
    elseif sNodeType == 'task' then
        self.tCurrentStepData.tSpecialNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
        return self:_initSpecialNode()
    elseif sNodeType == 'special' then
        self:_addSpecialNode()
        self.tCurrentStepData.tSpecialNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep].tSpecialNode
        return self:_initSpecialNode()
    else
        assert(false)
    end
end

-- nStep: if provided, gives data on this step. Otherwise uses current step.
-- return: startRoom, startTX,startTY, endRoom,endTX,endTY
function Pathfinder:getSegmentData(nStep)
    if not self.tPathNodes then
        assertdev(false)
        return nil
    end
    
    nStep = nStep or (self.tCurrentStepData and self.tCurrentStepData.nCurrentStep) or 1
    local tCurNode = self.tPathNodes[nStep]
    local tNextNode = self.tPathNodes[nStep+1]
    
    if not tCurNode then
        assertdev(false)
        return nil
    end
    
    if tCurNode.sNodeType == 'tilestep' and self.nCurrentTilestepSource then
        nStep = self.nCurrentTilestepSource
        tCurNode = self.tPathNodes[nStep]
        tNextNode = self.tPathNodes[self.nFirstPostTilestepNode]
        
        if not tCurNode then
            assertdev(false)
            return nil
        end        
    end
    
    local startRoom,startTX,startTY = tCurNode.nDestRoomID,tCurNode.tx,tCurNode.ty
    local endRoom,endTX,endTY
    if tNextNode then
        endRoom,endTX,endTY = tNextNode.nDestRoomID,tNextNode.tx,tNextNode.ty
    end
    return startRoom,startTX,startTY,endRoom,endTX,endTY
end

function Pathfinder:_initSpecialNode()
    local tTaskSpecArray = {}

    assert(self.tCurrentStepData.tSpecialNode.sTaskName)
    local tTaskSpec = {sName=self.tCurrentStepData.tSpecialNode.sTaskName, tData=self.tCurrentStepData.tSpecialNode.tTaskData  }
    table.insert(tTaskSpecArray, tTaskSpec)
    return 'enqueue', tTaskSpecArray
end

function Pathfinder:_initWalkStep(tx,ty)
    local x, y, z = self.rChar:getLoc()
    if not tx then
        tx,ty = self.tPathNodes[self.tCurrentStepData.nNextStep].tx,self.tPathNodes[self.tCurrentStepData.nNextStep].ty
    end
    local wx,wy = g_World._getWorldFromTile(tx,ty)
	self.tCurrentStepData.nNextX, self.tCurrentStepData.nNextY = wx,wy
	self.tCurrentStepData.nNextTX, self.tCurrentStepData.nNextTY = tx,ty
    local targetZ = g_World.getHackySortingZ(self.tCurrentStepData.nNextX, self.tCurrentStepData.nNextY)
    self.tCurrentStepData.nNextZ = targetZ

	self.tCurrentStepData.nPrevX, self.tCurrentStepData.nPrevY, self.tCurrentStepData.nPrevZ = x,y,z
	self.tCurrentStepData.nPrevTX, self.tCurrentStepData.nPrevTY = g_World._getTileFromWorld(x,y)
    self.tCurrentStepData.nElapsedMoveTime = 0
    
    -- MTF TEMP DEBUGGING: can remove for alpha 6 if it's not getting hit.
    local tCurrentStepNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    if tCurrentStepNode and tCurrentStepNode.tx then
        if self.tCurrentStepData.nPrevTX ~= tCurrentStepNode.tx or self.tCurrentStepData.nPrevTY ~= tCurrentStepNode.ty then
            assertdev(false)
            return self:_complete("Abnormal path termination: previous step failed to get to its target dest.")
        end
    end
    
    if self.tPathNodes[self.tCurrentStepData.nCurrentStep].sNodeType ~= 'spacewalkLerp' and 
            not g_World.isAdjacentToTile(self.tCurrentStepData.nPrevTX, self.tCurrentStepData.nPrevTY, self.tCurrentStepData.nNextTX, self.tCurrentStepData.nNextTY,true,true) then
        assertdev(false)
    end

    self.tCurrentStepData.nDistance = DFMath.distance(self.tCurrentStepData.nPrevX, self.tCurrentStepData.nPrevY,self.tCurrentStepData.nNextX, self.tCurrentStepData.nNextY)
    self.tCurrentStepData.nSegmentMoveTime = self.tCurrentStepData.nDistance / self.rChar:getAdjustedSpeed()
    local vx = self.tCurrentStepData.nNextX-self.tCurrentStepData.nPrevX
    local vy = self.tCurrentStepData.nNextY-self.tCurrentStepData.nPrevY
    local vz = self.tCurrentStepData.nNextZ-self.tCurrentStepData.nPrevZ
    local inv = 1/math.max(.0001,self.tCurrentStepData.nSegmentMoveTime)
    vx = vx*inv
    vy = vy*inv
    vz = vz*inv
    self.tCurrentStepData.tVelocity = {vx,vy,vz}

    return 'nextStep', self.tCurrentStepData
end

function Pathfinder.staticTick(dt)
    if dt > 0 then
        --[[
        print('PATH CLEAR')
        if Pathfinder.tStats.totalNodesEvaluated > 2 then
            local tStats = MOAISim.profileGetDuration("nothing")
            for k,v in pairs(tStats) do
                if string.find(k,"Pathfinder") then
                    print('-- ',k,' = ',v)
                end
            end
            print('---------------------------')
            for k,v in pairs(Pathfinder.tStats) do
                print('* ',k,' = ',v)
            end
        end
        ]]--
        Pathfinder.stPathCache = {}
        Pathfinder.tStats.locNodesPushed = 0
        Pathfinder.tStats.doorsEvaluated = 0
        Pathfinder.tStats.totalNodesPushed = 0
        Pathfinder.tStats.doorNodesPushed = 0
        Pathfinder.tStats.totalNodesEvaluated = 0
    end
end

-- Utility function. Needs to be called by the pathfinding client.
-- Only works for walk operations, not special nodes.
function Pathfinder:tick(dt)
    if dt <= 0.000001 then return end

    self.bMoving = false

    if self.bComplete then
        Print(TT_Warning, 'PATHFINDER.LUA: Ticking a complete path')
        return 'complete','already complete'
    end

    if not self.tCurrentStepData then
        -- first tick.
        local sStepName,tStepData = self:increment()
        return sStepName,tStepData
    end
    if self.tCurrentStepData.tSpecialNode then
        --print('incrementing post-special-node')
        local sStepName,tStepData = self:increment()
        return sStepName,tStepData
    end
    
    local tCurrentNode = self.tPathNodes[self.tCurrentStepData.nCurrentStep]
    assert(tCurrentNode.sNodeType == 'tilestep' or tCurrentNode.sNodeType == 'spacewalkLerp')
    if tCurrentNode.sNodeType == 'spacewalkLerp' and not self.rChar:spacewalking() then
        return self:_complete('Character is in a spacewalking node but is not spacewalking. Interrupting path.'..self.rChar:getUniqueID())
    end

    if not self.tCurrentStepData.bStarted then
        self.tCurrentStepData.bStarted = true
        self.rChar:faceWorld(self.tCurrentStepData.nNextX, self.tCurrentStepData.nNextY)
        self.rChar:playAnim(self.sWalkOverride or self.rChar:getWalkAnim())
        self.tCurrentStepData.nObstructionTime = nil
    end

    local bBlocked = tCurrentNode.sNodeType ~= 'spacewalkLerp' and g_World._isPathBlocked(self.tCurrentStepData.nNextTX, self.tCurrentStepData.nNextTY, self.rChar:spacewalking()) 
                and not g_World._isPathBlocked(self.tCurrentStepData.nPrevTX, self.tCurrentStepData.nPrevTY, self.rChar:spacewalking())

    if bBlocked then
        local sBreathe = self.sBreatheOverride or self.rChar:getBreatheAnim()
        if not self.rChar:isPlayingAnim(sBreathe) then
            self.rChar:playAnim(sBreathe)
        end
        return 'blocked', self.tCurrentStepData
    end

    self.tCurrentStepData.nElapsedMoveTime = self.tCurrentStepData.nElapsedMoveTime + dt

    local moveT = (self.tCurrentStepData.nSegmentMoveTime > 0.0001 and self.tCurrentStepData.nElapsedMoveTime / self.tCurrentStepData.nSegmentMoveTime) or 1
    if moveT >= 1 then
        --local nextTX,nextTY = self.tCurrentStepData.nNextTX,self.tCurrentStepData.nNextTY
        local nextX,nextY,nextZ = self.tCurrentStepData.nNextX,self.tCurrentStepData.nNextY,self.tCurrentStepData.nNextZ
        local bMoved = self.rChar:setLoc(nextX,nextY,nextZ)
        --local curX,curY,curZ = self.rChar:getLoc()
        --local curTX,curTY = self.rChar:getTileLoc()
        if not bMoved then
            self.rChar:playAnim(self.sBreatheOverride or self.rChar:getBreatheAnim())
            return 'blocked', self.tCurrentStepData
        end
        local sStepName,tStepData = self:increment()
        return sStepName,tStepData
    else
        local newX = DFMath.lerp(self.tCurrentStepData.nPrevX, self.tCurrentStepData.nNextX, moveT)
        local newY = DFMath.lerp(self.tCurrentStepData.nPrevY, self.tCurrentStepData.nNextY, moveT)
        local newZ = DFMath.lerp(self.tCurrentStepData.nPrevZ, self.tCurrentStepData.nNextZ, moveT)
        
        if tCurrentNode.sNodeType == 'spacewalkLerp' then
            if not self.rChar:isElevated() and not g_World.isPathable(newX,newY) then
                self.tCurrentStepData.nElapsedMoveTime = self.tCurrentStepData.nElapsedMoveTime - dt
                return 'elevate',self.tCurrentStepData
            end
            if self.rChar:isElevated() then
                if not self.tCurrentStepData.nLastElevatedTime then 
                    self.tCurrentStepData.nLastElevatedTime = self.tCurrentStepData.nElapsedMoveTime 
                elseif self.tCurrentStepData.nElapsedMoveTime - self.tCurrentStepData.nLastElevatedTime > 1 then
                    self.tCurrentStepData.nLastElevatedTime = self.tCurrentStepData.nElapsedMoveTime 
                    if self.rChar:canDeElevate() then
                        self.tCurrentStepData.nElapsedMoveTime = self.tCurrentStepData.nElapsedMoveTime - dt
                        return 'deelevate', self.tCurrentStepData
                    end
                end
            end
        end
        local vx = self.tCurrentStepData.nNextX-self.tCurrentStepData.nPrevX
        local vy = self.tCurrentStepData.nNextY-self.tCurrentStepData.nPrevY
        local vz = self.tCurrentStepData.nNextZ-self.tCurrentStepData.nPrevZ

        self.bMoving = true
        
        self.rChar:setLoc(newX, newY, newZ)
    end
end

function Pathfinder:getVelocity()
    if self.tCurrentStepData and self.tCurrentStepData.tVelocity and self.bMoving then
        return unpack(self.tCurrentStepData.tVelocity)
    end
    return 0,0,0
end

return Pathfinder
