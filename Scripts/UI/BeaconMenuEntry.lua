local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local Gui = require("UI.Gui")

local sUILayoutFileName = 'UILayouts/BeaconMenuEntryLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local sName
	local bDisabled = false
	
	function Ob:init()
        self:setRenderLayer('UIScrollLayerLeft')

        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
		self.rNameLabel = self:getTemplateElement('NameLabel')
		self.rHotKey = self:getTemplateElement('Hotkey')
		self.rNameButton = self:getTemplateElement('NameButton')
		self.rNameButton:addPressedCallback(self.onButtonClicked, self)
		
		self:_calcDimsFromElements()
	end
	
	function Ob:setName(_sName, _sHotkey, rCallback)
		sName = _sName
		self.rNameLabel:setString(sName)
		self.rHotKey:setString(_sHotkey)
		self.rCallback = rCallback
	end
	
	function Ob:getName()
		return sName
	end
	
	function Ob:setSelected(isSelected)
		self.rNameButton:setSelected(isSelected)
	end
	
	function Ob:onButtonClicked(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and not bDisabled then
			self:rCallback(self, sName)
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