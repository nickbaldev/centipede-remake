do
local _ENV = _ENV
package.preload[ "middleclass" ] = function( ... ) local arg = _G.arg;
local middleclass = {
  _VERSION     = 'middleclass v4.1.1',
  _DESCRIPTION = 'Object Orientation for Lua',
  _URL         = 'https://github.com/kikito/middleclass',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local function _createIndexWrapper(aClass, f)
  if f == nil then
    return aClass.__instanceDict
  elseif type(f) == "function" then
    return function(self, name)
      local value = aClass.__instanceDict[name]

      if value ~= nil then
        return value
      else
        return (f(self, name))
      end
    end
  else -- if  type(f) == "table" then
    return function(self, name)
      local value = aClass.__instanceDict[name]

      if value ~= nil then
        return value
      else
        return f[name]
      end
    end
  end
end

local function _propagateInstanceMethod(aClass, name, f)
  f = name == "__index" and _createIndexWrapper(aClass, f) or f
  aClass.__instanceDict[name] = f

  for subclass in pairs(aClass.subclasses) do
    if rawget(subclass.__declaredMethods, name) == nil then
      _propagateInstanceMethod(subclass, name, f)
    end
  end
end

local function _declareInstanceMethod(aClass, name, f)
  aClass.__declaredMethods[name] = f

  if f == nil and aClass.super then
    f = aClass.super.__instanceDict[name]
  end

  _propagateInstanceMethod(aClass, name, f)
end

local function _tostring(self) return "class " .. self.name end
local function _call(self, ...) return self:new(...) end

local function _createClass(name, super)
  local dict = {}
  dict.__index = dict

  local aClass = { name = name, super = super, static = {},
                   __instanceDict = dict, __declaredMethods = {},
                   subclasses = setmetatable({}, {__mode='k'})  }

  if super then
    setmetatable(aClass.static, {
      __index = function(_,k)
        local result = rawget(dict,k)
        if result == nil then
          return super.static[k]
        end
        return result
      end
    })
  else
    setmetatable(aClass.static, { __index = function(_,k) return rawget(dict,k) end })
  end

  setmetatable(aClass, { __index = aClass.static, __tostring = _tostring,
                         __call = _call, __newindex = _declareInstanceMethod })

  return aClass
end

local function _includeMixin(aClass, mixin)
  assert(type(mixin) == 'table', "mixin must be a table")

  for name,method in pairs(mixin) do
    if name ~= "included" and name ~= "static" then aClass[name] = method end
  end

  for name,method in pairs(mixin.static or {}) do
    aClass.static[name] = method
  end

  if type(mixin.included)=="function" then mixin:included(aClass) end
  return aClass
end

local DefaultMixin = {
  __tostring   = function(self) return "instance of " .. tostring(self.class) end,

  initialize   = function(self, ...) end,

  isInstanceOf = function(self, aClass)
    return type(aClass) == 'table'
       and type(self) == 'table'
       and (self.class == aClass
            or type(self.class) == 'table'
            and type(self.class.isSubclassOf) == 'function'
            and self.class:isSubclassOf(aClass))
  end,

  static = {
    allocate = function(self)
      assert(type(self) == 'table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
      return setmetatable({ class = self }, self.__instanceDict)
    end,

    new = function(self, ...)
      assert(type(self) == 'table', "Make sure that you are using 'Class:new' instead of 'Class.new'")
      local instance = self:allocate()
      instance:initialize(...)
      return instance
    end,

    subclass = function(self, name)
      assert(type(self) == 'table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
      assert(type(name) == "string", "You must provide a name(string) for your class")

      local subclass = _createClass(name, self)

      for methodName, f in pairs(self.__instanceDict) do
        if not (methodName == "__index" and type(f) == "table") then
          _propagateInstanceMethod(subclass, methodName, f)
        end
      end
      subclass.initialize = function(instance, ...) return self.initialize(instance, ...) end

      self.subclasses[subclass] = true
      self:subclassed(subclass)

      return subclass
    end,

    subclassed = function(self, other) end,

    isSubclassOf = function(self, other)
      return type(other)      == 'table' and
             type(self.super) == 'table' and
             ( self.super == other or self.super:isSubclassOf(other) )
    end,

    include = function(self, ...)
      assert(type(self) == 'table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")
      for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
      return self
    end
  }
}

function middleclass.class(name, super)
  assert(type(name) == 'string', "A name (string) is needed for the new class")
  return super and super:subclass(name) or _includeMixin(_createClass(name), DefaultMixin)
end

setmetatable(middleclass, { __call = function(_, ...) return middleclass.class(...) end })

return middleclass
end
end

do
local _ENV = _ENV
package.preload[ "std.strict" ] = function( ... ) local arg = _G.arg;
--[[
 Strict variable declarations for Lua 5.1, 5.2, 5.3 & 5.4.
 Copyright (C) 2006-2023 std.strict authors
]]
--[[--
 Diagnose uses of undeclared variables.

 All variables(including functions!) must be "declared" through a regular
 assignment(even assigning `nil` will do) in a strict scope before being
 used anywhere or assigned to inside a nested scope.

 Use the callable returned by this module to interpose a strictness check
 proxy table to the given environment.   The callable runs `setfenv`
 appropriately in Lua 5.1 interpreters to ensure the semantic equivalence.

 @module std.strict
]]


local setfenv = rawget(_G, 'setfenv') or function() end
local debug_getinfo = debug.getinfo


-- Return callable objects.
-- @function callable
-- @param x an object or primitive
-- @return *x* if *x* can be called, otherwise `nil`
-- @usage
--   (callable(functable) or function()end)(args, ...)
local function callable(x)
   -- Careful here!
   -- Most versions of Lua don't recurse functables, so make sure you
   -- always put a real function in __call metamethods.  Consequently,
   -- no reason to recurse here.
   -- func=function() print 'called' end
   -- func() --> 'called'
   -- functable=setmetatable({}, {__call=func})
   -- functable() --> 'called'
   -- nested=setmetatable({}, {__call=function(self, ...) return functable(...)end})
   -- nested() -> 'called'
   -- notnested=setmetatable({}, {__call=functable})
   -- notnested()
   -- --> stdin:1: attempt to call global 'nested' (a table value)
   -- --> stack traceback:
   -- -->	stdin:1: in main chunk
   -- -->		[C]: in ?
   if type(x) == 'function' or (getmetatable(x) or {}).__call then
      return x
   end
end


-- Return named metamethod, if callable, otherwise `nil`.
-- @param x item to act on
-- @string n name of metamethod to look up
-- @treturn function|nil metamethod function, if callable, otherwise `nil`
local function getmetamethod(x, n)
   return callable((getmetatable(x) or {})[n])
end


-- Length of a string or table object without using any metamethod.
-- @function rawlen
-- @tparam string|table x object to act on
-- @treturn int raw length of *x*
-- @usage
--    --> 0
--    rawlen(setmetatable({}, {__len=function() return 42}))
local function rawlen(x)
   -- Lua 5.1 does not implement rawlen, and while # operator ignores
   -- __len metamethod, `nil` in sequence is handled inconsistently.
   if type(x) ~= 'table' then
      return #x
   end

   local n = #x
   for i = 1, n do
      if x[i] == nil then
         return i -1
      end
   end
   return n
end


-- Deterministic, functional version of core Lua `#` operator.
--
-- Respects `__len` metamethod (like Lua 5.2+).   Otherwise, always return
-- one less than the lowest integer index with a `nil` value in *x*, where
-- the `#` operator implementation might return the size of the array part
-- of a table.
-- @function len
-- @param x item to act on
-- @treturn int the length of *x*
-- @usage
--    x = {1, 2, 3, nil, 5}
--    --> 5 3
--    print(#x, len(x))
local function len(x)
   return (getmetamethod(x, '__len') or rawlen)(x)
end


-- Like Lua `pairs` iterator, but respect `__pairs` even in Lua 5.1.
-- @function pairs
-- @tparam table t table to act on
-- @treturn function iterator function
-- @treturn table *t*, the table being iterated over
-- @return the previous iteration key
-- @usage
--    for k, v in pairs {'a', b='c', foo=42} do process(k, v) end
local pairs = (function(f)
   if not f(setmetatable({},{__pairs=function() return false end})) then
      return f
   end

   return function(t)
      return(getmetamethod(t, '__pairs') or f)(t)
   end
end)(pairs)


-- What kind of variable declaration is this?
-- @treturn string 'C', 'Lua' or 'main'
local function what()
   local d = debug_getinfo(3, 'S')
   return d and d.what or 'C'
end


return setmetatable({
   --- Module table.
   -- @table strict
   -- @string version release version identifier


   --- Require variable declarations before use in scope *env*.
   --
   -- Normally the module @{strict:__call} metamethod is all you need,
   -- but you can use this method for more complex situations.
   -- @function strict
   -- @tparam table env lexical environment table
   -- @treturn table *env* proxy table with metamethods to enforce strict
   --    declarations
   -- @usage
   --   local _ENV = setmetatable({}, {__index = _G})
   --   if require 'std._debug'.strict then
   --      _ENV = require 'std.strict'.strict(_ENV)
   --   end
   --   -- ...and for Lua 5.1 compatibility, without triggering undeclared
   --   -- variable error:
   --   if rawget(_G, 'setfenv') ~= nil then
   --      setfenv(1, _ENV)
   --   end
   strict = function(env)
      -- The set of declared variables in this scope.
      local declared = {}

      --- Environment Metamethods
      -- @section environmentmetamethods

      return setmetatable({}, {
         --- Detect dereference of undeclared variable.
         -- @function env:__index
         -- @string n name of the variable being dereferenced
         __index = function(_, n)
            local v = env[n]
            if v ~= nil then
               declared[n] = true
            elseif not declared[n] and what() ~= 'C' then
               error("variable '" .. n .. "' is not declared", 2)
            end
            return v
         end,

         --- Proxy `len` calls.
         -- @function env:__len
         -- @tparam table t strict table
         __len = function() return len(env) end,

         --- Detect assignment to undeclared variable.
         -- @function env:__newindex
         -- @string n name of the variable being declared
         -- @param v initial value of the variable
         __newindex = function(_, n, v)
            local x = env[n]
            if x == nil and not declared[n] then
               local w = what()
               if w ~= 'main' and w ~= 'C' then
                  error("assignment to undeclared variable '" .. n .. "'", 2)
               end
            end
            declared[n] = true
            env[n] = v
         end,

         --- Proxy `pairs` calls.
         -- @function env:__pairs
         -- @tparam table t strict table
         __pairs = function()
            return pairs(env)
         end,
      })
   end,
}, {
   --- Module Metamethods
   -- @section modulemetamethods

   --- Enforce strict variable declarations in *env*.
   -- @function strict:__call
   -- @tparam table env lexical environment table
   -- @tparam[opt=1] int level stack level for `setfenv`, 1 means
   --    set caller's environment
   -- @treturn table *env* which must be assigned to `_ENV`
   -- @usage
   --   local _ENV = require 'std.strict'(_G)
   __call = function(self, env, level)
      env = self.strict(env)
      setfenv(1 + (level or 1), env)
      return env
   end,

   --- Lazy loading of strict submodules.
   -- Don't load everything on initial startup, wait until first attempt
   -- to access a submodule, and then load it on demand.
   -- @function __index
   -- @string name submodule name
   -- @treturn table|nil the submodule that was loaded to satisfy the missing
   --    `name`, otherwise `nil` if nothing was found
   -- @usage
   --   local strict = require 'std.strict'
   --   local version = strict.version
   __index = function(self, name)
      local ok, t = pcall(require, 'std.strict.' .. name)
      if ok then
         rawset(self, name, t)
         return t
      end
   end,
})
end
end

-- title:   game title
-- author:  game developer, email, etc.
-- desc:    short description
-- site:    website link
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

local _ENV = require 'std.strict' (_G)

SCREEN_WIDTH = 240
SCREEN_HEIGHT = 136
PLAYER_SPEED = 2
BULLET_SPEED = 5
CENTIPEDE_SPEED = 1
MUSHROOM_COUNT = 20
PIXEL_SIZE = 8
FIRE_RATE = 10

player = {x=120, y=120, width=8, height=8, bullets={}}
centipedes = {}
mushrooms = {}
spider = {x=0, y=120, speed=0.75, alive=true, respawn_timer=0, dir=1,
            jump_counter=0, jump_time=60, is_jumping = true}
score = 0
lives = 3
level = 1

fire_timer = 0
frame_count = 0

respawn_timer = 0
respawn_delay = 120
is_respawning = false

function start()
--generates the centipede and muchrooms when the game first starts
    create_centipede()
    create_mushrooms(MUSHROOM_COUNT)
end

function respawn()
--sets game state when you respawn, adds some mushrooms on the screen and resets centipede
    player.x = 120
    player.y = 120
    player.bullets = {}
    centipedes = {}
    create_centipede()
    create_mushrooms(10)
end

function respawn_spider()
    local side = get_random()
    if side == -1 then 
        spider.x = 0
    else spider.x = SCREEN_WIDTH-8 end
    spider.y = math.random(SCREEN_HEIGHT*2//3, SCREEN_HEIGHT-8)
    spider.alive = true
    spider.dir = get_random()
    spider.jump_counter = 0
    spider.is_jumping = true
    spider.jump_time = math.random(45, 65)
end

function create_centipede()
    local cent = {}
    for i = 0, 10 do
        table.insert(cent, {x=8*i, y=0, dir=1})
    end
    table.insert(centipedes, cent)
end

function create_mushrooms(n)
    for i = 1, n do
        local x = math.random(1, (SCREEN_WIDTH//PIXEL_SIZE)-2)* PIXEL_SIZE
        local y = math.random(1, (SCREEN_HEIGHT//PIXEL_SIZE)-3) * PIXEL_SIZE
        table.insert(mushrooms, {x=x, y=y, health=2})
    end
end 

function update_player()
--allows player to move and shoot
   --player movement
   if btn(2) and player.x > 0 then player.x = player.x - PLAYER_SPEED end
   if btn(3) and player.x < SCREEN_WIDTH-8 then player.x = player.x + PLAYER_SPEED end
   if btn(0) and player.y > (SCREEN_HEIGHT*2/3) then player.y = player.y - PLAYER_SPEED end
   if btn(1) and player.y < SCREEN_HEIGHT-16 then player.y = player.y + PLAYER_SPEED end

   --player shooting
   if btn(4) and frame_count - fire_timer >= FIRE_RATE then
      table.insert(player.bullets, {x = player.x + 3, y = player.y-2})
      fire_timer = frame_count
      sfx(0, 40, 10)
   end
end

function update_centipede()
--moves the centipede, flips its direction and moves down a level when it reaches a wall. 
--Also moves the centipede up two levels when it reaches the bottom.
    for _, centipede in ipairs(centipedes) do
        for _, segment in ipairs(centipede) do
            segment.x = segment.x + (segment.dir * CENTIPEDE_SPEED)
            
            if segment.y >= SCREEN_HEIGHT-8 then
                segment.y = segment.y - 24
            end
            
            if segment.x < 0 or segment.x > SCREEN_WIDTH-8 then
                segment.dir = -segment.dir
                segment.y = segment.y + 8
            end
        end
    end
end

function update_bullets()
--moves the bullets and removes them when they go off the screen
  for i = #player.bullets, 1, -1 do --iterate backwards to avoid the items in the table from shifting
     local bullet = player.bullets[i]
     bullet.y = bullet.y - BULLET_SPEED
     if bullet.y < 0 then
        table.remove(player.bullets, i)
     end
  end
end

function update_spider()
--moves the spider in zig zags in a random direction and random range of heights
    if spider.alive then
        if spider.is_jumping then
            spider.x = spider.x + spider.dir * spider.speed
            spider.y = spider.y - spider.speed
            
            spider.jump_counter = spider.jump_counter + 1
            if spider.jump_counter >= spider.jump_time then
                spider.is_jumping = false 
            end
        else
            -- makes spider fall
            spider.y = spider.y + spider.speed
            
            -- when spider hits the bottom
            if spider.y >= 120 then
                spider.y = 120
                spider.is_jumping = true
                spider.jump_counter = 0
                spider.jump_time = math.random(45, 65)
                spider.dir = get_random()
            end
        end

        -- bounds
        if spider.x < 0 then
            spider.dir = 1
            spider.x = 0
        elseif spider.x > SCREEN_WIDTH - 8 then
            spider.dir = -1
            spider.x = SCREEN_WIDTH - 8
        end
    else
        if spider.respawn_timer > 0 then
            spider.respawn_timer = spider.respawn_timer - 1
        else
            respawn_spider()
        end
    end
end

function check_mushroom_and_centipede_collision()
--changes the centipedes direction and y-cord if it hits a mushroom
    for _, centipede in ipairs(centipedes) do
        for _, segment in ipairs(centipede) do
            for _, mushroom in ipairs(mushrooms) do
                if segment.x < mushroom.x+8 and segment.x+8 > mushroom.x and segment.y < mushroom.y+8 and segment.y+8 > mushroom.y then
                    if segment.x < 0 or segment.x > SCREEN_WIDTH-8 then --this line fixes a bug where the centipede would infinitely change dir and y if hit mushroom located at the sides of the screen
                    else
                        segment.dir = -segment.dir
                        segment.y = segment.y+8
                    end
                    break
                end
            end
        end
    end
end

function check_mushroom_and_bullet_collision()
--removes a mushroom if hit by two bullets and adds score for each mushroom destroyed
   for i = #player.bullets, 1, -1 do
      local bullet = player.bullets[i]
      for j = #mushrooms, 1, -1 do
         local mushroom = mushrooms[j]
         if bullet.x < mushroom.x+8 and bullet.x+2 > mushroom.x and bullet.y < mushroom.y+8 and bullet.y+4 > mushroom.y then
            mushroom.health = mushroom.health - 1
            table.remove(player.bullets, i)
            if mushroom.health <= 0 then
                table.remove(mushrooms, j)
                score = score + 1 --one point for destroying a mushroom
            end
         end
      end
   end
end

function check_mushroom_and_spider_collison()
--checks if the spider touches a mushroom. If yes, it has a chance of eating that mushroom
    if spider.alive then
        for i = #mushrooms, 1, -1 do
            local mushroom = mushrooms[i]
            if spider.x < mushroom.x+8 and spider.x+8 > mushroom.x and spider.y < mushroom.y+8 and spider.y+8 > mushroom.y then
                if math.random(0, 40) == 0 then table.remove(mushrooms, i) end
                --since this runs more than once per second, can't just do math.random(0,3) 
                --for a 25% chance, so I expierimented and found that (0, 40) does it roughly 25% of the time
                break
            end
        end
    end
end

function check_bullet_and_centipede_collision()
--checks for when a bullet hits a segment in the centipede and removes
--that segment, and then splits the centipede into two if a middle segment is shot. 
--Also turns the segment that was shot into a mushroom, just like the real game.
    local temp_centipedes = {}
    for i = #player.bullets, 1, -1 do
        local bullet = player.bullets[i]
        for k = #centipedes, 1, -1 do
            local centipede = centipedes[k]
            local new_centipedes = {}
            for j = #centipede, 1, -1 do
                local segment = centipede[j]
                
                if bullet.x < segment.x+8 and bullet.x+2 > segment.x and bullet.y < segment.y+8 and bullet.y+4 > segment.y then
                    table.remove(player.bullets, i)
                    
                    local mushroom = {x=segment.x//PIXEL_SIZE*PIXEL_SIZE, y=segment.y//PIXEL_SIZE*PIXEL_SIZE, health=2}

                    if j==1 or j==#centipede then
                        if #centipede == 1 then
                            table.remove(centipede, j)
                            table.remove(centipedes, k)
                            score = score+100
                        else 
                            table.remove(centipede, j)
                            score = score+100
                        end
                        table.insert(mushrooms, mushroom)
                    else
                        local new_centipede1 = {}
                        local new_centipede2 = {}

                        for n=1, j-1 do
                            table.insert(new_centipede1, centipede[n])
                        end

                        for n=j+1, #centipede do
                            table.insert(new_centipede2, centipede[n])
                        end

                        if #new_centipede1 > 0 then
                            table.insert(new_centipedes, new_centipede1)
                        end

                        if #new_centipede2 > 0 then
                            table.insert(new_centipedes, new_centipede2)
                        end

                        table.remove(centipedes, k)
                        table.remove(centipede, j)
                        score = score+10
                        table.insert(mushrooms, mushroom)
                        break
                    end
                    --break
                end
            end
            
            for _, cent in ipairs(new_centipedes) do
                table.insert(centipedes, cent)
            end
        end
    end
    if #centipedes == 0 then
        next_level()
    end
end

function check_bullet_and_spider_collision()
--kills spider when shot and awards the player either 
--300, 600, or 900 points based on how far it was shot from
    if spider.alive then
        for i = #player.bullets, 1, -1 do
            local bullet = player.bullets[i]
            if bullet.x < spider.x + 8 and bullet.x + 2 > spider.x and bullet.y < spider.y + 8 and bullet.y + 4 > spider.y then
                local distance = player.y - spider.y
                if distance < 20 then 
                    score = score + 300
                elseif distance >= 20 and distance < 40 then
                    score = score + 600
                else
                    score = score + 900
                end
                spider.alive = false
                spider.respawn_timer = 150 
                table.remove(player.bullets, i)
                break
            end
        end
    end
end

function check_player_and_centipede_collision()
--removes a life if the player gets hit by a centipede and initiates respawn mechanics
    if is_respawning == false then
        for _, centipede in ipairs(centipedes) do
            for _, segment in ipairs(centipede) do
                if player.x < segment.x+8 and player.x+8 > segment.x and player.y < segment.y+8 and player.y+8 > segment.y then
                    sfx(1, 10, 10)
                    if lives > 0 then
                        lives = lives - 1
                    end
                    is_respawning = true
                    respawn_timer = respawn_delay
                    return
                end
            end
        end
    end
end

function check_player_and_spider_collision()
--removes a life if the player gets hit by a spider and initiates respawn mechanics
    if spider.alive and not is_respawning then
        if player.x < spider.x + 8 and player.x + player.width > spider.x and
           player.y < spider.y + 8 and player.y + player.height > spider.y then
            sfx(1, 10, 50)
            if lives > 0 then
                lives = lives - 1
            end

            is_respawning = true
            respawn_timer = respawn_delay
            spider.alive = false
            spider.respawn_timer = 150
            return
        end
    end
end

function update_respawn()
--allows the to game pause for 2 seconds while the player respawns
    if is_respawning then
        respawn_timer = respawn_timer - 1
        if respawn_timer <= 0 then
            is_respawning = false
            respawn()
        end
    end
end

function next_level()
--increases the level, creates a new centipede at the
--top of the screen, and adds 15 mushrooms to the field
    level = level + 1
    create_centipede()
    create_mushrooms(15)
end

function draw_game(mushroom_sprite, centipede_sprite, spider_sprite)
--draws the player, centipedes, mushrooms, spider, score, and lives on the screen
    spr(10, player.x, player.y)
    for _, bullet in ipairs(player.bullets) do
        rect(bullet.x, bullet.y, 2, 4, 1)
    end
    
    for _, centipede in ipairs(centipedes) do
        for _, segment in ipairs(centipede) do
            spr(centipede_sprite, segment.x, segment.y)
        end
    end
    
    for _, mushroom in ipairs(mushrooms) do
        spr(mushroom_sprite, mushroom.x, mushroom.y)
    end

    if spider.alive then
        spr(spider_sprite, spider.x, spider.y)
    end

    print("_______________________________________________", 0, 125, 12)
    print(score, 210, 131, 12)
    --draw lives
    for i = 1, lives do
        --rect((i-1)*PIXEL_SIZE, 131, 5, 5, 12)
        spr(10, (i-1)*PIXEL_SIZE, 131)
    end
end

function get_mushroom_sprite()
--returns the proper mushroom sprite to use based on the level
    local sprites = {0, 2, 4, 6, 8}
    local index = level%5
    if index == 0 then 
        return sprites[5]
    else return sprites[index] end
end

function get_centipede_sprite()
--returns the proper centipede sprite to use based on the level
    local sprites = {1, 3, 5, 7, 9}
    local index = level%5
    if index == 0 then 
        return sprites[5]
    else return sprites[index] end
end

function get_spider_sprite()
--returns the proper spider sprite to use based on the level
    local sprites = {11, 12, 13, 14, 15}
    local index = level%5
    if index == 0 then 
        return sprites[5]
    else return sprites[index] end
end

function get_random()
--helper function used to get a random direction
    if math.random() > 0.5 then 
        return 1
    else return -1 end
end

function play_game()
--function that combines the game elements and run the game to clean up the TIC() function
    if lives > 0 then
        if not is_respawning then
            update_player()
            update_bullets()
            update_centipede()
            update_spider()
            
            check_mushroom_and_centipede_collision()
            check_mushroom_and_bullet_collision()
            check_mushroom_and_spider_collison()
            check_bullet_and_centipede_collision()
            check_bullet_and_spider_collision()
            check_player_and_centipede_collision()
            check_player_and_spider_collision()
        else
            --put animation or sound if we get to it
        end
        update_respawn()
        local spr1 = get_mushroom_sprite()
        local spr2 = get_centipede_sprite()
        local spr3 = get_spider_sprite()
        draw_game(spr1, spr2, spr3)
    else
        print("GAME OVER", 0, SCREEN_HEIGHT//2-5, 12)
        print("YOUR SCORE: " .. score, 0, SCREEN_HEIGHT//2+5, 12)
    end

    if level > 5 then 
        spider.speed = 1.5 
        spider.jump_time = 40
    end
end

function TIC()
    cls()
    frame_count = frame_count + 1
    play_game()
end

start()

-- <TILES>
-- 000:0222222022222222222222222222222222222222002222000033330000333300
-- 001:0022220022333322233333323333333333333333233333322233332200222200
-- 002:0333333033333333333333333333333333333333003333000044440000444400
-- 003:0033330033444433344444434444444444444444344444433344443300333300
-- 004:0555555055555555555555555555555555555555005555000066660000666600
-- 005:0055550055666655566666656666666666666666566666655566665500555500
-- 006:0888888088888888888888888888888888888888008888000077770000777700
-- 007:0088880088777788877777787777777777777777877777788877778800888800
-- 008:09999990999999999999999999999999999999990099990000aaaa0000aaaa00
-- 009:0099990099aaaa999aaaaaa9aaaaaaaaaaaaaaaa9aaaaaa999aaaa9900999900
-- 010:000cc000000cc0000cdccdc00cccccc00ccaacc00dccccd000dccd00000cc000
-- 011:2000000202200220002332002233332200333300023333202030030220000002
-- 012:3000000303300330003443003344443300444400034444303040040330000003
-- 013:5000000505500550005665005566665500666600056666505060060550000005
-- 014:8000000808800880008778008877778800777700087777808070070880000008
-- 015:9000000909900990009aa90099aaaa9900aaaa0009aaaa9090a00a0990000009
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 003:00000660707000800009667970a00660
-- 004:000bbc78000988743495867000ccb004
-- 005:00057000000aa84999f0280000000550
-- 006:00c9900c93304a93077a86095a3bbbb0
-- 007:000a0eb31b5580640700020440000004
-- </WAVES>

-- <SFX>
-- 000:000000200030005000600080009000a000b000d000e000e000f000f000f000f000f000d000c000c000b000b000a000a0009000900080006000400030305000000000
-- 001:07f0070007000700078007000700070007f0070007000700077007000700070007f0070007000700077007000700070007f007000700070007700700208000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2cfa005d0cee00f600e600ffffff0400ffd2003824ffffff0c8d00faff205973eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

