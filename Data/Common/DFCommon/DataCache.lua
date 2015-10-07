local DataCache = {}

DataCache.tCacheTypes = {}

DataCache.tFlags = {
    DebugIO = false,
}

function DataCache.createCache( sType, nMaxEntries )

	assert(DataCache.tCacheTypes[sType] == nil)

	local rDataCache = {}
	DataCache.tCacheTypes[sType] = rDataCache
	
	function rDataCache:_init( nMaxEntries )

		self.nMaxEntries = nMaxEntries
        self.nNumEntries = 0
		self.tEntries = {}		
	end

	function rDataCache:_clear()
    
        self.nNumEntries = 0
		self.tEntries = {}
    end
    
	function rDataCache:_getData( sFileName )

		local tEntry = self.tEntries[sFileName]
		
		if tEntry == nil then
		
			if self.nNumEntries > self.nMaxEntries then
				self:_removeLeastRecentlyUsed()
			end
			
			Trace(TT_Cache, "DATACACHE.LUA: Cache miss: " .. sFileName)
			
			tEntry = {}
			tEntry.nAge = 0
			tEntry.tData = DataCache._loadData(sFileName)
			
			self.tEntries[sFileName] = tEntry
            self.nNumEntries = self.nNumEntries + 1
		
		else
        		
			--Trace("Cache hit: " .. sFileName)
			
			tEntry.nAge = 0
        end
		
		self:_tickEntries()
		
		return tEntry.tData

	end

	function rDataCache:_removeLeastRecentlyUsed()

		local sOldestFileName = nil
		local nOldestAge = 0
		for sFileName,tEntry in pairs(self.tEntries) do
		
			if tEntry.nAge > nOldestAge then
				sOldestFileName = sFileName
				nOldestAge = tEntry.nAge
			end
		end
		
		--Trace("Unloading: " .. sOldestFileName)
		self.tEntries[sOldestFileName] = nil
        self.nNumEntries = self.nNumEntries - 1

	end

	function rDataCache:_tickEntries()

		for sFileName,tEntry in pairs(self.tEntries) do
			tEntry.nAge = tEntry.nAge + 1
		end

	end
	
	rDataCache:_init(nMaxEntries)
	
	return rDataCache
	
end

function DataCache._loadData( sFileName )

	if not MOAIFileSystem.checkFileExists(sFileName) then
        Trace(TT_Warning, "DATACACHE.LUA: Can't open file: " .. sFileName)
		return nil
	end
	
    if DataCache.tFlags.DebugIO then
        Trace("DATACACHE.LUA: dofile(" .. sFileName .. ")")
    end
    
	return dofile(sFileName)
end

function DataCache.getData( sType, sFileName )

	local rDataCache = DataCache.tCacheTypes[sType]
	if rDataCache ~= nil then
		return rDataCache:_getData(sFileName)
	end
	
	Trace("DATACACHE.LUA: Can't cache data. Unknown cache type: " .. sType)
	
	return DataCache._loadData(sFileName)

end

function DataCache.clear( sType )

    if sType == nil then
    
        for sType,rDataCache in pairs(DataCache.tCacheTypes) do
            if rDataCache ~= nil then
                rDataCache:_clear()
            end
        end    
    else
        local rDataCache = DataCache.tCacheTypes[sType]
        if rDataCache ~= nil then
            return rDataCache:_clear()
        end
    end
end

return DataCache
