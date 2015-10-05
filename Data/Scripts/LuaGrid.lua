local Class=require('Class')

local LuaGrid = Class.create()

--'o2_occlude'=DFOxygenGrid.TILE_OCCLUDE,
--'o2_indoors'=DFOxygenGrid.TILE_INDOORS,
--'path_hide'=MOAIGridSpace.TILE_HIDE
local MaxTiles = 256
local inv256 = 1/MaxTiles

function a2c(addr)
    addr = addr-1
	return addr % MaxTiles + 1, math.floor(addr * inv256) % MaxTiles + 1
end

function getaddr(tx,ty)
    tx = (tx-1) % MaxTiles
    ty = (ty-1) % MaxTiles
    return ty*MaxTiles+tx+1
end

function LuaGrid.fromSaveData(tData,bSaveLoadTileColor,tOldSaveDefaults)
    local lg = LuaGrid.new(tData.sGridClass or tOldSaveDefaults.sGridClass)

    lg.bSaveLoadTileColor = bSaveLoadTileColor
    
    if tOldSaveDefaults.nDefaultVal then lg.nDefaultVal = tOldSaveDefaults.nDefaultVal end
    if tOldSaveDefaults.nDefaultColor then lg.nDefaultColor = tOldSaveDefaults.nDefaultColor end
    
    if tData.mShape then
        if tData.moaiGridData then
            lg.rGrid:deserializeFromTable(tData.moaiGridData)
        else
            lg.rGrid = tData.moaiGrid
        end
        lg.mWidth = tData.mWidth
        lg.mHeight = tData.mHeight
        lg.mCellWidth = tData.mCellWidth
        lg.mCellHeight = tData.mCellHeight
        lg.mTileWidth = tData.mTileWidth
        lg.mTileHeight = tData.mTileHeight
        lg.mShape = tData.mShape
        lg.tTiles = tData.tTiles
        lg.tFlags = tData.tFlags or {}
        if bSaveLoadTileColor then
            lg.tColors = tData.tColors or {}
        else
            lg.tColors = {}
        end
        if tData.nDefaultVal then lg.nDefaultVal = tData.nDefaultVal end
        if tData.tDefaultColor then lg.tDefaultColor = tData.tDefaultColor end
    else
        -- old saves
        lg.rGrid = tData
        lg.tTiles = nil
        lg.mWidth,lg.mHeight = tData:getSize()
        lg.mTileWidth,lg.mTileHeight = tData:getTileSize()
        local nShape = tData:getShape()
        if nShape == MOAIGridSpace.RECT_SHAPE then
            lg.mShape = 'rect'
        elseif nShape == MOAIGridSpace.DIAMOND_SHAPE then
            lg.mShape = 'diamond'
        else
            assert(false)
        end
        lg.mCellWidth = lg.mTileWidth
        lg.mCellHeight = lg.mTileHeight
        if lg.mShape == 'diamond' then lg.mCellHeight = lg.mTileHeight*.5 end
    end

    lg.mInvCellWidth=1/lg.mCellWidth
    lg.mInvCellHeight=1/lg.mCellHeight
    
    if not lg.nDefaultVal then lg.nDefaultVal = 0 end
    if not lg.nDefaultColor then lg.nDefaultColor = {1,1,1,1} end
    
    if not lg.tTiles or not next(lg.tTiles) then
        local tTiles = {}
        local tFlags = {}
        local tColors = {}
        lg.tTiles = tTiles
        lg.tFlags = tFlags
        lg.tColors = tColors
        local rGrid = lg.rGrid
        --local tAllowedFlags={'o2_occlude','o2_indoors','path_hide'}
        local tAllowedFlags={DFOxygenGrid.TILE_OCCLUDE, DFOxygenGrid.TILE_INDOORS, MOAIGridSpace.TILE_HIDE}
        for x=1,lg.mWidth do
            for y=1,lg.mHeight do
                local val = rGrid:getTileValue(x,y)
                if val ~= lg.nDefaultVal then
                    local addr = getaddr(x,y)
                    tTiles[addr] = val
                    for _,flagConstant in ipairs(tAllowedFlags) do
                        if rGrid:checkTileFlag(x,y,flagConstant) then
                            if not tFlags[addr] then tFlags[addr] = {} end
                            tFlags[addr][flagConstant] = 1
                        end
                    end
                end
                if bSaveLoadTileColor then
                local r,g,b,a = rGrid:getTileColor(x,y)
                    if b and (r ~= lg.nDefaultColor[1] or g ~= lg.nDefaultColor[2] or b ~= lg.nDefaultColor[3] or a ~= lg.nDefaultColor[4]) then
                        tColors[getaddr(x,y)] = {r,g,b,a}
                    end
                end
            end
        end
    end
    return lg
end

function LuaGrid:getSaveData()
    local t = {}
    t.mWidth=self.mWidth
    t.mHeight=self.mHeight
    t.sGridClass = self.sGridClass
    t.mCellWidth=self.mCellWidth
    t.mCellHeight=self.mCellHeight
    t.mShape = self.mShape
    assert(self.rGrid)
    t.moaiGridData = self.rGrid:serializeToTable()
    --t.moaiGrid = self.rGrid -- MOAIGrid supports serialization
    t.tTiles = self.tTiles
    t.tFlags = self.tFlags
    t.tColors = (self.bSaveLoadTileColor and self.tColors) or {}
    t.tDefaultColor = self.tDefaultColor
    t.nDefaultVal = self.nDefaultVal
    return t
end

function LuaGrid._createBackingGrid(sClass)
    if sClass == 'DFOxygenGrid' then
        return DFOxygenGrid.new()
    end
    return MOAIGrid.new()
end

function LuaGrid:init(sClass)
    self.sGridClass = sClass
    self.rGrid = LuaGrid._createBackingGrid(sClass)
    self.tTiles = {}
    self.tFlags = {}
    self.tColors = {}
    self.nDefaultVal=0
    self.tDefaultColor={0,0,0,0}
end

function LuaGrid:fill(val)
    self.rGrid:fill(val)
    self.nDefaultVal = val
    self.tTiles={}
    self.tFlags={}
end

function LuaGrid:fillColor(r,g,b,a)
    self.rGrid:fillColor(r,g,b,a)
    self.tDefaultColor={r,g,b,a}
    self.tColors={}
end

function LuaGrid:setTile(tx,ty,val)
    self.rGrid:setTile(tx,ty,val)
    self.tTiles[getaddr(tx,ty)] = val
end

function LuaGrid:setTileValue(tx,ty,val)
    self.rGrid:setTileValue(tx,ty,val)
    self.tTiles[getaddr(tx,ty)] = val
end

function LuaGrid:setTileColor(tx,ty,r,g,b,a)
    self.rGrid:setTileColor(tx,ty,r,g,b,a)
    self.tColors[getaddr(tx,ty)] = {r,g,b,a}
end

function LuaGrid:getTileColor(tx,ty)
    local c = self.tColors[getaddr(tx,ty)] or self.tDefaultColor
    if c then return unpack(c) end
end

function LuaGrid:setTileFlag(tx,ty, flag)
    self.rGrid:setTileFlags(tx,ty, flag)
    local addr = getaddr(tx,ty)
    if not self.tFlags[addr] then self.tFlags[addr] = {} end
    self.tFlags[addr][flag] = 1
end

function LuaGrid:clearTileFlag(tx,ty, flag)
    self.rGrid:clearTileFlags(tx,ty, flag)
    local addr = getaddr(tx,ty)
    if self.tFlags[addr] then self.tFlags[addr][flag] = nil end
end

function LuaGrid:checkTileFlag(tx,ty, flag)
    --self.rGrid:checkTileFlag(tx,ty, val)
    local addr = getaddr(tx,ty)
    return self.tFlags[addr] and self.tFlags[addr][flag]
end

--[[
function LuaGrid:getTile(tx,ty)
    return self.rGrid:getTile(tx,ty)
end
]]--

function LuaGrid:getMOAIGrid()
    return self.rGrid
end

function LuaGrid:getTileValue(tx,ty)
    return self.tTiles[getaddr(tx,ty)] or self.nDefaultVal
    --return self.rGrid:getTileValue(tx,ty)
end

function LuaGrid:cellAddrToCoord(addr)
    addr = addr-1
	return addr % MaxTiles + 1, math.floor(addr * inv256) % MaxTiles + 1
	--return addr % self.mWidth + 1, math.floor(addr / self.mWidth) % self.mHeight + 1
end

function LuaGrid:getCellAddr(tx,ty)
    tx = (tx-1) % MaxTiles
    ty = (ty-1) % MaxTiles
    return ty*MaxTiles+tx+1
--    local dbgaddr = self.rGrid:getCellAddr(tx,ty)
--[[
    tx = (tx-1) % self.mWidth
    ty = (ty-1) % self.mHeight
    return ty*self.mWidth+tx+1
    ]]--
--    local ca = ty*self.mWidth+tx+1
--    assert(ca == dbgaddr)
--    return ca
end

function LuaGrid:getTileLoc(tx,ty,position)
    position = position or MOAIGridSpace.TILE_CENTER
    tx=tx-1
    ty=ty-1
    local xOff = 0
    if self.mShape == 'diamond' and ty % 2 == 1 then xOff = self.mCellWidth*.5 end

    local wx,wy = tx*self.mCellWidth+xOff,ty*self.mCellHeight
    if position == MOAIGridSpace.TILE_CENTER then
        wx=wx+self.mTileWidth*.5
        wy=wy+self.mTileHeight*.5
    elseif position == MOAIGridSpace.TILE_LEFT_TOP then
    elseif position == MOAIGridSpace.TILE_RIGHT_TOP then
        wx=wx+self.mTileWidth
    elseif position == MOAIGridSpace.TILE_LEFT_BOTTOM then
        wy=wy+self.mTileHeight
    elseif position == MOAIGridSpace.TILE_RIGHT_BOTTOM then
        wx=wx+self.mTileWidth
        wy=wy+self.mTileHeight
    elseif position == MOAIGridSpace.TILE_LEFT_CENTER then
        wy=wy+self.mTileHeight*.5
    elseif position == MOAIGridSpace.TILE_RIGHT_CENTER then
        wx=wx+self.mTileWidth
        wy=wy+self.mTileHeight*.5
    elseif position == MOAIGridSpace.TILE_TOP_CENTER then
        wx=wx+self.mTileWidth*.5
    elseif position == MOAIGridSpace.TILE_BOTTOM_CENTER then
        wx=wx+self.mTileWidth*.5
        wy=wy+self.mTileHeight
    end

    --local dbgx,dbgy = self.rGrid:getTileLoc(tx+1,ty+1,position)
    --assert(math.abs(dbgx-wx) < .001 and math.abs(dbgy-wy) < 0.001)

    return wx,wy
end

function LuaGrid:locToCoord(gridX,gridY)
    local xUnit = gridX*self.mInvCellWidth
    local yUnit = gridY*self.mInvCellHeight
    local yTile = math.floor(yUnit)
    local stepRight = 0
    if yTile % 2 == 1 then 
        stepRight = 1 
        xUnit = xUnit-.5
    end
    local stepLeft = stepRight-1
    local xTile = math.floor(xUnit)
    local xLocal = (xUnit - xTile) * 4
    local yLocal = (yUnit - yTile)*2 - 1
    if xLocal < 1 then
        if yLocal < 0 then
            if yLocal < -xLocal then
                xTile = xTile+stepLeft
                yTile = yTile-1
            end
        elseif yLocal > xLocal then
            xTile = xTile+stepLeft
            yTile = yTile+1
        end
    elseif xLocal > 3 then
        if yLocal < 0 then
            if yLocal < xLocal - 4 then
                xTile = xTile+stepRight
                yTile = yTile-1
            end
        elseif yLocal > 4-xLocal then
            xTile = xTile+stepRight
            yTile = yTile+1
        end
    end
    return xTile+1,yTile+1
    --local rx,ry = xTile+1,yTile+1
    --local dbgx,dbgy = self.rGrid:locToCoord(gridX,gridY)
    --assert(dbgx == rx and dbgy == ry)
    --return rx,ry
end

function LuaGrid:initRectGrid(w,h,tw,th,xGutter,yGutter)
    assert(not xGutter)
    assert(not yGutter)
    xGutter = xGutter or 0
    yGutter = yGutter or 0
    self.rGrid:initRectGrid(w,h,tw,th,xGutter,yGutter)
    self.mWidth=w
    self.mHeight=h
    self.mShape='rect'
    self.mTileWidth=tw
    self.mTileHeight=th
    self.mCellWidth=tw
    self.mCellHeight=th
    self.mInvCellWidth=1/self.mCellWidth
    self.mInvCellHeight=1/self.mCellHeight
end

function LuaGrid:initDiamondGrid(w,h,tw,th,xGutter,yGutter)
    assert(not xGutter)
    assert(not yGutter)
    xGutter = xGutter or 0
    yGutter = yGutter or 0
    self.rGrid:initDiamondGrid(w,h,tw,th,xGutter,yGutter)
    self.mWidth=w
    self.mHeight=h
    self.mTileWidth=tw
    self.mTileHeight=th
    self.mShape='diamond'
    self.mCellWidth=tw
    self.mCellHeight=th*.5
    self.mInvCellWidth=1/self.mCellWidth
    self.mInvCellHeight=1/self.mCellHeight
	--self.mXOff = xGutter * 0.5
	--self.mYOff = yGutter * 0.5
	--self.mTileWidth = tw - xGutter
	--self.mTileHeight = th - yGutter
end

function LuaGrid:getOxygen(tx,ty)
    return self.rGrid:getOxygen(tx,ty)
end

function LuaGrid:setOxygen(tx,ty,o2)
    self.rGrid:setOxygen(tx,ty,o2)
end

function LuaGrid:addOxygen(tx,ty,o2)
    self.rGrid:addOxygen(tx,ty,o2)
end

function LuaGrid:setDebugColorsEnabled(bEnabled)
    if self.rGrid.setDebugColorsEnabled then
        self.rGrid:setDebugColorsEnabled(bEnabled)
    end
end

return LuaGrid

