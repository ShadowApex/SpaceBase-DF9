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
local tBeacons = {}

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

-- local function EmergencyBeacon:newBeacon(sSquadName)
	-- local beacon = Class.create(nil, MOAIProp.new)
	-- beacon.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT
	-- tBeacons[sSquadName] = beacon
-- end

function EmergencyBeacon:getActivityOption()
    return self.rActivityOption
end

function EmergencyBeacon:init()
    Room = require('Room')
    self.nCount=0
    self.deck = DFGraphics.loadSpriteSheet('UI/Beacon')
    self.tChars = {}
    
    self.eViolence = EmergencyBeacon.VIOLENCE_DEFAULT

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
	self.rSelectedSquad = rSquad
end

function EmergencyBeacon:onTick()
	if self.tMode == EmergencyBeacon.MODE_EXPLORE then
		local tRooms = Room.getRoomsOfTeam(self:getTargetTeam())
        if not next(tRooms) then
            self:remove()
        end
	end
end

function EmergencyBeacon:getModeAt(tx,ty)
    --if g_World._getVisibility(tx,ty,1) ~= g_World.VISIBILITY_HIDDEN then
    local rRoom = Room.getRoomAtTile(tx,ty,1,true)
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

    if rProp == self.rPreviewProp and self.tMode then
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
        rProp:setLoc(wx,wy,0)
    end

    self:updatePropIndex()

    return tMode,tx,ty
end

function EmergencyBeacon:getToolTipTextInfos()
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

function EmergencyBeacon:showAtTile(tx,ty)
    tx,ty = g_World.clampTileToBounds(tx,ty)
    local wx,wy = g_World._getWorldFromTile(tx,ty,1)
    return self:_showPropAt(wx, wy, tx, ty, self.rPreviewProp)
end

function EmergencyBeacon:showAtWorldPos(wx,wy)
    local tx,ty = g_World._getTileFromWorld(wx,wy)
    return self:_showPropAt(wx, wy, tx, ty, self.rPreviewProp)
end

-- Used by tasks to see if the beacon they started out for is still active.
function EmergencyBeacon:stillActive(wx,wy,rTargetObject,beaconType)
    if self.tx and self.ty then
        local tx,ty = g_World._getTileFromWorld(wx,wy)
        if tx == self.tx and ty == self.ty and beaconType == self.tMode then
            return true
        end
    elseif self.rTargetObject then
        if rTargetObject == self.rTargetObject and beaconType == self.tMode then
            return true
        end
    end
    return false
end

function EmergencyBeacon:charResponded(rChar)
    self.tChars[rChar] = {nWaitTime=0, bArrived=false}
end

function EmergencyBeacon:_testChar(rChar,sTest)
    if not self.tChars[rChar] then
        Print(TT_Warning,"Character "..sTest.." at beacon without first responding to it: "..rChar:getUniqueID())
        self:charResponded(rChar)
    end
end

function EmergencyBeacon:charArrived(rChar)
    self:_testChar(rChar,'arrived')
    self.tChars[rChar].bArrived = true
    local nArrived = 0
    for rChar,tData in pairs(self.tChars) do
        if tData.bArrived then
            nArrived = nArrived+1
        end
    end
    self.nCharsAtBeacon = nArrived
end

function EmergencyBeacon:getSaveTable()
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

function EmergencyBeacon:fromSaveTable(t)
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
    self.tChars[rChar].nWaitTime = self.tChars[rChar].nWaitTime + dt
end

-- used for hints
function EmergencyBeacon:timeWaited()
    local nMax=0
    if self.tMode == EmergencyBeacon.MODE_EXPLORE then
        if self.nCharsAtBeacon and self.nCount and self.nCharsAtBeacon < self.nCount then
            for rChar,tData in pairs(self.tChars) do
                if tData.nWaitTime and tData.nWaitTime > nMax then
                    nMax = tData.nWaitTime
                end
            end
        end
    end
    return nMax
end

function EmergencyBeacon:charAbandoned(rChar)
    self:_testChar(rChar,'abandoned')
    self.tChars[rChar] = nil
end

function EmergencyBeacon:charShouldWait(rChar)
    if self.tMode == EmergencyBeacon.MODE_TRAVELTO then
        return true
    else
        return self.nCharsAtBeacon < self.nCount
    end
end

function EmergencyBeacon:getTargetTeam()
    return self.nTargetTeam
end

function EmergencyBeacon:updatePropIndex()
    if self.tMode and self.tMode.spriteName and self.nCount then
        self:setIndex(self.deck.names[self.tMode.spriteName..self.nCount])
    end
end

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

function EmergencyBeacon:_incrementCount(sSpriteName)
    self.nCount = self.nCount+1
    if self.nCount > self:_maxAllowedCount() then
        self.nCount = 1
    end
    self:updatePropIndex()
    self.rActivityOption.tData.nMaxReservations = self.nCount
end

function EmergencyBeacon:placeAt(tx,ty,nCount)
	if not self.rSelectedSquad then
		print("EmergencyBeacon:placeAt() Error: No squad selected")
		return
	end
	-- if tBeacons[self.rSelectedSquad] then
		-- return
	-- end
	-- tBeacons[self.rSelectedSquad] = true
    local nTargetTeam = Room.getTeamAtTile(tx,ty,1)
	
	-- if squad has a beacon already, move it
	-- if squad has no beacon, place new
	--
	
	-- if tBeacons[self.rSelectedSquad] then
		-- nCount = tBeacons[self.rSelectedSquad]
	-- end
	
	if not tBeacons[self.rSelectedSquad] then
		tBeacons[self.rSelectedSquad] = table.getn(tBeacons) + 1
	end
	nCount = tBeacons[self.rSelectedSquad]

    self:clearAttrLink(MOAIProp.INHERIT_LOC)
    local wx,wy = g_World._getWorldFromTile(tx,ty,1)
    local tMode,tx,ty = self:_showPropAt(wx, wy, tx, ty, self)

    -- if self.tMode == tMode then
        -- if self.nTargetTeam and self.nTargetTeam ~= Character.TEAM_ID_PLAYER then
            -- A "ship explore" beacon is the same as long as you're targeting the same ship.
            -- if self.nTargetTeam == nTargetTeam then
                -- self:_incrementCount(tMode.spriteName)
                -- return
            -- end
        -- else
            -- if self.tx and self.ty and math.abs(self.tx-tx) < 2 and math.abs(self.ty-ty) < 2 then
                -- A "travel here" beacon is the same as long as you're targeting the same location, or close.
                -- self:_incrementCount(tMode.spriteName)
                -- return
            -- end
        -- end
    -- end

    -- looks like we've got a new beacon.
    -- self.nCount = nCount or 1
    self.tx,self.ty = tx,ty
    self.rTargetObject = nil
    self.tChars = {}
    self.nCharsAtBeacon = 0
    self.tMode = tMode
    self.nTargetTeam = nTargetTeam
    -- self:updatePropIndex()
	self:setIndex(self.deck.names[self.tMode.spriteName..self.nCount])

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
    if self.tMode == EmergencyBeacon.MODE_TRAVELTO then
        local bOutside = g_World.isAdjacentToSpace(self.tx,self.ty,true,true)
        local sActivityName = (bOutside and 'ERCircleBeaconSpace') or 'ERCircleBeaconInside'
        tData.bInside = not bOutside
        tData.pathX,tData.pathY = wx,wy
        tData.pathToNearest = true
        self.rActivityOption = ActivityOption.new(sActivityName, tData)
    elseif self.tMode == EmergencyBeacon.MODE_BREACH then
    elseif self.tMode == EmergencyBeacon.MODE_EXPLORE then
        local sActivityName = 'ERBeaconExplore'
        tData.pathX,tData.pathY = wx,wy
        tData.pathToNearest = true
        self.rActivityOption = ActivityOption.new(sActivityName, tData)
    else
        self.rActivityOption = nil
        self:setVisible(false)
    end
end

function EmergencyBeacon:attachTo(rTargetObject,nCount)
    local tx, ty, tz = rTargetObject:getTileLoc()
    local tMode = EmergencyBeacon.MODE_TRAVELTO
    local nTargetTeam = rTargetObject:getTeam()

    if self.tMode == tMode then
        if self.rTargetObject and self.rTargetObject == rTargetObject then
            self:_incrementCount(tMode.spriteName)
            return
        end
    end

    self:clearAttrLink(MOAIProp.INHERIT_LOC)
    self:setLoc(0,200,0)
    self:setAttrLink(MOAIProp.INHERIT_LOC, rTargetObject, MOAIProp.TRANSFORM_TRAIT)
    self:setVisible(true)
    self:updatePropIndex()

    -- looks like we've got a new beacon.
    self.nCount = nCount or 1
    self.tx, self.ty = nil, nil
    self.rTargetObject = rTargetObject
    self.tChars = {}
    self.nCharsAtBeacon = 0
    self.tMode = tMode
    self.nTargetTeam = nTargetTeam
    self:updatePropIndex()

    local tData = {}
    tData.utilityGateFn = function(rChar) 
        -- if beacon is attached to you, you can't respond to it.
        if rChar ~= rTargetObject and rChar:getJob() == Character.EMERGENCY then
            return true
        else
            return false, 'not an ER or is themselves the target'
        end
    end

    local wx,wy = g_World._getWorldFromTile(tx,ty,1)

    local bOutside = g_World.isAdjacentToSpace(tx, ty, true, true)
    local sActivityName = (bOutside and 'ERCircleBeaconSpace') or 'ERCircleBeaconInside'
    tData.bInside = not bOutside
    tData.nMaxReservations = self.nCount
    tData.rTargetObject = rTargetObject
    tData.pathToNearest = true
    self.rActivityOption = ActivityOption.new(sActivityName, tData)
end

function EmergencyBeacon:needsMoreResponders()
    if self.tMode and self.rActivityOption then
        if (self.rActivityOption.tData.nMaxReservations or 1) > (self.rActivityOption.nReservations or 0) then
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
    self.rActivityOption = nil
    self:setVisible(false)
    self:clearAttrLink(MOAITransform.INHERIT_LOC)
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
