component = require("component")
local reactor = component.proxy("71bc94b4-e89e-430d-91e7-801f8511ef23")
local fluxIn = component.proxy("623d5254-2eff-4d6c-a6e8-a8edd8dfd25a")
local fluxOut = component.proxy("dadcbf04-51b9-4ae9-9fe3-fe039dd2b48c")

function rInfoS(info) --- на вход параметр реактора в string ..на выход значение 
    st = reactor.getReactorInfo()
    return st[info]
end

fluxOut.setOverrideEnabled(true)
fluxOut.setFlowOverride(rInfoS("generationRate"))
fluxIn.setOverrideEnabled(true)
fluxIn.setFlowOverride((rInfoS("fieldDrainRate"))*2)
local max = rInfoS("maxFieldStrength")
local goal = max * 0.1

local extra = 0
local isExtra = true


-- local locker = true
local forceD = false
local forceU = false

while true do
	local shield = rInfoS("fieldStrength")
	local inFlow = fluxIn.getFlow()
    -- local shieldMax = rInfoS("maxFieldStrength")
	
 
--------------------------------------------------------
	while (rInfoS("fieldStrength")) < max * 0.05 do
		if isExtra then
			extra = fluxOut.getFlow()
			isExtra = false
		end
		fluxOut.setFlowOverride(0)
		fluxIn.setFlowOverride(fluxIn.getFlow() + (fluxIn.getFlow() * 0.5) + 100)
		os.sleep(0.05)		
	end
	if not isExtra then
		fluxOut.setFlowOverride(extra)
		isExtra = true
	end
--------------------------------------------------------
 
    if (shield < (goal * 0.9)) then
		fluxIn.setFlowOverride(rInfoS("fieldDrainRate") * 1.01)--1.2)
		os.sleep(0.5)
		forceU = true
		if forceD then
			-- fluxIn.setFlowOverride(rInfoS("fieldDrainRate") * 1.05)
			forceD = false
			print("forceD = false")
		end
		
		
		
		
	elseif (shield > (goal * 1.1)) then
		fluxIn.setFlowOverride(rInfoS("fieldDrainRate") * 0.99)--1.2)
		os.sleep(0.5)
		forceD = true
		if forceU then
			-- fluxIn.setFlowOverride(rInfoS("fieldDrainRate") * 1)
			forceU = false
			print("forceU = false")
		end
	
	
				--#########  === 9`900`000
	elseif shield < (goal - (goal * 0.01)) then -- goal = 10`000`000 		goal * 0.01 = 100`000`   #########  === 9`900`000
		start = rInfoS("fieldStrength")
		os.sleep(0.05)--005
		stop = rInfoS("fieldStrength")
		if (stop - start) < (max * 0.0001) then  --сотая процента от максимума = 1`000
			fluxIn.setFlowOverride(fluxIn.getFlow() + 5)-- 50 -- 100 better
		else
			fluxIn.setFlowOverride(fluxIn.getFlow() - 1)-- 50 -- 100 better
			-- os.sleep(0.05)
		
		
		
		-- if (start - stop) > 100 then    
			-- fluxIn.setFlowOverride(fluxIn.getFlow() + 50)-- 50 -- 100 better
			
			-- os.sleep(0.05)
			
		-- elseif (start - stop) > 10 then
			-- fluxIn.setFlowOverride(fluxIn.getFlow() + 5) -- 5	-- 100 better
			
			-- os.sleep(0.05)
			
		-- else
			-- fluxIn.setFlowOverride(fluxIn.getFlow() + 1)			
			
			-- os.sleep(0.05)
			
		end
		
		
	
	
	
	
	elseif shield > (goal + (goal * 0.01)) then
		start = rInfoS("fieldStrength")
		os.sleep(0.05)--005
		stop = rInfoS("fieldStrength")
		if (start - stop) < (max * 0.0001) then  --сотая процента от максимума = 1`000
			fluxIn.setFlowOverride(fluxIn.getFlow() - 5)-- 50 -- 100 better
		else
			fluxIn.setFlowOverride(fluxIn.getFlow() + 1)-- 50 -- 100 better
		
	
	
	
		-- start = rInfoS("fieldStrength")
		-- os.sleep(0.05)--005
		-- stop = rInfoS("fieldStrength")
		-- if (stop - start) > 100 then
			-- fluxIn.setFlowOverride(fluxIn.getFlow() - 50) -- 50
			
			-- os.sleep(0.05)
			
		-- elseif (stop - start) > 10 then
			-- fluxIn.setFlowOverride(fluxIn.getFlow() - 5) -- 5
			
			-- os.sleep(0.05)
			
		-- else
			-- fluxIn.setFlowOverride(fluxIn.getFlow() - 1)	
			
			-- os.sleep(0.05)
			
		end
	end
	
	if (shield < (goal + (goal * 0.001))) and (shield > (goal - (goal * 0.001))) then
		if shield < goal then
		
		
		
			fluxIn.setFlowOverride(fluxIn.getFlow() + 1)
			os.sleep(1)
		elseif shield > goal then
			fluxIn.setFlowOverride(fluxIn.getFlow() - 1)
			os.sleep(1)
		end
	end
	
	
end 