local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SoundManager = require('SoundManager')
local ResearchData = require('ResearchData')
local Base = require('Base')

local sUILayoutFileName = 'UILayouts/DebugMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
		self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
		self.rResearchButton = self:getTemplateElement('ResearchButton')
		self.rResearchButton:addPressedCallback(self.onResearchButtonPressed, self)
		self.rResearchAllButton = self:getTemplateElement('ResearchAllButton')
		self.rResearchAllButton:addPressedCallback(self.onResearchAllButtonPressed, self)
		self.tHotkeyButtons = {}
		self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
		self:addHotkey(self:getTemplateElement('ResearchHotkey').sText, self.rResearchButton)
		self:addHotkey(self:getTemplateElement('ResearchAllHotkey').sText, self.rResearchAllButton)
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
        elseif sKey == "bksp" then
            keyCode = 8
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
                rButton:keyboardPressed()
                bHandled = true
            end
        end
        
        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end
        
        return bHandled
    end
	
	function Ob:onDoneButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:closeSubmenu()
                SoundManager.playSfx('degauss')
            end
        end
    end
	
	function Ob:onResearchButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tAvailableResearch = Base.getAvailableResearch()
			for k,v in pairs(tAvailableResearch) do
				if v.nResearchUnits then
					Base.addResearch(k, ResearchData[k].nResearchUnits - v.nResearchUnits)
				end
			end
		end
	end
	
	function Ob:onResearchAllButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tAvailableResearch = Base.getAvailableResearch()
			for k,v in pairs(tAvailableResearch) do
				Base.addResearch(k, ResearchData[k].nResearchUnits)
			end
		end
	end
	
	function Ob:onTick(dt)
		
	end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m