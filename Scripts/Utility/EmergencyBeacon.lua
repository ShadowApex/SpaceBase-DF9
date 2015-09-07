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

local EmergencyBeacon = Class.create(nil, MOAIProp.new)

local kNUM_BEACON_TEXTURES = 6

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
		table.insert(tActivityOptions, v.rActivityOption)
	end
	return tActivityOptions
end

function EmergencyBeacon:init()
    Room = require('Room')
    self.nCount=0
    self.deck = DFGraphics.loadSpriteSheet('UI/Beacon')
    self.tChars = {}
	self.tBeacons = {}

    for _,tMode in ipairs(self.tModes) do
        for index = 1, kNUM_BEACON_TEXTURES do
            DFGraphics.alignSprite(self.deck, tMode.spriteName..index, "center", "bottom")
        end
    end

    self:setDeck(self.deck)
    Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(self)
    self:setScl(1.5,1.5,1.5)
	self:setVisible(false)

    self.rPreviewProp = MOAIProp.new()
    self.rPreviewProp:setScl(1.5,1.5,1.5)
    self.rPreviewProp:setDeck(self.deck)
    Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(self.rPreviewProp)
	self.rPreviewProp:setVisible(false)

    self:setColor(unpack(Gui.AMBER))
    self.rPreviewProp:setColor(unpack(Gui.AMBER))
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
	if self.tBeacons[sSquadName] then
		self.tBeacons[sSquadName].eViolence = eViolence
	end
end

function EmergencyBeacon:newBeacon(sSquadName)
	local beacon = MOAIProp.new()
	local deck = self:generateGraphic()
	beacon:setDeck(deck)
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(beacon)
	beacon:setVisible(false)
	beacon:setColor(unpack(Gui.AMBER))
	beacon.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT
	self.tBeacons[sSquadName] = beacon
end

function EmergencyBeacon:generateGraphic()
	local image = MOAIImageExt.new()
	local totalWidth, totalHeight = 100, 100
	local iconWidth, iconHeight = totalWidth - (totalWidth / 3), totalHeight - (totalHeight / 3) -- total width/height of the icon part
	local iconx, icony = (totalWidth - iconWidth) / 2, (totalHeight - iconHeight) / 2
	local yellow = {1, 1, 0, 1}
	image:init(totalWidth, totalHeight)
	image:setRGBA(0, 0, 1, 1, 1, 1)
	image.fillTriangle({x = 0, y = totalHeight / 2}, {x = totalWidth / 2, y = 0}, {x = totalWidth, y = totalHeight / 2}, yellow)
	image.drawLine(totalWidth / 2, totalHeight / 2, 0, totalHeight, 5, yellow)
	image.drawLine(totalWidth / 2, totalHeight / 2, totalWidth, totalHeight, 5, yellow)
	image.fillRect({x = iconx, y = icony}, {x = iconx + iconWidth - 1, y = icony + iconHeight - 1}, yellow)
	local randoms = self:_getDistinctRandoms(4, 2, 0, 8)
	local tl = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[1])
	local tr = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[2])
	local bl = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[3])
	local br = self:_drawQuadrant(iconWidth / 2, iconHeight / 2, randoms[4])
	image.copyImage(tl, 0, 0, iconWidth / 2, iconHeight / 2, iconx, icony, false)
	image.copyImage(tr, iconWidth / 2, 0, 0, iconHeight / 2, iconx + iconWidth, icony, false)
	image.copyImage(bl, 0, iconHeight / 2, iconWidth / 2, 0, iconx, icony + iconHeight, false)
	image.copyImage(br, iconWidth / 2, iconHeight / 2, 0, 0, iconx + iconWidth, icony + iconWidth, false)
	local gfxQuad = MOAIGfxQuad2D.new()
	gfxQuad:setTexture(image)
	gfxQuad:setRect(-totalWidth / 2, -totalHeight / 2, totalWidth / 2, totalHeight / 2)
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
    end    
    
    rProp:setVisible(true)
	if wx == math.inf or wy == math.inf or wx ~= wx or wy ~= wy then
        assertdev(false)
    else
        rProp:setLoc(wx, wy, 0)
    end

    return tMode, tx, ty
end

-- function EmergencyBeacon:getToolTipTextInfos() -- need to fix this
	-- -- hovering in inspect mode, show nature and target of beacon order, eg
	-- -- Secure Room (Lethal Force):
	-- -- The Rusty Killbot
	-- self.tToolTipTextInfos = {}
	-- self.tToolTipTextInfos[1] = {}
	-- self.tToolTipTextInfos[2] = {}
	-- self.tToolTipTextInfos[3] = {}
	-- -- character or room?
	-- local rTarget = self.rTargetObject
	-- local sOrderLC
	-- if not rTarget then
		-- assertdev(self.tx ~= nil)
        -- if self.tx == nil then return {} end
		-- rTarget = Room.getRoomAtTile(self.tx, self.ty, 1, true)
		-- sOrderLC = 'UIMISC037TEXT'
	-- else
		-- sOrderLC = 'UIMISC035TEXT'
		-- if not Base.isFriendlyToPlayer(rTarget) then
			-- sOrderLC = 'UIMISC036TEXT'
		-- end
	-- end
	-- local sTypeLC = EmergencyBeacon.tBeaconTypeLinecodes[self.eViolence]
	-- local s = g_LM.line(sOrderLC) .. ' (' .. g_LM.line(sTypeLC) .. ')'
	-- self.tToolTipTextInfos[1].sString = s
	-- -- security icon
    -- self.tToolTipTextInfos[1].sTextureSpriteSheet = 'UI/JobRoster'
    -- self.tToolTipTextInfos[1].sTexture = 'ui_jobs_iconJobResponse'
	-- -- beacon for hidden area?
	-- local sTargetName
	-- if not rTarget then
		-- -- beacon is in space, don't show a room name if so
	-- elseif ObjectList.getObjType(rTarget) == ObjectList.CHARACTER then
		-- sTargetName = rTarget.tStats.sName
	-- elseif rTarget.uniqueZoneName then
        -- local wx,wy = self.tx and g_World._getWorldFromTile(self.tx, self.ty)
        -- local bHidden = not wx or g_World.getVisibility(wx,wy) ~= g_World.VISIBILITY_FULL
        -- if not bHidden then
            -- sTargetName = rTarget.uniqueZoneName
        -- end
	-- end
	-- if sTargetName then
		-- self.tToolTipTextInfos[2].sString = sTargetName
	-- end
	-- return self.tToolTipTextInfos
-- end

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
	if not self.tBeacons[rChar:getSquadName()] then
		return false
	end
    if self.tBeacons[rChar:getSquadName()].tx and self.tBeacons[rChar:getSquadName()].ty then
        local tx,ty = g_World._getTileFromWorld(wx,wy)
        if tx == self.tBeacons[rChar:getSquadName()].tx and ty == self.tBeacons[rChar:getSquadName()].ty and beaconType == self.tBeacons[rChar:getSquadName()].tMode then
            return true
        end
    elseif self.tBeacons[rChar:getSquadName()].rTargetObject then
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

function EmergencyBeacon:getSaveTable() -- need to fix this
    local t = {}
    t.eViolence = self.eViolence
    t.tx = self.tx
    t.ty = self.ty
    t.nCount = self.nCount
    if self.tMode and self.tMode.spriteName then
        -- save out the mode
        t.spriteName = self.tMode.spriteName
    end
    if self.rTargetObject then
        local tTag = ObjectList.getTag(self.rTargetObject)
        if tTag then
            t.tTargetObjTag = ObjectList.getTagSaveData(tTag)
        end
    end
    return t
end

function EmergencyBeacon:fromSaveTable(t) -- need to fix this
    if t.eViolence ~= nil then
        self.eViolence = t.eViolence
    else
        self.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT
    end
    local bSet = false
    if t.tTargetObjTag then
        self.tTargetObjTag = t.tTargetObjTag 
        local rTargetObject = ObjectList.getObject(self.tTargetObjTag)
        if rTargetObject then
            self:attachTo(rTargetObject,t.ncount)
            bSet = true
        end
    end
    if not bSet and t.tx and t.ty then
        self:placeAt(t.tx,t.ty,t.nCount)
    end 
end

function EmergencyBeacon:charWaiting(rChar,dt)
    self:_testChar(rChar,'waited')
    self.tBeacons[rChar:getSquadName()].tChars[rChar].nWaitTime = self.tBeacons[rChar:getSquadName()].tChars[rChar].nWaitTime + dt
end

-- used for hints
-- function EmergencyBeacon:timeWaited() -- need to fix this
    -- local nMax=0
    -- if self.tBeacons[rChar.getSquadName()].tMode == EmergencyBeacon.MODE_EXPLORE then
        -- if self.tBeacons[rChar.getSquadName()].nCharsAtBeacon and 
			-- self.tBeacons[rChar.getSquadName()].nCount and 
			-- self.tBeacons[rChar.getSquadName()].nCharsAtBeacon < self.tBeacons[rChar.getSquadName()].nCount then
            -- for rChar,tData in pairs(self.tBeacons[rChar.getSquadName()].tChars) do
                -- if tData.nWaitTime and tData.nWaitTime > nMax then
                    -- nMax = tData.nWaitTime
                -- end
            -- end
        -- end
    -- end
    -- return nMax
-- end

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

-- function EmergencyBeacon:updatePropIndex()
    -- if self.tBeacons[rChar.getSquadName()].tMode and self.tBeacons[rChar.getSquadName()].tMode.spriteName and self.tBeacons[rChar.getSquadName()].nCount then
        -- self.tBeacons[rChar.getSquadName()]:setIndex(self.deck.names[self.tBeacons[rChar.getSquadName()].tMode.spriteName..self.tBeacons[rChar.getSquadName()].nCount])
    -- end
-- end

-- function EmergencyBeacon:_maxAllowedCount() 
    -- local tChars = CharacterManager.getOwnedCharacters()
    -- local nCount=0
    -- for _,rChar in ipairs(tChars) do
		-- if rChar.tStats.nTeam == Character.TEAM_ID_PLAYER and rChar:getJob() == Character.EMERGENCY then
            -- nCount=nCount+1
            -- if nCount > 4 then
                -- break
            -- end
        -- end
    -- end
    -- return math.max(nCount,1)
-- end

-- function EmergencyBeacon:_incrementCount(sSpriteName)
    -- self.tBeacons[rChar.getSquadName()].nCount = self.tBeacons[rChar.getSquadName()].nCount+1
    -- if self.tBeacons[rChar.getSquadName()].nCount > self:_maxAllowedCount() then
        -- self.tBeacons[rChar.getSquadName()].nCount = 1
    -- end
    -- self:updatePropIndex()
    -- self.tBeacons[rChar.getSquadName()].rActivityOption.tData.nMaxReservations = self.nCount
-- end

function EmergencyBeacon:placeAt(tx,ty,nCount)
	if not self.rSelectedSquad then
		print("EmergencyBeacon:placeAt() Error: No squad selected")
		return
	end
    local nTargetTeam = Room.getTeamAtTile(tx,ty,1)

    self:clearAttrLink(MOAIProp.INHERIT_LOC)
    local wx,wy = g_World._getWorldFromTile(tx,ty,1)
	if not self.tBeacons[self.rSelectedSquad.getName()] then
		print("EmergencyBeacon:placeAt() self.tBeacons["..self.rSelectedSquad.getName().."] not found")
		self:newBeacon(self.rSelectedSquad.getName())
	end
	self.tBeacons[self.rSelectedSquad.getName()]:setVisible(false)
	local tMode,tx,ty = self:_showPropAt(wx, wy, tx, ty, self.tBeacons[self.rSelectedSquad.getName()])
	-- nCount = nCount or 1
	self.tBeacons[self.rSelectedSquad.getName()].tx, self.tBeacons[self.rSelectedSquad.getName()].ty = tx, ty
	self.tBeacons[self.rSelectedSquad.getName()].rTargetObject = nil
	self.tBeacons[self.rSelectedSquad.getName()].tChars = {}
	self.tBeacons[self.rSelectedSquad.getName()].nCharsAtBeacon = 0
	self.tBeacons[self.rSelectedSquad.getName()].tMode = tMode
	self.tBeacons[self.rSelectedSquad.getName()].nTargetTeam = nTargetTeam
	self.tBeacons[self.rSelectedSquad.getName()].nCount = nCount or self.rSelectedSquad.getSize()
	-- self.tBeacons[self.rSelectedSquad.getName()]:setIndex(self.deck.names[tMode.spriteName..nCount])

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
        if rSquad.getName() == self.rSelectedSquad.getName() then
            return true
        else
            return false, 'not in squad'
        end
    end

	tData.nMaxReservations = self.rSelectedSquad.getSize()
    wx,wy = g_World._getWorldFromTile(tx,ty)
    if self.tBeacons[self.rSelectedSquad.getName()].tMode == EmergencyBeacon.MODE_TRAVELTO then
        local bOutside = g_World.isAdjacentToSpace(self.tBeacons[self.rSelectedSquad.getName()].tx,self.tBeacons[self.rSelectedSquad.getName()].ty,true,true)
        local sActivityName = (bOutside and 'ERCircleBeaconSpace') or 'ERCircleBeaconInside'
        tData.bInside = not bOutside
        tData.pathX,tData.pathY = wx,wy
        tData.pathToNearest = true
		self.tBeacons[self.rSelectedSquad.getName()].rActivityOption = ActivityOption.new(sActivityName, tData)
    elseif self.tBeacons[self.rSelectedSquad.getName()].tMode == EmergencyBeacon.MODE_BREACH then
    elseif self.tBeacons[self.rSelectedSquad.getName()].tMode == EmergencyBeacon.MODE_EXPLORE then
        local sActivityName = 'ERBeaconExplore'
        tData.pathX,tData.pathY = wx,wy
        tData.pathToNearest = true
		self.tBeacons[self.rSelectedSquad.getName()].rActivityOption = ActivityOption.new(sActivityName, tData)
    else
		self.tBeacons[self.rSelectedSquad.getName()].rActivityOption = nil
		self.tBeacons[self.rSelectedSquad.getName()]:setVisible(false)
    end
end

function EmergencyBeacon:attachTo(rTargetObject, nCount)
    local tx, ty, tz = rTargetObject:getTileLoc()
    local tMode = EmergencyBeacon.MODE_TRAVELTO
    local nTargetTeam = rTargetObject:getTeam()
    self.tBeacons[self.rSelectedSquad.getName()]:clearAttrLink(MOAIProp.INHERIT_LOC)
    self.tBeacons[self.rSelectedSquad.getName()]:setLoc(0, 400, 0)
    self.tBeacons[self.rSelectedSquad.getName()]:setAttrLink(MOAIProp.INHERIT_LOC, rTargetObject, MOAIProp.TRANSFORM_TRAIT)
    self.tBeacons[self.rSelectedSquad.getName()]:setVisible(true)
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

function EmergencyBeacon:needsMoreResponders(sSquadName)
	if not self.tBeacons[sSquadName] then
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
		k = nil
	end
    self:setVisible(false)
    self:clearAttrLink(MOAITransform.INHERIT_LOC)
end

function EmergencyBeacon:removeSelectedBeacon()
	if not self.rSelectedSquad or not self.tBeacons[self.rSelectedSquad.getName()] then
		return
	end
	self.tBeacons[self.rSelectedSquad.getName()]:clearAttrLink(MOAIProp.INHERIT_LOC)
	self.tBeacons[self.rSelectedSquad.getName()]:setVisible(false)
	self.tBeacons[self.rSelectedSquad.getName()] = nil
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
