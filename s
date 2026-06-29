--[[
    NebulaHub UI Library — Extended Edition
    Adds: Icon support (Nebula Icon Library), ColorPicker, Keybind,
          Paragraph, Separator, and icon params on every element.

    Boot icons (auto-loaded inside the library, but you can also use them externally):
        local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
        local id = NebulaIcons:GetIcon("home", "Material")   -- returns asset id number

    Usage:
        local NebulaHub = loadstring(game:HttpGet("YOUR_URL"))()
        local Window = NebulaHub:CreateWindow({ Title = "My Hub" })
        local Tab = Window:CreateTab("Main", { Icon = "home", IconSource = "Material" })
        Tab:AddButton({ Text = "Click", Icon = "mouse-pointer", IconSource = "Lucide", Callback = function() end })
]]

local NebulaHub = {}
NebulaHub.__index = NebulaHub

-- ─── Services ─────────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService         = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ─── Icon Library (lazy-loaded) ───────────────────────────────────────────────
local NebulaIcons = nil
local function LoadIcons()
    if NebulaIcons then return NebulaIcons end
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
    end)
    if ok and result then
        NebulaIcons = result
    else
        -- Fallback stub so the rest of the library never errors
        NebulaIcons = {
            GetIcon = function() return nil end,
            nebulaIcons = {},
        }
    end
    return NebulaIcons
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function Tween(obj, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.18, style, direction), props):Play()
end

local function New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
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

-- Apply an icon to an ImageLabel, using NebulaIcons if a name is given,
-- or treating the value as a direct asset ID if it's a number.
local function ApplyIcon(imageLabel, iconValue, iconSource)
    if not iconValue then
        imageLabel.Visible = false
        return
    end
    imageLabel.Visible = true
    if type(iconValue) == "number" then
        imageLabel.Image = "rbxassetid://" .. tostring(iconValue)
    else
        local icons = LoadIcons()
        local id = icons:GetIcon(iconValue, iconSource or "Symbols")
        if id then
            imageLabel.Image = "rbxassetid://" .. tostring(id)
        else
            imageLabel.Visible = false
        end
    end
end

-- ─── Theme ────────────────────────────────────────────────────────────────────
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
do
    local ok = pcall(function() return Enum.Font.GothamMedium end)
    if not ok then
        Theme.Font     = Enum.Font.SourceSans
        Theme.FontBold = Enum.Font.SourceSansBold
        Theme.FontMono = Enum.Font.SourceSans
    end
end

-- ─── CreateWindow ─────────────────────────────────────────────────────────────
function NebulaHub:CreateWindow(config)
    config = config or {}
    local Title   = config.Title    or "Nebula Hub"
    local WinSize = config.Size     or UDim2.new(0, 580, 0, 460)
    local WinPos  = config.Position or UDim2.new(0.5, -290, 0.5, -230)

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
    New("UICorner",  { CornerRadius = UDim.new(0, 12), Parent = Main })
    New("UIStroke",  { Color = Theme.Border, Thickness = 1, Parent = Main })

    -- Shadow
    local Shadow = New("Frame", {
        Size                   = UDim2.new(1, 24, 1, 24),
        Position               = UDim2.new(0, -12, 0, -12),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.65,
        BorderSizePixel        = 0,
        ZIndex                 = Main.ZIndex - 1,
        Parent                 = Main,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 18), Parent = Shadow })

    -- Sidebar
    local Sidebar = New("Frame", {
        Name             = "Sidebar",
        Size             = UDim2.new(0, 168, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = Main,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Sidebar })
    -- Clip right corners
    New("Frame", {
        Size             = UDim2.new(0, 12, 1, 0),
        Position         = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })
    New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Sidebar })

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
    New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = LogoDot })
    for r = 0, 1 do
        for c = 0, 1 do
            New("Frame", {
                Size                   = UDim2.new(0, 6, 0, 6),
                Position               = UDim2.new(0, 4 + c*9, 0, 4 + r*9),
                BackgroundColor3       = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 0.2,
                BorderSizePixel        = 0,
                Parent                 = LogoDot,
            })
        end
    end
    New("TextLabel", {
        Text = Title, Size = UDim2.new(1,-44,0,16), Position = UDim2.new(0,42,0,14),
        BackgroundTransparency = 1, TextColor3 = Theme.Text,
        Font = Theme.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LogoSection,
    })
    New("TextLabel", {
        Text = gameName, Size = UDim2.new(1,-44,0,13), Position = UDim2.new(0,42,0,32),
        BackgroundTransparency = 1, TextColor3 = Theme.TextDim,
        Font = Theme.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = LogoSection,
    })
    New("Frame", {
        Size = UDim2.new(1,-24,0,1), Position = UDim2.new(0,12,0,68),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = Sidebar,
    })

    -- Tab button container
    local TabContainer = New("ScrollingFrame", {
        Name               = "TabContainer",
        Size               = UDim2.new(1, 0, 1, -148),
        Position           = UDim2.new(0, 0, 0, 76),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ScrollBarThickness = 0,
        CanvasSize         = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent             = Sidebar,
    })
    local tabList = New("UIListLayout", {
        Padding = UDim.new(0,2), FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabContainer,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
        PaddingTop = UDim.new(0,4), Parent = TabContainer,
    })

    -- User card
    local UserCard = New("Frame", {
        Name = "UserCard", Size = UDim2.new(1,0,0,56),
        Position = UDim2.new(0,0,1,-56),
        BackgroundTransparency = 1, Parent = Sidebar,
    })
    New("Frame", {
        Size = UDim2.new(1,-24,0,1), Position = UDim2.new(0,12,0,0),
        BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = UserCard,
    })
    local Avatar = New("ImageLabel", {
        Size = UDim2.new(0,30,0,30), Position = UDim2.new(0,12,0,13),
        BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0,
        Image = thumbUrl, Parent = UserCard,
    })
    New("UICorner", { CornerRadius = UDim.new(1,0), Parent = Avatar })
    New("UIStroke", { Color = Theme.Border2, Thickness = 1.5, Parent = Avatar })
    New("TextLabel", {
        Text = displayName, Size = UDim2.new(1,-52,0,14), Position = UDim2.new(0,48,0,14),
        BackgroundTransparency = 1, TextColor3 = Theme.Text,
        Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = UserCard,
    })
    New("TextLabel", {
        Text = "@"..username, Size = UDim2.new(1,-52,0,12), Position = UDim2.new(0,48,0,30),
        BackgroundTransparency = 1, TextColor3 = Theme.TextDim,
        Font = Theme.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = UserCard,
    })

    -- Content area
    local ContentArea = New("Frame", {
        Name = "ContentArea", Size = UDim2.new(1,-180,1,-16),
        Position = UDim2.new(0,176,0,8),
        BackgroundTransparency = 1, Parent = Main,
    })

    -- Close button
    local CloseBtn = New("TextButton", {
        Text = "×", Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-30,0,8),
        BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
        TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 16,
        ZIndex = 10, Parent = Main,
    })
    New("UICorner", { CornerRadius = UDim.new(0,6), Parent = CloseBtn })
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, { Size = UDim2.new(0, WinSize.X.Offset, 0, 0) }, 0.22)
        task.wait(0.23)
        ScreenGui:Destroy()
    end)
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Theme.Red, TextColor3 = Color3.new(1,1,1) }, 0.12) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.TextMuted }, 0.12) end)

    -- Minimise button
    local MinBtn = New("TextButton", {
        Text = "−", Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-56,0,8),
        BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
        TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 16,
        ZIndex = 10, Parent = Main,
    })
    New("UICorner", { CornerRadius = UDim.new(0,6), Parent = MinBtn })
    local minimised = false
    MinBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        Tween(Main, { Size = minimised and UDim2.new(0, WinSize.X.Offset, 0, 38) or WinSize }, 0.22)
    end)
    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, { BackgroundColor3 = Theme.Amber, TextColor3 = Color3.new(1,1,1) }, 0.12) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, { BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.TextMuted }, 0.12) end)

    MakeDraggable(Main, LogoSection)

    -- Entrance animation
    Main.Size = UDim2.new(0, WinSize.X.Offset, 0, 0)
    Main.BackgroundTransparency = 1
    Tween(Main, { Size = WinSize, BackgroundTransparency = 0 }, 0.28, Enum.EasingStyle.Back)

    -- ─── Window object ────────────────────────────────────────────────────────
    local Window = { _tabs = {}, _activeTab = nil }

    function Window:CreateTab(name, tabConfig)
        tabConfig = tabConfig or {}
        local isFirst = #self._tabs == 0

        -- Tab button
        local TabBtn = New("TextButton", {
            Text = "", Size = UDim2.new(1,0,0,34),
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = isFirst and 0 or 1,
            BorderSizePixel = 0, AutoButtonColor = false,
            LayoutOrder = #self._tabs + 1, Parent = TabContainer,
        })
        New("UICorner", { CornerRadius = UDim.new(0,6), Parent = TabBtn })

        local AccentBar = New("Frame", {
            Size = UDim2.new(0,2,0,16), Position = UDim2.new(0,0,0.5,-8),
            BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
            BackgroundTransparency = isFirst and 0 or 1, Parent = TabBtn,
        })
        New("UICorner", { CornerRadius = UDim.new(0,2), Parent = AccentBar })

        -- Tab icon
        local TabIcon = New("ImageLabel", {
            Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,10,0.5,-7),
            BackgroundTransparency = 1,
            ImageColor3 = isFirst and Theme.Text or Theme.TextDim,
            Visible = false, Parent = TabBtn,
        })
        if tabConfig.Icon then
            ApplyIcon(TabIcon, tabConfig.Icon, tabConfig.IconSource)
        end

        local iconOffset = (tabConfig.Icon and TabIcon.Visible) and 28 or 12
        local TabLabel = New("TextLabel", {
            Text = name, Size = UDim2.new(1, -iconOffset - 4, 1, 0),
            Position = UDim2.new(0, iconOffset, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = isFirst and Theme.Text or Theme.TextDim,
            Font = Theme.Font, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TabBtn,
        })

        -- Page
        local Page = New("ScrollingFrame", {
            Name = name.."Page", Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border2,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = isFirst, Parent = ContentArea,
        })
        New("UIListLayout", {
            Padding = UDim.new(0,6), FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = Page,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0,8), PaddingRight = UDim.new(0,8),
            PaddingBottom = UDim.new(0,8), Parent = Page,
        })

        local tabData = { Button = TabBtn, Page = Page, Label = TabLabel, Bar = AccentBar, Icon = TabIcon }
        table.insert(self._tabs, tabData)
        if isFirst then self._activeTab = tabData end

        TabBtn.MouseButton1Click:Connect(function()
            if self._activeTab == tabData then return end
            if self._activeTab then
                self._activeTab.Page.Visible = false
                Tween(self._activeTab.Button, { BackgroundTransparency = 1 }, 0.12)
                Tween(self._activeTab.Label,  { TextColor3 = Theme.TextDim }, 0.12)
                Tween(self._activeTab.Bar,    { BackgroundTransparency = 1 }, 0.12)
                Tween(self._activeTab.Icon,   { ImageColor3 = Theme.TextDim }, 0.12)
            end
            Page.Visible = true
            Tween(TabBtn,    { BackgroundTransparency = 0, BackgroundColor3 = Theme.Surface3 }, 0.12)
            Tween(TabLabel,  { TextColor3 = Theme.Text }, 0.12)
            Tween(AccentBar, { BackgroundTransparency = 0 }, 0.12)
            Tween(TabIcon,   { ImageColor3 = Theme.Text }, 0.12)
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

        -- ─── Tab API ──────────────────────────────────────────────────────────
        local Tab = { _order = 0, _page = Page, _screen = ScreenGui }

        local function NextOrder()
            Tab._order = Tab._order + 1
            return Tab._order
        end

        -- Helper: add an icon to a row element
        local function RowIcon(parent, iconValue, iconSource, yCenter)
            local img = New("ImageLabel", {
                Size = UDim2.new(0,14,0,14),
                Position = UDim2.new(0, 12, 0.5, -7),
                BackgroundTransparency = 1,
                ImageColor3 = Theme.TextMuted,
                Visible = false,
                Parent = parent,
            })
            ApplyIcon(img, iconValue, iconSource)
            return img
        end

        -- ── AddSection ────────────────────────────────────────────────────────
        function Tab:AddSection(text)
            local Section = New("Frame", {
                Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1,
                LayoutOrder = NextOrder(), Parent = Page,
            })
            New("TextLabel", {
                Text = string.upper(text), Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1, TextColor3 = Theme.TextDim,
                Font = Theme.Font, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Section,
            })
            New("Frame", {
                Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
                BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = Section,
            })
        end

        -- ── AddSeparator ──────────────────────────────────────────────────────
        function Tab:AddSeparator()
            New("Frame", {
                Size = UDim2.new(1,0,0,1), BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = Page,
            })
        end

        -- ── AddLabel ─────────────────────────────────────────────────────────
        function Tab:AddLabel(text, color)
            local L = New("TextLabel", {
                Text = text or "", Size = UDim2.new(1,0,0,24),
                BackgroundTransparency = 1,
                TextColor3 = color or Theme.TextMuted,
                Font = Theme.Font, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true, LayoutOrder = NextOrder(), Parent = Page,
            })
            return { SetText = function(_, t) L.Text = t end }
        end

        -- ── AddParagraph ──────────────────────────────────────────────────────
        function Tab:AddParagraph(config)
            config = config or {}
            local Container = New("Frame", {
                Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
                LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Container })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Container })
            New("UIPadding", {
                PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12),
                PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10),
                Parent = Container,
            })
            if config.Title then
                New("TextLabel", {
                    Text = config.Title, Size = UDim2.new(1,0,0,16),
                    BackgroundTransparency = 1, TextColor3 = Theme.Text,
                    Font = Theme.FontBold, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                    LayoutOrder = 1, Parent = Container,
                })
            end
            local Body = New("TextLabel", {
                Text = config.Content or config.Text or "",
                Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, TextColor3 = Theme.TextMuted,
                Font = Theme.Font, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                RichText = config.RichText or false,
                LayoutOrder = 2, Parent = Container,
            })
            -- Inner UIListLayout for stacking title + body
            New("UIListLayout", {
                Padding = UDim.new(0,4), FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder, Parent = Container,
            })
            return {
                SetContent = function(_, t) Body.Text = t end,
            }
        end

        -- ── AddButton ─────────────────────────────────────────────────────────
        function Tab:AddButton(config)
            config = config or {}
            local Btn = New("TextButton", {
                Text = "", Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
                AutoButtonColor = false, LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Btn })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Btn })

            -- Icon
            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,12,0.5,-7),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, Parent = Btn,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local textX = (config.Icon and iconImg.Visible) and 34 or 14

            New("TextLabel", {
                Text = config.Text or "Button",
                Size = UDim2.new(1,-textX-8,1,0), Position = UDim2.new(0,textX,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Btn,
            })

            -- Description
            if config.Description then
                Btn.Size = UDim2.new(1,0,0,52)
                New("TextLabel", {
                    Text = config.Description,
                    Size = UDim2.new(1,-textX-8,0,12), Position = UDim2.new(0,textX,0,24),
                    BackgroundTransparency = 1, TextColor3 = Theme.TextDim,
                    Font = Theme.Font, TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = Btn,
                })
            end

            Btn.MouseEnter:Connect(function()    Tween(Btn, { BackgroundColor3 = Theme.Surface2 }, 0.1) end)
            Btn.MouseLeave:Connect(function()    Tween(Btn, { BackgroundColor3 = Theme.Surface  }, 0.1) end)
            Btn.MouseButton1Down:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.Surface3 }, 0.07) end)
            Btn.MouseButton1Click:Connect(function()
                Tween(Btn, { BackgroundColor3 = Theme.Surface }, 0.12)
                if config.Callback then pcall(config.Callback) end
            end)
            return Btn
        end

        -- ── AddToggle ─────────────────────────────────────────────────────────
        function Tab:AddToggle(config)
            config = config or {}
            local state = config.Default or false

            local Row = New("Frame", {
                Size = UDim2.new(1,0,0,36), BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Row })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Row })

            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,12,0.5,-7),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, Parent = Row,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local textX = (config.Icon and iconImg.Visible) and 34 or 14

            New("TextLabel", {
                Text = config.Label or "Toggle",
                Size = UDim2.new(1,-76,1,0), Position = UDim2.new(0,textX,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Row,
            })

            local Track = New("Frame", {
                Size = UDim2.new(0,34,0,18), Position = UDim2.new(1,-48,0.5,-9),
                BackgroundColor3 = state and Theme.Accent or Theme.Surface3,
                BorderSizePixel = 0, Parent = Row,
            })
            New("UICorner", { CornerRadius = UDim.new(1,0), Parent = Track })
            New("UIStroke", { Color = Theme.Border2, Thickness = 1, Parent = Track })
            local Knob = New("Frame", {
                Size = UDim2.new(0,12,0,12),
                Position = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0, Parent = Track,
            })
            New("UICorner", { CornerRadius = UDim.new(1,0), Parent = Knob })

            local function Update()
                Tween(Track, { BackgroundColor3 = state and Theme.Accent or Theme.Surface3 }, 0.15)
                Tween(Knob,  { Position = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6) }, 0.15)
                if config.Callback then pcall(config.Callback, state) end
            end

            local Click = New("TextButton", {
                Text = "", Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1, Parent = Row,
            })
            Click.MouseButton1Click:Connect(function() state = not state Update() end)

            return {
                SetState = function(_, s) state = s Update() end,
                GetState = function() return state end,
            }
        end

        -- ── AddSlider ─────────────────────────────────────────────────────────
        function Tab:AddSlider(config)
            config = config or {}
            local minVal  = config.Min     or 0
            local maxVal  = config.Max     or 100
            local current = config.Default or minVal
            local suffix  = config.Suffix  or ""

            local Container = New("Frame", {
                Size = UDim2.new(1,0,0,52), BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Container })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Container })

            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,12,0,8),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, Parent = Container,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local textX = (config.Icon and iconImg.Visible) and 30 or 14

            New("TextLabel", {
                Text = config.Label or "Slider",
                Size = UDim2.new(0.65,-textX,0,24), Position = UDim2.new(0,textX,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Container,
            })
            local ValueLabel = New("TextLabel", {
                Text = tostring(current)..suffix,
                Size = UDim2.new(0.35,-14,0,24), Position = UDim2.new(0.65,0,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Accent,
                Font = Theme.FontMono, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Container,
            })

            local Track = New("Frame", {
                Size = UDim2.new(1,-28,0,4), Position = UDim2.new(0,14,0,36),
                BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0, Parent = Container,
            })
            New("UICorner", { CornerRadius = UDim.new(1,0), Parent = Track })
            local Fill = New("Frame", {
                Size = UDim2.new((current-minVal)/(maxVal-minVal),0,1,0),
                BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = Track,
            })
            New("UICorner", { CornerRadius = UDim.new(1,0), Parent = Fill })
            local Knob = New("Frame", {
                Size = UDim2.new(0,12,0,12), AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new((current-minVal)/(maxVal-minVal),0,0.5,0),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BorderSizePixel = 0, ZIndex = 2, Parent = Track,
            })
            New("UICorner", { CornerRadius = UDim.new(1,0), Parent = Knob })

            local dragging = false
            Knob.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    current = math.round(minVal + rel * (maxVal - minVal))
                    ValueLabel.Text = tostring(current)..suffix
                    Fill.Size = UDim2.new(rel,0,1,0)
                    Knob.Position = UDim2.new(rel,0,0.5,0)
                    if config.Callback then pcall(config.Callback, current) end
                end
            end)

            return {
                SetValue = function(_, v)
                    current = math.clamp(v, minVal, maxVal)
                    local rel = (current-minVal)/(maxVal-minVal)
                    ValueLabel.Text = tostring(current)..suffix
                    Fill.Size = UDim2.new(rel,0,1,0)
                    Knob.Position = UDim2.new(rel,0,0.5,0)
                end,
                GetValue = function() return current end,
            }
        end

        -- ── AddDropdown ───────────────────────────────────────────────────────
        function Tab:AddDropdown(config)
            config = config or {}
            local options  = config.Options or {}
            local selected = config.Default or (options[1] or "")
            local open     = false

            local Container = New("Frame", {
                Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1,
                LayoutOrder = NextOrder(), ClipsDescendants = false,
                Parent = Page, ZIndex = 5,
            })
            local Header = New("TextButton", {
                Text = "", Size = UDim2.new(1,0,0,36),
                BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
                AutoButtonColor = false, ZIndex = 5, Parent = Container,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Header })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Header })

            -- Icon
            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,12,0.5,-7),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, ZIndex = 6, Parent = Header,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local textX = (config.Icon and iconImg.Visible) and 32 or 14

            New("TextLabel", {
                Text = config.Label or "Dropdown",
                Size = UDim2.new(0.45,0,1,0), Position = UDim2.new(0,textX,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.TextMuted,
                Font = Theme.Font, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = Header,
            })
            local SelLabel = New("TextLabel", {
                Text = selected,
                Size = UDim2.new(0.55,-36,1,0), Position = UDim2.new(0.45,0,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5, Parent = Header,
            })
            local Arrow = New("TextLabel", {
                Text = ">", Size = UDim2.new(0,20,1,0), Position = UDim2.new(1,-24,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.TextDim,
                Font = Theme.Font, TextSize = 14, ZIndex = 5, Parent = Header,
            })

            local Dropdown = New("Frame", {
                Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,40),
                BackgroundColor3 = Theme.Surface2, BorderSizePixel = 0,
                ClipsDescendants = true, ZIndex = 10, Parent = Container,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Dropdown })
            New("UIStroke", { Color = Theme.Border2, Thickness = 1, Parent = Dropdown })
            New("UIListLayout", { Padding = UDim.new(0,1), Parent = Dropdown })
            New("UIPadding", {
                PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), Parent = Dropdown,
            })

            for _, opt in ipairs(options) do
                local OptBtn = New("TextButton", {
                    Text = opt, Size = UDim2.new(1,-8,0,28),
                    BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 1,
                    BorderSizePixel = 0, TextColor3 = Theme.TextMuted,
                    Font = Theme.Font, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11, Parent = Dropdown,
                })
                New("UIPadding", { PaddingLeft = UDim.new(0,10), Parent = OptBtn })
                OptBtn.MouseEnter:Connect(function()
                    Tween(OptBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = Theme.Surface3, TextColor3 = Theme.Text }, 0.1)
                end)
                OptBtn.MouseLeave:Connect(function()
                    Tween(OptBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted }, 0.1)
                end)
                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelLabel.Text = opt
                    open = false
                    Tween(Dropdown, { Size = UDim2.new(1,0,0,0) }, 0.15)
                    Tween(Arrow,    { Rotation = 0 }, 0.15)
                    Container.Size = UDim2.new(1,0,0,36)
                    if config.Callback then pcall(config.Callback, opt) end
                end)
            end

            Header.MouseButton1Click:Connect(function()
                open = not open
                local targetH = open and math.min(#options*29+8, 180) or 0
                Tween(Dropdown, { Size = UDim2.new(1,0,0,targetH) }, 0.18)
                Tween(Arrow,    { Rotation = open and 90 or 0 }, 0.18)
                Container.Size = UDim2.new(1,0,0, open and 36+targetH+4 or 36)
            end)

            return {
                SetValue = function(_, v) selected = v SelLabel.Text = v end,
                GetValue = function() return selected end,
            }
        end

        -- ── AddInput ──────────────────────────────────────────────────────────
        function Tab:AddInput(config)
            config = config or {}
            local Container = New("Frame", {
                Size = UDim2.new(1,0,0,54), BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Container })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Container })

            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,12,0,6),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, Parent = Container,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local labelX = (config.Icon and iconImg.Visible) and 30 or 14

            New("TextLabel", {
                Text = config.Label or "Input",
                Size = UDim2.new(1,-labelX,0,18), Position = UDim2.new(0,labelX,0,6),
                BackgroundTransparency = 1, TextColor3 = Theme.TextMuted,
                Font = Theme.Font, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Container,
            })
            local Box = New("TextBox", {
                Text = config.Default or "",
                PlaceholderText = config.Placeholder or "",
                Size = UDim2.new(1,-28,0,22), Position = UDim2.new(0,14,0,26),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.TextDim,
                Font = config.Mono and Theme.FontMono or Theme.Font,
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false, Parent = Container,
            })
            Box.Focused:Connect(function()  Tween(Container, { BackgroundColor3 = Theme.Surface2 }, 0.12) end)
            Box.FocusLost:Connect(function(enter)
                Tween(Container, { BackgroundColor3 = Theme.Surface }, 0.12)
                if config.Callback then pcall(config.Callback, Box.Text, enter) end
            end)
            return {
                GetValue = function() return Box.Text end,
                SetValue = function(_, v) Box.Text = v end,
            }
        end

        -- ── AddKeybind ────────────────────────────────────────────────────────
        function Tab:AddKeybind(config)
            config = config or {}
            local currentKey = config.Default or Enum.KeyCode.Unknown
            local listening  = false

            local Row = New("Frame", {
                Size = UDim2.new(1,0,0,36), BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0, LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Row })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Row })

            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,12,0.5,-7),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, Parent = Row,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local textX = (config.Icon and iconImg.Visible) and 34 or 14

            New("TextLabel", {
                Text = config.Label or "Keybind",
                Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,textX,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Row,
            })

            local KeyBtn = New("TextButton", {
                Text = tostring(currentKey.Name),
                Size = UDim2.new(0,80,0,22), Position = UDim2.new(1,-88,0.5,-11),
                BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0,
                TextColor3 = Theme.Accent, Font = Theme.FontMono, TextSize = 10,
                Parent = Row,
            })
            New("UICorner", { CornerRadius = UDim.new(0,5), Parent = KeyBtn })
            New("UIStroke", { Color = Theme.Border2, Thickness = 1, Parent = KeyBtn })

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                KeyBtn.Text = "..."
                Tween(KeyBtn, { BackgroundColor3 = Theme.Accent }, 0.12)
                Tween(KeyBtn, { TextColor3 = Color3.new(1,1,1) }, 0.12)
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    currentKey = input.KeyCode
                    KeyBtn.Text = tostring(currentKey.Name)
                    Tween(KeyBtn, { BackgroundColor3 = Theme.Surface3 }, 0.12)
                    Tween(KeyBtn, { TextColor3 = Theme.Accent }, 0.12)
                    if config.Callback then pcall(config.Callback, currentKey) end
                end
            end)

            return {
                GetValue = function() return currentKey end,
                SetValue = function(_, k) currentKey = k KeyBtn.Text = tostring(k.Name) end,
            }
        end

        -- ── AddColorPicker ────────────────────────────────────────────────────
        --[[
            A full HSV color picker with:
              • Hue bar
              • Saturation/Value 2D square
              • Live preview swatch
              • Hex input box
              • RGB readout
        ]]
        function Tab:AddColorPicker(config)
            config = config or {}
            local currentColor = config.Default or Color3.fromRGB(124,111,255)
            local h, s, v = Color3.toHSV(currentColor)
            local open = false

            -- Outer container (collapsed by default)
            local Container = New("Frame", {
                Size = UDim2.new(1,0,0,36), BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0, ClipsDescendants = true,
                LayoutOrder = NextOrder(), Parent = Page,
            })
            New("UICorner", { CornerRadius = UDim.new(0,8), Parent = Container })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Container })

            -- Header row (always visible)
            local Header = New("TextButton", {
                Text = "", Size = UDim2.new(1,0,0,36),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                AutoButtonColor = false, Parent = Container,
            })

            local iconImg = New("ImageLabel", {
                Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,12,0.5,-7),
                BackgroundTransparency = 1, ImageColor3 = Theme.TextMuted,
                Visible = false, Parent = Header,
            })
            if config.Icon then ApplyIcon(iconImg, config.Icon, config.IconSource) end
            local textX = (config.Icon and iconImg.Visible) and 34 or 14

            New("TextLabel", {
                Text = config.Label or "Color",
                Size = UDim2.new(1,-70,1,0), Position = UDim2.new(0,textX,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Header,
            })

            local Swatch = New("Frame", {
                Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-38,0.5,-11),
                BackgroundColor3 = currentColor, BorderSizePixel = 0, Parent = Header,
            })
            New("UICorner", { CornerRadius = UDim.new(0,5), Parent = Swatch })
            New("UIStroke", { Color = Theme.Border2, Thickness = 1, Parent = Swatch })

            -- ── Picker body ──────────────────────────────────────────────────
            local Body = New("Frame", {
                Size = UDim2.new(1,0,0,188), Position = UDim2.new(0,0,0,36),
                BackgroundTransparency = 1, Parent = Container,
            })

            -- SV Square (saturation = X, value = Y inverted)
            local SV = New("ImageLabel", {
                Size = UDim2.new(1,-28,0,120), Position = UDim2.new(0,14,0,8),
                BackgroundColor3 = Color3.fromHSV(h,1,1),
                BorderSizePixel = 0, Image = "rbxassetid://6903835898", -- white→transparent gradient
                Parent = Body,
            })
            New("UICorner", { CornerRadius = UDim.new(0,6), Parent = SV })

            -- Overlay: value (black→transparent, top to bottom)
            local SVDark = New("ImageLabel", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                Image = "rbxassetid://6903835897", Parent = SV,
            })
            New("UICorner", { CornerRadius = UDim.new(0,6), Parent = SVDark })

            -- SV cursor
            local SVCursor = New("Frame", {
                Size = UDim2.new(0,12,0,12), AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(s, 0, 1-v, 0),
                BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
                ZIndex = 3, Parent = SV,
            })
            New("UICorner", { CornerRadius = UDim.new(1,0), Parent = SVCursor })
            New("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.5, Parent = SVCursor })

            -- Hue bar
            local HueBar = New("ImageLabel", {
                Size = UDim2.new(1,-28,0,12), Position = UDim2.new(0,14,0,136),
                Image = "rbxassetid://6903835902", -- full hue spectrum
                BorderSizePixel = 0, Parent = Body,
            })
            New("UICorner", { CornerRadius = UDim.new(0,4), Parent = HueBar })

            local HueCursor = New("Frame", {
                Size = UDim2.new(0,8,1,4), AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(h,0,0.5,0),
                BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
                ZIndex = 3, Parent = HueBar,
            })
            New("UICorner", { CornerRadius = UDim.new(0,3), Parent = HueCursor })
            New("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1, Parent = HueCursor })

            -- Hex + RGB row
            local BottomRow = New("Frame", {
                Size = UDim2.new(1,-28,0,28), Position = UDim2.new(0,14,0,156),
                BackgroundTransparency = 1, Parent = Body,
            })

            local HexBox = New("TextBox", {
                Text = string.format("#%02X%02X%02X",
                    math.round(currentColor.R*255),
                    math.round(currentColor.G*255),
                    math.round(currentColor.B*255)),
                Size = UDim2.new(0,90,1,0),
                BackgroundColor3 = Theme.Surface3, BorderSizePixel = 0,
                TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDim,
                Font = Theme.FontMono, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                ClearTextOnFocus = false, Parent = BottomRow,
            })
            New("UICorner", { CornerRadius = UDim.new(0,5), Parent = HexBox })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = HexBox })

            local RGBLabel = New("TextLabel", {
                Text = "", Size = UDim2.new(1,-98,1,0), Position = UDim2.new(0,98,0,0),
                BackgroundTransparency = 1, TextColor3 = Theme.TextDim,
                Font = Theme.FontMono, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right, Parent = BottomRow,
            })

            -- ── Update helpers ───────────────────────────────────────────────
            local function Commit()
                currentColor = Color3.fromHSV(h, s, v)
                Swatch.BackgroundColor3 = currentColor
                SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                SVCursor.Position = UDim2.new(s, 0, 1-v, 0)
                HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                HexBox.Text = string.format("#%02X%02X%02X",
                    math.round(currentColor.R*255),
                    math.round(currentColor.G*255),
                    math.round(currentColor.B*255))
                RGBLabel.Text = string.format("R%d G%d B%d",
                    math.round(currentColor.R*255),
                    math.round(currentColor.G*255),
                    math.round(currentColor.B*255))
                if config.Callback then pcall(config.Callback, currentColor) end
            end
            Commit()

            -- ── Dragging on SV square ────────────────────────────────────────
            local svDrag = false
            SV.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if svDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                    s = math.clamp((i.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((i.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                    Commit()
                end
            end)

            -- ── Dragging on Hue bar ──────────────────────────────────────────
            local hueDrag = false
            HueBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if hueDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                    h = math.clamp((i.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 0.9999)
                    Commit()
                end
            end)

            -- ── Hex input ────────────────────────────────────────────────────
            HexBox.FocusLost:Connect(function()
                local hex = HexBox.Text:gsub("#","")
                if #hex == 6 then
                    local r = tonumber(hex:sub(1,2), 16)
                    local g = tonumber(hex:sub(3,4), 16)
                    local b = tonumber(hex:sub(5,6), 16)
                    if r and g and b then
                        currentColor = Color3.fromRGB(r,g,b)
                        h, s, v = Color3.toHSV(currentColor)
                        Commit()
                    end
                end
            end)

            -- ── Toggle open/close ────────────────────────────────────────────
            Header.MouseButton1Click:Connect(function()
                open = not open
                Tween(Container, { Size = UDim2.new(1,0,0, open and 36+188+4 or 36) }, 0.2)
            end)

            return {
                GetValue = function() return currentColor end,
                SetValue = function(_, c)
                    currentColor = c
                    h, s, v = Color3.toHSV(c)
                    Commit()
                end,
            }
        end

        -- ── Notify ────────────────────────────────────────────────────────────
        function Tab:Notify(config)
            config = config or {}
            local typeColor = ({
                info    = Theme.Blue,
                success = Theme.Green,
                warning = Theme.Amber,
                error   = Theme.Red,
            })[config.Type or "info"] or Theme.Blue

            local Toast = New("Frame", {
                Size = UDim2.new(0,280,0,64),
                Position = UDim2.new(1,300,1,-80),
                AnchorPoint = Vector2.new(1,1),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0, ZIndex = 100, Parent = ScreenGui,
            })
            New("UICorner", { CornerRadius = UDim.new(0,10), Parent = Toast })
            New("UIStroke", { Color = typeColor, Thickness = 1, Parent = Toast })

            -- Icon on toast
            local toastIconImg = New("ImageLabel", {
                Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,28,0,12),
                BackgroundTransparency = 1, ImageColor3 = typeColor,
                Visible = false, ZIndex = 101, Parent = Toast,
            })
            if config.Icon then ApplyIcon(toastIconImg, config.Icon, config.IconSource or "Symbols") end

            local hasIcon = config.Icon and toastIconImg.Visible
            New("Frame", {
                Size = UDim2.new(0,3,1,-16), Position = UDim2.new(0,10,0,8),
                BackgroundColor3 = typeColor, BorderSizePixel = 0,
                ZIndex = 101, Parent = Toast,
            })
            New("TextLabel", {
                Text = config.Title or "Notification",
                Size = UDim2.new(1,-36,0,20),
                Position = UDim2.new(0, hasIcon and 50 or 20, 0, 10),
                BackgroundTransparency = 1, TextColor3 = Theme.Text,
                Font = Theme.FontBold, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101, Parent = Toast,
            })
            New("TextLabel", {
                Text = config.Message or "",
                Size = UDim2.new(1,-36,0,16),
                Position = UDim2.new(0, hasIcon and 50 or 20, 0, 32),
                BackgroundTransparency = 1, TextColor3 = Theme.TextMuted,
                Font = Theme.Font, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 101, Parent = Toast,
            })

            Tween(Toast, { Position = UDim2.new(1,-10,1,-80) }, 0.25, Enum.EasingStyle.Back)
            task.delay(config.Duration or 3, function()
                Tween(Toast, { Position = UDim2.new(1,300,1,-80) }, 0.2)
                task.wait(0.22)
                Toast:Destroy()
            end)
        end

        return Tab
    end

    return Window
end

return NebulaHub
