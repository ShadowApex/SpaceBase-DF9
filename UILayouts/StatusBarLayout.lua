local Gui = require('UI.Gui')

local sBottomIconY = '-g_GuiManager.getUIViewportSizeY() + 40'
local nZoomoutButtonX = 1072
local nZoominButtonX = 1012
local nWallButtonX = 912
local nOxygenButtonX = 842

local sFlipBorderX = '0'
local sFlipBorderTopY = '-(g_GuiManager.getUIViewportSizeY() - 184)'
local sFlipBorderBottomY = sFlipBorderTopY .. ' - 206'
local sFlipLabelX = sFlipBorderX .. ' + 4'
local sFlipHotkeyX = sFlipBorderX .. ' + 176'
local sFlipTextY = sFlipBorderTopY .. ' + 41'
local sFlipArrowsX = sFlipBorderX .. ' + 76'
local sFlipArrowsY = sFlipBorderTopY .. ' - 124'
local sFlipButtonX = sFlipBorderX .. ' + 1'
local sFlipButtonY = sFlipBorderTopY .. ' - 1'
local nFlipButtonW = 193
local nFlipButtonH = 206
local nAlertExpandedOffsetX = -480

return 
{
    posInfo =
        {
        alignX = 'right',
        alignY = 'top',
        offsetX = -1150,
        offsetY = 36,
        scale = { 1, 1 },
    },
    tExtraInfo =
    {
        alertsExpandedOverride =
        {
            {
                key = 'ZoomoutButton',
                pos = { nZoomoutButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'ZoomoutTexture',
                pos = { nZoomoutButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'ZoomoutActiveTexture',
                pos = { nZoomoutButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'ZoominButton',
                pos = { nZoominButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'ZoominTexture',
                pos = { nZoominButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'ZoominActiveTexture',
                pos = { nZoominButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'ZoominActiveTexture',
                pos = { nZoominButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'BottomButtonDividerLine',
                pos = { nZoomoutButtonX - 76 + nAlertExpandedOffsetX, '-g_GuiManager.getUIViewportSizeY() + 40'  },
            },
            {
                key = 'WallButton',
                pos = { nWallButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'WallTexture',
                pos = { nWallButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },       
            {
                key = 'WallActiveTexture',
                pos = { nWallButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'WallHotkey',
                pos = { nWallButtonX + 50 + nAlertExpandedOffsetX, sBottomIconY..' - 30' },
            },
            {
                key = 'OxygenButton',
                pos = { nOxygenButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'OxygenTexture',
                pos = { nOxygenButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'OxygenActiveTexture',
                pos = { nOxygenButtonX + nAlertExpandedOffsetX, sBottomIconY },
            },
            {
                key = 'OxygenHotkey',
                pos = { nOxygenButtonX + 50 + nAlertExpandedOffsetX, sBottomIconY..' - 30' },
            },
        },
        alertsCollapsedOverride =
        {
            {
                key = 'ZoomoutButton',
                pos = { nZoomoutButtonX, sBottomIconY },
            },
            {
                key = 'ZoomoutTexture',
                pos = { nZoomoutButtonX, sBottomIconY },
            },
            {
                key = 'ZoomoutActiveTexture',
                pos = { nZoomoutButtonX, sBottomIconY },
            },
            {
                key = 'ZoominButton',
                pos = { nZoominButtonX, sBottomIconY },
            },
            {
                key = 'ZoominTexture',
                pos = { nZoominButtonX, sBottomIconY },
            },
            {
                key = 'ZoominActiveTexture',
                pos = { nZoominButtonX, sBottomIconY },
            },
            {
                key = 'ZoominActiveTexture',
                pos = { nZoominButtonX, sBottomIconY },
            },
            {
                key = 'BottomButtonDividerLine',
                pos = { nZoomoutButtonX - 76, '-g_GuiManager.getUIViewportSizeY() + 40'  },
            },
            {
                key = 'WallButton',
                pos = { nWallButtonX, sBottomIconY },
            },
            {
                key = 'WallTexture',
                pos = { nWallButtonX, sBottomIconY },
            },            
            {
                key = 'WallActiveTexture',
                pos = { nWallButtonX, sBottomIconY },
            },
            {
                key = 'WallHotkey',
                pos = { nWallButtonX + 50, sBottomIconY..' - 30' },
            },
            {
                key = 'OxygenButton',
                pos = { nOxygenButtonX, sBottomIconY },
            },
            {
                key = 'OxygenTexture',
                pos = { nOxygenButtonX, sBottomIconY },
            },
            {
                key = 'OxygenActiveTexture',
                pos = { nOxygenButtonX, sBottomIconY },
            },
            {
                key = 'OxygenHotkey',
                pos = { nOxygenButtonX + 50, sBottomIconY..' - 30' },
            },
        },        
    },
    tElements =
    {
        {
            key = 'CreditsIcon',
            type = 'uiTexture',
            textureName = 'ui_hud_iconMatter',
            sSpritesheetPath = 'UI/HUD',
            pos = { 320, -70 },
            scale = { 1.4, 1.4 },
            color = Gui.AMBER,
        },
        {
            key = 'CreditsLabel',
            type = 'textBox',
            pos = { 430, -52 },
            linecode = 'HUDHUD063TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'CreditsText',
            type = 'textBox',
            pos = { 430, -70 },
            text = '1',
            style = 'dosisregular70',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        }, 

        {
            key = 'MatterIcon',
            type = 'uiTexture',
            textureName = 'ui_hud_iconMatter',
            sSpritesheetPath = 'UI/HUD',
            pos = { 570, -70 },
            scale = { 1.4, 1.4 },
            color = Gui.AMBER,
        },
        {
            key = 'MatterLabel',
            type = 'textBox',
            pos = { 680, -52 },
            linecode = 'HUDHUD002TEXT',
            style = 'dosissemibold26',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'MatterText',
            type = 'textBox',
            pos = { 680, -70 },
            text = '1',
            style = 'dosisregular70',
            rect = { 0, 300, 200, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        }, 
        {
            key = 'CapacityIcon',
            type = 'uiTexture',
            textureName = 'ui_hud_iconPeople',
            sSpritesheetPath = 'UI/HUD',
            pos = { 880, -70 },
            scale = { 1.4, 1.4 },          
            color = Gui.AMBER,
        },
        {
            key = 'CapacityLabel',
            type = 'textBox',
            pos = { 940, -50 },
            linecode = 'HUDHUD003TEXT',
            style = 'dosissemibold26',
            rect = { 0, 200, 600, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.GREY,
        },
        {
            key = 'CapacityText',
            type = 'textBox',
            pos = { 940, -74 },
            text = '2',
            style = 'dosisregular70',
            rect = { 0, 300, 400, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },   
        {
            key = 'DividerLine',
            type = 'onePixel',
            pos = { 620, -192 },
            scale = { 490, 4 },
            color = Gui.AMBER,     
        },
        --[[ Commented out until we implement the feature
        { 
            key = 'HistoryButton',
            type = 'textureButton',
            sTextureName = 'ui_hud_buttonHistory',
            sSpritesheetPath = 'UI/HUD',
            pos = { 630, -274 },            
            scale = { 2, 2 },
            color = Gui.AMBER,
            hidden = true,
        },]]--
        {
            key = 'StardateText',
            type = 'textBox',
            pos = { 620, -214 },
            text = '2',
            style = 'dosissemibold30',
            rect = { 0, 100, 300, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },   
        {
            key = 'PauseButton',
            type = 'onePixelButton',
            pos = { 900, -214 },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'PauseInactiveTexture',
                    hidden = true,
                },
                {
                    key = 'PauseActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'PauseInactiveTexture',
                    hidden = false,
                },
                {
                    key = 'PauseActiveTexture',
                    hidden = true,
                },
            },
        },            
        {
            key = 'PauseInactiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed0',
            sSpritesheetPath = 'UI/HUD',
            pos = { 900, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
        },
        {
            key = 'PauseActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed0_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { 900, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'Speed1Button',
            type = 'onePixelButton',
            pos = { 956, -214 },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'Speed1InactiveTexture',
                    hidden = true,
                },
                {
                    key = 'Speed1ActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'Speed1InactiveTexture',
                    hidden = false,
                },
                {
                    key = 'Speed1ActiveTexture',
                    hidden = true,
                },
            },
        },            
        {
            key = 'Speed1InactiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed1',
            sSpritesheetPath = 'UI/HUD',
            pos = { 956, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
        },
        {
            key = 'Speed1ActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed1_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { 956, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'Speed2Button',
            type = 'onePixelButton',
            pos = { 1012, -214 },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'Speed2InactiveTexture',
                    hidden = true,
                },
                {
                    key = 'Speed2ActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'Speed2InactiveTexture',
                    hidden = false,
                },
                {
                    key = 'Speed2ActiveTexture',
                    hidden = true,
                },
            },
        },           
        {
            key = 'Speed2InactiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed2',
            sSpritesheetPath = 'UI/HUD',
            pos = { 1012, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
        },
        {
            key = 'Speed2ActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed2_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { 1012, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'Speed3Button',
            type = 'onePixelButton',
            pos = { 1068, -214 },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'Speed3InactiveTexture',
                    hidden = true,
                },
                {
                    key = 'Speed3ActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'Speed3InactiveTexture',
                    hidden = false,
                },
                {
                    key = 'Speed3ActiveTexture',
                    hidden = true,
                },
            },
        },           
        {
            key = 'Speed3InactiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed3',
            sSpritesheetPath = 'UI/HUD',
            pos = { 1068, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
        },
        {
            key = 'Speed3ActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_speed3_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { 1068, -214 },
            scale = {1.4, 1.4},
            color = Gui.AMBER,
            hidden = true,            
        },
        -- zoomout
        {
            key = 'ZoomoutButton',
            type = 'onePixelButton',
            pos = { nZoomoutButtonX, sBottomIconY },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'ZoomoutTexture',
                    hidden = true,
                },
                {
                    key = 'ZoomoutActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'ZoomoutTexture',
                    hidden = false,
                },
                {
                    key = 'ZoomoutActiveTexture',
                    hidden = true,
                },
            },
        },            
        {
            key = 'ZoomoutTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_button_zoomout',
            sSpritesheetPath = 'UI/HUD',
            pos = { nZoomoutButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
        },
        {
            key = 'ZoomoutActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_button_zoomout_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { nZoomoutButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
            hidden = true,
        },
        -- zoomin
       {
            key = 'ZoominButton',
            type = 'onePixelButton',
            pos = { nZoominButtonX, sBottomIconY },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'ZoominTexture',
                    hidden = true,
                },
                {
                    key = 'ZoominActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'ZoominTexture',
                    hidden = false,
                },
                {
                    key = 'ZoominActiveTexture',
                    hidden = true,
                },
            },
        },            
        {
            key = 'ZoominTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_button_zoomin',
            sSpritesheetPath = 'UI/HUD',
            pos = { nZoominButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
        },
        {
            key = 'ZoominActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_button_zoomin_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { nZoominButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
            hidden = true,
        },
        -- divider
        {
            key = 'BottomButtonDividerLine',
            type = 'onePixel',
            pos = { nZoomoutButtonX - 76, '-g_GuiManager.getUIViewportSizeY() + 40'  },
            scale = { 4, 54 },
            color = Gui.AMBER,     
        },        
        -- wall button
       {
            key = 'WallButton',
            type = 'onePixelButton',
            pos = { nWallButtonX, sBottomIconY },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'WallTexture',
                    hidden = true,
                },
                {
                    key = 'WallActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'WallTexture',
                    hidden = false,
                },
                {
                    key = 'WallActiveTexture',
                    hidden = true,
                },
            },
        },            
        {
            key = 'WallTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_buttonvis_walls',
            sSpritesheetPath = 'UI/HUD',
            pos = { nWallButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
        },
        {
            key = 'WallActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_buttonvis_walls_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { nWallButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'WallHotkey',
            type = 'textBox',
            pos = { nWallButtonX + 50, sBottomIconY..' - 30' },
            text = 'K',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
        -- oxygen button
       {
            key = 'OxygenButton',
            type = 'onePixelButton',
            pos = { nOxygenButtonX, sBottomIconY },
            scale = { 40, 40 },
            color = {1, 0, 0},
            hidden = true,
            clickWhileHidden=true,
            onHoverOn =
            {
                {
                    key = 'OxygenTexture',
                    hidden = true,
                },
                {
                    key = 'OxygenActiveTexture',
                    hidden = false,
                },
                {
                    playSfx = 'hilight',
                },
            },
            onHoverOff =
            { 
                {
                    key = 'OxygenTexture',
                    hidden = false,
                },
                {
                    key = 'OxygenActiveTexture',
                    hidden = true,
                },
            },
        },            
        {
            key = 'OxygenTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_buttonvis_o2',
            sSpritesheetPath = 'UI/HUD',
            pos = { nOxygenButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
        },
        {
            key = 'OxygenActiveTexture',
            type = 'uiTexture',
            textureName = 'ui_hud_buttonvis_o2_active',
            sSpritesheetPath = 'UI/HUD',
            pos = { nOxygenButtonX, sBottomIconY },
            scale = {1, 1},
            color = Gui.AMBER,
            hidden = true,
        },
        {
            key = 'OxygenHotkey',
            type = 'textBox',
            pos = { nOxygenButtonX + 50, sBottomIconY..' - 30' },
            text = 'O',
            style = 'dosissemibold22',
            rect = { 0, 100, 100, 0 },
            hAlign = MOAITextBox.LEFT_JUSTIFY,
            vAlign = MOAITextBox.LEFT_JUSTIFY,
            color = Gui.AMBER,
        },
    },
}
