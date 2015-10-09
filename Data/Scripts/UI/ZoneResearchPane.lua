local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
--local ZoneResearchButton = require('UI.ZoneResearchButton')
local ZoneStatsTab = require('UI.ZoneStatsTab')
local TemplateButton = require('UI.TemplateButton')
local Base = require('Base')
local GameScreen = require('GameScreen')
local Gui = require('UI.Gui')
local Malady = require('Malady')
local MaladyData = require('NewMaladyData')
local Character = require('CharacterConstants')
local ResearchData = require('ResearchData')
local EnvObject = require('EnvObjects.EnvObject')

--local sUILayoutFileName = 'UILayouts/ZoneInspectorLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rRoom = nil

    function Ob:init()
        Ob.Parent.init(self)

        self.tButtons = {}
    end

    function Ob:setRoom(rRoom)
        self.rRoom = rRoom
    end

    function Ob:inside(wx,wy)
        Ob.Parent.inside(self,wx,wy)
    end

    function Ob:onTick(dt)
        --local tAvailableResearch = Base.getAvailableResearch()

        local tAvailableMaladies,nAvailableMaladies = Malady.getAvailableResearch()
        local tAvailableResearch,nAvailableResearch = Base.getAvailableResearch()
        
        nAvailableResearch=nAvailableResearch+nAvailableMaladies
        
        local tAllAvailable = {}
        for k,v in pairs(tAvailableMaladies) do
            table.insert(tAllAvailable, {key=k,bMalady=true})
        end
        for k,v in pairs(tAvailableResearch) do
            table.insert(tAllAvailable, {key=k,bMalady=false})
        end

        if nAvailableResearch ~= #self.tButtons then
            while #self.tButtons > 0 do
                local rElement = self.tButtons[#self.tButtons]
                table.remove(self.tButtons,#self.tButtons)
                self:removeElement(rElement)
                --self:removeScrollingItem(rElement)
            end
            for i=1,nAvailableResearch do
                --local rButton = ZoneResearchButton.new()
                local rButton = TemplateButton.new()
                rButton:setLayoutFile('UILayouts/ZoneResearchButtonLayout')
                rButton:setButtonName('Button')
                rButton:addPressedCallback(self.onButtonPressed, self)
                rButton.rButtonLabel = rButton:getTemplateElement('ButtonLabel')
				rButton.rButtonDesc = rButton:getTemplateElement('ButtonDescription')
                rButton.rButton = rButton:getTemplateElement('Button')
                rButton.rProgressBar = rButton:getTemplateElement('ProgressBar')
                rButton.rProgressBar.rFG:setColor(unpack(Gui.AMBER_OPAQUE))
                rButton.rNumText = rButton:getTemplateElement('NumText')
                rButton.bDoRolloverCheck = true
                self:addElement(rButton)
                table.insert(self.tButtons, rButton)
            end
        end

        local nHeight = 0
        
        for i,v in ipairs(tAllAvailable) do
--        for k,v in pairs(tAvailableResearch) do
            local w,h = self.tButtons[i]:getDims()
            self.tButtons[i]:setLoc(0,nHeight)
            nHeight = nHeight + h
            local k = v.key
            local bSelected = self.rRoom.zoneObj.getResearchStatus and self.rRoom.zoneObj:getResearchStatus() == k
            local tResearchTable = (v.bMalady and tAvailableMaladies[k]) or tAvailableResearch[k]
            self:_setResearch(self.tButtons[i], k, tResearchTable,bSelected,v.bMalady)
        end
        
        -- MTF HORRIBLE BUILD DAY HACK:
        -- Need to figure out a good way to pass resize notifications up, rather than
        -- manually jumping a number of elems up the tree and crashing if anything changes.
        self:_calcDimsFromElements()
        self.rParentUIElement:_calcDimsFromElements()
        self.rParentUIElement.rParentUIElement:_calcDimsFromElements()
        self.rParentUIElement.rParentUIElement.rParentUIElement:refresh()
    end

    function Ob:_setResearch(rButton, sKey,tProgress,bSelected,bMalady)
        local sName,sDesc,nProgress,nTotal
        if bMalady then
            sName = Malady.getFriendlyName(sKey)
            sDesc = g_LM.line(Malady.getDescription(sKey))
            nProgress = tProgress.nCureProgress
            nTotal = tProgress.nResearchCure
        else
            local tSpec = ResearchData[sKey]
            if tSpec.sItemForDesc then
                sName = EnvObject.getObjectData(tSpec.sItemForDesc).friendlyNameLinecode
                sDesc = EnvObject.getObjectData(tSpec.sItemForDesc).description
            end
            if tSpec.sName then sName = tSpec.sName end
            if tSpec.sDesc then sDesc = tSpec.sDesc end
            if sName then sName = g_LM.line(sName) end
            if sDesc then sDesc = g_LM.line(sDesc) end
            nProgress = tProgress.nResearchUnits or 0
            nTotal = tSpec.nResearchUnits
        end

        nProgress = math.floor(nProgress)
        nTotal = math.floor(nTotal)
        
        rButton.rButtonLabel:setString(sName)
		rButton.rButtonDesc:setString(sDesc)
        
        rButton.rNumText:setString(tostring(math.floor(nProgress)) .. '/' .. tostring(nTotal))
        rButton.rProgressBar:setProgress(nProgress / nTotal)
        rButton:setSelected(bSelected)
        rButton.sKey = sKey
    end

    function Ob:onButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            print('RESEARCH',rButton.sKey)
            if self.rRoom and self.rRoom.zoneObj.setActiveResearch then
                if rButton.bSelected then
                    self.rRoom.zoneObj:setActiveResearch(nil)
                else
                    self.rRoom.zoneObj:setActiveResearch(rButton.sKey)
                end
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
