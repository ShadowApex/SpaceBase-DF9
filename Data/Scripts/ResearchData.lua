local t = {
    VaporizeLevel2 = {
        sName='RESRCH001TEXT',
        sDesc='RESRCH002TEXT',
        tPrereqs={},
        nResearchUnits=1200,
        sIcon = 'ui_jobs_iconJobBuilder',
    },
    MaintenanceLevel2 = {
        sName='RESRCH009TEXT',
        sDesc='RESRCH010TEXT',
        tPrereqs={'MaintenanceLevel2Discovered'},
        nResearchUnits=1200,
        nConditionMultiplier=1.5,
        sIcon = 'ui_jobs_iconJobTechnician',
    },
    BuildLevel2 = {
        sName='RESRCH011TEXT',
        sDesc='RESRCH012TEXT',
        tPrereqs={},
        nResearchUnits=1000,
        sIcon = 'ui_jobs_iconJobBuilder',
    },
    PlantLevel2 = {
        sName='RESRCH013TEXT',
        sDesc='RESRCH014TEXT',
        tPrereqs={},
        nResearchUnits=1000,
        nConditionMultiplier=2,
        sIcon = 'ui_jobs_iconJobBotanist',
    },
    LaserRifles = {
        sName='RESRCH003TEXT',
        sDesc='RESRCH004TEXT',
        tPrereqs={},
        nResearchUnits=1100,
        sIcon = 'ui_jobs_iconJobResponse',
    },
    ArmorLevel2 = {
        sName='RESRCH005TEXT',
        sDesc='RESRCH006TEXT',
        tPrereqs={},
        nResearchUnits=900,
        sIcon = 'ui_jobs_iconJobResponse',
    },
    TeamTactics = {
        sName='RESRCH017TEXT',
        sDesc='RESRCH018TEXT',
        tPrereqs={'TeamTacticsDiscovered'},
        nResearchUnits=2000,
        sIcon = 'ui_jobs_iconJobResponse',
    },
    OxygenRecyclerLevel2 = {
        -- sItemForDesc corresponds with an EnvObjectData entry
        sItemForDesc='OxygenRecyclerLevel2',
        tPrereqs={'AirScrubber'},
        nResearchUnits=1000,
        sIcon = 'ui_jobs_iconJobUnemployed',
    },
    OxygenRecyclerLevel3 = {
        sItemForDesc = 'OxygenRecyclerLevel3',
        tPrereqs = {'OxygenRecyclerLevel2'},
        nResearchUnits = 1500,
        sIcon = 'ui_jobs_iconJobUnemployed',
    },
    OxygenRecyclerLevel4 = {
        sItemForDesc = 'OxygenRecyclerLevel4',
        tPrereqs ={ 'OxygenRecyclerLevel3'},
        nResearchUnits = 2000,
        sIcon = 'ui_jobs_iconJobUnemployed',
    },
    GeneratorLevel2 = {
        -- sItemForDesc corresponds with an EnvObjectData entry
        sItemForDesc='GeneratorLevel2',
        tPrereqs={},
        nResearchUnits=1000,
        sIcon = 'ui_jobs_iconJobUnemployed',
    },
    GeneratorLevel3 = {
        -- sItemForDesc corresponds with an EnvObjectData entry
        sItemForDesc='GeneratorLevel3',
        tPrereqs={'GeneratorLevel2'},
        nResearchUnits=1500,
        sIcon = 'ui_jobs_iconJobUnemployed',
    },
    GeneratorLevel4 = {
        -- sItemForDesc corresponds with an EnvObjectData entry
        sItemForDesc='GeneratorLevel4',
        tPrereqs={'GeneratorLevel3'},
        nResearchUnits=2000,
        sIcon = 'ui_jobs_iconJobUnemployed',
    },
    AirScrubber = {
        sItemForDesc='AirScrubber',
        tPrereqs={},
        nResearchUnits=750,
        sIcon = 'ui_jobs_iconJobDoctor',
    },
    DoorLevel2 = {
        sItemForDesc='HeavyDoor',
        tPrereqs={},
        nResearchUnits=1200,
    },
    FridgeLevel2 = {
        sItemForDesc='FridgeLevel2',
        tPrereqs={'FridgeLevel2Discovered'},
        nResearchUnits=800,
        sIcon = 'ui_jobs_iconJobBarkeep',
    },
    RefineryDropoffLevel2 = {
        sItemForDesc='RefineryDropoffLevel2',
        tPrereqs={},
        nResearchUnits=1200,
        sIcon = 'ui_jobs_iconJobMiner',
    },
    WallMountedTurret2 = {
        sItemForDesc='WallMountedTurret2',
        --tPrereqs={'WallMountedTurret','WallMountedTurretLevel2Discovered'},
        tPrereqs={'WallMountedTurretLevel2Discovered'},
        nResearchUnits=2000,
        sIcon = 'ui_jobs_iconJobResponse',
    },
    -- "blueprints": unlock research, don't give you new tech by themselves
    FridgeLevel2Discovered = {
        sName='PROPSX069TEXT',
        sDesc='PROPSX068TEXT',
        tPrereqs={},
        nResearchUnits=1,
        bDiscoverOnly=true,
    },
    TeamTacticsDiscovered = {
        sName='RESRCH017TEXT',
        sDesc='RESRCH018TEXT',
        tPrereqs={},
        nResearchUnits=1,
        bDiscoverOnly=true,
    },
    MaintenanceLevel2Discovered = {
        sName='RESRCH009TEXT',
        sDesc='RESRCH010TEXT',
        tPrereqs={},
        nResearchUnits=1,
        bDiscoverOnly=true,
    },
    WallMountedTurretLevel2Discovered = {
        sName='PROPSX080TEXT',
        sDesc='PROPSX081TEXT',
        tPrereqs={},
        nResearchUnits=1,
        bDiscoverOnly=true,
    },
}

return t
