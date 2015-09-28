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
    tExtraInfo =
    {
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
            rect = { 0, 300, 200, 0 },
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
            key = 'SquadMenuLabel',
            type = 'textBox',
            pos = { 380, -20 },
            linecode = 'SQUAD002TEXT',
            style = 'dosismedium44',
            rect = { 0, 400, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'CreateButton',
            type = 'onePixelButton',
            pos = { 800, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'CreateButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'CreateButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'CreateButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'CreateLabel',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'CreateButton',
                    color = Gui.BLACK,
                },
				{
                    key = 'CreateLabel',
                    color = Gui.AMBER,
                },
            },
        },
		{
            key = 'CreateLabel',
            type = 'textBox',
            pos = { 846, -20 },
            linecode = 'SQUAD008TEXT',
            style = 'dosisregular40',
            rect = { 0, 400, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'PurgeButton',
            type = 'onePixelButton',
            pos = { 800 + nButtonWidth, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'PurgeButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'PurgeButton',
                    color = AMBER,
                },       
            },
            onHoverOn =
            {
                {
                    key = 'PurgeButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'PurgeLabel',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'PurgeButton',
                    color = Gui.BLACK,
                },
				{
                    key = 'PurgeLabel',
                    color = Gui.AMBER,
                },
            },
        },
		{
            key = 'PurgeLabel',
            type = 'textBox',
            pos = { 800 + nButtonWidth, -20 },
            linecode = 'SQUAD025TEXT',
            style = 'dosisregular40',
            rect = { 0, 400, 300, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- top bar
		{
            key = 'SquadLabel',
            type = 'textBox',
            pos = { nNameColX, nTopLabelTextY },
            linecode = 'SQUAD003TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'SizeLabel',
            type = 'textBox',
            pos = { nSizeColX, nTopLabelTextY },            
            linecode = 'SQUAD004TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'StatusLabel',
            type = 'textBox',
            pos = { nStatusColX, nTopLabelTextY },            
            linecode = 'SQUAD005TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'EditLabel',
            type = 'textBox',
            pos = { nAssignColX, nTopLabelTextY },            
            linecode = 'SQUAD006TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'DisbandLabel',
            type = 'textBox',
            pos = { nDisbandColX, nTopLabelTextY },            
            linecode = 'SQUAD007TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
