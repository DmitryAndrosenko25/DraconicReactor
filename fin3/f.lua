component = require("component")
local reactor = component.proxy("71bc94b4-e89e-430d-91e7-801f8511ef23")
local fluxIn = component.proxy("623d5254-2eff-4d6c-a6e8-a8edd8dfd25a")
local fluxOut = component.proxy("dadcbf04-51b9-4ae9-9fe3-fe039dd2b48c")

function rInfoS(info) --- на вход параметр реактора в string ..на выход значение 
    st = reactor.getReactorInfo()
    return st[info]
end

fluxOut.setOverrideEnabled(false)

fluxIn.setOverrideEnabled(false)

