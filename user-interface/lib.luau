--[[
    UILib.lua — Roblox Luau UI Library
    Versi: 2.0
    
    USAGE:
        local UILib = loadstring(game:HttpGet("RAW_URL_HERE"))()

        local Win = UILib:CreateWindow({
            Title       = "Brand name",
            Slogan      = "The slogan, if there is one.",
            LogoText    = "R",
            AccentColor = Color3.fromRGB(192, 57, 43),
            Size        = Vector2.new(660, 424),
            ToggleKey   = Enum.KeyCode.RightShift,
        })

        local Tab = Win:AddTab({ Name = "ESP", Icon = "eye" })

        local Left  = Tab:AddSection("ESP",     "left")
        local Right = Tab:AddSection("LootESP", "right")

        Left:AddToggle({
            Name        = "Enable ESP",
            Description = "Reveals player positions through walls.",
            Default     = false,
            Callback    = function(v) print("ESP:", v) end,
        })

        Right:AddSlider({
            Name     = "Loot distance",
            Min      = 100,
            Max      = 200,
            Default  = 150,
            Callback = function(v) print("Dist:", v) end,
        })
]]

-- ════════════════════════════════════════════════════════════
--  Services
-- ════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════
--  Theme
-- ════════════════════════════════════════════════════════════
local T = {
    -- Window
    WindowBG        = Color3.fromRGB(28,  28,  28),
    WindowBorder    = Color3.fromRGB(46,  46,  46),
    -- TopBar / Sidebar
    DarkBG          = Color3.fromRGB(20,  20,  20),
    DividerColor    = Color3.fromRGB(35,  35,  35),
    -- Accent
    Accent          = Color3.fromRGB(192, 57,  43),
    AccentDark      = Color3.fromRGB(110, 28,  18),
    -- Text
    TextWhite       = Color3.fromRGB(255, 255, 255),
    TextPrimary     = Color3.fromRGB(210, 210, 210),
    TextSecondary   = Color3.fromRGB(130, 130, 130),
    TextMuted       = Color3.fromRGB(58,  58,  58),
    -- Row
    RowBG           = Color3.fromRGB(20,  20,  20),
    RowBorder       = Color3.fromRGB(32,  32,  32),
    -- Toggle
    ToggleOff       = Color3.fromRGB(52,  52,  52),
    ToggleOn        = Color3.fromRGB(192, 57,  43),
    -- Slider
    SliderTrack     = Color3.fromRGB(40,  40,  40),
    SliderFill      = Color3.fromRGB(192, 57,  43),
    -- Dropdown
    DropBG          = Color3.fromRGB(16,  16,  16),
    -- Sidebar icon states
    IconDefault     = Color3.fromRGB(64,  64,  64),
    IconActive      = Color3.fromRGB(192, 57,  43),
    SidebarActive   = Color3.fromRGB(30,  30,  30),
}

-- ════════════════════════════════════════════════════════════
--  Helpers
-- ════════════════════════════════════════════════════════════
local function New(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = obj end
    return obj
end

local function Tween(obj, goal, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        goal
    ):Play()
end

local function Corner(r)   return New("UICorner",  { CornerRadius = UDim.new(0, r or 8) })   end
local function Stroke(c,t) return New("UIStroke",  { Color = c or T.RowBorder, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
local function Padding(a,b,c,d)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, a or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, c or 0),
        PaddingRight  = UDim.new(0, d or 0),
    })
end
local function ListLayout(dir, halign, valign, pad)
    return New("UIListLayout", {
        FillDirection       = dir    or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
        Padding             = UDim.new(0, pad or 0),
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })
end

local function MakeDraggable(frame, handle)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; sp = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- Icon SVGs (subset — add more as needed)
-- Each returns a set of ImageLabel / Frame combos via DrawIcon()
-- We use simple Unicode chars mapped to a lookup for now;
-- swap with actual rbxassetid if you have image icons.
local Icons = {
    eye      = "👁",
    shield   = "🛡",
    info     = "ℹ",
    pulse    = "〜",
    folder   = "📁",
    settings = "⚙",
    home     = "⌂",
    zap      = "⚡",
}

-- ════════════════════════════════════════════════════════════
--  Library
-- ════════════════════════════════════════════════════════════
local UILib = {}
UILib.__index = UILib

function UILib:CreateWindow(cfg)
    cfg = cfg or {}
    local accent  = cfg.AccentColor or T.Accent
    local sz      = cfg.Size        or Vector2.new(660, 424)
    local togKey  = cfg.ToggleKey   or Enum.KeyCode.RightShift

    -- ── ScreenGui ────────────────────────────────────────────
    local GUI = New("ScreenGui", {
        Name           = "UILib_" .. (cfg.Title or "Window"),
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent         = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer.PlayerGui,
    })

    -- ── Window Frame ─────────────────────────────────────────
    local Win = New("Frame", {
        Name             = "Window",
        Size             = UDim2.fromOffset(sz.X, sz.Y),
        Position         = UDim2.new(0.5, -sz.X/2, 0.5, -sz.Y/2),
        BackgroundColor3 = T.WindowBG,
        BorderSizePixel  = 0,
        Parent           = GUI,
    }, {
        Corner(18),
        Stroke(T.WindowBorder, 1),
    })

    -- ── TopBar ───────────────────────────────────────────────
    local TopBar = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = T.DarkBG,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        ZIndex           = 2,
        Parent           = Win,
    }, {
        Corner(18),
    })
    -- Square off bottom of topbar
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 18),
        Position         = UDim2.new(0, 0, 1, -18),
        BackgroundColor3 = T.DarkBG,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = TopBar,
    })
    -- Divider
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.DividerColor,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = TopBar,
    })

    -- Logo box
    New("Frame", {
        Size             = UDim2.fromOffset(30, 30),
        Position         = UDim2.new(0, 12, 0.5, -15),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = TopBar,
    }, {
        Corner(8),
        New("TextLabel", {
            Size                 = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text                 = cfg.LogoText or "R",
            TextColor3           = Color3.new(1,1,1),
            TextSize             = 15,
            Font                 = Enum.Font.GothamBold,
            ZIndex               = 4,
        }),
    })

    -- Brand name
    New("TextLabel", {
        Size             = UDim2.fromOffset(300, 16),
        Position         = UDim2.new(0, 50, 0, 11),
        BackgroundTransparency = 1,
        Text             = cfg.Title  or "Brand name",
        TextColor3       = T.TextWhite,
        TextSize         = 12,
        Font             = Enum.Font.GothamSemibold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 3,
        Parent           = TopBar,
    })

    -- Slogan
    New("TextLabel", {
        Size             = UDim2.fromOffset(300, 14),
        Position         = UDim2.new(0, 50, 0, 29),
        BackgroundTransparency = 1,
        Text             = cfg.Slogan or "The slogan, if there is one.",
        TextColor3       = Color3.fromRGB(255,255,255),
        TextTransparency = 0.55,
        TextSize         = 10,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 3,
        Parent           = TopBar,
    })

    MakeDraggable(Win, TopBar)

    -- ── Sidebar ──────────────────────────────────────────────
    local Sidebar = New("Frame", {
        Size             = UDim2.new(0, 50, 1, -54),
        Position         = UDim2.new(0, 0, 0, 54),
        BackgroundColor3 = T.DarkBG,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        Parent           = Win,
    }, {
        Corner(18),
    })
    -- Square off top-right and top-left rounded bits
    New("Frame", { Size = UDim2.new(1,0,0,18), BackgroundColor3 = T.DarkBG, BorderSizePixel = 0, Parent = Sidebar })
    New("Frame", { Size = UDim2.new(0,18,1,0), Position = UDim2.new(1,-18,0,0), BackgroundColor3 = T.DarkBG, BorderSizePixel = 0, Parent = Sidebar })
    -- Sidebar right divider
    New("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T.DividerColor,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })

    -- Top icon list
    local TopIcons = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 200),
        BackgroundTransparency = 1,
        Parent           = Sidebar,
    }, {
        ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 2),
        Padding(10, 0, 0, 0),
    })

    -- Bottom icon list
    local BotIcons = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 90),
        Position         = UDim2.new(0, 0, 1, -90),
        BackgroundTransparency = 1,
        Parent           = Sidebar,
    }, {
        ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom, 2),
        Padding(0, 10, 0, 0),
    })

    -- ── Content Area ─────────────────────────────────────────
    local Content = New("Frame", {
        Name             = "Content",
        Size             = UDim2.new(1, -50, 1, -54),
        Position         = UDim2.new(0, 50, 0, 54),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = Win,
    })

    -- ── Window object ─────────────────────────────────────────
    local self        = setmetatable({}, UILib)
    self._gui         = GUI
    self._win         = Win
    self._sidebar     = Sidebar
    self._topIcons    = TopIcons
    self._botIcons    = BotIcons
    self._content     = Content
    self._accent      = accent
    self._tabs        = {}
    self._activeTab   = nil

    -- ── Toggle visibility ─────────────────────────────────────
    UIS.InputBegan:Connect(function(i, gpe)
        if not gpe and i.KeyCode == togKey then
            Win.Visible = not Win.Visible
        end
    end)

    -- ── Internal: make a sidebar icon button ──────────────────
    local function MakeSidebarBtn(icon, parent, isBottom)
        local btn = New("TextButton", {
            Size             = UDim2.fromOffset(36, 36),
            BackgroundColor3 = T.DarkBG,
            BackgroundTransparency = 1,
            Text             = "",
            BorderSizePixel  = 0,
            LayoutOrder      = isBottom and 999 or #parent:GetChildren(),
            Parent           = parent,
        }, { Corner(9) })

        -- Accent bar (hidden by default)
        local bar = New("Frame", {
            Size             = UDim2.fromOffset(3, 16),
            Position         = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = accent,
            BorderSizePixel  = 0,
            Visible          = false,
            Parent           = btn,
        }, { Corner(3) })

        -- Icon label
        New("TextLabel", {
            Size             = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text             = Icons[icon] or icon or "○",
            TextColor3       = T.IconDefault,
            TextSize         = 14,
            Font             = Enum.Font.Gotham,
            Parent           = btn,
        })

        return btn, bar
    end

    -- ════════════════════════════════════════════════════════
    --  AddTab
    -- ════════════════════════════════════════════════════════
    function self:AddTab(cfg)
        cfg = cfg or {}
        local tab = {}

        -- Sidebar button
        local btn, bar = MakeSidebarBtn(cfg.Icon or "○", TopIcons, false)

        -- Content frame (hidden until activated)
        local frame = New("Frame", {
            Name             = "Tab_" .. (cfg.Name or "Tab"),
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible          = false,
            Parent           = Content,
        })

        -- Split panels
        local leftPanel = New("Frame", {
            Name             = "Left",
            Size             = UDim2.new(0.5, -1, 1, 0),
            BackgroundTransparency = 1,
            Parent           = frame,
        })

        New("Frame", {  -- panel divider
            Size             = UDim2.new(0, 1, 1, 0),
            Position         = UDim2.new(0.5, -1, 0, 0),
            BackgroundColor3 = T.DividerColor,
            BorderSizePixel  = 0,
            Parent           = frame,
        })

        local rightPanel = New("Frame", {
            Name             = "Right",
            Size             = UDim2.new(0.5, -1, 1, 0),
            Position         = UDim2.new(0.5, 1, 0, 0),
            BackgroundTransparency = 1,
            Parent           = frame,
        })

        tab._btn    = btn
        tab._bar    = bar
        tab._frame  = frame
        tab._left   = leftPanel
        tab._right  = rightPanel
        tab._lib    = self

        -- Activate logic
        function tab:Activate()
            -- Deactivate current
            if self._lib._activeTab and self._lib._activeTab ~= self then
                local prev = self._lib._activeTab
                prev._frame.Visible = false
                prev._bar.Visible   = false
                Tween(prev._btn, { BackgroundTransparency = 1 }, 0.15)
                -- dim icon
                local ic = prev._btn:FindFirstChildWhichIsA("TextLabel")
                if ic then Tween(ic, { TextColor3 = T.IconDefault }, 0.15) end
            end
            self._lib._activeTab = self
            self._frame.Visible  = true
            self._bar.Visible    = true
            Tween(self._btn, { BackgroundTransparency = 0, BackgroundColor3 = T.SidebarActive }, 0.15)
            local ic = self._btn:FindFirstChildWhichIsA("TextLabel")
            if ic then Tween(ic, { TextColor3 = accent }, 0.15) end
        end

        btn.MouseButton1Click:Connect(function() tab:Activate() end)

        -- Auto-activate first tab
        if #self._tabs == 0 then
            task.defer(function() tab:Activate() end)
        end

        table.insert(self._tabs, tab)

        -- ══════════════════════════════════════════════════
        --  AddSection
        -- ══════════════════════════════════════════════════
        function tab:AddSection(name, side)
            local panel = (side == "right") and rightPanel or leftPanel
            local sec   = {}

            -- Panel header
            local hdr = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 38),
                BackgroundTransparency = 1,
                Parent           = panel,
            })
            -- Nav arrow (left panel only)
            if side ~= "right" then
                local navBtn = New("Frame", {
                    Size             = UDim2.fromOffset(20, 20),
                    Position         = UDim2.new(0, 12, 0.5, -10),
                    BackgroundColor3 = T.RowBG,
                    BorderSizePixel  = 0,
                    Parent           = hdr,
                }, {
                    Corner(5),
                    Stroke(T.DividerColor, 1),
                    New("TextLabel", {
                        Size             = UDim2.new(1,0,1,0),
                        BackgroundTransparency = 1,
                        Text             = "›",
                        TextColor3       = T.TextMuted,
                        TextSize         = 14,
                        Font             = Enum.Font.GothamBold,
                    }),
                })
            end
            -- Section label
            New("TextLabel", {
                Size             = UDim2.new(1, -50, 1, 0),
                Position         = UDim2.new(0, side == "right" and 14 or 40, 0, 0),
                BackgroundTransparency = 1,
                Text             = name or "Section",
                TextColor3       = T.TextMuted,
                TextSize         = 10,
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = hdr,
            })
            -- Header bottom divider
            New("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = T.DividerColor,
                BorderSizePixel  = 0,
                Parent           = hdr,
            })

            -- Scroll area
            local scroll = New("ScrollingFrame", {
                Size                 = UDim2.new(1, 0, 1, -38),
                Position             = UDim2.new(0, 0, 0, 38),
                BackgroundTransparency = 1,
                BorderSizePixel      = 0,
                ScrollBarThickness   = 2,
                ScrollBarImageColor3 = T.AccentDark,
                CanvasSize           = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize  = Enum.AutomaticSize.Y,
                Parent               = panel,
            }, {
                ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top, 5),
                Padding(10, 10, 10, 10),
            })

            sec._scroll = scroll
            sec._accent = accent

            -- ── Helper: make a row frame ──────────────────────────
            local function Row(h)
                return New("Frame", {
                    Size             = UDim2.new(1, 0, 0, h or 50),
                    BackgroundColor3 = T.RowBG,
                    BorderSizePixel  = 0,
                    LayoutOrder      = #scroll:GetChildren(),
                    Parent           = scroll,
                }, {
                    Corner(8),
                    Stroke(T.RowBorder, 1),
                })
            end

            -- ── Toggle ────────────────────────────────────────────
            function sec:AddToggle(cfg)
                cfg        = cfg or {}
                local state = cfg.Default or false
                local row   = Row(50)

                New("TextLabel", {
                    Size             = UDim2.new(1,-60,0,16),
                    Position         = UDim2.new(0,12,0,9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Toggle",
                    TextColor3       = T.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })
                New("TextLabel", {
                    Size             = UDim2.new(1,-60,0,13),
                    Position         = UDim2.new(0,12,0,27),
                    BackgroundTransparency = 1,
                    Text             = cfg.Description or "",
                    TextColor3       = T.TextMuted,
                    TextSize         = 9,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextTruncate     = Enum.TextTruncate.AtEnd,
                    Parent           = row,
                })
                -- Dots
                New("TextLabel", {
                    Size             = UDim2.fromOffset(20,20),
                    Position         = UDim2.new(1,-50,0.5,-10),
                    BackgroundTransparency = 1,
                    Text             = "···",
                    TextColor3       = T.TextMuted,
                    TextSize         = 12,
                    Font             = Enum.Font.GothamBold,
                    Parent           = row,
                })
                -- Track
                local track = New("Frame", {
                    Size             = UDim2.fromOffset(26,14),
                    Position         = UDim2.new(1,-28,0.5,-7),
                    BackgroundColor3 = state and T.ToggleOn or T.ToggleOff,
                    BorderSizePixel  = 0,
                    Parent           = row,
                }, { Corner(100) })
                -- Knob
                local knob = New("Frame", {
                    Size             = UDim2.fromOffset(10,10),
                    Position         = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel  = 0,
                    Parent           = track,
                }, { Corner(100) })

                local hitbox = New("TextButton", {
                    Size             = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 10,
                    Parent           = row,
                })
                hitbox.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(track, { BackgroundColor3 = state and T.ToggleOn or T.ToggleOff }, 0.15)
                    Tween(knob,  { Position = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }, 0.15)
                    if cfg.Callback then cfg.Callback(state) end
                end)

                local obj = {}
                function obj:Set(v)
                    state = v
                    Tween(track, { BackgroundColor3 = state and T.ToggleOn or T.ToggleOff }, 0.15)
                    Tween(knob,  { Position = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }, 0.15)
                end
                function obj:Get() return state end
                return obj
            end

            -- ── Slider ────────────────────────────────────────────
            function sec:AddSlider(cfg)
                cfg       = cfg or {}
                local min  = cfg.Min     or 0
                local max  = cfg.Max     or 100
                local val  = math.clamp(cfg.Default or min, min, max)
                local row  = Row(54)

                New("TextLabel", {
                    Size             = UDim2.new(0.55,0,0,16),
                    Position         = UDim2.new(0,12,0,9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Slider",
                    TextColor3       = T.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })
                local rangeLabel = New("TextLabel", {
                    Size             = UDim2.new(0,110,0,14),
                    Position         = UDim2.new(1,-120,0,9),
                    BackgroundTransparency = 1,
                    Text             = string.format("(%d, %d)", val, max),
                    TextColor3       = T.TextMuted,
                    TextSize         = 9,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Parent           = row,
                })
                -- Track bg
                local trackBg = New("Frame", {
                    Size             = UDim2.new(1,-24,0,6),
                    Position         = UDim2.new(0,12,0,34),
                    BackgroundColor3 = T.SliderTrack,
                    BorderSizePixel  = 0,
                    Parent           = row,
                }, { Corner(3) })
                -- Fill
                local pct  = (val - min) / math.max(max - min, 1)
                local fill = New("Frame", {
                    Size             = UDim2.new(pct,0,1,0),
                    BackgroundColor3 = T.SliderFill,
                    BorderSizePixel  = 0,
                    Parent           = trackBg,
                }, { Corner(3) })

                local dragging = false
                local hit = New("TextButton", {
                    Size             = UDim2.new(1,0,3,0),
                    Position         = UDim2.new(0,0,-1,0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 10,
                    Parent           = trackBg,
                })
                local function updateVal(x)
                    local rel  = math.clamp((x - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                    val        = math.floor(min + rel * (max - min) + 0.5)
                    fill.Size  = UDim2.new(rel, 0, 1, 0)
                    rangeLabel.Text = string.format("(%d, %d)", val, max)
                    if cfg.Callback then cfg.Callback(val) end
                end
                hit.MouseButton1Down:Connect(function() dragging = true end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        updateVal(i.Position.X)
                    end
                end)

                local obj = {}
                function obj:Set(v)
                    val = math.clamp(v, min, max)
                    local r = (val - min) / math.max(max - min, 1)
                    fill.Size = UDim2.new(r, 0, 1, 0)
                    rangeLabel.Text = string.format("(%d, %d)", val, max)
                end
                function obj:Get() return val end
                return obj
            end

            -- ── Dropdown ──────────────────────────────────────────
            function sec:AddDropdown(cfg)
                cfg      = cfg or {}
                local opts  = cfg.Options or {}
                local sel   = cfg.Default or (opts[1] or "")
                local open  = false
                local row   = Row(50)
                row.ClipsDescendants = true

                New("TextLabel", {
                    Size             = UDim2.new(0.55,0,0,50),
                    Position         = UDim2.new(0,12,0,0),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Dropdown",
                    TextColor3       = T.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })
                local valLabel = New("TextLabel", {
                    Size             = UDim2.new(0,110,0,50),
                    Position         = UDim2.new(1,-126,0,0),
                    BackgroundTransparency = 1,
                    Text             = sel,
                    TextColor3       = T.TextMuted,
                    TextSize         = 10,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Parent           = row,
                })
                New("TextLabel", {
                    Size             = UDim2.fromOffset(14,50),
                    Position         = UDim2.new(1,-16,0,0),
                    BackgroundTransparency = 1,
                    Text             = "▾",
                    TextColor3       = T.TextMuted,
                    TextSize         = 10,
                    Font             = Enum.Font.GothamBold,
                    Parent           = row,
                })

                local optList = New("Frame", {
                    Size             = UDim2.new(1,-24,0,#opts * 26),
                    Position         = UDim2.new(0,12,0,50),
                    BackgroundTransparency = 1,
                    Parent           = row,
                }, { ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, 2) })

                for _, o in ipairs(opts) do
                    local ob = New("TextButton", {
                        Size             = UDim2.new(1,0,0,22),
                        BackgroundColor3 = T.DropBG,
                        BorderSizePixel  = 0,
                        Text             = o,
                        TextColor3       = T.TextSecondary,
                        TextSize         = 10,
                        Font             = Enum.Font.Gotham,
                        Parent           = optList,
                    }, { Corner(5) })
                    ob.MouseButton1Click:Connect(function()
                        sel = o; valLabel.Text = o; open = false
                        Tween(row, { Size = UDim2.new(1,0,0,50) }, 0.2)
                        if cfg.Callback then cfg.Callback(sel) end
                    end)
                end

                local hit = New("TextButton", {
                    Size             = UDim2.new(1,0,0,50),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 10,
                    Parent           = row,
                })
                hit.MouseButton1Click:Connect(function()
                    open = not open
                    Tween(row, { Size = UDim2.new(1,0,0, open and 50 + #opts*28 or 50) }, 0.2)
                end)

                local obj = {}
                function obj:Set(v) sel = v; valLabel.Text = v end
                function obj:Get() return sel end
                return obj
            end

            -- ── Button ────────────────────────────────────────────
            function sec:AddButton(cfg)
                cfg       = cfg or {}
                local row = New("TextButton", {
                    Size             = UDim2.new(1,0,0,42),
                    BackgroundColor3 = T.RowBG,
                    BorderSizePixel  = 0,
                    Text             = "",
                    LayoutOrder      = #scroll:GetChildren(),
                    Parent           = scroll,
                }, {
                    Corner(8),
                    Stroke(T.RowBorder, 1),
                })
                New("TextLabel", {
                    Size             = UDim2.new(1,-36,1,0),
                    Position         = UDim2.new(0,12,0,0),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Button",
                    TextColor3       = T.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })
                New("TextLabel", {
                    Size             = UDim2.fromOffset(20,42),
                    Position         = UDim2.new(1,-24,0,0),
                    BackgroundTransparency = 1,
                    Text             = "›",
                    TextColor3       = T.TextMuted,
                    TextSize         = 16,
                    Font             = Enum.Font.GothamBold,
                    Parent           = row,
                })
                row.MouseButton1Click:Connect(function()
                    Tween(row, { BackgroundColor3 = T.AccentDark }, 0.1)
                    task.delay(0.15, function() Tween(row, { BackgroundColor3 = T.RowBG }, 0.15) end)
                    if cfg.Callback then cfg.Callback() end
                end)
            end

            -- ── TextInput ─────────────────────────────────────────
            function sec:AddInput(cfg)
                cfg       = cfg or {}
                local row = Row(50)
                New("TextLabel", {
                    Size             = UDim2.new(0.45,0,0,16),
                    Position         = UDim2.new(0,12,0,9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Input",
                    TextColor3       = T.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })
                local box = New("TextBox", {
                    Size             = UDim2.fromOffset(130,22),
                    Position         = UDim2.new(1,-142,0.5,-11),
                    BackgroundColor3 = T.WindowBG,
                    BorderSizePixel  = 0,
                    Text             = cfg.Default or "",
                    PlaceholderText  = cfg.Placeholder or "...",
                    PlaceholderColor3 = T.TextMuted,
                    TextColor3       = T.TextSecondary,
                    TextSize         = 10,
                    Font             = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    Parent           = row,
                }, {
                    Corner(5),
                    Stroke(T.DividerColor, 1),
                    Padding(0,0,7,0),
                })
                box.FocusLost:Connect(function(enter)
                    if cfg.Callback then cfg.Callback(box.Text, enter) end
                end)
                local obj = {}
                function obj:Set(v) box.Text = v end
                function obj:Get() return box.Text end
                return obj
            end

            return sec
        end -- AddSection

        return tab
    end -- AddTab

    -- Bottom static icons (folder + settings)
    local function AddStaticIcon(icon)
        New("TextButton", {
            Size             = UDim2.fromOffset(36, 36),
            BackgroundTransparency = 1,
            Text             = Icons[icon] or icon,
            TextColor3       = T.IconDefault,
            TextSize         = 14,
            Font             = Enum.Font.Gotham,
            BorderSizePixel  = 0,
            Parent           = BotIcons,
        }, { Corner(9) })
    end
    AddStaticIcon("folder")
    AddStaticIcon("settings")

    function self:Destroy() GUI:Destroy() end
    function self:Toggle() Win.Visible = not Win.Visible end

    return self
end

return UILib
