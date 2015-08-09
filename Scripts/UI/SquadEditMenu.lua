local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local SquadList = require("SquadList")
local SquadEntry = require('UI.SquadEntry')

local sUILayoutFileName = 'UILayouts/SquadLayout' --create a layout for the submenu



--
-- create randomised array of indexes
-- on use, check if it's already in use, if it is move on to next one
--

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local rScrollableUI

    function Ob:init()
        Ob.Parent.init(self)
		--self:refresh()
        self:processUIInfo(sUILayoutFileName)

        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)

        rScrollableUI = self:getTemplateElement('ScrollPane')
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)

	end
	
	function Ob:refresh()

    end
	
    function Ob:addHotkey(sKey, rButton)
        sKey = string.lower(sKey)
    
        local keyCode = -1
    
        if sKey == "esc" then
            keyCode = 27
        elseif sKey == "ret" or sKey == "ent" then
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
    
    -- returns true if key was handled
    function Ob:onKeyboard(key, bDown)
        local bHandled = false

        if not self.rSubmenu then
            if bDown and self.tHotkeyButtons[key] then
                local rButton = self.tHotkeyButtons[key]
                
                -- you pressed the button
                bHandled = true
                rButton:keyboardPressed()
            end
        end
		
        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end
        if bDown and key == 27 then -- esc
			self.onBackButtonPressed()
        end
		
        return bHandled
    end
    
    function Ob:onBackButtonPressed(rButton, eventType)
		self:hide()
		SoundManager.playSfx('degauss')
		Ob.Parent.show()
    end
    
    function Ob:show(basePri)
        --local w = g_GuiManager.getUIViewportSizeY()
        --g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)

        --self.bListDirty = true
        --local nPri = Ob.Parent.show(self, basePri)
        --rScrollableUI:reset()
		-- hide status bar behind us
		--g_GuiManager.statusBar:hide()
		--g_GuiManager.tutorialText:hide()
		--g_GuiManager.hintPane:hide()
		--g_GuiManager.alertPane:hide()
        --return nPri
		
    end

    function Ob:hide(bKeepAlive)
        --Ob.Parent.hide(self, bKeepAlive)
		--self:openSubmenu(parent)
    end

    function Ob:onTick(dt)
        
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if rScrollableUI:onFinger(touch, x, y, props) then
            bHandled = true
        end
        if rScrollableUI:isInsideScrollPane(x, y) then
                   
        end
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        local bHandled = Ob.Parent.inside(self, wx, wy)
        rScrollableUI:inside(wx, wy)
             
        return bHandled
    end

    function Ob:onResize()
        Ob.Parent.onResize(self,true)
        rScrollableUI:onResize()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
