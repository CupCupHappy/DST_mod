--
-- p_players.lua
-- Copyright (C) 2019 Yongwen Zhuang <zyeoman@163.com>
--
-- Distributed under terms of the MIT license.
--
-- 玩家修改
--
--   受伤降低成长伤害
--
--   2020-07-11 - 删除击杀蓝水晶奖励


AddPlayerPostInit(function(inst)
  inst:ListenForEvent("attacked", function()
    if inst and inst.components.combat then
      local weapon = inst.components.combat:GetWeapon()
      if weapon ~= nil then
        local chengzhang = weapon.components.weapon.externaldamage:CalculateModifierFromSource('chengzhang')
        weapon.components.weapon:SetDamage(chengzhang*0.8, 'chengzhang')
      end
    end
  end)
  local function onkilledfn(inst, data)
      local victim = data.victim
      if inst.oldfish_lastkilled == victim.GUID then
        return
      end
      inst.oldfish_lastkilled = victim.GUID
      if victim and victim.components.health then
          local healths = victim.components.health.maxhealth
          inst.components.oldfish:DoDelta_exp(healths)
      end
  end
  local function gaussian (mean, variance)
    return  math.sqrt(-2 * variance * math.log(math.random())) *
            math.cos(2 * math.pi * math.random()) + mean
  end
  function oneatfn(inst, data)
    local food = data.food
    if food then
      if food.prefab == "daoyaun_pill" then
        if math.abs(gaussian(0, 1)) > 4*(inst.components.oldfish.xxlevel/16) then
          inst.components.oldfish.xxlevel = inst.components.oldfish.xxlevel + 1
          inst.components.talker:Say('一朝顿悟，等级上升')
          inst.components.oldfish:touxian()
        end
      elseif food.prefab == "hongmeng_pill" then
        inst.components.oldfish.daoyuan = inst.components.oldfish.daoyuan or 0
        inst.components.oldfish.daoyuan = inst.components.oldfish.daoyuan + 5
        if (gaussian(9.5-inst.components.oldfish.gengu, 8)) > 0 then
          inst.components.oldfish:DoDelta_gengu(1)
        else
          inst.components.oldfish:DoDelta_gengu(-1)
        end
      elseif food.prefab == "mandrake" then
        inst.components.oldfish:punish()
      elseif food.prefab == "mandrake_cooked" then
        inst.components.oldfish:endpunish()
      else
        local swlingli = math.floor(food.components.edible.healthvalue*0.4 + food.components.edible.hungervalue*0.1 + food.components.edible.sanityvalue*0.5)*100
        inst.components.oldfish:DoDelta_exp(swlingli)
      end
    end
  end
  inst:ListenForEvent("killed", onkilledfn)
  inst:ListenForEvent("oneat", oneatfn)
  inst:DoTaskInTime(1,function()
    if inst.components.oldfish then
      inst.components.oldfish:touxian()
    end
  end)

  local oldDoDelta  = inst.components.health.DoDelta
  inst.components.health.DoDelta = function(self,amount,...)
    if amount < 0 and self.inst.components.oldfish.xxlevel and  self.inst.components.oldfish.xxlevel >= 16 then
      amount = 0
    end
    oldDoDelta(self,amount,...)
  end

  local oldCalcDamage  = inst.components.combat.CalcDamage
  inst.components.combat.CalcDamage = function(self,target, weapon, multiplier,...)
    local old = oldCalcDamage(self,target, weapon, multiplier,...)
    return old + (self.inst.components.oldfish.daoyuan ~= nil and self.inst.components.oldfish.daoyuan  or 0)
  end
end)
