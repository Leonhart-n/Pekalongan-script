local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Leonhart-n/Pekalongan-script/refs/heads/main/user-interface/lib.luau"))()

-- ─── Buat Window ────────────────────────────────────────────────────────────
local Window = UILib.CreateWindow({
    Title       = "Pekalongan - CDID",
    Slogan      = "There is no secret ingredient. The secret is believing in yourself.",
    LogoText    = "P",
    AccentColor = Color3.fromRGB(192, 57, 43),
})

-- ─── Tab: ESP ────────────────────────────────────────────────────────────────
local ESPTab = Window:CreateTab({ Name = "ESP", Icon = "◉" })

-- Left section
local ESPSection = ESPTab:CreateSection("ESP", "left")

ESPSection:CreateToggle({
    Name        = "Enable ESP",
    Description = "Reveals player positions through walls with outlines.",
    Default     = true,
    Callback    = function(state)
        print("ESP:", state)
    end,
})

ESPSection:CreateToggle({
    Name        = "Bullet tracer",
    Description = "Visualizes projectile paths in real time.",
    Default     = false,
    Callback    = function(state)
        print("Bullet tracer:", state)
    end,
})

ESPSection:CreateToggle({
    Name        = "Display distance",
    Description = "Shows range to targets on screen.",
    Default     = false,
    Callback    = function(state)
        print("Display distance:", state)
    end,
})

-- Right section
local LootSection = ESPTab:CreateSection("LootESP", "right")

LootSection:CreateToggle({
    Name        = "Loot items",
    Description = "Highlights valuable items and equipment on the ground.",
    Default     = true,
})

LootSection:CreateSlider({
    Name     = "Loot distance",
    Min      = 100,
    Max      = 200,
    Default  = 150,
    Callback = function(val)
        print("Loot distance:", val)
    end,
})

LootSection:CreateToggle({ Name = "Weapon", Default = true })
LootSection:CreateToggle({ Name = "Ammo",   Default = true })
LootSection:CreateToggle({ Name = "Keys",   Default = false })
LootSection:CreateToggle({ Name = "Barter", Default = true })

-- ─── Keybind untuk toggle window ─────────────────────────────────────────────
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Window:Toggle()
    end
end)
