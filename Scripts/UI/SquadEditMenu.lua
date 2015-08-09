local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
--local CharacterManager = require('CharacterManager')
local Character = require('Character')

local sUILayoutFileName = 'UILayouts/SquadEditLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local rScrollableUI
	local squad
	local menuManager
	local characterManager
	local rSquadEditMenuLabel

    function Ob:init(_menuManager, _characterManager)
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

		menuManager = _menuManager
		characterManager = _characterManager
        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
		rSquadEditMenuLabel = self:getTemplateElement('SquadEditMenuLabel')
		rSquadEditMenuLabel:setString("ARRRRR!")
        rScrollableUI = self:getTemplateElement('ScrollPane')
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
	end
	
	function Ob:setSquad(_squad)
		squad = _squad
		if squad ~= nil then
			rSquadEditMenuLabel:setString(squad.getName())
			--local tChars = characterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
			--self:printTable(tChars)
		else
			rSquadEditMenuLabel:setString("Fail Squad")
		end
	end
	
	function Ob:printTable(tbl)
		for k,v in pairs(tbl) do
			if type(v) == "table" then
				self:printTable(v)
			else
				print(v)
			end
		end
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
        
        return bHandled
    end
    
    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
			menuManager.showMenu("SquadMenu")
			SoundManager.playSfx('degauss')
        end
    end
    
    function Ob:show(basePri)
        local w = g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)

        self.bListDirty = true
        local nPri = Ob.Parent.show(self, basePri)
        rScrollableUI:reset()
        return nPri
    end

    function Ob:hide(bKeepAlive)
        Ob.Parent.hide(self, bKeepAlive)
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
