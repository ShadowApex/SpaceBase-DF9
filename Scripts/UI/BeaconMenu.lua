local m = {}

local Gui = require('UI.Gui')

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local EmergencyBeacon = require('Utility.EmergencyBeacon')
local World = require('World')
local SquadList = require('SquadList')

local sUILayoutFileName = 'UILayouts/BeaconMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil
	local activeSlot = nil
	local activeThreatLevel = nil
	local squadList = World.getSquadList()

    function Ob:init()
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
		self.rSlot1Button = self:getTemplateElement('Slot1Button')
		self.rSlot2Button = self:getTemplateElement('Slot2Button')
		self.rSlot3Button = self:getTemplateElement('Slot3Button')
		self.rSlot4Button = self:getTemplateElement('Slot4Button')
		self.rSlot5Button = self:getTemplateElement('Slot5Button')
		self.rSlot6Button = self:getTemplateElement('Slot6Button')
		self.rSlot7Button = self:getTemplateElement('Slot7Button')
		self.rSlot8Button = self:getTemplateElement('Slot8Button')
		self.rSlot9Button = self:getTemplateElement('Slot9Button')
		self.rSlot10Button = self:getTemplateElement('Slot10Button')
		self.rSlot1Button = self:getTemplateElement('Slot1Button')
		self.rSlot1Button = self:getTemplateElement('Slot1Button')
		self.rSlot1Button = self:getTemplateElement('Slot1Button')
		self.rThreatHighButton = self:getTemplateElement('ThreatHighButton')
		self.rThreatMediumButton = self:getTemplateElement('ThreatMediumButton')
		self.rThreatLowButton = self:getTemplateElement('ThreatLowButton')
		self.rStandDownButton = self:getTemplateElement('StandDownButton')

        self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
		self.rSlot1Button:addPressedCallback(self.onSlot1ButtonPressed, self)
		self.rSlot2Button:addPressedCallback(self.onSlot2ButtonPressed, self)
		self.rSlot3Button:addPressedCallback(self.onSlot3ButtonPressed, self)
		self.rSlot4Button:addPressedCallback(self.onSlot4ButtonPressed, self)
		self.rSlot5Button:addPressedCallback(self.onSlot5ButtonPressed, self)
		self.rSlot6Button:addPressedCallback(self.onSlot6ButtonPressed, self)
		self.rSlot7Button:addPressedCallback(self.onSlot7ButtonPressed, self)
		self.rSlot8Button:addPressedCallback(self.onSlot8ButtonPressed, self)
		self.rSlot9Button:addPressedCallback(self.onSlot9ButtonPressed, self)
		self.rSlot10Button:addPressedCallback(self.onSlot10ButtonPressed, self)
		self.rThreatHighButton:addPressedCallback(self.onThreatHighButtonPressed, self)
		self.rThreatMediumButton:addPressedCallback(self.onThreatMediumButtonPressed, self)
		self.rThreatLowButton:addPressedCallback(self.onThreatLowButtonPressed, self)
		self.rStandDownButton:addPressedCallback(self.onStandDownButtonPressed, self)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
		self:addHotkey(self:getTemplateElement('Slot1Hotkey').sText, self.rSlot1Button)
		self:addHotkey(self:getTemplateElement('Slot2Hotkey').sText, self.rSlot2Button)
		self:addHotkey(self:getTemplateElement('Slot3Hotkey').sText, self.rSlot3Button)
		self:addHotkey(self:getTemplateElement('Slot4Hotkey').sText, self.rSlot4Button)
		self:addHotkey(self:getTemplateElement('Slot5Hotkey').sText, self.rSlot5Button)
		self:addHotkey(self:getTemplateElement('Slot6Hotkey').sText, self.rSlot6Button)
		self:addHotkey(self:getTemplateElement('Slot7Hotkey').sText, self.rSlot7Button)
		self:addHotkey(self:getTemplateElement('Slot8Hotkey').sText, self.rSlot8Button)
		self:addHotkey(self:getTemplateElement('Slot9Hotkey').sText, self.rSlot9Button)
		self:addHotkey(self:getTemplateElement('Slot10Hotkey').sText, self.rSlot10Button)
		self:addHotkey(self:getTemplateElement('ThreatHighHotkey').sText, self.rThreatHighButton)
		self:addHotkey(self:getTemplateElement('ThreatMediumHotkey').sText, self.rThreatMediumButton)
		self:addHotkey(self:getTemplateElement('ThreatLowHotkey').sText, self.rThreatLowButton)
		self:addHotkey(self:getTemplateElement('StandDownHotkey').sText, self.rStandDownButton)
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
	
	function Ob:onSlot1ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 1
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot2ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 2
			rButton:setSelected(true)
		end
	end
	function Ob:onSlot3ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 3
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot4ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 4
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot5ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 5
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot6ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 6
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot7ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 7
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot8ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 8
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot9ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 9
			rButton:setSelected(true)
		end
	end
	
	function Ob:onSlot10ButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearActive()
			activeSlot = 10
			rButton:setSelected(true)
		end
	end
	
	function Ob:onThreatHighButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			activeThreatLevel = 'High'
			rButton:setSelected(true)
		end
	end
	
	function Ob:onThreatMediumButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			activeThreatLevel = 'Medium'
			rButton:setSelected(true)
		end
	end
	
	function Ob:onThreatLowButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			activeThreatLevel = 'Low'
			rButton:setSelected(true)
		end
	end
	
	function Ob:onStandDownButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
		end
	end
	
	function Ob:clearActive()
		if activeSlot ~= nil then
			local rButton = self:getTemplateElement('Slot'..activeSlot..'Button')
			rButton:setSelected(false)
			activeSlot = nil
		end
	end
	
	function Ob:clearThreatButton()
		if activeThreatLevel ~= nil then
			local rButton = self:getTemplateElement('Threat'..activeThreatLevel..'Button')
			rButton:setSelected(false)
			activeThreatLevel = nil
		end
	end
	
	function Ob:updateDisplay()
		local tSquads = squadList.getList()
		local count = 1
		for k,v in pairs(tSquads) do
			local rLabel = self:getTemplateElement('Slot'..count..'Label')
			local rButton = self:getTemplateElement('Slot'..count..'Button')
			local rHotKey = self:getTemplateElement('Slot'..count..'Hotkey')
			rLabel:setString(k)
			rLabel:setVisible(true)
			rButton:setVisible(true)
			rHotKey:setVisible(true)
			count = count + 1
		end
		for i = count, 10, 1 do
			local rLabel = self:getTemplateElement('Slot'..i..'Label')
			local rButton = self:getTemplateElement('Slot'..i..'Button')
			local rHotKey = self:getTemplateElement('Slot'..i..'Hotkey')
			rLabel:setString("")
			rLabel:setVisible(false)
			rButton:setVisible(false)
			rHotKey:setVisible(false)
		end
	end

    function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        g_GameRules.setUIMode(g_GameRules.MODE_BEACON)
		self:updateDisplay()
        return nPri
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
