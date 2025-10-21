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
	
	
	
	
	
	-- КОНСТАНТЫ И КОЭФФИЦИЕНТЫ
	local DT = 0.05             -- Интервал времени (равный вашему os.sleep)
	local Kp = -0.1             -- НАЧАЛЬНЫЕ ОТРИЦАТЕЛЬНЫЕ ЗНАЧЕНИЯ!
	local Ki = -0.0001
	local Kd = -1.0
	local INTEGRAL_LIMIT = 100000.0 -- Защита от насыщения интеграла (Anti-Windup)
	local FLOW_LIMIT_MAX = 5000000.0 -- Максимальный физический поток гейта

	-- ПЕРЕМЕННЫЕ СОСТОЯНИЯ (хранят историю)
	local integral = 0.0        -- Накопленная ошибка
	local last_error = 0.0      -- Ошибка из предыдущего цикла
	
	
	
	
	
	
	
	
	
	
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
			
		
			-- Внутри цикла while true do:

			-- 1. Считывание текущего значения
			local tCurrent = rInfo("temperature")

			-- 2. Вычисление ошибки
			local error = tCurrent - tMax -- Положительна, если слишком горячо

			
			--Я СРЕДИ ВСЕГО ЭТОГО ХАОСА ЗДЕСЬ!!!!!!!!!!!!!!!! 21.10.2025
			
			
			
			-- 3. Пропорциональный член (P)
			local P = Kp * error

			-- 4. Интегральный член (I)
			integral = integral + (error * DT) 
			-- Защита от насыщения интеграла (Anti-Windup)
			integral = math.min(math.max(integral, -INTEGRAL_LIMIT), INTEGRAL_LIMIT) 
			local I = Ki * integral

			-- 5. Дифференциальный член (D)
			local derivative = (error - last_error) / DT
			local D = Kd * derivative

			-- 6. Общее управляющее воздействие (Новый поток)
			local output_flow = P + I + D

			-- 7. Ограничение физическим лимитом
			local newFlow = math.max(FLOW_LIMIT_MIN, math.min(FLOW_LIMIT_MAX, output_flow))

			-- 8. Установка потока и обновление состояния
			fluxOut.setFlowOverride(newFlow)
			last_error = error -- Сохраняем ошибку для следующего цикла

			-- 9. Пауза
			os.sleep(DT)
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			

		end



----------------------------------------------------------------------------------------------------------------------------------

		
		
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