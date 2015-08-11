-- NEEDS DEF FORMAT:
-- Needs: { NeedName=Score, ... }
-- ScoreMods:
--  Priority: set it for survival-level actions.
--  BaseScore: added to the resultant score from the needs-based calculation.
-- PersonalityMods:
--  nBravery={min,max}: characters with bravery outside this range will not take this action. Tests >min, <=max.
--  (similar for all personality traits w/ a score)
-- Prerequisites: { PrereqName=true/false, ... }
-- Satisfies: { PrereqName=true/false, ... }
-- Tags:
--  Job: gates to only allow the option for character of that job.
--  DestOwned: the target location must be on the character's team. If no target loc specified, assumes character loc.
--  DestSafe: like DestOwned, but for: not breached; not on fire; no hostiles; not an airlock. Uses character memory.
--      Special value: 'AllowAirlock' is like DestSafe=true, but also allows activity to occur in an airlock.        
-- nJobExperience: xp to grant after completing the task. Will be given to JobForXP or Job

local Character=require('CharacterConstants')

local tPriorities=
{
    NO_ACTIVITY = -1,
    NORMAL = 0,
    -- Tasks that are high priority and should be undertaken as soon as possible
    -- e.g. responding to a beacon
    SURVIVAL_LOW = 1,
    -- Other survival events that are more urgent than fire. Suffocation.
    SURVIVAL_NORMAL = 2,
    -- Do not interrupt. Character is being controlled.
    PUPPET = 3,
}

local tAdvertisedActivities=
{
    WanderAround = {
        Needs={ Amusement=2, },
        ClassPath='Utility.Tasks.WanderAround',
        Prerequisites={ Spacewalking=false, EmptyHandsOrCuffed=true },
        UIText='UITASK001TEXT',
        Tags={ DestOwned=true, },
    },
    WanderAroundSpace = { 
        ScoreMods={BaseScore=.002, } ,
        ClassPath='Utility.Tasks.WanderAround',
        Prerequisites={ Spacewalking=true, EmptyHands=true },
        UIText='UITASK001TEXT',        
    },
    Explore = { 
        Needs={ Duty=2, },
        ClassPath='Utility.Tasks.Patrol',
        Tags={WorkShift=true,},
        Prerequisites={ EmptyHands=true },
        UIText='UITASK002TEXT',
        bAllowHostilePathing=true,
    },
    SleepOnFloor = 
    {
        Needs={ Energy=2, },
        ScoreMods={ BaseScore=-2, },
        ClassPath='Utility.Tasks.SleepOnFloor',
        Prerequisites={ Spacewalking=false, EmptyHandsOrCuffed=true },
        UIText='UITASK004TEXT',
        bShowDuration=true,
        Tags={DestOwned=true,},
    },
    SleepInBed = {
        Needs={ Energy=80, Amusement=.00001, Social=0.00001 },
        ClassPath='Utility.Tasks.SleepInBed',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        Tags={WorkShift=false,DestOwned=true,DestSafe=true,},
        UIText='UITASK005TEXT',
        bShowDuration=true,
    },
    BuildInside = {
        Needs={ Duty=20, },
        ScoreMods={BaseScore=.25, } ,
        Tags={WorkShift=true,Job=Character.BUILDER,},
        ClassPath='Utility.Tasks.BuildBase',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK008TEXT',
        nJobExperience=2,
    },
    BuildSpace = {
        Needs={ Duty=20, },
        ScoreMods={BaseScore=.25, },
        Tags={WorkShift=true,Job=Character.BUILDER,},
        ClassPath='Utility.Tasks.BuildBase',
        Prerequisites={ WearingSuit=true, EmptyHands=true },
        UIText='UITASK006TEXT',
        nJobExperience=2,
        bTestMemoryBreach=false,
    },

    Chat = {
        Needs={ Social=9, },
        ClassPath='Utility.Tasks.Chat',
        Prerequisites={ Spacewalking=false, EmptyHandsOrCuffed=true },
        UIText='UITASK007TEXT',
    },
    ChatPartner = {
        Needs={ Social=9, },
        ScoreMods={BaseScore=10,},
        ClassPath='Utility.Tasks.ChatPartner',
        Prerequisites={ Spacewalking=false, EmptyHandsOrCuffed=true },
        UIText='UITASK007TEXT',
    },
	GetDrink = {
		Needs={ Amusement=7, Hunger=1, },
        ClassPath='Utility.Tasks.GetDrink',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK009TEXT',
	},

    BuildEnvObject = {
        Needs={ Duty=10, },
        ClassPath='Utility.Tasks.BuildEnvObject',
        Tags={WorkShift=true,Job=Character.BUILDER,},
        Prerequisites={ EmptyHands=true },
        UIText='UITASK010TEXT',
    },
    DestroyEnvObject = {
        Needs={ Duty=10, },
        ClassPath='Utility.Tasks.DestroyEnvObject',
        Tags={WorkShift=true,Job=Character.BUILDER,},
        Prerequisites={ EmptyHands=true },
        UIText='UITASK011TEXT',
    },
    TearDownEnvObjectForResearch = {
        Needs={ Duty=20, },
        ClassPath='Utility.Tasks.DestroyEnvObject',
        Tags={WorkShift=true,Job=Character.SCIENTIST,},
        Prerequisites={ EmptyHands=true },
        UIText='UITASK011TEXT',
    },
    MaintainEnvObject = {
        Needs={ Duty=8, },
        ClassPath='Utility.Tasks.MaintainEnvObject',
        Tags={WorkShift=true,DestOwned=true, Job=Character.TECHNICIAN,},
        Prerequisites={ EmptyHands=true },
        UIText='UITASK012TEXT',
        nJobExperience=20,
    },

    ERCircleBeaconInside={
        Needs={Duty=20, },
        ScoreMods={BaseScore=5,Priority=tPriorities.SURVIVAL_LOW },
        Tags={WorkShift=true, },
        Prerequisites={ EmptyHands=true },        
        ClassPath='Utility.Tasks.CircleBeacon',
        UIText='UITASK002TEXT',
    },
    ERCircleBeaconSpace={
        Needs={Duty=20, },
        ScoreMods={BaseScore=5,Priority=tPriorities.SURVIVAL_LOW  } ,
        Tags={WorkShift=true, },
        ClassPath='Utility.Tasks.CircleBeacon',
        Prerequisites={ EmptyHands=true },        
        UIText='UITASK013TEXT',
    },
    ERBeaconExplore={
        Needs={Duty=20, },
        ScoreMods={BaseScore=5,Priority=tPriorities.SURVIVAL_LOW },
        Tags={WorkShift=true, },
        ClassPath='Utility.Tasks.Explore',
        Prerequisites={ EmptyHands=true },        
        UIText='UITASK002TEXT',
        bAllowHostilePathing=true,
    },

    MineInside = {
        Needs={ Duty=20, },
        ScoreMods={BaseScore=.25, } ,
        Tags={WorkShift=true,Job=Character.MINER,},
        Prerequisites={ EmptyHands=true },        
        ClassPath='Utility.Tasks.Mine',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK014TEXT',
        nJobExperience=24,
    },
    MineSpace = {
        Needs={ Duty=15, },
        ScoreMods={BaseScore=.25, } ,
        Tags={WorkShift=true,Job=Character.MINER,},
        Prerequisites={ EmptyHands=true },        
        ClassPath='Utility.Tasks.Mine',
        UIText='UITASK015TEXT',
        nJobExperience=24,
        --Prerequisites={ Spacewalking=true, },
    },
    DropOffRocks = {
        Needs={ Duty=7, },
        ScoreMods={BaseScore=5, }, -- HACK: really want these cleaned up, but we don't want to overfill duty.
        ClassPath='Utility.Tasks.DropOffRocks',
        Tags={WorkShift=true,Job=Character.MINER, DestOwned=true},
        Prerequisites={ HeldItem='Rock' },
        UIText='UITASK016TEXT',
    },
    DropRocksOnFloor = {
        ClassPath='Utility.Tasks.DropEverything',
        Needs={ Duty=1, },
        Prerequisites={ HeldItem='Rock', Spacewalking=false,},        
        UIText='UITASK017TEXT',
    },

    -- Botany
    HarvestAndDeliverFood = {
        Needs={ Duty=7, },
        ClassPath='Utility.Tasks.HarvestAndDeliverFood',
        Tags={WorkShift=true,DestOwned=true,DestSafe=true,Job=Character.BOTANIST,},
        Prerequisites={ EmptyHands=true },        
        UIText='UITASK057TEXT',
    },

    MaintainPlants = {
        Needs={ Duty=5, },
        ClassPath='Utility.Tasks.MaintainPlants',
        Prerequisites={ EmptyHands=true },
        Tags={WorkShift=true,DestOwned=true,DestSafe=true,Job=Character.BOTANIST,},
        UIText='UITASK058TEXT',
        nJobExperience=20,
    },
	
	-- SCIENCE!
    ResearchInLab = {
        Needs={ Duty=5, },
        ClassPath='Utility.Tasks.ResearchInLab',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        Tags={
			WorkShift=true,
			DestOwned=true,
			DestSafe=true,
			Job=Character.SCIENTIST,
		},
        UIText='UITASK062TEXT',
    },
    --[[
    CollectResearchDatacube = {
        Needs={ Duty=10, },
        ClassPath='Utility.Tasks.CollectResearchDatacube',
        Tags={
			WorkShift=true,
			DestSafe=true,
            Job=Character.SCIENTIST,
        },
        Prerequisites={ EmptyHands=true, Spacewalking=false, },
        UIText='UITASK063TEXT',
    },
    ]]--
    DeliverResearchDatacube = {
        Needs={ Duty=20, },
        ClassPath='Utility.Tasks.DeliverResearchDatacube',
        Tags={
			WorkShift=true,
			DestOwned=true,
			DestSafe=true,
            Job=Character.SCIENTIST,
        },
        Prerequisites={ HeldItem='ResearchDatacube', Spacewalking=false, },
        UIText='UITASK063TEXT',
    },
    -- If there are no research desks, just put it, you know, wherever.
    PutResearchDatacubeWherever = {
        Needs={ Duty=7, },
        ClassPath='Utility.Tasks.DropEverything',
        Tags={
			WorkShift=true,
			DestOwned=true,
			DestSafe=true,
            Job=Character.SCIENTIST,
        },
        Prerequisites={ HeldItem='ResearchDatacube', Spacewalking=false, HeldItemInDanger='ResearchDatacube' },
        UIText='UITASK063TEXT',
    },

    -- Doctor
    BedHeal = {
        Needs={ Duty=16, },
        Tags={WorkShift=true,DestOwned=true, DestSafe=true,Job=Character.DOCTOR, },
        ClassPath='Utility.Tasks.BedHeal',
        Prerequisites={ EmptyHands=true,},
        UIText='UITASK066TEXT',
    },
    GetFieldScanned = {
        Needs={ Duty=3, Social=3 },
        ScoreMods={BaseScore=10,},
        Tags={ DestSafe=true, },
        ClassPath='Utility.Tasks.GetFieldScanned',
        Prerequisites={ },
        UIText='UITASK069TEXT',
    },
    FieldScanAndHeal = {
        -- Can get up to 4 Duty added to it based on disease severity and time since checkup.
        Needs={ Duty=4, },
        Tags={WorkShift=true,DestOwned=true, DestSafe=true,Job=Character.DOCTOR,},
        ClassPath='Utility.Tasks.FieldScanAndHeal',
        Prerequisites={ EmptyHands=true,},
        UIText='UITASK067TEXT',
    },
    CheckInToHospital={
        Needs={ },
        Tags={DestOwned=true, DestSafe=true,},
        ClassPath='Utility.Tasks.CheckInToHospital',
        Prerequisites={ EmptyHands=true,},
        UIText='UITASK068TEXT',
        --ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=0.01},
    },
    DropOffCorpse = {
        Needs={ Duty=2, }, --6
        ScoreMods={},
        ClassPath='Utility.Tasks.DropOffCorpse',
        Tags={WorkShift=true,Job=Character.JANITOR,DestOwned=true,},
        Prerequisites={ HeldItem='Corpse' },
        UIText='UITASK071TEXT',
    },
    
    -- Emergency/security
    Patrol = { 
        Needs={ Duty=2, },
        ClassPath='Utility.Tasks.Patrol',
        Tags={WorkShift=true,DestOwned=true,Job=Character.EMERGENCY,},
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK003TEXT',
    },
    Cuff = { 
        Needs={ Duty=10, },
        ClassPath='Utility.Tasks.Cuff',
        Tags={WorkShift=true,Job=Character.EMERGENCY,},
        Prerequisites={ EmptyHands=true },
        --UIText='UITASK003TEXT',
    },

    -- Bartender
    OpenPub = {
		Needs={ Duty=8, },
        Tags={WorkShift=true,DestOwned=true, DestSafe=true,Job=Character.BARTENDER,},
        ClassPath='Utility.Tasks.MaintainPub',
        Prerequisites={ EmptyHands=true,},
        UIText='UITASK065TEXT',
	},
    MaintainPub = {
		Needs={ Duty=1, },
        Tags={WorkShift=true,DestOwned=true,DestSafe=true,Job=Character.BARTENDER,},
        ClassPath='Utility.Tasks.MaintainPub',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK064TEXT',
	},
    ServeDrink = {
		Needs={ Duty=4, Social=2, Amusement=1 },
        Tags={WorkShift=true,DestSafe=true,Job=Character.BARTENDER,},
        ClassPath='Utility.Tasks.ServeDrink',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK040TEXT',
        nJobExperience=15,
	},
    ServeFoodAtTable = {
		Needs={ Duty=6, },
        Tags={WorkShift=true,DestSafe=true,Job=Character.BARTENDER,},
        ClassPath='Utility.Tasks.ServeFoodAtTable',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK054TEXT',
        nJobExperience=30,
	},

    EatAtFoodReplicator = {
        Needs={ Hunger=10, },
        ClassPath='Utility.Tasks.EatAtFoodReplicator',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK055TEXT',
        bShowDuration=true,
        Tags={
            DestOwned=true,
            DestSafe=true,
        },
    },
    EatPlant = {
        Needs={ Hunger=15, },
        ClassPath='Utility.Tasks.EatPlant',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK052TEXT',
        bShowDuration=true,
        Tags={
            DestOwned=true,
            DestSafe=true,
        },
    },
    EatAtTable = {
        Needs={ Hunger=25, Amusement=2 },
        ClassPath='Utility.Tasks.EatAtTable',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK056TEXT',
        bShowDuration=true,
        Tags={DestSafe=true,},
    },
    Starve = {
        Needs={ },
        ClassPath='Utility.Tasks.SleepOnFloor',
        Prerequisites={ EmptyHandsOrCuffed=true },
        UIText='UITASK060TEXT',
        bShowDuration=true,
        Tags={DestSafe=true,},
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=0.01},
    },

    VoluntarilyWalkToBrig={
        ScoreMods={BaseScore=40, Priority=tPriorities.SURVIVAL_LOW },
        Tags={ NonThreatening=true, },
        ClassPath='Utility.Tasks.WalkTo',
        Prerequisites={ },        
        UIText='UITASK075TEXT',
    },
    VoluntarilyGetCuffed={
        ScoreMods={BaseScore=39,Priority=tPriorities.SURVIVAL_LOW },
        Tags={ NonThreatening=true, },
        ClassPath='Utility.Tasks.Breathe',
        Prerequisites={ },        
        UIText='UITASK078TEXT',
    },
    ----------------------------------------------------
    --HOBBIES
    ----------------------------------------------------
    WorkOutNoGym = {
        Needs={ Amusement=3, },
        ClassPath='Utility.Tasks.WorkOut',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK034TEXT',
        Tags={
            DestOwned=true,
		    DestSafe=true,
        },
    },
    WorkOutInGym = {
        Needs={ Amusement=6, },
        ClassPath='Utility.Tasks.WorkOutInGym',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK034TEXT',
        Tags={
            DestOwned=true,
		    DestSafe=true,
        },
    },
    LiftAtWeightBench = {
        Needs={ Amusement=7, },
        ClassPath='Utility.Tasks.LiftAtWeightBench',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK059TEXT',
        Tags={
            DestOwned=true,
            DestSafe=true,
        },
    },
    PlayGameSystem = {
        Needs={ Amusement=6, },
        ClassPath='Utility.Tasks.PlayGameSystem',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK035TEXT',
        Tags={
            DestOwned=true,
		    DestSafe=true,
        },
    },
    ListenToJukebox = {
        Needs={ Amusement=7, },
        ClassPath='Utility.Tasks.ListenToJukebox',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='JUKEX004TEXT',
        Tags={
            DestOwned=true,
            DestSafe=true,
        },
    },

    ------------------------------------------------------------------
    -- SURVIVAL
    ------------------------------------------------------------------
    
    FleeEmergencyAlarm = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=100 },
        ClassPath='Utility.Tasks.RunTo',
        Prerequisites={ },
        UIText='UITASK026TEXT',
    },
    FleeTemperTantrum = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_LOW, BaseScore=1 },
        ClassPath='Utility.Tasks.RunTo',
        Prerequisites={ },
        UIText='UITASK026TEXT',
    },
    -- FIRE. Score range 1-10.
    ExtinguishFireWithTool = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=8, } ,
        PersonalityMods={ nBravery={.05,1} },
        
        ClassPath='Utility.Tasks.ExtinguishFireWithTool',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK018TEXT',
        nJobExperience=20,
        JobForXP=Character.EMERGENCY,
        Tags={DestOwned=true,},
    },
    ExtinguishFireBareHanded = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=6, } ,
        PersonalityMods={ nBravery={.15,1} },
        ClassPath='Utility.Tasks.ExtinguishFireBareHanded',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK019TEXT',
        nJobExperience=20,
        JobForXP=Character.EMERGENCY,
        Tags={DestOwned=true,},
    },
    FireFleeArea = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=4, } ,
        PersonalityMods={ nBravery={.2,1} },
        ClassPath='Utility.Tasks.RunTo',
        Prerequisites={ },
        UIText='UITASK020TEXT',
    },
    PanicFire = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=2, } ,
        PersonalityMods={ nBravery={0,.4} },
        ClassPath='Utility.Tasks.PanicFire',
        Prerequisites={ },
        UIText='UITASK021TEXT',
    },
    -- Manual/forced.
    PanicOnFire = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL,} ,
        ClassPath='Utility.Tasks.PanicOnFire',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK022TEXT',
    },

    -- COMBAT. Score range 100-120.
    RangedAttackThreat = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=120, } ,
        PersonalityMods={ nBravery={.1,1} },
        Needs={ Duty=10, },
        Tags={ HighDistPenalty=true, },
        ClassPath='Utility.Tasks.AttackEnemy',
        Prerequisites={ EmptyHands=true, },
        UIText='UITASK023TEXT',
        bAllowHostilePathing=true,
    },
    AttackThreatFallback = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=99, } ,
        Needs={ },
        Tags={ HighDistPenalty=true, },
        ClassPath='Utility.Tasks.AttackEnemy',
        Prerequisites={ EmptyHands=true, },
        UIText='UITASK024TEXT',
        bAllowHostilePathing=true,
    },
    AttackThreat = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=110, } ,
        PersonalityMods={ nBravery={.8,1} },
        Needs={ Duty=5, },
        Tags={ HighDistPenalty=true, },
        ClassPath='Utility.Tasks.AttackEnemy',
        Prerequisites={ EmptyHands=true, },
        UIText='UITASK024TEXT',
        bAllowHostilePathing=true,
    },
    Brawl = {
        ScoreMods={Priority=tPriorities.SURVIVAL_LOW, BaseScore=60, },
        ClassPath='Utility.Tasks.AttackEnemy',
        Prerequisites={ EmptyHands=true, },
        UIText='UITASK076TEXT',
    },
    FleeThreat = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=110, },
        PersonalityMods={ nBravery={.4,1} },
        ClassPath='Utility.Tasks.RunTo',
        Prerequisites={ EmptyHandsOrCuffed=true, },
        UIText='UITASK026TEXT',
    },
    PanicThreat = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=110 },
        PersonalityMods={ nBravery={0,.2} },
        ClassPath='Utility.Tasks.PanicFire',
        Prerequisites={ EmptyHands=true },        
        UIText='UITASK025TEXT',
    },

    OxygenFleeArea = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=200} ,
        ClassPath='Utility.Tasks.RunTo',
        UIText='UITASK027TEXT',
    },
    PanicOxygen = { 
        ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=1 } ,
        PersonalityMods={ nBravery={0,.4} },
        ClassPath='Utility.Tasks.PanicFire',
        Prerequisites={ EmptyHands=true },
        UIText='UITASK039TEXT',
    },
    -- Dawgness.
    IncapacitatedOnFloor = {
        ClassPath='Utility.Tasks.Incapacitated',
        UIText='UITASK070TEXT',
        ScoreMods={BaseScore=.002, 
            -- gets normal pri. see note in incapacitated.lua on getPriority
            --Priority=tPriorities.PUPPET
            } ,
        Tags={ NonThreatening=true, },
    },
    -- Rampage Tasks
    -- Tasks gated by being on a rampage.
    --
    ViolentRampageBreathe = { 
        ScoreMods={BaseScore=100, Priority=tPriorities.SURVIVAL_NORMAL, },
        Tags={ Status=Character.STATUS_RAMPAGE_VIOLENT, Cooldown=15, },
        ClassPath='Utility.Tasks.RampageTantrum',
        Prerequisites={ EmptyHands=true },
        --UIText='UITASK039TEXT',
    },
    ViolentRampagePatrol = { 
        ScoreMods={BaseScore=100, Priority=tPriorities.SURVIVAL_NORMAL, } ,
        Tags={ Status=Character.STATUS_RAMPAGE_VIOLENT, },
        ClassPath='Utility.Tasks.Patrol',
        Prerequisites={ EmptyHands=true },
        --UIText='UITASK039TEXT',
    },
    NonviolentRampageSabotage = { 
        ScoreMods={BaseScore=105, Priority=tPriorities.SURVIVAL_LOW, } ,
        Tags={ Status=Character.STATUS_RAMPAGE_NONVIOLENT, },
        ClassPath='Utility.Tasks.Sabotage',
        Prerequisites={ EmptyHands=true },
        --UIText='UITASK039TEXT',
    },
    
    -----------------------------------------------
    -- FALLBACKS; PREREQS
    -----------------------------------------------
    Breathe = { 
        ScoreMods={BaseScore=0.001} ,
        ClassPath='Utility.Tasks.Breathe',        
        UIText='UITASK029TEXT',
    },
    FallbackDropEverything = { 
        ScoreMods={BaseScore=0.002},
        ClassPath='Utility.Tasks.DropEverything',
        UIText='UITASK032TEXT',
    },
    -- Available to people in an airlock with nothing better to do.
    GoOutsideStandalone = {
        ClassPath='Utility.Tasks.RunTo',
        UIText='UITASK036TEXT',
        ScoreMods={BaseScore=0.002},
    },
    -- Available to people without much to do inside, but who would still probably prefer not to suffocate.
    GoInsideStandalone = {
        ClassPath='Utility.Tasks.RunTo',
        ScoreMods={ BaseScore=.75, MinimumScore=.01, },
        Prerequisites={ Spacewalking=true, },
        UIText='UITASK030TEXT',
        --Satisfies={ Spacewalking=false, },
		--OverridePathTest=true,
        -- Why allow hostile pathing? because airlocks already have a team check in their gate function.
        -- So this is basically to allow raiders inside.
        -- Since the character is already in space, there's no way this makes them walk through hostile
        -- territory on the way inside.
        bAllowHostilePathing=true,
    },

    ----------------------------------------------------
    -- MONSTER-SPECIFIC
    ----------------------------------------------------
    MonsterPatrol = { 
        ScoreMods={BaseScore=1} ,
        ClassPath='Utility.Tasks.Patrol',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK031TEXT',
        bAllowHostilePathing=true,
    },
    MonsterAttackEquipment = {
        ScoreMods={BaseScore=2} ,
        --ScoreMods={Priority=tPriorities.SURVIVAL_NORMAL, BaseScore=101, } ,
        --Needs={ Duty=2, },
        ClassPath='Utility.Tasks.AttackEnemy',
        Prerequisites={ Spacewalking=false, EmptyHands=true },
        UIText='UITASK074TEXT',
        bAllowHostilePathing=true,
    },
    MonsterWander = {
        ScoreMods={BaseScore=.1},
        ClassPath='Utility.Tasks.WanderAround',
        Prerequisites={ },
        UIText='UITASK001TEXT',
        bAllowHostilePathing=true,
    },
    RaiderOxygenFleeArea = { 
        ScoreMods={ BaseScore=3 },
        ClassPath='Utility.Tasks.RunTo',
        UIText='UITASK027TEXT',
    },
    RaiderFleeThreat = { 
        ScoreMods={BaseScore=.2, },
        ClassPath='Utility.Tasks.RunTo',
        Prerequisites={  },
        UIText='UITASK026TEXT',
    },
    
    ----------------------------------------------------
    -- Prereq satisfiers.
    ----------------------------------------------------
    DropEverything = {
        ClassPath='Utility.Tasks.DropEverything',
        Needs={ Duty=-10, },
        ScoreMods={ BaseScore=-2, },
        Satisfies={ EmptyHands=true, },
        UIText='UITASK032TEXT',
	},
    PickUpFloorItem = {
        ClassPath='Utility.Tasks.PickUpFloorItem',
        Satisfies={ 
            --HeldItem='FILLED_IN_BY_PICKUP', 
        },
        UIText='UITASK033TEXT',
        Tags={DestOwned=true,},
        Prerequisites={ EmptyHands=true },        
	},
    PutOnSuit = {
        ClassPath='Utility.Tasks.PutOnSuit',
        Satisfies={ WearingSuit=true, },
        bTestMemoryBreach=false,
    },

    ----------------------------------------------------
    -- Stuff
    ----------------------------------------------------

    -- most of the scoring is done in Pickup's utilityOverrideFn.
    PickUpStuff = {
        ScoreMods={BaseScore=1 } ,
        ClassPath='Utility.Tasks.PickUpFloorItem',
        UIText='UITASK033TEXT',
        Tags={DestSafe='AllowAirlock',},
        Prerequisites={ EmptyHands=true },        
	},
    DisplayInventoryItem = {
        ScoreMods={ BaseScore=4 },
        ClassPath='Utility.Tasks.PutItemInTarget',
        UIText='UITASK081TEXT',
        Tags={DestSafe=true,DestOwned=true},
        Prerequisites={ Cuffed=false },
	},
    DropStuffOnFloor = {
        ScoreMods={} ,
        ClassPath='Utility.Tasks.DropEverything',
        UIText='UITASK080TEXT',
        Tags={DestSafe=true,},
        Prerequisites={ EmptyHands=true },        
	},
    IncinerateStuff = {
        ScoreMods={} ,
        ClassPath='Utility.Tasks.DropOffCorpse',
        UIText='UITASK079TEXT',
        Tags={DestSafe=true,},
        Prerequisites={ EmptyHands=true },
	},
    
    ----------------------------------------------------
    -- Manually created only.
    ----------------------------------------------------
    GoOutside = {
        ClassPath='Utility.Tasks.GoOutside',
        UIText='UITASK036TEXT',
        Satisfies={ WearingSuit=true, },
		-- small tweak downwards to approximate the distance cost of whatever's outside
        --ScoreMods={ BaseScore=-.05, },
        --Satisfies={ Spacewalking=true, },
		--OverridePathTest=true,
    },
    GoInside = {
        ClassPath='Utility.Tasks.GoInside',
        UIText='UITASK030TEXT',
        bAllowHostilePathing=true,        
    },
    VacuumPull = { 
        ScoreMods={Priority=tPriorities.PUPPET,} ,
        ClassPath='Utility.Tasks.VacuumPull',
        UIText='UITASK037TEXT',
    },
    Puppet = { 
        ScoreMods={Priority=tPriorities.PUPPET,} ,
        ClassPath='Utility.Tasks.Puppet',
        UIText='UITASK038TEXT',
    },

}

local OptionData=
{
    tAdvertisedActivities=tAdvertisedActivities,
    tPriorities=tPriorities,
}

return OptionData
