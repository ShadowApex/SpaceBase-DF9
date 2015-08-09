local m = {}

local DFUtil = require("DFCommon.Util")
local ScrollableUI = require('UI.ScrollableUI')
local Character = require('Character')
local CitizenDutyButton = require('UI.CitizenDutyButton')
local UIElement = require('UI.UIElement')


local sUILayoutFileName = 'UILayouts/CitizenDutyTabLayout'

local tJobOptions =
{
    {
        enum = Character.UNEMPLOYED,
        name = "DUTIES001TEXT",
        desc = "DUTIES002TEXT",
    },
    {
        enum = Character.BUILDER,
        name = "DUTIES003TEXT",
        desc = "DUTIES004TEXT",
    },
    {
        enum = Character.TECHNICIAN,
        name = "DUTIES005TEXT",
        desc = "DUTIES006TEXT",
    },
    {
        enum = Character.MINER,
        name = "DUTIES007TEXT",
        desc = "DUTIES008TEXT",
    },
    {
        enum = Character.EMERGENCY,
        name = "DUTIES009TEXT",
        desc = "DUTIES010TEXT",
    },
    {
        enum = Character.BARTENDER,
        name = "DUTIES013TEXT",
        desc = "DUTIES014TEXT",
    },
    {
        enum = Character.BOTANIST,
        name = "DUTIES016TEXT",
        desc = "DUTIES017TEXT",
    },
    {
        enum = Character.SCIENTIST,
        name = "DUTIES018TEXT",
        desc = "DUTIES019TEXT",
    },
    {
        enum = Character.DOCTOR,
        name = "DUTIES020TEXT",
        desc = "DUTIES021TEXT",
    },
	{
        enum = Character.JANITOR,
        name = "DUTIES022TEXT",
        desc = "DUTIES023TEXT",
    },
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rCitizen = nil
    Ob.tButtons = {}
    Ob.bDoRolloverCheck = true

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        local y=0
        for i, rDutyInfo in ipairs(tJobOptions) do
            local rButton = CitizenDutyButton.new(rDutyInfo)
            local w,h = rButton:getDims()
            self:addElement(rButton) 
            rButton:setLoc(0,y)
            y=y+h
            table.insert(self.tButtons, rButton)
        end
    end
    
    function Ob:show(n)
        local n2 = Ob.Parent.show(self,n)
        return n2
    end
    
    function Ob:hide()
        Ob.Parent.hide(self)
    end
    

    function Ob:setCitizen(rCitizen)
        self.rCitizen = rCitizen
        for i, rButton in ipairs(self.tButtons) do
            rButton:setCitizen(rCitizen)            
        end
    end

    function Ob:setHostileMode(bSet)
        self.bHostileMode = bSet
        if bSet then
            local tOverrides = self:getExtraTemplateInfo('tHostileMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
            --self:hide(true)
        else
            local tOverrides = self:getExtraTemplateInfo('tCitizenMode')
            if tOverrides then
                self:applyTemplateInfos(tOverrides)
            end
            --if not self:isVisible() then
                --self:show(self.currentBasePri)
            --end
        end
    end

    function Ob:onTick(dt)
        for i, rButton in ipairs(self.tButtons) do
            rButton:onTick(dt)
        end
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        for i, rButton in ipairs(self.tButtons) do
            bHandled = rButton:onFinger(touch, x, y, props) or bHandled
        end            
        return bHandled
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
