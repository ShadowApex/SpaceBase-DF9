local Gui = require('UI.Gui')

local nButtonWidth, nButtonHeight  = 400, 64 -- 330, 81
local nTextHeight = nButtonHeight
local nButtonStartY = -134
local nIconX, nIconStartY = 10, -136
local nDoneIconStartY = -2
local nLabelX, nLabelStartY = 30, -138 -- 94, -144
local nLabelNoIconX, nLabelButtonStartY = 10, -10
local nDoneLabelStartY = -10
local nHotkeyX, nHotkeyStartY = -75, -155 -- nButtonWidth - 112, -180
local nDoneHotkeyY = -46
local nIconScale = .6
local numButtons = 15
local nBGWidth = 160
local nCreateButtonX, nCreateButtonY = 0, -1064
local nLargeBarHeight = -nButtonStartY + (nButtonHeight * numButtons)

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
            pos = { 20, 0 },
            scale = { nButtonWidth,  nLargeBarHeight},
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'DoneButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight + 10 },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'DoneButton', color = Gui.AMBER, },
                { key = 'DoneLabel', color = Gui.BLACK, },
                { key = 'DoneHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'DoneButton', color = Gui.BLACK, },
                { key = 'DoneLabel', color = Gui.AMBER, },
                { key = 'DoneHotkey', color = Gui.AMBER, },
            },
        },
		{
            key = 'ScrollPane',
            type = 'scrollPane',
            pos = { 0, nButtonStartY },
            rect = { 0, 0, nButtonWidth, nLargeBarHeight - 400 },
			scissorLayerName='UIScrollLayerLeft',
        },
        {
            key = 'MenuSublabel',
            type = 'textBox',
            pos = { 40, -90 },
            linecode = "HUDHUD036TEXT",
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'DoneLabel',
            type = 'textBox',
            pos = { nLabelX, nDoneLabelStartY },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, 400, 200, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DoneHotkey',
            type = 'textBox',
            pos = { nHotkeyX + 20, nDoneHotkeyY + 10 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SidebarBottomEndcapExpanded',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { 0, nButtonStartY - numButtons * nButtonHeight },
            scale = { 1.28, 1.28 },
            color = Gui.SIDEBAR_BG,
        },
		{
            key = 'CreateSquadButton',
            type = 'onePixelButton',
            pos = { nCreateButtonX, nCreateButtonY },
            scale = { 400, 50 },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'CreateSquadButton', color = Gui.AMBER, },
                { key = 'CreateSquadLabel', color = Gui.BLACK, },
                { key = 'CreateSquadHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'CreateSquadButton', color = Gui.BLACK, },
                { key = 'CreateSquadLabel', color = Gui.AMBER, },
                { key = 'CreateSquadHotkey', color = Gui.AMBER, },
            },
        },
		{
            key = 'CreateSquadLabel',
            type = 'textBox',
            pos = { nCreateButtonX, nCreateButtonY },
            linecode = 'SQUAD008TEXT',
            style = 'dosisregular26',
            rect = { 0, 50, 400, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'CreateSquadHotkey',
            type = 'textBox',
            pos = { nCreateButtonX, nCreateButtonY - 20 },
            text = 'C',
            style = 'dosissemibold16',
            rect = { 0, 20, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
