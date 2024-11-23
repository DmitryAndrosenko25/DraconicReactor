-- ДАННЫЙ МОДУЛЬ ПРИНИМАЕТ НА ВХОД ТРИ АДРЕСА + до какой температуры, ЗАПУСКАЕТ НЕОБХОДИМЫЙ РЕЖИМ ЩИТА
-- И НАЧИНАЕТ ГРЕТЬ РЕАКТОР ДО РАБОЧЕЙ ТЕМПЕРАТУРЫ

local reactorToWorkTemperature = {}

local component = require("component")
local shield = require("shield")
local reactor = nil
local fluxInGate = nil
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
	local tEnd = nil
	local tDelta = nil
	
	local correction = 0
	
	while tCurrent < tempMax do 
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
        os.sleep(0.05) 
        tEnd = rInfo("temperature")
        tDelta = (tEnd - tCurrent)		
		if (tDelta < ((tempMax - tCurrent) / 200)) then -- 200!!!!
			local saturat = rInfo("maxEnergySaturation") - (rInfo("maxEnergySaturation") - rInfo("energySaturation"))			
			-- fluxOutGate.setFlowOverride(((rInfo("generationRate") * (tempMax / tCurrent)) + ((saturat /20) /100)) + 1)
			
			correction = (rInfo("fuelConversion") / rInfo("maxFuelConversion")) / 200  -- 150 ТАК САБЕ РАБОТАЕТ
			
			
			fluxOutGate.setFlowOverride((((rInfo("generationRate") * (tempMax / tCurrent)) + ((saturat /20) /100)) * (1 - correction)) + 1) 
		else
			fluxOutGate.setFlowOverride(rInfo("generationRate") + 1)		
		end
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOutGate.setFlowOverride( rInfo("generationRate"))
end

return reactorToWorkTemperature


	-- ((rInfo("maxFuelConversion") - rInfo("fuelConversion")) / rInfo("maxFuelConversion"))
	
	-- тут нужно добавить переменную которая в самом конце разогрева тормозит набор скорости МОЖЕТ ДАЖЕ СООТНОШЕНИЕМ МАКС САТУРАЦИИ К САТУРАЦИИ??????????
	-- rInfo("fuelConversion"))
-- print("maxFuelConversion " .. "__________" .. rInfo("maxFuelConversion"))
		-- 0								10 000
	
											-- 1.0 - ~ 0.02									
									-- 
									
									
									-- ((rInfo("maxFuelConversion") - rInfo("fuelConversion")) / rInfo("maxFuelConversion"))
	