local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local Character = require('CharacterConstants')
local SoundManager = require('SoundManager')
local UIElement = require('UI.UIElement')
local Base = require('Base')
local GameRules = require('GameRules')
local ObjectList = require('ObjectList')
local TemplateButton = require('UI.TemplateButton')
-- begin changes for mod HighlightUnassignedBedsAndCitizens (1/4)
local CharacterManager = require('CharacterManager')
-- end changes for mod HighlightUnassignedBedsAndCitizens (1/4)

local sUILayoutFileName = 'UILayouts/ZoneActionTabLayout'

local tActionButtonData=
{
	-- claim/unclaim
    {
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sButtonName = 'ActionButton',
		sLabelElement = 'ActionLabel',
        labelFn=function(self)
            if self.rSelected:getTeam() == Character.TEAM_ID_PLAYER then
                return g_LM.line("ZONEUI112TEXT")
            else
                return g_LM.line("ZONEUI111TEXT")
            end
        end,
        buttonStatusFn=function(self)
            if self.rSelected:getTeam() == Character.TEAM_ID_PLAYER then
                return 'normal'
            end
            if self.rSelected:canClaim() then
                return 'normal'
            end
            return 'disabled'
        end,
    },
	-- seal/unseal o2
    {
		sActiveLinecode="ZONEUI071TEXT",
        sInactiveLinecode="ZONEUI072TEXT",
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sButtonName = 'ActionButton',
		sLabelElement = 'ActionLabel',
		isActiveFn=function(self)
			return not self.rSelected:isLockedDown()
		end,
        buttonStatusFn = function(self)
			local rRoom = self.rSelected
			local bValidAirlock = rRoom.zoneObj and rRoom.zoneObj:isFunctionalAirlock()
			local bPlayerControlled = rRoom:getVisibility() == g_World.VISIBILITY_FULL and rRoom:getTeam() == Character.TEAM_ID_PLAYER
			if not bPlayerControlled or bValidAirlock then
				return 'disabled'
			elseif self.rSelected:isLockedDown() then
                return 'selected'
			end
            return 'normal'
        end,
    },
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tButtons = {}

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)
        local x=110
        local y=-40
		local nButtonMargin = 20
        for i, tButtonData in ipairs(tActionButtonData) do
            local rButton = TemplateButton.new()
			rButton:setBehaviorData(tButtonData)
            local w,h = rButton:getDims()
            self:addElement(rButton)
            rButton:setLoc(x,y)
            y = y + h - nButtonMargin
            table.insert(self.tButtons, rButton)
        end
        self.tButtons[1]:addPressedCallback(self.claimButtonPressed, self)
        self.tButtons[2]:addPressedCallback(self.sealButtonPressed, self)
        self.nStartBedButtonX = x
        self.nStartBedButtonY = y
        self.tCitizenAssignmentButtons = {}
        self.tCitizenUnassignmentButtons = {}
		self.rCustomControlsLabel = self:getTemplateElement('CustomControlsLabel')

        self.rAssignmentScrollableUI = self:getTemplateElement('AssignmentButtonScrollPane')
		self.rAssignmentScrollableUI:setRenderLayer('UIScrollLayerLeft')
        self.rAssignmentScrollableUI:setScissorLayer('UIScrollLayerLeft')
    end

    local tAssignmentButtonData={
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sButtonName = 'ActionButton',
		sLabelElement = 'ActionLabel',
        labelFn=function(btn)
			-- "unassigned"
			local label = g_LM.line('ZONEUI147TEXT')
			-- if selected, "click to assign"
			if btn.bClicked then
				label = g_LM.line('ZONEUI148TEXT')
			else
				local rChar = btn.rZoneActionTab:_btnToChar(btn)
				if rChar then
					label = rChar:getNiceName()
				end
			end
            return label
        end,
		buttonStatusFn = function(self)
			local rRoom = self.rZoneActionTab.rZoneInspector.rRoom
			local bValidAirlock = rRoom.zoneObj and rRoom.zoneObj:isFunctionalAirlock()
			local bPlayerControlled = rRoom:getVisibility() == g_World.VISIBILITY_FULL and rRoom:getTeam() == Character.TEAM_ID_PLAYER
			if self.bClicked then
				return 'selected'
			elseif not bPlayerControlled then
				return 'disabled'
			end
			return 'normal'
		end,
    }
	
	local tUnassignmentButtonData={
		sLayoutFile = 'UILayouts/CancelButtonLayout',
		sButtonName = 'CancelButton',
		buttonStatusFn=function(btn)
			-- only enable when slot is assigned
			local rChar = btn.rZoneActionTab:_btnToChar(btn)
			if rChar then
				return 'normal'
			end
			return 'disabled'
		end,
	}

    function Ob:_btnToChar(btn)
        local rRoom = self.rZoneInspector.rRoom
        local zoneObj = rRoom and rRoom.zoneObj
        if zoneObj and zoneObj.getAssignmentSlots then
            local tSlots = zoneObj:getAssignmentSlots()
            local rChar = tSlots[btn.idx] and tSlots[btn.idx].char and ObjectList.getObject(tSlots[btn.idx].char)
            if rChar then return rChar end

            local rBed = tSlots[btn.idx] and tSlots[btn.idx].bed and ObjectList.getObject(tSlots[btn.idx].bed)
            if rBed then
                return rBed:getOwner()
            end
        end
    end

    function Ob:_addAssignmentButton()
        local rButton = TemplateButton.new()
        rButton.rZoneActionTab = self
		rButton.bClicked = false
        rButton:setBehaviorData(tAssignmentButtonData)
        self.rAssignmentScrollableUI:addScrollingItem(rButton)
		-- no need to setLoc, that's done in onTick loop that creates us
        rButton:addPressedCallback(self.assignCitizenToZoneButtonPressed,self)
        table.insert(self.tCitizenAssignmentButtons, rButton)
        rButton.idx = #self.tCitizenAssignmentButtons
        table.insert(self.tButtons, rButton)
        return rButton
    end
	
	function Ob:_addUnassignmentButton()
		local rButton = TemplateButton.new()
        rButton.rZoneActionTab = self
        rButton:setBehaviorData(tUnassignmentButtonData)
        self.rAssignmentScrollableUI:addScrollingItem(rButton)
        rButton:addPressedCallback(self.unAssignCitizenToZoneButtonPressed,self)
        table.insert(self.tCitizenUnassignmentButtons, rButton)
        rButton.idx = #self.tCitizenUnassignmentButtons
        table.insert(self.tButtons, rButton)
        return rButton
	end
	
	function Ob:assignCitizenToZoneButtonPressed(rButton)
		if rButton.bClicked then
			-- begin changes for mod HighlightUnassignedBedsAndCitizens (2/4)
            self:cancelPickMode()
		else
			GameRules.setUIMode(GameRules.MODE_PICK, {
                target='Character',
                buttonIndex=rButton.idx,
                highlightTime=0,
                onTick=function(dt, params) self:citizenSelectOnTick(dt, params) end,
                cb=function(rCitizen) self:citizenSelected(rCitizen,rButton.idx) end
            })
			rButton.bClicked = true
		end
    end
	
	function Ob:citizenSelectOnTick(dt, params)
        params.highlightTime = params.highlightTime + dt
        self:highlightUnassignedCitizens(true, params.highlightTime)
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
    -- end changes for mod HighlightUnassignedBedsAndCitizens (2/4)
	
	function Ob:unAssignCitizenToZoneButtonPressed(rButton)
        local rRoom = self.rZoneInspector.rRoom
        local zoneObj = rRoom and rRoom.zoneObj
		if zoneObj and zoneObj.assignChar then
            zoneObj:assignChar(rButton.idx, nil)
		end
	end
	
    function Ob:citizenSelected(rCitizen,index)
	    -- begin changes for mod HighlightUnassignedBedsAndCitizens (3/4)
        self:cancelPickMode()
        -- end changes for mod HighlightUnassignedBedsAndCitizens (3/4)
        local rRoom = self.rZoneInspector.rRoom
        local zoneObj = rRoom and rRoom.zoneObj
        if zoneObj and zoneObj.assignChar then
            zoneObj:assignChar(index,rCitizen)
        end

    end

    -- begin changes for mod HighlightUnassignedBedsAndCitizens (4/4)
    function Ob:hide(bKeepAlive)
        self:cancelPickMode()
        Ob.Parent.hide(self, bKeepAlive)
    end

    function Ob:cancelPickMode()
        if GameRules.currentMode == GameRules.MODE_PICK then
            self.tCitizenAssignmentButtons[GameRules.currentModeParam.buttonIndex].bClicked = false
            self:highlightUnassignedCitizens(false)
            GameRules.setUIMode(GameRules.MODE_INSPECT)
        end
    end
    -- end changes for mod HighlightUnassignedBedsAndCitizens (4/4)
	
	function Ob:sealButtonPressed()
		self.rZoneInspector.rRoom:toggleLockdown()
	end
	
	function Ob:claimButtonPressed()
		local rRoom = self.rZoneInspector.rRoom
		if rRoom and rRoom:getVisibility() == g_World.VISIBILITY_FULL then
			if rRoom:getTeam() ~= Character.TEAM_ID_PLAYER then
				rRoom:claim()
                SoundManager.playSfx('claim')
			else
				rRoom:unclaim()
                SoundManager.playSfx('unclaim')
			end
		end
	end
	
	function Ob:setRoom(rRoom)
		for _,rButton in pairs(self.tButtons) do
			rButton.rSelected = rRoom
		end
	end
	
    function Ob:onTick(dt)
		local rRoom = self.rZoneInspector.rRoom
        local zoneObj = rRoom and rRoom.zoneObj
		-- track how many assignment buttons are used so we know which to hide
		local nAssignButtonIndex = 0
        if zoneObj and zoneObj.getAssignmentSlots then
			self.rCustomControlsLabel:setVisible(true)
			if rRoom:getZoneName() == 'BRIG' then
				self.rCustomControlsLabel:setString(g_LM.line('PROPSX099TEXT'))
			else
				self.rCustomControlsLabel:setString(g_LM.line('PROPSX098TEXT'))
			end
            local tSlots = zoneObj:getAssignmentSlots()
			local x,y = 0,0
			local nButtonMargin = 8
            for i,tSlot in ipairs(tSlots) do
				nAssignButtonIndex = i
                local rButton = self.tCitizenAssignmentButtons[i] or self:_addAssignmentButton()
				rButton:setLoc(x,y)
				local w,h = rButton:getDims()
				if not rButton:isVisible() then
					self:setElementHidden(rButton,false)
				end
				-- [X] unassign button
				local rCancelButton = self.tCitizenUnassignmentButtons[i] or self:_addUnassignmentButton()
				rCancelButton:setLoc(x + 160 + 52, y - 3)
				if not rCancelButton:isVisible() then
					self:setElementHidden(rCancelButton,false)
				end
				-- advance Y
				y = y + h - nButtonMargin
            end
        else
			self.rCustomControlsLabel:setVisible(false)
		end
		-- hide any assign button that isn't for a visible slot
		for i=nAssignButtonIndex+1,#self.tCitizenAssignmentButtons do
			self:setElementHidden(self.tCitizenAssignmentButtons[i], true)
			self:setElementHidden(self.tCitizenUnassignmentButtons[i], true)
		end
		-- individual buttons tick their status as defined in behavior data
        for _,rButton in pairs(self.tButtons) do
			rButton:onTick(dt)
		end
        self.rAssignmentScrollableUI:refresh()
    end
	
--[[	
    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        for i, rButton in ipairs(self.tButtons) do
            bHandled = rButton:onFinger(touch, x, y, props)
        end
        return bHandled
    end
]]--
	
    function Ob:inside(wx, wy)
        local bInside = Ob.Parent.inside(self, wx, wy)
        for i, rButton in ipairs(self.tButtons) do
            bInside = rButton:inside(wx, wy) or bInside
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
