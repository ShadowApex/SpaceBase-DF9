local Gui = {}

local DFGraphics = require('DFCommon.Graphics')
local DFFile = require('DFCommon.File')
local DFUtil = require('DFCommon.Util')
local Renderer = require('Renderer')
local SoundManager = require('SoundManager')

-- vars
Gui.rCurActivePane = nil
Gui.AMBER = {223/255, 162/255, 0, 1}
Gui.AMBER_DIM = {0.115, 0.075, 0, 1}
Gui.BRIGHT_AMBER = {1, 230/255, 150/255, 1}
Gui.AMBER_OPAQUE = {0.23, 0.15, 0, 1} -- MTF TODO: uh... why do the "opaque" colors have 0 alpha!?
Gui.AMBER_OPAQUE_DIM = {0.115, 0.075, 0, 0}
Gui.RED = {1, 61/255, 0, 1}
Gui.RED_LOW_ALPHA = {1, 61/255, 0, 0.25}
Gui.GREEN = {165/255, 211/255, 24/255, 1}
Gui.ORANGE = {1, 128/255, 0, 1}
Gui.AMBERGREEN = {211/255, 211/255, 24/255, 1}

if g_Config:getConfigValue("colorblind") then
    --These colors are the highest contrast in the color spectrum for both Protanopia and Deuteranopia
    --colorblind red
    Gui.RED = { 160/255, 4/255, 0.0, 1}
    --colorblind green
    Gui.GREEN = { 4/255, 252/255, 215/255, 1}
end

Gui.BROWN = {78/255, 53/255, 0/255, 1}
Gui.GREY = {200/255 * Gui.AMBER[1], 200/255 * Gui.AMBER[2], 200/255 * Gui.AMBER[3], 1}
Gui.SIDEBAR_BG = { 0, 0, 0, 0.8 }
Gui.SPACEFACE_BG = { 236/255*0.89, 236/255*0.89, 236/255*0.89 }
Gui.SPACEFACE_FG = { 180/255*0.89, 180/255*0.89, 180/255*0.89 }
Gui.WHITE = { 1, 1, 1, 1 }
Gui.BLACK = { 0, 0, 0, 1 }
Gui.BLACK_NO_ALPHA = { 0, 0, 0, 0 }

Gui.HINTLOG_BG = { 93/255, 128/255, 122/255 }
Gui.HINTLOG_BG_ALT = { 112/255, 155/255, 147/255 }
Gui.HINTLOG_HIGHLIGHT = { 188/255, 255/255, 255/255 }
Gui.ALERTLOG_BG = { 181/255, 119/255, 0/255 }
Gui.ALERTLOG_BG_ALT = { 202/255, 132/255, 0/255 }
Gui.ALERTLOG_LOWPRI_BG = { 90/255, 60/255, 0/255 }


Gui.styleDefs = 
{
    debug = {color={1,1,1}, size=38, },
    default = {color={0,0,0}, size=38, },
    gothicTitle = {color={0,0,0}, size=55, font='gothic'},
    gothicTitleWhite = {color={1,1,1}, size=55, font='gothic'},
    statusBar = {color={1,1,1}, size=55, font='gothic'},
    gothicSmallTitle = {color={1,1,1}, size=35, font='gothic'},
    nevisTitle = {color={1,1,1}, size=55, font='nevis'},
    nevisSmallTitle = {color={1,1,1}, size=25, font='nevis'},
    nevisStardate = {color={1,1,1}, size=35, font='nevis'},
    nevisBody = {color={0,0,0}, size=20, font='nevis'},
    nevisBodyWhite = {color={1,1,1}, size=20, font='nevis'},
    logText = {color={1,1,1}, size=30, font='nevis'},
    logTime = {color={1,1,1}, size=30, font='nevis'},
    inspectLabel = {color={0,0,0}, size=25, font='nevis'},
    inspectLabelWhite = {color={1,1,1}, size=25, font='nevis'},
    inspectName = {color={226/255,178/255,16/255}, size=50, font='gothic'},
    inspectWhite = {color={1,1,1}, size=35, font='nevis'},
    inspectAlert = {color={1,0,0}, size=35, font='nevis'},
    spaceface = {color={0,0,0}, size=24, font='silkscreen'},
    spacefaceBold = {color={0,0,0}, size=24, font='silkscreenbold'},
    debugmono = {color={1,1,1}, size=20, font='veramono'},
	debugmonoblack = {color={0,0,0}, size=20, font='veramono'},
    --jake fonts
    dosis = {color={1,1,1}, size=30, font='dosismedium'},
    dosismedium32 = {color={1,1,1}, size=32, font='dosismedium'},
    dosismedium44 = {color={1,1,1}, size=44, font='dosismedium'},
    orbitron = {color={.99,.76,.35}, size=65, font='orbitronlight'},
    orbitronWhite = {color={1,1,1}, size=65, font='orbitronlight'}, 
    smallSystemFont = {color={Gui.AMBER[1], Gui.AMBER[2], Gui.AMBER[3], 0.6}, size=18, font='dosissemibold'},     
    dosissemibold16 = {color={1,1,1}, size=16, font='dosissemibold'},  
    dosissemibold18 = {color={1,1,1}, size=18, font='dosissemibold'},  
    dosissemibold20 = {color={1,1,1}, size=20, font='dosissemibold'},  
    dosissemibold22 = {color={1,1,1}, size=22, font='dosissemibold'}, 
    dosissemibold24 = {color={1,1,1}, size=24, font='dosissemibold'}, 
    dosissemibold26 = {color={1,1,1}, size=26, font='dosissemibold'},  
    dosissemibold28 = {color={1,1,1}, size=28, font='dosissemibold'},  
    dosissemibold30 = {color={1,1,1}, size=30, font='dosissemibold'},
    dosissemibold32 = {color={1,1,1}, size=32, font='dosissemibold'},  
    dosissemibold35 = {color={1,1,1}, size=35, font='dosissemibold'},  
    dosissemibold38 = {color={1,1,1}, size=38, font='dosissemibold'}, 
    dosissemibold42 = {color={1,1,1}, size=42, font='dosissemibold'},  
    dosissemibold48 = {color={1,1,1}, size=48, font='dosissemibold'},
    dosisregular26 = {color={1,1,1}, size=26, font='dosisregular'},  
    dosisregular28 = {color={1,1,1}, size=28, font='dosisregular'},  
    dosisregular30 = {color={1,1,1}, size=30, font='dosisregular'},  
    dosisregular32 = {color={1,1,1}, size=32, font='dosisregular'},  
    dosisregular35 = {color={1,1,1}, size=35, font='dosisregular'},  
    dosisregular40 = {color={1,1,1}, size=40, font='dosisregular'},  
    dosisregular52 = {color={1,1,1}, size=52, font='dosisregular'},  
    dosisregular70 = {color={1,1,1}, size=70, font='dosisregular'},  
    dosisregular77 = {color={1,1,1}, size=77, font='dosisregular'},  
    dosisregular90 = {color={1,1,1}, size=90, font='dosisregular'},  
}

Gui.tDefaultCharacterRanges = 
{
}

function Gui.init()

    Gui.paneStack = {}
	
	-- create the fonts
    Gui.styles = {}
	Gui.initFonts()
	
    Gui.tWindowCloseListener = {}
    Gui.tWindowOpenListener = {}
    
    if not Gui.rOnePixelTexture then
        Gui.rOnePixelTexture = DFGraphics.loadTexture('4x4.png')
        assert(Gui.rOnePixelTexture)
	    Gui.rOnePixelDeck = MOAIGfxQuad2D.new() 
	    Gui.rOnePixelDeck:setTexture(Gui.rOnePixelTexture)
        Gui.rOnePixelDeck:setRect(0, -1, 1, 0)
    end
end

function Gui.initFonts()
    Gui.fonts = {}
	--local charcodes = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-%+$'"
	
    local fonts={
        {name='patrick',path='PatrickHand.font'},
        {name='gothic',path='LeagueGothic.font'},
        {name='nevis',path='Nevis.font'},
        {name='silkscreen',path='Silkscreen.font'},
        {name='silkscreenbold',path='SilkscreenBold.font'},
        {name='veramono',path='VeraMono.font'},
        {name='dosismedium', path='DosisMedium.font'},
        {name='orbitronlight', path='OrbitronLight.font'},
        {name='dosissemibold', path='DosisSemiBold.font'},
        {name='dosisregular', path='DosisRegular.font'},
    }

    for i,v in ipairs(fonts) do
	    Gui.fonts[ v.name ] = DFGraphics.loadFont('Fonts/'..v.path)
        if i == 1 then
	        Gui.fonts[ 'default' ] = Gui.fonts[v.name]
        end
    end
end

function Gui.getFont(sName)
	return Gui.fonts[sName or "default"]
end

function Gui.getTextStyle(sName)
    sName = sName or "default"
    if not Gui.styles[sName] then
        Gui.styles[sName] = MOAITextStyle.new()
        if Gui.styleDefs[sName] then
            local style = Gui.styles[sName]
            local def = Gui.styleDefs[sName]
            if def.color then style:setColor(unpack(def.color)) end
            if def.size then style:setSize(def.size) end
            style:setFont(Gui.getFont(def.font))
        end
    end
    return Gui.styles[sName]
end

function Gui.createTextBox(styleName, hAlign, vAlign)
	local rTextBox = MOAITextBox.new()
    rTextBox:setStyle(Gui.getTextStyle(styleName))
	rTextBox:setRect(-300, 80, 300, 0)
	rTextBox:setAlignment(hAlign or MOAITextBox.LEFT_JUSTIFY,vAlign or MOAITextBox.LEFT_JUSTIFY)
	rTextBox:setYFlip(true)
	
	return rTextBox
end

function Gui.getActivePane()
    return Gui.rCurActivePane
end

function Gui._popPaneStack()
    if #Gui.paneStack > 0 then
        local pane = Gui.paneStack[ #Gui.paneStack ]
	    Gui.rCurActivePane = pane
        if Gui.rCurActivePane.refresh then
            Gui.rCurActivePane:refresh()
        end
        print("GUI.LUA: popped pane stack. Show:", Gui.rCurActivePane.dbgName or "(no debug name)")
        Gui.paneStack[ #Gui.paneStack ] = nil
        --Gui.SetActivePane(pane)
    end
end

function Gui.setActivePane(rPane, bPush, nBasePri)
    local rOldPane = Gui.rCurActivePane
    local nextPri = 0
	if not bPush and Gui.rCurActivePane ~= nil then
        if Gui.rCurActivePane.dbgName then print("GUI.LUA: Hide",Gui.rCurActivePane.dbgName) end
		Gui.rCurActivePane:hide(true)
        -- even if we're not pushing this one, there could still be a screen stack under current pri.
        if #Gui.paneStack > 0 then
            nextPri = Gui.paneStack[ #Gui.paneStack ].maxPri
        end
    elseif Gui.rCurActivePane then
        nextPri = Gui.rCurActivePane.maxPri+1
    end
    if nBasePri then
        nextPri = nBasePri
	end

    if bPush then
        if Gui.rCurActivePane then
            Gui.paneStack[ #Gui.paneStack+1 ] = Gui.rCurActivePane
        else
            Print(TT_Warning, "GUI.LUA: Attempting to push onto gui stack while no gui element is showing.")
        end
    end

	Gui.rCurActivePane = rPane

    local pri = 0
    if Gui.rCurActivePane then
        if Gui.rCurActivePane.dbgName then print("GUI.LUA: Show",Gui.rCurActivePane.dbgName, "push?",bPush) end
	    pri = Gui.rCurActivePane:show(nextPri)
    else
        Gui._popPaneStack()
    end
    return pri
end

--[[
function Gui.addWindowCloseListener(rListener)
    Gui.windowCloseListeners[rListener] = 1
end

function Gui.removeWindowCloseListener(rListener)
    Gui.windowCloseListeners[rListener] = nil
end

function Gui.addWindowOpenListener(rListener)
    Gui.windowOpenListeners[rListener] = 1
end

function Gui.removeWindowOpenListener(rListener)
    Gui.windowOpenListeners[rListener] = nil
end
]]--

function Gui.touchInside(sx,sy)
    if Gui.rCurActivePane then
        if Gui.rCurActivePane.uiBG then
            local wx,wy = Renderer.getRenderLayer('UI'):wndToWorld(sx,sy)
            return Gui.rCurActivePane:inside(wx, wy)
        end
    end
end

function Gui.onFinger(touchEvent)
    if Gui.rCurActivePane then
        if Gui.rCurActivePane.onFinger then 
	        local renderLayer = Renderer.getRenderLayer('UI')
            local x, y = renderLayer:wndToWorld(touchEvent.x, touchEvent.y)
            local tProps = { renderLayer:getPartition():propListForPoint(x, y) }
            
            
            local overlayLayer = Renderer.getRenderLayer('UIOverlay')
            local foregroundLayer = Renderer.getRenderLayer('UIForeground')
            local scrollLayerLeft = Renderer.getRenderLayer('UIScrollLayerLeft')
            local scrollLayerRight = Renderer.getRenderLayer('UIScrollLayerRight')
            local backgroundLayer = Renderer.getRenderLayer('UIBackground')
            
            local tOverlayProps = { overlayLayer:getPartition():propListForPoint(x, y) }
            local tForegroundProps = { foregroundLayer:getPartition():propListForPoint(x, y) }
            local tScrollLayerLeftProps = { scrollLayerLeft:getPartition():propListForPoint(x, y) }
            local tScrollLayerRightProps = { scrollLayerRight:getPartition():propListForPoint(x, y) }
            local tBackgroundProps = { backgroundLayer:getPartition():propListForPoint(x, y) }
            
            
            -- merge in the overlay props to the front
            for i=#tOverlayProps,1,-1 do
                table.insert(tProps, 1, tOverlayProps[i])
            end

            for i=#tForegroundProps,1,-1 do
                table.insert(tProps, 1, tForegroundProps[i])
            end
            
            for i=#tScrollLayerLeftProps,1,-1 do
                table.insert(tProps, 1, tScrollLayerLeftProps[i])
            end

            for i=#tScrollLayerRightProps,1,-1 do
                table.insert(tProps, 1, tScrollLayerRightProps[i])
            end
            
            for i=#tBackgroundProps,1,-1 do
                table.insert(tProps, 1, tBackgroundProps[i])
            end

            
            --[[
            local realProps = {}
            for i,v in ipairs(tProps) do
                if Gui.rCurActivePane.tElementsR[v] then
                    table.insert(realProps,v)
                end
            end
            ]]--
            if Gui.rCurActivePane:onFinger(touchEvent, x, y, tProps) then
                SoundManager.playSfx( "beepHigh" )
            end
        end
        return true
	end			
	return false
end

--Gui.init()

return Gui
