local Class=require('Class')
local DFGraphics = require('DFCommon.Graphics')
local World=require('World')
local Base=require('Base')
local Renderer=require('Renderer')
local Zone= require('Zones.Zone')
local GameRules=require('GameRules')
local ObjectList=require('ObjectList')
local OptionData=require('Utility.OptionData')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local Asteroid = require('Asteroid')
local MiscUtil = require('MiscUtil')
local Malady = nil
local Character = require('CharacterConstants')
local Gui = require('UI.Gui')
local EnvObject=nil
local Lighting=nil
local SoundManager=nil
local CharacterManager=nil
local Cursor=nil
local ActivityOption=nil
local ActivityOptionList=nil
local CommandObject = nil
local Oxygen = nil
local Fire = nil
local Profile = require('Profile')
-- begin changes for mod HoverResearchLabShowsProgress (1/2)
local ResearchData = require('ResearchData')
-- end changes for mod HoverResearchLabShowsProgress (1/2)

local Room
if not g_Room then
    Room = Class.create()
    g_Room = Room
else
    Room = g_Room
    Room.onFileChanged()
end

-- start at 2 to help find array vs. table bugs faster.
Room.nextRoomID = 2

Room.profilerName='Room'

Room.LIGHTING_SCHEME_OFF = 0
Room.LIGHTING_SCHEME_NORMAL = 1
Room.LIGHTING_SCHEME_FIRE = 2
Room.LIGHTING_SCHEME_VACUUM = 3
Room.LIGHTING_SCHEME_DIM = 4
Room.LIGHTING_SCHEME_LOWPOWER = 5

Room.DANGEROUS_DURATION = 120
Room.LOSE_VISIBILITY_TIME = 45
Room.LOSE_REVEALED_TIME = 270
Room.FLOAT_AWAY_TIME = 720

Room.CONTIGUITY_TEST_INTERVAL = 2
Room.POWER_DRAW_PER_TILE = 1

Room.DEBUG_DRAW_NONE = 1
Room.DEBUG_DRAW_OXYGEN = 2
Room.DEBUG_DRAW_BORDERS = 3
Room.DEBUG_DRAW_PROPS = 4
Room.DEBUG_DRAW_MAX = Room.DEBUG_DRAW_PROPS

Room.POWER_DISPLAY_LAYER = 'WorldWall'

function Room.onFileChanged()
    SoundManager = require('SoundManager')
    EnvObject=require('EnvObjects.EnvObject')
    CharacterManager=require('CharacterManager')
    Malady=require('Malady')
    Cursor=require('UI.Cursor')
    ActivityOption=require('Utility.ActivityOption')
    ActivityOptionList=require('Utility.ActivityOptionList')
    CommandObject = require('Utility.CommandObject')
    Oxygen = require('Oxygen')
    Fire = require('Fire')
    Lighting = require('Lighting')
    if g_SpaceRoom then
        Room.rSpaceRoom = g_SpaceRoom
    end
end

function Room.getSpaceRoom()
    return g_SpaceRoom
end

function Room.DBG_verifyPower()
    local tPoweredProps = {}
    for id, rRoom in pairs(Room.tPowerZones) do
            for rProp,_ in pairs(rRoom.zoneObj.tThingsPowered) do
                if rProp.decayPerSecond ~= nil then
                    if tPoweredProps[rProp] then 
                        print('DOUBLE-DRAW PROP: '..rProp:getUniqueName())
                    end
                    if not rProp.rPowerRoom or rProp.rPowerRoom ~= rRoom then
                        print('INCORRECT POWER ROOM ASSIGNMENT')
                    end
                    tPoweredProps[rProp] = rProp
                end
            end
    end
end

function Room.DBG_verifyGrid()
    for x=1,World.width do
        for y=1,World.height do
            local roomTileValue = World.roomGrid:getTileValue(x,y)
            if roomTileValue ~= 0 then
                local rRoom = Room.tRooms[roomTileValue]
                if not rRoom then
                    print('failed to find room at',x,y,roomTileValue)
                else
                    local addr = World.pathGrid:getCellAddr(x,y)
                    if not rRoom.tTiles[addr] then
                        print('failed to find tile in room tile list',x,y)
                    end
                end
            end
        end
    end
    for id,rRoom in pairs(Room.tRooms) do
        for addr,coord in pairs(rRoom.tTiles) do
            if World.roomGrid:getTileValue(coord.x,coord.y) ~= id then
                print('failed to find room tile in world grid',coord.x,coord.y,id)
            end
        end
    end
end

function Room.enablePowerVis()
    Room.sbPowerVisEnabled = true
end

function Room.disablePowerVis()
    Room.sbPowerVisEnabled = false
end

function Room.powerVisEnabled()
    return Room.sbPowerVisEnabled
end

function Room.getPowerDebugText()
    local tProcessedRooms = {}
    local nUniversalDraw = 0
    local nUniversalGen = 0
    local nUniversalMetDraw = 0
    -- Print:
    -- per blob, power draw and power output, including space draw (separate and together)
    for id,rRoom in pairs(Room.tRooms) do
        if not tProcessedRooms[id] then            
            local tBlobInfo = {}
            local nTotalRooms=0
            local nTotalDraw=0
            local nMetDraw=0
            local nTotalOutput=0
            local tContig = rRoom.tContiguousRooms
            for contigID,rContigRoom in pairs(rRoom.tContiguousRooms) do
                tProcessedRooms[contigID] = tBlobInfo
                local nPowerOutput = rContigRoom.zoneObj:getPowerOutput()
                nTotalOutput = nTotalOutput+nPowerOutput
                nTotalDraw = nTotalDraw+rContigRoom.nPowerDraw
                nMetDraw = nMetDraw+rContigRoom.nPowerSupplied
                if rContigRoom.nPowerSupplied ~= rContigRoom.nPowerDraw then
                    local what='what'
                end
                nUniversalDraw = nUniversalDraw + rContigRoom.nPowerDraw
                nUniversalMetDraw = nUniversalMetDraw + rContigRoom.nPowerSupplied
                
                -- MTF TODO
                -- Calc how much of the power draw is met, and track that. e.g. bHasPower in the prop.
                -- also add in local nRoomDraw = self.nTiles * Room.POWER_DRAW_PER_TILE
                
                nUniversalGen = nUniversalGen+nPowerOutput
                nTotalRooms = nTotalRooms+1
            end
            tBlobInfo.nTotalOutput = nTotalOutput
            tBlobInfo.nTotalDraw = nTotalDraw
            tBlobInfo.nTotalRooms = nTotalRooms
            tBlobInfo.nSpaceDraw = 0
            tBlobInfo.nMetDraw = nMetDraw
            
            --tBlobInfo.nSpaceDraw = nSpaceDraw
        end
    end
    local nSpaceDraw = 0
    local nBlobErrors = 0
    local nUnpoweredSpaceProps = 0
    local nMissingSpacePower = 0
    for rProp,_ in pairs(g_SpaceRoom.tProps) do
        local nDraw = rProp:getPowerDraw()
        nSpaceDraw = nSpaceDraw+nDraw
        nUniversalDraw = nUniversalDraw+nDraw
        if rProp:hasPower() then
            nUniversalMetDraw = nUniversalMetDraw+nDraw
        end
        if rProp.rPowerRoom or rProp.rLeechingFromRoom then
            local rPowerRoom = rProp.rPowerRoom or rProp.rLeechingFromRoom
            local tBlob = tProcessedRooms[rPowerRoom.id]
            if tBlob then
                tBlob.nSpaceDraw = tBlob.nSpaceDraw + nDraw
                tBlob.nTotalDraw = tBlob.nTotalDraw + nDraw
                if rProp:hasPower() then
                    tBlob.nMetDraw = tBlob.nMetDraw + nDraw
                end
                tBlob.nTotalOutput = tBlob.nTotalOutput + rProp:getPowerOutput()
            else
                nBlobErrors = nBlobErrors+1
            end
        elseif nDraw > 0 then
            nUnpoweredSpaceProps = nUnpoweredSpaceProps+1
            nMissingSpacePower = nMissingSpacePower + nDraw
        end
    end
    local s = 'POWER DRAW\n'
    s = s.. ' Total Draw: '..nUniversalDraw..'\n'
    s = s.. ' Met Draw: '..nUniversalMetDraw..'\n'
    s = s.. ' Total Gen: '..nUniversalGen..'\n'
    s = s.. ' Space Draw: '..nSpaceDraw..'( '..nUnpoweredSpaceProps..' unpowered props for '..nMissingSpacePower..' PUs)\n'
    for id,tBlob in pairs(tProcessedRooms) do
        if not tBlob.bProcessed then
            tBlob.bProcessed = true
            s = s.. ' - Blob '..id..': '..tBlob.nMetDraw..' / '..tBlob.nTotalDraw..' / '..tBlob.nTotalOutput..' (Met/Desired/Power), # Rooms '..tBlob.nTotalRooms..', Space draw '..tBlob.nSpaceDraw..'\n'
        end
    end
    if nBlobErrors > 0 then
        s = s..'BLOB ERRORS GO GET MATT: '..nBlobErrors..'\n'
    end
    return s
end

function Room.cycleDebugDraw()
    if Room.debugDrawMode == Room.DEBUG_DRAW_PROPS then
        World.setPathGridVisualize(false)
    end

    Room.debugDrawMode = Room.debugDrawMode+1
    if Room.debugDrawMode > Room.DEBUG_DRAW_MAX then
        Room.debugDrawMode = Room.DEBUG_DRAW_NONE
    end

    if Room.debugDrawMode == Room.DEBUG_DRAW_PROPS then
        World.setPathGridVisualize(true)
    end
end

function Room.getNumOwnedTiles()
    return Room.nNumOwnedTiles
end

-- Common enough that I cache it here. {rRoom=1, ...}
function Room.getPlayerOwnedFunctionalAirlocks()
    return Room.tFunctionalPlayerAirlocks
end


function Room.getSafeRoomsOfTeam(nTeam, bOriginalTeam, sZoneName)
	-- same as below, but only returns non-dangerous rooms
	local tRooms, nNumRooms, nOtherTeamRooms = Room.getRoomsOfTeam(nTeam, bOriginalTeam, sZoneName)
	local tSafeRooms = {}
	for room,i in pairs(tRooms) do
		if room:isDangerous() then
			nNumRooms = nNumRooms - 1
		else
			-- same table format as getRoomsOfTeam
			tSafeRooms[room] = i
		end
	end
	return tSafeRooms, nNumRooms, nOtherTeamRooms
end

-- bArray: if true, tRooms is an array rather than the table described below.
-- return: tRooms { rRoom=id, ... }, nNumRooms, nNumRoomsOfDifferentTeam
function Room.getRoomsOfTeam(nTeam, bOriginalTeam, sZoneName, bArray)
    local tRooms = {}
    local nNumRooms = 0
    local nOtherTeamRooms = 0
    assert(nTeam)
    for id,rRoom in pairs(Room.tRooms) do
		if (bOriginalTeam and rRoom.nOriginalTeam == nTeam) or (not bOriginalTeam and rRoom.nTeam == nTeam) then
            if not sZoneName or ( sZoneName and sZoneName == rRoom:getZoneName() ) then
                if bArray then
                    table.insert(tRooms,rRoom)
                else
                    tRooms[rRoom] = id
                end
                nNumRooms = nNumRooms + 1
            end
		else
			nOtherTeamRooms = nOtherTeamRooms+1
        end
    end
    return tRooms, nNumRooms, nOtherTeamRooms
end

function Room.DBG_globalSetTeam(nTeam)
    for id,rRoom in pairs(Room.tRooms) do
        rRoom:_setTeam(nTeam)
    end
    --World.fixupVisuals()
end

function Room.needsCallback()
    return Room.debugDrawMode ~= Room.DEBUG_DRAW_NONE
end

function Room.debugDrawRooms()
    for idx,room in pairs(Room.tRooms) do
        room:debugDraw()
    end
end

function Room.visibilityBlip(tx,ty,nLevel,bFloorOnly)
    local rRoom = Room.getRoomAtTile(tx,ty,nLevel)
    if rRoom then
        rRoom.nLastSeen = GameRules.elapsedTime
    end
    --[[
    local rRoom = Room.getRoomAtTile(tx,ty,nLevel)
    if rRoom and rRoom.nTeam ~= Character.TEAM_ID_PLAYER then
        if rRoom:_setTeam(Character.TEAM_ID_PLAYER) then
            World.fixupVisuals()
        end
    elseif not bFloorOnly then
        if g_World.countsAsWall(tx,ty) then
            for i=2,9 do
                local atx,aty = World._getAdjacentTile(tx,ty,i)
                Room.visibilityBlip(atx,aty,nLevel,true)
            end
        end
    end
    ]]--
end

function Room.getVisibilityAtTile(tx,ty,tw)
    local r = Room.getRoomAtTile(tx,ty,tw,true)
    if not r then return World.VISIBILITY_FULL end
    return r:getVisibility()
end

function Room.getTeamAtTile(tx,ty,nLevel,defaultTeam)
    local rRoom = Room.getRoomAtTile(tx,ty,nLevel)
    if rRoom then return rRoom.nTeam end

    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tWall = Room.tWallsByAddr[addr]
    if tWall then
        for i=2,9 do
            local id = tWall.tDirs[i]
            if id then
                if not Room.tRooms[id] then
                    print('Wall had a nonexistent room id.',id)
                    assert(false)
                end
                if Room.tRooms[id].nTeam ~= Character.TEAM_ID_PLAYER then
                    return Room.tRooms[id].nTeam
                end
            end
        end
    end

    return defaultTeam or Character.TEAM_ID_PLAYER
end

function Room.getSpriteAtTile(tx,ty,tw,nLogicalValue)
    local rRoom = Room.getRoomAtTile(tx,ty,tw)
    if rRoom then
        return Room._getBaseFloorTile(tx,ty,nLogicalValue)
    end
end

-- Moved from World. May eventually be replaced by more intelligent
-- floor tile layout algorithms.
function Room._getBaseFloorTile(tileX, tileY,nLogicalValue)
    nLogicalValue = nLogicalValue or World._getTileValue(tileX, tileY)
    local zone = Zone.getZoneDataForIdx(nLogicalValue - World.logicalTiles.ZONE_LIST_START + 1)
    assert(zone)
    --[[
    if not zone then
        zone = Zone.PLAIN
    end
    ]]--
    -- floor tiles near walls use different art
    local floorName = nil
    if World.isAdjacentToWall(tileX, tileY, false) then
        floorName = zone.floorNames[1]
    else
        floorName = zone.floorNames[ math.random(math.min(2, #zone.floorNames), #zone.floorNames ) ]
    end
    return floorName
    --[[
    local idx = World.layers.worldFloor.spriteSheet.names[floorName]
    assert(idx and idx > 0)
    return idx
    ]]--
end

function Room.getRoomAt(wx,wy,wz,nLevel,bWallsDoorsAlso)
    if nLevel ~= 1 then
        return nil
    end
    assert(wx and wy)
    local tx, ty = World._getTileFromWorld(wx,wy,nLevel)
    local r,t = Room.getRoomAtTile(tx,ty,nLevel,bWallsDoorsAlso)
    return r,t
end

function Room.getRoomFromWall(wx, wy, wz, nLevel)
    local tx, ty = World._getTileFromWorld(wx,wy,nLevel)
	-- check south of wall, then north, then E/W
	local tDirectionOrder = { World.directions.S, World.directions.N, World.directions.E, World.directions.W }
	for _,dir in pairs(tDirectionOrder) do
		local otx, oty = World._getAdjacentTile(tx, ty, dir)
		local roomTileValue = World.roomGrid:getTileValue(otx, oty)
		local rRoom = Room.tRooms[roomTileValue]
		if rRoom then
			return rRoom
		end
	end
end

function Room.getRoomAtTile(tx,ty,tw,bWallsDoorsAlso)
    assert(tw)

    if tw ~= 1 then return nil end

    local roomTileValue = World.roomGrid:getTileValue(tx,ty)
    local rRoom = Room.tRooms[roomTileValue]
    if bWallsDoorsAlso then
        local bWall = false
        if not rRoom then
            local tWall = Room.getWallAtTile(tx,ty,tw)
            local tFound = {}
            local rFound = nil
            if tWall then
                for i=2,9 do
                    local id = tWall.tDirs[i]
                    if id then
                        rFound = Room.tRooms[id]
                        tFound[id] = rFound
                        bWall = true
                    end
                end
            end
            return rFound, tFound, bWall
        else
            return rRoom, {[rRoom.id]=rRoom}, false
        end
    end
    return rRoom
end

-- NOTE: only gets intact walls, not destroyed walls.
function Room.getWallAtTile(tx,ty,nLevel)
    if nLevel ~= 1 then return nil end
    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tWall = Room.tWallsByAddr[addr]
    return tWall
end

function Room.beginLoad(tSaveData,bModule)
    if bModule then return end
    if g_SpaceRoom then g_SpaceRoom:_destroy() end
end

function Room.hackLoadSpaceRoom(tSaveData)
    if g_SpaceRoom then g_SpaceRoom:_destroy() end
    -- MTF HACK: we load a space room in savegames that have them, but otherwise
    -- we need to create a default space room.
    if tSaveData.tWorldSaveData[ObjectList.ROOM] then
        for k,t in ipairs(tSaveData.tWorldSaveData[ObjectList.ROOM]) do
            if t.bSpaceRoom then
                Room.fromSaveTable(t, nil, nil, Character.TEAM_ID_PLAYER)
                --require('SpaceRoom').new(t)
                if g_SpaceRoom then
                    table.remove(tSaveData.tWorldSaveData[ObjectList.ROOM], k)
                end
            end
        end
    end
    if not g_SpaceRoom then
        require('SpaceRoom').new()
    end
    assertdev(g_SpaceRoom)
end

function Room.endLoad()
    if not g_SpaceRoom then
        require('SpaceRoom').new()
    end
end

function Room.reset()
    require('DFMoai.Debugger').dFileChanged:register(Room.onFileChanged,nil)
    --if Room.tRooms and Room.tRooms
    Room.tRooms = {}
    Room.tDirtyTiles = {}
    Room.tWallsByAddr= {}
    Room.tPowerZones = {}
    Room.tPendingObjectBuilds = {}
    Room.tPendingObjectCancels = {}
    Room.debugDrawMode = Room.DEBUG_DRAW_NONE

    Room.tFunctionalPlayerAirlocks = {}
    Room.tPendingObjectBuilds = {}
    Room.onFileChanged()
	-- "space room": not a real room, stores objects out in space
	require('SpaceRoom').new()

    for id,rRoom in pairs(Room.tRooms) do
        for addr,tData in pairs(rRoom.tPropPlacements) do
            EnvObject.destroyBuildGhost(tData.buildGhost)
        end
--        rRoom:_clearOldGhosts()
        --rRoom:_destroy()
    end
	for addr,tData in pairs(g_SpaceRoom.tPropPlacements) do
		EnvObject.destroyBuildGhost(tData.buildGhost)
	end

    Room.tDirtyTiles = {}
    Room.tWallsByAddr = {}
    Room.nextRoomID = 2
    World.dTileChanged:register(Room.dirtyTile)
    ObjectList.dTileContentsChanged:register(function(tx,ty,sourceTag,bSet)
        if sourceTag.objType == ObjectList.ENVOBJECT then
            Room.tileContentsChanged(tx,ty,sourceTag.addr)
        end
    end)
end

function Room.tileContentsChanged(tx,ty,addr)
    local found,tRooms = Room.getRoomAtTile(tx,ty,1,true)
    if found then
        if tRooms then
            for id,rRoom in pairs(tRooms) do
                rRoom:_retestPropPlacements()
            end
        else
            found:_retestPropPlacements()
        end
    else
		g_SpaceRoom:_retestPropPlacements()
	end
end

function Room.onTick( dt )
    -- update number of owned tiles.
    Room.nNumOwnedTiles = 0
    local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER)
    for rRoom,_ in pairs(tRooms) do
        Room.nNumOwnedTiles = Room.nNumOwnedTiles + rRoom.nTiles
    end

    local bUpdate = false

    local function shouldTickRoom(room)
        if room == g_SpaceRoom then
            return (not room.nLastUpdateTime or room.nLastUpdateTime + 1 < GameRules.elapsedTime)
        end
        -- zoneObj.bForceSim hack: airlocks need to know they're functional, in order for ERs to use them to invade ships.
        return room.nTeam == Character.TEAM_ID_PLAYER or room.nLastVisibility == World.VISIBILITY_FULL or room.bForceSim or (room.zoneObj and room.zoneObj.bForceSim)
    end

    Room.tFunctionalPlayerAirlocks = {}
    for idx,room in pairs(Room.tRooms) do
        if room.nTeam == Character.TEAM_ID_PLAYER and room.zoneObj:isFunctionalAirlock() then
            Room.tFunctionalPlayerAirlocks[room] = 1
        end
    end

    g_SpaceRoom:tickRoomFast()
    if shouldTickRoom(g_SpaceRoom) then
        g_SpaceRoom:tickRoomSlow()
        g_SpaceRoom.nLastUpdateTime = GameRules.elapsedTime
    end

    for idx,room in pairs(Room.tRooms) do
        room:tickVisibility()
        room:tickLighting()
        room:tickRoomFast()
        if not room.bHasUpdated and shouldTickRoom(room) then
            room:tickRoomSlow()
            room.bHasUpdated = true
            Room.lastUpdated = idx
        end
    end

    local bUpdatedARoom = false
    for idx,room in pairs(Room.tRooms) do
        if bUpdate then
            if shouldTickRoom(room) then
                room:tickRoomSlow()
                bUpdatedARoom = true
                Room.lastUpdated = idx
                break
            end
            Room.lastUpdated = idx
        end
        if idx == Room.lastUpdated then
            bUpdate = true
        end
    end

    if not bUpdatedARoom then
        local nextIdx = next(Room.tRooms)
        if nextIdx then
            local rRoom = Room.tRooms[nextIdx]
            if shouldTickRoom(rRoom) then
                rRoom:tickRoomSlow()
            end
            Room.lastUpdated = nextIdx
        end
    end
end

function Room.dirtyTile(tileX,tileY,addr,value,prevValue)
    if prevValue == value then return end
    Room.tDirtyTiles[addr] = true

    if g_World.countsAsWall(value) or
            Asteroid.isAsteroid(value) or
            value == World.logicalTiles.DOOR or
            g_World.countsAsWall(prevValue) or
            Asteroid.isAsteroid(prevValue) or
            prevValue == World.logicalTiles.DOOR
            then
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.NW)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.NE)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.SW)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.SE)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.N)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.E)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.S)) ] = true
        Room.tDirtyTiles[ World.pathGrid:getCellAddr(World._getAdjacentTile(tileX,tileY,World.directions.W)) ] = true
    end
end

function Room.getRoomJobs(rChar)
    local tObjects = {}
    for idx,room in pairs(Room.tRooms) do
        room:getJobs(rChar, tObjects)
    end
	g_SpaceRoom:getJobs(rChar, tObjects)
    return tObjects
end

-- Implementation:
-- Go through all dirty tiles. Add the tile to a dirty list.
-- If that tile was part of a room, add all of that room's tiles to the dirty list.
-- Clear the room value of all dirty tiles.
-- Ask rooms to reconstruct themselves, starting from an old tile member and using it to flood.
-- Any tiles that are still dirty get a new room or rooms.
function Room.updateDirty()
    --Profile.enterScope("Room.updateDirty")

    -- TODO: update rooms to preserve the largest room first, and recreate it using
    -- best match with its previous layout.
    local tDirtyRooms = {}
    local tTempDirtyTiles = {}

    for addr,_ in pairs(Room.tDirtyTiles) do
        local x, y = World.roomGrid:cellAddrToCoord(addr)
        local val = World.roomGrid:getTileValue(x,y)
        tDirtyRooms[val] = true
        tTempDirtyTiles[addr] = true
    end
    tDirtyRooms[0] = nil
    --Profile.enterScope("Room.updateDirtyA")

    -- tOldTiles hack: Below I clear out all the old room values from the roomgrid. But I actually need those values during flood
    -- to figure out the best zone for newly merged rooms. So I temp store them in this table.
    local tOldTiles = {}
    for roomIdx,_ in pairs(tDirtyRooms) do
        for addr,coord in pairs(Room.tRooms[roomIdx].tTiles) do
            tOldTiles[addr] = World.roomGrid:getTileValue(coord.x,coord.y)
            World.roomGrid:setTileValue(coord.x,coord.y, 0)
            tTempDirtyTiles[addr] = true
        end
    end
    --Profile.leaveScope("Room.updateDirtyA")
    --Profile.enterScope("Room.updateDirtyB")

    for roomIdx,_ in pairs(tDirtyRooms) do
        Room.tRooms[roomIdx]:_regenTiles(tOldTiles)
    end
    for roomIdx,_ in pairs(tDirtyRooms) do
        for addr,_ in pairs(Room.tRooms[roomIdx].tTiles) do
            tTempDirtyTiles[addr] = nil
        end
    end

    --Profile.leaveScope("Room.updateDirtyB")
    --Profile.enterScope("Room.updateDirtyC")
    local nextDirty = next(tTempDirtyTiles)
    while nextDirty do
        tTempDirtyTiles[nextDirty] = nil
        local tileX, tileY = World.roomGrid:cellAddrToCoord(nextDirty)
        -- attachedRoom can be a new room, an old room connected to the test tile,
        -- or nil if the test tile turned out to be wall/space/etc.
        -- Don't pass in old tiles here. All existing rooms got regenned above. 
        local attachedRoom = Room._updateFrom(tileX,tileY,nil, {}) --tOldTiles)
        if attachedRoom then
            for addr,_ in pairs(attachedRoom.tTiles) do
                tTempDirtyTiles[addr] = nil
            end
            --tDirtyRooms[attachedRoom.id] = true
        end
        nextDirty = next(tTempDirtyTiles)
    end
    --Profile.leaveScope("Room.updateDirtyC")

    for id,rRoom in pairs(Room.tRooms) do
        if not next(rRoom.tTiles) then
            rRoom:_destroy()
        end
    end

    Room.tDirtyTiles = {}
    --Profile.leaveScope("Room.updateDirty")

--    Room._updatePropAssignment()
end

        --[[
function Room._updatePropAssignment()
    for id,rRoom in pairs(Room.tRooms) do
        if rRoom.bPropsDirty then
            rRoom:_clearOldReservations()
            rRoom.tProps = {}
            rRoom.nProps = 0
            for addr,coord in pairs(rRoom.tTiles) do
                local o = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
                if o then
                    rRoom:addProp(o)
                end
            end
            rRoom.bPropsDirty = false
        end
    end
end
        ]]--

-- Tests dirty tiles to see if they can be part of an existing room, or
-- if a new room needs to be created. Then either assigns the tiles to
-- an existing room, or creates a new one, as appropriate.
function Room._updateFrom(tileX,tileY,nDefaultID,tOldTiles) --,tTempDirtyProps)
    local floodData = { id = Room.nextRoomID, tiles = {}, skipTiles={}, rooms={}, defaultID=nDefaultID }
    --Profile.enterScope("Room.floodRoom")
    Room._floodRoom( World.pathGrid:getCellAddr(tileX, tileY), floodData, tOldTiles )
    local nRoomID = Room._selectBestRoomFromFloodData(floodData)
    --Profile.leaveScope("Room.floodRoom")
    if not next(floodData.tiles) then return end

    if nRoomID and Room.tRooms[nRoomID] then
        Room.tRooms[nRoomID]:setTiles(floodData.tiles) --,tTempDirtyProps)
    else
        Room.tRooms[Room.nextRoomID] = Room.new(Room.nextRoomID, floodData.tiles) --, tTempDirtyProps )
        nRoomID = Room.nextRoomID
        while Room.tRooms[Room.nextRoomID] do
            Room.nextRoomID = Room.nextRoomID + 1
        end
    end

    Room.tRooms[nRoomID].nLastSeen = floodData.nLastSeen

    return Room.tRooms[nRoomID]
end

-- Attempts to regenerate an existing room.
-- Can orphan props.
function Room:_regenTiles(tOldTiles) --tTempDirtyProps)
    for addr,coord in pairs(self.tTiles) do
        if World.countsAsFloor(World.pathGrid:getTileValue(coord.x,coord.y)) then
            local nStoredRoomID = World.roomGrid:getTileValue(coord.x,coord.y)
            if nStoredRoomID == 0 or nStoredRoomID == self.id then
                if Room._updateFrom(coord.x,coord.y,self.id,tOldTiles) == self then
                    return true
                end
            end
        end
    end
    
    self:setTiles({})

    return false
end

function Room:getVisibility()
    return self.nLastVisibility
end

function Room:isTileInRoom(tx,ty,tw)
    return (self == Room.getRoomAtTile(tx,ty,tw,true))
end

function Room._floodRoom( thisTile, floodData, tOldTiles )
    if floodData.tiles[thisTile] or floodData.skipTiles[thisTile] then
        return
    end

    local tileX, tileY = World.pathGrid:cellAddrToCoord(thisTile)
    local xLeft = ((tileY % 2 == 1) and tileX-1) or tileX
    local tileValue = World.pathGrid:getTileValue(tileX, tileY)

    if not World.countsAsFloor(tileValue) then
        floodData.skipTiles[thisTile] = 1
        return
    end

    floodData.tiles[thisTile] = {x=tileX,y=tileY}
    local roomValue = tOldTiles[thisTile] or World.roomGrid:getTileValue(tileX, tileY)
    if roomValue == 0 then roomValue = floodData.defaultID or 0 end
    if roomValue > 0 then
        if not floodData.rooms[roomValue] then floodData.rooms[roomValue] = 0 end
        floodData.rooms[roomValue] = floodData.rooms[roomValue] + 1
        if Room.tRooms[roomValue] and Room.tRooms[roomValue].nLastSeen and (not floodData.nLastSeen or (Room.tRooms[roomValue].nLastSeen > floodData.nLastSeen)) then
            floodData.nLastSeen = Room.tRooms[roomValue].nLastSeen
        end
    end

    Room._floodRoom( World.pathGrid:getCellAddr(xLeft, tileY+1), floodData, tOldTiles )
    Room._floodRoom( World.pathGrid:getCellAddr(xLeft+1, tileY+1), floodData, tOldTiles )
    Room._floodRoom( World.pathGrid:getCellAddr(xLeft, tileY - 1), floodData, tOldTiles )
    Room._floodRoom( World.pathGrid:getCellAddr(xLeft+1, tileY - 1), floodData, tOldTiles )
end

-- to be used after _floodRoom to pick the best room for ownership
function Room._selectBestRoomFromFloodData(floodData)
    local nBestID
    local nBestCount = 0
    for id,count in pairs(floodData.rooms) do
        if not nBestID then
            nBestID = id
            nBestCount = count
        elseif Room.tRooms[id] and not Room.tRooms[nBestID] then
            nBestID = id
            nBestCount = count
        else
            local rBestRoom = Room.tRooms[nBestID]
            local rCurrentRoom = Room.tRooms[id]
            local bCurrentZonePlain = rCurrentRoom and rCurrentRoom:getZoneName() == 'PLAIN'
            local bBestZonePlain = rBestRoom:getZoneName() == 'PLAIN'
            if rCurrentRoom and rCurrentRoom.nTeam == Character.TEAM_ID_PLAYER and rBestRoom.nTeam ~= Character.TEAM_ID_PLAYER then
                nBestID = id
                nBestCount = count
            elseif rBestRoom.nTeam == Character.TEAM_ID_PLAYER and (not rCurrentRoom or rCurrentRoom.nTeam ~= Character.TEAM_ID_PLAYER) then
                -- do nothing; current best is a player-owned room and the test room isn't.
            elseif rCurrentRoom and (bBestZonePlain and not bCurrentZonePlain) then
                nBestID = id
                nBestCount = count
            elseif rCurrentRoom and (not bBestZonePlain and bCurrentZonePlain) then
                -- do nothing; current best is zoned and test room isn't.
            elseif count > nBestCount then
                nBestID = id
                nBestCount = count
            end
        end
    end
    return nBestID
end

function Room:init(id, tTiles, tSaveData)
    self.tCharacters = {}
    self.nLastCombatAlert = (tSaveData and tSaveData.nLastCombatAlert) or -9999
    self.nFireTiles=0
    self.nLevel=1
    self.nCharacters=0
    self.id = id
    self.tag = ObjectList.addObject(ObjectList.ROOM, nil, self, tSaveData, false,false, nil, nil, false)
    self.tProps = {}
    self.tPowerLeeches = {}
    self.tPropsByFunctionality = {}
    self.nPropsByFunctionality = {}
    self.tAdjoining = {}
    self.tWallBlobs = {}
    self.tAccessibleByDoor = {}
    self.tPropPlacements={}
    self.nProps = 0
	self.nPowerSupplied, self.nPowerDraw = 0,0
    self.nTeam = Character.TEAM_ID_PLAYER
	self.nLastFamiliarityTick = 0
	self.type = 'Room'
    self.activityOptionList = ActivityOptionList.new(self)
    self.fireActivityOptionList = ActivityOptionList.new(self)
    self:_addPersistentActivityOptions()
    self.bOxygenScoreOutOfDate = true
    self.bEmergencyAlarmEnabled = false
    if tSaveData and tSaveData.bEmergencyAlarmEnabled then
        self.bEmergencyAlarmEnabled = true
    end
    --self:setLightingScheme(Room.LIGHTING_SCHEME_NORMAL)
    self:setTiles(tTiles)
    -- unique zone name displayed to player
	if not self.uniqueZoneName then
		self.uniqueZoneName = Zone.getUniqueZoneName(self.zoneName)
		-- JPL TODO: generate a new name if this one isn't truly unique
	end
    self:tickVisibility()
end

function Room:getUniqueName()
    return self.uniqueZoneName
end

function Room:randomLeashedTileInRoom(tx,ty,tw,nLeash,bUnreservedOnly)
    nLeash = nLeash or 5
    local nAttempts = 0
    while nAttempts < 10 do
        local ltx,lty = tx+math.random(-nLeash,nLeash),ty+math.random(-nLeash,nLeash)
        if Room.getRoomAtTile(ltx,lty,tw) == self then
            ltx,lty = self:_getPathableNeighbor(ltx,lty,bUnreservedOnly)
            if ltx then
                return ltx,lty,tw
            end
        end
        nAttempts = nAttempts+1
    end
    return self:randomLocInRoom(true,true,bUnreservedOnly)
end

function Room:randomLocInRoom(bTileCoord,bPathableOnly,bUnreservedOnly)
    local pick = math.random(1,self.nTiles)
    local n = 1
    for addr,coord in pairs(self.tTiles) do
        if n == pick then
            local tx,ty = coord.x,coord.y
            if bPathableOnly then
                tx,ty = self:_getPathableNeighbor(coord.x,coord.y,bUnreservedOnly)
            end
            if tx then
                if bTileCoord then
                    return tx,ty,self.nLevel
                else
                    return World._getWorldFromTile(tx,ty,self.nLevel)
                end
            end
        end
        n = n+1
    end
end

function Room:getPathableTilePairs()
    local tries = 0
    while tries < 10 do
        local tx,ty = self:randomLocInRoom(true,true,true)
        if tx then
            local atx,aty = self:_getPathableNeighbor(tx,ty,true)
            if atx then
                return tx,ty,atx,aty
            end
        end
        tries = tries+1
    end
end

-- {  rAdjoiningRoom={id=id, nCount=n, tDoorCoords={coord1,coord2,...}}, ... }
function Room:getAdjoiningRooms()
    return self.tAdjoining
end

function Room:pathfindFailed(tx0,ty0,tx1,ty1)
    if not self.tFailedPathfinds then self.tFailedPathfinds = {} end
    local addr = World.pathGrid:getCellAddr(tx0,ty0)
    if not self.tFailedPathfinds[addr] then self.tFailedPathfinds[addr] = {} end
    local destAddr = World.pathGrid:getCellAddr(tx1,ty1)
    if not self.tFailedPathfinds[destAddr] then self.tFailedPathfinds[destAddr] = {} end
    self.tFailedPathfinds[addr][destAddr] = GameRules.elapsedTime
    self.tFailedPathfinds[destAddr][addr] = GameRules.elapsedTime
end

function Room:isReachable(txSource,tySource,txDest,tyDest)
    local srcAddr = World.pathGrid:getCellAddr(txSource,tySource)
    if self.tFailedPathfinds and self.tFailedPathfinds[srcAddr] then
        local destAddr = World.pathGrid:getCellAddr(txDest,tyDest)
        if self.tFailedPathfinds[srcAddr][destAddr] then
            return false
        end
    end
    return true
end

function Room:getReachableDoors(tx,ty,bSuited)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tBlocked
    if not bSuited then
        if self.tFailedPathfinds and self.tFailedPathfinds[addr] then
            tBlocked = self.tFailedPathfinds[addr]
        end
    end

    local tDoors = {}
    local tInvalidDoors = {}
    for addr,coord in pairs(self.tDoors) do
        local rDoor = ObjectList.getDoorAtTile(coord.x,coord.y)
        if rDoor then
            local destAddr = World.pathGrid:getCellAddr(coord.x,coord.y)
            -- the extra "tInvalidDoors" table is because some doors have a > 1 tile footprint,
            -- and only one of the tiles may be recorded as blocked, but the entire door should
            -- be regarded as invalid.
            if tBlocked and tBlocked[destAddr] then
                tInvalidDoors[rDoor] = 1
                tDoors[rDoor] = nil
            end
            if not tInvalidDoors[rDoor] then
                tDoors[rDoor] = 1
            end
        end
    end
    return tDoors
--    return self.tDoors
end

-- {  rAdjoiningRoom={id=id, nCount=n, tDoorCoords={coord1,coord2,...}}, ... }
function Room:getAccessibleByDoor()
    return self.tAccessibleByDoor
end

function Room:getRoomScore(rChar)
    local score = 0

	if self.nFireTiles > 0 then
		score = score-1
        if self.nFireTiles > self.nTiles*.5 then
            score=score-1
        end
	end

    if self:getOxygenScore() < Character.OXYGEN_SUFFOCATING then
        score = score-2
    elseif self:getOxygenScore() < Character.OXYGEN_LOW then
        score=score-1
    end

    if self.bBreach then
        score=score-2
    end

    if self:isDangerous(rChar) then
        score=score-1
    end

    local bCombat,nThreat = rChar:hasCombatAwarenessIn(self) 
    if rChar and bCombat and nThreat > Character.THREAT_LEVEL.NormalCitizen then
        score=score-1
    end

    return score
end

function Room:getOxygenScore()
    if self.bOxygenScoreOutOfDate then
        self.bOxygenScoreOutOfDate = false
        self.nOxygenScore,self.nTotalOxygen,self.nAverageOxygen = Oxygen.getOxygenScore(self.tTiles,self.nTiles)
        --[[
        -- just some debug code for debugging room oxygen propagation.
        self.nDBGTotalOxygen,self.nDBGOxygenAvg = 0,0
        for addr,coord in pairs(self.tTiles) do
            local o2 = g_World.oxygenGrid:getOxygen(coord.x,coord.y)
            self.nDBGTotalOxygen = self.nDBGTotalOxygen + o2
        end
        self.nDBGOxygenAvg = self.nDBGTotalOxygen / self.nTiles
        ]]--
    end
    return self.nOxygenScore,self.nTotalOxygen,self.nAverageOxygen
end

function Room:setPendingBreach(tx,ty,bBreach)
    if bBreach then
        if not self.tPendingBreaches then self.tPendingBreaches = {} end
        local addr = World.pathGrid:getCellAddr(tx,ty)
        self.tPendingBreaches[addr] = GameRules.elapsedTime
    else
        if self.tPendingBreaches then
            local addr = World.pathGrid:getCellAddr(tx,ty)
            self.tPendingBreaches[addr] = nil
        end
    end
    if not self.bPendingBreach and next(self.tPendingBreaches) then
        self.bPendingBreach = true
        --if not self.bForceSim then
            --self.bForceSim = true
        --end

        local nTeam = self:getTeam()

        local tRooms = Room.getRoomsOfTeam(nTeam)
        for rRoom, id in pairs(tRooms) do
            rRoom.bForceSim = true
        end
        if Base.getTeamFactionBehavior(nTeam) == Character.FACTION_BEHAVIOR.Friendly then
            -- Friendly people don't like it when you try to suffocate them.
            Base.setTeamFactionBehavior(nTeam,Character.FACTION_BEHAVIOR.Friendly)
        end
    else
        self.bPendingBreach = false
    end
end

function Room:_updateSound(bShuttingDown)
    local sCue = nil
    if bShuttingDown then
    elseif self.bEmergencyAlarmEnabled then sCue = 'room_alert'
    elseif self.nFireTiles > 0 then sCue = 'room_fire'
    elseif self.bBreach then sCue = 'room_breach'
    elseif self:getOxygenScore() < Character.OXYGEN_LOW then sCue = 'room_oxygen'
    end

    local nCurrentWalla = nil
    local sCurrentWalla = nil
    local sWallaParam = nil
    if self.nCharacters > 4 and not bShuttingDown then
        if GameRules.elapsedTime-self.nLastCombatAlert < 10 then
            sCurrentWalla = 'room_walla_bad'
            sWallaParam = 'wallanegative'
        else
            sCurrentWalla = 'room_walla_good'
            sWallaParam = 'wallapositive'
        end
        if self.nCharacters > 14 then nCurrentWalla = .8
        elseif self.nCharacters > 8 then nCurrentWalla = .5
        else nCurrentWalla = .2 end
    end

    local tx,ty = self:getCenterTile()
    local wx,wy,wz
    if tx then
        wx,wy = g_World._getWorldFromTile(tx,ty,1)
        wz = 0
    else
        sCue = nil
        sCurrentWalla = nil
    end

    local bSetParam = nCurrentWalla ~= self.nCurrentWalla
    if sCurrentWalla ~= self.sCurrentWalla then
        if self.rCurrentWalla then
            self.rCurrentWalla:stop()
        end
        self.sCurrentWalla = sCurrentWalla
        self.rCurrentWalla = nil
        if sCurrentWalla then
            self.rCurrentWalla = SoundManager.playSfx3D(sCurrentWalla, wx,wy,wz)
            bSetParam = true
        end
    end

    if bSetParam and self.rCurrentWalla then
        self.rCurrentWalla:setParameter(sWallaParam,nCurrentWalla)
    end
    self.nCurrentWalla = nCurrentWalla

    if sCue ~= self.sCurrentCue then
        if self.rCurrentCue then
            self.rCurrentCue:stop()
        end
        self.rCurrentCue = nil
        self.sCurrentCue = sCue

        if sCue then
            self.rCurrentCue = SoundManager.playSfx3D(sCue, wx,wy,wz)
            self.sCurrentCue = sCue
        end
    end
end

function Room:updateHazardStatus()
    --Profile.enterScope("UpdateHazardStatus")

    self.bBurning = false
    self.nFireTiles = 0
    self.tFires = {}
    --local bPendingBreach = false
    for addr,coord in pairs(self.tTiles) do
        if Fire.tTiles[addr] then
            self.bBurning = true
            self.nFireTiles = self.nFireTiles + 1
            self.tFires[addr] = 1
        end
        local cmdObj = CommandObject.tCommands[addr]
        --[[
        if not bPendingBreach and cmdObj then
            if cmdObj.tTiles[addr].commandParam == CommandObject.COMMAND_VAPORIZE then
                bPendingBreach = true
            elseif cmdObj.tTiles[addr].commandParam == CommandObject.COMMAND_DEMOLISH then
                if g_World.isAdjacentToSpace(coord.x, coord.y, true) then
                    bPendingBreach = true
                end
            end
        end
        ]]--
    end
    --self.bPendingBreach = bPendingBreach

    self:updateEmergency()

    --Profile.leaveScope("UpdateHazardStatus")
end

function Room:updateEmergency()
	-- visual room states: "no power" trumps "low/no oxygen" trumps "low power"
    if self:getVisibility() == World.VISIBILITY_DIM then
        self:setLightingScheme(Room.LIGHTING_SCHEME_DIM)
	-- no power
    elseif self.nPowerSupplied == 0 and not g_PowerHoliday then
        self:setLightingScheme(Room.LIGHTING_SCHEME_VACUUM)
	-- on fire, alarm on, no o2
    elseif self.bBurning or self.bEmergencyAlarmEnabled or self.bPendingBreach or self.bBreach or self:getOxygenScore() < Character.OXYGEN_SUFFOCATING then
        self:setLightingScheme(Room.LIGHTING_SCHEME_FIRE)
	-- low power
	elseif not g_PowerHoliday and (self.nPowerSupplied < self.nPowerDraw and not self:canProvidePower()) then
		self:setLightingScheme(Room.LIGHTING_SCHEME_LOWPOWER)
    elseif self.zoneObj.getLightingOverride and self.zoneObj:getLightingOverride() then
        self:setLightingScheme(self.zoneObj:getLightingOverride())
    else
        self:setLightingScheme(Room.LIGHTING_SCHEME_NORMAL)
    end
end

function Room:hasPower()
	return g_PowerHoliday or self.nPowerSupplied > 0 or self:canProvidePower()
end

function Room:hasFullPower()
	return g_PowerHoliday or self.nPowerSupplied == self.nPowerDraw or self:canProvidePower()
end

function Room:isLockedDown()
    return self.bUserBlockOxygen
end

function Room:toggleLockdown()
    self:setLockdown(not self.bUserBlockOxygen)
end

function Room:setLockdown(bLockdown)
    self.bUserBlockOxygen = bLockdown
    for addr,coord in pairs(self.tDoors) do
        local rProp = ObjectList.getDoorAtTile(coord.x,coord.y)
        if rProp then
            rProp:refreshLockdown(self.bUserBlockOxygen)
        end
    end
end

function Room:playerOwned()
    return self.nTeam == Character.TEAM_ID_PLAYER
end

-- rChar is optional.
function Room:isDangerous(rChar)
    if self.bEmergencyAlarmEnabled then
        return true
    end

	if (self.bBreach or self.bPendingBreach) and (not rChar or not rChar:wearingSpacesuit()) then return true end
    local nTeam = (rChar and rChar:getTeam()) or Character.TEAM_ID_PLAYER
    if self.nTeam ~= nTeam then return true end
    if self.zoneObj and self.zoneObj.bDangerous then return true end

    local bLowO2 = self:getOxygenScore() < Character.OXYGEN_LOW
    return bLowO2 and (not rChar or not rChar:wearingSpacesuit())
end

function Room:addCharacter(rChar)
    if not self.tCharacters[rChar] then
        self.tCharacters[rChar] = 1
        self.nCharacters = self.nCharacters+1
    end
end

function Room:removeCharacter(rChar)
    if self.tCharacters[rChar] then
        self.tCharacters[rChar] = nil
        self.nCharacters = self.nCharacters-1
        assert(self.nCharacters >= 0)
    end
end

-- return: { rChar=1, ... }, numChars
function Room:getCharactersInRoom(bIncludeDoors)
    return self.tCharacters,self.nCharacters
end

function Room:getFiresInRoom()
    return self.tFires
end

Room.MIN_O2_DIFF = 10
Room.MIN_O2_FOR_SHARING = 1000 * .2 --Oxygen.TILE_MAX * .2
Room.MAX_O2_GIVE_PER_TILE = 50
function Room:_shareOxygen(dt)
    -- let's breathe during this step as well.
    local tChars,nChars = self:getCharactersInRoom()
    local o2consumption = nChars * Character.OXYGEN_PER_SECOND * dt
    -- Have fire consume some oxygen as well
    o2consumption = o2consumption + (self.nFireTiles * Fire.OXYGEN_PER_SECOND * dt)
    local o2perTile = o2consumption / self.nTiles
    if o2perTile > 0 then
        for addr,coord in pairs(self.tTiles) do
            World.oxygenGrid:addOxygen(coord.x,coord.y,-o2perTile)
        end
    end
    self.bOxygenScoreOutOfDate = true

    if self:disallowO2Propagation() then return 0 end

    self:_o2shareSlowedAverage(dt)
    --self:_o2shareInstantAverage(dt)

    --[[
    local totalGive = 0
    for rAdjoiningRoom,nAdjoining in pairs(self.tAdjoining) do
        local adjo2score,adjtotalO2,adjaverageO2 = rAdjoiningRoom:getOxygenScore()
        local given
        if averageO2 > adjaverageO2 then
            given = self:_sendO2(rAdjoiningRoom,averageO2,adjaverageO2,totalO2,adjtotalO2,dt)
        else
            given = -rAdjoiningRoom:_sendO2(self,adjaverageO2,averageO2,adjtotalO2,totalO2,dt)
        end
        totalO2 = totalO2+given
        totalGive = totalGive+given
        averageO2 = totalO2 / self.nTiles
    end
    self.nLastGive = totalGive
    ]]--
end

function Room:hover(hoverTime)
    if GameRules.currentMode == GameRules.MODE_INSPECT or GameRules.currentMode == GameRules.MODE_PICK then
        local Lighting = require("Lighting")
        Lighting.setRoomHighlight(self, 0.3)
    end
end

function Room:unHover()
    local Lighting = require("Lighting")
    Lighting.setRoomHighlight(self, 0.0)
end

function Room:_o2shareSlowedAverage(dt)
    local o2scoreSelf,totalO2self,averageO2self = self:getOxygenScore()

    local totalO2,totalTiles = totalO2self,self.nTiles
    local totalRequest=0

    local tRequests = {}
    --Profile.enterScope("Loop1")
    for rAdjoiningRoom,nAdjoining in pairs(self.tAdjoining) do
        if not rAdjoiningRoom:disallowO2Propagation() then
            -- calc avg of adjacent room; o2 request is the diff between average tile vals.
            -- mtf question: should it be half the diff?
            local adjo2score,adjtotalO2,adjaverageO2 = rAdjoiningRoom:getOxygenScore()
            local avg = (totalO2self+adjtotalO2)/(self.nTiles+rAdjoiningRoom.nTiles)
            local request = (avg - adjaverageO2)*rAdjoiningRoom.nTiles

            -- there's a max o2 share rate based on # of tiles in either room.
            local maxRequest = math.min(self.nTiles,rAdjoiningRoom.nTiles)
            maxRequest = maxRequest * Room.MAX_O2_GIVE_PER_TILE * dt
            if math.abs(request) > maxRequest then
                if request > 0 then request = maxRequest
                else request = -maxRequest end
            end

            -- we track total requests for o2...
            tRequests[nAdjoining] = {avg=avg, request=request}
            totalRequest=totalRequest+request

            -- ... as well as the total o2 there is to work with.
            totalO2=totalO2+adjtotalO2
            totalTiles=totalTiles+rAdjoiningRoom.nTiles
        end
    end

    -- ideally, this room + all adjacent would have exactly the same o2 per tile.
    local targetAvg = totalO2/totalTiles
    local inMult,outMult = 1,1

	if (totalRequest > 0 and averageO2self < targetAvg) or (totalRequest < 0 and averageO2self > targetAvg) then
		-- Algorithm flaw:
		-- totalO2 isn't capped by maxrequest. This leads to issues where totalRequest can indicate o2 should
		-- flow out of the room, but targetAvg indicates o2 should flow into the room. Or vice versa.
		-- In that case, just fulfill all requests.
		-- Leave both mults at 1.
	elseif totalRequest > 1 and (totalO2self-totalRequest) < targetAvg*self.nTiles then
		-- if this transaction results in a net loss of o2, and if giving away the total requested oxygen
		-- would bring our o2 level below the target average, don't give away all that o2.
		-- Instead multiply outgoing o2 by some fraction.
		-- This happens in the case where we won't be able to give away enough o2 to bring everything
		-- up to the target average.
        local newRequest = (averageO2self-targetAvg)*self.nTiles
        outMult = newRequest/totalRequest
    elseif totalRequest < -1 and (totalO2self-totalRequest) > targetAvg*self.nTiles then
		-- as above comment, but for this room gaining o2 instead of losing it.
        local newRequest = (averageO2self-targetAvg)*self.nTiles
        inMult = newRequest/totalRequest
    end

    --local tDbgInfo = {}
    --Profile.leaveScope("Loop1")
    --Profile.enterScope("Loop2")
    local netChange = 0
    for rAdjoiningRoom,nAdjoining in pairs(self.tAdjoining) do
        if not rAdjoiningRoom:disallowO2Propagation() then
            local request = tRequests[nAdjoining].request
            if math.abs(request) > 10 then
                --tDbgInfo[nAdjoining] = {}
                request = request*((request > 0 and outMult) or inMult)
                netChange = netChange-request
                request = request / rAdjoiningRoom.nTiles
                for addr,coord in pairs(rAdjoiningRoom.tTiles) do
                    World.oxygenGrid:addOxygen(coord.x,coord.y,request)
                end
                rAdjoiningRoom.bOxygenScoreOutOfDate = true
                --tDbgInfo[nAdjoining].request = request
                --tDbgInfo[nAdjoining].netChange = netChange
                --tDbgInfo[nAdjoining].nTiles = rAdjoiningRoom.nTiles
            end
        end
    end
    --Profile.leaveScope("Loop2")
    --Profile.enterScope("Loop3")
    if math.abs(netChange) > 10 then
        local adjustO2 = netChange/self.nTiles
        for addr,coord in pairs(self.tTiles) do
            World.oxygenGrid:addOxygen(coord.x,coord.y,adjustO2)
        end
        self.bOxygenScoreOutOfDate = true
    end

    self.nLastGive = totalRequest
    --Profile.leaveScope("Loop3")
end

-- A debug-friendly algorithm that instantly averages all adjacent rooms.
-- Not very interesting for gameplay.
function Room:_o2shareInstantAverage()

    local o2score,totalO2,averageO2 = self:getOxygenScore()

    local cumulativeO2,cumulativeTiles = totalO2,self.nTiles

    for rAdjoiningRoom,nAdjoining in pairs(self.tAdjoining) do
        if not rAdjoiningRoom:disallowO2Propagation() then
            local adjo2score,adjtotalO2,adjaverageO2 = rAdjoiningRoom:getOxygenScore()
            cumulativeO2 = cumulativeO2+adjtotalO2
            cumulativeTiles = cumulativeTiles+rAdjoiningRoom.nTiles
        end
    end

    local newAvg = cumulativeO2 / cumulativeTiles
    for rAdjoiningRoom,nAdjoining in pairs(self.tAdjoining) do
        if not rAdjoiningRoom:disallowO2Propagation() then
            rAdjoiningRoom.bOxygenScoreOutOfDate = true

            for addr,coord in pairs(rAdjoiningRoom.tTiles) do
                World.oxygenGrid:setOxygen(coord.x,coord.y,newAvg)
            end
        end
    end

        for addr,coord in pairs(self.tTiles) do
            World.oxygenGrid:setOxygen(coord.x,coord.y,newAvg)
        end
    self.bOxygenScoreOutOfDate = true

end

function Room:_getPathableNeighbor(tx,ty,bUnreserved)
    -- MTF TODO: only searches this and adjacent tiles for unobstructed.
    -- Need to enhance this once we have bigger objects in the world.
    for i=2,9 do
        local newTX,newTY = World._getAdjacentTile(tx,ty,i)
        if self.tTiles[World.pathGrid:getCellAddr(newTX,newTY)] and World._isPathable(newTX,newTY) then
            if not bUnreserved or not ObjectList.getReservationAt(newTX,newTY) then
                return newTX,newTY
            end
        end
    end
end

function Room:getTileLoc()
    return self:getCenterTile()
end

function Room:getCenterTile(bPathableOnly,bRandomDefault)
    local tx,ty = self.nCenterTileX,self.nCenterTileY
    if not bPathableOnly then
        return tx,ty,self.nLevel
    else
        local newTX,newTY = self:_getPathableNeighbor(tx,ty)
        if newTX then return newTX,newTY,self.nLevel end
    end
    if bRandomDefault then
        return self:randomLocInRoom(true,bPathableOnly)
    end
end

function Room:disallowO2Propagation()
    return self.bBreach or self.bUserBlockOxygen or (self.zoneObj and self.zoneObj.disallowO2Propagation and self.zoneObj:disallowO2Propagation())
end

function Room:_sendO2(destRoom,fromAvg,toAvg,fromTotal,toTotal,dt)
    if fromAvg < Room.MIN_O2_FOR_SHARING then return 0 end
    if fromAvg - toAvg < Room.MIN_O2_DIFF*dt then return 0 end

    if self:disallowO2Propagation() or destRoom:disallowO2Propagation() then return 0 end

    local desiredGive = (destRoom.nTiles * fromTotal - self.nTiles * toTotal) / (self.nTiles+destRoom.nTiles)

    desiredGive = desiredGive * dt
    desiredGive = math.min(math.min(desiredGive, Room.MAX_O2_GIVE_PER_TILE * dt * self.nTiles), Room.MAX_O2_GIVE_PER_TILE * dt * destRoom.nTiles)

    local avgGive = -desiredGive / self.nTiles
    for addr,coord in pairs(self.tTiles) do
        World.oxygenGrid:addOxygen(coord.x,coord.y,avgGive)
    end

    avgGive = -avgGive
    for addr,coord in pairs(destRoom.tTiles) do
        World.oxygenGrid:addOxygen(coord.x,coord.y,avgGive)
    end

    self.bOxygenScoreOutOfDate = true
    destRoom.bOxygenScoreOutOfDate = true

    return desiredGive
end

function Room:_clearAdjoiningRooms()
    for rRoom,_ in pairs(self.tAdjoining) do
        rRoom:_setAdjoining(self,false)
    end
    for rRoom,_ in pairs(self.tAccessibleByDoor) do
        rRoom:_setAccessibleByDoor(self,nil)
    end
    self.tAdjoining = {}
    self.tWallBlobs = {}
    self.tAccessibleByDoor = {}
end

function Room:_updateAdjoiningRooms()
    --Profile.enterScope("UpdateAdjoiningRooms")

--    self.tWallBlobs = {}
    
    self.bDoorToSpace = false
    local fnAddAdjacencies = function(addr, tTarget,tDoorCoord, bMarkBlobAdjacencies)
        local tx, ty = World.roomGrid:cellAddrToCoord(addr)
        for i=2,5 do
            local adjX,adjY = World._getAdjacentTile(tx,ty,i)
            local rRoom = Room.getRoomAtTile(adjX,adjY,self.nLevel,true)
            if rRoom then
                if not tTarget[rRoom] then
                    tTarget[rRoom] = {id=rRoom.id, nCount=0, tDoorCoords={} }
                end
                tTarget[rRoom].nCount = tTarget[rRoom].nCount +1
                if tDoorCoord then
                    tTarget[rRoom].tDoorCoords[1] = tDoorCoord
                end
            elseif tDoorCoord and World._getTileValue(adjX,adjY) == World.logicalTiles.SPACE then
                self.bDoorToSpace = true
            elseif bMarkBlobAdjacencies then
                local addr = World.pathGrid:getCellAddr(adjX,adjY)
                local tBlob = World.tWallAddrToBlob[addr]
                if tBlob then
                    tBlob.tRooms[self.id] = true
                    self.tWallBlobs[tBlob] = true
                end
            end
        end
    end

    self:_clearAdjoiningRooms()
    for addr,_ in pairs(self.tWalls) do
        fnAddAdjacencies(addr, self.tAdjoining, nil, true)
    end
    for addr,coord in pairs(self.tDoors) do
        fnAddAdjacencies(addr, self.tAdjoining)
        fnAddAdjacencies(addr, self.tAccessibleByDoor, coord)
    end
    self.tAdjoining[self] = nil
    self.tAccessibleByDoor[self] = nil
    for rRoom,_ in pairs(self.tAdjoining) do
        self.tAdjoining[rRoom] = rRoom.id
        rRoom:_setAdjoining(self,true)
    end
    for rRoom,tAdjacencyData in pairs(self.tAccessibleByDoor) do
        --self.tAccessibleByDoor[rRoom] = tAdjacencyData
        rRoom:_setAccessibleByDoor(self,tAdjacencyData)
    end
    --Profile.leaveScope("UpdateAdjoiningRooms")
end

function Room:_setAdjoining(rRoom, bAdjoining)
    self.tAdjoining[rRoom] = (bAdjoining and rRoom.id) or nil
end

function Room:_setAccessibleByDoor(rRoom, tAdjacencyData)
    if tAdjacencyData then
        self.tAccessibleByDoor[rRoom] = tAdjacencyData
    else
        self.tAccessibleByDoor[rRoom] = nil
    end
end

function Room:_getMoraleScore()
	-- total morale score of all objects in room / size of room
	local nScore = 0
	for rProp,_ in pairs(self.tProps) do
		-- objects without power don't provide benefit
		-- (hasPower returns true if no power draw)
		if rProp.tData.nMoraleScore and rProp:hasPower() then
			nScore = nScore + rProp.tData.nMoraleScore
		end
	end
	nScore = nScore / self:getSize()
	-- clamp within min/max; diminishing returns remove incentive to clutter
	nScore = DFMath.clamp(nScore, -Character.MAX_ROOM_MORALE_SCORE, Character.MAX_ROOM_MORALE_SCORE)
	return nScore
end

function Room:tickDoors()
    for addr,coord in pairs(self.tDoors) do
        local rProp = ObjectList.getDoorAtTile(coord.x,coord.y)
        if rProp then
            rProp:onTick()
        end
    end
end

function Room:tickOxygen()
    self.bOxygenScoreOutOfDate = true
    local dt
    if not self.lastO2TickTime then
        self.lastO2TickTime = GameRules.elapsedTime
        dt = 1
    else
        dt = GameRules.elapsedTime - self.lastO2TickTime
        self.lastO2TickTime = GameRules.elapsedTime
    end

    self:_shareOxygen(dt)
end

-- power is requested, from zones, by rooms based on size and object count
local function fnAddPowerConsumer(rProp, tPowerConsumers)
    local nPowerDraw = rProp:getPowerDraw()
    if nPowerDraw > 0 then
		tPowerConsumers[rProp] = nPowerDraw
	end
    return nPowerDraw
end

function Room:getPowerDraw()
	if self.bDestroyed then return 0,{} end
	local tPowerConsumers = {}
	local nTotalPowerDraw = 0
	local tProps = self:getProps()
	for rProp,_ in pairs(tProps) do
        nTotalPowerDraw = nTotalPowerDraw + fnAddPowerConsumer(rProp, tPowerConsumers)
	end
    for rProp,_ in pairs(self.tPowerLeeches) do
        if rProp.rRoom then
            self.tPowerLeeches[rProp] = nil
        else
            nTotalPowerDraw = nTotalPowerDraw + fnAddPowerConsumer(rProp, tPowerConsumers)
        end
    end
	-- room also draws power based on size
	local nRoomDraw = self.nTiles * Room.POWER_DRAW_PER_TILE
	nTotalPowerDraw = nTotalPowerDraw + nRoomDraw
	tPowerConsumers[self] = nRoomDraw
	return nTotalPowerDraw, tPowerConsumers
end

function Room:tickPower()
    self.nLastPowerOutput = nil
    self:clearPowerVisLines()
	-- determine this room's power draw
	local nTotalPowerDraw,tPowerConsumers = self:getPowerDraw()
	if nTotalPowerDraw == 0 then
		self.nPowerSupplied = 0
        self.nPowerDraw = 0
		return
	end
	-- build list of contiguous power sources
	local tAvailablePower = {}
	local centerX,centerY = self:getCenterTile()
	for id,rPowerRoom in pairs(Room.tPowerZones) do
        -- MTF/JP TODO:
        -- Should we verify that a power zone is good here? e.g. not destroyed, and still providing power?
        
		-- also clear existing power requests
		if rPowerRoom.zoneObj and rPowerRoom.zoneObj:isPowering(self) then
			rPowerRoom.zoneObj:powerUnrequest(self)
		end
		if self.tContiguousRooms[id] then
			local px,py = rPowerRoom:getCenterTile()
			local nDist = DFMath.distance2D(centerX, centerY, px, py)
			table.insert(tAvailablePower, {rPowerRoom=rPowerRoom, nDist=nDist})
		end
	end
	-- sort list by proximity (closest first)
	local f = function(x,y) return x.nDist < y.nDist end
	table.sort(tAvailablePower, f)
	-- request power from nearby sources
	local nTotalPowerAvailable = 0
	-- draw until no power is left or our request has been fully met
	while not (nTotalPowerAvailable >= nTotalPowerDraw or #tAvailablePower == 0) do
		local rPowerRoom = tAvailablePower[1].rPowerRoom
		-- request power, store how much we drew
		if rPowerRoom.zoneObj then
			local nPowerDrawn = rPowerRoom.zoneObj:powerRequest(self, nTotalPowerDraw-nTotalPowerAvailable)
			nTotalPowerAvailable = nTotalPowerAvailable + nPowerDrawn
            if Room.sbPowerVisEnabled and nPowerDrawn > 0 then
                self:addPowerVisLine(false, rPowerRoom)
            end
		else
			-- room was destroyed?
		end
		table.remove(tAvailablePower, 1)
	end
	-- remember power provided
	self.nPowerSupplied = nTotalPowerAvailable
	-- distribute power to our objects, tell them they're powered or unpowered
	for rProp,nDraw in pairs(tPowerConsumers) do
		if nDraw <= nTotalPowerAvailable then
			nTotalPowerAvailable = nTotalPowerAvailable - nDraw
			-- only env objects use "has power" flag
			if rProp ~= self then
				rProp.bHasPower = true
                if Room.sbPowerVisEnabled then
                    self:addPowerVisLine(true, rProp)
                end
			end
		elseif rProp ~= self then
			rProp.bHasPower = false
		end
	end
    if Room.sbPowerVisEnabled then
        for rProp,_ in pairs(self.tPowerLeeches) do
            self:addPowerVisLine(true, rProp)
        end
    end
	-- remember power drawn
	self.nPowerDraw = nTotalPowerDraw
end

function Room:clearPowerVisLines()
    if self.tPowerVisLines then
        local rLayer = Renderer.getRenderLayer(Room.POWER_DISPLAY_LAYER)
        for rProp,_ in pairs(self.tPowerVisLines) do
            rLayer:removeProp(rProp)
        end
        self.tPowerVisLines = {}
    end
end

function Room:addPowerVisLine(bDraw,rEnt,rRoom)
    local toWX,toWY
    local color
    local ctx,cty = (rRoom or self):getCenterTile()
    local fromWX,fromWY = World._getWorldFromTile(ctx,cty,1)
    local z = 1000
    if bDraw then
        toWX,toWY = rEnt:getLoc()
        color = Gui.RED
    else
        local ptx,pty = rEnt:getCenterTile()
        toWX, toWY = World._getWorldFromTile(ptx,pty,1)
        color = Gui.GREEN
        z = 900
    end
    local rProp = MOAIProp.new()
    rProp.rTargetEnt = rEnt
    rProp:setDeck(Gui.rOnePixelDeck)
    local rLayer = Renderer.getRenderLayer(Room.POWER_DISPLAY_LAYER)
    rLayer:insertProp(rProp)
    rProp:setLoc(fromWX,fromWY,z)
    rProp:setColor(unpack(color))
    local nLen = DFMath.distance(fromWX,fromWY,z,toWX,toWY,z)
    rProp:setScl(nLen,5,5)
    local angle = DFMath.getAngleBetween(1,0,toWX-fromWX,toWY-fromWY)
    rProp:setRot(0,0,angle)
    if not self.tPowerVisLines then self.tPowerVisLines={} end
    self.tPowerVisLines[rProp] = 1
end

function Room:tickRoomSlow()
    self:tickDoors()
    self:tickOxygen()
	self:tickPower()
end

function Room:canProvidePower()
    if not self.nLastPowerOutput then 
        self.nLastPowerOutput = self.zoneObj:getPowerOutput()
    end
    return self.nLastPowerOutput > 0
end

function Room:addContiguousRooms(tRoomList)
	tRoomList[self.id] = self
	for rRoom,id in pairs(self.tAdjoining) do
		if not tRoomList[id] then
			rRoom:addContiguousRooms(tRoomList)
		end
	end
    for tBlob,_ in pairs(self.tWallBlobs) do
        for id,_ in pairs(tBlob.tRooms) do
            if not tRoomList[id] and Room.tRooms[id] then
                Room.tRooms[id]:addContiguousRooms(tRoomList)
            end
        end
    end
	return tRoomList
end

function Room:tickRoomFast()
    Profile.enterScope("TickSingleRoom")

    local dt
    if not self.lastTickTime then
        self.lastTickTime = GameRules.elapsedTime
        dt = 1
    else
        dt = GameRules.elapsedTime - self.lastTickTime
        self.lastTickTime = GameRules.elapsedTime
    end

	-- recalculate room contiguity data,
	-- updating that of other rooms in our "blob"
	if not self.nLastContiguityTestTime or GameRules.elapsedTime > self.nLastContiguityTestTime + Room.CONTIGUITY_TEST_INTERVAL then
		-- build list of contiguous rooms
		local tRooms = {}
		tRooms = self:addContiguousRooms(tRooms)
		-- update all contiguous rooms (plus self) with this data,
		-- so they don't recalc it until needed
		for id,rRoom in pairs(tRooms) do
			rRoom.nLastContiguityTestTime = GameRules.elapsedTime
			rRoom.tContiguousRooms = tRooms
			-- update global list of power zones
			if rRoom:canProvidePower() then
				Room.tPowerZones[id] = rRoom
			-- remove if a zone is no longer providing power
			elseif Room.tPowerZones[id] then
				Room.tPowerZones[id] = nil
			end
		end
		-- JPL TODO: store an average of all contiguous room centers, ie a
		-- "blob center", for things like o2 viz
	end

    if self.tFailedPathfinds then
        for srcAddr,tDests in pairs(self.tFailedPathfinds) do
            for destAddr,nTime in pairs(tDests) do
                if GameRules.elapsedTime - nTime > 20 then
                    tDests[destAddr] = nil
                end
                if not next(self.tFailedPathfinds[srcAddr]) then
                    self.tFailedPathfinds[srcAddr] = nil
                end
            end
        end
        if not next(self.tFailedPathfinds) then
            self.tFailedPathfinds = nil
        end
    end

    Profile.enterScope("HazardStatus")
    self:updateHazardStatus()
    Profile.leaveScope("HazardStatus")
    self:_updateSound()

    --self:_updateVacuumVectors()

    Profile.enterScope("ZoneObj")
    if self.zoneObj and self.zoneObj.onTick then
        self.zoneObj:onTick(dt)
    end
    Profile.leaveScope("ZoneObj")

    if self:getVisibility() ~= World.VISIBILITY_DIM then
--    if self.nTeam == Character.TEAM_ID_PLAYER then
        for rProp,_ in pairs(self.tProps) do
            --local sName = rProp.sName
        --Profile.enterScope("Props"..sName)
            rProp:onTick(dt)
        --Profile.leaveScope("Props"..sName)
        end
    end
    --self:tickDoors()

	-- get morale score even for non player owned rooms
	self.nMoraleScore = self:_getMoraleScore()

    Profile.enterScope("UpdateCharAllegiance")
	local tChars,nChars = self:getCharactersInRoom(true)
    if self.nLastVisibility == World.VISIBILITY_FULL then
--    if self.nTeam == Character.TEAM_ID_PLAYER then
		for rChar,_ in pairs(tChars) do
			if rChar:getFactionBehavior() == Character.FACTION_BEHAVIOR.Friendly then
                rChar:setTeam(Character.TEAM_ID_PLAYER)
			end
		end
    end
    Profile.leaveScope("UpdateCharAllegiance")

	if GameRules.elapsedTime - self.nLastFamiliarityTick > Character.FAMILIARITY_TICK_RATE then
	    self.nLastFamiliarityTick = GameRules.elapsedTime
	    -- tick familiarity for everyone in the room
	    for rChar,_ in pairs(tChars) do
		    for rOther,_ in pairs(tChars) do
			    if rChar ~= rOther then
				    rChar:addFamiliarity(rOther.tStats.sUniqueID, Character.FAMILIARITY_TICK_INCREASE)
			    end
		    end
	    end
    end

    Profile.leaveScope("TickSingleRoom")
end

function Room:revealed()
	-- start disappear timer for any dead characters
	for rChar,_ in pairs(CharacterManager.getDeadCharacters()) do
		if Room.getRoomAt(rChar:getLoc()) == self then
			CharacterManager.getDeadCharacters()[rChar] = GameRules.elapsedTime
		end
	end
end

function Room:tickVisibility()
    local nVisibility = World.VISIBILITY_HIDDEN
    if self.nTeam == Character.TEAM_ID_PLAYER or GameRules.inEditMode then
        nVisibility = World.VISIBILITY_FULL
    elseif self.nLastSeen then
        local nDiff = GameRules.elapsedTime - self.nLastSeen
        if nDiff < Room.LOSE_VISIBILITY_TIME then
            nVisibility = World.VISIBILITY_FULL
        end
	    for rChar,_ in pairs(self.tCharacters) do
            if rChar:getTeam() == Character.TEAM_ID_PLAYER then
                nVisibility = World.VISIBILITY_FULL
                break
            end
        end
        if nVisibility ~= World.VISIBILITY_FULL and nDiff < Room.LOSE_REVEALED_TIME then
            nVisibility = World.VISIBILITY_DIM
        end
    end

    if self.nLastVisibility ~= nVisibility then
        self.nFloatAwayTimerStart = nil
		if nVisibility == World.VISIBILITY_FULL then
			self:revealed()
		end
        self.nLastVisibility = nVisibility
        for addr,coord in pairs(self.tTiles) do
            World._dirtyTile(coord.x,coord.y)
        end
        for addr,coord in pairs(self.tWalls) do
            World._dirtyTile(coord.x,coord.y)
        end
        self:updateEmergency()
    end
    if self.DBG_floatForced then
        self.DBG_floatForced = nil
        self:_doFloatAway()
    elseif nVisibility == World.VISIBILITY_FULL and self:getTeam() ~= Character.TEAM_ID_PLAYER and not self.rClaimFlag then
        self.rClaimFlag = MOAIProp.new()
        local spriteSheet = DFGraphics.loadSpriteSheet('UI/UIMisc')
        self.rClaimFlag:setDeck(spriteSheet)
        local idx = spriteSheet.names['claim_flag']
        self.rClaimFlag:setIndex(idx)
        self.rClaimFlag:setColor( unpack( Gui.RED ) )
        local r = spriteSheet.rects[idx]
        local tx,ty,tw = self:getCenterTile()
        local wx,wy,wz = World._getWorldFromTile(tx,ty,tw)
        self.rClaimFlag:setLoc(wx,wy+r.origHeight*.5,wz)
        Renderer.getRenderLayer('WorldWall'):insertProp(self.rClaimFlag)
    elseif self.rClaimFlag and (nVisibility ~= World.VISIBILITY_FULL or self:getTeam() == Character.TEAM_ID_PLAYER) then
        Renderer.getRenderLayer('WorldWall'):removeProp(self.rClaimFlag)

        self.rClaimFlag = nil
    elseif nVisibility == World.VISIBILITY_HIDDEN then
        if not self.nFloatAwayTimerStart then self.nFloatAwayTimerStart = GameRules.elapsedTime end
        if GameRules.elapsedTime - self.nFloatAwayTimerStart > Room.FLOAT_AWAY_TIME then
            if not self.nNextFloatAwayTest or self.nNextFloatAwayTest < GameRules.elapsedTime then
                self.nNextFloatAwayTest = GameRules.elapsedTime + 30
                self:_attemptFloatAway()
            end
        end
    end
end

function Room:_attemptFloatAway()
    if not self.nOriginalTeam or self.nOriginalTeam == Character.TEAM_ID_PLAYER then return end

    local tRooms = Room.getRoomsOfTeam(self.nOriginalTeam, true)
    
    local tContig = self.tContiguousRooms
    for contigID,rContigRoom in pairs(tContig) do
        -- If we're contiguous with a room not on our team, it means we got attached to some other blob.
        -- No floating away.
        if not tRooms[rContigRoom] then
            return
        end
    end
    
    
    for rRoom,id in pairs(tRooms) do
        if not rRoom.nFloatAwayTimerStart or GameRules.elapsedTime - rRoom.nFloatAwayTimerStart < Room.FLOAT_AWAY_TIME then
            return
        end
        -- don't float away if connected to other structures.
        for rAdjoiningRoom,nAdjoining in pairs(self.tAdjoining) do
            if not rAdjoiningRoom.nOriginalTeam or rAdjoiningRoom.nOriginalTeam ~= self.nOriginalTeam then
                return
            end
        end
    end
    self:_doFloatAway(tRooms)
end

function Room:DBG_forceFloatAway()
    self.DBG_floatForced = true
end

function Room:_doFloatAway(tRooms)
    tRooms = tRooms or Room.getRoomsOfTeam(self.nOriginalTeam, true)
    local killTile = function(tx,ty)
		 local tObjects = ObjectList.getObjectsOfTypesAtTile(tx,ty,{[ObjectList.ENVOBJECT]=1, [ObjectList.CHARACTER]=1})
		 for rObj,sType in pairs(tObjects) do
			 if sType == ObjectList.CHARACTER then
				 CharacterManager.deleteCharacter( rObj )
			 else
				 rObj:remove()
			 end
		 end
		 -- dead characters don't occupy space, deal with them specially
		 -- (dead characters list generally never unreasonably long)
		 local tDeaders = CharacterManager.getDeadCharacters()
		 for rChar,_ in pairs(tDeaders) do
			 local ctx,cty = g_World._getTileFromWorld(rChar:getLoc())
			 if tx == ctx and ty == cty then
				 CharacterManager.deleteCharacter(rChar)
			 end
		 end
		 g_World._setTile(tx, ty, g_World.logicalTiles.SPACE, false, false)
    end
    
    local tTileTables={}
    local tWallBlobTables={}

    local wx,wy = g_World._getWorldFromTile(self.nCenterTileX,self.nCenterTileY)
    for rRoom,id in pairs(tRooms) do
        local tTiles = DFUtil.deepCopy(rRoom.tTiles)
        local tWalls = DFUtil.deepCopy(rRoom.tWalls)
        local tWallBlobs = DFUtil.deepCopy(rRoom.tWallBlobs)
        table.insert(tTileTables,tTiles)
        table.insert(tTileTables,tWalls)
        table.insert(tWallBlobTables,tWallBlobs)        
        local tGens = g_SpaceRoom:getExtraGeneratorsForRoom(id)
        for _,rGen in ipairs(tGens) do
            rGen:remove()
        end
    end
    for _,tTiles in ipairs(tTileTables) do
        for addr,coord in pairs(tTiles) do
            killTile(coord.x, coord.y)
        end
    end
    for _,tWallBlobs in ipairs(tWallBlobTables) do
        for tBlobData,_ in pairs(tWallBlobs) do
            for addr,_ in pairs(tBlobData.tWallAddrs) do
                local tx,ty = g_World.pathGrid:cellAddrToCoord(addr)
                killTile(tx,ty)
            end
        end
    end
    --g_World.fixupVisuals()
    Base.eventOccurred(Base.EVENTS.DerelictFloataway, {wx=wx,wy=wy})
end

function Room:getAlertString()
    if self:getTeam() ~= Character.TEAM_ID_PLAYER then
        return "UNCLAIMED"
    end
    if self.zoneObj and self.zoneObj.getAlertString then
        return self.zoneObj:getAlertString()
    end
    return ""
end

function Room:tickLighting()
    Profile.enterScope("FlashingLights")
    local dt = GameRules.deltaTime

    -- under normal or dark rooms we don't flash the lights, otherwise we do to draw attention
    if self.nLightingScheme ~= Room.LIGHTING_SCHEME_NORMAL
            and self.nLightingScheme ~= Room.LIGHTING_SCHEME_OFF
            and self.nLightingScheme ~= Room.LIGHTING_SCHEME_DIM then
        self.nLightFadeTimer = self.nLightFadeTimer + (dt * self.nLightFadesPerSecond)
        if self.nLightFadeTimer > 1.0 then
            self.nLightFadeTimer = self.nLightFadeTimer - 1.0
        end

        local nDarkPct = ((math.sin(self.nLightFadeTimer * math.pi * 2) * 0.5) + 0.5) * 0.5

        Lighting.setRoomTileLightInfo(self, 1.0, 1.0, nDarkPct)
    end
    Profile.leaveScope("FlashingLights")
end

function Room:setLightingScheme(nNewScheme)
    nNewScheme = nNewScheme or Room.DBG_globalSetTeam

    if self.nLightingScheme ~= nNewScheme then
        local nOldScheme = self.nLightingScheme
        self.nLightingScheme = nNewScheme

        if nNewScheme == Room.LIGHTING_SCHEME_DIM or nOldScheme == Room.LIGHTING_SCHEME_DIM then
            for rProp,_ in pairs(self.tProps) do
                rProp:lightingChanged(self)
            end
        end

        self.nLightFadeTimer = 0.0
        self.nLightFadesPerSecond = 0.5

        require("Lighting").updateEmergencyForRoom(self)
    end
end

function Room:debugDraw()
    if Room.debugDrawMode == Room.DEBUG_DRAW_OXYGEN then
        local rRenderLayer = World.getWorldRenderLayer()

        MOAIGfxDevice.setPenColor ( 1, 0, 0, 1 )

        local xmax,ymax,magmax = 0,0,0

        local tDisplayTiles = {}
        for addr,val in pairs(self.tTiles) do
            tDisplayTiles[addr] = val
        end
        --for addr,val in pairs(self.tWalls) do
            --tDisplayTiles[addr] = val
        --end

        for addr,_ in pairs(tDisplayTiles) do
            local wx,wy = World._getWorldFromAddr(addr)
            local vx,vy,mag = Oxygen.getVacuumVec(wx,wy)
            local a0, b0 = rRenderLayer:worldToWnd(wx,wy,0)
            local wx2,wy2 = wx+vx*mag,wy+vy*mag
            local a1, b1 = rRenderLayer:worldToWnd(wx2,wy2,0)
            MOAIDraw.drawLine( a0, b0, a1, b1 )
            MOAIDraw.fillRect(a1-2,b1-2,a1+2,b1+2)
            if mag > magmax then
                magmax = mag
                xmax,ymax = vx,vy
            end
        end
        --    print('Max vacuum this tick:',magmax,xmax,ymax)
    elseif Room.debugDrawMode == Room.DEBUG_DRAW_BORDERS then
        local rRenderLayer = World.getWorldRenderLayer()

        for addr,border in pairs(self.tBorders) do
            if self.tExteriors[addr] then
                MOAIGfxDevice.setPenColor ( 0, 0, 1, 1 )
            else
                MOAIGfxDevice.setPenColor ( 0, 1, 0, 1 )
            end
            local wx,wy = World._getWorldFromAddr(addr)
            local a0, b0 = rRenderLayer:worldToWnd(wx,wy,0)
            MOAIDraw.fillCircle(a0, b0, 10)
        end
    end
end

function Room:onFire()
    self.bBurning = true
end

function Room:getZoneName()
    return self.zoneName
end

function Room:getZoneDef()
    return Zone[self.zoneName]
end

function Room:getZoneObj()
    return self.zoneObj
end

function Room:getEnvObjectColor()
    local tZoneDef = self:getZoneDef()

    local tPropColor = self.tPropLightColor or (tZoneDef and tZoneDef.tPropLightColor) or {0.5, 0.5, 0.5}

    if self.nLightingScheme == Room.LIGHTING_SCHEME_DIM then
        tPropColor[1] = tPropColor[1]*.3
        tPropColor[2] = tPropColor[2]*.3
        tPropColor[3] = tPropColor[3]*.3
    end

    return tPropColor
end

-- room prop placement and job behavior:
-- rooms save prop placement by name, tile addr.
-- if a room layout changes, it reevaluates all of these.
-- whenever this list changes, it regens the prop list as appropriate.

function Room:autopopulateProps()
    local validObjects = Zone[self.zoneName].tValidObjectTypes
    local maxObjects = Zone[self.zoneName].nMaxProps
    if maxObjects then
        maxObjects = maxObjects - self.nProps
        if maxObjects <= 0 then
            self.bJobsDirty = false
            return
        end
    end
    local buildJobs = 0
    if validObjects and #validObjects > 0 then
        for addr,coord in pairs(self.tTiles) do
            local testObjName = DFUtil.arrayRandom(validObjects)
            local bAdded = Room.attemptAddPropGhostAt(coord.x,coord.y, self.nLevel, testObjName, false)
            if not bAdded then
                bAdded = Room.attemptAddPropGhostAt(coord.x,coord.y, self.nLevel, testObjName, true)
            end
            if bAdded then
                buildJobs = buildJobs+1
            end
            if maxObjects and buildJobs >= maxObjects then
                break
            end
        end
    end
end

function Room.createGhostCursor(tx,ty,sName,bFlipX,bFlipY)
    bFlipX = bFlipX and EnvObject.canFlipX(sName)
    Room.clearGhostCursor()
    local wx,wy = World._getWorldFromTile(tx,ty)

    local rRoom = Room.getRoomAtTile(tx,ty,1)
	-- if no room but object can be built in space, pass rSpaceRoom
	if not rRoom and EnvObject.getObjectData(sName).bCanBuildInSpace then
		rRoom = g_SpaceRoom
	end
    local bFound,tValid,tInvalid,newTX,newTY
    bFound,tx,ty,bFlipX,bFlipY,tValid,tInvalid = World._findPropFit(tx, ty, sName, bFlipX, bFlipY, true,true)
    wx,wy = World._getWorldFromTile(tx,ty)
	-- setting tempBuildGhost used to happen earlier, because reasons
    Room.tempBuildGhost = EnvObject.createBuildGhost(sName, tx,ty, bFlipX, bFlipY)
    Cursor.drawTiles(tValid, true,true)
    Cursor.drawTiles(tInvalid, false,true)
    Room.oldInvalidCursorTiles=tInvalid
    Room.oldValidCursorTiles=tValid
    return tValid,tInvalid
end

function Room.clearGhostCursor()
    if Room.tempBuildGhost then
        EnvObject.destroyBuildGhost(Room.tempBuildGhost)
        Room.tempBuildGhost = nil
    end
    if Room.oldValidCursorTiles then
        for addr,tile in pairs(Room.oldValidCursorTiles) do
            g_World.layers.cursor.grid:setTileValue(tile.x, tile.y, 0)
        end
        for addr,tile in pairs(Room.oldInvalidCursorTiles) do
            g_World.layers.cursor.grid:setTileValue(tile.x, tile.y, 0)
        end
        Room.oldValidCursorTiles=nil
        Room.oldInvalidCursorTiles=nil
    end
end

-- object placement
function Room.addPendingPropPlacement(rRoom, tx, ty, nCost)
    local tNewBuildInfo = {}
    tNewBuildInfo.rRoom = rRoom
    tNewBuildInfo.tx = tx
    tNewBuildInfo.ty = ty
    tNewBuildInfo.nCost = nCost
    tNewBuildInfo.addr = World.pathGrid:getCellAddr(tx,ty)
    Room.tPendingObjectBuilds[tNewBuildInfo.addr] = tNewBuildInfo
end

function Room.confirmAllPendingPropPlacements()
    for addr, rInfo in pairs(Room.tPendingObjectBuilds) do
        if rInfo.rRoom and not rInfo.rRoom.bDestroyed then
            rInfo.rRoom:confirmPropBuild()
        end
    end
    Room.tPendingObjectBuilds = {}
end

function Room.removeAllPendingPropPlacements()
    for addr, rInfo in pairs(Room.tPendingObjectBuilds) do
        if rInfo.rRoom and not rInfo.rRoom.bDestroyed then
            rInfo.rRoom:removePropGhostAt(rInfo.tx, rInfo.ty)
        end
    end
    Room.tPendingObjectBuilds = {}
end

function Room.removePendingPropPlacementAtTile(tx, ty)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    local rInfo = Room.tPendingObjectBuilds[addr]
    if rInfo and rInfo.rRoom and not rInfo.rRoom.bDestroyed then
        rInfo.rRoom:removePropGhostAt(rInfo.tx, rInfo.ty)
    end
    Room.tPendingObjectBuilds[addr] = nil
end

function Room.getPendingPropPlacementCost()
    local nCost = 0
    for addr, rInfo in pairs(Room.tPendingObjectBuilds) do
        nCost = nCost + rInfo.nCost
    end
    return nCost
end

function Room.addPendingObjectCancel(tx, ty)
    local rRoom, addr, tData = Room.getGhostAtTile(tx,ty)
    local tCancel
    if tData and tData.buildGhost then
        tCancel = Room.tPendingObjectCancels[addr]
        if not tCancel then
            tCancel = {}
            tCancel.rRoom = rRoom
            tCancel.tx = tx
            tCancel.ty = ty
            tCancel.nCost = tData.nCost
            tCancel.addr = addr
            tCancel.buildGhost = tData.buildGhost
            Room.tPendingObjectCancels[addr] = tCancel
        end
        if tCancel then
            tCancel.buildGhost:setVisible(false)
        end
    end
end

function Room.confirmAllPendingObjectCancels()
    for addr, rInfo in pairs(Room.tPendingObjectCancels) do
        if rInfo.rRoom then
            rInfo.rRoom:removePropGhostAt(rInfo.tx, rInfo.ty)
        end
    end
    Room.tPendingObjectCancels = {}
end

function Room.removeAllPendingObjectCancels()
    for addr, rInfo in pairs(Room.tPendingObjectCancels) do
        if rInfo.buildGhost then
            rInfo.buildGhost:setVisible(true)
        end
    end
    Room.tPendingObjectCancels = {}
end

function Room.getPendingObjectCancelCost()
    local nCost = 0
    for addr, rInfo in pairs(Room.tPendingObjectCancels) do
        nCost = nCost + rInfo.nCost
    end
    return nCost
end

function Room.sendAlert(tx,ty,tw,nRange,fn)
    local r = Room.getRoomAtTile(tx,ty,tw, true)
    if not r then return end

    local adjoiningRooms = r:getAdjoiningRooms()

    local tCharactersInRoom = r:getCharactersInRoom(true)
    for rCharInRoom,_ in pairs(tCharactersInRoom) do
        if MiscUtil.isoDist(tx,ty,rCharInRoom:getTileLoc()) < nRange then
            fn(rCharInRoom,tx,ty,tw)
        end
    end

    for rAdjoiningRoom,nAdjoining in pairs(adjoiningRooms) do
        tCharactersInRoom = rAdjoiningRoom:getCharactersInRoom(true)
        for rCharInRoom,_ in pairs(tCharactersInRoom) do
            if MiscUtil.isoDist(tx,ty,rCharInRoom:getTileLoc()) < nRange then
                fn(rCharInRoom,tx,ty,tw)
            end
        end
    end
end

function Room.spreadCombatAwareness(rAttacker, tx,ty,tw)
    -- Find nearby rooms
    local r,tRooms = Room.getRoomAtTile(tx,ty,tw, true)
    if not r then return end

    local tNotifyRooms = {}
    for id,rRoom in pairs(tRooms) do
        tNotifyRooms[id]=rRoom
        local adjoiningRooms = rRoom:getAdjoiningRooms()
        for rAdjoiningRoom,nAdjoining in pairs(adjoiningRooms) do
            tNotifyRooms[nAdjoining]=rAdjoiningRoom
        end
    end
    
    for id,rRoom in pairs(tNotifyRooms) do
        local tCharactersInRoom = rRoom:getCharactersInRoom(true)
        rRoom.nLastCombatAlert = GameRules.elapsedTime
        for rCharInRoom,_ in pairs(tCharactersInRoom) do
            rCharInRoom:combatAlert(rRoom,rAttacker,tx,ty)
        end
    end
end

function Room.attemptAddPropGhostAt(tx,ty,tw,sName,bFlipX,bFlipY)
    local nCost = EnvObject.getObjectData(sName).matterCost or 0
    local nPendingCost = GameRules.getPendingBuildCost()
    nPendingCost = nPendingCost + nCost
    if nPendingCost then
		if nPendingCost > GameRules.nMatter then
            return false
        end
	end

    local bForceFlipX = nil
    if bFlipX ~= nil then
        bForceFlipX = bFlipX
    end
    local bForceFlipY = nil
    if bFlipY ~= nil then
        bForceFlipY = bFlipY
    end
    local bFound

    bFound,tx,ty,bFlipX,bFlipY = World._findPropFit(tx,ty,sName,bForceFlipX,bForceFlipY,false,true)

    if bFound then
        local rRoom = Room.getRoomAtTile(tx,ty,1)

        if not rRoom and EnvObject.getObjectData(sName).bCanBuildInSpace then
            rRoom = g_SpaceRoom
        end
        if rRoom then
            rRoom:_addPropGhostAt(sName,tx,ty,bFlipX,bFlipY,nCost)
			if sName == 'OxygenRecycler' then
				GameRules.completeTutorialCondition('BuiltO2')
			elseif sName == 'OxygenRecycler' then
				GameRules.completeTutorialCondition('FlippedObject')
			end
            return true,tx,ty,bFlipX,bFlipY
        end
    end
    return false
end

function Room:_addPropGhostAt(sName,tx,ty,bFlipX,bFlipY,nCost)
        bFlipX = bFlipX and EnvObject.canFlipX(sName)
        local addr = World.pathGrid:getCellAddr(tx,ty)
        self.tPropPlacements[addr] = {
			sName=sName,
			bFlipX=bFlipX,
			bFlipY=bFlipY,
			tx=tx,
			ty=ty,
			addr=addr
		}
        local wx,wy = World._getWorldFromTile(tx,ty)
        World.makePropReservation(wx,wy,sName,bFlipX,bFlipY,self.id)
        self.tPropPlacements[addr].buildGhost = EnvObject.createBuildGhost(sName, tx,ty, bFlipX, bFlipY)
        self.tPropPlacements[addr].nCost = nCost

        -- add to the queue
        Room.addPendingPropPlacement(self, tx, ty, nCost)
end

function Room:confirmPropBuild()
    self.bJobsDirty=true
end

function Room:removePropGhostAt(tx,ty,bRefundCost)
    self.bJobsDirty = true
--    local addr = World.pathGrid:getCellAddr(tx,ty)

	local tReservation = ObjectList.getReservationAt(tx,ty)
    local addr = g_World.pathGrid:getCellAddr(tx,ty)

	--if tReservation then
        --addr = tReservation.addr
    --end
	local tData = self.tPropPlacements[addr]
    if tData then
        g_World._clearPropReservation(tData.tx, tData.ty, tData.sName, tData.bFlipX, self.id)
        EnvObject.destroyBuildGhost(tData.buildGhost)
    end
    
    local tInfo = Room.tPendingObjectBuilds[addr] or self.tPropPlacements[addr]
    self.tPropPlacements[addr] = nil
    Room.tPendingObjectBuilds[addr] = nil
    local bRefunded = false
    if tInfo and bRefundCost and tInfo.nCost then
        g_GameRules.addMatter(tInfo.nCost)
        bRefunded = true
    end
    return bRefunded
end

-- return: rRoom, addr, tData
function Room.getGhostAtTile(tx,ty)
    local r = Room.getRoomAtTile(tx,ty,1)
	if not r then
		r = g_SpaceRoom
	end
	local tReservation = ObjectList.getReservationAt(tx,ty)
	if not tReservation then return end
	local tData = r.tPropPlacements[tReservation.addr]
	if not tData then return end
	local bSourceTile = tData.tx == tx and tData.ty == ty
	return r,tReservation.addr,tData
end

function Room:_retestPropPlacements()
    for addr,tData in pairs(self.tPropPlacements) do
        self:_retestPropPlacement(addr,tData)
    end
end

function Room:_retestPropPlacement(addr,tData)
        -- temporarily remove the reservation so we can re-test
        World._clearPropReservation(tData.tx, tData.ty, tData.sName, tData.bFlipX, self.id)
        local rTargetRoom = Room.getRoomAtTile(tData.tx,tData.ty,1)
        -- need to track space ghosts
        if not rTargetRoom and World._getTileValue(tData.tx,tData.ty) == World.logicalTiles.SPACE then
            rTargetRoom = g_SpaceRoom
        end
        if rTargetRoom ~= self then
            self:removePropGhostAt(tData.tx,tData.ty,true)
            self.bJobsDirty = true
            Room.attemptAddPropGhostAt(tData.tx,tData.ty,1,tData.sName,tData.bFlipX,tData.bFlipY)
        elseif not World._checkPropFit(tData.tx,tData.ty, tData.sName, tData.bFlipX, tData.bFlipY,false, false) then
            self:removePropGhostAt(tData.tx,tData.ty,true)
            self.bJobsDirty = true
        else
            local wx,wy = World._getWorldFromTile(tData.tx,tData.ty)
            World.makePropReservation(wx,wy,tData.sName,tData.bFlipX,tData.bFlipY,self.id)
        end
end

function Room:getJobs(rChar, tObjects)
    local tJobs = {}

    if self.bJobsDirty then
        self:_refreshPropJobList()
    end

    local nFactionBehavior = rChar:getFactionBehavior()
    if self.bBurning then
        if (rChar.tStats.nRace ~= Character.RACE_MONSTER or rChar.tStats.nRace ~= Character.RACE_KILLBOT) and rChar:getTeam() == self.nTeam then
            table.insert(tObjects, self.fireActivityOptionList:getListAsUtilityOptions())
        end
    end

    if nFactionBehavior == Character.FACTION_BEHAVIOR.Citizen and (rChar:getTeam() == self.nTeam or self == g_SpaceRoom) then
        table.insert(tObjects, self.activityOptionList:getListAsUtilityOptions())

        if self.zoneObj then
            self.zoneObj:getActivityOptions(rChar, tObjects)
        end
	-- give raiders basic options like goinside
    elseif nFactionBehavior == Character.FACTION_BEHAVIOR.EnemyGroup then
		table.insert(tObjects, self.activityOptionList:getListAsUtilityOptions())
        if self.zoneObj and self.zoneObj.getEnemyActivityOptions then
            self.zoneObj:getEnemyActivityOptions(rChar, tObjects)
        end
	end
end

function Room:isBreached()
    return self.bBreach
end

function Room:setZoneCallback(zone, callback)
    self.rZone = zone
    self.zonePropCallback = callback
end

-- tx,ty is the wall tile.
-- dir is the direction FROM the room TO the wall.
-- We store the direction FROM the wall TO the room.
function Room:_setWall(tx,ty,dir,bSet,bDoor)

    local addr = World.pathGrid:getCellAddr(tx,ty)

    if dir then
        -- swap direction to its opposite.
        dir = World.oppositeDirections[dir]
    end

    if bSet then
        if not Room.tWallsByAddr[addr] then Room.tWallsByAddr[addr] = {tDirs={}} end

        Room.tWallsByAddr[addr].tDirs[dir] = self.id
        Room.tWallsByAddr[addr].bDoor = bDoor
        self.tWalls[addr] = {x=tx,y=ty,bDoor=bDoor,dirToRoom=dir}
        if dir == World.directions.SW or dir == World.directions.SE or dir == World.directions.S then
            self.tWalls[addr].bFacingRoom = true
        else
            self.tWalls[addr].bFacingRoom = false
        end
    else
        self.tWalls[addr] = nil
        if dir then
            Room.tWallsByAddr[addr].tDirs[dir] = nil
        else
            local tDirs = Room.tWallsByAddr[addr].tDirs

            for i=2,9 do
                if tDirs[i] == self.id then
                    tDirs[i] = nil
                end
            end
        end
        if not next(Room.tWallsByAddr[addr].tDirs) then
            Room.tWallsByAddr[addr] = nil
        end
    end
end

function Room:_setDoor(tx,ty,dir,bSet)
    self:_setWall(tx,ty,dir,bSet,true)
end


function Room:_clearWalls()
    if self.tWalls then
        for addr,coord in pairs(self.tWalls) do
            self:_setWall(coord.x,coord.y,nil,false)
        end
    end
    self.tWalls = {}
end

function Room._isValidRoomTile(tx,ty)
    if g_World._isInBounds(tx,ty) then
        return true
    end
    return false
end

function Room:setTiles(tTiles)
    Profile.enterScope("Room.setTiles")
    if self.zoneObj then
        self.zoneObj:preTileUpdate()
    end

    --self:_clearAdjoiningRooms()
    
    if self.tTiles then
        for addr,coord in pairs(self.tTiles) do
            if World.roomGrid:getTileValue(coord.x,coord.y) == self.id then
                World.roomGrid:setTileValue(coord.x,coord.y, 0)
            end
        end
    end

    self.tTiles = tTiles
    self.tLights = {}
    self.nTiles = 0

    self:_clearWalls()

    self.tCharacters = {}
    self.nCharacters = 0
    self.tBorders = {}
    self.tExteriors = {}
    self.tDoors = {}
    self.tBreaches = {}
    --self.bPropsDirty = true
    self.bExterior = false
    self.bBreach = false

    local tPropList = {}

    -- Compute some data about the room
    --     Compute the set of wall tiles
    --     Compute the set of door tiles
    --     Compute the breach status of the room
    --     Compute the "middle"
    local xTotal,yTotal=0,0
    --Profile.enterScope("Room.setTilesA")
    for addr,coord in pairs(tTiles) do
        if Room._isValidRoomTile(coord.x,coord.y) then
            self.nTiles = self.nTiles+1

            local rProp = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
            if rProp then tPropList[rProp] = 1 end

            local wx,wy = World._getWorldFromTile(coord.x, coord.y)
            xTotal,yTotal=xTotal+wx,yTotal+wy

            local old = World.roomGrid:getTileValue(coord.x,coord.y)
            if old > 0 and old ~= self.id then
                Room.tRooms[old].tTiles[addr] = nil
                if not next(Room.tRooms[old].tTiles) then
                    Room.tRooms[old]:_destroy()
                end
            end
            World.roomGrid:setTileValue(coord.x,coord.y, self.id)

        --Profile.enterScope("Room.setTilesA1")
            for dir=2,9 do
                local adjX,adjY = World._getAdjacentTile(coord.x,coord.y,dir)
                local adjVal = World.pathGrid:getTileValue(adjX,adjY)
                if adjVal == g_World.logicalTiles.WALL then
                    rProp = ObjectList.getObjAtTile(coord.x,coord.y,ObjectList.ENVOBJECT)
                    if rProp and rProp:getFacing() == World.oppositeDirections[dir] then
                        tPropList[rProp] = 1
                    end
                    self:_setWall(adjX,adjY,dir,true)
                elseif adjVal == World.logicalTiles.DOOR then
                    self.tDoors[ World.pathGrid:getCellAddr(adjX,adjY) ] = {x=adjX,y=adjY}
                    self:_setDoor(adjX,adjY,dir,true)
                elseif adjVal == World.logicalTiles.SPACE or World.isDestroyedWallAdjacentToSpace(adjX,adjY) then
                    -- MTF TODO: currently we just count breaches in pathable directions.
                    -- That can cause some weird behavior & layout, but is currently better than our
                    -- vacuum and pathfinding behavior otherwise.
                    if dir >=2 and dir <= 5 then
                        if not self.bBreach and self.bPotentiallyCombatBreached == true then
                            Base.eventOccurred(Base.EVENTS.Breach,{wx=wx,wy=wy})
                        end
                        if not self.bBreach then
                            if not self.bForceSim and self.nTeam ~= Character.TEAM_ID_PLAYER then
                                local tRooms = Room.getRoomsOfTeam(self.nTeam)
	                            for rAlliedRoom,_ in pairs(tRooms) do
                                    rAlliedRoom.bForceSim = true
                                end
                            end
                        end
                        self.bBreach = true
                        self.bForceSim = true
                        local bSpaceBreach = adjVal == World.logicalTiles.SPACE
                        if bSpaceBreach or not self.tBreaches[addr] then
                            --self.tBreaches[ World.pathGrid:getCellAddr(adjX,adjY) ] = {x=adjX,y=adjY,dirFromRoom=dir}
                            self.tBreaches[ addr ] = {roomX=coord.x,roomY=coord.y,spaceX=adjX,spaceY=adjY,spaceAddr=World.pathGrid:getCellAddr(adjX,adjY),dirFromRoom=dir,bSpaceBreach=bSpaceBreach}
                            if bSpaceBreach then
                                break
                            end
                        end
                    end
                end
            end
        --Profile.leaveScope("Room.setTilesA1")
        else
            self.tTiles[addr] = nil
        end
    end

    --Profile.leaveScope("Room.setTilesA")
    --Profile.enterScope("Room.setTilesB")
    --assert(self.nTiles > 0)
    if self.nTiles == 0 then return end

    self.nMidpointWX,self.nMidpointWY = xTotal/self.nTiles,yTotal/self.nTiles
    if Room.getRoomAt(self.nMidpointWX,self.nMidpointWY,0,1) == self then
        local tx, ty = World._getTileFromWorld(self.nMidpointWX,self.nMidpointWY)
        self.nCenterTileX,self.nCenterTileY = tx,ty
    else
        local nBestDist = 10000000
        local nBestTX,nBestTY = nil,nil
        for addr,coord in pairs(tTiles) do
            local wx,wy = World._getWorldFromTile(coord.x,coord.y)
            local nDist = DFMath.distance2DSquared(self.nMidpointWX,self.nMidpointWY, wx,wy)
            if nDist < nBestDist then
                nBestDist = nDist
                nBestTX,nBestTY = coord.x,coord.y
            end
        end
        self.nCenterTileX,self.nCenterTileY = nBestTX,nBestTY
        if not nBestTX then
            Print(TT_Warning, "Failed to get room midpoint. Picking randomly.")
            self.nCenterTileX,self.nCenterTileY = self:randomLocInRoom(true)
        end
    end
    --Profile.leaveScope("Room.setTilesB")
    --Profile.enterScope("Room.setTilesC")

    -- Compute some statistics about walls
    --   Count the number of walls
    --   Compute the set of border tiles (i.e. one tile extrusion of walls)
    local numWalls = 0
    for addr,wall in pairs(self.tWalls) do
        -- search for border tiles in all 9 compass directions
        for dir=2,9 do
            local borderX, borderY = World._getAdjacentTile(wall.x,wall.y,dir)
            local borderAddr = World.pathGrid:getCellAddr(borderX, borderY)
            if not self.tWalls[borderAddr] and not self.tTiles[borderAddr] and not self.tDoors[borderAddr] then
                -- store the directions from walls to border tile for use in
                -- computing the direction away from the wall/room
                if not self.tBorders[borderAddr] then
                    self.tBorders[borderAddr] = { x = borderX, y = borderY, tWallDirections = { World.getOppositeDirection(dir) }, nRoomDirection = World.directions.SAME }
                else
                    table.insert(self.tBorders[borderAddr].tWallDirections, World.getOppositeDirection(dir))
                end
            end
        end
        numWalls = numWalls+1
    end
    --Profile.leaveScope("Room.setTilesC")
    --Profile.enterScope("Room.setTilesD")

    -- Compute some statistics about borders
    --    Count the number of borders
    --    Compute the dominant direction from border to wall
    --    Compute the set of exterior tiles (border tiles that are SPACE)
    --    Compute whether a room is exterior or not
    local numBorders = 0
    local numExteriors = 0
    for addr,border in pairs(self.tBorders) do
        -- compute primary room direction by averaging all of the wall directions...
        local nAveDirX = 0
        local nAveDirY = 0
        for _,direction in ipairs(border.tWallDirections) do
            local vector = World.directionVectors[direction]
            nAveDirX = nAveDirX + vector[1]
            nAveDirY = nAveDirY + vector[2]
        end
        local nInvDirections = 1 / #border.tWallDirections
        nAveDirX, nAveDirY = DFMath.normalize(nAveDirX * nInvDirections, nAveDirY * nInvDirections)
        -- then compare the normalized average vector with the source direction vectors
        local nBestDistance = 1000000
        for direction,vector in pairs(World.directionVectors) do
            local nDistance = DFMath.distance2D( nAveDirX, nAveDirY, vector[1], vector[2] )
            if nDistance <= nBestDistance then
                border.nRoomDirection = direction
                nBestDistance = nDistance
            end
        end

        -- border tiles are exterior if they are space
        local borderValue = World.pathGrid:getTileValue(World.pathGrid:cellAddrToCoord(addr))
        if borderValue == World.logicalTiles.SPACE then
            self.tExteriors[addr] = self.tBorders[addr]
            numExteriors = numExteriors + 1
        end
        numBorders = numBorders+1
    end
    --Profile.leaveScope("Room.setTilesD")
    --Profile.enterScope("Room.setTilesE")
    --  room is exterior if >X% of border tiles are exterior
    local minExteriorFraction = 0.4
    self.bExterior = numExteriors / numBorders >= minExteriorFraction

    -- Compute the zone name/type for this room
    local zoneName = self.zoneName
    if not zoneName then
        for addr,_ in pairs(self.tTiles) do
            zoneName = World._zoneAtAddr(addr)
            if zoneName then
                break
            end
        end
    end
    if not zoneName then
        zoneName = 'PLAIN'
    end

    if self.zoneName ~= zoneName then
        self:setZone(zoneName, true)
    else
        for addr,_ in pairs(self.tTiles) do
            World._setZoneAtAddr(addr, self.zoneName)
        end
        if self.zoneObj then
            self.zoneObj:postTileUpdate()
        end
    end
    --Profile.leaveScope("Room.setTilesE")
    --Profile.enterScope("Room.setTilesF")

    --[[
    -- Print out some debug info for the room
    print('ROOM',self.id,'has',numWalls,'wall tiles')
    if self.bBreach then
        print(' and is breached')
    end

    if self.bExterior then
        print(' and is exterior')
    end
    --]]

    local tNew,tOld = MiscUtil.diffKeys(self.tProps,tPropList)
    for rProp,_ in pairs(tOld) do
        --self:removeProp(rProp)
        rProp:_updateRoomAssignment()
    end
    for rProp,_ in pairs(tNew) do
        --self:addProp(rProp)
        rProp:_updateRoomAssignment()
    end

    self:_retestPropPlacements()

    --Profile.leaveScope("Room.setTilesF")
    --Profile.enterScope("Room.setTilesG")
    self:updateEmergency()

    --Profile.leaveScope("Room.setTilesG")
    --Profile.enterScope("Room.setTilesH")
    -- Update the adjacency and finish
    self:_updateAdjoiningRooms()
    --Profile.leaveScope("Room.setTilesH")
    self.bJobsDirty = true
    Profile.leaveScope("Room.setTiles")
end

function Room:canClaim()
    if self:getTeam() ~= Character.TEAM_ID_PLAYER then
        return not self:hasHostiles()
    end
    return false
end

function Room:hasHostiles()
    for rChar,_ in pairs(self.tCharacters) do
        if rChar:isHostileToPlayer() and not rChar:isDead() and not rChar.tStatus.bCuffed and not Malady.isIncapacitated(rChar) then 
            return true 
        end
    end
    
    local rPC = CharacterManager.getPlayerCharacter()
    if not rPC then return false end

    for rProp,_ in pairs(self.tProps) do
        if rProp:isHostileTo(rPC) then
            return true
        end
    end
    return false
end

function Room:claim()
    self.nLastSeen = GameRules.elapsedTime
    self:_setTeam(Character.TEAM_ID_PLAYER)
end

function Room:unclaim()
    self.nLastSeen = GameRules.elapsedTime
    if not self.nOriginalTeam or self.nOriginalTeam == Character.TEAM_ID_PLAYER then
        self:_setTeam(Character.TEAM_ID_PLAYER_ABANDONED)
    else
        self:_setTeam(self.nOriginalTeam)
    end
end

function Room:setZone(zoneName, bNoUpdate)
    if zoneName ~= self.zoneName then
        if self.zoneObj then
            self.zoneObj:remove()
            self.zoneObj = nil
        end

        self.zoneName = zoneName

        for addr,_ in pairs(self.tTiles) do
            World._setZoneAtAddr(addr, zoneName)
        end

        local sClass = Zone[self.zoneName].class
        if sClass then
            self.zoneObj = require(sClass).new(self)
        else
            self.zoneObj = Zone.new(self)
        end
        self.bJobsDirty = true
        self.uniqueZoneName = Zone.getUniqueZoneName(self.zoneName)

        --set portrait for the inspector
        if Zone[self.zoneName].portrait then
            self.sPortrait = Zone[self.zoneName].portrait
        else
            self.sPortrait = 'portrait_generic'
        end
        self.sPortraitPath = 'UI/Portraits'

        self:_retestPropPlacements()
        --[[
        if not bNoUpdate then
            World.fixupVisuals()
        end
        ]]--
    end
end

function Room:getSize()
    local i = 0
    -- this is so dumb
    for _ in pairs(self.tTiles) do i = i + 1 end
    return i
end

function Room:addProp(rProp)
    if self.tProps[rProp] then return end

    self.tProps[rProp] = 1
    local sKey = rProp.sFunctionality or rProp.sName
    if not self.tPropsByFunctionality[sKey] then
        self.tPropsByFunctionality[sKey] = {}
        self.nPropsByFunctionality[sKey] = 0
    end
    self.tPropsByFunctionality[sKey][rProp] = 1
    self.nPropsByFunctionality[sKey] = self.nPropsByFunctionality[sKey] + 1

    self.nProps = self.nProps+1
    rProp.rRoom = self
    self:_retestPropPlacements()
    --World.modifyPropGrid(rProp.wx,rProp.wy,rProp.sName,self.id)
    self.bJobsDirty = true
    if self.zonePropCallback then self.zonePropCallback(self.rZone, rProp, false) end
    rProp:onAddedToRoom(self)
end

function Room:getProps()
    return self.tProps
end

-- Actually returns props of a certain "functionality", which is typically the name but is overridden by sFunctionality in EnvObjectData.
-- return: {rProp=1,rProp=1, ...}
function Room:getPropsOfName(sName)
    if self.tPropsByFunctionality[sName] then
        return self.tPropsByFunctionality[sName],self.nPropsByFunctionality[sName]
    end
    return {},0
end

function Room:getRandomAttackableObject()
	local tObjects = {}
	for rProp,_ in pairs(self.tProps) do
		-- "attackable" = can be damaged and is currently functioning
		if not rProp:isDoor() and rProp.bAttackable and rProp.tData.decayPerSecond and rProp:isFunctioning() then
			table.insert(tObjects, rProp)
		end
	end
	if #tObjects > 0 then
		return MiscUtil.randomValue(tObjects)
	end
end

function Room:_destroy()
    self:_updateSound(true)
    self:clearPowerVisLines()
	for id,rPowerRoom in pairs(Room.tPowerZones) do
		if rPowerRoom.zoneObj:isPowering(self) then
			rPowerRoom.zoneObj:powerUnrequest(self)
		end
    end
    Room.tPowerZones[self.id] = nil

    if self.zoneObj and self.zoneObj._destroy then self.zoneObj:_destroy() end
	self.bDestroyed = true
    Room.tRooms[self.id] = nil
    ObjectList.removeObject(self.tag)
    self.tag=nil
    self.tPowerLeeches = nil
    self:_clearWalls()
    self:_clearAdjoiningRooms()
    --self:_clearOldReservations()
    self:_clearOldGhosts()
    if self.rClaimFlag then
        local r = Renderer.getRenderLayer('WorldWall')
        if r then
            r:removeProp(self.rClaimFlag)
        end
        self.rClaimFlag = nil
    end
end

function Room:removeProp(rProp)
    rProp.rRoom = nil
    if not self.tProps[rProp] then
        Print(TT_Error, "Prop incorrectly removing itself from a room that does not own it.")
        return
    end
    self.tProps[rProp] = nil
    local sKey = rProp.sFunctionality or rProp.sName
    if self.tPropsByFunctionality[sKey][rProp] then
        self.tPropsByFunctionality[sKey][rProp] = nil
        self.nPropsByFunctionality[sKey] = self.nPropsByFunctionality[sKey] - 1
    end
    self.nProps = self.nProps-1
    if self.zonePropCallback then self.zonePropCallback(self.rZone, rProp, true) end
    --World.modifyPropGrid(rProp.wx,rProp.wy,rProp.sName,0)
    self.bJobsDirty = true
end

function Room:tileVaporized(tileX,tileY)
end

function Room:getExtinguishTargets(rChar, ao)
    local tTiles = {}
    for addr,_ in pairs(self.tTiles) do
        if Fire.tTiles[addr] then
            local wx,wy = World._getWorldFromAddr(addr)
            --table.insert(tTiles, {x=wx,y=wy})
            tTiles[addr] = {x=wx,y=wy,addr=addr}
        end
    end
    return tTiles
end

function Room:addFireExtinguisher()
    self.bFireUpgrade = true
    self.bJobsDirty = true
end

function Room:inside(wx,wy,wz,nLevel)
    local r = Room.getRoomAt(wx,wy,wz,nLevel)
    if r then
        return r == self
    else
        local tx, ty = World._getTileFromWorld(wx,wy)
        local tileAddr = World.roomGrid:getCellAddr(tx,ty)
        return self.tDoors[tileAddr]
    end
end

function Room:inOrAdjoining(wx,wy,wz,nLevel, bOnlyByDoor)
    local r = Room.getRoomAt(wx,wy,wz,nLevel)
    if r == self then
        return true
    end

    local tAdjoining
    if bOnlyByDoor then
        tAdjoining = self:getAccessibleByDoor()
    else
        tAdjoining = self:getAdjoiningRooms()
    end
    for adjoining,_ in pairs(tAdjoining) do
        if adjoining == r then
            return true
        end
    end

    return false
end

function Room:hasObjectOfType(sObjectType)
	for prop,_ in pairs(self:getProps()) do
		if prop.sName == sObjectType then
			return true
		end
	end
	return false
end

function Room:utilityGateTool(rChar)
	if self.bBurning then
        if self:hasObjectOfType('FirePanel') or rChar:getJob() == Character.EMERGENCY then
            local wx,wy,wz,nLevel = rChar:getLoc()
            if self:inOrAdjoining(wx,wy,wz,nLevel,true) then
                return true
            end
            return 'not in or next to room'
        end
        return false,'no fire upgrade'
    end
    return false, 'not on fire'
end

function Room:utilityGateHands(rChar)
	if self.bBurning then
        if not self.bFireUpgrade then
            local wx,wy,wz,nLevel = rChar:getLoc()
            if self:inOrAdjoining(wx,wy,wz,nLevel,true) then
                return true
            end
            return 'not in or next to room'
        end
        return false,'fire upgrade'
    end
    return false, 'not on fire'
end

function Room:utilityGatePanic(rChar)
	return self.bBurning and rChar.nThreat == OptionData.tPriorities.SURVIVAL_NORMAL and self:inside(rChar:getLoc()), 'no nearby fire seen'
end

function Room:utilityGateFlee(rChar)
	return (self.bBurning or self.bPendingBreach) and rChar.nThreat == OptionData.tPriorities.SURVIVAL_NORMAL and self:inside(rChar:getLoc()), 'no nearby hazard seen'
end

function Room:_addPersistentActivityOptions()
    local tData

    tData = {bFireTask=true, targetTileListFn=function(rChar) return self:getExtinguishTargets(rChar) end, utilityGateFn=function(rChar) return self:utilityGateTool(rChar) end, pathToNearest=true}
    self.aoExtinguishWithTool = ActivityOption.new('ExtinguishFireWithTool', tData)

    tData = {bFireTask=true, targetTileListFn=function(rChar) return self:getExtinguishTargets(rChar) end, utilityGateFn=function(rChar) return self:utilityGateHands(rChar) end, pathToNearest=true}
    self.aoExtinguishBareHanded = ActivityOption.new('ExtinguishFireBareHanded', tData)

    tData = {bInfinite=true, utilityGateFn=function(rChar) return self:utilityGatePanic(rChar) end, }
    self.aoPanicFire = ActivityOption.new('PanicFire', tData)

    tData = {bInfinite=true, utilityGateFn=function(rChar) return self:utilityGateFlee(rChar) end,
        targetLocationFn=function(rChar,rAO) return rChar:getFleeLocation('FireFleeArea') end,
        bPanic=true,
    }
    self.aoLeaveRoomFire = ActivityOption.new('FireFleeArea', tData)

    self.fireActivityOptionList:addOption(self.aoExtinguishWithTool,true)
    self.fireActivityOptionList:addOption(self.aoExtinguishBareHanded,true)
    self.fireActivityOptionList:addOption(self.aoPanicFire,true)
    self.fireActivityOptionList:addOption(self.aoLeaveRoomFire,true)

    tData = {
        targetLocationFn=function(rChar,rAO)
            return self:randomLocInRoom(false,true,false)
        end,
        utilityGateFn=function(rChar,rAO)
            if self.nLastVisibility ~= World.VISIBILITY_FULL then return false, 'not visible' end
            if rChar:getRoom() == self then return false, 'already there' end
            if self.nFireTiles > 0 then return false,'on fire' end
            if self.bBreach then return false,'breached' end
            if not self.zoneObj:isFunctionalAirlock() then
                if self:getOxygenScore() < Character.OXYGEN_SUFFOCATING then return false, 'low o2' end
            end
            return true
        end,
        utilityOverrideFn=function(rChar,rAO,nOriginalUtility)
            local nMult = 10 + self:getRoomScore(rChar)
            return nOriginalUtility * .1 * nMult
        end,
        priorityOverrideFn=function(rChar,rAO,nOriginalPri)
            if rChar.tStatus.bLowOxygen and rChar:spacewalking() and self.zoneObj:isFunctionalAirlock() then
                return OptionData.tPriorities.SURVIVAL_NORMAL
            end
            return nOriginalPri
        end,
        bInfinite=true,
    }
    self.rWalkHereOption = ActivityOption.new('GoInsideStandalone', tData)
end

function Room:getPropBuildPriority(rChar,nOriginalPri,propName)
    if propName == 'OxygenRecycler' or propName == 'OxygenRecyclerLevel2' then
        -- Missing o2 cyclers return the character's current threat level as priority, in case the low o2 is
        -- the thing causing high threat.
        if self:getOxygenScore() < Character.OXYGEN_LOW then
            return rChar.nThreat
        end
    end
    return nOriginalPri
end

function Room:_getPropBuildUtilityOverride(rChar,rAO,nScore,propName)
    if propName == 'OxygenRecycler' or propName == 'OxygenRecyclerLevel2' then
        -- Missing o2 cyclers return the character's current threat level as priority, in case the low o2 is
        -- the thing causing high threat.
        if self:getOxygenScore() < Character.OXYGEN_LOW then
            return 205
        end
    end
    return nScore
end

function Room:_refreshPropJobList()
    local tOptions = {}
    self:_retestPropPlacements()
    for addr,tData in pairs(self.tPropPlacements) do
        local wx,wy = World._getWorldFromTile(tData.tx,tData.ty)
        local tData = {
			propName=tData.sName,
			bFlipX = tData.bFlipX,
			bFlipY = tData.bFlipY,
			pathX=wx, pathY=wy,
			pathToNearest=true,
            utilityGateFn=function(rChar) return EnvObject.gateJobActivity(tData.sName, rChar, true) end,
            priorityOverrideFn=function(rChar,rAO,nOriginalPri) return self:getPropBuildPriority(rChar,nOriginalPri,tData.sName) end,
            utilityOverrideFn=function(rChar, rAO, nScore) return self:_getPropBuildUtilityOverride(rChar,rAO,nScore,tData.sName) end
        }
        local rOption = ActivityOption.new('BuildEnvObject',tData)
        table.insert(tOptions,rOption)
    end
    table.insert(tOptions,self.rWalkHereOption)
    self.activityOptionList:set(tOptions)
    self.bJobsDirty=false
end

function Room:getSaveTable(xShift,yShift)
    assert(not self.bDestroyed)
    assert(Room.tRooms[self.id])
    xShift = xShift or 0
    yShift = yShift or 0
    -- Hmm, this first pass didn't work with modules.
    --[[
    local tProps = {}
    for rProp,_ in pairs(tProps) do
        table.insert(tProps, rProp.id)
    end
    return { id=self.id, tTiles = DFUtil.deepCopy(self.tTiles), tProps=tProps }
    ]]--
    local tTiles = {}
    for addr,coord in pairs(self.tTiles) do
        local wx,wy = World._getWorldFromTile(coord.x,coord.y)
        table.insert(tTiles, {x=wx+xShift,y=wy+yShift})
    end

    local tPropPlacements = {}
    for addr,tData in pairs(self.tPropPlacements) do
        tPropPlacements[addr] = {}
        tPropPlacements[addr].sName=tData.sName
        tPropPlacements[addr].bFlipX=tData.bFlipX or tData.bFlipped
        tPropPlacements[addr].bFlipY=tData.bFlipY
        tPropPlacements[addr].tx=tData.tx
        tPropPlacements[addr].ty=tData.ty
    end

    local tZone = nil
    if self.zoneObj and self.zoneObj.getSaveTable then
        tZone = self.zoneObj:getSaveTable(xShift,yShift)
    end

    if next(tTiles) then
        return { tTiles = tTiles, bFireUpgrade=self.bFireUpgrade, uniqueZoneName=self.uniqueZoneName, bUserBlockOxygen=self.bUserBlockOxygen, 
                    nTeam=self.nTeam, nOriginalTeam=self.nOriginalTeam,
                    tPropPlacements=tPropPlacements, tZone=tZone,
                    nLastSeen=self.nLastSeen, id=self.id,
                    nLastCombatAlert=self.nLastCombatAlert,
                    --nOwnershipDuration=self.nOwnershipDuration
                    bEmergencyAlarmEnabled=self.bEmergencyAlarmEnabled,
                }
    end
end

function Room.fromSaveTable(t, xOff, yOff,nTeam)
    if g_World.bLoadingModule and t.bSpaceRoom then
        return nil
    end

    xOff = xOff or 0
    yOff = yOff or 0

    local sWarning = nil
    local tTiles = {}
    -- move all of the saved tiles over according to the offset.
    for _,pos in ipairs(t.tTiles) do
        local wx,wy = pos.x,pos.y
        wx,wy = wx+xOff,wy+yOff
        local tx, ty = World._getTileFromWorld(wx,wy)
        local tileValue = World._getTileValue(tx,ty)
        if not World.countsAsFloor(tileValue) then
            sWarning = "Non-floor tile saved as room tile."
        else
            local tileAddr = World.roomGrid:getCellAddr(tx,ty)
            if tx >= 1 and ty >= 1 and tx <= g_World.width and ty <= g_World.height then
                tTiles[tileAddr] = {x=tx,y=ty}
                Room.tDirtyTiles[tileAddr] = true
            end
        end
    end
    -- some saves had empty rooms; ignore them.
    if next(tTiles) or t.bSpaceRoom then
		local rNewRoom
		if t.bSpaceRoom then
            -- if this is spaceroom, only bother with prop placements
            -- We still need to recreate the room from savedata.
            
            if g_SpaceRoom then
                assertdev(false)
                g_SpaceRoom:_destroy()
                g_SpaceRoom = nil
            end
            require('SpaceRoom').new(t)
			rNewRoom = g_SpaceRoom
		else
            local newID = Room.nextRoomID
            if t.id and not World.loadingModule then
                if Room.tRooms[t.id] then
                    Print(TT_Warning, 'Room id conflict: '..newID)
                else
                    newID = t.id 
                end
            end
			rNewRoom = Room.new(newID, tTiles, t)
            
            -- If the new room fails to construct, ditch it.
            if rNewRoom.nTiles == 0 then rNewRoom = nil end
            
            if rNewRoom then
                Room.tRooms[newID] = rNewRoom
                if nTeam then
                    rNewRoom.nTeam = nTeam
                    rNewRoom.nOriginalTeam = nTeam
                else
                    rNewRoom.nTeam = t.nTeam or Character.TEAM_ID_PLAYER
                    rNewRoom.nOriginalTeam = t.nOriginalTeam or Room.tRooms[newID].nTeam
                end
                if rNewRoom.nTeam >= Base.nNextTeamID then
                    Base.nNextTeamID = rNewRoom.nTeam+1
                end
                --rNewRoom.nOwnershipDuration = t.nOwnershipDuration
                rNewRoom.bFireUpgrade = t.bFireUpgrade
                rNewRoom.uniqueZoneName = t.uniqueZoneName
                rNewRoom.nLastSeen = t.nLastSeen

                if t.tZone then
                    rNewRoom.zoneObj:initFromSaveTable(t.tZone)
                end

                if t.bUserBlockOxygen then rNewRoom:setLockdown(t.bUserBlockOxygen) end
            end
		end

        if rNewRoom then
            if t.tPropPlacements then
                for addr,tData in pairs(t.tPropPlacements) do
                    -- some savegames were missing cost data; reinstate it here.
                    local nCost = tData.nCost
                    if nCost == nil then
                        local eod = EnvObject.getObjectData(tData.sName)
                        if eod then
                            nCost = EnvObject.getObjectData(tData.sName).matterCost or 0
                        else
                            Print(TT_Error, "Missing object data for "..tostring(tData.sName))
                        end
                    end
                    if nCost ~= nil then
                        rNewRoom:_addPropGhostAt(tData.sName,tData.tx,tData.ty,tData.bFlipX,tData.bFlipY,nCost)
                    end
                end
            end

            rNewRoom:tickVisibility()
            rNewRoom:updateEmergency()
            while Room.tRooms[Room.nextRoomID] do
                Room.nextRoomID = Room.nextRoomID + 1
            end
        end
    elseif not sWarning then
        sWarning = "Saved out empty room"
    end

    if sWarning then
        Print(TT_Warning, "Loading room:"..(t.uniqueZoneName or 'nil zone name')..": "..sWarning)
    end
end

function Room:_clearOldGhosts()
    for addr,tData in pairs(self.tPropPlacements) do
        self:removePropGhostAt(tData.tx,tData.ty)
    end
end

function Room:_setTeam(nTeam)
    if self.nTeam ~= nTeam then
        self.nTeam = nTeam
        return true
    end
end

function Room:getTeam()
    return self.nTeam
end

function Room:getToolTipOxygenText()
    local s = ""
    if DFOxygenGrid.OXYGEN_TILE_MAX > 0 and self.nTiles > 0 then
        local _, nTotalOxygen = self:getOxygenScore()
        local sOxygenLabel = g_LM.line('INSPEC059TEXT')
        local nOxygenPct = self:getOxygenPct()
        s = string.format('%s %i%%', sOxygenLabel, nOxygenPct)
    end
    return s
end

function Room:getOxygenPct()
    if DFOxygenGrid.OXYGEN_TILE_MAX > 0 and self.nTiles > 0 then
        local _, nTotalOxygen = self:getOxygenScore()
        local nOxygenPct = (nTotalOxygen / (DFOxygenGrid.OXYGEN_TILE_MAX * self.nTiles)) * 100
        return nOxygenPct
    end
end

function Room:isEmergencyAlarmOn()
    return self.bEmergencyAlarmEnabled
end

function Room:setEmergencyAlarmOn(bOn)
    self.bEmergencyAlarmEnabled = bOn
end

function Room:hasFunctioningEmergencyAlarm()
    for rProp,_ in pairs(self:getProps()) do
        if rProp.sName == 'EmergencyAlarm' and rProp:isFunctioning() then
            return true
        end
    end    
    return false
end

function Room:onEmergencyAlarmDestroyed()
    -- check to see if we have any remaining
    if self.bEmergencyAlarmEnabled and not self:hasFunctioningEmergencyAlarm() then
        self.bEmergencyAlarmEnabled = false
    end
end

function Room:getToolTipTextInfos()
	-- reset tooltip lines
	self.tToolTipTextInfos = {}
	self.tToolTipTextInfos[1] = {}
	self.tToolTipTextInfos[2] = {}
	self.tToolTipTextInfos[3] = {}
	self.tToolTipTextInfos[4] = {}
	local nCurrentIndex = 1
    self.tToolTipTextInfos[nCurrentIndex].sString = self.uniqueZoneName
	nCurrentIndex = nCurrentIndex + 1
	-- object placement mode: custom tooltip shows auto-zone intent where appropriate
	if GameRules.currentMode == GameRules.MODE_PLACE_PROP then
		local tObjectData = EnvObject.getObjectData(GameRules.currentModeParam)
		if self:getZoneName() == 'PLAIN' and tObjectData.zoneName then
			-- line 1: "Place [Object Name]:"
			local s = g_LM.line('UIMISC038TEXT') .. ' '
			s = s .. g_LM.line(tObjectData.friendlyNameLinecode) .. ':'
			self.tToolTipTextInfos[1].sString = s
			-- line 2: "Auto-Zone room as [Object Zone]"
			s = g_LM.line('UIMISC039TEXT') .. ' '
			s = s .. g_LM.line(Zone.tZoneTypeLCs[tObjectData.zoneName])
			self.tToolTipTextInfos[2].sString = s
			return self.tToolTipTextInfos
		end
	-- beacon: show action on room and response level
	elseif GameRules.currentMode == GameRules.MODE_BEACON then
		local s = g_LM.line('UIMISC031TEXT')
		local sTypeLC = g_ERBeacon.tBeaconTypeLinecodes[g_ERBeacon.eViolence]
		s = s .. ' (' .. g_LM.line(sTypeLC) .. ')'
		self.tToolTipTextInfos[nCurrentIndex].sString = s
		-- no icon
        self.tToolTipTextInfos[nCurrentIndex].sTexture = nil
		nCurrentIndex = nCurrentIndex + 1
	-- "click to zone" line if unzoned
    elseif self:getZoneName() == 'PLAIN' then
        self.tToolTipTextInfos[nCurrentIndex].sString = g_LM.line('UIMISC015TEXT')
		nCurrentIndex = nCurrentIndex + 1
	end
	-- oxygen
    -- color red if oxygen at crit levels
    local nOxygenPct = self:getOxygenPct()
    local tColor = Gui.AMBER
    if nOxygenPct <= 25 then
        tColor = Gui.RED
    else
        tColor = Gui.AMBER
    end
	self.tToolTipTextInfos[nCurrentIndex].sString = self:getToolTipOxygenText()
	self.tToolTipTextInfos[nCurrentIndex].tColor = tColor
	if self.tToolTipTextInfos[nCurrentIndex].sString ~= "" then
		self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_bulletpoint'
		self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
		self.tToolTipTextInfos[nCurrentIndex].tTextureColor = tColor
	end
	-- show lab zone's current research project
	if self:getZoneName() == 'RESEARCH' and self.zoneObj.sCurrentResearch then
		nCurrentIndex = nCurrentIndex + 1
        -- begin changes for mod HoverResearchLabShowsProgress (2/2)
        local sProjectName = self.zoneObj.sCurrentResearch
        local sProject = Base.getResearchName(sProjectName)
        local nTotalNeeded, nProgress
        if Malady.tS.tResearch[sProjectName] then
            nTotalNeeded = Malady.tS.tResearch[sProjectName].nResearchCure
            nProgress = Malady.tS.tResearch[sProjectName].nCureProgress
        else
            nTotalNeeded = ResearchData[sProjectName].nResearchUnits
            nProgress = (Base.tS.tResearch[sProjectName] and Base.tS.tResearch[sProjectName].nResearchUnits) or 0
        end
        if nTotalNeeded then
            local nPercentage = math.floor(100 * nProgress / nTotalNeeded)
            self.tToolTipTextInfos[nCurrentIndex].sString = g_LM.line('UIMISC028TEXT') .. ' ' .. sProject .. ' (' .. tostring(nPercentage) .. '%)'
        else
            self.tToolTipTextInfos[nCurrentIndex].sString = g_LM.line('UIMISC028TEXT') .. ' ' .. sProject
        end
        self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_bulletpoint'
        self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
        -- end changes for mod HoverResearchLabShowsProgress (2/2)
	elseif self:getZoneName() == 'RESIDENCE' or self:getZoneName() == 'BRIG' then
		-- residences/brigs: show X/Y bed capacity
        if self.zoneObj.getAssignmentSlots then
            local tBeds,nBeds = self.zoneObj:getAssignmentSlots()
            if nBeds > 0 then
                local sString
                nCurrentIndex = nCurrentIndex + 1
                sString = g_LM.line('INSPEC191TEXT')
                sString = string.format('%s %s/%s', sString, #tBeds, nBeds)
                self.tToolTipTextInfos[nCurrentIndex].sString = sString
                self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_bulletpoint'
                self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
            end
        end
	end

	-- show power draw/output, if applicable
	if self.nPowerDraw > 0 or self:canProvidePower() then
		nCurrentIndex = nCurrentIndex + 1
		self.tToolTipTextInfos[nCurrentIndex].sTexture = 'ui_icon_bulletpoint'
		self.tToolTipTextInfos[nCurrentIndex].sTextureSpriteSheet = 'UI/Inspector'
		local sLabel,sPowerX,sPowerY
		local nPowerOutput = (self.zoneObj and self.zoneObj:getPowerOutput()) or 0
		if nPowerOutput > self.nPowerDraw then
			sLabel = g_LM.line('INSPEC165TEXT')
			-- get power consumed vs provided
			local nTotalRequest = 0
			local nTotalGrant = 0
			for _,rProp in ipairs(self.zoneObj.tOrderedThingsPowered) do
				local tPowerInfo = self.zoneObj.tThingsPowered[rProp]
				if rProp:getPowerDraw() > 0 then
					nTotalRequest = nTotalRequest + tPowerInfo.nPowerRequested
					nTotalGrant = nTotalGrant + tPowerInfo.nPowerGranted
				end
			end
			sPowerX = tostring(nTotalGrant)
			sPowerY = tostring(nPowerOutput)
			-- if power consumed < power provided, green
			if nTotalGrant < nPowerOutput then
				tColor = Gui.GREEN
			elseif nTotalGrant > nPowerOutput then
				tColor = Gui.RED
			end
		else
			-- power draw as X/Y
			sLabel = g_LM.line('INSPEC164TEXT')
			sPowerX = tostring(self.nPowerSupplied)
			sPowerY = tostring(self.nPowerDraw)
			if self.nPowerSupplied < self.nPowerDraw then
				tColor = Gui.RED
			end
		end
		local sString = string.format('%s %s/%s %s', sLabel, sPowerX, sPowerY, g_LM.line('INSPEC166TEXT'))
		self.tToolTipTextInfos[nCurrentIndex].sString = sString
		self.tToolTipTextInfos[nCurrentIndex].tColor = tColor
	end
    return self.tToolTipTextInfos
end

function Room.updateSavegame(nSavegameVersion, saveData)
end

return Room
