local m = {}

local DFUtil = require("DFCommon.Util")
local DFMath = require('DFCommon.Math')
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ObjectList = require('ObjectList')
local MiscUtil = require('MiscUtil')
local Gui = require('UI.Gui')

local sUILayoutFileName = 'UILayouts/NewBaseInspectorLayout'

local regionLineCode = "NEWBAS007TEXT"
local regionFormat = "%s %d-%d"

local ageIntroLineCode = "NEWBAS008TEXT"
local ageUnitsLineCode = "NEWBAS009TEXT"
local ageFormat = "%s %d %s"
local distanceIntroLineCode = "NEWBAS010TEXT"
local distanceUnitsLineCode = "NEWBAS011TEXT"
local distanceFormat = "%s %d %s"
local threatLineCode = "NEWBAS015TEXT"
local interferenceLineCode = "NEWBAS016TEXT"
local densityLineCode = "NEWBAS020TEXT"

local tRegionAdjectiveLineCodes = {
	'NEWBAS023TEXT', 'NEWBAS024TEXT', 'NEWBAS025TEXT', 'NEWBAS026TEXT', 'NEWBAS027TEXT',
	'NEWBAS028TEXT', 'NEWBAS029TEXT', 'NEWBAS030TEXT', 'NEWBAS031TEXT', 'NEWBAS032TEXT',
	'NEWBAS033TEXT', 'NEWBAS034TEXT', 'NEWBAS041TEXT', 'NEWBAS043TEXT',

	'NEWBAS060TEXT', 'NEWBAS061TEXT', 'NEWBAS062TEXT', 'NEWBAS063TEXT', 'NEWBAS064TEXT',
	'NEWBAS065TEXT', 'NEWBAS066TEXT', 'NEWBAS067TEXT', 'NEWBAS068TEXT', 'NEWBAS069TEXT',
	'NEWBAS070TEXT', 'NEWBAS071TEXT', 'NEWBAS072TEXT', 'NEWBAS073TEXT', 'NEWBAS074TEXT',
	'NEWBAS075TEXT', 'NEWBAS076TEXT', 'NEWBAS077TEXT', 'NEWBAS078TEXT', 'NEWBAS079TEXT',
	'NEWBAS080TEXT', 'NEWBAS081TEXT', 'NEWBAS082TEXT', 'NEWBAS083TEXT', 'NEWBAS084TEXT',
	'NEWBAS085TEXT', 'NEWBAS086TEXT', 'NEWBAS087TEXT', 'NEWBAS088TEXT', 'NEWBAS089TEXT',
	'NEWBAS090TEXT', 'NEWBAS091TEXT', 'NEWBAS092TEXT', 'NEWBAS093TEXT', 'NEWBAS094TEXT',
	'NEWBAS095TEXT', 'NEWBAS096TEXT', 'NEWBAS097TEXT', 'NEWBAS098TEXT', 'NEWBAS099TEXT',
	'NEWBAS100TEXT', 'NEWBAS101TEXT', 'NEWBAS102TEXT', 'NEWBAS103TEXT', 'NEWBAS104TEXT',
	'NEWBAS105TEXT', 'NEWBAS106TEXT', 'NEWBAS107TEXT', 'NEWBAS108TEXT', 'NEWBAS109TEXT',
	'NEWBAS110TEXT', 'NEWBAS111TEXT', 'NEWBAS112TEXT', 'NEWBAS113TEXT', 'NEWBAS114TEXT',
	'NEWBAS115TEXT', 'NEWBAS116TEXT', 'NEWBAS117TEXT', 'NEWBAS118TEXT', 'NEWBAS119TEXT',
	'NEWBAS120TEXT', 'NEWBAS121TEXT', 'NEWBAS122TEXT', 'NEWBAS123TEXT', 'NEWBAS124TEXT',
	'NEWBAS125TEXT', 'NEWBAS126TEXT', 'NEWBAS127TEXT', 'NEWBAS128TEXT', 'NEWBAS129TEXT',
	'NEWBAS130TEXT', 'NEWBAS131TEXT', 'NEWBAS132TEXT', 'NEWBAS133TEXT', 'NEWBAS134TEXT',
	'NEWBAS135TEXT', 'NEWBAS136TEXT', 'NEWBAS137TEXT', 'NEWBAS138TEXT', 'NEWBAS139TEXT',
	'NEWBAS140TEXT', 'NEWBAS141TEXT', 'NEWBAS142TEXT', 'NEWBAS143TEXT', 'NEWBAS144TEXT',
	'NEWBAS145TEXT', 'NEWBAS146TEXT', 'NEWBAS147TEXT', 'NEWBAS148TEXT', 'NEWBAS149TEXT',
	'NEWBAS150TEXT', 'NEWBAS151TEXT',

	-- Greek letters
	'ZONEUI018TEXT', 'ZONEUI019TEXT', 
	'ZONEUI020TEXT', 'ZONEUI021TEXT', 'ZONEUI022TEXT', 'ZONEUI023TEXT', 'ZONEUI024TEXT', 
	'ZONEUI025TEXT', 'ZONEUI026TEXT', 'ZONEUI027TEXT', 'ZONEUI028TEXT', 'ZONEUI029TEXT', 
	'ZONEUI030TEXT', 'ZONEUI031TEXT', 'ZONEUI032TEXT', 'ZONEUI033TEXT', 

	-- Colors
	'ZONEUI073TEXT', 'ZONEUI074TEXT', 
	'ZONEUI075TEXT', 'ZONEUI076TEXT', 'ZONEUI077TEXT', 'ZONEUI078TEXT', 'ZONEUI079TEXT',
	'ZONEUI080TEXT', 'ZONEUI081TEXT', 'ZONEUI082TEXT', 'ZONEUI083TEXT', 'ZONEUI084TEXT',
}
local tRegionNounLineCodes = {
	'NEWBAS035TEXT', 'NEWBAS036TEXT', 'NEWBAS037TEXT', 'NEWBAS038TEXT', 'NEWBAS039TEXT', 'NEWBAS040TEXT',
	'NEWBAS044TEXT', 'NEWBAS045TEXT', 'NEWBAS046TEXT', 'NEWBAS047TEXT', 'NEWBAS048TEXT', 'NEWBAS049TEXT',
	'NEWBAS050TEXT', 'NEWBAS051TEXT', 'NEWBAS052TEXT', 'NEWBAS053TEXT', 'NEWBAS054TEXT',
	'NEWBAS055TEXT', 'NEWBAS056TEXT', 'NEWBAS057TEXT', 'NEWBAS058TEXT', 'NEWBAS059TEXT',
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    function Ob:init()
        Ob.Parent.init(self)

        self:processUIInfo(sUILayoutFileName)
        
        self.tRevealedElements = {}
        for k,v in pairs(self.tTemplateElements) do
            if k ~= "ZoomedMap" then self.tRevealedElements[k] = v end
        end
        
        self.rZoomedMap = self:getTemplateElement('ZoomedMap')
        self.rLabelName = self:getTemplateElement('LabelName')
        self.rLabelAge = self:getTemplateElement('LabelAge')
        self.rTextDensity = self:getTemplateElement('TextDensity')
        self.rTextDistance = self:getTemplateElement('TextDistance')
        self.rTextThreat = self:getTemplateElement('TextThreat')
        self.rTextInterference = self:getTemplateElement('TextInterference')
        self.sRegionName = ''
        
        self.nElapsedTime = 0
        
        self.nZoomedMapTargetX,self.nZoomedMapTargetY = self.rZoomedMap:getLoc()
        self.nZoomedMapStartX,self.nZoomedMapStartY = -600, -722
    end
    
    function Ob:setLandingZone(tLandingZone,x,y)
        self.nZoomedMapStartX,self.nZoomedMapStartY = x-300,y
        local x,y = tLandingZone.x,tLandingZone.y
        self.sRegionName = self:getRegionName(x,y)
        self.rLabelName:setString(self.sRegionName)
        self.rLabelAge:setString(string.format(ageFormat, g_LM.line(ageIntroLineCode),  DFMath.roundDecimal(math.abs(math.sin(math.rad(x*15))) * 10 + 5), g_LM.line(ageUnitsLineCode)))
        
        local densityText, densityColor = MiscUtil.getSeverityFromValue(MiscUtil.getGalaxyMapValue(x, y,'asteroids'))
        if densityColor == 'low' then densityColor = Gui.RED
        elseif densityColor == 'high' then densityColor = Gui.GREEN
        else densityColor = Gui.AMBER end
        self.rTextDensity:setString(string.format("%s %s", "", densityText))
        self.rTextDensity:setColor(densityColor[1], densityColor[2], densityColor[3], 1)
        local distanceText, distanceColor = MiscUtil.getDistanceFromValue(MiscUtil.getGalaxyMapValue(x, y,'population'))
        self.rTextDistance:setString(string.format("%s %s", "", distanceText))
        --self.rTextDistance:setColor(distanceColor[1], distanceColor[2], distanceColor[3], 1)
        local threatText, threatColor = MiscUtil.getSeverityFromValue(MiscUtil.getGalaxyMapValue(x, y,'hostility'))
        if threatColor == 'low' then threatColor = Gui.GREEN
        elseif threatColor == 'high' then threatColor = Gui.RED
        else threatColor = Gui.AMBER end
        self.rTextThreat:setString(string.format("%s %s", "", threatText))
        self.rTextThreat:setColor(threatColor[1], threatColor[2], threatColor[3], 1)
        local interferenceText, interferenceColor = MiscUtil.getSeverityFromValue(MiscUtil.getGalaxyMapValue(x, y,'derelict'))   
        self.rTextInterference:setString(string.format("%s %s", "", interferenceText))
        --self.rTextInterference:setColor(interferenceColor[1], interferenceColor[2], interferenceColor[3], 1)
    end

    function Ob:onFinger(touch, x, y, props)
        if self.rCustomInspector then
            self.rCustomInspector:onFinger(touch, x, y, props)
        end
    end

    function Ob:inside(wx, wy)
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        self.bActive = true
    end

    function Ob:show(nPri)
        Ob.Parent.show(self, nPri)
        
        self.nElapsedTime = 0
        self.bDoneIntro = false
        self.bActive = true
        
        for k,v in pairs(self.tRevealedElements) do 
            self:setElementHidden(v,true)
        end
    end
    
    function Ob:onTick(dt)
        Ob.Parent.onTick(self, dt)
        if not self.bActive then return end
        if not self.bDoneIntro then
            local stepSize = 0.25
            local totalTime = 1.0
            self.nElapsedTime = self.nElapsedTime + dt
            if self.nElapsedTime > totalTime then
                self:setMap(1)
                self.bDoneIntro = true
                self.newBase:playWarbleEffect(true)
                for k,v in pairs(self.tRevealedElements) do 
                    self:setElementHidden(v,false)
                end
            else
                local currentStep = math.floor(self.nElapsedTime / stepSize)
                local totalSteps = math.max(math.floor(totalTime / stepSize), 1)
                self:setMap(currentStep / totalSteps)
            end
        end
    end
	
    function Ob:getRegionName(x,y)
		local adj = g_LM.line(DFUtil.arrayRandom(tRegionAdjectiveLineCodes))
		local noun = g_LM.line(DFUtil.arrayRandom(tRegionNounLineCodes))
        return string.format(regionFormat, adj..' '..noun,  x, y)
    end
    
    function Ob:setMap(t)
        self.rZoomedMap:setLoc(DFMath.lerp(self.nZoomedMapStartX, self.nZoomedMapTargetX, t), DFMath.lerp(self.nZoomedMapStartY, self.nZoomedMapTargetY, t))
        self.rZoomedMap:setRot(0, 0, DFMath.lerp(15, 0, t))
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
