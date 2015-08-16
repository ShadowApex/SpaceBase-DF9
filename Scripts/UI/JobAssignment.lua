local Gui = require('UI.Gui')
local DFUtil = require("DFCommon.Util")
local DFInput = require('DFCommon.Input')
local UIElement = require('UI.UIElement')
local Renderer = require('Renderer')
local Character = require('Character')
local CharacterManager = require('CharacterManager')
local SoundManager = require('SoundManager')

local m = {}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())

    Ob.jobs=
    {
        { enum = Character.UNEMPLOYED, name = g_LM.line("DUTIES001TEXT"), desc = g_LM.line("DUTIES002TEXT"), sound = "unemployed"}, 
        { enum = Character.BUILDER, name = g_LM.line("DUTIES003TEXT"), desc = g_LM.line("DUTIES004TEXT"), sound = "builder"},
        { enum = Character.TECHNICIAN, name = g_LM.line("DUTIES005TEXT"), desc = g_LM.line("DUTIES006TEXT"), sound = "technician"},
        { enum = Character.MINER, name = g_LM.line("DUTIES007TEXT"), desc = g_LM.line("DUTIES008TEXT"), sound = "miner"},
        { enum = Character.EMERGENCY, name = g_LM.line("DUTIES009TEXT"), desc = g_LM.line("DUTIES010TEXT"), sound = "emergency"},
        { enum = Character.BARTENDER, name = g_LM.line("DUTIES013TEXT"), desc = g_LM.line("DUTIES014TEXT"), sound = "emergency"},
        { enum = Character.BOTANIST, name = g_LM.line("DUTIES016TEXT"), desc = g_LM.line("DUTIES017TEXT"), sound = "emergency"},
		{ enum = Character.JANITOR, name = g_LM.line("DUTIES022TEXT"), desc = g_LM.line("DUTIES023TEXT"), sound = "emergency"},
		{ enum = Character.TRADER, name = g_LM.line("DUTIES024TEXT"), desc = g_LM.line("DUTIES025TEXT"), sound = "emergency"},
    }
    
    function Ob:init(w)
        Ob.Parent.init(self)

        self.width = w
        self.height = 40
        self.color = {0/255,115/255,186/255}
        self.darkColor = {0/255,0/255,0/255}
        self.highlightColor = {0/255,80/255,135/255}
        self.bg = self:addRect(w,1,unpack(self.color))
        self.buttonHash = {}
        local margin=5
        local marginInner=7
        local boxh=150
        local y=-margin
        for i,j in ipairs(self.jobs) do
            local r = self:addRect(w-2*margin,boxh,unpack(self.darkColor))
            r:setLoc(margin,y)
            self.buttonHash[r] = i

            r = self:addRect(w-2*marginInner,boxh-4,unpack(self.color))
            self.buttonHash[r] = i
            j.unselectedRect = r
            r:setLoc(marginInner,y-2)

            r = self:addRect(w-2*marginInner,boxh-4,unpack(self.highlightColor))
            self.buttonHash[r] = i
            j.highlightRect = r
            r:setLoc(marginInner,y-2)

            local text = self:addTextBox(j.name, "gothicTitleWhite",0,0,w-marginInner*2,boxh*.5,margin*2,y-boxh*.5)
            text = self:addTextBox(j.desc, "nevisBodyWhite",0,0,w-marginInner*2,boxh*.5,margin*2,y-boxh)

            j.skillText = self:addTextBox("", "nevisBodyWhite",0,0,w-marginInner*2-10,boxh*.45,margin*2,y-boxh*.5, MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY)
            j.currentText = self:addTextBox("", "nevisBodyWhite",0,0,w-marginInner*2-10,boxh*.45,margin*2,y-boxh*.4, MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.RIGHT_JUSTIFY)

            y=y-boxh-margin
        end
        self.bg:setScl(w,-y)
    end

    function Ob:updateSelected()
        self.selected = g_GuiManager.getSelectedCharacter()
        if not self.selected then
            self:hide()
        else
            for i,j in ipairs(self.jobs) do
                if j.enum == self.selected:getJob() then
                    j.highlightRect:setVisible(true)
                    j.unselectedRect:setVisible(false)
                                        
                else
                    j.highlightRect:setVisible(false)
                    j.unselectedRect:setVisible(true)
                end
                if j.enum ~= Character.UNEMPLOYED then
                    j.skillText:setString("Skill: "..self.selected:getJobCompetency(j.enum))
                end
                j.currentText:setString("Current: "..CharacterManager.tJobCount[j.enum])
            end
        end
    end

    function Ob:inside(wx,wy)
        return self.bg:inside(wx,wy)
    end

    function Ob:show(basePri)
        local pri = Ob.Parent.show(self,basePri)
        SoundManager.playSfx("assignnewduty")
        self:refresh()
        return pri
    end

    function Ob:refresh()
        self:updateSelected()
    end

    function Ob:onFinger(touch, x, y, props)
        if touch.eventType == DFInput.TOUCH_UP then
            for _,v in ipairs(props) do
                local idx = self.buttonHash[v]
                if idx then
                    self.selected:setJob(self.jobs[idx].enum)
                    SoundManager.playSfx(self.jobs[idx].sound)
                    return true
                end
            end
        end
    end

    return Ob
end

function m.new(...)
    local Ob = m.create()
    Ob:init(...)

    return Ob
end

return m
