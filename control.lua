-- Place Turret Loaded (Continued) - Unlicense (https://unlicense.org)
-- Loads a placed ammo turret from the player's inventory (first pick).

local SETTING_NAME = "ptl-ammo-amount" -- see settings.lua this indicates how many ammo entities will be added to the turret on placement

local function on_built_entity(event)
  local turret = event.entity
  if not (turret and turret.valid) then return end -- test if it was a turret build

  local player = game.get_player(event.player_index)
  if not player then return end 

  -- per-player setting, 0 = off, this is an early break
  local remaining = settings.get_player_settings(player)[SETTING_NAME].value
  if not remaining or remaining <= 0 then return end

  -- main inventory only, so equipped gun/ammo slots are left alone
  local turret_inv = turret.get_inventory(defines.inventory.turret_ammo)
  local player_inv = player.get_main_inventory()
  if not (turret_inv and player_inv) then return end -- test if turret and player have an inventory to break early

  -- left to right, top to bottom
  for i = 1, #player_inv do --for each inventory slot:
    local stack = player_inv[i] --pointer to the specific inventory slot
    if stack.valid_for_read and stack.type == "ammo" then -- test if the inventory slot can be read (test if empty), and if it is an ammo type
      

      -- returns 0 if the turret won't take it (wrong category / slot taken)
      local inserted = turret_inv.insert{
        name = stack.name,
        count = math.min(remaining, stack.count),
        quality = stack.quality,
      }

      - remove the inserted amount of ammo form the player inventory
      if inserted > 0 then
        stack.count = stack.count - inserted
        remaining = remaining - inserted
        if remaining <= 0 then return end
      end
    end
  end
end

-- filter so we only get called for turrets (players only, not robots)
script.on_event(defines.events.on_built_entity, on_built_entity, {
  {filter = "type", type = "ammo-turret"},
})
