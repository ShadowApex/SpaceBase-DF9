local Squad = {}

Squad.AVAILABLE = 1
Squad.MOVING = 2
Squad.BREACHING = 3
Squad.EXPLORING = 4

function Squad.new(_sName, _eStatus, _tMembers)
	local self = {}
	local sName = _sName
	local eStatus = _eStatus or Squad.AVAILABLE
	local tMembers = _tMembers or {}
	local nSize = 0
	
	function self.init()
		if _tMembers then
			for k,v in pairs(_tMembers) do
				nSize = nSize + 1
			end
		end
	end
	
	function self.getName()
		return sName
	end
	
	function self.getSize()
		return nSize
	end
	
	function self.getStatus()
		return eStatus
	end
	
	function self.setStatus(_eStatus)
		eStatus = _eStatus
	end
	
	function self.getMembers()
		return tMembers
	end
	
	function self.addMember(id, sMemberName)
		tMembers[id] = sMemberName
		nSize = nSize + 1
	end
	
	function self.remMember(id)
		if tMembers[id] then
			tMembers[id] = nil
			nSize = nSize - 1
		end
	end
	
	self.init()
	return self
end

return Squad