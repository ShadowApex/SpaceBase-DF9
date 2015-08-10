local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local SquadEntry = require('UI.SquadEntry')
local SquadEditMenu = require('UI.SquadEditMenu')
local Squad = require('Squad')
local World = require('World')
local SquadList = require('SquadList')

local sUILayoutFileName = 'UILayouts/SquadLayout'

local tSquadNames = { 'SQUAD009TEXT', 'SQUAD010TEXT', 'SQUAD011TEXT', 'SQUAD012TEXT', 'SQUAD013TEXT', 'SQUAD014TEXT', 'SQUAD015TEXT', 'SQUAD016TEXT', 'SQUAD017TEXT', 'SQUAD018TEXT',}
local tUsedSquadNames = {}
local MAX_SQUADS = 10
local nSquadIndex = 1
local nSquadCount = 0

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local tSquadEntries = {}
	local rScrollableUI
	local menuManager
	local squadEditMenu
	local squadList = World.getSquadList()

    function Ob:init(_menuManager, _squadEditMenu)
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

		menuManager = _menuManager
		squadEditMenu = _squadEditMenu
        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
		self.rCreateButton = self:getTemplateElement('CreateButton')
		self.rCreateButton:addPressedCallback(self.onCreateButtonPressed, self)
        rScrollableUI = self:getTemplateElement('ScrollPane')
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
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
				menuManager.closeMenu()
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
			local newSquad = Squad.new(name..' '..g_LM.line('SQUAD001TEXT'))
			squadList.addSquad(newSquad.getName(), newSquad)
			local rNewEntry = self:addSquadEntry()
			rNewEntry:setSquad(newSquad, self.disbandCallback, self.editCallback, table.getn(tSquadEntries), nSquadIndex)
			rNewEntry:show()
			rScrollableUI:refresh()
			nSquadCount = nSquadCount + 1
		end
	end
	
	function Ob:disbandCallback(name, entriesIndex, nameIndex)
		squadList.disbandSquad(name)
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
	
	function Ob:editCallback(squad)
		squadEditMenu:setSquad(squad)
		menuManager.showMenu("SquadEditMenu")
	end
	
	function Ob:show(basePri)
		local w = g_GuiManager.getUIViewportSizeY()
		g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)
		self.bListDirty = true
		local nPri = Ob.Parent.show(self, basePri)
		self:updateDisplay()
		rScrollableUI:reset()
		return nPri
	end
	
	function Ob:hide(bKeepAlive)
		Ob.Parent.hide(self, bKeepAlive)
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
	
	function Ob:updateDisplay()
		for k,v in ipairs(tSquadEntries) do
			v:update()
		end
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
