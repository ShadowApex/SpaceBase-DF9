local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local TemplateButton = require('UI.TemplateButton')
local DoorControls = require('UI.DoorControls')
local EmergencyAlarmControls = require('UI.EmergencyAlarmControls')
local InfirmaryBedControls = require('UI.InfirmaryBedControls')
local TurretControls = require('UI.TurretControls')
local ObjectList = require('ObjectList')
local GameRules = require('GameRules')
local SoundManager = require('SoundManager')
local CommandObject = require('Utility.CommandObject')
local Character = require('CharacterConstants')
-- begin changes for mod HighlightUnassignedBedsAndCitizens (1/5)
local CharacterManager = require('CharacterManager')
local Base = require('Base')
-- end changes for mod HighlightUnassignedBedsAndCitizens (1/5)

local sUILayoutFileName = 'UILayouts/ObjectActionTabLayout'

local nButtonRight = 160

local tActionButtonData=
{
	-- demolish button
    {
		-- active/inactive linecodes - overriden by labelFn
		sLayoutFile = 'UILayouts/CostToggleButtonLayout',
		-- element for clickable button
		sButtonName = 'CostButton',
		-- element whose text we set to change label
		sLabelElement = 'CostText',
		isVisibleFn=function(self)
			-- if we ever add things that can't be demolished, check that here
			return true
		end,
        buttonStatusFn=function(self)
			if self.rSelected:slatedForTeardown(false,true) then
				return 'selected'
			-- can't demolish if claiming for research
			elseif self.rSelected:slatedForTeardown(true,false) then
				return 'disabled'
			end
			return 'normal'
        end,
		labelFn=function(self)
			local nCost = math.floor(self.rSelected:getVaporizeCost())
			return string.format('%s', nCost)
		end,
		callbackFn=function(self)
			local tx, ty = self.rSelected:getTileCoords()
			local bSlated = self.rSelected:slatedForTeardown(false, true)
			if bSlated then
				CommandObject.undoDemolishObject(tx, ty)
			else
				CommandObject.demolishObject(tx, ty)
			end
			if self.rSelected.setSlatedForDemolition then
				self.rSelected:setSlatedForDemolition(not bSlated)
			end
			SoundManager.playSfx('inspectordoornormal')
		end,
    },
	-- retrieve research
    {
		sLayoutFile = 'UILayouts/CostToggleButtonLayout',
		sButtonName = 'CostButton',
		sLabelElement = 'ButtonLabel',
		sActiveLinecode = 'INSPEC121TEXT',
		sInactiveLinecode = 'INSPEC121TEXT',
		isVisibleFn=function(self)
            return self.rSelected.bHasResearchData
		end,
		buttonStatusFn=function(self)
			if not self.rSelected.bHasResearchData or self.rSelected:slatedForTeardown(false,true) then -- hack bool to indicate datacubes. 
				return 'disabled'
			elseif self.rSelected:slatedForTeardown(true,false) then
				return 'selected'
			end
			return 'normal'
		end,
		callbackFn=function(self)
			local bSlated = self.rSelected:slatedForTeardown(true, false)
			self.rSelected:slateForResearchTeardown(not bSlated)
			SoundManager.playSfx('inspectordoornormal')
		end,
	},
	-- deactivate
	{
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		-- element whose text we set to change label
		sLabelElement = 'ActionLabel',
		sActiveLinecode = 'INSPEC171TEXT',
		sInactiveLinecode = 'INSPEC172TEXT',
		isActiveFn=function(self)
			return self.rSelected.bActive
		end,
		buttonStatusFn=function(self)
			if not self.rSelected:canDeactivate() then
				return 'disabled'
			end
			return 'normal'
		end,
		callbackFn=function(self)
			self.rSelected.bActive = not self.rSelected.bActive
		end,
		nXOverride = 110,
	},
    -- assign bed to
	{
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		-- element whose text we set to change label
		sLabelElement = 'ActionLabel',
		isVisibleFn=function(self)
            local tag = ObjectList.getTag(self.rSelected)
			return tag and tag.objSubtype == 'Bed'
		end,
		buttonStatusFn=function(self)
			if not self.rSelected.rRoom or self.rSelected.rRoom:getTeam() ~= Character.TEAM_ID_PLAYER then
				return 'disabled'
			elseif GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.target == 'Character' then
				return 'selected'
			end
            return 'normal'
		end,
        labelFn=function(self)
			local rChar = self.rSelected:getOwner()
			-- "click to assign"
			if GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.target == 'Character' then
				return g_LM.line('ZONEUI148TEXT')
			elseif rChar then
				return rChar:getNiceName()
			-- "unassigned"
            else
				return g_LM.line('ZONEUI147TEXT')
			end
        end,
		callbackFn=function(self)
		    -- click while selected = bail out of pick mode
			if GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.target == 'Character' then
				-- begin changes for mod HighlightUnassignedBedsAndCitizens (2/5)
                self:cancelPickMode()
			else
				local tParam = {
					target='Character',
                    hoverTime=0,
                    onTick=function(dt, params) self:citizenSelectOnTick(dt, params) end,
					cb=function(rCitizen) self:citizenSelected(rCitizen) end
				}
				-- end changes for mod HighlightUnassignedBedsAndCitizens (2/5)
				GameRules.setUIMode(GameRules.MODE_PICK, tParam)
			end
		end,
		nXOverride = nButtonRight,
		nExtraYOffset = 50,
		-- weird property to keep *next* element on same Y as this one
		bNextUsesSameY = true,
	},
	-- unassign bed
	{
		sLayoutFile = 'UILayouts/CancelButtonLayout',
		sButtonName = 'CancelButton',
		buttonStatusFn=function(self)
			-- only enable when a citizen is assigned
			if self.rSelected:getOwner() then
				return 'normal'
			else
				return 'disabled'
			end
		end,
		callbackFn=function(self)
			if self.rSelected and self.rSelected.setOwner then self.rSelected:setOwner(nil) end
		end,
		isVisibleFn=function(self)
            local tag = ObjectList.getTag(self.rSelected)
			return tag and tag.objSubtype == 'Bed'
		end,
		-- button width = 160
		nXOverride = nButtonRight + 160 + 56,
		nExtraYOffset = 3,
	},
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tButtons = {}
	
    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
		-- special, object-specific controls
        self.rEmergencyAlarmControls = EmergencyAlarmControls.new()
        self.rInfirmaryBedControls = InfirmaryBedControls.new()
        self.rDoorControls = DoorControls.new()
        self.rTurretControls = TurretControls.new()
		self:addElement(self.rEmergencyAlarmControls)
		self:addElement(self.rInfirmaryBedControls)
		self:addElement(self.rDoorControls)
		self:addElement(self.rTurretControls)
		self:setElementHidden(self.rEmergencyAlarmControls, true)
		self:setElementHidden(self.rInfirmaryBedControls, true)
		self:setElementHidden(self.rDoorControls, true)
		self:setElementHidden(self.rTurretControls, true)
		-- action buttons
        local x,y = 20,-40
		local nButtonMargin = 20
        for i,tButtonData in ipairs(tActionButtonData) do
            local rButton = TemplateButton.new()
			rButton:setBehaviorData(tButtonData)
			if tButtonData.callbackFn then
				rButton:addPressedCallback(tButtonData.callbackFn, self)
			end
            local w,h = rButton:getDims()
            self:addElement(rButton)
			if tButtonData.nExtraYOffset then
				y = y - tButtonData.nExtraYOffset
			end
			rButton:setLoc(tButtonData.nXOverride or x, y)
			if not tButtonData.bNextUsesSameY then
				y = y + h - nButtonMargin
			end
            table.insert(self.tButtons, rButton)
        end
		self.rCustomControlsLabel = self:getTemplateElement('CustomControlsLabel')
		-- set custom button label for research
		-- (different from CostToggleButtonLayout defaults)
		local rCostLabel = self.tButtons[2]:getTemplateElement('CostLabel')
		rCostLabel:setString(g_LM.line('INSPEC122TEXT'))
		-- hide matter icon and cost
		self.tButtons[2]:getTemplateElement('CostText'):setVisible(false)
		self.tButtons[2]:getTemplateElement('CostIcon'):setVisible(false)
    end
	
    function Ob:refresh()
        if Ob.Parent.refresh then
			Ob.Parent.refresh(self)
		end
        self:setObject(self.rSelected)
    end
	
    function Ob:setObject(rObject)
        self.rSelected = rObject
		-- TemplateButton behaviors need an object to refer to
        for _,rButton in pairs(self.tButtons) do
			rButton.rSelected = rObject
		end
		if not rObject then
			return
		end
		local rCustomInspector = nil
        local sCustomInspectorName = rObject.getCustomInspectorName and rObject:getCustomInspectorName()
		self:setElementHidden(self.rCustomControlsLabel, false)
		if sCustomInspectorName == 'Door' then
			rCustomInspector = self.rDoorControls
		elseif sCustomInspectorName == 'EmergencyAlarmControls' then
			rCustomInspector = self.rEmergencyAlarmControls
		elseif sCustomInspectorName == 'InfirmaryBedControls' then
			rCustomInspector = self.rInfirmaryBedControls
		elseif sCustomInspectorName == 'TurretControls' then
			rCustomInspector = self.rTurretControls
		elseif self.rSelected.sName == 'Bed' and self.rSelected.getRoom and self.rSelected:getRoom() and self.rSelected:getRoom():getTeam() == Character.TEAM_ID_PLAYER then
			-- bed assignment
			self.rCustomControlsLabel:setString(g_LM.line('PROPSX098TEXT'))
		else
			-- hide custom controls label if there's nothing there
			self:setElementHidden(self.rCustomControlsLabel, true)
		end
		self:_setCustomInspector(rCustomInspector, rObject)
	end
	
    function Ob:citizenSelected(rCitizen)
		-- begin changes for mod HighlightUnassignedBedsAndCitizens (3/5)
        self:cancelPickMode()
        -- end changes for mod HighlightUnassignedBedsAndCitizens (3/5)
        local tag = ObjectList.getTag(self.rSelected)
        if tag and tag.objSubtype == 'Bed' then
            self.rSelected:setOwner(rCitizen)
			self.tButtons[4].bClicked = false
        end
    end
	
	-- begin changes for mod HighlightUnassignedBedsAndCitizens (4/5)
    function Ob:citizenSelectOnTick(dt, params)
        params.hoverTime = params.hoverTime + dt
        self:highlightUnassignedCitizens(true, params.hoverTime)
    end

    function Ob:highlightUnassignedCitizens(bHighlight, highlightTime)
        local alpha
        if bHighlight then
            alpha = math.abs(math.sin(highlightTime * 4)) / 2 + 0.5
        end
        local tChars, _ = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
        for _,rChar in pairs(tChars) do
            local tBedTag = Base.tCharToBed[rChar.tag]
            local rBed = tBedTag and ObjectList.getObject(tBedTag)
            if not rBed then
                if bHighlight then
                    rChar:_setHighlightColor(g_GuiManager.GREEN[1],g_GuiManager.GREEN[2],g_GuiManager.GREEN[3],alpha)
                else
                    rChar:_setHighlightColor()
                end
            elseif rBed:getOwner() ~= rChar then
                local buggyOwner = rBed:getOwner()
                local buggyName = (buggyOwner and 'different owner '..buggyOwner.tStats.sName) or 'no owner'
                Print(TT_Warning, 'Character '..rChar.tStats.sName..' assigned to bed '..rBed:getResidenceString()..' with '..buggyName)
                Base.assignBed(rChar,nil)
                if buggyOwner then
                    Base.assignBed(buggyOwner,nil)
                end
            end
        end
    end
    -- end changes for mod HighlightUnassignedBedsAndCitizens (4/5)
	
    function Ob:_setCustomInspector(rCustomInspector, rObject)
        if self.rCustomInspector and self.rCustomInspector ~= rCustomInspector then
			-- hide old inspector
			self:setElementHidden(self.rCustomInspector, true)
        end
        if rCustomInspector then
			-- show new inspector
			self:setElementHidden(rCustomInspector, false)
            rCustomInspector:setObject(rObject)
        end
        self.rCustomInspector = rCustomInspector
    end
	
    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        for i, rButton in ipairs(self.tButtons) do
            if rButton:isVisible() then
                bHandled = rButton:onFinger(touch, x, y, props)
            end
        end
        if self.rCustomInspector and self.rCustomInspector:onFinger(touch, x, y, props) then
			bHandled = true
        end
        return bHandled
    end
	
	function Ob:hide()
		Ob.Parent.hide(self)
		if self.rCustomInspector then
			self:setElementHidden(self.rCustomInspector, true)
		end
		-- begin changes for mod HighlightUnassignedBedsAndCitizens (5/5)
        self:cancelPickMode()
	end
	
    function Ob:cancelPickMode()
        if GameRules.currentMode == GameRules.MODE_PICK then
            self:highlightUnassignedCitizens(false)
            GameRules.setUIMode(GameRules.MODE_INSPECT)
        end
    end
    -- end changes for mod HighlightUnassignedBedsAndCitizens (5/5)
	
	function Ob:show(nPri)
		local n = Ob.Parent.show(self, nPri)
		if self.rCustomInspector then
			self:setElementHidden(self.rCustomInspector, false)
		end
		return n
	end
	
    function Ob:onTick(dt)
        if not self.rSelected then return end
        if self.rCustomInspector then
            self.rCustomInspector:onTick(dt)
			-- set label for custom controls (on tick in case it changes,
			-- eg infirmary beds)
			if self.rCustomInspector.getCustomControlsLabel then
				self.rCustomControlsLabel:setString(self.rCustomInspector:getCustomControlsLabel())
			end
        end
		-- individual buttons tick their status as defined in behavior data
        for _,rButton in pairs(self.tButtons) do
			rButton:onTick(dt)
		end
    end
	
    function Ob:inside(wx, wy)
        local bInside = Ob.Parent.inside(self, wx, wy)
        for i, rButton in ipairs(self.tButtons) do
            bInside = rButton:inside(wx, wy) or bInside
        end
        if self.rCustomInspector and self.rCustomInspector:inside(wx, wy) then
			bInside = true
        end
        return bInside
    end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
