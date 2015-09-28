local DFSaveLoad = require('DFCommon.SaveLoad')
local MessagePack = require('DFTools.MessagePack')
local DFFile = require('DFCommon.File')
local DFInput = require('DFCommon.Input')
local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local AssetSet = require('DFCommon.AssetSet')
local SoundManager = require('SoundManager')
local ParticleSystemManager = require('ParticleSystemManager')
local DebugInfoManager = require('DebugInfoManager')
local DebugManager = require('DebugManager')
local SoundManager = require('SoundManager')
local MiscUtil = require('MiscUtil')
local LuaGrid = require('LuaGrid')
local Environment = require('Environment.Environment')
local Pathfinder = nil
local Lighting = nil
--local Docking = nil
local EventController = nil
local Event = nil
local CharacterManager = nil
local WorldObject = nil
local Base = nil
local Character = nil
local Room = nil
local EnvObject = nil
local Turret = nil
local Oxygen = nil
local Fire = nil
local World = nil
local Renderer = nil
local Projectile = nil
local AnimatedSprite = nil
local ShipModules = require('ModuleData')
local ObjectList = require('ObjectList')
local Cursor = nil
local Hint = nil
local Goal = nil
local CommandObject = nil
local Delegate = require('DFMoai.Delegate')
local Topics = nil
local AutoSave = require('AutoSave')
local Profile = require('Profile')
local GameScreen = nil

local SAVE_TYPES={ObjectList.ROOM, ObjectList.ENVOBJECT, ObjectList.CHARACTER, ObjectList.RESERVATION}

-- state/preset data for tutorials
-- list order determines tutorial stage order
local tStartingTutorialState = {
    { sName = 'ZoomedView',        bComplete = false, sLC = 'TRAING001TEXT' },
    { sName = 'PannedView',        bComplete = false, sLC = 'TRAING002TEXT' },
    { sName = 'SelectedSomething', bComplete = false, sLC = 'TRAING003TEXT' },
    { sName = 'DeselectedThing',   bComplete = false, sLC = 'TRAING017TEXT' },
    { sName = 'SetTimeSpeed',      bComplete = false, sLC = 'TRAING004TEXT' },
    { sName = 'BuiltO2',           bComplete = false, sLC = 'TRAING005TEXT' },
    { sName = 'BuildConfirm',      bComplete = false, sLC = 'TRAING013TEXT' },
    { sName = 'AssignedBuilders',  bComplete = false, sLC = 'TRAING012TEXT' },
    { sName = 'UsedVizModes',      bComplete = false, sLC = 'TRAING020TEXT' },
    { sName = 'SelectedFoodRep',   bComplete = false, sLC = 'TRAING006TEXT' },
    { sName = 'FlippedObject',     bComplete = false, sLC = 'TRAING018TEXT' },
    { sName = 'BuiltAirlock',      bComplete = false, sLC = 'TRAING008TEXT' },
    { sName = 'SpeedUpTime',       bComplete = false, sLC = 'TRAING015TEXT' },
    { sName = 'RepairedBreach',    bComplete = false, sLC = 'TRAING007TEXT' },
    { sName = 'ZonedResidence',    bComplete = false, sLC = 'TRAING010TEXT' },
    { sName = 'MineConfirm',       bComplete = false, sLC = 'TRAING014TEXT' },
    { sName = 'AssignedTechs',     bComplete = false, sLC = 'TRAING019TEXT' },
    { sName = 'ExploredDerelict',  bComplete = false, sLC = 'TRAING009TEXT' },
    { sName = 'Final1',            bComplete = false, sLC = 'TRAING011TEXT' },
    { sName = 'Final2',            bComplete = false, sLC = 'TRAING016TEXT' },
}

local GameRules = {
	SAVEGAME_VERSION = 7,

    sEditModulePath='editme',

    nMatter = 0,
    
    simTime = 0,
    elapsedTime = 0,
    sStarDate = "0.0",    
    sStarTime = "00",
	-- timestamps we should remember
	nLastDutyAccident = 0,
	nLastNewShip = 0,
    
    startDragX=0,
    startDragY=0,
    kBUTTON_NONE = -1,
	nDragging=-1,
    
    -- this scales wall clock time into game time.
    -- i.e. 60 would mean one world second is one game minute.
    MAX_PLAYER_TIME_SCALE = 4,
    MIN_PLAYER_TIME_SCALE = 1/4,

    -- matter economy
    STARTING_MATTER = 2000,
    MAT_BUILD_FLOOR = 6,
    MAT_BUILD_DOOR = 12,
    MAT_BUILD_AIRLOCK_DOOR = 15,
    MAT_BUILD_HEAVY_DOOR = 20,
    MAT_VAPE_FLOOR = 4,
	-- matter yield based on miner skill
    MAT_MINE_ROCK_MIN = 30,
    MAT_MINE_ROCK_MAX = 50,
    MAT_MINE_ROCK_MIN_LVL2 = 40,
    MAT_MINE_ROCK_MAX_LVL2 = 60,
	-- % of an object's original cost you get from vaporizing it
    MAT_VAPE_OBJECT_PCT = 0.75,
    -- matter gained from remains
    MAT_CORPSE_MIN = 130,
    MAT_CORPSE_MAX = 170,
    
    -- life support system
    -- (# of recyclers needed to support 1 citizen)
    RECYCLERS_PER_CITIZEN = 3,
	
	-- hint system state
	bHasHadEnclosedRooms = false,
	bHasZoned = false,
    bHasStartedResearch = false,
	
	-- tutorial state (menu or special new base selection)
	bTutorialMode = false,
	-- keep tutorial flags in a table mainly for namespace/functional clarity
	tTutorialState = tStartingTutorialState,
	-- versioning tutorial state simplifies init logic
	nTutorialStateVersion = 6,
    
    -- minimum number of players to trigger upgrade music
    -- (if you start with more than this man, it will trigger upon getting one new character)
    CHARACTER_UPGRADE_MIN = 12,
    
    -- spacedate base number/year
    SPACEDATE_BASE = 9091,
	SPACEDATE_BASE_RANDOM_OFFSET = 9,
    minDerelicts = 7,
    maxDerelicts = 9,
    derelictMargin=5,
    
    sAutoSaveFile = 'SpacebaseDF9AutoSave',       
    
    -- Input handling
    MODE_INSPECT = 0,
    MODE_VAPORIZE = 1,
    MODE_MAKE_CHARACTER = 2,
    MODE_BUILD_ROOM = 3,
    MODE_BUILD_WALL = 4,    
    MODE_MINE = 5,
    MODE_CANCEL_COMMAND = 6,
    MODE_PICK = 7,
    MODE_NOTHING = 8,
    MODE_BUILD_DOOR = 15,
    MODE_PLACE_PROP = 16,
    MODE_GLOBAL_JOB = 17,
	MODE_PLACE_ASTEROID = 18,
    MODE_DELETE_CHARACTER = 19,
    MODE_PLACE_SPAWNER = 20,
    MODE_BEACON = 21,
    MODE_BUILD_FLOOR = 22,
    MODE_DAMAGE_WORLD_TILE = 23,
    MODE_DEMOLISH = 24,
    MODE_PLACE_WORLDOBJECT = 25,
    MODE_ERROR = -1,

	currentModeParam=0,
           
    fullScreen = false,
	
	MAX_ZOOM = 6.0,
	MIN_ZOOM = 0.75,
    ZOOM_SFX_THRESHOLD = 0.5, --distance from MAX_ZOOM at which sound fades out
	START_ZOOM = 2.5,
	ZOOM_WHEEL_STEP = 0.025,
	ZOOM_RATE = 0.005,
	DRAG_ZOOM_SCALE = 0.05,
	-- zoom state
	currentZoom = 1.0,
	lastZoom = 0,
	zoomBuffer = 0,
    
    drawGrid = false,
    selectedCharIndex = 0,
    selectedRoomIndex = 0,
	cutawayMode = false,
	prePauseSpeed = 1,
    bInCutscene = nil,
    
    bDisasterMode = false,
	
    worldAssets = nil,
}

function GameRules.onFileChanged()
    g_GameRules=GameRules
    CharacterManager = require('CharacterManager')
    WorldObject = require('WorldObjects.WorldObject')
    Base = require('Base')
    Character = require('Character')
    --Docking = require('Docking')
    EventController = require('EventController')
    Event = require('GameEvents.Event')
    Room = require('Room')
    EnvObject = require('EnvObjects.EnvObject')
    Turret = require('EnvObjects.Turret')
    Oxygen = require('Oxygen')
    Fire = require('Fire')
    Lighting = require('Lighting')
    World = require('World')    
    g_World = World    
    Renderer = require('Renderer')
    g_Renderer = Renderer
	Hint = require('Hint')
	Goal = require('Goal')
	Cursor = require('UI.Cursor')
    CommandObject = require('Utility.CommandObject')
	Topics = require('Topics')
	Projectile = require('Projectile')
    Pathfinder = require('Pathfinder')
    AnimatedSprite = require('AnimatedSprite')
    GameScreen = require('GameScreen')
end

function GameRules.init()
    GameRules.dEditModeChanged = Delegate.new()
    GameRules.dGameLoaded = Delegate.new()
    
	GameRules.cursorX, GameRules.cursorY = 0,0
    GameRules.prevDragX = {}
    GameRules.prevDragY = {}

    GameRules.bTimeLocked = false
    
    require('DFMoai.Debugger').dFileChanged:register(GameRules.onFileChanged,nil)
    GameRules.onFileChanged()

    GameRules.worldAssets = AssetSet.new()
    GameRules.matterMult = 1
    
    DFInput:init()
    GameRules.currentMode = GameRules.MODE_INSPECT
    
    GameRules.simTime = 0
    GameRules.elapsedTime = 0    
    GameRules.deltaTime = 0
	GameRules.resetTutorialState()
    GameRules.SPACEDATE_BASE = GameRules.SPACEDATE_BASE + math.random(0,GameRules.SPACEDATE_BASE_RANDOM_OFFSET)
    GameRules.sStarDate = GameRules.SPACEDATE_BASE .. ".0"
    GameRules.sStarTime = "00"
    GameRules.bHintsDisabled = false

    require('UI.GuiManager').init()

    ParticleSystemManager.init()
    World.init(256, 256, 128, 64)
    CharacterManager.init()

    DebugInfoManager.init()
    
    SoundManager.initialize( g_tSoundProjects )
    
    Topics.initializeTopicList()
    
    --Docking.init()
    require('Base').init()
    EventController.init()
    Lighting.init()
    AutoSave.init()

    g_ERBeacon = require('Utility.EmergencyBeacon').new()

    Hint.init()
	Goal.init()
    GameRules.setTimeScale(1)
    
    GameRules._centerCameraOnPoint(0, 0)
    GameRules.bInitialized=true
end

function GameRules.startLoop()
    GameRules.bRunning = true
    GameRules._setZoom(GameRules.currentZoom)
end

function GameRules.stopLoop()
    GameRules.bRunning = false
	if GameRules.mainThread then
		GameRules.mainThread:stop()
    	GameRules.mainThread = nil
	end
end

function GameRules.checkCameraPan(dt)
    local dx,dy = 0,0
    
    -- for now only pan in inspect mode (so you don't get wacky drag problems)
    if not g_GuiManager.inspectMode() then 
        -- make sure we're not in mine or beacon mode
        if GameRules.currentMode ~= GameRules.MODE_BEACON and GameRules.currentMode ~= GameRules.MODE_MINE then
            return 
        end
    end

    if GameScreen and GameScreen.inTextEntry() then return end
    
    local rKeyboard = MOAIInputMgr.device.keyboard
 
    if rKeyboard:keyIsDown(string.byte("w")) or rKeyboard:keyIsDown(MOAIKeyboardSensor.UP) then
        dy = dy + 1
    end
    
    if rKeyboard:keyIsDown(string.byte("s")) or rKeyboard:keyIsDown(MOAIKeyboardSensor.DOWN) then        
        dy = dy - 1       
    end
    
    if rKeyboard:keyIsDown(string.byte("a")) or rKeyboard:keyIsDown(MOAIKeyboardSensor.LEFT) then        
        dx = dx - 1
    end
    
    if rKeyboard:keyIsDown(string.byte("d")) or rKeyboard:keyIsDown(MOAIKeyboardSensor.RIGHT) then
        dx = dx + 1
    end
    
    local camSpeed = 300.0
    dx = dx * camSpeed * dt
    dy = dy * camSpeed * dt

    GameRules.panCamera(dx, dy)
end

function GameRules._DBGnext(fn)
    GameRules.DBG_runNext = fn
end

function GameRules.onTick(dt)

    if not GameRules.bRunning then return end
    
    if GameRules.DBG_runNext then
        GameRules.DBG_runNext()
        GameRules.DBG_runNext = nil
    end
    
    GameRules.deltaTime = dt * GameRules.playerTimeScale
    GameRules.simTime = GameRules.simTime + GameRules.deltaTime
    GameRules.elapsedTime = GameRules.elapsedTime + GameRules.deltaTime

    if GameRules.powerHolidayEndTime and GameRules.powerHolidayEndTime < GameRules.elapsedTime then
        GameRules.powerHolidayEndTime = nil
        g_PowerHoliday = false
    end
    
    Pathfinder.staticTick(GameRules.deltaTime)
	
    Profile.enterScope("Docking")
    EventController.onTick(GameRules.deltaTime)
    --Docking.onTick(GameRules.deltaTime)
    Profile.leaveScope("Docking")
    
    Profile.enterScope("Oxygen")
    Oxygen.onTick(GameRules.deltaTime)
    Profile.leaveScope("Oxygen")

    Profile.enterScope("Fire")
    Fire.onTick(GameRules.deltaTime)
    Profile.leaveScope("Fire")
    
    Profile.enterScope("Projectile")
    Projectile.onTick(GameRules.deltaTime)
    Profile.leaveScope("Projectile")

    Profile.enterScope("AnimatedSprite")
    AnimatedSprite.tickAll(GameRules.deltaTime)
    Profile.leaveScope("AnimatedSprite")
    
    Profile.enterScope("Room")
    Room.onTick(GameRules.deltaTime)
    Profile.leaveScope("Room")

    Profile.enterScope("EnvObject")
    EnvObject.staticTick(GameRules.deltaTime)
    Profile.leaveScope("EnvObject")
    Profile.enterScope("Turret")
    Turret.tick(GameRules.deltaTime)
    Profile.leaveScope("Turret")
    
    Profile.enterScope("World")
    World.onTick(GameRules.deltaTime)
    Profile.leaveScope("World")
    
    Profile.enterScope("Lighting")
    Lighting.onTick(GameRules.deltaTime)
    Profile.leaveScope("Lighting")
    
    Profile.enterScope("Characters")
    CharacterManager.onTick(GameRules.deltaTime)
    Profile.leaveScope("Characters")
    
    Profile.enterScope("WorldObjects")
    WorldObject.staticTick(GameRules.deltaTime)
    Profile.leaveScope("WorldObjects")
    
    Profile.enterScope("Base")
    require('Base').onTick(GameRules.deltaTime)
    Profile.leaveScope("Base")

    Profile.enterScope("CommandObject")
    CommandObject.onTick(GameRules.deltaTime)
    g_ERBeacon:onTick(GameRules.deltaTime)
    Profile.leaveScope("CommandObject")
    
    --SoundManager.onTick(GameRules.deltaTime)

    Profile.enterScope("ParticleSystemManager")
    ParticleSystemManager.onTick(GameRules.deltaTime)
    Profile.leaveScope("ParticleSystemManager")
    
    Profile.enterScope("Hints")
    Hint.onTick(GameRules.deltaTime)
    Profile.leaveScope("Hints")

    Profile.enterScope("Goals")
    Goal.onTick(GameRules.deltaTime)
    Profile.leaveScope("Goals")

    GameRules.checkCameraPan(dt)
    local camera = Renderer.getGameplayCamera()
    if camera then
        camera:tick(dt)
    end
    
    -- calculate the stardate
    GameRules.sStarDate = GameRules.getStardateTotalDays() .. "." .. GameRules.getStardateHour()
    GameRules.sStarTime = string.format("%.2i:%s",GameRules.getStardateHour(), GameRules.getStardateMinuteString())
    
    if GameRules.bInCutscene then
		return
	end
	--[[
	GameRules.cutSceneMode.nCurrentTime = GameRules.cutSceneMode.nCurrentTime + dt
	local camera = Renderer.getGameplayCamera()
	local t = math.min(GameRules.cutSceneMode.nCurrentTime / GameRules.cutSceneMode.nTotalDuration, 1)
	local newX,newY,newZ =  DFMath.lerp(GameRules.cutSceneMode.startX, GameRules.cutSceneMode.endX, t),
	DFMath.lerp(GameRules.cutSceneMode.startY, GameRules.cutSceneMode.endY, t),
	DFMath.lerp(GameRules.cutSceneMode.startZ, GameRules.cutSceneMode.endZ, t)
	GameRules.setCameraLoc(newX,newY,newZ)
	if GameRules.cutSceneMode.nCurrentTime >= GameRules.cutSceneMode.nTotalDuration then
	GameRules.cutSceneMode = nil
	end
	]]--
    
	Environment.onTick( GameRules.deltaTime ) 
    
	-- center camera on selected character
	if GameRules.currentMode == GameRules.MODE_INSPECT then
		if GameRules.bCamTrackEnabled then
			local rEnt = g_GuiManager.getSelected()
			if rEnt and rEnt.getLoc then
				local x, y = rEnt:getLoc()
				GameRules._centerCameraOnPoint(x, y)
			else
				GameRules.bCamTrackEnabled = false
			end
		end
	end
	
	Profile.enterScope("AutoSave")
	AutoSave.onTick(dt) -- uses real time
	Profile.leaveScope("AutoSave")
    
	-- tutorial mode
    if GameRules.bTutorialMode then
		GameRules.tutorialChecks()
        GameRules.updateTutorialText()
    end
	
	-- tick camera zoom
	if GameRules.zoomBuffer > 0 then
		GameRules.zoomBuffer = GameRules.zoomBuffer - GameRules.ZOOM_RATE
	elseif GameRules.zoomBuffer < 0 then
		GameRules.zoomBuffer = GameRules.zoomBuffer + GameRules.ZOOM_RATE
	else
		return
	end
	-- zero if close enough
	if math.abs(GameRules.zoomBuffer) < GameRules.ZOOM_RATE then
		GameRules.zoomBuffer = 0
	end
	local newZoom = GameRules.currentZoom + GameRules.zoomBuffer
	-- kill velocity if clamping
	if newZoom > GameRules.MAX_ZOOM then
		GameRules.zoomBuffer = 0
		newZoom = GameRules.MAX_ZOOM
	elseif GameRules.currentZoom < GameRules.MIN_ZOOM then
		GameRules.zoomBuffer = 0
		newZoom = GameRules.MIN_ZOOM
	end
	GameRules._setZoom(DFMath.clamp(newZoom, GameRules.MIN_ZOOM, GameRules.MAX_ZOOM), GameRules.zoomLoc.x, GameRules.zoomLoc.y)
	--GameRules._setZoom(newZoom)
end

function GameRules.updateTutorialText()
	if #GameRules.tTutorialState == 0 then
        g_GuiManager.tutorialText:setTutorialTextVisibility(false)
        GameRules.bTutorialMode = false
		return
    end
	local tNextTutorial = GameRules.tTutorialState[1]
	if not tNextTutorial.bComplete then
		g_GuiManager.tutorialText:setTutorialText(tNextTutorial.sLC)
	else
		table.remove(GameRules.tTutorialState, 1)
	end
end

function GameRules.completeTutorialCondition(sCondition)
    for _,tTutData in ipairs(GameRules.tTutorialState) do
        if tTutData.sName == sCondition and not tTutData.bComplete then
            tTutData.bComplete = true
        end
    end
end

function GameRules.isTutorialConditionComplete(sCondition)
	for _,tTutData in ipairs(GameRules.tTutorialState) do
        if tTutData.sName == sCondition then
			return tTutData.bComplete
		end
	end
	-- if we didn't find it, it must have already been completed and removed?
	return true
end

function GameRules.resetTutorialState()
	GameRules.tTutorialState = DFUtil.deepCopy(tStartingTutorialState)
end

function GameRules.isFunctionalAirlockSlated(rRoom)
	-- returns true if an airlock locker and two airlock doors have been
	-- slated for construction in the specified room
	local bLocker = false
	for addr,rProp in pairs(rRoom.tPropPlacements) do
		if rProp.sName == 'AirlockLocker' then
			bLocker = true
			break
		end
	end
	if not bLocker then
		return false
	end
	-- slated doors are command objects, not prop placements
	local bHasSpaceDoor, bHasInteriorDoor = false, false
	for addr,tCmd in pairs(CommandObject.tCommands) do
		if tCmd.commandAction == CommandObject.COMMAND_BUILD_ENVOBJECT and tCmd.commandParam == 'Airlock' then
			-- need >=1 space-facing door and >=1 interior-facing door
			local bSpaceFacing = false
			local bInAirlock = false
			for nTileAddr,_ in pairs(tCmd.tTiles) do
				-- count only airlocks that touch our walls
				if rRoom.tWalls[nTileAddr] then
					bInAirlock = true
					local wx,wy = g_World._getWorldFromAddr(nTileAddr)
					local tx,ty = World._getTileFromWorld(wx, wy)
					bSpaceFacing = g_World.isAdjacentToSpace(tx, ty)
				end
			end
			if bSpaceFacing then
				bHasSpaceDoor = true
			-- don't count airlock doors built in other rooms
			elseif bInAirlock then
				bHasInteriorDoor = true
			end
		end
	end
	return bHasSpaceDoor and bHasInteriorDoor
end

function GameRules.tutorialChecks()
	-- checks for tutorial conditions that don't occur in any other game code
	if not GameRules.isTutorialConditionComplete('AssignedBuilders') then
		CharacterManager.updateOwnedCharacters()
		if require('HintChecks').pendingConstruction() and CharacterManager.tJobCount[Character.BUILDER] > 0 then
			GameRules.completeTutorialCondition('AssignedBuilders')
		end
	end
	if not GameRules.isTutorialConditionComplete('AssignedTechs') then
		CharacterManager.updateOwnedCharacters()
		if CharacterManager.tJobCount[Character.TECHNICIAN] > 0 then
			GameRules.completeTutorialCondition('AssignedTechs')
		end
	end
	local bBreachedRoom = false
	local bFunctionalAirlock = false
	local bZonedResidence = false
	for _,rRoom in pairs(Room.tRooms) do
		if rRoom:isBreached() then
			bBreachedRoom = true
		end
		-- trigger hint after airlock when objects are confirmed,
		-- don't wait until they're built so we can train speedup
		-- (this check is a bit involved, only run it if we must)
		if rRoom.zoneName == 'AIRLOCK' and not GameRules.isTutorialConditionComplete('BuiltAirlock') then
			bFunctionalAirlock = GameRules.isFunctionalAirlockSlated(rRoom)
		elseif rRoom.zoneName == 'RESIDENCE' then
			bZonedResidence = true
		end
	end
	if not bBreachedRoom and not GameRules.isTutorialConditionComplete('RepairedBreach') then
		GameRules.completeTutorialCondition('RepairedBreach')
	end
	if bFunctionalAirlock and not GameRules.isTutorialConditionComplete('BuiltAirlock') then
		GameRules.completeTutorialCondition('BuiltAirlock')
	end
	if not bBreachedRoom and bZonedResidence and not GameRules.isTutorialConditionComplete('ZonedResidence') then
		GameRules.completeTutorialCondition('ZonedResidence')
	end
	-- last tick before end of tutorial might encounter empty tTutorialState
	if not GameRules.tTutorialState[1] then
		return
	-- trigger derelict if beacon is next incomplete check
	elseif GameRules.tTutorialState[1].sName == 'ExploredDerelict' and not GameRules.tTutorialState.bSpawnedDerelict then
		GameRules.tTutorialState.bSpawnedDerelict = true
		EventController.DBG_forceQueue('friendlyDerelictEvents', false, 5)
	-- wait a while to clear each "cool, you did the tutorial" message
	elseif GameRules.tTutorialState[1].sName == 'Final1' then
		if not GameRules.tTutorialState.nTimeSinceCompleted then
			GameRules.tTutorialState.nTimeSinceCompleted = GameRules.elapsedTime
		elseif GameRules.elapsedTime >= GameRules.tTutorialState.nTimeSinceCompleted + 30 then
			GameRules.completeTutorialCondition('Final1')
			-- reset completed time to trigger final2
			GameRules.tTutorialState.nTimeSinceCompleted = GameRules.elapsedTime
		end
	elseif GameRules.tTutorialState[1].sName == 'Final2' then
		if GameRules.elapsedTime >= GameRules.tTutorialState.nTimeSinceCompleted + 30 then
			-- this will only run once; last condition getting completed
			-- will stop tutorial ticking further
			GameRules.completeTutorialCondition('Final2')
		end
	end
end

function GameRules.shutdown()
    GameRules.bInitialized=false
	-- clear out research n junk
	local Base = require('Base')
	Base.tS.tResearch = {}
	Base.tS.tMemory = {}
	Base.tS.tGoals = {}
	Base.tS.tStats = {}
	GameRules.tTutorialState = nil
	
	GameRules.stopLoop()
    CharacterManager.shutdown()
    if g_ERBeacon then
        g_ERBeacon:destroy()
        g_ERBeacon = nil
    end
    World.shutdown()        
    SoundManager.shutdown()  
    if g_GuiManager then
        g_GuiManager.shutdown()
        g_GuiManager = nil
    end
    Renderer.clearRenderLayers()
end

function GameRules.reset(tLandingZone)
    GameRules.shutdown()
    GameRules.init()
    collectgarbage ("collect")
    if GameRules.inEditMode then
        GameRules.nMatter = GameRules.STARTING_MATTER
        GameRules.nLastDutyAccident = 0
        GameRules.nLastNewShip = 0
        GameRules.bHasHadEnclosedRooms = false
        Environment.randomSetup()
        EventController.setBaseSeeds()
    else
        GameRules.randomSetup(tLandingZone)
    end
	GameRules.startLoop()
	-- start new game paused
	GameRules.timePause()
end

function GameRules._getEditModeSaveFileName()
    --return 'editme'
    return "Module_"..os.time()
end

function GameRules.getLandingZone()
    if not GameRules.tLandingZone then GameRules.tLandingZone = {x=math.random(1,64),y=math.random(1,64)} end
    return GameRules.tLandingZone
end

function GameRules.saveGame()      
    local tSaveData = {}
    if GameRules.inEditMode then
        local xOff,yOff
        tSaveData.tWorldSaveData,xOff,yOff = World.getModuleSaveData()
        --tSaveData.tCharacterSaveData = CharacterManager.getSaveData(xOff, yOff)
    else
        tSaveData.nMatter = GameRules.nMatter
        tSaveData.powerHolidayEndTime = GameRules.powerHolidayEndTime
        tSaveData.simTime = GameRules.simTime
        tSaveData.elapsedTime = GameRules.elapsedTime or 0
		tSaveData.nLastDutyAccident = GameRules.nLastDutyAccident
		tSaveData.nLastNewShip = GameRules.nLastNewShip
        tSaveData.SPACEDATE_BASE = GameRules.SPACEDATE_BASE
        tSaveData.sStarDate = GameRules.sStarDate    
        tSaveData.sStarTime = GameRules.sStarTime
        tSaveData.tLandingZone = GameRules.getLandingZone()
        tSaveData.tSoundSaveData = SoundManager.getSaveData()    
        tSaveData.tWorldSaveData = World.getSaveData()
        tSaveData.tTopics = Topics.tTopics
        tSaveData.tEventControllerState = EventController.getSaveData()
        tSaveData.tBaseState = require('Base').getSaveData()
		tSaveData.currentZoom = GameRules.currentZoom
        tSaveData.bTutorialMode = GameRules.bTutorialMode
		tSaveData.tTutorialState = GameRules.tTutorialState
        tSaveData.nTutorialStateVersion = GameRules.nTutorialStateVersion
		tSaveData.tSquadData = require('World').getSquadList().getSaveData()
		local tSquads = require('World').squadList.getList()

		tSaveData.bHasHadEnclosedRooms = GameRules.bHasHadEnclosedRooms
		tSaveData.bHasZoned = GameRules.bHasZoned
		-- save camera location
		tSaveData.nCameraX,tSaveData.nCameraY,tSaveData.nCameraZ = Renderer.getGameplayCamera():getLoc()
        --tSaveData.tCharacterSaveData = CharacterManager.getSaveData()
    end

	tSaveData.nSavegameVersion = GameRules.SAVEGAME_VERSION
    ObjectList.removeStaleTags(tSaveData)

    --GameRules._dbgVerifySaveTable(tSaveData)

    MOAISim.forceGarbageCollection()
    if GameRules.inEditMode then
        local path = DFFile.getDataPath("Modules/")
        local str = MessagePack.pack(tSaveData)
        --MOAISim.forceGarbageCollection()
        DFSaveLoad.saveString( str, path..GameRules._getEditModeSaveFileName(), true)
        --MOAISim.forceGarbageCollection()
        DFSaveLoad.saveString( str, path..GameRules.sEditModulePath..'.sav', true)
    else
        -- Was doing some savegame debugging-- saving out to a lot of different files.
        --[[
        local tWhatever={"tBaseState","tEventControllerState","tSoundSaveData","tTopics","tWorldSaveData"}
        local shorterStr
        for _,s in ipairs(tWhatever) do
            if s == 'tWorldSaveData' then
                for k,v in pairs(tSaveData.tWorldSaveData) do
                    print(k)

                    if k == 'Character' then
                        for k2,v2 in pairs(tSaveData.tWorldSaveData.Character) do
                            shorterStr = MessagePack.pack(v2)
                            MOAISim.forceGarbageCollection()
                            DFSaveLoad.saveString( shorterStr, GameRules.sAutoSaveFile..tostring(k)..tostring(k2), nil, true )
                            MOAISim.forceGarbageCollection()
                        end
                    end

                    shorterStr = MessagePack.pack(v)
                    MOAISim.forceGarbageCollection()
                    DFSaveLoad.saveString( shorterStr, GameRules.sAutoSaveFile..k )
                    MOAISim.forceGarbageCollection()
                end
            end

            shorterStr = MessagePack.pack(tSaveData[s])
            MOAISim.forceGarbageCollection()
            DFSaveLoad.saveString( shorterStr, GameRules.sAutoSaveFile..s )
            MOAISim.forceGarbageCollection()
        end
        ]]--
        local str = MessagePack.pack(tSaveData)
        --MOAISim.forceGarbageCollection()
        DFSaveLoad.saveString( str, GameRules.sAutoSaveFile )
    end
    
    local tProcessed={}
    local tTags={}
    --GameRules._dbgVerifySaveTable(tSaveData,tTags)
    
    --MOAISim.forceGarbageCollection()
end

function GameRules._dbgVerifySaveTable(tSaveData,tTags)
    for k,v in pairs(tSaveData) do
        if type(k) == 'table' and k._ObjectList_TagMarker then
            if not tTags[k.objID] then
                tTags[k.objID] = k
            else
                assertdev(tTags[k.objID].objType == k.objType)
            end
        end
        if type(v) == 'table' then
                if v._ObjectList_TagMarker then
                    if not tTags[v.objID] then
                        tTags[v.objID] = v
                    else
                        assertdev(tTags[v.objID].objType == v.objType)
                    end
                end
                
            GameRules._dbgVerifySaveTable(v,tTags)
        end
    end
end

function GameRules.loadModule(setName,moduleName)
    local tModuleData = {}

    local tCreationData = ShipModules[setName][moduleName]

    if not tCreationData then
        Print(TT_Error, 'Failed to find module:',setName,moduleName)
        assertdev(false)
        return
    end

    
    local shipsWithCrew = tCreationData.shipsWithCrew
    local crewData,objectData,filename
    local bHostile=false
    if shipsWithCrew and type(shipsWithCrew) == 'table' then
        assert(false)
    elseif shipsWithCrew then
        crewData = ShipModules.shipsWithCrew[shipsWithCrew].crew
        objectData = ShipModules.shipsWithCrew[shipsWithCrew].objects
        filename = ShipModules.shipsWithCrew[shipsWithCrew].filename
        bHostile = ShipModules.shipsWithCrew[shipsWithCrew].bHostile
    end
    
    if tCreationData.filename then
        filename = tCreationData.filename
    end
    
    tModuleData.sFilename = filename
    tModuleData.sModuleName = moduleName
    tModuleData.sFilePath = filename
    tModuleData.sSetName = setName
    tModuleData.tCrewSpawns = crewData
    tModuleData.tObjectSpawns = objectData
    tModuleData.bHostile = bHostile or false
    
    if not filename then
        Print(TT_Warning, 'No filename for module '..setName..','..moduleName)
        return tModuleData
    end

    filename = DFFile.getDataPath("Modules/" .. filename .. ".sav")
    local saveData = GameRules._loadSavegameAndUpdate(filename, true,true,true)

    local w,h = saveData.tWorldSaveData.maxX-saveData.tWorldSaveData.minX,saveData.tWorldSaveData.maxY-saveData.tWorldSaveData.minY

    tModuleData.tSaveData = saveData
    tModuleData.tileWidth,tModuleData.tileHeight = w,h

    return tModuleData
end

function GameRules._loadSavegameAndUpdate(sPath, bPreservePath, bSilenceErrors)
    if not bPreservePath then
        sPath = DFSaveLoad.getSaveFilename(sPath)
    end
    local dataBuffer = MOAIDataBuffer.new()
    dataBuffer:load(sPath)
    if dataBuffer:testHeader('--MOAI') then
        -- nothing
    else
        dataBuffer:inflate()
    end
    local str = dataBuffer:getString()
    local str2 = str
    if string.len(str) < 5 then return end

    local saveData

    if not saveData then
        -- MTF TODO: pop up a confirmation dialog on old-school saves, re: security vulnerability.
        -- PLD: setfenv fixes the vulnerability.
        local f, compileError = loadstring(str)
        if f then
            local env = {
                MOAIDeserializer = MOAIDeserializer,
                DFOxygenGrid     = DFOxygenGrid,
                MOAIGrid         = MOAIGrid,
            }
            setfenv(f, env)
            local status, result = pcall(f)
            if status then
                saveData = result
            elseif not bSilenceErrors then
                Trace(TT_Error, "Failed to execute old save file %s\nError: %s", sPath, result)
            end
        elseif not bSilenceErrors then
            Trace(TT_Error, "Failed to load old save file %s\nError: %s", sPath, compileError)
        end
    end

    if not saveData then
        local status, result = pcall(MessagePack.unpack, str)
        if status then
            saveData = result
        else
            Trace(TT_Error, "Failed to load new save file %s\nError: %s", sPath, result)
        end
    end

    if saveData then
        saveData.nSavegameVersion = saveData.nSavegameVersion or 0
        World.updateSavegame(saveData.nSavegameVersion, saveData.tWorldSaveData)
        
        --saveData.tWorldSaveData.pathGrid = LuaGrid.fromSaveData(saveData.tWorldSaveData.pathGrid, false, {nDefaultVal=World.logicalTiles.SPACE})
        --saveData.tWorldSaveData.oxygenGrid = LuaGrid.fromSaveData(saveData.tWorldSaveData.oxygenGrid, false, {nDefaultVal=0})
    end
    
	return saveData
end

function GameRules.placeModule(tModuleData, tileXOff, tileYOff, bOnPlayerTeam)
	if not tileXOff then tileXOff = World.width * .5 end
	if not tileYOff then tileYOff = World.height * .5 end

	-- TODO: the two functions, GameRules.placeModule and World.loadModule, use different coordinates.
	-- They should unify.
	-- World coords are necessary for some entities that save their loc in world coords, so probably unify
	-- on using world coords.
    local worldXOff, worldYOff = World._getWorldFromTile(tileXOff,tileYOff)
    local nDefaultFactionBehavior = not bOnPlayerTeam and ( (tModuleData.bHostile and Character.FACTION_BEHAVIOR.EnemyGroup) or Character.FACTION_BEHAVIOR.Friendly )
    

    ObjectList.portOldSavegames(tModuleData.tSaveData,tModuleData.tSaveData.nSavegameVersion)
    ObjectList.beginLoad(tModuleData.tSaveData, true)
    Room.beginLoad(tModuleData.tSaveData, true)
            
    
    local nNewTeam = World.loadModule(tModuleData.tSaveData.nSavegameVersion, tModuleData.tSaveData.tWorldSaveData, worldXOff,worldYOff, nDefaultFactionBehavior)

    ObjectList.endLoad()
    
    SoundManager.loadModule( tModuleData.tSaveData.tSoundSaveData )
    
    local tFakeEvent = {sEventType='initialSpawn',sSetName=tModuleData.sSetName,sModuleName=tModuleData.sModuleName,nDifficulty=0,bValidDockingData=true}
    
    Event._prerollModuleSpawns(g_EventController, tFakeEvent)
    EventController.spawnModuleEntities(tFakeEvent, tModuleData,{ nDefaultTeam=nNewTeam, nDefaultFactionBehavior=nDefaultFactionBehavior })
end

function GameRules.loadGame(sOverridePath, bOverridePreservePath)
    -- load the data
    local tSaveData
    if GameRules.inEditMode then
        local path = DFFile.getDataPath("Modules/")
        tSaveData = GameRules._loadSavegameAndUpdate(path..GameRules.sEditModulePath..'.sav',true,true)
    else
        tSaveData = GameRules._loadSavegameAndUpdate(sOverridePath or GameRules.sAutoSaveFile, bOverridePreservePath, true)
    end
    -- bail out if load failed
    if not tSaveData then
        Trace(TT_Warning, "Could not load the save")
        return -- bail out
    end

    if GameRules.bInitialized then 
        GameRules.shutdown() 
    end
    GameRules.init()    

	local bLoaded = false
    if GameRules.inEditMode then
        --local saveData = DFSaveLoad.loadTable( "editme" )            
        local w,h = tSaveData.tWorldSaveData.maxX-tSaveData.tWorldSaveData.minX,tSaveData.tWorldSaveData.maxY-tSaveData.tWorldSaveData.minY
        local tModuleData = {tSaveData=tSaveData, sSetName='editMode',sModuleName='editMode'}
        GameRules.placeModule(tModuleData, math.floor((World.width-w)*.5), math.floor((World.height-h)*.5), true)
    else
        GameRules.nMatter = tSaveData.nMatter or tSaveData.matter or GameRules.STARTING_MATTER
        GameRules.tLandingZone = tSaveData.tLandingZone
        GameRules.simTime = tSaveData.simTime 
        GameRules.elapsedTime = tSaveData.elapsedTime  or 0
        
        GameRules.powerHolidayEndTime = tSaveData.powerHolidayEndTime
        if not tSaveData.nSavegameVersion or tSaveData.nSavegameVersion < 5 then
            GameRules.powerHolidayEndTime = GameRules.elapsedTime + 60*10
        end
        if GameRules.powerHolidayEndTime then
            g_PowerHoliday = true
        end
        
        GameRules.sStarDate = tSaveData.sStarDate 
        GameRules.sStarTime = tSaveData.sStarTime
        GameRules.nLastDutyAccident = tSaveData.nLastDutyAccident or 0
        GameRules.nLastNewShip = tSaveData.nLastNewShip or 0
        GameRules.bTutorialMode = tSaveData.bTutorialMode
        -- reset tutorial state if we've updated it since save
        if not tSaveData.nTutorialStateVersion or GameRules.nTutorialStateVersion > tSaveData.nTutorialStateVersion then
            GameRules.resetTutorialState()
        else
            GameRules.tTutorialState = tSaveData.tTutorialState or tStartingTutorialState
        end
        GameRules.SPACEDATE_BASE = tSaveData.SPACEDATE_BASE or GameRules.SPACEDATE_BASE
        
        ObjectList.portOldSavegames(tSaveData,tSaveData.nSavegameVersion)
        
        local tTags={}
        GameRules._dbgVerifySaveTable(tSaveData,tTags)
        
        Room.beginLoad(tSaveData, false)
        ObjectList.beginLoad(tSaveData, false)
        Room.hackLoadSpaceRoom(tSaveData)
        
        require('Base').fromSaveData(tSaveData.tBaseState or {})
        World.loadSaveData(tSaveData.nSavegameVersion, tSaveData.tWorldSaveData )
        --require('Base').fromSaveDataLate(tSaveData.tBaseState or {})
        EventController.fromSaveData(tSaveData.tEventControllerState or {})
        
        ObjectList.endLoad()
        Room.endLoad()
        
        local tBeaconSaveData = {}
        if tSaveData and tSaveData.tBaseState and tSaveData.tBaseState.tBeacon then
            tBeaconSaveData = tSaveData.tBaseState.tBeacon
        end
        g_ERBeacon:fromSaveTable(tBeaconSaveData)
		
		World.getSquadList().loadSaveData(tSaveData.tSquadData or {})
        
        Topics.fromSaveData(tSaveData)
        -- refresh activity list in case we added one since save creation
        Topics.generateActivityList()
        Topics.generatePeopleList()
        GameRules.bHasHadEnclosedRooms = tSaveData.bHasHadEnclosedRooms
        GameRules.bHasZoned = tSaveData.bHasZoned
        GameRules.currentZoom = tSaveData.currentZoom or GameRules.START_ZOOM
        --CharacterManager.loadSaveData( tSaveData.tCharacterSaveData )
        SoundManager.loadSaveData( tSaveData.tSoundSaveData )
        -- restore camera location
        if tSaveData.nCameraX and tSaveData.nCameraY and tSaveData.nCameraZ then
            GameRules._centerCameraOnPoint(tSaveData.nCameraX, tSaveData.nCameraY, tSaveData.nCameraZ)
        end
        bLoaded = true
        GameRules.dGameLoaded:dispatch()
    end

    collectgarbage()

	return bLoaded
end

function GameRules.getStardateMinuteString(nTime)
    local m = GameRules.getStardateMinute(nTime)
    if m < 10 then
        return '0'..m
    else
        return tostring(m)
    end
end

function GameRules.getStardateMinute(nTime)
	nTime = nTime or GameRules.simTime
	return math.floor( nTime % 60 )
end

function GameRules.getStardateHour(nTime)
	nTime = nTime or GameRules.simTime
	local elapsedHours = nTime / 60
	return math.floor( elapsedHours % 24 )
end

function GameRules.getStardateTotalDays(nTime)
	nTime = nTime or GameRules.simTime
	local elapsedDays = nTime / (60 * 24)
    return GameRules.SPACEDATE_BASE + math.floor( elapsedDays )
end

function GameRules.getFullStarDateString(nTime)
	local nDays = GameRules.getStardateTotalDays(nTime)
	local nHours = GameRules.getStardateHour(nTime)
	local nMinutes = GameRules.getStardateMinuteString(nTime)
	return string.format('%s.%s:%s', nDays, nHours, nMinutes)
end

function GameRules.timeFaster()
    if GameRules.playerTimeScale == 0 then
        GameRules.setTimeScale(1)
    else
        GameRules.setTimeScale( math.min(GameRules.MAX_PLAYER_TIME_SCALE, GameRules.playerTimeScale * 2) )    
    end
end

function GameRules.timeSlower()
    if GameRules.playerTimeScale <= 1 then
        GameRules.setTimeScale(0)
    else
        GameRules.setTimeScale( math.max(GameRules.MIN_PLAYER_TIME_SCALE, GameRules.playerTimeScale * .5) )    
    end
end

function GameRules.timeStandard()
	GameRules.setTimeScale( 1 )    
end

function GameRules.timePause()
	GameRules.setTimeScale(0)
end

function GameRules.lockTimeScale(bLock)
    GameRules.bTimeLocked = bLock
end

function GameRules.togglePause()
	if GameRules.bTimeLocked then
		return
	end
	if GameRules.playerTimeScale == 0 then
		GameRules.setTimeScale(GameRules.prePauseSpeed)
	else
		GameRules.prePauseSpeed = GameRules.playerTimeScale
		GameRules.timePause()
	end
end

function GameRules.getTimeScale()
    return GameRules.playerTimeScale
end

function GameRules.setTimeScale(timeScale)
	if GameRules.bTimeLocked then
        return
    end
    GameRules.playerTimeScale = timeScale
    MOAIActionMgr.setTimeScaleByType(ACTIONTYPE_GAMEPLAY, timeScale)
    DFSpace.setGlobalTimeScale(timeScale);
    DFEffects.setGlobalTimeScale(timeScale);
	print("Time Scale:",GameRules.playerTimeScale)
end

function GameRules.loadRandomFromSet(setName)
    local moduleName = MiscUtil.weightedRandom(ShipModules[setName])
    return GameRules.loadModule(setName,moduleName)
end

function GameRules.randomSetup(tLandingZone)
    if tLandingZone then
        GameRules.tLandingZone = tLandingZone
    else
        tLandingZone = GameRules.getLandingZone()
    end
    
    GameRules.nMatter = GameRules.STARTING_MATTER
	-- reset matter counter
	g_GuiManager:getStatusBar().nMatterCount = GameRules.nMatter
	GameRules.nLastDutyAccident = 0
	GameRules.nLastNewShip = 0
	GameRules.bHasHadEnclosedRooms = false

    Environment.randomSetup()

    local tModuleData 
	
	-- NewBase:setCursor sets tutorial mode flag
	if GameRules.bTutorialMode then
        tModuleData = GameRules.loadRandomFromSet("tutorialModules")
    else
        tModuleData = GameRules.loadRandomFromSet("startingModules")
    end
    local tileX,tileY = math.floor((World.width-tModuleData.tileWidth)*.5), math.floor((World.height-tModuleData.tileHeight)*.5)

    require('Asteroid').spawnAsteroids(MiscUtil.getGalaxyMapValue(tLandingZone.x, tLandingZone.y,'asteroids'))
    EventController.setBaseSeeds()
    
    GameRules.placeModule(tModuleData, tileX, tileY, true)
end

function GameRules.toggleHints(bEnable)
    GameRules.bHintsDisabled = not bEnable
end

function GameRules.setEditMode(bEnable)
    if bEnable == GameRules.inEditMode then
        return
    end

    GameRules.inEditMode = bEnable
    GameRules.matterMult = (bEnable and 0) or 1
    GameRules.bProhibitSuffocation = bEnable
    GameRules.timePause()
    GameRules.dEditModeChanged:dispatch(bEnable)
end

local firstHover = false
function GameRules.handleHover(x,y)
	GameRules.cursorX, GameRules.cursorY = x, y
    --GameRules.startDragX = nil
    --GameRules.startDragY = nil
    
    g_GuiManager.hoverInside(x,y)

    -- we don't need to do this every hover frame, but it's not expensive
    Cursor.updateGridCursor(x, y, -1, -1, GameRules.currentMode)
    -- update HUD after game starts
    -- weird place to do it, couldn't find another that made more sense
    if not firstHover then
        firstHover = true
    end
end

function GameRules.updateAudioLevels()
    if GameRules.bAudioLevelScaleApplied then
        GameRules.applyScaleToAudioLevels(GameRules.nAudioLevelLastScale)
    else
        SoundManager.setCategoryVolume ( "sfx", g_Config:getConfigValue("sfx_volume"))   
        SoundManager.setCategoryVolume ( "voice", g_Config:getConfigValue("voice_volume"))
        SoundManager.setCategoryVolume ( "music", g_Config:getConfigValue("music_volume"))
        SoundManager.setCategoryVolume ( "ambience", g_Config:getConfigValue("sfx_volume"))
        SoundManager.setCategoryVolume ( "ui", g_Config:getConfigValue("sfx_volume"))
    end
end

-- volume in menus is constant
function GameRules.removeScaleFromAudioLevels()
    GameRules.bAudioLevelScaleApplied = true
    GameRules.updateAudioLevels()
end

function GameRules.applyScaleToAudioLevels(scale)
    GameRules.nAudioLevelLastScale = GameRules.nAudioLevelLastScale or GameRules.MAX_ZOOM
    GameRules.nAudioLevelLastScale = scale or GameRules.nAudioLevelLastScale
    GameRules.bAudioLevelScaleApplied = true
    
    local nSfxVol = g_Config:getConfigValue("sfx_volume")
    local nMusicVol = g_Config:getConfigValue("music_volume")
    local nVoiceVol = g_Config:getConfigValue("voice_volume")
    
    --adjust volumes on zoom
    if scale == GameRules.MIN_ZOOM then
        SoundManager.setCategoryVolume ( "sfx",  nSfxVol)
        --SoundManager.setCategoryVolume ( "ambience", 0.65 * nSfxVol)
        SoundManager.setCategoryVolume ( "voice", 1 * nVoiceVol)
        SoundManager.setCategoryVolume ( "music", 0.65 * nMusicVol)  
    elseif scale <= GameRules.MIN_ZOOM + GameRules.ZOOM_SFX_THRESHOLD then
        SoundManager.setCategoryVolume ( "sfx", 0.45 * nSfxVol )
        --SoundManager.setCategoryVolume ( "ambience", 0.80 * nSfxVol)
        SoundManager.setCategoryVolume ( "voice", 0.45 * nVoiceVol)
        SoundManager.setCategoryVolume ( "music", 0.80 * nMusicVol)
    else
        SoundManager.setCategoryVolume ( "sfx", 0 * nSfxVol)
        --SoundManager.setCategoryVolume ( "ambience", 1 * nSfxVol)
        SoundManager.setCategoryVolume ( "voice", 0 * nVoiceVol)        
        SoundManager.setCategoryVolume ( "music", 1 * nMusicVol)
    end
    
    SoundManager.setCategoryVolume ( "ambience", g_Config:getConfigValue("sfx_volume"))
end

function GameRules._setZoom(scale, screenX, screenY)
	GameRules.lastZoom = GameRules.currentZoom
    local camera = Renderer.getGameplayCamera()
    local nDepth = 1 - ((scale - GameRules.MIN_ZOOM) / (GameRules.MAX_ZOOM - GameRules.MIN_ZOOM))
    camera:setScl(scale, scale)


	-- zoom at given location
    if screenX == nil then
        screenX, screenY = Renderer.getHalfScreenSize()
    end
    local worldLayer = World.getWorldRenderLayer()
    local zoomX, zoomY = worldLayer:wndToWorld(screenX, screenY)
	local cx, cy, cz = camera:getLoc()
	local dx,dy = zoomX-cx, zoomY-cy
	local newX,newY = zoomX - dx * scale / GameRules.lastZoom, zoomY - dy * scale / GameRules.lastZoom
	GameRules.setCameraLoc(newX,newY,cz)
	GameRules.currentZoom = scale
	
    local nearPlane = DFMath.lerp(Renderer.kMaxZoomNearPlane, Renderer.kMinZoomNearPlane, nDepth)
    local farPlane = DFMath.lerp(Renderer.kMaxZoomFarPlane, Renderer.kMinZoomFarPlane, nDepth)
    camera:setNearPlane(nearPlane)
    camera:setFarPlane(farPlane)

    SoundManager.setZoomLevel(nDepth) --("Depth", nDepth)
    GameRules.applyScaleToAudioLevels(scale)
end

function GameRules._centerCameraOnPoint(x, y, z)
    local camera = Renderer.getGameplayCamera()
    local cx, cy, cz = camera:getLoc()
    GameRules.setCameraLoc(x,y, z or cz)
end

function GameRules._resetCamera()
    -- center camera on "first" character
    GameRules.lastZoom = 1
    GameRules._setZoom(1.0)
    local tChars = CharacterManager.getCharacters()
    local firstChar = tChars[1]
    if firstChar then
        local x, y = firstChar:getLoc()
        GameRules._centerCameraOnPoint(x, y)
    end
end

function GameRules.startCameraShake(nMag,nDuration)
    local camera = Renderer.getGameplayCamera()
    if camera then camera:shake(nMag,nDuration) end
end

function GameRules.setCameraLoc(x,y,z)
    local camera = Renderer.getGameplayCamera()
    local oldX,oldY,oldZ = camera:getLoc()
    x = x or oldX
    x = x
    y = y or oldY
    y = y
    z = z or oldZ
    x,y = World.clampToBounds(x,y)
    if x == math.inf or y == math.inf or z == math.inf or x ~= x or y ~= y or z ~= z then
        Print(TT_Error, 'Attempt to move camera to NaN.')
    else
        local xDelta = oldX - x
        local yDelta = oldY - y
        camera:setLoc(x,y,z)
        local bgCamera = Renderer.getBackgroundCamera()
        local oldBGx, oldBGy = bgCamera:getLoc()
            
        xDelta = xDelta / 200
        yDelta = yDelta / 200
        
        local zOffs = 720
        local newX =  oldBGx - xDelta
        local newY =  oldBGy - yDelta
        bgCamera:setLoc( newX, newY, zOffs )

    end
end

function GameRules.AddZoom(zoomAmount, screenX, screenY)
    if screenX == nil then
        screenX, screenY = Renderer.getHalfScreenSize()
    end
    GameRules.zoomLoc = { x = screenX, y = screenY }
    GameRules.zoomBuffer = GameRules.zoomBuffer + zoomAmount    
end

function GameRules.stopCutscene()
    GameRules.bInCutscene = false
end

function GameRules.startCutscene()
    GameRules.bInCutscene = true
end

function GameRules.inputPointer(touch, bDoubleTap)
    -- MTF NOTE:
    -- Seeing some mysterious nil inputs in the wild. Not sure what's causing them; going to try to ignore bad inputs.
    if not touch.x or not touch.y then 
        assertdev(false)
        return
    end

	GameRules.cursorX = touch.x
	GameRules.cursorY = touch.y

--    if not GameRules.bPerformedDrag then
        g_GuiManager.touchInside(touch.x, touch.y)
        if g_GuiManager.onFinger(touch) then
            return
        end
--    end

    if touch.eventType == DFInput.TOUCH_DOWN then
        GameRules.startDragX = touch.x
        GameRules.startDragY = touch.y
		GameRules.nDragging = touch.button
        GameRules.bPerformedDrag = false
        GameRules.prevDragX[touch.button] = touch.x
        GameRules.prevDragY[touch.button] = touch.y
        Cursor.updateGridCursor(touch.x, touch.y, GameRules.startDragX, GameRules.startDragY, GameRules.currentMode, true)
    elseif touch.eventType == DFInput.TOUCH_MOVE then
        GameRules.setCamTrackEnabled(false)
        local camera = Renderer.getGameplayCamera()
        local x, y, z = camera:getLoc()
		-- don't allow RMB-dragging view if LMB-dragging in build mode
		if GameRules.nDragging == 0 and touch.button == 1 and GameRules.isBuildMode(GameRules.currentMode) then
			return
		end
		GameRules.nDragging = touch.button

        if touch.x ~= GameRules.startDragX or touch.y ~= GameRules.startDragY then
            GameRules.bPerformedDrag = true
        end

        if touch.button == DFInput.MOUSE_RIGHT or (touch.button == DFInput.MOUSE_LEFT and MOAIInputMgr.device.keyboard:keyIsDown(MOAIKeyboardSensor.CONTROL)) then
            local moveScale = 3.5
            local camScaleFactor = camera:getScl() / moveScale
            local prevX = touch.x
            if #GameRules.prevDragX >= touch.button and GameRules.prevDragX[touch.button] then
                prevX = GameRules.prevDragX[touch.button]
            end
            local prevY = touch.y
            if #GameRules.prevDragY >= touch.button and GameRules.prevDragY[touch.button] then
                prevY = GameRules.prevDragY[touch.button]
            end
                        
            x = x + (touch.x - prevX) * -moveScale * camScaleFactor
            y = y + (touch.y - prevY) * moveScale * camScaleFactor
            GameRules.setCameraLoc(x,y,z)
            GameRules.completeTutorialCondition('PannedView')
        elseif touch.button == DFInput.MOUSE_MIDDLE then
            local prevY = GameRules.prevDragY[touch.button] or touch.y
			local scale = (touch.y - prevY) * GameRules.DRAG_ZOOM_SCALE
			-- clamp
			scale = GameRules.currentZoom + scale
			scale = math.max(math.min(scale,GameRules.MAX_ZOOM),GameRules.MIN_ZOOM)
            GameRules._setZoom(scale, GameRules.startDragX, GameRules.startDragY)
            GameRules.completeTutorialCondition('ZoomedView')
        elseif touch.button == DFInput.MOUSE_LEFT then
            Cursor.updateGridCursor(touch.x, touch.y, GameRules.startDragX, GameRules.startDragY, GameRules.currentMode, true)
        end
    end
    
    if touch.button == DFInput.MOUSE_SCROLL_UP or touch.button == DFInput.MOUSE_SCROLL_DOWN then
		-- if at min or max zoom and scrolling out of range, don't bother
		if not ((GameRules.currentZoom == GameRules.MAX_ZOOM and touch.button == DFInput.MOUSE_SCROLL_DOWN) or (GameRules.currentZoom == GameRules.MIN_ZOOM and touch.button == DFInput.MOUSE_SCROLL_UP)) then
			-- wheel scrolls are more discrete events than middle-drag,
			-- so accumulate them
			local zoomAmount = GameRules.ZOOM_WHEEL_STEP
			if touch.button == DFInput.MOUSE_SCROLL_UP then
				zoomAmount = -zoomAmount
			end
            GameRules.AddZoom(zoomAmount, GameRules.cursorX, GameRules.cursorY)
		end
		GameRules.completeTutorialCondition('ZoomedView')
    end
    
    if touch.button == DFInput.MOUSE_LEFT and touch.eventType == DFInput.TOUCH_UP then
        if GameRules.nDragging ~= GameRules.kBUTTON_NONE then
            local wx,wy = Renderer.getWorldFromCursor(touch.x,touch.y)
            Cursor.execute(wx,wy)
        end
    end
    if touch.eventType == DFInput.TOUCH_UP then
        if touch.button == DFInput.MOUSE_RIGHT and not GameRules.bPerformedDrag then
            if GameRules.currentMode == GameRules.MODE_BEACON then
                g_ERBeacon:remove()
            end
        end
        Cursor.updateGridCursor(touch.x, touch.y, -1, -1, GameRules.currentMode)
		GameRules.nDragging = GameRules.kBUTTON_NONE        
    end
    GameRules.prevDragX[touch.button] = touch.x
    GameRules.prevDragY[touch.button] = touch.y
end

function GameRules.panCamera(dx, dy)
    local camera = Renderer.getGameplayCamera()
    local camScaleFactor = camera:getScl()

    local x,y,z = camera:getLoc()
    
    x = x + dx * camScaleFactor
    y = y + dy * camScaleFactor
    
    GameRules.setCameraLoc(x,y,z)
end

function GameRules.getCapacity()
	-- 2nd arg of getNumberOfObjects = "only count working objects"
	local nCapacity = 0
	local EnvObject = require('EnvObjects.EnvObject')
	nCapacity = nCapacity + EnvObject.getNumberOfObjects('OxygenRecycler', true) * GameRules.RECYCLERS_PER_CITIZEN
	nCapacity = nCapacity + EnvObject.getNumberOfObjects('OxygenRecyclerLevel2', true) * GameRules.RECYCLERS_PER_CITIZEN * 2
	nCapacity = nCapacity + EnvObject.getNumberOfObjects('OxygenRecyclerLevel3', true) * GameRules.RECYCLERS_PER_CITIZEN * 3
	nCapacity = nCapacity + EnvObject.getNumberOfObjects('OxygenRecyclerLevel4', true) * GameRules.RECYCLERS_PER_CITIZEN * 4
	return nCapacity
end

function GameRules.deleteCharacter(wx,wy)
    local rProp = g_GuiManager._getTargetAt(wx, wy)
    if rProp and rProp.tag and rProp.tag.objType == ObjectList.CHARACTER then
        local CharacterManager = require('CharacterManager')
        local Character = require('CharacterConstants')
        CharacterManager.deleteCharacter( rProp )
    end
end

function GameRules.deleteSelected()
	-- delete whatever is selected (debug)
	local rChar = g_GuiManager.getSelectedCharacter()
	local rObject = g_GuiManager.getSelected(ObjectList.ENVOBJECT)
	if rChar then
		local Character = require('CharacterConstants')
		CharacterManager.deleteCharacter(rChar)
	elseif rObject then
		rObject:remove()
	end
	g_GuiManager.setSelected()
end

function GameRules.cycleVisualizer()
    if not GameRules.currentVisualizer and not Room.powerVisEnabled() then
        GameRules.currentVisualizer = World.oxygenGrid
        Room.disablePowerVis()
    elseif GameRules.currentVisualizer and not Room.powerVisEnabled() and DFSpace.isDev() then
        Room.enablePowerVis()
        GameRules.currentVisualizer = nil
    else
        Room.disablePowerVis()
        GameRules.currentVisualizer = nil
    end
    if GameRules.currentVisualizer then
        World.setAnalysisPropEnabled(true,GameRules.currentVisualizer)
    else
        World.setAnalysisPropEnabled(false)
    end
end

function GameRules.isOxygenGridEnabled()
    if GameRules.currentVisualizer == World.oxygenGrid then
        return true
    end
    return false
end 

function GameRules.cycleCutawayMode()
    GameRules.cutawayMode = not GameRules.cutawayMode
    World.updateCutaway()
end

function GameRules.enableCutawayMode(bEnable, bShowSpace)
    GameRules.cutawayMode = bEnable
    World.updateCutaway(bShowSpace)
end

function GameRules.isCutawayModeEnabled()
    return GameRules.cutawayMode
end

function GameRules.isBuildMode(mode)
	return mode == GameRules.MODE_BUILD_ROOM or mode == GameRules.MODE_BUILD_WALL or mode == GameRules.MODE_BUILD_FLOOR
	    or mode == GameRules.MODE_BUILD_DOOR or mode == GameRules.MODE_VAPORIZE or mode == GameRules.MODE_MINE
	    or mode == GameRules.MODE_CANCEL_COMMAND or mode == GameRules.MODE_PLACE_ASTEROID
end

function GameRules.confirmBuild(bDontExpendMatter)
    
    if CommandObject.canAffordCost() then
        CommandObject.clearSavedCommandStates(nil, bDontExpendMatter)
        GameRules.setUIMode(GameRules.MODE_INSPECT)
		GameRules.completeTutorialCondition('BuildConfirm')
        return true
    else
        SoundManager.playSfx("disallow")
        return false
    end
end

function GameRules.cancelBuild(bStayInCurrentMode)
	CommandObject.restoreCommandStates()
    if not bStayInCurrentMode then
        GameRules.setUIMode(GameRules.MODE_INSPECT)
    end
end

function GameRules.getPendingBuildCost()
    return CommandObject.getCurrentPendingBuildCost()
end

function GameRules.setCamTrackEnabled(bEnabled)
    GameRules.bCamTrackEnabled = bEnabled
end

function GameRules.setUIMode(mode,param)
    if g_ERBeacon then g_ERBeacon:stopPreview() end
    Cursor.modeChanging(GameRules.currentMode,mode)

	local wasBuilding = GameRules.isBuildMode(GameRules.currentMode)
	local nowBuilding = GameRules.isBuildMode(mode)
	
    GameRules.currentMode = mode
    GameRules.currentModeParam = param
	
    local bShowFlip = false
    if GameRules.currentMode == GameRules.MODE_PLACE_PROP or GameRules.currentMode == GameRules.MODE_PLACE_WORLDOBJECT then
        if not EnvObject.getObjectData(GameRules.currentModeParam) or not EnvObject.getObjectData(GameRules.currentModeParam).autoFlip then
            bShowFlip = true
        end
    end
		
    g_GuiManager:getStatusBar():showFlipZone(bShowFlip)
     
    -- grid drawing?
    GameRules.drawGrid = nowBuilding
    if not World then
        return
    end
    local val = World.visualTiles.build_grid_square.index
    if not GameRules.drawGrid then
        val = val + MOAIGridSpace.TILE_HIDE
    end
    if World.layers.buildGrid.grid then -- if test to fix shutdown crash
        World.layers.buildGrid.grid:fill(val)
    end
end

function GameRules.expendMatter(nMatter)
    GameRules.nMatter = GameRules.nMatter - math.floor(nMatter)
    local rStatusBar = g_GuiManager:getStatusBar()
    if rStatusBar then
        rStatusBar:onMatterChanged(GameRules.nMatter)
    end
end

function GameRules.addMatter(nMatter)
    GameRules.nMatter = GameRules.nMatter + math.floor(nMatter)
    local rStatusBar = g_GuiManager:getStatusBar()
    if rStatusBar then
        rStatusBar:onMatterChanged(GameRules.nMatter)
    end
end

function GameRules.getMatter()
    return GameRules.nMatter
end

function GameRules.repairSelectedObject()
	GameRules.setSelectedObjectCondition(100)
end

function GameRules.setSelectedObjectCondition(condition)
	local rObject = g_GuiManager.getSelected(ObjectList.ENVOBJECT)
	if rObject then
		rObject:_setCondition(condition)
	end
end

function GameRules.getTotalIndoorTiles()
	-- returns # of interior (non-breached) player-owned floor tiles
	local tiles = 0
	for idx,room in pairs(Room.tRooms) do
		if not room.bBreach and room.nTeam == Character.TEAM_ID_PLAYER then
			tiles = tiles + room.nTiles
		end
	end
	return tiles
end

return GameRules
