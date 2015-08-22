local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local nButtonWidth, nButtonHeight  = 330, 81
local nButtonStartY = -123
local nLabelX, nLabelStartY = 105, -133
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -169
local nIconScale = .6
local numButtons = 2
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
    tElements =
    {       
        {
            key = 'LargeBar',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, -nButtonStartY + (nButtonHeight * numButtons) },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'DoneButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'DoneButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'DoneButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'DoneButton',
                    color = Gui.GREEN,
                },
                {
                    key = 'DoneLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'DoneHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'DoneButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'DoneLabel',
                    color = Gui.GREEN,
                },
                {
                    key = 'DoneHotkey',
                    color = Gui.GREEN,
                },
            },
        },
        {
            key = 'DoneLabel',
            type = 'textBox',
            pos = { nLabelX, -10 },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREEN,
        },
        {
            key = 'DoneHotkey',
            type = 'textBox',
            pos = { nHotkeyX, -46 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREEN
        },
		{
            key = 'ResearchButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
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
                    color = Gui.GREEN,
                },
                {
                    key = 'ResearchLabel',
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
                    color = Gui.BLACK,
                },
                {
                    key = 'ResearchLabel',
                    color = Gui.GREEN,
                },
                {
                    key = 'ResearchHotkey',
                    color = Gui.GREEN,
                },
            },
        },
        {
            key = 'ResearchLabel',
            type = 'textBox',
            pos = { 0, nButtonStartY },
            linecode = 'DEBUG002TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.GREEN,
        },
        {
            key = 'ResearchHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - 5 },
            text = '1.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.GREEN
        },
        {
            key = 'SidebarBottomEndcapExpanded',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { 0, nButtonStartY - numButtons*nButtonHeight },
            scale = { 1.28, 1.28 },            
            color = Gui.SIDEBAR_BG,
        },
    },
}