local GuiManager = {}

local DFUtil = require("DFCommon.Util")
local DFGraphics = require('DFCommon.Graphics')
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local Gui = require('UI.Gui')
local NewSideBar = require('UI.NewSideBar')
local StatusBar = require('UI.StatusBar')
local GameScreen = require('GameScreen')
local StartMenu = require('UI.StartMenu')
local GlobalJobs = require('UI.GlobalJobs')
local CharacterManager = require('CharacterManager')
local SoundManager = require('SoundManager')
local GameRules = require('GameRules')
local World = require('World')
local Room = require('Room')
local Character = require('Character')
local DebugInfoManager = require('DebugInfoManager')
local DebugInfoPane = require('UI.DebugInfoPane')
local HintPane = require('UI.HintPane')
local AlertPane = require('UI.AlertPane')
local ObjectList = require('ObjectList')
local EnvObject = require('EnvObjects.EnvObject')
local Delegate = require('DFMoai.Delegate')
local BuildHelper = require('UI.BuildHelper')
local DFMoaiDebugger = require("DFMoai.Debugger")
local UIEffectMask = require('UI.UIEffectMask')
local TextureButton = require('UI.TextureButton')
local TemplateButton = require('UI.TemplateButton')
local OnePixelButton = require('UI.OnePixelButton')
local ProgressBar = require('UI.ProgressBar')
local WorldToolTip = require('UI.WorldToolTip')
local Profile = require('Profile')
local MenuManager = require('UI.MenuManager')
local SquadMenu = require('UI.SquadMenu')
local SquadEditMenu = require('UI.SquadEditMenu')

local Cursor=nil

GuiManager.AMBER = Gui.AMBER
GuiManager.RED = Gui.RED
GuiManager.GREEN = Gui.GREEN
GuiManager.BROWN = Gui.BROWN
GuiManager.GREY = Gui.GREY
GuiManager.SIDEBAR_BG = Gui.SIDEBAR_BG

GuiManager.VERSION_SUBTITLE = 'UIMISC040TEXT'

--using for debug stuff! JM
GuiManager.LastClickedPos = {0,0}

GuiManager.tTemplateElementClasses =
{
    TextureButton = TextureButton,
    OnePixelButton = OnePixelButton,
    TemplateButton = TemplateButton,
    ProgressBar = ProgressBar,
}

local kDRAG_SELECT_THRESH = 10

function GuiManager.init()
    g_GuiManager = GuiManager
    GuiManager.dSelectionChanged = Delegate.new()
    local NewSideBar = require('UI.NewSideBar')
    local StatusBar = require('UI.StatusBar')
    local TutorialText = require('UI.TutorialText')
    Cursor = require('UI.Cursor')

    -- add the scissorrect for the scrollable layer
    GuiManager.tScrollableScissorRects = {}
    local rScrollableUILayerLeft = Renderer.getRenderLayer('UIScrollLayerLeft')
    if rScrollableUILayerLeft then
        local rScrollableScissorRect = MOAIScissorRect.new()        
        rScrollableScissorRect:setRect(0, -GuiManager.getUIViewportSizeY(), GuiManager.getUIViewportSizeX(), 0)
        rScrollableUILayerLeft:setScissorRect(rScrollableScissorRect)
        GuiManager.tScrollableScissorRects['UIScrollLayerLeft'] = rScrollableScissorRect
    end    
    local rScrollableUILayerRight = Renderer.getRenderLayer('UIScrollLayerRight')
    if rScrollableUILayerRight then
        local rScrollableScissorRect = MOAIScissorRect.new()        
        rScrollableScissorRect:setRect(0, -GuiManager.getUIViewportSizeY(), GuiManager.getUIViewportSizeX(), 0)
        rScrollableUILayerRight:setScissorRect(rScrollableScissorRect)
        GuiManager.tScrollableScissorRects['UIScrollLayerRight'] = rScrollableScissorRect
    end    

	--------------------------------
	GuiManager.menuManager = MenuManager.new(GuiManager)
	local squadEditMenu = SquadEditMenu.new(GuiManager.menuManager)
	GuiManager.menuManager.addMenu("SquadMenu", SquadMenu.new(GuiManager.menuManager, squadEditMenu))
	GuiManager.menuManager.addMenu("SquadEditMenu", squadEditMenu)
	---------------------------------------
    GuiManager.newSideBar = NewSideBar.new(GuiManager.menuManager)
    GuiManager.startMenu = StartMenu.new()
    GuiManager.statusBar = StatusBar.new()
	GuiManager.tutorialText = TutorialText.new()
    GuiManager.tPopupQueue = {}

    GuiManager.globalJobs = GlobalJobs.new()
	GuiManager.debugInfoPane = DebugInfoPane.new()
	GuiManager.buildHelper = BuildHelper.new()
	GuiManager.hintPane = HintPane.new()
    GuiManager.alertPane = AlertPane.new()
    GuiManager.uiEffectMask = UIEffectMask.new()
    
    GuiManager.worldToolTip = WorldToolTip.new()

    GuiManager.newBase = require('UI.NewBase').new()

    GuiManager.tMaxPriInfo = {}
    
    local pri = 0
    GuiManager.basePri = pri

    --pri = Gui.setActivePane(GuiManager.newSideBar, nil, pri)
    pri = GuiManager.newSideBar:show(pri)
    pri = GuiManager.statusBar:show(pri)
    pri = GuiManager.tutorialText:show(pri)
	if DebugInfoManager.drawSelectedDebug then
		pri = GuiManager.debugInfoPane:show(pri)
	end
	pri = GuiManager.buildHelper:show(pri)
	pri = GuiManager.hintPane:show(pri)
    pri = GuiManager.alertPane:show(pri)
    Renderer.dResized:register(GuiManager.onResize,GuiManager)
    GuiManager.onResize()	

	GuiManager.createSelectionProp()
    
    if MOAIInputMgr.device.pointer then    
        -- Load up custom cursor
        local spriteSheet = DFGraphics.loadSpriteSheet('UI/Shared', false, false, false)
        GuiManager.rCursor = MOAIProp2D.new()
        GuiManager.rCursor:setDeck(spriteSheet)
        GuiManager.rCursor:setIndex(spriteSheet.names['ui_cursor'])
        GuiManager.rCursor:setColor(unpack(Gui.AMBER))

        local bUseHardwareCursor = g_Config:getConfigValue("use_os_mouse") or false
        
        GuiManager.showCursorSprite(not bUseHardwareCursor)
    end

    g_GuiManager.bFinishedInit = true
end

function GuiManager.updateSquadMenu()
	GuiManager.menuManager.getMenu("SquadMenu").loadSaveData()
end

function GuiManager.showCursorSprite(bShowSprite)
    local rRenderLayer = Renderer.getRenderLayer("UIOverlay")

    if bShowSprite then
        rRenderLayer:insertProp(GuiManager.rCursor)    
        MOAIInputMgr.device.pointer:show(false)
    else
        rRenderLayer:removeProp(GuiManager.rCursor)    
        MOAIInputMgr.device.pointer:show(true)    
    end
end

function GuiManager.getSideBar()
    return GuiManager.newSideBar
end

function GuiManager.getStatusBar()
    return GuiManager.statusBar
end

function GuiManager.isInStartupScreen()
    return GuiManager.bInStartupScreen
end

function GuiManager.showStuff()
	GuiManager.killAllEffects()
	GuiManager.newSideBar:show()
	GuiManager.statusBar:show()
	GuiManager.tutorialText:show()
	GuiManager.hintPane:show()
	GuiManager.alertPane:show()
	GuiManager.hintPane:setMaximized(true)
	GuiManager.alertPane:setMaximized(true)
end

function GuiManager.hideStuff()
	GuiManager.newSideBar:hide()
	GuiManager.statusBar:hide()
	GuiManager.tutorialText:hide()
	GuiManager.hintPane:hide()
	GuiManager.alertPane:hide()
end

function GuiManager.setIsInStartupScreen(bSet)
    GuiManager.bInStartupScreen = bSet
end

function GuiManager.fadeInCentered(which, scale)
    GuiManager.shim = GuiManager.startMenu:addOnePixel()
    GuiManager.shim:setScl(3000,3000)
    GuiManager.shim:setLoc(-Renderer.getViewport().sizeX/2,Renderer.getViewport().sizeY/2)
    GuiManager.shim:setColor(0,0,0,1)
    Renderer.getRenderLayer('UIOverlay'):insertProp(GuiManager.shim)
    GuiManager.shim:setPriority(4)
    GuiManager.shim:setVisible(true)

    GuiManager.legalScreen = GuiManager.startMenu:getUITextureProp(which)
    local w,h = DFGraphics.getFullSpriteDims(GuiManager.legalScreen.deck,which)
    local scaleOverride = scale or 2 -- JM: for some reason stuff is scaled 0.5x sooooo doing this,,,
    w = w * scaleOverride
    h = h * scaleOverride
    GuiManager.legalScreen:setLoc(Renderer.getViewport().sizeX/2-w/2,-(Renderer.getViewport().sizeY/2-h/2))
    GuiManager.legalScreen:setScl( scaleOverride,scaleOverride ) 
    Renderer.getRenderLayer('UIOverlay'):insertProp(GuiManager.legalScreen)
    GuiManager.legalScreen:setPriority(5)
    GuiManager.legalScreen:setVisible(true)
    GuiManager.addVersionProp()
end

function GuiManager.addVersionProp()
    if not GuiManager.rVersionProp then
        GuiManager.rVersionProp = Gui.createTextBox('dosismedium44',MOAITextBox.CENTER_JUSTIFY,MOAITextBox.CENTER_JUSTIFY)
        local str = MOAIEnvironment.appVersion
		-- no subtitle for 1.0
        --str = str..': "'..g_LM.line(GuiManager.VERSION_SUBTITLE)..'\"'
        if DFSpace.isDev() then
            str = str..'\nDEBUG VERSION'
        end
        GuiManager.rVersionProp:setString(str)
        Renderer.getRenderLayer('UIOverlay'):insertProp(GuiManager.rVersionProp)
        GuiManager.rVersionProp:setPriority(100000)
	    GuiManager.rVersionProp:setRect(-800, 200, 800, 0)
        GuiManager.rVersionProp:setColor(GuiManager.AMBER[1],GuiManager.AMBER[2],GuiManager.AMBER[3], 1)
        GuiManager.rVersionProp:setLoc(Renderer.getViewport().sizeX/2,-Renderer.getViewport().sizeY+175)
        GuiManager.rVersionProp:setVisible(true)
    end
end

function GuiManager.removeVersionProp()
    if GuiManager.rVersionProp then
        Renderer.getRenderLayer('UIOverlay'):removeProp(GuiManager.rVersionProp)
        GuiManager.rVersionProp = nil
    end
end

function GuiManager.fadeOutFullScreen()
    GuiManager.removeVersionProp()

    if GuiManager.shim then
        GuiManager.startMenu:removeElement(GuiManager.shim)
        Renderer.getRenderLayer('UIOverlay'):removeProp(GuiManager.shim)
        GuiManager.shim:setVisible(false)
        GuiManager.shim = nil
    end
    Renderer.getRenderLayer('UIOverlay'):removeProp(GuiManager.legalScreen)
    GuiManager.legalScreen = nil
end

function GuiManager.killAllEffects()
	GuiManager.uiEffectMask:removeAllMasks()
end

function GuiManager.createEffectMaskBox(x,y,w,h,nTime,nIntensity)
    if not nTime then nTime = 5.0 end
    if not nIntensity then nIntensity = 1.0 end
   
    --add margins so the mask soft edge sits just outside the intended region
    local borderMarginW = w * 0.1
    local borderMarginH = h * 0.1
    
    GuiManager.uiEffectMask:addMask(x-borderMarginW,y-borderMarginH,w+borderMarginW*2,h+borderMarginH*2,nTime,nIntensity)
end

function GuiManager.onResize()
	if GuiManager.rVersionProp then
		GuiManager.rVersionProp:setLoc(Renderer.getViewport().sizeX/2,-Renderer.getViewport().sizeY+175)
	end
    GuiManager.statusBar:onResize()
    GuiManager.tutorialText:onResize()
	GuiManager.hintPane:onResize()
    GuiManager.alertPane:onResize()
    GuiManager.newSideBar:onResize()
    if Gui.rCurActivePane then
        Gui.rCurActivePane:onResize()
    end
    for i, rExistingUI in ipairs(GuiManager.tPopupQueue) do
        rExistingUI:onResize()
    end
end

function GuiManager.refresh()
    GuiManager.newSideBar:refresh()
    Cursor.refresh()
    if GameRules.currentMode == GameRules.MODE_GLOBAL_JOB then
        if Gui.rCurActivePane ~= GuiManager.globalJobs then
            Gui.setActivePane(GuiManager.globalJobs, nil, GuiManager.basePri+99999)
        end
    else
        if Gui.rCurActivePane == GuiManager.globalJobs then
            Gui.setActivePane(nil, nil, GuiManager.basePri)
            GuiManager.newSideBar:show(GuiManager.basePri)
        end
    end
end

function GuiManager.touchInside(sx,sy)
    GuiManager.touched = GuiManager.hoverInside(sx,sy)

    return GuiManager.touched
end

function GuiManager.inspectMode()
    if GameRules.currentMode == GameRules.MODE_INSPECT and 
            (not GuiManager.newSideBar.rSubmenu or GuiManager.newSideBar.rSubmenu == GuiManager.newSideBar.rInspectMenu) then
        return true
    end
end

function GuiManager.updateHoverTarget(sx, sy, dt)
    if not GuiManager.inMainScreen() then -- don't update hovertarget when in pause menu
        return
    end
	local wx, wy = Renderer.getRenderLayer(Character.RENDER_LAYER):wndToWorld(sx, sy)
	local hovering = nil
    if GuiManager.inspectMode() then
		-- hovering a beacon?
		hovering = GuiManager._getTargetAt(wx, wy, 'room', {isBeacon=true})
		if hovering ~= g_ERBeacon then
			hovering = GuiManager._getTargetAt(wx, wy, 'room')
		end
    elseif GameRules.currentMode == GameRules.MODE_PICK then
        -- begin changes for mod HighlightUnassignedBedsAndCitizens (1/2)
        if GameRules.currentModeParam and GameRules.currentModeParam.onTick then
            GameRules.currentModeParam.onTick(dt, GameRules.currentModeParam)
        end
        -- end changes for mod HighlightUnassignedBedsAndCitizens (1/2)
        hovering = GuiManager._getTargetAt(wx,wy,'room',{sOnlyThisType=GameRules.currentModeParam and GameRules.currentModeParam.target, sOnlyThisSubtype=GameRules.currentModeParam and GameRules.currentModeParam.objSubtype})
	-- beacon mode: ignore objects
    elseif GameRules.currentMode == GameRules.MODE_BEACON then
		hovering = GuiManager._getTargetAt(wx, wy, 'room', {sOnlyThisType=true})
	elseif GameRules.currentMode == GameRules.MODE_PLACE_PROP then
		hovering = GuiManager._getTargetAt(wx, wy, 'room', {sOnlyThisType=true})
	end
    if GuiManager.hoverTarget and GuiManager.hoverTarget.bDestroyed then GuiManager.hoverTarget = nil end
    
	-- unhovering anything?
	if GuiManager.hoverTarget and GuiManager.hoverTarget ~= hovering then
		if GuiManager.hoverTarget.unHover then
			GuiManager.hoverTarget:unHover()
		end
	end
	-- hovering nothing?
	if not hovering then
		GuiManager.hoverTarget = nil
        GuiManager.hoverTime = 0
		return
	end
	-- determine type
	-- (not used at the moment, might be handy in the future)
	local hoverType = nil
	if hovering._ObjectList_ObjectMarker then
		if hovering._ObjectList_ObjectMarker.objType == ObjectList.ENVOBJECT then
			hoverType = ObjectList.ENVOBJECT
		elseif hovering._ObjectList_ObjectMarker.objType == ObjectList.CHARACTER then
			hoverType = ObjectList.CHARACTER
        elseif hovering._ObjectList_ObjectMarker.objType == ObjectList.ROOM then
			hoverType = ObjectList.ROOM
		end
	end
	-- never hover hidden rooms or objects
	local bHoveringHidden = false
	if hoverType == ObjectList.ROOM and hovering.nLastVisibility == World.VISIBILITY_HIDDEN then
		bHoveringHidden = true
    elseif hoverType == ObjectList.ENVOBJECT and (hovering.getRoom and hovering:getRoom() and hovering:getRoom().nLastVisibility) == World.VISIBILITY_HIDDEN then
		bHoveringHidden = true
	end
	if bHoveringHidden then
		GuiManager.hoverTarget = nil
        GuiManager.hoverTime = 0
		return
	end
	-- tell the thing we're hovering (it's only polite)
	if hovering.hover then
		hovering:hover(GuiManager.hoverTime or 0)
	end
	-- remember what we're hovering for next time
	GuiManager.hoverTarget = hovering
    if not GuiManager.hoverTime then
       GuiManager.hoverTime = 0 
    end
    GuiManager.hoverTime = GuiManager.hoverTime + dt
end

function GuiManager.hoverInside(sx,sy)
    GuiManager.touched = nil
    GuiManager.bCanShowWorldToolTip = false

    if GameRules.currentMode == GameRules.MODE_GLOBAL_JOB then return GuiManager.globalJobs
    end
    
    local renderLayer = Renderer.getRenderLayer('UI')
    local wx, wy = renderLayer:wndToWorld(sx,sy)

    --MASSIVE HACK for pause menu taking precedence: KSC
    if Gui.rCurActivePane and Gui.rCurActivePane == GuiManager.startMenu then
        Gui.rCurActivePane:inside(wx,wy)
        return Gui.rCurActivePane
    end

    if (table.getn(GuiManager.tPopupQueue) > 0) then
        if GuiManager.tPopupQueue[1] then
            GuiManager.tPopupQueue[1]:inside(wx,wy)
        end
        return GuiManager.tPopupQueue[1]
    end
    
    if g_Gui.touchInside(sx,sy) then 
        return g_Gui
    end
	
	---------------------------------------
	if GuiManager.menuManager.getActive() ~= nil then
		if GuiManager.menuManager.getActive():inside(wx, wy) then
			return GuiManager.menuManager.getActive()
		end
	end
	---------------------------------------
	
    if GuiManager.hintPane:inside(wx,wy) then
        return GuiManager.hintPane
    end
    
    if GuiManager.alertPane:inside(wx,wy) then
        return GuiManager.alertPane
    end

    if GuiManager.statusBar:inside(wx,wy) then
        return GuiManager.statusBar
    end
    
    if GuiManager.newSideBar:inside(wx,wy) then
        return GuiManager.newSideBar
    end

    -- touching none of the other menus.  Should show tooltip
    GuiManager.bCanShowWorldToolTip = true

    return nil
end

function GuiManager.onTick(dt)
    local DBG_moreProfiling = false

    if DBG_moreProfiling then
        Profile.enterScope("Log")
    end

    if DBG_moreProfiling then
        Profile.leaveScope("Log")
        Profile.enterScope("SideBar")
    end
    GuiManager.newSideBar:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("SideBar")
        Profile.enterScope("StartMenu")
    end
    GuiManager.startMenu:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("StartMenu")
        Profile.enterScope("StatusBar")
    end
    GuiManager.statusBar:onTick(dt)
    GuiManager.tutorialText:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("StatusBar")
        Profile.enterScope("GlobalJobs")
    end
    GuiManager.globalJobs:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("GlobalJobs")
        Profile.enterScope("DebugInfoPane")
    end
	GuiManager.debugInfoPane:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("DebugInfoPane")
        Profile.enterScope("BuildHelper")
    end
	GuiManager.buildHelper:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("BuildHelper")
        Profile.enterScope("HintPane")
    end
	GuiManager.hintPane:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("HintPane")
        Profile.enterScope("AlertPane")
    end
    GuiManager.alertPane:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("AlertPane")
        Profile.enterScope("UIEffectMask")
    end
    GuiManager.uiEffectMask:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("UIEffectMask")
        Profile.enterScope("NewBase")
    end
    GuiManager.newBase:onTick(dt)
    if DBG_moreProfiling then
        Profile.leaveScope("NewBase")
    end
    
     
    if GameRules.bRunning and GameRules.cursorX and GameRules.cursorY then
        if DBG_moreProfiling then
            Profile.enterScope("HoverTarget")
        end
        GuiManager.updateHoverTarget(GameRules.cursorX, GameRules.cursorY, dt)
        if DBG_moreProfiling then
            Profile.leaveScope("HoverTarget")
        end
    end
    
    if DBG_moreProfiling then
        Profile.enterScope("AlertSetLoc")
    end
    GuiManager.snapAlertPos()

    if GuiManager.worldToolTip then
        if (GameRules.currentMode == GameRules.MODE_INSPECT or
		    -- begin changes for mod HighlightUnassignedBedsAndCitizens (2/2)
            GameRules.currentMode == GameRules.MODE_PICK or
		    -- end changes for mod HighlightUnassignedBedsAndCitizens (2/2)
			GameRules.currentMode == GameRules.MODE_BEACON or
			GameRules.currentMode == GameRules.MODE_PLACE_PROP) and GuiManager.shouldShowWorldToolTip() then
            GuiManager.worldToolTip:setTarget(GuiManager.hoverTarget)        
            GuiManager.worldToolTip:onTick(dt)
            if GuiManager.hoverTarget and GuiManager.worldToolTip.rCurTarget and GuiManager.worldToolTip.rCurTarget.getToolTipTextInfos  then
                if not GuiManager.worldToolTip:isVisible() then
                    GuiManager.worldToolTip:show()
                end
            else
                if GuiManager.worldToolTip:isVisible() then
                    GuiManager.worldToolTip:hide(true)
                end
            end
        else
            if GuiManager.worldToolTip:isVisible() then
                GuiManager.worldToolTip:hide(true)
            end
        end
    end
    if DBG_moreProfiling then
        Profile.leaveScope("AlertSetLoc")
    end

    if MOAIInputMgr.device.pointer then
        if DBG_moreProfiling then
            Profile.enterScope("tooltip")
        end
        if not GuiManager.isInStartupScreen() then
            local sRenderlayer = 'UIOverlay'
            local x, y = MOAIInputMgr.device.pointer:getLoc()
            local renderLayer = Renderer.getRenderLayer(sRenderlayer)
            local wx, wy = renderLayer:wndToWorld(x, y)
            GuiManager.rCursor:setLoc(wx, wy)
            
            local nPri = GuiManager.getMaxPriOnLayer(sRenderlayer)
            GuiManager.rCursor:setPriority(nPri + 1000)
            
            if GuiManager.worldToolTip then
                local nOffsetX, nOffsetY = GuiManager.worldToolTip:getCursorOffset()
                GuiManager.worldToolTip:setLoc(wx + nOffsetX, wy + nOffsetY)
            end
        end
        if DBG_moreProfiling then
            Profile.leaveScope("tooltip")
        end
    end
end

function GuiManager.snapAlertPos()
    local _,nHintYSize = GuiManager.hintPane:getDims()
    local nHintX, nHintY = GuiManager.hintPane:getLoc()
    local nAlertX, nAlertY = GuiManager.alertPane:getLoc()
    GuiManager.alertPane:setLoc(nAlertX, nHintY + nHintYSize)
end

function GuiManager.inMainScreen()
    -- returns false if the new base screen, start menu etc have focus
    return Gui.rCurActivePane ~= GuiManager.startMenu and Gui.rCurActivePane ~= GuiManager.newBase
end

function GuiManager.showStartMenu(bFirstTime)
    GuiManager.addVersionProp()
    if bFirstTime then GuiManager.startMenu:setFirstTime() end
    Gui.setActivePane(GuiManager.startMenu)
    local w,h = GuiManager.startMenu.width,GuiManager.startMenu.height
    --GuiManager.startMenu:setLoc(Renderer.getViewport().sizeX*.5 - w*.5,-Renderer.getViewport().sizeY*.5 + h*.5)
    SoundManager.playSfx("menu")
    if g_GameRules.getTimeScale() ~= 0 then
        GuiManager.startMenu.bWasPaused = false
        g_GameRules.togglePause()
    else
        GuiManager.startMenu.bWasPaused = true        
    end
end

function GuiManager.showNewBaseScreen()
    --Gui.setActivePane(GuiManager.newBase)
    SoundManager.playSfx("menu")
    g_GameRules.lockTimeScale(false)
    if g_GameRules.getTimeScale() ~= 0 then
        g_GameRules.togglePause()
    end
	-- don't shut down GameRules until new base deploys
	g_GuiManager.shutdown()
	g_GuiManager.setCursorVisible(false)
	g_GuiManager.killAllEffects()
    g_GuiManager.init()
    g_GuiManager.addToPopupQueue(GuiManager.newBase, true)
end

function GuiManager.setSelectedCharacter(char)
    GameRules.setUIMode(GameRules.MODE_INSPECT)
    GuiManager.setSelected(char)
end

function GuiManager.selectCharByID(sID)
	local rChar = CharacterManager.getCharacterByUniqueID(sID)
	GuiManager.setSelectedCharacter(rChar)
end

function GuiManager.getSelected(typeName, subType)
    if typeName then
        local objType, objSubtype = ObjectList.getObjType(GuiManager.rSelected)
        if objType == typeName and (not subType or objSubtype == subType) then
            return GuiManager.rSelected
        end
    elseif GuiManager.rSelected then
		return GuiManager.rSelected
	end
    return nil
end

function GuiManager.getSelectedCharacter()
    --local char = GuiManager.sidebar.activeSubmenu and GuiManager.sidebar.activeSubmenu.getSelected and GuiManager.sidebar.activeSubmenu:getSelected()
    local char = GuiManager.rSelected
    if char and char._ObjectList_ObjectMarker and char._ObjectList_ObjectMarker.objType == ObjectList.CHARACTER then
        return char
    end
end

function GuiManager.setSelected(rTarget)
	-- if we were entering text, bail out cleanly
	local GameScreen = require('GameScreen')
    GameScreen.endTextEntry()
	local bDeselecting = false
	if GuiManager.rSelected and not rTarget then
		g_GameRules.completeTutorialCondition('DeselectedThing')
	end
    -- all clicks clear out selected inventory item, since we don't actually detect clicks on items.
    local rObj = nil
    if rTarget then
        local objType = ObjectList.getObjType(rTarget)
        if objType == 'EnvObject' or objType == 'WorldObject' or objType == 'INVENTORYITEM' then
			-- never select hidden objects
            local rRoom = rTarget.getRoom and rTarget:getRoom()
			if rRoom and rRoom.nLastVisibility == World.VISIBILITY_HIDDEN then
				rTarget = nil
			else
				rObj = rTarget
			end
		-- never select hidden rooms
        elseif objType == 'Room' and rTarget.nLastVisibility == World.VISIBILITY_HIDDEN then
			rTarget = nil
		end
    end
    GuiManager.rSelected = rTarget
    GuiManager.newSideBar.rInspectMenu.rObjectInspector:setObject(rObj)
    
    GuiManager.dSelectionChanged:dispatch(rTarget)
    GuiManager.refresh()
	if rTarget then
		GuiManager.setSelectionProp(rTarget)
		GameRules.completeTutorialCondition('SelectedSomething')
	else
		GuiManager.clearSelectionProp()
	end
end

function GuiManager._getTargetAt(wx, wy, sRoomOrWall, tOptional)
	local isBeacon = tOptional and tOptional.isBeacon or false
	local sOnlyThisType = tOptional and tOptional.sOnlyThisType or nil
	local sOnlyThisSubtype = tOptional and tOptional.sOnlyThisSubtype or nil
	-- don't hover hidden areas UNLESS we're looking for the beacon
	if World.getVisibility(wx, wy) ~= World.VISIBILITY_FULL and not isBeacon then
		return nil
	end
	
    local tTestLayers={Character.RENDER_LAYER,'WorldFloor',Character.BACKGROUND_RENDER_LAYER}
    
    for _,v in ipairs(tTestLayers) do    
        local renderLayer = rLayerOverride or Renderer.getRenderLayer(v)
        local tProps = { renderLayer:getPartition():propListForRay(wx, wy, 15000, 0, 0, -1) }

        if #tProps > 0 then
            local rChar = nil
            local rEnvObject = nil
            local rWall,nBestWallZ = nil
            local rRoom = nil
            for i,v in ipairs(tProps) do
                -- the DFDynamicMesh is what gets returned from the engine, and we've set
                -- a ref to the entity on it.
                local rEnt = v.rEntity
                if rEnt then
                    local rProp = rEnt.rProp
                    if rProp and (not sOnlyThisType or sOnlyThisType == 'Character') then
						-- rig-based pickups/envobjects use rGroundRig
						local rRig = rProp.rRig or rProp.rGroundRig
                        local x0, y0, z0, x1, y1, z1 = rRig.rMainMesh:getWorldBounds(false)
                        if wx > x0 and wx < x1 and wy > y0 and wy < y1 then
                            rChar = rProp
                        end
                    end
                -- include a hydro plant's attached plant prop
                elseif v.rEnvObjParent then
                    if not sOnlyThisType or sOnlyThisType == 'EnvObject' then
                        rEnvObject = v.rEnvObjParent
                    end
				-- 2D props
                elseif v._Instance then
                    local rProp = v._Instance
                    if v._Instance.rEnvObjParent then
                        if not v._Instance.rEnvObjParent.bNoSelect and (not sOnlyThisType or sOnlyThisType == 'EnvObject') then
                            rEnvObject = v._Instance.rEnvObjParent
                        end
                    elseif rProp.tag and (rProp.tag.objType == ObjectList.ENVOBJECT or rProp.tag.objType == ObjectList.WORLDOBJECT) then
                        if not rProp.bNoSelect and (not sOnlyThisType or sOnlyThisType == 'EnvObject') then
                            local x0, y0, z0, x1, y1, z1 = rProp:getWorldBounds(true)
                            if wx > x0 and wx < x1 and wy > y0 and wy < y1 then
                                rEnvObject = rProp
                            end
                        end
					-- ER beacon?
                    elseif rProp == g_ERBeacon and g_ERBeacon:getAttr(MOAIProp.ATTR_VISIBLE) == 1 then
                        if not sOnlyThisType or sOnlyThisType == 'Beacon' then
						    return rProp
                        end
					end
				-- walls
                elseif (sRoomOrWall == 'wall' or sOnlyThisType=='Wall') and v.bWall then
                    if not sOnlyThisType or sOnlyThisType == 'Wall' then
                        if not v.bTop or v.bVisible then
                            local x,y,z = v:getLoc()
                            if not rWall or z > nBestWallZ then 
                                rWall = v
                                nBestWallZ = z
                            end
                        end
                    end
                elseif (sRoomOrWall == 'room' or sOnlyThisType == 'Room') and v.bWall then
                    if not sOnlyThisType or sOnlyThisType == 'Room' then
                        local x,y,z = v:getLoc()
                        rRoom = Room.getRoomFromWall(x,y,0,1)
                    end
                end
            end
            if sRoomOrWall == 'wall' then return rWall end
            if rChar then return rChar end
            if rEnvObject then
                if sOnlyThisSubtype then
                    local tag = ObjectList.getTag(rEnvObject)
                    if tag.objSubtype ~= sOnlyThisSubtype then
                        rEnvObject = nil
                    end
                end
                return rEnvObject 
            end
            if rRoom then 
                if sOnlyThisSubtype then
                    if rRoom:getZoneName() ~= sOnlyThisSubtype then
                        rRoom = nil
                    end
                end
                return rRoom 
            end
        end
    end

    if sRoomOrWall == 'wall' then return nil end
    if not sOnlyThisType or sOnlyThisType == 'Room' then
        local room = Room.getRoomAt(wx,wy,0,1)
        if room and sOnlyThisSubtype then
            if room:getZoneName() ~= sOnlyThisSubtype then
                room = nil
            end
        end
        return room
    end
end

function GuiManager._shouldClick(wx,wy)
    if g_GameRules.bPerformedDrag then
        -- if it's a small distance, it's ok
        local startDragX = g_GameRules.startDragX or 0
        local startDragY = g_GameRules.startDragY or 0
        local curX = g_GameRules.cursorX or 0
        local curY = g_GameRules.cursorY or 0
        local nXDist = math.abs(startDragX - curX)
        local nYDist = math.abs(startDragY - curY)
        local nTotalDragDist = nXDist + nYDist
        GuiManager.LastClickedPos = {wx, wy}
        if nTotalDragDist > kDRAG_SELECT_THRESH then
            return false
        end
    end
    return true
end

function GuiManager.inspectTouch(wx,wy)    
    if GuiManager._shouldClick(wx,wy) then
        local rTarget = GuiManager._getTargetAt(wx,wy,'room')
        GuiManager.setSelected(rTarget)
    end
end

function GuiManager.pickTouch(wx,wy)    
    if GuiManager._shouldClick(wx,wy) then
        local param = GameRules.currentModeParam
        local rTarget = GuiManager._getTargetAt(wx,wy,'room',{sOnlyThisType=param and param.target, sOnlyThisSubtype=param and param.objSubtype})
        if param and param.cb then param.cb(rTarget) end
    end
    GameRules.setUIMode(GameRules.MODE_INSPECT)
end

--
-- mouse click goes here
--
function GuiManager.onFinger(touch)
    local renderLayer = Renderer.getRenderLayer('UI')
    local wx, wy = renderLayer:wndToWorld(touch.x, touch.y)
    local tProps = { renderLayer:getPartition():propListForPoint(wx, wy) }

    --MASSIVE HACK for pause menu taking precedence: KSC
    if Gui.rCurActivePane and Gui.rCurActivePane == GuiManager.startMenu then
        Gui.rCurActivePane:onFinger(touch,wx,wy,tProps)
        return true
    end

    if (table.getn(GuiManager.tPopupQueue) > 0) then
        if GuiManager.tPopupQueue[1] then
            GuiManager.tPopupQueue[1]:onFinger(touch,wx,wy,tProps)
        end
        return true -- since popup we ALWAYS handle this
    end

    local bTouchedSideBar = false
    if Gui.rCurActivePane and Gui.rCurActivePane.onFinger then
        if Gui.rCurActivePane.onFinger(Gui.rCurActivePane,touch,wx,wy,tProps) or (Gui.rCurActivePane and Gui.rCurActivePane.uiBG) then
            return true
        end
    end
	if GuiManager.menuManager.getActive() ~= nil then
		if GuiManager.menuManager.getActive():onFinger(touch, wx, wy, Props) then
			return true
		end
	end
    if GuiManager.statusBar:onFinger(touch,wx,wy,tProps) then
        return true
    else        
        if GuiManager.hintPane:onFinger(touch,wx,wy,tProps) then
            return true
        end
        if GuiManager.alertPane:onFinger(touch,wx,wy,tProps) then
            return true
        end
         -- Gui.rCurActivePane:onFinger(touch,wx,wy,tProps)
        if GameScreen.handleTextEntryClick(wx,wy) then
            return true
        end
        bTouchedSideBar = GuiManager.newSideBar:onFinger(touch,wx,wy,tProps)
        --[[
        if GuiManager.touched then 
            local touched = GuiManager.touched
            GuiManager.touched = nil 
            
            if touched == g_Gui then
                return (touched.onFinger(touch) or bTouchedSideBar)
            else
                return (touched:onFinger(touch,wx,wy,tProps) or bTouchedSideBar)
            end
        end
        ]]--
    end
    return bTouchedSideBar
end

function GuiManager.onKeyboard(key, bDown)
    local bHandled = false
    for i, rExistingUI in ipairs(GuiManager.tPopupQueue) do
        if rExistingUI.onKeyboard and rExistingUI:onKeyboard(key, bDown) then
            return true
        end
    end
    if Gui.rCurActivePane and Gui.rCurActivePane.onKeyboard and Gui.rCurActivePane:onKeyboard(key, bDown) then
        return true
    end
	
    if g_GuiManager.newSideBar:onKeyboard(key, bDown) then
		return true
	end
	if GuiManager.menuManager.getActive() ~= nil then
		return GuiManager.menuManager.getActive():onKeyboard(key, bDown)
	end
end

function GuiManager.createSelectionProp()
    local spriteSheet = DFGraphics.loadSpriteSheet('UI/UIMisc', false, false, false)
	local spriteName = 'character_selected'
	local prop = MOAIProp2D.new()
	prop:setVisible(false)
    prop:setDeck(spriteSheet)
	prop:setIndex(spriteSheet.names[spriteName])
	DFGraphics.alignSprite(spriteSheet, spriteName, "center", "center", 1, 1)
    Renderer.getRenderLayer(Character.RENDER_LAYER):insertProp(prop)
	prop:setColor(unpack(GuiManager.AMBER))
	--prop:setBlendMode(MOAIProp2D.BLEND_MULTIPLY)
	GuiManager.selectionProp = prop
end

function GuiManager.setSelectionProp(object)
	-- we might have been attached to something previously, clear it
	GuiManager.selectionProp:clearAttrLink( MOAITransform.INHERIT_TRANSFORM )
	GuiManager.selectionProp:setLoc(0, 0)
	-- rooms use a different selection viz, don't bother
	if object.type == ObjectList.ROOM then
		GuiManager.selectionProp:setVisible(false)
		-- center on room
		-- JPL TODO: disabled for now, maybe make this a config option?
		--local wx,wy = World._getWorldFromTile(object:getCenterTile())
		--GameRules._centerCameraOnPoint(wx, wy)
		return
	end
	-- set loc offset and scale based on selected object size
	local scale = 1
	local wx, wy = object:getLoc()
	local xoff, yoff = 0, 0
    if not object._ObjectList_ObjectMarker then
        --
    elseif object._ObjectList_ObjectMarker.objType == ObjectList.CHARACTER or object._ObjectList_ObjectMarker.objType == ObjectList.WORLDOBJECT then
		GuiManager.selectionProp:setAttrLink( MOAITransform.INHERIT_TRANSFORM, object, MOAITransform.TRANSFORM_TRAIT )
		scale = 2
	elseif object._ObjectList_ObjectMarker.objType == ObjectList.ENVOBJECT then
		-- JPL TODO: read per-object offset and scale from EnvObjectData!
		local objDef = EnvObject.getObjectData(object.sName)
		if objDef.width == 2 then
			xoff, yoff = 30, -10
			scale = 2
		else
			scale = 1.25
		end
        SoundManager.playSfx(objDef.clickSound)
	end
	GuiManager.selectionProp:setScl(scale, scale)
	if object._ObjectList_ObjectMarker and object._ObjectList_ObjectMarker.objType ~= ObjectList.CHARACTER then
		GuiManager.selectionProp:setLoc(wx + xoff, wy + yoff)
	end
	GuiManager.selectionProp:setVisible(true)
end

function GuiManager.clearSelectionProp()
	GuiManager.selectionProp:setVisible(false)
	GuiManager.selectionProp:clearAttrLink( MOAITransform.INHERIT_TRANSFORM )
end

function GuiManager.getTemplateElementClass(sTemplateTypeName)
    if sTemplateTypeName then
        return GuiManager.tTemplateElementClasses[sTemplateTypeName]
    end
    return nil
end

function GuiManager.addToPopupQueue(rUI, bPauseGame)
    if rUI then
        table.insert(GuiManager.tPopupQueue, rUI)
        rUI:show()
        if bPauseGame then
            g_GameRules.timePause()
        end
    end
end

function GuiManager.clearPopupQueue()
        for i, rExistingUI in ipairs(GuiManager.tPopupQueue) do
            table.remove(GuiManager.tPopupQueue, i)
            rExistingUI:hide(true)
        end
end

function GuiManager.removeFromPopupQueue(rUI, bResumeGame)
    if rUI then
        for i, rExistingUI in ipairs(GuiManager.tPopupQueue) do
            if rUI == rExistingUI then
                table.remove(GuiManager.tPopupQueue, i)
                break
            end
        end
        rUI:hide(true)
        if bResumeGame then
            g_GameRules.timeStandard()
        end
    end
end

function GuiManager.setScrollableUICutoffY(sScrollLayerName, y)
    if sScrollLayerName then       
        local rScrollableScissorRect = GuiManager.tScrollableScissorRects[sScrollLayerName]
        if rScrollableScissorRect then
            rScrollableScissorRect:setRect(0, -GuiManager.getUIViewportSizeY(), GuiManager.getUIViewportSizeX(), y)
        end
    end
end

function GuiManager.getUIViewportSizeX()
    if not Renderer.getViewport() or not Renderer.getViewport().sizeX then
        Print(TT_Warning, "Getting ui viewport sizex without viewport")
        return Renderer.ScreenBufferWidth 
    end
    return Renderer.getViewport().sizeX
end

function GuiManager.getUIViewportSizeY()
    if not Renderer.getViewport() or not Renderer.getViewport().sizeX then
        Print(TT_Warning, "Getting ui viewport sizey without viewport")
        return Renderer.ScreenBufferHeight
    end
    return Renderer.getViewport().sizeY
end

function GuiManager.setMaxPriOnLayer(sRenderLayerName, nMaxPri)
    if sRenderLayerName and nMaxPri then
        if not GuiManager.tMaxPriInfo[sRenderLayerName] then
            GuiManager.tMaxPriInfo[sRenderLayerName] = 0
        end
        if GuiManager.tMaxPriInfo[sRenderLayerName] < nMaxPri then
            GuiManager.tMaxPriInfo[sRenderLayerName] = nMaxPri
        end
    end
end

function GuiManager.getMaxPriOnLayer(sRenderLayerName)
    local nMaxPri = 0
    if sRenderLayerName and GuiManager.tMaxPriInfo[sRenderLayerName] then
        nMaxPri = GuiManager.tMaxPriInfo[sRenderLayerName]
    end
    return nMaxPri
end

function GuiManager.setCursorVisible(bVisible)
    if GuiManager.rCursor then
        GuiManager.bCursorVisible = bVisible -- caching so that we don't make the c++ call every time
        GuiManager.rCursor:setVisible(bVisible)
    end
end

function GuiManager.isCursorVisible()
    return GuiManager.bCursorVisible
end

function GuiManager.shouldShowWorldToolTip()
    if not GuiManager.newBase:isVisible() and not GuiManager.startMenu:isVisible() and GuiManager.bCanShowWorldToolTip then
        return true
    end
    return false
end

function GuiManager.shutdown()
    Gui.setActivePane(nil)
    GuiManager.startMenu:hide(true)
    GuiManager.statusBar:hide(true)
    GuiManager.tutorialText:hide(true)
    GuiManager.newSideBar:hide(true)
    GuiManager.hintPane:hide(true)
    GuiManager.alertPane:hide(true)
    GuiManager.rSelected = nil
    GuiManager.clearSelectionProp()
    GuiManager.clearPopupQueue()
	GuiManager.hintPane:shutdown()
    if GuiManager.newSideBar then
        GuiManager.newSideBar:closeSubmenu()
    end
    GuiManager.startMenu = nil
    GuiManager.statusBar = nil
    GuiManager.tutorialText = nil
    GuiManager.newSideBar = nil
    GuiManager.hintPane = nil
    GuiManager.alertPane = nil
    GuiManager.rSelected = nil
	GuiManager.hintPane = nil
end


function GuiManager.onFileChange(path)    
end

-- Monitor file changes
DFMoaiDebugger.dFileChanged:register(GuiManager.onFileChange)

return GuiManager
