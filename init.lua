

local function keyCode(key, modifiers)
   modifiers = modifiers or {}
   return function()
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), true):post()
      hs.timer.usleep(1000)
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), false):post()
   end
end

local function keyCodeSet(keys)
   return function()
      for i, keyEvent in ipairs(keys) do
         keyEvent()
      end
   end
end

local function remapKey(modifiers, key, keyCode)
   hs.hotkey.bind(modifiers, key, keyCode, nil, keyCode)
end


local function disableAllHotkeys()
   for k, v in pairs(hs.hotkey.getHotkeys()) do
      v['_hk']:disable()
   end
end

local function enableAllHotkeys()
   for k, v in pairs(hs.hotkey.getHotkeys()) do
      v['_hk']:enable()
   end
end

local function handleGlobalAppEvent(name, event, app)
   if event == hs.application.watcher.activated then
      -- hs.alert.show(name)
      if name == "iTerm2" then
         disableAllHotkeys()
      else
         enableAllHotkeys()
      end
   end
end



appsWatcher = hs.application.watcher.new(handleGlobalAppEvent)
appsWatcher:start()


local function enableSemicoronHotKey()
    for k, v in pairs(hs.hotkey.getHotkeys()) do
      if v['idx'] == ";" then
        v["_hk"]:enable()
      end
    end
end

local function disableSemicoronHotKey()
    for k, v in pairs(hs.hotkey.getHotkeys()) do
      if v['idx'] == ";" then
        v["_hk"]:disable()
      end
    end
end


local function inputSourceChangedForSemicoron()
    -- hs.alert.show(hs.keycodes.currentMethod())
    
    if hs.keycodes.currentMethod() == nil or hs.keycodes.currentMethod():find('英字') then
        
        enableSemicoronHotKey()
    else
        disableSemicoronHotKey()
    end
end





hs.keycodes.inputSourceChanged(inputSourceChangedForSemicoron)


remapKey({}, ";", keyCode("return"))



local customKeyCodeTable = {}
customKeyCodeTable[0x66] = true -- EISUU
--customKeyCodeTable[0x68] = true -- KANA
local pressedCustomKeyTable = {}
local consumed = false
local remapKeyTable = {}
remapKeyTable[0x66] = {}
remapKeyTable[0x66][38] = {{}, 125} -- 下
remapKeyTable[0x66][40] = {{}, 126 }-- 上
remapKeyTable[0x66][4] = {{}, 123 }-- 左
remapKeyTable[0x66][37] = {{}, 124 }-- 右
remapKeyTable[0x66][14] = {{}, 53 }-- ESC
remapKeyTable[0x66][41] = {{}, 41} -- ;
remapKeyTable[0x66][3] = {{}, 51 } -- DEL
remapKeyTable[0x66][49] = {{}, 51 } -- DEL
remapKeyTable[0x66][34] = {{}, 116 } -- pageup 
remapKeyTable[0x66][31] = {{}, 121 } -- pagedown
remapKeyTable[0x66][32] = {{ "option", "control" }, 32 } -- Alfred
remapKeyTable[0x66][0] = {{ "command" }, 49 } -- Alfred clipboard
remapKeyTable[0x66][12] = {{ "control", "option" }, 103 } --iterm



eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
    local keyCode = event:getKeyCode()
    inputSourceChangedForSemicoron()
    if customKeyCodeTable[keyCode] == true then
        if event:getType() == hs.eventtap.event.types.keyDown then
            disableSemicoronHotKey()
            pressedCustomKeyTable[keyCode] = true
            return true
        end
        if event:getType() == hs.eventtap.event.types.keyUp then
            enableSemicoronHotKey()
        end
        pressedCustomKeyTable[keyCode] = false
        local currentConsumed = consumed
        consumed = false
        if currentConsumed == false then
            -- TODO: Modifier
            --hs.alert.show(keyCode)

            return true, {
                hs.eventtap.event.newKeyEvent({}, keyCode, true):setKeyCode(keyCode),
                hs.eventtap.event.newKeyEvent({}, keyCode, false):setKeyCode(keyCode)
            }
        end
    end
    local somePressed = false
    for keyCode, pressed in pairs(pressedCustomKeyTable) do
        if pressed == true then
            somePressed = true
            break
        end
    end
    if somePressed == true and event:getType() == hs.eventtap.event.types.keyDown then
        consumed = true
        keys = remapKeyTable[0x66][keyCode]

        if keys ~= nil then
            disableSemicoronHotKey()
            local modifiers = {table.unpack(keys[1])}
            for keyCode, pressed in pairs(event:getFlags()) do
                if pressed == true then
                    modifiers[#modifiers + 1] = keyCode
                end
            end
            if keys[2] ~= 53 then
                return true, {
                     hs.eventtap.event.newKeyEvent(modifiers, keys[2], true):setKeyCode(keys[2]),
                     hs.eventtap.event.newKeyEvent(modifiers, keys[2], false):setKeyCode(keys[2])
                }
            else
                return true, {
                     hs.eventtap.event.newKeyEvent(modifiers, keys[2], true):setKeyCode(keys[2]),
                     hs.eventtap.event.newKeyEvent(modifiers, keys[2], false):setKeyCode(keys[2]),
                     hs.eventtap.event.newKeyEvent(modifiers, 0x66, true):setKeyCode(keys[2]),
                     hs.eventtap.event.newKeyEvent(modifiers, 0x66, false):setKeyCode(keys[2])
                }
            end
        end
    end
end)
eventtap:start()





--- Perfect backslash(\) for Mac JIS keybord users

-- The problem:
--   On Mac, Japanese IME setting to replace Yen-backslash is ignored by
--   IntelliJ, jEdit or such as because JVM uses another keymap traditionally.

-- Solution:
--   Use Hammerspoon (http://www.hammerspoon.org/) instead of Japanese IME
--   setting. Paste below to your ~/.hammerspoon/init.lua file.

-- @author Hisateru Tanaka (tanakahisateru@gmail.com)

local VK_1 = 0x12
local VK_ESC = 0x35

-- Secret key codes not included in hs.keycodes.map
local VK_JIS_YEN = 0x5d
local VK_JIS_UNDERSCORE = 0x5e

--local log = hs.logger.new('keyhook','debug')

function flagsMatches(flags, modifiers)
    local set = {}
    for _, k in ipairs(modifiers) do set[string.lower(k)] = true end
    for _, k in ipairs({'fn', 'cmd', 'ctrl', 'alt', 'shift'}) do
        if set[k] ~= flags[k] then return false end
    end
    return true
end

-- NEVER define as local variable!
jisKeyboardFilter = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp
}, function(event)
    local c = event:getKeyCode()
    local f = event:getFlags()
    -- log.d(...)
    if c == VK_JIS_YEN then
        -- To input \ even if JVM, toggle Option key status when Yen key.
        if flagsMatches(f, {'alt'}) then
            event:setFlags({})
        elseif flagsMatches(f, {}) then
            event:setFlags({alt=true})
        end
        -- Hint: Never replace key code to backslash itself because JIS
        -- keyboard does'nt have phisical backslash and assignes it to close
        -- bracket (]) key.
--    elseif c == VK_JIS_UNDERSCORE then
        -- Also map single undetscore (_) key to backslash (\).
--        if flagsMatches(f, {}) then
--            event:setKeyCode(VK_JIS_YEN)
--            event:setFlags({alt=true})
--        end
    end
end)
jisKeyboardFilter:start()
















--
-- Fix Slack's channel switching.
-- This rebinds ctrl-tab and ctrl-shift-tab back to switching channels,
-- which is what they did before the Teams update.
--
-- Slack only provides alt+up/down for switching channels, (and the cmd-t switcher,
-- which is buggy) and have 3 (!) shortcuts for switching teams, most of which are
-- the usual tab switching shortcuts in every other app.
--
local ctrlTab = hs.hotkey.new({"ctrl"}, "tab", function()
  hs.eventtap.keyStroke({"alt", "shift"}, "Down")
end)
local ctrlShiftTab = hs.hotkey.new({"ctrl", "shift"}, "tab", function()
  hs.eventtap.keyStroke({"alt", "shift"}, "Up")
end)
slackWatcher = hs.application.watcher.new(function(name, eventType, app)
  if eventType ~= hs.application.watcher.activated then return end
  if name == "Slack" then
    ctrlTab:enable()
    ctrlShiftTab:enable()
  else
    ctrlTab:disable()
    ctrlShiftTab:disable()
  end
end)

-- If you re-init config often, be sure to stop() this before starting or you will
-- have multiple application watchers running at once.
slackWatcher:start()



