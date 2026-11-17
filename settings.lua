data:extend({
  {
    type = "int-setting",
    name = "ptl-ammo-amount",
    setting_type = "runtime-per-user", -- per player
    default_value = 10,
    minimum_value = 0, -- 0 disables auto-loading
    maximum_value = 100,
    order = "a"
  }
})
