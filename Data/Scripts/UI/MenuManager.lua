local MenuManager = {}

function MenuManager.new(_guiManager)
	local self = {}
	local list = {}
	local guiManager = _guiManager
	local active = nil
	
	function self.init()
		
	end
	
	function self.addMenu(sName, rMenu)
		list[sName] = rMenu
	end
	
	function self.getMenu(sName)
		if sName and list[sName] then
			return list[sName]
		end
		return nil
	end
	
	--
	--	show given menu and hide all the others
	--
	function self.showMenu(sName)
		for k,v in pairs(list) do
			if k == sName then
				v:show()
			else
				v:hide(true)
			end
		end
		guiManager:hideStuff()
		active = sName
		if g_GameRules.getTimeScale() ~= 0 then
            self.bWasPaused = false
            g_GameRules.togglePause()
        else
            self.bWasPaused = true
        end
	end
	
	--
	-- Close all menus and show the game stuff
	--
	function self.closeMenu()
		for k,v in pairs(list) do
			v:hide(true)
		end
		active = nil
		guiManager.showStuff()
		if g_GameRules.getTimeScale() == 0 and not self.bWasPaused then
            g_GameRules.togglePause()
        end
	end
	
	--
	-- Returns currently active menu, if no menu is active
	-- it will return nil
	--
	function self.getActive()
		if active == nil then
			return nil
		end
		return list[active]
	end
	
	self.init()
	return self
end

return MenuManager