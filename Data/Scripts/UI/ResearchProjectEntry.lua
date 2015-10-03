local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local TemplateButton = require('UI.TemplateButton')

-- used for each TemplateButton, not this element
local sUILayoutFileName = 'UILayouts/ResearchProjectButtonLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	
    function Ob:init()
        self:setRenderLayer('UIScrollLayerRight')
		
        Ob.Parent.init(self,self:getRenderLayerName())
		
		self.rButton = TemplateButton.new()
        self.rButton:setRenderLayer(self:getRenderLayerName())
        self.rButton:setLayoutFile(sUILayoutFileName)
		self.rButton:setButtonName('Button')
        self:addElement(self.rButton)
		
		self.nProgressBarWidth = self.rButton:getExtraTemplateInfo('nProgressBarWidth')
		self.nProgressBarHeight = self.rButton:getExtraTemplateInfo('nProgressBarHeight')
		
        self.rName = self.rButton:getTemplateElement('ProjectName')
        self.rDesc = self.rButton:getTemplateElement('ProjectDescription')
        self.rIcon = self.rButton:getTemplateElement('ProjectIcon')
        self.rPrereqs = self.rButton:getTemplateElement('ProjectPrereqsText')
        self.rPrereqLocked = self.rButton:getTemplateElement('ProjectPrereqLocked')
        self.rPrereqUnlocked = self.rButton:getTemplateElement('ProjectPrereqUnlocked')
        self.rProgressBar = self.rButton:getTemplateElement('ProjectProgressBar')
        self.rProgressLabel = self.rButton:getTemplateElement('ProjectProgressLabel')
		
        self:_calcDimsFromElements()
        self.rButton:addPressedCallback(self.onButtonPressed, self)
		self.tProject = nil
    end
	
    function Ob:setProject(tProject)
		if not tProject then
			return
		end
		self.tProject = tProject
		self.rName:setString(tProject.sName)
		self.rDesc:setString(tProject.sDesc)
		
		-- use project's icon if given, (?) if not, checkmark for completed ones
		local sSpriteSheetName = tProject.sIconSpriteSheet or 'UI/JobRoster'
		local rIconSheet = require('DFCommon.Graphics').loadSpriteSheet(sSpriteSheetName)
		if tProject.nProgress >= tProject.nTotalNeeded then
			self.rIcon:setIndex(rIconSheet.names['ui_jobs_icon_checkCircle'])
		elseif tProject.sIcon then
			self.rIcon:setIndex(rIconSheet.names[tProject.sIcon])
		else
			self.rIcon:setIndex(rIconSheet.names['ui_jobs_iconHelp'])
		end
		
		-- only display prereqs if we have them
		-- (discoveries have already been filtered out)
		self.rPrereqs:setString('')
        self:setElementHidden(self.rPrereqLocked,true)
        self:setElementHidden(self.rPrereqUnlocked,true)
		if tProject.tPrereqs and #tProject.tPrereqs > 0 then
			local sPrereqs = g_LM.line('RSCHUI001TEXT') .. ' '
			sPrereqs = sPrereqs .. table.concat(tProject.tPrereqs, ', ')
			self.rPrereqs:setString(sPrereqs)
			-- show locked/unlocked icon to show if all prereqs met
			if require('Base').isUnlocked(tProject.sID) then
                self:setElementHidden(self.rPrereqUnlocked,false)
			else
                self:setElementHidden(self.rPrereqLocked,false)
			end
		end
		local sProgress
        if tProject.nProgress >= tProject.nTotalNeeded then
            sProgress = g_LM.line('RSCHUI007TEXT')
        else
            sProgress = string.format('%s / %s', math.floor(tProject.nProgress), math.floor(tProject.nTotalNeeded))
        end
		self.rProgressLabel:setString(sProgress)
		-- set progress bar to correct width
		local w = (tProject.nProgress / tProject.nTotalNeeded) * self.nProgressBarWidth
		self.rProgressBar:setScl(w, self.nProgressBarHeight)
    end
	
	function Ob:onButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.bSelected then
				self.rButton:setSelected(false)
            else
				self.rButton:setSelected(true)
				-- tell parent element we're selected
				self.rAssignmentScreen:projectSelected(self)
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
