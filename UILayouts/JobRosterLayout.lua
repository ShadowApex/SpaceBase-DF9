local Gui = require('UI.Gui')
local CharacterConstants = require('CharacterConstants')

local AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.95 }
local BRIGHT_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 1 }
local SELECTION_AMBER = { Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.01 }
local HIGHLIGHT_COLOR = { 0.1, 0.1, 0.1, 0.75 }

local nBGWidth = 1925 --1800

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
local nJobColX = 10
local nNameColX = 106
local nSortTextureSize = 44

local nJobColScale = 128
local nJobBlockScale = 162
local nJob1ColX = 554
local nJob2ColX = nJob1ColX + nJobColScale
local nJob3ColX = nJob1ColX + nJobColScale * 2
local nJob4ColX = nJob1ColX + nJobColScale * 3
local nJob5ColX = nJob1ColX + nJobColScale * 4
local nJob6ColX = nJob1ColX + nJobColScale * 5
local nJob7ColX = nJob1ColX + nJobColScale * 6
local nJob8ColX = nJob1ColX + nJobColScale * 7
local nJob9ColX = nJob1ColX + nJobColScale * 8
local nJob10ColX = nJob1ColX + nJobColScale * 9

local nJobDivScl = 40
local nJobLabelDivScl = 24
local nJobCatLabelRectSize = nJobDivScl * 2 + nSortTextureSize
local nJobLabelRectSize = nJobLabelDivScl * 2 + nSortTextureSize

local nJobTextureXOffset = math.floor(nJobDivScl / 2) + 16
local nJobTextureYOffset = nTopLabelTextY + 36

local nJobNumXOffset = math.floor(nJobDivScl / 2) + 58
local nJobNumYOffset = nTopLabelTextY + 40

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
            rect = { 0, 0, 1840, '(g_GuiManager.getUIViewportSizeY() - 280)' },	--1715
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
            key = 'RosterLabel',
            type = 'textBox',
            pos = { 380, -20 },
            linecode = 'HUDHUD047TEXT',
            style = 'dosismedium44',
            rect = { 0, 400, 500, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- top bar
        -- job
        {
            key = 'JobSortButton',
            type = 'onePixelButton',
            pos = { nJobColX, nHighlightY },
            scale = { nJobLabelDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'JobSortHighlight',
                    color = HIGHLIGHT_COLOR,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'JobSortHighlight',
                    color = Gui.BLACK,
                },
            },
        },
        {
            key = 'JobSortHighlight',
            type = 'onePixel',
            pos = { nJobColX, nHighlightY },
            scale = { nJobLabelDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
        },
        {
            key = 'JobLabel',
            type = 'textBox',
            pos = { nJobColX, nTopLabelTextY },
            linecode = 'HUDHUD032TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'JobLabelDivLf',
            type = 'onePixel',
            pos = { nJobColX, nTopLabelY },
            scale = { nJobLabelDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'jobSortDivMid',
            type = 'onePixel',
            pos = { nJobColX + nJobLabelDivScl, nTopLabelY },
            scale = { 45, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'jobSortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColX + nJobLabelDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'jobSortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJobColX + nJobLabelDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'JobLabelDivRt',
            type = 'onePixel',
            pos = { nJobColX + nJobLabelDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobLabelDivScl, nTopBarHeight },
            color = Gui.GREY,
        },        
        -- name
        {
            key = 'NameSortButton',
            type = 'onePixelButton',
            pos = { nNameColX, nHighlightY },
            scale = { 432 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'NameSortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'NameSortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'NameSortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nNameColX, nHighlightY },
            pos = { nNameColX, nHighlightY },
            scale = { 402 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'NameLabel',
            type = 'textBox',
            pos = { nNameColX + 20, nTopLabelTextY },            
            linecode = 'HUDHUD033TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'NameLabelDivLf',
            type = 'onePixel',
            pos = { nNameColX, nTopLabelY },
            scale = { 38, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'nameSortDivMid',
            type = 'onePixel',
            pos = { nNameColX + 36, nTopLabelY },
            scale = { 45, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'nameSortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nNameColX + 36,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'nameSortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nNameColX + 36,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'NameLabelDivRt',
            type = 'onePixel',
            pos = { nNameColX + 81, nTopLabelY },
            scale = { 364, nTopBarHeight },
            color = Gui.GREY,
        },        
        -- job1
        {
            key = 'Job1SortButton',
            type = 'onePixelButton',
            pos = { nJob1ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job1SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job1SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job1SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob1ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job1Label',
            type = 'textBox',
            pos = { nJob1ColX, nTopLabelTextY },            
            linecode = 'DUTIES003TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job1Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.BUILDER],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob1ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job1Num',
            type = 'textBox',
            pos = { nJob1ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job1LabelDivLf',
            type = 'onePixel',
            pos = { nJob1ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job1SortDivMid',
            type = 'onePixel',
            pos = { nJob1ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job1SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob1ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job1SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob1ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job1LabelDivRt',
            type = 'onePixel',
            pos = { nJob1ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },        
        -- job2
        {
            key = 'Job2SortButton',
            type = 'onePixelButton',
            pos = { nJob2ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job2SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job2SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job2SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob2ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job2Label',
            type = 'textBox',
            pos = { nJob2ColX, nTopLabelTextY },            
            linecode = 'DUTIES005TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job2Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.TECHNICIAN],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob2ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job2Num',
            type = 'textBox',
            pos = { nJob2ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job2LabelDivLf',
            type = 'onePixel',
            pos = { nJob2ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job2SortDivMid',
            type = 'onePixel',
            pos = { nJob2ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job2SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob2ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job2SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob2ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job2LabelDivRt',
            type = 'onePixel',
            pos = { nJob2ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },        
        -- job3
        {
            key = 'Job3SortButton',
            type = 'onePixelButton',
            pos = { nJob3ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job3SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job3SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job3SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob3ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job3Label',
            type = 'textBox',
            pos = { nJob3ColX, nTopLabelTextY },            
            linecode = 'DUTIES007TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job3Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.MINER],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob3ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job3Num',
            type = 'textBox',
            pos = { nJob3ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job3LabelDivLf',
            type = 'onePixel',
            pos = { nJob3ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job3SortDivMid',
            type = 'onePixel',
            pos = { nJob3ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job3SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob3ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job3SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob3ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job3LabelDivRt',
            type = 'onePixel',
            pos = { nJob3ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },        
        -- job4
        {
            key = 'Job4SortButton',
            type = 'onePixelButton',
            pos = { nJob4ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job4SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job4SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job4SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob4ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job4Label',
            type = 'textBox',
            pos = { nJob4ColX, nTopLabelTextY },            
            linecode = 'DUTIES009TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job4Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.EMERGENCY],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob4ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job4Num',
            type = 'textBox',
            pos = { nJob4ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job4LabelDivLf',
            type = 'onePixel',
            pos = { nJob4ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job4SortDivMid',
            type = 'onePixel',
            pos = { nJob4ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job4SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob4ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job4SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob4ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job4LabelDivRt',
            type = 'onePixel',
            pos = { nJob4ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },     
        -- job5
        {
            key = 'Job5SortButton',
            type = 'onePixelButton',
            pos = { nJob5ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job5SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job5SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job5SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob5ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job5Label',
            type = 'textBox',
            pos = { nJob5ColX, nTopLabelTextY },            
            linecode = 'DUTIES013TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job5Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.BARTENDER],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob5ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job5Num',
            type = 'textBox',
            pos = { nJob5ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job5LabelDivLf',
            type = 'onePixel',
            pos = { nJob5ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job5SortDivMid',
            type = 'onePixel',
            pos = { nJob5ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job5SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob5ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job5SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob5ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job5LabelDivRt',
            type = 'onePixel',
            pos = { nJob5ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },           
        -- job6
        {
            key = 'Job6SortButton',
            type = 'onePixelButton',
            pos = { nJob6ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job6SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job6SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job6SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob6ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job6Label',
            type = 'textBox',
            pos = { nJob6ColX, nTopLabelTextY },            
            linecode = 'DUTIES016TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job6Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.BOTANIST],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob6ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job6Num',
            type = 'textBox',
            pos = { nJob6ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job6LabelDivLf',
            type = 'onePixel',
            pos = { nJob6ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job6SortDivMid',
            type = 'onePixel',
            pos = { nJob6ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job6SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob6ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job6SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob6ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job6LabelDivRt',
            type = 'onePixel',
            pos = { nJob6ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },

        -- job7
        {
            key = 'Job7SortButton',
            type = 'onePixelButton',
            pos = { nJob7ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job7SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job7SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job7SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob7ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job7Label',
            type = 'textBox',
            pos = { nJob7ColX, nTopLabelTextY },            
            linecode = 'DUTIES018TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job7Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.SCIENTIST],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob7ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job7Num',
            type = 'textBox',
            pos = { nJob7ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job7LabelDivLf',
            type = 'onePixel',
            pos = { nJob7ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job7SortDivMid',
            type = 'onePixel',
            pos = { nJob7ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job7SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob7ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job7SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob7ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job7LabelDivRt',
            type = 'onePixel',
            pos = { nJob7ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },           

        -- job8
        {
            key = 'Job8SortButton',
            type = 'onePixelButton',
            pos = { nJob8ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job8SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job8SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job8SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob8ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job8Label',
            type = 'textBox',
            pos = { nJob8ColX, nTopLabelTextY },            
            linecode = 'DUTIES020TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job8Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.DOCTOR],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob8ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job8Num',
            type = 'textBox',
            pos = { nJob8ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job8LabelDivLf',
            type = 'onePixel',
            pos = { nJob8ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job8SortDivMid',
            type = 'onePixel',
            pos = { nJob8ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job8SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob8ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job8SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob8ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job8LabelDivRt',
            type = 'onePixel',
            pos = { nJob8ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },           

       -- job9------------------------------------------------------------------------
        {
            key = 'Job9SortButton',
            type = 'onePixelButton',
            pos = { nJob9ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
            onHoverOn =
            {
                {
                    key = 'Job9SortHighlight',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            {
                {
                    key = 'Job9SortHighlight',
                    hidden = true,
                },
            },
        },
        {
            key = 'Job9SortHighlight',
            type = 'onePixel',
            hidden = true,
            pos = { nJob9ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = HIGHLIGHT_COLOR,
        },
        {
            key = 'job9Label',
            type = 'textBox',
            pos = { nJob9ColX, nTopLabelTextY },            
            linecode = 'DUTIES022TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job9Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.TECHNICIAN],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob9ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        },
        {
            key = 'job9Num',
            type = 'textBox',
            pos = { nJob9ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job9LabelDivLf',
            type = 'onePixel',
            pos = { nJob9ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'job9SortDivMid',
            type = 'onePixel',
            pos = { nJob9ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
            hidden = true,
        },   
        {
            key = 'job9SortDown',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortDown',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob9ColX + nJobDivScl,nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = false,
        },
        {
            key = 'job9SortUp',
            type = 'uiTexture',
            textureName = 'ui_jobs_catsortUp',
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob9ColX + nJobDivScl, nTopLabelY + 6  },
            color = Gui.GREY,
            scale = { 1, 1 },
            hidden = true,
        },
        {
            key = 'Job9LabelDivRt',
            type = 'onePixel',
            pos = { nJob9ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },          

        -- job10
        {
            key = 'Job10SortButton',
            type = 'onePixelButton',
            pos = { nJob10ColX, nHighlightY },
            scale = { nJobDivScl * 2 + nSortTextureSize, nSortHighlightScaleY },
            color = Gui.BLACK,
        },
        {
            key = 'job10Label',
            type = 'textBox',
            pos = { nJob10ColX, nTopLabelTextY },            
            linecode = 'DUTIES001TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, nJobCatLabelRectSize, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job10Texture',
            type = 'uiTexture',
            textureName = CharacterConstants.JOB_ICONS[CharacterConstants.UNEMPLOYED],
            sSpritesheetPath = 'UI/JobRoster',
            pos = { nJob10ColX + nJobTextureXOffset, nJobTextureYOffset },
            color = Gui.AMBER,
            scale = { 1, 1 },
        }, --[[
        {
            key = 'job10Num',
            type = 'textBox',
            pos = { nJob10ColX + nJobNumXOffset, nJobNumYOffset },
            text = '10',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        {
            key = 'Job10LabelDivLf',
            type = 'onePixel',
            pos = { nJob10ColX, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'Job10LabelDivMid',
            type = 'onePixel',
            pos = { nJob10ColX + nJobDivScl, nTopLabelY },
            scale = { nSortTextureSize, nTopBarHeight },
            color = Gui.GREY,
        },   
        {
            key = 'Job10LabelDivRt',
            type = 'onePixel',
            pos = { nJob10ColX + nJobDivScl + nSortTextureSize, nTopLabelY },
            scale = { nJobDivScl, nTopBarHeight },
            color = Gui.GREY,
        }, ]]--  
    },
}
