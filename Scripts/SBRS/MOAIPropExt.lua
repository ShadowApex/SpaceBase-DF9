local MOAIPropExt = {}

function MOAIPropExt.new()
	local self = MOAIProp.new()
	local setVisible = self.setVisible
	local visible = false
	
	function self:setVisible(_visible)
		visible = _visible
		setVisible(self, visible)
	end
	
	function self:isVisible()
		return visible
	end
	
	return self
end

return MOAIPropExt
