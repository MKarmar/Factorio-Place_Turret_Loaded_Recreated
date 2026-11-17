-- Place Turret Loaded (Continued) - released under The Unlicense (https://unlicense.org)

local SETTING_NAME = "ptl-ammo-amount"

-- item name -> total damage per shot (derived from prototypes, so safe to cache)
local damage_cache = {}

-- Recursively add up every "damage" trigger effect inside an ammo_type definition.
local function sum_damage(node, depth)
  if type(node) ~= "table" or depth > 12 then return 0 end
  local total = 0
  if node.type == "damage" and type(node.damage) == "table" and node.damage.amount then
    total = total + node.damage.amount
  end
  for _, child in pairs(node) do
    if type(child) == "table" then
      total = total + sum_damage(child, depth + 1)
    end
  end
  return total
end

local function get_ammo_damage(item_name)
  local cached = damage_cache[item_name]
  if cached ~= nil then return cached end

  local score = 0
  local proto = prototypes.item[item_name]
  if proto and proto.type == "ammo" then
    local ok, ammo_type = pcall(function() return proto.get_ammo_type("turret") end)
    if not ok or not ammo_type then
      ok, ammo_type = pcall(function() return proto.get_ammo_type() end)
    end
    if ok and ammo_type then
      score = sum_damage(ammo_type.action, 0)
    end
  end

  damage_cache[item_name] = score
  return score
end

local function get_quality_level(quality_name)
  local q = quality_name and prototypes.quality[quality_name]
  return q and q.level or 0
end

local function on_built_entity(event)
  local turret = event.entity
  if not (turret and turret.valid) then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  local amount = settings.get_player_settings(player)[SETTING_NAME].value
  if not amount or amount <= 0 then return end

  local turret_inv = turret.get_inventory(defines.inventory.turret_ammo)
  local player_inv = player.get_main_inventory() -- main inventory only, not equipped weapon/ammo slots
  if not (turret_inv and player_inv) then return end

  -- Collect ammo stacks from the inventory, best damage first.
  local candidates = {}
  for _, item in pairs(player_inv.get_contents()) do
    local damage = get_ammo_damage(item.name)
    if damage > 0 then
      candidates[#candidates + 1] = {
        name = item.name,
        count = item.count,
        quality = item.quality,
        damage = damage,
        level = get_quality_level(item.quality),
      }
    end
  end

  table.sort(candidates, function(a, b)
    if a.damage ~= b.damage then return a.damage > b.damage end
    if a.level ~= b.level then return a.level > b.level end
    if a.name ~= b.name then return a.name < b.name end
    return (a.quality or "") < (b.quality or "")
  end)

  -- Insert into the turret; insert() returns 0 for ammo the turret can't accept
  -- (wrong category, or slot already holds a different ammo type).
  local remaining = amount
  for _, c in ipairs(candidates) do
    if remaining <= 0 then break end
    local inserted = turret_inv.insert{
      name = c.name,
      count = math.min(remaining, c.count),
      quality = c.quality,
    }
    if inserted > 0 then
      player_inv.remove{name = c.name, count = inserted, quality = c.quality}
      remaining = remaining - inserted
    end
  end
end

script.on_event(defines.events.on_built_entity, on_built_entity, {
  {filter = "type", type = "ammo-turret"},
})
