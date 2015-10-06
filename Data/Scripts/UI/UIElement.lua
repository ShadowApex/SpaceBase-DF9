local DFGraphics = require('DFCommon.Graphics')
local DFFile = require('DFCommon.File')
local DFMoaiDebugger = require("DFMoai.Debugger")
local DFMath = require("DFCommon.Math")
local DFUtil = require('DFCommon.Util')
local Renderer = require('Renderer')
local Gui = require('UI.Gui')
local MiscUtil = require("MiscUtil")
local SoundManager = require('SoundManager')
local m = {}

function m.create()
    local Ob = MOAITransform.new()

    Ob.sDefaultRenderLayerName = 'UI'

    function Ob:init(sRenderLayerName,sLayoutFileName)
        self.uiWidth,self.uiHeight = 0,0
        if sLayoutFileName then
            self:processUIInfo(sLayoutFileName)
        end

        self.isUIElement = true
        if self.spriteList then
            self:loadUISpriteSheets(self.spriteList, self.xAlign or "left", self.yAlign or "top")
        end
        if self.spriteSheet then
            if not self.tUISpriteSheets then self.tUISpriteSheets = {} end 
            if not self.tTextureToSpriteSheet then self.tTextureToSpriteSheet = {} end 
            self:_addSpriteSheet(self.spriteSheet)
        end
        
        self.tAnimatingObjects = {}
        self.tTickElements = {}
        DFMoaiDebugger.dFileChanged:register(self.onFileChange,self)
    end

    function Ob:setRenderLayer(sName)
        self.sRenderLayerName = sName
    end
    
    function Ob:getRenderLayerName()
        if self.sRenderLayerName then return self.sRenderLayerName end
        if self.rParentUIElement then return self.rParentUIElement:getRenderLayerName() end
        return self.sDefaultRenderLayerName
    end

    function Ob:_addSpriteSheet(path)
        if self.tUISpriteSheets[path] then return end

        local rSpriteSheet = DFGraphics.loadSpriteSheet(path)
        for sName, data in pairs(rSpriteSheet.names) do
            DFGraphics.alignSprite(rSpriteSheet, sName, self.xAlign or "left", self.yAlign or "top")
            self.tTextureToSpriteSheet[sName] = rSpriteSheet
        end
        self.tUISpriteSheets[path] = rSpriteSheet
    end

    function Ob:isVisible()
        return self.elementsVisible
    end

    function Ob:show(basePri)
--        if self.elementsVisible == true then return end
        
        self.elementsVisible = true
        self.currentBasePri = basePri or self.currentBasePri

        if not self.tElements then return basePri end

        local maxPri = basePri or 0
        for _, v in ipairs(self.tElements) do
            maxPri = self:_setElementVisible(v, true, maxPri + 1)
        end

        self.maxPri = maxPri

        g_GuiManager.setMaxPriOnLayer(self:getRenderLayerName(), self.maxPri)
        return maxPri
    end

    function Ob:hide(bKeepAlive)
--        if self.elementsVisible == false then return end
        
        self.elementsVisible = false
        if self.tElements then
            for _, v in ipairs(self.tElements) do
                self:_setElementVisible(v, false)
            end
        end

        if not bKeepAlive then
           self:unloadUISpriteSheets()
        end
    end
    
    function Ob:onTick(dt)
    --This if statement is a hacky quick-fix for the debug menu crashes we were getting
	if self.tAnimatingObjects then
    --Hackiness above
        for k,v in pairs(self.tAnimatingObjects) do
            v.currentTime = math.min(v.currentTime + dt, (v.totalTime+v.delay))
            local t = math.max(v.currentTime - v.delay, 0) / v.totalTime
            if v.sType == "Move" then
                local newX = DFMath.lerp(v.startX, v.endX, t)
                local newY = DFMath.lerp(v.startY, v.endY, t)
                k:setLoc(newX, newY)
            elseif v.sType == "Color" then
                k:setColor(  DFMath.lerp(v.tStartColor[1], v.tEndColor[1], t), DFMath.lerp(v.tStartColor[2], v.tEndColor[2], t),
                                    DFMath.lerp(v.tStartColor[3], v.tEndColor[3], t), DFMath.lerp(v.tStartColor[4], v.tEndColor[4], t))
            end
            if v.currentTime >= (v.totalTime+v.delay) then
                if v.callback then v.callback() end
                self.tAnimatingObjects[k] = nil
            end
        end
        for k,v in pairs(self.tTickElements) do
            v:onTick(dt)
        end
	end
    end

    function Ob:loadUISpriteSheets(tSpriteSheetInfo, xAlign, yAlign)        
        Ob.tUISpriteSheets = {}
        Ob.tTextureToSpriteSheet = {}
        for sTextureName, spriteSheetPath in pairs(tSpriteSheetInfo) do
            self:addToUISpriteSheets(sTextureName, spriteSheetPath, xAlign, yAlign)
        end
    end

    function Ob:addToUISpriteSheets(sTextureName, spriteSheetPath, xAlign, yAlign)
        if not self.tUISpriteSheets then
            self.tUISpriteSheets = {}
        end
        if not self.tTextureToSpriteSheet then
            self.tTextureToSpriteSheet = {}
        end
        if not self.tUISpriteSheets[spriteSheetPath] then
            local rSpriteSheet = DFGraphics.loadSpriteSheet(spriteSheetPath)    
            if xAlign ~= 'skip' then
                for sName, data in pairs(rSpriteSheet.names) do
                    DFGraphics.alignSprite(rSpriteSheet, sName, xAlign or "left", yAlign or "top")
                end
            end
            self.tUISpriteSheets[spriteSheetPath] = rSpriteSheet
        end
        self.tTextureToSpriteSheet[sTextureName] = self.tUISpriteSheets[spriteSheetPath]
    end

    function Ob:unloadUISpriteSheets()
        if self.tUISpriteSheets then
            for sPathName, rSpriteSheet in pairs(self.tUISpriteSheets) do            
                DFGraphics.unloadSpriteSheet(sPathName)
            end
            self.tUISpriteSheets = nil
        end
    end

    function Ob:getSpriteSheetForTexture(sTextureName)
        if sTextureName then
            return self.tTextureToSpriteSheet[sTextureName]
        end
    end
    
    function Ob:_addDimsFuncs(rProp)
        rProp._inBounds = function(self,wx,wy)
            local w,h = self:getDims()
            local x,y = self:modelToWorld(0,0)
            if wx > x and wx < x+w then
                if h < 0 then
                    return wy < y and wy > y+h
                else
--                    return wy < y+h and wy > y
                    return wy < y and wy > y-h
                end
            end
            return false
        end
        
    end

    function Ob:getUITextureProp(sTextureName, rProp)
        assert(sTextureName and self.tTextureToSpriteSheet[sTextureName])
        local rSpriteSheet = self.tTextureToSpriteSheet[sTextureName]
        assertdev(rSpriteSheet.names[sTextureName])
        if not rProp then
            rProp = MOAIProp.new()
        end
        
        self:_addDimsFuncs(rProp)

        rProp:setDeck(rSpriteSheet)
        local idx = rSpriteSheet.names[sTextureName]
        rProp:setIndex(idx)
        rProp.deck = rSpriteSheet
        rProp.index = idx
        return rProp
    end

    function Ob:setTemplateUITexture(sElementName, sTextureName, sSpritesheetPath)
        if sElementName and sTextureName and sSpritesheetPath then
            local rElement = self:getTemplateElement(sElementName)
            if rElement then
                self:addToUISpriteSheets(sTextureName, sSpritesheetPath)
                local rSpriteSheet = self.tTextureToSpriteSheet[sTextureName]
                if rSpriteSheet and rSpriteSheet.names[sTextureName] then
                    rElement = self:getUITextureProp(sTextureName, rElement)
                    self.tTemplateElements[sElementName] = rElement
                    return true
                else
                    Print(TT_Error, 'setTemplateUITexture: Could Not Find '.. tostring(sTextureName))
                end
            end
        end
        return false
    end

    function Ob:addOnePixel(hAlign,vAlign)
        local prop = MOAIProp.new()
        prop.deck = Gui.rOnePixelDeck

        prop.getDims = function(self)
            local w,h = self:getScl()
            return w,-h
        end
        
        self:_addDimsFuncs(prop)
        prop:setDeck(Gui.rOnePixelDeck)
        if hAlign or vAlign then
            local x,y = 0,0
            if hAlign == 'center' then x = .5
            elseif hAlign == 'right' then x = 1 end
            if vAlign == 'center' then y = -.5
            elseif vAlign == 'bottom' then y = -1 end
            prop:setPiv(x,y)
        end
	    self:addElement(prop)
        return prop
    end

    function Ob:addRect(w, h, r,g,b,a)
        local box = self:addOnePixel()
        box:setScl(w,h)
        box:setColor(r,g,b,a)
        return box
    end

    --[[
    function Ob:addOverlayElement(rElement)
        if not self.tOverlayElements then 
            self.rOverlayRenderLayer = Renderer.getRenderLayer('UIOverlay')
            self.tOverlayElements = {} 
        end
        table.insert(self.tOverlayElements, rElement)
        MiscUtil.setTransformVisParent(rElement,self.Parent)
        if self.elementsVisible then
            self.rOverlayRenderLayer:insertProp(rElement)
            rElement:setPriority(self.currentBasePri+#self.tOverlayElements)
        end
    end
    ]]--

    function Ob:addTextToTexture(str, textureProp, styleName, hAlign, vAlign, hMargin, vMargin)
        local sclX,sclY = textureProp:getScl()
        local tb = Gui.createTextBox(styleName, hAlign, vAlign)
        MiscUtil.setTransformVisParent(tb,textureProp)
        local x0,y0,x1,y1
        if textureProp.deck == Gui.rOnePixelDeck then
            x0,y0,x1,y1= 0,-1,1,0
        else
            x0,y0,x1,y1= textureProp.deck:getRect(textureProp.index)
        end
		local x,y = textureProp:getLoc()
        x0=x0*sclX+x
        x1=x1*sclX+x
        y0=y0*sclY+y
        y1=y1*sclY+y
        hMargin = hMargin or 10
        vMargin = vMargin or 5
        tb:setRect(x0+hMargin,y0-vMargin,x1-hMargin,y1-vMargin)
        tb:setString(str)
	    self:addElement(tb)
        return tb
    end

    --[[
    function Ob:addTextToProp(str, styleName, hAlign, vAlign)
        local tb = Gui.createTextBox(styleName, hAlign, vAlign)
        tb:setRect(x0,y0,x1,y1)
        tb:setString(str)
	    tb:setLoc(x,y)
	    self:addElement(tb)
        return tb
    end
    ]]--

    function Ob:addTextBox(str, styleName, x0,y0,x1,y1, x, y, hAlign, vAlign)
        local tb = Gui.createTextBox(styleName, hAlign, vAlign)
        if x0 and y0 and x1 and y1 then
            tb:setRect(x0,y0,x1,y1)
        end
        tb:setString(str)
	    tb:setLoc(x,y)
	    self:addElement(tb)
        return tb
    end

	function Ob:addTexture(spriteName,x,y)
        local elem = self:getUITextureProp(spriteName)
        elem:setLoc(x,y)
        self:addElement(elem)
        return elem
    end

	function Ob:addFullScreenTexture(spriteName, bPreserveAR)
        local elem = self:getUITextureProp(spriteName)
        elem:setLoc(0, 0)
        local w,h = DFGraphics.getFullSpriteDims(elem.deck,spriteName)

        local sw,sh = kVirtualScreenWidth/w, kVirtualScreenHeight/h
        if bPreserveAR then
            sw = math.min(sw,sh)
            sh = sw
        end
        elem:setScl(sw,sh)
        self:addElement(elem)
        return elem
    end

	function Ob:addElement(rElement, bKeepHidden)
        if not self.tElements then 
            self.tElements = {} 
            self.tElementsR = {} 
        end
        
        table.insert(self.tElements, rElement)
        self.tElementsR[rElement] = #self.tElements
        rElement.rParentUIElement = self
        MiscUtil.setTransformVisParent(rElement,self)
        if self.elementsVisible and not bKeepHidden then
            self:_setElementVisible(rElement, true, self.currentBasePri+#self.tElements)
        end
	end

    function Ob:removeElement(rElement)
            for i, rExistingElement in ipairs(self.tElements) do
                if rElement == rExistingElement then
                    self:_setElementVisible(rElement, false)
                    table.remove(self.tElements, i)
                    self.tElementsR[rElement] = nil
                    rElement.rParentUIElement = nil
                    return
                end
            end
    end

    function Ob:setElementHidden(elem, bHidden)
        elem.hideOverride = bHidden
        if elem.isUIElement then
            if bHidden then
                if elem.elementsVisible ~= false then
                    elem:hide()
                end
            elseif self.elementsVisible then
                if elem.elementsVisible ~= true then
                    elem:show()
                end
            end
        else
            if bHidden then
                Renderer.getRenderLayer(self:getRenderLayerName()):removeProp(elem)
            elseif self.elementsVisible then
                local sRenderLayerName = self:getRenderLayerName()
                if elem.sElementLayerOverride then
                    sRenderLayerName = elem.sElementLayerOverride
                end
                Renderer.getRenderLayer(sRenderLayerName):insertProp(elem)
            end
        end
    end

	function Ob:_setElementVisible(rElement, bVisible, basePri)
        basePri = basePri or 0
        
        if not rElement then
            return basePri
        end

		if bVisible then
            if rElement.isUIElement then
                if rElement.hideOverride then 
                    return basePri
                else
                    return rElement:show(basePri)+1
                end
            else       
                local sRenderLayerName = self:getRenderLayerName()
                if rElement.sElementLayerOverride then
                    sRenderLayerName = rElement.sElementLayerOverride
                end
                if not rElement.hideOverride then Renderer.getRenderLayer(sRenderLayerName):insertProp(rElement) end
				if rElement.setPriority then
					rElement:setPriority(basePri)
				end
                return basePri + 1
            end
		else
            if rElement.isUIElement then
                rElement:hide(true)
            else
                local sRenderLayerName = self:getRenderLayerName()
                if rElement.sElementLayerOverride then
                    sRenderLayerName = rElement.sElementLayerOverride
                end                
                Renderer.getRenderLayer(sRenderLayerName):removeProp(rElement)
            end
		end
	end

    function Ob:_applyResizeChanges(rElement, tElementInfo)
        if tElementInfo then
            if tElementInfo.pos then
                local x = self:_convertLayoutVal(tElementInfo.pos[1])
                local y = self:_convertLayoutVal(tElementInfo.pos[2])
                if rElement.tPosInfo then
                    if rElement.tPosInfo.offsetX then
                        x = x + rElement.tPosInfo.offsetX
                    end
                    if rElement.tPosInfo.offsetY then
                        y = y + rElement.tPosInfo.offsetY
                    end
                end

                rElement:setLoc(x,y)
            end
            if tElementInfo.scale then
                local nScaleX = self:_convertLayoutVal(tElementInfo.scale[1])
                local nScaleY = self:_convertLayoutVal(tElementInfo.scale[2])
                rElement:setScl(nScaleX, nScaleY)
            end
            if tElementInfo.rect then
                rElement.tTemplateRect[1] = self:_convertLayoutVal(tElementInfo.rect[1])
                rElement.tTemplateRect[2] = self:_convertLayoutVal(tElementInfo.rect[2])
                rElement.tTemplateRect[3] = self:_convertLayoutVal(tElementInfo.rect[3])
                rElement.tTemplateRect[4] = self:_convertLayoutVal(tElementInfo.rect[4])
                rElement:setRect(unpack(rElement.tTemplateRect))
            end
        end
    end
    
    function Ob:_applyTemplateInfo(rElement, tElementInfo)
        if tElementInfo then
            -- save out the elementinfo
            if not rElement.tSavedElementInfo then
                rElement.tSavedElementInfo = {}
            end
            for key, val in pairs(tElementInfo) do
                rElement.tSavedElementInfo[key] = val
            end
            
            if tElementInfo.clickWhileHidden ~= nil then
                rElement.clickWhileHidden=tElementInfo.clickWhileHidden
            end
            
            if tElementInfo.layerOverride then
                if rElement.isUIElement then
                    rElement:setRenderLayer(tElementInfo.layerOverride)
                else
                    rElement.sElementLayerOverride = tElementInfo.layerOverride
                end
            end
            if tElementInfo.pos then
                local nPosX = self:_convertLayoutVal(tElementInfo.pos[1])
                local nPosY = self:_convertLayoutVal(tElementInfo.pos[2])
                rElement:setLoc(nPosX, nPosY)
            end
            if tElementInfo.scale then
                local nScaleX = self:_convertLayoutVal(tElementInfo.scale[1])
                local nScaleY = self:_convertLayoutVal(tElementInfo.scale[2])
                rElement:setScl(nScaleX, nScaleY)
            end
            if tElementInfo.color then
                rElement:setColor(tElementInfo.color[1], tElementInfo.color[2], tElementInfo.color[3], tElementInfo.color[4])
            end
            if tElementInfo.rot then
                rElement:setRot(tElementInfo.rot[1], tElementInfo.rot[2], tElementInfo.rot[3])
            end
            if rElement.setVisible then
                if tElementInfo.hidden ~= nil then
                    self:setElementHidden(rElement,tElementInfo.hidden)
                    --[[
                    if tElementInfo.hidden then
                        rElement:setVisible(false)
                    else
                        rElement:setVisible(true)
                    end
                    ]]--
                end
            end
            if tElementInfo.sNestedInfo then
                rElement:processUIInfo(tElementInfo.sNestedInfo)
            end
            if tElementInfo.tNestedInfo then
                rElement:_processUIInfoTable(tElementInfo.tNestedInfo)
            end
            if tElementInfo.bDoRolloverCheck then
                rElement.bDoRolloverCheck = true
            end
            if tElementInfo.rect then
                rElement.tTemplateRect = {}
                rElement.tTemplateRect[1] = self:_convertLayoutVal(tElementInfo.rect[1])
                rElement.tTemplateRect[2] = self:_convertLayoutVal(tElementInfo.rect[2])
                rElement.tTemplateRect[3] = self:_convertLayoutVal(tElementInfo.rect[3])
                rElement.tTemplateRect[4] = self:_convertLayoutVal(tElementInfo.rect[4])
                rElement:setRect(unpack(rElement.tTemplateRect))
            end
            if rElement.tTemplateElements then
                if not self.tTemplateElements then
                    self.tTemplateElements = {}
                end
                for s,t in pairs(rElement.tTemplateElements) do
                    self.tTemplateElements[tElementInfo.key..'_'..s] = t
--                    print('added ',tElementInfo.key..'_'..s)
                end
            end
        end
    end

    function Ob:applyTemplateInfos(tInfos)
        if tInfos and self.tTemplateElements then
            for i, tElementInfo in ipairs(tInfos) do
                local rElement = self.tTemplateElements[tElementInfo.key]
                if rElement then
                    self:_applyTemplateInfo(rElement, tElementInfo)
                end
            end
        end
    end

    function Ob:_addTemplateElement(sElementName, tElementInfo)
        if not self.tTemplateElements then
            self.tTemplateElements = {}
        end
        if sElementName and tElementInfo and tElementInfo.type then
            local rElement = nil
            if tElementInfo.type == 'uiTexture' then
                if tElementInfo.textureName and tElementInfo.sSpritesheetPath then    
                    self:addToUISpriteSheets(tElementInfo.textureName, tElementInfo.sSpritesheetPath,tElementInfo.hAlign,tElementInfo.vAlign)
                    rElement = self:addTexture(tElementInfo.textureName)
                    if rElement then
                        self.tTemplateElements[sElementName] = rElement
                    else
                        print("ERROR(UI): Could not load UI texture "..tElementInfo.textureName)
                    end
                end
			elseif tElementInfo.type == 'uiTextureSingle' then
				if tElementInfo.path and tElementInfo.rect and tElementInfo.pos then
					local quad = MOAIGfxQuad2D.new()
					quad:setTexture('Texture/'..tElementInfo.path)
					quad:setRect(unpack(tElementInfo.rect))
					local rProp = MOAIProp2D.new()
					rProp:setDeck(quad)
					Renderer.getRenderLayer(self:getRenderLayerName()):insertProp(rProp)
					if tElementInfo.scale then
						rProp:setScl(unpack(tElementInfo.scale))
					end
					rProp:setVisible(true)
					rProp:setLoc(unpack(tElementInfo.pos))
					if rProp then
						rProp:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self, MOAITransform.TRANSFORM_TRAIT)
						self.tTemplateElements[sElementName] = rProp
					else
						print("UIElement:_addTemplateElement() uiTextureSingle - unable to load texture: "..tElementInfo.path)
					end
				end
            elseif tElementInfo.type == 'textBox' then
                if tElementInfo.style then
                    local sString = ''
                    if tElementInfo.text then
                        sString = tElementInfo.text
                    elseif tElementInfo.linecode then
                        sString = g_LM.line(tElementInfo.linecode)
                    end
                    rElement = self:addTextBox(sString, tElementInfo.style, nil, nil, nil, nil, 0, 0, tElementInfo.hAlign, tElementInfo.vAlign)
                    rElement.sText = sString
                    self.tTemplateElements[sElementName] = rElement
                else
                    print("ERROR(UI): Need to specify text and style for "..sElementName)
                end
            elseif tElementInfo.type == 'tabbedPane' then
                rElement = require('UI.TabbedPane').new()
                rElement.bDoRolloverCheck = true
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement            
            elseif tElementInfo.type == 'onePixel' then
                rElement = self:addOnePixel(tElementInfo.hAlign,tElementInfo.vAlign)
                self.tTemplateElements[sElementName] = rElement
            elseif tElementInfo.type == 'onePixelButton' then
                local rClass = g_GuiManager.getTemplateElementClass('OnePixelButton')
                rElement = rClass.new()
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement
                rElement.bDoRolloverCheck = true
            elseif tElementInfo.type == 'progressBar' then
                local rClass = g_GuiManager.getTemplateElementClass('ProgressBar')
                rElement = rClass.new()
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement
            elseif tElementInfo.type == 'templateButton' then
                local rClass = g_GuiManager.getTemplateElementClass('TemplateButton')
                rElement = rClass.new()
                rElement.tElementInfo = tElementInfo
                if tElementInfo.replacements then
                    for k,v in pairs(tElementInfo.replacements) do
                        rElement:setReplacements(k,v)
                    end
                end
                if tElementInfo.layoutFile then
                    rElement:setLayoutFile(tElementInfo.layoutFile)
                end
                if tElementInfo.buttonName then
                    rElement:setButtonName(tElementInfo.buttonName)
                end
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement
                rElement.bDoRolloverCheck = true
            elseif tElementInfo.type == 'textureButton' then
                local rClass = g_GuiManager.getTemplateElementClass('TextureButton')
                rElement = rClass.new()
                rElement:setTextures(tElementInfo) --.textureName, tElementInfo.sSpritesheetPath)
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement
                rElement.bDoRolloverCheck = true
            elseif tElementInfo.type == 'scrollPane' then
                rElement = require('UI.ScrollableUI').new()
                if tElementInfo.scissorLayerName then
                    rElement:setScissorLayer(tElementInfo.scissorLayerName)
                end
                self:addElement(rElement)
                rElement.bDoRolloverCheck = true
                self.tTemplateElements[sElementName] = rElement
            elseif tElementInfo.type == 'slider' then
                rElement = require('UI.SliderUI').new(tElementInfo.configKey)
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement
                if rElement.onTick then self.tTickElements[sElementName] = rElement end
            elseif tElementInfo.type == 'checkbox' then
                rElement = require('UI.CheckboxUI').new(tElementInfo.configKey)
                self:addElement(rElement)
                self.tTemplateElements[sElementName] = rElement
            end
            if rElement then
                if tElementInfo.bothMouseEvents ~= nil then
                    rElement:setGenerateBothEvents(tElementInfo.bothMouseEvents)
                end
                rElement.sKey = sElementName
                rElement.tElementInfo = tElementInfo
                self:_applyTemplateInfo(rElement, tElementInfo)
            end
        end
    end

    function Ob:getTemplateElement(sElementName)
        if sElementName and self.tTemplateElements then
            return self.tTemplateElements[sElementName]
        end
        return nil
    end

    function Ob:alignToPosInfo()
    
        if not self.tPosInfo then 
            return 
        end
        
        local tPosInfo = self.tPosInfo or {}
        
        
            local x = 0
            local y = 0
            -- MTF: align right or center or bottom with anything with a parent is kind of bad.
            -- It grabs the parent's current pos and dims, but probably doesn't update properly.
            -- You probably shouldn't use it.
            if tPosInfo.alignX then
                if tPosInfo.alignX == 'right' then
                    if self.rParentUIElement then
                        local px,py = self.rParentUIElement:getLoc()
                        local pw,ph = self.rParentUIElement:getDims()
                        x = px+pw
                    else
                        x = Renderer.getViewport().sizeX
                    end
                elseif tPosInfo.alignX == 'left' then                        
                    x = 0
                elseif tPosInfo.alignX == 'center' then
                    if self.rParentUIElement then
                        local px,py = self.rParentUIElement:getLoc()
                        local pw,ph = self.rParentUIElement:getDims()
                        x = px+pw*.5
                    else
                        x = math.floor(Renderer.getViewport().sizeX / 2)
                    end
                end
            end
            if tPosInfo.alignY then
                if tPosInfo.alignY == 'top' then
                    y = 0
                elseif tPosInfo.alignY == 'bottom' then
                    if self.rParentUIElement then
                        local px,py = self.rParentUIElement:getLoc()
                        local pw,ph = self.rParentUIElement:getDims()
                        y = -py+ph
                    else
                        y = -Renderer.getViewport().sizeY
                    end
                elseif tPosInfo.alignY == 'center' then
                    if self.rParentUIElement then
                        local px,py = self.rParentUIElement:getLoc()
                        local pw,ph = self.rParentUIElement:getDims()
                        y = -py+ph*.5
                    else
                        y = (0 - math.floor(Renderer.getViewport().sizeY / 2))
                    end
                end
            end      
            if tPosInfo.offsetX then
                x = x + tPosInfo.offsetX
            end
            if tPosInfo.offsetY then
                y = y + tPosInfo.offsetY
            end
            if tPosInfo.scale then
                self:setScl(tPosInfo.scale[1], tPosInfo.scale[2])
            end
            self:setLoc(x, y)
    end

    function Ob:processUIInfo(sUILayoutFileName)
        local tInfo = self:_loadUIInfoFile(sUILayoutFileName)

        return self:_processUIInfoTable(tInfo)
    end
    
    function Ob:_loadUIInfoFile(sUILayoutFileName)
        if not sUILayoutFileName then return end

        sUILayoutFileName = DFFile.getDataPath(sUILayoutFileName..'.lua')
        local tInfo = dofile(sUILayoutFileName)

        if not tInfo then 
            Print(TT_Error, 'No layout data from file: '..sUILayoutFileName..'.lua')
            return
        end

        self.sUILayoutFileName = sUILayoutFileName
        
        return tInfo
    end

    function Ob:setReplacements(sElemKey, tReplacements)
        if not self.tElementInfoReplacements then
            self.tElementInfoReplacements = {}
        end
        self.tElementInfoReplacements[sElemKey] = tReplacements
        -- already processed. modify tElements directly.
        --[[
        if self.isUIElement and tInfo.tElements then
            local tExisting = nil
            for i, tElementInfo in ipairs(tInfo.tElements) do
                if tElementInfo.key == sElemKey then
                    tExisting = tElementInfo
                end
            end
            if not tExisting then
                tExisting = {}
                table.insert(tInfo.tElements,tExisting)
            end
            for k,v in pairs(self.tElementInfoReplacements[sElemKey]) do
                tExisting[k] = v
            end
            if self.refresh then 
                self:refresh()
            end
        end
        ]]--
    end

    function Ob:_processUIInfoTable(tInfo)
        if tInfo.posInfo then
            self.tPosInfo = tInfo.posInfo
            self:alignToPosInfo()    
        end
        if tInfo.tElements then
            for i, tElementInfo in ipairs(tInfo.tElements) do
                if self.tElementInfoReplacements and self.tElementInfoReplacements[tElementInfo.key] then
                    for k,v in pairs(self.tElementInfoReplacements[tElementInfo.key]) do
                        tElementInfo[k] = v
                    end
                end
                self:_addTemplateElement(tElementInfo.key, tElementInfo)
            end
        end
        if tInfo.tExtraInfo then
            self.tExtraTemplateInfo = tInfo.tExtraInfo
        end
    end

    -- convert values into numbers
    -- if the values are strings, they are assumed to be lua commands always eval to a number
    function Ob:_convertLayoutVal(val)
        local nRet = 0
        if type(val) == 'number' then
            nRet = val
        elseif type(val) == 'string' then
            local fn = loadstring('return '..val)
            if fn then
                local nTempVal = fn()
                if type(nTempVal) == 'number' then
                    nRet = math.floor(nTempVal)
                end
            end
        end
        return nRet
    end

    function Ob:_calcDimsFromElements(tOptionalElementArray)
        local tElements = tOptionalElementArray or self.tElements or {}
        local w,h = 0,0
        for _, v in ipairs(tElements) do
            local ex,ey = v:getLoc()
            local ew,eh = v:getDims()
            w = math.max(w,ex+ew)
            h = math.min(h,ey+eh)
        end
        self.uiWidth = w
        self.uiHeight = h
    end
    
    -- MTF TODO: height is negative because everything is terrible.
    function Ob:getDims()
        return self.uiWidth,self.uiHeight
    end
    
    function Ob:getExtraTemplateInfo(sInfoKey)
        if self.tExtraTemplateInfo and sInfoKey then
            return self.tExtraTemplateInfo[sInfoKey]
        end
    end

    function Ob:setPosInfo(tPosInfo)
        if not tPosInfo then 
            return 
        end
        
        self.tPosInfo = tPosInfo
        self:alignToPosInfo()
    end

    function Ob:onFileChange(path)    
        -- reprocess the template ui elements
        if self.sUILayoutFileName and path == self.sUILayoutFileName then
            print("RELOADING "..path)
            local tInfo = dofile(self.sUILayoutFileName)
            if not tInfo then
                print("ERROR: Could not reload "..self.sUILayoutFileName)
                return
            end
            if tInfo.posInfo then
                self.tPosInfo = tInfo.posInfo
                self:alignToPosInfo()                    
            end
            if self.tTemplateElements then 
                if tInfo.tElements then
                    for i, tElementInfo in ipairs(tInfo.tElements) do

                        local sElementName = tElementInfo.key
                        local rElement = self.tTemplateElements[sElementName]
                        if not rElement then
                            return
                        end
                        if tElementInfo.tTemplateRect then
                            rElement:setRect(unpack(tElementInfo.tTemplateRect))
                        end
                        if tElementInfo.type then
                            --if tElementInfo.type == 'uiTexture' then                            
                                -- let's not hotreload textures.  doesn't seem necessary
                            if tElementInfo.type == 'textBox' then
                                local sString = ''
                                if tElementInfo.text then
                                    sString = tElementInfo.text
                                elseif tElementInfo.linecode then
                                    sString = g_LM.line(tElementInfo.linecode)
                                end
                                rElement:setString(sString)
                                rElement:setAlignment(tElementInfo.hAlign or MOAITextBox.LEFT_JUSTIFY,tElementInfo.vAlign or MOAITextBox.LEFT_JUSTIFY)
                            end
                        end

                        self:_applyTemplateInfo(rElement, tElementInfo)
                    end
                end
                if tInfo.tExtraInfo then
                    self.tExtraTemplateInfo = tInfo.tExtraInfo
                end
            end
        end
        if self.tElements then
            for i, rElement in pairs(self.tElements) do
                if rElement.onFileChange then
                    rElement:onFileChange(path)
                end
            end
        end
    end

    -- MTF HACK/WEIRD
    -- "inside" is saying that's where the pointer is, and triggers hover etc.
    -- "_inBounds" is a simple query re: whether something's in your bounds.
    function Ob:_inBounds(wx,wy)
        local w,h = self:getDims()
        local x,y = self:modelToWorld(0,0)
            if wx > x and wx < x+w then
                if h < 0 then
                    return wy < y and wy > y+h
                else
                    return wy < y+h and wy > y
                end
            end
        return false
    end

    function Ob:inside(wx, wy, tElemListOverride)
        if not self.elementsVisible then return false end
        
        local bInside = false
--        local tElems = tElemListOverride or self.tTemplateElements
        local tElems = tElemListOverride or self.tElements
        if tElems then
            for i, rElement in pairs(tElems) do
--                if rElement.bDoRolloverCheck and rElement.inside then
                if rElement.inside and (not rElement.hideOverride or rElement.clickWhileHidden) then
                    if rElement:inside(wx, wy) then
                        bInside = true
                    end
                end
            end
        end
        return bInside
    end

    function Ob:onFinger(touch, x, y, props, tElemListOverride)
        if not self.elementsVisible then return false end

--        local tElems = tElemListOverride or self.tTemplateElements
        local tElems = tElemListOverride or self.tElements
        
        local bHandled = false
        if tElems then
            for i, rElement in pairs(tElems) do
                if (not rElement.hideOverride or rElement.clickWhileHidden) and rElement.onFinger and rElement:onFinger(touch, x, y, props) then
                    bHandled = true
                end
            end            
        end
        return bHandled
    end

    function Ob:onResize()
        self:alignToPosInfo()
        -- reapply all the scale and positions for the elements
        
        if self.tTemplateElements then
            for i, rElement in pairs(self.tTemplateElements) do
                if rElement.alignToPosInfo then rElement:alignToPosInfo() end
                if rElement.tSavedElementInfo then
                    self:_applyResizeChanges(rElement, rElement.tSavedElementInfo)
                end
            end
        end
        
    end
    
    function Ob:moveProp(rProp, x, y, t, delay, callback)
        x,y,t,delay = x or 0, y or 0, t or 1, delay or 0
        delay = math.max(delay, 0)
        local tNew = { currentTime = 0, sType = "Move", delay=delay, callback=callback }
        tNew.endX,tNew.endY,tNew.totalTime = x,y,t
        tNew.startX,tNew.startY = rProp:getLoc()
        self.tAnimatingObjects[rProp] = tNew

--[[    if self.tMovingObjects[rProp] then
        else
        end ]]--
    end
    
    function Ob:colorProp(rProp, tStartColor, tEndColor, t, delay, callback)
        tStartColor, tEndColor, t, delay = tStartColor or Gui.WHITE, tEndColor or Gui.WHITE, t or 1, delay or 0
        delay = math.max(delay, 0)
        local tNew = { currentTime = 0, sType = "Color", delay=delay, callback=callback }
        tNew.tStartColor,tNew.tEndColor,tNew.totalTime = tStartColor,tEndColor,t
        self.tAnimatingObjects[rProp] = tNew
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
