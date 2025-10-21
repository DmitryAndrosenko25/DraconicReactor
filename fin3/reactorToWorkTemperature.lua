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
	
	reactor = component.proxy(reactorAddress) 		-- Подключение к реактору и гейтам
	fluxInGate = component.proxy(fluxInAddress)		--
	fluxOutGate = component.proxy(fluxOutAddress)	--
		
	
	print("Начинаются попытки установки экстремального щита")
	local coroutineShieldExtrm = coroutine.create(shield.runShieldExtreme)	 --/ запуск щита
	-- coroutine.resume(coroutineShieldExtrm) -- Выведет "Начало корутины"		--/
	print("Попытки установки экстремального щита закончены")
	
	
	
	--===================================================================================
	print("Начинаются попытки установки безопасного щита")
	shield.setReactor(reactorAddress, fluxInAddress)	--\
	shield.setLevel(1.4)												 --\ ~33% щита
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
	
	local tMax = tempMax
	local tEnd = rInfo("temperature")
	local multy = 1
	local costyl = 1
	local balance = 0 -- переменная балансир, когда силы основной формулы не хватает для балансировки
	
	local shieldCount = 0 -- от 0 до 150 счетчик, который переключает экстремальный и безопасный щита
	
	while true do --?????????????????????? 
		
		if rInfo("status") == "cold" then
			multy = 1
			costyl = 1
			balance = 0
			print ("реактор остановлен.")
			break
		elseif rInfo("status") == "cooling" then
			multy = 1
			costyl = 1
			balance = 0			
			fluxOutGate.setFlowOverride(0)
			coroutine.resume(coroutineShield)
		
		--warming_up?????
		
		elseif rInfo("status") == "running" then
			
			
		
			if math.abs(tMax - tEnd) >= 0.2 then
				shieldCount = 0
			else
				if shieldCount < 150 then
					shieldCount = shieldCount + 1
				end
			end
			
			
			if shieldCount < 150 then
				coroutine.resume(coroutineShield)			
			else
				coroutine.resume(coroutineShieldExtrm)
			end		
			
			os.sleep(0.05) 
			tEnd = rInfo("temperature")		
			multy = tMax / tEnd
			
			if math.abs (tMax - tEnd) > 0.000 then
				costyl = (rInfo("generationRate") * math.pow(multy, 2)) + ((tMax - tEnd) * math.abs(tMax - tEnd))
				if tMax > tEnd then
					balance = balance + 1
				elseif tEnd > tMax then
					balance = balance - 1
				end
				
				costyl = costyl + (balance * 0.4)
				fluxOutGate.setFlowOverride(costyl)
				
				-- if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 90 then-- 90Слишком БОЛГО ждать охлада
				-- if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 85 then--
				if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 80 then--
					coroutine.resume(coroutineShield)
					reactor.stopReactor()													--	
				end	
			end
		end
	end
	
	print("\n Этап стабилизации рабочей температуры после разогрева ЗАВЕРШЕН\n")
	
    print("Реактор разогрет до ", rInfo("temperature"))
end

return reactorToWorkTemperature