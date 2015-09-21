local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BLACK = { Gui.BLACK[1], Gui.BLACK[2], Gui.BLACK[3], 1 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local CONSTRUCT_CANCEL = Gui.RED
local CONSTRUCT_CONFIRM = Gui.GREEN

local nButtonWidth, nButtonHeight  = 330, 68
local nButtonStartY = 278
local nIconX, nIconStartY = 20, -280
local nLabelX, nLabelStartY =  105, -288
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -330
local nIconScale = .6
local numButtons = 12
local nCancelIconStartY = -82
local nCancelLabelStartY = -90
local nCancelHotkeyY = -130
local nBGWidth = 160

return 
{
    posInfo =
        {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
        scale = { 1, 1 },
    },
    tExtraInfo =
    {
        onShowMatterCost =
        {
            {
                key = 'CostBackground',
                hidden = false,
            },
            {
                key = 'CostBackgroundEndCap',
                hidden = false,
            },
            {
                key = 'CostVerticalRule',
                hidden = false,
            },
            {
                key = 'CostIconMatter',
                hidden = false,
            },
            {
                key = 'CostText',
                hidden = false,
            },
        },
        onHideMatterCost =
        {
            {
                key = 'CostBackground',
                hidden = true,
            },
            {
                key = 'CostBackgroundEndCap',
                hidden = true,
            },
            {
                key = 'CostVerticalRule',
                hidden = true,
            },
            {
                key = 'CostIconMatter',
                hidden = true,
            },
            {
                key = 'CostText',
                hidden = true,
            },            
        },
    }, 
    tElements =
    {       
        {
            key = 'LargeBar',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonStartY + (numButtons * nButtonHeight) },
            color = Gui.SIDEBAR_BG,
        },
			 --[[ {
            key = 'ScrollPane',
            type = 'scrollPane',
            pos = { 0, nButtonStartY },
            rect = { 0, 0, nButtonWidth, 'g_GuiManager.getUIViewportSizeY() - 280)' },
			
        },
		--]]
        {
            key = 'BackButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'BackButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'BackButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'BackButton',
                    color = AMBER,
                },
                {
                    key = 'BackLabel',
                    color = { 0, 0, 0 },
                },          
                {
                    key = 'BackHotkey',
                    color = { 0, 0, 0 },                    
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'BackButton',
                    color = BLACK,
                },
                {
                    key = 'BackLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'BackHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'CancelButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onHoverOn =
            {
                {
                    key = 'CancelButton',
                    color = CONSTRUCT_CANCEL,
                },
                {
                    key = 'CancelIcon',
                    color = { 0, 0, 0 },
                },   
                {
                    key = 'CancelLabel',
                    color = { 0, 0, 0 },
                },          
                {
                    key = 'CancelHotkey',
                    color = { 0, 0, 0 },                    
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'CancelButton',
                    color = BLACK,
                },
                {
                    key = 'CancelIcon',
                    color = CONSTRUCT_CANCEL,
                },   
                {
                    key = 'CancelLabel',
                    color = CONSTRUCT_CANCEL,
                },
                {
                    key = 'CancelHotkey',
                    color = CONSTRUCT_CANCEL,
                },
            },
        },
        {
            key = 'ConfirmButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight * 2 },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'ConfirmButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ConfirmButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'ConfirmButton',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'ConfirmLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ConfirmIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'ConfirmHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostBackground',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostBackgroundEndCap',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostVerticalRule',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostIconMatter',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostText',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ConfirmButton',
                    color = BLACK,
                },
                {
                    key = 'ConfirmLabel',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'ConfirmIcon',
                    color = CONSTRUCT_CONFIRM,
                },  
                {
                    key = 'ConfirmHotkey',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostBackground',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostBackgroundEndCap',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CostVerticalRule',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostIconMatter',
                    color = CONSTRUCT_CONFIRM,
                },
                {
                    key = 'CostText',
                    color = CONSTRUCT_CONFIRM,
                },
            },
        },
        {
            key = 'AllButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonStartY },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'AllButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'AllButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'AllButton',
                    color = AMBER,
                },
                {
                    key = 'AllLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'AllIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'AllHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'AllButton',
                    color = BLACK,
                },
                {
                    key = 'AllLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'AllIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'AllHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'AirlockButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'AirlockButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'AirlockButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'AirlockButton',
                    color = AMBER,
                },
                {
                    key = 'AirlockLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'AirlockIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'AirlockHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'AirlockButton',
                    color = BLACK,
                },
                {
                    key = 'AirlockLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'AirlockIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'AirlockHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'ReactorButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 2*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'ReactorButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ReactorButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'ReactorButton',
                    color = AMBER,
                },
                {
                    key = 'ReactorLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ReactorIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'ReactorHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ReactorButton',
                    color = BLACK,
                },
                {
                    key = 'ReactorLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'ReactorIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'ReactorHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'GardenButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 3*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'GardenButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'GardenButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'GardenButton',
                    color = AMBER,
                },
                {
                    key = 'GardenLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'GardenIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'GardenHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'GardenButton',
                    color = BLACK,
                },
                {
                    key = 'GardenLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'GardenIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'GardenHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'LifeSupportButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 4*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'LifeSupportButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'LifeSupportButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'LifeSupportButton',
                    color = AMBER,
                },
                {
                    key = 'LifeSupportLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'LifeSupportIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'LifeSupportHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'LifeSupportButton',
                    color = BLACK,
                },
                {
                    key = 'LifeSupportLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'LifeSupportIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'LifeSupportHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'PubButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 5*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'PubButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'PubButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'PubButton',
                    color = AMBER,
                },
                {
                    key = 'PubLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'PubIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'PubHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'PubButton',
                    color = BLACK,
                },
                {
                    key = 'PubLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'PubIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'PubHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'RefineryButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 6*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'RefineryButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'RefineryButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'RefineryButton',
                    color = AMBER,
                },
                {
                    key = 'RefineryLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'RefineryIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'RefineryHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'RefineryButton',
                    color = BLACK,
                },
                {
                    key = 'RefineryLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'RefineryIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'RefineryHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'ResidenceButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 7*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'ResidenceButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ResidenceButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'ResidenceButton',
                    color = AMBER,
                },
                {
                    key = 'ResidenceLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ResidenceIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'ResidenceHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ResidenceButton',
                    color = BLACK,
                },
                {
                    key = 'ResidenceLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'ResidenceIcon',
                    color = Gui.AMBER,
                },  
                {
                    key = 'ResidenceHotkey',
                    color = Gui.AMBER,
                },
            },
        },		
        {
            key = 'FitnessButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 8*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'FitnessButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'FitnessButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'FitnessButton',
                    color = AMBER,
                },
                {
                    key = 'FitnessLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'FitnessIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'FitnessHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'FitnessButton',
                    color = BLACK,
                },
                {
                    key = 'FitnessLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'FitnessIcon',
                    color = Gui.AMBER,
                },
                {
                    key = 'FitnessHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'ResearchButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 9*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'ResearchButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ResearchButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'ResearchButton',
                    color = AMBER,
                },
                {
                    key = 'ResearchLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ResearchIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'ResearchHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ResearchButton',
                    color = BLACK,
                },
                {
                    key = 'ResearchLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'ResearchIcon',
                    color = Gui.AMBER,
                },
                {
                    key = 'ResearchHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'InfirmaryButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 10*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'InfirmaryButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'InfirmaryButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'InfirmaryButton',
                    color = AMBER,
                },
                {
                    key = 'InfirmaryLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'InfirmaryIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'InfirmaryHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'InfirmaryButton',
                    color = BLACK,
                },
                {
                    key = 'InfirmaryLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'InfirmaryIcon',
                    color = Gui.AMBER,
                },
                {
                    key = 'InfirmaryHotkey',
                    color = Gui.AMBER,
                },
            },
        },
		{
            key = 'CommandButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonStartY + 11*nButtonHeight) },
            scale = { nButtonWidth, nButtonHeight },
            color = BLACK,
            onPressed =
            {
                {
                    key = 'CommandButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'CommandButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'CommandButton',
                    color = AMBER,
                },
                {
                    key = 'CommandLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'CommandIcon',
                    color = { 0, 0, 0 },
                },                
                {
                    key = 'CommandHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'CommandButton',
                    color = BLACK,
                },
                {
                    key = 'CommandLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'CommandIcon',
                    color = Gui.AMBER,
                },
                {
                    key = 'CommandHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'CancelIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_decline',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nCancelIconStartY },
            color = CONSTRUCT_CANCEL,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'ConfirmIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_confirm',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nCancelIconStartY - nButtonHeight },
            color = CONSTRUCT_CONFIRM,
            scale = { nIconScale, nIconScale }
        },
        {
            key = 'AllIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_object',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'AirlockIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_airlock',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
--[[
        {
            key = 'DoorsIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_door',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 2) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
]]--
        {
            key = 'ReactorIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_reactor',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 2) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'GardenIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_garden',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 3) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'LifeSupportIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_lifesupport',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 4) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'PubIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_pub',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 5) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'RefineryIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_refineryAlt',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 6) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'ResidenceIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_residence',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 7) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'FitnessIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_fitness',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 8) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'ResearchIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_research',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 9) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'InfirmaryIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_infirmary',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 10) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
		{
            key = 'CommandIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_infirmary',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 11) },
            color = Gui.AMBER,
            scale = { nIconScale, nIconScale},
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -244 },
            linecode = "HUDHUD024TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'BackLabel',
            type = 'textBox',
            pos = { nLabelX, -10 },            
            linecode = 'HUDHUD009TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'CancelLabel',
            type = 'textBox',
            pos = { nLabelX, nCancelLabelStartY },
            linecode = 'HUDHUD034TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CANCEL,
        },
        {
            key = 'ConfirmLabel',
            type = 'textBox',
            pos = { nLabelX, nCancelLabelStartY - nButtonHeight },
            linecode = 'HUDHUD019TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CONFIRM,
        },
        {
            key = 'AllLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'ZONEUI058TEXT', --all
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AirlockLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight },
            linecode = 'ZONEUI036TEXT', -- airlock
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
--[[
        {
            key = 'DoorsLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 2) },
            linecode = 'HUDHUD038TEXT', -- doors
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
]]--
        {
            key = 'ReactorLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 2) },
            linecode = 'ZONEUI003TEXT', -- reactor
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'GardenLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 3) },
            linecode = 'ZONEUI069TEXT', -- doors
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'LifeSupportLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 4) },
            linecode = 'ZONEUI001TEXT', -- lifesupport
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'PubLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 5) },
            linecode = 'ZONEUI046TEXT', -- pub
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'RefineryLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 6) },
            linecode = 'ZONEUI037TEXT', -- refinery
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResidenceLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 7) },
            linecode = 'ZONEUI042TEXT', -- residence
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'FitnessLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 8) },
            linecode = 'ZONEUI109TEXT', -- fitness
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResearchLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 9) },
            linecode = 'ZONEUI126TEXT', -- research
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'InfirmaryLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 10) },
            linecode = 'ZONEUI049TEXT', -- infirmary
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'CommandLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 11) },
            linecode = 'COMMAND001TEXT', -- infirmary
            style = 'dosisregular40',
            rect = { 0, 300, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BackHotkey',
            type = 'textBox',
            pos = { nHotkeyX - 4, -50 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'CancelHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nCancelHotkeyY },
            text = 'X',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CANCEL,
        },
        {
            key = 'ConfirmHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nCancelHotkeyY - nButtonHeight },
            text = 'C',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = CONSTRUCT_CONFIRM
        },
        {
            key = 'AllHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY },
            text = 'Z',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AirlockHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight },
            text = 'A',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
--[[
        {
            key = 'DoorsHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 2) },
            text = 'D',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
]]--
        {
            key = 'ReactorHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 2) },
            text = 'T',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'GardenHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 3) },
            text = 'G',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'LifeSupportHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 4) },
            text = 'S',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'PubHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 5) },
            text = 'B',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'RefineryHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 6) },
            text = 'F',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResidenceHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 7) },
            text = 'R',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'FitnessHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 8) },
            text = 'N',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResearchHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 9) },
            text = 'H',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'InfirmaryHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 10) },
            text = 'I',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'CommandHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 11) },
            text = 'v',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SelectionHighlight',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = SELECTION_AMBER,
            hidden = true,
        },
        -- cost submenu
        {
            key = 'CostBackground',
            type = 'onePixel',
            pos = { nButtonWidth, -nButtonHeight * 2 },
            scale = { nBGWidth, nButtonHeight },
            color = CONSTRUCT_CONFIRM,
        },    
        {
            key = 'CostBackgroundEndCap',
            type = 'uiTexture',
            textureName = 'ui_confirm_endcap',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + nBGWidth - 1, -nButtonHeight * 2 },
            color = CONSTRUCT_CONFIRM,
        },   
        {
            key = 'CostVerticalRule',
            type = 'uiTexture',
            textureName = 'ui_confirm_verticalrule',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth, -(nButtonHeight * 2) - 4 },
            color = { 0, 0, 0 },
        },     
        {
            key = 'CostIconMatter',
            type = 'uiTexture',
            textureName = 'ui_confirm_iconmatter',
            sSpritesheetPath = 'UI/Shared',
            pos = { nButtonWidth + 10, -(nButtonHeight * 2) - 10 },
            color = { 0, 0, 0 },
        },   
        {
            key = 'CostText',
            type = 'textBox',
            pos = { nButtonWidth + 34, -(nButtonHeight * 2) - 4 },
            text = "-450 Build\n+75 Demolish\n+36 Undo",
            style = 'dosissemibold18',
            rect = { 0, 100, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        {
            key = 'SidebarBottomEndcapExpanded',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { 0, -(nButtonStartY + numButtons*nButtonHeight) + 1 },
            scale = { 1.28, 1.28 },            
            color = Gui.SIDEBAR_BG,
        },
    },
}
