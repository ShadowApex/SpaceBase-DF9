local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local ResearchProjectEntry = require('UI.ResearchProjectEntry')
local ResearchZoneEntry = require('UI.ResearchZoneEntry')
local Base = require('Base')
local Malady = require('Malady')
local ResearchData = require('ResearchData')
local Room = require('Room')
local Character = require('CharacterConstants')
local EnvObject = require('EnvObjects.EnvObject')

local sUILayoutFileName = 'UILayouts/ResearchAssignmentLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)
        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
		self.tResearchZoneEntries = {}
        self.rZoneScrollableUI = self:getTemplateElement('ZoneScrollPane')
		self.rZoneScrollableUI:setRenderLayer('UIScrollLayerLeft')
        self.rProjectScrollableUI = self:getTemplateElement('ProjectScrollPane')
		self.rProjectScrollableUI:setRenderLayer('UIScrollLayerRight')
        
        self.rZoneScrollableUI:setScissorLayer('UIScrollLayerLeft')
        self.rProjectScrollableUI:setScissorLayer('UIScrollLayerRight')

        self.rTechTabButton = self:getTemplateElement('TechTabButton')
        self.rDiseaseTabButton = self:getTemplateElement('DiseaseTabButton')
        self.rTechTabButton:addPressedCallback(function() self:setTechMode(true) end)
        self.rDiseaseTabButton:addPressedCallback(function() self:setTechMode(false) end)
        
		self.rProjectSelectPrompt = self:getTemplateElement('ProjectSelectPromptLabel')
		self.rSelectedZoneEntry = nil
        self:setTechMode(true)
    end
    
    function Ob:setTechMode(bTech)
        self.bResearchMaladies = not bTech
        local tOverrides
        self.rTechTabButton:setSelected(bTech)
        self.rDiseaseTabButton:setSelected(not bTech)
        if self.bResearchMaladies then
            tOverrides = self:getExtraTemplateInfo('tDiseaseMode')
        else
            tOverrides = self:getExtraTemplateInfo('tTechMode')
        end
        self:applyTemplateInfos(tOverrides)
    end
	
    function Ob:addHotkey(sKey, rButton)
        sKey = string.lower(sKey)
        local keyCode = -1
        if sKey == "esc" then
            keyCode = 27
        elseif sKey == "ret" or sKey == "ent" then
            keyCode = 13
        elseif sKey == "spc" then
            keyCode = 32
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
                -- you pressed the button
                bHandled = true
                rButton:keyboardPressed()
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
                g_GuiManager.newSideBar:closeSubmenu()
				--Ob:grabZones()
                SoundManager.playSfx('degauss')
            end
        end
    end
    
    function Ob:show(basePri)
		Ob:grabZones()
        if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
        local w,h = g_GuiManager.getUIViewportSizeX(), g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)
        local nPri = Ob.Parent.show(self, basePri)
        self.rProjectScrollableUI:reset()
        self.rZoneScrollableUI:reset()
        
		-- hide status bar behind us
		g_GuiManager.statusBar:hide()
		g_GuiManager.tutorialText:hide()
		g_GuiManager.hintPane:hide()
		g_GuiManager.alertPane:hide()
        return nPri
    end
	
    function Ob:hide(bKeepAlive)
        if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end
        Ob.Parent.hide(self, bKeepAlive)
        self.rProjectScrollableUI:hide()
        for i, rEntry in ipairs(self.tResearchZoneEntries) do
            rEntry:hide(bKeepAlive)
        end
		-- show status bar etc
		g_GuiManager.statusBar:show()
		g_GuiManager.tutorialText:show()
		g_GuiManager.hintPane:show()
		g_GuiManager.alertPane:show()
		g_GuiManager.hintPane:setMaximized(true)
		g_GuiManager.alertPane:setMaximized(true)
    end
	
    function Ob:onTick(dt)
		local tResearchProjects = self:getAllResearchItems()
		local nTotalItems = #tResearchProjects
		local nCurrentItems = #self.rProjectScrollableUI.tItems
		-- if list of research items changes, rebuild the list
        
		if nTotalItems > nCurrentItems then
            for i=nCurrentItems+1,nTotalItems do
				self:addProjectEntry(i)
			end
		elseif nTotalItems < nCurrentItems then
            for i=nCurrentItems,nTotalItems,-1 do
                self:removeProjectEntry(i)
			end
		end
        local bInSelectionMode = self.rSelectedZoneEntry ~= nil
		-- set Y here instead of in addProjectEntry for hot reload friendliness
		for i,rEntry in ipairs(self.rProjectScrollableUI.tItems) do
			local w,h = rEntry:getDims()
			local nMargin = 32
			local nYLoc = (h - nMargin) * (i - 1)
			rEntry:setLoc(0, nYLoc)
			rEntry:setProject(tResearchProjects[i])
            local bEnabled = bInSelectionMode and tResearchProjects[i].bCanResearch
            rEntry.rButton:setEnabled(bEnabled)
            local bSelected = bEnabled and self.rSelectedZoneEntry and self.rSelectedZoneEntry.rButton == rEntry
            rEntry.rButton:setSelected(bSelected)
        end
        self.rProjectScrollableUI:refresh()
		-- do similar for zone list
		local tResearchZones = self:getAllZoneItems()
		nTotalItems = #tResearchZones
		nCurrentItems = table.getn(self.tResearchZoneEntries)
		if nTotalItems > nCurrentItems then
			for i,tProject in ipairs(tResearchZones) do
				self:addZoneEntry(i)
			end
		end
		for i,rEntry in pairs(self.tResearchZoneEntries) do
			local w,h = rEntry:getDims()
            local nMargin = 48
			local nYLoc = (h - nMargin) * (i - 1) - 80
			rEntry:setLoc(0, nYLoc)
            if tResearchZones[i] then
                self:setElementHidden(rEntry,false)
                rEntry:show()
                rEntry:setZone(tResearchZones[i])
            else
                self:setElementHidden(rEntry,true)
            end
		end
        self.rZoneScrollableUI:refresh()
    end
	
	function Ob:grabZones()
		-- do similar for zone list
		local tResearchZones = self:getAllZoneItems()
		nTotalItems = #tResearchZones
		nCurrentItems = table.getn(self.tResearchZoneEntries)
		if nTotalItems > nCurrentItems then
			for i,tProject in ipairs(tResearchZones) do
				self:addZoneEntry(i)
			end
		end
		for i,rEntry in pairs(self.tResearchZoneEntries) do
			local w,h = rEntry:getDims()
            local nMargin = 48
			local nYLoc = (h - nMargin) * (i - 1) - 80
			rEntry:setLoc(0, nYLoc)
            if tResearchZones[i] then
                self:setElementHidden(rEntry,false)
                rEntry:show()
                rEntry:setZone(tResearchZones[i])
            else
                self:setElementHidden(rEntry,true)
            end
		end
		print("test4")
        self.rZoneScrollableUI:refresh()
	end
	
	function Ob:getAllResearchItems()
		-- compile all discovered research projects into a single, sorted list
		local tAvailableResearch
        local tCompletedResearch
        if self.bResearchMaladies then
            tAvailableResearch = Malady.getAvailableResearch()
            tCompletedResearch = Malady.getCompletedResearch()
        else
            tAvailableResearch = Base.getDiscoveredResearch()
            tCompletedResearch = Base.getCompletedResearch()
        end
        
		local tItems = {}
		for sProject,_ in pairs(tAvailableResearch) do
            local tItem = (self.bResearchMaladies and self:getMaladyItemData(sProject)) or self:getResearchItemData(sProject)
			table.insert(tItems, tItem)
		end
		-- sort by progress (in-progress at top)
		local f = function(x,y) 
            if (x.bCanResearch ~= y.bCanResearch) then
                return x.bCanResearch
            end
            return x.nProgress > y.nProgress 
        end
		table.sort(tItems, f)
		-- add completed items after (bottom of list)

        -- researched maladies don't show up in the available list so add this manually
        if self.bResearchMaladies then
            for sProject,_ in pairs(tCompletedResearch) do
                local tItem = (self.bResearchMaladies and self:getMaladyItemData(sProject)) or self:getResearchItemData(sProject)
                table.insert(tItems, tItem)
            end
        end

		return tItems
	end

	function Ob:getMaladyItemData(sMaladyName)
		-- return a table with all the info needed for UI
		local tItemData = {}
        local tResearchData = Malady.tS.tResearch[sMaladyName]
		tItemData.sID = sMaladyName
		tItemData.nProgress = (tResearchData and tResearchData.nCureProgress) or 0
		tItemData.nTotalNeeded = (tResearchData and tResearchData.nResearchCure) or 0
		tItemData.sName = Malady.getFriendlyName(sMaladyName)
        tItemData.sDesc =  g_LM.line(Malady.getDescription(sMaladyName))
		tItemData.sIcon = nil
        tItemData.bCanResearch = true
		return tItemData
    end
	
	function Ob:getResearchItemData(sProjectName)
		-- return a table with all the info needed for UI
		local tItemData = {}
		local tProjectData = ResearchData[sProjectName]
		tItemData.sID = sProjectName
		tItemData.nProgress = (Base.tS.tResearch[sProjectName] and Base.tS.tResearch[sProjectName].nResearchUnits) or 0
		tItemData.sName, tItemData.sDesc = Base.getResearchName(sProjectName)
		tItemData.sIcon = tProjectData.sIcon
		tItemData.nTotalNeeded = tProjectData.nResearchUnits
		-- get list of prereq names (save string processing for the UI code)
		tItemData.tPrereqs = {}
		for _,sPrereq in pairs(tProjectData.tPrereqs) do
			-- don't include discovery prereqs; if player sees this item
			-- they've discovered it
			if not tProjectData.bDiscoverOnly then
				local sPrereqName,_ = Base.getResearchName(sPrereq)
				table.insert(tItemData.tPrereqs, sPrereqName)
			end
		end
        tItemData.bCanResearch = Base.getAvailableResearch()[sProjectName] ~= nil
            
		return tItemData
	end
	
	function Ob:addProjectEntry(nIndex)
		local rNewEntry = ResearchProjectEntry.new()
		-- Y loc will be set onTick
        self:_calcDimsFromElements()
		self.rProjectScrollableUI:addScrollingItem(rNewEntry)
		rNewEntry.rAssignmentScreen = self
	end
	
	function Ob:removeProjectEntry(nIndex)
		self.rProjectScrollableUI:removeScrollingItem(self.rProjectScrollableUI.tItems[nIndex])
	end
	
	function Ob:getAllZoneItems()
		-- return list of research labs and their current projects
		local tLabs = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER, true, 'RESEARCH')
		local tItems = {}
		for rLab,nRoomIndex in pairs(tLabs) do
			local tItemData = {}
			tItemData.sName = rLab.uniqueZoneName
			tItemData.nZoneID = rLab.id
			tItemData.sProjectID = rLab.zoneObj.sCurrentResearch
            if tItemData.sProjectID then
                tItemData.sProjectName = Base.getResearchName(tItemData.sProjectID) or Malady.getFriendlyName(tItemData.sProjectID)
            else
                tItemData.sProjectName = nil
            end
			tItemData.bAssigned = tItemData.sProjectName ~= nil
			table.insert(tItems, tItemData)
		end
		return tItems
	end
	
	function Ob:addZoneEntry(nIndex)
		local rNewEntry = ResearchZoneEntry.new()
        self:_calcDimsFromElements()
		self.rZoneScrollableUI:addScrollingItem(rNewEntry)
		rNewEntry.rAssignmentScreen = self
        table.insert(self.tResearchZoneEntries, rNewEntry)
	end
	
    function Ob:zoneSelected(rZoneEntry)
        if self.rSelectedZoneEntry and self.rSelectedZoneEntry ~= rZoneEntry then
            self.rSelectedZoneEntry.rButton:setSelected(false)
        end
		self.rSelectedZoneEntry = rZoneEntry
        if self.rSelectedZoneEntry and not self.rSelectedZoneEntry.rButton.bSelected then
            self.rSelectedZoneEntry.rButton:setSelected(true)
        end
	end
	
	function Ob:projectSelected(rProjectEntry)
		if self.rSelectedZoneEntry then
			self.rSelectedZoneEntry:setZoneProject(rProjectEntry.tProject)
            self:zoneSelected(nil)
		end
	end
    
    -- Manual handling of onFinger for some custom behavior. Could probably kill this override if we found another
    -- way to do the zone assignment deselection.
    function Ob:onFinger(touch, x, y, props)
        if not self.elementsVisible then return false end
        local bHandled = false
        
        if self.rBackButton:onFinger(touch, x, y, props) or self.rTechTabButton:onFinger(touch,x,y,props) or self.rDiseaseTabButton:onFinger(touch,x,y,props) then
            return true
        end
        
        if self.rProjectScrollableUI:onFinger(touch, x, y, props) then
            bHandled = true
        end
        
        -- strange logic to get "clicking away from zone assignment deselects the zone"
        if not bHandled and not self.rProjectScrollableUI:inside(x, y) and touch.button == DFInput.MOUSE_LEFT and touch.eventType == DFInput.TOUCH_UP then
            self:zoneSelected(nil)
        end
        
        if not bHandled and self.rZoneScrollableUI:onFinger(touch, x, y, props) then
            bHandled = true
        end
        
        return bHandled
    end
	
    function Ob:inside(wx, wy)
        local bHandled = Ob.Parent.inside(self, wx, wy)
        self.rProjectScrollableUI:inside(wx, wy)
        for i, rEntry in ipairs(self.rProjectScrollableUI.tItems) do
            if rEntry:inside(wx, wy) then
                bHandled = true
            end
        end
        self.rZoneScrollableUI:inside(wx, wy)
        for i, rEntry in ipairs(self.tResearchZoneEntries) do
            if not rEntry.hideOverride and rEntry:inside(wx, wy) then
                bHandled = true
            end
        end
        return bHandled
    end
	
    function Ob:onResize()
        Ob.Parent.onResize(self,true)
        self.rZoneScrollableUI:onResize()
        self.rProjectScrollableUI:onResize()        
    end
	
    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)
	
    return Ob
end

return m
