local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SelectObjectForZoneMenu = require('UI.SelectObjectForZoneMenu')
local rScrollableUI = require('UI.ScrollableUI')
--local DoorsSubMenu = require('UI.DoorsSubMenu')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/ObjectMenuLayout'

local ZONES_BY_BUTTON_ID = 
{
    AllButton = "ALL",
    AirlockButton = "AIRLOCK",
    LifeSupportButton = "LIFESUPPORT",
    PubButton = "PUB",
    ReactorButton = "POWER",
    RefineryButton = "REFINERY",
    ResidenceButton = "RESIDENCE",
    GardenButton = "GARDEN",
    FitnessButton = "FITNESS",
    ResearchButton = "RESEARCH",
    InfirmaryButton = "INFIRMARY",
	CommandButton = "COMMAND",
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
	    self:setRenderLayer('UIScrollLayerLeft')
        self:processUIInfo(sUILayoutFileName)

		--self.rScrollableUI = self:getTemplateElement('ScrollPane')
		
        self.rBackButton = self:getTemplateElement('BackButton')

        self.rAllButton = self:getTemplateElement('AllButton')
        self.rAirlockButton = self:getTemplateElement('AirlockButton')
--        self.rDoorsButton = self:getTemplateElement('DoorsButton')
        self.rGardenButton = self:getTemplateElement('GardenButton')
        self.rLifeSupportButton = self:getTemplateElement('LifeSupportButton')
        self.rPubButton = self:getTemplateElement('PubButton')
        self.rReactorButton = self:getTemplateElement('ReactorButton')
        self.rRefineryButton = self:getTemplateElement('RefineryButton')
        self.rResidenceButton = self:getTemplateElement('ResidenceButton')
        self.rFitnessButton = self:getTemplateElement('FitnessButton')
        self.rResearchButton = self:getTemplateElement('ResearchButton')
        self.rInfirmaryButton = self:getTemplateElement('InfirmaryButton')
		self.rCommandButton = self:getTemplateElement('CommandButton')
        self.rSelectionHighlight = self:getTemplateElement('SelectionHighlight')
        self.rCancelButton = self:getTemplateElement('CancelButton')
        self.rConfirmButton = self:getTemplateElement('ConfirmButton')
        self.rCostText = self:getTemplateElement('CostText')

        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
        self.rAllButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rAirlockButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
--        self.rDoorsButton:addPressedCallback(self.onDoorsTypeButtonPressed, self)
        self.rLifeSupportButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rGardenButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rPubButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rReactorButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rRefineryButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rResidenceButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rFitnessButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rResearchButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rInfirmaryButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
		self.rCommandButton:addPressedCallback(self.onZoneTypeButtonPressed, self)
        self.rCancelButton:addPressedCallback(self.onCancelButtonPressed, self)
        self.rConfirmButton:addPressedCallback(self.onConfirmButtonPressed, self)

        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
        self:addHotkey(self:getTemplateElement('AllHotkey').sText, self.rAllButton)
        self:addHotkey(self:getTemplateElement('AirlockHotkey').sText, self.rAirlockButton)
--        self:addHotkey(self:getTemplateElement('DoorsHotkey').sText, self.rDoorsButton)       
        self:addHotkey(self:getTemplateElement('LifeSupportHotkey').sText, self.rLifeSupportButton)
        self:addHotkey(self:getTemplateElement('PubHotkey').sText, self.rPubButton)
        self:addHotkey(self:getTemplateElement('GardenHotkey').sText, self.rGardenButton)
        self:addHotkey(self:getTemplateElement('ReactorHotkey').sText, self.rReactorButton)
        self:addHotkey(self:getTemplateElement('RefineryHotkey').sText, self.rRefineryButton)
        self:addHotkey(self:getTemplateElement('ResidenceHotkey').sText, self.rResidenceButton)
        self:addHotkey(self:getTemplateElement('FitnessHotkey').sText, self.rFitnessButton)
        self:addHotkey(self:getTemplateElement('ResearchHotkey').sText, self.rResearchButton)
        self:addHotkey(self:getTemplateElement('InfirmaryHotkey').sText, self.rInfirmaryButton)
		self:addHotkey(self:getTemplateElement('CommandHotkey').sText, self.rCommandButton)
        self:addHotkey(self:getTemplateElement('CancelHotkey').sText, self.rCancelButton)
        self:addHotkey(self:getTemplateElement('ConfirmHotkey').sText, self.rConfirmButton)        

        self.sBuildCostLabel = g_LM.line("BUILDM017TEXT")
        self.sVaporizeLabel = g_LM.line("BUILDM018TEXT")
        self.sUndoLabel = g_LM.line("BUILDM019TEXT")
		
		
        self:setMatterCostVisible(false)
    end

    function Ob:addHotkey(sKey, rButton)
        sKey = string.lower(sKey)

        local keyCode = -1
    
        if sKey == "esc" then
            keyCode = 27
        elseif sKey == "ret" then
            keyCode = 13
        elseif sKey == "spc" then
            keyCode = 32
        elseif sKey == "bksp" then
            keyCode = 8
        else
            keyCode = string.byte(sKey)
            
            -- also store the uppercase version because hey why not
            local uppercaseKeyCode = string.byte(string.upper(sKey))
            self.tHotkeyButtons[uppercaseKeyCode] = rButton
        end
    
        self.tHotkeyButtons[keyCode] = rButton
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
    
    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:openSubmenu(g_GuiManager.newSideBar.rConstructMenu)
            end
        end
    end

    function Ob:onCancelButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            g_GameRules.cancelBuild()
            g_GuiManager.newSideBar:closeConstructMenu()
            SoundManager.playSfx('degauss')
        end
    end

    function Ob:onConfirmButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GameRules.confirmBuild() then
                g_GuiManager.newSideBar:closeConstructMenu()
                SoundManager.playSfx('confirm')
            end
        end
    end

    function Ob:onZoneTypeButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            local sZoneId = ZONES_BY_BUTTON_ID[rButton.sKey]
            
            local rSubmenu = SelectObjectForZoneMenu.new(sZoneId)
            
            g_GuiManager.newSideBar:openSubmenu(rSubmenu)
        end
    end

--[[
    function Ob:onDoorsTypeButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            local rSubmenu = DoorsSubMenu.new()
            g_GuiManager.newSideBar:openSubmenu(rSubmenu)
        end
    end
]]--
	
    function Ob:show(basePri)
        Ob.Parent.show(self, basePri)
    end

    function Ob:hide()
        Ob.Parent.hide(self)
    end

    function Ob:setMatterCostVisible(bVisible)
        if self.bMatterCostVisible ~= bVisible then
            local sTemplateInfoToApply = nil
            if bVisible then
                sTemplateInfoToApply = 'onShowMatterCost'
            else
                sTemplateInfoToApply = 'onHideMatterCost'
            end
            local tInfo = self:getExtraTemplateInfo(sTemplateInfoToApply)
            if tInfo then
                self:applyTemplateInfos(tInfo)
            end
            self.bMatterCostVisible = bVisible
            self.rConfirmButton:setEnabled(true)
        end
    end

	function Ob:getMatterCostText()
		local text = ''
        local sPlus = ''
        local nPendingBuildCost = g_GameRules.getPendingBuildCost()
        if nPendingBuildCost < 0 then sPlus = '+' else sPlus = '-' end
		if nPendingBuildCost ~= 0 then
            text = sPlus..(math.abs(nPendingBuildCost))..' '..self.sBuildCostLabel..'\n'
		end        
        if CommandObject.pendingVaporizeCost > 0 then sPlus = '+' else sPlus = '' end
		if CommandObject.pendingVaporizeCost ~= 0 then
            text = text .. sPlus .. CommandObject.pendingVaporizeCost .. ' ' .. self.sVaporizeLabel .. '\n'
		end        
        if CommandObject.pendingCancelCost > 0 then sPlus = '+' else sPlus = '' end
		if CommandObject.pendingCancelCost ~= 0 then
            text = text .. sPlus .. CommandObject.pendingCancelCost .. ' ' .. self.sUndoLabel
		end
		return text
	end	

    function Ob:onTick(dt)
        local sMatterCostText = self:getMatterCostText()
        if sMatterCostText ~= '' then
            self:setMatterCostVisible(true)
            self.rCostText:setString(sMatterCostText)
        else
            self:setMatterCostVisible(false)
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
