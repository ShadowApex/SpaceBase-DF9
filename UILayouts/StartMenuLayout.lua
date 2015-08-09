local Gui = require('UI.Gui')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.BRIGHT_AMBER[1], Gui.BRIGHT_AMBER[2], Gui.BRIGHT_AMBER[3], 1 }

local PAUSESCREEN_BG = { 0, 0, 0, 0.3 }

local nMenuItemsX = 100
local nMOTDX = -900
local nLineStartY = 120
local nLineHeight = 80

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
	tExtraInfo =
	{
		nMOTDX = nMOTDX,
	},
    tElements =
    {
        {
            key = 'Background',
            type = 'onePixel',
            pos = { -777, 641 },
            scale = { 2568, 1444 },
            color = PAUSESCREEN_BG,
            hidden = false,
        },
        {
            key = 'TextBGFadeTop',
            type = 'uiTexture',
            textureName = 'grad64',
            sSpritesheetPath = 'UI/Shared',
            pos = { -1920/2 - 64, 239 },
            scale = { 2568/64, 1 },
            color = {0, 0, 0, 0.6},
			--color = Gui.AMBER,
        },
        {
            key = 'MOTDTextBackground',
            type = 'onePixel',
            pos = { -1920/2 - 64, 175 },
            scale = { 2568, 625 },
            color = {0, 0, 0, 0.6},
            hidden = false,
        },
        {
            key = 'TextBGFadeBottom',
            type = 'uiTexture',
            textureName = 'grad64',
            sSpritesheetPath = 'UI/Shared',
            pos = { -1920/2 - 64, -514 },
            scale = { 2568/64, -1 },
            color = {0, 0, 0, 0.6},
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
            key = 'MOTDTitle',
            type = 'textBox',
            pos = { nMOTDX, 150 },
			linecode = 'UIMISC022TEXT',
            style = 'dosissemibold38',
            rect = { 0, 50, 705, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'WebsiteText',
            type = 'textBox',
            pos = { -400, 260 },
            linecode = "UIMISC016TEXT",
            style = 'dosismedium32',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonWebsite',
            type = 'onePixelButton',
            pos = { -400, 260 },
            scale = { 800, 70 },
            color = Gui.WHITE,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'WebsiteText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'WebsiteText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonResume',
            type = 'onePixelButton',
            pos = { 280, nLineStartY },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonResumeText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonResumeText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonNewGame',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonNewGameText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonNewGameText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonTutorial',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight*2 },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonTutorialText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonTutorialText', color = Gui.AMBER, },
            },
        },
		{
            key = 'ButtonLoadAndSave',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight*3 },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonLoadAndSaveText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonLoadAndSaveText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonSettings',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight*4 },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonSettingsText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonSettingsText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonCredits',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight*5 },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonCreditsText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonCreditsText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonQuit',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight*6 },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonQuitText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonQuitText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonQuitOnly',
            type = 'onePixelButton',
            pos = { 280, nLineStartY - nLineHeight*7 },
            scale = { 630, 70 },
            color = Gui.RED,
            hidden=true,
            clickWhileHidden=true,
            onHoverOn =
            {
                { key = 'ButtonQuitOnlyText', color = Gui.BRIGHT_AMBER, },
                { playSfx = 'hilight', },
            },
            onHoverOff =
            {
                { key = 'ButtonQuitOnlyText', color = Gui.AMBER, },
            },
        },
        {
            key = 'ButtonResumeText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY },
			linecode = 'UIMISC023TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonNewGameText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight },
			linecode = 'UIMISC024TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonTutorialText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight*2 },
			--linecode = 'UIMISC023TEXT',
			text = 'LEARN TO PLAY',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'ButtonLoadAndSaveText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight*3 },
			linecode = 'UIMISC044TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonSettingsText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight*4 },
			linecode = 'UIMISC025TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonCreditsText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight*5 },
			linecode = 'UIMISC026TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonQuitText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight*6 },
			linecode = 'UIMISC027TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'ButtonQuitOnlyText',
            type = 'textBox',
            pos = { nMenuItemsX, nLineStartY - nLineHeight*7 },
			linecode = 'UIMISC043TEXT',
            style = 'orbitronWhite',
            rect = { 0, 70, 800, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.CENTER_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
