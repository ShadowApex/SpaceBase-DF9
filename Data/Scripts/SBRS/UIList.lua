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

function m.create()
	local Ob = DFUtil.createSubclass(UIElement.create())
	local tList = {}
	local nSize = 0
	
	function Ob:add(sName, rElement)
		if not sName then
			return
		end
		tList[sName] = rElement
		tList[sName].nOrder = nSize
		self:addElement(rElement)
		self:_updateElement(sName)
		tList[sName]:show()
		nSize = nSize + 1
	end
	
	function Ob:addList(_tList)
		for k,v in pairs(_tList) do
			self:add(k, v)
		end
	end
	
	function Ob:remove(sName)
		if not sName then return end
		local nOrder = tList[sName].nOrder
		tList[sName]:hide()
		tList[sName] = nil
		nSize = nSize - 1
		for k,v in pairs(tList) do
			if k ~= sName and v.nOrder >= nOrder then
				v.nOrder = v.nOrder - 1
				self:_updateElement(k)
			end
		end
	end
	
	function Ob:getScrollDistance()  -- fix this
		return 0
	end
	
	function Ob:_updateElement(sName)
		if not sName then return end
		local x, y = self:getLoc()
		local w, h = tList[sName]:getDims()
		tList[sName]:setLoc(x, h * tList[sName].nOrder)
		tList[sName]:update(self)
	end
	
	function Ob:getOrder(sName)
		if not sName or not tList[sName] then
			return -1
		end
		return tList[sName].nOrder
	end
	
	function Ob:getList()
		return tList
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