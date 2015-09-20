local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
local CommandObject = require('Utility.CommandObject')
local SoundManager = require('SoundManager')
local ResearchData = require('ResearchData')
local Malady = require('Malady')
local Base = require('Base')
local Character = require('Character')
local CharacterManager = require('CharacterManager')
local World=require('World')


local sUILayoutFileName = 'UILayouts/DebugMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

	
    function Ob:init()
        self:processUIInfo(sUILayoutFileName)

        self.rDoneButton = self:getTemplateElement('DoneButton')
		self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
		self.rResearchButton = self:getTemplateElement('ResearchButton')
		self.rResearchButton:addPressedCallback(self.onResearchButtonPressed, self)
		self.rResearchAllButton = self:getTemplateElement('ResearchAllButton')
		self.rResearchAllButton:addPressedCallback(self.onResearchAllButtonPressed, self)
		
		self.rResearchAllMaladyButton = self:getTemplateElement('ResearchAllMaladyButton')
		self.rResearchAllMaladyButton:addPressedCallback(self.onResearchAllMaladyButtonPressed, self)
		self.rMakeAllHappyButton = self:getTemplateElement('MakeAllHappyButton')
		self.rMakeAllHappyButton:addPressedCallback(self.onMakeAllHappyButtonPressed, self)
		self.rMakeAllSadButton = self:getTemplateElement('MakeAllSadButton')
		self.rMakeAllSadButton:addPressedCallback(self.onMakeAllSadButtonPressed, self)
		self.rInfectButton = self:getTemplateElement('InfectButton')
		self.rInfectButton:addPressedCallback(self.onInfectButtonPressed, self)		
		self.rRandomTestButton = self:getTemplateElement('RandomTest')
		self.rRandomTestButton:addPressedCallback(self.onRandomTestButtonPressed, self)
		
		self.tHotkeyButtons = {}
		self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
		self:addHotkey(self:getTemplateElement('ResearchHotkey').sText, self.rResearchButton)
		self:addHotkey(self:getTemplateElement('ResearchAllHotkey').sText, self.rResearchAllButton)
		
		self:addHotkey(self:getTemplateElement('ResearchAllMaladyHotkey').sText, self.rResearchAllMaladyButton)
		self:addHotkey(self:getTemplateElement('MakeAllHappyHotkey').sText, self.rMakeAllHappyButton)		
		self:addHotkey(self:getTemplateElement('MakeAllSadHotkey').sText, self.rMakeAllSadButton)	
		self:addHotkey(self:getTemplateElement('InfectHotkey').sText, self.rInfectButton)			
		self:addHotkey(self:getTemplateElement('RandomTestHotkey').sText, self.rRandomTestButton)		
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
        elseif sKey == "bksp" then
            keyCode = 8
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
                rButton:keyboardPressed()
                bHandled = true
            end
        end
        
        if not bHandled and self.rSubmenu and self.rSubmenu.onKeyboard then
            bHandled = self.rSubmenu:onKeyboard(key, bDown)
        end
        
        return bHandled
    end
	
	function Ob:onDoneButtonPressed(rButton, eventType)
        if eventType == DFInput.TOUCH_UP then
            if g_GuiManager.newSideBar then
                g_GuiManager.newSideBar:closeSubmenu()
                SoundManager.playSfx('degauss')
            end
        end
    end
	
	function Ob:onResearchButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tAvailableResearch = Base.getAvailableResearch()
			for k,v in pairs(tAvailableResearch) do
				if v.nResearchUnits then
					Base.addResearch(k, ResearchData[k].nResearchUnits - v.nResearchUnits)
				end
			end
		end
	end
	
	function Ob:onResearchAllButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tAvailableResearch = Base.getAvailableResearch()
			for k,v in pairs(tAvailableResearch) do
				Base.addResearch(k, ResearchData[k].nResearchUnits)
			end
		end
	end
	
	------------------------------------------
	function Ob:onResearchAllMaladyButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tAvailableMaladyResearch = Malady.getAvailableResearch()
			for key,value in pairs(tAvailableMaladyResearch) do 
				Malady.addResearch(key, value["nResearchCure"] )
			end
		end
	end
	
	function Ob:onMakeAllHappyButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
			for key,value in pairs(tChars) do 
				print("cHARACTERasdasdasfda :  " .. key .. " - " .. value)
			end
		end
	end
	
	function Ob:onMakeAllSadButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			local tAvailableResearch = Base.getAvailableResearch()
			for k,v in pairs(tAvailableResearch) do
				Base.addResearch(k, ResearchData[k].nResearchUnits)
			end
		end
	end
	
	function Ob:onInfectButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			--local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
			--tChars[1].diseaseInteraction(nil,'Thing')
		end
	end
	
	
	function Ob:onRandomTestButtonPressed(rButton, eventType)
	--this button is used for random testing of code
		if eventType == DFInput.TOUCH_UP then
			for key in pairs(World.floorDecals) do
				World.floorDecals[key] = nil
			end
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