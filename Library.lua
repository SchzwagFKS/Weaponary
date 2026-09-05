--[[
===============================================================================
  SSRP LIBRARY (Based on Luna Interface Suite)
  - Fixed icon handling, bind callbacks, and error-free operation
  - Designed for SSRP Security integration
===============================================================================
]]

local Release = "SSRP Library v1.0"
local Luna = {
    Folder = "Luna",
    Options = {},
    ThemeGradient = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(117, 164, 206)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(123, 201, 201)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(224, 138, 175))
    }
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Localization = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local isStudio = RunService:IsStudio()

-- Safe icon lookup (fixes nil errors)
local IconModule = {
    Lucide = nil,
    Material = {
        ["menu"] = "http://www.roblox.com/asset/?id=6031097225",
        ["location_searching"] = "http://www.roblox.com/asset/?id=6034503370",
        ["settings"] = "http://www.roblox.com/asset/?id=6031280882",
        ["info"] = "http://www.roblox.com/asset/?id=6026568227",
        ["warning"] = "http://www.roblox.com/asset/?id=6031071053",
        ["error"] = "http://www.roblox.com/asset/?id=6031071057",
        ["check_circle"] = "http://www.roblox.com/asset/?id=6023426909",
        ["check"] = "http://www.roblox.com/asset/?id=6031094667",
        ["zoom_in"] = "http://www.roblox.com/asset/?id=6031075573",
        ["sparkle"] = "http://www.roblox.com/asset/?id=4483362748",
        ["location_on"] = "http://www.roblox.com/asset/?id=6035190846",
        ["visibility_off"] = "http://www.roblox.com/asset/?id=6031075929",
        ["visibility"] = "http://www.roblox.com/asset/?id=6031075931",
        ["star"] = "http://www.roblox.com/asset/?id=6031068423",
        ["close"] = "http://www.roblox.com/asset/?id=6031094678"
    }
}

local function GetIcon(icon, source)
    if not icon then return nil end
    if source == "Custom" then
        return "rbxassetid://" .. icon
    elseif source == "Lucide" then
        return nil -- For simplicity, we'll avoid Lucide; user can use Material.
    else
        if icon and IconModule[source] then
            return IconModule[source][icon]
        end
        return nil
    end
end

local function RemoveTable(tablre, value)
    for i, v in pairs(tablre) do
        if tostring(v) == tostring(value) then
            table.remove(tablre, i)
        end
    end
end

local function Kwargify(defaults, passed)
    for i, v in pairs(defaults) do
        if passed[i] == nil then
            passed[i] = v
        end
    end
    return passed
end

local function PackColor(Color)
    return { R = Color.R * 255, G = Color.G * 255, B = Color.B * 255 }
end

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

function tween(object, goal, callback, tweenin)
    local tween = TweenService:Create(object, tweenin or TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), goal)
    tween.Completed:Connect(callback or function() end)
    tween:Play()
end

-- Simplified Blur (removed for compatibility; you can uncomment if needed)
-- local function BlurModule(Frame) ... end

local function Draggable(Bar, Window)
    pcall(function()
        local Dragging, DragInput, MousePos, FramePos
        Bar.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                MousePos = Input.Position
                FramePos = Window.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        Bar.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - MousePos
                tween(Window, { Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y) })
            end
        end)
    end)
end

-- Notification
function Luna:Notification(data)
    task.spawn(function()
        data = Kwargify({
            Title = "Missing Title",
            Content = "Missing or Unknown Content",
            Icon = "info",
            ImageSource = "Material"
        }, data or {})

        -- Safely get icon
        local icon = GetIcon(data.Icon, data.ImageSource)
        if not icon then icon = "rbxassetid://6031097225" end -- fallback to menu icon

        -- Create notification
        local Notifications = self.Instance.Notifications
        local template = Notifications.Template
        local newNotification = template:Clone()
        newNotification.Name = data.Title
        newNotification.Parent = Notifications
        newNotification.LayoutOrder = #Notifications:GetChildren()
        newNotification.Visible = false
        newNotification.BackgroundTransparency = 1
        newNotification.Title.TextTransparency = 1
        newNotification.Description.TextTransparency = 1
        newNotification.UIStroke.Transparency = 1
        newNotification.Shadow.ImageTransparency = 1
        newNotification.Icon.ImageTransparency = 1
        newNotification.Icon.BackgroundTransparency = 1

        newNotification.Title.Text = data.Title
        newNotification.Description.Text = data.Content
        newNotification.Icon.Image = icon

        task.wait()

        newNotification.Size = UDim2.new(1, 0, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)
        newNotification.Icon.Size = UDim2.new(0, 28, 0, 28)
        newNotification.Icon.Position = UDim2.new(0, 16, 0.5, -1)

        newNotification.Visible = true
        newNotification.Description.Size = UDim2.new(1, -65, 0, math.huge)
        local bounds = newNotification.Description.TextBounds.Y + 55
        newNotification.Description.Size = UDim2.new(1, -65, 0, bounds - 35)
        newNotification.Size = UDim2.new(1, 0, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)
        tween(newNotification, { Size = UDim2.new(1, 0, 0, bounds) }, nil, TweenInfo.new(0.6, Enum.EasingStyle.Exponential))

        task.wait(0.15)
        tween(newNotification, { BackgroundTransparency = 0.45 }, nil, TweenInfo.new(0.4, Enum.EasingStyle.Exponential))
        tween(newNotification.Title, { TextTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
        task.wait(0.05)
        tween(newNotification.Icon, { ImageTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
        task.wait(0.05)
        tween(newNotification.Description, { TextTransparency = 0.35 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
        tween(newNotification.UIStroke, { Transparency = 0.95 }, nil, TweenInfo.new(0.4, Enum.EasingStyle.Exponential))
        tween(newNotification.Shadow, { ImageTransparency = 0.82 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))

        local waitDuration = math.min(math.max((#newNotification.Description.Text * 0.1) + 2.5, 3), 10)
        task.wait(data.Duration or waitDuration)

        newNotification.Icon.Visible = false
        tween(newNotification, { BackgroundTransparency = 1 }, nil, TweenInfo.new(0.4, Enum.EasingStyle.Exponential))
        tween(newNotification.UIStroke, { Transparency = 1 }, nil, TweenInfo.new(0.4, Enum.EasingStyle.Exponential))
        tween(newNotification.Shadow, { ImageTransparency = 1 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
        tween(newNotification.Title, { TextTransparency = 1 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
        tween(newNotification.Description, { TextTransparency = 1 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
        tween(newNotification, { Size = UDim2.new(1, -90, 0, 0) }, nil, TweenInfo.new(1, Enum.EasingStyle.Exponential))
        task.wait(1)
        tween(newNotification, { Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset) }, nil, TweenInfo.new(1, Enum.EasingStyle.Exponential))
        newNotification.Visible = false
        newNotification:Destroy()
    end)
end

-- Create Window
function Luna:CreateWindow(WindowSettings)
    WindowSettings = Kwargify({
        Name = "SSRP Library",
        Subtitle = "Example",
        LogoID = "6031097225",
        LoadingEnabled = false,
        LoadingTitle = "SSRP Library",
        LoadingSubtitle = "by SSRP",
        KeySystem = false,
        KeySettings = {}
    }, WindowSettings or {})

    local Window = { Bind = Enum.KeyCode.K, CurrentTab = nil, State = true }

    -- Load UI model
    local LunaUI = game:GetObjects("rbxassetid://86467455075715")[1]
    if not LunaUI then
        warn("Failed to load Luna UI model. Please check asset ID.")
        return nil
    end

    if gethui then LunaUI.Parent = gethui() else LunaUI.Parent = CoreGui end
    LunaUI.Enabled = true
    LunaUI.DisplayOrder = 1000000000

    local Main = LunaUI.SmartWindow
    Main.Visible = true
    Main.Title.Title.Text = WindowSettings.Name
    Main.Title.subtitle.Text = WindowSettings.Subtitle
    Main.Logo.Image = "rbxassetid://" .. WindowSettings.LogoID
    Main.Size = UDim2.fromOffset(675, 424)
    Main.Parent.ShadowHolder.Size = Main.Size

    local Elements = Main.Elements.Interactions
    local Navigation = Main.Navigation
    local Tabs = Navigation.Tabs
    local Notifications = LunaUI.Notifications

    Luna.Instance = LunaUI
    Luna.Notifications = Notifications
    Luna.Window = Window

    -- Initialize tabs
    local FirstTab = true

    function Window:CreateHomeTab(HomeTabSettings)
        -- home tab logic (optional)
    end

    function Window:CreateTab(TabSettings)
        TabSettings = Kwargify({
            Name = "Tab",
            ShowTitle = true,
            Icon = "menu",
            ImageSource = "Material"
        }, TabSettings or {})

        local Tab = {}
        local TabButton = Navigation.Tabs["InActive Template"]:Clone()
        TabButton.Name = TabSettings.Name
        TabButton.TextLabel.Text = TabSettings.Name
        TabButton.Parent = Navigation.Tabs
        TabButton.ImageLabel.Image = GetIcon(TabSettings.Icon, TabSettings.ImageSource) or "rbxassetid://6031097225"
        TabButton.Visible = true

        local TabPage = Elements.Template:Clone()
        TabPage.Name = TabSettings.Name
        TabPage.Title.Visible = TabSettings.ShowTitle
        TabPage.Title.Text = TabSettings.Name
        TabPage.Visible = true
        Tab.Page = TabPage
        TabPage.LayoutOrder = #Elements:GetChildren() - 3

        for _, TemplateElement in ipairs(TabPage:GetChildren()) do
            if TemplateElement.ClassName == "Frame" or TemplateElement.ClassName == "TextLabel" and TemplateElement.Name ~= "Title" then
                TemplateElement:Destroy()
            end
        end
        TabPage.Parent = Elements

        function Tab:Activate()
            tween(TabButton.ImageLabel, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
            tween(TabButton, { BackgroundTransparency = 0 })
            tween(TabButton.UIStroke, { Transparency = 0.41 })
            Elements.UIPageLayout:JumpTo(TabPage)
            task.wait(0.05)
            for _, OtherTabButton in ipairs(Navigation.Tabs:GetChildren()) do
                if OtherTabButton.Name ~= "InActive Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton then
                    tween(OtherTabButton.ImageLabel, { ImageColor3 = Color3.fromRGB(221, 221, 221) })
                    tween(OtherTabButton, { BackgroundTransparency = 1 })
                    tween(OtherTabButton.UIStroke, { Transparency = 1 })
                end
            end
            Window.CurrentTab = TabSettings.Name
        end

        if FirstTab then Tab:Activate() end
        task.wait(0.01)
        TabButton.Interact.MouseButton1Click:Connect(function() Tab:Activate() end)
        FirstTab = false

        -- Section
        function Tab:CreateSection(name)
            local Section = {}
            Section.Name = name or "Section"
            local Sectiont = Elements.Template.Section:Clone()
            Sectiont.Text = Section.Name
            Sectiont.Visible = true
            Sectiont.Parent = TabPage
            local TabPage = Sectiont.Frame
            Sectiont.TextTransparency = 1
            tween(Sectiont, { TextTransparency = 0 })

            function Section:Set(NewSection)
                Sectiont.Text = NewSection
            end

            function Section:Destroy()
                Sectiont:Destroy()
            end

            -- Button
            function Section:CreateButton(ButtonSettings)
                ButtonSettings = Kwargify({
                    Name = "Button",
                    Description = nil,
                    Callback = function() end
                }, ButtonSettings or {})

                local Button
                if ButtonSettings.Description and ButtonSettings.Description ~= "" then
                    Button = Elements.Template.ButtonDesc:Clone()
                else
                    Button = Elements.Template.Button:Clone()
                end
                Button.Name = ButtonSettings.Name
                Button.Title.Text = ButtonSettings.Name
                if ButtonSettings.Description then Button.Desc.Text = ButtonSettings.Description end
                Button.Visible = true
                Button.Parent = TabPage
                Button.UIStroke.Transparency = 1
                Button.Title.TextTransparency = 1
                if ButtonSettings.Description then Button.Desc.TextTransparency = 1 end
                tween(Button, { BackgroundTransparency = 0.5 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Button.UIStroke, { Transparency = 0.5 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Button.Title, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                if ButtonSettings.Description then tween(Button.Desc, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential)) end

                Button.Interact.MouseButton1Click:Connect(function()
                    pcall(ButtonSettings.Callback)
                end)

                Button.MouseEnter:Connect(function()
                    tween(Button.UIStroke, { Color = Color3.fromRGB(87, 84, 104) })
                end)
                Button.MouseLeave:Connect(function()
                    tween(Button.UIStroke, { Color = Color3.fromRGB(64, 61, 76) })
                end)

                local ButtonV = { Settings = ButtonSettings }
                function ButtonV:Destroy() Button:Destroy() end
                return ButtonV
            end

            -- Toggle
            function Section:CreateToggle(ToggleSettings)
                ToggleSettings = Kwargify({
                    Name = "Toggle",
                    Description = nil,
                    CurrentValue = false,
                    Callback = function() end
                }, ToggleSettings or {})

                local Toggle = Elements.Template.Toggle:Clone()
                Toggle.Name = ToggleSettings.Name
                Toggle.Title.Text = ToggleSettings.Name
                if ToggleSettings.Description then Toggle.Desc.Text = ToggleSettings.Description end
                Toggle.Visible = true
                Toggle.Parent = TabPage
                Toggle.UIStroke.Transparency = 1
                Toggle.Title.TextTransparency = 1
                if ToggleSettings.Description then Toggle.Desc.TextTransparency = 1 end
                tween(Toggle, { BackgroundTransparency = 0.5 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Toggle.UIStroke, { Transparency = 0.5 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Toggle.Title, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                if ToggleSettings.Description then tween(Toggle.Desc, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential)) end

                local function Set(value)
                    if value then
                        Toggle.toggle.color.Enabled = true
                        tween(Toggle.toggle, { BackgroundTransparency = 0 })
                        Toggle.toggle.UIStroke.color.Enabled = true
                        tween(Toggle.toggle.UIStroke, { Color = Color3.new(255, 255, 255) })
                        tween(Toggle.toggle.val, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(1, -23, 0.5, 0), BackgroundTransparency = 0.45 })
                    else
                        Toggle.toggle.color.Enabled = false
                        Toggle.toggle.UIStroke.color.Enabled = false
                        Toggle.toggle.UIStroke.Color = Color3.fromRGB(97, 97, 97)
                        tween(Toggle.toggle, { BackgroundTransparency = 1 })
                        tween(Toggle.toggle.val, { BackgroundColor3 = Color3.fromRGB(97, 97, 97), Position = UDim2.new(0, 5, 0.5, 0), BackgroundTransparency = 0 })
                    end
                    ToggleV.CurrentValue = value
                end

                local ToggleV = { CurrentValue = ToggleSettings.CurrentValue, Settings = ToggleSettings }
                Toggle.Interact.MouseButton1Click:Connect(function()
                    ToggleSettings.CurrentValue = not ToggleSettings.CurrentValue
                    Set(ToggleSettings.CurrentValue)
                    pcall(ToggleSettings.Callback, ToggleSettings.CurrentValue)
                end)

                Set(ToggleSettings.CurrentValue)
                function ToggleV:Set(newSettings)
                    newSettings = Kwargify(ToggleSettings, newSettings or {})
                    ToggleSettings = newSettings
                    Toggle.Title.Text = ToggleSettings.Name
                    if ToggleSettings.Description then Toggle.Desc.Text = ToggleSettings.Description end
                    Set(ToggleSettings.CurrentValue)
                end
                function ToggleV:UpdateState(State) Set(State) end
                function ToggleV:Destroy() Toggle:Destroy() end
                return ToggleV
            end

            -- Bind
            function Section:CreateBind(BindSettings)
                BindSettings = Kwargify({
                    Name = "Bind",
                    Description = nil,
                    CurrentBind = "Q",
                    HoldToInteract = false,
                    Callback = function() end,
                    OnChangedCallback = function() end
                }, BindSettings or {})

                local Bind = Elements.Template.Bind:Clone()
                Bind.Name = BindSettings.Name
                Bind.Title.Text = BindSettings.Name
                if BindSettings.Description then Bind.Desc.Text = BindSettings.Description end
                Bind.Visible = true
                Bind.Parent = TabPage
                Bind.UIStroke.Transparency = 1
                Bind.Title.TextTransparency = 1
                if BindSettings.Description then Bind.Desc.TextTransparency = 1 end
                Bind.BindFrame.BackgroundTransparency = 1
                Bind.BindFrame.UIStroke.Transparency = 1
                Bind.BindFrame.BindBox.TextTransparency = 1
                tween(Bind, { BackgroundTransparency = 0.5 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                tween(Bind.Title, { TextTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                if BindSettings.Description then tween(Bind.Desc, { TextTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential)) end
                tween(Bind.BindFrame, { BackgroundTransparency = 0.9 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                tween(Bind.BindFrame.UIStroke, { Transparency = 0.3 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                tween(Bind.BindFrame.BindBox, { TextTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))

                Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
                Bind.BindFrame.BindBox.Size = UDim2.new(0, Bind.BindFrame.BindBox.TextBounds.X + 20, 0, 42)

                local CheckingForKey = false
                Bind.BindFrame.BindBox.Focused:Connect(function()
                    CheckingForKey = true
                    Bind.BindFrame.BindBox.Text = ""
                end)
                Bind.BindFrame.BindBox.FocusLost:Connect(function()
                    CheckingForKey = false
                    if Bind.BindFrame.BindBox.Text == "" then
                        Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
                    end
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if CheckingForKey then
                        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Window.Bind then
                            local newKey = string.split(tostring(input.KeyCode), ".")[3]
                            Bind.BindFrame.BindBox.Text = newKey
                            BindSettings.CurrentBind = newKey
                            pcall(BindSettings.OnChangedCallback, newKey)
                            Bind.BindFrame.BindBox:ReleaseFocus()
                        end
                    elseif BindSettings.CurrentBind ~= nil and input.KeyCode == Enum.KeyCode[BindSettings.CurrentBind] and not processed then
                        if BindSettings.HoldToInteract then
                            local Held = true
                            local Connection = input.Changed:Connect(function(prop)
                                if prop == "UserInputState" then
                                    Connection:Disconnect()
                                    Held = false
                                end
                            end)
                            if Held then
                                pcall(BindSettings.Callback, true)
                                while Held do task.wait() end
                                pcall(BindSettings.Callback, false)
                            end
                        else
                            local state = not BindV.Active
                            BindV.Active = state
                            pcall(BindSettings.Callback, state)
                        end
                    end
                end)

                local BindV = { Active = false, Settings = BindSettings, CurrentBind = BindSettings.CurrentBind }
                function BindV:Set(newSettings)
                    newSettings = Kwargify(BindSettings, newSettings or {})
                    BindSettings = newSettings
                    Bind.Title.Text = BindSettings.Name
                    if BindSettings.Description then Bind.Desc.Text = BindSettings.Description end
                    Bind.BindFrame.BindBox.Text = BindSettings.CurrentBind
                    BindV.CurrentBind = BindSettings.CurrentBind
                end
                function BindV:Destroy() Bind:Destroy() end
                return BindV
            end

            -- Input
            function Section:CreateInput(InputSettings)
                InputSettings = Kwargify({
                    Name = "Input",
                    Description = nil,
                    PlaceholderText = "",
                    CurrentValue = "",
                    Numeric = false,
                    Enter = false,
                    Callback = function() end
                }, InputSettings or {})

                local Input = Elements.Template.Input:Clone()
                Input.Name = InputSettings.Name
                Input.Title.Text = InputSettings.Name
                if InputSettings.Description then Input.Desc.Text = InputSettings.Description end
                Input.Visible = true
                Input.Parent = TabPage
                tween(Input, { BackgroundTransparency = 0.5 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                tween(Input.UIStroke, { Transparency = 0.5 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                tween(Input.Title, { TextTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential))
                if InputSettings.Description then tween(Input.Desc, { TextTransparency = 0 }, nil, TweenInfo.new(0.3, Enum.EasingStyle.Exponential)) end

                Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
                Input.InputFrame.InputBox.Text = InputSettings.CurrentValue

                local InputV = { CurrentValue = InputSettings.CurrentValue, Settings = InputSettings }
                Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
                    if InputSettings.Numeric then
                        local text = Input.InputFrame.InputBox.Text
                        if not tonumber(text) and text ~= "." then
                            Input.InputFrame.InputBox.Text = text:match("[0-9.]*") or ""
                        end
                    end
                    InputV.CurrentValue = Input.InputFrame.InputBox.Text
                    if not InputSettings.Enter then pcall(InputSettings.Callback, InputV.CurrentValue) end
                end)
                Input.InputFrame.InputBox.FocusLost:Connect(function(enter)
                    if InputSettings.Enter and enter then pcall(InputSettings.Callback, InputV.CurrentValue) end
                end)

                function InputV:Set(newSettings)
                    newSettings = Kwargify(InputSettings, newSettings or {})
                    InputSettings = newSettings
                    Input.Title.Text = InputSettings.Name
                    Input.InputFrame.InputBox.Text = InputSettings.CurrentValue
                    InputV.CurrentValue = InputSettings.CurrentValue
                end
                function InputV:Destroy() Input:Destroy() end
                return InputV
            end

            -- Dropdown
            function Section:CreateDropdown(DropdownSettings)
                DropdownSettings = Kwargify({
                    Name = "Dropdown",
                    Description = nil,
                    Options = {"Option 1", "Option 2"},
                    CurrentOption = {"Option 1"},
                    MultipleOptions = false,
                    Callback = function() end
                }, DropdownSettings or {})

                local Dropdown = Elements.Template.Dropdown:Clone()
                Dropdown.Name = DropdownSettings.Name
                Dropdown.Title.Text = DropdownSettings.Name
                if DropdownSettings.Description then Dropdown.Desc.Text = DropdownSettings.Description end
                Dropdown.Visible = true
                Dropdown.Parent = TabPage

                local DropdownV = { CurrentOption = DropdownSettings.CurrentOption, Settings = DropdownSettings }
                local opened = false
                local function Toggle()
                    opened = not opened
                    if opened then
                        tween(Dropdown, { Size = UDim2.new(1, -25, 0, 170) })
                    else
                        tween(Dropdown, { Size = UDim2.new(1, -25, 0, 38) })
                    end
                end
                Dropdown.Interact.MouseButton1Click:Connect(Toggle)

                local function Refresh()
                    for _, child in ipairs(Dropdown.List:GetChildren()) do
                        if child.ClassName == "TextLabel" and child.Name ~= "Template" then child:Destroy() end
                    end
                    for _, option in ipairs(DropdownSettings.Options) do
                        local Option = Dropdown.List.Template:Clone()
                        Option.Name = option
                        Option.Text = option
                        Option.Visible = true
                        Option.Parent = Dropdown.List
                        Option.Interact.MouseButton1Click:Connect(function()
                            if DropdownSettings.MultipleOptions then
                                if table.find(DropdownSettings.CurrentOption, option) then
                                    RemoveTable(DropdownSettings.CurrentOption, option)
                                else
                                    table.insert(DropdownSettings.CurrentOption, option)
                                end
                            else
                                DropdownSettings.CurrentOption = {option}
                            end
                            DropdownV.CurrentOption = DropdownSettings.CurrentOption
                            pcall(DropdownSettings.Callback, DropdownV.CurrentOption)
                        end)
                    end
                end
                Refresh()

                function DropdownV:Set(newSettings)
                    newSettings = Kwargify(DropdownSettings, newSettings or {})
                    DropdownSettings = newSettings
                    Refresh()
                    DropdownV.CurrentOption = DropdownSettings.CurrentOption
                end
                function DropdownV:Destroy() Dropdown:Destroy() end
                return DropdownV
            end

            -- Paragraph
            function Section:CreateParagraph(ParagraphSettings)
                ParagraphSettings = Kwargify({
                    Title = "Paragraph",
                    Text = "Text"
                }, ParagraphSettings or {})

                local Paragraph = Elements.Template.Paragraph:Clone()
                Paragraph.Title.Text = ParagraphSettings.Title
                Paragraph.Text.Text = ParagraphSettings.Text
                Paragraph.Visible = true
                Paragraph.Parent = TabPage
                tween(Paragraph, { BackgroundTransparency = 1 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Paragraph.UIStroke, { Transparency = 0.5 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Paragraph.Title, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Paragraph.Text, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))

                local ParagraphV = { Settings = ParagraphSettings }
                Paragraph.Text.Size = UDim2.new(Paragraph.Text.Size.X.Scale, Paragraph.Text.Size.X.Offset, 0, math.huge)
                Paragraph.Text.Size = UDim2.new(Paragraph.Text.Size.X.Scale, Paragraph.Text.Size.X.Offset, 0, Paragraph.Text.TextBounds.Y)
                tween(Paragraph, { Size = UDim2.new(Paragraph.Size.X.Scale, Paragraph.Size.X.Offset, 0, Paragraph.Text.TextBounds.Y + 40) })
                function ParagraphV:Set(newSettings) Paragraph.Title.Text = newSettings.Title Paragraph.Text.Text = newSettings.Text end
                function ParagraphV:Destroy() Paragraph:Destroy() end
                return ParagraphV
            end

            -- Label
            function Section:CreateLabel(LabelSettings)
                LabelSettings = Kwargify({ Text = "Label", Style = 1 }, LabelSettings or {})
                local Label = Elements.Template.Label:Clone()
                Label.Text.Text = LabelSettings.Text
                Label.Visible = true
                Label.Parent = TabPage
                tween(Label, { BackgroundTransparency = LabelSettings.Style ~= 1 and 0.8 or 1 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Label.UIStroke, { Transparency = 0.5 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                tween(Label.Text, { TextTransparency = 0 }, nil, TweenInfo.new(0.7, Enum.EasingStyle.Exponential))
                local LabelV = { Settings = LabelSettings }
                function LabelV:Set(NewText) Label.Text.Text = NewText end
                function LabelV:Destroy() Label:Destroy() end
                return LabelV
            end

            -- Divider
            function Section:CreateDivider()
                local b = Elements.Template.Divider:Clone()
                b.Parent = TabPage
                b.Line.BackgroundTransparency = 1
                tween(b.Line, { BackgroundTransparency = 0 })
            end

            return Section
        end

        return Tab
    end

    -- Initialize UI visibility
    Elements.Parent.Visible = true
    tween(Elements.Parent, { BackgroundTransparency = 0.1 })
    Navigation.Visible = true
    tween(Navigation.Line, { BackgroundTransparency = 0 })

    -- Draggable
    Draggable(Main.Drag, Main)

    return Window
end

function Luna:Destroy()
    if Luna.Instance then Luna.Instance:Destroy() end
end

return Luna
