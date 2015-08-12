local SquadList = {}

local Squad = require('Squad')

function SquadList.new()
	print("SquadList.new()")
	local self = {}
	local tSquads = {}
	
	function self.loadSaveData(tSquadData)
		for k,v in pairs(tSquadData) do
			self.addSquad(v.name, Squad.new(v.name, v.status, v.members))
		end
		require("UI.GuiManager").updateSquadMenu() -- we cannot guarantee that SquadList will be loaded before SquadMenu so let's update it
	end

	function self.getList()
		return tSquads
	end

	function self.addSquad(name, squad)
		tSquads[name] = squad
	end

	function self.remSquad(name)
		tSquads[name] = nil
	end
	
	function self.getSquad(name)
		return tSquads[name] or nil
	end

	function self.numSquads()
		return #tSquads
	end

	function self.disbandSquad(name)
		local tMembers = tSquads[name].getMembers()
		local CharacterManager = require('CharacterManager')
		local Character = require('Character')
		local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
		for k,v in pairs(tChars) do
			if tMembers[v:getUniqueID()] ~= nil then
				v:setSquad(nil)
			end
		end
		tSquads[name] = nil
	end
	
	function self.getSaveData()
		local tSquadData = {}
		local n = 1
		for k,v in pairs(tSquads) do
			table.insert(tSquadData, {name=k, status=v.getStatus(), members=v.getMembers()})
			n = n + 1
		end
		return tSquadData
	end
	
	return self
end

return SquadList