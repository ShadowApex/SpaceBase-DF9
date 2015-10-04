local DFUtil=require('DFCommon.Util')

local ErrorReporting = {}

ErrorReporting.bEnabled = true
--ErrorReporting.bEnabled = not DFSpace.isDev()
ErrorReporting.bUserLocalServer = true --this will be changed when we have a permanent server for error logs to be sent to

ErrorReporting.LOCAL_URL = "http://localhost:8089/error"
ErrorReporting.PROD_URL = "http://dfp-space.appspot.com/error"

ErrorReporting.URL = ErrorReporting.PROD_URL

if ErrorReporting.bUserLocalServer then
    ErrorReporting.URL = ErrorReporting.LOCAL_URL
end

function ErrorReporting.init()
    if ErrorReporting.bEnabled then
        local function onError(message)
            if not g_Config:getConfigValue("crash_reporting") then return end
            -- only want to get 1 traceback through this function so we don't spam errors
            MOAISim.setTraceback(function(message) end)
        
            local errorLogBuffer = MOAIDataBuffer.new()
            errorLogBuffer:base64Encode(message)    

            local stackTrace = tostring(debug.traceback())       
            local abbrevStackLen = math.min(#stackTrace, 384)  
            local abbrevStackTrace = string.sub(stackTrace, 0, abbrevStackLen)
            
            local stackBuffer = MOAIDataBuffer.new()
            stackBuffer:base64Encode(abbrevStackTrace)
            
            -- call into our own error handler
            local errorVars = {}
            errorVars.buildId = MOAIEnvironment.appVersion
            local sExtraLogString = ""
            if MOAIEnvironment.appVersion then
                sExtraLogString = sExtraLogString .. "appVersion: "..MOAIEnvironment.appVersion.." "
            end
            if MOAIEnvironment.appBuild then
                sExtraLogString = sExtraLogString .. "appBuild: "..MOAIEnvironment.appBuild.." "
            end
            if MOAIEnvironment.devBrand then
                sExtraLogString = sExtraLogString .. "devBrand: "..MOAIEnvironment.devBrand.." "
            end
            if MOAIEnvironment.devName then
                sExtraLogString = sExtraLogString .. "devName: "..MOAIEnvironment.devName.." "
            end
            if MOAIEnvironment.devManufacturer then
                sExtraLogString = sExtraLogString .. "devManufacturer: "..MOAIEnvironment.devManufacturer.." "
            end
            if MOAIEnvironment.devModel then
                sExtraLogString = sExtraLogString .. "devModel: "..MOAIEnvironment.devModel.." "
            end
            if MOAIEnvironment.osVersion then
                sExtraLogString = sExtraLogString .. "osVersion: "..MOAIEnvironment.osVersion.." "
            end
            errorVars.log = message.." "..sExtraLogString --errorLogBuffer:getString()
            errorVars.stack = abbrevStackTrace --stackBuffer:getString()
            errorVars.type = "lua"
            
            local errorUrl = ErrorReporting.URL .. "?"
            errorUrl = errorUrl .. "&buildId=" .. errorVars.buildId
            errorUrl = errorUrl .. "&log=" .. errorVars.log
            errorUrl = errorUrl .. "&stack=" .. errorVars.stack 
            errorUrl = errorUrl .. "&type=" .. errorVars.type
            
            
			print("\n\n***********************\n\n" .. "Main error: " .. errorVars.log .. "\nStackTrace: " .. errorVars.stack .. "\nError Type: "..errorVars.type .. "\n\n***********************\n\n")
            
            local errorVarsString = MOAIJsonParser.encode(errorVars)
            
            local errorBuffer = MOAIDataBuffer.new()
            errorBuffer:base64Encode(errorVarsString)
            
            --print("errorVarsString:" .. errorVarsString .. "")
            
            -- we ended up using POST instead of GET because we can send larger buffers of weird data
            local httpTask = MOAIHttpTask.new()
            print("new task!")
            local errorBufferString = errorBuffer:getString()
            print("fully encoded buffer: " .. errorBufferString)
            httpTask:httpPost(ErrorReporting.URL, errorBufferString, nil, nil, true)
            print("posting nowwwww")
            DFUtil.timedCallback(4, MOAIAction.ACTIONTYPE_UI, nil, function() MOAISim.crash() end)
        end
        
        MOAISim.setTraceback(onError)
    end
end



return ErrorReporting
