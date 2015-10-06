------------------------------------------------------------------------
-- The contents of this file are subject to the Common Public
-- Attribution License Version 1.0. (the "License"); you may not use
-- this file except in compliance with this License.  You may obtain a
-- copy of the License from the COPYING file included in this code
-- base. The License is based on the Mozilla Public License Version 1.1,
-- but Sections 14 and 15 have been added to cover use of software over
-- a computer network and provide for limited attribution for the
-- Original Developer. In addition, Exhibit A has been modified to be
-- consistent with Exhibit B.
--
-- Software distributed under the License is distributed on an "AS IS"
-- basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
-- the License for the specific language governing rights and
-- limitations under the License.
--
-- The Original Code is Spacebase DF-9.
--
-- The Original Developer is not the Initial Developer and is Andrew
-- Hewson of Derelict Games.

-- The Initial Developer of the Original Code is Double Fine
-- Productions, Inc.
--
-- The code in this file is the original work of Derelict Games,
-- authored by Andrew Hewson.
--
-- Copyright (c) 2015  Andrew Hewson <hewson.andy@gmail.com>
-- All Rights Reserved.
------------------------------------------------------------------------

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')

local m = {}

m.SCROLL_LOCATION_LEFT = 1
m.SCROLL_LOCATION_RIGHT = 2

function m.create()
	local Ob = DFUtil.createSubclass(UIElement.create())
	local rElement
	local scrollY = 0
	
	function Ob:init(width, height, scrollLocation)
		scrollLocation = scrollLocation or m.SCROLL_LOCATION_RIGHT
		self.uiWidth, self.uiHeight = width, height
		self:setScl(width, height)
	end
	
	function Ob:addElement(_rElement)
		rElement = _rElement
		Ob.Parent:addElement(rElement)
		rElement:show()
		self:_update()
	end
	
	function Ob:_update()
		rElement:setLoc(0, scrollY)
	end
	
	function Ob:hide(bKeepAlive)
        Ob.Parent.hide(self, bKeepAlive)
    end

    function Ob:show(nMaxPri)
        return Ob.Parent.show(self, nMaxPri)
    end
	
	return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m