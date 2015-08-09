local MenuManager = {}

function MenuManager.new(_guiManager)
	local self = {}
	local list = {}
	local guiManager = _guiManager
	local active = nil
	
	function self.init()
		
	end
	
	function self.addMenu(name, rMenu)
		list[name] = rMenu
	end
	
	function self.getMenu(name)
		return list[name]
	end
	
	--
	--	show given menu and hide all the others
	--
	function self.showMenu(name)
		for k,v in pairs(list) do
			if k == name then
				v:show()
			else
				v:hide(true)
			end
		end
		guiManager:hideStuff()
		active = name
		if g_GameRules.getTimeScale() ~= 0 then
            g_GameRules.togglePause()
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