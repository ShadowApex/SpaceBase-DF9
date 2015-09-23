local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local JobRosterEntry = require('UI.JobRosterEntry')
local Character = require('Character')
local CharacterManager = require('CharacterManager')

local sUILayoutFileName = 'UILayouts/JobRosterLayout'

local tJobToEnum =
{
    job1 = Character.BUILDER,
    job2 = Character.TECHNICIAN,
    job3 = Character.MINER,
    job4 = Character.EMERGENCY,
    job5 = Character.BARTENDER,
    job6 = Character.BOTANIST,
    job7 = Character.SCIENTIST,
    job8 = Character.DOCTOR,
    job9 = Character.JANITOR,
    job10 = Character.UNEMPLOYED,
}

local tSortButtonInfos =
{
    JobSortButton = {
                        sSortKey = 'jobSort',
                    },
    NameSortButton = {
                         sSortKey = 'nameSort',
                     },
    Job1SortButton = {
                         sSortKey = 'job1Sort',
                     },
    Job2SortButton = {
                         sSortKey = 'job2Sort',
                     },
    Job3SortButton = {
                         sSortKey = 'job3Sort',
                     },
    Job4SortButton = {
                         sSortKey = 'job4Sort',
                     },
    Job5SortButton = {
                         sSortKey = 'job5Sort',
                     },
    Job6SortButton = {
                         sSortKey = 'job6Sort',
                     },
    Job7SortButton = {
                         sSortKey = 'job7Sort',
                     },
    Job8SortButton = {
                         sSortKey = 'job8Sort',
                     },
    Job9SortButton = {
                         sSortKey = 'job9Sort',
                     },
	Job10SortButton = {
                         sSortKey = 'job10Sort',
                     },
}

local function jobCatSortDownFn(rCitizen1, rCitizen2)
    return rCitizen1:getJob() < rCitizen2:getJob()
end

local function jobCatSortUpFn(rCitizen1, rCitizen2)
    return rCitizen1:getJob() > rCitizen2:getJob()
end

local function nameSortDownFn(rCitizen1, rCitizen2)
    return (rCitizen1:getNiceName() < rCitizen2:getNiceName())
end

local function nameSortUpFn(rCitizen1, rCitizen2)
    return (rCitizen1:getNiceName() > rCitizen2:getNiceName())
end

local function jobSortDownFn(eJob, rCitizen1, rCitizen2)
    return (rCitizen1:getBaseJobCompetency(eJob) > rCitizen2:getBaseJobCompetency(eJob))
end

local function jobSortUpFn(eJob, rCitizen1, rCitizen2)
    return (rCitizen1:getBaseJobCompetency(eJob) < rCitizen2:getBaseJobCompetency(eJob))
end

local tSortFnInfos = 
{
    jobSort = {
                  sortDownFn = jobCatSortDownFn,
                  sortUpFn = jobCatSortUpFn,            
              },
    nameSort = {
                   sortDownFn = nameSortDownFn,
                   sortUpFn = nameSortUpFn,
               },
    job1Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job1'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job1'], rCitizen1, rCitizen2) end,
               },
    job2Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job2'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job2'], rCitizen1, rCitizen2) end,
               },
    job3Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job3'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job3'], rCitizen1, rCitizen2) end,
               },
    job4Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job4'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job4'], rCitizen1, rCitizen2) end,
               },
    job5Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job5'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job5'], rCitizen1, rCitizen2) end,
               },
    job6Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job6'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job6'], rCitizen1, rCitizen2) end,
               },
    job7Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job7'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job7'], rCitizen1, rCitizen2) end,
               },
    job8Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job8'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job8'], rCitizen1, rCitizen2) end,
               },
    job9Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job9'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job9'], rCitizen1, rCitizen2) end,
               },
    job10Sort = {
        sortDownFn = function (rCitizen1, rCitizen2) return jobSortDownFn(tJobToEnum['job10'], rCitizen1, rCitizen2) end,
        sortUpFn = function (rCitizen1, rCitizen2) return jobSortUpFn(tJobToEnum['job10'], rCitizen1, rCitizen2) end,
               },
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
        
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)

        self.tRosterEntries = {}
        self.rScrollableUI = self:getTemplateElement('ScrollPane')
--        self.rScrollableUI = ScrollableUI.new()
--        self:addElement(self.rScrollableUI) -- to parent

        self.tSortButtons = {}
        self.tButtonToModes = {}
        self.tSortVisualLines = {}
        self.tJobLabels = {}

        for sElementName, rInfo in pairs(tSortButtonInfos) do
            local rButton = self:getTemplateElement(sElementName)
            if rButton then
                rButton:addPressedCallback(self.onSortButtonPressed, self)
                self.tButtonToModes[rButton] = rInfo.sSortKey
                local tVisuals = {}
                tVisuals.rSortMid = self:getTemplateElement(rInfo.sSortKey..'DivMid')
                tVisuals.rSortUp = self:getTemplateElement(rInfo.sSortKey..'Up')
                tVisuals.rSortDown = self:getTemplateElement(rInfo.sSortKey..'Down')
                self.tSortVisualLines[rButton] = tVisuals
            end
        end

        for sName, eJob in pairs(tJobToEnum) do
            local rNumLabel = self:getTemplateElement(sName..'Num')
            if rNumLabel then
                self.tJobLabels[eJob] = rNumLabel
            end
        end
        
        --self:setScrollListPos()
        --self:applyScrollBarOverride()        

        self:setSortMode('nameSort', true)
    end

    --[[
    function Ob:setScrollListPos()
        local scrollListPosInfo = self:getExtraTemplateInfo('scrollListPosInfo')
        self.rScrollableUI:setPosInfo(scrollListPosInfo)
        self.rScrollableUI:setScissorY(scrollListPosInfo.scissorLayerName, scrollListPosInfo.scissorY)
    end
    ]]--

    --[[
    function Ob:applyScrollBarOverride()
        local scrollBarOverride = self:getExtraTemplateInfo('scrollBarOverride')
        if scrollBarOverride then
            self.rScrollableUI:applyTemplateInfos(scrollBarOverride)
        end
    end
    ]]--

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
                SoundManager.playSfx('degauss')
            end
        end
    end

    function Ob:sortList(tChars)
        self.tSortedList = {}
        if tChars then
            for i, rChar in pairs(tChars) do
                table.insert(self.tSortedList, rChar)
            end
            local sortFnInfo = tSortFnInfos[self.sSortKey]
            local sortFn = nil
            if sortFnInfo then
                if self.bSortDown then
                    sortFn = sortFnInfo.sortDownFn
                else
                    sortFn = sortFnInfo.sortUpFn
                end
            end
            if sortFn then
                table.sort(self.tSortedList, sortFn)
            end
        end
    end

    function Ob:setSortMode(sSortKey, bSortDown)
        if sSortKey then
            self.bListDirty = true
            self.bSortDown = bSortDown
            self.sSortKey = sSortKey

            -- fix up the visuals
            for rButton, sExistingSortKey in pairs(self.tButtonToModes) do
                local tVisuals = self.tSortVisualLines[rButton]
                if sExistingSortKey == sSortKey then
                    rButton:setSelected(true)
                    if tVisuals then
                        if tVisuals.rSortMid then
                            self:setElementHidden(tVisuals.rSortMid, true)
                        end
                        if tVisuals.rSortUp then
                            if self.bSortDown then
                                self:setElementHidden(tVisuals.rSortUp,true)
                            else
                                self:setElementHidden(tVisuals.rSortUp,false)
                            end
                        end
                        if tVisuals.rSortDown then
                            if self.bSortDown then
                                self:setElementHidden(tVisuals.rSortDown,false)
                            else
                                self:setElementHidden(tVisuals.rSortDown,true)
                            end
                        end
                    end
                else
                    rButton:setSelected(false)
                    if tVisuals.rSortMid then
                        self:setElementHidden(tVisuals.rSortMid,false)
                    end
                    if tVisuals.rSortUp then
                        self:setElementHidden(tVisuals.rSortUp,true)
                    end
                    if tVisuals.rSortDown then
                        self:setElementHidden(tVisuals.rSortDown,true)
                    end
                end
            end
        end
    end

    function Ob:onSortButtonPressed(rButton, eventType)
        if rButton and eventType == DFInput.TOUCH_UP then        
            local sSortKey = self.tButtonToModes[rButton]
            if sSortKey then
                if self.sSortKey ~= sSortKey then
                    self:setSortMode(sSortKey, true)
                else
                    if self.bSortDown then
                        self:setSortMode(sSortKey, false)                        
                    else
                        self:setSortMode(sSortKey, true)  
                    end
                end
            end
        end
    end
    
    function Ob:show(basePri)
        if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
        local w = g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)

        self.bListDirty = true
        local nPri = Ob.Parent.show(self, basePri)
        self.rScrollableUI:reset()
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
        for i, rEntry in ipairs(self.tRosterEntries) do
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

    function Ob:addRosterEntry()
        local rNewEntry = JobRosterEntry.new()
        local nNumEntries = table.getn(self.tRosterEntries)
        
        local w,h = rNewEntry:getDims()
        local nYLoc = h * nNumEntries - 1
        
        rNewEntry:setLoc(0, nYLoc) -- assuming uniform Y size for entries

        self:_calcDimsFromElements()

        self.rScrollableUI:addScrollingItem(rNewEntry)
        table.insert(self.tRosterEntries, rNewEntry)
    end

    function Ob:onTick(dt)
        local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
        local nNumChars = table.getn(tChars)
        local nNumEntries = table.getn(self.tRosterEntries)
        local nNumEntriesToAdd = nNumChars - nNumEntries
        if nNumEntriesToAdd > 0 then -- dynamically add entries
            for i = 1, nNumEntriesToAdd do
                self:addRosterEntry()
            end
        end
        if nNumChars ~= nNumEntries then
            self.bListDirty = true
        end
        if self.bListDirty then
            self:sortList(tChars)
            self.bListDirty = false
        end
        if self.tSortedList then
            for i, rEntry in ipairs(self.tRosterEntries) do
                if self.tSortedList[i] then
                    rEntry:setCitizen(self.tSortedList[i])
                    if not rEntry:isVisible() then
                        rEntry:show(self.maxPri)
                    end
                    rEntry:onTick(dt)
                else
                    rEntry:setCitizen(nil)
                    if rEntry:isVisible() then
                        rEntry:hide(true)
                    end
                end
            end
        end
        self.rScrollableUI:refresh()
        for eJob, rNumLabel in pairs(self.tJobLabels) do
            rNumLabel:setString(tostring(CharacterManager.tJobCount[eJob]))
        end
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if self.rScrollableUI:onFinger(touch, x, y, props) then
            bHandled = true
        end
        if self.rScrollableUI:isInsideScrollPane(x, y) then
            for i, rEntry in ipairs(self.tRosterEntries) do
                if rEntry:onFinger(touch, x, y, props) then
                    bHandled = true
                end
            end        
        end
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        local bHandled = Ob.Parent.inside(self, wx, wy)
        self.rScrollableUI:inside(wx, wy)
        for i, rEntry in ipairs(self.tRosterEntries) do
            if rEntry:inside(wx, wy) then
                bHandled = true
            end
        end         
        return bHandled
    end

    function Ob:onResize()
        Ob.Parent.onResize(self,true)
        self.rScrollableUI:onResize()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
