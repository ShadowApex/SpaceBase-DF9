local DFMath = require('DFCommon.Math')
local DFUtil = require('DFCommon.Util')
local GameRules = require('GameRules')
local Room = require('Room')
local Topics = require('Topics')
local Character = require('CharacterConstants')
local MiscUtil = require('MiscUtil')

local Log = {}

-- if false, citizens will log every last thought that pops into their heads
-- (useful for debugging)
Log.bFilter = true

-- debug logging for this system, should only be enabled for non-shipping builds!
Log.bLog = false

--
-- log types
--
Log.tTypes = {
	-- super general observations: life, the universe, and everything
	GENERIC={
		lineCodes={ 'SFGNRC001CITZ', 'SFGNRC002CITZ', 'SFGNRC003CITZ', 'SFGNRC004CITZ', 'SFGNRC005CITZ',
                    'SFGNRC006CITZ', 'SFGNRC007CITZ', 'SFGNRC008CITZ', 'SFGNRC009CITZ', 'SFGNRC010CITZ',
                    'SFGNRC011CITZ', 'SFGNRC012CITZ', 'SFGNRC013CITZ', 'SFGNRC014CITZ', 'SFGNRC015CITZ',
                    'SFGNRC016CITZ', 'SFGNRC017CITZ', 'SFGNRC018CITZ', 'SFGNRC019CITZ', 'SFGNRC020CITZ',
                    'SFGNRC021CITZ', 'SFGNRC022CITZ', 'SFGNRC023CITZ', 'SFGNRC024CITZ', 'SFGNRC025CITZ',
                    'SFGNRC026CITZ', 'SFGNRC027CITZ', 'SFGNRC028CITZ', 'SFGNRC029CITZ', 'SFGNRC030CITZ',
                    'SFGNRC031CITZ', 'SFGNRC032CITZ', 'SFGNRC033CITZ', 'SFGNRC034CITZ', 'SFGNRC035CITZ',
                    'SFGNRC036CITZ', 'SFGNRC037CITZ', 'SFGNRC038CITZ', 'SFGNRC039CITZ', 'SFGNRC040CITZ',
                    'SFGNRC041CITZ', 'SFGNRC042CITZ', 'SFGNRC043CITZ', 'SFGNRC044CITZ', 'SFGNRC045CITZ',
					'SFGNRC046CITZ', 'SFGNRC047CITZ', 'SFGNRC048CITZ', 'SFGNRC049CITZ', 'SFGNRC050CITZ',
					'SFGNRC051CITZ', 'SFGNRC052CITZ', 'SFGNRC053CITZ', 'SFGNRC054CITZ', 'SFGNRC055CITZ',
					'SFGNRC056CITZ', 'SFGNRC057CITZ', 'SFGNRC058CITZ', 'SFGNRC059CITZ', 'SFGNRC060CITZ',
                },
		priority=0,
	},
	-- like/dislike "interesting" (strong affinity*familiarity) person in room
	LIKE_NEARBY_PERSON={
		lineCodes={ 'SFNEAR001CITZ', 'SFNEAR005CITZ', 'SFNEAR006CITZ', 'SFNEAR007CITZ', 'SFNEAR013CITZ', 
					'SFNEAR014CITZ',
				},
		priority=0,
	},
	DISLIKE_NEARBY_PERSON={
		lineCodes={ 'SFNEAR002CITZ', 'SFNEAR008CITZ', 'SFNEAR009CITZ', 'SFNEAR010CITZ', 'SFNEAR011CITZ',
					'SFNEAR012CITZ', 
				},
		priority=0,
	},
	NEARBY_OBJECT={
		lineCodes={ 'SFNEAR003CITZ', 'SFNEAR016CITZ', 'SFNEAR017CITZ', 'SFNEAR004CITZ', 'SFNEAR015CITZ',
					'SFNEAR018CITZ',
				},
		priority=0,
	},
	-- became a citizen of the base
	JOINED={
		lineCodes={ 'SFSPWN001CITZ', 'SFSPWN002CITZ', 'SFSPWN003CITZ', 'SFSPWN004CITZ', 'SFSPWN005CITZ', 'SFSPWN006CITZ' },
		-- log type priority: can be positive, zero, or negative
		priority=3,
	},
    --raider enters your base
    ENEMY_JOINED={
		lineCodes={ 'SFSPWN007RAID', 'SFSPWN008RAID', 'SFSPWN009RAID', 'SFSPWN010RAID', 'SFSPWN011RAID', 'SFSPWN012RAID' },		
		priority=3,
	},
	-- did some useful work
	DUTY_GENERIC={},
	-- assigned a new duty
	DUTY_ASSIGNED={
		lineCodes={
			'SFDTAS006CITZ', 'SFDTAS007CITZ', 'SFDTAS008CITZ', 'SFDTAS009CITZ', 'SFDTAS010CITZ',
			'SFDTAS011CITZ', 'SFDTAS012CITZ', 'SFDTAS013CITZ', 'SFDTAS014CITZ', 'SFDTAS015CITZ',
			'SFDTAS016CITZ', 'SFDTAS017CITZ', 'SFDTAS018CITZ', 'SFDTAS019CITZ', 'SFDTAS020CITZ',
		},
		priority=2,
	},
	DUTY_UNEMPLOYED={
		lineCodes={ 'SFDTAS001CITZ', 'SFDTAS002CITZ', 'SFDTAS003CITZ', 'SFDTAS004CITZ', 'SFDTAS005CITZ' },
	},
	-- duty-specific
	DUTY_BUILD={
		lineCodes={ 'SFDTBD001CITZ', 'SFDTBD002CITZ', 'SFDTBD003CITZ','SFDTBD004CITZ','SFDTBD005CITZ',
					'SFDTBD006CITZ', 'SFDTBD007CITZ',
				},
	},
	DUTY_TECH={
		lineCodes={ 'SFDTTK001CITZ','SFDTTK002CITZ','SFDTTK003CITZ','SFDTTK004CITZ','SFDTTK005CITZ',
                    'SFDTTK007CITZ','SFDTTK008CITZ','SFDTTK009CITZ','SFDTTK010CITZ','SFDTTK011CITZ',
					'SFDTTK012CITZ',
				},
	},
	DUTY_MINE={
        lineCodes={ 'SFMINE001CITZ', 'SFMINE002CITZ', 'SFMINE003CITZ', 'SFMINE004CITZ', 'SFMINE005CITZ',
                    'SFMINE006CITZ', 'SFMINE007CITZ','SFMINE009CITZ','SFMINE010CITZ' },
    },
	DUTY_SECURITY_PATROL={
		lineCodes={ 'SFSECU010CITZ', 'SFSECU011CITZ', 'SFSECU012CITZ', 'SFSECU013CITZ', 'SFSECU014CITZ',
					'SFSECU015CITZ', 'SFSECU016CITZ', 'SFSECU017CITZ', 'SFSECU018CITZ', 'SFSECU019CITZ',
					'SFSECU020CITZ', 'SFSECU021CITZ', },
	},
	DUTY_SECURITY_START_EXPLORE={
		lineCodes={ 'SFSECU022CITZ', 'SFSECU023CITZ', 'SFSECU024CITZ', 'SFSECU025CITZ', 'SFSECU026CITZ',
		},
	},
	DUTY_SECURITY_EXPLORED_COMBAT={
		lineCodes={ 'SFSECU028CITZ', 'SFSECU030CITZ', 'SFSECU031CITZ', 'SFSECU032CITZ', 'SFSECU033CITZ',
		},
		priority=2,
	},
	DUTY_SECURITY_EXPLORED_NOCOMBAT={
		lineCodes={ 'SFSECU029CITZ', 'SFSECU034CITZ', 'SFSECU035CITZ', 'SFSECU036CITZ', 'SFSECU037CITZ',
		},
		priority=2,
	},
    DUTY_BOTANIST_MAINTAIN={
        lineCodes={ 'SFBOTN001CITZ','SFBOTN007CITZ','SFBOTN008CITZ','SFBOTN009CITZ','SFBOTN010CITZ',
                    'SFBOTN011CITZ','SFBOTN012CITZ','SFBOTN013CITZ','SFBOTN014CITZ','SFBOTN018CITZ',
					'SFBOTN019CITZ','SFBOTN020CITZ',
				},
    },
    DUTY_BOTANIST_HARVEST={
        lineCodes={ 'SFBOTN015CITZ','SFBOTN016CITZ','SFBOTN017CITZ',},
    },
	DUTY_SERVE_DRINK={
		lineCodes={ 'SFDRNK009CITZ', 'SFBART001CITZ', 'SFBART002CITZ', 'SFBART003CITZ', 'SFBART004CITZ',
                    'SFBART005CITZ', 'SFBART006CITZ', },
	},
    DUTY_SCIENTIST_RESEARCH_FIRE={
        lineCodes={ 'SFRSCH015CITZ', 'SFRSCH016CITZ', 'SFRSCH017CITZ', 'SFRSCH018CITZ', },
    },
	DUTY_SCIENTIST_DO_RESEARCH={
        lineCodes={ 'SFRSCH001CITZ', 'SFRSCH002CITZ', 'SFRSCH003CITZ', 'SFRSCH004CITZ', 'SFRSCH011CITZ',
                    'SFRSCH012CITZ', 'SFRSCH013CITZ', 'SFRSCH014CITZ', 'SFRSCH019CITZ', },
    },
	DUTY_SCIENTIST_COLLECT_RESEARCH={
		lineCodes={ 'SFRSCH005CITZ', 'SFRSCH007CITZ', 'SFRSCH008CITZ', }
	},
	DUTY_SCIENTIST_DELIVER_RESEARCH={
		lineCodes={ 'SFRSCH006CITZ', 'SFRSCH009CITZ', 'SFRSCH010CITZ', }
	},
    EXPLORED_ROOM={
        lineCodes={ 'SFSECU001CITZ', 'SFSECU002CITZ', 'SFSECU003CITZ', 'SFSECU004CITZ', 'SFSECU005CITZ',
                    'SFSECU006CITZ', 'SFSECU007CITZ','SFSECU008CITZ','SFSECU009CITZ' },
    },
	-- doctor duty
	DUTY_DOCTOR_REFINE_CORPSE_FRIENDLY={
		lineCodes={ 'SFDOCT005CITZ', 'SFDOCT006CITZ', 'SFDOCT008CITZ', 'SFDOCT017CITZ', 'SFDOCT018CITZ',
					'SFDOCT019CITZ', 'SFDOCT020CITZ', 'SFDOCT064CITZ', 
				},
		priority=2,
	},
	DUTY_DOCTOR_REFINE_CORPSE_MONSTER={
		lineCodes={ 'SFDOCT027CITZ', 'SFDOCT028CITZ', 'SFDOCT029CITZ', },
	},
	DUTY_DOCTOR_REFINE_CORPSE_RAIDER={
		lineCodes={ 'SFDOCT030CITZ', 'SFDOCT031CITZ', 'SFDOCT032CITZ', 'SFDOCT033CITZ', },
	},
	DUTY_DOCTOR_SCAN_HEALTHY={
		lineCodes={ 'SFDOCT026CITZ', 'SFDOCT034CITZ', 'SFDOCT035CITZ', 'SFDOCT062CITZ',
					'SFDOCT063CITZ',
				},
	},
	DUTY_DOCTOR_HEAL_ILLNESS={
		lineCodes={ 'SFDOCT001CITZ', 'SFDOCT011CITZ', 'SFDOCT014CITZ', 'SFDOCT015CITZ', },
	},
	DUTY_DOCTOR_HEAL_BROKEN_LEG={
		lineCodes={ 'SFDOCT002CITZ', 'SFDOCT009CITZ', 'SFDOCT012CITZ', 'SFDOCT013CITZ', },
	},
	DUTY_DOCTOR_HEAL_HP_MAJOR={
		lineCodes={ 'SFDOCT009CITZ', 'SFDOCT012CITZ', 'SFDOCT013CITZ', },
	},
	DUTY_DOCTOR_HEAL_HP_MINOR={
		lineCodes={ 'SFDOCT061CITZ', 'SFDOCT060CITZ', },
	},
	DUTY_DOCTOR_DIAGNOSE_ILLNESS={
		lineCodes={ 'SFDOCT003CITZ', 'SFDOCT007CITZ', 'SFDOCT010CITZ', 'SFDOCT016CITZ', },
		priority=2,
	},
	-- citizen illness/injury
	HEALTH_CITIZEN_SCAN={
		lineCodes={ 'SFDOCT021CITZ', 'SFDOCT036CITZ', 'SFDOCT037CITZ', 'SFDOCT038CITZ', 'SFDOCT039CITZ',
					'SFDOCT040CITZ', 'SFDOCT041CITZ',
				},
	},
	HEALTH_CITIZEN_GETTING_ILL={
		lineCodes={ 'SFDOCT022CITZ', 'SFDOCT042CITZ', 'SFDOCT043CITZ', 'SFDOCT044CITZ', 'SFDOCT054CITZ',
					'SFDOCT055CITZ',
				},
		priority=2,
	},
	HEALTH_CITIZEN_DIAGNOSED={
		lineCodes={ 'SFDOCT023CITZ', 'SFDOCT047CITZ', 'SFDOCT051CITZ',
				},
		priority=2,
	},
	HEALTH_CITIZEN_INCAPACITATED_ILLNESS={
		lineCodes={ 'SFDOCT024CITZ', 'SFDOCT048CITZ',
				},
		priority=3,
	},
	HEALTH_CITIZEN_INCAPACITATED_INJURY={
		lineCodes={ 'SFDOCT025CITZ', 'SFDOCT049CITZ', 'SFDOCT050CITZ',
				},
		priority=3,
	},
	HEALTH_CITIZEN_HEAL_ILLNESS={
		lineCodes={ 'SFDOCT045CITZ', 'SFDOCT046CITZ', 'SFDOCT052CITZ', 'SFDOCT053CITZ',
				},
		priority=3,
	},
	HEALTH_CITIZEN_HOSPITAL_CHECKIN={
		lineCodes={ 'SFDOCT056CITZ', 'SFDOCT057CITZ', 'SFDOCT058CITZ', 'SFDOCT059CITZ',
				},
		priority=2,
	},
	-- chatting
	CHAT_INTRODUCE={
		lineCodes={ 'SFCHAT001CITZ', 'SFCHAT002CITZ', 'SFCHAT003CITZ', 'SFCHAT004CITZ' },
		priority=3,
	},
	CHAT_GOOD_GENERIC={
		lineCodes={ 'SFCHAT005CITZ', 'SFCHAT006CITZ', 'SFCHAT007CITZ', 'SFCHAT008CITZ' },
	},
	CHAT_BAD_GENERIC={
		lineCodes={ 'SFCHAT009CITZ', 'SFCHAT010CITZ', 'SFCHAT011CITZ', 'SFCHAT012CITZ', 'SFCHAT020CITZ',
					'SFCHAT021CITZ',
				},
	},
	CHAT_CHEER_UP={
		lineCodes={ 'SFCHAT013CITZ', 'SFCHAT014CITZ', 'SFCHAT015CITZ', 'SFCHAT016CITZ', 'SFCHAT017CITZ', 'SFCHAT018CITZ' },
		priority=2,
	},
	-- trading
	CHAT_TRADE={
		lineCodes={ 'SFCHAT019CITZ', 'SFTRAD007CITZ', 'SFTRAD008CITZ', 'SFTRAD009CITZ',
                    'SFTRAD010CITZ', 'SFTRAD011CITZ', 'SFTRAD012CITZ' },
		priority=2,
	},
	PICKUP_ITEM={
		lineCodes={ 'SFTRAD001CITZ' },
		priority=2,
	},
	-- death-related
	-- logging about a (non-self) citizen who died
	DEATH_REACT_CITIZEN={
		lineCodes={ 'SFDTHG002CITZ', 'SFDTHG003CITZ', 'SFDTHG004CITZ', 'SFDTHG018CITZ', },
		priority=4,
	},
    -- reaction of enemy death
    DEATH_REACT_ENEMY={
		lineCodes={ 'SFDTHG015CITZ', 'SFDTHG016CITZ', 'SFDTHG017CITZ', },
		priority=4,
    },
    -- friend who died :[
	DEATH_REACT_FRIEND={
		lineCodes={ 'SFDTHG005CITZ', 'SFDTHG006CITZ', 'SFDTHG007CITZ', 'SFDTHG019CITZ', },
		priority=4,
	},
    --raider reaction to citizen death
    DEATH_REACT_RAIDER_TO_CITZ={
		lineCodes={ 'SFDTHG008RAID','SFDTHG009RAID','SFDTHG010RAID', },
		priority=4,
    },    
    -- raider reaction to raider death
    DEATH_REACT_RAIDER_TO_RAIDER={
		lineCodes={ 'SFDTHG011RAID','SFDTHG012RAID','SFDTHG013RAID','SFDTHG014RAID', },
		priority=4,
    },
    ENTER_BRAWL={
        lineCodes={ 'SFCOMB030CITZ', 'SFCOMB031CITZ', 'SFCOMB032CITZ', 'SFCOMB033CITZ', 'SFCOMB034CITZ',
					'SFCOMB035CITZ', 'SFCOMB036CITZ',
				},
		priority=2,
    },
	ENTER_COMBAT_MELEE={
		lineCodes={ 'SFCOMB021CITZ', 'SFCOMB022CITZ', 'SFCOMB023CITZ'},
		priority=2,
	},
	ENTER_COMBAT_RANGED={
		lineCodes={ 'SFCOMB018CITZ', 'SFCOMB019CITZ', 'SFCOMB020CITZ', 'SFCOMB027CITZ'},
		priority=2,
	},
	ENTER_COMBAT_RAIDER={
		lineCodes={ 'SFCOMB024RAID', 'SFCOMB025RAID', 'SFCOMB026RAID'},
		priority=2,
	},
	RAIDER_ATTACK_DOOR={
		lineCodes={ 'SFCOMB028RAID', 'SFCOMB029RAID' },
	},
	KILLED_A_THING_MELEE={
		lineCodes={ 'SFCOMB003CITZ', 'SFCOMB007CITZ'},
		priority=2,
	},
	KILLED_A_THING_RANGED={
		lineCodes={ 'SFCOMB004CITZ','SFCOMB014CITZ','SFCOMB017CITZ' },
		priority=2,
	},
	ER_KILLED_A_THING_MELEE={
		lineCodes={ 'SFCOMB001CITZ','SFCOMB013CITZ' },
		priority=2,
	},
	ER_KILLED_A_THING_RANGED={
		lineCodes={ 'SFCOMB002CITZ','SFCOMB008CITZ','SFCOMB012CITZ' },
		priority=2,
	},
	RAIDER_KILLED_A_THING_MELEE={
		lineCodes={ 'SFCOMB005RAID','SFCOMB009RAID', 'SFCOMB010RAID', 'SFCOMB011RAID' },
		priority=2,
	},
	RAIDER_KILLED_A_THING_RANGED={
		lineCodes={ 'SFCOMB006RAID', 'SFCOMB009RAID', 'SFCOMB010RAID', 'SFCOMB011RAID','SFCOMB015RAID','SFCOMB016RAID' },
		priority=2,
	},
    CAUGHT_FIRE={
        lineCodes={ 'SFFIRE001CITZ', 'SFFIRE003CITZ','SFFIRE005CITZ','SFFIRE006CITZ','SFFIRE007CITZ',},
		priority=3,
    },
    CAUGHT_FIRE_MANY={ --caught fire more than once
        lineCodes={ 'SFFIRE002CITZ', 'SFFIRE004CITZ', 'SFFIRE001CITZ', 'SFFIRE003CITZ', 'SFFIRE005CITZ',
                    'SFFIRE006CITZ', 'SFFIRE007CITZ', 'SFFIRE008CITZ', 'SFFIRE009CITZ'
                },
		priority=3,
    },
	-- speaker is dying
	DEATH_GENERIC={},
	DEATH_FIRE={},
    DEATH_CHESTBURST={ 
        lineCodes={ 'SFPARA010CITZ','SFPARA011CITZ','SFPARA012CITZ','SFPARA013CITZ','SFPARA014CITZ',
                    'SFPARA015CITZ','SFPARA016CITZ','SFPARA017CITZ','SFPARA018CITZ', },
        priority=4,
    },
	DEATH_SUFFOCATION={
        lineCodes={'OXYGEN001CITZ','OXYGEN008CITZ','OXYGEN009CITZ','OXYGEN010CITZ','OXYGEN011CITZ',
                   'OXYGEN012CITZ','OXYGEN013CITZ','OXYGEN024CITZ','OXYGEN025CITZ','OXYGEN027CITZ'},
        priority=4,
    },
	DEATH_STARVATION={
        lineCodes={'SFEATS039CITZ', 'SFEATS040CITZ', 'SFEATS041CITZ',},
        priority=4,
    },
	-- witnessing / hearing about a disaster
	DISASTER_FIRE={
		lineCodes={'SFDISA012CITZ', 'SFDISA013CITZ', 'SFDISA014CITZ', 'SFDISA015CITZ', 'SFDISA016CITZ',
				   'SFDISA017CITZ', 'SFDISA018CITZ', 'SFDISA019CITZ', 'SFDISA020CITZ',
			   },
		priority=3,
	},
	DISASTER_MONSTER={},
	DISASTER_RAIDER={},
	DISASTER_BREACH={
		lineCodes={'SFDISA003CITZ', 'SFDISA004CITZ', 'SFDISA005CITZ', 'SFDISA006CITZ', 'SFDISA007CITZ',
					 'SFDISA009CITZ', 'SFDISA010CITZ', 'SFDISA011CITZ',
				 },
		priority=3,
	},
    -- anger events
    RAMPAGE_START={
        lineCodes={'SFRAMP003CITZ', 'SFRAMP005CITZ', 'SFRAMP006CITZ', 'SFRAMP007CITZ', 'SFRAMP008CITZ',
				 },
		priority=3,
    },
    TANTRUM_START={
        lineCodes={'SFRAMP001CITZ', 'SFRAMP002CITZ', 'SFRAMP004CITZ', 'SFRAMP007CITZ', 'SFRAMP009CITZ',
				 },
		priority=3,
    },
    RAMPAGE_NEARBY={
        lineCodes={'SFRAMP010CITZ', 'SFRAMP011CITZ', 'SFRAMP012CITZ', 'SFRAMP013CITZ',
				 },
		priority=3,
    },
    TANTRUM_NEARBY={
        lineCodes={'SFDISA021CITZ', 'SFDISA022CITZ', 'SFDISA023CITZ', 'SFDISA024CITZ',
				 },
		priority=3,
    },
	BRIG_ASSIGN_INCAPACITATED={
		lineCodes={'SFRAMP017CITZ', 'SFRAMP019CITZ', 'SFRAMP020CITZ', 'SFRAMP021CITZ',
				 },
		priority=2,
	},
	BRIG_ASSIGN_NOT_INCAPACITATED={
		lineCodes={'SFRAMP014CITZ', 'SFRAMP015CITZ', 'SFRAMP016CITZ', 'SFRAMP018CITZ',
				 },
		priority=2,
	},
	BRIG_ESCAPE={
		lineCodes={'SFRAMP022CITZ', 'SFRAMP023CITZ', 'SFRAMP024CITZ',},
		priority=2,
	},
	-- slept on floor / in bed
	SLEEP_FLOOR={
		lineCodes={ 'SFSLEP009CITZ', 'SFSLEP010CITZ', 'SFSLEP011CITZ', 'SFSLEP013CITZ', 'SFSLEP012CITZ',
                    'SFSLEP014CITZ', 'SFSLEP015CITZ', 'SFSLEP016CITZ', 'SFSLEP018CITZ', 'SFSLEP022CITZ',
                    'SFSLEP023CITZ', 'SFSLEP024CITZ',
                },
		priority=3,
	},
	SLEEP_BED_OWNED={
		-- includes "generic" slept in bed
		lineCodes={ 'SFSLEP009CITZ','SFSLEP010CITZ','SFSLEP011CITZ','SFSLEP017CITZ','SFSLEP018CITZ',
                    'SFSLEP019CITZ','SFSLEP020CITZ','SFSLEP021CITZ',
					'SFSLEP025CITZ','SFSLEP029CITZ','SFSLEP030CITZ',
				},
		priority=2,
	},
	SLEEP_BED_UNOWNED={
		-- includes "generic" slept in bed
		lineCodes={ 'SFSLEP009CITZ','SFSLEP010CITZ','SFSLEP011CITZ','SFSLEP017CITZ','SFSLEP018CITZ',
                    'SFSLEP019CITZ','SFSLEP020CITZ','SFSLEP021CITZ',
					'SFSLEP026CITZ','SFSLEP027CITZ','SFSLEP028CITZ',
				},
		priority=3,
	},
    EAT_REPLICATOR={
        lineCodes={ 'SFEATS001CITZ','SFEATS002CITZ','SFEATS003CITZ','SFEATS004CITZ','SFEATS005CITZ',
                    'SFEATS006CITZ','SFEATS007CITZ','SFEATS008CITZ','SFEATS009CITZ','SFEATS010CITZ',
                    'SFEATS036CITZ','SFEATS046CITZ','SFEATS047CITZ',},
    },
    ENEMY_EAT_REPLICATOR={
        lineCodes={ 'SFEATS011RAID','SFEATS012RAID','SFEATS013RAID','SFEATS014RAID','SFEATS015RAID','SFEATS036CITZ',},
    },
    EAT_RAW_FOOD={
        lineCodes={ 'SFEATS016CITZ','SFEATS017CITZ','SFEATS018CITZ','SFEATS019CITZ','SFEATS020CITZ',
                    'SFEATS021CITZ','SFEATS022CITZ',},
    },
    ENEMY_EAT_RAW_FOOD={
        lineCodes={ 'SFEATS023RAID','SFEATS024RAID','SFEATS025RAID','SFEATS026RAID',},
    },
    EAT_COOKED_MEAL_GOOD={
        lineCodes={ 'SFEATS027CITZ', 'SFEATS028CITZ', 'SFEATS029CITZ', 'SFEATS031CITZ', 'SFEATS042CITZ', },
        priority=2,
	},
    EAT_COOKED_MEAL_BAD={
        lineCodes={ 'SFEATS030CITZ', 'SFEATS032CITZ', 'SFEATS033CITZ', 'SFEATS034CITZ', 'SFEATS035CITZ' },
        priority=2,
    },
	EAT_COOKED_MEAL_FAVORITE={
		lineCodes={ 'SFEATS043CITZ' },
        priority=3,
    },
	-- drinking
	DRINK_GOOD_MORALE = {
		lineCodes={'SFDRNK001CITZ', 'SFDRNK005CITZ', 'SFDRNK008CITZ', 'SFDRNK010CITZ', 'SFDRNK011CITZ', },
	},
	DRINK_BAD_MORALE = {
		lineCodes={'SFDRNK003CITZ', 'SFDRNK006CITZ', 'SFDRNK007CITZ', 'SFDRNK012CITZ', 'SFDRNK013CITZ'},
	},
	-- general good/bad morale cases
	MORALE_GENERIC_GOOD={},
	MORALE_GENERIC_BAD={},
    MORALE_HIGH_OXYGEN={
        lineCodes={ 'OXYGEN003CITZ', 'OXYGEN018CITZ', 'OXYGEN019CITZ', 'OXYGEN021CITZ', 'OXYGEN022CITZ',
                    'OXYGEN023CITZ','OXYGEN026CITZ','OXYGEN028CITZ','OXYGEN029CITZ'
                },
        priority=3,
    },
	-- morale lower due to basic needs not being met
	MORALE_LOW_DUTY={
		lineCodes={ 'SFNEED025CITZ', 'SFNEED026CITZ', 'SFNEED027CITZ', 'SFNEED055CITZ', 'SFNEED056CITZ',
                    'SFNEED057CITZ', 'SFNEED058CITZ', 'SFNEED059CITZ', 'SFNEED060CITZ', 'SFNEED061CITZ',
                    'SFNEED062CITZ', 'SFNEED063CITZ', 'SFNEED064CITZ',
                },
	},
	MORALE_LOW_SOCIAL={
		lineCodes={ 'SFNEED028CITZ', 'SFNEED029CITZ', 'SFNEED030CITZ', 'SFNEED072CITZ', },
	},
	MORALE_LOW_AMUSEMENT={
		lineCodes={ 'SFNEED031CITZ', 'SFNEED032CITZ', 'SFNEED033CITZ' },
	},
	MORALE_LOW_ENERGY={
		lineCodes={ 'SFNEED034CITZ', 'SFNEED035CITZ', 'SFNEED036CITZ', 'SFNEED071CITZ', },
	},
	MORALE_LOW_HUNGER={
		lineCodes={ 'SFEATS038CITZ', 'SFNEED050CITZ', 'SFNEED051CITZ', 'SFNEED054CITZ',
					'SFNEED070CITZ',
				},
		priority=2,
	},
	MORALE_LOW_STUFF={
		lineCodes={ 'SFNEED065CITZ', 'SFNEED066CITZ', 'SFNEED067CITZ', 'SFNEED068CITZ',
                'SFNEED069CITZ',},
		priority=2,
	},
	NEED_SHELVING={
		lineCodes={ 'SFTRAD015CITZ', 'SFTRAD016CITZ', 'SFTRAD017CITZ', },
	},
	-- morale higher due to this need being satisfactorily high
	MORALE_HIGH_DUTY={
		lineCodes={ 'SFNEED037CITZ', 'SFNEED038CITZ', 'SFNEED039CITZ' },
	},
	MORALE_HIGH_SOCIAL={
		lineCodes={ 'SFNEED040CITZ', 'SFNEED041CITZ', 'SFNEED042CITZ' },
	},
	MORALE_HIGH_AMUSEMENT={
		lineCodes={ 'SFNEED043CITZ', 'SFNEED044CITZ', 'SFNEED045CITZ' },
	},
	MORALE_HIGH_ENERGY={
		lineCodes={ 'SFNEED046CITZ', 'SFNEED047CITZ', 'SFNEED048CITZ' },
	},
	MORALE_HIGH_HUNGER={
		lineCodes={ 'SFNEED049CITZ', 'SFNEED052CITZ', 'SFNEED053CITZ' },
	},
	MORALE_LOW_OXYGEN={
        lineCodes={'OXYGEN002CITZ','OXYGEN004CITZ','OXYGEN005CITZ','OXYGEN006CITZ','OXYGEN007CITZ',
                   'OXYGEN014CITZ','OXYGEN015CITZ','OXYGEN016CITZ','OXYGEN027CITZ','OXYGEN017CITZ',
                   'OXYGEN020CITZ','OXYGEN025CITZ'},
        priority=3,
    },
	-- high room score
	MORALE_COOL_PUB={
		lineCodes={'SFWAND023CITZ','SFWAND024CITZ','SFWAND025CITZ','SFWAND026CITZ','SFWAND027CITZ',},
	},
	MORALE_COOL_GARDEN={
		lineCodes={'SFWAND028CITZ','SFWAND029CITZ','SFWAND030CITZ','SFWAND031CITZ','SFWAND032CITZ',},
	},
	MORALE_COOL_ROOM_GENERIC={
		lineCodes={'SFWAND033CITZ','SFWAND034CITZ','SFWAND035CITZ','SFWAND036CITZ','SFWAND037CITZ',},
	},
	-- activities
	WORK_OUT = {
		lineCodes={ 'SFWOUT001CITZ','SFWOUT002CITZ','SFWOUT003CITZ','SFWOUT004CITZ','SFWOUT005CITZ',
                    'SFWOUT006CITZ','SFWOUT007CITZ','SFWOUT008CITZ','SFWOUT009CITZ','SFWOUT010CITZ',
                    'SFWOUT011CITZ','SFWOUT012CITZ','SFWOUT022CITZ','SFWOUT023CITZ' },
		priority=0,
	},
	LIFT_WEIGHTS = {
		lineCodes={ 'SFWOUT013CITZ', 'SFWOUT014CITZ', 'SFWOUT015CITZ', 'SFWOUT016CITZ', 'SFWOUT017CITZ',
                    'SFWOUT018CITZ', 'SFWOUT019CITZ', 'SFWOUT020CITZ', 'SFWOUT021CITZ', 'SFWOUT022CITZ',
					'SFWOUT022CITZ',
				},
	},
    PLAY_GAME_SYSTEM = {
		lineCodes={ 'SFGAME001CITZ','SFGAME002CITZ','SFGAME003CITZ','SFGAME005CITZ','SFGAME007CITZ',
                    'SFGAME008CITZ','SFGAME009CITZ','SFGAME010CITZ','SFGAME012CITZ','SFGAME013CITZ',
					'SFGAME014CITZ','SFGAME015CITZ',
				},
	},
    PLAY_GAME_SYSTEM_UNEMPLOYED = {
		lineCodes={ 'SFGAME001CITZ','SFGAME002CITZ','SFGAME004CITZ','SFGAME005CITZ','SFGAME006CITZ',
                    'SFGAME007CITZ','SFGAME008CITZ','SFGAME009CITZ','SFGAME010CITZ','SFGAME011CITZ'},
	},
	WANDER = {
		lineCodes={ 'SFWAND001CITZ', 'SFWAND002CITZ', 'SFWAND003CITZ', 'SFWAND004CITZ', 'SFWAND005CITZ',
                    'SFWAND006CITZ', 'SFWAND007CITZ', 'SFWAND008CITZ', 'SFWAND020CITZ' },
        priority=0,
	},
    WANDER_SPACE = {
		lineCodes={ 'SFWAND007CITZ','SFWAND009CITZ','SFWAND010CITZ','SFWAND011CITZ','SFWAND012CITZ',
                    'SFWAND013CITZ','SFWAND014CITZ','SFWAND015CITZ','SFWAND016CITZ','SFWAND017CITZ',
                    'SFWAND018CITZ','SFWAND019CITZ','SFWAND020CITZ','SFWAND021CITZ','SFWAND021CITZ',
                    'SFWAND022CITZ' },
        priority=0,
	},
    INFECTED_PARASITE = {
        lineCodes={'SFPARA001CITZ','SFPARA002CITZ','SFPARA003CITZ','SFPARA004CITZ','SFPARA005CITZ',
                   'SFPARA006CITZ','SFPARA007CITZ','SFPARA008CITZ','SFPARA009CITZ',},
        priority=2,
    },
    MONSTER_GENERIC = {
        lineCodes={'SFMONS001MONS','SFMONS002MONS','SFMONS003MONS','SFMONS004MONS','SFMONS005MONS',
                   'SFMONS006MONS','SFMONS007MONS','SFMONS008MONS','SFMONS009MONS','SFMONS010MONS',
                   'SFMONS011MONS','SFMONS012MONS','SFMONS013MONS','SFMONS014MONS','SFMONS015MONS',
                   'SFMONS016MONS','SFMONS017MONS','SFMONS018MONS','SFMONS019MONS','SFMONS020MONS',},
    },
    KILLBOT_GENERIC = {
        lineCodes={'SFMONS021KBOT','SFMONS022KBOT','SFMONS023KBOT','SFMONS024KBOT','SFMONS025KBOT',
                   'SFMONS026KBOT','SFMONS027KBOT','SFMONS028KBOT','SFMONS029KBOT','SFMONS030KBOT',
                   'SFMONS031KBOT',},
    },
}

-- if priority isn't specified for a log type above, use this
Log.DEFAULT_PRIORITY = 0
-- logs with this priority or higher will always post, even if more are queued
Log.PRIORITY_ALWAYS_POST = 4

-- codes used in log texts that signify a replacement to be performed,
-- all caps and enclosed in slashes, eg /RANDOMBAND/
-- evalFn: refer to a function for replacement.
-- keyName: use a tData (passed to Log.add) key for replacement.
-- bLink: this should appear as a clickable link in the UI.
Log.tReplaceCodes=
{
	MYNAME = { evalFn=function(rChar) return rChar.tStats.sName end },
	RANDOMBAND = { evalFn=function() return Log.randomBand() end },
    RANDOMFOOD = { evalFn=function() return Log.randomFood() end },
    FAVORITEFOOD = { evalFn=function(rChar) return Log.getFavoriteFood(rChar) end },
    RANDOMGAME = { evalFn=function() return g_LM.randomLine(Topics.GameNames) end },
    PLAYTIME = { keyName = 'nPlayTime' },
	RANDOMDUTY = { evalFn=function(rChar) return Log.randomDuty(rChar.tStats.nJob) end },
	MYDUTY = { evalFn=function(rChar) return Log.getDutyName(rChar) end },
	DUTYTARGET = { bLink=true, keyName='sDutyTarget' },
	CHATPARTNER = { bLink=true, keyName='sChatPartner' },
	CHATTOPIC = { keyName='sTopic' },
	DECEASED = { bLink=true, keyName='sDeceased' },
	ATTACKTARGET = { bLink=true, keyName='sAttackTarget' },
    THINGKILLED = { keyName='sThingKilled' },
    TIMESBURNED = { keyName='sTimesBurned' },
	RANDOMDRINKNAME = { evalFn=function() return Topics.generateDrinkName() end },
	CURRENTROOM = { bLink=true, evalFn=function(rChar) 
        local rRoom = rChar:getRoom()
        return (rRoom and rRoom ~= Room.getSpaceRoom() and rRoom.uniqueZoneName)
    end 
    },
	MYMEAL = { keyName='sMealName' },
	RANDOMPROVENANCE = { evalFn=function() return Topics.getRandomProvenance() end },
	RANDOMCREATURE = { evalFn=function() return Topics.generateCreatureName() end },
	RANDOMCITIZENINROOM = { evalFn=function(rChar) return Log.randomPersonInRoom(rChar) end },
	CARRIEDRESEARCH = { keyName='sResearchData' },
	RESEARCHSUBJECT = { keyName='sResearchData' },
    RANDOMDISEASE = { evalFn=function() return require('Malady').getDiseaseName() end },
	PATIENT = { keyName='sPatient' },
	DOCTOR = { keyName='sDoctor' },
	DISEASE = { keyName='sDisease' },
    RANDOMPUB = { evalFn=function() return Log.randomPub() end },
	NEARBYPERSON = { keyName='sCharacter' },
	NEARBYOBJECT = { keyName='sObject' },
	TRADEPARTNER = { bLink=true, keyName='sTradePartner' },
	TRADEITEM = { keyName='sItemName' },
	TRADEOTHERITEM = { keyName='sOtherItemName' },
	TRADETAG = { keyName='sFavTag' },
	ITEM = { keyName='sPickupItem' },
	ITEMTAG = { keyName='sFavTag' },
    OPPONENT = { keyName='sOpponent' },
    SABOTEUR = { keyName='sSaboteur' },
    RAMPAGER = { keyName='sRampager' },
	BESTFRIEND = { evalFn=function(rChar) return Log.bestFriend(rChar) end },
}

Log.tTags=
{
    -- personality variables
	brave = { scoreFn=function(rChar) return Log.normalizedScore(rChar.tStats.tPersonality.nBravery) end },
	coward = { scoreFn=function(rChar) return -Log.normalizedScore(rChar.tStats.tPersonality.nBravery) end },
	gregarious = { scoreFn=function(rChar) return Log.normalizedScore(rChar.tStats.tPersonality.nGregariousness) end },
	shy = { scoreFn=function(rChar) return -Log.normalizedScore(rChar.tStats.tPersonality.nGregariousness) end },
	neat = { scoreFn=function(rChar) return Log.normalizedScore(rChar.tStats.tPersonality.nNeatness) end },
	slob = { scoreFn=function(rChar) return -Log.normalizedScore(rChar.tStats.tPersonality.nNeatness) end },
    optimist = { scoreFn=function(rChar) return Log.normalizedScore(rChar.tStats.tPersonality.nPositivity) end },
    pessimist = { scoreFn=function(rChar) return -Log.normalizedScore(rChar.tStats.tPersonality.nPositivity) end },
    angry = { scoreFn=function(rChar) return Log.angerScore(rChar) end },
    chill = { scoreFn=function(rChar) return -Log.normalizedScore(rChar.tStats.tPersonality.nTemper) end },
    hardworking = { scoreFn=function(rChar) return Log.normalizedScore(rChar.tStats.tPersonality.nWorkEthic) end },
    lazy = { scoreFn=function(rChar) return -Log.normalizedScore(rChar.tStats.tPersonality.nWorkEthic) end },
    authoritarian = { scoreFn=function(rChar) return Log.normalizedScore(rChar.tStats.tPersonality.nAuthoritarian) end },
    -- morale
    happy = { scoreFn=function(rChar) return Log.moraleScore(rChar) end },
    sad = { scoreFn=function(rChar) return -Log.moraleScore(rChar) end },
    -- self-esteem (ie affinity for self)
    egoist = { scoreFn=function(rChar) return Log.selfEsteemScore(rChar) end },
    insecure = { scoreFn=function(rChar) return -Log.selfEsteemScore(rChar) end },
    -- "quirks" (boolean personality flags)
    emoticon = { scoreFn=function(rChar) return Log.quirkScore(rChar.tStats.tPersonality.bEmoticon) end },
    gourmand = { scoreFn=function(rChar) return Log.quirkScore(rChar.tStats.tPersonality.bGourmand) end },
    joker = { scoreFn=function(rChar) return Log.quirkScore(rChar.tStats.tPersonality.bJoker) end },
    sentimental = { scoreFn=function(rChar) return Log.quirkScore(rChar.tStats.tPersonality.bSentimental) end },
    competitive = { scoreFn=function(rChar) return Log.quirkScore(rChar.tStats.tPersonality.bCompetitive) end },
    hipster = { scoreFn=function(rChar) return Log.quirkScore(rChar.tStats.tPersonality.bHipster) end },
    -- needs
    hungry = { scoreFn=function(rChar) return -Log.needsScore(rChar, 'Hunger') end },
    bored = { scoreFn=function(rChar) return -(Log.needsScore(rChar, 'Amusement') + Log.needsScore(rChar, 'Duty')) / 2 end },
    lonely = { scoreFn=function(rChar) return -Log.needsScore(rChar, 'Social') end },
    tired = { scoreFn=function(rChar) return -Log.needsScore(rChar, 'Energy') end },
    -- duties
    scientist = { scoreFn=function(rChar) return Log.dutyScore(rChar, Character.SCIENTIST) end },
    technician = { scoreFn=function(rChar) return Log.dutyScore(rChar, Character.TECHNICIAN) end },
	-- duty affinity
	lovesjob = { scoreFn=function(rChar) return Log.currentDutyAffScore(rChar) end },
	hatesjob = { scoreFn=function(rChar) return -Log.currentDutyAffScore(rChar) end },
    -- races
    human = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_HUMAN) end },
    tobian = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_TOBIAN) end },
    shamon = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_SHAMON) end },
    jelly = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_JELLY) end },
    cat = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_CAT) end },
    chicken = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_CHICKEN) end },
    birdshark = { scoreFn=function(rChar) return Log.raceScore(rChar, Character.RACE_BIRDSHARK) end },
    -- activity affinities - these correspond with Topics.tActivities entries
    boozer = { scoreFn=function(rChar) return Log.activityScore(rChar, 'Drinking') end },
    jock = { scoreFn=function(rChar) return Log.activityScore(rChar, 'Exercise') end },
    gamer = { scoreFn=function(rChar) return Log.activityScore(rChar, 'Gaming') end },
}

--
-- replacement helper functions
-- (usually very custom, one-off behavior)
--
function Log.getDutyName(rChar)
	local lc = Character.JOB_NAMES[rChar.tStats.nJob]
	return g_LM.line(lc)
end

function Log.randomDuty(nExcept)
    local idx = DFUtil.arrayRandomExcept(Character.JOB_NAMES,nExcept)
	return g_LM.line(idx)
end

function Log.randomFood()
	local id = Topics.getRandomTopic('Foods')
	return Topics.tTopics[id].name
end

function Log.randomBand()
	local id = Topics.getRandomTopic('Bands')
	return Topics.tTopics[id].name
end

function Log.getFavoriteFood(rChar)
    local faveFood = rChar:getFavorite('Foods')
    if faveFood then
        return Topics.tTopics[faveFood].name
    end
end

function Log.bestFriend(rChar)
	local sFriendID = rChar:getFavorite('People')
	if not sFriendID then
		return g_LM.line('SFSECU027CITZ')
	end
	local rFriend = require('CharacterManager').getCharacterByUniqueID(sFriendID, true)
	if not rFriend or not rFriend.tStats then
		return g_LM.line('SFSECU027CITZ')
	end
	return rFriend.tStats.sName
end

function Log.randomPersonInRoom(rChar)
	-- returns ID of random person in the room (who isn't the specified character)
    local rRoom = rChar:getRoom()
    if not rRoom or rRoom == Room.getSpaceRoom() then return nil end

	local tCharacters,nCharacters = rRoom:getCharactersInRoom()
	-- if nobody else is in the room, use a generic "that guy"
	if nCharacters <= 1 then
		return g_LM.line('SFBART007CITZ')
	end
	local rOther = rChar
	while rOther == rChar do
		rOther = MiscUtil.randomKey(tCharacters)
	end
	return rOther.tStats.sName
end

function Log.randomPub()
	-- returns friendlyname of random pub on base
	local tRooms = Room.getRoomsOfTeam(Character.TEAM_ID_PLAYER, false, 'PUB', true)
	if #tRooms == 0 then
		-- no pubs, generic "the pub"
		return g_LM.line('SFBART008CITZ')
	end
	local rRoom = DFUtil.arrayRandom(tRooms)
	return rRoom.uniqueZoneName
end

--
-- core Log functionality
--
function Log.add(tLogType, rChar, tData)
    assert(rChar.bInitialized)
	-- handle empty tData
	tData = tData or {}
    --if monster, play ridiculous monster lines
    if rChar.tStats.nRace == Character.RACE_MONSTER then 
        tLogType = Log.tTypes.MONSTER_GENERIC
    elseif rChar.tStats.nRace == Character.RACE_KILLBOT then 
        tLogType = Log.tTypes.KILLBOT_GENERIC
    end
	if not tLogType.lineCodes or #tLogType.lineCodes == 0 then
		Print(TT_Warning, 'LOG: linecode not found for log type '..tLogType)
		return
	end
	-- sort group of linecodes based on tag scores, pick best
	local nBestTagScore = 0
	local sBestLine
    -- randomize (in place) list of linecodes so if we have to grab one
    -- at random, we won't always grab the first in the list
    DFUtil.arrayShuffle(tLogType.lineCodes)
	for _,lc in pairs(tLogType.lineCodes) do
		-- log repeating in the same screen never looks good
		if not rChar:lineCodeUsedRecently(lc) then
            -- if no valid tags for any of these lines, grab first in list
            if not sBestLine then
                sBestLine = lc
            end
			local tags = g_LM.getTags(lc)
            if tags then
                local nTotalScore = 0
                for _,tag in pairs(tags) do
                    -- gated/negated tags give score of -1000
                    nTotalScore = nTotalScore + Log.getLogTagScore(tag, rChar)
                end
                if nTotalScore > nBestTagScore then
                    nBestTagScore = nTotalScore
                    sBestLine = lc
                end
            end
		end
	end
    -- if all logs are recently used or low-scoring, just pick a random one
    if not sBestLine then
        sBestLine = DFUtil.arrayRandom(tLogType.lineCodes)
    end
    assert(sBestLine ~= nil)
	-- do replacements for linecode's string based on context
	local sLine, tLines = Log.getReplacements(sBestLine, rChar, tData)
	if not sLine or not tLines then
		Print(TT_Warning, "LOG: couldn't parse replacements for log with linecode "..sBestLine)
		return
	end
    -- compile entry data
	local tEntry = {}
	tEntry.sLine = sLine
	tEntry.tLines = tLines
	tEntry.linecode = sBestLine
	-- store tag score to help prioritize in Character:postLogFromQueue
	tEntry.nTagScore = nBestTagScore
    -- store log's type as a string
	tEntry.logType = Log.getTypeString(tLogType)
	-- sort code is cleaner when we can assume it has a priority
	tEntry.priority = tLogType.priority or Log.DEFAULT_PRIORITY
	tEntry.nTime = GameRules.elapsedTime
    -- dump to file for data sciencen'
    if Log.bLog then
        local s = MiscUtil.padString(tEntry.logType, 40, true)
        s = s .. MiscUtil.padString(tEntry.linecode, 13, true)
        s = s .. ' @ ' .. tEntry.nTime
        -- log each linecode's tags
        local tTags = g_LM.getTags(tEntry.linecode)
        if tTags and #tTags > 0 then
            s = s .. ' (tags: '
            for _,tag in pairs(tTags) do
                s = s .. tag .. ', '
            end
            -- snip last comma and close paren
            s = string.sub(s, 1, string.len(s) - 2)
            s = s .. ')'
        end
        local logDir = MOAIEnvironment.documentDirectory .. "/Logs/"
        MOAIFileSystem.affirmPath(logDir)
        local testlog = io.open( logDir .. "spaceface.log" , "a")
        testlog:write(s .. "\n")
        testlog:close()
    end
	-- add log to a queue, to be posted next "log tick" if high pri enough
	if Log.bFilter then
		rChar:queueLog(tEntry)
	else
		rChar:addLog(tEntry)
	end
end

function Log.getTypeString(tType)
    for sType,tData in pairs(Log.tTypes) do
        if tData and tData == tType then
            return sType
        end
    end
end

function Log.getLogTagScore(sTag, rChar)
	-- tags starting with g_: "gated", ie only use log if tag is apropos
	-- tags starting with n_: "negative gated", ie only use log if tag is NOT
    local bGated, bNegativeGated = false, false
    if string.find(sTag, 'g_') == 1 then
        bGated = true
        -- snip g_ from tag name to get its "normal" form
        sTag = sTag:gsub('g_', '')
    elseif string.find(sTag, 'n_') == 1 then
        bNegativeGated = true
        sTag = sTag:gsub('n_', '')
    end
    -- valid tag?
	if not Log.tTags[sTag] then
		return 0
	end
	local nScore = Log.tTags[sTag].scoreFn(rChar)
    if bGated and nScore <= 0 then
        return -10000
    elseif bNegativeGated and nScore > 0 then
        return -10000
    else
        return nScore
    end
end

--
-- tag scoring functions
--

function Log.normalizedScore(nValue)
    -- score for things like personality should be negative if, for example,
    -- tag is brave and someone is the opposite of brave
    return (nValue * 2) - 1
end

function Log.needsScore(rChar, sNeed)
    -- map -100 to +100 needs values on to -1 to 1 tag score range
    -- NOTE: following assumes min = -max; we'll probably never change that?
    local Needs = require('Utility.Needs')
    return rChar.tNeeds[sNeed] / Needs.MAX_VALUE
end

function Log.dutyScore(rChar, nDuty)
    -- return 0 if citizen is not of specified duty, 1 if so
    if rChar.tStats.nJob == nDuty then
        return 1
    else
        return 0
    end
end

function Log.currentDutyAffScore(rChar)
	-- map affinity to -1 to 1 tag score range
	return rChar:getJobAffinity(rChar.tStats.nJob) / 10
end

function Log.raceScore(rChar, nRace)
    -- return 0 if citizen is not of specified race, 1 if so
    if rChar.tStats.nRace == nRace then
        return 1
    else
        return 0
    end
end

function Log.angerScore(rChar)
	return rChar.tStatus.nAnger / Character.ANGER_MAX
end

function Log.activityScore(rChar, sActivity)
    -- return -1/1 affinity for specified activity
    return rChar:getAffinity(sActivity) / Character.STARTING_AFFINITY
end

function Log.selfEsteemScore(rChar)
    -- "affinity for self"
	return rChar:getAffinity(rChar.tStats.sUniqueID) / Character.STARTING_AFFINITY
end

function Log.moraleScore(rChar)
    -- NOTE: following assumes min = -max; we'll probably never change that?
    return rChar.tStats.nMorale / Character.MORALE_MAX
end

function Log.quirkScore(bHasQuirk)
    if bHasQuirk then
		-- vary score to create more variation in log choice
        return math.min(0.5, math.random())
    else
        return 0
    end
end

function Log.getReplacement(tSub, rChar, tData)
	if tSub.evalFn then
		-- use a function to get the replacement
		return tSub.evalFn(rChar, tData) or ''
	elseif tSub.keyName then
		-- use a tData key for the replacementink
		return tData[tSub.keyName]
	else
		print("LOG: no evalFn or keyName for replacement "..tSub)
		return 'ERROR'
	end
end

function Log.getReplacements(linecode, rChar, tData)
	-- returns a concatenated string AND a table of lines, some of which are
	-- strings and some of which are tables of link data.
	-- (all strings, so that data is both savegame-friendly and UI-ready)
	
	local tLines = {}
	local line = g_LM.line(linecode)
	
	-- break string into chunks, iteratively nibbling it down
	local i = 0
	while i < line:len() do
		-- find next /
		i = line:find('/', 0)
		-- if no replacements, return the rest of the line
		if not i then
			i = line:len()
			table.insert(tLines, line)
			break
		end
		-- double slash (//) escapes a normal slash
		local nextChar = line:sub(i, i+1)
		if nextChar == '/' then
			i = i + 2
		else
			-- snip string before / and find the closing /
			local firsthalf = line:sub(0, i-1)
			line = line:sub(i + 1, line:len())
			local lastIndex = i
			i = line:find('/', 0)
			local secondhalf
			if not i then
				secondhalf = 'ERROR FINDING SECOND /'
				i = lastIndex
			else
				secondhalf = line:sub(0, i-1)
			end
			-- is text between slashes a valid replacement code?
			local tSub = Log.tReplaceCodes[secondhalf]
			if not tSub then
				-- can't parse, quote input up to this point
				-- (re-add / in case we just passed an escape slash)
				table.insert(tLines, firsthalf..secondhalf..'/')
				line = line:sub(i + 1, line:len())
			else
				-- separate replacement even if it's not a link,
				-- so we can color/highlight it
				table.insert(tLines, firsthalf)
				-- getReplacement returns an ID and type for links
				local id,linkType
				secondhalf,id,linkType = Log.getReplacement(tSub, rChar, tData)
				if tSub.bLink then
					-- compile table of link data, in place of string
					local tLink = {}
					-- link text = player-visible text
					tLink.linkText = secondhalf
					-- link ID = unique ID of the object linked to
					tLink.linkID = tData.sLinkTarget
					-- link type = type of linked object
					tLink.linkType = tData.sLinkType
					table.insert(tLines , tLink)
				else
					table.insert(tLines, secondhalf)
				end
				line = line:sub(i + 1, line:len())
				-- update i for new string length
				i = line:find('/', 0) or line:len() - 1
			end
		end
	end
	-- for possibly-temporary reasons, save out a plain ol concatenated string
	-- version of the entire line
	local sLine = ''
	for _,line in pairs(tLines) do
		if line.linkText then
			--sLine = sLine .. '[' .. line.linkText .. ']' --removed until we add links for real
            sLine = sLine .. line.linkText
		elseif type(line) == 'string' then
			sLine = sLine .. line
		end
	end
	-- return table only if it's got lines for easier nil check
	if #tLines then
		return sLine, tLines
	end
end

return Log
