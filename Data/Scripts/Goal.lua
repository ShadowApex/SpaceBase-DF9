local GameRules = require('GameRules')
local Base = require('Base')
local GoalData = require('GoalData')

local Goal = { profilerName='Goals' }

Goal.tickIndex = 1

-- table of goal progress numbers
Goal.tGoalProgress = {}

function Goal.init()
	Goal.nTicks = 0
end

function Goal.getNumCompletedGoals()
	local nGoals = 0
	for _,tGoal in pairs(GoalData.tGoals) do
		if Base.tS.tGoals[tGoal.sName] then
			nGoals = nGoals + 1
		end
	end
	return nGoals
end

function Goal.onTick(dt)
	-- tick one goal per tick, for simplicity -
	-- rapid response for these is even less critical than hints
	Goal.tickIndex = Goal.tickIndex + 1
	if Goal.tickIndex > #GoalData.tGoals then
		Goal.tickIndex = 1
	end
	local tGoal = GoalData.tGoals[Goal.tickIndex]
	assert(tGoal ~= nil)
	-- we might not have initialized yet
	if not Base.tS.tGoals then return end
	-- don't check completed goals, iterate until we find an uncompleted one
    -- if we go off the end, that's fine, we'll get it next tick.
	while tGoal and Base.tS.tGoals[tGoal.sName] == true do
		Goal.tickIndex = Goal.tickIndex+1
		tGoal = GoalData.tGoals[Goal.tickIndex]
	end
	-- completed all goals?
	if not tGoal then
		return
	end
	assert(tGoal.checkFn ~= nil)
	-- check and store progress in a table so UI can just use that
	local bCompleted,nProgress = tGoal.checkFn()
	if bCompleted then
		Base.tS.tGoals[tGoal.sName] = true
		-- show alert
		-- (but not on first tick; those were completed in a prior session)
		if Goal.nTicks > #GoalData.tGoals then
			local sGoalName = g_LM.line(tGoal.sNameLC)
			Base.eventOccurred(Base.EVENTS.GoalCompleted, {sGoal=sGoalName})
			-- TODO: this is where we'd trigger Steam achievements
		end
	end
	Goal.tGoalProgress[tGoal.sName] = nProgress
	if Goal.nTicks <= #GoalData.tGoals then
		Goal.nTicks = Goal.nTicks + 1
	end
end

return Goal
