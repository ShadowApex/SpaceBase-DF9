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
local World = require('World')
local UIButton = require('UI.UIButton')


local sUILayoutFileName = 'UILayouts/DebugMenuLayout'

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
	
    function Ob:init()
		Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

		self.rDoneButton = UIButton.new({clickCallback = self.onDoneButtonPressed}) -- , hotkey = {text = 'ESC'}
		self:addElement(self.rDoneButton)
--		self.rDoneButton:show()
		
--        self.rDoneButton = self:getTemplateElement('DoneButton')
--		self.rDoneButton:addPressedCallback(self.onDoneButtonPressed, self)
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
		
--		self:addHotkey(self:getTemplateElement('DoneHotkey').sText, self.rDoneButton)
		self:addHotkey(self:getTemplateElement('ResearchHotkey').sText, self.rResearchButton)
		self:addHotkey(self:getTemplateElement('ResearchAllHotkey').sText, self.rResearchAllButton)
		
		self:addHotkey(self:getTemplateElement('ResearchAllMaladyHotkey').sText, self.rResearchAllMaladyButton)
		self:addHotkey(self:getTemplateElement('MakeAllHappyHotkey').sText, self.rMakeAllHappyButton)		
		self:addHotkey(self:getTemplateElement('MakeAllSadHotkey').sText, self.rMakeAllSadButton)	
		self:addHotkey(self:getTemplateElement('InfectHotkey').sText, self.rInfectButton)			
		self:addHotkey(self:getTemplateElement('RandomTestHotkey').sText, self.rRandomTestButton)	
		self:addHotkey(self.rDoneButton:getTemplateElement('Hotkey').sText, self.rDoneButton:getTemplateElement('Button'))
	end

	function Ob:onDoneButtonPressed()
		if g_GuiManager.newSideBar then
			g_GuiManager.newSideBar:closeSubmenu()
			SoundManager.playSfx('degauss')
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
		end
	end
	
	function Ob:onMakeAllSadButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
			
		end
	end
	
	function Ob:onInfectButtonPressed(rButton, eventType)
		if eventType == DFInput.TOUCH_UP then
		print(Malady.getDiseaseName('Thing'))
		print(Malady.getDiseaseName('dysentary'))
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