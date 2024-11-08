

-- Этот файл должен в дальнейшем быть точкой входа в программу 


reactorInit = require("reactorInit")
-- reactorHeating = require("reactorHeating")
-- shield = require("shield")
-- component = require("component")

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