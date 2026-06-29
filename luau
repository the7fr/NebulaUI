--[[
    NebulaHub UI Library
    A clean, modern UI library for Roblox Luau scripts.

    Usage:
        local NebulaHub = loadstring(game:HttpGet("..."))()
        local Window = NebulaHub:CreateWindow()
        local Tab = Window:CreateTab("Main")
        Tab:AddButton({ Text = "Click me", Callback = function() end })
]]

local NebulaHub = {}
NebulaHub.__index = NebulaHub

-- ─── Services ────────────────────────────────────────────────────────────────
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function Tween(obj, props, duration, style, direction)
    style     = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.18, style, direction), props):Play()
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
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

-- ─── Theme ───────────────────────────────────────────────────────────────────
local Theme = {
    BG          = Color3.fromRGB(13,  13,  17),
    Surface     = Color3.fromRGB(22,  22,  28),
    Surface2    = Color3.fromRGB(30,  30,  38),
    Surface3    = Color3.fromRGB(40,  40,  52),
    Border      = Color3.fromRGB(46,  46,  58),
    Border2     = Color3.fromRGB(62,  62,  78),
    Accent      = Color3.fromRGB(124, 111, 255),
    AccentHover = Color3.fromRGB(165, 148, 255),
    Text        = Color3.fromRGB(232, 232, 240),
    TextMuted   = Color3.fromRGB(145, 145, 168),
    TextDim     = Color3.fromRGB(90,  90,  114),
    Green       = Color3.fromRGB(62,  207, 142),
    Red         = Color3.fromRGB(240, 107, 107),
    Amber       = Color3.fromRGB(245, 166,  35),
    Blue        = Color3.fromRGB(77,  166, 255),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    FontMono    = Enum.Font.Code,
}

-- Resolve Enum.Font safely (Gotham may not exist in all executors)
local ok = pcall(function() return Enum.Font.GothamMedium end)
if not ok then
    Theme.Font     = Enum.Font.SourceSans
    Theme.FontBold = Enum.Font.SourceSansBold
end

-- ─── Window ──────────────────────────────────────────────────────────────────
function NebulaHub:CreateWindow(config)
    config = config or {}
    local Title    = config.Title    or "Nebula Hub"
    local Size     = config.Size     or UDim2.new(0, 560, 0, 440)
    local Position = config.Position or UDim2.new(0.5, -280, 0.5, -220)

    -- Game name
    local gameName = "Unknown Game"
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        gameName = info and info.Name or gameName
    end)
    if gameName == "Unknown Game" then
        pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    end

    -- Player info
    local username  = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local userId    = LocalPlayer.UserId
    local thumbUrl  = string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png",
        userId
    )

    -- ── ScreenGui ──
    local ScreenGui = Create("ScreenGui", {
        Name            = "NebulaHub",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- ── Main frame ──
    local Main = Create("Frame", {
        Name            = "Main",
        Size            = Size,
        Position        = Position,
        BackgroundColor3 = Theme.BG,
        BorderSizePixel = 0,
        Parent          = ScreenGui,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 12) }, {}):Parent = Main
    Create("UIStroke", {
        Color     = Theme.Border,
        Thickness = 1,
    }):Parent = Main

    -- Drop shadow effect (frame behind)
    local Shadow = Create("Frame", {
        Name             = "Shadow",
        Size             = UDim2.new(1, 24, 1, 24),
        Position         = UDim2.new(0, -12, 0, -12),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.65,
        BorderSizePixel  = 0,
        ZIndex           = Main.ZIndex - 1,
        Parent           = Main,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 18) }):Parent = Shadow

    -- ── Sidebar ──
    local Sidebar = Create("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = Main,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 12) }):Parent = Sidebar

    -- Clip the right corners of sidebar
    local SidebarClip = Create("Frame", {
        Size             = UDim2.new(0, 12, 1, 0),
        Position         = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })

    local SidebarStroke = Create("UIStroke", {
        Color     = Theme.Border,
        Thickness = 1,
    })
    SidebarStroke.Parent = Sidebar

    -- ── Logo / title section ──
    local LogoSection = Create("Frame", {
        Name             = "LogoSection",
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundTransparency = 1,
        Parent           = Sidebar,
    })

    -- Accent dot
    local LogoDot = Create("Frame", {
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(0, 14, 0, 16),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = LogoSection,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }):Parent = LogoDot

    -- Inner grid icon on dot
    for r = 0, 1 do
        for c = 0, 1 do
            Create("Frame", {
                Size             = UDim2.new(0, 6, 0, 6),
                Position         = UDim2.new(0, 4 + c * 9, 0, 4 + r * 9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.2,
                BorderSizePixel  = 0,
                Parent           = LogoDot,
            })
        end
    end

    local TitleLabel = Create("TextLabel", {
        Text             = Title,
        Size             = UDim2.new(1, -44, 0, 16),
        Position         = UDim2.new(0, 42, 0, 14),
        BackgroundTransparency = 1,
        TextColor3       = Theme.Text,
        Font             = Theme.FontBold or Theme.Font,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = LogoSection,
    })

    local GameLabel = Create("TextLabel", {
        Text             = gameName,
        Size             = UDim2.new(1, -44, 0, 13),
        Position         = UDim2.new(0, 42, 0, 32),
        BackgroundTransparency = 1,
        TextColor3       = Theme.TextDim,
        Font             = Theme.Font,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        Parent           = LogoSection,
    })

    -- Divider below title
    Create("Frame", {
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 0, 68),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })

    -- ── Tab buttons container ──
    local TabContainer = Create("ScrollingFrame", {
        Name             = "TabContainer",
        Size             = UDim2.new(1, 0, 1, -160),
        Position         = UDim2.new(0, 0, 0, 76),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 0,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent           = Sidebar,
    })
    local TabListLayout = Create("UIListLayout", {
        Padding          = UDim.new(0, 2),
        FillDirection    = Enum.FillDirection.Vertical,
        SortOrder        = Enum.SortOrder.LayoutOrder,
    })
    TabListLayout.Parent = TabContainer
    Create("UIPadding", {
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
        PaddingTop    = UDim.new(0, 4),
    }):Parent = TabContainer

    -- ── User card (bottom of sidebar) ──
    local UserCard = Create("Frame", {
        Name             = "UserCard",
        Size             = UDim2.new(1, 0, 0, 56),
        Position         = UDim2.new(0, 0, 1, -56),
        BackgroundTransparency = 1,
        Parent           = Sidebar,
    })

    -- Divider above user card
    Create("Frame", {
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = UserCard,
    })

    -- Avatar image
    local Avatar = Create("ImageLabel", {
        Size             = UDim2.new(0, 30, 0, 30),
        Position         = UDim2.new(0, 12, 0, 13),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel  = 0,
        Image            = thumbUrl,
        Parent           = UserCard,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }):Parent = Avatar
    Create("UIStroke", { Color = Theme.Border2, Thickness = 1.5 }):Parent = Avatar

    -- Username
    Create("TextLabel", {
        Text             = displayName,
        Size             = UDim2.new(1, -52, 0, 14),
        Position         = UDim2.new(0, 48, 0, 14),
        BackgroundTransparency = 1,
        TextColor3       = Theme.Text,
        Font             = Theme.Font,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        Parent           = UserCard,
    })
    Create("TextLabel", {
        Text             = "@" .. username,
        Size             = UDim2.new(1, -52, 0, 12),
        Position         = UDim2.new(0, 48, 0, 30),
        BackgroundTransparency = 1,
        TextColor3       = Theme.TextDim,
        Font             = Theme.Font,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = UserCard,
    })

    -- ── Content area ──
    local ContentArea = Create("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -168, 1, -16),
        Position         = UDim2.new(0, 168, 0, 8),
        BackgroundTransparency = 1,
        Parent           = Main,
    })

    -- ── Close button ──
    local CloseBtn = Create("TextButton", {
        Text             = "×",
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(1, -30, 0, 8),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel  = 0,
        TextColor3       = Theme.TextMuted,
        Font             = Theme.Font,
        TextSize         = 16,
        ZIndex           = 10,
        Parent           = Main,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }):Parent = CloseBtn
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, { Size = UDim2.new(0, Size.X.Offset, 0, 0) }, 0.22)
        task.wait(0.23)
        ScreenGui:Destroy()
    end)
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { BackgroundColor3 = Theme.Red }, 0.12)
        Tween(CloseBtn, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { BackgroundColor3 = Theme.Surface2 }, 0.12)
        Tween(CloseBtn, { TextColor3 = Theme.TextMuted }, 0.12)
    end)

    -- Minimise button
    local MinBtn = Create("TextButton", {
        Text             = "−",
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(1, -56, 0, 8),
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel  = 0,
        TextColor3       = Theme.TextMuted,
        Font             = Theme.Font,
        TextSize         = 16,
        ZIndex           = 10,
        Parent           = Main,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6) }):Parent = MinBtn
    local minimised = false
    MinBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        if minimised then
            Tween(Main, { Size = UDim2.new(0, Size.X.Offset, 0, 38) }, 0.22)
        else
            Tween(Main, { Size = Size }, 0.22)
        end
    end)
    MinBtn.MouseEnter:Connect(function()
        Tween(MinBtn, { BackgroundColor3 = Theme.Amber }, 0.12)
        Tween(MinBtn, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
    end)
    MinBtn.MouseLeave:Connect(function()
        Tween(MinBtn, { BackgroundColor3 = Theme.Surface2 }, 0.12)
        Tween(MinBtn, { TextColor3 = Theme.TextMuted }, 0.12)
    end)

    -- Make draggable from the sidebar header
    MakeDraggable(Main, LogoSection)

    -- Entrance animation
    Main.Size = UDim2.new(0, Size.X.Offset, 0, 0)
    Main.BackgroundTransparency = 1
    Tween(Main, { Size = Size, BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Back)

    -- ── Window object ──
    local Window = { _tabs = {}, _activeTab = nil }

    function Window:CreateTab(name, icon)
        local isFirst = #self._tabs == 0

        -- Tab button
        local TabBtn = Create("TextButton", {
            Text             = "",
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = isFirst and Theme.Surface3 or Color3.fromRGB(0,0,0),
            BackgroundTransparency = isFirst and 0 or 1,
            BorderSizePixel  = 0,
            AutoButtonColor  = false,
            LayoutOrder      = #self._tabs + 1,
            Parent           = TabContainer,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }):Parent = TabBtn

        -- Accent bar (visible when active)
        local AccentBar = Create("Frame", {
            Size             = UDim2.new(0, 2, 0, 16),
            Position         = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            BackgroundTransparency = isFirst and 0 or 1,
            Parent           = TabBtn,
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 2) }):Parent = AccentBar

        -- Tab label
        local TabLabel = Create("TextLabel", {
            Text             = name,
            Size             = UDim2.new(1, -16, 1, 0),
            Position         = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            TextColor3       = isFirst and Theme.Text or Theme.TextDim,
            Font             = Theme.Font,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = TabBtn,
        })

        -- Content page
        local Page = Create("ScrollingFrame", {
            Name             = name .. "Page",
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Border2,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = isFirst,
            Parent           = ContentArea,
        })
        Create("UIListLayout", {
            Padding      = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder    = Enum.SortOrder.LayoutOrder,
        }):Parent = Page
        Create("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
        }):Parent = Page

        local tabData = { Button = TabBtn, Page = Page, Label = TabLabel, Bar = AccentBar }
        table.insert(self._tabs, tabData)
        if isFirst then self._activeTab = tabData end

        TabBtn.MouseButton1Click:Connect(function()
            if self._activeTab == tabData then return end
            -- Deactivate old
            if self._activeTab then
                self._activeTab.Page.Visible = false
                Tween(self._activeTab.Button, { BackgroundTransparency = 1 }, 0.12)
                Tween(self._activeTab.Label, { TextColor3 = Theme.TextDim }, 0.12)
                Tween(self._activeTab.Bar, { BackgroundTransparency = 1 }, 0.12)
            end
            -- Activate new
            Page.Visible = true
            Tween(TabBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Surface3 }, 0.12)
            Tween(TabLabel, { TextColor3 = Theme.Text }, 0.12)
            Tween(AccentBar, { BackgroundTransparency = 0 }, 0.12)
            self._activeTab = tabData
        end)

        TabBtn.MouseEnter:Connect(function()
            if self._activeTab ~= tabData then
                Tween(TabBtn, { BackgroundTransparency = 0.6, BackgroundColor3 = Theme.Surface3 }, 0.1)
                Tween(TabLabel, { TextColor3 = Theme.TextMuted }, 0.1)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self._activeTab ~= tabData then
                Tween(TabBtn, { BackgroundTransparency = 1 }, 0.1)
                Tween(TabLabel, { TextColor3 = Theme.TextDim }, 0.1)
            end
        end)

        -- ── Tab component API ──────────────────────────────────────────────
        local Tab = { _order = 0 }

        local function NextOrder()
            Tab._order += 1
            return Tab._order
        end

        -- Section label
        function Tab:AddSection(text)
            local Section = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            Create("TextLabel", {
                Text             = string.upper(text),
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.TextDim,
                Font             = Theme.Font,
                TextSize         = 9,
                TextXAlignment   = Enum.TextXAlignment.Left,
                LetterSpacing    = 2,
                Parent           = Section,
            })
            Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel  = 0,
                Parent           = Section,
            })
        end

        -- Button
        function Tab:AddButton(config)
            config = config or {}
            local Btn = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }):Parent = Btn
            Create("UIStroke", { Color = Theme.Border, Thickness = 1 }):Parent = Btn

            Create("TextLabel", {
                Text             = config.Text or "Button",
                Size             = UDim2.new(1, -16, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Text,
                Font             = Theme.Font,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = Btn,
            })

            Btn.MouseEnter:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface2 }, 0.1)
            end)
            Btn.MouseLeave:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface }, 0.1)
            end)
            Btn.MouseButton1Down:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface3 }, 0.07)
            end)
            Btn.MouseButton1Click:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface }, 0.12)
                if config.Callback then
                    pcall(config.Callback)
                end
            end)

            return Btn
        end

        -- Toggle
        function Tab:AddToggle(config)
            config = config or {}
            local state = config.Default or false

            local Row = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }):Parent = Row
            Create("UIStroke", { Color = Theme.Border, Thickness = 1 }):Parent = Row

            Create("TextLabel", {
                Text             = config.Label or "Toggle",
                Size             = UDim2.new(1, -60, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Text,
                Font             = Theme.Font,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = Row,
            })

            local Track = Create("Frame", {
                Size             = UDim2.new(0, 34, 0, 18),
                Position         = UDim2.new(1, -48, 0.5, -9),
                BackgroundColor3 = state and Theme.Accent or Theme.Surface3,
                BorderSizePixel  = 0,
                Parent           = Row,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }):Parent = Track
            Create("UIStroke", { Color = Theme.Border2, Thickness = 1 }):Parent = Track

            local Knob = Create("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel  = 0,
                Parent           = Track,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }):Parent = Knob

            local function UpdateToggle()
                if state then
                    Tween(Track, { BackgroundColor3 = Theme.Accent }, 0.15)
                    Tween(Knob, { Position = UDim2.new(1, -15, 0.5, -6) }, 0.15)
                else
                    Tween(Track, { BackgroundColor3 = Theme.Surface3 }, 0.15)
                    Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -6) }, 0.15)
                end
                if config.Callback then
                    pcall(config.Callback, state)
                end
            end

            local ClickRegion = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Parent           = Row,
            })
            ClickRegion.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
            end)

            return {
                SetState = function(_, s)
                    state = s
                    UpdateToggle()
                end,
                GetState = function() return state end,
            }
        end

        -- Slider
        function Tab:AddSlider(config)
            config = config or {}
            local min     = config.Min     or 0
            local max     = config.Max     or 100
            local default = config.Default or min
            local current = default

            local Container = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }):Parent = Container
            Create("UIStroke", { Color = Theme.Border, Thickness = 1 }):Parent = Container

            local TopRow = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent           = Container,
            })
            Create("TextLabel", {
                Text             = config.Label or "Slider",
                Size             = UDim2.new(0.7, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Text,
                Font             = Theme.Font,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = TopRow,
            })
            local ValueLabel = Create("TextLabel", {
                Text             = tostring(current),
                Size             = UDim2.new(0.3, -14, 1, 0),
                Position         = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Accent,
                Font             = Theme.FontMono or Theme.Font,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Right,
                Parent           = TopRow,
            })

            local Track = Create("Frame", {
                Size             = UDim2.new(1, -28, 0, 4),
                Position         = UDim2.new(0, 14, 0, 36),
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel  = 0,
                Parent           = Container,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }):Parent = Track

            local Fill = Create("Frame", {
                Size             = UDim2.new((current - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                Parent           = Track,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }):Parent = Fill

            local Knob = Create("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new((current - min) / (max - min), 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel  = 0,
                ZIndex           = 2,
                Parent           = Track,
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0) }):Parent = Knob

            local dragging = false
            Knob.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local trackPos   = Track.AbsolutePosition.X
                    local trackWidth = Track.AbsoluteSize.X
                    local rel        = math.clamp((i.Position.X - trackPos) / trackWidth, 0, 1)
                    current          = math.round(min + rel * (max - min))
                    ValueLabel.Text  = tostring(current)
                    Fill.Size        = UDim2.new(rel, 0, 1, 0)
                    Knob.Position    = UDim2.new(rel, 0, 0.5, 0)
                    if config.Callback then pcall(config.Callback, current) end
                end
            end)

            return {
                SetValue = function(_, v)
                    current = math.clamp(v, min, max)
                    local rel = (current - min) / (max - min)
                    ValueLabel.Text = tostring(current)
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    Knob.Position = UDim2.new(rel, 0, 0.5, 0)
                end,
                GetValue = function() return current end,
            }
        end

        -- Dropdown
        function Tab:AddDropdown(config)
            config = config or {}
            local options  = config.Options or {}
            local selected = config.Default or options[1] or ""
            local open     = false

            local Container = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                LayoutOrder      = NextOrder(),
                ClipsDescendants = false,
                Parent           = Page,
                ZIndex           = 5,
            })

            local Header = Create("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ZIndex           = 5,
                Parent           = Container,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }):Parent = Header
            Create("UIStroke", { Color = Theme.Border, Thickness = 1 }):Parent = Header

            Create("TextLabel", {
                Text             = config.Label or "Dropdown",
                Size             = UDim2.new(0.5, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.TextMuted,
                Font             = Theme.Font,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 5,
                Parent           = Header,
            })

            local SelectedLabel = Create("TextLabel", {
                Text             = selected,
                Size             = UDim2.new(0.5, -36, 1, 0),
                Position         = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Text,
                Font             = Theme.Font,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Right,
                ZIndex           = 5,
                Parent           = Header,
            })

            local Arrow = Create("TextLabel", {
                Text             = "›",
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                TextColor3       = Theme.TextDim,
                Font             = Theme.Font,
                TextSize         = 16,
                ZIndex           = 5,
                Parent           = Header,
            })

            local Dropdown = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 40),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 10,
                Parent           = Container,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }):Parent = Dropdown
            Create("UIStroke", { Color = Theme.Border2, Thickness = 1 }):Parent = Dropdown
            local DList = Create("UIListLayout", { Padding = UDim.new(0, 1) })
            DList.Parent = Dropdown
            Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }):Parent = Dropdown

            for _, opt in ipairs(options) do
                local OptBtn = Create("TextButton", {
                    Text             = opt,
                    Size             = UDim2.new(1, -8, 0, 28),
                    BackgroundColor3 = Theme.Surface2,
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    TextColor3       = Theme.TextMuted,
                    Font             = Theme.Font,
                    TextSize         = 12,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 11,
                    Parent           = Dropdown,
                })
                Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }):Parent = OptBtn

                OptBtn.MouseEnter:Connect(function()
                    Tween(OptBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Surface3 }, 0.1)
                    Tween(OptBtn, { TextColor3 = Theme.Text }, 0.1)
                end)
                OptBtn.MouseLeave:Connect(function()
                    Tween(OptBtn, { BackgroundTransparency = 1 }, 0.1)
                    Tween(OptBtn, { TextColor3 = Theme.TextMuted }, 0.1)
                end)
                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelectedLabel.Text = opt
                    open = false
                    Tween(Dropdown, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    Tween(Arrow, { Rotation = 0 }, 0.15)
                    if config.Callback then pcall(config.Callback, opt) end
                end)
            end

            Header.MouseButton1Click:Connect(function()
                open = not open
                local targetH = open and math.min(#options * 29 + 8, 180) or 0
                Tween(Dropdown, { Size = UDim2.new(1, 0, 0, targetH) }, 0.18)
                Tween(Arrow, { Rotation = open and 90 or 0 }, 0.18)
                Container.Size = UDim2.new(1, 0, 0, open and 36 + targetH + 4 or 36)
            end)

            return {
                SetValue = function(_, v)
                    selected = v
                    SelectedLabel.Text = v
                end,
                GetValue = function() return selected end,
            }
        end

        -- TextInput
        function Tab:AddInput(config)
            config = config or {}

            local Container = Create("Frame", {
                Size             = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 8) }):Parent = Container
            Create("UIStroke", { Color = Theme.Border, Thickness = 1 }):Parent = Container

            Create("TextLabel", {
                Text             = config.Label or "Input",
                Size             = UDim2.new(1, -14, 0, 18),
                Position         = UDim2.new(0, 14, 0, 6),
                BackgroundTransparency = 1,
                TextColor3       = Theme.TextMuted,
                Font             = Theme.Font,
                TextSize         = 10,
                TextXAlignment   = Enum.TextXAlignment.Left,
                Parent           = Container,
            })

            local Box = Create("TextBox", {
                Text             = config.Default or "",
                PlaceholderText  = config.Placeholder or "",
                Size             = UDim2.new(1, -28, 0, 22),
                Position         = UDim2.new(0, 14, 0, 26),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Text,
                PlaceholderColor3 = Theme.TextDim,
                Font             = config.Mono and Theme.FontMono or Theme.Font,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent           = Container,
            })

            Box.Focused:Connect(function()
                Tween(Container, { BackgroundColor3 = Theme.Surface2 }, 0.12)
            end)
            Box.FocusLost:Connect(function(enter)
                Tween(Container, { BackgroundColor3 = Theme.Surface }, 0.12)
                if config.Callback then
                    pcall(config.Callback, Box.Text, enter)
                end
            end)

            return {
                GetValue = function() return Box.Text end,
                SetValue = function(_, v) Box.Text = v end,
            }
        end

        -- Label / info text
        function Tab:AddLabel(text, color)
            local L = Create("TextLabel", {
                Text             = text or "",
                Size             = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                TextColor3       = color or Theme.TextMuted,
                Font             = Theme.Font,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            return {
                SetText = function(_, t) L.Text = t end,
            }
        end

        -- Notify (toast)
        function Tab:Notify(config)
            config = config or {}
            local typeColor = ({
                info    = Theme.Blue,
                success = Theme.Green,
                warning = Theme.Amber,
                error   = Theme.Red,
            })[config.Type or "info"] or Theme.Blue

            local Toast = Create("Frame", {
                Size             = UDim2.new(0, 260, 0, 60),
                Position         = UDim2.new(1, 10, 1, -70),
                AnchorPoint      = Vector2.new(1, 1),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel  = 0,
                ZIndex           = 100,
                Parent           = ScreenGui,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 10) }):Parent = Toast
            Create("UIStroke", { Color = typeColor, Thickness = 1 }):Parent = Toast

            -- Accent left bar
            Create("Frame", {
                Size             = UDim2.new(0, 3, 1, -16),
                Position         = UDim2.new(0, 10, 0, 8),
                BackgroundColor3 = typeColor,
                BorderSizePixel  = 0,
                ZIndex           = 101,
                Parent           = Toast,
            })

            Create("TextLabel", {
                Text             = config.Title or "Notification",
                Size             = UDim2.new(1, -30, 0, 20),
                Position         = UDim2.new(0, 20, 0, 10),
                BackgroundTransparency = 1,
                TextColor3       = Theme.Text,
                Font             = Theme.FontBold or Theme.Font,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 101,
                Parent           = Toast,
            })
            Create("TextLabel", {
                Text             = config.Message or "",
                Size             = UDim2.new(1, -30, 0, 16),
                Position         = UDim2.new(0, 20, 0, 32),
                BackgroundTransparency = 1,
                TextColor3       = Theme.TextMuted,
                Font             = Theme.Font,
                TextSize         = 10,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextTruncate     = Enum.TextTruncate.AtEnd,
                ZIndex           = 101,
                Parent           = Toast,
            })

            Toast.Position = UDim2.new(1, 280, 1, -70)
            Tween(Toast, { Position = UDim2.new(1, -10, 1, -70) }, 0.25, Enum.EasingStyle.Back)

            task.delay(config.Duration or 3, function()
                Tween(Toast, { Position = UDim2.new(1, 280, 1, -70) }, 0.2)
                task.wait(0.22)
                Toast:Destroy()
            end)
        end

        return Tab
    end

    return Window
end

return NebulaHub
