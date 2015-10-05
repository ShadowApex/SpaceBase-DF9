----------------------------------------------------------------
-- Copyright (c) 2012 Double Fine Productions
-- All Rights Reserved. 
----------------------------------------------------------------

-- Initialize the debugger before everything else
local DFDebugger = require('DFMoai.Debugger')

local DFGraphics = require('DFCommon.Graphics')
local DFUtil = require("DFCommon.Util")
local DFScriptSystem = require('DFCommon.ScriptSystem')
local Renderer = require('Renderer')
local SoundManager = require('SoundManager')
local GameRules = require('GameRules')
local DataCache = require("DFCommon.DataCache")
local DFMath = require('DFCommon.Math')
local DFFile = require('DFCommon.File')
local DebugInfoManager = require('DebugInfoManager')
local LinecodeManager = require('LinecodeManager')
local ScreenManager = require('UI.ScreenManager')
local Hint = require('Hint')
local ErrorReporting = require('ErrorReporting')
local GameConfig = require('GameConfig')
local Profile = require('Profile')
local Point = require('Point')

g_World = nil
g_GameRules = GameRules
g_GuiManager=nil
g_mainThread = nil

DBG_START_IN_EDIT_MODE = false

-- check for luajit status
local jit = require("jit")    
print("MAIN.LUA: jit status - " .. tostring(jit.status()))

local function _initGarbageCollector()
	-- Setup the garbage collector
	--collectgarbage ("setpause", 50)
	--collectgarbage ("setstepmul", 100)
    
    -- JLV: Pretty sure that this code path is broken.  gLuaGcStepTimer only gets set once, and constantly gets incremenetd.
    -- And evne with this setting enabled, it never actually limits the time spent in a gc step to 2 seconds.  I fixed the other
    -- codepath, so I'm leaving this one disabled for now.
	--MOAISim.setGcFrameMaxDuration (2000) -- Maximum time (in micro second) Lua can spend for GC during one frame

    -- JLV:  This one is working.  When lua_gc is called with LUA_GCSTEP is called we will iterate on the lua heap collecting
    -- one object at a time until we exceed this time.  In practice, the gc step may take a few microseconds more than this
    -- but it should not be siginificant.  Set at 1ms now, but in practice it could be less.
    -- XXX: Make this increase as a function of space we need to get back?  Right now if we get behind we will just accumulate
    -- garbage until we run out of space and have to do a full GC.
    --MOAISim.setGcConstantDuration (2000) -- Amount of time (in micro second) Lua will spend at the end of the frame for GC
end

local function _initSimulation()	
	MOAISim.clearLoopFlags()
    -- MTF NOTE 1: this was MOAISim.LOOP_FLAGS_VARIABLE, which entertainingly doesn't exist!
    -- Not sure if fixed or default is better right now; will revisit if we ever integrate LOOP_FLAGS_VARIABLE from dropchord.
	MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED)    
	MOAISim.setCpuBudget(1)
    -- MTF NOTE 2: we can set this to avoid a little bit of stuttering we sometimes get from Lua GC at 60fps, but it's a judgement call whether
    -- the 30fps steady is better than a mostly 60fps experience. Leaving the flag out for now to see how it feels near 60.
	--MOAISim.setStep(1/30)
	--MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_MULTISTEP)    
end

local function _initGame(windowWidth, windowHeight)

    -- Replace MOAITransform.getLoc with an FFI function that is much faster and LuaJIT friendlier.
    if MOAIEnvironment.osBrand ~= "OSX" then
        --Point.monkeyPatchGetLoc()
    end

    -- NOTE: Execute this file to rebuild the main_lua.h header, generated from moai.lua.  This is necessary when
    -- the lua bytecode changes.  The error you will likely encounter if you need to this is is MOAICamera2D is
    -- missing, since it is a virtual class generated in that header.
    -- dofile('../Common/Code/Moai/src/lua-headers/main.lua')

    ErrorReporting.init()

    DFSpace.enableConstraintAspectRatio(g_nMinAspectRatio, g_nMaxAspectRatio)

    DataCache.createCache("particles", 20)
    DataCache.createCache("material", 10)
    DataCache.createCache("shader", 10)
    DataCache.createCache("font", 10)
    DataCache.createCache("anim", 200)
    DataCache.createCache("rig", 50)
    DataCache.createCache("texparams", 50)

    -- ensure randomness!
    math.randomseed(os.time())
    for i=1,50 do math.random() end
    
    g_nPopulationCap = g_Config:getConfigValue("pop_cap")
    
    if g_Config:getConfigValue('dev_mode') then
        DFSpace.isDev = function() return true end
    end
    
    local Post = require("PostFX.Post")
    Post.kEnabled = Post.kEnabled and g_Config:getConfigValue("posteffects")
    
    require('ObjectList').init()
    g_Gui = require('UI.Gui')
    g_Gui.init()


    -- Setup the main window
    local gameViewport, uiViewport = DFGraphics.createWindow( "Spacebase DF9", windowWidth, windowHeight, true )
    Renderer.initializeRenderer(gameViewport, uiViewport)
    require('DebugManager'):initialize()
    
    GameRules.init()
    local GameScreen = require('GameScreen')    
    ScreenManager:initialize(g_Config:getConfigValue("launch_fullscreen"))
    ScreenManager:pushScreen(GameScreen.new())
               
    Renderer.getGameplayCamera():setScl(8,8)

    --GameRules.timePause()

    local startThread = MOAICoroutine.new()
    startThread:setName("StartThread")
    startThread:run(    
        function()
            g_GuiManager.setCursorVisible(false)
            g_GuiManager.setIsInStartupScreen(true)
            g_GuiManager.fadeInCentered("2HB",1) --JM: draw the logo centered instead of stretched across the screen
            DFUtil.sleep(3)
            
            print('MAIN.LUA: StartThread a')
			DFGraphics.blockOnAsyncTextureLoad()    
            print('MAIN.LUA: StartThread b')
            
            coroutine.yield()
            coroutine.yield()
            local bLoaded = false
            g_GuiManager.fadeOutFullScreen()
            g_GuiManager.fadeInCentered("LegalScreen", 1.5)
            DFUtil.sleep(0.1)
            g_GuiManager.setCursorVisible(true)
            g_GuiManager.setIsInStartupScreen(false)
            
            if DBG_START_IN_EDIT_MODE then
                GameRules.setEditMode(true)
                bLoaded = true
            else
                bLoaded = GameRules.loadGame()
                --[[if not bLoaded then
                    GameRules.randomSetup()  
                end ]]--    
            end
            
            print('MAIN.LUA: StartThread c')
			DFGraphics.blockOnAsyncTextureLoad()
            print('MAIN.LUA: StartThread d')
            if bLoaded then GameRules.startLoop() end
            g_GuiManager.fadeOutFullScreen()
            
            if not bLoaded then
                g_GuiManager.showNewBaseScreen()
            else
                g_GuiManager.showStartMenu(true)
				print('MAIN.LUA: StartMenu Load')
                if g_Config:getConfigValue('auto_start') then
                    g_GuiManager.startMenu:resume()
                end
            end

            --local World = require('World')
            --World.setAnalysisPropEnabled(true,World.oxygenGrid)
            --g_GuiManager.showStartMenu(not bLoaded)
        end
        )
end

function main()
	-- Setup the garbage collector
	_initGarbageCollector()
    
    local sPath = DFFile.getDataPath('build.string')
	local file = io.open(sPath)
	assert(file)
	local data = file:read('*all')
	file:close()
	data = data:gsub('\n', '')
    print('MAIN.LUA: LAUNCHING SPACEBASE BUILD '..data)
    MOAIEnvironment.appVersion = data

    -- Setup linecode
    
	DataCache.createCache("linecode", 200)
	--print('LINECODE DATACACHE LOADED')
	g_LM = LinecodeManager.initialize('Dialog/Linecodes/MainGame_enUS.lua')
	--print('LINECODE INIT LOADED')
	
	-- Set simumation flags
	_initSimulation()
	
	-- Initialize the game
    local resW = tonumber(g_Config:getConfigValue("window_resolution_w"))
    local resH = tonumber(g_Config:getConfigValue("window_resolution_h"))
	_initGame(resW, resH)
    
    local lastTime = MOAISim.getDeviceTime()    
    local MAX_FRAME_TIME = 1/10
    g_mainThread = MOAICoroutine.new()
    g_mainThread:setName("MainLoop")
    local DBG_moreProfiling=false

    --[[
    local fnWhat=function(val)
        print('hi '..val)
    end
    ]]--

    g_mainThread:run(function()
        TT_ENABLED[TT_Cache] = true
        
        while true do
            local currentTime = MOAISim.getDeviceTime()                
            local deltaTime = currentTime - lastTime
            deltaTime = math.min(deltaTime, MAX_FRAME_TIME)
            lastTime = currentTime

            Profile.shinyBeginLoop('main_loop')
            
            -- Tick game/simulation
            GameRules.onTick(deltaTime)

            --[[
            local thing={5,6,7,8,9}
            local test = coroutine.wrap(function()
                local i = 1
                while true do
                    fnWhat(thing[i])
                    i = i+1
                    coroutine.yield()
                end
            end)
            test()
            test()
            test()
            test()
            test()
            test()
            test()
            ]]--
            
            -- Tick UI      
            Profile.enterScope("UI")
            if DBG_moreProfiling then
                Profile.enterScope("ScreenManager")
            end
            ScreenManager:onTick(deltaTime)
            if DBG_moreProfiling then
                Profile.leaveScope("ScreenManager")
                Profile.enterScope("DebugManager")
            end
            DebugInfoManager.onTick(deltaTime)
            if DBG_moreProfiling then
                Profile.leaveScope("DebugManager")
                Profile.enterScope("GuiManager")
            end
            g_GuiManager.onTick(deltaTime)
            if DBG_moreProfiling then
                Profile.leaveScope("GuiManager")
            end
            Profile.leaveScope("UI")
            
            -- Tick Audio
            Profile.enterScope("SoundManager")
            SoundManager.onTick(deltaTime)      
            Profile.leaveScope("SoundManager")
      
            Profile.shinyEndLoop('main_loop')

            coroutine.yield()
        end
    end)
end

main()



