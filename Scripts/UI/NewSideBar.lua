local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local MineMenu = require('UI.MineMenu')
local ConstructMenu = require('UI.ConstructMenu')
local ObjectMenu = require('UI.ObjectMenu')
local NewInspectMenu = require('UI.NewInspectMenu')
local JobRosterMenu = require('UI.JobRoster')
local ResearchMenu = require('UI.ResearchAssignment')
local GoalsList = require('UI.GoalsList')
local BeaconMenu = require('UI.BeaconMenu')
local DisasterMenu = require('UI.DisasterMenu')
local Renderer = require('Renderer')
local SoundManager = require('SoundManager')
local CommandObject = require('Utility.CommandObject')
local Gui = require('UI.Gui')
local MenuManager = require('UI.MenuManager')

local sUILayoutFileName = 'UILayouts/SideBarLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    Ob.bIsExpanded = true
    Ob.rSubmenu = nil

    function Ob:init(menuManager, _world)
        Ob.Parent.init(self)

        self:processUIInfo(sUILayoutFileName)

		--------------------------------------------------------
		self.menuManager = menuManager
		----------------------------------------------------------------
        self.rSmallBarButton = self:getTemplateElement('SmallBarButton')
        if self.rSmallBarButton then
            self.rSmallBarButton:addHoverCallback(self.onSmallbarHovered, self)
        end
        self.rLargeBarButton = self:getTemplateElement('LargeBarButton')
        if self.rLargeBarButton then
            self.rLargeBarButton:addHoverCallback(self.onLargebarHovered, self)
        end
        self.rInspectHotkey = self:getTemplateElement('InspectHotkey')
        self.rInspectHotkeyExpanded = self:getTemplateElement('InspectHotkeyExpanded')
        self.rAssignHotKey = self:getTemplateElement('AssignHotkey')
        self.rAssignHotKeyExpanded = self:getTemplateElement('AssignHotkeyExpanded')
        self.rResearchHotKey = self:getTemplateElement('ResearchHotkey')
        self.rResearchHotKeyExpanded = self:getTemplateElement('ResearchHotkeyExpanded')
        self.rGoalHotKey = self:getTemplateElement('GoalHotkey')
        self.rGoalHotKeyExpanded = self:getTemplateElement('GoalHotkeyExpanded')
        self.rConstructHotKey = self:getTemplateElement('ConstructHotkey')
        self.rConstructHotKeyExpanded = self:getTemplateElement('ConstructHotkeyExpanded')
        self.rMineHotKey = self:getTemplateElement('MineHotkey')
        self.rMineHotKeyExpanded = self:getTemplateElement('MineHotkeyExpanded')
        self.rBeaconHotKey = self:getTemplateElement('BeaconHotkey')
        self.rBeaconHotKeyExpanded = self:getTemplateElement('BeaconHotkeyExpanded')
        self.rDisasterHotKey = self:getTemplateElement('DisasterHotkey')
        self.rDisasterHotKeyExpanded = self:getTemplateElement('DisasterHotkeyExpanded')

        self.rInspectLabel = self:getTemplateElement('InspectLabel')
        self.rAssignLabel = self:getTemplateElement('AssignLabel')
        self.rResearchLabel = self:getTemplateElement('ResearchLabel')
        self.rGoalLabel = self:getTemplateElement('GoalLabel')
        self.rConstructLabel = self:getTemplateElement('ConstructLabel')
        self.rMineLabel = self:getTemplateElement('MineLabel')
        self.rBeaconLabel = self:getTemplateElement('BeaconLabel')
        self.rDisasterLabel = self:getTemplateElement('DisasterLabel')
        self.rDisasterIcon = self:getTemplateElement('DisasterIcon')

        self.rInspectButton = self:getTemplateElement('InspectButton')
        self.rAssignButton = self:getTemplateElement('AssignButton')
        self.rResearchButton = self:getTemplateElement('ResearchButton')
        self.rGoalButton = self:getTemplateElement('GoalButton')
        self.rConstructButton = self:getTemplateElement('ConstructButton')
        self.rMineButton = self:getTemplateElement('MineButton')
        self.rBeaconButton = self:getTemplateElement('BeaconButton')
        self.rDisasterButton = self:getTemplateElement('DisasterButton')

        self.rEndCap = self:getTemplateElement('SidebarBottomEndcap')
        self.rEndCapExpanded = self:getTemplateElement('SidebarBottomEndcapExpanded')

        self.rInspectIcon = self:getTemplateElement('InspectIcon')
        self.rInspectHotkey = self:getTemplateElement('InspectHotkey')
        self.rSmallBarHighlight = self:getTemplateElement('SmallBarHighlight')

        self.rInspectButton:addPressedCallback(self.onInspectButtonPressed, self)
        self.rAssignButton:addPressedCallback(self.onAssignButtonPressed, self)
        self.rResearchButton:addPressedCallback(self.onResearchButtonPressed, self)
        self.rGoalButton:addPressedCallback(self.onGoalButtonPressed, self)
        self.rMineButton:addPressedCallback(self.onMineButtonPressed, self)
        self.rConstructButton:addPressedCallback(self.onConstructButtonPressed, self)
        self.rBeaconButton:addPressedCallback(self.onBeaconButtonPressed, self)
        self.rDisasterButton:addPressedCallback(self.onDisasterButtonPressed, self)

        self.tHotkeyButtons = {}
        self:addHotkey(self.rInspectHotkey.sText, self.rInspectButton)
        self:addHotkey(self.rAssignHotKey.sText, self.rAssignButton)
        self:addHotkey(self.rResearchHotKey.sText, self.rResearchButton)
        self:addHotkey(self.rGoalHotKey.sText, self.rGoalButton)
        self:addHotkey(self.rConstructHotKey.sText, self.rConstructButton)
        self:addHotkey(self.rMineHotKey.sText, self.rMineButton)
        self:addHotkey(self.rBeaconHotKey.sText, self.rBeaconButton)
		
		-----------------------------------------------
		self.rSquadLabel = self:getTemplateElement('SquadLabel')
		self.rSquadIcon = self:getTemplateElement('SquadIcon')
		self.rSquadButton = self:getTemplateElement('SquadButton')
		self.rSquadHotKey = self:getTemplateElement('SquadHotkey')
		self.rSquadHotKeyExpanded = self:getTemplateElement('SquadHotkeyExpanded')
		self.rSquadButton:addPressedCallback(self.onSquadButtonPressed, self)
		self:addHotkey(self.rSquadHotKey.sText, self.rSquadButton)
		------------------------------------------------
        self:setExpanded(false)

		self.rBeaconMenu = BeaconMenu.new(_world)
        self.rMineMenu = MineMenu.new()
        self.rConstructMenu = ConstructMenu.new()
        self.rInspectMenu = NewInspectMenu.new()
        self.rObjectMenu = ObjectMenu.new()
        self.rJobRosterMenu = JobRosterMenu.new()
        self.rResearchMenu = ResearchMenu.new()
        self.rGoalsList = GoalsList.new()
        
        self.rDisasterMenu = DisasterMenu.new()
        
        -- disable + hide disaster menu to start
        self.rDisasterButton:setEnabled(false)
        self:setElementHidden(self.rDisasterButton, true)
        self:setElementHidden(self.rDisasterIcon, true)
        self:setElementHidden(self.rDisasterLabel, true)
        self:setElementHidden(self.rDisasterHotKey, true)
        self:setElementHidden(self.rDisasterHotKeyExpanded, true)
        -- track UI state to listen for change
        self.bDisasterMode = false
		
    end
    
    function Ob:enableDisasterMenu()
        self.bDisasterMode = true
        self.rDisasterButton:setEnabled(true)
        self:setElementHidden(self.rDisasterIcon, false)
        self:setElementHidden(self.rDisasterHotKey, false)
        -- #s taken from SideBarLayout
        local nButtonHeight, nButtons = 81, 8
        self.rEndCap:setLoc(-152, -nButtonHeight * nButtons)
        self.rEndCapExpanded:setLoc(0, -nButtonHeight * nButtons)
        self.rSmallBarButton:setScl(104, nButtonHeight * nButtons)
        self.rLargeBarButton:setScl(286, nButtonHeight * nButtons)
        self:addHotkey(self.rDisasterHotKey.sText, self.rDisasterButton)
    end
    
    function Ob:onTick(dt)
        if self.elementsVisible or g_GuiManager.inMainScreen() then
            if g_GameRules.bDisasterMode and not self.bDisasterMode then
                self:enableDisasterMenu()
            end
            if not self.rSubmenu and g_GuiManager.getSelected() then
                self:openSubmenu(self.rInspectMenu)
            end
            if self.rSubmenu and self.rSubmenu.onTick then
                self.rSubmenu:onTick(dt)
            end
        end
    end

    function Ob:refresh()
        if self.rSubmenu and self.rSubmenu.refresh then
            self.rSubmenu:refresh()
        end
    end

    function Ob:addHotkey(sKey, rButton)
        sKey = string.lower(sKey)

        local keyCode = -1

        if sKey == "esc" then
            keyCode = 27
        elseif sKey == "ret" then
            keyCode = 13
        elseif sKey == "spc" then
            keyCode = 32
        else
            keyCode = string.byte(sKey)

            -- also store the uppercase version because hey why not
            local uppercaseKeyCode = string.byte(string.upper(sKey))
            self.tHotkeyButtons[uppercaseKeyCode] = rButton
        end

        self.tHotkeyButtons[keyCode] = rButton
    end

    function Ob:setButtonsLocked(bDisabled, bHoveredOverride)
        local bEnabled = not bDisabled
        self.rInspectButton:setEnabled(bEnabled)
        self.rAssignButton:setEnabled(bEnabled)
        self.rResearchButton:setEnabled(bEnabled)
        self.rGoalButton:setEnabled(bEnabled)
        self.rConstructButton:setEnabled(bEnabled)
        self.rMineButton:setEnabled(bEnabled)
        self.rBeaconButton:setEnabled(bEnabled)
        if g_GameRules.bDisasterMode then
            self.rDisasterButton:setEnabled(bEnabled)
        end
		-------------------------------------
		self.rSquadButton:setEnabled(bEnabled)
		------------------------------------
    end

    function Ob:playWarbleEffect(bFullscreen, nTimeScale)
        nTimeScale = nTimeScale or 1.0
        if bFullscreen then
            local uiX,uiY,uiW,uiH = Renderer.getUIViewportRect()
            g_GuiManager.createEffectMaskBox(0, 0, uiW, uiH, 0.3 * nTimeScale)
        else
            g_GuiManager.createEffectMaskBox(-80, -80, 500, 1844, 0.3 * nTimeScale, 0.3)
        end
    end

    function Ob:setExpanded(bExpanded, nEffectScale)
        if self.bIsExpanded == bExpanded then
            return
        end
        if nEffectScale then
            self:playWarbleEffect(false, nEffectScale)
        end
		
        self:setElementHidden(self.rSmallBarButton, bExpanded)
        self:setElementHidden(self.rLargeBarButton, not bExpanded)
        self:setElementHidden(self.rInspectButton, not bExpanded)
        self:setElementHidden(self.rInspectHotkey, bExpanded)
        self:setElementHidden(self.rInspectHotkeyExpanded, not bExpanded)
        self:setElementHidden(self.rAssignButton, not bExpanded)
        self:setElementHidden(self.rAssignHotKey, bExpanded)
        self:setElementHidden(self.rAssignHotKeyExpanded, not bExpanded)
        self:setElementHidden(self.rResearchButton, not bExpanded)
        self:setElementHidden(self.rResearchHotKey, bExpanded)
        self:setElementHidden(self.rResearchHotKeyExpanded, not bExpanded)
        self:setElementHidden(self.rGoalButton, not bExpanded)
        self:setElementHidden(self.rGoalHotKey, bExpanded)
        self:setElementHidden(self.rGoalHotKeyExpanded, not bExpanded)
        self:setElementHidden(self.rConstructButton, not bExpanded)
        self:setElementHidden(self.rConstructHotKey, bExpanded)
        self:setElementHidden(self.rConstructHotKeyExpanded, not bExpanded)
        self:setElementHidden(self.rMineButton, not bExpanded)
        self:setElementHidden(self.rMineHotKey, bExpanded)
        self:setElementHidden(self.rMineHotKeyExpanded, not bExpanded)
        self:setElementHidden(self.rBeaconButton, not bExpanded)
        self:setElementHidden(self.rBeaconHotKey, bExpanded)
        self:setElementHidden(self.rBeaconHotKeyExpanded, not bExpanded)
        if g_GameRules.bDisasterMode then
            self:setElementHidden(self.rDisasterButton, not bExpanded)
            self:setElementHidden(self.rDisasterHotKey, bExpanded)
            self:setElementHidden(self.rDisasterHotKeyExpanded, not bExpanded)
        end
		
        self:setElementHidden(self.rInspectLabel, not bExpanded)
        self:setElementHidden(self.rAssignLabel, not bExpanded)
        self:setElementHidden(self.rResearchLabel, not bExpanded)
        self:setElementHidden(self.rGoalLabel, not bExpanded)
        self:setElementHidden(self.rConstructLabel, not bExpanded)
        self:setElementHidden(self.rMineLabel, not bExpanded)
        self:setElementHidden(self.rBeaconLabel, not bExpanded)
        if g_GameRules.bDisasterMode then
            self:setElementHidden(self.rDisasterLabel, not bExpanded)
        end
		
		----------------------------------------------
		self:setElementHidden(self.rSquadButton, not bExpanded)
		self:setElementHidden(self.rSquadLabel, not bExpanded)
		self:setElementHidden(self.rSquadHotKey, bExpanded)
		self:setElementHidden(self.rSquadHotKeyExpanded, not bExpanded)
		------------------------------------------------
		
        self:setElementHidden(self.rEndCap, bExpanded)
        self:setElementHidden(self.rEndCapExpanded, not bExpanded)
        self:setElementHidden(self.rSmallBarHighlight, bExpanded)
		
		
		

        if bExpanded then
            self:setButtonsLocked(false)

            self.rInspectIcon:setColor(unpack(Gui.AMBER))
            self.rInspectHotkey:setColor(unpack(Gui.AMBER))

            if self.rInspectButton:isCursorInside() then
                self.rInspectIcon:setColor(0, 0, 0)
                self.rInspectHotkey:setColor(0, 0, 0)
            end

            self.rLargeBarButton.bDoRolloverCheck = true
            self.rSmallBarButton.bDoRolloverCheck = false
        else
            self:setButtonsLocked(true, false)

            self.rInspectIcon:setColor(0, 0, 0)
            self.rInspectHotkey:setColor(0, 0, 0)

            self.rLargeBarButton.bDoRolloverCheck = false
            self.rSmallBarButton.bDoRolloverCheck = true
        end
        self.bIsExpanded = bExpanded
    end

    function Ob:onSmallbarHovered(rButton, bHovered)
        if bHovered then
            if not self.bIsExpanded then
                SoundManager.playSfx('sidebarexpand')
            end
            self:setExpanded(true, 0.4)
        end
    end

    function Ob:onLargebarHovered(rButton, bHovered)
        if not bHovered then
            if self.bIsExpanded then
                SoundManager.playSfx('degauss')
            end
            self:setExpanded(false, 0.75)
        end
    end

    function Ob:onAssignButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GameRules.currentMode == g_GameRules.MODE_BEACON then
                g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
            end
            self:openSubmenu(self.rJobRosterMenu)
        end
    end

    function Ob:onResearchButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GameRules.currentMode == g_GameRules.MODE_BEACON then
                g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
            end
            self:openSubmenu(self.rResearchMenu)
        end
    end
	
	function Ob:onGoalButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
            self:openSubmenu(self.rGoalsList)
        end
	end
	
    function Ob:openSubmenu(rMenu)
        if self.rSubmenu then
            self.rSubmenu:hide(true)
        end
        if rMenu then
            self:playWarbleEffect()
            self:hide(true)
            self.rSubmenu = rMenu
            rMenu:show()
            SoundManager.playSfx('selectdegauss')
        end
    end

    function Ob:closeSubmenu()
        if self.rSubmenu then
            self:playWarbleEffect()
            self.rSubmenu:hide(true)
            self:show()
            self.rSubmenu = nil
        end
    end

    function Ob:hide(bKeepAlive)
        if self.rSubmenu then
            self.rSubmenu:hide(true)
            self.rSubmenu = nil
        end
        Ob.Parent.hide(self, bKeepAlive)
    end

    function Ob:onMineButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:openSubmenu(self.rMineMenu)
        end
    end

    function Ob:onConstructButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GameRules.currentMode == g_GameRules.MODE_BEACON then g_GameRules.setUIMode(g_GameRules.MODE_INSPECT) end
            self:openConstructMenu(true)
        end
    end

    function Ob:isConstructMenuOpen()
        return self.bConstructMenuOpen
    end

    function Ob:openConstructMenu(bSaveCommandStates)
        self.bConstructMenuOpen = true
        if bSaveCommandStates then
            CommandObject.saveCommandStates()
        end
        self:openSubmenu(self.rConstructMenu)

        if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
        g_GameRules.lockTimeScale(true) -- time can't move when performing construction

        self.bCutawayModeWasEnabled = g_GameRules.isCutawayModeEnabled()
        g_GameRules.enableCutawayMode(true, true) -- hide the back walls
    end

    function Ob:closeConstructMenu()
        self.bConstructMenuOpen = false
        g_GameRules.lockTimeScale(false)

        if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end       

        if self.bCutawayModeWasEnabled then
            g_GameRules.enableCutawayMode(true) -- show the backwalls
        else
            g_GameRules.enableCutawayMode(false)
        end

        self:closeSubmenu()
    end

    function Ob:onInspectButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:openSubmenu(self.rInspectMenu)
        end
    end

    function Ob:onBeaconButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            -- do beacon
            self:openSubmenu(self.rBeaconMenu)
        end
    end

    function Ob:onDisasterButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:openSubmenu(self.rDisasterMenu)
        end
    end
	
	-------------------------------------------------
	function Ob:onSquadButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
            if g_GameRules.currentMode == g_GameRules.MODE_BEACON then
                g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
            end
            --self:openSubmenu(self.rSquadMenu)
			--self:openSubmenu(self.rMenu)
			self.menuManager.showMenu("SquadMenu")
        end
	end
	------------------------------------------------------

    function Ob:onFinger(touch, x, y, props)
        if self.rSubmenu then
            return self.rSubmenu:onFinger(touch, x, y, props)
        else
            return Ob.Parent.onFinger(self, touch, x, y, props)
        end
        return false
    end

    -- returns true if key was handled
    function Ob:onKeyboard(key, bDown)
        local bHandled = false

        if not self.rSubmenu then
            if bDown and self.tHotkeyButtons[key] then
                local rButton = self.tHotkeyButtons[key]
                rButton:keyboardPressed()
                bHandled = true
            end
        end

        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end

        return bHandled
    end

    function Ob:inside(wx, wy)
        if self.rSubmenu then
            return self.rSubmenu:inside(wx, wy)
        else
            return Ob.Parent.inside(self, wx, wy)
        end
    end

    function Ob:onResize()
        Ob.Parent.onResize(self)
        self.rMineMenu:onResize()
        self.rConstructMenu:onResize()
        self.rInspectMenu:onResize()
        self.rObjectMenu:onResize()
        self.rJobRosterMenu:onResize()
        self.rResearchMenu:onResize()
        self.rGoalsList:onResize()
        self.rBeaconMenu:onResize()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
