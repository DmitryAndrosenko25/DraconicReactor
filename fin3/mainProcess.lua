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
	
	
	
	--[[
	print("Начинаются попытки установки экстремального щита")
	local coroutineShieldExtrm = coroutine.create(shield.runShieldExtreme)	 --/ запуск щита
	coroutine.resume(coroutineShieldExtrm) -- Выведет "Начало корутины"		--/
	print("Попытки установки экстремального щита закончены")
	
	--]]
	--===================================================================================
	print("Начинаются попытки установки безопасного щита")
	shield.setReactor(reactorAddress, fluxInAddress)	--\
	shield.setLevel(1.5)												 --\ ~33% щита
	local coroutineShield = coroutine.create(shield.runShield)		 	 --/ запуск щита
	coroutine.resume(coroutineShield) -- Выведет "Начало корутины"		--/
	print("Попытки установки безопасного щита закончены")
	--===================================================================================
	
	
	
	
	local up = 1
	local down = 1
		
	local isRunning = true
	
	local tCurrent = rInfo("temperature")
	local outFlow = fluxOut.getFlow()
	local tStart = rInfo("temperature")
	local tEnd = rInfo("temperature")
	
	
	-- local isNeedUp = true
	local multy = 0
	
	while isRunning do
		-- coroutine.resume(coroutineShieldExtrm)
		coroutine.resume(coroutineShield)
		
		
		
		
		tCurrent = rInfo("temperature")
		outFlow = fluxOut.getFlow()
		tStart = rInfo("temperature")
        os.sleep(0.05)
        tEnd = rInfo("temperature")
		
		
		if tMax > tCurrent then
			if (tMax - tCurrent) > 0.01 then
				
				
				if (tEnd - tStart) > 1 then						-- Если рост слишком быстрый?????
					up = up - (1 * ((tEnd - tStart)* 20)) --75
				elseif (tEnd - tStart) > 0.1 then
					up = up - (1 * ((tEnd - tStart)* 10)) --30 --50
				elseif (tEnd - tStart) > 0.01 then
					up = up - (1 * ((tEnd - tStart)* 5)) --15 --25
				else
					up = up + 1
				end
			end
			fluxOut.setFlowOverride(rInfo("generationRate") + up)
		
		elseif tCurrent > tMax then
			if (tCurrent - tMax) > 0.01 then
				
				if (tStart - tEnd) > 100 then							-- Если падение слишком быстрое???
					down = down - (1 * ((tStart - tEnd) * 5000000))
				elseif (tStart - tEnd) > 10 then
					down = down - (1 * ((tStart - tEnd) * 500000))
				elseif (tStart - tEnd) > 1 then
					down = down - (1 * ((tStart - tEnd) * 50000))
				
				
				
				тут нужно добавить переменную которая  тормозит набор скорости МОЖЕТ ДАЖЕ СООТНОШЕНИЕМ МАКС САТУРАЦИИ К САТУРАЦИИ??????????
				
				
				
				
				
				elseif (tStart - tEnd) > 0.5 then
					down = down - (1 * ((tStart - tEnd) * 5000))
				elseif (tStart - tEnd) > 0.1 then
					down = down - (1 * ((tStart - tEnd) * 1500)) -- 1000--500
				elseif (tStart - tEnd) > 0.05 then
					down = down - (1 * ((tStart - tEnd) * 750)) -- 500--300 
				elseif (tStart - tEnd) > 0.03 then				
					down = down - (1 * ((tStart - tEnd) * 450)) -- 300 --150
				elseif (tStart - tEnd) > 0.02 then
					down = down - (1 * ((tStart - tEnd) * 300))	--100				-- ИЛИ ТУТ ЕЩЕ ДОБАВИТЬ ЕЛС ИФ ГРАДАЦИЮ 0.05, 0.03, 0.02....
				elseif (tStart - tEnd) > 0.01 then								-- 100  НУЖНО ПОПРОБОВАТЬ 100 - ТАК КАК ПРИ ТЕСТИРОВАНИИ 13 000 ГРАДУСОВ СКАКАЛО В ПРЕДЕЛАХ 0.1 ГРАДУСА
					down = down - (1 * ((tStart - tEnd) * 150)) --50					
				else
					down = down + 1
				end
			end	
			fluxOut.setFlowOverride(rInfo("generationRate") - down)
		else
			fluxOut.setFlowOverride(rInfo("generationRate"))
			-- down = down * 0.95
			up = 0
		end
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		--[[
		
		if (tMax - tCurrent) > 0.01 then
			-- 13000 - 12987.01 = 12,99
		
			-- start = 12987.01	start - end = 17.01
			-- end   = 12980.00
			
			if (tStart - tEnd) > 0.01 then
				
				if (tMax - tCurrent) > 1 then
					print("((tStart - tEnd)/100) = ".. ((tStart - tEnd)/100))		--1000			-- это в принципе работает, но делитель нужно подобрать, так как температура всеравно падает
					fluxOut.setFlowOverride(outFlow * (1 + ((tStart - tEnd)/100)))
				elseif (tMax - tCurrent) > 0.1 then
					print("((tStart - tEnd)/300) = ".. ((tStart - tEnd)/250))		--1000			-- это в принципе работает, но делитель нужно подобрать, так как температура всеравно падает
					fluxOut.setFlowOverride(outFlow * (1 + ((tStart - tEnd)/250)))
				else
					print("((tStart - tEnd)/150) = ".. ((tStart - tEnd)/300))		--1000			-- это в принципе работает, но делитель нужно подобрать, так как температура всеравно падает
					fluxOut.setFlowOverride(outFlow * (1 + ((tStart - tEnd)/300)))
				end
			end	
			
			-- print("((tMax - tCurrent)/100) = ".. ((tMax - tCurrent)/1000))
			-- fluxOut.setFlowOverride(outFlow * (1 + ((tMax - tCurrent)/1000)))
		
		elseif (tCurrent - tMax) > 0.01 then
			
			if (tStart - tEnd) > 0.01 then
				
				print("((tStart - tEnd)/1500) = ".. ((tStart - tEnd)/1500))		--1000		ДИКИЙ РОСТ!!!!!!	-- это в принципе работает, но делитель нужно подобрать, так как температура всеравно падает
				fluxOut.setFlowOverride(outFlow * (1 - ((tStart - tEnd)/1500)))
			end
		
		
		
		
		else
			fluxOut.setFlowOverride(rInfo("generationRate"))
		
		end
		--]]
		--[[
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		if tMax > tCurrent then
			
			
			
			
			
			
			if (tMax - tCurrent) > 0.01 then
				if (tEnd < tStart) then
					
					
					
					up = up + 10 * ((tStart - tEnd) / 0.01)
					fluxOut.setFlowOverride(outFlow + (1 * up))
					
					
					-- up = up + (100 * ((tStart - tEnd) / 0.01))				
					-- fluxOut.setFlowOverride(outFlow + up)
					print (up .. " up - temerature: " ..tEnd)			-- ВСЕ РАВНО СЛИШКОМ БЫСТРО ПАДАЕТ ТЕМПЕРАТУРА. В СТРОКЕ 60 НУЖНО УВЕЛИЧИТЬ МНОЖИТЕЛЬ!!!!!
				end
			end
			down = 1
			
			
		elseif tCurrent > tMax then
			
			if (tCurrent - tMax) > 0.01 then				
				if (tStart > tEnd) then
					down = down + (1 * ((tStart - tEnd) / 0.01))		
					print (down .. " down - temperature: " ..tEnd)
				end
			end	
			fluxOut.setFlowOverride(outFlow - down)
			up = 1		
		end
		--]]
		
		-- Остановка реактора при 90% конвертации - но ЛУЧШЕ при 80-85%
		if ((rInfo("fuelConversion") / rInfo("maxFuelConversion")) * 100) >= 90 then --95 then-- 95% (--97% = BOOM!!!)
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