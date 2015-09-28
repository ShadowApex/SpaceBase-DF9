local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.1 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

return 
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
        offsetX = 0,
        offsetY = 0,
    },
	tExtraInfo =
	{
		-- padding between buttons
		nMarginY = 12,
	},
    tElements =
    {       
        {
            key = 'Button',
            type = 'onePixelButton',
            pos = { 10, -40}, -- 10, -40
            scale = { 400, 60 }, --400, 60
            color = Gui.RED,
            hidden = true,
            clickWhileHidden = true,
            onHoverOn =
            {
                {
                    key = 'StarBG',
                    hidden = false
                },
                {
                    key = 'DutyButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'DutyButtonLabelBG',
                    color = Gui.AMBER,
                },
                {
                    key = 'ButtonLabel',
                    color = {0,0,0},
                },
                {
                    key = 'ButtonDescription',
                    color = {0,0,0},
                },                
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'StarBG',  
                    hidden = true
                },
                {
                    key = 'DutyButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'DutyButtonLabelBG',
                    color = Gui.AMBER_OPAQUE,
                },
                {
                    key = 'ButtonLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'ButtonDescription',
                    color = Gui.AMBER,
                },                
            },
        },  
        {
            key = 'StarBG',
            type = 'onePixel',
            pos = { 224, -41 },
            scale = { 120, 59 }, --120, 59
            color = { 0, 0, 0 },
            hidden = true,
			layerOverride = 'UIScrollLayerLeft',--none
        },
        { --whole button picture
            key = 'DutyButton',
            type = 'uiTexture',
            textureName = 'ui_inspector_dutybutton',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 10, -40 },
            scale = { 0.91, 1 }, -- 1,1
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },   
        {
            key = 'DutyButtonLabelBG',
            type = 'uiTexture',
            textureName = 'ui_inspector_dutybuttonlabel',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 60, -41 }, --60,-40
            scale = { 1, 1.01 }, -- 1,1
            color = Gui.AMBER_OPAQUE,
            layerOverride = 'UIScrollLayerLeft',
        },        
        { -- job title
            key = 'ButtonLabel',
            type = 'textBox',
            pos = { -180, -40 }, -- -180,-40
            text = "ERROR",
            style = 'dosissemibold30',
            rect = { 0, 200, 400, 0 }, -- 0, y, x, 0
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
        { -- desc of the job
            key = 'ButtonDescription',
            type = 'textBox',
            pos = { -180, -74 },
            text = "ERROR",
            style = 'dosissemibold16',
            rect = { 0, 300, 400, 0 },--0,300,400,0
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
             
        -- prop labels
        {
            key = 'PropDescription',
            type = 'textBox',
            pos = { 366, -54 }, --366,54
            text = "",
            style = 'dosissemibold30',
            rect = { 0, 300, 400, 0 }, --0,300,400,0
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
            layerOverride = 'UIScrollLayerLeft',
        },
        --duty icon
        {
            key = 'DutyIcon',
            type = 'uiTexture',
            textureName = 'ui_jobs_iconJobBarkeep',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { 23, -55 }, --23,-55
            scale = { 1, 1 }, --1,1
            color = Gui.AMBER,
            hidden = false,
			layerOverride = 'UIScrollLayerLeft', --none
        },
        {
            key = 'SkillIcon',
            type = 'uiTexture',
            textureName = 'ui_icon_friend',
            sSpritesheetPath = 'UI/Inspector',
            pos = { 305, -55 }, --345, -55
            scale = { 1.25, 1.25 }, --1.25,1.25
            color = { 0, 0, 0},
            hidden = false,
			layerOverride = 'UIScrollLayerLeft', --none
        },      
        {
            key = 'NumText',
            type = 'textBox',
            pos = { 102, -48 }, --122, -48
            text = "1",
            style = 'dosissemibold35',
            rect = { 0, 300, 490, 0 }, --0, 300, 500, 0
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
            layerOverride = 'UIScrollLayerLeft',
        },
        {
            key = 'StarsIcon',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { 175, -40 }, --175,-40
            scale = { 1, 1 },
            color = Gui.AMBER,
            hidden = false,
			layerOverride = 'UIScrollLayerLeft', --none
        },
        {
            key = 'AffIcon',
            type = 'uiTexture',
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
            pos = { 275, -52 }, --280, 52
            scale = { 1, 1 }, --1, 1
            color = Gui.AMBER,
            hidden = false,
			layerOverride = 'UIScrollLayerLeft', --none
        },
    },
}
