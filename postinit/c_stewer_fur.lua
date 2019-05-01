--
-- c_stewer_fur.lua
-- Copyright (C) 2019 Yongwen Zhuang <zeoman@163.com>
--
-- Distributed under terms of the MIT license.
--
-- 修改炼丹炉使之支持炼制武器
--
--
local types = {
  ["fire"]=1,       -- 火焰
  ["ice"]=1,        -- 冰霜
  ["lifesteal"]=2,  -- 吸血
  ["shrinker"]=1,   -- 减速
  ["crit"]=2,       -- 暴击
  ["vorpal"]=2,     -- 秒杀
  ["poison"]=2,     -- 剧毒
  ["sharp"]=2,      -- 锋锐
  ["dehealth"]=3,   -- 邪恶
  ["repair"]=4,     -- 再生
  ["grow"]=4,     -- 成长
  ["thorny"]=-1,    -- 带刺
  ["slippery"]=-1,  -- 湿滑
  ["disappear"]=-2, -- 残破
}
local desc = {
  ["fire"]="火焰",
  ["ice"]="冰霜",
  ["lifesteal"]="吸血",
  ["shrinker"]="减速",
  ["crit"]="暴击",
  ["vorpal"]="秒杀",
  ["poison"]="剧毒",
  ["sharp"]="锋锐",
  ["dehealth"]="邪恶",
  ["repair"]="再生",
  ["grow"]="成长",
  ["thorny"]="带刺",
  ["slippery"]="湿滑",
  ["disappear"]="残破",
}

local function randomchoice(t)
  local keys = {}
  for key, value in pairs(t) do
    keys[#keys+1] = key --Store keys in another table
  end
  index = keys[math.random(1, #keys)]
  return index, t[index], #keys
end

local function addtype(inst, tps, num)
  inst.components.weapon.types = {}
  local key, value, size = randomchoice(tps)
  if size < num then
    for key, value in pairs(tps) do
      inst.components.weapon.types[key] = value
    end
  else
    local count = 0
    for i=1,num*10 do
      local key, value = randomchoice(tps)
      if inst.components.weapon.types[key] ~= value then
        inst.components.weapon.types[key] = value
        count = count + 1
        if count == num then
          return
        end
      end
    end
  end
end

local function cookcook(inst)
  local a = 960
  local b = 480
  local c = 180
  if inst:Has("minotaurhorn", 1) and inst:Has("bluegem", 1) and inst:Has("foliage", 1) and inst:Has("nitre", 1) then
    return "heat_resistant_pill" , a  --避暑
  elseif inst:Has("minotaurhorn", 1) and inst:Has("redgem", 1) and inst:Has("foliage", 1) and inst:Has("nitre", 1) then
    return "cold_resistant_pill" , a  --避寒丹
  elseif inst:Has("minotaurhorn", 1) and inst:Has("yellowgem", 1) and inst:Has("foliage", 1) and inst:Has("nitre", 1) then
    return "dust_resistant_pill" , a --避尘丹
  elseif inst:Has("heat_resistant_pill", 1) and inst:Has("bluegem", 1) and inst:Has("foliage", 1) and inst:Has("nitre", 1) then
    return "heat_resistant_pill" , b  --避暑重置
  elseif inst:Has("cold_resistant_pill", 1) and inst:Has("redgem", 1) and inst:Has("foliage", 1) and inst:Has("nitre", 1) then
    return "cold_resistant_pill" , b  --避寒重置
  elseif inst:Has("dust_resistant_pill", 1) and inst:Has("yellowgem", 1) and inst:Has("foliage", 1) and inst:Has("nitre", 1) then
    return "dust_resistant_pill" , b --避尘重置
  elseif inst:Has("nitre", 1) and inst:Has("dragonfruit", 1) and inst:Has("honey", 1) and inst:Has("nightmarefuel", 1) then
    return "fly_pill" , c --腾云
  elseif inst:Has("purplegem", 1) and inst:Has("livinglog", 1) and inst:Has("batwing", 1) and inst:Has("nightmarefuel", 1) then
    return "bloodthirsty_pill" , c --嗜血
  elseif inst:Has("gunpowder", 1) and inst:Has("stinger", 1) and inst:Has("durian", 1) and inst:Has("nightmarefuel", 1) then
    return "condensed_pill" , c --凝神
  else
    local i = 0
    local value = 0
    local dmg = 0
    for k = 1, inst.numslots do
      local item = inst:GetItemInSlot(k)
      if item and item.components.weapon then
        for k,v in pairs(item.components.weapon.types or {}) do
          value = value + types[k]*v
        end
        dmg = dmg + item.components.weapon.damage or 0
        i = i+1
      end
    end
    if i < 4 then
      return nil, 1.5
    else
      return "weapon", 1+value*15+dmg/4
    end
  end
  return nil , 1.5
end
local function dobad(inst, self) --over
  self.task = nil
  if self.puff ~= nil then
    self.puff:Cancel()
    self.puff = nil
  end
  self.targettime = nil

  if self.ondobad ~= nil then
    self.ondobad(inst)
  end
  self.done = nil
  if inst.components.container then
    inst.components.container.canbeopened = true
  end
end
local function dostew(inst, self) --over
  self.task = nil
  if self.puff ~= nil then
    self.puff:Cancel()
    self.puff = nil
  end
  self.targettime = nil

  if self.ondonecooking ~= nil then
    self.ondonecooking(inst)
  end
  self.done = true
end
local function dopuff(inst, self)
  local pt = Vector3(inst.Transform:GetWorldPosition())
  local mk_cloudpuff = SpawnPrefab( "mk_cloudpuff" )
  mk_cloudpuff.Transform:SetPosition( pt.x , pt.y + 1, pt.z)
  mk_cloudpuff:DoTaskInTime(3,function() mk_cloudpuff:Remove()end)
  self.puff = inst:DoTaskInTime(math.random(5,8), dopuff, self)
end

AddComponentPostInit("stewer_fur", function(Stewer_Fur)
  function Stewer_Fur:StartCooking()
    if self.targettime == nil and self.inst.components.container ~= nil then
      self.done = nil

      if self.onstartcooking ~= nil then
        self.onstartcooking(self.inst)
      end
      local cooktime = 1
      self.product, cooktime = cookcook(self.inst.components.container) --"kabobs" ,  60 -- cooking.CalculateRecipe(self.inst.prefab, ings)
      if self.product ~= nil then
        self.percent = nil
        self.targettime = GetTime() + cooktime
        if self.task ~= nil then
          self.task:Cancel()
        end
        self.task = self.inst:DoTaskInTime(cooktime, dostew, self)
        for i=1,cooktime do
          self.inst:DoTaskInTime(i,function(inst)
            if self.inst.components.talker == nil then
              self.inst:AddComponent("talker")
            end
            self.inst.components.talker:Say("还剩"..cooktime-i.."s")
          end)
        end

        if self.puff ~= nil then
          self.puff:Cancel()
        end
        self.puff = self.inst:DoTaskInTime(math.random(5,8), dopuff, self)
        self.inst.components.container:Close()
        --self.inst.components.container:DestroyContents()
        for k = 1, self.inst.components.container.numslots do
          local item = self.inst.components.container:GetItemInSlot(k)
          if item ~= nil then
            if item:HasTag("mk_pills") then
              self.percent = item.components.fueled and item.components.fueled:GetPercent() or 1
            end
          end
        end
        self.inst.components.container.canbeopened = false

      else
        self.targettime = 1.5
        self.product = nil
        self.percent = nil
        if self.task ~= nil then
          self.task:Cancel()
        end

        if self.puff ~= nil then
          self.puff:Cancel()
        end
        self.task = self.inst:DoTaskInTime(1.5, dobad, self)

        self.inst.components.container:Close()
        self.inst.components.container:DestroyContents()
        self.inst.components.container.canbeopened = false
      end
    end
  end
  function Stewer_Fur:Harvest(harvester)
    if self.done then
      if self.onharvest ~= nil then
        self.onharvest(self.inst)
      end

      if self.product ~= nil then
        local loot = nil
        if self.product == "weapon" then
          local weapon_types = {}
          for k = 1, self.inst.components.container.numslots do
            local item = self.inst.components.container:GetItemInSlot(k)
            for k,v in pairs(item.components.weapon.types or {}) do
              weapon_types[k] = v + (weapon_types[k] or 0)
            end
          end
          if next(weapon_types) == nil then
            local key = randomchoice(types)
            weapon_types[key] = 1
          end
          loot = self.inst.components.container:RemoveItemBySlot(1)
          if loot then
            addtype(loot, weapon_types, math.random(3,5))
            if loot.components.named == nil then
              loot:AddComponent("named")
            end
            local originName = STRINGS.NAMES[string.upper(loot.prefab)]
            local name = originName
            for key, value in pairs(loot.components.weapon.types) do
              name = name .. '\n' .. desc[key] .. ' : +' .. value
            end
            loot.components.named:SetName(name)
            local damage = loot.components.weapon.externaldamage:Get()/2 - (loot.components.weapon.basedamage or 0) / 2
            for i = 2, self.inst.components.container.numslots do
              local item = self.inst.components.container:RemoveItemBySlot(i)
              if item ~= nil then
                damage = damage + item.components.weapon.damage/2
                item:Remove()
              end
            end
            loot.components.weapon:AddDamage("stewer", math.min(damage, loot.components.weapon.damage or 99999))
          end
        else
          loot = SpawnPrefab(self.product)
        end
        if loot ~= nil then
          local stacksize =  1
          if stacksize > 1 then
            loot.components.stackable:SetStackSize(stacksize)
          end
          if  self.percent ~= nil and loot.components.fueled ~= nil   then
            loot.components.fueled:SetPercent(self.percent + 0.5)
          end
          if harvester ~= nil and harvester.components.inventory ~= nil then
            harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
          else
            LaunchAt(loot, self.inst, nil, 1, 1)
          end
        end
        self.inst.components.container:DestroyContents()
        self.product = nil
        self.percent = nil
      end

      if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
      end
      if self.puff ~= nil then
        self.puff:Cancel()
        self.puff = nil
      end
      self.targettime = nil
      self.done = nil

      if self.inst.components.container ~= nil then
        self.inst.components.container.canbeopened = true
      end
      return true
    end
  end
end)