local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local TemplateButton = require('UI.TemplateButton')
local Room = require('Room')

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	
    function Ob:init()
        self:setRenderLayer('UIScrollLayerLeft')
		
        Ob.Parent.init(self)
        
        self.rButton = TemplateButton.new()
        self.rButton:setLayoutFile('UILayouts/ResearchZoneButtonLayout')
		self.rButton:setButtonName('Button')
        self:addElement(self.rButton)
        
		self.rZoneName = self.rButton:getTemplateElement('ZoneName')
        self.rProjectName = self.rButton:getTemplateElement('ProjectName')
		
        self:_calcDimsFromElements()
        self.rButton:addPressedCallback(self.onButtonPressed, self)
		self.tZone = nil
    end
	
    function Ob:setZone(tZone)
        if not tZone then
            assertdev(false)
            return
        end
		self.tZone = tZone
		-- zone name is not a linecode
		self.rZoneName:setString(tZone.sName)
		self:setProjectString()
    end
	
	function Ob:setZoneProject(tProject)
		local rLab = Room.tRooms[self.tZone.nZoneID]
        if rLab then
		    rLab.zoneObj:setActiveResearch(tProject.sID)
            -- unselect
            self.rButton:setSelected(false)
		    self:setProjectString()
        end
	end
	
	function Ob:setProjectString()
        -- "select a project" prompt
        if self.rButton.bSelected then
            self.rProjectName:setString(g_LM.line('RSCHUI002TEXT'))
        else
            local sEmptyString =  '                             --'
            self.rProjectName:setString(self.tZone.sProjectName or sEmptyString)
        end
	end
	
	function Ob:onButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rButton.bSelected then
				self.rButton:setSelected(false)
                self.rAssignmentScreen:zoneSelected(nil)
            else
				self.rButton:setSelected(true)
				-- tell parent element we're selected
				self.rAssignmentScreen:zoneSelected(self)
            end
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
