local DFFile = require('DFCommon.File')
local Renderer = require('Renderer')
local MiscUtil = require('MiscUtil')
local Room = nil
local GameRules = nil

local SoundManager = {
    profilerName='SoundManager',
}

SoundManager.tFlags = {
	DebugOverrides = false,
}

SoundManager.introMusic = "Music/Music/Intro_GuitarTrack"

local tMusicCues = {
    { base = "Music/Music/SpaceBase_Track1", },
    { base = "Music/Music/SpaceBase_Track3", },
    { base = "Music/Music/SpaceBase_Track4", },
    { base = "Music/Music/SpaceBase_Track5", },
}

SoundManager.rExteriorAmbienceInstance = nil    -- current playEvent2D reference for ambience
SoundManager.nExteriorAmbienceTime = 0          -- ticked time for ambience
SoundManager.nMusicTime = 0             -- ticked time for music
SoundManager.nZoomDepth = 1 --2.5           -- current zoom depth (for tweaking volumes)
SoundManager.AMBIENCE_TIME = 500        -- time before switching ambience tracks
SoundManager.MUSIC_TIME = 400          -- time before switching music tracks
SoundManager.MUSIC_SILENCE_TIME = 450   -- time of silence between tracks
SoundManager.bBetweenTracks = false

local tAmbiences = {
    "SFX/Ambience/Ambience_A", 
    "SFX/Ambience/Ambience_B", 
    "SFX/Ambience/Ambience_C", 
    "SFX/Ambience/Ambience_D", 
    "SFX/Ambience/Ambience_E",
}

local tSfx = 
{
    --UI
    degauss = "UI/NewUI/UI_Static",
    selectdegauss = "UI/NewUI/UI_SelectDegauss", --selecting construct / mine and such
    disallow = "UI/NewUI/UI_Disallow", --can't buy, etc    
    hilight = "UI/NewUI/UI_Hilight", --scrolling over tabs
    sidebarexpand = "UI/NewUI/UI_Expand",
    showgrid = "UI/NewUI/UI_GridShow",
    select = "UI/NewUI/UI_Select",
    confirm = "UI/NewUI/UI_Confirm",
    inspectorshow = "UI/NewUI/UI_InspectorShow", --1 time sound when the inspector 1st appears
    inspectortab = "UI/NewUI/UI_InspectorFolder", --clicking a folder in the inspector tab
    inspectorduty = "UI/NewUI/UI_InspectorDuty", --assigning a duty with the inspector
    inspectordoornormal = "UI/NewUI/UI_DoorNormal", --selecting door normal
    inspectordoorlock = "UI/NewUI/UI_DoorLock", --selecting door locked
    inspectordoorlockdown = "UI/NewUI/UI_DoorLock_PDown", --selecting door locked
    buildscroll = "UI/NewUI/UI_BuildScroll", --making new areas in contrust mode, clicking and dragging
    mattercounter = "UI/NewUI/UI_MatterScroll", --digit counter sfx
    placebeacon = "UI/NewUI/UI_PlaceBeacon", --selecting beacon
    clearbeacon = "UI/NewUI/UI_ClearBeacon", --selecting clear beacon
    claim = "UI/NewUI/UI_Claim", --selecting claim
    unclaim = "UI/NewUI/UI_UnClaim", --selecting unclaim
    
    --Intro SFX
    accept = 'UI/Intro/Intro_AcceptButton', --hitting the accept or decline button
    cancel = 'UI/Intro/Intro_CancelButton', --hitting the cancel button at the bottom
    launchbutton ='UI/Intro/Intro_LaunchButton', --hitting the launch button
    launchopen = 'UI/Intro/Intro_LaunchOpen', --when the launch door slides open
    launchclose = 'UI/Intro/Intro_LaunchClose', --when the launch door closes
    cursorappear = 'UI/Intro/Intro_ScreenAppear', --when the screen and cursor appear since they happen at the same time
    previewappear = 'UI/Intro/Intro_UIAppear', --when clicking on the map and the side ui appears
    previewdissappear = 'UI/Intro/Intro_UIDissappear', --when the side ui goes away
    
    --place object sounds
    placeairlock = 'UI/PlaceObject/PlaceAirlock',
    placebar = 'UI/PlaceObject/PlaceBar',
    placebed ='UI/PlaceObject/PlaceBed',
    placedoor = 'UI/PlaceObject/PlaceDoor',
    placedresser = 'UI/PlaceObject/PlaceDresser',
    placefirepanel = 'UI/PlaceObject/PlaceFireExtinguisher',
    placemonitor = 'UI/PlaceObject/PlaceMonitor',
    placeplant = 'UI/PlaceObject/PlacePlant',
    placereactor = 'UI/PlaceObject/PlaceReactor',
    placereactorserver = 'UI/PlaceObject/PlaceReactorServer',
    placereactortile = 'UI/PlaceObject/PlaceReactorTile',
    placerecycler = 'UI/PlaceObject/PlaceRecycler',
    placeoxygenfilter = 'UI/PlaceObject/PlaceOxygenFilter',
    placerefinery = 'UI/PlaceObject/PlaceRefinery',
    placerug = 'UI/PlaceObject/PlaceRug',
    placespacesuitlocker = 'UI/PlaceObject/PlaceSuitLocker',
    placewall = "UI/Build/PlaceWall",
    placehydroplant = 'UI/PlaceObject/PlaceHydroPlant',
    placefoodreplicator = 'UI/PlaceObject/PlaceFoodReplicator',
    placetable = 'UI/PlaceObject/PlaceTable',
    placestove = 'UI/PlaceObject/PlaceStove',
    placefridge = 'UI/PlaceObject/PlaceFridge',
    placeneon = 'UI/PlaceObject/PlaceNeon',
        
    --old
    menu = "UI/UI/Menu",
    jobs = "UI/UI/Jobs",
    done = "UI/UI/Done",    
    inspect = "UI/Inspect/Inspect",
    rezone = "UI/Inspect/ReZone",
    clickairlock = "UI/Inspect/Airlock",
    clicklifesupport = "UI/Inspect/LifeSupport",
    clickreactor = "UI/Inspect/Reactor",
    clickresidence = "UI/Inspect/Residence",
    clickunzoned = "UI/Inspect/Unzoned",
    fireextinguisher = "UI/Inspect/FireExtinguisher",
    assignnewduty = "UI/Inspect/AssignNewDuty",
    spacesuitlocker = "UI/Inspect/SpacesuitLocker",
    spacebed = "UI/Inspect/SpaceBed",
    spacedoor = "UI/Inspect/SpaceDoor",
    doorlocked = "UI/Inspect/Locked",
    doornormal = "UI/Inspect/Unlocked",
    doorforcedopen = "UI/Inspect/ForcedOpen",
    oxygenrecycler = "UI/Inspect/OxygenRecycler",
    fusionreactor = "UI/Inspect/FusionReactor",
    build = "UI/Build/Build",
    area = "UI/Build/Build",
    wall = "UI/Build/Wall",
    door = "UI/Build/Door",
    airlock = "UI/Build/Airlock",
    vaporize = "UI/Build/Vaporize",
    unemployed = "UI/Inspect/Unemployed",
    builder = "UI/Inspect/Builder",
    technician = "UI/Inspect/Technician",
    
    --3D Sounds
    reactorloop = "SFX/Ambience/ReactorLoop",
    refineryloop = "SFX/Ambience/RefineryLoop",
    oxygenrecyclerloop = "SFX/Ambience/OxygenRecyclerLoop",
    fireloop = "SFX/SFX/FireLoop",
    firestart = "SFX/SFX/FireStartExtra",    
    dooropen = "SFX/SFX/DoorOpen",    
    doorclose = "SFX/SFX/DoorClose",    
    airlockdooropen = "SFX/SFX/AirlockDoorOpen",    
    airlockdoorclose = "SFX/SFX/AirlockDoorClose",    
    spacesuit = "SFX/SFX/Spacesuit",

    takedamagedefault = "SFX/SFX/Brawl_Impact",
    takedamagelaser = "SFX/SFX/Laser_Impact",
    takedamagetaser = "SFX/SFX/Taser_Impact",

    wallexplode = "SFX/SFX/WallExplode", --walls exploding sfx
    spacetaxi = "SFX/SFX/SpaceTaxi", --spacetaxi cutscene
    spacetaxienter = "SFX/SFX/SpaceTaxi_Enter", --taxi appears in the distance
    spacetaxidropoff = "SFX/SFX/SpaceTaxi_DropOff", --people get out of the taxi
    spacetaxileave = "SFX/SFX/SpaceTaxi_Leave", -- taxi takes off
    fridgeopen = "SFX/SFX/FridgeOpen",
    fridgeclose = "SFX/SFX/FrideClose",
    derelictdocking = "SFX/SFX/Derelict_Docking",
    powerup = "SFX/SFX/PowerUp",
    powerdown = "SFX/SFX/PowerDown",
    raiderdocking = "SFX/SFX/Raider_Docking",
    raiderdrill = "SFX/SFX/Raider_Drill",
    raiderengineloop = "SFX/SFX/Raider_EngineLoop",
    turretgunswivel = "SFX/SFX/TurretGun_Swivel",
    turretgunfire = "SFX/SFX/TurretGun_Fire",

    -- rooms
    room_alert = "SFX/SFX/Alarm_Alert",
    room_breach = "SFX/SFX/Alarm_Breach",
    room_fire = "SFX/SFX/Alarm_Fire",
    room_lowoxygen = "SFX/SFX/Alarm_LowOxygen", 
    room_walla_bad = "SFX/Ambience/Walla_Negative", 
    room_walla_good = "SFX/Ambience/Walla_Positive", 

    --Jukebox
    jukebox_music = "SpaceBaseV2/Jukebox/music01"
}

----------------------
-- STATIC FUNCTIONS
----------------------
-- initialize the sound manager
function SoundManager.initialize( tSoundProjects )
    
    if MOAIFmodEventMgr == nil then
        return
    end

    if SoundManager.tAmbiences then
        for k,v in pairs(SoundManager.tAmbiences) do
            if v.instance then
                v.instance:stop()
                v.instance = nil
            end
        end
    end
    
    Room = require('Room')
    GameRules = require('GameRules')
    -- Initialize the sound system
	if not MOAIFmodEventMgr.isEnabled() then
		local tInitParams =
		{
			voiceLRUMaxMB = 12,
			voiceLRUBufferMB = 2,       
            enableAuditioning = true,
		}
        MOAIFmodEventMgr.init( tInitParams )
		if tSoundProjects.tFEV then
			for _, sProject in pairs( tSoundProjects.tFEV ) do
                print(string.format("Loading project %s", sProject))
				MOAIFmodEventMgr.loadProject( DFFile.getAudioPath( sProject ) )    
			end
		end
		
		if tSoundProjects.tFSB then
			for _,sProject in ipairs( tSoundProjects.tFSB ) do
				MOAIFmodEventMgr.loadVoiceProject( DFFile.getAudioPath( sProject ) )
			end	
		end
		
		-- initialize the mic and then set it to follow the transform of the prop
		local rMic = MOAIFmodEventMgr.getMicrophone() 
		rMic:setAttrLink( MOAITransform.ATTR_X_LOC, Renderer.getGameplayCamera(), MOAITransform.ATTR_X_LOC )
        rMic:setAttrLink( MOAITransform.ATTR_Y_LOC, Renderer.getGameplayCamera(), MOAITransform.ATTR_Y_LOC )
	end
    
    -- set volume levels
    SoundManager.setCategoryVolume ( "sfx", g_Config:getConfigValue("sfx_volume"))   
    SoundManager.setCategoryVolume ( "voice", g_Config:getConfigValue("voice_volume"))
    SoundManager.setCategoryVolume ( "music", g_Config:getConfigValue("music_volume"))
    SoundManager.setCategoryVolume ( "ambience", g_Config:getConfigValue("sfx_volume"))
    SoundManager.setCategoryVolume ( "ui", g_Config:getConfigValue("sfx_volume"))
    
    SoundManager.tAmbiences=
    {
        Interior={cue='SFX/Ambience/InteriorAmbience'},
    }
    for k,v in pairs(SoundManager.tAmbiences) do
        v.instance = MOAIFmodEventMgr.playEvent2D(v.cue)
        v.instance:pause(true)
    end

    SoundManager._fromScratch()
end

function SoundManager._fromScratch()
    if SoundManager.tMusicEventInstance then
        SoundManager.stopMusic()
    end
    SoundManager.tMusicEventInstance = {}
    SoundManager.currentMusicCue = math.random( 1, #tMusicCues ) -- Initial music choice is random
    SoundManager.currentExteriorAmbience = math.random( 1, #tAmbiences )
    SoundManager.layerLevels =
    {
        base = { currentLevel = 0, desiredLevel = 1, lerpScale = .05 },
    }
    SoundManager.addDisplayFunctions()    
    SoundManager.disasterNotifyLength = 1000
    SoundManager.timeToDeactivateDisasterNotify = SoundManager.disasterNotifyLength
    SoundManager.disasterActive = false
end

function SoundManager.addDisplayFunctions()
    for layer, level in pairs(SoundManager.layerLevels) do
        function level.displayLevel()
            return SoundManager.convertToDisplay(layer)
        end
    end
end

function SoundManager.playMenuMusic()
    SoundManager.stopMusic()
    SoundManager.tMusicEventInstance[1] = MOAIFmodEventMgr.playEvent2D( SoundManager.introMusic )
end

function SoundManager.playMusic( currentMusicCue )
    SoundManager.bBetweenTracks = false
    SoundManager.stopMusic()
    for layer, level in pairs( SoundManager.layerLevels ) do
        level.currentLevel = 0
    end
    for layer, path in pairs( tMusicCues[SoundManager.currentMusicCue] ) do
        SoundManager.tMusicEventInstance[layer] = MOAIFmodEventMgr.playEvent2D( path )
    end
end

function SoundManager.stopMusic( )
    SoundManager.bBetweenTracks = false
    for name, track in pairs(SoundManager.tMusicEventInstance) do
        track:stop()
    end
end

function SoundManager.playAmbience( currentExteriorAmbience )
    if SoundManager.rExteriorAmbienceInstance then SoundManager.rExteriorAmbienceInstance:stop() end
    SoundManager.rExteriorAmbienceInstance = MOAIFmodEventMgr.playEvent2D( tAmbiences[currentExteriorAmbience] )
    SoundManager.setZoomLevel(SoundManager.nZoomDepth)
    SoundManager.currentExteriorAmbience = currentExteriorAmbience
end

function SoundManager.disablePlayback()
    MOAIFmodEventMgr.stopAllEvents()
end

function SoundManager.shutdown()
    SoundManager.stopMusic()
    if SoundManager.rExteriorAmbienceInstance then
        SoundManager.rExteriorAmbienceInstance:stop()
        SoundManager.rExteriorAmbienceInstance = nil
   end
end

function SoundManager.incrementTrack( )        
    if SoundManager.bBetweenTracks then
        SoundManager.bBetweenTracks = false
        if SoundManager.currentMusicCue >= #tMusicCues then
            SoundManager.currentMusicCue = 1
        elseif SoundManager.currentMusicCue > 0 then
            SoundManager.currentMusicCue = SoundManager.currentMusicCue + 1
        else
            SoundManager.currentMusicCue = 1
        end    
        SoundManager.playMusic( SoundManager.currentMusicCue )
    else
        SoundManager.stopMusic()
        SoundManager.bBetweenTracks = true
    end
    
end

function SoundManager.setZoomLevel(value)
    SoundManager.nZoomDepth = value
    if SoundManager.rExteriorAmbienceInstance ~= nil then
        SoundManager.rExteriorAmbienceInstance:setParameter('Depth', 1-value)
        SoundManager.rExteriorAmbienceInstance:setVolume(1-value)
    end
end

function SoundManager.updateAmbiences()
    -- Simple sampling method of selecting ambiences & volumes.
    local nSamplesX,nSamplesY = 3,3
    for k,v in pairs(SoundManager.tAmbiences) do
        v.volume = 0
    end
	local worldLayer = g_World.getWorldRenderLayer()
    local nWorldMinX,nWorldMinY = worldLayer:wndToWorld(20,20)
    local nWorldMaxX,nWorldMaxY = worldLayer:wndToWorld(kVirtualScreenWidth-20,kVirtualScreenHeight-20)
    local nIncX,nIncY = (nWorldMaxX-nWorldMinX)/nSamplesX,(nWorldMaxY-nWorldMinY)/nSamplesY
    local nWeight = 1/(nSamplesX*nSamplesY)
    
    for x=0,nSamplesX-1 do
        for y=0,nSamplesY-1 do
	        local wx,wy = nWorldMinX+nIncX*x,nWorldMinY+nIncY*y
            local _,tRooms = Room.getRoomAt(wx,wy,0,1,true)
            local k = next(tRooms)
            if k then
                -- get ambience params from tRooms[k]
                local sAmbience = 'Interior'
                SoundManager.tAmbiences[sAmbience].volume = SoundManager.tAmbiences[sAmbience].volume + nWeight
            end
        end
    end
    local nZoomScale = SoundManager.nZoomDepth
    
    for k,v in pairs(SoundManager.tAmbiences) do
        v.instance:setVolume(v.volume * nZoomScale)
        v.instance:pause(v.volume == 0)
        v.instance:setVolume(v.volume * nZoomScale)
    end
end

function SoundManager.convertToDisplay(layer)
    return math.ceil(SoundManager.layerLevels[layer].desiredLevel * 100)
end

function SoundManager.playSfx( sfxCue )
    return MOAIFmodEventMgr.playEvent2D( tSfx[sfxCue] )
end

function SoundManager.playSfx3D( sfxCue, x, y, z )
    print(string.format("playing sound %s", sfxCue))
    return MOAIFmodEventMgr.playEvent3D( tSfx[sfxCue], x, y, z )
end

function SoundManager.loadSaveData(tMusicSaveData)
    if tMusicSaveData then
        SoundManager.layerLevels = tMusicSaveData.layerLevels
        SoundManager.playMusic( tMusicSaveData.currentMusicCue )
        SoundManager.playAmbience( tMusicSaveData.currentExteriorAmbience )
        SoundManager.addDisplayFunctions()    
    else
        SoundManager.playMusic( SoundManager.currentMusicCue )
        SoundManager.playAmbience( SoundManager.currentExteriorAmbience )
    end
end

function SoundManager.loadModule(tMusicSaveData)
    SoundManager.loadSaveData(tMusicSaveData)
end

function SoundManager.setCategoryVolume( category, volume )
    MOAIFmodEventMgr.setSoundCategoryVolume( category, volume )
end

function SoundManager.getSaveData()
    local tMusicSaveData = {}
    local tLayerLevels={}

    for layer, level in pairs(SoundManager.layerLevels) do
        tLayerLevels[layer] = MiscUtil.deepCopyData(level)
    end

    tMusicSaveData.layerLevels = tLayerLevels
    tMusicSaveData.currentMusicCue = SoundManager.currentMusicCue
    tMusicSaveData.nZoomDepth = SoundManager.nZoomDepth
    return tMusicSaveData
end    

function SoundManager.onTick( dt )

    -- change the exterior ambient track every few minutes
    SoundManager.nExteriorAmbienceTime = SoundManager.nExteriorAmbienceTime + dt
    SoundManager.nMusicTime = SoundManager.nMusicTime + dt
    if GameRules.bRunning then
        SoundManager.updateAmbiences()
    
        if not SoundManager.rExteriorAmbienceInstance or SoundManager.nExteriorAmbienceTime > SoundManager.AMBIENCE_TIME then
            SoundManager.playAmbience(math.random(1,#tAmbiences))
            SoundManager.nExteriorAmbienceTime = 0
        end
    end
        if SoundManager.bBetweenTracks then --if between tracks...
            if SoundManager.nMusicTime > SoundManager.MUSIC_SILENCE_TIME then                
                SoundManager.incrementTrack()
                SoundManager.nMusicTime = 0
            end
        else
            if SoundManager.nMusicTime > SoundManager.MUSIC_TIME then
                SoundManager.incrementTrack()
                SoundManager.nMusicTime = 0
            end
        end
end

return SoundManager
