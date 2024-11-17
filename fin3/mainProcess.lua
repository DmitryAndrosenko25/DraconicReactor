--[[
	ЭТОТ МОДУЛЬ ОТВЕЧАЕТ ЗА ОСНОВНУЮ ЧАСТЬ ПРОГРАММЫ
	И ЕЩЕ ПОД ВОПРОСОМ, РАЗБИТЬ ЛИ 8000 13000 И БАЛАНС МОД ПО 
	ОТДЕЛЬНЫМ МОДУЛЯМ ИЛИ ВСЕ НАПИСАТЬ В КУЧЕ.

]]

local mainProcess = {}

local component = require("component")
local shield = require("shield")

-- local a = reactorCheck.reactorSearchAddress() -- Получаем адреса по порядку: 1 реактор, 2 гейт вход, 3 гейт выход
-- local reactorAddress = a[1]
-- local fluxInAddress = a[2]
-- local fluxOutAddress = a[3]
-- local reactor = component.proxy(reactorAddress)
-- local fluxIn = component.proxy(fluxInAddress)
-- local fluxOut = component.proxy(fluxOutAddress)

local function rInfo(info) --- на вход параметр реактора в string ..на выход значение 
    st = reactor.getReactorInfo()
    return st[info]
end

function mainProcess.reactorInit(reactorAddress, fluixInAddress, fluixOutAddress, reactorMode) 	-- reactorMode - может принимать три валидных значения:
																								-- 1 - самая оптимальная температура в 8000 градусов
																								-- 2 - самая оптимальная температура в 8000 градусов
																								-- 3 - баланс выход энергии равно входу







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
					down = down - (1 * ((tStart - tEnd) * 1000)) --500
				elseif (tStart - tEnd) > 0.05 then
					down = down - (1 * ((tStart - tEnd) * 500)) --300 
				elseif (tStart - tEnd) > 0.03 then
					down = down - (1 * ((tStart - tEnd) * 300)) --150
				elseif (tStart - tEnd) > 0.02 then
					down = down - (1 * ((tStart - tEnd) * 200))	--100				-- ИЛИ ТУТ ЕЩЕ ДОБАВИТЬ ЕЛС ИФ ГРАДАЦИЮ 0.05, 0.03, 0.02....
				elseif (tStart - tEnd) > 0.01 then								-- 100  НУЖНО ПОПРОБОВАТЬ 100 - ТАК КАК ПРИ ТЕСТИРОВАНИИ 13 000 ГРАДУСОВ СКАКАЛО В ПРЕДЕЛАХ 0.1 ГРАДУСА
					down = down - (1 * ((tStart - tEnd) * 100)) --50					
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







return mainProcess