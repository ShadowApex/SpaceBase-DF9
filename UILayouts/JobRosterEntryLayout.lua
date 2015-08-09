local Gui = require('UI.Gui')

local nBorderScale = 4
local nBorderHeight = 60
local nJobBlockScale = 128
local nJobColStart = 538
local nUnassignedJobBGScale = nJobBlockScale - 32
local nJobCheckmarkOffsetX = -22
local nJobCheckmarkOffsetY = 10
local nNameBGScaleX, nNameBGScaleY = 418, 62
local nNameBGLocX = 122
local nSkillLevelIconOffsetX = -32
local nAffinityIconOffsetX = 76
local nHorizBorderXScale = 1760 --1636
local nHorizBorderYScale = 2







return
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
--        offsetX = 40,
--        offsetY = -300,
    offsetX = 0,
        offsetY = 0,
    },
    tExtraInfo =
    {
        tActiveJobInfo =
        {
            Job1 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + nJobBlockScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job2 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 2) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY }, --538 + (128 * 2) + 4 + -22, 10 = 776,10
                },
            },
            Job3 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 3) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job4 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 4) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job5 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 5) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job6 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 6) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job7 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 7) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job8 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 8) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
                },
            },
            Job9 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 9) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY }, --538 + (128 * 9) + 4 + -22, 10 = 1672,10
                },
            },
	    Job10 =
            {
                {
                    key = 'SelectedCheckmark',
                    pos = { nJobColStart + (nJobBlockScale * 10) + nBorderScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY }, --538 + (128 * 10) + 4 + -22, 10 = 1800,10
                },
            },
        },
    },
    tElements =
    {
        -- job1
        {
            key = 'Job1Button',
            type = 'onePixelButton',
            pos = { nJobColStart, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob1BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob1BG',
                    hidden = true,
                },
            },
        },
        -- job2
        {
            key = 'Job2Button',
            type = 'onePixelButton',
            pos = { nJobColStart + nJobBlockScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob2BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob2BG',
                    hidden = true,
                },
            },
        },
        -- job3
        {
            key = 'Job3Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 2) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob3BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob3BG',
                    hidden = true,
                },
            },
        },
        -- job4
        {
            key = 'Job4Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 3) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob4BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob4BG',
                    hidden = true,
                },
            },
        },
        -- job5
        {
            key = 'Job5Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 4) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob5BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob5BG',
                    hidden = true,
                },
            },
        },



        -- job6
        {
            key = 'Job6Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 5) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob6BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob6BG',
                    hidden = true,
                },
            },
        },
        -- job7
        {
            key = 'Job7Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 6) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob7BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob7BG',
                    hidden = true,
                },
            },
        },
        -- job8
        {
            key = 'Job8Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 7) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob8BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob8BG',
                    hidden = true,
                },
            },
        },
        -- job9
        {
            key = 'Job9Button',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 8) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'ActiveJob9BG',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'ActiveJob9BG',
                    hidden = true,
                },
            },
        },
        -- unassigned
        {
            key = 'UnassignedJobButton',
            type = 'onePixelButton',
            pos = { nJobColStart + (nJobBlockScale * 9) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'UnassignedJobBG',
                    hidden = false,
                },
                {
                    key = 'UnassignedJobBGBracket',
                    hidden = false,
                },
            },
            onHoverOff =
            {
                {
                    key = 'UnassignedJobBG',
                    hidden = true,
                },
                {
                    key = 'UnassignedJobBGBracket',
                    hidden = true,
                },
            },
        },
        -- selected bg
        {
            key = 'ActiveJob1BG',
            type = 'onePixel',
            pos = { nJobColStart, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob2BG',
            type = 'onePixel',
            pos = { nJobColStart + nJobBlockScale + 4, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob3BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 2) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob4BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 3) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob5BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 4) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob6BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 5) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob7BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 6) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob8BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 7) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'ActiveJob9BG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 8) + nBorderScale, 0 },
            scale = { nJobBlockScale, nBorderHeight },
            color = { 1, 0, 0 },
            hidden = true,
        },
        {
            key = 'UnassignedJobBG',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 9) + nBorderScale, 0 },
            scale = { nUnassignedJobBGScale, nBorderHeight },
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'UnassignedJobBGBracket',
            type = 'uiTexture',
            textureName = 'ui_circlefilled',
            sSpritesheetPath = 'UI/Shared',
            pos = { nJobColStart + (nJobBlockScale * 9) + nBorderScale + nUnassignedJobBGScale + 32, 0  },
            color = Gui.AMBER,
            scale = { -1, 1 },
            hidden = true,
        },
        {
            key = 'LeftBracket',
            type = 'uiTexture',
            textureName = 'ui_circleempty',
            sSpritesheetPath = 'UI/Shared',
            pos = { 0, 0  },
            color = Gui.GREY,
            scale = { 1, 1 },
        },
        {
            key = 'TopBorder',
            type = 'onePixel',
            pos = { 32, 0 },
            scale = { nHorizBorderXScale, nHorizBorderYScale },
            color = Gui.GREY,
        },
        {
            key = 'BottomBorder',
            type = 'onePixel',
            pos = { 32, -61 },
            scale = { nHorizBorderXScale, nHorizBorderYScale },
            color = Gui.GREY,
        },
        {
            key = 'JobTexture',
            type = 'uiTexture',
            textureName = 'ui_jobs_iconJobBuilder',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { 30, -14 },
            color = Gui.GREY,
            scale = { 1, 1 },
        },
        {
            key = 'NameLeftBracket',
            type = 'uiTexture',
            textureName = 'ui_circlefilled',
            sSpritesheetPath = 'UI/Shared',
            pos = { 90, 0 },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'NameBG',
            type = 'onePixel',
            pos = { nNameBGLocX, 0 },
            scale = { nNameBGScaleX, nNameBGScaleY },
            color = Gui.AMBER,
        },
        {
            key = 'NameButton',
            type = 'onePixelButton',
            pos = { nNameBGLocX, 0 },
            scale = { nNameBGScaleX, nNameBGScaleY },
            color = { 1, 0, 0 },
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'NameBG',
                    color = Gui.AMBER_OPAQUE,
                },
                {
                    key = 'NameLeftBracket',
                    color = Gui.AMBER_OPAQUE,
                },
                {
                    key = 'NameRightBracket',
                    color = Gui.AMBER_OPAQUE,
                },
                {
                    key = 'NameLabel',
                    color = Gui.AMBER,
                },
            },
            onHoverOff =
            {
                {
                    key = 'NameBG',
                    color = Gui.AMBER,
                },
                {
                    key = 'NameLeftBracket',
                    color = Gui.AMBER,
                },
                {
                    key = 'NameRightBracket',
                    color = Gui.AMBER,
                },
                {
                    key = 'NameLabel',
                    color = { 0, 0, 0 },
                },
            },
        },
        {
            key = 'NameRightBracket',
            type = 'uiTexture',
            textureName = 'ui_circleinverse',
            sSpritesheetPath = 'UI/Shared',
            pos = { nJobColStart, 0 },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'NameLabel',
            type = 'textBox',
            pos = { 130, -6 },
            text = "Christopher di Remo",
            style = 'dosissemibold35',
            rect = { 0, 100, 600, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = { 0, 0, 0 },
        },
        {
            key = 'Column1',
            type = 'onePixel',
            pos = { nJobColStart + nJobBlockScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column2',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 2) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column3',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 3) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column4',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 4) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column5',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 5) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column6',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 6) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column7',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 7) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column8',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 8) + nBorderScale, 0 },
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'Column9',
            type = 'onePixel',
            pos = { nJobColStart + (nJobBlockScale * 9) + nBorderScale, 0 }, --538 + (128*9) + 4 = 1694, 0
            scale = { nBorderScale, nBorderHeight },
            color = Gui.GREY,
        },
        {
            key = 'RightBracket',
            type = 'uiTexture',
            textureName = 'ui_circleempty',
            sSpritesheetPath = 'UI/Shared',
            pos = { nJobColStart + (nJobBlockScale * 10) + nBorderScale, 0 },
            color = Gui.GREY,
            scale = { -1, 1 },
        },
        {
            key = 'SelectedCheckmark',
            type = 'uiTexture',
            textureName = 'ui_jobs_icon_checkCircle',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + nJobBlockScale + nJobCheckmarkOffsetX, nJobCheckmarkOffsetY },
            color = Gui.GREY,
            scale = { 1, 1 },
        },
		-- job affinity smiley icons
        {
            key = 'Job1AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX, -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.BLACK,
        },
		-- (yes, the separate texture for dark circle sucks)
        {
            key = 'Job1Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX, -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job2AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + nJobBlockScale, -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job2Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + nJobBlockScale, -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job3AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*2), -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job3Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*2), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job4AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*3), -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job4Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*3), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job5AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*4), -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job5Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*4), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job6AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*5), -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job6Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*5), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job7AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*6), -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job7Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*6), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job8AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*7), -12 },
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job8Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*7), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
	{
            key = 'Job9AffBG',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*8), -12 }, --538+76+(128*8) = 1638,-12
            textureName = 'ui_dialogicon_blackBG',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
        {
            key = 'Job9Aff',
            type = 'uiTexture',
            pos = { nJobColStart + nAffinityIconOffsetX + (nJobBlockScale*8), -12 },
            textureName = 'ui_dialogicon_meh',
            sSpritesheetPath = 'UI/Emoticons',
			scale = { 1, 1 },
            color = Gui.AMBER,
        },
         {
            key = 'Job1SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
         {
            key = 'Job2SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + nJobBlockScale + nBorderScale  + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
         {
            key = 'Job3SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 2) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
         {
            key = 'Job4SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 3) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'Job5SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 4) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'Job6SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 5) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'Job7SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 6) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'Job8SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 7) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'Job9SkillLevel',
            type = 'uiTexture',
            textureName = 'ui_jobs_skillrank5',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColStart + (nJobBlockScale * 8) + nBorderScale + nSkillLevelIconOffsetX, 0  },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
},
}