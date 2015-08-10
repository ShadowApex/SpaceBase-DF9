local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local Gui = require("UI.Gui")

local sUILayoutFileName = 'UILayouts/SquadEditEntryLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local id
	local name
	local disabled = false
	
	function Ob:init()
        self:setRenderLayer('UIScrollLayerLeft')

        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
		self.rNameLabel = self:getTemplateElement('NameLabel')
		self.rNameButton = self:getTemplateElement('NameButton')
		self.rNameButton:addPressedCallback(self.onButtonClicked, self)
		
		self:_calcDimsFromElements()
	end
	
	function Ob:setChar(_id, _name, callback)
		id = _id
		name = _name
		self.rNameLabel:setString(name)
		self.callback = callback
	end
	
	function Ob:onButtonClicked(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and not disabled then
			self:callback(self, id, name)
			SoundManager.playSfx('degauss')
		end
	end
	
	function Ob:hide(bKeepAlive)
		disabled = true
		if self.rNameLabel then
			self.rNameLabel:setVisible(false)
		end
		if self.rNameButton then
			self.rNameButton:setVisible(false)
		end
        Ob.Parent.hide(self, bKeepAlive)
    end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m