local UILib = {}
UILib.__index = UILib

-- ─── Services ───────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer:GetMouse()

-- ─── Utility ────────────────────────────────────────────────────────────────
local function Tween(obj, props, duration, style, direction)
    style     = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.2, style, direction), props):Play()
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ─── Theme ──────────────────────────────────────────────────────────────────
local Theme = {
    Background      = Color3.fromRGB(24, 24, 24),
    TopBar          = Color3.fromRGB(17, 17, 17),
    Sidebar         = Color3.fromRGB(17, 17, 17),
    Panel           = Color3.fromRGB(24, 24, 24),
    Row             = Color3.fromRGB(20, 20, 20),
    Border          = Color3.fromRGB(30, 30, 30),
    Accent          = Color3.fromRGB(192, 57, 43),
    AccentDim       = Color3.fromRGB(100, 30, 22),
    TextPrimary     = Color3.fromRGB(210, 210, 210),
    TextSecondary   = Color3.fromRGB(120, 120, 120),
    TextMuted       = Color3.fromRGB(55,  55,  55),
    ToggleOff       = Color3.fromRGB(50,  50,  50),
    ToggleOn        = Color3.fromRGB(192, 57, 43),
    SliderFill      = Color3.fromRGB(192, 57, 43),
    SliderTrack     = Color3.fromRGB(38,  38,  38),
    DropdownBg      = Color3.fromRGB(20,  20,  20),
    Overlay         = Color3.fromRGB(14,  14,  14),
}

-- ─── Window ─────────────────────────────────────────────────────────────────
function UILib.CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, UILib)
    self.Tabs       = {}
    self.ActiveTab  = nil
    self.AccentColor = config.AccentColor or Theme.Accent

    -- Root ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name            = "UILib",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        Parent          = CoreGui,
    })

    -- Window frame
    local Window = Create("Frame", {
        Name            = "Window",
        Size            = UDim2.new(0, 620, 0, 420),
        Position        = UDim2.new(0.5, -310, 0.5, -210),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent          = ScreenGui,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
        Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })

    -- ── TopBar ──────────────────────────────────────────────────────────────
    local TopBar = Create("Frame", {
        Name             = "TopBar",
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.TopBar,
        BorderSizePixel  = 0,
        Parent           = Window,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
        -- Bottom-fill to square off the bottom edge
        Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 14),
            Position         = UDim2.new(0, 0, 1, -14),
            BackgroundColor3 = Theme.TopBar,
            BorderSizePixel  = 0,
        }),
    })

    -- Divider below topbar
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = Window,
    })

    -- Logo box
    local LogoBox = Create("Frame", {
        Size             = UDim2.new(0, 28, 0, 28),
        Position         = UDim2.new(0, 12, 0.5, -14),
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel  = 0,
        Parent           = TopBar,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 7) }),
        Create("TextLabel", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text             = config.LogoText or "R",
            TextColor3       = Color3.new(1, 1, 1),
            TextSize         = 14,
            Font             = Enum.Font.GothamBold,
        }),
    })

    -- Title
    Create("TextLabel", {
        Size             = UDim2.new(0, 200, 0, 16),
        Position         = UDim2.new(0, 48, 0.5, -18),
        BackgroundTransparency = 1,
        Text             = config.Title or "Brand name",
        TextColor3       = Theme.TextPrimary,
        TextSize         = 12,
        Font             = Enum.Font.GothamSemibold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = TopBar,
    })

    -- Slogan
    Create("TextLabel", {
        Size             = UDim2.new(0, 200, 0, 14),
        Position         = UDim2.new(0, 48, 0.5, 2),
        BackgroundTransparency = 1,
        Text             = config.Slogan or "The slogan, if there is one.",
        TextColor3       = Theme.TextMuted,
        TextSize         = 10,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = TopBar,
    })

    MakeDraggable(Window, TopBar)

    -- ── Sidebar ─────────────────────────────────────────────────────────────
    local Sidebar = Create("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 46, 1, -48),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Parent           = Window,
    }, {
        -- Bottom-left corner rounding
        Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
        -- Top-fill to square off top
        Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 14),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel  = 0,
        }),
        -- Right-fill to square off right edge
        Create("Frame", {
            Size             = UDim2.new(0, 14, 1, 0),
            Position         = UDim2.new(1, -14, 0, 0),
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel  = 0,
        }),
    })

    -- Sidebar divider
    Create("Frame", {
        Size             = UDim2.new(0, 1, 1, -48),
        Position         = UDim2.new(0, 46, 0, 48),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = Window,
    })

    local SidebarList = Create("Frame", {
        Name             = "List",
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent           = Sidebar,
    }, {
        Create("UIListLayout", {
            FillDirection       = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment   = Enum.VerticalAlignment.Top,
            Padding             = UDim.new(0, 3),
        }),
        Create("UIPadding", { PaddingTop = UDim.new(0, 10) }),
    })

    -- ── Content Area ────────────────────────────────────────────────────────
    local ContentArea = Create("Frame", {
        Name             = "Content",
        Size             = UDim2.new(1, -46, 1, -48),
        Position         = UDim2.new(0, 46, 0, 48),
        BackgroundTransparency = 1,
        Parent           = Window,
    })

    -- ── Tab System ──────────────────────────────────────────────────────────
    self._screen      = ScreenGui
    self._window      = Window
    self._sidebarList = SidebarList
    self._contentArea = ContentArea

    function self:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tab = {}
        tab.Name     = tabConfig.Name or "Tab"
        tab.Sections = {}

        -- Sidebar button
        local btn = Create("TextButton", {
            Name             = "TabBtn_" .. tab.Name,
            Size             = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = Theme.Sidebar,
            BackgroundTransparency = 1,
            Text             = "",
            BorderSizePixel  = 0,
            Parent           = SidebarList,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        })

        -- Accent bar (hidden by default)
        local accentBar = Create("Frame", {
            Size             = UDim2.new(0, 3, 0, 16),
            Position         = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = self.AccentColor,
            BorderSizePixel  = 0,
            Parent           = btn,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
        })
        accentBar.Visible = false

        -- Icon label (use text icon or unicode)
        Create("TextLabel", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text             = tabConfig.Icon or "○",
            TextColor3       = Theme.TextMuted,
            TextSize         = 14,
            Font             = Enum.Font.Gotham,
            Parent           = btn,
        })

        -- Content frame for this tab
        local contentFrame = Create("Frame", {
            Name             = "Tab_" .. tab.Name,
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible          = false,
            Parent           = ContentArea,
        })

        tab._btn          = btn
        tab._accentBar    = accentBar
        tab._frame        = contentFrame
        tab._lib          = self

        -- Activate tab
        function tab:Activate()
            if self._lib.ActiveTab then
                self._lib.ActiveTab._btn.BackgroundTransparency = 1
                self._lib.ActiveTab._accentBar.Visible = false
                self._lib.ActiveTab._frame.Visible = false
            end
            self._lib.ActiveTab = self
            btn.BackgroundTransparency = 0
            btn.BackgroundColor3 = Theme.Row
            accentBar.Visible = true
            contentFrame.Visible = true
        end

        btn.MouseButton1Click:Connect(function() tab:Activate() end)

        -- ── Split Panel Layout ───────────────────────────────────────────────
        -- Left panel
        local leftPanel = Create("Frame", {
            Name             = "LeftPanel",
            Size             = UDim2.new(0.5, -1, 1, 0),
            BackgroundTransparency = 1,
            Parent           = contentFrame,
        })

        -- Panel divider
        Create("Frame", {
            Size             = UDim2.new(0, 1, 1, 0),
            Position         = UDim2.new(0.5, -1, 0, 0),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
            Parent           = contentFrame,
        })

        -- Right panel
        local rightPanel = Create("Frame", {
            Name             = "RightPanel",
            Size             = UDim2.new(0.5, -1, 1, 0),
            Position         = UDim2.new(0.5, 1, 0, 0),
            BackgroundTransparency = 1,
            Parent           = contentFrame,
        })

        tab._leftPanel  = leftPanel
        tab._rightPanel = rightPanel

        -- Helper: create a section inside a panel
        local function makeSection(parent, sectionName)
            local section = {}

            -- Scrollable list
            local scroll = Create("ScrollingFrame", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.AccentDim,
                CanvasSize       = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent           = parent,
            }, {
                Create("UIPadding", { PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), PaddingTop = UDim.new(0,12) }),
                Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding       = UDim.new(0, 5),
                    SortOrder     = Enum.SortOrder.LayoutOrder,
                }),
            })

            -- Section title
            Create("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text             = sectionName,
                TextColor3       = Theme.TextMuted,
                TextSize         = 10,
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                LayoutOrder      = 0,
                Parent           = scroll,
            })

            section._scroll = scroll

            -- ── Toggle ──────────────────────────────────────────────────────
            function section:CreateToggle(cfg)
                cfg = cfg or {}
                local state = cfg.Default or false

                local row = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel  = 0,
                    LayoutOrder      = #scroll:GetChildren(),
                    Parent           = scroll,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                })

                -- Label
                Create("TextLabel", {
                    Size             = UDim2.new(1, -60, 0, 16),
                    Position         = UDim2.new(0, 12, 0, 9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Toggle",
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                -- Description
                Create("TextLabel", {
                    Size             = UDim2.new(1, -60, 0, 14),
                    Position         = UDim2.new(0, 12, 0, 27),
                    BackgroundTransparency = 1,
                    Text             = cfg.Description or "",
                    TextColor3       = Theme.TextMuted,
                    TextSize         = 9,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextTruncate     = Enum.TextTruncate.AtEnd,
                    Parent           = row,
                })

                -- Dots menu
                local dotsBtn = Create("TextButton", {
                    Size             = UDim2.new(0, 20, 0, 20),
                    Position         = UDim2.new(1, -52, 0.5, -10),
                    BackgroundTransparency = 1,
                    Text             = "···",
                    TextColor3       = Theme.TextMuted,
                    TextSize         = 12,
                    Font             = Enum.Font.GothamBold,
                    Parent           = row,
                })

                -- Toggle track
                local track = Create("Frame", {
                    Size             = UDim2.new(0, 26, 0, 14),
                    Position         = UDim2.new(1, -30, 0.5, -7),
                    BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                    BorderSizePixel  = 0,
                    Parent           = row,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })

                -- Toggle knob
                local knob = Create("Frame", {
                    Size             = UDim2.new(0, 10, 0, 10),
                    Position         = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel  = 0,
                    Parent           = track,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                })

                local clickBtn = Create("TextButton", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 5,
                    Parent           = row,
                })

                clickBtn.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(track, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.15)
                    Tween(knob,  { Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5) }, 0.15)
                    if cfg.Callback then cfg.Callback(state) end
                end)

                return { SetState = function(v)
                    state = v
                    Tween(track, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.15)
                    Tween(knob,  { Position = state and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5) }, 0.15)
                end }
            end

            -- ── Slider ──────────────────────────────────────────────────────
            function section:CreateSlider(cfg)
                cfg = cfg or {}
                local min   = cfg.Min or 0
                local max   = cfg.Max or 100
                local value = cfg.Default or min

                local row = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel  = 0,
                    LayoutOrder      = #scroll:GetChildren(),
                    Parent           = scroll,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                })

                Create("TextLabel", {
                    Size             = UDim2.new(0.5, 0, 0, 16),
                    Position         = UDim2.new(0, 12, 0, 9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Slider",
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                -- Range label
                local rangeLabel = Create("TextLabel", {
                    Size             = UDim2.new(0, 100, 0, 14),
                    Position         = UDim2.new(1, -112, 0, 9),
                    BackgroundTransparency = 1,
                    Text             = string.format("(%d, %d)", min, max),
                    TextColor3       = Theme.TextMuted,
                    TextSize         = 9,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Parent           = row,
                })

                -- Track bg
                local trackBg = Create("Frame", {
                    Size             = UDim2.new(1, -24, 0, 6),
                    Position         = UDim2.new(0, 12, 0.5, 6),
                    BackgroundColor3 = Theme.SliderTrack,
                    BorderSizePixel  = 0,
                    Parent           = row,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                })

                -- Fill
                local pct = (value - min) / (max - min)
                local fill = Create("Frame", {
                    Size             = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = Theme.SliderFill,
                    BorderSizePixel  = 0,
                    Parent           = trackBg,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
                })

                -- Drag
                local dragging = false
                local dragBtn = Create("TextButton", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 5,
                    Parent           = trackBg,
                })

                local function updateSlider(inputX)
                    local abs     = trackBg.AbsolutePosition.X
                    local width   = trackBg.AbsoluteSize.X
                    local rel     = math.clamp((inputX - abs) / width, 0, 1)
                    value         = math.floor(min + rel * (max - min) + 0.5)
                    fill.Size     = UDim2.new(rel, 0, 1, 0)
                    rangeLabel.Text = string.format("(%d, %d)", value, max)
                    if cfg.Callback then cfg.Callback(value) end
                end

                dragBtn.MouseButton1Down:Connect(function() dragging = true end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(i.Position.X)
                    end
                end)

                return { SetValue = function(v)
                    value = v
                    local r = (v - min) / (max - min)
                    fill.Size = UDim2.new(math.clamp(r,0,1), 0, 1, 0)
                end }
            end

            -- ── Dropdown ────────────────────────────────────────────────────
            function section:CreateDropdown(cfg)
                cfg = cfg or {}
                local options  = cfg.Options or {}
                local selected = cfg.Default or (options[1] or "")
                local open     = false

                local row = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel  = 0,
                    LayoutOrder      = #scroll:GetChildren(),
                    ClipsDescendants = true,
                    Parent           = scroll,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                })

                Create("TextLabel", {
                    Size             = UDim2.new(0.6, 0, 0, 16),
                    Position         = UDim2.new(0, 12, 0, 9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Dropdown",
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local valueLabel = Create("TextLabel", {
                    Size             = UDim2.new(0, 120, 0, 14),
                    Position         = UDim2.new(1, -130, 0, 10),
                    BackgroundTransparency = 1,
                    Text             = selected,
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 10,
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Right,
                    Parent           = row,
                })

                -- Arrow
                local arrow = Create("TextLabel", {
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(1, -16, 0, 10),
                    BackgroundTransparency = 1,
                    Text             = "▾",
                    TextColor3       = Theme.TextMuted,
                    TextSize         = 10,
                    Font             = Enum.Font.GothamBold,
                    Parent           = row,
                })

                -- Options list (inside row, revealed by resizing)
                local optList = Create("Frame", {
                    Size             = UDim2.new(1, -24, 0, #options * 24),
                    Position         = UDim2.new(0, 12, 0, 50),
                    BackgroundTransparency = 1,
                    Parent           = row,
                }, {
                    Create("UIListLayout", { Padding = UDim.new(0, 2) }),
                })

                for _, opt in ipairs(options) do
                    local optBtn = Create("TextButton", {
                        Size             = UDim2.new(1, 0, 0, 22),
                        BackgroundColor3 = Theme.DropdownBg,
                        BorderSizePixel  = 0,
                        Text             = opt,
                        TextColor3       = Theme.TextSecondary,
                        TextSize         = 10,
                        Font             = Enum.Font.Gotham,
                        Parent           = optList,
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    })
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        valueLabel.Text = opt
                        open = false
                        Tween(row, { Size = UDim2.new(1, 0, 0, 50) }, 0.2)
                        if cfg.Callback then cfg.Callback(selected) end
                    end)
                end

                local clickBtn = Create("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundTransparency = 1,
                    Text             = "",
                    ZIndex           = 5,
                    Parent           = row,
                })

                clickBtn.MouseButton1Click:Connect(function()
                    open = not open
                    Tween(row, { Size = UDim2.new(1, 0, 0, open and 50 + #options * 26 or 50) }, 0.2)
                    arrow.Text = open and "▴" or "▾"
                end)

                return { SetSelected = function(v)
                    selected = v
                    valueLabel.Text = v
                end }
            end

            -- ── Button ──────────────────────────────────────────────────────
            function section:CreateButton(cfg)
                cfg = cfg or {}

                local row = Create("TextButton", {
                    Size             = UDim2.new(1, 0, 0, 42),
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel  = 0,
                    Text             = "",
                    LayoutOrder      = #scroll:GetChildren(),
                    Parent           = scroll,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                })

                Create("TextLabel", {
                    Size             = UDim2.new(1, -40, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Button",
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                Create("TextLabel", {
                    Size             = UDim2.new(0, 20, 0, 14),
                    Position         = UDim2.new(1, -24, 0.5, -7),
                    BackgroundTransparency = 1,
                    Text             = "›",
                    TextColor3       = Theme.TextMuted,
                    TextSize         = 16,
                    Font             = Enum.Font.GothamBold,
                    Parent           = row,
                })

                row.MouseButton1Click:Connect(function()
                    Tween(row, { BackgroundColor3 = Theme.AccentDim }, 0.1)
                    task.delay(0.15, function()
                        Tween(row, { BackgroundColor3 = Theme.Row }, 0.15)
                    end)
                    if cfg.Callback then cfg.Callback() end
                end)
            end

            -- ── TextInput ───────────────────────────────────────────────────
            function section:CreateInput(cfg)
                cfg = cfg or {}

                local row = Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Theme.Row,
                    BorderSizePixel  = 0,
                    LayoutOrder      = #scroll:GetChildren(),
                    Parent           = scroll,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                })

                Create("TextLabel", {
                    Size             = UDim2.new(0.45, 0, 0, 16),
                    Position         = UDim2.new(0, 12, 0, 9),
                    BackgroundTransparency = 1,
                    Text             = cfg.Name or "Input",
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 11,
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    Parent           = row,
                })

                local box = Create("TextBox", {
                    Size             = UDim2.new(0, 130, 0, 22),
                    Position         = UDim2.new(1, -142, 0.5, -11),
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel  = 0,
                    Text             = cfg.Default or "",
                    PlaceholderText  = cfg.Placeholder or "Enter value...",
                    PlaceholderColor3 = Theme.TextMuted,
                    TextColor3       = Theme.TextSecondary,
                    TextSize         = 10,
                    Font             = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    Parent           = row,
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 7) }),
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1 }),
                })

                box.FocusLost:Connect(function(enter)
                    if cfg.Callback then cfg.Callback(box.Text, enter) end
                end)

                return { SetText = function(v) box.Text = v end }
            end

            return section
        end

        -- Public: create section in left or right panel
        function tab:CreateSection(name, side)
            side = side or "left"
            local parent = side == "right" and self._rightPanel or self._leftPanel
            return makeSection(parent, name)
        end

        -- Auto-activate first tab
        if #self.Tabs == 0 then
            task.defer(function() tab:Activate() end)
        end

        table.insert(self.Tabs, tab)
        return tab
    end

    -- Toggle visibility
    function self:Toggle()
        Window.Visible = not Window.Visible
    end

    function self:Destroy()
        ScreenGui:Destroy()
    end

    return self
end

return UILib
