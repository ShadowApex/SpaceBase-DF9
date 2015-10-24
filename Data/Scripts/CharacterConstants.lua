local Class=require('Class')
local Gui=require('UI.Gui')

local CharacterConstants = Class.create(nil, MOAIProp.new)

CharacterConstants.NUM_VARIATIONS = 10
CharacterConstants.DIR_ROT = 
{
    S=0,
    SE=45,
    E=90,
    NE=135,
    N=180,
    NW=225,
    W=270,
    SW=315,
}

CharacterConstants.ROT_DIR=
{
    {15,'SE'},
    {75,'E'},
    {105,'NE'},
    {165,'N'},
    {195,'NW'},
    {255,'W'},
    {285,'SW'},
    {345,'S'},
}

CharacterConstants.PERSONALITY_TRAITS=
{
    -- NOTE: numeric or boolean type is inferred from first character,
    -- so always use hungarian notation for these
    
    -- 1 = brave, 0 = coward
    nBravery=1,
    -- 1 = gregarious, 0 = shy
    nGregariousness=2,
    -- 1 = chatty, 0 = quiet
	nChattiness=3,
    -- 1 = neat, 0 = slob
    nNeatness=4,
    -- uses emoticons
    bEmoticon=5,
    -- insecure (doubts self, body image, etc)
    -- REMOVED: now handled as self-affinity
    --bInsecure=6,
    -- 1 = angry/violent, 0 = chill/pacifist
    nTemper=7,
    -- 1 = hardworking, 0 = lazy
    nWorkEthic=8,
    -- fear/suspicion of different people
    bXenophobe=9,
    -- worries about things
    bAnxious=10,
    -- high standards for food
    bGourmand=11,
    -- likes to crack jokes
    bJoker=12,
    -- thinks about the past
    bSentimental=13,
    -- thinks they're the best
    -- REMOVED: now handled as self-affinity
    --bEgoist=14,
    -- cares about getting ahead, being the best
    bCompetitive=15,
    -- types in all lowercase
    bLowerCase=16,
    -- cares about being cool
    bHipster=17,
    -- 1 = positive outlook, 0 = negative outlook
    nPositivity=18,
	-- 1 = obedient, 0 = rebellious
	nAuthoritarian=19,
}
CharacterConstants.PERSONALITY_LINE=
{
    nBravery = { nHigh='PERSON001TEXT', nLow='PERSON008TEXT' },
    nGregariousness = { nHigh='PERSON002TEXT', nLow='PERSON009TEXT' },
    nChattiness = { nHigh='PERSON003TEXT', nLow='PERSON010TEXT' },
    nNeatness = { nHigh='PERSON004TEXT', nLow='PERSON011TEXT' },
    nTemper = { nHigh='PERSON012TEXT', nLow='PERSON013TEXT' },
    nWorkEthic = { nHigh='PERSON014TEXT', nLow='PERSON015TEXT' },
    nPositivity = { nHigh='PERSON016TEXT', nLow='PERSON017TEXT' },
	nAuthoritarian = { nHigh='PERSON027TEXT', nLow='PERSON028TEXT', },
}
CharacterConstants.QUIRK_LINE=
{
	bXenophobe = 'PERSON018TEXT',
	bAnxious = 'PERSON020TEXT',
	bGourmand = 'PERSON021TEXT',
	bJoker = 'PERSON019TEXT',
	bSentimental = 'PERSON022TEXT',
	bCompetitive = 'PERSON023TEXT',
	bHipster = 'PERSON024TEXT',
}
CharacterConstants.PERSONALITY_LIKELIHOOD=
{
    -- some boolean traits should be more or less common,
    -- chance (1.0 = 100%) is specified here
    bEmoticon = 0.1,
    bJoker = 0.2,
    bXenophobe = 0.1,
    bHipster = 0.2,
    bLowerCase = 0.05,
	bCompetitive = 0.3,
}
CharacterConstants.PERSONALITY_ADJECTIVE_LINE=
{
    { nMin = 0, linecode = 'PERSON007TEXT', },
    { nMin = 0.35, linecode = 'PERSON006TEXT', },
	{ nMin = 0.5, linecode = 'PERSON026TEXT', },
    { nMin = 0.85, linecode = 'PERSON005TEXT', },
}
CharacterConstants.SELF_ESTEEM_LINE=
{
    { nMin = -10, linecode = 'INSPEC128TEXT', },
    { nMin = -8, linecode = 'INSPEC129TEXT', },
    { nMin = -5, linecode = 'INSPEC130TEXT', },
    { nMin = -3, linecode = 'INSPEC131TEXT', },
    { nMin = -1, linecode = 'INSPEC132TEXT', },
    { nMin = 1, linecode = 'INSPEC133TEXT', },
    { nMin = 3, linecode = 'INSPEC134TEXT', },
    { nMin = 5, linecode = 'INSPEC135TEXT', },
    { nMin = 8, linecode = 'INSPEC136TEXT', },
    { nMin = 10, linecode = 'INSPEC137TEXT', },
}

CharacterConstants.TEAM_ID_NONE = 0
CharacterConstants.TEAM_ID_PLAYER = 1
CharacterConstants.TEAM_ID_DEBUG_ENEMYGROUP = -2
CharacterConstants.TEAM_ID_PLAYER_ABANDONED = 3
CharacterConstants.TEAM_ID_DEBUG_MONSTER = -3
CharacterConstants.TEAM_ID_DEBUG_FRIENDLY = -4
CharacterConstants.TEAM_ID_FIRST_USABLE = 100

CharacterConstants.FACTION_BEHAVIOR=
{
    Citizen=1,
    Monster=2,
    Friendly=3,
    EnemyGroup=4,
	-- custom killbot faction, only used for debug purposes right now
	KillBot=5,
    Trader=6,
}

CharacterConstants.THREAT_LEVEL=
{
    None=0,
    NormalCitizen=1,
    BadCitizen=3,
    Raider=3,
    Turret=3,
    Monster=4,
}

CharacterConstants.ATTACK_TYPE=
{
    Grapple=1, -- Grapple attempts a 1v1 grapple; failing that will just melee beat on the target.
    Ranged=2,
    Stunner=3,
}

CharacterConstants.HUMAN_MELEE_DAMAGE = 20
--CharacterConstants.HUMAN_RANGED_DAMAGE_PISTOL = 15
--CharacterConstants.HUMAN_RANGED_DAMAGE_RIFLE = 30
--CharacterConstants.HUMAN_RANGED_DAMAGE_STUNNER = 15
CharacterConstants.MONSTER_MELEE_DAMAGE = 40
--CharacterConstants.KILLBOT_RANGED_DAMAGE = 20

--CharacterConstants.RIFLE_RANGE = 18
--CharacterConstants.STUNNER_RANGE = 3
CharacterConstants.MELEE_RANGE = 2

CharacterConstants.DEFAULT_PROJECTILE_ATTACH_JOINT = 'Rt_Prop'
CharacterConstants.DEFAULT_PROJECTILE_ATTACH_OFFSET = { 0, 0, 0 }

CharacterConstants.SPRITE_NAME_FRIENDLY_RIFLE = 'temp_laser_blue'
CharacterConstants.SPRITE_NAME_ENEMY_RIFLE = 'temp_laser'
CharacterConstants.SPRITE_NAME_FRIENDLY_PISTOL = 'pistol_laser_blue'
CharacterConstants.SPRITE_NAME_ENEMY_PISTOL = 'pistol_laser'

CharacterConstants.DAMAGE_TYPE=
{
    None=0,
    Melee=1,
    Laser=2,
    Fire=3,
    Acid=4,
    Impact=6,
    Stunner=7,
}

CharacterConstants.PremadePortraits={
    ['JP LeBreton'] = 'jp',
    ['Gabe Miller'] = 'Gabe',
    ['Chris Remo'] = 'Chris',
    ['Matt Franklin'] = 'Matt',
    ['Kee Chi'] = 'Kee',
    ['Ben Burbank'] = 'Ben',
    ['Jeremy Mitchell'] = 'Jeremy',
    ['Tim Schafer'] = 'Tim',
}

CharacterConstants.AccessoryDefs = {  
    Rifle = { sTexture='Props/Tools/Rifle/Textures/Rifle', sRig ='Props/Tools/Rifle/Rig/Rifle.rig', tOff={0,0,0}},
    Pistol = { sTexture='Props/Tools/Rifle/Textures/Rifle', sRig ='Props/Tools/Pistol/Rig/Pistol.rig', tOff={0,0,0}},           
    Bodybag = { sTexture='Props/Tools/Bodybag/Textures/Bodybag01', sRig ='Props/Tools/BodyBag/Rig/BodyBag.rig', tOff={0,0,0}},
    Cigarette = { sTexture='Props/Tools/Cigarette/Textures/Cigarette', sRig ='Props/Tools/Cigarette/Rig/Cigarette.rig', tOff={0,0,0}},
    Datapad = { sTexture='Props/Tools/Datapad/Textures/Datapad01', sRig ='Props/Tools/Datapad/Rig/Datapad.rig', tOff={0,0,0}},
    Extinguisher = { sTexture='Props/Tools/FireExtinguisher/Textures/Tools', sRig ='Props/Tools/FireExtinguisher/Rig/FireExtinguisher.rig', tOff={0,0,0}},
    GameSystem = { sTexture='Props/Tools/Spaceboy64/Textures/Spaceboy01', sRig ='Props/Tools/Spaceboy64/Rig/Spaceboy64.rig', tOff={0,0,0}},
    Mug = { sTexture='Props/Tools/Mug/Textures/Mug01', sRig ='Props/Tools/Mug/Rig/Mug01.rig', tOff={0,0,0}},
    Weldammer = { sTexture='Props/Tools/Weldammer/Textures/Weldammer', sRig ='Props/Tools/Weldammer/Rig/Weldammer.rig', tOff={0,0,0}},
    DebugRock = { sTexture='Props/Asteroid/AsteroidChunk/Textures/AsteroidChunk01', sRig='Props/Asteroid/AsteroidChunk/Rig/AsteroidChunk.rig', tOff={0,0,0}},
    Builder = { sTexture='Characters/Citizen_Base/Textures/Builder', sRig ='Props/Tools/Builder/Rig/Builder.rig', tOff={0,0,0}},
    Sphere = { sTexture="Characters/Primitives/Textures/Gray.png", sRig="Characters/Primitives/Rig/Sphere.rig", tOff={0,0,0}},
    Cube = { sTexture="Characters/Primitives/Textures/Gray.png", sRig="Characters/Primitives/Rig/Cube.rig", tOff={0,0,0}},
    FoodBar = { sTexture="Props/FoodItems/Textures/fooditems.png", sRig="Props/FoodItems/FoodBar/Rig/FoodBar.rig", tOff={0,0,0}},
    FoodVegetable = { sTexture="Props/FoodItems/Textures/fooditems.png", sRig="Props/FoodItems/Carrot/Rig/Carrot.rig", tOff={0,0,0}},
    FoodFork = { sTexture="Props/FoodItems/Textures/fooditems.png", sRig="Props/FoodItems/Fork/Rig/Fork.rig", tOff={0,0,0}},
    FryingPan = { sTexture="Props/FoodItems/Textures/fooditems.png", sRig="Props/FoodItems/FryingPan/Rig/FryingPan.rig", tOff={0,0,0}},
    Barbell = { sTexture="Props/Tools/Barbell/Textures/barbell01.png", sRig="Props/Tools/Barbell/Rig/Barbell01.rig", tOff={0,0,0}},
    Dumbell = { sTexture="Props/Tools/Barbell/Textures/barbell01.png", sRig="Props/Tools/Dumbell/Rig/Dumbell.rig", tOff={0,0,0}},
}


-- time before someone will consider chatting with last person they chatted with
CharacterConstants.CHAT_COOLDOWN = 10
-- bonus social reward for chatting in a pub - reward will be multiplied by this
CharacterConstants.CHAT_PUB_BONUS = 100
-- affinity values
-- max affinity = the most two people can possibly love each other <3 <3 <3
CharacterConstants.MAX_AFFINITY = 20
CharacterConstants.MAX_AFFINITY_INVERSE = 1/20
-- initial base population affinity ranges
CharacterConstants.STARTING_AFFINITY = 10
-- % of utility score for an activity can be +/- modified by affinity
CharacterConstants.ACTIVITY_AFFINITY_CHANGE_PCT = 0.2
CharacterConstants.AFFINITY_CHANGE_MINOR = 1
CharacterConstants.AFFINITY_CHANGE_MEDIUM = 4
-- chance a new immigrant will bring knowledge of a new topic
CharacterConstants.IMMIGRATION_ADD_TOPIC_CHANCE = 0.1
-- weighting for non-people topics vs people topics,
-- eg 0.2 = thing affinity counts for 1/5th equivalent people affinity
CharacterConstants.THING_WEIGHT = 0.5
-- 
CharacterConstants.FRIEND_AFFINITY = 5
CharacterConstants.ENEMY_AFFINITY = -5
-- if affinity for a duty above/below this, we like/dislike it,
-- otherwise we're just meh
CharacterConstants.DUTY_AFFINITY_LIKE = 2.5
CharacterConstants.DUTY_AFFINITY_DISLIKE = -2.5
-- largest duty-affinity XP bonus/penalty will get
CharacterConstants.DUTY_AFFINITY_XP_MAX_RATE = 0.5
-- largest duty-affinity morale bonus/penalty will get
CharacterConstants.DUTY_AFFINITY_MORALE_MAX = 0.4

-- stuff affinity
CharacterConstants.STUFF_AFFINITY_PICKUP_THRESHOLD = 2
CharacterConstants.STUFF_AFFINITY_DISCARD_THRESHOLD = -1
CharacterConstants.MAX_OWNED_STUFF = 10
CharacterConstants.SATISFACTION_UTILITY_SCALE = 1/10
CharacterConstants.MAX_INVENTORY = 5
CharacterConstants.STUFF_MIN_HOLD_TIME = 60*4

-- default max hitpoints
CharacterConstants.STARTING_HIT_POINTS = 100
-- hitpoint threshold to enter STATUS_HURT
CharacterConstants.HURT_THRESHOLD = 30
CharacterConstants.SCUFFED_UP_THRESHOLD = 80

-- hitpoints regained per second
CharacterConstants.HEAL_RATE = 0.05
-- time in seconds till auto heal works again
CharacterConstants.SELF_HEAL_COOLDOWN = 15

-- needs reduce every... uh... 14.4 seconds. Remnant of our old bad time conversion system.
-- They reduce typically by 1.
CharacterConstants.NEEDS_REDUCE_TICK = 14.4

-- starvation
CharacterConstants.NEEDS_HUNGER_STARVATION = -90
-- if we starve for this long consecutively, we die
CharacterConstants.TIME_BEFORE_STARVATION = 60 * 10
CharacterConstants.NEEDS_ENERGY_TIRED = -50
CharacterConstants.NEEDS_STUFF_LOW = -50

-- hitpoints damaged per second
CharacterConstants.FIRE_DAMAGE_RATE = 5

CharacterConstants.BLOOD_DECALS = { "blood01", "blood02", "blood03", "blood04", "blood05" }

-- frequency (sim seconds) to update graph data
CharacterConstants.GRAPH_TICK_RATE = 3
CharacterConstants.GRAPH_MAX_ENTRIES = 200

-- # of tasks to log
CharacterConstants.TASK_LOGS_MAX = 100

CharacterConstants.BASE_LOG_SKILL_UP_DURATION = 30


--
-- morale
--
CharacterConstants.MORALE_TICK = 15 -- seconds
CharacterConstants.SURVIVAL_TICK = 1 -- seconds
CharacterConstants.OXYGEN_TICK = 0.25 -- seconds
CharacterConstants.MORALE_MAX = 100
CharacterConstants.MORALE_MIN = -100
-- # of morale events to remember
CharacterConstants.MORALE_EVENTS_LOG_MAX = 100
-- above this, character is happy and gets a bonus to work, below -this, character is sad and gets a penalty to work
CharacterConstants.MORALE_COMPETENCY_THRESHOLD = 33
-- Added or subtracted from 1 when the character is happy/sad to affect their job competency
CharacterConstants.MORALE_COMPETENCY_MODIFIER = 0.5
-- same, but for move (and possibly other, in the future) speeds
CharacterConstants.MORALE_SPEED_THRESHOLD = 50
CharacterConstants.MORALE_LOW_SPEED_MODIFIER = -0.3
CharacterConstants.MORALE_HIGH_SPEED_MODIFIER = 0.1
-- if average of all needs below this value, morale lowers gradually...
CharacterConstants.MORALE_NEEDS_LOW = -20
-- by this much per tick
CharacterConstants.MORALE_NEEDS_DECREASE = -0.1
-- same as above, but for high avg needs + morale
CharacterConstants.MORALE_NEEDS_HIGH = 25
CharacterConstants.MORALE_NEEDS_INCREASE = 0.1
-- room morale score = score of all objects in room / size of room (in tiles)
CharacterConstants.MAX_ROOM_MORALE_SCORE = 0.5
-- room morale "diminishing returns range" - as morale goes from start to end, boost dwindles to zero
CharacterConstants.ROOM_MORALE_FALLOFF_START = 30
CharacterConstants.ROOM_MORALE_FALLOFF_END = 60
-- max morale boost from highest scoring room per MORALE_TICK seconds
CharacterConstants.MAX_ROOM_MORALE_BOOST = 0.4
-- how often to sample room morale
CharacterConstants.ROOM_MORALE_TICK = 3
-- corpse unpleasantness (same scale as env object morale scores)
CharacterConstants.CORPSE_ROOM_MORALE_SCORE = -20
-- # of room morale samples to average for room satifaction
CharacterConstants.ROOM_MORALE_SAMPLES = CharacterConstants.MORALE_TICK / CharacterConstants.ROOM_MORALE_TICK
-- 0 to 1 room score threshold citizens will log about
CharacterConstants.ROOM_MORALE_LOG_THRESHOLD = 0.8
CharacterConstants.MORALE_UI_TEXT =
{
	-- numbers here should span MORALE_MIN and MORALE_MAX above
    { nMinMorale = -100, linecode = "INSPEC068TEXT", },
    { nMinMorale = -75, linecode = "INSPEC064TEXT", },
    { nMinMorale = -50, linecode = "INSPEC023TEXT", },
    { nMinMorale = -25, linecode = "INSPEC065TEXT", },
    { nMinMorale = -5, linecode = "INSPEC025TEXT", },
    { nMinMorale = 5, linecode = "INSPEC066TEXT", },
    { nMinMorale = 25, linecode = "INSPEC024TEXT", },
    { nMinMorale = 50, linecode = "INSPEC067TEXT", },
    { nMinMorale = 75, linecode = "INSPEC069TEXT", },
}
CharacterConstants.ANGER_UI_TEXT =
{
	{ nMinAnger = 0, linecode = 'INSPEC178TEXT' },
	{ nMinAnger = 10, linecode = 'INSPEC179TEXT' },
	{ nMinAnger = 20, linecode = 'INSPEC180TEXT' },
	{ nMinAnger = 30, linecode = 'INSPEC181TEXT' },
	{ nMinAnger = 40, linecode = 'INSPEC182TEXT' },
	{ nMinAnger = 50, linecode = 'INSPEC183TEXT' },
	{ nMinAnger = 60, linecode = 'INSPEC184TEXT' },
	{ nMinAnger = 70, linecode = 'INSPEC186TEXT' },
	{ nMinAnger = 80, linecode = 'INSPEC185TEXT' },
	{ nMinAnger = 90, linecode = 'INSPEC187TEXT' },
}
-- if needs are met but morale is negative, bump by this each tick
CharacterConstants.MORALE_NEEDS_MET_BONUS = 0.5
CharacterConstants.MORALE_LOW_OXYGEN = -0.1
CharacterConstants.MORALE_LOW_OXYGEN_THRESHOLD = 550
--
-- morale events
--
-- good things
CharacterConstants.MORALE_NICE_CHAT = 0
CharacterConstants.MORALE_MET_NEW_CITIZEN = 6
CharacterConstants.MORALE_MINE_ASTEROID = 0
CharacterConstants.MORALE_MAINTAIN_OBJECT = 0
CharacterConstants.MORALE_MAINTAIN_PLANT = 0
CharacterConstants.MORALE_REPAIR_OBJECT = 0
CharacterConstants.MORALE_BUILD_BASE = 0
CharacterConstants.MORALE_DID_HOBBY = 0
CharacterConstants.MORALE_WOKE_UP_BED = 4
CharacterConstants.MORALE_DELIVERED_FOOD = 0
CharacterConstants.MORALE_SERVED_MEAL = 1
CharacterConstants.MORALE_DRANK_BASE = 3
CharacterConstants.MORALE_DRANK_MAX = 6
CharacterConstants.MORALE_ATE_MEAL_BASE = 1
CharacterConstants.MORALE_ATE_MEAL_MAX = 10
-- when you chat with someone nice and you're depressed, they make you happier
CharacterConstants.MORALE_HAPPY_CHAT_BASE = 1
CharacterConstants.MORALE_HAPPY_CHAT_MAX = 10

-- bad things
CharacterConstants.MORALE_BAD_CHAT = 0
CharacterConstants.MORALE_SLEPT_ON_FLOOR = -1
-- familiarity and affinity determine how bummed you feel when someone dies
CharacterConstants.MORALE_CITIZEN_DIES_MIN = -4
CharacterConstants.MORALE_CITIZEN_DIES_MAX = -60
-- morale loss for death plateaus beyond these familiarity + affinity levels
CharacterConstants.MORALE_MAX_FAMILIARITY_DEATH = 100
CharacterConstants.MORALE_MAX_AFFINITY_DEATH = 10

-- TODO: hook up these anger triggers & more.
-- Character will rampage at 100 anger. 
-- With terrible morale, these numbers can be as much as doubled; with good morale multiplied by .4.
-- Also, everyone but the worst-tempered citizen will ignore some of these (random role vs. temper).
-- Furthermore, anger reduces every morale tick.
-- So we need lots of anger coming into the system to cause rampages.
CharacterConstants.ANGER_BAD_CONVO_WITH_NORMAL = 1
CharacterConstants.ANGER_BAD_CONVO_WITH_JERK = 5
CharacterConstants.ANGER_NEARBY_BRAWL = 15
CharacterConstants.ANGER_NEARBY_RAMPAGE = 25
-- following 2 are unused; anger is % of max based on temper
CharacterConstants.ANGER_EMBRIGGENED_UNJUST = 60
CharacterConstants.ANGER_EMBRIGGENED_JUST = 15
CharacterConstants.ANGER_JOB_FAIL_TINY = 5
CharacterConstants.ANGER_JOB_FAIL_MINOR = 15
CharacterConstants.ANGER_JOB_FAIL_MAJOR = 25
CharacterConstants.ANGER_BAD_FOOD = 10
CharacterConstants.REPLICATOR_FOOD = 3
CharacterConstants.ANGER_MAX = 100
CharacterConstants.ANGER_REDUCTION_PER_MORALE_TICK = 1
CharacterConstants.ANGER_REDUCTION_PER_MORALE_TICK_BRIG = 2

CharacterConstants.STATUS_RAMPAGE = 1
CharacterConstants.STATUS_RAMPAGE_NONVIOLENT = 2
CharacterConstants.STATUS_RAMPAGE_VIOLENT = 3
CharacterConstants.VIOLENT_RAMPAGE_CHANCE = .25

--
-- familiarity
--
CharacterConstants.FAMILIARITY_TICK_RATE = 5
CharacterConstants.FAMILIARITY_TICK_INCREASE = 0.1
CharacterConstants.FAMILIARITY_CHAT = 4
CharacterConstants.FAMILIARITY_SERVE_MEAL = 0.5

-- log "recently used" threshold
CharacterConstants.LOG_RECENT_HISTORY = 5
-- citizens will post non-priority logs this often, based on chattiness
CharacterConstants.LOG_RATE_MIN = 5
CharacterConstants.LOG_RATE_MAX = 15
-- how often citizens will log needs-based morale changes
CharacterConstants.LOG_MORALE_NEEDS_RATE = 180

-- pub capacity (tiles per citizen)
CharacterConstants.PUB_CAPACITY = 3
-- bonus people per bar
CharacterConstants.PUB_CITIZENS_PER_BARTENDER = 5

CharacterConstants.RENDER_LAYER = 'WorldWall'
--CharacterConstants.BACKGROUND_RENDER_LAYER = 'WorldFloor'
CharacterConstants.BACKGROUND_RENDER_LAYER = 'WorldOutlines'

CharacterConstants.SIGHT_RADIUS = 18

CharacterConstants.OXYGEN_PER_SECOND = 200
CharacterConstants.OXYGEN_LOW = 400
CharacterConstants.OXYGEN_SUFFOCATING = 100
CharacterConstants.OXYGEN_SUFFOCATION_UNTIL_DEATH = 60 -- in game seconds
CharacterConstants.OXYGEN_AVERAGE_SAMPLE = 5
-- max oxygen = seconds of life inside suit * o2/sec
CharacterConstants.SPACESUIT_MAX_OXYGEN = 480 * CharacterConstants.OXYGEN_PER_SECOND
CharacterConstants.SPACESUIT_OXYGEN_SUFFOCATING = CharacterConstants.OXYGEN_SUFFOCATION_UNTIL_DEATH * CharacterConstants.OXYGEN_PER_SECOND
CharacterConstants.UNNECESSARY_SPACESUIT_REMOVE = 10

-- chance to play "startle" anim in panic situation
CharacterConstants.STARTLE_CHANCE = 0.75

CharacterConstants.TIME_BETWEEN_IDLE_ANIMS_RAMPAGE = 60
CharacterConstants.TIME_BETWEEN_IDLE_ANIMS = 120
CharacterConstants.TIME_BETWEEN_IDLE_ANIMS_TIRED = 60

-- health statuses
CharacterConstants.STATUS_HEALTHY = 1
CharacterConstants.STATUS_HURT = 2
CharacterConstants.STATUS_SICK = 3
CharacterConstants.STATUS_DEAD = 4
CharacterConstants.STATUS_INCAPACITATED = 5
CharacterConstants.STATUS_ILL = 6
CharacterConstants.STATUS_SCUFFED_UP = 7
CharacterConstants.STATUS_INJURED = 8

CharacterConstants.HEALTH_STATUS_LINE=
{
    [CharacterConstants.STATUS_HEALTHY] = "INSPEC022TEXT",
    [CharacterConstants.STATUS_HURT] = "INSPEC021TEXT",
    [CharacterConstants.STATUS_SICK] = "INSPEC009TEXT",
    [CharacterConstants.STATUS_DEAD] = "INSPEC010TEXT",
    [CharacterConstants.STATUS_INCAPACITATED] = "INSPEC142TEXT",
    [CharacterConstants.STATUS_ILL] = "INSPEC143TEXT",
    [CharacterConstants.STATUS_SCUFFED_UP] = "INSPEC151TEXT",
    [CharacterConstants.STATUS_INJURED] = "INSPEC201TEXT",
}

CharacterConstants.ROBOT_HEALTH_STATUS_LINE=
{
    [CharacterConstants.STATUS_HEALTHY] = "INSPEC089TEXT",
    [CharacterConstants.STATUS_HURT] = "INSPEC090TEXT",
    [CharacterConstants.STATUS_SICK] = "INSPEC092TEXT",
    [CharacterConstants.STATUS_DEAD] = "INSPEC091TEXT",
    [CharacterConstants.STATUS_INCAPACITATED] = "INSPEC142TEXT",
    [CharacterConstants.STATUS_ILL] = "INSPEC142TEXT",
    [CharacterConstants.STATUS_SCUFFED_UP] = "INSPEC151TEXT",
}

CharacterConstants.CORPSE_DURATION = 60*10

CharacterConstants.CAUSE_OF_DEATH = {
    UNSPECIFIED = 1,
    DEBUG = 2,
    SUFFOCATION = 3,
    FIRE = 4,
    DISEASE = 5,
    COMBAT_RANGED = 6,
    SUCKED_INTO_SPACE = 7,
    PARASITE = 8,
    STARVATION = 9,
    COMBAT_MELEE = 10,
    THING = 11,
}

CharacterConstants.INFESTATION_CHANCE = .025 -- chance a random character will be infested
CharacterConstants.INFESTATION_LOG_TIME = 60 * 5 -- time in seconds between logs about infestation

CharacterConstants.WORKOUT_COOLDOWN = 60*2 --wait at least 2 hours between workouts
CharacterConstants.GAMING_COOLDOWN = 60*2

-- death causes, shown in inspector
CharacterConstants.tDeathCauses=
{
	[CharacterConstants.CAUSE_OF_DEATH.UNSPECIFIED] = 'INSPEC103TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.DEBUG] = 'INSPEC108TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.SUFFOCATION] = 'INSPEC098TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.FIRE] = 'INSPEC100TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.DISEASE] = 'INSPEC109TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.COMBAT_RANGED] = 'INSPEC102TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.SUCKED_INTO_SPACE] = 'INSPEC105TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.PARASITE] = 'INSPEC104TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.STARVATION] = 'INSPEC099TEXT',
	[CharacterConstants.CAUSE_OF_DEATH.COMBAT_MELEE] = 'INSPEC101TEXT',
    [CharacterConstants.CAUSE_OF_DEATH.THING] = 'INSPEC200TEXT',
}

-- job-related
CharacterConstants.MAX_COMPETENCY = 10
CharacterConstants.MAX_STARTING_COMPETENCY = 2
-- starting "skill points": total competency to dole out randomly
-- to new citizens
-- (probably increase this when we add a new job!)
CharacterConstants.STARTING_SKILL_POINTS = 8
-- chances to fail at 0% and 100% competency
CharacterConstants.MAX_CHANCE_TO_FAIL = 0.1
CharacterConstants.MIN_CHANCE_TO_FAIL = 0
CharacterConstants.NO_FAIL_COMPETENCY_THRESHOLD = 0.9
CharacterConstants.FAILURE_XP_PENALTY = 0.5
CharacterConstants.EXPERIENCE_PER_LEVEL= 200
CharacterConstants.JOB_EXPERIENCE_RATE = 25.0 / 60.0

CharacterConstants.tJobLevels =
{
    {   
        nLevel = 1,
        nMinCompetency = 0,
        sTextureName = 'ui_jobs_skillrank1'
    },
    {   
        nLevel = 2,
        nMinCompetency = .16,
        sTextureName = 'ui_jobs_skillrank2'
    },
    {   
        nLevel = 3,
        nMinCompetency = .28,
        sTextureName = 'ui_jobs_skillrank3'
    },
    {   
        nLevel = 4,
        nMinCompetency = .60,
        sTextureName = 'ui_jobs_skillrank4'
    },
    {   
        nLevel = 5,
        nMinCompetency = .90,
        sTextureName = 'ui_jobs_skillrank5'
    },
}

CharacterConstants.XP_FIRE_EXTINGUISH = 15
CharacterConstants.XP_COMBAT_KILL = 15
CharacterConstants.XP_COMBAT_DAMAGE = 1
CharacterConstants.XP_BUILD_BASE = 2

-- Memories. You're talking about memories!
-- These don't really need to be turned into 'constants', but it's convenient to have them all in one place.
-- This is a list of all memories a character may store. Prefixes typically have a room ID or similar appended.
CharacterConstants.MEMORY_WORKED_OUT_RECENTLY = 'bWorkedOutRecently'
CharacterConstants.MEMORY_PLAYED_GAME_RECENTLY = 'bPlayedGameRecently'
CharacterConstants.MEMORY_LAST_BED = 'tLastSleptInBed'
CharacterConstants.MEMORY_ATTEMPTED_MONSTER_SPAWN_RECENTLY = 'bRecentlyTriedToSpawnMonster'
CharacterConstants.MEMORY_TOOK_DAMAGE_RECENTLY = 'bTookDamageRecently'
CharacterConstants.MEMORY_ENTERED_COMBAT_RECENTLY = 'bEnteredCombatRecently'
CharacterConstants.MEMORY_GENERIC_LOG = 'bMadeGenericLogRecently'
CharacterConstants.GENERIC_LOG_FREQUENCY = 240
CharacterConstants.MEMORY_STUFF_NEED = 'bMadeStuffNeedLogRecently'
CharacterConstants.STUFF_NEED_LOG_FREQUENCY = 800
CharacterConstants.MEMORY_PRISON_ANGER_RECENTLY = 'bPrisonAngerRecently'
CharacterConstants.MEMORY_EXPLORED_RECENTLY = 'bExploredRecently'
CharacterConstants.MAX_LOG_ENTRIES = 100

CharacterConstants.MEMORY_ROOM_BREACHED_PREFIX = 'bRoomBreached'
CharacterConstants.MEMORY_ROOM_COMBAT_PREFIX = 'bCombatInRoom'
CharacterConstants.MEMORY_ROOM_FIRE_PREFIX = 'bFireInRoom'
CharacterConstants.MEMORY_ROOM_LOWO2_PREFIX = 'bLowOxygenInRoom'

CharacterConstants.MEMORY_LOGGED_RECENTLY = 'bLoggedRecently'
CharacterConstants.MEMORY_LOGGED_MORALE_RECENTLY = 'bLoggedMoraleRecently'
CharacterConstants.MEMORY_ATTEMPTED_MONSTER_LOG_RECENTLY = 'bRecentLogAboutParasite'
CharacterConstants.MEMORY_LOGGED_PATROL_RECENTLY = 'bLoggedPatrolRecently'
CharacterConstants.PATROL_LOG_FREQUENCY = 120

CharacterConstants.MEMORY_LOGGED_RESEARCH_RECENTLY = 'bLoggedResearchRecently'

CharacterConstants.MEMORY_SENT_TO_HOSPITAL = 'bSentToHospital'
CharacterConstants.MEMORY_STARTLED_RECENTLY = 'bStartledRecently'
CharacterConstants.MEMORY_STARTLED_RECENTLY_DURATION = 15
CharacterConstants.MEMORY_SAW_TANTRUM_RECENTLY = 'tSawTantrum'

-- movement
CharacterConstants.BASE_SPEED = 1.5 -- tiles per sim second, which go by much faster than real world seconds
CharacterConstants.RUN_SPEED = 2.2

-- JOB STUFF --------------------------------------------------------------------
--jobs
-- NOTE: do not remove or change any of these constants. If you add any, add to the end.
-- We assume array-like behavior from these constants in several places.
CharacterConstants.UNEMPLOYED = 1
CharacterConstants.BUILDER = 2
CharacterConstants.TECHNICIAN = 3
CharacterConstants.MINER = 4
CharacterConstants.EMERGENCY = 5
CharacterConstants.RAIDER = 6
CharacterConstants.BARTENDER = 7
CharacterConstants.BOTANIST = 8
CharacterConstants.SCIENTIST = 9
CharacterConstants.EMERGENCY2 = 10
CharacterConstants.EMERGENCY3 = 11
CharacterConstants.DOCTOR = 12
CharacterConstants.JANITOR = 13
CharacterConstants.TRADER = 14
-- convenience list for jobs you can have a proficiency/affinity for
CharacterConstants.tJobs = {
	CharacterConstants.BUILDER, CharacterConstants.TECHNICIAN,
	CharacterConstants.MINER, CharacterConstants.EMERGENCY,
	CharacterConstants.BARTENDER, CharacterConstants.BOTANIST,
	CharacterConstants.SCIENTIST, CharacterConstants.DOCTOR,
        CharacterConstants.JANITOR,
}
--job competency levels
CharacterConstants.COMPETENCY_LEVEL1 = 1
CharacterConstants.COMPETENCY_LEVEL2 = 2
CharacterConstants.COMPETENCY_LEVEL3 = 3
CharacterConstants.COMPETENCY_LEVEL4 = 4
CharacterConstants.COMPETENCY_LEVEL5 = 5

--job hand accessories
CharacterConstants.WELDER = 1
CharacterConstants.DATAPAD = 2
CharacterConstants.RIFLE = 3
CharacterConstants.ROCK = 4
CharacterConstants.BEER = 5

CharacterConstants.SHIFT_COOLDOWN = 360
CharacterConstants.SHIFT_DURATION = 270
CharacterConstants.SLEEP_DURATION = 270

CharacterConstants.VACUUM_VEC_SAMPLES = 5

CharacterConstants.DISPLAY_JOBS = {
CharacterConstants.UNEMPLOYED,
CharacterConstants.BUILDER,
CharacterConstants.TECHNICIAN,
CharacterConstants.MINER,
CharacterConstants.EMERGENCY,
CharacterConstants.BARTENDER,
CharacterConstants.BOTANIST,
CharacterConstants.SCIENTIST,
CharacterConstants.DOCTOR,
CharacterConstants.JANITOR,
CharacterConstants.TRADER,
}

-- NOTE: do not remove or change any of these constants. If you add any, add to the end.
-- We assume array-like behavior from these constants in several places.
CharacterConstants.JOB_NAMES_CAPS=
{
    [CharacterConstants.UNEMPLOYED] = "DUTIES001TEXT",
    [CharacterConstants.BUILDER] = "DUTIES003TEXT",
    [CharacterConstants.TECHNICIAN] = "DUTIES005TEXT",
    [CharacterConstants.MINER] = "DUTIES007TEXT",
    [CharacterConstants.EMERGENCY] = "DUTIES009TEXT",
    [CharacterConstants.RAIDER] = "DUTIES011TEXT",
    [CharacterConstants.BARTENDER] = "DUTIES013TEXT",
    [CharacterConstants.BOTANIST] = "DUTIES016TEXT",
    [CharacterConstants.SCIENTIST] = "DUTIES018TEXT",
    [CharacterConstants.DOCTOR] = "DUTIES020TEXT",
    [CharacterConstants.JANITOR] = "DUTIES022TEXT",
    [CharacterConstants.TRADER] = "DUTIES024TEXT",
}
CharacterConstants.JOB_NAMES=
{
    [CharacterConstants.UNEMPLOYED] = "DUTIES001TEXT",
    [CharacterConstants.BUILDER] = "DUTIES003TEXT",    
    [CharacterConstants.TECHNICIAN] = "DUTIES005TEXT",
    [CharacterConstants.MINER] = "DUTIES007TEXT",
    [CharacterConstants.EMERGENCY] = "DUTIES009TEXT",
    [CharacterConstants.RAIDER] = "DUTIES012TEXT",
    [CharacterConstants.BARTENDER] = "DUTIES013TEXT",
    [CharacterConstants.BOTANIST] = "DUTIES016TEXT",
    [CharacterConstants.SCIENTIST] = "DUTIES018TEXT",
    [CharacterConstants.DOCTOR] = "DUTIES020TEXT",
    [CharacterConstants.JANITOR] = "DUTIES022TEXT",
    [CharacterConstants.TRADER] = "DUTIES024TEXT",
}
CharacterConstants.JOB_ICONS=
{
    [CharacterConstants.UNEMPLOYED] = "ui_jobs_iconJobUnemployed",
    [CharacterConstants.BUILDER] = "ui_jobs_iconJobBuilder",
    [CharacterConstants.TECHNICIAN] = "ui_jobs_iconJobTechnician",
    [CharacterConstants.MINER] = "ui_jobs_iconJobMiner",
    [CharacterConstants.EMERGENCY] = "ui_jobs_iconJobResponse",
    [CharacterConstants.RAIDER] = "ui_jobs_iconJobUnemployed",
    [CharacterConstants.BARTENDER] = "ui_jobs_iconJobBarkeep",
    [CharacterConstants.BOTANIST] = "ui_jobs_iconJobBotanist",
    [CharacterConstants.SCIENTIST] = "ui_jobs_iconJobScientist",
    [CharacterConstants.DOCTOR] = "ui_jobs_iconJobDoctor",
    [CharacterConstants.JANITOR] = "ui_jobs_iconJobTechnician",
    [CharacterConstants.TRADER] = "ui_jobs_iconJobUnemployed"
}
-- icons and colors that correspond with affinity #s
CharacterConstants.AFFINITY_ICONS =
{
	-- could use sIconName as keys, but algorithm is simpler if this is an array
	{ sIconName = 'ui_dialogicon_bigfrown', nAffMin = -10, tColor = Gui.RED },
	{ sIconName = 'ui_dialogicon_frown',    nAffMin = -7.5, tColor = Gui.ORANGE },
	{ sIconName = 'ui_dialogicon_meh',      nAffMin = CharacterConstants.DUTY_AFFINITY_DISLIKE, tColor = Gui.AMBER },
	{ sIconName = 'ui_dialogicon_smile',    nAffMin = CharacterConstants.DUTY_AFFINITY_LIKE, tColor = Gui.AMBERGREEN },
	{ sIconName = 'ui_dialogicon_bigsmile', nAffMin = 7.5, tColor = Gui.GREEN },
}
CharacterConstants.JOB_COMPETENCY_COLORS=
{
    [CharacterConstants.COMPETENCY_LEVEL1] = { 79/255, 28/255, 1/255 },
    [CharacterConstants.COMPETENCY_LEVEL2] = { 105/255, 69/255, 14/255 },
    [CharacterConstants.COMPETENCY_LEVEL3] = { 87/255, 81/255, 1/255 },
    [CharacterConstants.COMPETENCY_LEVEL4] = { 37/255, 78/255, 0/255 },
    [CharacterConstants.COMPETENCY_LEVEL5] = { 28/255, 91/255, 118/255 },
}
CharacterConstants.JOB_EQUIPMENT_PREFIX = '_Character_Group_Group_Flipbook_Group_Job_FBGroup_Jobs_AllTransB_Jobs_'
CharacterConstants.JOB_EQUIPMENT =
{   
    [CharacterConstants.BUILDER] = { 
        bHasHelmet = true,
        bHasSuit = true,
        --sModel = 'Builder_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Builder01', 
        sTopLayer = 'Characters/Citizen_Base/Textures/Builder01_Base_top', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Builder01_Base_bottom',
    },
    [CharacterConstants.TECHNICIAN] = { 
        bHasHelmet = false,
        bHasSuit = true,
        --sModel = 'Tech_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Technician01',
        sTopLayer = 'Characters/Citizen_Base/Textures/Technician01_Base_top', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Technician01_Base_bottom',
    },
    [CharacterConstants.MINER] = { 
        bHasHelmet = true,
        bHasSuit = true,
        --sModel = 'Miner_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Miner01',
        sTopLayer = 'Characters/Citizen_Base/Textures/Miner01_Base_top', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Miner01_Base_bottom',
    },
    [CharacterConstants.EMERGENCY] = { 
        bHasHelmet = true,
        bHasSuit = true,
        --sModel = 'Emergency_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Emergency01'
    },
    [CharacterConstants.EMERGENCY2] = { 
        bHasHelmet = true,
        bHasSuit = true,
        --sModel = 'Emergency_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Emergency02'
    },
    [CharacterConstants.EMERGENCY3] = { 
        bHasHelmet = true,
        bHasSuit = true,
        --sModel = 'Emergency_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Emergency03'
    },
    [CharacterConstants.RAIDER] = { 
        bHasHelmet = false,
        bHasSuit = true,
        --sModel = 'Raider_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Raider01',
        sTopLayer = 'Characters/Citizen_Base/Textures/Raider01_top', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Raider01_bottom',
    },    
    [CharacterConstants.BARTENDER] = { 
        bHasHelmet = false,
        bHasSuit = true,
        --sModel = 'Bartender_Suit02', 
        --sTexture = 'Characters/Citizen_Base/Textures/Tourist_Shirt_Male_01'
    },
    [CharacterConstants.BOTANIST] = {     
        bHasHelmet = false,
        bHasSuit = false,
        sTopLayer = 'Characters/Citizen_Base/Textures/gardener_base', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/gardener_base',
    },
    [CharacterConstants.SCIENTIST] = {     
        bHasHelmet = false,
        bHasSuit = true,
        sTopLayer = 'Characters/Citizen_Base/Textures/Scientist_base', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Scientist_base',
    },
    [CharacterConstants.DOCTOR] = {
        bHasHelmet = false,
        bHasSuit = true,
        sTopLayer = 'Characters/Citizen_Base/Textures/Scientist_base', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Scientist_base',
    },
    [CharacterConstants.JANITOR] = {
        bHasHelmet = false,
        bHasSuit = false,
        sTopLayer = 'Characters/Citizen_Base/Textures/Technician01_Base_top', 
        sBottomLayer = 'Characters/Citizen_Base/Textures/Technician01_Base_bottom',
    },
    [CharacterConstants.TRADER] = {
        bHasHelmet = false,
        bHasSuit = false,
       -- sTopLayer = 'Characters/Citizen_Base/Textures/Technician01_Base_top', 
       -- sBottomLayer = 'Characters/Citizen_Base/Textures/Technician01_Base_bottom',
    },
}
--[[
CharacterConstants.JOB_HELMET_PREFIX = '_Character_Group_Group_Flipbook_Group_Helmet_FBGroup_Helmets_Head_Helmets_Helmets_'
CharacterConstants.JOB_HELMETS =
{   
    [CharacterConstants.BUILDER] = { sModel = 'Builder_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Builder01'},
    [CharacterConstants.TECHNICIAN] = { sModel = '', sTexture = ''},
    [CharacterConstants.MINER] = { sModel = 'Miner_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Miner01'},
    [CharacterConstants.EMERGENCY] = { sModel = 'Emergency_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Emergency01'},
    [CharacterConstants.EMERGENCY3] = { sModel = 'Emergency_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Emergency01'},
    [CharacterConstants.RAIDER] = { sModel = 'Raider_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Raider01'},
    [CharacterConstants.BARTENDER] = { sModel = '', sTexture = ''},
    [CharacterConstants.BOTANIST] = { sModel = '', sTexture = ''},
    [CharacterConstants.SCIENTIST] = { sModel = '', sTexture = ''},
    [CharacterConstants.JANITOR] = { sModel = '', sTexture = ''},
}
]]--

CharacterConstants.SPACESUIT_PREFIX = '_Character_Group_Group_Flipbook_Group_FBody_FBGroup_FBody_AllTransB_Full_Body_'
CharacterConstants.SPACESUITS =
{   
    [CharacterConstants.UNEMPLOYED] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.BUILDER] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.TECHNICIAN] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.MINER] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceMiner01'},
    [CharacterConstants.EMERGENCY] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceEmergency01'},
    [CharacterConstants.RAIDER] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceRaider01'},
    [CharacterConstants.BARTENDER] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.BOTANIST] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.SCIENTIST] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.DOCTOR] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.JANITOR] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
    [CharacterConstants.TRADER] = { sModel = 'Suit01_Body', sTexture = 'Characters/Spacesuit/Textures/SpaceDefault01'},
}

CharacterConstants.SPACESUIT_JOB_EQUIPMENT_PREFIX = '_Character_Group_Group_Flipbook_Group_Job_FBGroup_Jobs_AllTransB_Jobs_'
CharacterConstants.SPACESUIT_JOB_EQUIPMENT =
{   
    [CharacterConstants.UNEMPLOYED] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.BUILDER] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.TECHNICIAN] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.MINER] = { sModel = 'Miner_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/MinerAcc01'},
    [CharacterConstants.EMERGENCY] = { sModel = 'Emergency_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/SpaceEmergency01'},
    [CharacterConstants.RAIDER] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.BARTENDER] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.BOTANIST] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.SCIENTIST] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.DOCTOR] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.JANITOR] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
    [CharacterConstants.TRADER] = { sModel = 'Builder_Spacesuit01', sTexture = 'Characters/Spacesuit/Textures/Spacesuit01'},
}
CharacterConstants.JOB_HAND_ACCESSORY_PREFIX = '_Character_Group_Group_Flipbook_Group_AC_Hand_FBGroup_Hands_Rt_Prop_ACHands_'
CharacterConstants.JOB_HAND_ACCESSORIES=
{
    [CharacterConstants.WELDER] = { sModel = 'Builder_Hand01', sTexture = 'Characters/Citizen_Base/Textures/Builder01'},
    [CharacterConstants.DATAPAD] = { sModel = 'Tech_Hand01', sTexture = 'Characters/Citizen_Base/Textures/Technician01'}, 
    [CharacterConstants.RIFLE] = { sModel = 'Rifle_01', sTexture = 'Characters/Citizen_Base/Textures/Rifle01'},
    [CharacterConstants.BEER] = { sModel = 'Mug_01', sTexture = 'Characters/Citizen_Base/Textures/Mug01'},
}
CharacterConstants.SPACESUIT_JOB_HAND_ACCESSORIES=
{
    [CharacterConstants.WELDER] = { sModel = 'Builder_Hand01', sTexture = 'Characters/Citizen_Base/Textures/Builder01'},
    [CharacterConstants.ROCK] = { sModel = 'AsteroidChunk01', sTexture = 'Characters/Spacesuit/Textures/AsteroidChunk01'}, 
}
--MODEL DEFS---------------------------------------------------------------
--rigs
CharacterConstants.RIG_BASE = 1
CharacterConstants.RIG_ALIEN = 2
CharacterConstants.RIG_CUBE = 3
CharacterConstants.RIG_SPHERE = 6
CharacterConstants.RIG_MONSTER = 4
CharacterConstants.RIG_KILLBOT = 5
--races
CharacterConstants.HUMAN_RACE_PCT = 60
CharacterConstants.CAT_RACE_PCT = 2
CharacterConstants.RACE_HUMAN = 1
CharacterConstants.RACE_JELLY = 2
CharacterConstants.RACE_TOBIAN = 3
CharacterConstants.RACE_CAT = 4
CharacterConstants.RACE_BIRDSHARK = 5
CharacterConstants.RACE_CHICKEN = 6
CharacterConstants.RACE_MONSTER = 7
CharacterConstants.RACE_SHAMON = 8
CharacterConstants.RACE_MURDERFACE = 9
CharacterConstants.RACE_KILLBOT = 10
-- race strings
CharacterConstants.tRaceNames=
{
    [CharacterConstants.RACE_HUMAN] = 'NAMESX253TEXT',
    [CharacterConstants.RACE_JELLY] = 'NAMESX254TEXT',
    [CharacterConstants.RACE_TOBIAN] = 'NAMESX255TEXT',
    [CharacterConstants.RACE_CAT] = 'NAMESX259TEXT',
    [CharacterConstants.RACE_BIRDSHARK] = 'NAMESX256TEXT',
    [CharacterConstants.RACE_CHICKEN] = 'NAMESX258TEXT',
    [CharacterConstants.RACE_MONSTER] = 'NAMESX260TEXT',
    [CharacterConstants.RACE_SHAMON] = 'NAMESX257TEXT',
    [CharacterConstants.RACE_MURDERFACE] = 'NAMESX261TEXT',    
    [CharacterConstants.RACE_MURDERFACE] = 'NAMESX340TEXT',
}
--bodies
CharacterConstants.BODY_HUMAN_BROWN_MALE = 1
CharacterConstants.BODY_HUMAN_YELLOWISH_MALE = 2
CharacterConstants.BODY_HUMAN_REDDISH_MALE = 3
CharacterConstants.BODY_HUMAN_WHITE_MALE = 4
CharacterConstants.BODY_HUMAN_BLACK_MALE = 5
CharacterConstants.BODY_HUMAN_BROWN_FEMALE = 6
CharacterConstants.BODY_HUMAN_YELLOWISH_FEMALE = 7
CharacterConstants.BODY_HUMAN_REDDISH_FEMALE = 8
CharacterConstants.BODY_HUMAN_WHITE_FEMALE = 9
CharacterConstants.BODY_HUMAN_BLACK_FEMALE = 10
CharacterConstants.BODY_JELLY_MAUVE_FEMALE = 11
CharacterConstants.BODY_JELLY_PURPLE_FEMALE = 12
CharacterConstants.BODY_JELLY_PINK_FEMALE = 13
CharacterConstants.BODY_JELLY_BLUE_FEMALE = 14
CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_01 = 15
CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_02 = 16
CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_03 = 17
CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_04 = 18
CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_05 = 19
CharacterConstants.BODY_CAT_MALE_01 = 20
CharacterConstants.BODY_CAT_MALE_02 = 21
CharacterConstants.BODY_CAT_FEMALE_01 = 22
CharacterConstants.BODY_CAT_FEMALE_02 = 23
CharacterConstants.BODY_BIRDSHARK_MALE_01 = 24
CharacterConstants.BODY_BIRDSHARK_MALE_02 = 25
CharacterConstants.BODY_BIRDSHARK_FEMALE_01 = 26
CharacterConstants.BODY_BIRDSHARK_FEMALE_02 = 27
CharacterConstants.BODY_CHICKEN_MALE_01 = 28
CharacterConstants.BODY_CHICKEN_MALE_02 = 29
CharacterConstants.BODY_CHICKEN_FEMALE_01 = 30
CharacterConstants.BODY_CHICKEN_FEMALE_02 = 31
CharacterConstants.BODY_HUMAN_FAT_BROWN_MALE = 32
CharacterConstants.BODY_HUMAN_FAT_YELLOWISH_MALE = 33
CharacterConstants.BODY_HUMAN_FAT_REDDISH_MALE = 34
CharacterConstants.BODY_HUMAN_FAT_WHITE_MALE = 35
CharacterConstants.BODY_HUMAN_FAT_BLACK_MALE = 36
CharacterConstants.BODY_HUMAN_FAT_BROWN_FEMALE = 37
CharacterConstants.BODY_HUMAN_FAT_YELLOWISH_FEMALE = 38
CharacterConstants.BODY_HUMAN_FAT_REDDISH_FEMALE = 39
CharacterConstants.BODY_HUMAN_FAT_WHITE_FEMALE = 40
CharacterConstants.BODY_HUMAN_FAT_BLACK_FEMALE = 41
CharacterConstants.BODY_JELLY_FAT_MAUVE_FEMALE = 42
CharacterConstants.BODY_JELLY_FAT_PURPLE_FEMALE = 43
CharacterConstants.BODY_JELLY_FAT_PINK_FEMALE = 44
CharacterConstants.BODY_JELLY_FAT_BLUE_FEMALE = 45
CharacterConstants.BODY_CAT_FAT_MALE_01 = 46
CharacterConstants.BODY_CAT_FAT_MALE_02 = 47
CharacterConstants.BODY_CAT_FAT_FEMALE_01 = 48
CharacterConstants.BODY_CAT_FAT_FEMALE_02 = 49
CharacterConstants.BODY_BIRDSHARK_FAT_MALE_01 = 50
CharacterConstants.BODY_BIRDSHARK_FAT_MALE_02 = 51
CharacterConstants.BODY_BIRDSHARK_FAT_FEMALE_01 = 52
CharacterConstants.BODY_BIRDSHARK_FAT_FEMALE_02 = 53
CharacterConstants.BODY_MONSTER = 54
CharacterConstants.BODY_SHAMON_MALE_01 = 55
CharacterConstants.BODY_MURDERFACE_MALE_01 = 56
CharacterConstants.BODY_KILLBOT_01 = 57
--heads
CharacterConstants.HEAD_HUMAN_BROWN_MALE = 1
CharacterConstants.HEAD_HUMAN_YELLOWISH_MALE = 2
CharacterConstants.HEAD_HUMAN_REDDISH_MALE = 3
CharacterConstants.HEAD_HUMAN_WHITE_MALE = 4
CharacterConstants.HEAD_HUMAN_BLACK_MALE = 5
CharacterConstants.HEAD_HUMAN_BROWN_FEMALE = 6
CharacterConstants.HEAD_HUMAN_YELLOWISH_FEMALE = 7
CharacterConstants.HEAD_HUMAN_REDDISH_FEMALE = 8
CharacterConstants.HEAD_HUMAN_WHITE_FEMALE = 9
CharacterConstants.HEAD_HUMAN_BLACK_FEMALE = 10
CharacterConstants.HEAD_JELLY_MAUVE_FEMALE = 11
CharacterConstants.HEAD_JELLY_PURPLE_FEMALE = 12
CharacterConstants.HEAD_JELLY_PINK_FEMALE = 13
CharacterConstants.HEAD_JELLY_BLUE_FEMALE = 14
CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_01 = 15
CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_02 = 16
CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_03 = 17
CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_04 = 18
CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_05 = 19
CharacterConstants.HEAD_CAT_MALE_01 = 20
CharacterConstants.HEAD_CAT_MALE_02 = 21
CharacterConstants.HEAD_CAT_FEMALE_01 = 22
CharacterConstants.HEAD_CAT_FEMALE_02 = 23
CharacterConstants.HEAD_BIRDSHARK_MALE_01 = 24
CharacterConstants.HEAD_BIRDSHARK_MALE_02 = 25
CharacterConstants.HEAD_BIRDSHARK_FEMALE_01 = 26
CharacterConstants.HEAD_BIRDSHARK_FEMALE_02 = 27
CharacterConstants.HEAD_CHICKEN_MALE_01 = 28
CharacterConstants.HEAD_CHICKEN_MALE_02 = 29
CharacterConstants.HEAD_CHICKEN_FEMALE_01 = 30
CharacterConstants.HEAD_CHICKEN_FEMALE_02 = 31
CharacterConstants.HEAD_HUMAN_FAT_BROWN_MALE = 32
CharacterConstants.HEAD_HUMAN_FAT_YELLOWISH_MALE = 33
CharacterConstants.HEAD_HUMAN_FAT_REDDISH_MALE = 34
CharacterConstants.HEAD_HUMAN_FAT_WHITE_MALE = 35
CharacterConstants.HEAD_HUMAN_FAT_BLACK_MALE = 36
CharacterConstants.HEAD_HUMAN_FAT_BROWN_FEMALE = 37
CharacterConstants.HEAD_HUMAN_FAT_YELLOWISH_FEMALE = 38
CharacterConstants.HEAD_HUMAN_FAT_REDDISH_FEMALE = 39
CharacterConstants.HEAD_HUMAN_FAT_WHITE_FEMALE = 40
CharacterConstants.HEAD_HUMAN_FAT_BLACK_FEMALE = 41
CharacterConstants.HEAD_SHAMON_MALE_01 = 42
CharacterConstants.HEAD_MURDERFACE_MALE_01 = 43
CharacterConstants.HEAD_NONE = 44
--hairs
CharacterConstants.BALD = 0
CharacterConstants.MALE_HAIR_01_BLONDE = 1
CharacterConstants.MALE_HAIR_02_BLONDE = 2
CharacterConstants.MALE_HAIR_03_BLONDE = 3
CharacterConstants.FEMALE_HAIR_01_BLONDE = 4
CharacterConstants.FEMALE_HAIR_02_BLONDE = 5
CharacterConstants.FEMALE_HAIR_03_BLONDE = 6
CharacterConstants.FEMALE_HAIR_04_BLONDE = 7
CharacterConstants.FEMALE_HAIR_05_BLONDE = 8
CharacterConstants.TOBIAN_DONG_01 = 9
CharacterConstants.TOBIAN_DONG_02 = 11
CharacterConstants.TOBIAN_DONG_03 = 12
CharacterConstants.TOBIAN_DONG_04 = 13
CharacterConstants.TOBIAN_DONG_05 = 14
CharacterConstants.TOBIAN_MUSTACHE_01 = 10
CharacterConstants.TOBIAN_MUSTACHE_02 = 15
CharacterConstants.TOBIAN_MUSTACHE_03 = 16
CharacterConstants.TOBIAN_MUSTACHE_04 = 17
CharacterConstants.TOBIAN_MUSTACHE_05 = 18
CharacterConstants.TOBIAN_ELEPHANT_01 = 19
CharacterConstants.TOBIAN_ELEPHANT_02 = 20
CharacterConstants.TOBIAN_ELEPHANT_03 = 21
CharacterConstants.TOBIAN_ELEPHANT_04 = 22
CharacterConstants.TOBIAN_ELEPHANT_05 = 23
CharacterConstants.CAT_MUSTACHE_01 = 24
CharacterConstants.FEMALE_HAIR_02_RED = 25
CharacterConstants.FEMALE_HAIR_02_BRUNETTE = 26
CharacterConstants.FEMALE_HAIR_02_BLACK = 27
CharacterConstants.FEMALE_HAIR_01_RED = 28
CharacterConstants.FEMALE_HAIR_01_BRUNETTE = 29
CharacterConstants.FEMALE_HAIR_01_BLACK = 30
CharacterConstants.FEMALE_HAIR_03_RED = 31
CharacterConstants.FEMALE_HAIR_03_BRUNETTE = 32
CharacterConstants.FEMALE_HAIR_03_BLACK = 33
CharacterConstants.FEMALE_HAIR_04_RED = 34
CharacterConstants.FEMALE_HAIR_04_BRUNETTE = 35
CharacterConstants.FEMALE_HAIR_04_BLACK = 36
CharacterConstants.FEMALE_HAIR_05_RED = 37
CharacterConstants.FEMALE_HAIR_05_BRUNETTE = 38
CharacterConstants.FEMALE_HAIR_05_BLACK = 39
CharacterConstants.MALE_HAIR_01_RED = 40
CharacterConstants.MALE_HAIR_01_BRUNETTE = 41
CharacterConstants.MALE_HAIR_01_BLACK = 42
CharacterConstants.MALE_HAIR_02_RED = 43
CharacterConstants.MALE_HAIR_02_BRUNETTE = 44
CharacterConstants.MALE_HAIR_02_BLACK = 45
CharacterConstants.MALE_HAIR_03_RED = 46
CharacterConstants.MALE_HAIR_03_BRUNETTE = 47
CharacterConstants.MALE_HAIR_03_BLACK = 48
CharacterConstants.FEMALE_HAIR_01_PURPLE = 49
CharacterConstants.FEMALE_HAIR_01_GREEN = 50
CharacterConstants.FEMALE_HAIR_05_PURPLE = 51
CharacterConstants.FEMALE_HAIR_05_GREEN = 52 
CharacterConstants.MALE_HAIR_01_REDBANGS = 53
CharacterConstants.MALE_HAIR_01_BLUEBANGS = 54
CharacterConstants.MALE_HAIR_02_REDBANGS = 55
CharacterConstants.MALE_HAIR_02_BLUEBANGS = 56
CharacterConstants.MALE_HAIR_03_REDBANGS = 57
CharacterConstants.MALE_HAIR_03_BLUEBANGS = 58
CharacterConstants.FEMALE_HAIR_03_REDBANGS = 59
CharacterConstants.FEMALE_HAIR_03_BLUEBANGS = 60
CharacterConstants.FEMALE_HAIR_04_REDBANGS = 61
CharacterConstants.FEMALE_HAIR_04_BLUEBANGS = 62
CharacterConstants.CAT_MUSTACHE_02 = 63
CharacterConstants.MALE_HAIR_04_BLONDE = 64
CharacterConstants.MALE_HAIR_04_RED = 65
CharacterConstants.MALE_HAIR_04_BRUNETTE = 66
CharacterConstants.MALE_HAIR_04_BLACK = 67
CharacterConstants.MALE_HAIR_04_REDBANGS = 68
CharacterConstants.MALE_HAIR_04_BLUEBANGS = 69
CharacterConstants.MALE_HAIR_05_BLONDE = 70
CharacterConstants.MALE_HAIR_05_RED = 71
CharacterConstants.MALE_HAIR_05_BRUNETTE = 72
CharacterConstants.MALE_HAIR_05_BLACK = 73
CharacterConstants.MALE_HAIR_05_REDBANGS = 74
CharacterConstants.MALE_HAIR_05_BLUEBANGS = 75
CharacterConstants.MALE_HAIR_01_GRAY = 76
CharacterConstants.MALE_HAIR_02_GRAY = 77
CharacterConstants.MALE_HAIR_03_GRAY = 78
CharacterConstants.MALE_HAIR_04_GRAY = 79
CharacterConstants.MALE_HAIR_05_GRAY = 80
CharacterConstants.FEMALE_HAIR_01_GRAY = 81
CharacterConstants.FEMALE_HAIR_02_GRAY = 82
CharacterConstants.FEMALE_HAIR_03_GRAY = 83
CharacterConstants.FEMALE_HAIR_04_GRAY = 84
CharacterConstants.FEMALE_HAIR_05_GRAY = 85
--face bottom layer
CharacterConstants.FACE_BOTTOM_CLEAR = 0
CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_01 = 1
CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_02 = 2
CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_03 = 3
CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_04 = 4
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE = 5
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED = 6
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE = 7
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK = 8
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE = 9
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED = 10
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE = 11
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK = 12
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE = 13
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED = 14
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE = 15
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK = 16
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE = 17
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED = 18
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE = 19
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK = 20
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE = 21
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED = 22
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE = 23
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK = 24
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY = 25
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY = 26
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY = 27
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY = 28
CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY = 29
--face top layer
CharacterConstants.FACE_TOP_CLEAR = 0
CharacterConstants.FACE_TOP_CHICKEN_COMB_01 = 1
CharacterConstants.FACE_TOP_CHICKEN_COMB_02 = 2
CharacterConstants.FACE_TOP_CHICKEN_COMB_03 = 3
CharacterConstants.FACE_TOP_CHICKEN_COMB_04 = 4
--bottom accessories
CharacterConstants.NO_BOTTOM_ACCESSORY = 0
CharacterConstants.MALE_BOTTOM_ACCESSORY_LEGPOUCH_01 = 1
CharacterConstants.MALE_BOTTOM_ACCESSORY_BELT_01 = 2
CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01 = 3
CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01 = 4
CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_LEGPOUCH_01 = 5
CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_BELT_01 = 6
CharacterConstants.MALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01 = 7
CharacterConstants.FEMALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01 = 8
CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_TOURISTSHORTS_01 = 9
CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01 = 10
CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01 = 11
CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_BELT_01 = 12
CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_BELT_01 = 13
CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_TOURISTSHORTS_01 = 14
CharacterConstants.SHAMON_BOTTOM_ACCESSORY_BELT_01 = 15
CharacterConstants.SHAMON_BOTTOM_ACCESSORY_LEGPOUCH_01 = 16
--top accessories
CharacterConstants.NO_TOP_ACCESSORY = 0
CharacterConstants.MALE_TOP_ACCESSORY_COLLAR_01 = 1
CharacterConstants.MALE_TOP_ACCESSORY_VEST_01 = 2
CharacterConstants.FEMALE_TOP_ACCESSORY_COLLAR_01 = 3
CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01 = 4
CharacterConstants.TOBIAN_TOP_ACCESSORY_COLLAR_01 = 5
CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01 = 6
CharacterConstants.MALE_TOP_ACCESSORY_SEXYSHIRT_01 = 7
CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_01 = 8
CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_01 = 9
CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_01 = 10
CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_01 = 11
CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_02 = 12
CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_02 = 13
CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_02 = 14
CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_02 = 15
CharacterConstants.MALE_TOP_ACCESSORY_FAT_COLLAR_01 = 19
CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01 = 20
CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01 = 21
CharacterConstants.TOBIAN_TOP_ACCESSORY_ROBESHIRT_01 = 22
CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02 = 24
CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03 = 25
CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02 = 26
CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03 = 27
CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE = 28
CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE = 29
CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01_BEIGE = 30
CharacterConstants.SHAMON_TOP_ACCESSORY_SEXYSHIRT_01 = 31
CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_02 = 33
CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_03 = 34
CharacterConstants.SHAMON_TOP_ACCESSORY_VEST_01 = 35
CharacterConstants.SHAMON_TOP_ACCESSORY_VEST_01_BEIGE = 36
CharacterConstants.TOP_ACCESSORY_HUMANVISOR_01 = 37
CharacterConstants.TOP_ACCESSORY_BIRDSHARKVISOR_01 = 38
CharacterConstants.TOP_ACCESSORY_CATVISOR_01 = 39
CharacterConstants.TOP_ACCESSORY_SHAMONVISOR_01 = 40
CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02 = 41
CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03 = 42
CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_04 = 43
CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_05 = 44
CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_02 = 45
CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_03 = 46
CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_04 = 47
CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_05 = 48
CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02 = 49
CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03 = 50
CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_04 = 51
CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_05 = 52
CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_04 = 53
CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_05 = 54
CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_04 = 55
CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_05 = 56
CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_03 = 57
CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_04 = 58
CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_05 = 59
--accessory set types
CharacterConstants.HUMAN_MALE = 1
CharacterConstants.HUMAN_FEMALE = 2
CharacterConstants.JELLY_FEMALE = 3
CharacterConstants.TOBIAN = 4
CharacterConstants.MURDERFACE_MALE = 5
CharacterConstants.CAT_MALE = 6
CharacterConstants.CAT_FEMALE = 7
CharacterConstants.BIRDSHARK_MALE = 8
CharacterConstants.BIRDSHARK_FEMALE = 9
CharacterConstants.CHICKEN_MALE = 10
CharacterConstants.CHICKEN_FEMALE = 11
CharacterConstants.SHAMON_MALE = 12
CharacterConstants.SHAMON_FEMALE = 13
CharacterConstants.HUMAN_FAT_MALE = 14
CharacterConstants.HUMAN_FAT_FEMALE = 15
CharacterConstants.JELLY_FAT_FEMALE = 16
CharacterConstants.CAT_FAT_MALE = 17
CharacterConstants.CAT_FAT_FEMALE = 18
CharacterConstants.BIRDSHARK_FAT_MALE = 19
CharacterConstants.BIRDSHARK_FAT_FEMALE = 20
--hair set types (uses most of the above accessory ids, but there are a few differences)
CharacterConstants.TOBIAN_BLUE_ALIEN_01 = 21
CharacterConstants.TOBIAN_BLUE_ALIEN_02 = 22  
CharacterConstants.TOBIAN_BLUE_ALIEN_03 = 23
CharacterConstants.TOBIAN_BLUE_ALIEN_04 = 24
CharacterConstants.TOBIAN_BLUE_ALIEN_05 = 25
CharacterConstants.CAT_MALE_01 = 26
CharacterConstants.CAT_MALE_02 = 27
CharacterConstants.KILLBOT_01 = 28
--job outfits
CharacterConstants.BUILDER_BASE_NORMAL = 1
CharacterConstants.BUILDER_BASE_NORMAL_NO_HELMET = 2
CharacterConstants.BUILDER_BASE_FAT = 3
CharacterConstants.BUILDER_BASE_FAT_NO_HELMET = 4
CharacterConstants.BUILDER_TOBIAN_NO_HELMET = 5
CharacterConstants.TECHNICIAN_BASE_NORMAL = 6
CharacterConstants.TECHNICIAN_TOBIAN = 7
CharacterConstants.MINER_BASE_NORMAL = 8
CharacterConstants.MINER_BASE_FAT = 9
CharacterConstants.MINER_TOBIAN = 10
CharacterConstants.EMERGENCY_BASE_NORMAL = 11
CharacterConstants.EMERGENCY_BASE_FAT = 12
CharacterConstants.EMERGENCY_TOBIAN = 13
CharacterConstants.RAIDER_BASE_NORMAL = 14
CharacterConstants.BUILDER_BASE_NORMAL_HOOF_BOOT = 15
CharacterConstants.MINER_BASE_NORMAL_HOOF_BOOT = 16
CharacterConstants.EMERGENCY_BASE_NORMAL_HOOF_BOOT = 17
CharacterConstants.RAIDER_BASE_NORMAL_NO_HELMET = 18
CharacterConstants.RAIDER_BASE_FAT = 19
CharacterConstants.RAIDER_BASE_FAT_NO_HELMET = 20
CharacterConstants.RAIDER_TOBIAN_NO_HELMET = 21
CharacterConstants.BARTENDER_BASE_NORMAL = 22
CharacterConstants.BARTENDER_BASE_FAT = 23
CharacterConstants.BARTENDER_BASE_NORMAL_FEMALE = 24
CharacterConstants.BARTENDER_BASE_FAT_FEMALE = 25
CharacterConstants.BARTENDER_TOBIAN = 26
CharacterConstants.BARTENDER_SHAMON = 27
CharacterConstants.TECHNICIAN_BASE_FAT = 28
CharacterConstants.BOTANIST_BASE_NORMAL = 29
CharacterConstants.SCIENTIST_BASE_NORMAL = 29
CharacterConstants.SCIENTIST_BASE_FAT = 30
CharacterConstants.DOCTOR_BASE_NORMAL = 31
CharacterConstants.DOCTOR_BASE_FAT = 32
CharacterConstants.JANITOR_BASE_NORMAL = 33
CharacterConstants.JANITOR_BASE_FAT = 34
CharacterConstants.JANITOR_TOBIAN = 35
CharacterConstants.TRADER_BASE_NORMAL = 36
CharacterConstants.TRADER_BASE_FAT = 37
CharacterConstants.TRADER_TOBIAN = 38
--job helmets
CharacterConstants.NO_HELMET = 0
CharacterConstants.BUILDER_BASE_HELMET = 1
CharacterConstants.MINER_BASE_HELMET = 2
CharacterConstants.MINER_TOBIAN_HELMET = 3
CharacterConstants.EMERGENCY_BASE_HELMET = 4
CharacterConstants.EMERGENCY_TOBIAN_HELMET = 5
CharacterConstants.RAIDER_BASE_HELMET = 6

-- special
CharacterConstants.NO_REPLACE = 1000000+1

--RACES -----------------------------------------------------------------------
CharacterConstants.RACE_TYPE=
{
    [CharacterConstants.RACE_HUMAN] = { 
        sName = "human", 
        tMaleVoices = {"Voice/Male1/Male_1_", "Voice/Male2/Male_2_"},
        tFemaleVoices = {"Voice/Female1/Female_1_"},
        nRig = CharacterConstants.RIG_BASE, 
        tBodies = { 
            CharacterConstants.BODY_HUMAN_BROWN_MALE,
            CharacterConstants.BODY_HUMAN_YELLOWISH_MALE,
            CharacterConstants.BODY_HUMAN_REDDISH_MALE,
            CharacterConstants.BODY_HUMAN_WHITE_MALE,
            CharacterConstants.BODY_HUMAN_BLACK_MALE,
            CharacterConstants.BODY_HUMAN_BROWN_FEMALE,
            CharacterConstants.BODY_HUMAN_YELLOWISH_FEMALE,
            CharacterConstants.BODY_HUMAN_REDDISH_FEMALE,
            CharacterConstants.BODY_HUMAN_WHITE_FEMALE,
            CharacterConstants.BODY_HUMAN_BLACK_FEMALE,
            CharacterConstants.BODY_HUMAN_FAT_BROWN_MALE,
            CharacterConstants.BODY_HUMAN_FAT_YELLOWISH_MALE,
            CharacterConstants.BODY_HUMAN_FAT_REDDISH_MALE,
            CharacterConstants.BODY_HUMAN_FAT_WHITE_MALE,
            CharacterConstants.BODY_HUMAN_FAT_BLACK_MALE,
            CharacterConstants.BODY_HUMAN_FAT_BROWN_FEMALE,
            CharacterConstants.BODY_HUMAN_FAT_YELLOWISH_FEMALE,
            CharacterConstants.BODY_HUMAN_FAT_REDDISH_FEMALE,
            CharacterConstants.BODY_HUMAN_FAT_WHITE_FEMALE,
            CharacterConstants.BODY_HUMAN_FAT_BLACK_FEMALE, 
            }, 
    }, 
    [CharacterConstants.RACE_JELLY] = { 
        sName = "jelly", 
        tMaleVoices = {"Voice/Male1/Male_1_", "Voice/Male2/Male_2_"},
        tFemaleVoices = {"Voice/Female1/Female_1_"},
        nRig = CharacterConstants.RIG_BASE, 
        tBodies = { 
            CharacterConstants.BODY_JELLY_MAUVE_FEMALE,
            CharacterConstants.BODY_JELLY_PURPLE_FEMALE,
            CharacterConstants.BODY_JELLY_PINK_FEMALE,
            CharacterConstants.BODY_JELLY_BLUE_FEMALE,
            CharacterConstants.BODY_JELLY_FAT_MAUVE_FEMALE,
            CharacterConstants.BODY_JELLY_FAT_PURPLE_FEMALE,
            CharacterConstants.BODY_JELLY_FAT_PINK_FEMALE,
            CharacterConstants.BODY_JELLY_FAT_BLUE_FEMALE,
            }, 
    }, 
    [CharacterConstants.RACE_TOBIAN] = { 
        sName = "tobian", 
        tMaleVoices = {"Voice/Tobian1/Tobian_1_"},
        tFemaleVoices = {"Voice/Tobian1/Tobian_1_"},
        nRig = CharacterConstants.RIG_ALIEN, 
        tBodies = { 
            CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_01,
            CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_02,
            CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_03,
            CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_04,
            CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_05,
        }, 
    },      
    [CharacterConstants.RACE_CAT] = { 
        sName = "cat", 
        tMaleVoices = {"Voice/CatMale/CatMale_"},
        tFemaleVoices = {"Voice/CatFemale/CatFemale_"},
        nRig = CharacterConstants.RIG_BASE, 
        tBodies = { 
            CharacterConstants.BODY_CAT_MALE_01,
            CharacterConstants.BODY_CAT_MALE_02,
            CharacterConstants.BODY_CAT_FEMALE_01,
            CharacterConstants.BODY_CAT_FEMALE_02,
            CharacterConstants.BODY_CAT_FAT_MALE_01,
            CharacterConstants.BODY_CAT_FAT_MALE_02,
            CharacterConstants.BODY_CAT_FAT_FEMALE_01,
            CharacterConstants.BODY_CAT_FAT_FEMALE_02,
        }, 
    },  
    [CharacterConstants.RACE_BIRDSHARK] = { 
        sName = "birdshark", 
        tMaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        tFemaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        nRig = CharacterConstants.RIG_BASE, 
        tBodies = { 
            CharacterConstants.BODY_BIRDSHARK_MALE_01,
            CharacterConstants.BODY_BIRDSHARK_MALE_02,
            CharacterConstants.BODY_BIRDSHARK_FEMALE_01, 
            CharacterConstants.BODY_BIRDSHARK_FEMALE_02,
            CharacterConstants.BODY_BIRDSHARK_FAT_MALE_01,
            CharacterConstants.BODY_BIRDSHARK_FAT_MALE_02,
            CharacterConstants.BODY_BIRDSHARK_FAT_FEMALE_01, 
            CharacterConstants.BODY_BIRDSHARK_FAT_FEMALE_02, 
        }, 
    },  
    [CharacterConstants.RACE_CHICKEN] = { 
        sName = "chicken", 
        tMaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        tFemaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        nRig = CharacterConstants.RIG_ALIEN, 
        tBodies = { 
            CharacterConstants.BODY_CHICKEN_MALE_01, 
            CharacterConstants.BODY_CHICKEN_MALE_02, 
            CharacterConstants.BODY_CHICKEN_FEMALE_01, 
            CharacterConstants.BODY_CHICKEN_FEMALE_02, 
        }, 
    },  
    [CharacterConstants.RACE_MONSTER] = { 
        sName = "badalien", 
        tMaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        tFemaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        nRig = CharacterConstants.RIG_MONSTER, 
        tBodies = { 
            CharacterConstants.BODY_MONSTER, 
        }, 
    },  
    [CharacterConstants.RACE_SHAMON] = { 
        sName = "shamon", 
        tMaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        tFemaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        nRig = CharacterConstants.RIG_BASE, 
        tBodies = { 
            CharacterConstants.BODY_SHAMON_MALE_01,
        }, 
    },
    [CharacterConstants.RACE_MURDERFACE] = { 
        sName = "murderface", 
        tMaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        tFemaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        nRig = CharacterConstants.RIG_ALIEN, 
        tBodies = { 
            CharacterConstants.BODY_MURDERFACE_MALE_01,
        }, 
    },  
    [CharacterConstants.RACE_KILLBOT] = { 
        sName = "killbot", 
        tMaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        tFemaleVoices = {"Voice/ChickenMale/ChickenMale_"},
        nRig = CharacterConstants.RIG_KILLBOT, 
        tBodies = { 
            CharacterConstants.BODY_KILLBOT_01,
        }, 
    },
}
--RIGS -----------------------------------------------------------------------
CharacterConstants.RIG_TYPE=
{
    [CharacterConstants.RIG_BASE] = {sRigPath='Characters/Citizen_Base/Rig/Citizen_Base.rig',sAnimPath='Animations.Citizen_Base',nScl=.5},
    [CharacterConstants.RIG_ALIEN] = {sRigPath='Characters/Citizen_Alien/Rig/Citizen_Alien.rig',sAnimPath='Animations.Citizen_Alien',nScl=.5},
    [CharacterConstants.RIG_CUBE] = {sRigPath='Characters/Primitives/Rig/Cube.rig',sAnimPath='Animations.None',nScl=.5},
    [CharacterConstants.RIG_SPHERE] = {sRigPath='Characters/Primitives/Rig/Sphere.rig',sAnimPath='Animations.None',nScl=.5},
    [CharacterConstants.RIG_MONSTER] = {sRigPath='Characters/Bad_Alien/Rig/Bad_Alien.rig',sAnimPath='Animations.Bad_Alien',nScl=.65},
    [CharacterConstants.RIG_KILLBOT] = {sRigPath='Characters/Murder_Robot/Rig/Murder_Robot.rig',sAnimPath='Animations.Murder_Robot',nScl=.5},
}

CharacterConstants.RIG_SPACESUIT = "Characters/Spacesuit/Rig/Spacesuit.rig"

-- BODIES -------------------------------------------------------------------
CharacterConstants.BODY_PREFIX = '_Character_Group_Group_Flipbook_Group_FBody_FBGroup_FBody_AllTransB_Full_Body_'

CharacterConstants.BODY_TYPE=
{
    [CharacterConstants.BODY_HUMAN_BROWN_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_01", 
        tHeads = { CharacterConstants.HEAD_HUMAN_BROWN_MALE }, 
        nAccessorySetType = CharacterConstants.HUMAN_MALE,
    }, 
    [CharacterConstants.BODY_HUMAN_YELLOWISH_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_02", 
        tHeads = { CharacterConstants.HEAD_HUMAN_YELLOWISH_MALE },
        nAccessorySetType = CharacterConstants.HUMAN_MALE,        
    },  
    [CharacterConstants.BODY_HUMAN_REDDISH_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_03", 
        tHeads = { CharacterConstants.HEAD_HUMAN_REDDISH_MALE },
        nAccessorySetType = CharacterConstants.HUMAN_MALE,         
    },    
    [CharacterConstants.BODY_HUMAN_WHITE_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_04", 
        tHeads = { CharacterConstants.HEAD_HUMAN_WHITE_MALE },
        nAccessorySetType = CharacterConstants.HUMAN_MALE,         
    }, 
    [CharacterConstants.BODY_HUMAN_BLACK_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_05", 
        tHeads = { CharacterConstants.HEAD_HUMAN_BLACK_MALE },
        nAccessorySetType = CharacterConstants.HUMAN_MALE, 
        
    },  
    [CharacterConstants.BODY_HUMAN_BROWN_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_01", 
        tHeads = { CharacterConstants.HEAD_HUMAN_BROWN_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FEMALE,
    },
    [CharacterConstants.BODY_HUMAN_YELLOWISH_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_02", 
        tHeads = { CharacterConstants.HEAD_HUMAN_YELLOWISH_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FEMALE,
    },   
    [CharacterConstants.BODY_HUMAN_REDDISH_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_03", 
        tHeads = { CharacterConstants.HEAD_HUMAN_REDDISH_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FEMALE,        
    },    
    [CharacterConstants.BODY_HUMAN_WHITE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_04", 
        tHeads = { CharacterConstants.HEAD_HUMAN_WHITE_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FEMALE,
    }, 
    [CharacterConstants.BODY_HUMAN_BLACK_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_05", 
        tHeads = { CharacterConstants.HEAD_HUMAN_BLACK_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FEMALE,
    },
  [CharacterConstants.BODY_HUMAN_FAT_BROWN_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_01", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_BROWN_MALE },        
        nAccessorySetType = CharacterConstants.HUMAN_FAT_MALE,
        bFat = true,
        
    }, 
    [CharacterConstants.BODY_HUMAN_FAT_YELLOWISH_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_02", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_YELLOWISH_MALE },        
        nAccessorySetType = CharacterConstants.HUMAN_FAT_MALE,
        bFat = true,
    },    
    [CharacterConstants.BODY_HUMAN_FAT_REDDISH_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_03", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_REDDISH_MALE },        
        nAccessorySetType = CharacterConstants.HUMAN_FAT_MALE,
        bFat=true,
    },    
    [CharacterConstants.BODY_HUMAN_FAT_WHITE_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_04", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_WHITE_MALE },       
        nAccessorySetType = CharacterConstants.HUMAN_FAT_MALE, 
        bFat=true,
    }, 
    [CharacterConstants.BODY_HUMAN_FAT_BLACK_MALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Male01_base_05", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_BLACK_MALE },        
        nAccessorySetType = CharacterConstants.HUMAN_FAT_MALE,
        bFat=true,
    },  
    [CharacterConstants.BODY_HUMAN_FAT_BROWN_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_01", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_BROWN_FEMALE },        
        nAccessorySetType = CharacterConstants.HUMAN_FAT_FEMALE,
        bFat=true,
    },
    [CharacterConstants.BODY_HUMAN_FAT_YELLOWISH_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_02", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_YELLOWISH_FEMALE },        

        nAccessorySetType = CharacterConstants.HUMAN_FAT_FEMALE, 
        bFat=true,
        
    },   
    [CharacterConstants.BODY_HUMAN_FAT_REDDISH_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_03", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_REDDISH_FEMALE },        
        nAccessorySetType = CharacterConstants.HUMAN_FAT_FEMALE, 
        bFat=true,
    },    
    [CharacterConstants.BODY_HUMAN_FAT_WHITE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_04", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_WHITE_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FAT_FEMALE,
        bFat=true,
    }, 
    [CharacterConstants.BODY_HUMAN_FAT_BLACK_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Human_Body_Female01_base_05", 
        tHeads = { CharacterConstants.HEAD_HUMAN_FAT_BLACK_FEMALE },         
        nAccessorySetType = CharacterConstants.HUMAN_FAT_FEMALE,
        bFat=true,
    },  
    [CharacterConstants.BODY_JELLY_MAUVE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_01", 
        tHeads = { CharacterConstants.HEAD_JELLY_MAUVE_FEMALE },         
        nAccessorySetType = CharacterConstants.JELLY_FEMALE,        
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    }, 
    [CharacterConstants.BODY_JELLY_PURPLE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_02", 
        tHeads = { CharacterConstants.HEAD_JELLY_PURPLE_FEMALE },        
        nAccessorySetType = CharacterConstants.JELLY_FEMALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    }, 
    [CharacterConstants.BODY_JELLY_PINK_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_03", 
        tHeads = { CharacterConstants.HEAD_JELLY_PINK_FEMALE },       
        nAccessorySetType = CharacterConstants.JELLY_FEMALE,      
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    }, 
    [CharacterConstants.BODY_JELLY_BLUE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_04", 
        tHeads = { CharacterConstants.HEAD_JELLY_BLUE_FEMALE },        
        nAccessorySetType = CharacterConstants.JELLY_FEMALE,      
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    },
    
    [CharacterConstants.BODY_JELLY_FAT_MAUVE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_01", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_JELLY_MAUVE_FEMALE },        
        nAccessorySetType = CharacterConstants.JELLY_FAT_FEMALE,        
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    }, 
    [CharacterConstants.BODY_JELLY_FAT_PURPLE_FEMALE] = { 

        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_02", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_JELLY_PURPLE_FEMALE },       
        nAccessorySetType = CharacterConstants.JELLY_FAT_FEMALE,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    }, 
    [CharacterConstants.BODY_JELLY_FAT_PINK_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_03", 
        bFat=true,
        tHeads = {  CharacterConstants.HEAD_JELLY_PINK_FEMALE },         
        nAccessorySetType = CharacterConstants.JELLY_FAT_FEMALE,    
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    }, 
    [CharacterConstants.BODY_JELLY_FAT_BLUE_FEMALE] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Jelly_Body_Female01_base_04", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_JELLY_BLUE_FEMALE },        
        nAccessorySetType = CharacterConstants.JELLY_FAT_FEMALE,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    },
    
    [CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_01] = { 
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Alien_Body01_base_01", 
        tHeads = {  CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_01 },    
        nAccessorySetType = CharacterConstants.TOBIAN,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_02] = { 
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Alien_Body01_base_02", 
        tHeads = {   CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_02, },    
        nAccessorySetType = CharacterConstants.TOBIAN,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        }, 
    }, 
    [CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_03] = { 
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Alien_Body01_base_03", 
        tHeads = { CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_03, },    
        nAccessorySetType = CharacterConstants.TOBIAN,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_04] = { 
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Alien_Body01_base_04", 
        tHeads = { CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_04, },    
        nAccessorySetType = CharacterConstants.TOBIAN,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_TOBIAN_BLUE_ALIEN_05] = { 
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Alien_Body01_base_05", 
        tHeads = { CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_05, },    
        nAccessorySetType = CharacterConstants.TOBIAN,  
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_CAT_MALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Male01_base_01", 
        tHeads = { CharacterConstants.HEAD_CAT_MALE_01 },    
        nAccessorySetType = CharacterConstants.CAT_MALE,  
         
    }, 
    [CharacterConstants.BODY_CAT_MALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Male01_base_02", 
        tHeads = { CharacterConstants.HEAD_CAT_MALE_02 },    
        nAccessorySetType = CharacterConstants.CAT_MALE,  
    }, 
    [CharacterConstants.BODY_CAT_FEMALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Female01_base_01", 
        tHeads = { CharacterConstants.HEAD_CAT_FEMALE_01 },    
        nAccessorySetType = CharacterConstants.CAT_FEMALE,  
    }, 
    [CharacterConstants.BODY_CAT_FEMALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Female01_base_02", 
        tHeads = { CharacterConstants.HEAD_CAT_FEMALE_02 },     
        nAccessorySetType = CharacterConstants.CAT_FEMALE, 
    }, 
    [CharacterConstants.BODY_CAT_FAT_MALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Male01_base_01", 
        bFat=true,
        tHeads = {  CharacterConstants.HEAD_CAT_MALE_01  },    
        nAccessorySetType = CharacterConstants.CAT_FAT_MALE, 
    }, 
    [CharacterConstants.BODY_CAT_FAT_MALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Male01_base_02", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_CAT_MALE_02 },    
        nAccessorySetType = CharacterConstants.CAT_FAT_MALE,
    }, 
    [CharacterConstants.BODY_CAT_FAT_FEMALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Female01_base_01", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_CAT_FEMALE_01 },     
        nAccessorySetType = CharacterConstants.CAT_FAT_FEMALE,
    }, 
    [CharacterConstants.BODY_CAT_FAT_FEMALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Cat_Body_Female01_base_02", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_CAT_FEMALE_02 },   
        nAccessorySetType = CharacterConstants.CAT_FAT_FEMALE,        
    },
    [CharacterConstants.BODY_BIRDSHARK_MALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Male01_base_01", 
        tHeads = { CharacterConstants.HEAD_BIRDSHARK_MALE_01  },
        nAccessorySetType = CharacterConstants.BIRDSHARK_MALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        }, 
    }, 
    [CharacterConstants.BODY_BIRDSHARK_MALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Male01_base_02", 
        tHeads = { CharacterConstants.HEAD_BIRDSHARK_MALE_02 }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_MALE,        
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    }, 
    [CharacterConstants.BODY_BIRDSHARK_FEMALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Female01_base_01", 
        tHeads = {  CharacterConstants.HEAD_BIRDSHARK_FEMALE_01 }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_FEMALE,        
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    }, 
    [CharacterConstants.BODY_BIRDSHARK_FEMALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_Body', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Female01_base_02", 
        tHeads = {  CharacterConstants.HEAD_BIRDSHARK_FEMALE_02 }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_FEMALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_NORMAL,
        },
    },
    [CharacterConstants.BODY_BIRDSHARK_FAT_MALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Male01_base_01", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_BIRDSHARK_MALE_01  }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_FAT_MALE,       
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    }, 
    [CharacterConstants.BODY_BIRDSHARK_FAT_MALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Male01_base_01", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_BIRDSHARK_MALE_02  }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_FAT_MALE, 
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    }, 
    [CharacterConstants.BODY_BIRDSHARK_FAT_FEMALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Female01_base_01", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_BIRDSHARK_FEMALE_01  }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_FAT_FEMALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    }, 
    [CharacterConstants.BODY_BIRDSHARK_FAT_FEMALE_02] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "F", 
        sBodyModel = 'Female01_FatBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Bird_Body_Female01_base_01", 
        bFat=true,
        tHeads = { CharacterConstants.HEAD_BIRDSHARK_FEMALE_02  }, 
        nAccessorySetType = CharacterConstants.BIRDSHARK_FAT_FEMALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_FAT,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_FAT,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_FAT,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_BASE_FAT,
        },
    },
    [CharacterConstants.BODY_CHICKEN_MALE_01] = {
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Chicken_Body01_base_01", 
        tHeads = { CharacterConstants.HEAD_CHICKEN_MALE_01 },
        nAccessorySetType = CharacterConstants.CHICKEN_MALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_CHICKEN_MALE_02] = {
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Chicken_Body01_base_02", 
        tHeads = {  CharacterConstants.HEAD_CHICKEN_MALE_02 },
        nAccessorySetType = CharacterConstants.CHICKEN_MALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        }, 
    },
    [CharacterConstants.BODY_CHICKEN_FEMALE_01] = {
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "F", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Chicken_Body01_base_03", 
        tHeads = { CharacterConstants.HEAD_CHICKEN_FEMALE_01 },
        nAccessorySetType = CharacterConstants.CHICKEN_FEMALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_CHICKEN_FEMALE_02] = {
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "F", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Chicken_Body01_base_04", 
        tHeads = {  CharacterConstants.HEAD_CHICKEN_FEMALE_02  }, 
        nAccessorySetType = CharacterConstants.CHICKEN_FEMALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },         
    },
    [CharacterConstants.BODY_MONSTER] = {
        nRig = CharacterConstants.RIG_MONSTER, 
        sSex = "F", 
        bNoReplacements=true,
        bNoSpacesuit=true,
        --sBodyModel = 'Alien01_Body', 
        --sBodyTexture = "Characters/Citizen_Alien/Textures/Chicken_Body01_base_04", 
    },
    [CharacterConstants.BODY_SHAMON_MALE_01] = { 
        nRig = CharacterConstants.RIG_BASE, 
        sSex = "M", 
        sBodyModel = 'Male01_ShamonBody', 
        sBodyTexture = "Characters/Citizen_Base/Textures/Shamon_Body", 
        tHeads = { CharacterConstants.HEAD_SHAMON_MALE_01 },
        nAccessorySetType = CharacterConstants.SHAMON_MALE,
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_NORMAL_HOOF_BOOT,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_BASE_NORMAL,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_NORMAL_HOOF_BOOT,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_NORMAL_HOOF_BOOT,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.NO_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.BOTANIST] = CharacterConstants.NO_HELMET,
            [CharacterConstants.SCIENTIST] = CharacterConstants.NO_HELMET,
        },
    }, 
    [CharacterConstants.BODY_MURDERFACE_MALE_01] = {
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        sBodyModel = 'Alien01_Body', 
        sBodyTexture = "Characters/Citizen_Alien/Textures/Murder_Body01", 
        tHeads = { CharacterConstants.HEAD_MURDERFACE_MALE_01 },
        nAccessorySetType = CharacterConstants.MURDERFACE_MALE, 
        tJobOutfits = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_TOBIAN_NO_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.TECHNICIAN_TOBIAN,     
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN,     
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN,
            [CharacterConstants.RAIDER] = CharacterConstants.RAIDER_TOBIAN_NO_HELMET,
        },         
    },
    [CharacterConstants.BODY_KILLBOT_01] = {
        nRig = CharacterConstants.RIG_ALIEN, 
        sSex = "M", 
        bNoReplacements=true,
        bNoSpacesuit=true,
    },
}

-- HEADS --------------------------------------------------------------------
CharacterConstants.HEAD_PREFIX = '_Character_Group_Group_Flipbook_Group_Head_FBGroup_Head_Head_Heads_'

CharacterConstants.HEAD_TYPE=
{   --0 = no hair in tHairs, handled in Character:_setHair()
    [CharacterConstants.HEAD_HUMAN_BROWN_MALE] = { 
        sHeadModel = 'Male01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_01", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },     
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,            
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_HUMAN_YELLOWISH_MALE] = { 
        sHeadModel = 'Male01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_02", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_HUMAN_REDDISH_MALE] = { 
        sHeadModel = 'Male01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_03", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_HUMAN_WHITE_MALE] = { 
        sHeadModel = 'Male01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_04", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_HUMAN_BLACK_MALE] = { 
        sHeadModel = 'Male01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_05", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_BROWN_FEMALE] = { 
        sHeadModel = 'Female01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_01", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_HUMAN_YELLOWISH_FEMALE] = { 
        sHeadModel = 'Female01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_02", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_REDDISH_FEMALE] = { 
        sHeadModel = 'Female01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_03", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_WHITE_FEMALE] = { 
        sHeadModel = 'Female01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_04", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_BLACK_FEMALE] = { 
        sHeadModel = 'Female01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_05", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_BROWN_MALE] = { 
        sHeadModel = 'Male01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_01", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_YELLOWISH_MALE] = { 
        sHeadModel = 'Male01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_02", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_HUMAN_FAT_REDDISH_MALE] = { 
        sHeadModel = 'Male01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_03",
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_WHITE_MALE] = { 
        sHeadModel = 'Male01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_04", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_BLACK_MALE] = { 
        sHeadModel = 'Male01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Male01_base_05", 
        nHairSetType = CharacterConstants.HUMAN_MALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED,
            CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY,
			CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_BROWN_FEMALE] = { 
        sHeadModel = 'Female01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_01", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_YELLOWISH_FEMALE] = { 
        sHeadModel = 'Female01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_02", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_REDDISH_FEMALE] = { 
        sHeadModel = 'Female01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_03", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_WHITE_FEMALE] = { 
        sHeadModel = 'Female01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_04",
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },  
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_HUMAN_FAT_BLACK_FEMALE] = { 
        sHeadModel = 'Female01_FatHead', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Human_Head_Female01_base_05", 
        nHairSetType = CharacterConstants.HUMAN_FEMALE,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_JELLY_MAUVE_FEMALE] = { 
        sHeadModel = 'Jelly01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Jelly_Head_Female01_base_01",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_JELLY_PURPLE_FEMALE] = { 
        sHeadModel = 'Jelly01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Jelly_Head_Female01_base_02",         
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_JELLY_PINK_FEMALE] = { 
        sHeadModel = 'Jelly01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Jelly_Head_Female01_base_03",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_JELLY_BLUE_FEMALE] = { 
        sHeadModel = 'Jelly01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Jelly_Head_Female01_base_04",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_01] = { 
        sHeadModel = 'Alien01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_01",       
        nHairSetType = CharacterConstants.TOBIAN_BLUE_ALIEN_01,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_02] = { 
        sHeadModel = 'Alien01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_02",       
        nHairSetType = CharacterConstants.TOBIAN_BLUE_ALIEN_02,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,

        },tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_03] = { 
        sHeadModel = 'Alien01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_03",      
        nHairSetType = CharacterConstants.TOBIAN_BLUE_ALIEN_03,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_04] = { 
        sHeadModel = 'Alien01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_04",      
        nHairSetType = CharacterConstants.TOBIAN_BLUE_ALIEN_04,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_TOBIAN_BLUE_ALIEN_05] = { 
        sHeadModel = 'Alien01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_05",       
        nHairSetType = CharacterConstants.TOBIAN_BLUE_ALIEN_05,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },    
    [CharacterConstants.HEAD_CAT_MALE_01] = { 
        sHeadModel = 'Cat01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Cat_Head_Male01_base_01", 
        nHairSetType = CharacterConstants.CAT_MALE_01,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_CAT_MALE_02] = { 
        sHeadModel = 'Cat01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Cat_Head_Male01_base_02", 
        nHairSetType = CharacterConstants.CAT_MALE_02,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_CAT_FEMALE_01] = { 
        sHeadModel = 'Cat01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Cat_Head_Female01_base_01",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_CAT_FEMALE_02] = { 
        sHeadModel = 'Cat01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Cat_Head_Female01_base_02",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.BUILDER_BASE_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_BIRDSHARK_MALE_01] = { 
        sHeadModel = 'Bird01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Bird_Head_Male01_base_01",       
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_BIRDSHARK_MALE_02] = { 
        sHeadModel = 'Bird01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Bird_Head_Male01_base_02",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_BIRDSHARK_FEMALE_01] = { 
        sHeadModel = 'Bird01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Bird_Head_Female01_base_01",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_BIRDSHARK_FEMALE_02] = { 
        sHeadModel = 'Bird01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Bird_Head_Female01_base_02",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_CHICKEN_MALE_01] = { 
        sHeadModel = 'Chicken01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Chicken_Head01_base_01",       
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_01,
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_02,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CHICKEN_COMB_01,
            CharacterConstants.FACE_TOP_CHICKEN_COMB_02,
            
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_CHICKEN_MALE_02] = { 
        sHeadModel = 'Chicken01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Chicken_Head01_base_02",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_01,
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_02,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CHICKEN_COMB_01,
            CharacterConstants.FACE_TOP_CHICKEN_COMB_02,
            
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,

            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.HEAD_CHICKEN_FEMALE_01] = { 
        sHeadModel = 'Chicken01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Chicken_Head01_base_03",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_03,
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_04,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CHICKEN_COMB_03,
            CharacterConstants.FACE_TOP_CHICKEN_COMB_04,
            
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_CHICKEN_FEMALE_02] = { 
        sHeadModel = 'Chicken01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Chicken_Head01_base_04",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_03,
            CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_04,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CHICKEN_COMB_03,
            CharacterConstants.FACE_TOP_CHICKEN_COMB_04,
            
        }, 
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
    [CharacterConstants.NO_REPLACE] = {        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.NO_REPLACE,
        },
        tFaceTop = {
            CharacterConstants.NO_REPLACE,
        }, 
    },
    [CharacterConstants.HEAD_SHAMON_MALE_01] = { 
        sHeadModel = 'Shamon01_Head', 
        sHeadTexture = "Characters/Citizen_Base/Textures/Shamon_Head01",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_BASE_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_BASE_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        }, 
    },
    [CharacterConstants.HEAD_MURDERFACE_MALE_01] = { 
        sHeadModel = 'Murderface01_Head', 
        sHeadTexture = "Characters/Citizen_Alien/Textures/Murder_Head01",        
        nHairSetType = CharacterConstants.BALD,
        tFaceBottom = {
            CharacterConstants.FACE_BOTTOM_CLEAR,
        },
        tFaceTop = {
            CharacterConstants.FACE_TOP_CLEAR,
        },
        tJobHelmets = {
            [CharacterConstants.BUILDER] = CharacterConstants.NO_HELMET,
            [CharacterConstants.TECHNICIAN] = CharacterConstants.NO_HELMET,
            [CharacterConstants.EMERGENCY] = CharacterConstants.EMERGENCY_TOBIAN_HELMET,
            [CharacterConstants.MINER] = CharacterConstants.MINER_TOBIAN_HELMET,
            [CharacterConstants.BARTENDER] = CharacterConstants.NO_HELMET,
        },
    },
}

-- FACE PARTS ----------------------------------------------------------------
CharacterConstants.FACE_BOTTOM_TYPE=
{
    [CharacterConstants.FACE_BOTTOM_CLEAR] = "transparent",
    [CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_01] = "Characters/Citizen_Alien/Textures/Chicken_Head01_bottom_01",
    [CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_02] = "Characters/Citizen_Alien/Textures/Chicken_Head01_bottom_02",
    [CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_03] = "Characters/Citizen_Alien/Textures/Chicken_Head01_bottom_03",
    [CharacterConstants.FACE_BOTTOM_CHICKEN_BEAK_04] = "Characters/Citizen_Alien/Textures/Chicken_Head01_bottom_04",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLONDE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_01_Color_01",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_RED] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_01_Color_02",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BRUNETTE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_01_Color_03",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_BLACK] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_01_Color_04",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLONDE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_02_Color_01",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_RED] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_02_Color_02",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BRUNETTE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_02_Color_03",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_BLACK] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_02_Color_04",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLONDE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_03_Color_01",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_RED] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_03_Color_02",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BRUNETTE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_03_Color_03",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_BLACK] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_03_Color_04",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLONDE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_04_Color_01",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_RED] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_04_Color_02",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BRUNETTE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_04_Color_03",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_BLACK] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_04_Color_04",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLONDE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_05_Color_01",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_RED] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_05_Color_02",
    [CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BRUNETTE] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_05_Color_03",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_BLACK] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_05_Color_04",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_01_GRAY] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_01_Color_05",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_02_GRAY] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_02_Color_05",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_03_GRAY] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_03_Color_05",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_04_GRAY] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_04_Color_05",
	[CharacterConstants.FACE_BOTTOM_HUMAN_BEARD_05_GRAY] = "Characters/Citizen_Base/Textures/Human_Head_Male01_bottom_05_Color_05",
}

CharacterConstants.FACE_TOP_TYPE=
{
    [CharacterConstants.FACE_TOP_CLEAR] = "transparent",
    [CharacterConstants.FACE_TOP_CHICKEN_COMB_01] = "Characters/Citizen_Alien/Textures/Chicken_Head01_top_01",
    [CharacterConstants.FACE_TOP_CHICKEN_COMB_02] = "Characters/Citizen_Alien/Textures/Chicken_Head01_top_02",
    [CharacterConstants.FACE_TOP_CHICKEN_COMB_03] = "Characters/Citizen_Alien/Textures/Chicken_Head01_top_03",
    [CharacterConstants.FACE_TOP_CHICKEN_COMB_04] = "Characters/Citizen_Alien/Textures/Chicken_Head01_top_04",
}


-- HAIR/ALIEN EYES ---------------------------------------------------------------
CharacterConstants.HAIR_PREFIX = "_Character_Group_Group_Flipbook_Group_Hair_FBGroup_Hairs_Head_Hairs_"

CharacterConstants.HAIR_TYPE=
{   --{modelName, texturePath}
    [CharacterConstants.BALD] = { },
    [CharacterConstants.MALE_HAIR_01_BLONDE] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.MALE_HAIR_01_RED] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.MALE_HAIR_01_BRUNETTE] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.MALE_HAIR_01_BLACK] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.MALE_HAIR_01_REDBANGS] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.MALE_HAIR_01_BLUEBANGS] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.MALE_HAIR_01_GRAY] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.MALE_HAIR_02_BLONDE] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.MALE_HAIR_02_RED] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.MALE_HAIR_02_BRUNETTE] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.MALE_HAIR_02_BLACK] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.MALE_HAIR_02_REDBANGS] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.MALE_HAIR_02_BLUEBANGS] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.MALE_HAIR_02_GRAY] = { sHairModel = 'Short03', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.MALE_HAIR_03_BLONDE] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.MALE_HAIR_03_RED] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.MALE_HAIR_03_BRUNETTE] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.MALE_HAIR_03_BLACK] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.MALE_HAIR_03_REDBANGS] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.MALE_HAIR_03_BLUEBANGS] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.MALE_HAIR_03_GRAY] = { sHairModel = 'Short05', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.MALE_HAIR_04_BLONDE] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.MALE_HAIR_04_RED] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.MALE_HAIR_04_BRUNETTE] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.MALE_HAIR_04_BLACK] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.MALE_HAIR_04_REDBANGS] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.MALE_HAIR_04_BLUEBANGS] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.MALE_HAIR_04_GRAY] = { sHairModel = 'Short07', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.MALE_HAIR_05_BLONDE] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.MALE_HAIR_05_RED] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Red" },
	[CharacterConstants.MALE_HAIR_05_BRUNETTE] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.MALE_HAIR_05_BLACK] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.MALE_HAIR_05_REDBANGS] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.MALE_HAIR_05_BLUEBANGS] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.MALE_HAIR_05_GRAY] = { sHairModel = 'Short08', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.FEMALE_HAIR_01_BLONDE] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.FEMALE_HAIR_01_RED] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.FEMALE_HAIR_01_BRUNETTE] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.FEMALE_HAIR_01_BLACK] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.FEMALE_HAIR_01_PURPLE] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_05", sPortraitColor = "Pink" },
	[CharacterConstants.FEMALE_HAIR_01_GREEN] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_06", sPortraitColor = "Green" },
	[CharacterConstants.FEMALE_HAIR_01_GRAY] = { sHairModel = 'Short01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_07", sPortraitColor = "Gray" }, 
    [CharacterConstants.FEMALE_HAIR_02_BLONDE] = { sHairModel = 'Short02', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short02_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.FEMALE_HAIR_02_RED] = { sHairModel = 'Short02', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short02_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.FEMALE_HAIR_02_BRUNETTE] = { sHairModel = 'Short02', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short02_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.FEMALE_HAIR_02_BLACK] = { sHairModel = 'Short02', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short02_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.FEMALE_HAIR_02_GRAY] = { sHairModel = 'Short02', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short02_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.FEMALE_HAIR_03_BLONDE] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.FEMALE_HAIR_03_RED] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.FEMALE_HAIR_03_BRUNETTE] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.FEMALE_HAIR_03_BLACK] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.FEMALE_HAIR_03_REDBANGS] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.FEMALE_HAIR_03_BLUEBANGS] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.FEMALE_HAIR_03_GRAY] = { sHairModel = 'Short06', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.FEMALE_HAIR_04_BLONDE] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.FEMALE_HAIR_04_RED] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.FEMALE_HAIR_04_BRUNETTE] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.FEMALE_HAIR_04_BLACK] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.FEMALE_HAIR_04_REDBANGS] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_05", sPortraitColor = "Red" },
	[CharacterConstants.FEMALE_HAIR_04_BLUEBANGS] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_06", sPortraitColor = "Blue" },
	[CharacterConstants.FEMALE_HAIR_04_GRAY] = { sHairModel = 'Short04', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Short03_Color_07", sPortraitColor = "Gray" },
	[CharacterConstants.FEMALE_HAIR_05_BLONDE] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_01", sPortraitColor = "Yellow" },
	[CharacterConstants.FEMALE_HAIR_05_RED] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_02", sPortraitColor = "Orange" },
	[CharacterConstants.FEMALE_HAIR_05_BRUNETTE] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_03", sPortraitColor = "Brown" },
	[CharacterConstants.FEMALE_HAIR_05_BLACK] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_04", sPortraitColor = "Black" },
	[CharacterConstants.FEMALE_HAIR_05_PURPLE] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_05", sPortraitColor = "Pink" },
	[CharacterConstants.FEMALE_HAIR_05_GREEN] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_06", sPortraitColor = "Green" },
	[CharacterConstants.FEMALE_HAIR_05_GRAY] = { sHairModel = 'Long01', sHairTexture = "Characters/Citizen_Base/Textures/Hair_Long01_Color_07", sPortraitColor = "Gray" },
    [CharacterConstants.TOBIAN_DONG_01] = { sHairModel = 'Alien01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_01" },    
    [CharacterConstants.TOBIAN_DONG_02] = { sHairModel = 'Alien01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_02" },    
    [CharacterConstants.TOBIAN_DONG_03] = { sHairModel = 'Alien01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_03" },    
    [CharacterConstants.TOBIAN_DONG_04] = { sHairModel = 'Alien01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_04" },    
    [CharacterConstants.TOBIAN_DONG_05] = { sHairModel = 'Alien01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Alien_Head01_base_05" },    
    [CharacterConstants.TOBIAN_MUSTACHE_01] = { sHairModel = 'Moustache01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Moustache01_Hair01_base_01" },
    [CharacterConstants.TOBIAN_MUSTACHE_02] = { sHairModel = 'Moustache01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Moustache01_Hair01_base_02" },
    [CharacterConstants.TOBIAN_MUSTACHE_03] = { sHairModel = 'Moustache01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Moustache01_Hair01_base_03" },
    [CharacterConstants.TOBIAN_MUSTACHE_04] = { sHairModel = 'Moustache01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Moustache01_Hair01_base_04" },
    [CharacterConstants.TOBIAN_MUSTACHE_05] = { sHairModel = 'Moustache01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Moustache01_Hair01_base_05" },    
    [CharacterConstants.TOBIAN_ELEPHANT_01] = { sHairModel = 'Elephant01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Elephant01_Hair01_base_01" },    
    [CharacterConstants.TOBIAN_ELEPHANT_02] = { sHairModel = 'Elephant01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Elephant01_Hair01_base_02" },    
    [CharacterConstants.TOBIAN_ELEPHANT_03] = { sHairModel = 'Elephant01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Elephant01_Hair01_base_03" },    
    [CharacterConstants.TOBIAN_ELEPHANT_04] = { sHairModel = 'Elephant01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Elephant01_Hair01_base_04" },    
    [CharacterConstants.TOBIAN_ELEPHANT_05] = { sHairModel = 'Elephant01_Hair01', sHairTexture = "Characters/Citizen_Alien/Textures/Elephant01_Hair01_base_05" },  
    [CharacterConstants.CAT_MUSTACHE_01] = { sHairModel = 'Cat01', sHairTexture = "Characters/Citizen_Base/Textures/Cat_Head_Male01_base_01" },  
    [CharacterConstants.CAT_MUSTACHE_02] = { sHairModel = 'Cat01', sHairTexture = "Characters/Citizen_Base/Textures/Cat_Head_Male01_base_02" },  
    [CharacterConstants.NO_REPLACE] = { 
    },
}

CharacterConstants.HAIR_SET_TYPE=
{
    [CharacterConstants.BALD]={
        tHairs = { CharacterConstants.BALD },
    },
    [CharacterConstants.HUMAN_MALE] = { 
        tHairs = { 
            CharacterConstants.BALD,
            CharacterConstants.MALE_HAIR_01_BLONDE,
            CharacterConstants.MALE_HAIR_01_RED,
            CharacterConstants.MALE_HAIR_01_BRUNETTE,
            CharacterConstants.MALE_HAIR_01_BLACK,
            CharacterConstants.MALE_HAIR_01_REDBANGS,
            CharacterConstants.MALE_HAIR_01_BLUEBANGS,
            CharacterConstants.MALE_HAIR_02_BLONDE,
            CharacterConstants.MALE_HAIR_02_RED,
            CharacterConstants.MALE_HAIR_02_BRUNETTE,
            CharacterConstants.MALE_HAIR_02_BLACK,
            CharacterConstants.MALE_HAIR_02_REDBANGS,
            CharacterConstants.MALE_HAIR_02_BLUEBANGS,
            CharacterConstants.MALE_HAIR_03_BLONDE, 
            CharacterConstants.MALE_HAIR_03_RED,
            CharacterConstants.MALE_HAIR_03_BRUNETTE,
            CharacterConstants.MALE_HAIR_03_BLACK,
            CharacterConstants.MALE_HAIR_03_REDBANGS,
            CharacterConstants.MALE_HAIR_03_BLUEBANGS,
            CharacterConstants.MALE_HAIR_04_BLONDE, 
            CharacterConstants.MALE_HAIR_04_RED,
            CharacterConstants.MALE_HAIR_04_BRUNETTE,
            CharacterConstants.MALE_HAIR_04_BLACK,
            CharacterConstants.MALE_HAIR_04_REDBANGS,
            CharacterConstants.MALE_HAIR_04_BLUEBANGS,
            CharacterConstants.MALE_HAIR_05_BLONDE, 
            CharacterConstants.MALE_HAIR_05_RED,
            CharacterConstants.MALE_HAIR_05_BRUNETTE,
            CharacterConstants.MALE_HAIR_05_BLACK,
            CharacterConstants.MALE_HAIR_05_REDBANGS,
            CharacterConstants.MALE_HAIR_05_BLUEBANGS,
            CharacterConstants.MALE_HAIR_01_GRAY,
            CharacterConstants.MALE_HAIR_02_GRAY,
            CharacterConstants.MALE_HAIR_03_GRAY,
            CharacterConstants.MALE_HAIR_04_GRAY,
            CharacterConstants.MALE_HAIR_05_GRAY,
        }, 
    },
    [CharacterConstants.HUMAN_FEMALE] = { 
        tHairs = { 
            CharacterConstants.BALD,            
            CharacterConstants.FEMALE_HAIR_01_BLONDE,
			CharacterConstants.FEMALE_HAIR_01_RED,
			CharacterConstants.FEMALE_HAIR_01_BRUNETTE,
			CharacterConstants.FEMALE_HAIR_01_BLACK,
			CharacterConstants.FEMALE_HAIR_01_PURPLE,
			CharacterConstants.FEMALE_HAIR_01_GREEN,
            CharacterConstants.FEMALE_HAIR_02_BLONDE,
			CharacterConstants.FEMALE_HAIR_02_RED,
			CharacterConstants.FEMALE_HAIR_02_BRUNETTE,
			CharacterConstants.FEMALE_HAIR_02_BLACK,
            CharacterConstants.FEMALE_HAIR_03_BLONDE,
			CharacterConstants.FEMALE_HAIR_03_RED,
			CharacterConstants.FEMALE_HAIR_03_BRUNETTE,
			CharacterConstants.FEMALE_HAIR_03_BLACK,
			CharacterConstants.FEMALE_HAIR_03_REDBANGS,
			CharacterConstants.FEMALE_HAIR_03_BLUEBANGS,
            CharacterConstants.FEMALE_HAIR_04_BLONDE,
			CharacterConstants.FEMALE_HAIR_04_RED,
			CharacterConstants.FEMALE_HAIR_04_BRUNETTE,
			CharacterConstants.FEMALE_HAIR_04_BLACK,
			CharacterConstants.FEMALE_HAIR_04_REDBANGS,
			CharacterConstants.FEMALE_HAIR_04_BLUEBANGS,
            CharacterConstants.FEMALE_HAIR_05_BLONDE,
			CharacterConstants.FEMALE_HAIR_05_RED,
			CharacterConstants.FEMALE_HAIR_05_BRUNETTE,
			CharacterConstants.FEMALE_HAIR_05_BLACK,
			CharacterConstants.FEMALE_HAIR_05_PURPLE,
			CharacterConstants.FEMALE_HAIR_05_GREEN,
			CharacterConstants.FEMALE_HAIR_01_GRAY,
			CharacterConstants.FEMALE_HAIR_02_GRAY,
			CharacterConstants.FEMALE_HAIR_03_GRAY,
			CharacterConstants.FEMALE_HAIR_04_GRAY,
			CharacterConstants.FEMALE_HAIR_05_GRAY,
        },
    },
    [CharacterConstants.TOBIAN_BLUE_ALIEN_01] = {
        tHairs = {         
            CharacterConstants.TOBIAN_DONG_01,
            CharacterConstants.TOBIAN_MUSTACHE_01,            
            CharacterConstants.TOBIAN_ELEPHANT_01,
        },
    },
    [CharacterConstants.TOBIAN_BLUE_ALIEN_02] = {
        tHairs = {         
            CharacterConstants.TOBIAN_DONG_02,
            CharacterConstants.TOBIAN_MUSTACHE_02,            
            CharacterConstants.TOBIAN_ELEPHANT_02,
        },
    },
    [CharacterConstants.TOBIAN_BLUE_ALIEN_03] = {
        tHairs = {         
            CharacterConstants.TOBIAN_DONG_03,
            CharacterConstants.TOBIAN_MUSTACHE_03,            
            CharacterConstants.TOBIAN_ELEPHANT_03,
        },
    },
    [CharacterConstants.TOBIAN_BLUE_ALIEN_04] = {
        tHairs = {         
            CharacterConstants.TOBIAN_DONG_04,
            CharacterConstants.TOBIAN_MUSTACHE_04,            
            CharacterConstants.TOBIAN_ELEPHANT_04,
        },
    },
    [CharacterConstants.TOBIAN_BLUE_ALIEN_05] = {
        tHairs = {         
            CharacterConstants.TOBIAN_DONG_05,
            CharacterConstants.TOBIAN_MUSTACHE_05,            
            CharacterConstants.TOBIAN_ELEPHANT_05,
        },
    },     
    [CharacterConstants.CAT_MALE_01]={
        tHairs = { CharacterConstants.CAT_MUSTACHE_01, }, 
    },
    [CharacterConstants.CAT_MALE_02]={
        tHairs = { CharacterConstants.CAT_MUSTACHE_02, }, 
    },
}


-- ACCESSORIES (STYLE) -------------------------------------------------------
CharacterConstants.BOTTOM_ACCESSORY_PREFIX = "_Character_Group_Group_Flipbook_Group_AC_LwBody_FBGroup_LwBody_AllTransB_LwBody_"

CharacterConstants.BOTTOM_ACCESSORY_TYPE=
{   --{modelName, texturePath}
    [CharacterConstants.MALE_BOTTOM_ACCESSORY_LEGPOUCH_01] = { 
        sModel = 'M_LegPouch01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches",
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        }, 
    },
    [CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01] = { 
        sModel = 'M_FatLegPouch', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches",
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        }, 
    },
    [CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01] = { 
        sModel = 'F_FatLegPouch', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches",
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        }, 
    },
    [CharacterConstants.MALE_BOTTOM_ACCESSORY_BELT_01] = { 
        sModel = 'Belt01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01] = { 
        sModel = 'F_LegPouch01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches",
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01] = { 
        sModel = 'Belt01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_BELT_01] = { 
        sModel = 'FatBelt_F', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_BELT_01] = { 
        sModel = 'FatBelt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_LEGPOUCH_01] = { 
        sModel = 'LegPouch01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_BELT_01] = { 
        sModel = 'Belt01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01] = { 
        sModel = 'TouristShorts_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shorts_Male_01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01] = { 
        sModel = 'TouristShorts_F', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shorts_Female_01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_TOURISTSHORTS_01] = { 
        sModel = 'FatTouristShorts_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shorts_Male_01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_TOURISTSHORTS_01] = { 
        sModel = 'TouristShorts', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shorts_Male_01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.NO_REPLACE] = { 
    },
    [CharacterConstants.SHAMON_BOTTOM_ACCESSORY_LEGPOUCH_01] = { 
        sModel = 'ShamonLegPouch01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches",
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        }, 
    },
    [CharacterConstants.SHAMON_BOTTOM_ACCESSORY_BELT_01] = { 
        sModel = 'ShamonBelt01', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
}

CharacterConstants.TOP_ACCESSORY_PREFIX = "_Character_Group_Group_Flipbook_Group_AC_UpBody_FBGroup_UpBody_AllTransB_UpBody_"

CharacterConstants.TOP_ACCESSORY_TYPE=
{   --{modelName, texturePath}
    [CharacterConstants.MALE_TOP_ACCESSORY_COLLAR_01] = { 
        sModel = 'M_Collar01', 
        sTexture = "Characters/Citizen_Base/Textures/Collar01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_COLLAR_01] = { 
        sModel = 'M_FatCollar01', 
        sTexture = "Characters/Citizen_Base/Textures/Collar01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_VEST_01] = { 
        sModel = 'Vest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.SCIENTIST,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE] = { 
        sModel = 'Vest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_COLLAR_01] = { 
        sModel = 'F_Collar01', 
        sTexture = "Characters/Citizen_Base/Textures/Collar01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01] = { 
        sModel = 'Vest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE] = { 
        sModel = 'Vest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_01] = { 
        sModel = 'Bandoleer_01_F', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },   
    [CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_01] = { 
        sModel = 'FatBandoleer_01_F', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },  
 [CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_02] = { 
        sModel = 'Bandoleer_02_F', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },   
    [CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_02] = { 
        sModel = 'FatBandoleer_02_F', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },   
    [CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_01] = { 
        sModel = 'Bandoleer_01_M', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },   
    [CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_02] = { 
        sModel = 'Bandoleer_02_M', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    }, 
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_01] = { 
        sModel = 'FatBandoleer_01_M', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },  
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_02] = { 
        sModel = 'FatBandoleer_02_M', 
        sTexture = "Characters/Citizen_Base/Textures/Straps_Pouches", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },  
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02] = { 
        sModel = 'FatTouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03] = { 
        sModel = 'FatTouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_03", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_04] = { 
        sModel = 'FatTouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_04", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_05] = { 
        sModel = 'FatTouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02] = { 
        sModel = 'TouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03] = { 
        sModel = 'TouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_03", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_04] = { 
        sModel = 'TouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_04", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_05] = { 
        sModel = 'TouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_02] = { 
        sModel = 'TouristShirt_F', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_03] = { 
        sModel = 'TouristShirt_F', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_03", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_04] = { 
        sModel = 'TouristShirt_F', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_04", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_05] = { 
        sModel = 'TouristShirt_F', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_05", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_COLLAR_01] = { 
        sModel = 'Collar01', 
        sTexture = "Characters/Citizen_Base/Textures/Collar01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01] = { 
        sModel = 'TobianVest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01_BEIGE] = { 
        sModel = 'TobianVest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_SEXYSHIRT_01] = { 
        sModel = 'M_RobeShirt01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01] = { 
        sModel = 'Male01_Lf_ArmGauntlet', 
        sTexture = "Characters/Citizen_Base/Textures/Arm_Gauntlet", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
        },
    },
    [CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01] = { 
        sModel = 'Male01_Rt_ArmGauntlet1', 
        sTexture = "Characters/Citizen_Base/Textures/Arm_Gauntlet", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_ROBESHIRT_01] = { 
        sModel = 'TobianRobeShirt01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_03] = {
        sModel = 'TobianTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.BUILDER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_04] = {
        sModel = 'TobianTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_04", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BUILDER,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_05] = {
        sModel = 'TobianTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,

        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02] = { 
        sModel = 'TouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BUILDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03] = { 
        sModel = 'TouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BUILDER,
            CharacterConstants.BARTENDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02] = { 
        sModel = 'FatTouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_02", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03] = { 
        sModel = 'FatTouristShirt_M', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.NO_REPLACE] = { 
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_VEST_01] = { 
        sModel = 'ShamonVest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_02] = { 
        sModel = 'ShamonTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_02", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_03] = { 
        sModel = 'ShamonTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.BUILDER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_04] = { 
        sModel = 'ShamonTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_04", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.BUILDER,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_05] = { 
        sModel = 'ShamonTouristShirt', 
        sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_05", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BUILDER,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_SEXYSHIRT_01] = { 
        sModel = 'ShamonRobeShirt01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody03", 
        tJobModelConflicts = {
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.SHAMON_TOP_ACCESSORY_VEST_01_BEIGE] = { 
        sModel = 'ShamonVest01', 
        sTexture = "Characters/Citizen_Base/Textures/AC_UpBody02", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
            CharacterConstants.BARTENDER,
            CharacterConstants.BOTANIST,
            CharacterConstants.SCIENTIST,
            CharacterConstants.DOCTOR,
            CharacterConstants.JANITOR,
			CharacterConstants.TRADER,
        },
    },
    [CharacterConstants.TOP_ACCESSORY_HUMANVISOR_01] = { 
        sModel = 'Human_Visor01', 
        sTexture = "Characters/Citizen_Base/Textures/Visor01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
        },
    },
    [CharacterConstants.TOP_ACCESSORY_CATVISOR_01] = { 
        sModel = 'Cat_Visor01', 
        sTexture = "Characters/Citizen_Base/Textures/Visor01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,

            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
        },
    },
    [CharacterConstants.TOP_ACCESSORY_BIRDSHARKVISOR_01] = { 
        sModel = 'Birdshark_Visor01', 
        sTexture = "Characters/Citizen_Base/Textures/Visor01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
        },
    },
    [CharacterConstants.TOP_ACCESSORY_SHAMONVISOR_01] = { 
        sModel = 'Shamon_Visor01', 
        sTexture = "Characters/Citizen_Base/Textures/Visor01", 
        tJobModelConflicts = {
            CharacterConstants.BUILDER,
            CharacterConstants.TECHNICIAN,
            CharacterConstants.MINER,
            CharacterConstants.EMERGENCY,
        },
    },
}
CharacterConstants.ACCESSORY_SET_TYPE=
{
    [CharacterConstants.HUMAN_MALE] = {
        tTopAccessories = { 
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.MALE_TOP_ACCESSORY_SEXYSHIRT_01,
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_01, 
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_02,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_HUMANVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.MALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01,

        },
    },
    [CharacterConstants.HUMAN_FEMALE] = {
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_01,       
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_02,  
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_02, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_03, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_04, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_05, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_HUMANVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.JELLY_FEMALE] = {
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,    
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_01,      
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_02,  
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_02, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_03, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_04, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_05, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01, 
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.JELLY_FAT_FEMALE] = {
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_01, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_02, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01, 
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.TOBIAN] = {     
        tTopAccessories = { 
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_ROBESHIRT_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_05,
        }, 
        tBottomAccessories = { 
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_BELT_01,            
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.CAT_MALE] = {
        tTopAccessories = { 
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_01, 
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_02,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_CATVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.MALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.CAT_FEMALE] = {    
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_01, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_02, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_02,
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_05, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_CATVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.CAT_FAT_MALE] = {     
        tTopAccessories = { 
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_01, 
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_02,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_04,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_05, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_CATVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01,
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_BELT_01, 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.CAT_FAT_FEMALE] = {
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_01, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_02, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_CATVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_BELT_01, 
        },
    },
    [CharacterConstants.BIRDSHARK_MALE] = {
        tTopAccessories = { 
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_01, 
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_02, 
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_02,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.MALE_TOP_ACCESSORY_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_BIRDSHARKVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.MALE_BOTTOM_ACCESSORY_BELT_01, 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_TOURISTSHORTS_01, 
        },
    },
    [CharacterConstants.BIRDSHARK_FEMALE] = {
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_BANDOLIER_02, 
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_02,
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.FEMALE_TOP_ACCESSORY_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_BIRDSHARKVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01, 
        },
    },
    [CharacterConstants.BIRDSHARK_FAT_MALE] = {
        tTopAccessories = { 
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_01, 
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_02,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_04,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_BIRDSHARKVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01,
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_BELT_01, 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_TOURISTSHORTS_01, 
        }, 
    },
    [CharacterConstants.BIRDSHARK_FAT_FEMALE] = { 
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_02, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_BIRDSHARKVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_BELT_01, 
        },
    },
    [CharacterConstants.CHICKEN_MALE] = {     
        tTopAccessories = { 
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_ROBESHIRT_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_05,
        }, 
        tBottomAccessories = { 
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_BELT_01,            
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },      
    },
    [CharacterConstants.CHICKEN_FEMALE] = { 
        tTopAccessories = { 
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_ROBESHIRT_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_TOURIST_SHIRT_05,
        }, 
        tBottomAccessories = { 
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_BELT_01,            
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    }, 
    [CharacterConstants.SHAMON_MALE] = { 
        tTopAccessories = { 
            CharacterConstants.SHAMON_TOP_ACCESSORY_VEST_01,
            CharacterConstants.SHAMON_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.SHAMON_TOP_ACCESSORY_SEXYSHIRT_01,
            CharacterConstants.MALE_TOP_ACCESSORY_BANDOLIER_01,
            CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_02,
            CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_03,
            CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_04,
            CharacterConstants.SHAMON_TOP_ACCESSORY_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_SHAMONVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.SHAMON_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.SHAMON_BOTTOM_ACCESSORY_BELT_01,         
        },
    },
    [CharacterConstants.MURDERFACE_MALE] = {    
        tTopAccessories = { 
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.TOBIAN_TOP_ACCESSORY_ROBESHIRT_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_BELT_01,            
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_LEGPOUCH_01,
            CharacterConstants.TOBIAN_BOTTOM_ACCESSORY_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.HUMAN_FAT_MALE] = {
        tTopAccessories = { 
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.MALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_01,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_BANDOLIER_02,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_02,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_03,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_04,
            CharacterConstants.MALE_TOP_ACCESSORY_FAT_TOURIST_SHIRT_05,
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_HUMANVISOR_01,
        }, 
        tBottomAccessories = { 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01,
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_BELT_01, 
            CharacterConstants.MALE_BOTTOM_ACCESSORY_FAT_TOURISTSHORTS_01,
        },
    },
    [CharacterConstants.HUMAN_FAT_FEMALE] = {
        tTopAccessories = { 
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_VEST_01_BEIGE,
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_01,
            CharacterConstants.FEMALE_TOP_ACCESSORY_FAT_BANDOLIER_02, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_LEFT_01, 
            CharacterConstants.TOP_ACCESSORY_GAUNTLET_RIGHT_01,
            CharacterConstants.TOP_ACCESSORY_HUMANVISOR_01,
        },
        tBottomAccessories = { 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_LEGPOUCH_01,
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_BELT_01, 
            CharacterConstants.FEMALE_BOTTOM_ACCESSORY_FAT_TOURISTSHORTS_01,
        },
    },
}
CharacterConstants.JOB_OUTFIT_TYPE=
--suit variations based on body type
{
    [CharacterConstants.DOCTOR_BASE_NORMAL] = { sModel = 'Doctor_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Scientist01' },
    [CharacterConstants.DOCTOR_BASE_FAT] = { sModel = 'Doctor_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Scientist01' },
    [CharacterConstants.SCIENTIST_BASE_NORMAL] = { sModel = 'Doctor_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Scientist01' },
    [CharacterConstants.SCIENTIST_BASE_FAT] = { sModel = 'Doctor_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Scientist01' },
    [CharacterConstants.BUILDER_BASE_NORMAL] = { sModel = 'Builder_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Builder01' },
    [CharacterConstants.BUILDER_BASE_FAT] = { sModel = 'Builder_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Builder01' },
    [CharacterConstants.BUILDER_TOBIAN_NO_HELMET] = { sModel = 'Builder_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Builder01' },
    [CharacterConstants.BUILDER_BASE_NORMAL_HOOF_BOOT] = { sModel = 'Builder_Suit03', sTexture = 'Characters/Citizen_Base/Textures/Builder01' },
    [CharacterConstants.TECHNICIAN_BASE_NORMAL] = { sModel = 'Tech_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.TECHNICIAN_BASE_FAT] = { sModel = 'Tech_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.TECHNICIAN_TOBIAN] = { sModel = 'Tech_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.JANITOR_TOBIAN] = { sModel = 'Tech_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.JANITOR_BASE_NORMAL] = { sModel = 'Tech_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.JANITOR_BASE_FAT] = { sModel = 'Tech_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.TRADER_TOBIAN] = { sModel = 'Tech_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.TRADER_BASE_NORMAL] = { sModel = 'Tech_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.TRADER_BASE_FAT] = { sModel = 'Tech_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Technician01' },
    [CharacterConstants.MINER_BASE_NORMAL] = { sModel = 'Miner_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Miner01' },
    [CharacterConstants.MINER_BASE_FAT] = { sModel = 'Miner_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Miner01' },
    [CharacterConstants.MINER_TOBIAN] = { sModel = 'Miner_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Miner01' },
    [CharacterConstants.MINER_BASE_NORMAL_HOOF_BOOT] = { sModel = 'Miner_Suit03', sTexture = 'Characters/Citizen_Base/Textures/Miner01' },
    [CharacterConstants.EMERGENCY_BASE_NORMAL] = {
        Level1 = { sModel = 'Emergency_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency01' },
        Level2 = { sModel = 'Emergency_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency02' },
        Level3 = { sModel = 'Emergency_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency03' },
    },
    [CharacterConstants.EMERGENCY_BASE_FAT] = {
        Level1 = { sModel = 'Emergency_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency01' },
        Level2 = { sModel = 'Emergency_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency02' },
        Level3 = { sModel = 'Emergency_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency03' },
    },
    [CharacterConstants.EMERGENCY_TOBIAN] = {
        Level1 = { sModel = 'Emergency_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency01' },
        Level2 = { sModel = 'Emergency_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency02' },
        Level3 = { sModel = 'Emergency_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Emergency03' },
    },
    [CharacterConstants.EMERGENCY_BASE_NORMAL_HOOF_BOOT] = {
        Level1 = { sModel = 'Emergency_Suit03', sTexture = 'Characters/Citizen_Base/Textures/Emergency01' },
        Level2 = { sModel = 'Emergency_Suit03', sTexture = 'Characters/Citizen_Base/Textures/Emergency02' },
        Level3 = { sModel = 'Emergency_Suit03', sTexture = 'Characters/Citizen_Base/Textures/Emergency03' },
    },
    [CharacterConstants.RAIDER_BASE_NORMAL] = {
        Level1 = { sModel = 'Raider_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
        Level2 = { sModel = 'Raider_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
        Level3 = { sModel = 'Raider_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
    },
    [CharacterConstants.RAIDER_BASE_FAT] = {
        Level1 = { sModel = 'Raider_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
        Level2 = { sModel = 'Raider_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
        Level3 = { sModel = 'Raider_FatSuit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
    },
    [CharacterConstants.RAIDER_TOBIAN_NO_HELMET] = {
        Level1 = { sModel = 'Raider_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
        Level2 = { sModel = 'Raider_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
        Level3 = { sModel = 'Raider_Suit02', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
    },
    [CharacterConstants.BARTENDER_BASE_NORMAL] = { sModel = 'Bartender_Suit02_M', sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_01", },
    [CharacterConstants.BARTENDER_BASE_FAT] = { sModel = 'Bartender_FatSuit02_M', sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_01", },
    [CharacterConstants.BARTENDER_BASE_NORMAL_FEMALE] = { sModel = 'Bartender_Suit02_F', sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_01", },
    [CharacterConstants.BARTENDER_BASE_FAT_FEMALE] = { sModel = 'Bartender_FatSuit02_F', sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_01", },
    [CharacterConstants.BARTENDER_TOBIAN] = { sModel = 'Bartender_Suit02', sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Male_01", },
    [CharacterConstants.BARTENDER_SHAMON] = { sModel = 'Bartender_Suit03', sTexture = "Characters/Citizen_Base/Textures/Tourist_Shirt_Female_01", },
}

CharacterConstants.JOB_HELMET_PREFIX = '_Character_Group_Group_Flipbook_Group_Helmet_FBGroup_Helmets_Head_Helmets_'
CharacterConstants.JOB_HELMET_TYPE=
{
    [CharacterConstants.BUILDER_BASE_HELMET] = { sModel = 'Builder_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Builder01' },
    [CharacterConstants.MINER_BASE_HELMET] = { sModel = 'Miner_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Miner01' },
    [CharacterConstants.MINER_TOBIAN_HELMET] = { sModel = 'Miner_TobianHelmet01', sTexture = 'Characters/Citizen_Base/Textures/Miner01' },
    [CharacterConstants.EMERGENCY_BASE_HELMET] = {
        Level1 = { sModel = 'Emergency_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Emergency01' },
        Level2 = { sModel = 'Emergency_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Emergency02' },
        Level3 = { sModel = 'Emergency_Helmet02', sTexture = 'Characters/Citizen_Base/Textures/Emergency03' },
    },
    [CharacterConstants.EMERGENCY_TOBIAN_HELMET] = {
        Level1 = { sModel = 'Emergency_TobianHelmet01', sTexture = 'Characters/Citizen_Base/Textures/Emergency01' },
        Level2 = { sModel = 'Emergency_TobianHelmet01', sTexture = 'Characters/Citizen_Base/Textures/Emergency02' },
        Level3 = { sModel = 'Emergency_TobianHelmet02', sTexture = 'Characters/Citizen_Base/Textures/Emergency03' },
    },
    [CharacterConstants.RAIDER_BASE_HELMET] = { sModel = 'Raider_Helmet01', sTexture = 'Characters/Citizen_Base/Textures/Raider01' },
}

function CharacterConstants.getDefaultJobOutfit(nJob,bFat)
    if nJob == CharacterConstants.BUILDER then
        return (bFat and CharacterConstants.BUILDER_BASE_FAT) or CharacterConstants.BUILDER_BASE_NORMAL
    elseif nJob == CharacterConstants.TECHNICIAN then
        return (bFat and CharacterConstants.TECHNICIAN_BASE_FAT) or CharacterConstants.TECHNICIAN_BASE_NORMAL
    elseif nJob == CharacterConstants.MINER then
        return (bFat and CharacterConstants.MINER_BASE_FAT) or CharacterConstants.MINER_BASE_NORMAL
    elseif nJob == CharacterConstants.EMERGENCY then
        return (bFat and CharacterConstants.EMERGENCY_BASE_FAT) or CharacterConstants.EMERGENCY_BASE_NORMAL
    elseif nJob == CharacterConstants.RAIDER then
        return (bFat and CharacterConstants.RAIDER_BASE_FAT) or CharacterConstants.RAIDER_BASE_NORMAL
    elseif nJob == CharacterConstants.BARTENDER then
        return (bFat and CharacterConstants.BARTENDER_BASE_FAT) or CharacterConstants.BARTENDER_BASE_NORMAL
    elseif nJob == CharacterConstants.BOTANIST then
        return CharacterConstants.BOTANIST_BASE_NORMAL
    elseif nJob == CharacterConstants.SCIENTIST then
        return (bFat and CharacterConstants.SCIENTIST_BASE_FAT) or CharacterConstants.SCIENTIST_BASE_NORMAL
    elseif nJob == CharacterConstants.DOCTOR then
        return (bFat and CharacterConstants.DOCTOR_BASE_FAT) or CharacterConstants.DOCTOR_BASE_NORMAL
    elseif nJob == CharacterConstants.JANITOR then
        return (bFat and CharacterConstants.JANITOR_BASE_FAT) or CharacterConstants.JANITOR_BASE_NORMAL
    elseif nJob == CharacterConstants.TRADER then
        return (bFat and CharacterConstants.TRADER_BASE_FAT) or CharacterConstants.TRADER_BASE_NORMAL
    else
        assert(false)
    end
end

return CharacterConstants
