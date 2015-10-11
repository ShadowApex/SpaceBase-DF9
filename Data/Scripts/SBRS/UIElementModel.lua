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

local UIElementModel {}

local tKeyMappings = {
	'esc' = 27,
	'ret' = 13,
	'ent' = 13,
	'spc' = 32,
} -- convenience table


function UIElementModel.new()
	local self = MOAITransform.new()
	local tHotkeyButtons = {}
	local tElements = {}
	local sRenderLayerName = 'UI'
	local width, height = 0, 0
	local bIsVisible = true
	
	function self:init(_sRenderLayerName)
		sRenderLayerName = _sRenderLayerName
	end

	function self:addHotkey(sKey, rButton)
		sKey = string.lower(sKey)
        local keyCode = -1
		if tKeyMappings[sKey] then
			keyCode = tKeyMappings[sKey]
		else
            keyCode = string.byte(sKey)
            local uppercaseKeyCode = string.byte(string.upper(sKey))
			tHotkeyButtons[uppercaseKeyCode] = rButton
        end
		tHotkeyButtons[keyCode] = rButton
	end
	
	function self:remHotkey(sKey)
		sKey = string.lower(sKey)
        local keyCode = -1
        if tKeyMappings[sKey] then
			keyCode = tKeyMappings[sKey]
        else
            keyCode = string.byte(sKey)
            local uppercaseKeyCode = string.byte(string.upper(sKey))
			tHotkeyButtons[uppercaseKeyCode] = nil
        end
		tHotkeyButtons[keyCode] = nil
	end
	
	function self:setRenderLayer(_sRenderLayerName)
		sRenderLayerName = _sRenderLayerName
	end
	
	function self:getRenderLayer()
		return sRenderLayerName
	end
	
	function self:setVisible(_bIsVisible)
		bIsVisible = _bIsVisible
	end
	
	function self:isVisible()
		return bIsVisible
	end
	
	function self:addElement(sName, rElement)
		tElements[sName] = rElement
	end
	
	function self:remElement(sName)
		tElements[sName]:setVisible(false)
		tElements[sName] = nil
	end
	
	self:init()
	return self
end

return UIElementModel