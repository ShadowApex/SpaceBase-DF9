local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local ScrollableUI = require('UI.ScrollableUI')
local SoundManager = require('SoundManager')
local CharacterConstants = require('CharacterConstants')
local CharacterManager = require('CharacterManager')
local Character = require('Character')
local SquadEditEntry = require('UI.SquadEditEntry')
local Squad = require('Squad')

local sUILayoutFileName = 'UILayouts/SquadEditLayout'

local BUTTON_X_MEMBERS = 200 - 10
local BUTTON_X_AVAILABLE = 800 - 10

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	local rScrollableUI
	local squad
	local menuManager
	local rSquadEditMenuLabel
	local rAvailableCountLabel
	local rMembersCountLabel
	local tMemberEntries = {}
	local tAvailableEntries = {}
	local test = true

    function Ob:init(_menuManager)
        Ob.Parent.init(self)
    
        self:processUIInfo(sUILayoutFileName)

		menuManager = _menuManager
        self.rBackButton = self:getTemplateElement('BackButton')
        self.rBackButton:addPressedCallback(self.onBackButtonPressed, self)
		rSquadEditMenuLabel = self:getTemplateElement('SquadEditMenuLabel')
		rSquadEditMenuLabel:setString("ARRRRR!")
		rAvailableCountLabel = self:getTemplateElement('AvailableCountLabel')
		rMembersCountLabel = self:getTemplateElement('MembersCountLabel')
        rScrollableUI = self:getTemplateElement('ScrollPane')
        self.tHotkeyButtons = {}
        self:addHotkey(self:getTemplateElement('BackHotkey').sText, self.rBackButton)
	end
	
	function Ob:setSquad(_squad)
		squad = _squad
		if squad ~= nil then
			rSquadEditMenuLabel:setString(squad.getName())
			local squadMembers = squad.getMembers()
			for k,v in pairs(squadMembers) do
				self:addSquadMemberEntry(k, v)
			end
			if #squadMembers == 0 then
				rMembersCountLabel:setString(''..#tMemberEntries)
			end
		else
			rSquadEditMenuLabel:setString("Fail Squad")
		end
		rScrollableUI:refresh()
	end
	
	function Ob:loadCharacters()
		local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
		for k,v in ipairs(tChars) do
			if v:getJob() == CharacterConstants.EMERGENCY and v:getSquad() == nil then
				self:addAvailableEntry(v:getUniqueID(), v:getNiceName())
			end
		end
	end
	
	function Ob:addSquadMemberEntry(id, name)
		local rNewEntry = self:addEntry(#tMemberEntries + 1, BUTTON_X_MEMBERS)
		rNewEntry:setChar(id, name, self.onSquadMemberClickCallback)
		table.insert(tMemberEntries, rNewEntry)
		rMembersCountLabel:setString(''..#tMemberEntries)
	end
	
	function Ob:addAvailableEntry(id, name)
		local rNewEntry = self:addEntry(#tAvailableEntries + 1, BUTTON_X_AVAILABLE)
		rNewEntry:setChar(id, name, self.onAvailableClickCallback)
		table.insert(tAvailableEntries, rNewEntry)
		rAvailableCountLabel:setString(''..#tAvailableEntries)
	end
	
	function Ob:addEntry(index, x)
		local rNewEntry = SquadEditEntry.new()
		local w,h = rNewEntry:getDims()
        local nYLoc = h * index - 25
        rNewEntry:setLoc(x, nYLoc)
        self:_calcDimsFromElements()
        rScrollableUI:addScrollingItem(rNewEntry)
		return rNewEntry
	end
	
	function Ob:remSquadMemberEntry(rEntry)
		for k,v in ipairs(tMemberEntries) do
			if v == rEntry then
				v:hide()
				table.remove(tMemberEntries, k)
				self:resetEntryHeight(tMemberEntries, BUTTON_X_MEMBERS)
				rMembersCountLabel:setString(''..#tMemberEntries)
				return
			end
		end
		
	end
	
	function Ob:remAvailableEntry(rEntry)
		for k,v in ipairs(tAvailableEntries) do
			if v == rEntry then
				v:hide()
				table.remove(tAvailableEntries, k)
				self:resetEntryHeight(tAvailableEntries, BUTTON_X_AVAILABLE)
				rAvailableCountLabel:setString(''..#tAvailableEntries)
				return
			end
		end
	end
	
	function Ob:resetEntryHeight(tEntries, x)
		for k,v in ipairs(tEntries) do
			local w,h = v:getDims()
			local nYLoc = h * k - 25
			v:setLoc(x, nYLoc)
			self:_calcDimsFromElements()
		end
	end
	
	function Ob:onSquadMemberClickCallback(rEntry, id, name)
		Ob:remSquadMemberEntry(rEntry)
		Ob:addAvailableEntry(id, name)
		squad.remMember(id)
		local rChar = CharacterManager:getCharacterByUniqueID(id, true)
		if rChar then
			rChar:setSquad(nil)
		end
	end
	
	function Ob:onAvailableClickCallback(rEntry, id, name)
		Ob:remAvailableEntry(rEntry)
		for k,v in ipairs(tMemberEntries) do
			if v == rEntry then
				return
			end
		end
		Ob:addSquadMemberEntry(id, name)
		squad.addMember(id, name)
		local rChar = CharacterManager.getCharacterByUniqueID(id, true)
		if rChar == nil then
			print("SquadEditMenu:onAvailableClickCallback() Error: unable to retrieve character from id")
			return
		end
		rChar:setSquad(squad.getName())
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
			menuManager.showMenu("SquadMenu")
			SoundManager.playSfx('degauss')
        end
    end
    
    function Ob:show(basePri)
        local w = g_GuiManager.getUIViewportSizeY()
        g_GuiManager.createEffectMaskBox(0, 0, 1800, w, 0.3, 0.3)
        local nPri = Ob.Parent.show(self, basePri)
		self:loadCharacters()
        rScrollableUI:reset()
        return nPri
    end

    function Ob:hide(bKeepAlive)
		Ob.Parent.hide(self, bKeepAlive)
		for i = #tMemberEntries, 1, -1 do
			tMemberEntries[i]:hide(bKeepAlive)
			tMemberEntries[i] = nil
		end
		for i = #tAvailableEntries, 1, -1 do
			tAvailableEntries[i]:hide(bKeepAlive)
			tAvailableEntries[i] = nil
		end
		--MOAISim.forceGarbageCollection()
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
