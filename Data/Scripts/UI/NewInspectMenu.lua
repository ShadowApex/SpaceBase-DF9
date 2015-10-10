local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CitizenInspector = require('UI.CitizenInspector')
local ObjectInspector = require('UI.ObjectInspector')
local ZoneInspector = require('UI.ZoneInspector')
local ObjectList = require('ObjectList')
local SoundManager = require('SoundManager')

local sUILayoutFileName = 'UILayouts/InspectMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rSelectedButton = nil

    function Ob:init()
		Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rCitizenInspector = CitizenInspector.new()
        self.rObjectInspector = ObjectInspector.new()
        self.rZoneInspector = ZoneInspector.new()

        self.rBackButton = self:getTemplateElement('BackButton')        
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
        self.rLargeBar = self:getTemplateElement('LargeBar')
        
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
		self.rSelected = nil
    end

    function Ob:setActiveInspector(rInspector)
        if self.rCurInspector ~= rInspector then
            if self.rCurInspector then
                self.rCurInspector:hide(true)
                if self.rCurInspector == self.rCitizenInspector then
                    self.rCitizenInspector:setCitizen(nil)
                elseif self.rCurInspector == self.rObjectInspector then
                    self.rObjectInspector:setObject(nil)
                elseif self.rCurInspector == self.rZoneInspector then
                    self.rZoneInspector:setRoom(nil)
                end
            end
            self.rCurInspector = rInspector
            if self.rCurInspector then
                self.rCurInspector:show(self.maxPri)
            end
        end
    end

    function Ob:onTick(dt)
        local rSelected = g_GuiManager.getSelected()
        
        if self.rSelected ~= rSelected then
            local objType = ObjectList.getObjType(rSelected)
            if objType == 'Character' then
                self:setActiveInspector(self.rCitizenInspector)
                self.rCitizenInspector:setCitizen(rSelected)
            elseif objType == 'EnvObject' or objType == 'WorldObject' or objType == 'INVENTORYITEM' then
                self:setActiveInspector(self.rObjectInspector)
                self.rObjectInspector:setObject(rSelected)
            elseif objType == 'Room' then
                self:setActiveInspector(self.rZoneInspector)
                self.rZoneInspector:setRoom(rSelected)
            end
            self.rSelected = rSelected
            if not rSelected then
                g_GuiManager.newSideBar:closeSubmenu()
                SoundManager.playSfx('degauss')                
            end
        end
        if self.rCurInspector then
            self.rCurInspector:onTick(dt)
        end
    end

    function Ob:onFinger(touch, x, y, props)
        local bTouched = false
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bTouched = true
        end
        
        if self.rCurInspector and self.rCurInspector:onFinger(touch, x, y, props) then
            bTouched = true
        end
        
        if not bTouched and props then
            for i, rProp in ipairs(props) do
                if rProp == self.rLargeBar then
                    return true -- disallow button presses through the menu
                end
            end
        end
        return bTouched
    end

    function Ob:inside(wx, wy)
        local bHandled = false
        if Ob.Parent.inside(self, wx, wy) then
            bHandled = true
        end
        if self.rCurInspector then
            if self.rCurInspector:inside(wx, wy) then
                bHandled = true
            end
        end
        return bHandled
    end

    function Ob:onBackButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
				g_GameRules.completeTutorialCondition('DeselectedThing')
                g_GuiManager.newSideBar:closeSubmenu()
                --g_GuiManager.clearSelectionProp()
                g_GuiManager.setSelected(nil)
                SoundManager.playSfx('degauss')
            end
        end
    end   

    function Ob:show(basePri)
        g_GameRules.setUIMode(g_GameRules.MODE_INSPECT)
        return Ob.Parent.show(self, basePri)
    end

    function Ob:hide()
        Ob.Parent.hide(self)
        self.rSelected = nil
        self:setActiveInspector(nil)
    end

    function Ob:onResize()
        Ob.Parent.onResize(self)
        if self.rCurInspector then
            self.rCurInspector:onResize()
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
    
