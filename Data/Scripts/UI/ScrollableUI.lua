local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local MiscUtil = require("MiscUtil")

local sDefaultLayoutFileName = 'UILayouts/ScrollableUILayout'
local sDefaultScissorLayerName = 'UIScrollLayerLeft'

local kINCREMENT = 50
local kSCROLL_BAR_SCALE = 5

-- currently just a stub until masking tech
function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.tItems = {}
    Ob.bInScrollMode = false

    function Ob:init(sRenderLayerName,sLayoutFileName)
        self.sScissorLayerName = sDefaultScissorLayerName
        Ob.Parent.init(self,sRenderLayerName,sLayoutFileName or sDefaultLayoutFileName)
        self.nContentHeight = 0
        self.rItemsTransform = UIElement.new()        
        self:addElement(self.rItemsTransform)
            
        self.rUpButton = self:getTemplateElement('UpButton')
        self.rDownButton = self:getTemplateElement('DownButton')
        self.rScrollbarButton = self:getTemplateElement('ScrollbarButton')
        self.rPaneBG = self:getTemplateElement('PaneBG')
        if not self.rPaneBG then
            self.rPaneBG = self:addOnePixel()
        end
        self.rPaneBG:setColor(0,0,0,0)
        self.tScrollerItems={self.rUpButton,self.rDownButton,self.rScrollbarButton}
        
        self.rUpButton:addPressedCallback(self.onUpButtonPressed, self)
        self.rDownButton:addPressedCallback(self.onDownButtonPressed, self)
        self.rScrollbarButton:addPressedCallback(self.onScrollbarButtonPressed, self)

        self.nOrigScrollbarX, self.nOrigScrollbarY = self.rScrollbarButton:getLoc()
        self:setRect(0,0,0,0)
        self.bInitialized = true
    end

    function Ob:getDims()
        if self.tRect then
            return self.tRect[3],self.tRect[4]
        end
        return Ob.Parent.getDims(self)
    end

    function Ob:setRect(x1,y1,x2,y2)
        self.tRect = {x1,y1,x2,y2}
        self.rPaneBG:setScl(x2-x1,y2-y1)
        self.rPaneBG:setLoc(x1,y1)
        self.nBarX = x2-x1
        
        if not self.rUpButton.tPosInfo then self.rUpButton.tPosInfo = {} end
        if not self.rDownButton.tPosInfo then self.rDownButton.tPosInfo = {} end
        if not self.rScrollbarButton.tPosInfo then self.rScrollbarButton.tPosInfo = {} end
        if not self.rScrollbarButton.tPosInfo then self.rScrollbarButton.tPosInfo = {} end

        self.rUpButton.tPosInfo.offsetX = self.nBarX
        self.rDownButton.tPosInfo.offsetX = self.nBarX
        self.rScrollbarButton.tPosInfo.offsetX = self.nBarX
        self.rScrollbarButton.tPosInfo.offsetX = self.nBarX

        local w,h = self.rDownButton:getDims()
        self.nBottomY = -(y2-y1)
        self.rDownButton.tPosInfo.offsetY = self.nBottomY
        self.nBottomY = self.nBottomY + h

        self:_updateScrollableUICutoff()
        self:reset()
    end

    function Ob:setScissorLayer(sName)
        self.sScissorLayerName = sName
    end

    function Ob:hide(bKeepAlive)
        Ob.Parent.hide(self,bKeepAlive)
    end

    function Ob:show(nMaxPri)
        self:_updateScrollableUICutoff()
        local n = Ob.Parent.show(self, nMaxPri)
        self:reset()
        return n
    end
    
    function Ob:_updateScrollableUICutoff()
        local _,nWorldTopY = self:modelToWorld(0,0)
        g_GuiManager.setScrollableUICutoffY(self.sScissorLayerName, nWorldTopY)
    end

    function Ob:addScrollingItem(rItem)
        table.insert(self.tItems, rItem)
        self.rItemsTransform:addElement(rItem)
        self:_updateContentSize()
        if self.bInitialized then
            self:refresh()
        end
    end
    
    function Ob:onTick(dt)
        Ob.Parent.onTick(self,dt)
        for i,v in ipairs(self.tItems) do
            if v.onTick then v:onTick(dt) end
        end
    end

    function Ob:removeScrollingItem(rItem)
        for i,v in ipairs(self.tItems) do
            if v == rItem then
                table.remove(self.tItems,i)
            end
        end
        self.rItemsTransform:removeElement(rItem)
        self:_updateContentSize()
        if self.bInitialized then
            self:refresh()
        end
    end
    
    function Ob:refresh()
        self:_updateContentSize()
        self:_updateScrollableUICutoff()
        if self:getMaxScrollbarY() == 0 then
            -- no need to scroll
            self:setScrollEnabled(false)
        else
            self:setScrollEnabled(true)
        end
        for i, rItem in ipairs(self.tItems) do
            if rItem.refresh then rItem:refresh() end            
        end
    end

    function Ob:onResize()
        Ob.Parent.onResize(self)
        self:_updateScrollableUICutoff()
        self:reset()
    end

    function Ob:reset()
        local x, y = self.rItemsTransform:getLoc()
        self.rItemsTransform:setLoc(x, 0)
        self:_updateScrollbarPos()
    end

    function Ob:setScrollEnabled(bEnabled)
        self.bScrollEnabled = bEnabled
        self:setElementHidden(self.rUpButton,not bEnabled)
        self:setElementHidden(self.rDownButton,not bEnabled)
        self:setElementHidden(self.rScrollbarButton,not bEnabled)
        if not bEnabled then self:reset() end
    end

    function Ob:isScrollEnabled()
        return self.bScrollEnabled
    end

    function Ob:inside(wx,wy)
        local bInside = Ob.Parent.inside(self,wx,wy,self.tItems)
        bInside = Ob.Parent.inside(self,wx,wy,self.tScrollerItems) or bInside
    end

    function Ob:isInsideScrollPane(x, y)
        if self.rPaneBG:inside(x, y) then
            return true
        else
            return false
        end
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if self.rPaneBG:inside(x, y) then
            bHandled = Ob.Parent.onFinger(self, touch, x, y, props, self.tItems)
        end
        if not self.bScrollEnabled then
            if bHandled or self.rPaneBG:inside(x, y) then
                return true
            else
                return false
            end
        end
        bHandled = Ob.Parent.onFinger(self, touch, x, y, props, self.tScrollerItems) or bHandled
        if touch.button == DFInput.MOUSE_LEFT then
            if touch.eventType == DFInput.TOUCH_UP and self.bInScrollMode then
                self.bInScrollMode = false
                self.nLastX = nil
                self.nLastY = nil
                return true
            end
            if self.bInScrollMode then
                if not self.nLastX then
                    self.nLastX = x
                end
                if not self.nLastY then
                    self.nLastY = y
                end
                local nIncrement = math.floor(math.abs(self.nLastY - y) * kSCROLL_BAR_SCALE)
                if self.nLastY > y then
                    self:scroll(false, nIncrement)
                elseif self.nLastY < y then
                    self:scroll(true, nIncrement)
                end
                self.nLastX = x
                self.nLastY = y
                return true
            end
        elseif touch.button == DFInput.MOUSE_SCROLL_UP then
            if self.rPaneBG:inside(x, y) then
                self:scroll(true, kINCREMENT)
                return true
            end
        elseif touch.button == DFInput.MOUSE_SCROLL_DOWN then
            if self.rPaneBG:inside(x, y) then
                self:scroll(false, kINCREMENT)
                return true
            end
        end
        return bHandled
    end

    function Ob:_updateScrollbarPos()
        local nMaxY = self:getMaxScrollbarY()
        local x, y = self.rItemsTransform:getLoc()
        local nBarX, _ = self.rScrollbarButton:getLoc()
        local nBarY = self.nOrigScrollbarY
        local nDownButtonY = self.nBottomY
        self.nMaxScrollbarYSize = math.abs(self.nOrigScrollbarY - nDownButtonY)        
        if nMaxY ~= 0 then
            nBarY = self.nOrigScrollbarY + (0 - ((y / nMaxY) * self.nMaxScrollbarYSize))
        end
        self.rScrollbarButton:setLoc(nBarX, nBarY)
    end

    function Ob:_updateContentSize()
        local nYSize = 0
        for i, rItem in ipairs(self.tItems) do
            local bShouldCheck = true
            if rItem and rItem.isVisible and not rItem:isVisible() then
                bShouldCheck = false
            end
            if bShouldCheck then
                local x,y = rItem:getLoc()
                local w,h = rItem:getDims()
                local maxY = math.abs(y+h)
                nYSize = math.max(maxY,nYSize)
            end
        end
        self.nContentHeight = nYSize
    end

    function Ob:getMaxScrollbarY()
        local nScaleX, nScaleY = self.rPaneBG:getScl()
        nScaleY = math.abs(nScaleY)
        local nMaxY = self.nContentHeight - nScaleY
        if nMaxY < 0 then
            nMaxY = 0
        end
        return nMaxY
    end
	
	function Ob:getScrollDistance()
		local x,y = self.rItemsTransform:getLoc()
		return y
	end

    function Ob:scroll(bDown, nIncrement)
        local x, y = self.rItemsTransform:getLoc()
        local nMaxY = self:getMaxScrollbarY()
        if not nIncrement then
            nIncrement = kINCREMENT
        end
        local nFinalY = 0
        if bDown then
            nFinalY = y - nIncrement
            if nFinalY < 0 then
                nFinalY = 0
            end
        else
            nFinalY = y + nIncrement
            if nFinalY > nMaxY then
                nFinalY = nMaxY
            end
        end
        self.rItemsTransform:setLoc(x, nFinalY)
        self:_updateScrollbarPos()
    end

    function Ob:onUpButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:scroll(true)
        end
    end

    function Ob:onDownButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            self:scroll(false)
        end
    end

    function Ob:onScrollbarButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_DOWN then
            self.bInScrollMode = true
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
