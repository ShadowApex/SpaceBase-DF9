local Gui = require('UI.Gui')
local CharacterConstants = require('CharacterConstants')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }
local HIGHLIGHT_COLOR = { 0.1, 0.1, 0.1, 0.75 }

local nBGWidth = 1800

local nButtonWidth, nButtonHeight  = 286, 98
local nButtonStartY = -204
local nIconX, nIconStartY = 10, -12
local nLabelX, nLabelStartY = 105, -20
local nHotkeyX, nHotkeyStartY = nButtonWidth - 110, -68
local nIconScale = .6

local nTopLabelY = -206
local nTopLabelTextY = -154
local nTopBarHeight = 5
local nHighlightY = -110

local nBorderScale = 2
--local nJobColX = 10
--local nNameColX = 106
--local nSortTextureSize = 44

--local nJobColScale = 128
--local nJobBlockScale = 162
--local nJob1ColX = 554
--local nJob2ColX = nJob1ColX + nJobColScale
--local nJob3ColX = nJob1ColX + nJobColScale * 2
--local nJob4ColX = nJob1ColX + nJobColScale * 3
--local nJob5ColX = nJob1ColX + nJobColScale * 4
--local nJob6ColX = nJob1ColX + nJobColScale * 5
--local nJob7ColX = nJob1ColX + nJobColScale * 6
--local nJob8ColX = nJob1ColX + nJobColScale * 7
--local nJob9ColX = nJob1ColX + nJobColScale * 8

local nNameColX = 10
local nColScale = 200
local nSizeColX = 500
local nStatusColX = nSizeColX + nColScale
local nAssignColX = nSizeColX + nColScale * 2
local nDisbandColX = nSizeColX + nColScale * 3



--local nJobDivScl = 40
--local nJobLabelDivScl = 24
--local nJobCatLabelRectSize = nJobDivScl * 2 + nSortTextureSize
--local nJobLabelRectSize = nJobLabelDivScl * 2 + nSortTextureSize

--local nJobTextureXOffset = math.floor(nJobDivScl / 2) + 16
--local nJobTextureYOffset = nTopLabelTextY + 36

--local nJobNumXOffset = math.floor(nJobDivScl / 2) + 58
--local nJobNumYOffset = nTopLabelTextY + 40

local nSortHighlightScaleY = 90

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
            scale = { nBGWidth, 'g_GuiManager.getUIViewportSizeY()' },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'BGFade',
            type = 'uiTexture',
            textureName = 'grad64_left',
            sSpritesheetPath = 'UI/Shared',
            pos = { nBGWidth, 0 },
            color = Gui.SIDEBAR_BG,
            scale = { 1, 'g_GuiManager.getUIViewportSizeY()' },
            hidden = false,
        },
        {
            key = 'ScrollPane',
            type = 'scrollPane',
            pos = { 10, -250 },
            rect = { 0, 0, 1715, '(g_GuiManager.getUIViewportSizeY() - 280)' },
        },
        {
            key = 'BackButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'BackButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'BackButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'BackButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'BackLabel',
                    color = { 0, 0, 0 },
                },          
                {
                    key = 'BackHotkey',
                    color = { 0, 0, 0 },                    
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'BackButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'BackLabel',
                    color = Gui.AMBER,
                },
                {
                    key = 'BackHotkey',
                    color = Gui.AMBER,
                },
            },
        },
        {
            key = 'BackLabel',
            type = 'textBox',
            pos = { 96, -20 },
            linecode = 'HUDHUD035TEXT',
            style = 'dosisregular40',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BackHotkey',
            type = 'textBox',
            pos = { nHotkeyX, -60 },
            text = 'ESC',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SquadEditMenuLabel',
            type = 'textBox',
            pos = { 380, -20 },
			text = 'fail',
            style = 'dosismedium44',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- top bar
		{
            key = 'MembersLabel',
            type = 'textBox',
            pos = { 200, -300 },
            linecode = 'SQUAD019TEXT',
            style = 'dosismedium44',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'MembersCountLabel',
            type = 'textBox',
            pos = { 500, -300 },
            text = '0/0',
            style = 'dosismedium44',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'AvailableLabel',
            type = 'textBox',
            pos = { 800, -300 },
            linecode = 'SQUAD020TEXT',
            style = 'dosismedium44',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'AvailableCountLabel',
            type = 'textBox',
            pos = { 1100, -300 },
            text = '0/0',
            style = 'dosismedium44',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
