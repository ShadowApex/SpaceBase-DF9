local SquadList = {}

function SquadList.new()
	local self = {}
	local list = {}
	
	function self.init()
		
	end
	
	function self.addSquad(squad)
		list[squad.getName()] = squad
	end
	
	function self.remSquad(name)
		list[name] = nil
	end
	
	function self.setSquadStatus(name, status)
		list[name].status = status
	end
	
	function self.addMember(squadName, memberName)
		table.insert(list[squadName].members, memberName)
	end
	
	function self.remMember(squadName, memberName)
		local member = -1
		for k,v in ipairs(list[squadName].members) do
			if v == memberName then
				member = k
			end
		end
		if (member > 0) then
			table.remove(list[squadName].members, member)
		end
	end
	
	function self.getSquadList()
		return list
	end
	
	self.init()
	return self
end

return SquadList