--[[
	ЭТОТ МОДУЛЬ ОТВЕЧАЕТ ЗА ОСНОВНУЮ ЧАСТЬ ПРОГРАММЫ
	И ЕЩЕ ПОД ВОПРОСОМ, РАЗБИТЬ ЛИ 8000 13000 И БАЛАНС МОД ПО 
	ОТДЕЛЬНЫМ МОДУЛЯМ ИЛИ ВСЕ НАПИСАТЬ В КУЧЕ.

]]

local mainProcess = {}

local component = require("component")
local shield = require("shield")

-- local a = reactorCheck.reactorSearchAddress() -- Получаем адреса по порядку: 1 реактор, 2 гейт вход, 3 гейт выход
local reactorAddress = nil
local fluxInAddress = nil
local fluxOutAddress = nil
local reactor = nil
local fluxIn = nil
local fluxOut = nil


local function rInfo(info) --- на вход параметр реактора в string ..на выход значение 
    st = reactor.getReactorInfo()
    return st[info]
end

local function main(temerature)
	local tMax = temerature
	
	print("Начинаются попытки установки экстремального щита")
	local coroutineShieldExtrm = coroutine.create(shield.runShieldExtreme)	 --/ запуск щита
	-- coroutine.resume(coroutineShieldExtrm) -- Выведет "Начало корутины"		--/
	print("Попытки установки экстремального щита закончены")
	
	
	--===================================================================================
	print("Начинаются попытки установки безопасного щита")
	shield.setReactor(reactorAddress, fluxInAddress)	--\
	shield.setLevel(1.5)												 --\ ~33% щита
	local coroutineShield = coroutine.create(shield.runShield)		 	 --/ запуск щита
	coroutine.resume(coroutineShield) -- Выведет "Начало корутины"		--/
	print("Попытки установки безопасного щита закончены")
	--===================================================================================
			
	local isRunning = true
	
	local tCurrent = rInfo("temperature")
	local outFlow = fluxOut.getFlow()
	local tStart = rInfo("temperature")
	local tEnd = rInfo("temperature")
	
	local ifStable = false
	local stableCount = 0
	local a = 0
	local b = 0
	
	while isRunning do
		
		tCurrent = rInfo("temperature")
		outFlow = fluxOut.getFlow()
		tStart = rInfo("temperature")
        os.sleep(0.05)
        tEnd = rInfo("temperature")
		
		
		if math.abs(tMax - tEnd) > 10 then
			-- ifStable = false
			coroutine.resume(coroutineShield)		
			stableCount = 0
		else
			if stableCount > 100 then						-- ЕСЛИ ТЕМПЕРАТУРА СКАЧЕТ ОЧЕНЬ СИЛЬНО ТО ВКЛЮЧАЕМ БЕЗОПАСНЫЙ ЩИТ
				coroutine.resume(coroutineShieldExtrm)		-- ПО ЛОГИКЕ ЕСЛИ ПРИМЕРНО 5 СЕКУНД, А ЭТО 100 ТИКОВ, ТЕМПЕРАТУРА В НОРМЕ ТО ВКЛЮЧАЕМ ЕКСТРИМ ЩИТ
			else	
				stableCount = stableCount + 1
				coroutine.resume(coroutineShield)
			end
		end
		
		
		a = (rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 200 --		200	50		100					200!!!!!!!			100
		b = (rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 50 --	100	200	50		100					200!!!!!!!			100
		
		if (tMax - tEnd) > 0.001 then			
			if (tStart > tEnd) then																		-- ЕСЛИ ТЕМПЕРАТУРА НИЖЕ НУЖНОЙ И ПРОДОЛЖАЕТ ПАДАТЬ
				
								
				fluxOut.setFlowOverride(rInfo("generationRate") + (rInfo("generationRate") * ((tMax - tEnd) / (100 + a)))) 	--	200		``500 ТО РЕАЛЬНУЮ ГЕНЕРАЦИЮ УВЕЛИЧИВАЕМ НА 1%
				
				-- fluxOut.setFlowOverride(rInfo("generationRate") + (rInfo("generationRate") * 0.00005)) 	-- ТО РЕАЛЬНУЮ ГЕНЕРАЦИЮ УВЕЛИЧИВАЕМ НА 1%
			elseif (tEnd - tStart) > 0.001 then
				
				
				fluxOut.setFlowOverride((rInfo("generationRate")) + (rInfo("generationRate") * ((tMax - tEnd) / (200 + a))))   -- 300	400			700    500 МНОЖЕТЕЛЬ МЕНЯТЬ ТУТ
			end
		
--[[
			При конвертации > 40% - температура прыгает +-0.1 примерно. так же при перезаходе к хуям все бахает, нужно чтото делать со щитом
=====================================================================================================================================================
--]]


		
		elseif (tEnd - tMax) > 0.001 then
			fluxOut.setFlowOverride((rInfo("generationRate")) - ((rInfo("generationRate") * (tEnd - tMax)) / (150 + b)))  -- 	200				500 Это супер множитель МНОЖЕТЕЛЬ МЕНЯТЬ ТУТ
		else 
			fluxOut.setFlowOverride(rInfo("generationRate"))		
		end
		print(tEnd)
		
		-- Остановка реактора при 90% конвертации - но ЛУЧШЕ при 80-85%
		if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 80 then --95 then-- 95% (--97% = BOOM!!!)
			reactor.stopReactor()
			print((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100)
			isRunning = false
		end
	end
	while (rInfo("status")) ~= "cold" do
		coroutine.resume(coroutineShieldExtrm)
		os.sleep(0.05)
	end
end
	

function mainProcess.reactorInit(reactorAddressIn, fluxInAddressIn, fluxOutAddressIn, reactorMode) 	-- reactorMode - может принимать три валидных значения:
																										-- 1 - самая оптимальная температура в 8000 градусов
																										-- 2 - самая "экстремальная" температура в 13000 градусов
																										-- 3 - баланс выход энергии равно входу
	
	reactorAddress = reactorAddressIn
	fluxInAddress = fluxInAddressIn
	fluxOutAddress = fluxOutAddressIn
	reactor = component.proxy(reactorAddress)
	fluxIn = component.proxy(fluxInAddress)
	fluxOut = component.proxy(fluxOutAddress)
	
	if (reactorMode == 1) then
		local temeratureMax = 8000
		main(temeratureMax)
	elseif (reactorMode == 2)then
		local temeratureMax = 13000
		main(temeratureMax)
	elseif (reactorMode == 3)then
		local temeratureMax = nil
		balance()	
	else
		print("Какая то хуйня со входящим значением reactorMode при вызове mainProcess.reactorInit")
	end
	
	
end

return mainProcess