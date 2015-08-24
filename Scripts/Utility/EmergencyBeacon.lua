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
    
    -- self.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT

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

function EmergencyBeacon:newBeacon(sSquadName)
	print("EmergencyBeacon:newBeacon(sSquadName): "..sSquadName)
	local beacon = MOAIProp.new()
	beacon:setDeck(self.deck)
	Renderer.getRenderLayer(EmergencyBeacon.RENDER_LAYER):insertProp(beacon)
	beacon:setVisible(false)
	beacon:setScl(1.5, 1.5, 1.5)
	beacon:setColor(unpack(Gui.AMBER))
	beacon.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT
	self.tBeacons[sSquadName] = beacon
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

function EmergencyBeacon:getToolTipTextInfos() -- need to fix this
	-- hovering in inspect mode, show nature and target of beacon order, eg
	-- Secure Room (Lethal Force):
	-- The Rusty Killbot
	self.tToolTipTextInfos = {}
	self.tToolTipTextInfos[1] = {}
	self.tToolTipTextInfos[2] = {}
	self.tToolTipTextInfos[3] = {}
	-- character or room?
	local rTarget = self.rTargetObject
	local sOrderLC
	if not rTarget then
		assertdev(self.tx ~= nil)
        if self.tx == nil then return {} end
		rTarget = Room.getRoomAtTile(self.tx, self.ty, 1, true)
		sOrderLC = 'UIMISC037TEXT'
	else
		sOrderLC = 'UIMISC035TEXT'
		if not Base.isFriendlyToPlayer(rTarget) then
			sOrderLC = 'UIMISC036TEXT'
		end
	end
	local sTypeLC = EmergencyBeacon.tBeaconTypeLinecodes[self.eViolence]
	local s = g_LM.line(sOrderLC) .. ' (' .. g_LM.line(sTypeLC) .. ')'
	self.tToolTipTextInfos[1].sString = s
	-- security icon
    self.tToolTipTextInfos[1].sTextureSpriteSheet = 'UI/JobRoster'
    self.tToolTipTextInfos[1].sTexture = 'ui_jobs_iconJobResponse'
	-- beacon for hidden area?
	local sTargetName
	if not rTarget then
		-- beacon is in space, don't show a room name if so
	elseif ObjectList.getObjType(rTarget) == ObjectList.CHARACTER then
		sTargetName = rTarget.tStats.sName
	elseif rTarget.uniqueZoneName then
        local wx,wy = self.tx and g_World._getWorldFromTile(self.tx, self.ty)
        local bHidden = not wx or g_World.getVisibility(wx,wy) ~= g_World.VISIBILITY_FULL
        if not bHidden then
            sTargetName = rTarget.uniqueZoneName
        end
	end
	if sTargetName then
		self.tToolTipTextInfos[2].sString = sTargetName
	end
	return self.tToolTipTextInfos
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
        return self.tBeacons[rChar:getSquadName()].nCharsAtBeacon < self.tBeacons[rChar:getSquadName()].nCount
    end
end

-- function EmergencyBeacon:getTargetTeam(tBeacon) -- need to fix this
    -- return self.tBeacons[rChar.getSquadName()].nTargetTeam
-- end

-- function EmergencyBeacon:updatePropIndex()
    -- if self.tBeacons[rChar.getSquadName()].tMode and self.tBeacons[rChar.getSquadName()].tMode.spriteName and self.tBeacons[rChar.getSquadName()].nCount then
        -- self.tBeacons[rChar.getSquadName()]:setIndex(self.deck.names[self.tBeacons[rChar.getSquadName()].tMode.spriteName..self.tBeacons[rChar.getSquadName()].nCount])
    -- end
-- end

function EmergencyBeacon:_maxAllowedCount() 
    local tChars = CharacterManager.getOwnedCharacters()
    local nCount=0
    for _,rChar in ipairs(tChars) do
		if rChar.tStats.nTeam == Character.TEAM_ID_PLAYER and rChar:getJob() == Character.EMERGENCY then
            nCount=nCount+1
            if nCount > 4 then
                break
            end
        end
    end
    return math.max(nCount,1)
end

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
	nCount = nCount or table.getn(self.tBeacons)
	self.tBeacons[self.rSelectedSquad.getName()].tx, self.tBeacons[self.rSelectedSquad.getName()].ty = tx, ty
	self.tBeacons[self.rSelectedSquad.getName()].rTargetObject = nil
	self.tBeacons[self.rSelectedSquad.getName()].tChars = {}
	self.tBeacons[self.rSelectedSquad.getName()].nCharsAtBeacon = 0
	self.tBeacons[self.rSelectedSquad.getName()].tMode = tMode
	self.tBeacons[self.rSelectedSquad.getName()].nTargetTeam = nTargetTeam
	self.tBeacons[self.rSelectedSquad.getName()]:setIndex(self.deck.names[tMode.spriteName..nCount])

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
	if not self.rSelectedSquad then
		return
	end
    local tx, ty, tz = rTargetObject:getTileLoc()
    local tMode = EmergencyBeacon.MODE_TRAVELTO
    local nTargetTeam = rTargetObject:getTeam()

    -- if self.tMode == tMode then
        -- if self.rTargetObject and self.rTargetObject == rTargetObject then
            -- self:_incrementCount(tMode.spriteName)
            -- return
        -- end
    -- end

    self:clearAttrLink(MOAIProp.INHERIT_LOC)
    self:setLoc(0,200,0)
    self:setAttrLink(MOAIProp.INHERIT_LOC, rTargetObject, MOAIProp.TRANSFORM_TRAIT)
    self:setVisible(true)
    -- self:updatePropIndex()

    -- looks like we've got a new beacon.
    nCount = nCount or table.getn(self.tBeacons)
    -- self.tx, self.ty = nil, nil
    -- self.rTargetObject = rTargetObject
    -- self.tChars = {}
    -- self.nCharsAtBeacon = 0
    -- self.tMode = tMode
    -- self.nTargetTeam = nTargetTeam
	self.tBeacons[self.rSelectedSquad.getName()].tx, self.tBeacons[self.rSelectedSquad.getName()].ty = tx, ty
	self.tBeacons[self.rSelectedSquad.getName()].rTargetObject = nil
	self.tBeacons[self.rSelectedSquad.getName()].tChars = {}
	self.tBeacons[self.rSelectedSquad.getName()].nCharsAtBeacon = 0
	self.tBeacons[self.rSelectedSquad.getName()].tMode = tMode
	self.tBeacons[self.rSelectedSquad.getName()].nTargetTeam = nTargetTeam
	self.tBeacons[self.rSelectedSquad.getName()]:setIndex(self.deck.names[tMode.spriteName..nCount])

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

    local wx,wy = g_World._getWorldFromTile(tx, ty, 1)

	local bOutside = g_World.isAdjacentToSpace(self.tBeacons[self.rSelectedSquad.getName()].tx, self.tBeacons[self.rSelectedSquad.getName()].ty, true, true)
	local sActivityName = (bOutside and 'ERCircleBeaconSpace') or 'ERCircleBeaconInside'
    tData.nMaxReservations = self.rSelectedSquad.getSize()
    tData.rTargetObject = rTargetObject
    tData.pathToNearest = true
	tData.bInside = not bOutside
	tData.pathX, tData.pathY = wx, wy
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
    self.tx,self.ty = nil,nil
    self.rTargetObject = nil
    self.tMode = nil
    self.rPreviewProp:setVisible(false)
	for k,v in pairs(self.tBeacons) do
		v:setVisible(false)
		k = nil
	end
    -- self:setVisible(false)
    self:clearAttrLink(MOAITransform.INHERIT_LOC)
end

function EmergencyBeacon:removeSelectedBeacon()
	if not self.rSelectedSquad then
		return
	end
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

function EmergencyBeacon:getViolenceMode()
end

function EmergencyBeacon:setViolenceMode(eMode)
end

return EmergencyBeacon
