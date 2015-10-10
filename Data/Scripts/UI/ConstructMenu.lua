local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/ConstructMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
		Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rCancelButton = self:getTemplateElement('CancelButton')
        self.rEraseButton = self:getTemplateElement('EraseButton')

        self.rAreaButton = self:getTemplateElement('AreaButton')
        self.rWallButton = self:getTemplateElement('WallButton')
        self.rFloorButton = self:getTemplateElement('FloorButton')
        self.rAirlockButton = self:getTemplateElement('AirlockButton')
        self.rDemolishButton = self:getTemplateElement('DemolishButton')
        self.rVaporizeButton = self:getTemplateElement('VaporizeButton')
        self.rConfirmButton = self:getTemplateElement('ConfirmButton')
        self.rObjectButton = self:getTemplateElement('ObjectButton')
		self.rNoFundsLabel = self:getTemplateElement('NoFundsLabel')
		self.rPendingCostDisplay = self:getTemplateElement('PendingCost')
        self.rSelectionHighlight = self:getTemplateElement('SelectionHighlight')
        self.rCostText = self:getTemplateElement('CostText')

        self.rCancelButton:addPressedCallback(self.onCancelButtonPressed, self)
        self.rEraseButton:addPressedCallback(self.onBuildTypeButtonPressed, self)
        self.rAreaButton:addPressedCallback(self.onBuildTypeButtonPressed, self)
        self.rWallButton:addPressedCallback(self.onBuildTypeButtonPressed, self)
        self.rFloorButton:addPressedCallback(self.onBuildTypeButtonPressed, self)
        self.rDemolishButton:addPressedCallback(self.onBuildTypeButtonPressed, self)
        self.rVaporizeButton:addPressedCallback(self.onBuildTypeButtonPressed, self)
        self.rObjectButton:addPressedCallback(self.onObjectButtonPressed, self)
        self.rConfirmButton:addPressedCallback(self.onConfirmButtonPressed, self)

        self:addHotkey(self:getTemplateElement('CancelHotkey').sText, self.rCancelButton)
        self:addHotkey(self:getTemplateElement('EraseHotkey').sText, self.rEraseButton)
        self:addHotkey(self:getTemplateElement('AreaHotkey').sText, self.rAreaButton)
        self:addHotkey(self:getTemplateElement('WallHotkey').sText, self.rWallButton)
        self:addHotkey(self:getTemplateElement('FloorHotkey').sText, self.rFloorButton)
        self:addHotkey(self:getTemplateElement('VaporizeHotkey').sText, self.rVaporizeButton)
        self:addHotkey(self:getTemplateElement('DemolishHotkey').sText, self.rDemolishButton)
        self:addHotkey(self:getTemplateElement('ConfirmHotkey').sText, self.rConfirmButton)
        self:addHotkey(self:getTemplateElement('ObjectHotkey').sText, self.rObjectButton)

        self.sBuildCostLabel = g_LM.line("BUILDM017TEXT")
        self.sVaporizeLabel = g_LM.line("BUILDM021TEXT")
        self.sDemolishLabel = g_LM.line("BUILDM018TEXT")
        self.sUndoLabel = g_LM.line("BUILDM019TEXT")

        self:setMatterCostVisible(false)
    end
    
    function Ob:setModeSelected(rModeButton)
        for k,v in pairs(self.tHotkeyButtons) do
            v:setSelected(false)
        end
        --if self.rCurModeButton then self.rCurModeButton:setSelected(false) end
        self.rCurModeButton = rModeButton
        if rModeButton then
            --self.rSelectionHighlight:setVisible(true)
            if rModeButton == self.rAreaButton then
                g_GameRules.setUIMode(g_GameRules.MODE_BUILD_ROOM)
            elseif rModeButton == self.rWallButton then
                g_GameRules.setUIMode(g_GameRules.MODE_BUILD_WALL)
            elseif rModeButton == self.rFloorButton then
                g_GameRules.setUIMode(g_GameRules.MODE_BUILD_FLOOR)
            elseif rModeButton == self.rVaporizeButton then
                g_GameRules.setUIMode(g_GameRules.MODE_VAPORIZE)
            elseif rModeButton == self.rDemolishButton then
                g_GameRules.setUIMode(g_GameRules.MODE_DEMOLISH)
            elseif rModeButton == self.rEraseButton then
                g_GameRules.setUIMode(g_GameRules.MODE_CANCEL_COMMAND, CommandObject.CANCEL_PARAM_BUILD)
            end
            --local x, y = self.rCurModeButton:getLoc()
            self.rCurModeButton:setSelected(true)
            --self.rSelectionHighlight:setLoc(x, y)
        else
            self.rSelectionHighlight:setVisible(false)
        end
    end

    function Ob:onCancelButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GameRules.cancelBuild()
                g_GuiManager.newSideBar:closeConstructMenu()
                SoundManager.playSfx('degauss')
            end
        end
    end

    function Ob:onBuildTypeButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:setModeSelected(rButton)            
            SoundManager.playSfx('select')
        end
    end

    function Ob:onConfirmButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
				if g_GameRules.confirmBuild() then
                    g_GuiManager.newSideBar:closeConstructMenu()
                    SoundManager.playSfx('confirm')
                end
            end
        end
    end
	
    function Ob:onObjectButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            g_GuiManager.newSideBar:openSubmenu(g_GuiManager.newSideBar.rObjectMenu)
        end
    end    

    function Ob:show(basePri)
        local nPri = Ob.Parent.show(self, basePri)
        self:setModeSelected(nil)
        return nPri
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        self:setModeSelected(nil)
        g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
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
            self.rConfirmButton:setSelected(false)
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
        if CommandObject.pendingVaporizeCost < 0 then sPlus = '+' else sPlus = '-' end
		if CommandObject.pendingVaporizeCost ~= 0 then
            text = text .. sPlus .. math.abs(CommandObject.pendingVaporizeCost) .. ' ' .. self.sDemolishLabel .. '\n'
		end        
        if CommandObject.pendingCancelCost < 0 then sPlus = '+' else sPlus = '-' end
		if CommandObject.pendingCancelCost ~= 0 then
            text = text .. sPlus .. math.abs(CommandObject.pendingCancelCost) .. ' ' .. self.sUndoLabel
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
