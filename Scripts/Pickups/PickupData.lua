local Character=require('CharacterConstants')
local PickupData = {}

PickupData.tObjects=
{
    Rock=
    {
        width=1,
        height=1,
        margin=0,
		customClass='Pickups.Rock',
        spriteName='rock',
        friendlyNameLinecode='PROPSX023TEXT',
        description='PROPSX024TEXT',
        sRigPath='Props/Asteroid/AsteroidChunk/Rig/AsteroidChunk.rig',
		sTexture='Props/Asteroid/AsteroidChunk/Textures/AsteroidChunk01',
        tOffsetPosition = {0.09,0.05,-0.02},
        tOffsetRotation = {0,0,0},
		tSpacesuitOffsetPosition = {-.03,0,.22},
		tSpacesuitOffsetRotation = {0,0,0},
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_Rock',
        bLeaveEnvObject=true,
		bCanDemolish=false,
    },
    TransientCrate=
    {
        width=1,
        height=1,
        margin=0,
        spriteName='foodcrate',
        bUseItemNameAndDesc=true,
        friendlyNameLinecode='PROPSX035TEXT',
        description='PROPSX036TEXT',
        sRigPath='Props/Crates/FoodCrate/Rig/FoodCrate.rig',
		sTexture='Props/Crates/FoodCrate/Textures/FoodCrate',
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_Foodcrate',
        bRemoveOnEmpty=true,
        bUseDisplaySpriteAsPropSprite=true,
        tDisplaySlots=
        {
            {x=-140,y=-75,z=10},
--            {x=-145,y=180,z=10},
        },
    },
    CookedMeal=
    {
        width=1,
        height=1,
        margin=0,
        friendlyNameLinecode='PROPSX044TEXT',
        description='PROPSX045TEXT',
        sRigPath='Props/FoodItems/FoodTray/Rig/FoodTray.rig',
		sTexture='Props/FoodItems/Textures/fooditems',
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_Rock',
        bNoSave=true,
        bLeaveEnvObject=false,
    },
    FryingPan=
    {
        width=1,
        height=1,
        margin=0,
        friendlyNameLinecode='PROPSX035TEXT',
        description='PROPSX036TEXT',
		sRigPath='Props/FoodItems/FryingPan/Rig/FryingPan.rig',
		sTexture='Props/FoodItems/Textures/fooditems',
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_Rock',
        bNoSave=true,
        bLeaveEnvObject=false,
    },
    FoodBar=
    {
        width=1,
        height=1,
        margin=0,
        friendlyNameLinecode='PROPSX035TEXT',
        description='PROPSX036TEXT',
        sRigPath='Props/FoodItems/FoodBar/Rig/FoodBar.rig',
		sTexture='Props/FoodItems/Textures/fooditems',
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_Rock',
        bNoSave=true,
        bLeaveEnvObject=false,
    },
    ResearchDatacube=
    {
        width=1,
        height=1,
        margin=0,
        spriteName='data_pickup',
        bUseItemNameAndDesc=true,
        bHasResearchData=true,
        sRigPath='Props/Crates/FoodCrate/Rig/FoodCrate.rig',
		sTexture='Props/Crates/FoodCrate/Textures/FoodCrate',
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_Datacube',
		bCanDemolish=false,
        bRemoveOnEmpty=true,
    },
    Corpse=
    {
        width=1,
        height=1,
        margin=0,
		customClass='Pickups.Corpse',
		bDontShowBuilderData=true,
        friendlyNameLinecode='PROPSX082TEXT',
        description='PROPSX083TEXT',
        sRigPath='Props/Tools/BodyBag/Rig/BodyBag.rig',
		sTexture='Props/Tools/BodyBag/Textures/BodyBag01',
        tOffsetPosition = {0.09, 0.05, -0.02},
        tOffsetRotation = {0,0,0},
		tSpacesuitOffsetPosition = {-.03,0,.22},
		tSpacesuitOffsetRotation = {0,0,0},
        tScale = {1,1,1},
        sTargetAttachJointName = 'Rt_Prop',
        portrait = 'Env_BodyBag',
        bLeaveEnvObject=true,
		bCanDemolish=false,
		-- dead bodies = icky, makes citizens unhappy
		nMoraleScore=-20,
		sCustomCarryAnim='carry_walk_corpse',
		sCustomBreatheAnim='carry_breathe_corpse',
		bDrawRigOnGround=true,
        tGroundOffsetPosition = { 0.09, 0.05, -0.02 },
		tGroundRotation = { -30, -30, -45 },
		tGroundScale = { 0.5, 0.5 },
    },
}

for k,v in pairs(PickupData.tObjects) do
    v.bPickup = true
    v.noRoom = true
    v.bInventory = true
end

return PickupData
