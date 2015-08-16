local Character=require('CharacterConstants')
local InventoryData = {}

InventoryData.MINE_PICKUP_NAME = 'Rock' -- Actually the template name, not the item name.
InventoryData.DEFAULT_SPRITE_SHEET = 'Environments/Objects'
-- every 14.4 seconds (every needs reduce tick)
-- Let's say a favorite item can become totally uninteresting (1->0) after 5 hours of gameplay,
-- e.g. 18000 seconds, e.g. 1250 ticks, so 1/1250. (*20 for aff system)
-- We may want to make this higher, and just flag sentimental items for slower decay individually.
InventoryData.DEFAULT_AFFINITY_DECAY = .016

InventoryData.tTags=
{
    Color={
        Red=    { lc='TAGSXX001TEXT', color={220/255,20/255,60/255}, },
        Orange= { lc='TAGSXX002TEXT', color={255/255,153/255,18/255}, },
        Yellow= { lc='TAGSXX003TEXT', color={255/255,255/255,0/255}, },
        Green=  { lc='TAGSXX004TEXT', color={0,205/255,0}, },
        Cyan=   { lc='TAGSXX005TEXT', color={0,238/255,238/255}, },
        Blue=   { lc='TAGSXX006TEXT', color={24/255,116/255,205/255}, },
        Purple= { lc='TAGSXX007TEXT', color={186/255,85/255,211/255}, },
        Magenta={ lc='TAGSXX008TEXT', color={1,0,1}, },
        Black=  { lc='TAGSXX009TEXT', color={0,0,0}, },
        White=  { lc='TAGSXX010TEXT', color={1,1,1}, },
        Grey=   { lc='TAGSXX011TEXT', color={.5,.5,.5}, },
        Brown=  { lc='TAGSXX012TEXT', color={139/255,69/255,19/255}, },
		Beige=  { lc='TAGSXX032TEXT', color={216/255,176/255,150/255}, },
        Gold=   { lc='TAGSXX033TEXT', color={255/255,200/255,10/255}, },
    },
    Material={
        Stone={ lc='TAGSXX013TEXT', },
        Steel={ lc='TAGSXX014TEXT', },
        Wood={ lc='TAGSXX015TEXT', },
        Rubber={ lc='TAGSXX029TEXT', },
        Velvet={ lc='TAGSXX030TEXT', },
    },
    Texture={
        Fuzzy={ lc='TAGSXX016TEXT', },
        Bumpy={ lc='TAGSXX017TEXT', },
        Sticky={ lc='TAGSXX018TEXT', },
        Spiky={ lc='TAGSXX019TEXT', },
        Smooth={ lc='TAGSXX031TEXT', },
    },
    Shape={
        Round={ lc='TAGSXX020TEXT', },
        Flat={ lc='TAGSXX021TEXT', },
        Square={ lc='TAGSXX022TEXT', },
        Conical={ lc='TAGSXX023TEXT', },
    },
    Style={
        Elegant={ lc='TAGSXX024TEXT', },
        Bizarre={ lc='TAGSXX025TEXT', },
        Gaudy={ lc='TAGSXX026TEXT', },
        Punk={ lc='TAGSXX027TEXT', },
        Hip={ lc='TAGSXX028TEXT', },
    },
}

InventoryData.sDefaultPickup = 'TransientCrate'
InventoryData.nDefaultMaxStacks = 20

InventoryData.tTemplates=
{
    -- bHeldOnly: can't go into backpack. If in inv must be in hands.
    -- bDisappearOnDrop: if you drop it it goes poof
    -- bSatisfier: advertise for HeldItem prereq purposes
    -- bStuff: is innately desirable to characters, who may choose to collect it and possibly display it if bDisplayable.
    -- bDisplayable: can be displayed on a shelf.
    -- Job: If a prereq satisfier, then will only be picked up by characters with this job.
    --      If a stuff, will be much more attractive to this profession, and less attractive to characters outside the profession.
    -- bSingleton: don't collect more than one object with this template.
    
    -- DISAPPEAR ON DROP + HELD-ONLY
    FryingPan=
    {
        bHeldOnly=true,
        bDisappearOnDrop=true,
        Pickup='FryingPan',
        sName='PROPSX035TEXT',
        sDesc='PROPSX036TEXT',
    },
    FoodBar=
    {
        bHeldOnly=true,
        bDisappearOnDrop=true,
        Pickup='FoodBar',
        sName='PROPSX035TEXT',
        sDesc='PROPSX036TEXT',
    },
    CookedMeal=
    {
        bHeldOnly=true,
        bDisappearOnDrop=true,
        Pickup='CookedMeal',
        sName='PROPSX044TEXT',
        sDesc='PROPSX045TEXT',
    },

    -- HELD-ONLY
    Rock=
    {
        sName='PROPSX023TEXT',
        sDesc='PROPSX024TEXT',
        bHeldOnly=true,
        Pickup='Rock',
        Job=Character.MINER,
        bStackable=true,
        nMaxStacks=6,
        bSatisfier=true,
		-- tags
		Texture='Bumpy',
		Color='Brown',
		Material='Stone',
    },
    Corpse=
    {
        bHeldOnly=true,
        Pickup='Corpse',
        Job=Character.JANITOR,
        bSatisfier=true,
        sName='PROPSX082TEXT',
        sDesc='PROPSX083TEXT',
		Color='Blue',
    },
    ResearchDatacube=
    {
        sName='PROPSX070TEXT',
        sDesc='PROPSX071TEXT',
        Pickup='TransientCrate',
        bHeldOnly=true,
        bDisplayable=true,
        sPortraitSprite = 'Env_Datacube',
        Job=Character.SCIENTIST,
        bSatisfier=true,
        nPortraitScl=1.2,
        nPortraitOffX=-100,
        nPortraitOffY=-200,
    },
    FoodCrate=
    {
        sName='PROPSX035TEXT',
        sDesc='PROPSX036TEXT',
        bContainer=true,
        bHeldOnly=true,
        Job=Character.BARTENDER,
        Pickup='TransientCrate',
		Shape='Square',
		Material='Steel',
    },

    -- FOOD
    Corn=
    {
        bStackable=true,
        sName='FOODSX001TEXT',
        Color='Yellow',
		Texture='Bumpy',
    },
    Pod=
    {
        bStackable=true,
        sName='FOODSX002TEXT',
        Shape='Round',
        Color='Brown',
		Texture='Sticky',
    },
    Glowfruit=
    {
        bStackable=true,
        sName='FOODSX003TEXT',
        Color='Cyan',
		Texture='Fuzzy',
    },
    CandyCane=
    {
        sName='FOODSX004TEXT',
        bStackable=true,
        Style='Gaudy',
    },

    -- Job Objects. JobObs.
	ArmorLevel0=
	{
        -- Extra bad armor for initial raiders.
        sName='INVOBJ019TEXT',
        sDesc='INVOBJ020TEXT',
        Job=Character.EMERGENCY,
        sOutfit='Level1',
        bDisappearOnDrop=true,
        nDodgeChance=.1,
        nDamageReduction=0.15,
        bJobTool=true,
	},
	ArmorLevel1=
	{
        sName='INVOBJ018TEXT',
        sDesc='INVOBJ021TEXT',
    
        Job=Character.EMERGENCY,
        sOutfit='Level1',
        bDisappearOnDrop=true,
        nDodgeChance=.15,
        nDamageReduction=0.35,
        bJobTool=true,
	},
	ArmorLevel2=
	{
        sName='INVOBJ015TEXT',
        sDesc='INVOBJ016TEXT',
    
        Job=Character.EMERGENCY,
        sOutfit='Level2',
        bDisappearOnDrop=true,
        nDodgeChance=.2,
        nDamageReduction=0.5,
        bJobTool=true,
	},
	ArmorLevel3=
	{
        sName='INVOBJ014TEXT',
        sDesc='INVOBJ017TEXT',
    
        bStuff=true,
        Job=Character.EMERGENCY,
        sOutfit='Level3',
        nDodgeChance=.25,
        nDamageReduction=0.65,
        bJobTool=true,
	},
	Pistol=
	{
        sName='INVOBJ022TEXT',
        sDesc='INVOBJ023TEXT',
    
        Job=Character.EMERGENCY,
        bJobTool=true,
        sStance = 'pistol',
        bDisappearOnDrop=true,
        nDamage = 15,
        nRange=18,
        nDamageType = Character.DAMAGE_TYPE.Laser,
	},
	KillbotRifle=
	{
        sName='INVOBJ024TEXT',
        sDesc='INVOBJ025TEXT',
    
        bDisappearOnDrop=true,
        nDamage = 20,
        nRange=18,
        nDamageType = Character.DAMAGE_TYPE.Laser,
	},
	LaserRifle=
	{
        sName='INVOBJ026TEXT',
        sDesc='INVOBJ027TEXT',
    
        Job=Character.EMERGENCY,
        bJobTool=true,
        sStance = 'rifle',
        bDisappearOnDrop=true,
        nDamage = 30,
        nRange=18,
        nDamageType = Character.DAMAGE_TYPE.Laser,
	},
	Stunner=
	{
        sName='INVOBJ028TEXT',
        sDesc='INVOBJ054TEXT',
    
        bDisappearOnDrop=true,
        Job=Character.EMERGENCY,
        bJobTool=true,
        sStance = 'stunner',
        nDamage = 15,
        nRange=3,
        nDamageType = Character.DAMAGE_TYPE.Stunner,
	},
	SuperStunner=
	{
        sName='INVOBJ028TEXT',
        sDesc='INVOBJ055TEXT',
    
        bStuff=true,
        Job=Character.EMERGENCY,
        tPossibleTags={'Color','Style','Texture'},
        bJobTool=true,
        sStance = 'stunner',
        nDamage = 30,
        nRange=6,
        nDamageType = Character.DAMAGE_TYPE.Stunner,
	},
	PlasmaRifle=
	{
        sName='INVOBJ030TEXT',
        sDesc='INVOBJ056TEXT',
    
        bStuff=true,
        Job=Character.EMERGENCY,
        tPossibleTags={'Color','Style','Texture'},
        bJobTool=true,
        sStance = 'rifle',
        nDamage = 45,
        nRange=18,
        nDamageType = Character.DAMAGE_TYPE.Laser,
	},
    -- Stops condition decay on an object for several minutes on maintain.
    -- See MaintainEnvObject.
    SuperMaintainer=
    {
        sName='INVOBJ031TEXT',
        sDesc='INVOBJ057TEXT',
    
        bStuff=true,
        Job=Character.TECHNICIAN,
        tPossibleTags={'Color','Style','Texture','Shape'},
        bJobTool=true,
    },
    -- Slows decay on built objects (see BuildEnvObject); builds at turbo even if level 2 not researched.
    SuperBuilder=
    {
        sName='INVOBJ032TEXT',
        sDesc='INVOBJ058TEXT',
    
        bStuff=true,
        Job=Character.BUILDER,
        tPossibleTags={'Color','Style','Texture','Shape'},
        bJobTool=true,
    },
    -- Miner gets more matter when returning a rock to the refinery.
    EfficientMiner=
    {
        sName='INVOBJ033TEXT',
        sDesc='INVOBJ059TEXT',
    
        bStuff=true,
        Job=Character.MINER,
        tPossibleTags={'Color','Style','Texture','Shape'},
        bJobTool=true,
    },
    -- Maintains as level 2 without research.
    -- Also, ages plant on maintain.
    SuperGreenThumb=
    {
        sName='INVOBJ034TEXT',
        sDesc='INVOBJ060TEXT',
    
        bStuff=true,
        Job=Character.BOTANIST,
        tPossibleTags={'Color','Style','Texture','Shape'},
        bJobTool=true,
    },
    -- Heals many more HP in field checkup.
    -- Improves diagnosis success rate in field checkup.
    SuperDoctorTool=
    {
        sName='INVOBJ035TEXT',
        sDesc='INVOBJ061TEXT',
    
        bStuff=true,
        Job=Character.DOCTOR,
        tPossibleTags={'Color','Style','Texture','Shape'},
        bJobTool=true,
    },
	--
    -- DECORATIONS (aka inventory aka things that can go on shelves)
	--
    AlarmClock=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffAlarmClock',
        sSuffix='INVOBJ041TEXT',
        sDesc='INVOBJ062TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Red',Shape='Square'},
    },
    Baseball=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffBaseball',
        sSuffix='INVOBJ042TEXT',
        sDesc='INVOBJ063TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='White',Shape='Round'},
    },
    Basketball=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffBasketball',
        sSuffix='INVOBJ043TEXT',
        sDesc='INVOBJ064TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Orange',Shape='Round'},
    },
    CandyBucket=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffCandyBucket',
        sSuffix='INVOBJ044TEXT',
        sDesc='INVOBJ065TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Orange',Shape='Round'},
    },
	CowSkull=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffCowSkull',
        sSuffix='INVOBJ012TEXT',
        sDesc='INVOBJ066TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='White'},
	},
	DeadGlobe=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffDeadEarthGlobe',
        sSuffix='INVOBJ037TEXT',
        sDesc='INVOBJ067TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Brown',Shape='Round'},
	},
	Ducky=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffDucky',
        sSuffix='INVOBJ009TEXT',
        sDesc='INVOBJ069TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Yellow'},
	},
	Globe=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffEarthGlobe',
        sSuffix='INVOBJ046TEXT',
        sDesc='INVOBJ068TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Green',Shape='Round'},
	},
	GardenGnome=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffGnome',
        sTintSprite='StuffGnome_tint',
        sSuffix='INVOBJ038TEXT',
        sDesc='INVOBJ070TEXT',
        tPossibleTags={'Color','Style','Texture','Material'},
		tForcedTags={Shape='Conical'},
	},
	HumanSkull=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffHumanSkull',
        sSuffix='INVOBJ012TEXT',
        sDesc='INVOBJ071TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Beige'},
	},
	Kitty=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffKitty',
        sTintSprite='StuffKitty_tint',
        sSuffix='INVOBJ003TEXT',
        sDesc='INVOBJ072TEXT',
        tPossibleTags={'Color','Style','Texture','Material'},
	},
	LavaLamp=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffLavalamp',
        sSuffix='INVOBJ039TEXT',
        sDesc='INVOBJ073TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Magenta',},
	},
	Cactus=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffLittleCactus',
        sSuffix='INVOBJ040TEXT',
        sDesc='INVOBJ074TEXT',
        tPossibleTags={'Style','Material'},
		tForcedTags={Color='Green',Texture='Spiky'},
	},
	MoaiHead=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffMoaiHead',
        sSuffix='INVOBJ047TEXT',
        sDesc='INVOBJ075TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Grey',},
	},
	ToySpacebus=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffModelSpacebus',
        sSuffix='INVOBJ048TEXT',
        sDesc='INVOBJ076TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Grey',},
	},
    Mug=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffMug',
        sTintSprite='StuffMug_tint',
        sSuffix='INVOBJ002TEXT',
        sDesc='INVOBJ077TEXT',
        tPossibleTags={'Color','Style','Texture','Material'},
    },
	MusicBox=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffMusicBox',
        sSuffix='INVOBJ049TEXT',
        sDesc='INVOBJ078TEXT',
        tPossibleTags={'Style','Texture','Material'},
	},
	OldComputer=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffOldComputer',
        sSuffix='INVOBJ010TEXT',
        sDesc='INVOBJ079TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Beige',},
	},
	PictureFrame=
	{
		bStuff=true,
        bDisplayable=true,
		tPortraitSprites={'StuffPictureFrame01','StuffPictureFrame02','StuffPictureFrame03'},
        sSuffix='INVOBJ050TEXT',
        sDesc='INVOBJ080TEXT',
        tPossibleTags={'Style','Material'},
		tForcedTags={Shape='Flat',},
	},
	PocketWatch=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffPocketWatch',
        sSuffix='INVOBJ011TEXT',
        sDesc='INVOBJ081TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Gold',Shape='Round',},
	},
	PuzzleCube=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffPuzzleCube',
        sSuffix='INVOBJ007TEXT',
        sDesc='INVOBJ082TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Gold',Shape='Square',},
	},
	Radio=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffRadio',
        sSuffix='INVOBJ004TEXT',
        sDesc='INVOBJ083TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Brown'},
	},
	TeddyBear=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffTeddyBear',
        sTintSprite='StuffTeddyBear_tint',
        sSuffix='INVOBJ005TEXT',
        sDesc='INVOBJ084TEXT',
        tPossibleTags={'Color','Style','Texture','Material'},
	},
	TentacleMonster=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffTentacleMonster',
        sSuffix='INVOBJ006TEXT',
        sDesc='INVOBJ085TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Blue'},
	},
    ToyBall=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffToyBall',
        sTintSprite='StuffToyBall_tint',
        sSuffix='INVOBJ001TEXT',
        sDesc='INVOBJ086TEXT',
        tPossibleTags={'Color','Style','Texture','Material'},
    },
    ParasiteActionFigure=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffToyParasite',
        sSuffix='INVOBJ051TEXT',
        sDesc='INVOBJ087TEXT',
        tPossibleTags={'Style','Texture','Material'},
    },
    LadyActionFigure=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffToySpacelady',
        sSuffix='INVOBJ052TEXT',
        sDesc='INVOBJ088TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Purple'},
    },
    GuyActionFigure=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffToySpaceman',
        sSuffix='INVOBJ052TEXT',
        sDesc='INVOBJ089TEXT',
        tPossibleTags={'Style','Texture','Material'},
    },
    WizardActionFigure=
    {
        bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffToyWizard',
        sSuffix='INVOBJ053TEXT',
        sDesc='INVOBJ091TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Grey'},
    },
	Fossil=
	{
		bStuff=true,
        bDisplayable=true,
        sPortraitSprite='StuffTrilobiteFossil',
        sSuffix='INVOBJ013TEXT',
        sDesc='INVOBJ090TEXT',
        tPossibleTags={'Style','Texture','Material'},
		tForcedTags={Color='Beige'},
	},
}

function InventoryData.recalcStuffNames()
    InventoryData.tStuffNames = {}
    for k,v in pairs(InventoryData.tTemplates) do
        if v.bStuff then
            table.insert(InventoryData.tStuffNames,k)
        end
    end
end
InventoryData.recalcStuffNames()

return InventoryData
