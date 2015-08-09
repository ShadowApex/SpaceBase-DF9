local Squad = {}

function Squad.new(_name, _size, _status, _members)
	local self = {}
	local name = _name
	local size = _size or 0
	local status = _status or "available"
	local members = _members or {}
	
	function self.init()
		
	end
	
	function self.getName()
		return name
	end
	
	function self.getSize()
		return size
	end
	
	function self.getStatus()
		return status
	end
	
	function self.getMembers()
		return members
	end
	
	self.init()
	return self
end

return Squad