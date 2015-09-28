local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }

return 
{
    posInfo =
        {
        alignX = 'center',
        alignY = 'center',
        offsetX = 0,
        offsetY = 0,
        scale = { 1, 1 },
    },
    tElements =
    {
        {
            key = 'Background',
            type = 'onePixel',
            pos = { -777, 641 },
            scale = { 2568, 1444 },
            color = { 0, 0, 0, 0.83 },
            hidden = false,
        },
        {
            key = 'Logo',
            type = 'uiTexture',
            textureName = 'logo',
            sSpritesheetPath = 'UI/StartMenu',
            pos = { -1920/2, 1152/2 + 50 },
            scale = { 1.5, 1.5 },
            color = Gui.WHITE,
            hidden = false,
        },
        {
            key = 'HeaderText',
            type = 'textBox',
            pos = { -5, 200 },
            text = "LOAD AND SAVE BASE",
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.White,
        },
    },
}