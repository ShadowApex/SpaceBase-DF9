local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local DFFile = require('DFCommon.File')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local GameRules = require('GameRules')
local SoundManager = require('SoundManager')
local runLoadSave = require('UI.LoadSave')

local sUILayoutFileName = 'UILayouts/StartMenuLayout'

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    Ob.spriteSheet = "UI/StartMenu"
    
    function Ob:init()
        Ob.Parent.init(self)
        
        self.rMOTDTask = MOAIHttpTaskCurl.new()
        self.rMOTDTask:setCallback(function(rHTTPTask, nResponseCode) self:onMOTDTaskFinished(rHTTPTask, nResponseCode) end)

        self:setRenderLayer("UIOverlay")

        self:processUIInfo(sUILayoutFileName)
		
		-- read a const from layout data so we don't have same # in many places
		self.nMOTDX = self:getExtraTemplateInfo('nMOTDX')
        self:refreshMOTD()
		
        --self.logo = self:getTemplateElement('Logo')
        self.uiBG = self:getTemplateElement('Background')
        self.uiBG:setScl( Renderer.getViewport().sizeX * 2, Renderer.getViewport().sizeY * 2 )
        self.uiBG:setLoc( -Renderer.getViewport().sizeX * .5, Renderer.getViewport().sizeY * .5 )
        
        -- buttons
        self.rButtonWebsite = self:getTemplateElement('ButtonWebsite')
        self.rButtonWebsite:addPressedCallback(self.onWebsitePressed, self)
        self.rButtonResume = self:getTemplateElement('ButtonResume')
        self.rButtonResume:addPressedCallback(self.onResumePressed, self)
        self.rButtonNewGame = self:getTemplateElement('ButtonNewGame')
        self.rButtonNewGame:addPressedCallback(self.startNew, self)
        self.rButtonTutorial = self:getTemplateElement('ButtonTutorial')
        self.rButtonTutorial:addPressedCallback(self.startTutorial, self)
		self.rButtonLoadAndSave = self:getTemplateElement('ButtonLoadAndSave')
        self.rButtonLoadAndSave:addPressedCallback(self.loadSave, self)
        self.rButtonSettings = self:getTemplateElement('ButtonSettings')
        self.rButtonSettings:addPressedCallback(self.openSettings, self)
        self.rButtonCredits = self:getTemplateElement('ButtonCredits')
        self.rButtonCredits:addPressedCallback(self.openCredits, self)
        self.rButtonQuit = self:getTemplateElement('ButtonQuit')
        self.rButtonQuit:addPressedCallback(self.quit, self)
        self.rButtonQuitOnly = self:getTemplateElement('ButtonQuitOnly')
        self.rButtonQuitOnly:addPressedCallback(self.quitOnly, self)

	
    end

    function Ob:onTick(dt)
        Ob.Parent.onTick(self, dt)
        if self.credits then self.credits:onTick(dt) end
        if self.settings then self.settings:onTick(dt) end
    end

    function Ob:refreshMOTD()
        if DFSpace.isDev() then
            local sPath = DFFile.getDataPath("UILayouts/motd-test.json")
            local f = io.open(sPath, "r")
            local sJson = f:read("*a")
            f:close()
            self:setupMOTD(sJson)
        else
            local sMOTDURL = 'http://blog.spacebasedf9.com/motd/motd.txt'
            self.rMOTDTask:httpGet(sMOTDURL)
        end
    end

    function Ob:playWarbleEffect(bFullscreen)
        if bFullscreen then
            local uiX,uiY,uiW,uiH = Renderer.getUIViewportRect()            
            g_GuiManager.createEffectMaskBox(0, 0, uiW, uiH, 0.3)
        else
            g_GuiManager.createEffectMaskBox(0, 0, 500, 1444, 0.3, 0.3)
        end
    end    


    function Ob:onFinger(eventType, x, y, props)
        return Ob.Parent.onFinger(self, eventType, x, y, props)
    end

    function Ob:inside(wx, wy)
        return Ob.Parent.inside(self, wx, wy)
    end

    function Ob:onKeyboard(key, bDown)
        -- capture all keyboard input
        if bDown and key == 27 then -- esc
            g_GuiManager.startMenu:resume(false)
        end
        return true
    end

    function Ob:onFileChange(path)
        Ob.Parent.onFileChange(self, path)

        self:refreshMOTD()
        
        self.uiBG:setScl( Renderer.getViewport().sizeX * 2, Renderer.getViewport().sizeY * 2 )
        self.uiBG:setLoc( -Renderer.getViewport().sizeX * .5, Renderer.getViewport().sizeY * .5 )        
    end

    function Ob:onWebsitePressed(rEnt, button, eventType)
        MOAIOpenInBrowser.openInBrowser('http://spacebasedf9.com/')
        g_GuiManager.updateHoverTarget()
    end
    
    function Ob:onResumePressed(rEnt, button, eventType)
        SoundManager.playSfx('select')
        self:resume(false)
    end

    function Ob:resume(bInMenu)
        g_GuiManager.startMenuActive = false
        if not bInMenu then
            Gui.setActivePane(nil)
--[[
            local nPri = g_GuiManager.basePri
            nPri = g_GuiManager.statusBar:show(nPri)
            nPri = g_GuiManager.newSideBar:show(nPri)
            nPri = g_GuiManager.hintPane:show(nPri)
            nPri = g_GuiManager.alertPane:show(nPri)
            g_GuiManager.snapAlertPos()
    ]]--
            if not self.bWasPaused then
                GameRules.togglePause()
            end
        else
            self:hide(true)
        end
        g_GuiManager.refresh()        
    end
    
    function Ob:setFirstTime()
        self.bFirstTime = true
    end

    function Ob:onMOTDTaskFinished(rHTTPTask, nResponseCode)
        if nResponseCode == 200 then
            local sJson = rHTTPTask:getString()
            self:setupMOTD(sJson)
        else
            -- if http request failed, fall back to motd-test file
            local sPath = DFFile.getDataPath("UILayouts/motd-test.json")
            local f = io.open(sPath, "r")
            local sJson = f:read("*a")
            f:close()
            self:setupMOTD(sJson)
        end
    end

    function Ob:setupMOTD(sJson)
        local tData = MOAIJsonParser.decode(sJson)
        if not tData then
            assertdev(false)
            return
        end

        -- set up paragraphs
        local tTextBoxTemplateInfo = {
            key = 'MOTDText',
            type = 'textBox',
            pos = { self.nMOTDX, 35 },
            text = "TEXT",
            style = 'dosismedium32',
            rect = { 0, 500, 940, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        }
        for nIdx, tBodyData in ipairs(tData.body) do
            local sElementName = "MOTDParagraph" .. nIdx
            local rElement = self:getTemplateElement(sElementName)
            if rElement then
                rElement:setString(tBodyData.text)
                local x, y, z = rElement:getLoc()
                rElement:setLoc(x, tBodyData.y, z)
            else
                local tNewElementData = DFUtil.deepCopy(tTextBoxTemplateInfo)
                tNewElementData.text = tBodyData.text
                tNewElementData.pos[2] = tBodyData.y
                tNewElementData.key = sElementName
                self:_addTemplateElement(sElementName, tNewElementData)
            end
        end

        -- set up the footer
        if tData.footer then
            local tFooterTextInfo = {
                key = 'MOTDFooterText',
                type = 'textBox',
                pos = { self.nMOTDX, 35 },
                text = "TEXT",
                style = 'dosissemibold32',
                rect = { 0, 100, 940, 0 },
                hAlign = MOAITextBox.LEFT_JUSTIFY,
                vAlign = MOAITextBox.LEFT_JUSTIFY,
                color = Gui.AMBER,
            }
            local tFooterButtonInfo = {
                key = 'MOTDFooterButton',
                type = 'onePixelButton',
                pos = { self.nMOTDX, 35 },
                scale = { 740, 40 },
                color = Gui.AMBER,
                hidden = true,
                clickWhileHidden=true,
                onHoverOn =
                {
                    {
                        key = 'MOTDFooterText',
                        color = Gui.BRIGHT_AMBER,
                    },
                    {
                        playSfx = 'hilight',
                    },
                },
                onHoverOff =
                {
                    {
                        key = 'MOTDFooterText',
                        color = Gui.AMBER,
                    },
                },
            }
            local sFooterTextName = "MOTDFooterText"
            if tData.footer.text then
                local rFooterText = self:getTemplateElement(sFooterTextName)
                if rFooterText then
                    rFooterText:setString(tData.footer.text)
                    local x, y, z = rFooterText:getLoc()
                    rFooterText:setLoc(x, tData.footer.y, z)
                else
                    local tNewElementData = DFUtil.deepCopy(tFooterTextInfo)
                    tNewElementData.text = tData.footer.text
                    tNewElementData.pos[2] = tData.footer.y
                    tNewElementData.key = sFooterTextName
                    self:_addTemplateElement(sFooterTextName, tNewElementData)
                end
            end
            if tData.footer.url then

                local callback = function()
                    MOAIOpenInBrowser.openInBrowser(tData.footer.url)
                end

                local sFooterButtonName = "MOTDFooterButton"
                local rFooterButton = self:getTemplateElement(sFooterButtonName)
                if rFooterButton then
                    local x, y, z = rFooterButton:getLoc()
                    rFooterButton:setLoc(x, tData.footer.y, z)
                    local w, h, sz = rFooterButton:getScl()
                    rFooterButton:setScl(tData.footer.w, h, sz)
                else
                    local tNewElementData = DFUtil.deepCopy(tFooterButtonInfo)
                    tNewElementData.pos[2] = tData.footer.y
                    tNewElementData.scale[1] = tData.footer.w
                    tNewElementData.key = sFooterButtonName
                    tNewElementData.onHoverOn.key = sFooterTextName
                    tNewElementData.onHoverOff.key = sFooterTextName
                    self:_addTemplateElement(sFooterButtonName, tNewElementData)
                    -- hook up callback to footer buton
                    local rFooterButton = self:getTemplateElement(sFooterButtonName)
                    rFooterButton:addPressedCallback(callback)
                end
            end
        end
    end

    function Ob:startNew()
        --GameRules.reset()
        SoundManager.playSfx('select')
        self:resume(true)
        g_GuiManager.showNewBaseScreen()
    end
	
	function Ob:startTutorial()
		-- reset with no landing zone given + tutorial mode
		GameRules.bTutorialMode = true
		-- JPL TODO: show the loading screen?
		--g_GuiManager:fadeInCentered('LegalScreen')
		GameRules.reset()
	end
	
    function Ob:quit()
        SoundManager.playSfx('select')
        if g_GuiManager.newSideBar:isConstructMenuOpen() then
            g_GameRules.cancelBuild(true) -- let's cancel out any pending UNPAID construction
            g_GuiManager.newSideBar:closeConstructMenu()            
        end
        GameRules.saveGame()
        MOAISim.exit()
    end
	function Ob:quitOnly()
        SoundManager.playSfx('select')
        if g_GuiManager.newSideBar:isConstructMenuOpen() then
            g_GameRules.cancelBuild(true) -- let's cancel out any pending UNPAID construction
            g_GuiManager.newSideBar:closeConstructMenu()            
        end
        MOAISim.exit()
    end 
   
	function Ob:loadSave()
		SoundManager.playSfx('select')
        self.loadSave = runLoadSave.new()
        Gui.setActivePane(self.loadSave)
		print('TEEEEEEEEEST - loadSave: -------  ' .. tostring(self.loadSave))
	end
	
	
    function Ob:openCredits()
        SoundManager.playSfx('select')
        if not self.credits then self.credits = require('UI.Credits').new() end
        Gui.setActivePane(self.credits)
        --self.credits:show(self.maxPri)
    end
    
    function Ob:openSettings()
        SoundManager.playSfx('select')
        if not self.settings then self.settings = require('UI.AudioVideoSettings').new() end
		print('TEEEEEEEEEST settings: -------  ' .. tostring(self.settings))
        Gui.setActivePane(self.settings)
        --self.settings:show(self.maxPri)
    end
    
    function Ob:onResize()
        Ob.Parent.onResize(self)
        self.uiBG:setScl(Renderer.getViewport().sizeX*2,Renderer.getViewport().sizeY*2)
        self.uiBG:setLoc(-Renderer.getViewport().sizeX*.5,Renderer.getViewport().sizeY*.5)
        self:refresh()
    end

    function Ob:show(basePri)
        local pri = Ob.Parent.show(self,basePri)
        g_GuiManager.startMenuActive = true
        self:refresh()
        self:onResize()
        Renderer.setShowUI(false)
        return pri
    end

    function Ob:hide(bKeepAlive)
        Ob.Parent.hide(self,bKeepAlive)
        g_GuiManager.removeVersionProp()
        Renderer.setShowUI(true)
    end

    function Ob:refresh()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
