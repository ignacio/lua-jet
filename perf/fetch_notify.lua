#!/usr/bin/env lua
-- Measure fetch-notification throughput and the impact of a growing
-- number of fetchers (which dont match).
-- This (unrealistic) setup can not benefit from message batches.
local profiler = require'profiler'
local jet = require'jet'
local ev = require'ev'

local port = 10112

local daemon = jet.daemon.new({
    port = port,
    crit = print
})

daemon:start()

local peer = jet.peer.new({
    port = port
})

local long_path_prefix = string.rep('foobar',10)

local count_state = peer:state({
    path = long_path_prefix..'COUNT',
    value = 0
})

local count = 1

-- Creates an exact path based count fetcher
-- which increments the count immediatly.
peer:fetch('^'..count_state:path()..'$',function(path,event,value)
    assert(value == (count-1))
    count_state:value(count)
    count = count + 1
  end)

local dt = 10
local fetchers = 1
local last = 0

-- After 'dt' seconds, print the current throughput results and
-- restart the test with 20 more peers.
ev.Timer.new(function(loop,timer)
    -- receiving a changed value actually implies 2 messages
    print(math.floor((count-last)*2/dt),'fetch-notify/sec @'..fetchers..' fetchers')
    last = count
    if fetchers > 201 then
      peer:close()
      daemon:stop()
      timer:stop(loop)
    else
      for i=1,20 do
        peer:fetch('^'..long_path_prefix..fetchers..'$',function() end)
        fetchers = fetchers + 1
      end
    end
  end,dt,dt):start(ev.Loop.default)

--profiler.start()

ev.Loop.default:loop()

--profiler.stop()
