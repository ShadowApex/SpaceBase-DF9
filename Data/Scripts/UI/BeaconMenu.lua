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
local BeaconMenuEdit = require('UI.BeaconMenuEdit')
local UIList = require('SBRS.UIList')
--local UIScroll = require('SBRS.UIScroll')

local sUILayoutFileName = 'UILayouts/BeaconMenuLayout'

-- Things not working:
--
--    - Scrollbar displaying on right instead of left
--    - Arrow texture not correct, have to figure out post effects
--    - When scrolling, items that are off the scrollbar are still visible

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil
	local activeThreatButton = nil
	local squadList = World.getSquadList()
	local activeEntry = nil
--	local rScrollableUI
	local nNumEntries = 0
	local rThreatHighButton, rThreatMediumButton, rThreatLowButton, rStandDownButton
	local rThreatHighLabel, rThreatMediumLabel, rThreatLowLabel, rStandDownLabel
	local rThreatHighHotkey, rThreatMediumHotkey, rThreatLowHotkey, rStandDownHotkey
	local rBeaconMenuEdit
	local nBeaconMenuEditXLoc = 400
	local rUIList = UIList.new()

    function Ob:init(_menuManager)
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
		self.rCreateSquadButton = self:getTemplateElement('CreateSquadButton')
--		rScrollableUI = self:getTemplateElement('ScrollPane')
--		rScrollableUI:setRenderLayer('UIScrollLayerLeft')
--		rScrollableUI:setScissorLayer('UIScrollLayerLeft')
--		rScrollableUI:addElement(rUIList)
		self:addElement(rUIList)
		
--		local rUIScroll = UIScroll.new(400, 1000)
--		rUIScroll:addElement(rUIList)
--		self:addElement(rUIScroll)
		rUIList:setLoc(0, -134)
		
        self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
		self.rCreateSquadButton:addPressedCallback(self.onCreateSquadButtonPressed, self)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
		self:addHotkey(self:getTemplateElement('CreateSquadHotkey').sText, self.rCreateSquadButton)
		rBeaconMenuEdit = BeaconMenuEdit.new(self, _menuManager)
		
		self:addElement(rBeaconMenuEdit)
		rBeaconMenuEdit:hide()
		rBeaconMenuEdit:setLoc(-300, 300) -- appearing for no apparent reason, so move it off screen
		self:_calcDimsFromElements()
		
		self:addHotkey(rBeaconMenuEdit:getTemplateElement('HighViolenceHotkey').sText, rBeaconMenuEdit.rHighViolenceButton)
		self:addHotkey(rBeaconMenuEdit:getTemplateElement('MedViolenceHotkey').sText, rBeaconMenuEdit.rMedViolenceButton)
		self:addHotkey(rBeaconMenuEdit:getTemplateElement('LowViolenceHotkey').sText, rBeaconMenuEdit.rLowViolenceButton)
		self:addHotkey(rBeaconMenuEdit:getTemplateElement('NoViolenceHotkey').sText, rBeaconMenuEdit.rNoViolenceButton)
		self:addHotkey(rBeaconMenuEdit:getTemplateElement('EditSquadHotkey').sText, rBeaconMenuEdit.rEditSquadButton)
		self:addHotkey(rBeaconMenuEdit:getTemplateElement('DisbandSquadHotkey').sText,rBeaconMenuEdit.rDisbandSquadButton)
		
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
	
	function Ob:remHotkey(sKey)
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
            self.tHotkeyButtons[uppercaseKeyCode] = nil
        end
		self.tHotkeyButtons[keyCode] = nil
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
	
	function Ob:onCreateSquadButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local squadList = require('World').getSquadList()
			squadList.newSquad()
			self:updateDisplay()
		end
	end
	
	function Ob:onSlotButtonPressed(rEntry, sName)
		local rSquad = squadList.getSquad(sName)
		if not rSquad then
			print("BeaconMenu:onSlotButtonPressed() Error: Couldn't find squad.")
			return
		end
		g_ERBeacon:setSelectedSquad(rSquad)
		if activeEntry then
			activeEntry:setSelected(false)
			activeEntry = nil
		else
			g_ERBeacon:setViolence(sName, EmergencyBeacon.VIOLENCE_DEFAULT)
		end
		rEntry:setSelected(true)
		if g_ERBeacon:getViolence(sName) == 'High' then
			rThreatHighButton:setSelected(true)
		elseif g_ERBeacon:getViolence(sName) == 'Medium' then
			rThreatMediumButton:setSelected(true)
		elseif g_ERBeacon:getViolence(sName) == 'Low' then
			rThreatLowButton:setSelected(true)
		end
		activeEntry = rEntry
		rBeaconMenuEdit:setSquad(rSquad)
		local x,y = activeEntry:getLoc()
		rBeaconMenuEdit:setLoc(nBeaconMenuEditXLoc, y - 60 + rUIList:getScrollDistance())
		rBeaconMenuEdit:show()
	end
	
	function Ob:updateDisplay(isSelectionDisbanded)
		squadList = World.getSquadList()
		local tSquads = squadList.getList()
		local tList = rUIList.getList()
		if nNumEntries ~= squadList.numSquads() then
			for k,v in pairs(tList) do
				if not tSquads[k] then
					rUIList:remove(k)
					v:hide(false)
					v:setLoc(-500, 500)
					v = nil
					nNumEntries = nNumEntries - 1
				end
			end
		end
		for k,v in pairs(tSquads) do
			if not tList[k] then
				self:addEntry(k)
			end
		end
		if isSelectionDisbanded then
			activeEntry = nil
		end
	end
	
	function Ob:addEntry(sName)
		local rNewEntry = BeaconMenuEntry.new(self)
        local w,h = rNewEntry:getDims()
        self:_calcDimsFromElements()
		rNewEntry:setName(squadList.getSquad(sName), self.onSlotButtonPressed)
		rUIList:add(sName, rNewEntry)
		nNumEntries = nNumEntries + 1
		return rNewEntry
	end

    function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        g_GameRules.setUIMode(g_GameRules.MODE_BEACON)
		self:updateDisplay()
		if not activeEntry then
			rBeaconMenuEdit:hide()
		end
        return nPri
    end

    function Ob:hide()
		rBeaconMenuEdit:hide()
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
