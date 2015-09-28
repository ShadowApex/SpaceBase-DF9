local Gui = require('UI.Gui')

local nNameColX = 10
local nColScale = 200
local nSizeColX = 500
local nStatusColX = nSizeColX + nColScale
local nAssignColX = nSizeColX + nColScale * 2
local nDisbandColX = nSizeColX + nColScale * 3
local nButtonWidth, nButtonHeight  = nColScale, 50

return
{
    posInfo =
    {
        alignX = 'left',
        alignY = 'top',
		offsetX = 0,
        offsetY = 0,
    },
    tElements =
    {
		{
            key = 'NameLabel',
            type = 'textBox',
            pos = { nNameColX + 10, 0 },
            text = "Fail Squad",
            style = 'dosissemibold35',
            rect = { 0, 100, nSizeColX, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'SizeLabel',
            type = 'textBox',
            pos = { nSizeColX, 0 },
            text = "0",
            style = 'dosissemibold35',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.RIGHT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'StatusLabel',
            type = 'textBox',
            pos = { nStatusColX, 0 },
            text = "Available",
            style = 'dosissemibold35',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'EditButton',
            type = 'onePixelButton',
            pos = { nAssignColX, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = { 0, 0, 0 },
            onHoverOn =
            {
                {
                    key = 'EditButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'EditLabel',
                    color = { 0, 0, 0 },
                },
            },
            onHoverOff =
            {
                {
                    key = 'EditButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'EditLabel',
                    color = Gui.AMBER,
                },
            },
        },
		{
            key = 'EditLabel',
            type = 'textBox',
            pos = { nAssignColX, 0 },
            text = "Edit",
            style = 'dosissemibold35',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
		{
            key = 'DisbandButton',
            type = 'onePixelButton',
            pos = { nDisbandColX, 0 },
            scale = { nButtonWidth, nButtonHeight },
            color = { 0, 0, 0 },
            onHoverOn =
            {
                {
                    key = 'DisbandButton',
                    color = Gui.AMBER,
                },
                {
                    key = 'DisbandLabel',
                    color = { 0, 0, 0 },
                },
            },
            onHoverOff =
            {
                {
                    key = 'DisbandButton',
                    color = { 0, 0, 0 },
                },
                {
                    key = 'DisbandLabel',
                    color = Gui.AMBER,
                },
            },
        },
		{
            key = 'DisbandLabel',
            type = 'textBox',
            pos = { nDisbandColX, 0 },
            text = "Disband",
            style = 'dosissemibold35',
            rect = { 0, 100, nColScale, 0 },
            hAlign = MOAITextBox.CENTER_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
	},
}