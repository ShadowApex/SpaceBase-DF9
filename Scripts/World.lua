local World = require('WorldConstants')
local DFGraphics = require('DFCommon.Graphics')
local Delegate = require('DFMoai.Delegate')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local Renderer = require('Renderer')
local Zone = require('Zones.Zone')
local ObjectList = require('ObjectList')
local Asteroid = require('Asteroid')
local MiscUtil = require('MiscUtil')
local Environment = require('Environment.Environment')
local GridUtil = require('GridUtil')
local LuaGrid = require('LuaGrid')
local Base = nil
local Gui = require('UI.Gui')
local Room = nil
local Turret = nil
local Fire = nil
local Character = nil
local EnvObject = nil
local WorldObject = nil
local Oxygen = nil
local Lighting = nil
local CommandObject = nil
local Door = nil
local GameRules = nil
local Pathfinder = nil
local GlobalObjects = nil
local Profile = require('Profile')
local SquadList = require('SquadList')

-- guarantee order for object loading.
local SAVE_TYPES={ObjectList.ROOM, ObjectList.ENVOBJECT, ObjectList.CHARACTER, ObjectList.RESERVATION}

World.pathGrid=nil
World.roomGrid=nil
World.cursorTiles = {}
World.dragValid = true
World.dragCost = 0
    
World.dirtyVisualTiles = {}
World.props = {}
World.tilesToExplore={}
World.tileDetails={}
    
World.tileHealth={}
    
World.lifeSupportTiles = 0
World.gardenTiles = 0
    
World.floorDecals = {}
World.wallDecals = {}
    
World.doorSpriteName = 'base01'
World.fogRoofSpriteName = 'rooftest'
World.layers = {
        space = {
            layer='Space',
            spritePath = 'Environments/Tiles/Space',
            gridIndexer=false,
        },
        buildGrid = {
            layer = 'BuildGrid',
            spritePath = 'UI/Cursor',
            gridIndexer=true,
            offsetZ=15,
        },
        worldFloor = {
            layer='WorldFloor',
            spritePath = 'Environments/Tiles/Floor',
            gridIndexer=true,
            priority=0,
            useWorldLightShader=true,
        },
        worldFloorDecal = {
            layer='WorldFloor',
            spritePath = 'Environments/Tiles/Floor',
            gridIndexer=true,
            useWorldLightShader=false,
            offsetZ=5,
        },
        worldWall = {
            layer='WorldWall',
            spritePath = 'Environments/Tiles/Wall',
        },
        worldCeiling = {
            layer='WorldCeiling',
            spritePath = 'Environments/Tiles/Wall',
        },
        cursor = {
            layer='Cursor',
            spritePath = 'UI/Cursor',
            gridIndexer=true,
            offsetZ=25,
        },
    }
World.analysisPropLayer='WorldAnalysis'
World.analysisSpritePath='Environments/Tiles/Floor'
World.background = {
        spritePath = 'Backgrounds/Backgrounds',
        spriteNames = { 'nebula01' },
        layer = 'Background',
}

local _DIR_SAME   = 1
local _DIR_NW     = 2
local _DIR_NE     = 3
local _DIR_SW     = 4
local _DIR_SE     = 5
local _DIR_N      = 6
local _DIR_E      = 7
local _DIR_S      = 8
local _DIR_W      = 9
local _DIR_DIAG_START = 2
local _DIR_DIAG_END = 5
local _DIR_END = 9

function World.getOppositeDirection(d)
    if d == World.directions.SAME then
        return World.directions.SAME
    elseif d == World.directions.NW then
        return World.directions.SE
    elseif d == World.directions.NE then
        return World.directions.SW
    elseif d == World.directions.SW then
        return World.directions.NE
    elseif d == World.directions.SE then
        return World.directions.NW
    elseif d == World.directions.W then
        return World.directions.E
    elseif d == World.directions.E then
        return World.directions.W
    elseif d == World.directions.N then
        return World.directions.S
    elseif d == World.directions.S then
        return World.directions.N
    else
        assert(false)
    end
end

function World.getPerpindicularDirection(d)
    if d == World.directions.SAME then
        return World.directions.SAME
    elseif d == World.directions.NW then
        return World.directions.NE
    elseif d == World.directions.NE then
        return World.directions.NW
    elseif d == World.directions.SW then
        return World.directions.SE
    elseif d == World.directions.SE then
        return World.directions.SW
    elseif d == World.directions.W then
        return World.directions.N
    elseif d == World.directions.E then
        return World.directions.S
    elseif d == World.directions.N then
        return World.directions.W
    elseif d == World.directions.S then
        return World.directions.E
    else
        assert(false)
    end
end

function World.getCardinalOrOrdinalDirectionToVector(x,y)
    -- Uses cosine similarity, http://en.wikipedia.org/wiki/Cosine_similarity
    if x==0 and y==0 then return World.directions.SAME end -- Can't determine direction from a 0,0 vector
    local sourceLength = math.sqrt(x*x+y*y)    
    local similarity, direction
    local vecs = World.directionVectors
    local nTests = #vecs
    for i=2,nTests do
        local x0,y0 = vecs[i][1],vecs[i][2]
        if x0 ~= 0 or y0 ~= 0 then 
            local currentSimilarity = (x*x0+y*y0) / ( sourceLength * (math.sqrt(x0*x0+y0*y0)))
            if not similarity or currentSimilarity < similarity then
                similarity = currentSimilarity
                direction = i
            end
        end
    end
    return direction and World.oppositeDirections[direction]
end

local tSpaceNames = {
    "The Void",
    "Cold, Empty Space",
    "Blackness",
    "Nothing",
    "The Abyss",
    "Everything & Nothing",
    "The Infinite",
    "Outer Space",
    "Space",
    "The Final Frontier",
    "Naught",
    "Nobody Can Hear You Scream Here",
    "The Universe",
    "Emptiness",
    "Darkness",
}

World.visualTiles = {
	
    wall_error = {
        names = { 'wall_block_temp' },
        layer = World.layers.worldWall,
    },
    
    -- exterior tiles
    space = {
        names = { 'stars_test', },    
        layer = World.layers.space,
    },
    
    -- cursor/meta visuals
    cursor = {
        names = { 'ISO_build_YES', },        
        layer = World.layers.cursor,
    },
    cursor_dragbox = {
        names = { 'ISO_build_YES', },
        layer = World.layers.cursor,
    },
    cursor_dragbox_invalid = {
        names = { 'ISO_build_NO', },
        layer = World.layers.cursor,
    },
    cursor_door = {
        names = { 'build_door', },
        layer = World.layers.cursor,
    },
    
    build_grid_square = {
        names = { 'ISO_build_grid', },
        layer = World.layers.buildGrid,
    },
    build_grid_square_bright = {
        names = { 'ISO_build_grid_bright', },
        layer = World.layers.buildGrid,
    },
    build_grid_square_bright_xaxis = {
        names = { 'ISO_build_grid_bright_xaxis', },
        layer = World.layers.buildGrid,
    },
    build_grid_square_bright_yaxis = {
        names = { 'ISO_build_grid_bright_yaxis', },
        layer = World.layers.buildGrid,
    },
}

--                    same  nw ne sw se  n  e  s  w
local _X_OFFSET   = { 0,    0, 1, 0, 1, 0, 1, 0,-1 }
local _Y_OFFSET   = { 0,    1, 1,-1,-1, 2, 0,-2, 0 }
local _NEED_XLEFT = { 0,    1, 1, 1, 1, 0, 0, 0, 0 }

-- accepts and returns tile coords, and a number from World.directions
function World._getAdjacentTile(x,y,d)
    local xLeft = - (y % 2)
    return (x + xLeft * _NEED_XLEFT[d] + _X_OFFSET[d]), (y + _Y_OFFSET[d]),1
end

local _getAdjacentTile = World._getAdjacentTile

function World.getBounds()
    local w,h = .5*World.width*World.tileWidth,.5*World.height*World.tileHeightH
    return -w,-h,w,h
end

function World.isInBounds(wx,wy)
    if not wx or not wy then return false end
    local x0,y0,x1,y1 = World.getBounds()
    return wx>=x0 and wx<=x1 and wy>=y0 and wy<=y1
end

function World._isInBounds(tx,ty,bNotSafe)
    if not tx or not ty then return false end
    local x0,y0,x1,y1 = World.getTileBounds(bNotSafe)
    return tx>=x0 and tx<=x1 and ty>=y0 and ty<=y1
end

function World.clampToBounds(wx,wy,bNotSafe)
    local x0,y0,x1,y1=World.getBounds()
    if not bNotSafe then
        local offset = World.CHARACTER_SAFETY_TOLERANCE * World.tileWidth
        x0,y0,x1,y1 = x0+offset,y0+offset,x1-offset,y1-offset
    end
    return DFMath.clamp(wx or 0, x0, x1), DFMath.clamp(wy or 0, y0, y1)
end

-- bNotSafe gives the real bounds instead of the "indented" bounds
function World.getTileBounds(bNotSafe)
    local x0,y0,x1,y1 = 1,1,World.width,World.height
    if not bNotSafe then x0,y0,x1,y1 = x0+World.CHARACTER_SAFETY_TOLERANCE,y0+World.CHARACTER_SAFETY_TOLERANCE,x1-World.CHARACTER_SAFETY_TOLERANCE,y1-World.CHARACTER_SAFETY_TOLERANCE end
    return x0,y0,x1,y1
end

function World.isInTileBounds(tx,ty,bNotSafe)
    local x0,y0,x1,y1 = World.getTileBounds(bNotSafe)
    return tx>=x0 and tx<=x1 and ty>=y0 and ty<=y1
end

function World.clampTileToBounds(tx,ty,bNotSafe)
    local x0,y0,x1,y1 = World.getTileBounds(bNotSafe)
    return DFMath.clamp(tx, x0, x1), DFMath.clamp(ty, y0, y1)
end

function World._createGrid(layerName, spritePath, bUseWorldLightShader, nOffsetZ)
    local grid = LuaGrid.new()
    grid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)
    local spriteSheet = Renderer.loadSpriteSheet(spritePath, false, false, true)
    local prop = MOAIProp.new()
    prop:setDeck(spriteSheet)
    
    if bUseWorldLightShader then
        prop:setGrid(grid:getMOAIGrid(), true) -- true here means we'll be expecting extra UVs based on the tile's location
        local rMaterial = Renderer.getGlobalMaterial("worldLight")
        prop:setMaterial(rMaterial)
    else
        prop:setGrid(grid:getMOAIGrid())
    end
    
    prop:setLoc(-World.width*World.tileWidth*.5, -World.height*World.tileHeightH*.5, nOffsetZ or 0)
    Renderer.getRenderLayer(layerName):insertProp(prop)

    return grid, spriteSheet, prop
end

function World.getWorldRenderLayer()
    return Renderer.getRenderLayer('WorldFloor')
end

function World._zoneAtAddr(addr)
    local tileX,tileY = World.pathGrid:cellAddrToCoord(addr)
    local tileVal = World.pathGrid:getTileValue(tileX,tileY)
    --return Zone.tOrderedZoneList[World.logicalTiles.ZONE_LIST_START - 1 + tileVal]
    return Zone.tOrderedZoneList[tileVal - World.logicalTiles.ZONE_LIST_START + 1]
end

function World._zoneAtTile(tileX, tileY)
    local tileVal = World.pathGrid:getTileValue(tileX,tileY)
    return Zone.tOrderedZoneList[tileVal - World.logicalTiles.ZONE_LIST_START + 1]
end

function World._zoneValue(tileVal)
    return Zone.tOrderedZoneList[tileVal - World.logicalTiles.ZONE_LIST_START + 1]
end

function World._setZoneAtAddr(addr, zoneName)
    local tileX, tileY = World.pathGrid:cellAddrToCoord(addr)
    if not World.countsAsFloor(World.pathGrid:getTileValue(tileX,tileY)) then
        Print(TT_Warning,'Attempt to set non-floor to zone',zoneName)
--         World._setTile(tileX, tileY, World.logicalTiles.ASTEROID_VALUE_START)
    else
        World._setTile(tileX, tileY, World.logicalTiles[zoneName])
    end
end

function World.init(width, height, tileWidth, tileHeight)
    Room = require('Room')
    Turret = require('EnvObjects.Turret')
    Base = require('Base')
    Character = require('Character')
    Fire = require('Fire')
    EnvObject = require('EnvObjects.EnvObject')
    WorldObject = require('WorldObjects.WorldObject')
    Oxygen = require('Oxygen')
    Lighting = require('Lighting')
    CommandObject = require('Utility.CommandObject')
    GameRules = require('GameRules')
    Pathfinder = require('Pathfinder')
    Door = require('EnvObjects.Door')
    GlobalObjects = require('Utility.GlobalObjects')

    World.dTileChanged = Delegate.new()
    World.tWallAddrToBlob={}
    World.tDirtyWallTiles={}

    GameRules.dEditModeChanged:register(World.onEditModeChanged)
    
    Zone.initZoneData()
    ObjectList.init()
    EnvObject.globalInit()
    WorldObject.globalInit()
    Room.reset()
	Turret.reset()
    CommandObject.staticInit()
    Oxygen.reset()
    Fire.reset()
    Door.reset()
	
	World.squadList = SquadList.new()
	
    require('Projectile').reset()
    GlobalObjects.reset()
    for idx,val in ipairs(Zone.tOrderedZoneList) do
        World.logicalTiles[val] = World.logicalTiles.ZONE_LIST_START - 1 + idx
        World.logicalTiles.ZONE_LIST_END = World.logicalTiles.ZONE_LIST_START - 1 + idx
    end

    World.tileHealth = {}
    World.floorDecals = {}
    World.wallDecals = {}
    
    World.width = width
    World.height = height
    World.tileWidth = tileWidth
    World.tileHeight = tileHeight
    World.tileHeight2 = 2*tileHeight
    World.tileHeightH = .5*tileHeight

    World.cursorTiles = {}
    World.dirtyVisualTiles = { dirtyList = {} }
	World.tilesToExplore = {}
    --World.buildReservations = {}
    World.tWalls = {}
    World.tAsteroids = {}
    
    -- setup the render order for the layers
    World.layers[1] = World.layers.space
    World.layers[2] = World.layers.worldFloor
    World.layers[3] = World.layers.worldFloorDecal
    World.layers[4] = World.layers.buildGrid
    World.layers[5] = World.layers.worldWall
    World.layers[6] = World.layers.worldCeiling
    World.layers[7] = World.layers.cursor
    
    -- create the pathing grid
    World.pathGrid = LuaGrid.new()
    World.pathGrid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)
    
    -- create the room grid
    World.roomGrid = LuaGrid.new()
    World.roomGrid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)
    
    -- create the spacey background
    --[[
    World.background.spriteSheet = Renderer.loadSpriteSheet(World.background.spritePath, false, false, true)
    World.background.grid = LuaGrid.new()
    local spaceTiles = 4
    local spaceTileSize = 2048
    World.background.grid:initRectGrid(spaceTiles, spaceTiles, spaceTileSize, spaceTileSize)     
    World.background.grid:fill(World.background.spriteSheet.names[DFUtil.arrayRandom(World.background.spriteNames)])
    World.background.prop = MOAIProp.new()    
    World.background.prop:setDeck( World.background.spriteSheet )    
    World.background.prop:setGrid( World.background.grid:getMOAIGrid() )
    World.background.prop:setLoc(spaceTiles * spaceTileSize * -0.5, spaceTiles * spaceTileSize * -0.5, 0) 
    Renderer.getRenderLayer(World.background.layer):insertProp(World.background.prop)
    ]]--

    -- create layer datas 
    for i,layer in ipairs(World.layers) do
        if layer.gridIndexer then
            layer.grid, layer.spriteSheet, layer.prop = World._createGrid(layer.layer, layer.spritePath, layer.useWorldLightShader, layer.offsetZ)
            if layer.priority ~= nil then
                layer.prop:setPriority(layer.priority)
            end
        else
            layer.grid = LuaGrid.new()
            layer.grid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)
            layer.spriteSheet = Renderer.loadSpriteSheet(layer.spritePath, false, false, false)
            layer.props = {}
            layer.renderLayer = Renderer.getRenderLayer(layer.layer)
            layer.originX,layer.originY = -World.width*World.tileWidth*.5, -World.height*World.tileHeightH*.5
        end
    end
    
    World.oxygenGrid = LuaGrid.new('DFOxygenGrid')
    World.oxygenGrid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)
    World.oxygenGrid:getMOAIGrid():setVisualizationColors(Gui.RED[1],Gui.RED[2],Gui.RED[3],Gui.GREEN[1],Gui.GREEN[2],Gui.GREEN[3])
    World.oxygenGrid:fill(0)
    Pathfinder.staticInit()

    World.analysisGrid, World.analysisSpriteSheet, World.analysisProp = World._createGrid(World.analysisPropLayer, World.analysisSpritePath)
    Renderer.getRenderLayer(World.analysisPropLayer):removeProp(World.analysisProp)
    World.analysisGrid:fill(World.analysisSpriteSheet.names['oxy_debug'])

    -- load the prop data
    --World.propGrid = LuaGrid.new()
    --World.propGrid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)
    --World.propGrid:fillColor(0,0,0,0)

    --World.objectGrid = {}
    --World.reverseObjectGrid = {}

    World.fireGrid = LuaGrid.new()
    World.fireGrid:initDiamondGrid(World.width, World.height, World.tileWidth, World.tileHeight)

    -- lookup indexes for all visual tiles
    for tile,data in pairs(World.visualTiles) do
        data.indexes = {}
        for i,name in ipairs(data.names) do
            table.insert(data.indexes, data.layer.spriteSheet.names[name])
        end
        data.index = data.indexes[1]
    end
    
    -- put some space everywhere in space        
    World.layers.space.grid:fill(World.visualTiles.space.index)
    
    local pathFlags = 0
    World.pathGrid:fill(World.logicalTiles.SPACE)
    
    GridUtil.PopulateTileLookup()
end

function World.getSquadList()
	return World.squadList
end

function World.setAnalysisPropEnabled(bEnabled,rGrid)
    if bEnabled then
        World.analysisProp:setColorGrid(rGrid:getMOAIGrid())
        World.rCurrentColorGrid = rGrid
        rGrid:setDebugColorsEnabled(true)
        Renderer.getRenderLayer(World.analysisPropLayer):insertProp(World.analysisProp)
    else
        World.analysisProp:setColorGrid(nil)
        if World.rCurrentColorGrid then
            World.rCurrentColorGrid:setDebugColorsEnabled(false)
            World.rCurrentColorGrid = nil
        end
        Renderer.getRenderLayer(World.analysisPropLayer):removeProp(World.analysisProp)
    end
end

function World.onEditModeChanged()
    if GameRules.inEditMode then
        World.layers.worldCeiling.renderLayer:setLoc(100000,100000)
    else
        World.layers.worldCeiling.renderLayer:setLoc(0,0)
    end
end

function World.shutdown()
    World.bSuspendFixupVisuals = true
    GameRules.dEditModeChanged:unregister(World.onEditModeChanged)
    CommandObject.shutdown()
    EnvObject.globalShutdown()
    WorldObject.globalShutdown()
    Environment.shutdown()
    local tObj = ObjectList.tObjList
    
    -- tear down gameplay grids
    World.setAnalysisPropEnabled(false)
    World.pathGrid = nil
    --World.propGrid = nil
    World.fireGrid = nil
    World.roomGrid = nil
    World.oxygenGrid = nil
    World.tileHealth = nil

    local rLightLayer = Renderer.getRenderLayer('Light')
    
    -- junk the visual grids
    for i,layer in ipairs(World.layers) do    
        if layer.prop then
            Renderer.getRenderLayer(layer.layer):removeProp(layer.prop)        
            layer.prop = nil
        end
        if layer.props then
            for _,v in pairs(layer.props) do
                for _,rProp in pairs(v) do
                    layer.renderLayer:removeProp(rProp)
                    rLightLayer:removeProp(rProp)
                end
            end
            layer.props = nil
        end
        layer.grid = nil
        DFGraphics.unloadSpriteSheet(layer.spriteSheet)  
    end  
    
    -- remove the background visuals
    --[[
    Renderer.getRenderLayer(World.background.layer):removeProp(World.background.prop)
    World.background.prop = nil
    World.background.grid = nil
    DFGraphics.unloadSpriteSheet(World.background.spriteSheet)
    ]]--
    
    -- Clean up other book keeping stuffs
    World.cursorTiles = {}
    World.dirtyVisualTiles = {}
    World.bSuspendFixupVisuals = false
end

function World.saveOtherTypes(saveData, worldXOff,worldYOff)
    for _,objType in ipairs(ObjectList.tSaveTypes) do
        saveData[objType] = {}
        local tTags = ObjectList.getTagsOfType(objType)
        for _,objData in pairs(tTags) do
            local tag = objData.tag
            local tData = ObjectList.getSaveTable(objType,tag,worldXOff,worldYOff)
            if tData then 
                assert(tData._ObjectList_ObjectMarker.objType == objType)
                table.insert(saveData[objType], tData) 
            end
        end
    end
    saveData.fire = require('Fire').getSaveTable(worldXOff,worldYOff)
    saveData.commandObject = CommandObject.getSaveTable(worldXOff,worldYOff)
    if not worldXOff then
        saveData.environment = Environment.getSaveTable()
    end

    saveData.oxygenGrid = World.oxygenGrid:getSaveData()

    for _,objType in ipairs(ObjectList.tSaveTypes) do
        for i,v in ipairs(saveData[objType]) do
            assert(not v._ObjectList_ObjectMarker or v._ObjectList_ObjectMarker.objType == objType)
        end
    end
end

function World.getModuleSaveData()
    
    local saveData = {       
        --pathGrid = {},
        --props = {},
        --rooms = {},
    }
    local minX,minY = 999999,999999
    local maxX,maxY = -999999,-999999
    
    for x = 0, World.width do
        for y = 0, World.height do
            local tile = World.pathGrid:getTileValue(x, y)    
            if tile > World.logicalTiles.SPACE then
                minX, minY = math.min(minX, x), math.min(minY, y)
                maxX, maxY = math.max(maxX, x), math.max(maxY, y)
            end
        end
    end
	
	-- take envobjects into account computing module bounds
    local tTags = ObjectList.getTagsOfType(ObjectList.ENVOBJECT)
    for _,objData in pairs(tTags) do
		local x,y = World._getTileFromWorld(objData.obj:getLoc())
		minX = math.min(x, minX)
		maxX = math.max(x, maxX)
		minY = math.min(y, minY)
		maxY = math.max(y, maxY)
	end
	
    local worldMinX, worldMinY = World._getWorldFromTile(minX,minY)
    local worldMaxX, worldMaxY = World._getWorldFromTile(maxX,maxY)
    
    saveData.tileHealth = World.tileHealth
    saveData.pathGrid = World.pathGrid:getSaveData()
    saveData.floorDecals = World.floorDecals

	-- We used to request offset save data (in savegame version 0). However, now that we're not offsetting
	-- the pathGrid above, we'll just get everything in its current coordinates, and 
	-- handle module moving/offsetting on the loading side.
    World.saveOtherTypes(saveData, 0, 0) -- -worldMinX,-worldMinY)

    saveData.origMinX,saveData.origMinY = minX,minY
--    minX,minY,maxX,maxY = minX-minX,minY-minY,maxX-minX,maxY-minY
    saveData.minX,saveData.minY,saveData.maxX,saveData.maxY = minX,minY,maxX,maxY
    saveData.worldMinX,saveData.worldMinY,saveData.worldMaxX,saveData.worldMaxY = worldMinX,worldMinY,worldMaxX,worldMaxY
	
	-- write list of dock points for docking code to easily refer to.
	-- placed dock points should be named NE/NW/SE/SW based on which
	-- edge of the module they're located at.
	saveData.dockingPoints = {}
    local fn = ObjectList.getTypeIterater(ObjectList.ENVOBJECT,false,'DockPoint')
    local rEnvObj = fn()
    while rEnvObj do
		local x,y = World._getTileFromWorld(rEnvObj:getLoc())
		if rEnvObj.sFriendlyName == 'NE' then
			saveData.dockingPoints[World.directions.NE] = {tileX=x, tileY=y}
		elseif rEnvObj.sFriendlyName == 'NW' then
			saveData.dockingPoints[World.directions.NW] = {tileX=x, tileY=y}
		elseif rEnvObj.sFriendlyName == 'SE' then
			saveData.dockingPoints[World.directions.SE] = {tileX=x, tileY=y}
		elseif rEnvObj.sFriendlyName == 'SW' then
			saveData.dockingPoints[World.directions.SW] = {tileX=x, tileY=y}
		end
        rEnvObj = fn()
    end
    return saveData, -worldMinX, -worldMinY
end

function World.getSaveData()
    local saveData = {
		tilesToExplore={},
    }
	local tSquads = World.getSquadList().getList()
    print("World:getSaveData() #tSquads: "..#tSquads)
    -- Save out the path grid.
    -- Do not save out prop grid. Props will save themselves out and re-place themselves in the world.
    -- Do not save out room grid. Rooms will save themselves out, so they can save out their attributes.
    
    saveData.tileHealth = World.tileHealth
    saveData.floorDecals = World.floorDecals
    saveData.pathGrid = World.pathGrid:getSaveData()

    World.saveOtherTypes(saveData)

	for k,v in pairs(World.tilesToExplore) do
		table.insert(saveData.tilesToExplore, {k=k,x=v.x,y=v.y})
	end

    return saveData
end

function World._updatePathGridDbgColor(tx,ty,bUnpathable)
    if not World.bPathGridVisualize then return end 

    local addr = World.pathGrid:getCellAddr(tx,ty)
    local tTag = Pathfinder.tTaggedTiles[addr]
    local bSoftUnpathable = false
    if tTag and tTag.tTagSpec.fnSoftLock and tTag.tTagSpec.fnSoftLock(tTag.tTagSpec,tTag.tAdditionalData) then
        bSoftUnpathable=true
    end

    local bReserved = ObjectList.getReservationAt(tx,ty) ~= nil
    local color = {0,0,0,0}
    if bUnpathable then color = {1,0,0,1}
    elseif bSoftUnpathable then color = {1,0,1,1}
    elseif tTag then color = {0,1,0,1}
    elseif bReserved then color = {0,0,1,1} end

	World.pathGrid:setTileColor(tx,ty,unpack(color))
end

function World.loadModule(nSavegameVersion, saveData, worldXOff, worldYOff, nNewTeamFactionBehavior)
    World.bLoadingGame=true
    World.bLoadingModule=true

    World.bSuspendFixupVisuals = true
	worldXOff,worldYOff = worldXOff-saveData.worldMinX,worldYOff-saveData.worldMinY

    if not saveData.pathGrid.rGrid then
        saveData.pathGrid = LuaGrid.fromSaveData(saveData.pathGrid, false, {nDefaultVal=World.logicalTiles.SPACE})
    end
    if not saveData.oxygenGrid.rGrid then
        saveData.oxygenGrid = LuaGrid.fromSaveData(saveData.oxygenGrid, false, {nDefaultVal=0,sGridClass='DFOxygenGrid'})
    end

    local nTeam = Character.TEAM_ID_PLAYER
    if nNewTeamFactionBehavior then
        nTeam = Base.createNewTeamID(nNewTeamFactionBehavior)
    end
    
    World.tileHealth = saveData.tileHealth or {}
    
    --placeDim = placeDim and World.fogOfWar
	for x=saveData.minX,saveData.maxX do
		for y=saveData.minY,saveData.maxY do
			local tileVal = saveData.pathGrid:getTileValue(x,y)
            local srcAddr = World.pathGrid:getCellAddr(x,y)
			local wx,wy = World._getWorldFromTile(x,y)
			local newTileX,newTileY = World._getTileFromWorld(wx+worldXOff,wy+worldYOff)

            if tileVal > World.logicalTiles.SPACE then
			    World._setTile(newTileX,newTileY,tileVal,true,false)
                local rChar = ObjectList.getObjAtTile(newTileX,newTileY,ObjectList.CHARACTER)
                if rChar and rChar:spacewalking() then
                    rChar:setElevatedSpacewalk(true)
                end
                World.oxygenGrid:setTileValue(newTileX,newTileY, saveData.oxygenGrid:getTileValue(x,y))
                if saveData.oxygenGrid:checkTileFlag(x,y, DFOxygenGrid.TILE_OCCLUDE) then
                    World.oxygenGrid:setTileFlag(newTileX,newTileY, DFOxygenGrid.TILE_OCCLUDE)
                end
                if saveData.oxygenGrid:checkTileFlag(x,y, DFOxygenGrid.TILE_INDOORS) then
                    World.oxygenGrid:setTileFlag(newTileX,newTileY, DFOxygenGrid.TILE_INDOORS)
                end
                World.oxygenGrid:setOxygen(newTileX,newTileY, saveData.oxygenGrid:getOxygen(x,y))
			    World._dirtyTile(newTileX,newTileY,true)

                if saveData.floorDecals and saveData.floorDecals[srcAddr] then
                    local t = saveData.floorDecals[srcAddr]
                    World.setFloorDecal(newTileX,newTileY,t.sDecal,t.tColor)
                end
            end
		end
	end

    World.loadOtherTypes(nSavegameVersion, saveData, worldXOff, worldYOff, nTeam)
    if not nTeam or nTeam == Character.TEAM_ID_PLAYER then
        CommandObject.fromSaveTable(saveData.commandObject, worldXOff, worldYOff, true)
    end
    World.bSuspendFixupVisuals = false
    World.bLoadingGame=true
    World.bLoadingModule=true
    return nTeam
end

function World.loadOtherTypes(nSavegameVersion, saveData, worldXOff, worldYOff, nTeam)
    --[[
    -- just some testing code for savegame issues. verifies good object tags.
    for i=1,#SAVE_TYPES do
        for _,objType in ipairs(ObjectList.tSaveTypes) do
            if objType == SAVE_TYPES[i] and saveData[objType] then
                for _,t in ipairs(saveData[objType]) do
                    assertdev(not t._ObjectList_ObjectMarker or t._ObjectList_ObjectMarker.objType == objType)
                end
            end
        end
    end
    ]]--
    for i=1,#SAVE_TYPES do
        for _,objType in ipairs(ObjectList.tSaveTypes) do
            if objType == SAVE_TYPES[i] and saveData[objType] then
                for _,t in ipairs(saveData[objType]) do
                    if t._ObjectList_ObjectMarker then
                        assertdev(t._ObjectList_ObjectMarker.objType == objType)
                    end
                    local obj = ObjectList.loadFromSaveTable(objType,t,worldXOff,worldYOff,nTeam)
                    if obj and nSavegameVersion < 7 and objType == ObjectList.CHARACTER then
                        obj:generateStartingStuff()
                    end
                end
            end
        end
    end

--    Room.updateDirty()
    if not worldXOff then
        Environment.fromSaveTable(saveData.environment)
    end
    Fire.fromSaveTable(saveData.fire, worldXOff,worldYOff, nTeam)
    
    require('CharacterManager').updateOwnedCharacters()
end

function World.setPathGridVisualize(bVis)
    if bVis == World.bPathGridVisualize then
        return
    end
    World.bPathGridVisualize = bVis
    World.setAnalysisPropEnabled(bVis,World.pathGrid)

    if bVis then
        for x=1,World.width do
            for y=1,World.height do
                World._updatePathGridDbgColor(x,y,World.pathGrid:checkTileFlag(x,y,MOAIGridSpace.TILE_HIDE))
            end
        end
    end
end

function World.loadSaveData(nSavegameVersion, saveData)
    World.bSuspendFixupVisuals = true
    World.bLoadingGame=true

    -- debug/testing code for good object tags.
    --[[
    for i=1,#SAVE_TYPES do
        for _,objType in ipairs(ObjectList.tSaveTypes) do
            if objType == SAVE_TYPES[i] and saveData[objType] then
                for _,t in ipairs(saveData[objType]) do
                    assertdev(not t._ObjectList_ObjectMarker or t._ObjectList_ObjectMarker.objType == objType)
                end
            end
        end
    end
    ]]--

    World.tileHealth = saveData.tileHealth or {}
    print('a')
    World.roomGrid:fill(0)
    World.pathGrid = LuaGrid.fromSaveData(saveData.pathGrid, false, {nDefaultVal=World.logicalTiles.SPACE})
    local tTiles = World.pathGrid.tTiles
    for addr,_ in pairs(tTiles) do
        if not World._isInBounds(World.pathGrid:cellAddrToCoord(addr)) then
            tTiles[addr] = nil
        end
    end
    
    World.oxygenGrid = LuaGrid.fromSaveData(saveData.oxygenGrid, false, {nDefaultVal=0,sGridClass='DFOxygenGrid'})
    World.oxygenGrid:getMOAIGrid():setVisualizationColors(Oxygen.COLOR_LOW[1],Oxygen.COLOR_LOW[2],Oxygen.COLOR_LOW[3],Oxygen.COLOR_HIGH[1],Oxygen.COLOR_HIGH[2],Oxygen.COLOR_HIGH[3])
    -- Hack: the o2 grid saves its generators, but EnvObjects will add them when
    -- they get loaded in.
    World.oxygenGrid:getMOAIGrid():clearGenerators()
    Pathfinder.staticInit()
    for x=1,World.width do
        for y=1,World.height do
            World._dirtyTile(x,y,true)
        end
    end
    print('b')
    World.loadOtherTypes(nSavegameVersion, saveData)
    
    print('c')
	World.tilesToExplore = {}
	if saveData.tilesToExplore then
		for _,v in ipairs(saveData.tilesToExplore) do
			World.tilesToExplore[v.k] = {x=v.x,y=v.y}
		end
	end
    
    print('d')

    -- using the fixupVisuals approach since just save/loading the saved tile data gives us ugly
    -- results when we update our tiles.    
    World.bSuspendFixupVisuals = false
    World.bLoadingGame=false
    
    World.fixupVisuals()

    --    if not nTeam or nTeam == Character.TEAM_ID_PLAYER then
        CommandObject.fromSaveTable(saveData.commandObject, nil,nil, true)
--    end

    if saveData.floorDecals then
        for addr,t in pairs(saveData.floorDecals) do
            World.setFloorDecal(t.tx,t.ty,t.sDecal,t.tColor)
        end
    end

    print('f')
end

function World.updateSavegame(nSavegameVersion, saveData)
    Room.updateSavegame(nSavegameVersion, saveData[ObjectList.ROOM])
    EnvObject.updateSavegame(nSavegameVersion, saveData[ObjectList.ENVOBJECT])
    Character.updateSavegame(nSavegameVersion, saveData[ObjectList.CHARACTER])
end

--[[
function World.cursorOverEmptyFloor(cursorX, cursorY)
    return World.tileOverEmptyFloor(World._getTileFromCursor(cursorX, cursorY))    
end

function World.worldOverEmptyFloor(worldX, worldY)    
    local returnX, returnY = World._getTileFromWorld(worldX, worldY)
    return World.tileOverEmptyFloor(returnX, returnY), returnX, returnY
end

function World.tileOverEmptyFloor(tileX, tileY)
    local tileValue = World._getTileValue(tileX, tileY)
    return World.countsAsFloor(tileValue) and World.propGrid:getTileValue(tileX, tileY) == 0
end
]]--

function World.getHackySortingZ(x,y,skipTileJustification)
    if not skipTileJustification then
        x,y = World.getTileJustifiedWorldPos(x,y)
    end
    local z = -y-World.height*World.tileHeightH*.5
    return z
end

function World.onTick(dt)
    -- just a random thing for testing
    --[[
    for i=1,60 do
        local tx = math.floor(math.random() * World.width)
        local ty = math.floor(math.random() * World.height)
        World.setWallDecal(tx, ty, "Damage", 5.0)
    end
    ]]--

    -- heal base damage over-time. HACK till we get in repairing
    for tileAddr,tHealthDetails in pairs(World.tileHealth) do
        if tHealthDetails.nHitPoints > 0 and tHealthDetails.nHitPoints < World.TILE_STARTING_HIT_POINTS then
            tHealthDetails.nHitPoints = math.min(tHealthDetails.nHitPoints + (World.TILE_HEAL_OVER_TIME * dt), World.TILE_STARTING_HIT_POINTS)
            local nHitPointPct = tHealthDetails.nHitPoints / World.TILE_STARTING_HIT_POINTS
            tHealthDetails.nHealth = math.floor(nHitPointPct * World.TILE_DAMAGE_HEALTHY)
        end
        World.updateHealthVisuals(tileAddr, tHealthDetails)
    end
    World.fixupVisuals()    
end

function World.updateHealthVisuals(tileAddr, tHealthDetails)
    if tHealthDetails.nHitPoints <= 0 or tHealthDetails.nHitPoints >= World.TILE_STARTING_HIT_POINTS then
        if World.floorDecals[tileAddr] then
            local tx,ty = World.pathGrid:cellAddrToCoord(tileAddr)
            World.setFloorDecal(tx,ty,nil)
        end
        if World.wallDecals[tileAddr] then
            local tx,ty = World.pathGrid:cellAddrToCoord(tileAddr)
            World.setWallDecal(tx,ty,nil)
        end
        World.tileHealth[tileAddr] = nil
    else
        local tx,ty = World.pathGrid:cellAddrToCoord(tileAddr)
        if World.countsAsFloor(World._getTileValue(tx,ty)) then
            local tDecal = World.floorDecals[tileAddr]
            if tDecal then
                local pct = 1-math.max(math.min(tHealthDetails.nHitPoints / World.TILE_STARTING_HIT_POINTS,1),0)
                -- set all the color values because premultiplied alpha.
                World.layers.worldFloorDecal.grid:setTileColor(tDecal.tx, tDecal.ty, pct,pct,pct,pct)
            else
                World.setFloorDecal(tx,ty, "char03")
            end
        else
            local tDecal = World.wallDecals[tileAddr]
            if tDecal then
                local rDecal = tDecal.tPropTable and tDecal.tPropTable['decal']
                if rDecal then 
                    local pct = 1-math.max(math.min(tHealthDetails.nHitPoints / World.TILE_STARTING_HIT_POINTS,1),0)
                    rDecal:setColor(pct,pct,pct,pct)
                end
            else
                World.setWallDecal(tx,ty, "Damage")
            end
        end
    end
end

-- Adds a decal at the cursor
function World.testFloorDecal(sDecal)
    local DFInput = require('DFCommon.Input')
    local x,y = DFInput.m_x, DFInput.m_y
    local tx, ty = World._getTileFromCursor(x, y)
    World.setFloorDecal(tx,ty,sDecal)
end

function World.setFloorDecal(tx,ty,sDecal,tColor)
    local addr = World.pathGrid:getCellAddr(tx,ty)
    if not sDecal then
        World.floorDecals[addr] = nil
        World.layers.worldFloorDecal.grid:setTileValue(tx,ty,0)
    else
        local tDecal = {}
        tDecal.tx = tx
        tDecal.ty = ty
        tDecal.sDecal=sDecal
        tDecal.tColor = tColor or {1.0, 1.0, 1.0, 1.0}
        World.floorDecals[addr] = tDecal
        
        local nSplat = World.layers.worldFloorDecal.spriteSheet.names[sDecal]
        World.layers.worldFloorDecal.grid:setTileValue(tx, ty, nSplat)
        World.layers.worldFloorDecal.grid:setTileColor(tx, ty, unpack(tDecal.tColor))
    end
end

function World.setWallDecal(tx,ty,sDecal)
    local tProp = World._getGridProp(World.layers.worldWall, tx, ty)
    
    -- first figure out what kind of wall this is
    if tProp and tProp.top then
        local addr = World.pathGrid:getCellAddr(tx,ty)
        if not sDecal then
            local oldProp = tProp.decal
            if oldProp then
                World._removeWallProp(World.layers.worldWall, tProp, "decal")
            end
            tProp.decal = nil
            World.wallDecals[addr] = nil
        else
            -- take decal type, figure out the wall type based on our indices
            local dir = World._getWallDirection(tx,ty)
            
            local sDirection = ""
            if dir == World.wallDirections.NESW or dir == World.wallDirections.NWSE then
                sDirection = "Straight01"
            elseif dir == World.wallDirections.V then
                sDirection = "Corner_outer01"
            elseif dir == World.wallDirections.GREATERTHAN then
                sDirection = "Corner_rb"
            elseif dir == World.wallDirections.LESSTHAN then
                sDirection = "Corner_lb"
            else
                sDirection = "Corner_inner01"
            end
            
            -- generate a full path for the decal sprite
            sDecal = sDecal .. "_" .. sDirection .. "_top"

            local top = tProp.top
            
            local topLocX,topLocY,topLocZ = top:getLoc()
            local tDetails = World._getWallTileDetails(tx, ty)
            local nSplat = World.layers.worldWall.spriteSheet.names[sDecal]
            World.wallDecals[addr] = {tx=tx,ty=ty,tPropTable=tProp}
            World._addWallSpriteToTable(World.layers.worldWall, tProp, tx, ty, 'decal', nSplat, tDetails.bFlip)
        end
    end
end

-- Gets the non-occupied location that best matches the direction vector and magnitude.
-- Location will be in a current or adjacent tile-- will not return a location more than
-- one tile away, regardless of magnitude.
-- If it fails to find a good match (e.g. the source loc is off the map), returns 
-- the input loc wx,wy.
function World.getTargetLoc(wx,wy,vx,vy,mag,bThroughCorners,bAllowSpace)
	local otx,oty = World._getTileFromWorld(wx,wy)
	local twx,twy = wx+vx*mag,wy+vy*mag
    local ttx,tty = World._getTileFromWorld(twx,twy)

    local destTileValue = World._getTileValue(ttx, tty)
    
    if World._areTilesAdjacent(otx,oty,ttx,tty,bThroughCorners,true) then
        if World._isPathable(ttx,tty, not bAllowSpace) then
            return twx,twy
        end
    end

    local newTX,newTY = World._getBestOpenNeighbor(wx,wy,vx,vy,bThroughCorners,bAllowSpace)
    if newTX then
        return World._getWorldFromTile(newTX,newTY)
    else
        return wx,wy
    end
end

function World.isPathable(wx,wy,bDisallowSpace)
    local tx,ty = World._getTileFromWorld(wx,wy)
    return World._isPathable(tx,ty,bDisallowSpace)
end

-- TODO: change bDisallowSpace to bAllowSpace. Called in lots of places. :P
function World._isPathable(tx,ty,bDisallowSpace)
    return not World._isPathBlocked(tx,ty,not bDisallowSpace)
end

function World._isPathBlocked(tx,ty,bAllowSpace)
    if Pathfinder.pathSoftBlocked(tx,ty) then return true end
    local tv = World._getTileValue(tx,ty)
    if tv == World.logicalTiles.SPACE or tv == World.logicalTiles.WALL_DESTROYED then return not bAllowSpace end
    return World.pathGrid:checkTileFlag(tx,ty, MOAIGridSpace.TILE_HIDE)
end

function World.getRandomDirection()
	return DFUtil.tableRandom(World.directions)
end

function World._getBestOpenNeighbor(wx,wy,vx,vy,bThroughCorners,bAllowSpace)
    local tx,ty = World._getTileFromWorld(wx,wy)

    if tx < 1 or ty < 1 or tx > World.width or ty > World.height then
        return nil
    end

    local tOptions = {}
    for i=2,((bThroughCorners and 9) or 5) do
        local dp = DFMath.dot(vx,vy, World.directionVectors[i][1], World.directionVectors[i][2])
        if dp > 0.1 then
            table.insert(tOptions, {dir=i, dp=dp, vx=vx,vy=vy})
        end
    end
    if #tOptions > 0 then
        table.sort(tOptions, function(a,b)
            return a.dp > b.dp
        end)

        for i=1,#tOptions do
            local atx,aty = _getAdjacentTile(tx,ty, tOptions[i].dir)
            if World._isPathable(atx,aty,not bAllowSpace) then return atx,aty end
        end
    end
end

function World.areWorldCoordsAdjacent(wx0,wy0,wx1,wy1,bThroughCorners,bOrEqual)
    local tileX0, tileY0 = World._getTileFromWorld(wx0,wy0)
    local tileX1, tileY1 = World._getTileFromWorld(wx1,wy1)

    return World._areTilesAdjacent(tileX0,tileY0,tileX1,tileY1,bThroughCorners,bOrEqual)
end

function World._areTilesAdjacent(tileX0,tileY0,tileX1,tileY1,bThroughCorners,bOrEqual)
    if bOrEqual and tileX0 == tileX1 and tileY0 == tileY1 then return true end

    -- example:
    -- for dir = (bOrEqual and _DIR_SAME or _DIR_DIAG_START),
    --           (bThroughCorners and _DIR_END or _DIR_DIAG_END)
    -- do
    --     local x,y = _getAdjacentTile(tileX0, tileY0, dir)
    --     if x == tileX1 and y == tileY1 then
    --         return true
    --     end
    -- end
    -- return false

    for i=2,((bThroughCorners and 9) or 5) do
        local x,y = _getAdjacentTile(tileX0,tileY0,i)
        if x == tileX1 and y == tileY1 then
            return true
        end
    end
    return false
end

function World.isAdjacentToFn(tileX, tileY, testFn, bThroughCorners, bIncludeSame)
    for i=((bIncludeSame and 1) or 2),((bThroughCorners and 9) or 5) do
        local x,y = _getAdjacentTile(tileX,tileY,i)
        if testFn(x,y) then return x,y,i end
    end
    return false
end

-- Avoids instant vacuums in vaporized tiles.
function World._cheatOxygen(tx,ty)
    local totalOxygen, totalCount = 0,0
    for i=2,5 do
        local atx,aty = _getAdjacentTile(tx,ty,i)
        local o2, bOcclude, bIndoors = World.oxygenGrid:getOxygen(atx,aty)
        if bIndoors and not bOcclude then
            totalOxygen = totalOxygen+o2
            totalCount = totalCount+1
        end
    end
    local newO2 = (totalCount > 0 and totalOxygen/totalCount) or 0
    World.oxygenGrid:setOxygen(tx,ty,newO2)
end

function World._demolishTile(tileX,tileY)
    local bDemolishedTile = false
    local tileValue = World._getTileValue(tileX, tileY)
    
    local objAtTile = ObjectList.getObjAtTile(tileX,tileY,ObjectList.ENVOBJECT)
    if objAtTile then
        objAtTile:remove()
        bDemolishedTile = true
    elseif World.countsAsWall(tileValue) then
        World._setTile(tileX, tileY, World.logicalTiles.ZONE_LIST_START,true)
        bDemolishedTile = true
    else
        bDemolishedTile = Asteroid.vaporizeTile(tileX,tileY,tileValue,false)
    end
    if bDemolishedTile then
        World._cheatOxygen(tileX,tileY)
        local room = Room.getRoomAtTile(tileX,tileY,1)
        if room then
            room:tileVaporized(tileX,tileY,1)
        end
        
        local tileAddr = World.pathGrid:getCellAddr(tileX, tileY)
        World.tileHealth[tileAddr] = nil
    end
    
    return bDemolishedTile
end

function World._getEnvObjectOnWall(tileX, tileY)
    local nOffsetX = 1
    local nOffsetY = -1
    local tDetails = World._getWallTileDetails(tileX, tileY)
    if tDetails and tDetails.bFlip then
        nOffsetX = -1
    end
    local objAtTile = ObjectList.getObjAtTile(tileX+nOffsetX,tileY+nOffsetY,ObjectList.ENVOBJECT)
    if objAtTile then
        -- verify
        local objWallTileX, objWallTileY = objAtTile:getWallTile()
        if objWallTileX == tileX and objWallTileY == tileY then
            return objAtTile
        end
    end
    return nil
end

function World._vaporizeTile(tileX,tileY)
    local bVaporizedTile = false
    
    local objAtTile = ObjectList.getObjAtTile(tileX,tileY,ObjectList.ENVOBJECT)
    if objAtTile then
        objAtTile:vaporize()
        bVaporizedTile = true
    end
    local tileValue = World._getTileValue(tileX, tileY)
    if World.countsAsWall(tileValue) or World.countsAsFloor(tileValue) then
        if World.countsAsWall(tileValue) then
            -- destroy the object
            local rObjOnWall = World._getEnvObjectOnWall(tileX, tileY)
            if rObjOnWall then
                rObjOnWall:vaporize()
            end
            World.setWallDecal(tileX, tileY, nil)
        elseif World.countsAsFloor(tileValue) then
            World.setFloorDecal(tileX, tileY, nil)
        end
        World._setTile(tileX, tileY, World.logicalTiles.SPACE,true)
        bVaporizedTile = true
    else
        bVaporizedTile = Asteroid.vaporizeTile(tileX,tileY,tileValue,true)
    end
    if bVaporizedTile then
        World._cheatOxygen(tileX,tileY)
        local room = Room.tRooms[World.roomGrid:getTileValue(tileX, tileY)]
        if room then
            local wx,wy = World._getWorldFromTile(tileX,tileY)
            room:tileVaporized(wx,wy,tileX,tileY)
        end
        
        local tileAddr = World.pathGrid:getCellAddr(tileX, tileY)
        World.tileHealth[tileAddr] = nil
    end
    
    return bVaporizedTile
end

function World.isAdjacentToTile(tileX, tileY, tx2, ty2, bThroughCorners, bIncludeSame)
    local testFn = function(tx,ty) return tx2 == tx and ty2 == ty end
    return World.isAdjacentToFn(tileX,tileY, testFn, bThroughCorners, bIncludeSame)
end

function World.isAdjacentToWall(tileX, tileY, bThroughCorners, bIncludeSame)
    local testFn = function(tx,ty) return World.countsAsWall(World._getTileValue(tx,ty)) end
    return World.isAdjacentToFn(tileX,tileY, testFn, bThroughCorners, bIncludeSame)
end

function World.isAdjacentToFloor(tileX, tileY, bThroughCorners, bIncludeSame)
    local testFn = function(tx,ty) return World.countsAsFloor(World._getTileValue(tx,ty)) end
    return World.isAdjacentToFn(tileX,tileY, testFn, bThroughCorners, bIncludeSame)
end

function World.isAdjacentTo(tileX, tileY, bThroughCorners, value, bIncludeSame)
    return World.isAdjacentToFn(tileX,tileY, function(tx,ty) return World._getTileValue(tx,ty) == value end, bThroughCorners, bIncludeSame)
end

function World.isAdjacentToObj(tileX, tileY, bThroughCorners, obj, bIncludeSame)
    local fn = function(tx,ty)
        return ObjectList.isTagAtTile(tx,ty,obj.tag)
    end
    return World.isAdjacentToFn(tileX,tileY, fn, bThroughCorners, bIncludeSame)
end

function World.isAdjacentToBase(tileX, tileY, bThroughCorners, zoned, bIncludeSame)
    local testFn = function(tx,ty) 
        local tv = World._getTileValue(tx,ty)
        return World.countsAsFloor(tv) or World.countsAsWall(tv) or CommandObject.getConstructionAtTile(tx, ty)
    end
    return World.isAdjacentToFn(tileX,tileY, testFn, bThroughCorners, bIncludeSame)
end

function World.isAdjacentToSpace(tileX, tileY,bThroughCorners, bIncludeSame)
    local testFn = function(tx,ty) return World._getTileValue(tx,ty) == World.logicalTiles.SPACE end
    return World.isAdjacentToFn(tileX,tileY, testFn, bThroughCorners, bIncludeSame)
end

function World.isDestroyedWallAdjacentToSpace(tileX, tileY)
    local tileValue = World._getTileValue(tileX, tileY)
    return tileValue == World.logicalTiles.WALL_DESTROYED and World.isAdjacentToSpace(tileX, tileY, true)
end

function World.isDestroyedWallAdjacentToSpaceFromWorld(wx, wy)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    return World.isDestroyedWallAdjacentToSpace(tileX, tileY)
end

function World.getTileValueFromWorld(wx, wy)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    local tileValue = World._getTileValue(tileX, tileY)
    return tileValue
end

function World.clearPropReservation(worldX, worldY, propName, roomID)
    local tx,ty = World._getTileFromWorld(worldX,worldY)
    return World._clearPropReservation(tx,ty,propName,roomID)
end

function World._clearPropReservation(tx, ty, propName, roomID)
    if not roomID then roomID = nil end -- Lua!    
    local tag = ObjectList.getTagAtTile(tx,ty,ObjectList.RESERVATION)
    if tag then
        local x,y = World.pathGrid:cellAddrToCoord(tag.addr)
        if x == tx and y == ty and (not tag.roomID or roomID == tag.roomID) then
            ObjectList.removeObject(tag)
        end
    else
        if not World.bLoadingGame and not World.bLoadingModule then
            Print(TT_Warning, 'Incorrect reservation clear.')
        end
    end
end

-- We don't have a prop ID yet, so we make the reservation under the room ID.
-- This doesn't cause confusion, because we set the TILE_HIDE flag in only this case.
function World.makePropReservation(worldX, worldY, propName,bFlipX,bFlipY,roomID)
    ObjectList.addObject(ObjectList.RESERVATION, propName, {}, nil, false, false, worldX, worldY, bFlipX, bFlipY)
end

-- MTF BUILD DAY HACK:
-- There are lots of things that get EnvObject flips, etc. & turn them into front/rear directions;
-- unify across the functions here and in EnvObject
function _flipsToRearDirection(bFlipX,bFlipY)
            if bFlipX then
				if bFlipY then
					return World.directions.SE
                else
                    return World.directions.NE
				end
            else
				if bFlipY then
					return World.directions.SW
                else
                    return World.directions.NW
				end
            end
end

-- returns: bFound,tx,ty,bFlipX,bFlipY,tValid,tInvalid
-- tx,ty are the first failed coords if bFound is false
function World._findPropFit(tx,ty,propName,bForceFlipX,bForceFlipY,bReturnTileLists,bAllowRezone)
    local bSuccess
    local tData = EnvObject.getObjectData(propName)
    local bTestOnce = true
    if tData.againstWall or tData.width ~= tData.height or tData.door then
        bTestOnce = false
    end
    if bForceFlipX == nil then
        if not EnvObject.canFlipX(propName) then
            bForceFlipX = false
        end
    end
    if bForceFlipY == nil then
        if not EnvObject.canFlipY(propName) then
            bForceFlipY = false
        end
    end
    if tData.autoFlip then
        bForceFlipX,bForceFlipY = nil,nil
    else
        if bForceFlipX == nil then
            bForceFlipX = false
        end
    end
    
    assertdev(not bForceFlipX or EnvObject.canFlipX(propName))
    assertdev(not bForceFlipY or EnvObject.canFlipY(propName))
    
    local tValidTiles,tInvalidTiles = nil,nil
    local tValidTilesSaved,tInvalidTilesSaved = nil,nil
    local txFirstFail,tyFirstFail=nil,nil
    if bReturnTileLists then
        tValidTiles,tInvalidTiles = {},{}
    end

    local rCursorWall = nil
    local rTileWall = nil
    local bTileAsteroid = false
    if tData.againstWall then
        local wx,wy = World._getWorldFromTile(tx,ty)
        rCursorWall = g_GuiManager._getTargetAt(wx,wy,'wall')
        local potentialWallVal = World._getTileValue(tx,ty)
        if potentialWallVal == World.logicalTiles.WALL then
            rTileWall = World.tWalls[World.pathGrid:getCellAddr(tx,ty)]
            if rTileWall then
                rTileWall.tx,rTileWall.ty = tx,ty
            end
        elseif Asteroid.isAsteroid(potentialWallVal) then
            bTileAsteroid = true
        end
    end
    
    for i=1,4 do
        local txTest,tyTest = tx,ty
        local bFlipX,bFlipY
        if i == 1 then
            bFlipX,bFlipY = false,false
        elseif i == 2 then
            bFlipX,bFlipY = false,true
        elseif i == 3 then
            bFlipX,bFlipY = true,false
        else -- i == 4
            bFlipX,bFlipY = true,true
        end
        -- Placement assist for against-wall props.
        -- Look at the tile in front of the wall that the mouse cursor hits, but only if the wall is facing
        -- a direction that the prop could mount on.
        -- MTF: build day hackery. Code is pretty messy here, but the logic is reasonably close to what we want.
        local bWalled = false
        if rCursorWall then
            local awayFromWallDir
            if rCursorWall.bFlip then
                awayFromWallDir = (bFlipY and g_World.directions.NE) or g_World.directions.SW
            else
                awayFromWallDir= (bFlipY and g_World.directions.NW) or g_World.directions.SE
            end
            local propDir = _flipsToRearDirection(bFlipX,bFlipY)
            if World.oppositeDirections[propDir] == awayFromWallDir then
                txTest,tyTest = g_World._getAdjacentTile(rCursorWall.tx,rCursorWall.ty,awayFromWallDir)
                bWalled = true
            end
        end
        if rTileWall and not bWalled then
            local awayFromWallDir
            if rTileWall.bFlip then
                awayFromWallDir = (bFlipY and g_World.directions.NE) or g_World.directions.SW
            else
                awayFromWallDir = (bFlipY and g_World.directions.NW) or g_World.directions.SE
            end
            local propDir = _flipsToRearDirection(bFlipX,bFlipY)
            if World.oppositeDirections[propDir] == awayFromWallDir then
                txTest,tyTest = g_World._getAdjacentTile(rTileWall.tx,rTileWall.ty,awayFromWallDir)
            end
        end
        if bTileAsteroid and not bWalled then
            if bFlipX then
                txTest,tyTest = g_World._getAdjacentTile(tx,ty,g_World.directions.SW)
            else
                txTest,tyTest = g_World._getAdjacentTile(tx,ty,g_World.directions.SE)
            end
        end

        if (bFlipX == bForceFlipX or bForceFlipX == nil) and (bFlipY == bForceFlipY or bForceFlipY == nil) then
            bSuccess = World._checkPropFit(txTest, tyTest, propName, bFlipX, bFlipY, bAllowRezone, tValidTiles,tInvalidTiles)
            if bSuccess then return true,txTest,tyTest,bFlipX,bFlipY,tValidTiles,tInvalidTiles end
            if not txFirstFail then
                txFirstFail,tyFirstFail = txTest,tyTest
            end
            if bReturnTileLists then
                if not tValidTilesSaved then
                    tValidTilesSaved,tInvalidTilesSaved = tValidTiles,tInvalidTiles
                end
                tValidTiles,tInvalidTiles = {},{}
            end
            if bTestOnce then break end
        end
    end
    return false,txFirstFail,tyFirstFail,bForceFlipX,bForceFlipY, tValidTilesSaved, tInvalidTilesSaved
end

-- if you pass tValidTiles and tInvalidTiles, World will fill them out for you.
function World._checkPropFit(tileX, tileY, propName, bFlipX, bFlipY, bAllowRezone, tValidTiles,tInvalidTiles)
    local affectedTiles,bAgainstWall = World._getPropFootprint(tileX, tileY, propName, true,bFlipX, bFlipY)
    local tData = EnvObject.getObjectData(propName)
    if tData.againstWall and not bAgainstWall then
        if tValidTiles then
            local txWall,tyWall
            if bFlipX then
				if bFlipY then
					txWall,tyWall = _getAdjacentTile(tileX,tileY,World.directions.SE)
                else
                    txWall,tyWall = _getAdjacentTile(tileX,tileY,World.directions.NE)
				end
            else
				if bFlipY then
					txWall,tyWall = _getAdjacentTile(tileX,tileY,World.directions.SW)
                else
                    txWall,tyWall = _getAdjacentTile(tileX,tileY,World.directions.NW)
				end
            end
            local wallTileAddr = World.pathGrid:getCellAddr(txWall,tyWall)
            tInvalidTiles[wallTileAddr] = {x=txWall,y=tyWall,addr=wallTileAddr}
        else
            return false
        end
    end
	
    if tData.door then
        local lastDir = nil
        for i,tile in ipairs(affectedTiles) do 
            local wallDir = World._getWallDirection(World.pathGrid:cellAddrToCoord(tile))
            local bValid = true
            if (lastDir and lastDir ~= wallDir) then
                bValid = false
            end
            if wallDir ~= World.wallDirections.NWSE and wallDir ~= World.wallDirections.NESW then
                bValid = false
            end
            if bFlipX and wallDir == World.wallDirections.NESW then
                bValid = false
            end
            if not bFlipX and wallDir == World.wallDirections.NWSE then
                bValid = false
            end
            
            if GameRules.inEditMode then
                bValid = true
            end
            
            if tValidTiles then
                local txDoor,tyDoor = World.pathGrid:cellAddrToCoord(tile)
                if bValid then tValidTiles[tile] = {x=txDoor,y=tyDoor,addr=tile}
                else tInvalidTiles[tile] = {x=txDoor,y=tyDoor,addr=tile} end
            elseif not bValid then
                return false
            end
            lastDir = wallDir
        end
    end
    
    local affectedTilesNoMargin = {}
    if tData.margin and tData.margin > 0 then
        affectedTilesNoMargin = World._getPropFootprint(tileX, tileY, propName, false,bFlipX)
    end
    
    for i,tile in ipairs(affectedTiles) do 
        local tx,ty = World.pathGrid:cellAddrToCoord(tile)
        local tileValue = World._getTileValue(tx,ty)
        local bValid=true
        if not tData.door and (not World._isPathable(tx,ty) or tileValue == World.logicalTiles.DOOR) then
            bValid = false
        end
        if tData.door and tileValue == World.logicalTiles.DOOR then
            bValid = false
        end
		if tData.bCanBuildInSpace and tileValue == World.logicalTiles.SPACE then
			bValid = true
		end
        local objAtTile = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT)
        local resAtTile = ObjectList.getReservationAt(tx,ty)
        local tOccupyingObjData
        if objAtTile then
			tOccupyingObjData = objAtTile.tData
		elseif resAtTile then
			tOccupyingObjData = EnvObject.getObjectData(resAtTile.objSubtype)
		end
        if tOccupyingObjData then
            -- check if this tile blocks pathing. 
            if tOccupyingObjData.bBlocksPathing then
                bValid = false
            elseif tData.margin and tData.margin > 0 then
                local bInsideObjectNoMargin = false
            
                --if it doesn't, check if this tile is in the margin for this prop
                for _,noMarginTile in pairs(affectedTilesNoMargin) do
                    if noMarginTile == tile then
                        bInsideObjectNoMargin = true
                        break
                    end
                end
                
                -- otherwise, nope
                bValid = not bInsideObjectNoMargin
            else
                bValid = false
            end
        end
        
        if bValid then
            local rRoom = Room.getRoomAtTile(tx,ty,1)
            if rRoom and rRoom:getVisibility() == g_World.VISIBILITY_HIDDEN  then
                bValid = false
            elseif tData.zoneName and not EnvObject.allowObjInRoom(tData,rRoom) then
                bValid = false
				-- allow zone-specific objects to "auto-zone" unzoned rooms
				if rRoom and not bValid and bAllowRezone and rRoom:getZoneName() == 'PLAIN' then
					bValid = true
				end
            end
        end
        
        if tValidTiles then
            if tInvalidTiles[tile] then
                -- nothing. tile was already decided to be invalid.
            elseif bValid then
                tValidTiles[tile] = {x=tx,y=ty,addr=tile}
            else
                tInvalidTiles[tile] = {x=tx,y=ty,addr=tile}
            end
        elseif not bValid then
            return false
        end
    end

    if tValidTiles then
        return not next(tInvalidTiles)
    else
        return true
    end
end

--
-- keep running list of walls for cutaway mode
--
function World.removeWall(tileAddr,tPropList)
    if not tPropList then
        World.tWalls[tileAddr] = nil
    else
        local tWallProps = World.tWalls[tileAddr]
        if tWallProps then
            for k,v in pairs(tPropList) do
                if tWallProps[k] == v then
                    tWallProps[k] = nil
                end
            end
            if not next(tWallProps) then 
                World.tWalls[tileAddr] = nil 
            end
        end
    end
end

function World.addWall(tileAddr, tDetails)
    assertdev(tDetails and tDetails.tProps)
    World.tWalls[tileAddr] = tDetails
end

function World.removeAsteroid(tileAddr)
	World.tAsteroids[tileAddr] = nil
end

function World.addAsteroid(tileAddr, prop)
	World.tAsteroids[tileAddr] = prop
end

function World.updateCutaway(bShowSpace)
	local wallLayer = Renderer.getRenderLayer('WorldWall')
	-- update walls
    for addr, tWall in pairs(Room.tWallsByAddr) do
        local bShow = not GameRules.cutawayMode
        local tDetails = World.tWalls[addr]
        local propTable = tDetails and tDetails.tProps
        if propTable then
            local id = tWall.tDirs[6] or tWall.tDirs[3] or tWall.tDirs[2]
            local r = id and Room.tRooms[id]
            if bShowSpace then
                if r then
                    bShow = bShow or (r:getVisibility() == World.VISIBILITY_HIDDEN)
                end
            else
                bShow = bShow or (not r or (r:getVisibility() == World.VISIBILITY_HIDDEN))
            end
            if propTable.top then
                if bShow then
                    wallLayer:insertProp(propTable.top)
                else
                    wallLayer:removeProp(propTable.top)
                end
                propTable.top:setVisible(bShow)
                propTable.top.bVisible = bShow
            end
            if propTable.decal then
                if bShow then
                    wallLayer:insertProp(propTable.decal)
                else
                    wallLayer:removeProp(propTable.decal)
                end
                propTable.decal:setVisible(bShow)
                propTable.decal.bVisible = bShow
            end
        end
    end
	-- update asteroids
	for addr,prop in pairs(World.tAsteroids) do
		local wx, wy = World._getWorldFromAddr(addr)
		local tx, ty = World._getTileFromWorld(wx, wy)
		local nTileValue = World._getTileValue(tx, ty)
		local sSpriteName = Asteroid.getSpriteName(nTileValue)
		local index = World.layers.worldWall.spriteSheet.names[sSpriteName]
		prop:setIndex(index)
	end
end

function World.buildTile(worldX, worldY)
    local tx, ty = World._getTileFromWorld(worldX, worldY)
	local rv = World._buildTile(tx,ty)
    return rv
end

function World._buildTile(tileX,tileY,param)
    local tileAddr = World.pathGrid:getCellAddr(tileX, tileY)
    local tileValue = World._getTileValue(tileX, tileY)    
    local bSuccess = true
    
    -- clear damage
    World.tileHealth[tileAddr] = nil
    
    -- TODO: remove decals?
    
    if param == CommandObject.BUILD_PARAM_VAPORIZE then
        bSuccess = World._vaporizeTile(tileX,tileY)
    elseif param == CommandObject.BUILD_PARAM_DEMOLISH then
        bSuccess = World._demolishTile(tileX,tileY)
    elseif param then
        World._setTile(tileX, tileY, param)
    elseif GameRules.inEditMode and World.countsAsFloor(tileValue) then
        World._setTile(tileX, tileY, World.logicalTiles.WALL)
    elseif GameRules.inEditMode and tileValue == World.logicalTiles.SPACE then
        World._setTile(tileX, tileY, World.logicalTiles.WALL)        
    else
        bSuccess = false
    end
    CommandObject._invalidateCommandTile(tileAddr)
    return bSuccess
end

function World.canBuildFloor(tileX, tileY)
    local tile = World._getTileValue(tileX, tileY)
    return tile == World.logicalTiles.SPACE
end



function testWallPlacementIntersectsProp(sPropName,wallAddr,wtx,wty,ptx,pty,bFlipX,bFlipY)
    local tPropData = EnvObject.getObjectData(sPropName)
    if tPropData and tPropData.margin and tPropData.margin > 0 and MiscUtil.isoDist(wtx,wty,ptx,pty) <= (tPropData.margin + math.max(tPropData.width,tPropData.height)) then
        local tFootprint = World._getPropFootprint(ptx,pty, sPropName, true, bFlipX, bFlipY,true)
        if tFootprint[wallAddr] then 
            return true
        end
    elseif tPropData.againstWall then
        if ptx == wtx and pty == wty then
            return true
        end
    end
    
    return false
end

function World.canBuildWall(tx, ty)
    local tile = World._getTileValue(tx, ty)
    if tile == World.logicalTiles.WALL_DESTROYED then return true end
    if tile ~= World.logicalTiles.SPACE and not World.countsAsFloor(tile) then
        return false
    end
    if ObjectList.pathBlockedByObject(tx,ty) then
        return false
    end
    if ObjectList.getDoorAtTile(tx,ty) then
        return false
    end
    
    -- Iterate over all props in the room and check to see if their margins block wall building.
    -- I'd much rather store prop margins in the grid, but we're a bit close to ship to monkey
    -- with the ObjectList that much.
    local rRoom = Room.getRoomAtTile(tx,ty,1)
    if rRoom then
        local addr = World.pathGrid:getCellAddr(tx, ty)    
        for rProp,_ in pairs(rRoom.tProps) do
            local ptx,pty = rProp:getTileLoc()
            if testWallPlacementIntersectsProp(rProp.sName,addr,tx,ty,ptx,pty,rProp.bFlipX,rProp.bFlipY) then
                return false
            end
        end
        for _,coord in pairs(rRoom.tDoors) do
            local rDoor = ObjectList.getDoorAtTile(coord.x,coord.y)
            if rDoor and rDoor:isInFrontOfDoor(addr) then
                return false 
            end
        end
        for _,tData in pairs(rRoom.tPropPlacements) do
            if testWallPlacementIntersectsProp(tData.sName,addr,tx,ty,tData.tx,tData.ty,tData.bFlipX,tData.bFlipY) then
                return false
            end
        end
    end
    
    return true
end

function World.isAreaSpace(minX, minY, maxX, maxY)
    for i = minX, maxX do
        for j = minY, maxY do            
            if World.pathGrid:getTileValue(i, j) ~= World.logicalTiles.SPACE then
                return false
            end
        end
    end
    return true
end

function World.countsAsWall(tile)
    return (tile == World.logicalTiles.WALL or tile == World.logicalTiles.WALL_DESTROYED)
end

function World.countsAsFloor(tile)
    return (tile >= World.logicalTiles.ZONE_LIST_START and tile <= World.logicalTiles.ZONE_LIST_END)           
end

function World._getGridProp(layer, x,y)
    return layer.props[(y-1)*World.width+x]
end

function World._createWallProp(layer, x, y, side, bFlip, bIgnoreLighting, bTop)
    local prop =  MOAIProp.new()
    prop:setDeck(layer.spriteSheet)
    local wx,wy = layer.grid:getTileLoc(x,y,MOAIGridSpace.TILE_LEFT_TOP)
    
    local rRenderLayer = layer.renderLayer
    
    wx,wy = wx+layer.originX, wy+layer.originY
    
	if bFlip then
		prop:setScl(-1, 1)
		wx = wx + 128
		wy = wy + 0
	end
	
    local wz = World.getHackySortingZ(wx, wy+World.tileHeightH);

    Lighting.setWallLightUVs(x, y, prop, bIgnoreLighting)
    if not bIgnoreLighting then
        local rMaterial = require("Renderer").getGlobalMaterial("wallLight")
        prop:setMaterial(rMaterial)    
    end
    
    rRenderLayer:insertProp(prop)
    prop:setLoc(wx,wy, wz)

    prop.bWall,prop.tx,prop.ty,prop.bFlip,prop.bTop = true,x,y,bFlip,bTop
    
    return prop
end

function World._removeWallProp(layer, propTable, side)
    assert(propTable[side])
    layer.renderLayer:removeProp(propTable[side])
    if propTable[side..'Light'] then
        Renderer.getRenderLayer('Light'):removeProp(propTable[side..'Light'])
        propTable[side..'Light'] = nil
    end
    propTable[side] = nil
end

function World._addWallSpriteToTable(rLayer, tTable, tx,ty, sSlotId, nIndex, bFlip, bIgnoreLighting, sPropType)
    if nIndex and nIndex ~= 0 then
		local wx,wy = rLayer.grid:getTileLoc(tx,ty,MOAIGridSpace.TILE_LEFT_TOP)
		wx,wy = wx+rLayer.originX, wy+rLayer.originY
		local wz = 0
		if not tTable[sSlotId] then
			tTable[sSlotId] = World._createWallProp(rLayer, tx, ty, sSlotId, bFlip, bIgnoreLighting, sSlotId == "top")
			-- if setting index on a pre-existing prop, scale may not be what
			-- we want, so set it manually
		elseif bFlip then
			tTable[sSlotId]:setScl(-1, 1)
			-- flipped walls need a different offset
			wx = wx + 128
			wz = World.getHackySortingZ(wx,wy+World.tileHeightH)
			tTable[sSlotId]:setLoc(wx, wy, wz)
		else
			tTable[sSlotId]:setScl(1, 1)
			wz = World.getHackySortingZ(wx,wy+World.tileHeightH)
			tTable[sSlotId]:setLoc(wx, wy, wz)
		end
		tTable[sSlotId]:setIndex(nIndex)
        
        -- do something here to handle cutaway mode when constructing the object
        if sPropType == "asteroid" then
            tTable[sSlotId]:setVisible(true)
        elseif sSlotId == "top" or sSlotId == "decal" then
            local bShow = not GameRules.cutawayMode
            
            if World._getVisibility(tx, ty,1) ~= World.VISIBILITY_HIDDEN then
                tTable[sSlotId]:setVisible(bShow)
                tTable[sSlotId].bVisible = bShow
            end
        end

    elseif tTable[sSlotId] then
		World._removeWallProp(rLayer, tTable, sSlotId)
    end
end

function World.getCachedWallProps(tx, ty)
    local addr = World.pathGrid:getCellAddr(tx, ty)
    
    return World.layers.worldWall.props[addr]
end

function World._getWallPropTable(layer, x, y, nTopIndex, nBottomIndex, bFlip, bIgnoreLighting, tExistingTable, sPropType)
	-- walls consist of multiple props, specified by top+bottom values
	--local idx = (y-1)*World.width+x
	--local propTable = { }
    
    if not sPropType then sPropType = "unknown" end
	
    local propTable = tExistingTable or {}

    World._addWallSpriteToTable(layer, propTable, x,y, 'bottom', nBottomIndex, bFlip, bIgnoreLighting, sPropType)
    World._addWallSpriteToTable(layer, propTable, x,y, 'top', nTopIndex, bFlip, bIgnoreLighting, sPropType)
	
	return propTable
end

function World._setGridTile(layer, x, y, nTopIndex, nBottomIndex, bFlip, sPropType)
	layer.grid:setTileValue(x,y,nTopIndex)

    local propTable = nil
    if layer == World.layers.worldWall or layer == World.layers.worldCeiling then
	    local idx = (y-1)*World.width+x
        if not layer.props[idx] then layer.props[idx] = {} end
        if layer == World.layers.worldWall then
		    
            propTable = World._getWallPropTable(layer, x, y, nTopIndex, nBottomIndex, bFlip, false, layer.props[idx], sPropType)
        else
            World._addWallSpriteToTable(layer, layer.props[idx], x,y, 'ceiling', nTopIndex, bFlip)
        end
	end
    
    if nTopIndex ~= 0 then
        -- ISO TEST HACK: destroy walls when placing floors; vice versa.
        if layer == World.layers.worldFloor then
            World._setGridTile(World.layers.worldWall, x, y, 0, 0, 0)
            if World._getVisibility(x,y,1) ~= World.VISIBILITY_HIDDEN then
                World._setGridTile(World.layers.worldCeiling, x, y, 0)
            end
        elseif layer == World.layers.worldWall then
            World._setGridTile(World.layers.worldFloor, x, y, 0)
            if World._getVisibility(x,y,1) ~= World.VISIBILITY_HIDDEN then
                World._setGridTile(World.layers.worldCeiling, x, y, 0)
            end
        elseif layer == World.layers.worldCeiling then
            --World._setGridTile(World.layers.worldFloor, x, y, 0)
            --World._setGridTile(World.layers.worldWall, x, y, 0, 0, 0)
        end
    end
    
    return propTable
end

function World._setGridLocColor(tx, ty, worldColor, bFlip)
    local tileColor = {worldColor[1], worldColor[2], worldColor[3], worldColor[4]}

    -- this is the color result for tile-based lighting (only used for walls at the moment, floors are lit using
    --  shader stuff.
    local tLitTileColor = {worldColor[1], worldColor[2], worldColor[3], worldColor[4]}
    
    local tLightColor = Lighting.getAmbientLightColorForTile(tx, ty)
    -- for now we're applying light as a tint here... which is a little gross and can totally be better eventually
    for k,v in ipairs(tLightColor) do
        tLitTileColor[k] = v * tLightColor[k]
    end
   
    World.layers.worldFloor.grid:setTileColor(tx, ty, unpack(tLitTileColor))
end

function World._updateOxygenFlags(tx,ty,logicalValue)
    logicalValue = logicalValue or World._getTileValue(tx,ty)
    if World._shouldObstructOxygen(tx,ty,logicalValue) then
        World.oxygenGrid:setTileFlag(tx,ty,DFOxygenGrid.TILE_OCCLUDE)
    else
        World.oxygenGrid:clearTileFlag(tx,ty,DFOxygenGrid.TILE_OCCLUDE)
    end
    if logicalValue == World.logicalTiles.SPACE then
        World.oxygenGrid:clearTileFlag(tx,ty,DFOxygenGrid.TILE_INDOORS)
    else
        World.oxygenGrid:setTileFlag(tx,ty,DFOxygenGrid.TILE_INDOORS)
    end
end

--[[
World.tWallAddrToBlob={addr=tBlob,addr=tBlob,addr=tBlob...}
]]--

-- 
function _floodWallBlob(tx,ty,tBlobData,tScratch)
    -- if wall already in blobdata: bail.
    -- if wall already on another blob in the world: merge this into it, then... return the new table... and still recurse, on the new table.
    -- if neither: add and recurse.

	local addr = World.pathGrid:getCellAddr(tx,ty)
    if tScratch[addr] then return tBlobData end
    tScratch[addr] = true
    -- already flooded. bail.
    if tBlobData.tWallAddrs[addr] then return tBlobData end

    -- It's in another blob. Merge this blob into that one.
    if World.tWallAddrToBlob[addr] then
        local tTargetBlob = World.tWallAddrToBlob[addr] 
        for id,_ in pairs(tBlobData.tRooms) do
            if Room.tRooms[id] then
                Room.tRooms[id].tWallBlobs[tBlobData] = nil
                Room.tRooms[id].tWallBlobs[tTargetBlob] = true
                tTargetBlob.tRooms[id] = true
            end
        end
        for addr,_ in pairs(tBlobData.tWallAddrs) do
            -- point all walls in this blob to the new target blob.
            tTargetBlob.tWallAddrs[addr] = true
            World.tWallAddrToBlob[addr] = tTargetBlob
        end
        tBlobData.tWallAddrs = {}
        return tTargetBlob
    end

    if Room.tWallsByAddr[addr] then
        -- This wall belongs to a room (or rooms). Mark the adjacency.
        for i=2,9 do
            local id = Room.tWallsByAddr[addr].tDirs[i] 
            if id then
                Room.tRooms[id].tWallBlobs[tBlobData] = true
                tBlobData.tRooms[id] = true
            end
        end
    else
        -- yay more blob
        World.tWallAddrToBlob[addr] = tBlobData
        tBlobData.tWallAddrs[addr] = true
        for i=2,5 do
            local atx,aty = _getAdjacentTile(tx,ty,i)
            local logicalValue = World._getTileValue(atx,aty)
            if logicalValue == World.logicalTiles.WALL then
                tBlobData = _floodWallBlob(atx,aty,tBlobData,tScratch)
            end
        end
    end
    return tBlobData
end

-- Updates the visuals for the appropriate tiles
function World.fixupVisuals()
    if World.bSuspendFixupVisuals then
        return
    end

    Room.updateDirty()

    Profile.enterScope("World.fixupVisuals")

    for addr,coord in pairs(World.tDirtyWallTiles) do
        if not World.tWallAddrToBlob[addr] and not Room.tWallsByAddr[addr] then
            local logicalValue = World._getTileValue(coord.x,coord.y)
            if logicalValue == World.logicalTiles.WALL then
                local tNewBlob = { tRooms={}, tWallAddrs={} }
                _floodWallBlob(coord.x,coord.y,tNewBlob,{})
            end
        end
    end
    World.tDirtyWallTiles = {}

    local numTilesDirty = #World.dirtyVisualTiles
    
    for i,tile in ipairs(World.dirtyVisualTiles) do
        local tx,ty = tile.x,tile.y
        local logicalValue = World._getTileValue(tx, ty)

		local tileAddr = World.pathGrid:getCellAddr(tx,ty)
        if logicalValue == World.logicalTiles.SPACE then
            -- Clear the world visuals
            World._setGridTile(World.layers.worldFloor,tx,ty,0)
            World._setGridTile(World.layers.worldWall,tx,ty,0, 0, 0)
            Lighting.setTile(tx, ty, 0)
            World._setGridTile(World.layers.space,tx,ty,World.visualTiles.space.index)
            World._setGridTile(World.layers.worldCeiling,tx,ty, 0)
        else
			local bFlip = false
            -- Do fancy logic to pick the right visual tiles
            local asteroidSprite = Asteroid.getSpriteName(logicalValue)

            if World._getVisibility(tx,ty,1) == World.VISIBILITY_HIDDEN then
                local sSpriteName = World.fogRoofSpriteName
                local idx = World.layers.worldCeiling.spriteSheet.names[sSpriteName]
                assert(idx and idx > 0)
                World._setGridTile(World.layers.worldCeiling,tx,ty, idx)
            else
                World._setGridTile(World.layers.worldCeiling,tx,ty, 0)
            end
            if asteroidSprite then
                local propTable = World._setGridTile(World.layers.worldWall,tx,ty,World.layers.worldWall.spriteSheet.names[asteroidSprite], nil, false, "asteroid")
				World.addAsteroid(tileAddr, propTable.top)
            elseif logicalValue == World.logicalTiles.WALL then
                -- walls have top and bottom
                local tDetails = World._getWallTileDetails(tx, ty)
                if tDetails.topIdx then -- top & bottom may be nil, as in the fog of war case.
			        bFlip = tDetails.bFlip
                    local wallPropTable = World._setGridTile(World.layers.worldWall, tx, ty, tDetails.topIdx, tDetails.bottomIdx, tDetails.bFlip)
			        -- add to global list of walls for cutaway
			        -- (walls are removed in _setTile)
                    --if World._getVisibility(tx,ty,1) ~= World.VISIBILITY_HIDDEN then
                        tDetails.tProps = wallPropTable
			            World.addWall(tileAddr, tDetails)
                        
                        for sKey,rProp in pairs(wallPropTable) do
                            Lighting.setWallLightUVs(tx, ty, rProp)
                        end
                    --end
                else
                    World.removeWall(tileAddr)
                end
            elseif logicalValue == World.logicalTiles.WALL_DESTROYED then
                -- clear out whatever was there
                World.removeWall(tileAddr)
                
                local tDetails = World._getWallTileDetails(tx, ty)
                
                local wallPropTable = World._setGridTile(World.layers.worldWall, tx, ty, 0, tDetails.damageIdx, tDetails.bFlip)
            -- doors
            elseif logicalValue == World.logicalTiles.DOOR then
                local idx = World.layers.worldFloor.spriteSheet.names[World.doorSpriteName]
                World._setGridTile(World.layers.worldFloor,tx,ty, idx)
            else
                local sSpriteName = Room.getSpriteAtTile(tx,ty,1,logicalValue)
                if sSpriteName then
                    local rLayer = World.layers.worldFloor
                    local idx = rLayer.spriteSheet.names[sSpriteName]
                    assert(idx and idx > 0)
                    World._setGridTile(rLayer,tx,ty, idx)
                    Lighting.setTile(tx, ty, logicalValue)
                else
                    -- MTF: should we allow 0 values? should these all have been set to space?
                    --assertdev(logicalValue == 0)
                    World._setTile(tx, ty, World.logicalTiles.SPACE)
                end
            end
        end
    end
    
    Lighting.updateAll()
    
    local numColorsDirty = #World.dirtyVisualTiles
    
    --Profile.enterScope("World.adjustTileColor")

    -- now that we've contributed to lighting and set up the map, adjust the tile color
    for i,tile in ipairs(World.dirtyVisualTiles) do
        local tx,ty = tile.x,tile.y
        local logicalValue = World._getTileValue(tx, ty)

        if logicalValue ~= World.logicalTiles.SPACE then
            local bFlip = false
        
            if logicalValue == World.logicalTiles.WALL then
                local tDetails = World._getWallTileDetails(tx, ty)
				bFlip = tDetails.bFlip
            end
            World._updateTileColor(tx,ty,nil,logicalValue, bFlip)
        end
    end
    --Profile.leaveScope("World.adjustTileColor")
    
    Profile.leaveScope("World.fixupVisuals")

    World.dirtyVisualTiles = { dirtyList = {} }
end

function World._updateTileColor(tx,ty,addr,value, bFlip)
    --value = value or World._getTileValue(tx,ty)
    --[[
    if World.fogOfWar then
        local dim = World.pathGrid:checkTileFlag(tx, ty, MOAIGridSpace.TILE_DIM)
        if dim then
            World._setGridLocColor(tx, ty, World.dimColor, bFlip)
            return
        end
    end
    ]]--
    --addr = addr or World.pathGrid:getCellAddr(tx,ty)
    --[[
    local color = CommandObject.getCommandColorAtAddr(addr)
    if color then
        World._setGridLocColor(tx, ty, color)
        return
    end
    ]]--
    World._setGridLocColor(tx, ty, World.rightFacingColor, bFlip)
end
    
function World.getSpaceName()
    return tSpaceNames[math.random(1,#tSpaceNames)]
end

function World.getWallDirection(wx,wy)
    local tileX, tileY = World._getTileFromWorld(wx,wy)
    return World._getWallDirection(tileX,tileY)
end

function World._getWallDirection(tileX,tileY)
    local tileValue = World._getTileValue(tileX, tileY)
    if tileValue ~= World.logicalTiles.WALL and tileValue ~= World.logicalTiles.DOOR then
        return World.wallDirections.INVALID
    end
    local tileNW = World._getTileValue(_getAdjacentTile(tileX,tileY,2))
    local tileNE = World._getTileValue(_getAdjacentTile(tileX,tileY,3))
    local tileSW = World._getTileValue(_getAdjacentTile(tileX,tileY,4))
    local tileSE = World._getTileValue(_getAdjacentTile(tileX,tileY,5))
    
    tileNW = tileNW == World.logicalTiles.WALL or tileNW == World.logicalTiles.DOOR
    tileNE = tileNE == World.logicalTiles.WALL or tileNE == World.logicalTiles.DOOR
    tileSW = tileSW == World.logicalTiles.WALL or tileSW == World.logicalTiles.DOOR
    tileSE = tileSE == World.logicalTiles.WALL or tileSE == World.logicalTiles.DOOR

    if (tileNW or tileSE) and not tileSW and not tileNE then
        return World.wallDirections.NWSE
    end
    if (tileNE or tileSW) and not tileSE and not tileNW then 
        return World.wallDirections.NESW
    end

    if tileNW and tileSW and not tileNE and not tileSE then
        return World.wallDirections.GREATERTHAN
    end
    if tileNE and tileSE and not tileSW and not tileNW then 
        return World.wallDirections.LESSTHAN
    end

    if tileNE and tileNW and tileSE and tileSW then
        return World.wallDirections.X
    end
    if tileNW and tileNE then
        return World.wallDirections.V
    end
    if tileSW and tileSE then
        return World.wallDirections.CARAT
    end

    return World.wallDirections.PILLAR
end

function World._getWallTileDetails(tileX, tileY)
	local tAdj = {}
	local nConstruction = CommandObject.getConstructionAtTile(tileX, tileY)
	for i=1,9 do
		local x,y = _getAdjacentTile(tileX,tileY,i)
		-- part of a build command?
		tAdj[i] = CommandObject.getConstructionAtTile(x, y)
		if not tAdj[i] then 
			tAdj[i] = World._getTileValue(x, y)
		end
	end
	
	local function isWall(dir)
		local val = tAdj[World.directions[dir]]
		return val == World.logicalTiles.WALL or World.isDoor(val)
	end
	local function zoneVal(dir)
		-- different zone sets for vaporize vs build?
		--if nConstruction == CommandObject.BUILD_PARAM_DEMOLISH or nConstruction == CommandObject.BUILD_PARAM_VAPORIZE then
			--return Zone.CONSTRUCTION
		--else
        if nConstruction == World.logicalTiles.WALL then
			return Zone.CONSTRUCTION
		end
		local val = tAdj[World.directions[dir]]
		return Zone[World._zoneValue(val)] or Zone.EXTERIOR -- in space? this way of detecting it works for now
	end
	
    -- walls are comprised of top and bottom props
	-- anything that falls through the big switch case will show error tile
    local top = World.visualTiles.wall_error.names
	local bottom = World.visualTiles.wall_error.names
	local zone = 'PLAIN'
	local dir = World.wallDirections.INVALID
	local bFlip = false
	local fallBack = World.layers.worldWall.spriteSheet.names['Wall_Error']
	-- straight pieces: NE/SW, NW/SE
	if isWall('NE') and not isWall('SE') and isWall('SW') and not isWall('NW') then
		-- set dir if only for debugging
		dir = World.wallDirections.NESW
		-- get zone during rule check
		zone = zoneVal('SE') 
		top = zone.wallStraightTop
		bottom = zone.wallStraightBottom
	elseif not isWall('NE') and isWall('SE') and not isWall('SW') and isWall('NW') then
		dir = World.wallDirections.NWSE
		zone = zoneVal('SW')
		top = zone.wallStraightTop
		bottom = zone.wallStraightBottom
		bFlip = true
	-- corners: N,E,S,W
	elseif not isWall('NE') and isWall('SE') and isWall('SW') and not isWall('NW') then
		dir = World.wallDirections.CARAT
		zone = zoneVal('S')
		top = zone.wallCornerSTop
		bottom = zone.wallCornerSBottom
	elseif isWall('NE') and isWall('SE') and not isWall('SW') and not isWall('NW') then
		dir = World.wallDirections.LESSTHAN
		zone = zoneVal('W')
		top = zone.wallCornerETop
		bottom = zone.wallCornerEBottom
	elseif isWall('NE') and not isWall('SE') and not isWall('SW') and isWall('NW') then
		dir = World.wallDirections.V
		zone = zoneVal('S')
		top = zone.wallCornerNTop
		bottom = zone.wallCornerNBottom
	elseif not isWall('NE') and not isWall('SE') and isWall('SW') and isWall('NW') then
		dir = World.wallDirections.GREATERTHAN
		zone = zoneVal('E')
		top = zone.wallCornerWTop
		bottom = zone.wallCornerWBottom
	-- T intersections: NE,SE,SW,NW (base of T)
	elseif isWall('NE') and isWall('SE') and not isWall('SW') and isWall('NW') then
		dir = World.wallDirections.T_NE
		zone = zoneVal('SW')
		top = zone.wallTNETop
		bottom = zone.wallTNEBottom
	elseif isWall('NE') and isWall('SE') and isWall('SW') and not isWall('NW') then
		dir = World.wallDirections.T_SE
		zone = zoneVal('S')
		top = zone.wallTSETop
		bottom = zone.wallTSEBottom
	elseif not isWall('NE') and isWall('SE') and isWall('SW') and isWall('NW') then
		dir = World.wallDirections.T_SW
		zone = zoneVal('S')
		top = zone.wallTSWTop
		bottom = zone.wallTSWBottom
	elseif isWall('NE') and not isWall('SE') and isWall('SW') and isWall('NW') then
		dir = World.wallDirections.T_NW
		zone = zoneVal('SE')
		top = zone.wallTNWTop
		bottom = zone.wallTNWBottom
	-- cross piece
	elseif isWall('NE') and isWall('SE') and isWall('SW') and isWall('NW') then
		dir = World.wallDirections.X
		zone = zoneVal('S')
		top = zone.wallCrossTop
		bottom = zone.wallCrossBottom
	-- column
	elseif not isWall('NE') and not isWall('SE') and not isWall('SW') and not isWall('NW') then
		dir = World.wallDirections.PILLAR
		zone = zoneVal('S')
		top = zone.wallColumnTop
		bottom = zone.wallColumnBottom
	-- straight ends
	elseif isWall('NE') or isWall('SW') then
		dir = World.wallDirections.NESW
		zone = zoneVal('SE')
		top = zone.wallStraightTop
		bottom = zone.wallStraightBottom
	elseif isWall('NW') or isWall('SE') then
		dir = World.wallDirections.NWSE
		zone = zoneVal('SW')
		top = zone.wallStraightTop
		bottom = zone.wallStraightBottom
		bFlip = true
	end
	-- use deterministic, weighted random for tile
	local addr = World.pathGrid:getCellAddr(tileX, tileY)
	local topTile = MiscUtil.weightedRandom(top, addr)
	-- use fallback "error" art if this tile isn't found
	if not World.layers.worldWall.spriteSheet.names[topTile] then
		print('World._getWallTileDetails: '..topTile..' not found')
		topTile = fallBack
	else
		topTile = World.layers.worldWall.spriteSheet.names[topTile]
	end
	local bottomTile = MiscUtil.weightedRandom(bottom, addr)
	if not World.layers.worldWall.spriteSheet.names[bottomTile] then
		print('World._getWallTileDetails: '..bottomTile..' not found')
		bottomTile = fallBack
	else
		bottomTile = World.layers.worldWall.spriteSheet.names[bottomTile]
	end

    local tDetails = {}
    tDetails.topIdx = topTile
    tDetails.bottomIdx = bottomTile
    -- TODO: calc wall damage idx based on wall type
    tDetails.damageIdx = World.layers.worldWall.spriteSheet.names["Base_Straight_destroyed"]
    tDetails.bFlip = bFlip
    tDetails.direction = dir
    tDetails.zone = zone

    local facingDir = World.wallLightDirections[tDetails.direction]
    local adjx,adjy = _getAdjacentTile(tileX,tileY,facingDir)
    local rRoom = Room.getRoomAtTile(adjx,adjy,1)
    tDetails.facingDir = facingDir
    tDetails.nRoomID = rRoom and rRoom.id
    
	return tDetails
end

function World.getTileHealth(tx, ty)
    local tileAddr = World.pathGrid:getCellAddr(tx, ty)
    return World.tileHealth[tileAddr]
end

-- TODO: should be moved out of World, but not sure where to yet.
function World.damageTile(tx, ty, tw, tDamage, bDamageContents)
    local tileValue = World._getTileValue(tx, ty)
    local bIsFloor = World.countsAsFloor(tileValue)
    local bIsWall = World.logicalTiles.WALL == tileValue

    local tileAddr = World.pathGrid:getCellAddr(tx, ty)
    
    -- attempt to damage this tile
    local tHealthDetails = World.tileHealth[tileAddr]
    if not tHealthDetails then
        tHealthDetails = {
            nHealth = World.TILE_DAMAGE_HEALTHY,
            nHitPoints = World.TILE_STARTING_HIT_POINTS,
            nDamageReduction = 0,
            nDamageType = Character.DAMAGE_TYPE.None,
            tDamageTypes = {}
        }
        World.tileHealth[tileAddr] = tHealthDetails
    end
        
    -- eventually we may want to allow re-inforced tiles
    local nDamageReduction = tHealthDetails.nDamageReduction or 0
    local nDamage = math.max(tDamage.nDamage * (1 - nDamageReduction), 0)
    local nDamageType = tDamage.nDamageType or Character.DAMAGE_TYPE.Laser
        
    -- prioritize different damage types (or somehow mix them such that something can be ON FIRE and ON ACID)
    if not tHealthDetails.tDamageTypes then tHealthDetails.tDamageTypes = {} end
    tHealthDetails[nDamageType] = true
    
    -- set health
    tHealthDetails.nHitPoints = math.max(tHealthDetails.nHitPoints - nDamage, 0)
    local nHitPointPct = tHealthDetails.nHitPoints / World.TILE_STARTING_HIT_POINTS
    tHealthDetails.nHealth = math.floor(nHitPointPct * World.TILE_DAMAGE_HEALTHY)

    local nResult = nil
        
    -- if still alive, set decal
    if tHealthDetails.nHitPoints > 0 then
        
        --[[ example for how to detect type of damage
        if tHealthDetails.tDamageTypes[Character.DAMAGE_TYPE.Laser] then
            -- pick different damage type
        end
        ]]--
        
        if bIsFloor then
            World.setFloorDecal(tx, ty, "char03")
        elseif bIsWall then
            World.setWallDecal(tx, ty, "Damage")
        end

        World.updateHealthVisuals(tileAddr, tHealthDetails)
    else
        -- if dead, remove floor
        local rRoom = Room.getRoomAtTile(tx,ty,1)
        if rRoom then rRoom.bPotentiallyCombatBreached = true end
        if bIsFloor then
            World._vaporizeTile(tx, ty)
            nResult = World.logicalTiles.SPACE
        elseif bIsWall then
            -- set this wall to being in a DESTROYED state
            World.setWallDecal(tx, ty, nil)
            
            -- fixupVisuals will replace the sprites
            World._setTile(tx, ty, World.logicalTiles.WALL_DESTROYED)
            nResult = World.logicalTiles.WALL_DESTROYED

            -- destroy objects on wall
            local rObjOnWall = World._getEnvObjectOnWall(tx, ty)
            if rObjOnWall then
                rObjOnWall:vaporize()
            end            
        end
        -- put out fire
        Fire.extinguishTile(tx, ty)
    end

    if bDamageContents then
        local rEO = ObjectList.getObjAtTile(tx,ty,ObjectList.ENVOBJECT)
        if rEO then
            rEO:takeDamage(nil, tDamage)
        end
        local rChar = ObjectList.getObjAtTile(tx,ty,ObjectList.CHARACTER)
        if rChar then
            rChar:takeDamage(nil, tDamage)
        end
    end

    return nResult
end

function World._randomTileSprite(visualTileData) --spriteName, errorSprite)
    local spriteSheetIndex = nil
    if #visualTileData.indexes > 0 then
        spriteSheetIndex = DFUtil.arrayRandom(visualTileData.indexes)
    end
    if not spriteSheetIndex then
        if visualTileData.layer == World.layers.worldWall then
            spriteSheetIndex = visualTileData.layer.spriteSheet.names['Wall_Error']
        else
            spriteSheetIndex = visualTileData.layer.spriteSheet.names['Tile_Error']
        end
    end
    return spriteSheetIndex
end

function World._getWorldFromAddr(addr)
    return World._getWorldFromTile(World.pathGrid:cellAddrToCoord(addr))
end

function World.getPropMinY(wx,wy,propName,bFlipX)
    local tx, ty = World._getTileFromWorld(wx,wy)
    local tTiles = World._getPropFootprint(tx,ty,propName,false,bFlipX)
    local minTileX,minTileY = 0,100000
    for i,tile in ipairs(tTiles) do 
        local x,y = World.pathGrid:cellAddrToCoord(tile)
        if y < minTileY then
            minTileX = x
            minTileY = y
        end
    end
    local worldX, worldY = World._getWorldFromTile(minTileX,minTileY,1,MOAIGridSpace.TILE_LEFT_TOP)
    return worldX,worldY
end

-- bIndexByAddr: if true, return {[addr]=1,[addr]=1,...}
--      Otherwise, return {addr,addr,addr...}
function World._getPropFootprint(tileX, tileY, propName, bBuffer, bFlipX, bFlipY,bIndexByAddr)
    local o = EnvObject.getObjectData(propName)
	
    if not o then
        local addr = World.pathGrid:getCellAddr(tileX, tileY)
        if bIndexByAddr then
            return {[addr]=1}
        else
            return {World.pathGrid:getCellAddr(tileX, tileY)}
        end
    end
	
    local bAgainstWall = o.againstWall
	
    if (not o.width or o.width == 1) and (not o.height or o.height == 1) then
        local t = {}
		local nBuffer
		if bBuffer then
			nBuffer = o.margin
		end
		-- determine if we fit flipped in X and/or Y
        if bAgainstWall then
			local function isAgainstWall(dir)
				local tv = World._getTileValue(_getAdjacentTile(tileX,tileY,dir))
                return tv == World.logicalTiles.WALL or Asteroid.isAsteroid(tv)
			end
            if bFlipX then
                if bFlipY then
					bAgainstWall = isAgainstWall(World.directions.SE)
                else
                    bAgainstWall = isAgainstWall(World.directions.NE)
                end
            else
                if bFlipY then
					bAgainstWall = isAgainstWall(World.directions.SW)
                else
                    bAgainstWall = isAgainstWall(World.directions.NW)
                end
            end
        end
		-- compile list of tiles in footprint
        if not nBuffer or nBuffer == 0 then
            if bIndexByAddr then
                t[World.pathGrid:getCellAddr(tileX, tileY)]=1
            else
                table.insert(t,World.pathGrid:getCellAddr(tileX, tileY))
            end
        elseif nBuffer == 1 then
            for i=1,9 do
                if not o.againstWall or 
						-- wall-mounted, flipped in X and Y
                        (bFlipX and bFlipY and i ~= World.directions.S and i ~= World.directions.SE and i ~= World.directions.E) or
						-- wall-mounted, flipped in Y but not X
                        (not bFlipX and bFlipY and i ~= World.directions.S and i ~= World.directions.SW and i ~= World.directions.W) or
				        -- wall-mounted, flipped in X
                        (bFlipX and not bFlipY and i ~= World.directions.N and i ~= World.directions.NE and i ~= World.directions.E) or
				        -- wall-mounted, not flipped in X
                        (not bFlipX and not bFlipY and i ~= World.directions.N and i ~= World.directions.NW and i ~= World.directions.W) then
                    if bIndexByAddr then
                        t[World.pathGrid:getCellAddr(_getAdjacentTile(tileX,tileY,i))]=1
                    else
                        table.insert(t,World.pathGrid:getCellAddr(_getAdjacentTile(tileX,tileY,i)))
                    end
                end
            end
		else
        	return World._getDiamondPropFootprint(tileX, tileY, propName, bBuffer,bFlipX, bFlipY,bIndexByAddr)
        end
        return t, bAgainstWall
    else
        return World._getDiamondPropFootprint(tileX, tileY, propName, bBuffer,bFlipX, bFlipY,bIndexByAddr)
    end
end

function World._getDiamondPropFootprint(tileX, tileY, propName, bBuffer, bFlipX, bFlipY,bIndexByAddr)
    local o = EnvObject.getObjectData(propName)
    local w,h = o.width,o.height

    if bFlipX and bFlipY then
    elseif bFlipX or bFlipY then
        w=o.height
        h=o.width
    end

	local nBuffer = nil
	if bBuffer then
		nBuffer = o.margin
	end
    if nBuffer then 
        if o.againstWall then
            if bFlipX then
                w=w+nBuffer
                h=h+2*nBuffer
                tileX = tileX-nBuffer
            else
                w=w+2*nBuffer
                h=h+nBuffer
            end
        else
            w=w+2*nBuffer
            h=h+2*nBuffer
            tileX = tileX-nBuffer
        end
    end

    local tAddresses = {}
    local tLocs = {}

    local bAgainstWall = o.againstWall

    local startX = tileX
    local startY = tileY
    -- the i loop draws a line NE.
    -- the j loop draws SE from there.
    for i=1,w do
        local curX,curY = startX,startY
        for j=1,h do
            -- NOTE: hackily, we do the 'against wall' test in the footprint function, since this is where we're iterating
            -- through all the tiles in a diamond.
            if bAgainstWall and not bFlipX and i == 1 then
                local tv = World._getTileValue(_getAdjacentTile(curX,curY,World.directions.NW))
                bAgainstWall = tv == World.logicalTiles.WALL or Asteroid.isAsteroid(tv)
            elseif bAgainstWall and bFlipX and j == 1 then
                local tv = World._getTileValue(_getAdjacentTile(curX,curY,World.directions.NE)) 
                bAgainstWall = tv == World.logicalTiles.WALL or Asteroid.isAsteroid(tv)
            end

            table.insert(tLocs, {curX,curY})
            local addr = World.pathGrid:getCellAddr(curX, curY)
            assert(not tAddresses[addr])
            tAddresses[addr] = 1
            if curY % 2 == 0 then
                curX = curX+1
            end
            curY = curY-1
        end

        if startY % 2 == 0 then
            startX = startX+1
        end
        startY = startY+1
    end

    if bIndexByAddr then
        return tAddresses, bAgainstWall
    end
    
    local t = {}
    for addr,_ in pairs(tAddresses) do
        table.insert(t,addr)
    end
    return t,bAgainstWall
end

function World.isDoor(value)
    return value == World.logicalTiles.DOOR
end


-- utility method to see if we should mark the path grid as hidden,
-- used after modifying a tile's contents.
function World._shouldObstructPathing(tx,ty,tileValue)
    if not World.countsAsFloor(tileValue) and tileValue ~= World.logicalTiles.DOOR 
            and tileValue ~= World.logicalTiles.SPACE then
        return true
    end
    return (ObjectList.pathBlockedByObject(tx,ty) and true)
end

-- utility method to see if we should block oxygen
-- used after modifying a tile's contents.
function World._shouldObstructOxygen(tx,ty,tileValue)
    if tileValue == World.logicalTiles.WALL or Asteroid.isAsteroid(tileValue) then
        return true
    end
    return (ObjectList.oxygenBlockedByObject(tx,ty) and true)
end

-- Sets the logical value of the tile.
-- NOTE:
-- Only two things can change pathability and o2 permeability of a tile.
-- This _setTile call, and ObjectList._setIDAtTile.
function World._setTile(tileX, tileY, value, skipVis)
    assert(value ~= 0)
    assert(value > 0)
    
    local bBlocksPathing = World._shouldObstructPathing(tileX,tileY,value)
    local prevTile = World.pathGrid:getTileValue(tileX, tileY)
    local bBlockedPathing = World.pathGrid:checkTileFlag(tileX, tileY,MOAIGridSpace.TILE_HIDE)
    
    -- bail on redundant state changes or degenerate inputs
    if (prevTile == value and bBlocksPathing == bBlockedPathing) or
       tileX < 0 or tileY < 0 or tileX > World.width or tileY > World.height then        
        return
    end
	
    local oldZone = Zone.tOrderedZoneList[prevTile - World.logicalTiles.ZONE_LIST_START + 1]
    local newZone = Zone.tOrderedZoneList[value - World.logicalTiles.ZONE_LIST_START + 1]

    local tileAddr = World.pathGrid:getCellAddr(tileX, tileY)
	
	-- was this a wall?  remove it from walls list used by cutaway
	if World.tWalls[tileAddr] and value ~= World.logicalTiles.WALL then
		World.removeWall(tileAddr)
	end
	
	if World.tAsteroids[tileAddr] and (value <= World.logicalTiles.ASTEROID_VALUE_START or value >= World.logicalTiles.ASTEROID_VALUE_END) then
		World.removeAsteroid(tileAddr)
	end
    
    World.pathGrid:setTileValue(tileX, tileY, value)
    if bBlocksPathing then
        World.pathGrid:setTileFlag(tileX,tileY,MOAIGridSpace.TILE_HIDE)
    else
        World.pathGrid:clearTileFlag(tileX,tileY,MOAIGridSpace.TILE_HIDE)
    end
    World._updatePathGridDbgColor(tileX, tileY, World.pathGrid:checkTileFlag(tileX,tileY,MOAIGridSpace.TILE_HIDE))

    --[[
    --MTF TODO PERF: we can calculate if this change affected oxygen permeability, and only
    --call the update in that case.
    local prevValue = prevTile % 65536
    if tileValue == World.logicalTiles.WALL or tileValue == World.logicalTiles.ASTEROID_WALL then
    ]]--
        World._updateOxygenFlags(tileX,tileY,value)
        World.dTileChanged:dispatch(tileX,tileY,tileAddr,value, prevTile % MOAIGridSpace.TILE_FLAGS_MASK)

        -- If it was part of a blob, delete the blob and re-flood starting at all adjacent.
        -- If it's new, re-flood starting at this point.
        local bDirtyWallBlobs=false
        if value == World.logicalTiles.WALL then
            World.tDirtyWallTiles[tileAddr] = {x=tileX,y=tileY}
        elseif prevTile == World.logicalTiles.WALL then
            bDirtyWallBlobs=true
            local tOldBlob = World.tWallAddrToBlob[tileAddr]

            if tOldBlob then
                World._deleteWallBlob(tOldBlob)
            end
        end

        for i=1,9 do
            local x,y = _getAdjacentTile(tileX,tileY,i)
            World._dirtyTile(x,y,bDirtyWallBlobs)
        end
end

function World._deleteWallBlob(tBlob)
    for addr,_ in pairs(tBlob.tWallAddrs) do
        World.tWallAddrToBlob[addr] = nil
    end
    --World.tWallBlobs[tBlob] = nil
    for id,_ in pairs(tBlob.tRooms) do
        if Room.tRooms[id] then
            Room.tRooms[id][tBlob] = nil
        end
    end
end

function World._dumpBlobs()
    local tMarked={}
    for addr,tBlob in pairs(World.tWallAddrToBlob) do
        if not tMarked[tBlob] then
            tMarked[tBlob] = true
            print('Blob: ')
            for blobAddr,_ in pairs(tBlob.tWallAddrs) do
                print('   ',World.pathGrid:cellAddrToCoord(blobAddr))
            end
        end
    end
end

function World._dirtyTile(tileX, tileY, bDirtyWallBlobs)
    local tileAddr = World.pathGrid:getCellAddr(tileX, tileY)
    if World.dirtyVisualTiles.dirtyList[tileAddr] == nil then
        World.dirtyVisualTiles.dirtyList[tileAddr] = true
        table.insert(World.dirtyVisualTiles, { x = tileX, y = tileY })
    end
    if bDirtyWallBlobs then
        World.tDirtyWallTiles[tileAddr] = {x=tileX,y=tileY}
    end
end

-- Get the logical/gameplay value of a tile
function World._getTileValue(tileX, tileY, tw)
    if tw and tw ~= 1 then return World.logicalTiles.SPACE end
    return World.pathGrid:getTileValue(tileX, tileY)    
end

-- Get the tile coordinates at the specified cursor position
function World._getTileFromCursor(cursorX, cursorY)    
    local wx,wy = Renderer.getWorldFromCursor(cursorX, cursorY)
    return World._getTileFromWorld(wx,wy)
end

-- Get the tile coordinates at the specified world position
function World._getTileFromWorld(worldX, worldY, worldZ, nLevel)
    -- nil worldX and worldY shouldn't occur, but there was an old isInBounds test that was catching it, 
    -- and we're close enough to release that I don't want to assume we'll fix all the old code that
    -- relied on that.
    if World.layers.worldFloor.prop and worldX and worldY then
        local gridX, gridY = World.layers.worldFloor.prop:getLoc()
        -- Magic 16! I think it's because of a mismatch between the grid sprite alignment and
        -- MOAIGridSpace's locToCoord behavior. Ideally would be fixed in one of those places.
        local tx,ty = World.layers.worldFloor.grid:locToCoord(worldX - gridX, worldY - gridY - 16)
        return tx,ty,(nLevel or 1)
    else
        return 1,1,(nLevel or 1)
    end
end

-- MOAIGridSpace.TILE_LEFT_TOP, MOAIGridSpace.TILE_CENTER
function World.getTileJustifiedWorldPos(wx,wy, justification)
    local tx,ty,tw = World._getTileFromWorld(wx,wy)
    return World._getWorldFromTile(tx,ty, tw, justification)
end

-- Get the world coordinates for the specified tile
function World._getWorldFromTile(tileX, tileY, tileW, justification)    
    local modelX, modelY = World.layers.worldFloor.grid:getTileLoc(tileX, tileY, justification or MOAIGridSpace.TILE_CENTER)
    local gridX, gridY = World.layers.worldFloor.prop:getLoc()
    return gridX + modelX, gridY + modelY  
end

function World.getVisibility(wx,wy,nLevel)
    local tx,ty,tw = World._getTileFromWorld(wx,wy,0,nLevel)
    if tx then
        return World._getVisibility(tx,ty,tw)
    end
    return World.VISIBILITY_FULL
end

function World._getVisibility(tx,ty,tw)
    local rRoom, tRooms = Room.getRoomAtTile(tx,ty,tw,true)
    if tRooms then
        local nWorst = World.VISIBILITY_FULL
        for id,rAdjRoom in pairs(tRooms) do
            local nVis = rAdjRoom:getVisibility()
            if nVis < nWorst then nWorst = nVis end
        end
        return nWorst
    elseif rRoom then
        return rRoom:getVisibility()
    end
    return World.VISIBILITY_FULL
end

function World.playExplosion( wx, wy )
    local rSprite = require('AnimatedSprite').new(Renderer.getRenderLayer("WorldWall"), nil, "explode01_", {tSizeRange={1.65,1.95} })
    rSprite:setLoc(wx,wy+40,0)
    rSprite:play(true, 0)
    require('SoundManager').playSfx3D( "wallexplode", wx, wy, 0)  
end

return World
