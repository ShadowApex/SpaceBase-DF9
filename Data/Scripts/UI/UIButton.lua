local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')

local sUILayoutFileName = 'UILayouts/UIButtonLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local clickCallback = nil
	
    function Ob:init(tOpt)
		Ob.Parent.init(self)
		self:processUIInfo(sUILayoutFileName)
		self.rButton = self:getTemplateElement('Button')
		self.rLabel = self:getTemplateElement('Label')
		self.rHotkey = self:getTemplateElement('Hotkey')
		if tOpt then self:_processOptionalArguments(tOpt) end
--		self:processUIInfo(sUILayoutFileName)
	end
	
	function Ob:onButtonPressed(rButton, eventType)
		print('UIButton:onButtonPressed')
		if eventType == DFInput.TOUCH_UP then
			clickCallback(self.rLabel:getString())
		end
	end
	
	function Ob:_processOptionalArguments(tOpt)
		if tOpt.button then self:_processElement(self.rButton, tOpt.button) end
		if tOpt.label then self:_processElement(self.rLabel, tOpt.label) end
		if tOpt.hotkey then self:_processElement(self.rHotkey, tOpt.hotkey) end
		if tOpt.clickCallback then
			clickCallback = tOpt.clickCallback
			self.rButton:addPressedCallback(self.onButtonPressed, self)
			if tOpt.hotkey and tOpt.hotkey.text then
				print('hotkey.text: '..tOpt.hotkey.text)
				self:addHotkey(tOpt.hotkey.text, self.rButton)
				self:setElementHidden(self.rHotkey, false)
			end
		end
	end
	
	function Ob:_processElement(rElement, tInfo)
		for k,v in pairs(tInfo) do
			rElement[k] = v
		end
	end
	
	return Ob
end


function m.new(...)
    local Ob = m.create()
    Ob:init(...)
    return Ob
end

return m