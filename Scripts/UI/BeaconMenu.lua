local m = {}

local Gui = require('UI.Gui')

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local EmergencyBeacon = require('Utility.EmergencyBeacon')
local World = require('World')
local SquadList = require('SquadList')
local BeaconMenuEntry = require('UI.BeaconMenuEntry')

local sUILayoutFileName = 'UILayouts/BeaconMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil
	local activeThreatButton = nil
	local squadList = World.getSquadList()
	local tBeaconMenuEntries = {}
	local activeEntry = nil
	local rScrollableUI
	local nNumEntries = 0
	local rThreatHighButton, rThreatMediumButton, rThreatLowButton, rStandDownButton
	local rThreatHighLabel, rThreatMediumLabel, rThreatLowLabel, rStandDownLabel
	local rThreatHighHotkey, rThreatMediumHotkey, rThreatLowHotkey, rStandDownHotkey

    function Ob:init()
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
		rScrollableUI = self:getTemplateElement('ScrollPane')
		rThreatHighButton = self:getTemplateElement('ThreatHighButton')
		rThreatMediumButton = self:getTemplateElement('ThreatMediumButton')
		rThreatLowButton = self:getTemplateElement('ThreatLowButton')
		rStandDownButton = self:getTemplateElement('StandDownButton')
		rThreatHighLabel = self:getTemplateElement('ThreatHighLabel')
		rThreatMediumLabel = self:getTemplateElement('ThreatMediumLabel')
		rThreatLowLabel = self:getTemplateElement('ThreatLowLabel')
		rStandDownLabel = self:getTemplateElement('StandDownLabel')
		rThreatHighHotkey = self:getTemplateElement('ThreatHighHotkey')
		rThreatMediumHotkey = self:getTemplateElement('ThreatMediumHotkey')
		rThreatLowHotkey = self:getTemplateElement('ThreatLowHotkey')
		rStandDownHotkey = self:getTemplateElement('StandDownHotkey')

        self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
		rThreatHighButton:addPressedCallback(self.onThreatHighButtonPressed, self)
		rThreatMediumButton:addPressedCallback(self.onThreatMediumButtonPressed, self)
		rThreatLowButton:addPressedCallback(self.onThreatLowButtonPressed, self)
		rStandDownButton:addPressedCallback(self.onStandDownButtonPressed, self)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
		self:addHotkey('z', rThreatHighButton)
		self:addHotkey('x', rThreatMediumButton)
		self:addHotkey('c', rThreatLowButton)
		self:addHotkey('v', rStandDownButton)
		
		-- rThreatHighButton:setEnabled(false)
		rThreatHighLabel:setVisible(false)
		rThreatHighHotkey:setVisible(false)
		-- rThreatMediumButton:setEnabled(false)
		rThreatMediumLabel:setVisible(false)
		rThreatMediumHotkey:setVisible(false)
		-- rThreatLowButton:setEnabled(false)
		rThreatLowLabel:setVisible(false)
		rThreatLowHotkey:setVisible(false)
		rStandDownButton:setVisible(false)
		rStandDownLabel:setVisible(false)
		rStandDownHotkey:setVisible(false)
		self:_calcDimsFromElements()
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
	
	function Ob:onSlotButtonPressed(rEntry, sName)
		if activeEntry then
			activeEntry:setSelected(false)
			activeEntry = nil
		else
			rThreatHighLabel:setVisible(true)
			rThreatHighHotkey:setVisible(true)
			rThreatMediumLabel:setVisible(true)
			rThreatMediumHotkey:setVisible(true)
			rThreatLowLabel:setVisible(true)
			rThreatLowHotkey:setVisible(true)
			rStandDownLabel:setVisible(true)
			rStandDownHotkey:setVisible(true)
			rThreatMediumButton:setSelected(true)
		end
		rEntry:setSelected(true)
		local rSquad = squadList.getSquad(sName)
		if not rSquad then
			print("BeaconMenu:onSlotButtonPressed() Error: Couldn't find squad.")
			return
		end
		if g_ERBeacon:getViolence(sName) == 'High' then
			rThreatHighButton:setSelected(true)
		elseif g_ERBeacon:getViolence(sName) == 'Medium' then
			rThreatMediumButton:setSelected(true)
		elseif g_ERBeacon:getViolence(sName) == 'Low' then
			rThreatLowButton:setSelected(true)
		end
		g_ERBeacon:setSelectedSquad(rSquad)
		activeEntry = rEntry
	end
	
	function Ob:onThreatHighButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			activeThreatButton = rButton
			rButton:setSelected(true)
			g_ERBeacon:setViolence(activeEntry:getName(), EmergencyBeacon.VIOLENCE_LETHAL)
		end
	end
	
	function Ob:onThreatMediumButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			activeThreatButton = rButton
			rButton:setSelected(true)
			g_ERBeacon:setViolence(activeEntry:getName(), EmergencyBeacon.VIOLENCE_DEFAULT)
		end
	end
	
	function Ob:onThreatLowButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			activeThreatButton = rButton
			rButton:setSelected(true)
			g_ERBeacon:setViolence(activeEntry:getName(), EmergencyBeacon.VIOLENCE_NONLETHAL)
		end
	end
	
	function Ob:onStandDownButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:clearThreatButton()
			g_ERBeacon:removeSelectedBeacon()
		end
	end
	
	function Ob:clearThreatButton()
		if activeThreatButton ~= nil then
			activeThreatButton:setSelected(false)
			activeThreatButton = nil
		end
	end
	
	function Ob:updateDisplay()
		squadList = World.getSquadList()
		local tSquads = squadList.getList()
		local count = 0
		if nNumEntries ~= squadList.numSquads() then
			for k,v in pairs(tBeaconMenuEntries) do
				if not tSquads[k] then
					tBeaconMenuEntries[k]:hide(false)
					tBeaconMenuEntries[k] = nil
				end
			end
		end
		for k,v in pairs(tSquads) do
			if not tBeaconMenuEntries[k] then
				self:addEntry(k)
			else
				local w, h = tBeaconMenuEntries[k]:getDims()
				tBeaconMenuEntries[k]:setLoc(0, h * count)
			end
			count = count + 1
		end
		rScrollableUI:refresh()
	end
	
	function Ob:addEntry(sName)
		local rNewEntry = BeaconMenuEntry.new()
        local w,h = rNewEntry:getDims()
        local nYLoc = h * nNumEntries - 1
        rNewEntry:setLoc(0, nYLoc)
        self:_calcDimsFromElements()
        rScrollableUI:addScrollingItem(rNewEntry)
		local sHotkey = ''..(nNumEntries + 1)
		rNewEntry:setName(sName, sHotkey..'.', self.onSlotButtonPressed)
		self:addHotkey(sHotkey, rNewEntry:getTemplateElement("NameButton"))
		tBeaconMenuEntries[sName] = rNewEntry
		nNumEntries = nNumEntries + 1
	end

    function Ob:show(basePri)
		if activeEntry then
			rThreatHighLabel:setVisible(true)
			rThreatHighHotkey:setVisible(true)
			rThreatMediumLabel:setVisible(true)
			rThreatMediumHotkey:setVisible(true)
			rThreatLowLabel:setVisible(true)
			rThreatLowHotkey:setVisible(true)
			rStandDownLabel:setVisible(true)
			rStandDownHotkey:setVisible(true)
		end
        local nPri = Ob.Parent.show(self, basePri)
        g_GameRules.setUIMode(g_GameRules.MODE_BEACON)
		self:updateDisplay()
        return nPri
    end

    function Ob:hide()
		rThreatHighLabel:setVisible(false)
		rThreatHighHotkey:setVisible(false)
		rThreatMediumLabel:setVisible(false)
		rThreatMediumHotkey:setVisible(false)
		rThreatLowLabel:setVisible(false)
		rThreatLowHotkey:setVisible(false)
		rStandDownLabel:setVisible(false)
		rStandDownHotkey:setVisible(false)
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
