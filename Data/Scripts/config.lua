MOAILogMgr.setLogLevel ( MOAILogMgr.LOG_STATUS )

MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAI_FileNotFound_S, 'File not found: %s' )
MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAI_IndexNoReserved, 'Nothing reserved' )
MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAI_IndexOutOfRange_DDD, 'Index %d is out of acceptable range [%d, %d]' )
MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAI_NewIsUnsupported, 'Method \'new\' is unsupported. Instances of this class are created by the engine or through another interface.' )
MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAI_ParamTypeMismatch, 'Param type mismatch; check function call' )

MOAILogMgr.registerLogMessage ( MOAILogMgr.MOAINode_AttributeNotFound, 'No such attribute' )

ENV_DEFAULTS = {}
ENV_DEFAULTS.appID = 'com.doublefine.space'
ENV_DEFAULTS.appDisplayName = 'Space'
ENV_DEFAULTS.appVersion = "0.0.1"
ENV_DEFAULTS.appBuild = "1"
ENV_DEFAULTS.connectionType = MOAIEnvironment.CONNECTION_TYPE_WIFI

for k,v in pairs(ENV_DEFAULTS) do
    if MOAIEnvironment[k]==nil then
        MOAIEnvironment[k] = v
    end
end

package.path = "Data/Scripts/?.lua;Data/Common/?.lua;Data/Moai/?.lua"

if MOAIEnvironment.osBrand == "Windows" or MOAIEnvironment.osBrand == "OSX" then
    MOAIEnvironment.documentDirectory = MOAIEnvironment.documentDirectory.."/SpacebaseDF9"
elseif MOAIEnvironment.osBrand == "Linux" then
    MOAIEnvironment.documentDirectory = MOAIEnvironment.documentDirectory.."/doublefine/spacebasedf9"
end

-- for controlling what you see in your logging console
g_tTraceOutput = 
{
    TT_Error = true,
    TT_Warning = true,
    TT_System = true,
    TT_Gameplay = true,    
    TT_Info = true,
}

g_tSoundProjects = 
{
	tFEV =
	{
		"SFX/SFX.fev",
		"Music/Music.fev",
        "UI/UI.fev",
		"Voice/Voice.fev",	
		"SpaceBaseV2/SpaceBaseV2.fev"
	},
	tFSB =
	{	
		--"MainGame_enUS/enUS_Streaming.fsb",
	},
	bStartMuted=false,
}

function print(...) return Print(TT_Info, ...) end

assertdev = function() end

MOAILogMgr.openFile(string.format('moai_log_%s.txt', MOAIEnvironment.appDisplayName))        

local BootConfig = require('BootConfig')
g_Config = BootConfig.init()

-- JIT and profiling
local jit = require('jit')
local Profile = require('Profile')
local DFUtil = require('DFCommon.Util')

