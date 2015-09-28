local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CitizenDutyTab = require('UI.CitizenDutyTab')
local CitizenStatsTab = require('UI.CitizenStatsTab')
local CitizenPsychTab = require('UI.CitizenPsychTab')
local CitizenLogTab = require('UI.CitizenLogTab')
local CitizenActionTab = require('UI.CitizenActionTab')
local TemplateButton = require('UI.TemplateButton')
local Character = require('CharacterConstants')
local OptionData = require('Utility.OptionData')
local MiscUtil = require('MiscUtil')
local GameScreen = require('GameScreen')
local Room = require('Room')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/CitizenInspectorLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.bHostileMode = false
    Ob.bDoRolloverCheck = true

    function Ob:init()
        Ob.Parent.init(self)

        self:processUIInfo(sUILayoutFileName)

        self.rCitizenDutyTab = CitizenDutyTab.new()
        self.rCitizenStatsTab = CitizenStatsTab.new()
        self.rCitizenPsychTab = CitizenPsychTab.new()
        self.rCitizenLogTab = CitizenLogTab.new()
        self.rCitizenActionTab = CitizenActionTab.new()
        self.rCitizenActionTab.rCitizenInspector=self

        self.rTabbedPane = self:getTemplateElement('TabbedPane')
        local tIcons={'ui_icon_duty','ui_icon_stats','ui_icon_psych','ui_icon_spaceface','ui_icon_duty'}
        local tButtons = {}
        for i,v in ipairs(tIcons) do
            tButtons[i] = TemplateButton.new()
            tButtons[i]:setReplacements('Icon',{textureName=v})
            tButtons[i]:setLayoutFile('UILayouts/IconTabLayout')
            tButtons[i]:setButtonName('TabButton')
        end
        self.rTabbedPane:addTab(self.rCitizenDutyTab, 'CitizenDutyTab', true, tButtons[1])
        self.rTabbedPane:addTab(self.rCitizenStatsTab, 'CitizenStatsTab', true, tButtons[2])
        self.rTabbedPane:addTab(self.rCitizenPsychTab, 'CitizenPsychTab', true, tButtons[3])
        self.rTabbedPane:addTab(self.rCitizenLogTab, 'CitizenLogTab', true, tButtons[4])
        self.rTabbedPane:addTab(self.rCitizenActionTab, 'CitizenActionTab', true, tButtons[5])

        -- "shortcut" buttons for stats tab, morale tab, room
        self.rHealthButton = self:getTemplateElement('HealthStatButton')
        self.rHealthButton:addPressedCallback(self.onHealthButtonPressed, self)
        self.rMoraleButton = self:getTemplateElement('MoraleButton')
        self.rMoraleButton:addPressedCallback(self.onMoraleButtonPressed, self)
        self.rRoomButton = self:getTemplateElement('RoomButton')
        self.rRoomButton:addPressedCallback(self.onRoomButtonPressed, self)
        self.rActivityButton = self:getTemplateElement('ActivityButton')
        self.rActivityButton:addPressedCallback(self.onActivityButtonPressed, self)

        self.rNameText = self:getTemplateElement('NameLabel')
        self.rNameEditBG = self:getTemplateElement('NameEditBG')
        self.rTitleLabel = self:getTemplateElement('TitleLabel')
        self.rHealthText = self:getTemplateElement('HealthText')
        self.rLocationText = self:getTemplateElement('LocationText')
        self.rActivityText = self:getTemplateElement('ActivityText')
        self.rMoraleIcon = self:getTemplateElement('MoraleIcon')
        self.rMoraleLabel = self:getTemplateElement('MoraleLabel')
        self.rMoraleText = self:getTemplateElement('MoraleText')
        self.rDeathIcon = self:getTemplateElement('DeathIcon')
        self.rDeathLabel = self:getTemplateElement('DeathLabel')
        self.rDeathText = self:getTemplateElement('DeathText')
        self.rNameEditButton = self:getTemplateElement('NameEditButton')
        self.rCamCenterButton = self:getTemplateElement('CamCenterButton')
		
		-- stretch box + line to fill space where tabs could be
		self.rTabSpacer = self:getTemplateElement('TabBGSpacer')
		self.rTabLineSpacer = self:getTemplateElement('TabLineSpacer')
		-- read vars from layout to avoid data duplication
		self.nTabWidth = self:getExtraTemplateInfo('nTabWidth')
		self.nTabHeight = self:getExtraTemplateInfo('nTabHeight')
		self.nTabLineHeight = self:getExtraTemplateInfo('nTabLineHeight')
		
        self.rNameEditButton:addPressedCallback(self.onNameEditButtonPressed, self)
        self.rCamCenterButton:addPressedCallback(self.onCamCenterButtonPressed, self)
    end
	
	function Ob:getNumberOfTabs()
		if not self.rCitizen then
			return 0
		elseif self.rCitizen:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen then
			return 5
		else
			return 2
		end
	end
	
	function Ob:adjustSpacer()
		local nTabs = self:getNumberOfTabs()
		-- shaded background
		self.rTabSpacer:setLoc(self.nTabWidth * nTabs, -420)
		self.rTabSpacer:setScl(self.nTabWidth * (5 - nTabs) + 3, self.nTabHeight)
		-- line that completes tab row
		self.rTabLineSpacer:setLoc(self.nTabWidth * nTabs, -420 - self.nTabHeight)
		self.rTabLineSpacer:setScl(self.nTabWidth * (5 - nTabs) + 3, self.nTabLineHeight)
	end
	
    function Ob:onTick(dt)
        if not self.rCitizen then
			self.rTabbedPane:onTick()
		end
		if self.rNameText and not GameScreen.inTextEntry() then
			self.rNameText:setString(self.rCitizen:getNiceName())                
		end
		if self.rCitizen.tStats.sPortrait then
			self:setTemplateUITexture('Picture', self.rCitizen.tStats.sPortrait, self.rCitizen.tStats.sPortraitPath)
		end
		if self.rCitizen.tStats.sPortraitFacialHair then
			self:setTemplateUITexture('PictureFacialHair', self.rCitizen.tStats.sPortraitFacialHair, self.rCitizen.tStats.sPortraitPath)
		else
			self:setTemplateUITexture('PictureFacialHair', 'NoHair', self.rCitizen.tStats.sPortraitPath)
		end
		if self.rCitizen.tStats.sPortraitHair then
			self:setTemplateUITexture('PictureHair', self.rCitizen.tStats.sPortraitHair, self.rCitizen.tStats.sPortraitPath)
		else
			self:setTemplateUITexture('PictureHair', 'NoHair', self.rCitizen.tStats.sPortraitPath)
		end
		if self.rTitleLabel then
			local str = g_LM.line(Character.JOB_NAMES[self.rCitizen:getJob()])
			if self.rCitizen:onDuty() then
				str = str.." "..g_LM.line('DUTIES015TEXT') -- (On Duty)
			end
			self.rTitleLabel:setString(str)
		end
		if self.rHealthText then
			local s = self.rCitizen:getHealthText(true)
			self.rHealthText:setString(s)
		end
		if self.rLocationText then
			local rRoom = self.rCitizen:getRoom()
			local sString = ""
			if rRoom and rRoom ~= Room.getSpaceRoom() then
				if rRoom.uniqueZoneName then
					sString = rRoom.uniqueZoneName
				end
			else
				-- must be in space
				sString = g_LM.line("ZONEUI067TEXT")
			end
			self.rLocationText:setString(sString)
		end
		if self.rActivityText then
			self.rActivityText:setString(self.rCitizen:getActivityText())
		end
		-- if dead, show cause of death instead of morale
		if self.rMoraleText and self.rCitizen:getHealth() ~= Character.STATUS_DEAD then
			self.rMoraleText:setString(self.rCitizen:getMoraleText())
			-- hide death and show morale icon/label/text
			self.rMoraleIcon:setVisible(true)
			self.rMoraleLabel:setVisible(true)
			self.rMoraleText:setVisible(true)
			self.rDeathIcon:setVisible(false)
			self.rDeathLabel:setVisible(false)
			self.rDeathText:setVisible(false)
		elseif self.rDeathText then
			local s = g_LM.line(Character.tDeathCauses[self.rCitizen.tStatus.nDeathCause])
			self.rDeathText:setString(s)
			-- hide morale and show death icon/label/text
			self.rDeathIcon:setVisible(true)
			self.rDeathLabel:setVisible(true)
			self.rDeathText:setVisible(true)
			self.rMoraleIcon:setVisible(false)
			self.rMoraleLabel:setVisible(false)
			self.rMoraleText:setVisible(false)
		end
		self.rTabbedPane:onTick()
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        --[[
        if self.rTabbedPane:onFinger(touch, x, y, props) then
            bHandled = true
        end
        ]]--
        return bHandled
    end

    function Ob:inside(wx, wy)
        local bHandled = false
        if Ob.Parent.inside(self, wx, wy) then
            bHandled = true
        end
        bHandled = self.rTabbedPane:inside(wx, wy) or bHandled
        return bHandled
    end

    function Ob:show(nPri)
        if self.rCitizen then
            g_GameRules.setCamTrackEnabled(true)
        end
        local nPri = Ob.Parent.show(self, nPri)
        return nPri
    end

    function Ob:setCitizen(rCitizen)
        if rCitizen ~= self.rCitizen then
            if rCitizen then
                g_GameRules.setCamTrackEnabled(true)
            end
            if rCitizen then
                if rCitizen:getFactionBehavior() == Character.FACTION_BEHAVIOR.Citizen then
                    self:setHostileMode(false)
                else
                    self:setHostileMode(true)
                end
                
					-- smart defaults if char inspector wasn't open before
					if self.rCitizen == nil then
						-- unassigned citizen = duty tab, else command tab
						if rCitizen.tStats.nJob == Character.UNEMPLOYED then
							self.rTabbedPane:setTabSelectedByKey('CitizenDutyTab')
						else
							self.rTabbedPane:setTabSelectedByKey('CitizenActionTab')
						end
					end
            end
            if GameScreen.inTextEntry() then
                GameScreen.endTextEntry()
            end
        end
        self.rCitizen = rCitizen
        self.rCitizenDutyTab:setCitizen(rCitizen)
        self.rCitizenStatsTab:setCitizen(rCitizen)
        self.rCitizenPsychTab:setCitizen(rCitizen)
        self.rCitizenLogTab:setCitizen(rCitizen)
        self.rCitizenActionTab:setCitizen(rCitizen)
		self:adjustSpacer()
    end

    function Ob:setHostileMode(bSet)
        local updateTabVis = bSet ~= self.bHostileMode
        self.bHostileMode = bSet
        if bSet then
            local tOverrides = self:getExtraTemplateInfo('tHostileMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
        else
            local tOverrides = self:getExtraTemplateInfo('tCitizenMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
        end
        self.rCitizenDutyTab:setHostileMode(bSet)
        self.rCitizenStatsTab:setHostileMode(bSet)
        self.rCitizenPsychTab:setHostileMode(bSet)
        self.rCitizenLogTab:setHostileMode(bSet)
        if bSet then
            if updateTabVis then
                self.rTabbedPane:hideTab('CitizenDutyTab')
                self.rTabbedPane:hideTab('CitizenPsychTab')
            end
--            self.rTabbedPane:setTabSelectedByKey('CitizenStatsTab') -- default to stats
        else
            if updateTabVis then
                self.rTabbedPane:revealTab('CitizenDutyTab')
                self.rTabbedPane:revealTab('CitizenPsychTab')
                self.rTabbedPane:revealTab('CitizenActionTab')
            end
        end
        self.rTabbedPane:setTabSelected(self.rTabbedPane:getSelectedTabIndex()) 
    end

    function Ob:onNameEditButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP and not GameScreen.inTextEntry() and not self.bHostileMode then
            GameScreen.beginTextEntry(self.rNameText, self, self.confirmTextEntry, self.cancelTextEntry)
			self.rNameEditButton:setSelected(true)
        end
    end
    
    function Ob:onCamCenterButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rCitizen then
                g_GameRules.setCamTrackEnabled(true)
            end
        end
    end
    
    function Ob:onHealthButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rCitizen then
                -- stats tab
                self.rTabbedPane:setTabSelected(2)
            end
        end
    end
    
    function Ob:onMoraleButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rCitizen then
                -- psych profile tab
                self.rTabbedPane:setTabSelected(3)
            end
        end
    end
    
    function Ob:onRoomButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rCitizen then
                -- select current room
                local rRoom = self.rCitizen:getRoom()
                -- if we're in space, center on citizen
                if rRoom == Room.getSpaceRoom() then
                    g_GameRules.setCamTrackEnabled(true)
                elseif rRoom then
                    g_GuiManager.setSelected(rRoom)
                    local wx,wy = g_World._getWorldFromTile(rRoom:getCenterTile())
                    g_GameRules._centerCameraOnPoint(wx, wy)
                end
            end
        end
    end
    
    function Ob:onActivityButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if self.rCitizen then
                -- command tab
				self.rTabbedPane:setTabSelectedByKey('CitizenActionTab')
            end
        end
    end
    
    function Ob:confirmTextEntry(text)
        if self.rCitizen and self.rCitizen.tStats then
            if text then
                local sTrimmedText = text:gsub("^%s*(.-)%s*$", "%1")
                if sTrimmedText ~= "" then
                    self.rCitizen:setName(sTrimmedText)
                    self.rNameEditButton:setSelected(false)
                end
            end
        end
    end
	
	function Ob:cancelTextEntry(text)
		self.rNameEditButton:setSelected(false)
	end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
