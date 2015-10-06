local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local Gui = require("UI.Gui")
local Renderer = require('Renderer')
local MOAIPropExt = require('SBRS.MOAIPropExt')
local EmergencyBeacon = require('Utility.EmergencyBeacon')

local sUILayoutFileName = 'UILayouts/BeaconMenuEntryLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local rSquad
	local nIndex
	local bDisabled = false
	local rBeaconMenu
	local sHotkey
	
	function Ob:init(_rBeaconMenu)
		rBeaconMenu = _rBeaconMenu
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
		self.rNameLabel = self:getTemplateElement('NameLabel')
		self.rHotkey = self:getTemplateElement('Hotkey')
		self.rSizeLabel = self:getTemplateElement('SizeLabel')
		self.rStatusLabel = self:getTemplateElement('StatusLabel')
		self.rNameButton = self:getTemplateElement('NameButton')
		self.rNameButton:addPressedCallback(self.onButtonClicked, self)
		
		self:_calcDimsFromElements()
	end
	
	function Ob:setName(_rSquad, rCallback)
		rSquad = _rSquad
		self.rNameLabel:setString(rSquad.getName())
		self.rSizeLabel:setString('Size: '..rSquad.getSize())
		self.rStatusLabel:setString('Status: '..rSquad.getStatusString())
		local rDeckLow, rDeckMed, rDeckHigh = g_ERBeacon:getGraphics(rSquad.getName())
		self.rBeaconLow, self.rBeaconMed, self.rBeaconHigh = MOAIPropExt.new(), MOAIPropExt.new(), MOAIPropExt.new()
		self.rBeaconHigh:setDeck(rDeckHigh)
		self.rBeaconMed:setDeck(rDeckMed)
		self.rBeaconLow:setDeck(rDeckLow)
		Renderer.getRenderLayer('UIOverlay'):insertProp(self.rBeaconHigh)
		Renderer.getRenderLayer('UIOverlay'):insertProp(self.rBeaconMed)
		Renderer.getRenderLayer('UIOverlay'):insertProp(self.rBeaconLow)
		self.rBeaconHigh:setVisible(false)
		self.rBeaconLow:setVisible(false)
		self.rBeaconHigh:setScl(0.5, 0.5, 0.5)
		self.rBeaconMed:setScl(0.5, 0.5, 0.5)
		self.rBeaconLow:setScl(0.5, 0.5, 0.5)
		local xOffset, yOffset = 50, -50
		self.rCallback = rCallback
		self:addElement(self.rBeaconHigh)
		self:addElement(self.rBeaconMed)
		self:addElement(self.rBeaconLow)
		self.rBeaconHigh:setLoc(xOffset, yOffset)
		self.rBeaconMed:setLoc(xOffset, yOffset)
		self.rBeaconLow:setLoc(xOffset, yOffset)
	end
	
	function Ob:getName()
		return rSquad.getName()
	end
	
	function Ob:update(rSource)
		local sNewHotkey = tostring(math.fmod(rSource:getOrder(rSquad.getName()) + 1, 10))
		if sHotkey then
			rBeaconMenu:remHotkey(sHotkey)
		end
		if not sHotkey or sHotkey ~= sNewHotkey then
			sHotkey = sNewHotkey
			rBeaconMenu:addHotkey(sHotkey, self:getTemplateElement("NameButton"))
			self.rHotkey:setString(sHotkey)
		end
	end
	
	function Ob:setSelected(isSelected)
		self.rNameButton:setSelected(isSelected)
	end
	
	function Ob:setViolence(eViolence)
		if eViolence == EmergencyBeacon.VIOLENCE_LETHAL then
			self.rBeaconHigh:setVisible(true)
			self.rBeaconMed:setVisible(false)
			self.rBeaconLow:setVisible(false)
		elseif eViolence == EmergencyBeacon.VIOLENCE_DEFAULT then
			self.rBeaconHigh:setVisible(false)
			self.rBeaconMed:setVisible(true)
			self.rBeaconLow:setVisible(false)
		elseif eViolence == EmergencyBeacon.VIOLENCE_NONLETHAL then
			self.rBeaconHigh:setVisible(false)
			self.rBeaconMed:setVisible(false)
			self.rBeaconLow:setVisible(true)
		end
	end
	
	function Ob:onButtonClicked(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and not bDisabled then
			self:rCallback(self, rSquad.getName())
			SoundManager.playSfx('degauss')
		end
	end
	
	function Ob:hide(bKeepAlive)
		bDisabled = true
		if self.rNameLabel then
			self.rNameLabel:setVisible(false)
		end
		if self.rNameButton then
			self.rNameButton:setVisible(false)
		end
		if self.rHotKey then
			self.rHotKey:setVisible(false)
		end
		self.rBeaconHigh:setVisible(false)
		self.rBeaconMed:setVisible(false)
		self.rBeaconLow:setVisible(false)
        Ob.Parent.hide(self, bKeepAlive)
    end
	
	function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        bDisabled = false
		if self.rNameLabel then
			self.rNameLabel:setVisible(true)
		end
		if self.rNameButton then
			self.rNameButton:setVisible(true)
		end
		if self.rHotKey then
			self.rHotKey:setVisible(true)
		end
		if g_ERBeacon:getViolence(sName) == EmergencyBeacon.VIOLENCE_LETHAL then
			self.rBeaconHigh:setVisible(true)
		elseif g_ERBeacon:getViolence(sName) == EmergencyBeacon.VIOLENCE_DEFAULT and self.rBeaconMed then
			self.rBeaconMed:setVisible(true)
		elseif g_ERBeacon:getViolence(sName) == EmergencyBeacon.VIOLENCE_NONLETHAL then
			self.rBeaconLow:setVisible(true)
		end
        return nPri
    end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m