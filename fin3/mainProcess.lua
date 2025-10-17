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
	local stableCount = 0
	
	local tCurrent = rInfo("temperature")	
	local flagTempDelta = 0
	
	local force = fluxOut.getFlow() --ПОСТАРАЮСЬ НЕ ИСПОЛЬЗОВАТЬ ЭТУ ПЕРЕМЕННУЮ
	local flagBalanceU = 0 -- переменная балансир, когда силы основной формулы не хватает для балансировки 
	local flagBalanceD = 0 -- переменная балансир, когда силы основной формулы не хватает для балансировки
	local flagTempStart = rInfo("temperature")
	local flagTempEnd = rInfo("temperature") -- КАК ПОКАЗАЛА ПРАКТИКА ЭТО СТАРТ ИЗЗА ТОГО ЧТО ЦЫКЛ КРУТИТСЯ ПО КРУГУ
	
	while isRunning do
	
		-- print("\n Мы сейчас на этапе основного рабочего метода после разогрева \n")
		
		coroutine.resume(coroutineShield)
		tCurrent = rInfo("temperature")
		flagTempStart = rInfo("temperature")
        flagTempDelta = math.abs(tMax - tCurrent) -- вычисление наличия отклонения не важно в какую сторону
		
		if flagTempDelta > 0.005 then 
			
			if tMax > tCurrent then -- ЕСЛИ реактор не догрет до нужной температуры
				if flagTempEnd >= flagTempStart then -- Этот иф нужен, если во время необходимости поднятия температуры она падает или стоит на месте
					flagBalanceU = flagBalanceU + 1
				end				
				fluxOut.setFlowOverride(rInfo("generationRate") + (((rInfo("generationRate") * (1 - (tCurrent / tMax))) * 0.05) + flagBalanceU)) 	--0.5 0.1
				if flagBalanceD > 1 then
					flagBalanceD = flagBalanceD - 1
				else
					flagBalanceD = 1
				end				
			elseif tCurrent > tMax then
				if flagTempStart >= flagTempEnd then -- Этот иф нужен, если во время необходимости понижения температуры она растет или стоит на месте
					flagBalanceD = flagBalanceD + 1					
				end				
				fluxOut.setFlowOverride(rInfo("generationRate") - (((rInfo("generationRate") * (1 - (tMax/tCurrent))) * 0.05) + flagBalanceD))			--1		0.1
				if flagBalanceU > 1 then
					flagBalanceU = flagBalanceU - 1
				else
					flagBalanceU = 1				
				end
			end		
		end
		flagTempEnd = rInfo("temperature")
		os.sleep(0.05)
		
		-------[[[[[[----------------------------------------
		if math.abs(tMax - tCurrent) > 0.1 then				--	
			coroutine.resume(coroutineShield)				--
			stableCount = 0									--
		else												--
			if stableCount > 150 then			--100		-- ЕСЛИ ТЕМПЕРАТУРА СКАЧЕТ ОЧЕНЬ СИЛЬНО ТО ВКЛЮЧАЕМ БЕЗОПАСНЫЙ ЩИТ
				coroutine.resume(coroutineShieldExtrm)		-- ПО ЛОГИКЕ ЕСЛИ ПРИМЕРНО 5 СЕКУНД, А ЭТО 100 ТИКОВ, ТЕМПЕРАТУРА В НОРМЕ ТО ВКЛЮЧАЕМ ЕКСТРИМ ЩИТ
			else											--
				stableCount = stableCount + 1				--
				coroutine.resume(coroutineShield)			--
			end												--
		end													--
		--------]]]]]]---------------------------------------
		
		
		-- Остановка реактора при 80%------											--
		if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 80 then--
			reactor.stopReactor()													--	
			print((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100)		--
			isRunning = false														--
		end																			--
		-----------------------------------
	-- print('tCurrent = rInfo("temperature") - ' .. tCurrent) -- ВРЕМЕННАЯ ДИАГНОСТИЧЕСКАЯ СТРОКА
	
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