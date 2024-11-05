local reactorCheck = {} -- Создаем модуль для проверки реактора

local component = require("component") -- Импортируем библиотеку Opencomputers
local logFile = "reactorInfo.txt" -- Объявляем локальные переменные для имени файла и адресов адаптеров
local reactorAddress = "reactor="
local fluxInAddress = "fluxIn="
local fluxOutAddress = "fluxOut="
local reactor = nil

local function rInfoCheck(info) -- Создаем локальную функцию для получения информации о реакторе
	local reactorF = component.proxy(reactorAddress) -- Получаем объект реактора по адресу		
	local st = reactorF.getReactorInfo() -- Получаем статус реактора
	return st[info] -- Возвращаем значение по ключу
end

function reactorCheck.reactorSearchAddress() -- Создаем функцию для поиска адресов адаптеров reactorCheck.
	local f = io.open(logFile, "r") -- Пытаемся открыть файл для чтения
	if f then -- Если файл существует, то
		print(string.format("Файл настроек %s был найден.", logFile)) -- Выводим сообщение
		local readed = {} -- Создаем локальную таблицу для хранения адресов
		for var in f:lines() do -- Читаем файл построчно и добавляем строки в таблицу
			table.insert(readed, var)
		end
		f:close() -- Закрываем файл
		
		for _, v in pairs(readed) do -- Перебираем таблицу с адресами
			if v:find(reactorAddress) then -- Если строка содержит адрес реактора, то
				reactorAddress = string.sub(v, ((v:find('='))+1)) -- Обрезаем строку до адреса
				print("Адрес реактора определен - "..reactorAddress) -- Выводим сообщение
			elseif v:find(fluxInAddress) then -- Если строка содержит адрес входного Flux Gate, то
				fluxInAddress = string.sub(v, ((v:find('='))+1)) -- Обрезаем строку до адреса
				print("Адрес входного flux gate определен - "..fluxInAddress) -- Выводим сообщение
			elseif v:find(fluxOutAddress) then -- Если строка содержит адрес выходного Flux Gate, то
				fluxOutAddress = string.sub(v, ((v:find('='))+1)) -- Обрезаем строку до адреса
				print("Адрес выходного flux gate определен - "..fluxOutAddress) -- Выводим сообщение
			end
		end		
	
	else
		print(string.format("Создаётся новый файл настроек %s с реальными адресами", logFile))		--"Файл настроек %s не был найден или был поврежден.", logFile)) -- Выводим сообщение
		for v, _ in component.list("draco") do -- Пытаемся найти адрес реактора среди компонентов
			reactorAddress = v
		end		
		if reactorAddress then -- Если адрес реактора найден, то
			reactor = component.proxy(reactorAddress) -- Получаем объект реактора по адресу
			local t = {} -- Создаем локальную таблицу для хранения адресов Flux Gate
			for address, _ in component.list("flux") do -- Перебираем все компоненты типа Flux Gate
				table.insert(t, address) -- Добавляем адреса в таблицу
			end			
			if #t == 2 then -- Если в таблице есть два адреса, то
				local firstGate = t[1] -- Получаем адреса из таблицы
				local secondGate = t[2]
				local gate = component.proxy(firstGate) -- Получаем объекты Flux Gate по адресам
				local gate2 = component.proxy(secondGate)
				gate.setOverrideEnabled(true) -- Включаем режим переопределения потока для обоих гейтов
				gate2.setOverrideEnabled(true)
				gate.setFlowOverride(1) -- Устанавливаем поток для первого гейта в 1        temp 100
				gate2.setFlowOverride(0) -- Устанавливаем поток для второго гейта в 0
				reactor.chargeReactor() -- Запускаем реактор
				local startFlow = rInfoCheck("fieldStrength") -- Запоминаем начальную силу поля реактора
				print("please wait...")
				os.sleep(3) -- Ждем одну секунду																	!!!!!!!!!!!!!!!!!!!!!!!!
				
				
				local endFlow = rInfoCheck("fieldStrength") -- Запоминаем конечную силу поля реактора
				gate.setFlowOverride(0) -- Устанавливаем поток для первого гейта в 0
				if startFlow < endFlow then -- Если сила поля увеличилась, то
					fluxInAddress = firstGate -- Первый гейт является входным, а второй - выходным
					fluxOutAddress = secondGate					
				-- elseif startFlow > endFlow then -- Если сила поля уменьшилась, то
				else	
					-- print("Какая то жопа с определением гейтов")
					fluxOutAddress = firstGate -- Первый гейт является выходным, а второй - входным
					fluxInAddress = secondGate
				end
				reactor.stopReactor() -- stopReactor
				
				local file = io.open('reactorInfo.txt', 'w') -- Пытаемся создать файл для записи адресов
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
			else -- Если в таблице не два адреса, то
				print("Не удалось найти два адреса Flux Gate.") -- Выводим сообщение об ошибке
			end
		else -- Если адрес реактора не найден, то
			print("Не удалось найти адрес реактора.") -- Выводим сообщение об ошибке
		end
	end	
	local result = {reactorAddress, fluxInAddress, fluxOutAddress} -- Создаем локальную таблицу для хранения результатов
	return result
end

return reactorCheck -- Возвращаем модуль для проверки реактора
--running, stopping, cold, warming_up, cooling!!!!!!!!!!!!