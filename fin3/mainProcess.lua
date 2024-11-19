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
		
		if (tMax - tCurrent) > 0.01 then
			-- 13000 - 12987.01 = 12,99
		
			-- start = 12987.01	start - end = 17.01
			-- end   = 12980.00
			
			if (tStart - tEnd) > 0.01 then
				
				print("((tStart - tEnd)/1000) = ".. ((tStart - tEnd)/1000))					-- это в принципе работает, но делитель нужно подобрать, так как температура всеравно падает
				fluxOut.setFlowOverride(outFlow * (1 + ((tStart - tEnd)/1000)))
			end	
			
			
			
			-- print("((tMax - tCurrent)/100) = ".. ((tMax - tCurrent)/1000))
			-- fluxOut.setFlowOverride(outFlow * (1 + ((tMax - tCurrent)/1000)))
		
		
		end
		
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