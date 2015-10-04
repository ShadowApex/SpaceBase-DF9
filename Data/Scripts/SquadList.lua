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


local SquadList = {}

local Squad = require('Squad')

local tSquadNames = { {name='SQUAD009TEXT', isUsed=false}, {name='SQUAD010TEXT', isUsed=false}, {name='SQUAD011TEXT', isUsed=false}, {name='SQUAD012TEXT', isUsed=false}, 
						{name='SQUAD013TEXT', isUsed=false}, {name='SQUAD014TEXT', isUsed=false}, {name='SQUAD015TEXT', isUsed=false}, {name='SQUAD016TEXT', isUsed=false}, 
						{name='SQUAD017TEXT', isUsed=false}, {name='SQUAD018TEXT', isUsed=false},}


function SquadList.new()
	local self = {}
	local tSquads = {}
	local nSize = 0
	local MAX_SQUADS = 10
	local nSquadIndex = 1
	
	function self.init()
		self.shuffleSquadNames()
	end
	
	function self.loadSaveData(tSquadData)
		for k,v in pairs(tSquadData) do
			if not self.getSquad(v.name) then
				self.addSquad(v.name, Squad.new(v.name, v.status, v.members))
			end
		end
	end
	
	function self.shuffleSquadNames()
		local rand = math.random
		local iterations = #tSquadNames
		local j
		for i = iterations, 2, -1 do
			j = rand(i)
			tSquadNames[i], tSquadNames[j] = tSquadNames[j], tSquadNames[i]
		end
	end

	function self.getList()
		return tSquads
	end
	
	function self.newSquad()
		if nSize < MAX_SQUADS then
			local sName = self._getUnusedSquadname()
			self.addSquad(sName, Squad.new(sName))			
		end
	end
	
	function self._getUnusedSquadname()
		local sName = g_LM.line(tSquadNames[nSquadIndex].name)
		if not self.getSquad(sName) then
			return sName
		else
			if nSquadIndex < #tSquadNames then
				nSquadIndex = nSquadIndex + 1
			else
				nSquadIndex = 0
			end
			return self._getUnusedSquadname()
		end
	end

	function self.addSquad(sName, squad)
		tSquads[sName] = squad
		nSize = nSize + 1
	end

	function self.remSquad(sName)
		tSquads[sName] = nil
		nSize = nSize - 1
	end
	
	function self.getSquad(sName)
		return tSquads[sName] or nil
	end

	function self.numSquads()
		return nSize
	end

	function self.disbandSquad(sName)
		local tMembers = tSquads[sName].getMembers()
		local CharacterManager = require('CharacterManager')
		local Character = require('Character')
		local tChars = CharacterManager.getTeamCharacters(Character.TEAM_ID_PLAYER)
		for k,v in pairs(tChars) do
			if tMembers[v:getUniqueID()] ~= nil then
				v:setSquadName(nil)
			end
		end
		tSquads[sName] = nil
		nSize = nSize - 1
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
	
	self.init()
	return self
end

return SquadList