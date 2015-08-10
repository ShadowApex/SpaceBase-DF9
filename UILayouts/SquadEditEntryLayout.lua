local Gui = require('UI.Gui')

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
            scale = { 400, 50 },
            color = { 0, 0, 0 },
            onHoverOn =
            {
                {
                    key = 'NameButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'NameLabel',
                    color = { 0, 0, 0 },
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
            },
        },
		{
            key = 'NameLabel',
            type = 'textBox',
            pos = { 0, 0 },
            text = "I'm a Turkey!",
            style = 'dosissemibold35',
            rect = { 0, 50, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
	},
}