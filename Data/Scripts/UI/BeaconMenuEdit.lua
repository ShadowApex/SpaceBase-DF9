local m = {}

local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local EmergencyBeacon = require('Utility.EmergencyBeacon')

local sUILayoutFileName = 'UILayouts/BeaconMenuEditLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local rBeaconMenu
	local rMenuManager
	local activeViolenceButton
	
	function Ob:init(_rBeaconMenu, _rMenuManager)
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
		self.tHotkeyButtons = {}
		rBeaconMenu = _rBeaconMenu
		rMenuManager = _rMenuManager
		
		self.rHighViolenceButton = self:getTemplateElement('HighViolenceButton')
		self.rMedViolenceButton = self:getTemplateElement('MedViolenceButton')
		self.rLowViolenceButton = self:getTemplateElement('LowViolenceButton')
		self.rNoViolenceButton = self:getTemplateElement('NoViolenceButton')
		self.rEditSquadButton = self:getTemplateElement('EditSquadButton')
		self.rDisbandSquadButton = self:getTemplateElement('DisbandSquadButton')
		
		self.rHighViolenceButton:addPressedCallback(self.onHighViolenceButtonPressed, self)
		self.rMedViolenceButton:addPressedCallback(self.onMedViolenceButtonPressed, self)
		self.rLowViolenceButton:addPressedCallback(self.onLowViolenceButtonPressed, self)
		self.rNoViolenceButton:addPressedCallback(self.onNoViolenceButtonPressed, self)
		self.rEditSquadButton:addPressedCallback(self.onEditSquadButtonPressed, self)
		self.rDisbandSquadButton:addPressedCallback(self.onDisbandSquadButtonPressed, self)
		
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
	
	function Ob:show(basePri)
		
		return Ob.Parent.show(self, basePri)
	end
	
	function Ob:hide()
		Ob.Parent.hide(self)
	end
	
	function Ob:onHighViolenceButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:selectButton(rButton)
			g_ERBeacon:setViolence(self.rSquad.getName(), EmergencyBeacon.VIOLENCE_LETHAL)
		end
	end
	
	function Ob:onMedViolenceButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:selectButton(rButton)
			g_ERBeacon:setViolence(self.rSquad.getName(), EmergencyBeacon.VIOLENCE_DEFAULT)
		end
	end
	
	function Ob:onLowViolenceButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:selectButton(rButton)
			g_ERBeacon:setViolence(self.rSquad.getName(), EmergencyBeacon.VIOLENCE_NONLETHAL)
		end
	end
	
	function Ob:onNoViolenceButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			self:selectButton(nil)
			g_ERBeacon:hideSelectedBeacon()
		end
	end
	
	function Ob:selectButton(rButton)
		if activeViolenceButton then
			activeViolenceButton:setSelected(false)
		end
		if rButton then
			rButton:setSelected(true)
			activeViolenceButton = rButton
		else
			activeViolenceButton = nil
		end
	end
	
	function Ob:onEditSquadButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			rBeaconMenu:hide()
			local rSquadEditMenu = rMenuManager.getMenu('SquadEditMenu')
			rSquadEditMenu:setSquad(self.rSquad)
			rMenuManager.showMenu("SquadEditMenu")
		end
	end
	
	function Ob:onDisbandSquadButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local squadList = require('World').getSquadList()
			squadList.disbandSquad(self.rSquad.getName())
			rBeaconMenu:updateDisplay()
			self:hide()
		end
	end
	
	function Ob:setSquad(_rSquad)
		self.rSquad = _rSquad
	end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m