component = require("component")



local reactor = component.proxy("71bc94b4-e89e-430d-91e7-801f8511ef23")
local fluxIn = component.proxy("623d5254-2eff-4d6c-a6e8-a8edd8dfd25a")
local fluxOut = component.proxy("dadcbf04-51b9-4ae9-9fe3-fe039dd2b48c")

function rInfo(info) --- на вход параметр реактора в string ..на выход значение 
    st = reactor.getReactorInfo()
    return st[info]
end





-- fluxOut.setOverrideEnabled(false)
-- fluxIn.setOverrideEnabled(true)


-- while true do
	-- fluxIn.setFlowOverride((rInfo("fieldDrainRate")))
	-- print(rInfo("fieldDrainRate"))
	-- os.sleep(0.05)
-- end



print("temperature " .. "__________" .. rInfo("temperature"))
print("fieldStrength " .. "__________" .. rInfo("fieldStrength"))
print("maxFieldStrength " .. "__________" .. rInfo("maxFieldStrength"))
print("energySaturation " .. "__________" .. rInfo("energySaturation"))
print("maxEnergySaturation " .. "__________" .. rInfo("maxEnergySaturation"))
print("fuelConversion " .. "__________" .. rInfo("fuelConversion"))
print("maxFuelConversion " .. "__________" .. rInfo("maxFuelConversion"))
print("generationRate " .. "__________" .. rInfo("generationRate"))
print("fieldDrainRate " .. "__________" .. rInfo("fieldDrainRate"))
print("fuelConversionRate " .. "__________" .. rInfo("fuelConversionRate"))
print("status " .. "__________" .. rInfo("status") .. "/n")


-- st = reactor.getReactorInfo()

-- for i, v in pairs(st) do -- Перебираем таблицу с адресами
	-- print(i .. "$$$$$$$" .. v)
-- end
				-- temperature, 
-- fieldStrength, 
-- maxFieldStrength, 
-- energySaturation, 
-- maxEnergySaturation, 
-- fuelConversion, 
-- maxFuelConversion, 
-- generationRate, 
-- fieldDrainRate, 
-- fuelConversionRate, 
-- status]",
