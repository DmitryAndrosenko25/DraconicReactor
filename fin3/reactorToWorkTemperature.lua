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
	local tStart = nil
	local tEnd = nil
	local tDelta = nil
	-- local OutFlow = nil
	
	while tCurrent < (tempMax) do 
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
        tStart = rInfo("temperature")
        os.sleep(0.05) 
        tEnd = rInfo("temperature")
        tDelta = tEnd - tStart
        -- OutFlow = fluxOutGate.getFlow()
		


				-- 13000-7000/20 = 300
		if (tDelta < ((tempMax - tCurrent) / 100)) then -- 50
			-- fluxOutGate.setFlowOverride(rInfo("generationRate") * (tempMax / tCurrent) + 1)		-- СТАРАЯ ВЕРСИЯ
			fluxOutGate.setFlowOverride((rInfo("generationRate") * (tempMax / tCurrent)) + ((tempMax - tCurrent) /10 ))	-- РОСТ МОЖЕТ БЫТЬ СЛИШКОМ БЫСТРЫЙ	
		
		
				--13000-7000/50 = 120
		elseif (tDelta > ((tempMax - tCurrent) / 50)) then	 --40
			fluxOutGate.setFlowOverride(rInfo("generationRate"))
		end        
		
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOutGate.setFlowOverride( rInfo("generationRate"))
	
	
	
	
	
	
	
	
	
	
	
	



end




return reactorToWorkTemperature