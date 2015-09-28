local m = {}

local DFUtil = require("DFCommon.Util")
local Character = require('Character')
local UIElement = require('UI.UIElement')
local Base = require('Base')
local Room = require('Room')
local Brig = require('Zones.BrigZone')
local GameRules = require('GameRules')
local ObjectList = require('ObjectList')
local TemplateButton = require('UI.TemplateButton')
local BedAssignment=require('UI.BedAssignment')
-- begin changes for mod HighlightUnassignedBedsAndCitizens (1/4)
local EnvObject = require('EnvObjects.EnvObject')
-- end changes for mod HighlightUnassignedBedsAndCitizens (1/4)

local sUILayoutFileName = 'UILayouts/CitizenActionTabLayout'

local nButtonRight = 160

local tActionButtonData=
{
	-- assign residence
	{
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sLabelElement = 'ActionLabel',
		buttonStatusFn=function(self)
			if self.rSelected:isDead() or not self.rSelected:isPlayersTeam() then
				return 'disabled'
			elseif GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.objSubtype == 'Bed' then
				return 'selected'
			end
			return 'normal'
		end,
		labelFn=function(self)
			local tBedTag = self.rSelected and Base.tCharToBed[self.rSelected.tag]
			local rBed = tBedTag and ObjectList.getObject(tBedTag)
            local sBed = rBed and rBed:getResidenceString()
			-- "click to assign"
			if GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.objSubtype == 'Bed' then
				return g_LM.line('ZONEUI150TEXT')
			-- unassigned
			elseif not sBed then
				return g_LM.line('INSPEC160TEXT')
			else
				return sBed
			end
		end,
		callbackFn=function(self)
		    -- click while selected = bail out of pick mode
			if GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.objSubtype == 'Bed' then
                -- begin changes for mod HighlightUnassignedBedsAndCitizens (2/4)
				self:cancelPickMode()
			else
				local tParam = {
					target='EnvObject',
					objSubtype='Bed',
                    highlightTime=0,
                    onTick=function(dt, params) self:bedSelectOnTick(dt, params) end,
					cb=function(rBed) self:bedSelected(rBed) end,
				}
				-- end changes for mod HighlightUnassignedBedsAndCitizens (2/4)
				GameRules.setUIMode(GameRules.MODE_PICK, tParam)
			end
		end,
		nXOverride = nButtonRight,
		-- weird property to keep *next* element on same Y as this one
		bNextUsesSameY = true,
	},
	-- unassign residence
	{
		sLayoutFile = 'UILayouts/CancelButtonLayout',
		sButtonName = 'CancelButton',
		buttonStatusFn=function(self)
			-- only enable when a residence is assigned
			local tBedTag = self.rSelected and Base.tCharToBed[self.rSelected.tag]
			if tBedTag then
				return 'normal'
			else
				return 'disabled'
			end
		end,
		callbackFn=function(self)
			Base.assignBed(self.rSelected, nil)
		end,
		-- button width = 160
		nXOverride = nButtonRight + 160 + 56,
		nExtraYOffset = 3,
	},
	-- go to quarantine
    {
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sLabelElement = 'ActionLabel',
        buttonStatusFn=function(self)
			if self.rSelected:isDead() or not self.rSelected:isPlayersTeam() then
				return 'disabled'
            elseif self.rSelected:retrieveMemory(Character.MEMORY_SENT_TO_HOSPITAL) then
                return 'selected'
            end
            return 'normal'
        end,
		labelFn=function(self)
			if self.rSelected:retrieveMemory(Character.MEMORY_SENT_TO_HOSPITAL) then
				return g_LM.line('INSPEC148TEXT')
			else
				return g_LM.line('INSPEC147TEXT')
			end
		end,
        callbackFn=function(self)
            local rChar = self.rSelected
            if rChar:retrieveMemory(Character.MEMORY_SENT_TO_HOSPITAL) then
                rChar:clearMemory(Character.MEMORY_SENT_TO_HOSPITAL)
            else
                rChar:storeMemory(Character.MEMORY_SENT_TO_HOSPITAL,true,9999999)
                rChar:reevaluateTask()
            end
        end,
		nExtraYOffset = 90,
    },
	-- cuff
	{
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sLabelElement = 'ActionLabel',
		buttonStatusFn=function(self)
            if self.rSelected:isCuffed() then return 'normal' end
            if self.rSelected:isMarkedForCuff() then
                return 'selected'
            end
            if not self.rSelected:canMarkForCuff() then return 'disabled' end
            return 'normal'
		end,
		labelFn=function(self)
            if self.rSelected:isMarkedForCuff() then
				return g_LM.line('INSPEC194TEXT')
			else
				return g_LM.line('INSPEC193TEXT')
			end
		end,
		callbackFn=function(self)
            self.rSelected:setMarkedForCuff(not self.rSelected:isCuffed() and not self.rSelected:isMarkedForCuff())
		end,
        bCuffButton=true,
	},
	-- execute
	{
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sLabelElement = 'ActionLabel',
		buttonStatusFn=function(self)
			if Base.isFriendlyToPlayer(self.rSelected) then
				if self.rSelected.tStatus.bMarkedForExecution then
					return 'selected'
				else
					return 'normal'
				end
			else
				return 'disabled'
			end
		end,
		labelFn=function(self)
			if self.rSelected.tStatus.bMarkedForExecution then
				return g_LM.line('INSPEC198TEXT')
			else
				return g_LM.line('INSPEC195TEXT')
			end
		end,
		callbackFn=function(self)
			self.rSelected.tStatus.bMarkedForExecution = not self.rSelected.tStatus.bMarkedForExecution
		end,
	},
	-- assign brig
	{
		sLayoutFile = 'UILayouts/ActionButtonLayout',
		sLabelElement = 'ActionLabel',
		buttonStatusFn=function(self)
			-- can't embriggen parasites or killbots :[
			if self.rSelected.tStats.nRace == Character.RACE_MONSTER or self.rSelected.tStats.nRace == Character.RACE_KILLBOT or self.rSelected:isDead() then
				return 'disabled'
			elseif GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.objSubtype == 'BRIG' then
				return 'selected'
			end
			return 'normal'
		end,
		labelFn=function(self)
			local rBrigRoom = self.rSelected and Brig.getBrigRoomForChar(self.rSelected)
			local sRoom = rBrigRoom and rBrigRoom:getUniqueName()
            if GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.objSubtype == 'BRIG' then
				return g_LM.line('ZONEUI151CITZ')
			elseif not sRoom then
				return g_LM.line('INSPEC160TEXT')
			else
				return sRoom
			end
		end,
		callbackFn=function(self)
            if GameRules.currentMode == GameRules.MODE_PICK and GameRules.currentModeParam.objSubtype == 'BRIG' then
				GameRules.setUIMode(GameRules.MODE_INSPECT)
			else
				local tParam = {
					target='Room',
					objSubtype='BRIG',
					cb=function(rBrig) self:brigSelected(rBrig) end,
				}
				GameRules.setUIMode(GameRules.MODE_PICK, tParam)
			end
		end,
		nXOverride = nButtonRight,
		bNextUsesSameY = true,
	},
	-- unassign brig
	{
		sLayoutFile = 'UILayouts/CancelButtonLayout',
		sButtonName = 'CancelButton',
		buttonStatusFn=function(self)
			-- only enabled when assigned to brig
			if self.rSelected.tStatus.tAssignedToBrig then
				return 'normal'
			else
				return 'disabled'
			end
		end,
		callbackFn=function(self)
			local rBrig = ObjectList.getObject(self.rSelected.tStatus.tAssignedToBrig)
            if rBrig and rBrig.zoneObj then
			    rBrig.zoneObj:unassignChar(self.rSelected)
            end
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

        local x=110
        local y=-40
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
            rButton.bCuffButton = tButtonData.bCuffButton
            rButton:setLoc(tButtonData.nXOverride or x, y)
			-- weird property to keep *next* element on same Y as this one
			if not tButtonData.bNextUsesSameY then
				y = y + h - nButtonMargin
			end
            table.insert(self.tButtons, rButton)
        end
--		self.bBedButtonClicked = false
		self.bBrigButtonClicked = false
    end
    
	function Ob:setCitizen(rCitizen)
        self.rSelected = rCitizen
        for _,rButton in pairs(self.tButtons) do
			rButton.rSelected = rCitizen
		end
	end

    function Ob:bedSelected(rBed)
        -- begin changes for mod HighlightUnassignedBedsAndCitizens (3/4)
        self:cancelPickMode()
        -- end changes for mod HighlightUnassignedBedsAndCitizens (3/4)
        local rCitizen = self.rSelected
        if rCitizen then
            Base.assignBed(rCitizen,rBed)
        end
    end

    -- begin changes for mod HighlightUnassignedBedsAndCitizens (4/4)
    function Ob:bedSelectOnTick(dt, params)
        params.highlightTime = params.highlightTime + dt
        self:highlightUnassignedBeds(true, params.highlightTime)
    end

    function Ob:highlightUnassignedBeds(bHighlight, highlightTime)
        local alpha
        if bHighlight then
            alpha = math.abs(math.sin(highlightTime * 4)) / 2 + 0.5
        end
        local tBeds,_ = EnvObject.getObjectsOfType('Bed', true)
        for _,rBed in pairs(tBeds) do
            local rChar = rBed:getOwner()
            if not rChar and rBed:getRoom():getZoneName() == 'RESIDENCE' then
                if bHighlight then
                    rBed:setColor(g_GuiManager.GREEN[1],g_GuiManager.GREEN[2],g_GuiManager.GREEN[3],alpha)
                else
                    rBed:unHover()
                end
            elseif rChar then
                local otherBed = Base.tCharToBed[ObjectList.getTag(rChar)] and ObjectList.getObject(Base.tCharToBed[ObjectList.getTag(rChar)])
                if rBed ~= otherBed then
                    local buggyName = (otherBed and 'different bed '..otherBed:getResidenceString()) or 'no bed'
                    Print(TT_Warning, 'Bed '..rBed:getResidenceString()..' assigned to Character '..rChar.tStats.sName..' with '..buggyName)
                    Base.assignBed(nil, rBed)
                    if otherBed then
                        Base.assignBed(nil, otherBed)
                    end
                end
            end
        end
    end

    function Ob:hide(bKeepAlive)
        self:cancelPickMode()
        Ob.Parent.hide(self, bKeepAlive)
    end

    function Ob:cancelPickMode()
        if GameRules.currentMode == GameRules.MODE_PICK then
            self:highlightUnassignedBeds(false)
            GameRules.setUIMode(GameRules.MODE_INSPECT)
        end
    end
    -- end changes for mod HighlightUnassignedBedsAndCitizens (4/4)

    function Ob:brigSelected(rBrig)
        local rCitizen = self.rSelected
        if rCitizen then
            local rExisting = Brig.getBrigRoomForChar(rCitizen)
            if rExisting and rExisting ~= rBrig then
				rExisting.zoneObj:unassignChar(rCitizen)
			end
            if rBrig then
				rBrig.zoneObj:assignChar(nil, rCitizen)
			end
        end
    end
    
    function Ob:onTick(dt)
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
