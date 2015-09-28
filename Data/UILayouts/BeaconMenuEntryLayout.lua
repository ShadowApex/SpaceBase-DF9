local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight = 400, 50

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
            key = 'NameButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'NameButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'NameLabel',
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
                    key = 'NameButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'NameLabel',
                    color = Gui.AMBER,
                },
				{ 
					key = 'Hotkey', 
					color = Gui.AMBER,
				},
            },
        },
		{
            key = 'NameLabel',
            type = 'textBox',
            pos = { 50, 0 },
            text = "I'm a Turkey!",
            style = 'dosissemibold35',
            rect = { 0, 50, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'Hotkey',
            type = 'textBox',
            pos = { 10, 0 },
            text = '0',
            style = 'dosissemibold22',
            rect = { 0, 50, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
	},
}