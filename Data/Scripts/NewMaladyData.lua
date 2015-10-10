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
-- The Original Developer is not the Initial Developer and is Michael
-- Hamm of Derelict Games.

-- The Initial Developer of the Original Code is Double Fine
-- Productions, Inc.
--
-- The code in this file is the original work of Derelict Games,
-- authored by Michael Hamm.
--
-- Copyright (c) 2015  Michael Hamm <untrustedlife2@gmail.com>
-- All Rights Reserved.
------------------------------------------------------------------------

local Log=require('Log')

local tMaladyList = {
 Default=
    {
    --The "default" malady
		nDifficulty=.25,
        nBacteriaLifetime=180,
        nChanceToInfectCharacter=.05,
        nChanceToInfectObject=.2,
        nImmuneChance=.5,
        tDurationRange={600,2000},
        tImmuneRaces={},
        --nResearchIdentify=0,
        --nResearchCure=0,
        bNoCreate=true,
        bSpreadSneeze=false,
        bSpreadTouch=false,

        nPerceivedSeverity=.2,
        nSeverity=.2,
        bCreateStrains=false,
        bIsMental=false,
    },

    -- NON-CONTAGIOUS CONDITIONS we will keep for now
	
    BrokenLeg=
    {
        sFriendlyName='DISEASTYPE02TEXT',
        sDesc='DISEASDESC01TEXT',
        bIncapacitated=true,
        tDurationRange={100000000,100000000},
        nFieldTreatSkill=0,
		nDifficulty=1,
        nPerceivedSeverity=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },

    KnockedOut=
    {
        sFriendlyName='DISEASTYPE04TEXT',
        sDesc='DISEASDESC08TEXT',
        bIncapacitated=true,
        tDurationRange={60*2.5,60*5},
        nFieldTreatSkill=0,
        nPerceivedSeverity=1,
		nDifficulty=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },

--Our injuries
    CrackedSkull=
    {
        sFriendlyName='DISEASTYPE05TEXT',
        sDesc='DISEASDESC11TEXT',
        bIncapacitated=true,
        tDurationRange={100000000,100000000},
        nFieldTreatSkill=0,
		nDifficulty=1,
        nPerceivedSeverity=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },
    
     BrokenRib=
    {
        sFriendlyName='DISEASTYPE07TEXT',
        sDesc='DISEASDESC12TEXT',
        bIncapacitated=false,
        tDurationRange={100000000,100000000},
        nFieldTreatSkill=0,
		nDifficulty=1,
        nPerceivedSeverity=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },
    BrokenNose=
    {
        sFriendlyName='DISEASTYPE06TEXT',
        sDesc='DISEASDESC13TEXT',
        bIncapacitated=true,
        tDurationRange={100000000,100000000},
        nFieldTreatSkill=0,
		nDifficulty=1,
        nPerceivedSeverity=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },
---Injuries above

--doublefine diseases we will keep (for the moment)
 AntisocialDisease=
    {
        sDesc='DISEASDESC05TEXT',
       	nChanceOfAffliction = 50,
        nChanceOfNewStrain = 50,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.2,
        nSeverity=.4,
		nDifficulty=.4,
        tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Social=0,
        },
    }
    ,
    Parasite=
    {
        sFriendlyName='DISEASTYPE03TEXT',
        sDesc='DISEASDESC02TEXT',
	    nChanceOfAffliction = 4,
        nChanceOfNewStrain = 0,
        nSeverity=1,
		nDifficulty=.5,
        nAdditionalDeadliness=.2,
        nPerceivedSeverity=.2,
        sSpecial='parasite',
        nFieldTreatSkill=99999,
        bCreateStrains=false,
        tSymptomStages=
        {
            {
                tTimeToSymptoms={60*3,60*8},
                tReduceMods={
                    Hunger=1.5,
                },
                sSymptomLog=Log.tTypes.INFECTED_PARASITE,
            },
            {
                tTimeToSymptoms={60*10,60*15},
                sSpecial='parasite',
            },
        },
    },

--Our diseases
    -- NEED REDUCE MOD DISEASES
    Thing=
    {
        sDesc='DISEASTHINGTEXT',
		nChanceOfAffliction = 4,
        nChanceOfNewStrain = 100,
	    bSpreadSneeze=false,
        bSpreadTouch=false,
        nSeverity=1,
		nDifficulty=.7,
        nAdditionalDeadliness=.5,
        nPerceivedSeverity=.2,
        nFieldTreatSkill=6,
        bCreateStrains=true,
		tSymptomStages=
        {
            {
                tTimeToSymptoms={60*1,60*2},
                tReduceMods={
                    Hunger=2,
				    Social=4,
                },
			sSymptomLog=Log.tTypes.HEALTH_CITIZEN_IS_THING,
            },
            {
                tTimeToSymptoms={60*1,60*4},
				sSpecial='thing',
            },
        },
    },
 
	 Hyper=
    {
        sDesc='DISEASDESC10TEXT',
		nChanceOfAffliction = 15,
        nChanceOfNewStrain = 50,
	    bSpreadSneeze=true,
        bSpreadTouch=false,
        nSeverity=1,
		nDifficulty=.6,
	    tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nAdditionalDeadliness=.5,
        nPerceivedSeverity=.4,
        nFieldTreatSkill=6,
        bCreateStrains=true,
		tReduceMods={
            Duty=4,
            Hunger=8,
            Energy=8,
		    Social=4,
            Amusement=4,
        },
    },
	

    Dysentery=
    {
        sDesc='DISEASDESC09TEXT',
	    nChanceOfAffliction = 20,
        nChanceOfNewStrain = 10,
        bSpreadSneeze=false,
        bSpreadTouch=true,
        nPerceivedSeverity=.25,
        nSeverity=.75,
		nDifficulty=.7,
        nImmuneChance=.1,
        tTimeToContagious={30,60*15},
        nFieldTreatSkill=2,
        nBacteriaLifetime=60*15,
        bCreateStrains=true,
	sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tSymptomStages=
        {
            {
	        tTimeToSymptoms={10,60*2},
		tReduceMods={
		   Duty=.25,
		   Hunger=0,
		},
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
	    {
                tTimeToSymptoms={60*2,60*12},
                tReduceMods={
                    Duty=0,
                    Social=.2,
                    Amusement=.2,
                    Hunger=0,
                    Energy=.2,
                },
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
            {
                tTimeToSymptoms={60*12,60*15},
                sSpecial='death',
            },
        },
    },
	--An extremely contagious disease, though non-deadly
	Rhinovirus=
    {
        sDesc='DISEASDESC07TEXT',
		nChanceOfAffliction = 50,
        nChanceOfNewStrain = 50,
        nChanceToInfectCharacter=.5,
        nChanceToInfectObject=.5,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.15,
        nSeverity=.2,
		nDifficulty=.3,
        nImmuneChance=.1,
        tTimeToContagious={0,10},
        nFieldTreatSkill=2,
        nBacteriaLifetime=60*15,
        bCreateStrains=true,
	sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tSymptomStages=
        {
            {
	        tTimeToSymptoms={10,60*2},
		tReduceMods={
		   Duty=.5,
		   Energy=.1,
		},
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
     
        },
	  },
	},
	--Really unpleasent and kills slowly, and less noticeable then a parasite., spreads more easily
	SpacePlague=
    {
        sDesc='DISEASDESC03TEXT',
		nChanceOfAffliction = 15,
        nChanceOfNewStrain = 50,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nChanceToInfectCharacter=.9,
        nChanceToInfectObject=.9,
        nPerceivedSeverity=.15,
        nSeverity=.5,
		nDifficulty=.7,
        nImmuneChance=.1,
        tTimeToContagious={1,2},
        nFieldTreatSkill=7,
        nBacteriaLifetime=60*30,
        bCreateStrains=true,
	sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tSymptomStages=
        {
            {
	        tTimeToSymptoms={10,60*2},
			tReduceMods={
				Duty=.5,
				Energy=.1,
			},
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
     
        },
         {
            tTimeToSymptoms={60*2,60*15},
			tReduceMods={
				Duty=.9,
				Energy=.5,
                Social=.8,
                Amusement=.8,
				Energy=.5,
                Hunger=1.
			},
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
     
        },
         {
          tTimeToSymptoms={60*15,60*20},
          sSpecial='death',
        },
	  },
	},

    --The hippo virus is deadly if left for awhile, t spreads , and very unpleasent, kills quickly
	Hippovirus=
    {
        sDesc='DISEASDESC04TEXT',
		nChanceOfAffliction = 50,
        nChanceOfNewStrain = 20,
        bSpreadSneeze=false,
        bSpreadTouch=true,
        nPerceivedSeverity=.5,
        nSeverity=.5,
		nDifficulty=.7,
        tTimeToContagious={60*2,60*10},
        nFieldTreatSkill=5,
        nBacteriaLifetime=60*30,
        bCreateStrains=true,
	sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tSymptomStages=
        {
            {
	        tTimeToSymptoms={10,60*2},
		tReduceMods={
		   Duty=0,
		},
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
	    {
                tTimeToSymptoms={60*2,60*10},
                tReduceMods={
                    Duty=0,
                    Social=.8,
                    Amusement=.8,
					Energy=.5,

                },
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
            {
                tTimeToSymptoms={60*10,60*11},
                sSpecial='death',
            },
        },
	},
	--madcow should make the infected attack people, for now it just amuses them then kills them
	Crazies=
    {
        sDesc='DISEASDESC14TEXT',
		nChanceOfAffliction = 15,
        nChanceOfNewStrain = 50,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.35,
        nSeverity=.5,
		nDifficulty=.7,
        tTimeToContagious={60*2,60*10},
        nFieldTreatSkill=5,
        nBacteriaLifetime=60*30,
        bCreateStrains=true,
	sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tSymptomStages=
        {
            {
	        tTimeToSymptoms={10,60*2},
		tReduceMods={
		--a value of zero locks the need in place.
		   Duty=0,
		   social=0,
		   --a negative value will increase the need
		   Amusement=-.3,
		},
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
	    {
                tTimeToSymptoms={60*2,60*15},
                tReduceMods={
                    Duty=0,
                    Social=0,
                    Amusement=-.8,

                },
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
            {
                tTimeToSymptoms={60*18,60*21},
                sSpecial='death',
            },
        },
	},

    --More specific diseases
    Workaholic=
    {
        sDesc='DISEASDESC15TEXT',
        nChanceOfAffliction = 50,
        nChanceOfNewStrain = 30,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.2,
        nSeverity=.5,
		nDifficulty=.4,
        tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Duty=3,
        },
    },
    
    --sneeze on people when socializing
    SuperSocial=
    {
        sDesc='DISEASDESC16TEXT',
        nChanceOfAffliction = 50,
        nChanceOfNewStrain = 30,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.2,
        nSeverity=.5,
		nDifficulty=.5,
        tTimeToContagious={1,10},
        tTimeToSymptoms={10,11},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Social=3,
        },
    },
    
    --No amusement
    NotAmused=
    {
        sDesc='DISEASDESC17TEXT',
        nChanceOfAffliction = 50,
        nChanceOfNewStrain = 30,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.3,
        nSeverity=.5,
		nDifficulty=.5,
        tTimeToContagious={1,10},
        tTimeToSymptoms={10,11},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Amusement = 3,
        },
    },
    --No energy
    SleepyDisease=
    {
        sDesc='DISEASDESC18TEXT',
        nChanceOfAffliction = 50,
        nChanceOfNewStrain = 30,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.3,
        nSeverity=.5,
		nDifficulty=.5,
        tTimeToContagious={1,10},
        tTimeToSymptoms={10,11},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Social=.2,
            Energy=4,
        },
    },
    --All the effects of the simpler diseases piled into one game ending evil infection.
    AllBadDisease=
    {
        sDesc='DISEASDESC19TEXT',
        nChanceOfAffliction = 4,
        nChanceOfNewStrain = 90,
        nChanceToInfectCharacter=.9,
        nChanceToInfectObject=.9,
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.3,
        nSeverity=.5,
		nDifficulty=.5,
        tTimeToContagious={1,10},
        tTimeToSymptoms={10,11},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Energy=4,
            Amusement = 3,
            Social = 3,
            Hunger = 8,
            Duty=0,
        },
    },


}
return tMaladyList