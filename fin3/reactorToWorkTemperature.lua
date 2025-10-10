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
	local multy = 1
	
	while tCurrent < tempMax do 
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
        os.sleep(0.05) 
        tEnd = rInfo("temperature")
        tDelta = (tEnd - tCurrent)		
		if (tDelta < ((tempMax - tCurrent) / 200)) then -- 200!!!!
			-----------------------------------------
			multy = 1
			if (tempMax - tCurrent) > 1000 then
				multy = 4
			elseif (tempMax - tCurrent) > 300 then
				multy = 2.5					
			elseif (tempMax - tCurrent) > 200 then
				multy = 1.5
			elseif (tempMax - tCurrent) > 100 then
				multy = 1.25				
			elseif (tempMax - tCurrent) > 10 then
				multy = 1
			elseif (tempMax - tCurrent) > 1 then
				multy = 0.999
			elseif (tempMax - tCurrent) > 0.1 then
				multy = 0.99
			else										----------------------------------------- последняя коррекция
				multy = 0.95				
			end			
			-----------------------------------------
			local saturat = rInfo("maxEnergySaturation") - (rInfo("maxEnergySaturation") - rInfo("energySaturation"))			
			correction = (rInfo("fuelConversion") / rInfo("maxFuelConversion")) / 200
			fluxOutGate.setFlowOverride(((((rInfo("generationRate") * (tempMax / tCurrent)) + ((saturat /20) /100)) * (1 - correction)) + 1) * multy)
		else
			fluxOutGate.setFlowOverride(rInfo("generationRate") + 1)
		end
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOutGate.setFlowOverride( rInfo("generationRate"))
end

return reactorToWorkTemperature