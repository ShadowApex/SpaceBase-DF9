local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }

local nButtonWidth, nButtonHeight  = 330, 81
local nButtonStartY = -100
local nDoneLabelX, nLabelX, nLabelStartY = 105, 30, -133
local nHotkeyX, nHotkeyStartY = nButtonWidth - 112, -169
local numButtons = 8

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
            key = 'ResearchButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY }, -- 0,-100
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
                    color = SELECTION_AMBER,
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
                    color = SELECTION_AMBER,
                },
                {
                    key = 'ResearchHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
        {
            key = 'ResearchLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY },
            linecode = 'DEBUG002TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
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
            color = SELECTION_AMBER
        },
		{
            key = 'ResearchAllButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - nButtonHeight },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'ResearchAllButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ResearchAllButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'ResearchAllButton',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'ResearchAllLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ResearchAllHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ResearchAllButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'ResearchAllLabel',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'ResearchAllHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
		{
            key = 'ResearchAllLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY - nButtonHeight }, --  -100 - 81 = -181
            linecode = 'DEBUG003TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'ResearchAllHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - nButtonHeight - 5 },
            text = '2.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER
        },
		--------------------------------------------
		{
            key = 'ResearchAllMaladyButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight *2) }, --  -100 - 81 = 262
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'ResearchAllMaladyButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'ResearchAllMaladyButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'ResearchAllMaladyButton',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'ResearchAllMaladyLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'ResearchAllMaladyHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'ResearchAllMaladyButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'ResearchAllMaladyLabel',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'ResearchAllMaladyHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
		{
            key = 'ResearchAllMaladyLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY - (nButtonHeight *2) },
            linecode = 'DEBUG004TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'ResearchAllMaladyHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - (nButtonHeight *2) - 5 },
            text = '3.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER
        },
		-----------------------------------------------
		{
            key = 'MakeAllHappyButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight *3) },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'MakeAllHappyButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'MakeAllHappyButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'MakeAllHappyButton',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'MakeAllHappyLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'MakeAllHappyHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'MakeAllHappyButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'MakeAllHappyLabel',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'MakeAllHappyHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
		{
            key = 'MakeAllHappyLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY - (nButtonHeight *3) },
            linecode = 'DEBUG005TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'MakeAllHappyHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - (nButtonHeight *3) - 5 },
            text = '4.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER
        },
		-----------------------------------------------------------------
		{
            key = 'MakeAllSadButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight *4) },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'MakeAllSadButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'MakeAllSadButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'MakeAllSadButton',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'MakeAllSadLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'MakeAllSadHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'MakeAllSadButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'MakeAllSadLabel',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'MakeAllSadHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
		{
            key = 'MakeAllSadLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY - (nButtonHeight *4) },
            linecode = 'DEBUG006TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'MakeAllSadHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - (nButtonHeight *4) - 5 },
            text = '5.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER
        },
		------------------------------------------------------------
		{
            key = 'InfectButton',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight *5) },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'InfectButton',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'InfectButton',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'InfectButton',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'InfectLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'InfectHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'InfectButton',
                    color = Gui.BLACK,
                },
                {
                    key = 'InfectLabel',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'InfectHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
		{
            key = 'InfectLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY - (nButtonHeight *5) },
            linecode = 'DEBUG007TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'InfectHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - (nButtonHeight *5) - 5 },
            text = '6.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER
        },
		
		------------------------------------------------------------
		{
            key = 'RandomTest',
            type = 'onePixelButton',
            pos = { 0, nButtonStartY - (nButtonHeight *6) },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                {
                    key = 'RandomTest',
                    color = BRIGHT_AMBER,
                },            
            },
            onReleased =
            {
                {
                    key = 'RandomTest',
                    color = AMBER,
                },
            },
            onHoverOn =
            {
                {
                    key = 'RandomTest',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'RandomTestLabel',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'RandomTestHotkey',
                    color = { 0, 0, 0 },
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'RandomTest',
                    color = Gui.BLACK,
                },
                {
                    key = 'RandomTestLabel',
                    color = SELECTION_AMBER,
                },
                {
                    key = 'RandomTestHotkey',
                    color = SELECTION_AMBER,
                },
            },
        },
		{
            key = 'RandomTestLabel',
            type = 'textBox',
            pos = { nLabelX, nButtonStartY - (nButtonHeight *6) },
            linecode = 'DEBUG008TEXT',
            style = 'dosisregular40',
            rect = { 0, nButtonHeight, nButtonWidth, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER,
        },
        {
            key = 'RandomTestHotkey',
            type = 'textBox',
            pos = { 0, nButtonStartY - (nButtonHeight *6) - 5 },
            text = '7.',
            style = 'dosissemibold22',
            rect = { 0, nButtonHeight, 20, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = SELECTION_AMBER
        },
		
		------------
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