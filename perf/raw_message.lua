local ev = require'ev'
local port = 12343
local count = 0
local server = require'jet.socket'.listener({
    port = port,
    on_connect = function(other)
      other:on_message(function(_,msg)
          count = count + 1
          other:send(msg)
        end)
    end
})

local client = require'jet.socket'.new({
    ip = 'localhost',
    port = port
})

client:on_message(function(client,msg)
    count = count + 1    
    client:send(msg)
  end)

client:on_connect(function()
    client:send('hello')
  end)

client:connect()

local dt = tonumber(arg[1]) or 3
ev.Timer.new(function()
    print(count/dt,'messages/sec')
    client:close()
    server:close()
  end,dt):start(ev.Loop.default)

ev.Loop.default:loop()
