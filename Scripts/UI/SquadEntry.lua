local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local Gui = require("UI.Gui")

local sUILayoutFileName = 'UILayouts/SquadEntryLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.name = nil
	local index = -2
	local nameIndex = -2

    function Ob:init()
	
		Ob.Parent.init(self)
        self:setRenderLayer('UIScrollLayerLeft')

        
        self:processUIInfo(sUILayoutFileName)

        self.rNameLabel = self:getTemplateElement('NameLabel')
		self.rDisbandButton = self:getTemplateElement('DisbandButton')
		self.rDisbandButton:addPressedCallback(self.onDisbandButtonPressed, self)
		self.rEditButton = self:getTemplateElement('EditButton')
		self.rEditButton:addPressedCallback(self.onCreateButtonPressed, self)
        self:_calcDimsFromElements()
    end
	
	function Ob:setName(name, disbandCallback, editCallback, _index, _nameIndex)
		self.name = name
		self.disbandCallback = disbandCallback
		self.editCallback = editCallback
		index = _index
		nameIndex = _nameIndex
		if name then
			self.rNameLabel:setString(name)
		end
	end
	
	function Ob:setIndex(_index)
		index = _index
	end
	
	function Ob:onDisbandButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and self.disbandCallback then
			self:disbandCallback(self.name, index, nameIndex)
		end
	end
	
	function Ob:onCreateButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and self.editCallback then
			self:editCallback()
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