local m = {}

local DFUtil = require("DFCommon.Util")
local UIElement = require('UI.UIElement')
local DFInput = require('DFCommon.Input')
--local Character = require('Character')
local CharacterManager = require('CharacterManager')
local Character = require('CharacterConstants')
local SoundManager = require('SoundManager')
local Gui = require("UI.Gui")

local sUILayoutFileName = 'UILayouts/JobRosterEntryLayout'

local tJobInfo =
{
    [Character.BUILDER] = 'Job1',
    [Character.TECHNICIAN] = 'Job2',
    [Character.MINER] = 'Job3',
    [Character.EMERGENCY] = 'Job4',
    [Character.BARTENDER] = 'Job5',
    [Character.BOTANIST] = 'Job6',
    [Character.SCIENTIST] = 'Job7',
    [Character.DOCTOR] = 'Job8',
    [Character.JANITOR] = 'Job9',
    [Character.UNEMPLOYED] = 'Job10'
}
local tJobTextureInfo =
{
    [Character.TECHNICIAN] = Character.JOB_ICONS[Character.TECHNICIAN],
    [Character.BUILDER] = Character.JOB_ICONS[Character.BUILDER],
    [Character.MINER] = Character.JOB_ICONS[Character.MINER],
    [Character.EMERGENCY] = Character.JOB_ICONS[Character.EMERGENCY],
    [Character.BARTENDER] = Character.JOB_ICONS[Character.BARTENDER],
    [Character.BOTANIST] = Character.JOB_ICONS[Character.BOTANIST],
    [Character.SCIENTIST] = Character.JOB_ICONS[Character.SCIENTIST],
    [Character.DOCTOR] = Character.JOB_ICONS[Character.DOCTOR],
    [Character.JANITOR] = Character.JOB_ICONS[Character.TECHNICIAN],
    [Character.UNEMPLOYED] = Character.JOB_ICONS[Character.UNEMPLOYED]
}
local tJobCompetencyTexture =
{
    [Character.BUILDER] = 'Job1SkillLevel',
    [Character.TECHNICIAN] = 'Job2SkillLevel',
    [Character.MINER] = 'Job3SkillLevel',
    [Character.EMERGENCY] = 'Job4SkillLevel',
    [Character.BARTENDER] = 'Job5SkillLevel',
    [Character.BOTANIST] = 'Job6SkillLevel',
    [Character.SCIENTIST] = 'Job7SkillLevel',
    [Character.DOCTOR] = 'Job8SkillLevel',
    [Character.JANITOR] = 'Job9SkillLevel',
}
local tCompetencyInfo =
{
    {
        nMinCompetency = 0,
        sTextureName = 'ui_jobs_skillrank1'
    },
    {
        nMinCompetency = .16,
        sTextureName = 'ui_jobs_skillrank2'
    },
    {
        nMinCompetency = .28,
        sTextureName = 'ui_jobs_skillrank3'
    },
    {
        nMinCompetency = .60,
        sTextureName = 'ui_jobs_skillrank4'
    },
    {
        nMinCompetency = .90,
        sTextureName = 'ui_jobs_skillrank5'
    },
}
local tJobCompetencyColors =
{
    ui_jobs_skillrank1 = Character.JOB_COMPETENCY_COLORS[Character.COMPETENCY_LEVEL1],
    ui_jobs_skillrank2 = Character.JOB_COMPETENCY_COLORS[Character.COMPETENCY_LEVEL2],
    ui_jobs_skillrank3 = Character.JOB_COMPETENCY_COLORS[Character.COMPETENCY_LEVEL3],
    ui_jobs_skillrank4 = Character.JOB_COMPETENCY_COLORS[Character.COMPETENCY_LEVEL4],
    ui_jobs_skillrank5 = Character.JOB_COMPETENCY_COLORS[Character.COMPETENCY_LEVEL5],
}
local tJobBGInfo =
{
    [Character.BUILDER] = 'ActiveJob1BG',
    [Character.TECHNICIAN] = 'ActiveJob2BG',
    [Character.MINER] = 'ActiveJob3BG',
    [Character.EMERGENCY] = 'ActiveJob4BG',
    [Character.BARTENDER] = 'ActiveJob5BG',
    [Character.BOTANIST] = 'ActiveJob6BG',
    [Character.SCIENTIST] = 'ActiveJob7BG',
    [Character.DOCTOR] = 'ActiveJob8BG',
    [Character.JANITOR] = 'ActiveJob9BG',
}
local tJobButtonButtonMapping =
{
    [Character.BUILDER] = 'Job1Button',
    [Character.TECHNICIAN] = 'Job2Button',
    [Character.MINER] = 'Job3Button',
    [Character.EMERGENCY] = 'Job4Button',
    [Character.BARTENDER] = 'Job5Button',
    [Character.BOTANIST] = 'Job6Button',
    [Character.SCIENTIST] = 'Job7Button',
    [Character.DOCTOR] = 'Job8Button',
    [Character.JANITOR] = 'Job9Button',
    [Character.UNEMPLOYED] = 'UnassignedJobButton',
}

function m.create()
    local Ob = DFUtil.createSubclass(UIElement.create())
    Ob.rCitizen = nil

    function Ob:init()
        self:setRenderLayer('UIScrollLayerLeft')

        Ob.Parent.init(self)
        self:processUIInfo(sUILayoutFileName)

        self.rNameLabel = self:getTemplateElement('NameLabel')
        self.rNameButton = self:getTemplateElement('NameButton')

        self.tJobButtons = {}
        for eJob, sElementName in pairs(tJobButtonButtonMapping) do
            local rButton = self:getTemplateElement(sElementName)
            rButton:addPressedCallback(self.onJobButtonPressed, self)
            self.tJobButtons[rButton] = eJob
        end
        self.tJobBGTextures = {}
        for eJob, sElementName in pairs(tJobBGInfo) do
            local rBGTexture = self:getTemplateElement(sElementName)
            self.tJobBGTextures[eJob] = rBGTexture
        end
		self.tAffIcons = {}
		for i,_ in pairs(Character.tJobs) do
			self.tAffIcons[i] = self:getTemplateElement('Job'..i..'Aff')
		end

        self.rActiveJobInfo = self:getExtraTemplateInfo('tActiveJobInfo')
        self:_calcDimsFromElements()
        self.rNameButton:addPressedCallback(self.onNameButtonPressed, self)
    end

    function Ob:setJob(eJob)
        if eJob then
            local sInfoKey = tJobInfo[eJob]
            if sInfoKey then
                local rOverride = self.rActiveJobInfo[sInfoKey]
                if rOverride then
                    self:applyTemplateInfos(rOverride)
                end
            end
            local sTextureName = tJobTextureInfo[eJob]
            if sTextureName then
                self:setTemplateUITexture('JobTexture', sTextureName, 'UI/JobRoster')
            end
            for rButton, eExistingJob in pairs(self.tJobButtons) do
                rButton:setSelected(eExistingJob == eJob)
            end
        end
    end

    function Ob:onTick(dt)
        if self.rCitizen then
            local eCurJob = self.rCitizen:getJob()
            if self.eJobAtLastTick ~= eCurJob then
                self:setJob(eCurJob)
            end
            for eJob, sTextureElement in pairs(tJobCompetencyTexture) do
                local sTextureToUse = nil
                local nCompetency = self.rCitizen:getBaseJobCompetency(eJob)
                for i, rCompetencyInfo in ipairs(tCompetencyInfo) do
                    if nCompetency > rCompetencyInfo.nMinCompetency then
                        sTextureToUse = rCompetencyInfo.sTextureName
                    end
                end
                if sTextureToUse then
                    self:setTemplateUITexture(sTextureElement, sTextureToUse, 'UI/JobRoster')
                    local tColorInfo = tJobCompetencyColors[sTextureToUse]
                    if tColorInfo and self.tJobBGTextures[eJob] then
                        self.tJobBGTextures[eJob]:setColor(tColorInfo[1], tColorInfo[2], tColorInfo[3])
                    end
                end
            end
            self.eJobAtLastTick = eCurJob
			-- show affinity
			-- icons line up with jobs b/c we iterate through the same list as above
			for i,nJob in pairs(Character.tJobs) do
				local nAff = self.rCitizen:getJobAffinity(nJob)
				local sIcon,tColor = self.rCitizen:getAffinityIconAndColor(nAff)
				self:setTemplateUITexture('Job'..i..'Aff', sIcon, 'UI/Emoticons')
				self.tAffIcons[i]:setColor(unpack(tColor))
			end
        end
    end

    function Ob:onJobButtonPressed(rButton, eventType)
        if rButton and self.rCitizen and eventType == DFInput.TOUCH_UP then
            local eJob = self.tJobButtons[rButton]
            if eJob then
                self.rCitizen:setJob(eJob)
                SoundManager.playSfx('inspectorduty')
            end
        end
    end

    function Ob:onNameButtonPressed(rButton, eventType)
        if rButton and self.rCitizen and eventType == DFInput.TOUCH_UP then
            g_GuiManager.setSelected(self.rCitizen)
            g_GuiManager.newSideBar:closeSubmenu()
        end
    end

    function Ob:setCitizen(rCitizen)
        self.rCitizen = rCitizen

        if rCitizen then
            self.rNameLabel:setString(self.rCitizen:getNiceName())
        end
    end

    function Ob:isActive()
        if self.rCitizen then
            return true
        else
            return false
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