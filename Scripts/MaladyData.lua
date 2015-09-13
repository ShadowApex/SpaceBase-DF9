local Log=require('Log')

local t=
{
    Default=
    {
        -- Spread:
        -- Generally, cough/sneeze/touch a surface, then someone else does.
        -- Or direct person-person contact. That's most cases.
        -- We could call that airborne, which includes all that.
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
    },

    -- NON-CONTAGIOUS CONDITIONS
    BrokenLeg=
    {
        sFriendlyName='DISEAS002TEXT',
        sDesc='DISEAS022TEXT',
        bIncapacitated=true,
        tDurationRange={100000000,100000000},
        nFieldTreatSkill=0,
        nPerceivedSeverity=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },

    -- NON-CONTAGIOUS CONDITIONS
    KnockedOut=
    {
        sFriendlyName='DISEAS032TEXT',
        sDesc='DISEAS033TEXT',
        bIncapacitated=true,
        tDurationRange={60*2.5,60*5},
        nFieldTreatSkill=0,
        nPerceivedSeverity=1,
        bCreateStrains=false,
        bNoSpawnInEvent=true,
		-- "injury" flag denotes it in a separate UI section
		bIsInjury=true,
    },

    Parasite=
    {
        sFriendlyName='DISEAS003TEXT',
        sDesc='DISEAS023TEXT',
        nSeverity=1,
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

    -- NEED REDUCE MOD DISEASES
    SpaceFlu=
    {
        sDesc='DISEAS024TEXT',
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.5,
        nSeverity=.5,
        tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nFieldTreatSkill=3,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Duty=.5,
            Social=.5,
            Amusement=.5,
            Hunger=.5,
            Energy=2,
        },
    },

    SlackersDisease=
    {
        sDesc='DISEAS025TEXT',
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.2,
        nSeverity=.4,
        tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Duty=.1,
        },
    },

    AntisocialDisease=
    {
        sDesc='DISEAS026TEXT',
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.2,
        nSeverity=.4,
        tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nFieldTreatSkill=5,
        bCreateStrains=true,
		sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
        tReduceMods={
            Social=0,
        },
    },

    HighEnergyLowEnergy =
    {
        sDesc='DISEAS027TEXT',
        nPerceivedSeverity=.1,
        nSeverity=.4,
        tTimeToContagious={30,60},
        tTimeToSymptoms={60,120},
        nFieldTreatSkill=5,
        bCreateStrains=true,
        bStagesLoop = true,
        tDurationRange={2000,4000},
        tSymptomStages=
        {
            {
                -- time until this stage kicks in, either from the time the disease was contracted,
                -- or from the time the next stage started. (looping)
                tTimeToSymptoms={60*4,60*8},
                tReduceMods={
                    Duty=2,
                    Energy=.5,
                    Social=.8,
                    Amusement=.8,
                },
				sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
            {
                -- time until this stage kicks in, from after the last one started.
                tTimeToSymptoms={60*4,60*8},
                tReduceMods={
                    Energy=2,
                },
            },
        },
    },

    Plague=
    {
        sDesc='DISEAS028TEXT',
        bSpreadSneeze=true,
        bSpreadTouch=true,
        nPerceivedSeverity=.9,
        nSeverity=1,
        nFieldTreatSkill=6,
        bCreateStrains=true,
        tSymptomStages=
        {
            {
                tTimeToSymptoms={60*3,60*8},
                tReduceMods={
                    Duty=0,
                    Social=.2,
                    Amusement=.2,
                    Hunger=.2,
                    Energy=3,
                },
                sSymptomLog=Log.tTypes.HEALTH_CITIZEN_GETTING_ILL,
            },
            {
                tTimeToSymptoms={60*10,60*15},
                sSpecial='death',
            },
        },
    },
}

return t
