local M = {}

local logFile = "reactorInfo.txt" -- Объявляем локальные переменные для имени файла и адресов адаптеров
local reactorAddress = "reactor="
local fluxInAddress = "fluxIn="
local fluxOutAddress = "fluxOut="
local isValidFile = false -- Это результат проверки файла с адресами на существование и на валидность
local component = require("component")


local function writeAddresses() -- ПИШЕТ АДРЕСА В ФАЙЛ
	local file = io.open(logFile, 'w') -- Пытаемся создать файл для записи адресов
	if file then -- Если файл создан, то
		file:write("reactor="..reactorAddress, '\n') -- Записываем адрес реактора в файл
		print(string.format("Адрес реактора был записан в файл настроек %s.", logFile), '\n') -- Выводим сообщение
		file:write("fluxIn="..fluxInAddress, '\n') -- Записываем адрес входного Flux Gate в файл
		print(string.format("Адрес входного flux gate был записан в файл настроек %s.", logFile), '\n') -- Выводим сообщение
		file:write("fluxOut="..fluxOutAddress, '\n') -- Записываем адрес выходного Flux Gate в файл
		print(string.format("Адрес выходного flux gate был записан в файл настроек %s.", logFile), '\n') -- Выводим сообщение
		file:close() -- Закрываем файл
	else -- Если файл не создан, то
		print("Не удалось создать файл для записи адресов.") -- Выводим сообщение об ошибке
	end
end

local function rCheck(info) -- Создаем локальную функцию для получения информации о реакторе
	local reactorF = component.proxy(reactorAddress) -- Получаем объект реактора по адресу		
	local st = reactorF.getReactorInfo() -- Получаем статус реактора
	return st[info] -- Возвращаем значение по ключу
end

function M.getReactorAddress(fileName) -- устанавливает адрес реактора и проверяет файл настроек на ВАЛИДНОСТЬ
	local result = false
	for d, _ in component.list("draconic_reactor") do -- Пытаемся найти адрес реактора среди компонентов
		reactorAddress = d
		result = true
	end	
	local f = io.open(fileName, "r") -- Пытаемся открыть файл для чтения
	if f then -- Если файл существует, то
		print(string.format("Файл настроек %s был найден.", fileName)) -- Выводим сообщение
		local readed = {} -- Создаем локальную таблицу для хранения адресов
		for var in f:lines() do -- Читаем файл построчно и добавляем строки в таблицу
			table.insert(readed, var)
		end
		f:close() -- Закрываем файл		
		for _, v in pairs(readed) do -- Перебираем таблицу с адресами
			if string.find(v, reactorAddress, 1, true) then -- Если строка содержит адрес реактора, то
				print("Адрес реактора в файле прочитан верно - "..reactorAddress) -- Выводим сообщение
				print(string.format("Файл настроек %s проверен", fileName)) -- Выводим сообщение
				isValidFile = true -- Подтверждаем что файл "не бит, не крашен"
				
				for _, w in pairs(readed) do -- Перебираем таблицу с адресами
					if w:find(fluxInAddress, 1, true) then -- Если строка содержит адрес входного Flux Gate, то
						fluxInAddress = string.sub(w, ((w:find('='))+1)) -- Обрезаем строку до адреса
						print("Адрес входного flux gate с файла прочитан - "..fluxInAddress) -- Выводим сообщение
					elseif w:find(fluxOutAddress, 1, true) then -- Если строка содержит адрес выходного Flux Gate, то
						fluxOutAddress = string.sub(w, ((w:find('='))+1)) -- Обрезаем строку до адреса
						print("Адрес выходного flux gate с файла прочитан - "..fluxOutAddress) -- Выводим сообщение
					end
				end
			end
		end
	end	
	return result -- ВОЗВРАЩАЕТ TRUE ЕСЛИ АДРЕС РЕАКТОРА НАЙДЕН
end

function M.getGatesAddresses()			-- метод получает адреса гейтов (В РАЗНЫХ СТАТУСАХ РЕАКТОРА????)
	local result = {}	-- результат - таблица с {адресом реактора, адрес гейт на вход, на выход} !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	local gate = nil
	local gate2 = nil
	local firstGate = nil
	local secondGate = nil

	if (M.getReactorAddress(logFile)) then -- если нашли реальный адрес реактора ТО
		-- local component = require("component")
		local reactor = component.proxy(reactorAddress)
		if (not isValidFile) then
			if ((rCheck("maxFuelConversion") * 0.4) < rCheck("fuelConversion")) then
				print("Обслужите реактор, перезапустите программу")
				os.exit()
			else
				local t = {} -- Создаем локальную таблицу для хранения адресов Flux Gate
				for address, _ in component.list("flux") do -- Перебираем все компоненты типа Flux Gate
					table.insert(t, address) -- Добавляем адреса в таблицу
				end			
				if #t == 2 then -- Если в таблице есть два адреса, то
					firstGate = t[1] -- Получаем адреса из таблицы
					secondGate = t[2]
					gate = component.proxy(firstGate) -- Получаем объекты Flux Gate по адресам
					gate2 = component.proxy(secondGate)				
				else 						-- Если в таблице не два адреса, то
					print("Не удалось найти два адреса Flux Gate.") -- Выводим сообщение об ошибке
					os.exit()
				end
				
				if (rCheck("status") == "cold") then														--  STATUS COLD
					gate.setOverrideEnabled(true) -- Включаем режим переопределения потока для обоих гейтов
					gate2.setOverrideEnabled(true)
					gate.setFlowOverride(10) -- Устанавливаем поток для первого гейта в 10
					gate2.setFlowOverride(0) -- Устанавливаем поток для второго гейта в 0
					reactor.chargeReactor() -- Запускаем реактор
					local startFlow = rCheck("fieldStrength") -- Запоминаем начальную силу поля реактора
					print("Gates` scan test, please wait...")
					os.sleep(3) -- Ждем три секунды
					local endFlow = rCheck("fieldStrength") -- Запоминаем конечную силу поля реактора
					gate.setFlowOverride(0) -- Устанавливаем поток для первого гейта в 0
					if startFlow < endFlow then -- Если сила поля увеличилась, то
						fluxInAddress = firstGate -- Первый гейт является входным, а второй - выходным
						fluxOutAddress = secondGate					
					else						
						fluxOutAddress = firstGate -- Первый гейт является выходным, а второй - входным
						fluxInAddress = secondGate
					end
					reactor.stopReactor() -- stopReactor
					writeAddresses()					--ЗАПИСЬ АДРЕСОВ В ФАЙЛ
				--================================================================================================================
				elseif (rCheck("status") == "warming_up") then											--  STATUS warming_up
					gate.setOverrideEnabled(true) -- Включаем режим переопределения потока для обоих гейтов
					gate2.setOverrideEnabled(true)
					gate.setFlowOverride(0) -- Устанавливаем поток для первого гейта в 0
					gate2.setFlowOverride(0) -- Устанавливаем поток для второго гейта в 0
					print("Gates` scan test, please wait...")
					reactor.stopReactor() -- stopReactor
					os.sleep(2) -- Ждем две секунды------------Чтобы понизить силу поля и начать замеры
					reactor.chargeReactor() -- Запускаем процес зарядки реактора
					local startShield = rCheck("fieldStrength") -- Запоминаем начальную силу поля реактора
					gate.setFlowOverride(10) -- Устанавливаем поток для первого гейта в 10
					os.sleep(2) -- Ждем две секунды
					gate.setFlowOverride(0) -- Устанавливаем поток для первого гейта в 0
					local endShield = rCheck("fieldStrength") -- Запоминаем конечную силу поля реактора
					
					if startShield < endShield then -- Если сила поля увеличилась, то
						fluxInAddress = firstGate -- Первый гейт является входным, а второй - выходным
						fluxOutAddress = secondGate
					else	
						fluxOutAddress = firstGate -- Первый гейт является выходным, а второй - входным
						fluxInAddress = secondGate
					end
					writeAddresses()					--ЗАПИСЬ АДРЕСОВ В ФАЙЛ
				--====================================================================================================================	
				elseif (rCheck("status") == "running") then											--  STATUS running
					local levelGate_1 = gate.getFlow()
					local levelGate_2 = gate2.getFlow()
					local reactorShield = rCheck("fieldDrainRate")	
					local diff1 = math.abs(reactorShield - levelGate_1)
					local diff2 = math.abs(reactorShield - levelGate_2)
					if diff1 < diff2 then -- Сравнение двух гейтов по модулю с щитом
						fluxInAddress = firstGate -- Первый гейт является входным, а второй - выходным
						fluxOutAddress = secondGate					
					else						
						fluxOutAddress = firstGate -- Первый гейт является выходным, а второй - входным?
						fluxInAddress = secondGate
					end
					
					if (fluxInAddress == fluxOutAddress) then -- проверка чтобы гейты были разными
						print("Во время тестирования гейтов по модулю произошло совпадениие значений")
						os.exit()
					end
					writeAddresses()					--ЗАПИСЬ АДРЕСОВ В ФАЙЛ
				--=====================================================================================================================	
				elseif (rCheck("status") == "stopping") then					--  STATUS stopping	
					gate.setOverrideEnabled(true) -- Включаем режим переопределения потока для обоих гейтов
					gate2.setOverrideEnabled(true)
					local reactorShieldStart = rCheck("fieldStrength")
					gate.setFlowOverride(rCheck("fieldDrainRate") * 2) -- Устанавливаем поток для первого гейта в 0
					gate2.setFlowOverride(rCheck("fieldDrainRate") * 0.99) -- Устанавливаем поток для второго гейта в 0
					os.sleep(2)
					local reactorShieldEnd = rCheck("fieldStrength")
					
					if reactorShieldEnd > reactorShieldStart then
						fluxInAddress = firstGate -- Первый гейт является входным, а второй - выходным
						fluxOutAddress = secondGate
					else	
						fluxOutAddress = firstGate -- Первый гейт является выходным, а второй - входным
						fluxInAddress = secondGate
					end
					print("Поиск гейтов в статусе реактора stopping прошло удачно")
					writeAddresses()					--ЗАПИСЬ АДРЕСОВ В ФАЙЛ
				--=====================================================================================================================	
				elseif (rCheck("status") == "cooling") then																	--  STATUS cooling
					print("реактор почти остыл. Просто подожди как остынет и перезапусти программу")
					os.exit()
				end
			end
		end
	end
	result[1] = reactorAddress
	result[2] = fluxInAddress
	result[3] = fluxOutAddress
	return result
end



return M