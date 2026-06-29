--[[
    NebulaHub UI Library
    A clean, modern UI library for Roblox Luau scripts.

    Usage:
        local NebulaHub = loadstring(game:HttpGet("YOUR_URL"))()
        local Window = NebulaHub:CreateWindow({ Title = "Nebula Hub" })
        local Tab = Window:CreateTab("Main")
        Tab:AddButton({ Text = "Click me", Callback = function() end })
]]

local NebulaHub = {}
NebulaHub.__index = NebulaHub

-- Services
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

-- Helpers
local function Tween(obj, props, duration, style, direction)
    style     = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.18, style, direction), props):Play()
end

local function New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
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

-- Theme
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

local ok = pcall(function() return Enum.Font.GothamMedium end)
if not ok then
    Theme.Font     = Enum.Font.SourceSans
    Theme.FontBold = Enum.Font.SourceSansBold
    Theme.FontMono = Enum.Font.SourceSans
end

-- Window
function NebulaHub:CreateWindow(config)
    config = config or {}
    local Title    = config.Title    or "Nebula Hub"
    local WinSize  = config.Size     or UDim2.new(0, 560, 0, 440)
    local WinPos   = config.Position or UDim2.new(0.5, -280, 0.5, -220)

    -- Game name
    local gameName = "Unknown Game"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    -- Player info
    local username    = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local userId      = LocalPlayer.UserId
    local thumbUrl    = "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. tostring(userId) .. "&width=48&height=48&format=png"

    -- ScreenGui
    local ScreenGui = New("ScreenGui", {
        Name           = "NebulaHub",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    local ok2 = pcall(function() ScreenGui.Parent = CoreGui end)
    if not ok2 then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Main frame
    local Main = New("Frame", {
        Name             = "Main",
        Size             = WinSize,
        Position         = WinPos,
        BackgroundColor3 = Theme.BG,
        BorderSizePixel  = 0,
        Parent           = ScreenGui,
    })
    local mainCorner = New("UICorner", { CornerRadius = UDim.new(0, 12) })
    mainCorner.Parent = Main
    local mainStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
    mainStroke.Parent = Main

    -- Shadow
    local Shadow = New("Frame", {
        Name                   = "Shadow",
        Size                   = UDim2.new(1, 24, 1, 24),
        Position               = UDim2.new(0, -12, 0, -12),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.65,
        BorderSizePixel        = 0,
        ZIndex                 = Main.ZIndex - 1,
        Parent                 = Main,
    })
    local shadowCorner = New("UICorner", { CornerRadius = UDim.new(0, 18) })
    shadowCorner.Parent = Shadow

    -- Sidebar
    local Sidebar = New("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = Main,
    })
    local sideCorner = New("UICorner", { CornerRadius = UDim.new(0, 12) })
    sideCorner.Parent = Sidebar
    -- Clip right corners of sidebar
    local SideClip = New("Frame", {
        Size             = UDim2.new(0, 12, 1, 0),
        Position         = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })
    local sideStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
    sideStroke.Parent = Sidebar

    -- Logo section
    local LogoSection = New("Frame", {
        Name                   = "LogoSection",
        Size                   = UDim2.new(1, 0, 0, 72),
        BackgroundTransparency = 1,
        Parent                 = Sidebar,
    })

    local LogoDot = New("Frame", {
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(0, 14, 0, 16),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Parent           = LogoSection,
    })
    local dotCorner = New("UICorner", { CornerRadius = UDim.new(0, 6) })
    dotCorner.Parent = LogoDot

    -- Grid dots on logo
    for r = 0, 1 do
        for c = 0, 1 do
            local dot = New("Frame", {
                Size                   = UDim2.new(0, 6, 0, 6),
                Position               = UDim2.new(0, 4 + c * 9, 0, 4 + r * 9),
                BackgroundColor3       = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.2,
                BorderSizePixel        = 0,
                Parent                 = LogoDot,
            })
        end
    end

    local TitleLabel = New("TextLabel", {
        Text                   = Title,
        Size                   = UDim2.new(1, -44, 0, 16),
        Position               = UDim2.new(0, 42, 0, 14),
        BackgroundTransparency = 1,
        TextColor3             = Theme.Text,
        Font                   = Theme.FontBold,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = LogoSection,
    })

    local GameLabel = New("TextLabel", {
        Text                   = gameName,
        Size                   = UDim2.new(1, -44, 0, 13),
        Position               = UDim2.new(0, 42, 0, 32),
        BackgroundTransparency = 1,
        TextColor3             = Theme.TextDim,
        Font                   = Theme.Font,
        TextSize               = 10,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        Parent                 = LogoSection,
    })

    -- Divider below title
    local titleDivider = New("Frame", {
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 0, 68),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })

    -- Tab buttons container
    local TabContainer = New("ScrollingFrame", {
        Name               = "TabContainer",
        Size               = UDim2.new(1, 0, 1, -160),
        Position           = UDim2.new(0, 0, 0, 76),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ScrollBarThickness = 0,
        CanvasSize         = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent             = Sidebar,
    })
    local tabList = New("UIListLayout", {
        Padding       = UDim.new(0, 2),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder     = Enum.SortOrder.LayoutOrder,
    })
    tabList.Parent = TabContainer
    local tabPad = New("UIPadding", {
        PaddingLeft  = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop   = UDim.new(0, 4),
    })
    tabPad.Parent = TabContainer

    -- User card at bottom of sidebar
    local UserCard = New("Frame", {
        Name                   = "UserCard",
        Size                   = UDim2.new(1, 0, 0, 56),
        Position               = UDim2.new(0, 0, 1, -56),
        BackgroundTransparency = 1,
        Parent                 = Sidebar,
    })
    local userDivider = New("Frame", {
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 0, 0),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel  = 0,
        Parent           = UserCard,
    })
    local Avatar = New("ImageLabel", {
        Size             = UDim2.new(0, 30, 0, 30),
        Position         = UDim2.new(0, 12, 0, 13),
        BackgroundColor3 = Theme.Surface3,
        BorderSizePixel  = 0,
        Image            = thumbUrl,
        Parent           = UserCard,
    })
    local avatarCorner = New("UICorner", { CornerRadius = UDim.new(1, 0) })
    avatarCorner.Parent = Avatar
    local avatarStroke = New("UIStroke", { Color = Theme.Border2, Thickness = 1.5 })
    avatarStroke.Parent = Avatar

    local DisplayLabel = New("TextLabel", {
        Text                   = displayName,
        Size                   = UDim2.new(1, -52, 0, 14),
        Position               = UDim2.new(0, 48, 0, 14),
        BackgroundTransparency = 1,
        TextColor3             = Theme.Text,
        Font                   = Theme.Font,
        TextSize               = 11,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        Parent                 = UserCard,
    })
    local UsernameLabel = New("TextLabel", {
        Text                   = "@" .. username,
        Size                   = UDim2.new(1, -52, 0, 12),
        Position               = UDim2.new(0, 48, 0, 30),
        BackgroundTransparency = 1,
        TextColor3             = Theme.TextDim,
        Font                   = Theme.Font,
        TextSize               = 10,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = UserCard,
    })

    -- Content area
    local ContentArea = New("Frame", {
        Name                   = "ContentArea",
        Size                   = UDim2.new(1, -168, 1, -16),
        Position               = UDim2.new(0, 168, 0, 8),
        BackgroundTransparency = 1,
        Parent                 = Main,
    })

    -- Close button
    local CloseBtn = New("TextButton", {
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
    local closeBtnCorner = New("UICorner", { CornerRadius = UDim.new(0, 6) })
    closeBtnCorner.Parent = CloseBtn

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, { Size = UDim2.new(0, WinSize.X.Offset, 0, 0) }, 0.22)
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
    local MinBtn = New("TextButton", {
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
    local minBtnCorner = New("UICorner", { CornerRadius = UDim.new(0, 6) })
    minBtnCorner.Parent = MinBtn

    local minimised = false
    MinBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        if minimised then
            Tween(Main, { Size = UDim2.new(0, WinSize.X.Offset, 0, 38) }, 0.22)
        else
            Tween(Main, { Size = WinSize }, 0.22)
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

    MakeDraggable(Main, LogoSection)

    -- Entrance animation
    Main.Size = UDim2.new(0, WinSize.X.Offset, 0, 0)
    Main.BackgroundTransparency = 1
    Tween(Main, { Size = WinSize, BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Back)

    -- Window object
    local Window = { _tabs = {}, _activeTab = nil }

    function Window:CreateTab(name)
        local isFirst = #self._tabs == 0

        local TabBtn = New("TextButton", {
            Text                   = "",
            Size                   = UDim2.new(1, 0, 0, 32),
            BackgroundColor3       = Theme.Surface3,
            BackgroundTransparency = isFirst and 0 or 1,
            BorderSizePixel        = 0,
            AutoButtonColor        = false,
            LayoutOrder            = #self._tabs + 1,
            Parent                 = TabContainer,
        })
        local tabBtnCorner = New("UICorner", { CornerRadius = UDim.new(0, 6) })
        tabBtnCorner.Parent = TabBtn

        local AccentBar = New("Frame", {
            Size                   = UDim2.new(0, 2, 0, 16),
            Position               = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3       = Theme.Accent,
            BorderSizePixel        = 0,
            BackgroundTransparency = isFirst and 0 or 1,
            Parent                 = TabBtn,
        })
        local accentBarCorner = New("UICorner", { CornerRadius = UDim.new(0, 2) })
        accentBarCorner.Parent = AccentBar

        local TabLabel = New("TextLabel", {
            Text                   = name,
            Size                   = UDim2.new(1, -16, 1, 0),
            Position               = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            TextColor3             = isFirst and Theme.Text or Theme.TextDim,
            Font                   = Theme.Font,
            TextSize               = 12,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = TabBtn,
        })

        local Page = New("ScrollingFrame", {
            Name                   = name .. "Page",
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 2,
            ScrollBarImageColor3   = Theme.Border2,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            Visible                = isFirst,
            Parent                 = ContentArea,
        })
        local pageList = New("UIListLayout", {
            Padding       = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder     = Enum.SortOrder.LayoutOrder,
        })
        pageList.Parent = Page
        local pagePad = New("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
        })
        pagePad.Parent = Page

        local tabData = {
            Button = TabBtn,
            Page   = Page,
            Label  = TabLabel,
            Bar    = AccentBar,
        }
        table.insert(self._tabs, tabData)
        if isFirst then self._activeTab = tabData end

        TabBtn.MouseButton1Click:Connect(function()
            if self._activeTab == tabData then return end
            if self._activeTab then
                self._activeTab.Page.Visible = false
                Tween(self._activeTab.Button, { BackgroundTransparency = 1 }, 0.12)
                Tween(self._activeTab.Label,  { TextColor3 = Theme.TextDim }, 0.12)
                Tween(self._activeTab.Bar,    { BackgroundTransparency = 1 }, 0.12)
            end
            Page.Visible = true
            Tween(TabBtn,   { BackgroundTransparency = 0, BackgroundColor3 = Theme.Surface3 }, 0.12)
            Tween(TabLabel, { TextColor3 = Theme.Text }, 0.12)
            Tween(AccentBar, { BackgroundTransparency = 0 }, 0.12)
            self._activeTab = tabData
        end)
        TabBtn.MouseEnter:Connect(function()
            if self._activeTab ~= tabData then
                Tween(TabBtn,   { BackgroundTransparency = 0.6, BackgroundColor3 = Theme.Surface3 }, 0.1)
                Tween(TabLabel, { TextColor3 = Theme.TextMuted }, 0.1)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self._activeTab ~= tabData then
                Tween(TabBtn,   { BackgroundTransparency = 1 }, 0.1)
                Tween(TabLabel, { TextColor3 = Theme.TextDim }, 0.1)
            end
        end)

        -- Tab API
        local Tab = { _order = 0, _page = Page, _screen = ScreenGui }

        local function NextOrder()
            Tab._order = Tab._order + 1
            return Tab._order
        end

        function Tab:AddSection(text)
            local Section = New("Frame", {
                Size                   = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                LayoutOrder            = NextOrder(),
                Parent                 = Page,
            })
            local lbl = New("TextLabel", {
                Text                   = string.upper(text),
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.TextDim,
                Font                   = Theme.Font,
                TextSize               = 9,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = Section,
            })
            local div = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel  = 0,
                Parent           = Section,
            })
        end

        function Tab:AddButton(config)
            config = config or {}
            local Btn = New("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            local btnCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })
            btnCorner.Parent = Btn
            local btnStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
            btnStroke.Parent = Btn
            local btnLbl = New("TextLabel", {
                Text                   = config.Text or "Button",
                Size                   = UDim2.new(1, -16, 1, 0),
                Position               = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.Text,
                Font                   = Theme.Font,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = Btn,
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
                if config.Callback then pcall(config.Callback) end
            end)
            return Btn
        end

        function Tab:AddToggle(config)
            config = config or {}
            local state = config.Default or false

            local Row = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            local rowCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })
            rowCorner.Parent = Row
            local rowStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
            rowStroke.Parent = Row
            local rowLbl = New("TextLabel", {
                Text                   = config.Label or "Toggle",
                Size                   = UDim2.new(1, -60, 1, 0),
                Position               = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.Text,
                Font                   = Theme.Font,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = Row,
            })
            local Track = New("Frame", {
                Size             = UDim2.new(0, 34, 0, 18),
                Position         = UDim2.new(1, -48, 0.5, -9),
                BackgroundColor3 = state and Theme.Accent or Theme.Surface3,
                BorderSizePixel  = 0,
                Parent           = Row,
            })
            local trackCorner = New("UICorner", { CornerRadius = UDim.new(1, 0) })
            trackCorner.Parent = Track
            local trackStroke = New("UIStroke", { Color = Theme.Border2, Thickness = 1 })
            trackStroke.Parent = Track
            local Knob = New("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                Position         = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel  = 0,
                Parent           = Track,
            })
            local knobCorner = New("UICorner", { CornerRadius = UDim.new(1, 0) })
            knobCorner.Parent = Knob

            local function UpdateToggle()
                if state then
                    Tween(Track, { BackgroundColor3 = Theme.Accent }, 0.15)
                    Tween(Knob,  { Position = UDim2.new(1, -15, 0.5, -6) }, 0.15)
                else
                    Tween(Track, { BackgroundColor3 = Theme.Surface3 }, 0.15)
                    Tween(Knob,  { Position = UDim2.new(0, 3, 0.5, -6) }, 0.15)
                end
                if config.Callback then pcall(config.Callback, state) end
            end

            local ClickRegion = New("TextButton", {
                Text                   = "",
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Parent                 = Row,
            })
            ClickRegion.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
            end)

            return {
                SetState = function(_, s) state = s UpdateToggle() end,
                GetState = function() return state end,
            }
        end

        function Tab:AddSlider(config)
            config = config or {}
            local minVal  = config.Min     or 0
            local maxVal  = config.Max     or 100
            local current = config.Default or minVal

            local Container = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            local conCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })
            conCorner.Parent = Container
            local conStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
            conStroke.Parent = Container

            local TopRow = New("Frame", {
                Size                   = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Parent                 = Container,
            })
            local sliderLbl = New("TextLabel", {
                Text                   = config.Label or "Slider",
                Size                   = UDim2.new(0.7, 0, 1, 0),
                Position               = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.Text,
                Font                   = Theme.Font,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = TopRow,
            })
            local ValueLabel = New("TextLabel", {
                Text                   = tostring(current),
                Size                   = UDim2.new(0.3, -14, 1, 0),
                Position               = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.Accent,
                Font                   = Theme.FontMono,
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = TopRow,
            })

            local Track = New("Frame", {
                Size             = UDim2.new(1, -28, 0, 4),
                Position         = UDim2.new(0, 14, 0, 36),
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel  = 0,
                Parent           = Container,
            })
            local trackCorner2 = New("UICorner", { CornerRadius = UDim.new(1, 0) })
            trackCorner2.Parent = Track

            local Fill = New("Frame", {
                Size             = UDim2.new((current - minVal) / (maxVal - minVal), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                Parent           = Track,
            })
            local fillCorner = New("UICorner", { CornerRadius = UDim.new(1, 0) })
            fillCorner.Parent = Fill

            local Knob = New("Frame", {
                Size             = UDim2.new(0, 12, 0, 12),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new((current - minVal) / (maxVal - minVal), 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel  = 0,
                ZIndex           = 2,
                Parent           = Track,
            })
            local knobCorner2 = New("UICorner", { CornerRadius = UDim.new(1, 0) })
            knobCorner2.Parent = Knob

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
                    current          = math.round(minVal + rel * (maxVal - minVal))
                    ValueLabel.Text  = tostring(current)
                    Fill.Size        = UDim2.new(rel, 0, 1, 0)
                    Knob.Position    = UDim2.new(rel, 0, 0.5, 0)
                    if config.Callback then pcall(config.Callback, current) end
                end
            end)

            return {
                SetValue = function(_, v)
                    current = math.clamp(v, minVal, maxVal)
                    local rel = (current - minVal) / (maxVal - minVal)
                    ValueLabel.Text = tostring(current)
                    Fill.Size       = UDim2.new(rel, 0, 1, 0)
                    Knob.Position   = UDim2.new(rel, 0, 0.5, 0)
                end,
                GetValue = function() return current end,
            }
        end

        function Tab:AddDropdown(config)
            config = config or {}
            local options  = config.Options or {}
            local selected = config.Default or (options[1] or "")
            local open     = false

            local Container = New("Frame", {
                Size                   = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                LayoutOrder            = NextOrder(),
                ClipsDescendants       = false,
                Parent                 = Page,
                ZIndex                 = 5,
            })

            local Header = New("TextButton", {
                Text             = "",
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ZIndex           = 5,
                Parent           = Container,
            })
            local headerCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })
            headerCorner.Parent = Header
            local headerStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
            headerStroke.Parent = Header

            local ddLbl = New("TextLabel", {
                Text                   = config.Label or "Dropdown",
                Size                   = UDim2.new(0.5, 0, 1, 0),
                Position               = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.TextMuted,
                Font                   = Theme.Font,
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 5,
                Parent                 = Header,
            })
            local SelectedLabel = New("TextLabel", {
                Text                   = selected,
                Size                   = UDim2.new(0.5, -36, 1, 0),
                Position               = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.Text,
                Font                   = Theme.Font,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Right,
                ZIndex                 = 5,
                Parent                 = Header,
            })
            local Arrow = New("TextLabel", {
                Text                   = ">",
                Size                   = UDim2.new(0, 20, 1, 0),
                Position               = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = Theme.TextDim,
                Font                   = Theme.Font,
                TextSize               = 14,
                ZIndex                 = 5,
                Parent                 = Header,
            })

            local Dropdown = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 0, 40),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 10,
                Parent           = Container,
            })
            local ddCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })
            ddCorner.Parent = Dropdown
            local ddStroke = New("UIStroke", { Color = Theme.Border2, Thickness = 1 })
            ddStroke.Parent = Dropdown
            local ddList = New("UIListLayout", { Padding = UDim.new(0, 1) })
            ddList.Parent = Dropdown
            local ddPad = New("UIPadding", {
                PaddingTop    = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
            })
            ddPad.Parent = Dropdown

            for _, opt in ipairs(options) do
                local OptBtn = New("TextButton", {
                    Text                   = opt,
                    Size                   = UDim2.new(1, -8, 0, 28),
                    BackgroundColor3       = Theme.Surface2,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    TextColor3             = Theme.TextMuted,
                    Font                   = Theme.Font,
                    TextSize               = 12,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 11,
                    Parent                 = Dropdown,
                })
                local optPad = New("UIPadding", { PaddingLeft = UDim.new(0, 10) })
                optPad.Parent = OptBtn

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
                    Tween(Dropdown,  { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    Tween(Arrow,     { Rotation = 0 }, 0.15)
                    Container.Size = UDim2.new(1, 0, 0, 36)
                    if config.Callback then pcall(config.Callback, opt) end
                end)
            end

            Header.MouseButton1Click:Connect(function()
                open = not open
                local targetH = open and math.min(#options * 29 + 8, 180) or 0
                Tween(Dropdown, { Size = UDim2.new(1, 0, 0, targetH) }, 0.18)
                Tween(Arrow,    { Rotation = open and 90 or 0 }, 0.18)
                Container.Size = UDim2.new(1, 0, 0, open and 36 + targetH + 4 or 36)
            end)

            return {
                SetValue = function(_, v) selected = v SelectedLabel.Text = v end,
                GetValue = function() return selected end,
            }
        end

        function Tab:AddInput(config)
            config = config or {}

            local Container = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                LayoutOrder      = NextOrder(),
                Parent           = Page,
            })
            local inCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })
            inCorner.Parent = Container
            local inStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1 })
            inStroke.Parent = Container

            local inLbl = New("TextLabel", {
                Text                   = config.Label or "Input",
                Size                   = UDim2.new(1, -14, 0, 18),
                Position               = UDim2.new(0, 14, 0, 6),
                BackgroundTransparency = 1,
                TextColor3             = Theme.TextMuted,
                Font                   = Theme.Font,
                TextSize               = 10,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = Container,
            })
            local Box = New("TextBox", {
                Text              = config.Default or "",
                PlaceholderText   = config.Placeholder or "",
                Size              = UDim2.new(1, -28, 0, 22),
                Position          = UDim2.new(0, 14, 0, 26),
                BackgroundTransparency = 1,
                TextColor3        = Theme.Text,
                PlaceholderColor3 = Theme.TextDim,
                Font              = config.Mono and Theme.FontMono or Theme.Font,
                TextSize          = 12,
                TextXAlignment    = Enum.TextXAlignment.Left,
                ClearTextOnFocus  = false,
                Parent            = Container,
            })
            Box.Focused:Connect(function()
                Tween(Container, { BackgroundColor3 = Theme.Surface2 }, 0.12)
            end)
            Box.FocusLost:Connect(function(enter)
                Tween(Container, { BackgroundColor3 = Theme.Surface }, 0.12)
                if config.Callback then pcall(config.Callback, Box.Text, enter) end
            end)

            return {
                GetValue = function() return Box.Text end,
                SetValue = function(_, v) Box.Text = v end,
            }
        end

        function Tab:AddLabel(text, color)
            local L = New("TextLabel", {
                Text                   = text or "",
                Size                   = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                TextColor3             = color or Theme.TextMuted,
                Font                   = Theme.Font,
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextWrapped            = true,
                LayoutOrder            = NextOrder(),
                Parent                 = Page,
            })
            return {
                SetText = function(_, t) L.Text = t end,
            }
        end

        function Tab:Notify(config)
            config = config or {}
            local typeColor = ({
                info    = Theme.Blue,
                success = Theme.Green,
                warning = Theme.Amber,
                error   = Theme.Red,
            })[config.Type or "info"] or Theme.Blue

            local Toast = New("Frame", {
                Size             = UDim2.new(0, 260, 0, 60),
                Position         = UDim2.new(1, 280, 1, -70),
                AnchorPoint      = Vector2.new(1, 1),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel  = 0,
                ZIndex           = 100,
                Parent           = ScreenGui,
            })
            local toastCorner = New("UICorner", { CornerRadius = UDim.new(0, 10) })
            toastCorner.Parent = Toast
            local toastStroke = New("UIStroke", { Color = typeColor, Thickness = 1 })
            toastStroke.Parent = Toast

            local toastBar = New("Frame", {
                Size             = UDim2.new(0, 3, 1, -16),
                Position         = UDim2.new(0, 10, 0, 8),
                BackgroundColor3 = typeColor,
                BorderSizePixel  = 0,
                ZIndex           = 101,
                Parent           = Toast,
            })
            local toastTitle = New("TextLabel", {
                Text                   = config.Title or "Notification",
                Size                   = UDim2.new(1, -30, 0, 20),
                Position               = UDim2.new(0, 20, 0, 10),
                BackgroundTransparency = 1,
                TextColor3             = Theme.Text,
                Font                   = Theme.FontBold,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 101,
                Parent                 = Toast,
            })
            local toastMsg = New("TextLabel", {
                Text                   = config.Message or "",
                Size                   = UDim2.new(1, -30, 0, 16),
                Position               = UDim2.new(0, 20, 0, 32),
                BackgroundTransparency = 1,
                TextColor3             = Theme.TextMuted,
                Font                   = Theme.Font,
                TextSize               = 10,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                ZIndex                 = 101,
                Parent                 = Toast,
            })

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
