-- ╔══════════════════════════════════════════════════════════════╗
-- ║              ELERIUM UI  —  Complete Rewrite                ║
-- ║  API: AddWindow · AddTab · AddButton · AddSwitch            ║
-- ║       AddSlider · AddDropdown · AddKeybind · AddLabel       ║
-- ║       AddFolder · AddColorPicker · AddTextBox               ║
-- ║       AddHorizontalAlignment                                ║
-- ║  Visual: Dark bg · Red accent · Vertical sidebar            ║
-- ║          Smooth tweens · Profile card · RightShift toggle   ║
-- ╚══════════════════════════════════════════════════════════════╝

local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer

-- ────────────────────────────────────────────────────────────────
-- Theme
-- ────────────────────────────────────────────────────────────────
local Theme = {
    BG         = Color3.fromRGB(13, 13, 18),
    Sidebar    = Color3.fromRGB(18, 18, 25),
    Panel      = Color3.fromRGB(22, 22, 30),
    Element    = Color3.fromRGB(28, 28, 38),
    ElementHov = Color3.fromRGB(34, 34, 46),
    Accent     = Color3.fromRGB(200, 30, 30),
    AccentDark = Color3.fromRGB(140, 10, 10),
    AccentGlow = Color3.fromRGB(255, 60, 60),
    Border     = Color3.fromRGB(55, 20, 20),
    BorderSub  = Color3.fromRGB(40, 40, 55),
    Text       = Color3.fromRGB(240, 240, 248),
    SubText    = Color3.fromRGB(150, 150, 170),
    White      = Color3.new(1,1,1),
    SliderFill = Color3.fromRGB(200, 30, 30),
    ToggleOff  = Color3.fromRGB(50, 50, 65),
    ToggleOn   = Color3.fromRGB(200, 30, 30),
}

-- ────────────────────────────────────────────────────────────────
-- Tween helper
-- ────────────────────────────────────────────────────────────────
local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t or 0.22, style, dir), props):Play()
end

-- ────────────────────────────────────────────────────────────────
-- Instance factory
-- ────────────────────────────────────────────────────────────────
local function New(class, props, children)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    for _,c in ipairs(children or {}) do
        c.Parent = obj
    end
    return obj
end

local function Corner(r)
    return New("UICorner",{CornerRadius=UDim.new(0,r or 6)})
end
local function Stroke(color, thick, trans)
    return New("UIStroke",{
        Color=color or Theme.Border,
        Thickness=thick or 1,
        Transparency=trans or 0,
        ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    })
end
local function Padding(top,bottom,left,right)
    return New("UIPadding",{
        PaddingTop    = UDim.new(0,top    or 0),
        PaddingBottom = UDim.new(0,bottom or 0),
        PaddingLeft   = UDim.new(0,left   or 0),
        PaddingRight  = UDim.new(0,right  or 0),
    })
end
local function ListLayout(dir, pad, align)
    return New("UIListLayout",{
        FillDirection       = dir   or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, pad or 4),
        SortOrder           = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
    })
end

-- ────────────────────────────────────────────────────────────────
-- Gotham font helpers
-- ────────────────────────────────────────────────────────────────
local GOTHAM_PATH = "rbxasset://fonts/families/GothamSSm.json"
local function GothamFont(weight, style)
    return Font.new(GOTHAM_PATH,
        weight or Enum.FontWeight.Regular,
        style  or Enum.FontStyle.Normal)
end

-- ────────────────────────────────────────────────────────────────
-- ScreenGui
-- ────────────────────────────────────────────────────────────────
local function getGui()
    local existing = (gethui and gethui()) or game:GetService("CoreGui")
    local old = existing:FindFirstChild("EleriumUI_v5")
    if old then old:Destroy() end
    local sg = New("ScreenGui",{
        Name             = "EleriumUI_v5",
        ResetOnSpawn     = false,
        ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset   = true,
        Parent           = (RunService:IsStudio() and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or existing,
    })
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(sg)
        elseif (protectgui) then protectgui(sg) end
    end)
    return sg
end

-- ────────────────────────────────────────────────────────────────
-- Floating dropdown layer (ZIndex 200)
-- ────────────────────────────────────────────────────────────────
local DropdownLayer  -- set in AddWindow

-- ────────────────────────────────────────────────────────────────
-- Library table
-- ────────────────────────────────────────────────────────────────
local Library = {
    Options   = {},
    _GUI      = nil,
    _Window   = nil,
}

-- ────────────────────────────────────────────────────────────────
-- AddWindow
-- ────────────────────────────────────────────────────────────────
function Library:AddWindow(config)
    config = config or {}
    local title    = config.Title    or "Elerium"
    local subtitle = config.SubTitle or ""
    local minKey   = config.MinimizeKey or Enum.KeyCode.RightShift
    local winW     = config.Width  or 680
    local winH     = config.Height or 500
    local sideW    = config.SidebarWidth or 170

    local GUI = getGui()
    Library._GUI = GUI

    -- Floating dropdown layer
    DropdownLayer = New("Frame",{
        Name                 = "DropdownLayer",
        BackgroundTransparency = 1,
        Size                 = UDim2.fromScale(1,1),
        ZIndex               = 200,
        Parent               = GUI,
    })

    -- ── Root window frame ──────────────────────────────────────
    local Root = New("Frame",{
        Name                 = "Root",
        Size                 = UDim2.fromOffset(winW, winH),
        Position             = UDim2.fromOffset(
            math.floor((workspace.CurrentCamera.ViewportSize.X - winW)/2),
            math.floor((workspace.CurrentCamera.ViewportSize.Y - winH)/2)
        ),
        BackgroundColor3     = Theme.BG,
        BorderSizePixel      = 0,
        ClipsDescendants     = true,
        Parent               = GUI,
    },{
        Corner(10),
        Stroke(Theme.Border, 1.5, 0),
        New("UIGradient",{
            Rotation = 120,
            Color    = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(25,15,15)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,15)),
            }),
        }),
    })

    -- ── Title bar ─────────────────────────────────────────────
    local TitleBar = New("Frame",{
        Name             = "TitleBar",
        Size             = UDim2.new(1,0,0,46),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = Root,
    },{
        New("Frame",{ -- accent line bottom
            Size             = UDim2.new(1,0,0,2),
            Position         = UDim2.new(0,0,1,-2),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
        }),
        -- Logo dot
        New("Frame",{
            Size             = UDim2.fromOffset(10,10),
            Position         = UDim2.fromOffset(16,18),
            BackgroundColor3 = Theme.AccentGlow,
            BorderSizePixel  = 0,
        },{Corner(5)}),
        -- Title
        New("TextLabel",{
            Text             = title,
            Font             = Enum.Font.GothamBold,
            TextSize         = 14,
            TextColor3       = Theme.Text,
            BackgroundTransparency = 1,
            Size             = UDim2.new(0,300,0,20),
            Position         = UDim2.fromOffset(34,13),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 4,
        }),
        -- Subtitle
        New("TextLabel",{
            Text             = subtitle,
            FontFace         = GothamFont(Enum.FontWeight.Regular),
            TextSize         = 11,
            TextColor3       = Theme.SubText,
            BackgroundTransparency = 1,
            Size             = UDim2.new(0,300,0,14),
            Position         = UDim2.new(0,34,0,28),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 4,
        }),
    })

    -- ── Close / Minimize buttons ───────────────────────────────
    local function BarBtn(icon, pos, col)
        local btn = New("TextButton",{
            Text             = "",
            Size             = UDim2.fromOffset(18,18),
            Position         = pos,
            AnchorPoint      = Vector2.new(1,0.5),
            BackgroundColor3 = col,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            Parent           = TitleBar,
        },{Corner(9)})
        if icon then
            New("TextLabel",{
                Text  = icon, Font = Enum.Font.GothamBold,
                TextSize = 10, TextColor3 = Theme.White,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1), ZIndex = 6,
            }).Parent = btn
        end
        return btn
    end
    local CloseBtn = BarBtn("✕", UDim2.new(1,-12,0.5,0), Color3.fromRGB(200,50,50))
    local MinBtn   = BarBtn("─", UDim2.new(1,-36,0.5,0), Color3.fromRGB(55,55,65))

    -- ── Sidebar ────────────────────────────────────────────────
    local Sidebar = New("Frame",{
        Name             = "Sidebar",
        Size             = UDim2.new(0,sideW,1,-46),
        Position         = UDim2.fromOffset(0,46),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
        Parent           = Root,
    },{
        New("Frame",{ -- right border line
            Size             = UDim2.new(0,1,1,0),
            Position         = UDim2.new(1,-1,0,0),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
        }),
    })

    -- Tab list in sidebar
    local TabList = New("ScrollingFrame",{
        Name                   = "TabList",
        Size                   = UDim2.new(1,0,1,-100), -- leave room for profile
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = Theme.Accent,
        CanvasSize             = UDim2.new(0,0,0,0),
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        ZIndex                 = 2,
        Parent                 = Sidebar,
    },{
        ListLayout(Enum.FillDirection.Vertical, 3),
        Padding(8,0,6,6),
    })

    -- ── Profile card at sidebar bottom ────────────────────────
    local profileCard = New("Frame",{
        Name             = "ProfileCard",
        Size             = UDim2.new(1,0,0,82),
        Position         = UDim2.new(0,0,1,-90),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = Sidebar,
    },{
        Corner(8),
        Padding(8,8,8,8),
        Stroke(Theme.Accent, 1, 0.4),
        New("Frame",{ -- top border line
            Size             = UDim2.new(1,0,0,1),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
        }),
    })

    -- Avatar
    local avatarHolder = New("Frame",{
        Size             = UDim2.fromOffset(42,42),
        Position         = UDim2.fromOffset(8,12),
        BackgroundColor3 = Theme.AccentDark,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = profileCard,
    },{
        Corner(21),
        Stroke(Theme.Accent, 2, 0),
    })

    local avatarImg = New("ImageLabel",{
        Size             = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Image            = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=60&h=60",
        ZIndex           = 4,
        Parent           = avatarHolder,
    },{Corner(21)})

    local profileName = New("TextLabel",{
        Text             = LocalPlayer.DisplayName,
        FontFace         = GothamFont(Enum.FontWeight.Bold),
        TextSize         = 12,
        TextColor3       = Theme.Text,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1,-60,0,16),
        Position         = UDim2.fromOffset(58,14),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        ZIndex           = 3,
        Parent           = profileCard,
    })
    local profileUser = New("TextLabel",{
        Text             = "@"..LocalPlayer.Name,
        FontFace         = GothamFont(Enum.FontWeight.Regular),
        TextSize         = 10,
        TextColor3       = Theme.SubText,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1,-60,0,14),
        Position         = UDim2.fromOffset(58,30),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        ZIndex           = 3,
        Parent           = profileCard,
    })
    -- online dot
    New("Frame",{
        Size             = UDim2.fromOffset(8,8),
        Position         = UDim2.fromOffset(58,46),
        BackgroundColor3 = Color3.fromRGB(50,200,80),
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = profileCard,
    },{Corner(4)})
    New("TextLabel",{
        Text  = "Online", FontFace = GothamFont(),
        TextSize = 10, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(0,60,0,14),
        Position = UDim2.fromOffset(70,44),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3, Parent = profileCard,
    })

    -- ── Content area ──────────────────────────────────────────
    local ContentArea = New("Frame",{
        Name             = "ContentArea",
        Size             = UDim2.new(1,-sideW,1,-46),
        Position         = UDim2.fromOffset(sideW,46),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 1,
        Parent           = Root,
    })

    -- Tab selector indicator on sidebar
    local Selector = New("Frame",{
        Size             = UDim2.new(1,-12,0,32),
        Position         = UDim2.fromOffset(6,8),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 1,
        Parent           = Sidebar,
    },{Corner(6)})
    Selector.BackgroundTransparency = 0.85

    -- ── Dragging ──────────────────────────────────────────────
    do
        local dragging, dragStart, startPos = false, nil, nil
        TitleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = inp.Position
                startPos  = Root.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - dragStart
                Root.Position = UDim2.fromOffset(
                    startPos.X.Offset + d.X,
                    startPos.Y.Offset + d.Y
                )
            end
        end)
    end

    -- ── Resize ────────────────────────────────────────────────
    do
        local resizeHandle = New("TextButton",{
            Text             = "",
            Size             = UDim2.fromOffset(14,14),
            Position         = UDim2.new(1,-14,1,-14),
            AnchorPoint      = Vector2.new(1,1),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.7,
            BorderSizePixel  = 0,
            ZIndex           = 10,
            Parent           = Root,
        },{Corner(3)})
        local resizing, resStart, resSize = false, nil, nil
        resizeHandle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true; resStart = inp.Position
                resSize  = Vector2.new(Root.AbsoluteSize.X, Root.AbsoluteSize.Y)
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then resizing = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - resStart
                local nx = math.clamp(resSize.X + d.X, 480, 1200)
                local ny = math.clamp(resSize.Y + d.Y, 360, 900)
                Root.Size = UDim2.fromOffset(nx, ny)
                ContentArea.Size = UDim2.new(1,-sideW,1,-46)
                TabList.Size     = UDim2.new(1,0,1,-100)
            end
        end)
    end

    -- ── Close / Minimize ──────────────────────────────────────
    local minimized = false
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Root, {Size=UDim2.fromOffset(Root.AbsoluteSize.X,0)}, 0.22)
        task.wait(0.23)
        GUI:Destroy()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(Root,{Size=UDim2.fromOffset(Root.AbsoluteSize.X,46)},0.2)
        else
            Tween(Root,{Size=UDim2.fromOffset(Root.AbsoluteSize.X,winH)},0.2)
        end
    end)

    -- RightShift toggle
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == minKey then
            minimized = not minimized
            Root.Visible = not minimized
        end
    end)

    -- ── Hover on buttons ──────────────────────────────────────
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(255,70,70)},0.1) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(200,50,50)},0.1) end)

    -- ────────────────────────────────────────────────────────────
    -- Window object
    -- ────────────────────────────────────────────────────────────
    local Window = {
        _Root        = Root,
        _TabList     = TabList,
        _ContentArea = ContentArea,
        _Selector    = Selector,
        _Tabs        = {},
        _TabIndex    = 0,
        _ActiveTab   = nil,
    }
    Library._Window = Window

    -- update selector position
    local function moveSelectorTo(tabFrame)
        local tabPos = tabFrame.AbsolutePosition.Y - TabList.AbsolutePosition.Y + TabList.CanvasPosition.Y
        Tween(Selector, {
            Position = UDim2.fromOffset(6, tabPos + 6),
            Size     = UDim2.new(1,-12,0,tabFrame.AbsoluteSize.Y - 4),
        }, 0.18)
    end

    -- ── AddTab ───────────────────────────────────────────────
    function Window:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Title or ("Tab "..tostring(#self._Tabs+1))
        local tabIcon = tabConfig.Icon  or nil

        self._TabIndex = self._TabIndex + 1
        local idx = self._TabIndex

        -- Sidebar button
        local tabBtn = New("TextButton",{
            Text             = "",
            Size             = UDim2.new(1,-12,0,32),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ZIndex           = 3,
            LayoutOrder      = idx,
            Parent           = TabList,
        },{Corner(6)})

        -- Icon
        if tabIcon then
            New("ImageLabel",{
                Image            = tabIcon,
                Size             = UDim2.fromOffset(14,14),
                Position         = UDim2.fromOffset(8,9),
                BackgroundTransparency = 1,
                ImageColor3      = Theme.SubText,
                ZIndex           = 4,
                Parent           = tabBtn,
            })
        end

        New("TextLabel",{
            Text         = tabName,
            FontFace     = GothamFont(Enum.FontWeight.Medium),
            TextSize     = 12,
            TextColor3   = Theme.SubText,
            BackgroundTransparency = 1,
            Size         = UDim2.new(1,-30,1,0),
            Position     = UDim2.fromOffset(tabIcon and 26 or 10, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex       = 4,
            Parent       = tabBtn,
        })

        -- Content pane
        local pane = New("ScrollingFrame",{
            Size                   = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Theme.Accent,
            ScrollBarImageTransparency = 0.5,
            CanvasSize             = UDim2.new(0,0,0,0),
            ScrollingDirection     = Enum.ScrollingDirection.Y,
            Visible                = false,
            ZIndex                 = 2,
            Parent                 = ContentArea,
        },{
            ListLayout(Enum.FillDirection.Vertical, 6),
            Padding(10,10,12,12),
        })

        -- auto canvas
        local paneLayout = pane:FindFirstChildOfClass("UIListLayout")
        paneLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            pane.CanvasSize = UDim2.new(0,0,0,paneLayout.AbsoluteContentSize.Y + 20)
        end)

        -- select logic
        local function selectTab()
            -- hide all panes, dim all buttons
            for _, t in ipairs(Window._Tabs) do
                t._Pane.Visible = false
                Tween(t._Btn:FindFirstChildOfClass("TextLabel"),{TextColor3=Theme.SubText},0.15)
                Tween(t._Btn,{BackgroundTransparency=1},0.15)
            end
            pane.Visible = true
            Tween(tabBtn:FindFirstChildOfClass("TextLabel"),{TextColor3=Theme.Text},0.15)
            Tween(tabBtn,{BackgroundTransparency=0.82},0.15)
            moveSelectorTo(tabBtn)
            Window._ActiveTab = Window._Tabs[idx]
        end

        tabBtn.MouseButton1Click:Connect(selectTab)

        -- hover
        tabBtn.MouseEnter:Connect(function()
            if Window._ActiveTab ~= Window._Tabs[idx] then
                Tween(tabBtn,{BackgroundTransparency=0.9},0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._ActiveTab ~= Window._Tabs[idx] then
                Tween(tabBtn,{BackgroundTransparency=1},0.1)
            end
        end)

        -- Tab object
        local Tab = {
            _Btn   = tabBtn,
            _Pane  = pane,
            _Index = idx,
        }
        table.insert(self._Tabs, Tab)

        -- Auto-select first tab
        if #self._Tabs == 1 then
            task.defer(selectTab)
        end

        -- ── Element helpers bound to this tab ────────────────

        -- shared element frame builder
        local function makeElement(title, desc)
            local elem = New("Frame",{
                Size             = UDim2.new(1,0,0,42),
                BackgroundColor3 = Theme.Element,
                BorderSizePixel  = 0,
                AutomaticSize    = Enum.AutomaticSize.Y,
                ZIndex           = 3,
                Parent           = pane,
            },{
                Corner(6),
                Stroke(Theme.BorderSub, 1, 0.5),
                Padding(10,10,12,12),
            })
            local titleLbl = New("TextLabel",{
                Text         = title or "",
                FontFace     = GothamFont(Enum.FontWeight.Medium),
                TextSize     = 13,
                TextColor3   = Theme.Text,
                BackgroundTransparency = 1,
                Size         = UDim2.new(1,-10,0,15),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex       = 4,
                Parent       = elem,
            })
            local descLbl
            if desc and desc ~= "" then
                descLbl = New("TextLabel",{
                    Text         = desc,
                    FontFace     = GothamFont(),
                    TextSize     = 11,
                    TextColor3   = Theme.SubText,
                    BackgroundTransparency = 1,
                    Size         = UDim2.new(1,-10,0,13),
                    Position     = UDim2.fromOffset(0,16),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped  = true,
                    ZIndex       = 4,
                    Parent       = elem,
                })
            end
            -- hover
            elem.MouseEnter:Connect(function()
                Tween(elem,{BackgroundColor3=Theme.ElementHov},0.1)
            end)
            elem.MouseLeave:Connect(function()
                Tween(elem,{BackgroundColor3=Theme.Element},0.1)
            end)
            return elem, titleLbl, descLbl
        end

        -- ── AddButton ────────────────────────────────────────
        function Tab:AddButton(config)
            config = config or {}
            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,40)

            local btn = New("TextButton",{
                Text  = "", Size = UDim2.fromScale(1,1),
                BackgroundTransparency = 1, ZIndex = 5,
                Parent = elem,
            })
            local rightIco = New("TextLabel",{
                Text       = "›",
                Font       = Enum.Font.GothamBold,
                TextSize   = 18,
                TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Size       = UDim2.fromOffset(20,20),
                Position   = UDim2.new(1,-14,0.5,0),
                AnchorPoint= Vector2.new(1,0.5),
                ZIndex     = 5, Parent = elem,
            })
            btn.MouseButton1Click:Connect(function()
                Tween(elem,{BackgroundColor3=Theme.AccentDark},0.08)
                task.delay(0.12, function()
                    Tween(elem,{BackgroundColor3=Theme.Element},0.12)
                end)
                if config.Callback then pcall(config.Callback) end
            end)
            local obj = {}
            function obj:SetTitle(t) titleLbl.Text = t end
            function obj:Fire() if config.Callback then pcall(config.Callback) end end
            return obj
        end

        -- ── AddSwitch (Toggle) ────────────────────────────────
        function Tab:AddSwitch(idx2, config)
            config = config or {}
            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,40)

            local state   = config.Default or false
            local cb      = config.Callback or function() end
            local changed  = nil

            -- Track background
            local trackBG = New("Frame",{
                Size             = UDim2.fromOffset(38,20),
                Position         = UDim2.new(1,-12,0.5,0),
                AnchorPoint      = Vector2.new(1,0.5),
                BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = elem,
            },{Corner(10)})
            local knob = New("Frame",{
                Size             = UDim2.fromOffset(14,14),
                Position         = UDim2.fromOffset(state and 21 or 3, 3),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 6,
                Parent           = trackBG,
            },{Corner(7)})

            local sw = {Value = state, Type = "Toggle"}
            Library.Options[idx2] = sw

            local function applyState(v, silent)
                state = v
                sw.Value = v
                Tween(trackBG,{BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff},0.2)
                Tween(knob,{Position = UDim2.fromOffset(v and 21 or 3, 3)},0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
                if not silent then
                    pcall(cb, v)
                    if changed then pcall(changed, v) end
                end
            end

            local clickBtn = New("TextButton",{
                Text = "", Size = UDim2.fromScale(1,1),
                BackgroundTransparency = 1, ZIndex = 7, Parent = elem,
            })
            clickBtn.MouseButton1Click:Connect(function()
                applyState(not state)
            end)

            function sw:SetValue(v)   applyState(v, true) end
            function sw:GetValue()    return state end
            function sw:OnChanged(f)  changed = f; f(state) end
            function sw:SetTitle(t)   titleLbl.Text = t end

            applyState(state, true)
            return sw
        end

        -- ── AddSlider ─────────────────────────────────────────
        function Tab:AddSlider(idx2, config)
            config = config or {}
            assert(config.Min,     "Slider: Missing Min")
            assert(config.Max,     "Slider: Missing Max")
            assert(config.Default ~= nil, "Slider: Missing Default")

            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,54)

            local min     = config.Min
            local max     = config.Max
            local rounding= config.Rounding or 0
            local cb      = config.Callback or function() end
            local changed  = nil

            -- Value label
            local valLbl = New("TextLabel",{
                Text       = tostring(config.Default),
                FontFace   = GothamFont(Enum.FontWeight.Medium),
                TextSize   = 11,
                TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Size       = UDim2.fromOffset(50,14),
                Position   = UDim2.new(1,-12,0,10),
                AnchorPoint= Vector2.new(1,0),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex     = 5, Parent = elem,
            })

            -- Rail
            local rail = New("Frame",{
                Size             = UDim2.new(1,-24,0,4),
                Position         = UDim2.fromOffset(0,32),
                BackgroundColor3 = Theme.BorderSub,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = elem,
            },{Corner(2)})

            -- Fill
            local fill = New("Frame",{
                Size             = UDim2.fromScale(0,1),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                ZIndex           = 6, Parent = rail,
            },{Corner(2)})

            -- Thumb
            local thumb = New("Frame",{
                Size             = UDim2.fromOffset(12,12),
                AnchorPoint      = Vector2.new(0.5,0.5),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 7, Parent = rail,
            },{Corner(6),Stroke(Theme.Accent,2,0)})

            local sl = {Value=config.Default, Type="Slider", Min=min, Max=max}
            Library.Options[idx2] = sl

            local function applyValue(v, silent)
                local r = rounding == 0 and math.floor or function(n)
                    local f = 10^rounding
                    return math.floor(n*f+0.5)/f
                end
                v = math.clamp(r(v), min, max)
                sl.Value = v
                local pct = (v - min)/(max - min)
                fill.Size  = UDim2.fromScale(pct, 1)
                thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text = tostring(v)
                if not silent then
                    pcall(cb, v)
                    if changed then pcall(changed, v) end
                end
            end

            -- Interaction
            local dragging = false
            local inputConn
            local function startDrag()
                dragging = true
                inputConn = UserInputService.InputChanged:Connect(function(inp)
                    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                        local rx = inp.Position.X - rail.AbsolutePosition.X
                        local pct = math.clamp(rx / rail.AbsoluteSize.X, 0, 1)
                        applyValue(min + (max - min)*pct)
                    end
                end)
            end
            local function stopDrag()
                dragging = false
                if inputConn then inputConn:Disconnect() inputConn = nil end
            end

            rail.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    local rx = inp.Position.X - rail.AbsolutePosition.X
                    local pct = math.clamp(rx / rail.AbsoluteSize.X, 0, 1)
                    applyValue(min + (max - min)*pct)
                    startDrag()
                end
            end)
            rail.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    stopDrag()
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    stopDrag()
                end
            end)

            function sl:SetValue(v)   applyValue(v, true) end
            function sl:GetValue()    return sl.Value end
            function sl:OnChanged(f)  changed = f; f(sl.Value) end
            function sl:SetTitle(t)   titleLbl.Text = t end

            applyValue(config.Default, true)
            return sl
        end

        -- ── AddDropdown ───────────────────────────────────────
        function Tab:AddDropdown(idx2, config)
            config = config or {}
            local values = config.Values or {}
            local multi  = config.Multi  or false
            local cb     = config.Callback or function() end
            local changed = nil

            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,54)

            -- Display box
            local dispBox = New("Frame",{
                Size             = UDim2.new(1,-24,0,26),
                Position         = UDim2.fromOffset(0,24),
                BackgroundColor3 = Theme.BG,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = elem,
            },{Corner(5),Stroke(Theme.Border,1,0)})

            local dispLbl = New("TextLabel",{
                Text         = "Select...",
                FontFace     = GothamFont(),
                TextSize     = 11,
                TextColor3   = Theme.SubText,
                BackgroundTransparency = 1,
                Size         = UDim2.new(1,-28,1,0),
                Position     = UDim2.fromOffset(8,0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex       = 6, Parent = dispBox,
            })
            local arrowLbl = New("TextLabel",{
                Text = "▾", Font = Enum.Font.GothamBold,
                TextSize = 12, TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(16,16),
                Position = UDim2.new(1,-4,0.5,0),
                AnchorPoint = Vector2.new(1,0.5),
                ZIndex = 6, Parent = dispBox,
            })

            local dd = {
                Value  = multi and {} or nil,
                Values = values,
                Multi  = multi,
                Type   = "Dropdown",
            }
            Library.Options[idx2] = dd

            local function updateDisplay()
                if multi then
                    local sel = {}
                    for k,v in pairs(dd.Value) do
                        if v then table.insert(sel, k) end
                    end
                    dispLbl.Text = #sel == 0 and "Select..." or table.concat(sel, ", ")
                    dispLbl.TextColor3 = #sel == 0 and Theme.SubText or Theme.Text
                else
                    dispLbl.Text       = dd.Value or "Select..."
                    dispLbl.TextColor3 = dd.Value and Theme.Text or Theme.SubText
                end
            end

            -- Floating list
            local listOpen    = false
            local listFrame   = nil
            local listConn    = nil

            local function closeList()
                if listFrame then
                    listFrame:Destroy()
                    listFrame = nil
                end
                if listConn then listConn:Disconnect() listConn = nil end
                Tween(arrowLbl,{Rotation=0},0.15)
                listOpen = false
            end

            local function openList()
                if listOpen then closeList(); return end
                listOpen = true
                Tween(arrowLbl,{Rotation=180},0.15)

                local absPos  = dispBox.AbsolutePosition
                local absSize = dispBox.AbsoluteSize
                local vpSize  = workspace.CurrentCamera.ViewportSize
                local listH   = math.min(#values * 28 + 8, 200)
                local yPos    = absPos.Y + absSize.Y + 2
                if yPos + listH > vpSize.Y - 10 then
                    yPos = absPos.Y - listH - 2
                end

                listFrame = New("Frame",{
                    Size             = UDim2.fromOffset(absSize.X, listH),
                    Position         = UDim2.fromOffset(absPos.X, yPos),
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel  = 0,
                    ZIndex           = 200,
                    Parent           = DropdownLayer,
                },{
                    Corner(6),
                    Stroke(Theme.Border,1,0),
                })

                local scrollList = New("ScrollingFrame",{
                    Size                   = UDim2.fromScale(1,1),
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    ScrollBarThickness     = 2,
                    ScrollBarImageColor3   = Theme.Accent,
                    CanvasSize             = UDim2.new(0,0,0,0),
                    ZIndex                 = 201,
                    Parent                 = listFrame,
                },{
                    ListLayout(Enum.FillDirection.Vertical, 2),
                    Padding(4,4,4,4),
                })

                local scrollLayout = scrollList:FindFirstChildOfClass("UIListLayout")
                scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    scrollList.CanvasSize = UDim2.new(0,0,0,scrollLayout.AbsoluteContentSize.Y+8)
                end)

                for _, val in ipairs(values) do
                    local isSelected = multi and (dd.Value[val] == true) or (dd.Value == val)
                    local optBtn = New("TextButton",{
                        Text             = "",
                        Size             = UDim2.new(1,0,0,24),
                        BackgroundColor3 = isSelected and Theme.AccentDark or Theme.Element,
                        BackgroundTransparency = isSelected and 0.4 or 0.6,
                        BorderSizePixel  = 0,
                        ZIndex           = 202,
                        Parent           = scrollList,
                    },{Corner(4)})
                    New("TextLabel",{
                        Text         = tostring(val),
                        FontFace     = GothamFont(),
                        TextSize     = 11,
                        TextColor3   = isSelected and Theme.Text or Theme.SubText,
                        BackgroundTransparency = 1,
                        Size         = UDim2.new(1,-8,1,0),
                        Position     = UDim2.fromOffset(8,0),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex       = 203, Parent = optBtn,
                    })
                    optBtn.MouseButton1Click:Connect(function()
                        if multi then
                            dd.Value[val] = not dd.Value[val]
                        else
                            dd.Value = val
                        end
                        updateDisplay()
                        pcall(cb, dd.Value)
                        if changed then pcall(changed, dd.Value) end
                        if not multi then closeList() end
                    end)
                    optBtn.MouseEnter:Connect(function()
                        Tween(optBtn,{BackgroundTransparency=0.4},0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        Tween(optBtn,{BackgroundTransparency= (multi and dd.Value[val]) or (dd.Value==val) and 0.4 or 0.6},0.1)
                    end)
                end

                -- close on click outside
                listConn = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mp = inp.Position
                        local lp = listFrame and listFrame.AbsolutePosition
                        local ls = listFrame and listFrame.AbsoluteSize
                        if lp and ls then
                            if mp.X < lp.X or mp.X > lp.X+ls.X or mp.Y < lp.Y or mp.Y > lp.Y+ls.Y then
                                closeList()
                            end
                        end
                    end
                end)
            end

            local openBtn = New("TextButton",{
                Text="", Size=UDim2.fromScale(1,1),
                BackgroundTransparency=1, ZIndex=7, Parent=dispBox,
            })
            openBtn.MouseButton1Click:Connect(openList)

            function dd:SetValue(v)
                if multi and type(v) == "table" then
                    dd.Value = {}
                    for _, k in ipairs(v) do dd.Value[k] = true end
                else
                    dd.Value = v
                end
                updateDisplay()
            end
            function dd:SetValues(v)
                values = v; dd.Values = v
            end
            function dd:OnChanged(f) changed = f; f(dd.Value) end
            function dd:GetValue()   return dd.Value end

            -- apply default
            if config.Default then
                if multi and type(config.Default) == "table" then
                    dd.Value = {}
                    for _, k in ipairs(config.Default) do dd.Value[k] = true end
                else
                    dd.Value = config.Default
                end
            end
            updateDisplay()
            return dd
        end

        -- ── AddKeybind ────────────────────────────────────────
        function Tab:AddKeybind(idx2, config)
            config = config or {}
            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,40)

            local kb = {
                Value   = config.Default or "None",
                Mode    = config.Mode or "Toggle",
                Toggled = false,
                Type    = "Keybind",
                Callback        = config.Callback        or function() end,
                ChangedCallback = config.ChangedCallback or function() end,
            }
            Library.Options[idx2] = kb
            local changed = nil

            local keyBtn = New("TextButton",{
                Text             = "",
                Size             = UDim2.fromOffset(70,24),
                Position         = UDim2.new(1,-12,0.5,0),
                AnchorPoint      = Vector2.new(1,0.5),
                BackgroundColor3 = Theme.Element,
                BorderSizePixel  = 0,
                ZIndex           = 5, Parent = elem,
            },{Corner(4),Stroke(Theme.Border,1,0.3)})

            local keyLbl = New("TextLabel",{
                Text       = kb.Value,
                FontFace   = GothamFont(Enum.FontWeight.Medium),
                TextSize   = 11,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Size       = UDim2.fromScale(1,1),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex     = 6, Parent = keyBtn,
            })

            local picking = false
            keyBtn.MouseButton1Click:Connect(function()
                if picking then return end
                picking = true
                keyLbl.Text = "..."
                keyLbl.TextColor3 = Theme.Accent
                task.wait(0.25)
                local ev
                ev = UserInputService.InputBegan:Connect(function(inp)
                    local key
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        key = inp.KeyCode.Name
                    elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        key = "MouseLeft"
                    elseif inp.UserInputType == Enum.UserInputType.MouseButton2 then
                        key = "MouseRight"
                    end
                    if key then
                        picking = false
                        kb.Value = key
                        keyLbl.Text = key
                        keyLbl.TextColor3 = Theme.Text
                        pcall(kb.ChangedCallback, key)
                        if changed then pcall(changed, key) end
                        ev:Disconnect()
                    end
                end)
            end)

            -- fire on keypress
            UserInputService.InputBegan:Connect(function(inp, gp)
                if gp or picking then return end
                if kb.Mode == "Toggle" then
                    local match = (inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name == kb.Value)
                                or (inp.UserInputType == Enum.UserInputType.MouseButton1 and kb.Value == "MouseLeft")
                                or (inp.UserInputType == Enum.UserInputType.MouseButton2 and kb.Value == "MouseRight")
                    if match then
                        kb.Toggled = not kb.Toggled
                        pcall(kb.Callback, kb.Toggled)
                    end
                end
            end)

            function kb:SetValue(k, m)
                kb.Value = k or kb.Value
                kb.Mode  = m or kb.Mode
                keyLbl.Text = kb.Value
            end
            function kb:GetState()
                if kb.Mode == "Always" then return true end
                if kb.Mode == "Hold" then
                    if kb.Value == "MouseLeft"  then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                    if kb.Value == "MouseRight" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                    return pcall(function() return UserInputService:IsKeyDown(Enum.KeyCode[kb.Value]) end) and true or false
                end
                return kb.Toggled
            end
            function kb:OnChanged(f)  changed = f; f(kb.Value) end
            function kb:SetTitle(t)   titleLbl.Text = t end

            return kb
        end

        -- ── AddLabel ──────────────────────────────────────────
        function Tab:AddLabel(config)
            config = config or {}
            local text = type(config) == "string" and config or (config.Text or config.Title or "")

            local lbl = New("Frame",{
                Size             = UDim2.new(1,0,0,28),
                BackgroundTransparency = 1,
                ZIndex           = 3,
                Parent           = pane,
            })
            local tl = New("TextLabel",{
                Text         = text,
                FontFace     = GothamFont(Enum.FontWeight.Regular),
                TextSize     = 12,
                TextColor3   = Theme.SubText,
                BackgroundTransparency = 1,
                Size         = UDim2.fromScale(1,1),
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText     = true,
                ZIndex       = 4, Parent = lbl,
            })
            local obj = {}
            function obj:SetText(t) tl.Text = t end
            function obj:SetTitle(t) tl.Text = t end
            return obj
        end

        -- ── AddColorPicker ────────────────────────────────────
        function Tab:AddColorPicker(idx2, config)
            config = config or {}
            local defColor = config.Default or Color3.new(1,0,0)
            local cb       = config.Callback or function() end
            local changed  = nil

            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,40)

            local cp = {Value = defColor, Type = "Colorpicker"}
            Library.Options[idx2] = cp

            -- Color swatch
            local swatch = New("Frame",{
                Size             = UDim2.fromOffset(28,20),
                Position         = UDim2.new(1,-12,0.5,0),
                AnchorPoint      = Vector2.new(1,0.5),
                BackgroundColor3 = defColor,
                BorderSizePixel  = 0,
                ZIndex           = 5, Parent = elem,
            },{Corner(4),Stroke(Theme.Border,1,0)})

            -- Picker popup
            local pickerOpen = false
            local pickerFrame = nil

            local function closePicker()
                if pickerFrame then pickerFrame:Destroy(); pickerFrame = nil end
                pickerOpen = false
            end

            local function buildPicker()
                if pickerOpen then closePicker(); return end
                pickerOpen = true
                local absPos  = swatch.AbsolutePosition
                local pW, pH  = 200, 220

                pickerFrame = New("Frame",{
                    Size             = UDim2.fromOffset(pW, pH),
                    Position         = UDim2.fromOffset(
                        math.clamp(absPos.X - pW + 28, 4, workspace.CurrentCamera.ViewportSize.X - pW - 4),
                        absPos.Y + 26
                    ),
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel  = 0,
                    ZIndex           = 200,
                    Parent           = DropdownLayer,
                },{Corner(8),Stroke(Theme.Border,1,0)})

                -- SV palette
                local palette = New("ImageLabel",{
                    Image            = "rbxassetid://2531909969",
                    Size             = UDim2.new(1,-16,0,120),
                    Position         = UDim2.fromOffset(8,8),
                    BackgroundColor3 = Color3.fromHSV(Color3.toHSV(cp.Value)),
                    ZIndex           = 201, Parent = pickerFrame,
                },{Corner(5)})

                local paletteCursor = New("Frame",{
                    Size             = UDim2.fromOffset(8,8),
                    AnchorPoint      = Vector2.new(0.5,0.5),
                    BackgroundColor3 = Theme.White,
                    BorderSizePixel  = 0,
                    ZIndex           = 202, Parent = palette,
                },{Corner(4),Stroke(Color3.fromRGB(0,0,0),1,0.4)})

                -- Hue bar
                local hueBar = New("ImageLabel",{
                    Image    = "rbxassetid://2531909975",
                    Size     = UDim2.new(1,-16,0,16),
                    Position = UDim2.fromOffset(8,136),
                    ZIndex   = 201, Parent = pickerFrame,
                },{Corner(4)})
                local hueThumb = New("Frame",{
                    Size             = UDim2.fromOffset(4,20),
                    AnchorPoint      = Vector2.new(0.5,0.5),
                    BackgroundColor3 = Theme.White,
                    BorderSizePixel  = 0,
                    ZIndex           = 202, Parent = hueBar,
                },{Corner(2)})

                -- Hex input
                local function colorToHex(c)
                    return string.format("#%02X%02X%02X",
                        math.floor(c.R*255+0.5),
                        math.floor(c.G*255+0.5),
                        math.floor(c.B*255+0.5))
                end
                local hexBox = New("TextBox",{
                    Text             = colorToHex(cp.Value),
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 11,
                    TextColor3       = Theme.Text,
                    BackgroundColor3 = Theme.Element,
                    Size             = UDim2.new(1,-16,0,24),
                    Position         = UDim2.fromOffset(8,162),
                    ZIndex           = 201, Parent = pickerFrame,
                    PlaceholderText  = "#RRGGBB",
                    ClearTextOnFocus = false,
                },{Corner(4),Padding(0,0,6,0)})

                -- Close btn
                local cBtn = New("TextButton",{
                    Text             = "✕",
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 10,
                    TextColor3       = Theme.SubText,
                    BackgroundColor3 = Theme.Element,
                    Size             = UDim2.fromOffset(24,18),
                    Position         = UDim2.new(1,-8,0,194),
                    AnchorPoint      = Vector2.new(1,0),
                    ZIndex           = 202, Parent = pickerFrame,
                },{Corner(4)})
                cBtn.MouseButton1Click:Connect(closePicker)

                local H, S, V = Color3.toHSV(cp.Value)

                local function applyHSV()
                    local newColor = Color3.fromHSV(H, S, V)
                    cp.Value = newColor
                    swatch.BackgroundColor3 = newColor
                    palette.BackgroundColor3 = Color3.fromHSV(H,1,1)
                    paletteCursor.Position = UDim2.fromOffset(
                        S * palette.AbsoluteSize.X - 4,
                        (1-V) * palette.AbsoluteSize.Y - 4
                    )
                    hueThumb.Position = UDim2.new(H,0,0.5,0)
                    hexBox.Text = colorToHex(newColor)
                    pcall(cb, newColor)
                    if changed then pcall(changed, newColor) end
                end

                -- Palette drag
                local draggingPal = false
                palette.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingPal = true
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if draggingPal and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local rx = math.clamp(inp.Position.X - palette.AbsolutePosition.X, 0, palette.AbsoluteSize.X)
                        local ry = math.clamp(inp.Position.Y - palette.AbsolutePosition.Y, 0, palette.AbsoluteSize.Y)
                        S = rx / palette.AbsoluteSize.X
                        V = 1 - ry / palette.AbsoluteSize.Y
                        applyHSV()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingPal = false
                    end
                end)

                -- Hue drag
                local draggingHue = false
                hueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        draggingHue = true
                        H = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 1)
                        applyHSV()
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if draggingHue and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        H = math.clamp((inp.Position.X - hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 1)
                        applyHSV()
                    end
                end)

                applyHSV()
            end

            local swBtn = New("TextButton",{
                Text="",Size=UDim2.fromScale(1,1),
                BackgroundTransparency=1,ZIndex=6,Parent=elem,
            })
            swBtn.MouseButton1Click:Connect(buildPicker)

            function cp:SetValue(c)
                cp.Value = c; swatch.BackgroundColor3 = c
            end
            function cp:OnChanged(f)  changed = f; f(cp.Value) end
            function cp:SetTitle(t)   titleLbl.Text = t end

            return cp
        end

        -- ── AddTextBox ────────────────────────────────────────
        function Tab:AddTextBox(idx2, config)
            config = config or {}
            local cb       = config.Callback or function() end
            local changed  = nil
            local finished = config.Finished or false

            local elem, titleLbl = makeElement(config.Title, config.Description)
            elem.Size = UDim2.new(1,0,0,56)

            local box = New("TextBox",{
                Text             = config.Default or "",
                PlaceholderText  = config.Placeholder or "Enter text...",
                FontFace         = GothamFont(),
                TextSize         = 12,
                TextColor3       = Theme.Text,
                PlaceholderColor3 = Theme.SubText,
                BackgroundColor3 = Theme.BG,
                ClearTextOnFocus = false,
                Size             = UDim2.new(1,-24,0,26),
                Position         = UDim2.fromOffset(0,24),
                ZIndex           = 5, Parent = elem,
            },{Corner(5),Padding(0,0,8,8),Stroke(Theme.Border,1,0.3)})

            local tb = {Value = config.Default or "", Type = "Input"}
            Library.Options[idx2] = tb

            box.Focused:Connect(function()
                Tween(box,{BackgroundColor3=Theme.Element},0.12)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(box,{BackgroundColor3=Theme.BG},0.12)
                if finished and enter then
                    tb.Value = box.Text
                    pcall(cb, tb.Value)
                    if changed then pcall(changed, tb.Value) end
                end
            end)
            if not finished then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    tb.Value = box.Text
                    pcall(cb, tb.Value)
                    if changed then pcall(changed, tb.Value) end
                end)
            end

            function tb:SetValue(v)  box.Text = v; tb.Value = v end
            function tb:GetValue()   return tb.Value end
            function tb:OnChanged(f) changed = f; f(tb.Value) end
            function tb:SetTitle(t)  titleLbl.Text = t end

            return tb
        end

        -- ── AddHorizontalAlignment ────────────────────────────
        function Tab:AddHorizontalAlignment(config)
            config = config or {}
            local hFrame = New("Frame",{
                Size             = UDim2.new(1,0,0,40),
                BackgroundTransparency = 1,
                ZIndex           = 3,
                Parent           = pane,
            },{
                New("UIListLayout",{
                    FillDirection       = Enum.FillDirection.Horizontal,
                    Padding             = UDim.new(0, 6),
                    SortOrder           = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment   = Enum.VerticalAlignment.Center,
                }),
            })

            local halign = {}

            function halign:AddButton(hConfig)
                hConfig = hConfig or {}
                local btn = New("TextButton",{
                    Text             = hConfig.Title or "Button",
                    FontFace         = GothamFont(Enum.FontWeight.Medium),
                    TextSize         = 12,
                    TextColor3       = Theme.Text,
                    BackgroundColor3 = Theme.Element,
                    Size             = UDim2.fromOffset(0,32),
                    AutomaticSize    = Enum.AutomaticSize.X,
                    BorderSizePixel  = 0,
                    ZIndex           = 4, Parent = hFrame,
                },{Corner(5),Padding(0,0,12,12),Stroke(Theme.BorderSub,1,0.5)})
                btn.MouseButton1Click:Connect(function()
                    Tween(btn,{BackgroundColor3=Theme.AccentDark},0.08)
                    task.delay(0.14,function() Tween(btn,{BackgroundColor3=Theme.Element},0.12) end)
                    if hConfig.Callback then pcall(hConfig.Callback) end
                end)
                btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=Theme.ElementHov},0.1) end)
                btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=Theme.Element},0.1) end)
                return btn
            end

            return halign, hFrame
        end

        -- ── AddFolder ─────────────────────────────────────────
        function Tab:AddFolder(name)
            name = tostring(name or "Folder")

            local folder = New("Frame",{
                Size             = UDim2.new(1,0,0,34),
                BackgroundColor3 = Theme.Sidebar,
                BorderSizePixel  = 0,
                ZIndex           = 3,
                Parent           = pane,
            },{Corner(6),Stroke(Theme.Border,1,0.4)})

            local headerBtn = New("TextButton",{
                Text             = "",
                Size             = UDim2.new(1,0,0,34),
                BackgroundTransparency = 1,
                ZIndex           = 4, Parent = folder,
            })
            New("TextLabel",{
                Text         = "  ▸  "..name,
                FontFace     = GothamFont(Enum.FontWeight.Medium),
                TextSize     = 12,
                TextColor3   = Theme.Text,
                BackgroundTransparency = 1,
                Size         = UDim2.new(1,-10,1,0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex       = 5, Parent = headerBtn,
            })
            local arrowLabel = headerBtn:FindFirstChildOfClass("TextLabel")

            -- Content frame inside folder
            local content = New("Frame",{
                Size             = UDim2.new(1,-8,0,0),
                Position         = UDim2.fromOffset(4,34),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                ZIndex           = 4, Parent = folder,
            },{
                ListLayout(Enum.FillDirection.Vertical,4),
                Padding(0,4,0,0),
            })
            content.Visible = false

            local contentLayout = content:FindFirstChildOfClass("UIListLayout")
            local function updateFolderSize(open)
                if open then
                    local h = contentLayout.AbsoluteContentSize.Y
                    folder.Size = UDim2.new(1,0,0,34+h+8)
                else
                    folder.Size = UDim2.new(1,0,0,34)
                end
            end
            contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if content.Visible then updateFolderSize(true) end
            end)

            local open = false
            headerBtn.MouseButton1Click:Connect(function()
                open = not open
                content.Visible = open
                arrowLabel.Text = "  "..(open and "▾" or "▸").."  "..name
                updateFolderSize(open)
            end)

            -- Folder proxy — same methods as Tab, parented to content
            local folderObj = {}

            -- helper that re-parents element frames into content
            local function patchParent(method)
                return function(self2, ...)
                    -- temporarily redirect pane → content
                    local origPane = pane
                    pane = content
                    local result = {method(Tab, ...)}
                    pane = origPane
                    return table.unpack(result)
                end
            end

            folderObj.AddButton           = patchParent(Tab.AddButton)
            folderObj.AddSwitch           = patchParent(Tab.AddSwitch)
            folderObj.AddSlider           = patchParent(Tab.AddSlider)
            folderObj.AddDropdown         = patchParent(Tab.AddDropdown)
            folderObj.AddKeybind          = patchParent(Tab.AddKeybind)
            folderObj.AddLabel            = patchParent(Tab.AddLabel)
            folderObj.AddColorPicker      = patchParent(Tab.AddColorPicker)
            folderObj.AddTextBox          = patchParent(Tab.AddTextBox)
            folderObj.AddHorizontalAlignment = patchParent(Tab.AddHorizontalAlignment)

            return folderObj, folder
        end

        -- ── AddSection (bonus helper used internally) ─────────
        function Tab:AddSection(sectionTitle)
            local lbl = New("TextLabel",{
                Text         = sectionTitle or "",
                FontFace     = GothamFont(Enum.FontWeight.SemiBold),
                TextSize     = 11,
                TextColor3   = Theme.Accent,
                BackgroundTransparency = 1,
                Size         = UDim2.new(1,0,0,18),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex       = 3, Parent = pane,
            })
            -- thin accent line
            New("Frame",{
                Size             = UDim2.new(1,0,0,1),
                Position         = UDim2.fromOffset(0,16),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel  = 0,
                ZIndex           = 3, Parent = lbl,
            })
            -- return a section proxy with same element methods
            local sec = {Container = pane}
            sec.AddButton           = function(s,...) return Tab:AddButton(...) end
            sec.AddSwitch           = function(s,...) return Tab:AddSwitch(...) end
            sec.AddToggle           = function(s,...) return Tab:AddSwitch(...) end
            sec.AddSlider           = function(s,...) return Tab:AddSlider(...) end
            sec.AddDropdown         = function(s,...) return Tab:AddDropdown(...) end
            sec.AddKeybind          = function(s,...) return Tab:AddKeybind(...) end
            sec.AddLabel            = function(s,...) return Tab:AddLabel(...) end
            sec.AddColorPicker      = function(s,...) return Tab:AddColorPicker(...) end
            sec.AddInput            = function(s,...) return Tab:AddTextBox(...) end
            sec.AddTextBox          = function(s,...) return Tab:AddTextBox(...) end
            return sec
        end

        -- Aliases for compatibility
        Tab.AddToggle  = Tab.AddSwitch
        Tab.AddInput   = Tab.AddTextBox

        return Tab
    end -- AddTab

    -- ── Window-level helpers ──────────────────────────────────
    function Window:SelectTab(idx2)
        if self._Tabs[idx2] then
            self._Tabs[idx2]._Btn.MouseButton1Click:Fire()
        end
    end
    function Window:Minimize()
        minimized = not minimized
        Root.Visible = not minimized
    end
    function Window:Destroy()
        GUI:Destroy()
    end
    function Window:Notify(cfg)
        cfg = cfg or {}
        local notif = New("Frame",{
            Size             = UDim2.fromOffset(280, 70),
            Position         = UDim2.new(1,10,1,-80 - (#GUI:GetChildren() * 78),0),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel  = 0,
            ZIndex           = 150,
            Parent           = GUI,
        },{
            Corner(8),Stroke(Theme.Border,1,0.3),
            New("Frame",{
                Size=UDim2.fromOffset(3,50),Position=UDim2.fromOffset(0,10),
                BackgroundColor3=Theme.Accent,BorderSizePixel=0,
            },{Corner(2)}),
            New("TextLabel",{
                Text=cfg.Title or "",Font=Enum.Font.GothamBold,TextSize=13,
                TextColor3=Theme.Text,BackgroundTransparency=1,
                Size=UDim2.new(1,-20,0,16),Position=UDim2.fromOffset(12,10),
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=151,
            }),
            New("TextLabel",{
                Text=cfg.Content or "",FontFace=GothamFont(),TextSize=11,
                TextColor3=Theme.SubText,BackgroundTransparency=1,
                Size=UDim2.new(1,-20,0,14),Position=UDim2.fromOffset(12,28),
                TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=151,
            }),
        })
        Tween(notif,{Position=UDim2.new(1,-290,1,-80,0)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        task.delay(cfg.Duration or 4, function()
            Tween(notif,{Position=UDim2.new(1,10,1,-80,0)},0.25)
            task.delay(0.3, function() pcall(function() notif:Destroy() end) end)
        end)
    end

    Library._Window = Window
    return Window
end -- AddWindow

-- ── Compatibility shim ────────────────────────────────────────
-- The old API exposed Library:CreateWindow — keep it working
function Library:CreateWindow(cfg)
    return self:AddWindow(cfg)
end

return Library
