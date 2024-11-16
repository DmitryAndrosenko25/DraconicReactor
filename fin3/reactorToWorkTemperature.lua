-- ДАННЫЙ МОДУЛЬ ПРИНИМАЕТ НА ВХОД ТРИ АДРЕСА, ЗАПУСКАЕТ НЕОБХОДИМЫЙ РЕЖИМ ЩИТА
-- И НАЧИНАЕТ ГРЕТЬ РЕАКТОР ДО РАБОЧЕЙ ТЕМПЕРАТУРЫ

local reactorToWorkTemperature = {}

local component = require("component")
local shield = require("shield")

local reactor = nil
-- local fluxInGate = nil
local fluxOutGate = nil

local function rInfo(info) --- на вход параметр реактора в string ..на выход значение 
	local st = reactor.getReactorInfo()
	return st[info]
end

local function starter()				-- Запуск разогретого до 2000 реактора/ перевод его в статус running
	fluxOutGate.setOverrideEnabled(true)
    fluxOutGate.setFlowOverride(0)
    
    if rInfo("status") ~= "running" then         --ЗАПУСК РЕАКТОРА
        if reactor.activateReactor() then 
            print("Реактор запустился из модуля reactorToWorkTemperature")
        else
            -- fluxInGate.setFlowOverride(1)
            local temp = fluxInGate.getFlow()
            local run = true
            print("стартер реактора гудит...")
            while run do         
                if reactor.activateReactor() then
                    run = false
                else
                    fluxInGate.setFlowOverride(temp +1)
                    os.sleep(0.05)
                    temp = fluxInGate.getFlow()
                end
            end
            print("Реактор запустился из модуля reactorToWorkTemperature")
        end
    else
       print("Реактор запущен из модуля reactorToWorkTemperature") 
    end
end

function reactorToWorkTemperature.startHeating(reactorAddress, fluxInAddress, fluxOutAddress, tempMax)
	reactor = component.proxy(reactorAddress) -- Подключение к реактору и гейтам
	fluxInGate = component.proxy(fluxInAddress)
	fluxOutGate = component.proxy(fluxOutAddress)
		
	--===================================================================================
	print("Начинаются попытки установки безопасного щита")
	shield.setReactor(reactorAddress, fluxInAddress)	--\
	shield.setLevel(1.5)												 --\ ~33% щита
	local coroutineShield = coroutine.create(shield.runShield)		 	 --/ запуск щита
	coroutine.resume(coroutineShield) -- Выведет "Начало корутины"		--/
	print("Попытки установки безопасного щита закончены")
	--===================================================================================
	
	if rInfo("status") ~= "running" then
		starter()		
	end
	
	--=============================ОСНОВНАЯ ЧАСТЬ РАЗОГРЕВА==========================================
	print(string.format("Разогрев ректора до %d", tempMax))
	fluxOutGate.setOverrideEnabled(true)
    fluxOutGate.setFlowOverride(rInfo("generationRate")) -- минимальный старт разогрева
	
	local tCurrent = rInfo("temperature")
	-- local tStart = nil
	local tEnd = nil
	local tDelta = nil
	local outFlow = fluxOutGate.getFlow()
	local multy = 1
	local pulty = 1
	-- local onePercentLeft = nil
	-- local tempSpeed = nil
	local up = 1
	
	local extraStop1 = true
	local extraStop2 = true
	local extraStop3 = true
	
	
	
	while tCurrent <= (tempMax) do 
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
        os.sleep(0.05) 
        tEnd = rInfo("temperature")
        tDelta = (tEnd - tCurrent)
		multy = 1
		--==================================================================================
		-- print("energySaturation " .. "__________" .. rInfo("energySaturation"))
		-- print("maxEnergySaturation " .. "__________" .. rInfo("maxEnergySaturation"))
		-- ОБРАЗЕЦ РАБОЧЕГО АЛГОРИТМА
		--[[
		if (tDelta < ((tempMax - tCurrent) / 200)) then -- 50
			-- fluxOutGate.setFlowOverride(rInfo("generationRate") * (tempMax / tCurrent) + 1)		-- СТАРАЯ ВЕРСИЯ
			fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) /10 ))	-- РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
		elseif (tDelta > ((tempMax - tCurrent) / 100)) then	 --40
			fluxOutGate.setFlowOverride(rInfo("generationRate"))
		end 
		
		
		
		--]]
		-- if (tDelta < ((tempMax - tCurrent) / 200)) then -- 50
			-- Это почти идеал!!!!!!!!!!!
			
			-- fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) /10 ))	-- РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
		-- elseif (tDelta > ((tempMax - tCurrent) / 100)) then	 --40
			-- fluxOutGate.setFlowOverride(rInfo("generationRate"))
		-- end 
		
		if (tDelta < ((tempMax - tCurrent) / 200)) then -- 200!!!!
			-- Это почти идеал!!!!!!!!!!!
			
			-- fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) + up ))	-- /10!!! РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
			-- local del = (rInfo("energySaturation") / rInfo("maxEnergySaturation")) * 3
			
			local saturat = rInfo("maxEnergySaturation") - (rInfo("maxEnergySaturation") - rInfo("energySaturation"))
			-- fluxOutGate.setFlowOverride((rInfo("generationRate") * ((tempMax / tCurrent) + (rInfo("energySaturation") / rInfo("maxEnergySaturation")))) + 1) -- (rInfo("generationRate") * del))	-- /10!!! РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
			fluxOutGate.setFlowOverride(((rInfo("generationRate") * (tempMax / tCurrent)) + ((saturat /20) /200)) + 1) -- (rInfo("generationRate") * del))	-- /10!!! РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
			-- up = up + 1
		
		
		-- elseif (tDelta > ((tempMax - tCurrent) / 100)) then	 --40
			-- fluxOutGate.setFlowOverride(1)
		
		-- elseif (tDelta > ((tempMax - tCurrent) / 140)) then	 --40
			-- fluxOutGate.setFlowOverride(rInfo("generationRate"))
			up = 1
		
		-- elseif (tDelta > ((tempMax - tCurrent) / 180)) then	 --40
			-- fluxOutGate.setFlowOverride(fluxOutGate.getFlow.getFlow() * 0.9)
		else
			fluxOutGate.setFlowOverride(rInfo("generationRate") + 1)
		
		end
		
		--==================================================================================
		--[[
		if (((rInfo("maxEnergySaturation") * 0.5 ) > rInfo("energySaturation")) and extraStop) then -- Экстренный стопкран
			extraStop1 = false
			-- fluxOutGate.setFlowOverride(rInfo("generationRate"))			
			fluxOutGate.setFlowOverride(1)			
		end
		
		if (((rInfo("maxEnergySaturation") * 0.2 ) > rInfo("energySaturation")) and extraStop) then -- Экстренный стопкран
			extraStop2 = false
			-- fluxOutGate.setFlowOverride(rInfo("generationRate"))			
			fluxOutGate.setFlowOverride(1)			
		end
		
		if (((rInfo("maxEnergySaturation") * 0.04 ) > rInfo("energySaturation")) and extraStop) then -- Экстренный стопкран
			extraStop3 = false
			-- fluxOutGate.setFlowOverride(rInfo("generationRate"))			
			fluxOutGate.setFlowOverride(1)		
		end
		
		
		if ((tempMax - tCurrent) > 1000) then -- если РАЗНИЦА температур больше 1000
			multy = multy * 10
		end		
		if ((tempMax - tCurrent) > 100) then -- если РАЗНИЦА температур больше 100
			multy = multy * 10
		end
		if ((tempMax - tCurrent) < 10) then -- если РАЗНИЦА температур больше 10
			multy = 5
		end
		
		
		if (tDelta < ((tempMax - tCurrent) / 200 / 100)) then 
			fluxOutGate.setFlowOverride(rInfo("generationRate") * (tempMax / tCurrent) + multy + pulty)
			pulty = pulty + 1
			
		elseif (tDelta > ((tempMax - tCurrent) / 40 / 100)) then 
			fluxOutGate.setFlowOverride(rInfo("generationRate") * (tempMax / tCurrent))
			pulty = pulty - 1
		elseif (tDelta > ((tempMax - tCurrent) / 1 / 100)) then 
			fluxOutGate.setFlowOverride(rInfo("generationRate"))
			pulty = 1
		end
		--]]
		--========================================================================================================
		
		--[[
			-- fluxOutGate.setFlowOverride(rInfo("generationRate") * (tempMax / tCurrent) + 1)		-- СТАРАЯ ВЕРСИЯ
									-- fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) /10 ))	-- РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
			-- fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) * 100 ) + 10)	-- /10     РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
		
		
		-- elseif (tDelta > ((tempMax - tCurrent) / 10)) then	 --40
			-- tempSpeed = fluxOutGate.getFlow()
			-- fluxOutGate.setFlowOverride(fluxOutGate.getFlow() * 0.9999)
		
		
		-- elseif (tDelta > ((tempMax - tCurrent) * 1)) then	 --40
			-- fluxOutGate.setFlowOverride(rInfo("generationRate"))
		-- end 
		
		
		
		
		onePercentLeft = ((tempMax - tCurrent) * 0.01)	-- (13 000 - 8 320) = 4 680 * 0.01 = 46.80
														-- (13 000 - 11 140) = 1 860 * 0.01 = 18.60
														-- Один процент от оставшейся набрать температуры
		outFlow = fluxOutGate.getFlow()
		
		if tDelta < 0 then
			outFlow = (rInfo("generationRate") + (rInfo("generationRate") * 0.01) + 1)
		else



			if (tDelta > (onePercentLeft * 0.2)) then
				if (tDelta > (onePercentLeft * 1)) then
					if (tDelta > (onePercentLeft * 10)) then
						outFlow = outFlow * 0.9
					else
						outFlow = outFlow * 0.99					
					end
				else
					outFlow = outFlow * 0.999
				end
			
			end
		



		
			if (tDelta < (onePercentLeft * 0.1)) then
				if (tDelta < (onePercentLeft * 0.05)) then
					if(tDelta < (onePercentLeft * 0.01)) then
						outFlow = outFlow + (outFlow * 0.01) + 1
					else
						outFlow = outFlow + (outFlow * 0.05) + 1
					end
				else
					outFlow = outFlow + (outFlow * 0.1) + 1
				end
				
			end
			
			
			
		end
		
	
		
		
		
		fluxOutGate.setFlowOverride(outFlow)
		
		
		
		--]]
		
		
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOutGate.setFlowOverride( rInfo("generationRate"))
end




return reactorToWorkTemperature