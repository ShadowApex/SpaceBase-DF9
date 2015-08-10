local SquadList = {}

function SquadList.new()
	local self = {}
	local tSquads = {}

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
	
	return self
end

return SquadList