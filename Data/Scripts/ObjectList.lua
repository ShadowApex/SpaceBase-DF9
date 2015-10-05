local DFUtil = require('DFCommon.Util')
local Delegate = require('DFMoai.Delegate')
local World = nil
local EnvObjectData=nil
local Room=nil
local EnvObject=nil
local WorldObject=nil
local CharacterManager=nil

local ObjectList = 
{
    CHARACTER = "Character",
    ENVOBJECT = "EnvObject",
    ROOM = "Room",
    RESERVATION = "Reservation",
    WORLDOBJECT = "WorldObject",
    INVENTORYITEM = "INVENTORYITEM",
    objectCounter=1,
    --tObjList={},
    --tIDsAtAddr={},
}

local tagMT = {
    __eq = function (lhs, rhs)
        return lhs.objID == rhs.objID
    end,
}

ObjectList.tSaveTypes={ObjectList.ROOM, ObjectList.ENVOBJECT, ObjectList.CHARACTER, ObjectList.RESERVATION, ObjectList.WORLDOBJECT, ObjectList.INVENTORYITEM}

-- Is a table a tag? iff it has _ObjectList_TagMarker = true
-- Is a table an object? iff it has _ObjectList_ObjectMarker = true
function ObjectList.isTag(tag)
    return tag and tag._ObjectList_TagMarker and not tag.bInvalid
end

function ObjectList.isValidObject(obj)
    return obj and ObjectList.isTag(obj._ObjectList_ObjectMarker)
end

function ObjectList.getTag(rObject)
    if rObject and ObjectList.isTag(rObject._ObjectList_ObjectMarker) then
        return rObject._ObjectList_ObjectMarker
    end
end

function ObjectList.getObject(tag)
    if not ObjectList.isTag(tag) or not ObjectList.tObjList[tag.objID] then return nil end
    return ObjectList.tObjList[tag.objID].obj
end

function ObjectList.getTagSaveData(tag)
    if ObjectList.isTag(tag) then
        return tag
    end
end

function ObjectList.reserveTag(tagSaveData)
    if tagSaveData.bInvalid then return end
    
    local id = tagSaveData.objID
    assertdev(not ObjectList.tObjList[id])
    ObjectList.tReservedTags[id] = tagSaveData
    ObjectList.objectCounter = math.max(ObjectList.objectCounter, id+1)
end

-- tag:
--  obj: object ref
--  objType: Character,EnvObject,Room,Reservation
--  objID: unique ID
--  objSubtype: 'Door','Airlock', etc.
--  tSaveData: pass in if creating an object from a savegame. Will maintain its objID so that old handles to it work.
--  bFlipX: special-case to props
--  addr: primary tile loc
--  tTiles: list of other tiles occupied
--  bBlocksPathing: yup
--  bBlocksOxygen: yup
function ObjectList.addObject(objType, objSubtype, obj, tSaveData, bBlocksPathing, bBlocksOxygen, wx,wy, bFlipX, bFlipY)
    local objID, tag

    if ObjectList._bLoading and ObjectList.tReservedTags and tSaveData and tSaveData._ObjectList_ObjectMarker then
        objID = tSaveData._ObjectList_ObjectMarker.objID
        if not ObjectList.tReservedTags[objID] then
            assertdev(require('GameRules').inEditMode)
        else
            tag = ObjectList.tReservedTags[objID]
            ObjectList.tReservedTags[objID] = nil
        end
    end
    
    if not objID then
        while ObjectList.tObjList[ObjectList.objectCounter] or (ObjectList.tReservedTags and ObjectList.tReservedTags[ObjectList.objectCounter]) do
            ObjectList.objectCounter = ObjectList.objectCounter+1
        end
        objID = ObjectList.objectCounter
    end
    
    if not tag then
        tag = {objType=objType, objSubtype=objSubtype, objID=objID, bBlocksPathing=bBlocksPathing,bBlocksOxygen=bBlocksOxygen,_ObjectList_TagMarker=true}
        setmetatable(tag,tagMT)
    else
        assertdev(tag.objType == objType)
        assertdev(tag.objSubtype == objSubtype or (not objSubtype and objType == ObjectList.ROOM) or not tag.objSubtype)
        tag.objType = objType
        tag.objSubtype = objSubtype
        tag.bBlocksOxygen = bBlocksOxygen
        tag.bBlocksPathing = bBlocksPathing
        tag._ObjectList_TagMarker=true
        tag.addr = nil
    end
    tag.tTiles={}
    local objData = {tag=tag,obj=obj}

    ObjectList.tObjList[objID] = objData
    
    ObjectList.tObjByType[objType][objID] = objData
    ObjectList.tCountByType[objType] = ObjectList.tCountByType[objType] + 1
    if wx then
        ObjectList.occupySpace(wx,wy,tag,bFlipX,bFlipY)
    end
    if objType == ObjectList.RESERVATION then
        assertdev(tag.addr)
        assertdev(next(tag.tTiles))
    end
    obj._ObjectList_ObjectMarker = tag

    return tag
end

function ObjectList.loadFromSaveTable(objType,t,xOff,yOff,nTeam)
    local o = nil
    
    if objType == ObjectList.CHARACTER then
        o = CharacterManager.loadCharacter( t, xOff, yOff,nTeam )
    elseif objType == ObjectList.ENVOBJECT then
        o = EnvObject.fromSaveTable(t, xOff, yOff,nTeam)
    elseif objType == ObjectList.ROOM then
        o = Room.fromSaveTable(t, xOff, yOff,nTeam)
    elseif objType == ObjectList.RESERVATION then
        -- NOT SAVED/LOADED 
    elseif objType == ObjectList.WORLDOBJECT then
        o = WorldObject.fromSaveTable(t, xOff, yOff,nTeam)
    elseif objType == ObjectList.INVENTORYITEM then
        -- NOT SAVED/LOADED
    else
        assert(false)
    end

    return o
end

function ObjectList.convertObjectTagsForSave(tSaveData)
end

function _isStaleTag(t)
    if type(t) == 'table' and t._ObjectList_TagMarker then
        if not ObjectList.isTag(t) then
            return true 
        end
        local o = ObjectList.getObject(t)
        if not o or o._ObjectList_ObjectMarker.objType ~= t.objType or o._ObjectList_ObjectMarker.objSubtype ~= t.objSubtype then
            return true
        end
    end
    return false
end

-- DEBUG: not actually necessary.
-- Just doing it for now to make it easier to identify savegame bugs.
function ObjectList.removeStaleTags(tSaveData)
    for k,v in pairs(tSaveData) do
        if _isStaleTag(k) or _isStaleTag(v) then 
            tSaveData[k] = nil
        else
            local bObj = false
            
            if type(k) == 'table' then ObjectList.removeStaleTags(k) end
            if type(v) == 'table' then 
                bObj = v._ObjectList_ObjectMarker ~= nil
                ObjectList.removeStaleTags(v)
                if bObj and v._ObjectList_ObjectMarker == nil then
                    -- v was an object but it got nuked.
                    -- Should never actually happen.
                    assertdev(false)
                    tSaveData[k] = nil
                end
            end
            
        end
    end
end

function ObjectList.portOldSavegames(tSaveData,nSavegameVersion)
    if nSavegameVersion < 7 then
        local tTags={}
        ObjectList._portOldTags(tSaveData,tTags)
    end
    return tSaveData
end

function _portTag(v,tTags)
    if v.bInvalid then return end
    
    local objID --,tag
    if v.objType and v.objID then
        v._ObjectList_TagMarker=true
        objID = v.objID
    end
    if v._ObjectListTag then
        v._ObjectList_ObjectMarker = v._ObjectListTag
        v.bTesting = true
        --objID = v._ObjectList_ObjectMarker.objID
        --tag = v._ObjectListTag
        v._ObjectListTag = nil
        _portTag(v._ObjectList_ObjectMarker,tTags)
    end
    
    if objID then
        if tTags[objID] then
            local nID = objID
            local tTag = tTags[nID]
            while tTag and (tTag.objType ~= v.objType or tTag.objSubtype ~= v.objSubtype or tTag.addr ~= v.addr or v.bFlipX ~= tTag.bFlipX or v.bFlipY ~= tTag.bFlipY) do
                nID = nID+10000
                tTag = tTags[nID]
            end
            tTags[nID] = v
            if v._ObjectList_ObjectMarker then v._ObjectList_ObjectMarker.objID = nID end
            if v._ObjectList_TagMarker then v.objID = nID end
        else
            tTags[objID] = v
        end
    end
end

function ObjectList._portOldTags(tSaveData,tTags)
    for k,v in pairs(tSaveData) do
        if type(k) == 'table' then
            _portTag(k,tTags)
            ObjectList._portOldTags(k,tTags)
        end
        if type(v) == 'table' then
            _portTag(v,tTags)
            ObjectList._portOldTags(v,tTags)
        end
    end
end

function ObjectList.beginLoad(tSaveData,bIsModule)
    ObjectList._bLoading = true
    local nTagOffset = nil
    ObjectList.tReservedTags = {}
    if bIsModule then
        nTagOffset = ObjectList.objectCounter+1
    end
    ObjectList._generateNewObjectTagsForModuleLoad(tSaveData,nTagOffset, {})
end

function ObjectList.endLoad()
    ObjectList._bLoading = false
    
    if ObjectList.tReservedTags then
        for k,v in pairs(ObjectList.tReservedTags) do
            local tTag = v
            Print(TT_Warning, "OBJECTLIST.LUA: Not all reserved tags claimed: "..tTag.objType..','..(tTag.objSubtype or ''))
        end
        ObjectList.tReservedTags = nil
    end
    
    for objID,objData in pairs(ObjectList.tObjList) do
        if objData.obj.postLoad then
            objData.obj:postLoad()
        end
    end
end

function _adjustTag(v,nTagOffset,tProcessedTags)
    local foundTag = nil
            if v._ObjectList_TagMarker then
                -- This table is a tag.
                if nTagOffset then
                    v.objID = v.objID+nTagOffset
                end
                if tProcessedTags[v.objID] then
                    foundTag = tProcessedTags[v.objID]
                else
                    tProcessedTags[v.objID] = v
                    setmetatable(v,tagMT)
                    ObjectList.reserveTag(v)
                end
            else
                ObjectList._generateNewObjectTagsForModuleLoad(v, nTagOffset, tProcessedTags)
                if v._ObjectList_ObjectMarker and not v._ObjectList_ObjectMarker.bInvalid then
                    if ObjectList.tObjList[v._ObjectList_ObjectMarker.objID] then
                        -- Two objects with same ID, or two copies of same object.
                        -- Can happen in some buggy saves.
                        Print(TT_Warning, "OBJECTLIST.LUA: Object collision: "..v._ObjectList_ObjectMarker.objID..', '..tostring(v._ObjectList_ObjectMarker.objType)..', '..tostring(v._ObjectList_ObjectMarker.objSubtype))
                        
                        if ObjectList.tObjList[v._ObjectList_ObjectMarker.objID].tag == v._ObjectList_ObjectMarker then
                            v._ObjectList_ObjectMarker.bDuplicate = true
                        else
                            v._ObjectList_ObjectMarker.bInvalid = true
                        end
                        return
                        
                        --[[
                        local nNewID = v._ObjectList_ObjectMarker.objID+100000
                        while ObjectList.tObjList[nNewID] or tProcessedTags[nNewID] or ObjectList.tReservedTags[nNewID] do
                            nNewID=nNewID+1
                        end
                        v._ObjectList_ObjectMarker.objID = nNewID
                        ObjectList.reserveTag(v._ObjectList_ObjectMarker)
                        ]]--
                    end
                    -- This table is an object.
                    -- The recursive call will have already fixed up the tag's value.
                    -- For inventory items, we can call objectlist.addobject now, since they don't need any
                    -- fancy save/load code.
                    if v._ObjectList_ObjectMarker.objType == ObjectList.INVENTORYITEM then
                        ObjectList.addObject(v._ObjectList_ObjectMarker.objType, v._ObjectList_ObjectMarker.objSubtype, v, v, v._ObjectList_ObjectMarker.bBlocksPathing, v._ObjectList_ObjectMarker.bBlocksOxygen)
                    end
                end
            end
            return foundTag
end

function ObjectList._generateNewObjectTagsForModuleLoad(tSaveData, nTagOffset, tProcessedTags)
    for k,v in pairs(tSaveData) do
        local found = nil
        if type(k) == 'table' then
            found = _adjustTag(k,nTagOffset,tProcessedTags)
            if found then
                assertdev(found._ObjectList_TagMarker)
                assertdev(k._ObjectList_TagMarker)
                assertdev(found.objType == k.objType)
                tSaveData[found] = tSaveData[k]
                tSaveData[k] = nil
            elseif k._ObjectList_ObjectMarker and (k._ObjectList_ObjectMarker.bInvalid or k._ObjectList_ObjectMarker.bDuplicate) then
                tSaveData[k] = nil
                k._ObjectList_ObjectMarker.bDuplicate = nil
            end
        end
        if type(v) == 'table' then
            found = _adjustTag(v,nTagOffset,tProcessedTags)
            if found then
                assertdev(found._ObjectList_TagMarker)
                assertdev(v._ObjectList_TagMarker)
                assertdev(found.objType == v.objType)
                tSaveData[k] = found
            elseif v._ObjectList_ObjectMarker and (v._ObjectList_ObjectMarker.bInvalid or v._ObjectList_ObjectMarker.bDuplicate) then
                v._ObjectList_ObjectMarker.bDuplicate = nil
                tSaveData[k] = nil
            end
        end
    end
end

function ObjectList._adjustAddr(addr,xOff,yOff)
    if not xOff then return addr end

    local tx,ty = World.pathGrid:cellAddrToCoord(addr)
    local wx,wy = World._getWorldFromTile(tx,ty)
    wx,wy = wx+xOff,wy+yOff
    tx,ty = World._getTileFromWorld(wx,wy)
    addr = World.pathGrid:getCellAddr(tx,ty)
    
    return addr,wx,wy
end

function ObjectList.getSaveTable(objType,tag,xOff,yOff)
    assertdev(not tag.bInvalid)
    if tag.bInvalid then return nil end
    local tData = nil
    local objData = ObjectList.tObjList[tag.objID]
    local obj = objData.obj
    if objType == ObjectList.CHARACTER then
        tData = obj:getSaveData(xOff,yOff)
    elseif objType == ObjectList.ENVOBJECT then
        tData = obj:getSaveTable(xOff, yOff)
    elseif objType == ObjectList.ROOM then
        tData = obj:getSaveTable(xOff, yOff)
    elseif objType == ObjectList.RESERVATION then
        -- DO NOTHING
    elseif objType == ObjectList.WORLDOBJECT then
        tData = obj:getSaveTable(xOff, yOff)
    elseif objType == ObjectList.INVENTORYITEM then
        -- MTF NOTE: we don't currently save inventory as part of the ObjectList. (see tSaveTypes above)
        -- Rather, containers save out the complete item, since it's a table w/ no userdata.
    else
        assertdev(false)
    end
    
    if tData then
        -- Save out the tag for restoration on load.
        tData._ObjectList_ObjectMarker = tag
    end
    
    return tData
end

function ObjectList.init()
    World=require('World')
    EnvObjectData=require('EnvObjects.EnvObjectData')
    EnvObject=require('EnvObjects.EnvObject')
    WorldObject=require('WorldObjects.WorldObject')
    Room=require('Room')
    CharacterManager=require('CharacterManager')
    ObjectList.reset()
end

function ObjectList.getObjType(obj)
    if obj then
        return ((obj.tag and obj.tag.objType) or obj.objType), (obj.tag and obj.tag.objSubtype)
    end
end

function ObjectList.getObjSubtype(obj)
    local _,st = ObjectList.getObjType(obj)
    return st
end

function ObjectList.getCountOfType(sType)
    return ObjectList.tCountByType[sType] 
end

function ObjectList.getTagsOfType(typeName)
    return ObjectList.tObjByType[typeName]
end

-- Faster and jit-friendly.
function ObjectList.getTypeIterater(typeName, bYieldTag, subtype)
    local index = nil
    assert(subtype, 'Use getTagsOfType if you do not want the subtype.')
    local list = ObjectList.tObjByType[typeName]
    assert(list)

    -- Could remove the need for some upvalues if we take advantage of the
    -- "state" and "index" parameters that the for loop keeps for us, but unless
    -- we get rid of all the upvalues we can't prevent creating a bit of garbage
    local function iter()
        while true do
            local key, value = next(list, index)
            index = key
            if key == nil then 
                break 
            end

            local objID, objData = key, value
            local tag = objData.tag
            if tag.objSubtype == subtype then
                return (bYieldTag and tag) or objData.obj
            end
        end
    end

    return iter, nil, nil       -- state and index are unused
end

function ObjectList.getObjByID(id)
    local objData = id and ObjectList.tObjList[id]
    if objData and not objData.tag.bInvalid then return objData.obj end
end

function ObjectList.reset()
    ObjectList.tObjList={}
    ObjectList.tObjByType={}
    ObjectList.tCountByType={}
    for _,sType in ipairs(ObjectList.tSaveTypes) do
        ObjectList.tObjByType[sType] = {}
        ObjectList.tCountByType[sType] = 0
    end
    ObjectList.tIDsAtAddr={}
    ObjectList.objectCounter=1
    ObjectList.dTileContentsChanged = Delegate.new()
end

function ObjectList.oxygenBlockedByObject(tx,ty)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tObjIDs = ObjectList.tIDsAtAddr[addr]
    if tObjIDs then
        for objID,_ in pairs(tObjIDs) do
            if ObjectList._blocksOxygen(ObjectList.tObjList[objID].tag) then
                return ObjectList.tObjList[objID].obj
            end
        end
    end
end

function ObjectList.setBlocksPathing(tag,bBlock)
    assert(not tag.bInvalid)
    if tag.bBlocksPathing == bBlock then return end
    tag.bBlocksPathing = bBlock
    for addr,_ in pairs(tag.tTiles) do
        local tx,ty = World.pathGrid:cellAddrToCoord(addr)
        ObjectList._refreshTileAttributes(tx,ty,addr,true,false,tag)
    end
end

function ObjectList.setBlocksOxygen(tag,bBlock)
    assert(not tag.bInvalid)
    if tag.bBlocksOxygen == bBlock then return end
    tag.bBlocksOxygen = bBlock
    for addr,_ in pairs(tag.tTiles) do
        local tx,ty = World.pathGrid:cellAddrToCoord(addr)
        ObjectList._refreshTileAttributes(tx,ty,addr,false,true,tag)
    end
end

function ObjectList._blocksPathing(tag)
    assert(not tag.bInvalid)
    return tag.bBlocksPathing
end

function ObjectList._blocksOxygen(tag)
    assert(not tag.bInvalid)
    return tag.bBlocksOxygen
end

function ObjectList.pathBlockedByObject(tx,ty)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tObjIDs = ObjectList.tIDsAtAddr[addr]
    if tObjIDs then
        for objID,_ in pairs(tObjIDs) do
            if ObjectList._blocksPathing(ObjectList.tObjList[objID].tag) then
                return ObjectList.tObjList[objID].obj
            end
        end
    end
end

function ObjectList.getReservationAt(tx,ty)
    local res = ObjectList.getTagAtTile(tx,ty,ObjectList.RESERVATION)
    if res then
        return res
    end
end

function ObjectList.getDoorAtTile(tx,ty)
    local rDoor = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT,'Door')
    if not rDoor then
        rDoor = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT,'Airlock')
    end
    if not rDoor then
        rDoor = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT,'HeavyDoor')
    end
    return rDoor
end

function ObjectList.isTagAtTile(tx,ty,tag)
    assert(not tag.bInvalid)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    return tag.tTiles[addr]
end

function ObjectList.getObjAtTile(tx,ty,objType,objSubtype)
    local tag = ObjectList.getTagAtTile(tx,ty,objType,objSubtype)
    if tag and not tag.bInvalid then return ObjectList.tObjList[tag.objID].obj end
end

function ObjectList.getObjectsOfTypesAtTile(tx,ty,tObjTypes)
    local tObjects = {}

    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tObjIDs = ObjectList.tIDsAtAddr[addr]
    if tObjIDs then
        for objID,_ in pairs(tObjIDs) do
            if tObjTypes[ObjectList.tObjList[objID].tag.objType] then
                tObjects[ ObjectList.tObjList[objID].obj ] = ObjectList.tObjList[objID].tag.objType
            end
        end
    end

    return tObjects
end


function ObjectList.getTagAtTile(tx,ty,objType,objSubtype)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tObjIDs = ObjectList.tIDsAtAddr[addr]
    if tObjIDs then
        for objID,_ in pairs(tObjIDs) do
            if ObjectList.tObjList[objID].tag.objType == objType then
                if not objSubtype or objSubtype == ObjectList.tObjList[objID].tag.objSubtype then
                    return ObjectList.tObjList[objID].tag
                end
            end
        end
    end
end

function ObjectList.removeObject(tag)
    if tag.bInvalid then
        Print(TT_Warning, "OBJECTLIST.LUA: removing object twice")
        return
    end
    
    ObjectList.unoccupySpace(tag)
    ObjectList.tObjList[tag.objID] = nil
    ObjectList.tObjByType[tag.objType][tag.objID] = nil
    ObjectList.tCountByType[tag.objType] = ObjectList.tCountByType[tag.objType] - 1
    tag.bInvalid = true
end

function ObjectList.unoccupySpace(tag)
    assert(not tag.bInvalid)
    
    for touchedAddr,_ in pairs(tag.tTiles) do
        local tx,ty = World.pathGrid:cellAddrToCoord(touchedAddr)
        ObjectList._setIDAtTile(tx,ty,tag,false)
    end
    tag.addr = nil
end

function ObjectList._setIDAtTile(tx,ty,tag,bSet)
    local id = tag.objID
    local addr = World.pathGrid:getCellAddr(tx,ty)

    if not ObjectList.tIDsAtAddr[addr] then
        ObjectList.tIDsAtAddr[addr] = {}
    end

    assert((bSet and not ObjectList.tIDsAtAddr[addr][id]) or (not bSet and ObjectList.tIDsAtAddr[addr][id]))
    ObjectList.tIDsAtAddr[addr][id] = (bSet and 1) or nil
    tag.tTiles[addr] = (bSet and 1) or nil

    ObjectList._refreshTileAttributes(tx,ty,addr,ObjectList._blocksPathing(tag),ObjectList._blocksOxygen(tag),tag,bSet)
end

function ObjectList._refreshTileAttributes(tx,ty,addr,bPathing,bOxygen,sourceTag,bSet)
    local tileValue = nil
    if bPathing then
        -- we just re-set the tile to the same value, and let World calculate any flag changes.
		tileValue = World._getTileValue(tx,ty)
        World._setTile(tx,ty,tileValue,true)
    -- NOTE: the 'elseif' is because _setTile already updates oxygen permeability.
    elseif bOxygen then
        World._updateOxygenFlags(tx,ty,tileValue)
    end
    ObjectList.dTileContentsChanged:dispatch(tx,ty,sourceTag,bSet)
end

function ObjectList.occupySpace(wx,wy,tag,bFlipX,bFlipY)
    assert(not tag.bInvalid)
    local tx,ty = World._getTileFromWorld(wx,wy)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    if tag.addr == addr and tag.bFlipX == bFlipX and tag.bFlipY == bFlipY then
        -- moving to same space
        return true
    end

    if tag.addr then
        -- vacate old space
        ObjectList.unoccupySpace(tag)
    end

    tag.bFlipX = bFlipX
    tag.bFlipY = bFlipY
    tag.addr = addr

    if tag.objType == ObjectList.ENVOBJECT or tag.objType == ObjectList.RESERVATION then
        local tTiles = World._getPropFootprint(tx,ty, tag.objSubtype, false, tag.bFlipX, tag.bFlipY)
        for _,touchedAddr in ipairs(tTiles) do
            local x,y = World.pathGrid:cellAddrToCoord(touchedAddr)
            ObjectList._setIDAtTile(x,y,tag,true)
        end
    else
        ObjectList._setIDAtTile(tx,ty,tag,true)
    end

    return true
end


return ObjectList
