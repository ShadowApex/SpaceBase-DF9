local m = {}

local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local SquadList = require("SquadList")
local SquadEntry = require('UI.SquadEntry')
local SquadEditMenu = require("UI.SquadEditMenu")

local sUILayoutFileName = 'UILayouts/SquadLayout'

local tSquadNames = { 'SQUAD009TEXT', 'SQUAD010TEXT', 'SQUAD011TEXT', 'SQUAD012TEXT', 'SQUAD013TEXT', 'SQUAD014TEXT', 'SQUAD015TEXT', 'SQUAD016TEXT', 'SQUAD017TEXT', 'SQUAD018TEXT',}
local tUsedSquadNames = {}
local MAX_SQUADS = 10
local nSquadIndex = 1
local nSquadCount = 0


--
-- create randomised array of indexes
-- on use, check if it's already in use, if it is move on to next one
--

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local squadList
	local tSquadEntries = {}
	local rScrollableUI

    function Ob:init()
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
		self.rCreateButton = self:getTemplateElement('CreateButton')
		self.rCreateButton:addPressedCallback(self.onCreateButtonPressed, self)
		--self.tSquadEntries = {}
        rScrollableUI = self:getTemplateElement('ScrollPane')
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
		squadList = SquadList.new()
		math.randomseed(os.time())
		self:shuffleSquadNames()
		for k,v in ipairs(tSquadNames) do
			tUsedSquadNames[k] = false
		end
	end
	
	function Ob:shuffleSquadNames()
		local rand = math.random
		local iterations = #tSquadNames
		local j
		for i = iterations, 2, -1 do
			j = rand(i)
			tSquadNames[i], tSquadNames[j] = tSquadNames[j], tSquadNames[i]
		end
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
                SoundManager.playSfx('degauss')
            end
        end
    end
	
	function Ob:onCreateButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP  then
			self:createSquad()
		end
	end
	
	function Ob:createSquad()
		if nSquadCount < MAX_SQUADS then
			if tUsedSquadNames[nSquadIndex] then
				nSquadIndex = nSquadIndex + 1
				if nSquadIndex > MAX_SQUADS then 
					nSquadIndex = 1
				end
				self:createSquad()
				return
			end
			local name = g_LM.line(tSquadNames[nSquadIndex])
			tUsedSquadNames[nSquadIndex] = true
			local name2 = name..' '..g_LM.line('SQUAD001TEXT')
			squadList.addSquad(name2)
			local rNewEntry = self:addSquadEntry()
			rNewEntry:setName(name2, self.disbandCallback, self.editCallback, table.getn(tSquadEntries), nSquadIndex)
			rNewEntry:show()
			rScrollableUI:refresh()
			nSquadCount = nSquadCount + 1
		
		end
	end
	
	function Ob:disbandCallback(name, entriesIndex, nameIndex)
		squadList.remSquad(name)
		nSquadCount = nSquadCount - 1
		tUsedSquadNames[nameIndex] = false
		local entry = tSquadEntries[entriesIndex]
		entry:hide(true)
		rScrollableUI:removeScrollingItem(entry)
		table.remove(tSquadEntries, entriesIndex)
		for k, v in ipairs(tSquadEntries) do
			local w,h = v:getDims()
			local nYLoc = h * (k - 1) - 1
			v:setLoc(0, nYLoc)
			v:setIndex(k)
		end
		rScrollableUI:refresh()
	end
	
	function Ob:editCallback()
		SoundManager.playSfx('select')
        self.editCallback = SquadEditMenu.new()
		Ob.Parent.hide(self, bKeepAlive)
		self.editCallback:show()
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
        rScrollableUI:reset()
		-- hide status bar behind us
		g_GuiManager.statusBar:hide()
		g_GuiManager.tutorialText:hide()
		g_GuiManager.hintPane:hide()
		g_GuiManager.alertPane:hide()
        return nPri
    end
	
	-- function Ob:show()
		-- local w = g_GuiManager.getUIViewportSizeY()
		-- g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)
		-- self.bListDirty = true
		-- rScrollableUI:reset()
	-- end

    function Ob:hide(bKeepAlive)
        if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end
        Ob.Parent.hide(self, bKeepAlive)
		-- show status bar etc
		g_GuiManager.statusBar:show()
		g_GuiManager.tutorialText:show()
		g_GuiManager.hintPane:show()
		g_GuiManager.alertPane:show()
		g_GuiManager.hintPane:setMaximized(true)
		g_GuiManager.alertPane:setMaximized(true)
    end

    function Ob:addSquadEntry()
		local rNewEntry = SquadEntry.new()
        local nNumEntries = table.getn(tSquadEntries)
        
        local w,h = rNewEntry:getDims()
        local nYLoc = h * nNumEntries - 1
        
        rNewEntry:setLoc(0, nYLoc) -- assuming uniform Y size for entries

        self:_calcDimsFromElements()

        rScrollableUI:addScrollingItem(rNewEntry)
        table.insert(tSquadEntries, rNewEntry)
		return rNewEntry
	end

    function Ob:onTick(dt)
        
    end

    function Ob:onFinger(touch, x, y, props)
        local bHandled = false
        if rScrollableUI:onFinger(touch, x, y, props) then
            bHandled = true
        end
        if rScrollableUI:isInsideScrollPane(x, y) then
                   
        end
        if Ob.Parent.onFinger(self, touch, x, y, props) then
            bHandled = true
        end
        return bHandled
    end

    function Ob:inside(wx, wy)
        local bHandled = Ob.Parent.inside(self, wx, wy)
        rScrollableUI:inside(wx, wy)
             
        return bHandled
    end

    function Ob:onResize()
        Ob.Parent.onResize(self,true)
        rScrollableUI:onResize()
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
