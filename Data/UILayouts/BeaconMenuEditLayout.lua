local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight = 400, 50
local nButtonXStart = 100

return
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
		offsetX = 0,
        offsetY = 0,
    },
    tElements =
    {
		{
			key = '_',
			type = 'onePixel',
			pos = { 0, 0 },
			scale = { 100, 250 },
			color = Gui.BLACK,
		},
		{
			key = 'Arrow',
			type = 'uiTexture',
			textureName = 'Triangle',
            sSpritesheetPath = 'UI/BeaconMenu',
			pos = { 0, -74 },
			color = Gui.AMBER,
			scale = { 1.0, 1.0 },
		},
		{
            key = 'HighViolenceButton',
            type = 'onePixelButton',
            pos = { nButtonXStart, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'HighViolenceButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'HighViolenceLabel',
                    color = Gui.BLACK,
                },
				{ 
					key = 'HighViolenceHotkey', 
					color = Gui.BLACK,
				},
				{
					playSfx = 'hilight',
				},
            },
            onHoverOff =
            {
                {
                    key = 'HighViolenceButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'HighViolenceLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'HighViolenceHotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'HighViolenceLabel',
            type = 'textBox',
            pos = { nButtonXStart + 20, 0 },
            text = "Extreme Prejudice",
            style = 'dosisregular26',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'HighViolenceHotkey',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth - 25, 0 },
            text = 'R',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'MedViolenceButton',
            type = 'onePixelButton',
            pos = { nButtonXStart, -nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'MedViolenceButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'MedViolenceLabel',
                    color = Gui.BLACK,
                },
				{ 
					key = 'MedViolenceHotkey', 
					color = Gui.BLACK,
				},
				{
					playSfx = 'hilight',
				},
            },
            onHoverOff =
            {
                {
                    key = 'MedViolenceButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'MedViolenceLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'MedViolenceHotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'MedViolenceLabel',
            type = 'textBox',
            pos = { nButtonXStart + 20, -nButtonHeight },
            text = "Eleminate Hostiles",
            style = 'dosisregular26',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'MedViolenceHotkey',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth - 25, -nButtonHeight },
            text = 'F',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'LowViolenceButton',
            type = 'onePixelButton',
            pos = { nButtonXStart, -nButtonHeight * 2 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'LowViolenceButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'LowViolenceLabel',
                    color = Gui.BLACK,
                },
				{ 
					key = 'LowViolenceHotkey', 
					color = Gui.BLACK,
				},
				{
					playSfx = 'hilight',
				},
            },
            onHoverOff =
            {
                {
                    key = 'LowViolenceButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'LowViolenceLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'LowViolenceHotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'LowViolenceLabel',
            type = 'textBox',
            pos = { nButtonXStart + 20, -nButtonHeight * 2 },
            text = "Subdue/Capture",
            style = 'dosisregular26',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'LowViolenceHotkey',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth - 25, -nButtonHeight * 2 },
            text = 'V',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'NoViolenceButton',
            type = 'onePixelButton',
            pos = { nButtonXStart, -nButtonHeight * 3 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'NoViolenceButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'NoViolenceLabel',
                    color = Gui.BLACK,
                },
				{ 
					key = 'NoViolenceHotkey', 
					color = Gui.BLACK,
				},
				{
					playSfx = 'hilight',
				},
            },
            onHoverOff =
            {
                {
                    key = 'NoViolenceButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'NoViolenceLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'NoViolenceHotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'NoViolenceLabel',
            type = 'textBox',
            pos = { nButtonXStart + 20, -nButtonHeight * 3 },
            text = "Stand Down",
            style = 'dosisregular26',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'NoViolenceHotkey',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth - 25, -nButtonHeight * 3 },
            text = 'B',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'EditSquadButton',
            type = 'onePixelButton',
            pos = { nButtonXStart, -nButtonHeight * 4 },
            scale = { nButtonWidth / 2, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'EditSquadButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'EditSquadLabel',
                    color = Gui.BLACK,
                },
				{ 
					key = 'EditSquadHotkey', 
					color = Gui.BLACK,
				},
				{
					playSfx = 'hilight',
				},
            },
            onHoverOff =
            {
                {
                    key = 'EditSquadButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'EditSquadLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'EditSquadHotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'EditSquadLabel',
            type = 'textBox',
            pos = { nButtonXStart + 20, -nButtonHeight * 4 },
            text = "Edit Squad",
            style = 'dosisregular26',
            rect = { 0, nButtonHeight, nButtonWidth / 2, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'EditSquadHotkey',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth / 2 - 25, -nButtonHeight * 4 },
            text = 'X',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'DisbandSquadButton',
            type = 'onePixelButton',
            pos = { nButtonXStart + nButtonWidth / 2, -nButtonHeight * 4 },
            scale = { nButtonWidth / 2, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'DisbandSquadButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'DisbandSquadLabel',
                    color = Gui.BLACK,
                },
				{ 
					key = 'DisbandSquadHotkey', 
					color = Gui.BLACK,
				},
				{
					playSfx = 'hilight',
				},
            },
            onHoverOff =
            {
                {
                    key = 'DisbandSquadButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'DisbandSquadLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'DisbandSquadHotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'DisbandSquadLabel',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth / 2 + 20, -nButtonHeight * 4 },
            text = "Disband Squad",
            style = 'dosisregular26',
            rect = { 0, nButtonHeight, nButtonWidth / 2, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'DisbandSquadHotkey',
            type = 'textBox',
            pos = { nButtonXStart + nButtonWidth - 25, -nButtonHeight * 4 },
            text = 'Z',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
	},
}