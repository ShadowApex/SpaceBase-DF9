local m = {}

local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local UIElement = require('UI.UIElement')
local ZoneRezoneButton = require('UI.ZoneRezoneButton')

local sUILayoutFileName = 'UILayouts/ZoneRezoneTabLayout'

local tZoneOptions =
{
    {
        name = "ZONEUI036TEXT",
        desc = "INSPEC034TEXT",
        propdesc = "INSPEC041TEXT",
        zoneName = 'AIRLOCK',        
    },
    {
        --LIFE SUPPORT
        name = "ZONEUI001TEXT",
        desc = "INSPEC035TEXT",
        propdesc = "INSPEC042TEXT",
        zoneName= 'LIFESUPPORT',
    },
    {
        --REACTOR
        name = "ZONEUI003TEXT",
        desc = "INSPEC036TEXT",
        propdesc = "INSPEC043TEXT",
        zoneName = 'POWER',
    },
    {
        --REFINERY
        name = "ZONEUI037TEXT",
        desc = "INSPEC037TEXT",
        propdesc = "INSPEC044TEXT",
        zoneName = 'REFINERY',
    },
    {
        --RESIDENCE
        name = "ZONEUI042TEXT",
        desc = "INSPEC038TEXT",
        propdesc = "INSPEC045TEXT",
        zoneName = 'RESIDENCE',
    },
    {
        --PUB
        name = "ZONEUI046TEXT",
        desc = "INSPEC039TEXT",
        propdesc = "INSPEC046TEXT",
        zoneName = 'PUB',
    },
    {
        --GARDEN
        name = "ZONEUI069TEXT",
        desc = "INSPEC083TEXT",
        propdesc = "INSPEC084TEXT",
        zoneName = 'GARDEN',
    },
    {
        --FITNESS
        name = "ZONEUI109TEXT",
        desc = "INSPEC116TEXT",
        propdesc = "INSPEC115TEXT",
        zoneName = 'FITNESS',
    },
    {
        --RESEARCH
        name = "ZONEUI126TEXT",
        desc = "INSPEC119TEXT",
        propdesc = "INSPEC120TEXT",
        zoneName = 'RESEARCH',
    },
    {
        --INFIRMARY
        name = "ZONEUI049TEXT",
        desc = "INSPEC138TEXT",
        propdesc = "INSPEC139TEXT",
        zoneName = 'INFIRMARY',
    },
    {
        --BRIG
        name = "ZONEUI142TEXT",
        desc = "ZONEUI143TEXT",
        propdesc = "ZONEUI144TEXT",
        zoneName = 'BRIG',
    },
	{
        --COMMAND ZONE
        name = "COMMAND001TEXT",
        desc = "COMMAND002TEXT",
        propdesc = "COMMAND003TEXT",
        zoneName= 'COMMAND',
    },
    {
        --UNZONED
        name = "ZONEUI005TEXT",
        desc = "INSPEC040TEXT",
        zoneName= 'PLAIN',
    },
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rZone = nil
    Ob.bDoRolloverCheck = true
    Ob.tButtons = {}

    function Ob:init()
        self:processUIInfo(sUILayoutFileName)
        Ob.Parent.init(self)

        local y=0
        for i, rZoneInfo in ipairs(tZoneOptions) do
            local rButton = ZoneRezoneButton.new(rZoneInfo)
            local w,h = rButton:getDims()
            self:addElement(rButton)
            rButton:setLoc(0,y)
            y=y+h
            table.insert(self.tButtons, rButton)
        end
        self:_calcDimsFromElements()
    end
	
    function Ob:setRoom(rRoom)
        self.rRoom = rRoom
        for i, rButton in ipairs(self.tButtons) do
            rButton:setRoom(rRoom)
        end
    end

    function Ob:onTick(dt)
        for i, rButton in ipairs(self.tButtons) do
            rButton:onTick(dt)
        end
    end

    --[[
    function Ob:onSelected(bSelected)
        self.bSelected = bSelected
        if bSelected then
            self.rScrollableUI:show(self.maxPri)
            for i, rButton in ipairs(self.tButtons) do
                rButton:show(0) -- used for temp scrolling masking
            end
        else
            self.rScrollableUI:hide(true)
            for i, rButton in ipairs(self.tButtons) do
                rButton:hide(true)
            end
        end
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        for i, rButton in ipairs(self.tButtons) do
            rButton:hide(true)
        end
    end
    ]]--

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        for i, rButton in ipairs(self.tButtons) do
            bHandled = rButton:onFinger(touch, x, y, props)
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        Ob.Parent.inside(self, wx, wy)
        --self.rScrollableUI:inside(wx, wy)
        for i, rButton in ipairs(self.tButtons) do
            rButton:inside(wx, wy)
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
