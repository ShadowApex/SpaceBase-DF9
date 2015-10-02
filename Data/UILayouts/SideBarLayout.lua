local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }

local nButtonWidth, nButtonHeight  = 104, 81
local nButtonWidthExpanded = 286
local nButtonStartY = -204
local nIconX, nIconStartY = 10, 0
local nLabelX, nLabelStartY = 105, -10
local nHotkeyX, nHotkeyStartY = nButtonWidth - 104, -50
local nHotkeyExpandedX = nButtonWidthExpanded - 112
local nIconScale = 0.6
-- # is 8 with disaster menu but start with it hidden
local nNumButtons = 8

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
            key = 'SmallBarButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { 104, nButtonHeight * nNumButtons },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'LargeBarButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidthExpanded, nButtonHeight * nNumButtons },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'SmallBarHighlight',
            type = 'onePixel',
            pos = { 0, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = Gui.AMBER,
        },
        {
            key = 'InspectButton',
            type = 'onePixelButton',
            pos = { 0, 0 },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'InspectButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'InspectButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'InspectButton', color=Gui.AMBER, },
                { key = 'InspectLabel', color = { 0, 0, 0 }, },
                { key = 'InspectIcon', color = { 0, 0, 0 }, },
                { key = 'InspectHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'InspectButton', color = Gui.BLACK, },
                { key = 'InspectLabel', color = Gui.AMBER, },
                { key = 'InspectIcon', color = Gui.AMBER, },
                { key = 'InspectHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'InspectIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_inspect',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'AssignButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'AssignButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'AssignButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'AssignButton',  color=Gui.AMBER, },
                { key = 'AssignLabel', color = { 0, 0, 0 }, },
                { key = 'AssignIcon', color = { 0, 0, 0 }, },
                { key = 'AssignHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'AssignButton', color = Gui.BLACK, },
                { key = 'AssignLabel', color = Gui.AMBER, },
                { key = 'AssignIcon', color = Gui.AMBER, },
                { key = 'AssignHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'AssignIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_assign',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'ResearchButton',
            type = 'onePixelButton',
            pos = { 0, -nButtonHeight * 2 },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'ResearchButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'ResearchButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'ResearchButton',  color=Gui.AMBER, },
                { key = 'ResearchLabel', color = { 0, 0, 0 }, },
                { key = 'ResearchIcon', color = { 0, 0, 0 }, },
                { key = 'ResearchHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ResearchButton', color = Gui.BLACK, },
                { key = 'ResearchLabel', color = Gui.AMBER, },
                { key = 'ResearchIcon', color = Gui.AMBER, },
                { key = 'ResearchHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'ResearchIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_research',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - nButtonHeight*2 },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'GoalButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonHeight * 3) },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'GoalButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'GoalButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'GoalButton', color = Gui.AMBER, },
                { key = 'GoalLabel', color = { 0, 0, 0 }, },
                { key = 'GoalIcon', color = { 0, 0, 0 }, },
                { key = 'GoalHotkey', color = { 0, 0, 0 }, },
                { key = 'GoalHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'GoalButton', color = Gui.BLACK, },
                { key = 'GoalLabel', color = Gui.AMBER, },
                { key = 'GoalIcon', color = Gui.AMBER, },
                { key = 'GoalHotkey', color = Gui.AMBER, },
                { key = 'GoalHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'GoalIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_confirm',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 3) },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'ConstructButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonHeight * 4) },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'ConstructButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'ConstructButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'ConstructButton',  color=Gui.AMBER, },
                { key = 'ConstructLabel', color = { 0, 0, 0 }, },
                { key = 'ConstructIcon', color = { 0, 0, 0 }, },
                { key = 'ConstructHotkey', color = { 0, 0, 0 }, },
                { key = 'ConstructHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ConstructButton', color = Gui.BLACK, },
                { key = 'ConstructLabel', color = Gui.AMBER, },
                { key = 'ConstructIcon', color = Gui.AMBER, },
                { key = 'ConstructHotkey', color = Gui.AMBER, },
                { key = 'ConstructHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'ConstructIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_construct',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 4) },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'MineButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonHeight * 5) },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'MineButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'MineButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'MineButton',  color=Gui.AMBER, },
                { key = 'MineLabel', color = { 0, 0, 0 }, },
                { key = 'MineIcon', color = { 0, 0, 0 }, },
                { key = 'MineHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'MineButton', color = Gui.BLACK, },
                { key = 'MineLabel', color = Gui.AMBER, },
                { key = 'MineIcon', color = Gui.AMBER, },
                { key = 'MineHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'MineIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_mine',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 5) },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'BeaconButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonHeight * 6) },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'BeaconButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'BeaconButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'BeaconButton',  color=Gui.AMBER, },
                { key = 'BeaconLabel', color = { 0, 0, 0 }, },
                { key = 'BeaconIcon', color = { 0, 0, 0 }, },
                { key = 'BeaconHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'BeaconButton', color = Gui.BLACK, },
                { key = 'BeaconLabel', color = Gui.AMBER, },
                { key = 'BeaconIcon', color = Gui.AMBER, },
                { key = 'BeaconHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'BeaconIcon',
            type = 'uiTexture',
            textureName = 'ui_iconIso_beacon',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 6) },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'DisasterButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonHeight * 8) },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'DisasterButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'DisasterButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'DisasterButton',  color=Gui.AMBER, },
                { key = 'DisasterLabel', color = { 0, 0, 0 }, },
                { key = 'DisasterIcon', color = { 0, 0, 0 }, },
                { key = 'DisasterHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'DisasterButton', color = Gui.BLACK, },
                { key = 'DisasterLabel', color = Gui.AMBER, },
                { key = 'DisasterIcon', color = Gui.AMBER, },
                { key = 'DisasterHotkeyExpanded', color = Gui.AMBER, },
            },
        },
        {
            key = 'DisasterIcon',
            type = 'uiTexture',
            textureName = 'icon_wall_neon_pizza',
            sSpritesheetPath = 'UI/Shared',
            pos = { nIconX, nIconStartY - (nButtonHeight * 8) },
            scale = {nIconScale, nIconScale},
            color = Gui.AMBER,
        },
        {
            key = 'InspectLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY },
            linecode = 'HUDHUD005TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AssignLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight },
            linecode = 'HUDHUD006TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResearchLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight * 2 },
            linecode = 'HUDHUD046TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'GoalLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - nButtonHeight * 3 },
            linecode = 'HUDHUD052TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ConstructLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 4) },
            linecode = 'HUDHUD007TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 280, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'MineLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 5) },
            linecode = 'HUDHUD008TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BeaconLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 6) },
            linecode = 'HUDHUD025TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DisasterLabel',
            type = 'textBox',
            pos = { nLabelX, nLabelStartY - (nButtonHeight * 8) },
            linecode = 'HUDHUD062TEXT',
            style = 'dosisregular40',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'InspectHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY },
            text = 'I',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'InspectHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY },
            text = 'I',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AssignHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight },
            text = 'R',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'AssignHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - nButtonHeight },
            text = 'R',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResearchHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight * 2 },
            text = 'E',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ResearchHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - nButtonHeight * 2 },
            text = 'E',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'GoalHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - nButtonHeight * 3 },
            text = 'G',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'GoalHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - nButtonHeight * 3 },
            text = 'G',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ConstructHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 4) },
            text = 'C',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ConstructHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - (nButtonHeight * 4) },
            text = 'C',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'MineHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 5) },
            text = 'M',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'MineHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - (nButtonHeight * 5) },
            text = 'M',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BeaconHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 6) },
            text = 'B',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'BeaconHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - (nButtonHeight * 6) },
            text = 'B',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DisasterHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 8) },
            text = 'Z',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DisasterHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - (nButtonHeight * 8) },
            text = 'Z',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'DebugButton',
            type = 'onePixelButton',
            pos = { 0, -(nButtonHeight * 7) },
            scale = { nButtonWidthExpanded, nButtonHeight },
            color = Gui.BLACK,
            onPressed =
            {
                { key = 'DebugButton', color = BRIGHT_AMBER, },
            },
            onReleased =
            {
                { key = 'DebugButton', color = AMBER, },
            },
            onHoverOn =
            {
                { key = 'DebugButton',  color=Gui.AMBER, },
                { key = 'DebugLabel', color = { 0, 0, 0 }, },
                { key = 'DebugIcon', color = { 0, 0, 0 }, },
                { key = 'DebugHotkey',  color = { 0, 0, 0 }, },
                { key = 'DebugHotkeyExpanded', color = { 0, 0, 0 }, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'DebugButton', color = Gui.BLACK, },
                { key = 'DebugLabel', color = Gui.AMBER, },
                { key = 'DebugIcon', color = Gui.AMBER, },
                { key = 'DebugHotkey', color = Gui.AMBER, },
                { key = 'DebugHotkeyExpanded', color = Gui.AMBER, },
            },
        },
		{
			key = 'DebugLabel',
			type = 'textBox',
			pos = { nLabelX, nLabelStartY - (nButtonHeight * 7) },
			linecode = 'DEBUG001TEXT',
			style = 'dosisregular40',
			rect = { 0, 300, 280, 0 },
			hAlign = MOAITextBox.LEFT_JUSTIFY,
			vAlign = MOAITextBox.LEFT_JUSTIFY,
			color = Gui.AMBER,
		},
		{
			key = 'DebugIcon',
			type = 'uiTexture',
			textureName = 'icon_wall_neon_pizza',
			sSpritesheetPath = 'UI/Shared',
			pos = { nIconX, nIconStartY - (nButtonHeight * 7) },
			scale = {nIconScale, nIconScale},
			color = Gui.AMBER,
		},
		{
            key = 'DebugHotkey',
            type = 'textBox',
            pos = { nHotkeyX, nHotkeyStartY - (nButtonHeight * 7) },
            text = 'X',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'DebugHotkeyExpanded',
            type = 'textBox',
            pos = { nHotkeyExpandedX, nHotkeyStartY - (nButtonHeight * 7) },
            text = 'X',
            style = 'dosissemibold20',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'SidebarBottomEndcap',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { -152, -(nButtonHeight * nNumButtons) },
            scale = { 1, 1 },
            color = Gui.SIDEBAR_BG,
        },
        {
            key = 'SidebarBottomEndcapExpanded',
            type = 'uiTexture',
            textureName = 'ui_hud_anglebottom',
            sSpritesheetPath = 'UI/HUD',
            pos = { 0, -(nButtonHeight * nNumButtons) },
            scale = { 1.12, 1.12 },
            color = Gui.SIDEBAR_BG,
        },
    },
}
