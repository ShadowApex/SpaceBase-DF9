local GameRules=require('GameRules')
local DFGraphics=require('DFCommon.Graphics')
local Renderer = require('Renderer')
local MiscUtil = require('MiscUtil')
local Room = nil
local Gui = require('UI.Gui')
local ActivityOption = require('Utility.ActivityOption')
local Character = require('CharacterConstants')
local CharacterManager = require('CharacterManager')
local SoundManager= require('SoundManager')
local ObjectList=require('ObjectList')
local Base=require('Base')
local Class=require('Class')
local MOAIImageExt = require('SBRS.MOAIImageExt')
local MOAIPropExt = require('SBRS.MOAIPropExt')

local EmergencyBeacon = Class.create(nil, MOAIProp.new)

EmergencyBeacon.COLOUR_VIOLENCE_HIGH = {0.9, 0, 0, 1}
EmergencyBeacon.COLOUR_VIOLENCE_MEDIUM = Gui.AMBER
EmergencyBeacon.COLOUR_VIOLENCE_LOW = {138 / 255, 43 / 255, 226 / 255}

EmergencyBeacon.RENDER_LAYER = 'Cursor'
EmergencyBeacon.MODE_TRAVELTO={spriteName='beacon_waypoint'}
EmergencyBeacon.MODE_BREACH={spriteName='beacon_investigatealt'} -- UNUSED
EmergencyBeacon.MODE_EXPLORE={spriteName='beacon_investigate'}
EmergencyBeacon.MODE_INVALID={spriteName='beacon_investigatealt'} -- UNUSED

EmergencyBeacon.VIOLENCE_DEFAULT=2
EmergencyBeacon.VIOLENCE_LETHAL=3
EmergencyBeacon.VIOLENCE_NONLETHAL=4

EmergencyBeacon.tBeaconTypeLinecodes = {
	[EmergencyBeacon.VIOLENCE_DEFAULT] = 'UIMISC032TEXT',
	[EmergencyBeacon.VIOLENCE_LETHAL] = 'UIMISC033TEXT',
	[EmergencyBeacon.VIOLENCE_NONLETHAL] = 'UIMISC034TEXT',
}

EmergencyBeacon.tModes={EmergencyBeacon.MODE_TRAVELTO,EmergencyBeacon.MODE_BREACH,EmergencyBeacon.MODE_EXPLORE,EmergencyBeacon.MODE_INVALID}

function EmergencyBeacon:getActivityOptions()
	local tActivityOptions = {}
	for k,v in pairs(self.tBeacons) do
		if v.rActivityOption then
			table.insert(tActivityOptions, v.rActivityOption)
		end
	end
	return tActivityOptions
end

function EmergencyBeacon:init()
	Room = require('Room')
	self.tBeacons = {}
	self.rPreviewProp = MOAIPropExt.new()
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(self.rPreviewProp)
	self.rPreviewProp:setVisible(false)
end

function EmergencyBeacon:setSelectedSquad(rSquad)
	if not rSquad then
		print("EmergencyBeacon:setSelectedSquad() Error: rSquad is nil")
		return
	end
	if not self.tBeacons[rSquad.getName()] then
		self:newBeacon(rSquad.getName())
	end
	self.rSelectedSquad = rSquad
end

function EmergencyBeacon:getViolence(sSquadName)
	if self.tBeacons[sSquadName] then
		return self.tBeacons[sSquadName].eViolence
	else
		return EmergencyBeacon.VIOLENCE_DEFAULT
	end
end

function EmergencyBeacon:setViolence(sSquadName, eViolence)
	if not self.tBeacons[sSquadName] then
		self:newBeacon(sSquadName)
	end
	self.tBeacons[sSquadName].eViolence = eViolence
	if self.rSelectedSquad then
		local beacon = self:_getCurrentBeacon(sSquadName)
		self.rPreviewProp:setDeck(beacon.deck)
		self.rPreviewProp:setVisible(true)
	end
end

function EmergencyBeacon:newBeacon(sSquadName)
	local beaconLow, beaconMed, beaconHigh = MOAIPropExt.new(), MOAIPropExt.new(), MOAIPropExt.new()
	local deckHigh, deckMed, deckLow = self:_generateGraphics()
	beaconHigh:setDeck(deckHigh)
	beaconMed:setDeck(deckMed)
	beaconLow:setDeck(deckLow)
	beaconHigh.deck = deckHigh
	beaconMed.deck = deckMed
	beaconLow.deck = deckLow
	beaconHigh.sSquadName = sSquadName
	beaconMed.sSquadName = sSquadName
	beaconLow.sSquadName = sSquadName
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(beaconHigh)
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(beaconMed)
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(beaconLow)
	beaconHigh:setVisible(false)
	beaconMed:setVisible(false)
	beaconLow:setVisible(false)
	self.tBeacons[sSquadName] = {}
	self.tBeacons[sSquadName].eViolence = EmergencyBeacon.VIOLENCE_DEFAULT
	self.tBeacons[sSquadName].beaconLow = beaconLow
	self.tBeacons[sSquadName].beaconMed = beaconMed
	self.tBeacons[sSquadName].beaconHigh = beaconHigh
end

function EmergencyBeacon:_generateGraphics()
	local totalWidth, totalHeight = 100, 100
	local iconWidth, iconHeight = totalWidth - (totalWidth / 3), totalHeight - (totalHeight / 3) -- total width/height of the icon part
	local randoms = self:_getDistinctRandoms(4, 2, 0, 8)
	local tl = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[1])
	local tr = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[2])
	local bl = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[3])
	local br = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[4])
	local image1 = self:_generateGraphic(totalWidth, totalHeight, iconWidth, iconHeight, tl, tr, bl, br, EmergencyBeacon.COLOUR_VIOLENCE_HIGH)
	local image2 = self:_generateGraphic(totalWidth, totalHeight, iconWidth, iconHeight, tl, tr, bl, br, EmergencyBeacon.COLOUR_VIOLENCE_MEDIUM)
	local image3 = self:_generateGraphic(totalWidth, totalHeight, iconWidth, iconHeight, tl, tr, bl, br, EmergencyBeacon.COLOUR_VIOLENCE_LOW)
	return image1, image2, image3
end

function EmergencyBeacon:_generateGraphic(width, height, iconWidth, iconHeight, tl, tr, bl, br, colour)
	local iconx, icony = (width - iconWidth) / 2, (height - iconHeight) / 2
	local image = MOAIImageExt.new()
	image:init(width, height)
	image.fillTriangle({x = 0, y = height / 2}, {x = width / 2, y = 0}, {x = width, y = height / 2}, colour)
	image.drawLine(width / 2, height / 2, 0, height, 5, colour)
	image.drawLine(width / 2, height / 2, width, height, 5, colour)
	image.fillRect({x = iconx, y = icony}, {x = iconx + iconWidth - 1, y = icony + iconHeight - 1}, colour)
	image.copyImage(tl, 0, 0, iconWidth / 2, iconHeight / 2, iconx, icony, false)
	image.copyImage(tr, iconWidth / 2, 0, 0, iconHeight / 2, iconx + iconWidth, icony, false)
	image.copyImage(bl, 0, iconHeight / 2, iconWidth / 2, 0, iconx, icony + iconHeight, false)
	image.copyImage(br, iconWidth / 2, iconHeight / 2, 0, 0, iconx + iconWidth, icony + iconWidth, false)
	local gfxQuad = MOAIGfxQuad2D.new()
	gfxQuad:setTexture(image)
	gfxQuad:setRect(-width / 2, -height / 2, width / 2, height / 2)
	return gfxQuad
end

function EmergencyBeacon:_getDistinctRandoms(numRandoms, numSameAllowed, minRand, maxRand)
	local randomAmounts = {}
	local randoms = {}
	local count = 0
	math.random()
	math.random()
	math.random()
	while count < numRandoms do
		local rand = math.random(minRand, maxRand)
		if not randomAmounts[rand] then
			randomAmounts[rand] = 1
		else
			if randomAmounts[rand] < numSameAllowed then
				randomAmounts[rand] = randomAmounts[rand] + 1
				count = count + 1
				table.insert(randoms, rand)
			end
		end
	end
	return randoms
end

function EmergencyBeacon:_drawQuadrant(width, height, option)
	local image = MOAIImageExt.new()
	image:init(width, height)
	local lineWidth = 5
	local colour = {0, 0, 0, 1}
	if option == 0 then
		image.fillCircle(width, height, width, colour)
	elseif option == 1 then
		image.fillCircle(width, height, width / 2, colour)
	elseif option == 2 then
		image.fillTriangle({x = width, y = height}, {x = 0, y = height}, {x = width, y = 0}, colour)
	elseif option == 3 then
		image.drawLine(width, height, 0, 0, lineWidth, colour)
	elseif option == 4 then
		image.drawLine(0, height, width, 0, lineWidth, colour)
	elseif option == 5 then
		image.drawLine(width + lineWidth, height - lineWidth, lineWidth, -lineWidth, lineWidth, colour)
		image.drawLine(width - lineWidth, height + lineWidth, -lineWidth, lineWidth, lineWidth, colour)
	elseif option == 6 then
		image.drawLine(lineWidth, height + lineWidth, width + lineWidth, lineWidth, lineWidth, colour)
		image.drawLine(-lineWidth, height - lineWidth, width - lineWidth, -lineWidth, lineWidth, colour)
	elseif option == 7 then -- square minus large circle
		local tempImage = MOAIImageExt.new()
		tempImage:init(width, height)
		tempImage.fillRect({x = 0, y = 0}, {x = width - 0, y = height - 0}, colour)
		tempImage.fillCircle(0, 0, width, {0, 0, 0, 0})
		image.copyImage(tempImage, 0, 0, width, height, 0, 0, width, height, false)
	elseif option == 8 then	-- large circle minus small circle
		local tempImage = MOAIImageExt.new()
		tempImage:init(width, height)
		tempImage.fillCircle(width, height, width, colour)
		tempImage.fillCircle(width, height, width / 2, {0, 0, 0, 0})
		image.copyImage(tempImage, 0, 0, width, height, 0, 0, width, height, false)
	end
	return image
end

function EmergencyBeacon:onTick()
	for k,v in pairs(self.tBeacons) do
		if v.tMode == EmergencyBeacon.MODE_EXPLORE then
			local tRooms = Room.getRoomsOfTeam(v.nTargetTeam)
			if not next(tRooms) then
				v = nil
			end
		end
	end
end

function EmergencyBeacon:getModeAt(tx, ty)
	local rRoom = Room.getRoomAtTile(tx, ty, 1, true)
	if rRoom and rRoom:getTeam() ~= Character.TEAM_ID_PLAYER then
		return self.MODE_EXPLORE
	end
	return self.MODE_TRAVELTO
end

function EmergencyBeacon:_showPropAt(wx, wy, tx, ty, rProp)
	if not rProp then
		return
	end
	if rProp == self then
		SoundManager.playSfx('placebeacon')
	end

	local tMode = self:getModeAt(tx,ty)
	if tMode == EmergencyBeacon.MODE_EXPLORE then
		local nTeam = Room.getTeamAtTile(tx,ty,1)
		local tRooms = Room.getRoomsOfTeam(nTeam, true)

		local newWX,newWY = 0,0
		local n = 0
		for rRoom,id in pairs(tRooms) do
			local roomCenterWX,roomCenterWY = g_World._getWorldFromTile(rRoom:getCenterTile())
			newWX,newWY = newWX+roomCenterWX,newWY+roomCenterWY
			n=n+1
		end
		if n > 0 then
			wx,wy=newWX/n,newWY/n
		end
		tx,ty = g_World._getTileFromWorld(wx,wy)
	end

	wy=wy+g_World.tileHeight*.75

	if rProp == self.rPreviewProp then
		local placedWX,placedWY = self:getLoc()
		if math.abs(placedWX-wx) < 1 and math.abs(placedWY-wy) < 1 then
			-- don't show a temp drag cursor on top of the placed cursor, because the placed one will have 
			-- more info.
			rProp:setVisible(false)
			return
		end
		if self.rSelectedSquad and self.tBeacons[self.rSelectedSquad.getName()] then
			local beacon = self:_getCurrentBeacon(self.rSelectedSquad.getName())
			if beacon and beacon:isVisible() then
				rProp:setDeck(beacon.deck)
				rProp:setVisible(true)
			end
		end
	else
		rProp:setVisible(true)
	end


	if wx == math.inf or wy == math.inf or wx ~= wx or wy ~= wy then
		assertdev(false)
	else
		rProp:setLoc(wx, wy, 0)
	end

	return tMode, tx, ty
end

--function EmergencyBeacon:getToolTipTextInfos(test) -- need to fix this
--	print("EmergencyBeacon:getToolTipTextInfos() test: "..test)
--	-- hovering in inspect mode, show nature and target of beacon order, eg
--	-- Secure Room (Lethal Force):
--	-- The Rusty Killbot
--	self.tToolTipTextInfos = {}
--	self.tToolTipTextInfos[1] = {}
--	self.tToolTipTextInfos[2] = {}
--	self.tToolTipTextInfos[3] = {}
--	-- character or room?
--	local rTarget = self.rTargetObject
--	local sOrderLC
--	if not rTarget then
--		assertdev(self.tx ~= nil)
--		if self.tx == nil then return {} end
--		rTarget = Room.getRoomAtTile(self.tx, self.ty, 1, true)
--		sOrderLC = 'UIMISC037TEXT'
--	else
--		sOrderLC = 'UIMISC035TEXT'
--		if not Base.isFriendlyToPlayer(rTarget) then
--			sOrderLC = 'UIMISC036TEXT'
--		end
--	end
--	local sTypeLC = EmergencyBeacon.tBeaconTypeLinecodes[self.eViolence]
--	local s = g_LM.line(sOrderLC) .. ' (' .. g_LM.line(sTypeLC) .. ')'
--	self.tToolTipTextInfos[1].sString = s
--	-- security icon
--	self.tToolTipTextInfos[1].sTextureSpriteSheet = 'UI/JobRoster'
--	self.tToolTipTextInfos[1].sTexture = 'ui_jobs_iconJobResponse'
--	-- beacon for hidden area?
--	local sTargetName
--	if not rTarget then
--		-- beacon is in space, don't show a room name if so
--	elseif ObjectList.getObjType(rTarget) == ObjectList.CHARACTER then
--		sTargetName = rTarget.tStats.sName
--	elseif rTarget.uniqueZoneName then
--		local wx,wy = self.tx and g_World._getWorldFromTile(self.tx, self.ty)
--		local bHidden = not wx or g_World.getVisibility(wx,wy) ~= g_World.VISIBILITY_FULL
--		if not bHidden then
--			sTargetName = rTarget.uniqueZoneName
--		end
--	end
--	if sTargetName then
--		self.tToolTipTextInfos[2].sString = sTargetName
--	end
--	return self.tToolTipTextInfos
--end

function EmergencyBeacon:isVisible(rProp)
	print("EmergencyBeacon:isVisible() sSquadName: "..rProp.sSquadName)
	if self.tBeacons[rProp.sSquadName].beaconHigh:isVisible() then
		return true
	elseif self.tBeacons[rProp.sSquadName].beaconMed:isVisible() then
		return true
	elseif self.tBeacons[rProp.sSquadName].beaconLow:isVisible() then
		return true
	end
	return false
end

function EmergencyBeacon:showAtTile(tx, ty)
	tx, ty = g_World.clampTileToBounds(tx, ty)
	local wx, wy = g_World._getWorldFromTile(tx, ty, 1)
	return self:_showPropAt(wx, wy, tx, ty, self.rPreviewProp)
end

function EmergencyBeacon:showAtWorldPos(wx,wy)
	local tx,ty = g_World._getTileFromWorld(wx,wy)
	return self:_showPropAt(wx, wy, tx, ty, self.rPreviewProp)
end

-- Used by tasks to see if the beacon they started out for is still active.
function EmergencyBeacon:stillActive(rChar, wx,wy,rTargetObject,beaconType)
	if not rChar:getSquadName() then
		return false
	end
	if self.tBeacons[rChar:getSquadName()].tx and self.tBeacons[rChar:getSquadName()].ty then
		local tx,ty = g_World._getTileFromWorld(wx,wy)
		if tx == self.tBeacons[rChar:getSquadName()].tx and ty == self.tBeacons[rChar:getSquadName()].ty and beaconType == self.tBeacons[rChar:getSquadName()].tMode then
			return true
		end
	elseif self.tBeacons[rChar:getSquadName()].rTargetObject and self.tBeacons[rChar:getSquadName()].tMode then
		if rTargetObject == self.tBeacons[rChar:getSquadName()].rTargetObject and beaconType == self.tBeacons[rChar:getSquadName()].tMode then
			return true
		end
	end
	return false
end

function EmergencyBeacon:charResponded(rChar)
	self.tBeacons[rChar:getSquadName()].tChars[rChar] = {nWaitTime=0, bArrived=false}
end

function EmergencyBeacon:_testChar(rChar,sTest)
	if not self.tBeacons[rChar:getSquadName()].tChars[rChar] then
		Print(TT_Warning,"Character "..sTest.." at beacon without first responding to it: "..rChar:getUniqueID())
		self:charResponded(rChar)
	end
end

function EmergencyBeacon:charArrived(rChar)
	self:_testChar(rChar,'arrived')
	self.tBeacons[rChar:getSquadName()].tChars[rChar].bArrived = true
	local nArrived = 0
	for rChar,tData in pairs(self.tBeacons[rChar:getSquadName()].tChars) do
		if tData.bArrived then
			nArrived = nArrived+1
		end
	end
	self.tBeacons[rChar:getSquadName()].nCharsAtBeacon = nArrived
end

function EmergencyBeacon:getSaveTable()
	local World = require('World')
	local t = {}
	for k, v in pairs(self.tBeacons) do
		if World.getSquadList().getSquad(k) then
			t[k] = {}
			t[k].eViolence = v.eViolence
			t[k].tx = v.tx
			t[k].ty = v.ty
			t[k].nCount = v.nCount
			if v.tMode and v.tMode.spriteName then
				t[k].spriteName = v.tMode.spriteName
			end
			if v.rTargetObject then
				local tTag = ObjectList.getTag(v.rTargetObject)
				if tTag then
					t[k].tTargetObjTag = ObjectList.getTagSaveData(tTag)
				end
			end
		end
	end
	return t
end

function EmergencyBeacon:fromSaveTable(t)
	for k,v in pairs(t) do
		if type(v) ~= 'table' then
			break -- old save, so ignore it
		end
		self:newBeacon(k)
		self.tBeacons[k].eViolence = v.eViolence
		local bSet = false
		if v.tTargetObjTag then
			self.tBeacons[k].tTargetObject = v.tTargetObjTag
			local rTargetObject = ObjectList.getObject(self.tBeacons[k].tTargetObjTag)
			if rTargetObject then
				self:attachTo(rTargetObject, v.nCount)
				bSet = true
			end
		end
		if not bSet and v.tx and v.ty then
			self:placeAt(v.tx, v.ty, v.nCount, {sSquadName = k})
		end
	end
end

function EmergencyBeacon:charWaiting(rChar,dt)
	self:_testChar(rChar,'waited')
	self.tBeacons[rChar:getSquadName()].tChars[rChar].nWaitTime = self.tBeacons[rChar:getSquadName()].tChars[rChar].nWaitTime + dt
end

function EmergencyBeacon:charAbandoned(rChar)
	self:_testChar(rChar,'abandoned')
	self.tBeacons[rChar:getSquadName()].tChars[rChar] = nil
end

function EmergencyBeacon:charShouldWait(rChar)
	if self.tBeacons[rChar:getSquadName()].tMode == EmergencyBeacon.MODE_TRAVELTO then
		return true
	else
		return self.tBeacons[rChar:getSquadName()].nCharsAtBeacon < require('World').getSquadList().getSquad(rChar:getSquadName()).getSize()
	end
end

function EmergencyBeacon:getTargetTeam(rChar)
	return self.tBeacons[rChar:getSquadName()].nTargetTeam
end

function EmergencyBeacon:placeAt(tx, ty, nCount, optional)
	local sSquadName = nil
	if self.rSelectedSquad then
		sSquadName = self.rSelectedSquad.getName()
	elseif optional and optional.sSquadName then
		sSquadName = optional.sSquadName
	end
	if not sSquadName then
		print("EmergencyBeacon:placeAt() Error: No squad selected")
		return
	end
	local nTargetTeam = Room.getTeamAtTile(tx,ty,1)
	local wx,wy = g_World._getWorldFromTile(tx,ty,1)
	if not self.tBeacons[sSquadName] then
		print("EmergencyBeacon:placeAt() self.tBeacons["..sSquadName.."] not found")
		self:newBeacon(sSquadName)
	end
	self.tBeacons[sSquadName].beaconHigh:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[sSquadName].beaconMed:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[sSquadName].beaconLow:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[sSquadName].beaconHigh:setVisible(false)
	self.tBeacons[sSquadName].beaconMed:setVisible(false)
	self.tBeacons[sSquadName].beaconLow:setVisible(false)
	local beacon = self:_getCurrentBeacon(sSquadName)
	local tMode,tx,ty = self:_showPropAt(wx, wy, tx, ty, beacon)
	self.tBeacons[sSquadName].tx, self.tBeacons[sSquadName].ty = tx, ty
	self.tBeacons[sSquadName].rTargetObject = nil
	self.tBeacons[sSquadName].tChars = {}
	self.tBeacons[sSquadName].nCharsAtBeacon = 0
	self.tBeacons[sSquadName].tMode = tMode
	self.tBeacons[sSquadName].nTargetTeam = nTargetTeam
	self.tBeacons[sSquadName].nCount = nCount or self.rSelectedSquad.getSize()

	local tData = {}
	tData.utilityGateFn = function(rChar)
		if not rChar:getJob() == Character.EMERGENCY then
			return false, 'not an ER'
		end
		if not rChar:getSquadName() then
			return false, 'has no squad'
		end
		local tSquads = require('World').getSquadList().getList()
		local rSquad = tSquads[rChar:getSquadName()] or nil
		if not rSquad then
			return false, 'could not find squad'
		end
		if rSquad.getName() == sSquadName then
			return true
		else
			return false, 'not in squad'
		end
	end

	tData.nMaxReservations = nCount or self.rSelectedSquad.getSize()
	wx,wy = g_World._getWorldFromTile(tx,ty)
	if self.tBeacons[sSquadName].tMode == EmergencyBeacon.MODE_TRAVELTO then
		local bOutside = g_World.isAdjacentToSpace(self.tBeacons[sSquadName].tx,self.tBeacons[sSquadName].ty,true,true)
		local sActivityName = (bOutside and 'ERCircleBeaconSpace') or 'ERCircleBeaconInside'
		tData.bInside = not bOutside
		tData.pathX,tData.pathY = wx,wy
		tData.pathToNearest = true
		self.tBeacons[sSquadName].rActivityOption = ActivityOption.new(sActivityName, tData)
	elseif self.tBeacons[sSquadName].tMode == EmergencyBeacon.MODE_BREACH then
	elseif self.tBeacons[sSquadName].tMode == EmergencyBeacon.MODE_EXPLORE then
		local sActivityName = 'ERBeaconExplore'
		tData.pathX,tData.pathY = wx,wy
		tData.pathToNearest = true
		self.tBeacons[sSquadName].rActivityOption = ActivityOption.new(sActivityName, tData)
	else
		self.tBeacons[sSquadName].rActivityOption = nil
		self.tBeacons[sSquadName].beaconHigh:setVisible(false)
		self.tBeacons[sSquadName].beaconMed:setVisible(false)
		self.tBeacons[sSquadName].beaconLow:setVisible(false)
	end
end

function EmergencyBeacon:attachTo(rTargetObject, nCount)
	local tx, ty, tz = rTargetObject:getTileLoc()
	local tMode = EmergencyBeacon.MODE_TRAVELTO
	local nTargetTeam = rTargetObject:getTeam()
	if not self.rSelectedSquad.getName() then
		print("EmergencyBeacon:attachTo() Error: No squad selected")
		return
	end
	if not self.tBeacons[self.rSelectedSquad.getName()] then
		print("EmergencyBeacon:attachTo() self.tBeacons["..self.rSelectedSquad.getName().."] not found")
		self:newBeacon(self.rSelectedSquad.getName())
	end
	self.tBeacons[self.rSelectedSquad.getName()].beaconHigh:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[self.rSelectedSquad.getName()].beaconMed:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[self.rSelectedSquad.getName()].beaconLow:clearAttrLink(MOAIProp.INHERIT_LOC)
	local beacon = self:_getCurrentBeacon(self.rSelectedSquad.getName())
	beacon:setLoc(0, 400, 0)
	beacon:setAttrLink(MOAIProp.INHERIT_LOC, rTargetObject, MOAIProp.TRANSFORM_TRAIT)
	beacon:setVisible(true)
	self.tBeacons[self.rSelectedSquad.getName()].nCount = nCount or self.rSelectedSquad.getSize()
	self.tBeacons[self.rSelectedSquad.getName()].tx, self.tBeacons[self.rSelectedSquad.getName()].ty = nil, nil
	self.tBeacons[self.rSelectedSquad.getName()].rTargetObject = rTargetObject
	self.tBeacons[self.rSelectedSquad.getName()].tChars = {}
	self.tBeacons[self.rSelectedSquad.getName()].nCharsAtBeacon = 0
	self.tBeacons[self.rSelectedSquad.getName()].tMode = tMode
	self.tBeacons[self.rSelectedSquad.getName()].nTargetTeam = nTargetTeam
	local tData = {}

	tData.utilityGateFn = function(rChar) 
		-- if beacon is attached to you, you can't respond to it.
		if rChar == rTargetObject then
			return false, 'target is self'
		end
		if not rChar:getJob() == Character.EMERGENCY then
			return false, 'not an ER'
		end
		if not rChar:getSquadName() then
			return false, 'has no squad'
		end
		local tSquads = require('World').getSquadList().getList()
		local rSquad = tSquads[rChar:getSquadName()] or nil
		if not rSquad then
			return false, 'could not find squad'
		end
		if rSquad.getName() == self.rSelectedSquad.getName() then
			return true
		else
			return false, 'not in squad'
		end
	end

	local wx, wy = g_World._getWorldFromTile(tx, ty, 1)
	local bOutside = g_World.isAdjacentToSpace(tx, ty, true, true)
	local sActivityName = (bOutside and 'ERCircleBeaconSpace') or 'ERCircleBeaconInside'
	tData.bInside = not bOutside
	tData.nMaxReservations = self.tBeacons[self.rSelectedSquad.getName()].nCount
	tData.rTargetObject = rTargetObject
	tData.pathToNearest = true
	self.tBeacons[self.rSelectedSquad.getName()].rActivityOption = ActivityOption.new(sActivityName, tData)
end

function EmergencyBeacon:_getCurrentBeacon(sSquadName)
	if not sSquadName or not self.tBeacons[sSquadName] then
		return nil
	end
	if self.tBeacons[sSquadName].eViolence == EmergencyBeacon.VIOLENCE_LETHAL then
		return self.tBeacons[sSquadName].beaconHigh
	elseif self.tBeacons[sSquadName].eViolence == EmergencyBeacon.VIOLENCE_DEFAULT then
		return self.tBeacons[sSquadName].beaconMed
	elseif self.tBeacons[sSquadName].eViolence == EmergencyBeacon.VIOLENCE_NONLETHAL then
		return self.tBeacons[sSquadName].beaconLow
	else
		return self.tBeacons[sSquadName].beaconMed
	end
end

function EmergencyBeacon:needsMoreResponders(sSquadName)
	if not self.tBeacons or not self.tBeacons[sSquadName] then
		return false
	end
	if not self.tBeacons[sSquadName].rActivityOption then
		return false
	end
	if self.tBeacons[sSquadName] and self.tBeacons[sSquadName].rActivityOption then
		if (self.tBeacons[sSquadName].rActivityOption.tData.nMaxReservations or 1) > (self.tBeacons[sSquadName].rActivityOption.nReservations or 0) then
			return true
		end
	end
	return false
end

function EmergencyBeacon:remove()
	self.rPreviewProp:setVisible(false)
	for k,v in pairs(self.tBeacons) do
		v:setVisible(false)
		self:removeBeacon(v)
	end
	self:setVisible(false)
	self:clearAttrLink(MOAITransform.INHERIT_LOC)
end

function EmergencyBeacon:removeBeacon(beacon)
	if not self.rSelectedSquad or not self.tBeacons[self.rSelectedSquad.getName()] then
		return
	end
	beacon.beaconHigh:clearAttrLink(MOAIProp.INHERIT_LOC)
	beacon.beaconMed:clearAttrLink(MOAIProp.INHERIT_LOC)
	beacon.beaconLow:clearAttrLink(MOAIProp.INHERIT_LOC)
	beacon.beaconHigh:setVisible(false)
	beacon.beaconMed:setVisible(false)
	beacon.beaconLow:setVisible(false)
	beacon = nil
end

function EmergencyBeacon:hideSelectedBeacon()
	if not self.rSelectedSquad or not self.tBeacons[self.rSelectedSquad.getName()] then
		return
	end
	self.tBeacons[self.rSelectedSquad.getName()].beaconHigh:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[self.rSelectedSquad.getName()].beaconMed:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[self.rSelectedSquad.getName()].beaconLow:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[self.rSelectedSquad.getName()].beaconHigh:setVisible(false)
	self.tBeacons[self.rSelectedSquad.getName()].beaconMed:setVisible(false)
	self.tBeacons[self.rSelectedSquad.getName()].beaconLow:setVisible(false)
	self.tBeacons[self.rSelectedSquad.getName()].rActivityOption = nil
	self.tBeacons[self.rSelectedSquad.getName()].tx, self.tBeacons[self.rSelectedSquad.getName()].ty = nil, nil
	self.rPreviewProp:setDeck()
	self.rPreviewProp:setVisible(false)
end

function EmergencyBeacon:stopPreview()
	self.rPreviewProp:setVisible(false)
end

function EmergencyBeacon:destroy()
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):removeProp(self)
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):removeProp(self.rPreviewProp)
	self.rPreviewProp=nil
end

return EmergencyBeacon
