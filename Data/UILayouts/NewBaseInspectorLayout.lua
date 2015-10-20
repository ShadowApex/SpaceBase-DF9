local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local WIDTH = 550
local defaultTextStyle = 'dosissemibold28'
local textX = 1125
local boxX = 1100

return 
{
    posInfo =
        {
        alignX = 'right',
        alignY = 'top',
        offsetX = -1770,
        offsetY = 0,
        scale = { 1, 1 },
    },
    tExtraInfo =
    {
        tAccordionInfo =
        {
            ObjectStatsTab = { nInitX = 0, nInitY = -598, nFinalX = 0, nFinalY = -598 },
        },
    },
    tElements =
    {       
        {
            key = 'BlackBG',
            type = 'onePixel',
            pos = { boxX, -215 },
            scale = { WIDTH, 'g_GuiManager.getUIViewportSizeY()' },
            color = { 0, 0, 0, 0.75 },
        },
        {
            key = 'HeaderBG',
            type = 'onePixel',
            pos = { boxX, -215 },
            scale = { WIDTH, 151 },
            color = Gui.AMBER,
        },
        {
            key = 'ZoomedMap',
            type = 'uiTexture',
            textureName = 'galaxy_zoom01',
            sSpritesheetPath = 'UI/NewGame',
            pos = { boxX, 0 },
            color = Gui.AMBER,
        },
        -- Name
        {
            key = 'LabelName',
            type = 'textBox',
            pos = { textX, -225 },
            linecode = "NEWBAS007TEXT",
             style = 'dosisregular52',
            rect = { 0, 300, WIDTH - 50, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        {
            key = 'LabelAge',
            type = 'textBox',
            pos = { textX, -300 },
            linecode = "NEWBAS008TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        -- stats
        {
            key = 'StatsBG',
            type = 'onePixel',
            pos = { boxX, -352 },
            scale = { WIDTH, 195 },
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'LabelDensity',
            type = 'textBox',
            pos = { textX, -375 },
            linecode = "NEWBAS020TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'LabelDistance',
            type = 'textBox',
            pos = { textX, -415 },
            linecode = "NEWBAS010TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'LabelThreat',
            type = 'textBox',
            pos = { textX, -455 },
            linecode = "NEWBAS015TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'LabelInterference',
            type = 'textBox',
            pos = { textX, -495 },
            linecode = "NEWBAS016TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TextDensity',
            type = 'textBox',
            pos = { textX + 165, -375 },
            linecode = "NEWBAS020TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TextDistance',
            type = 'textBox',
            pos = { textX + 225, -415 },
            linecode = "NEWBAS010TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TextThreat',
            type = 'textBox',
            pos = { textX + 155, -455 },
            linecode = "NEWBAS015TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'TextInterference',
            type = 'textBox',
            pos = { textX + 248, -495 },
            linecode = "NEWBAS016TEXT",
            style = defaultTextStyle,
            rect = { 0, 300, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        --
        {
            key = 'FolderTop',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderTop',
            sSpritesheetPath = 'UI/Inspector',
            pos = { boxX, -547 },
            scale = { 1.315, 1.56 },
            color = Gui.AMBER_OPAQUE,
        },
        {
            key = 'FolderHeader',
            type = 'uiTexture',
            textureName = 'ui_inspector_folderActive',
            sSpritesheetPath = 'UI/Inspector',
            pos = { boxX, -547 },
            scale = { 1.315, 1.56 },
            color = Gui.AMBER,
        },
        {
            key = 'LabelFolder',
            type = 'textBox',
            pos = { textX + 10, -545 },
            linecode = "NEWBAS013TEXT",
            style = 'dosisregular52',
            rect = { 0, 300, 250, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.BLACK,
        },
        {
            key = 'FolderFooterBG',
            type = 'onePixel',
            pos = { boxX, -610 },
            scale = { WIDTH, 15 },
            color = Gui.AMBER,
        },
        {
            key = 'LabelHelpText',
            type = 'textBox',
            pos = { textX, -650 },
            linecode = "NEWBAS014TEXT",
            style = defaultTextStyle,
            rect = { 0, 900, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}