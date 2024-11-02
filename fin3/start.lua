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

local tMax = 8000
local tCurrent = rInfo("temperature")
local shieldMax = rInfo("maxFieldStrength")
local tDelta = 0
local OutFlow = fluxOut.getFlow()

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
	
	local saturatingSwitch = true
	local temperatureSwitch = true
	local hightTemperatureADD = 0
	local hightTemperatureADDSwitch = 0 -- от 0 до 20
	
    while tCurrent < (temperatureValueMax) do 
        
		coroutine.resume(coroutineShield)
		
		tCurrent = rInfo("temperature")
        tStart = rInfo("temperature")
        saturatStart = rInfo("energySaturation")
        os.sleep(0.05)      -- 0.5                                    
        tEnd = rInfo("temperature")
        saturatEnd = rInfo("energySaturation")
        tDelta = tEnd - tStart
        local saturatDelta = saturatStart - saturatEnd  --- Я ЗДЕСЬ!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        OutFlow = fluxOut.getFlow()
        
		
		
		local saturatMax = rInfo("maxEnergySaturation")
        local saturatcurrent = rInfo("energySaturation")
        
        
		
		-- сатурацию до 10% + до 7000 градусов
		-- потом засчет рейта генерации последние 1000 градусов добирать в градации 100 10 1
		
		local tempV = saturatMax - saturatcurrent
		if tCurrent < (tMax - 1000) then
			if saturatcurrent > (saturatMax / 2) then
				fluxOut.setFlowOverride(rInfo("generationRate") + (((saturatMax - tempV) /100))) --500
			elseif saturatcurrent > (saturatMax / 4) then
				fluxOut.setFlowOverride(rInfo("generationRate") + (((saturatMax - tempV) /250))) --/ 20) /600))
			elseif saturatcurrent > (saturatMax / 8) then
				fluxOut.setFlowOverride(rInfo("generationRate") + (((saturatMax - tempV) /500))) --/ 20) /600))
			elseif saturatcurrent > (saturatMax / 10) then	
				fluxOut.setFlowOverride(rInfo("generationRate") + (((saturatMax - tempV) /1000))) --/ 20) /600))
			end
			saturatingSwitch = true
			
			
		elseif (tCurrent > (tMax - 1000)) and (tCurrent < tMax ) then
			
			if saturatingSwitch then
				print("saturatingSwitch has been set to FALSE")
				fluxOut.setFlowOverride(rInfo("generationRate"))
				OutFlow = fluxOut.getFlow()
			end
			saturatingSwitch = false
			
			if ((tMax - tCurrent) > 500) then
			temperatureSwitch = true
				if (tDelta < 1) then
					fluxOut.setFlowOverride(OutFlow + (OutFlow * 0.2)) -- 0.15
				elseif (tDelta > 4) then -- 1.2
					fluxOut.setFlowOverride(OutFlow - (OutFlow * 0.01)) -- 0.1				
				
				end
			elseif (tMax - tCurrent) > 200 then
				if(tDelta < 0.2) then
					fluxOut.setFlowOverride(OutFlow + (OutFlow * 0.005)) -- 0.1
				elseif(tDelta > 0.5) then
					fluxOut.setFlowOverride(OutFlow - (OutFlow * 0.002)) --100
					temperatureSwitch = true
				end
			elseif ((tMax - tCurrent) < 150) then -- 100
				if (temperatureSwitch and ((tMax - tCurrent) < 150)) then --100
					print("temperatureSwitch has been set to FALSE")
					fluxOut.setFlowOverride(rInfo("generationRate"))
					OutFlow = fluxOut.getFlow()
					temperatureSwitch = false
				end		
				
				if ((tMax - tCurrent) > 100) then --10
					if (tDelta < 0.1) then --001
						fluxOut.setFlowOverride(OutFlow + 1 + ((tMax - tCurrent) * 60))--5))--3)) --(OutFlow * 0.01)) -- 0.1
					elseif (tDelta > 0.2) then	--0.5
						fluxOut.setFlowOverride(OutFlow - (1 + ((tMax - tCurrent) * 40))) -- (OutFlow * 0.01)) -- 0.1
					end
				
				
				
				
				elseif ((tMax - tCurrent) > 50) then --10
					if (tDelta < 0.05) then --001
						fluxOut.setFlowOverride(OutFlow + 1 + ((tMax - tCurrent) * 40))--5))--3)) --(OutFlow * 0.01)) -- 0.1
					elseif (tDelta > 0.1) then	--0.5
						fluxOut.setFlowOverride(OutFlow - (1 + ((tMax - tCurrent) * 20))) -- (OutFlow * 0.01)) -- 0.1
					end				
				elseif ((tMax - tCurrent) > 10) then --10
					if (tDelta < 0.03) then -- 0.02
						fluxOut.setFlowOverride(OutFlow + 1 + ((tMax - tCurrent) * 20)) --(OutFlow * 0.01)) -- 0.1
					elseif (tDelta > 0.05) then	--0.04
						fluxOut.setFlowOverride(OutFlow - (1 + ((tMax - tCurrent) * 10))) -- (OutFlow * 0.01)) -- 0.1
					end						
				elseif ((tMax - tCurrent) > 5) then --10
					if (tDelta < 0.02) then -- 0.02
						fluxOut.setFlowOverride(OutFlow + 1 + ((tMax - tCurrent) * 10)) --(OutFlow * 0.01)) -- 0.1
					elseif (tDelta > 0.03) then	--0.04
						fluxOut.setFlowOverride(OutFlow - (1 + ((tMax - tCurrent) * 5))) -- (OutFlow * 0.01)) -- 0.1
					end						
				
				elseif ((tMax - tCurrent) < 5) then
					if (tDelta < 0.01) then
						-- if hightTemperatureADDSwitch < 200 then
							-- hightTemperatureADDSwitch = hightTemperatureADDSwitch + 1
						-- else	
							-- hightTemperatureADD = hightTemperatureADD + 1
							-- hightTemperatureADDSwitch = 0
						-- end
					
						fluxOut.setFlowOverride(OutFlow + 1 + ((tMax - tCurrent) * 2)) --  hightTemperatureADD)-- (1) + hightTemperatureADD)					--((tMax - tCurrent) * 1) + hightTemperatureADD) -- ((tMax - tCurrent) * 2)
						print("sleep UP ")
						
					elseif (tDelta > 0.02) then				--0.02) then	
						fluxOut.setFlowOverride(OutFlow - (1 + ((tMax - tCurrent) * 10))) -- - ( hightTemperatureADD / 2)) -- 4	
						print("DOWN ")
						hightTemperatureADD = 0
						hightTemperatureADDSwitch = 0
					end
				end
				
				
			end
		end		
    end
    print("Реактор разогрет до ", rInfo("temperature"))
	fluxOut.setFlowOverride( rInfo("generationRate"))
	
	-- ========================= hold 8 k ====================
	
	print("Начинаются попытки установки экстремального щита")
	--shield.setReactor(reactorAddress, fluxInAddress, fluxOutAddress)		--\
	-- shield.setLevel(1.5)												 	 --\ ~33% щита
	local coroutineShieldExtrm = coroutine.create(shield.runShieldExtreme)	 --/ запуск щита
	coroutine.resume(coroutineShieldExtrm) -- Выведет "Начало корутины"		--/
	print("Попытки установки экстремального щита закончены")
	
	-- local isDown = false
	-- local isUp = false
	-- local switch8 = false
	
	while true do
		coroutine.resume(coroutineShieldExtrm)		
		tCurrent = rInfo("temperature")
        OutFlow = fluxOut.getFlow()
		
		
		-- tStart = rInfo("temperature")
        os.sleep(0.05)      -- 0.5                                    
        -- tEnd = rInfo("temperature")
        
        if tMax == tCurrent then
			fluxOut.setFlowOverride( rInfo("generationRate"))
		elseif tMax > tCurrent then		
			fluxOut.setFlowOverride(OutFlow + 1) 
		
		elseif tCurrent > tMax then	--0.04
			
			fluxOut.setFlowOverride(OutFlow - 1) 
		
		end
		
	end
	-- fluxOut.setFlowOverride(0) -- only for test
	-- fluxIn.setFlowOverride(rInfo("fieldDrainRate") * 2)
end
outUpTo(tMax)