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
	local onePercentLeft = nil
	
	while tCurrent <= (tempMax) do 
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
        os.sleep(0.05) 
        tEnd = rInfo("temperature")
        tDelta = (tEnd - tCurrent)
		onePercentLeft = ((tempMax - tCurrent) * 0.01)	-- (13 000 - 8 320) = 4 680 * 0.01 = 46.80
														-- (13 000 - 11 140) = 1 860 * 0.01 = 18.60
														-- Один процент от оставшейся набрать температуры
		outFlow = fluxOutGate.getFlow()
		
		if tDelta < 0 then
			outFlow = (rInfo("generationRate") + (rInfo("generationRate") * 0.01) + 1)
		else
			
			if (tDelta > onePercentLeft * 0.1) then
				outFlow = outFlow * 0.999
			
			
			Я тут, температура растет крайне медленно
			
			
			
			
			elseif(tDelta < onePercentLeft * 0.05) then
				outFlow = outFlow + (outFlow * 0.001)
			end
			
			
			
			--[[
			if     (tDelta < (onePercentLeft * 0.01)) then
				outFlow = outFlow + (outFlow * 0.01)
			elseif (tDelta < (onePercentLeft * 0.1)) then
				outFlow = outFlow + (outFlow * 0.1)
			elseif (tDelta < (onePercentLeft * 1)) then
				outFlow = outFlow + (outFlow * 1)
			elseif (tDelta < (onePercentLeft * 10)) then
				outFlow = outFlow + (outFlow * 10)
			
			elseif (tDelta > (onePercentLeft * 1)) then
				outFlow = outFlow * 0.9
			elseif (tDelta > (onePercentLeft * 0.1)) then
				outFlow = outFlow * 0.99
			elseif (tDelta > (onePercentLeft * 0.01)) then
				outFlow = outFlow * 0.999
			elseif (tDelta > (onePercentLeft * 0.001)) then
				outFlow = outFlow * 0.9999
			end
			
			
			]]--
		end
		--[[
		if ((tempMax * 0.5) > tCurrent) then
			multy = 0.1
			
		elseif ((tempMax * 0.8) > tCurrent) then
			multy = 1
		
		elseif ((tempMax * 0.9) < tCurrent) then
			multy = 10
		
		else
			-- multy = 1
		end
			
			
		if (tDelta < ((tempMax / 100)/(20 * multy))) then	-- 20	меньше 1 градуса в сек
			-- outFlow = (rInfo("generationRate") + (rInfo("generationRate") * (1 - (tCurrent / tempMax))) + 1)		
			outFlow = (rInfo("generationRate") * (tempMax / tCurrent) + 1)		
		else--if (tDelta > ((tempMax / 100)/(15 * multy))) then -- 50 больше 2 градусов в сек
			outFlow = (outFlow * 0.99999)
			
		
		
		
		
		
		


				-- 13000-7000/20 = 300
		-- if ((rInfo("maxEnergySaturation") * 0.001) > rInfo("energySaturation")) then	-- Если сатурация больше 4% - работаем  0.01%
			-- outFlow = outFlow * 0.98
		-- else
		-- if (tDelta < ((tempMax - tCurrent) / 100)) then -- 50
		-- надо ввести динамический множитель
		
		
			if (tDelta < ((tempMax / 100)/20)) then	-- 20				--then -- 50
				-- fluxOutGate.setFlowOverride(rInfo("generationRate") * (tempMax / tCurrent) + 1)		-- СТАРАЯ ВЕРСИЯ
				outFlow =(outFlow + (rInfo("generationRate") * (1 - (tCurrent / tempMax))) + 1)		
				-- fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) /10 ))	-- РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
				-- if 
				
				
				
			
			elseif (tDelta > ((tempMax / 100)/18)) then -- 50
				outFlow =(rInfo("generationRate") * 0.99999)
			
			
					--13000-7000/50 = 120
			-- 2500 / 13000 = 0,1923076923076923
			-- (rInfo("generationRate") + (rInfo("generationRate") * (1 - (tCurrent / tempMax))) +1)
			-- (rInfo("generationRate") + (rInfo("generationRate") * (1 - (tCurrent / tempMax))) +1)
			
			-- elseif (tDelta > ((tempMax - tCurrent) / 90)) then	 --40
				-- fluxOutGate.setFlowOverride(rInfo("generationRate") * 0.99)
			
			
			-- elseif (tDelta > ((tempMax - tCurrent) / 80)) then	 --40
				-- fluxOutGate.setFlowOverride(rInfo("generationRate"))
			end
		-- end
		
		end
		]]--
		
		
		
		fluxOutGate.setFlowOverride(outFlow)
		
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOutGate.setFlowOverride( rInfo("generationRate"))
end




return reactorToWorkTemperature