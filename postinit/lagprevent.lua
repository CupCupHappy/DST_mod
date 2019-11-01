--
-- lagprevent.lua
-- Copyright (C) 2019 Yongwen Zhuang <zyeoman@163.com>
--
-- Distributed under terms of the MIT license.
--
-- 防卡一招
-- 来自 workshop-609675532
--

local _G = GLOBAL
-- 指数增长速度
local rate = 1.1

local prefabs = 
{

  mole = 24,
  --molehill = 24,

  bee = 60,
  killerbee = 30,

  -- babybeefalo = 5,
  -- beefalo = 20,
  -- beefaloherd = 20,

  bat = 40,
  frog = 40,

  mosquito = 20,

  monkey = 40,

  spiderden = 40,
  spider = 60,
  spider_warrior = 30,
  spiderqueen = 5,
  spider_hider = 60,
  spider_spitter = 35,

  skeleton_player = 16,

  spoiled_food = 500,

  --hound = 20,
  firehound = 20,
  icehound = 20,

  bunnyman = 30,
  pigman = 30,
  merm = 30,
  rocky = 30,

  -- leif_sparse = 10,
  -- lightninggoat = 10,

  -- mossling = 12,
  klaus = 1,

  glommer = 8,
  rabbit = 160,
  --rabbithole = 160,

  penguin = 40,

  --fireflies = 600,

  --marsh_bushs = 150,
  --red_mushroom = 160,
  --blue_mushroom = 160,
  --green_mushroom = 160,
  --flower = 200,
  --cactuss = 200,
  --carrot_planteds = 200,
  --tumbleweedspawners = 50,
  --tumbleweed = 50,
  --saplings = 1000,
  --grass = 500,
}

function clazz(_ctor)
  local c = {}    -- a new class instance

  c.__index = c

  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj, c)
    if c._ctor then
      c._ctor(obj, ...)
    end
    return obj
  end    

  c._ctor = _ctor
  setmetatable(c, mt)

  return c
end

LinkedList2 = clazz(function(self)
  self._head = nil
  self._tail = nil
  self._count = 0
end)

function LinkedList2:Append(v)
  local elem = {data=v}
  if self._head == nil and self._tail == nil then
    self._head = elem
    self._tail = elem
  else
    elem._prev = self._tail
    self._tail._next = elem
    self._tail = elem
  end
  self._count = self._count + 1
  return v
end

function LinkedList2:Remove(v)
  local current = self._head
  while current ~= nil do
    if current.data == v then
      if current._prev ~= nil then
        current._prev._next = current._next
      else
        self._head = current._next
      end

      if current._next ~= nil then
        current._next._prev = current._prev
      else
        self._tail = current._prev
      end
      self._count = self._count - 1
      return true
    end

    current = current._next
  end

  return false
end

function LinkedList2:Head()
  return self._head and self._head.data or nil
end

function LinkedList2:Tail()
  return self._tail and self._tail.data or nil
end

function LinkedList2:Clear()
  self._head = nil
  self._tail = nil
  self._count = 0
end

function LinkedList2:Count()
  return self._count
end

function LinkedList2:Iterator()
  return {
    _list = self,
    _current = nil,
    Current = function(it)
      return it._current and it._current.data or nil
    end,
    RemoveCurrent = function(it)
      -- use to snip out the current element during iteration

      if it._current._prev == nil and it._current._next == nil then
        -- empty the list!
        it._list:Clear()
        return
      end

      local count = it._list:Count()

      if it._current._prev ~= nil then
        it._current._prev._next = it._current._next
      else
        --assert(it._list._head == it._current)
        it._list._head = it._current._next
      end

      if it._current._next ~= nil then
        it._current._next._prev = it._current._prev
      else
        --assert(it._list._tail == it._current)
        it._list._tail = it._current._prev
      end

      it._list._count = count - 1
      --assert(count-1 == it._list:Count())

      -- NOTE! "current" is now not part of the list, but its _next and _prev still work for iterating off of it.
    end,
    Next = function(it)
      if it._current == nil then
        it._current = it._list._head
      else
        it._current = it._current._next
      end
      return it:Current()
    end,
  }
end

local counts = {}
local entlist = {}

local dec_fn = function (inst)
  local name = inst.prefab
  if counts[name] > 0 then
    counts[name] = counts[name] - 1
  end
  if entlist[name] == nil then
    return
  end
  entlist[name]:Remove(inst)
end

local sel_random = function(name, ent)
  local random = math.random
  local list = entlist[name]
  if list == nil then
    return ent
  end
  local count = list:Count()
  if count == 0 then
    return ent
  end
  local id = random(count)
  local i = 0
  local it = list:Iterator()
  while it:Next() ~= nil do
    i = i + 1
    if i == id then
      local current = it:Current()
      return current
    end
  end
  return ent
end

local spawn_fn = function (name, ent)
  local list = entlist[name]
  if list == nil then
    list = LinkedList2()
    entlist[name] = list
  end
  list:Append(ent)
end

  local count_fn = function (name, ent)
    if counts[name] == nil then
      counts[name] = 1
    else
      counts[name] = counts[name] + 1
    end
    return counts[name]
  end

  local do_strength = function(ent)
    if ent~=nil and ent.components.combat~=nil and ent.components.health~=nil then
      local choice = math.random(3)
      if choice == 1 then
        ent.components.health:SetMaxHealth(ent.components.health.maxhealth*rate)
      elseif choice == 2 then
        ent.components.combat.externaldamagemultipliers:SetModifier("limit", rate*ent.components.combat.externaldamagemultipliers:CalculateModifierFromSource("limit"))
      elseif choice == 3 then
        ent.components.combat.externaldamagetakenmultipliers:SetModifier("limit", rate*ent.components.combat.externaldamagetakenmultipliers:CalculateModifierFromSource("limit"))
      end
    end
  end

local function WaitActivated(inst)
  local TheWorld = inst
  local old_SpawnPrefab = nil
  if _G.SpawnPrefab ~= nil then
    old_SpawnPrefab = _G.SpawnPrefab
    _G.SpawnPrefab = function (name, skin, skin_id, creator, ...)
      local lim = prefabs[name]
      if lim ~= nil then
        lim = lim*4
        local N = count_fn(name, ent)
        if N > lim then
          local to_strength = sel_random(name)
          do_strength(to_strength)
        else
          local ent = old_SpawnPrefab(name, skin, skin_id, creator, ...)
          ent:ListenForEvent("onremove", dec_fn)
          spawn_fn(name, ent)
          return ent
        end
      end
      return nil
    end
  end
end
