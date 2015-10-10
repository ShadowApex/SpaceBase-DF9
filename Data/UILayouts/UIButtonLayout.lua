local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight = 330, 81
local nButtonX, nButtonY = 0, 0
local nLabelX, nLabelY = 50, 0
local nHotkeyX, nHotkeyY = nButtonWidth - 112, -46

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
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
        scale = { 1, 1 },
    },
    tElements =
    {
		{
            key = 'Button',
            type = 'onePixelButton',
            pos = { nButtonX, nButtonY },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'Button',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'Button',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'Button',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'Label',
                    color = Gui.BLACK,
                },
                {
                    key = 'Hotkey',
                    color = Gui.BLACK,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Button',
                    color = Gui.BLACK,
                },
                {
                    key = 'Label',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'Hotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
        {
            key = 'Label',
            type = 'textBox',
            pos = { nLabelX, nLabelY },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'Hotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyY },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = SELECTION_AMBER,
--			hidden = true,
        },
	},
}