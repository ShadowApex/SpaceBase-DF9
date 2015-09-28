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
            rect = { 0, 0, nButtonWidth, '(g_GuiManager.getUIViewportSizeY() - 280)' },
        },
		{
            key = 'ThreatHighButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight * 10 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'ThreatHighButton', color = Gui.AMBER, },
                { key = 'ThreatHighLabel', color = Gui.BLACK, },
                { key = 'ThreatHighHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ThreatHighButton', color = Gui.BLACK, },
                { key = 'ThreatHighLabel', color = Gui.AMBER, },
                { key = 'ThreatHighHotkey', color = Gui.AMBER, },
            },
        },
		{
            key = 'ThreatHighLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight * 10 },
            linecode = 'SQUAD021TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'ThreatHighHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight * 10 },
            text = 'z.',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'ThreatMediumButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight * 11 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'ThreatMediumButton', color = Gui.AMBER, },
                { key = 'ThreatMediumLabel', color = Gui.BLACK, },
                { key = 'ThreatMediumHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ThreatMediumButton', color = Gui.BLACK, },
                { key = 'ThreatMediumLabel', color = Gui.AMBER, },
                { key = 'ThreatMediumHotkey', color = Gui.AMBER, },
            },
        },
		{
            key = 'ThreatMediumLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight * 11 },
            linecode = 'SQUAD022TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'ThreatMediumHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight * 11 },
            text = 'x.',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'ThreatLowButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight * 12 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'ThreatLowButton', color = Gui.AMBER, },
                { key = 'ThreatLowLabel', color = Gui.BLACK, },
                { key = 'ThreatLowHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ThreatLowButton', color = Gui.BLACK, },
                { key = 'ThreatLowLabel', color = Gui.AMBER, },
                { key = 'ThreatLowHotkey', color = Gui.AMBER, },
            },
        },
		{
            key = 'ThreatLowLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight * 12 },
            linecode = 'SQUAD023TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'ThreatLowHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight * 12 },
            text = 'c.',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'StandDownButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight * 13 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                { key = 'StandDownButton', color = Gui.AMBER, },
                { key = 'StandDownLabel', color = Gui.BLACK, },
                { key = 'StandDownHotkey', color = Gui.BLACK, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'StandDownButton', color = Gui.BLACK, },
                { key = 'StandDownLabel', color = Gui.AMBER, },
                { key = 'StandDownHotkey', color = Gui.AMBER, },
            },
        },
		{
            key = 'StandDownLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight * 13 },
            linecode = 'SQUAD024TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'StandDownHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight * 13 },
            text = 'v.',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
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
    },
}
