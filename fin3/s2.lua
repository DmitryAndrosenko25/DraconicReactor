reactorCheck = require("reactorCheck")
reactorHeating = require("reactorHeating")
shield = require("shield")
component = require("component")

local a = reactorCheck.reactorSearchAddress() -- Получаем адреса по порядку: 1 реактор, 2 гейт вход, 3 гейт выход
local reactorAddress = a[1]
local fluxInAddress = a[2]
local fluxOutAddress = a[3]
local reactor = component.proxy(reactorAddress)
local fluxIn = component.proxy(fluxInAddress)
local fluxOut = component.proxy(fluxOutAddress)

local function rInfo(info) --- на вход параметр реактора в string ..на выход значение 
    st = reactor.getReactorInfo()
    return st[info]
end

local tMax = 13000 --8000
local tCurrent = rInfo("temperature")
local tDelta = 0


local function starter()				-- Запуск разогретого до 2000 реактора
	fluxOut.setOverrideEnabled(true)
    fluxOut.setFlowOverride(0)
    fluxIn.setFlowOverride(1)
    
    if rInfo("status") ~= "running" then         --ЗАПУСК РЕАКТОРА
        if reactor.activateReactor() then 
            print("Реактор запустился")
        else
            fluxIn.setFlowOverride(1)
            local temp = fluxIn.getFlow()
            local run = true
            print("стартер реактора гудит...")
            while run do         
                if reactor.activateReactor() then
                    run = false
                else
                    fluxIn.setFlowOverride(temp +1)
                    os.sleep(0.05)
                    temp = fluxIn.getFlow()
                end
            end
            print("Реактор запустился")
        end
    else
       print("Реактор запущен") 
    end
end

local function outUpTo (temperatureValue)	-- поднятие рабочей температуры до temperatureValue (или понижение?????)
	local temperatureValueMax = temperatureValue
	
	if rInfo("temperature") < 2000 then
		reactorHeating.startHeating()
	end
	
	if rInfo("status") ~= "running" then  --ЗАПУСК РЕАКТОРА
		starter()
	end
	
	print("Начинаются попытки установки безопасного щита")
	shield.setReactor(reactorAddress, fluxInAddress, fluxOutAddress)	--\
	shield.setLevel(1.5)												 --\ ~33% щита
	local coroutineShield = coroutine.create(shield.runShield)		 	 --/ запуск щита
	coroutine.resume(coroutineShield) -- Выведет "Начало корутины"		--/
	print("Попытки установки безопасного щита закончены")
		
	print(string.format("Разогрев ректора до %d", temperatureValueMax))
	fluxOut.setOverrideEnabled(true)
    fluxOut.setFlowOverride(rInfo("generationRate")) -- минимальный старт разогрева
	
    while tCurrent < (temperatureValueMax) do 
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
        tStart = rInfo("temperature")
        os.sleep(0.05) 
        tEnd = rInfo("temperature")
        tDelta = tEnd - tStart
        OutFlow = fluxOut.getFlow()
		
		if (tDelta < ((tMax - tCurrent) / 50)) then -- 50
			fluxOut.setFlowOverride(rInfo("generationRate") * (tMax / tCurrent) + 1)		
		elseif (tDelta > ((tMax - tCurrent) / 42)) then	 --40
			fluxOut.setFlowOverride(rInfo("generationRate"))
		end        
		
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOut.setFlowOverride( rInfo("generationRate"))
	-- shield.stopShield()
	-- coroutine.resume(coroutineShield)
	
	-- ========================= hold 8 k ====================
	
	print("Начинаются попытки установки экстремального щита")
	local coroutineShieldExtrm = coroutine.create(shield.runShieldExtreme)	 --/ запуск щита
	coroutine.resume(coroutineShieldExtrm) -- Выведет "Начало корутины"		--/
	print("Попытки установки экстремального щита закончены")
	
	local up = 0
	local down = 0
		
	local isRunning = true
	while isRunning do
		coroutine.resume(coroutineShieldExtrm)
	
		tCurrent = rInfo("temperature")
		OutFlow = fluxOut.getFlow()
		tStart = rInfo("temperature")
        os.sleep(0.05)
        tEnd = rInfo("temperature")
		
		if tMax > tCurrent then
			if (tMax - tCurrent) > 0.01 then
				
				
				if (tEnd - tStart) > 1 then
					up = up - (1 * ((tEnd - tStart)* 75)) --50
				elseif (tEnd - tStart) > 0.1 then
					up = up - (1 * ((tEnd - tStart)* 50)) --50
				elseif (tEnd - tStart) > 0.01 then
					up = up - (1 * ((tEnd - tStart)* 25)) --50
				else
					up = up + 1
				end
			end
			fluxOut.setFlowOverride(rInfo("generationRate") + up)
		
		elseif tCurrent > tMax then
			if (tCurrent - tMax) > 0.01 then
				
				if (tStart - tEnd) > 100 then
					down = down - (1 * ((tStart - tEnd) * 5000000))
				elseif (tStart - tEnd) > 10 then
					down = down - (1 * ((tStart - tEnd) * 500000))
				elseif (tStart - tEnd) > 1 then
					down = down - (1 * ((tStart - tEnd) * 50000))
				elseif (tStart - tEnd) > 0.5 then
					down = down - (1 * ((tStart - tEnd) * 5000))
				elseif (tStart - tEnd) > 0.1 then
					down = down - (1 * ((tStart - tEnd) * 500)) 
				elseif (tStart - tEnd) > 0.05 then
					down = down - (1 * ((tStart - tEnd) * 300)) 
				elseif (tStart - tEnd) > 0.03 then
					down = down - (1 * ((tStart - tEnd) * 150))
				elseif (tStart - tEnd) > 0.02 then
					down = down - (1 * ((tStart - tEnd) * 100))					-- ИЛИ ТУТ ЕЩЕ ДОБАВИТЬ ЕЛС ИФ ГРАДАЦИЮ 0.05, 0.03, 0.02....
				elseif (tStart - tEnd) > 0.01 then								-- 100  НУЖНО ПОПРОБОВАТЬ 100 - ТАК КАК ПРИ ТЕСТИРОВАНИИ 13 000 ГРАДУСОВ СКАКАЛО В ПРЕДЕЛАХ 0.1 ГРАДУСА
					down = down - (1 * ((tStart - tEnd) * 50)) 					
				else
					down = down + 1
				end
			end	
			fluxOut.setFlowOverride(rInfo("generationRate") - down)
		else
			fluxOut.setFlowOverride(rInfo("generationRate"))
			down = down * 0.95
			up = 0
		end
		-- Остановка реактора при 90% конвертации
		if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 90 then --95 then-- 95% (--97% = BOOM!!!)
			reactor.stopReactor()
			print((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100)
			isRunning = false
		end
	end
	-- тут на цикл нужно запустить coroutine.resume(coroutineShieldExtrm) 
	-- пока реактор полностью не остынет
	while (rInfo("status")) ~= "cold" do
		coroutine.resume(coroutineShieldExtrm)
		os.sleep(0.05)
	end
end
outUpTo(tMax)


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
print("status " .. "__________" .. rInfo("status"))
print ("Все закончилось удачно")