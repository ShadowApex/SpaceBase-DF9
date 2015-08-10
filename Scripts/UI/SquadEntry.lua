local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local SoundManager = require('SoundManager')
local Gui = require("UI.Gui")

local sUILayoutFileName = 'UILayouts/SquadEntryLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    local squad
	local index = -2
	local nameIndex = -2

    function Ob:init()
        self:setRenderLayer('UIScrollLayerLeft')

        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rNameLabel = self:getTemplateElement('NameLabel')
		self.rSizeLabel = self:getTemplateElement('SizeLabel')
		self.rDisbandButton = self:getTemplateElement('DisbandButton')
		self.rDisbandButton:addPressedCallback(self.onDisbandButtonPressed, self)
		self.rEditButton = self:getTemplateElement('EditButton')
		self.rEditButton:addPressedCallback(self.onEditButtonPressed, self)
        self:_calcDimsFromElements()
    end
	
	function Ob:setSquad(_squad, disbandCallback, editCallback, _index, _nameIndex)
		squad = _squad
		self.disbandCallback = disbandCallback
		self.editCallback = editCallback
		index = _index
		nameIndex = _nameIndex
		if squad then
			self.rNameLabel:setString(squad.getName())
		end
	end
	
	function Ob:setIndex(_index)
		index = _index
	end
	
	function Ob:update()
		self.rSizeLabel:setString(''..squad.getSize())
	end
	
	function Ob:onDisbandButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and self.disbandCallback then
			self:disbandCallback(squad.getName(), index, nameIndex)
		end
	end
	
	function Ob:onEditButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP and self.editCallback then
			self:editCallback(squad)
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