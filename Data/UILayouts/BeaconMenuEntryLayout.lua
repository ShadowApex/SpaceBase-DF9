local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight = 400, 100

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
                    key = 'SizeLabel',
                    color = Gui.BLACK,
                },
				{
                    key = 'StatusLabel',
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
				{
                    key = 'SizeLabel',
                    color = Gui.AMBER,
                },
				{
                    key = 'StatusLabel',
                    color = Gui.AMBER,
                },
            },
        },
		{
            key = 'NameLabel',
            type = 'textBox',
            pos = { 100, 0 },
            text = "I'm a Turkey!",
            style = 'dosissemibold35',
            rect = { 0, nButtonHeight - 50, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'Hotkey',
            type = 'textBox',
            pos = { nButtonWidth - 25, -nButtonHeight + 40 },
            text = '0',
            style = 'dosissemibold22',
            rect = { 0, 50, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'SizeLabel',
            type = 'textBox',
            pos = { 100, -nButtonHeight + 40 },
            text = "Size: 0",
            style = 'dosissemibold20',
            rect = { 0, 50, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'StatusLabel',
            type = 'textBox',
            pos = { nButtonWidth / 2 + 10, -nButtonHeight + 40 },
            text = "Status: Available",
            style = 'dosissemibold20',
            rect = { 0, 50, 150, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
	},
}