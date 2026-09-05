local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local function getSafeParent()
    if gethui then
        return gethui()
    elseif game:GetService("CoreGui") then
        return game:GetService("CoreGui")
    end
    return game:GetService("Players").LocalPlayer.PlayerGui
end

if getSafeParent():FindFirstChild("IYPluginMaker") then
    getSafeParent().IYPluginMaker:Destroy()
end

-----/UI/-----
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IYPluginMaker"
ScreenGui.Parent = getSafeParent()
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 550)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 65)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local Dragging, DragInput, DragStart, StartPos

local function Update(input)
    local delta = input.Position - DragStart
    local newPos = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
    TweenService:Create(MainFrame, TweenInfo.new(0.05), {Position = newPos}):Play()
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if Dragging then Update(input) end
    end
end)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local BottomHider = Instance.new("Frame")
BottomHider.Size = UDim2.new(1, 0, 0, 10)
BottomHider.Position = UDim2.new(0, 0, 1, -10)
BottomHider.BorderSizePixel = 0
BottomHider.BackgroundColor3 = TopBar.BackgroundColor3
BottomHider.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "IY Plugin Maker V2"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Size = UDim2.new(0, 40, 1, 0)
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "×"
CloseButton.TextSize = 24
CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseButton.Font = Enum.Font.Gotham
CloseButton.Parent = TopBar
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Container = Instance.new("ScrollingFrame")
Container.Name = "Content"
Container.Size = UDim2.new(1, 0, 1, -40) 
Container.Position = UDim2.new(0, 0, 0, 40)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 4
Container.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Parent = Container
UIList.Padding = UDim.new(0, 15)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding")
UIPadding.Parent = Container
UIPadding.PaddingTop = UDim.new(0, 15)
UIPadding.PaddingBottom = UDim.new(0, 80)

-----/Create Inputs/-----
local function CreateInput(labelText, placeholder, height, multiLine, layoutOrder)
    local Wrapper = Instance.new("Frame")
    Wrapper.Name = "Input_" .. labelText
    Wrapper.Size = UDim2.new(0.9, 0, 0, height + 25) 
    Wrapper.BackgroundTransparency = 1
    Wrapper.LayoutOrder = layoutOrder
    Wrapper.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Text = labelText
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Wrapper
    
    local BoxFrame = Instance.new("Frame")
    BoxFrame.Size = UDim2.new(1, 0, 0, height)
    BoxFrame.Position = UDim2.new(0, 0, 0, 25)
    BoxFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    BoxFrame.BorderSizePixel = 0
    BoxFrame.Parent = Wrapper
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 6)
    BoxCorner.Parent = BoxFrame
    
    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Color = Color3.fromRGB(50, 50, 55)
    BoxStroke.Transparency = 0.5
    BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BoxStroke.Parent = BoxFrame

    local InputObject
    if multiLine then
        Wrapper.AutomaticSize = Enum.AutomaticSize.Y
        BoxFrame.AutomaticSize = Enum.AutomaticSize.Y
        
        InputObject = Instance.new("TextBox")
        InputObject.Size = UDim2.new(1, -16, 0, height)
        InputObject.Position = UDim2.new(0, 8, 0, 8)
        InputObject.AutomaticSize = Enum.AutomaticSize.Y
        InputObject.MultiLine = true
        InputObject.TextXAlignment = Enum.TextXAlignment.Left
        InputObject.TextYAlignment = Enum.TextYAlignment.Top
        
        local TextPadding = Instance.new("UIPadding")
        TextPadding.PaddingBottom = UDim.new(0, 8)
        TextPadding.Parent = BoxFrame
        InputObject.Parent = BoxFrame
    else
        InputObject = Instance.new("TextBox")
        InputObject.Size = UDim2.new(1, -16, 1, 0)
        InputObject.Position = UDim2.new(0, 8, 0, 0)
        InputObject.TextXAlignment = Enum.TextXAlignment.Left
        InputObject.Parent = BoxFrame
    end
    
    InputObject.BackgroundTransparency = 1
    InputObject.Text = ""
    InputObject.PlaceholderText = placeholder
    InputObject.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputObject.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    InputObject.Font = Enum.Font.Gotham
    InputObject.TextSize = 14
    
    InputObject.ClearTextOnFocus = false
    
    InputObject.Focused:Connect(function()
        TweenService:Create(BoxStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(100, 150, 255), Transparency = 0}):Play()
    end)
    InputObject.FocusLost:Connect(function()
        TweenService:Create(BoxStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(50, 50, 55), Transparency = 0.5}):Play()
    end)

    return InputObject
end

-----/Fields/-----
local inputs = {}
inputs.pluginName = CreateInput("Plugin Name", "SuperFly", 35, false, 1)
inputs.pluginDesc = CreateInput("Plugin Description", "Allows you to fly super fast", 35, false, 2)
inputs.cmdName = CreateInput("Command Name", "superfly", 35, false, 3)
inputs.aliases = CreateInput("Aliases", "sfly, fastfly", 35, false, 4)
inputs.cmdDesc = CreateInput("Command Description", "Enable super flight", 35, false, 5)
inputs.funcCode = CreateInput("Function (Lua Code)", "-- Type your code here\nlocal hum = speaker.Character.Humanoid...", 200, true, 6)

-----/Button/-----
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 60)
Footer.Position = UDim2.new(0, 0, 1, -60)
Footer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Footer.BorderSizePixel = 0
Footer.ZIndex = 5 
Footer.Parent = MainFrame

local FooterLine = Instance.new("Frame")
FooterLine.Size = UDim2.new(1, 0, 0, 1)
FooterLine.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
FooterLine.BorderSizePixel = 0
FooterLine.Parent = Footer

local GenerateBtn = Instance.new("TextButton")
GenerateBtn.Size = UDim2.new(1, -40, 0, 35)
GenerateBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
GenerateBtn.AnchorPoint = Vector2.new(0.5, 0.5)
GenerateBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
GenerateBtn.Text = "Save Plugin (.iy)"
GenerateBtn.Font = Enum.Font.GothamBold
GenerateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GenerateBtn.TextSize = 14
GenerateBtn.AutoButtonColor = true
GenerateBtn.Parent = Footer

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = GenerateBtn

GenerateBtn.MouseButton1Click:Connect(function()
    local name = inputs.pluginName.Text
    local desc = inputs.pluginDesc.Text
    local cmd = inputs.cmdName.Text
    local cmdD = inputs.cmdDesc.Text
    local aliasRaw = inputs.aliases.Text
    local code = inputs.funcCode.Text
    
    if name == "" or cmd == "" then
        if notify then notify("Plugin Creator: Name and Command are required.") end
        GenerateBtn.Text = "Error: Missing Fields!"
        wait(1)
        GenerateBtn.Text = "Export to Workspace (.iy)"
        return
    end

    local aliasFormatted = ""
    local count = 0
    for s in string.gmatch(aliasRaw, "([^,]+)") do
        local clean = s:gsub("^%s*", ""):gsub("%s*$", "")
        if clean ~= "" then
            aliasFormatted = aliasFormatted .. '"' .. clean .. '", '
            count = count + 1
        end
    end
    if count > 0 then
        aliasFormatted = aliasFormatted:sub(1, -3)
    end
    
    local listName = cmd
    if count > 0 then
        listName = cmd .. " / " .. aliasRaw:gsub(",", " /")
    end

    local finalStr = string.format(
[[local Plugin = {
    ["PluginName"] = "%s",
    ["PluginDescription"] = "%s",
    ["Commands"] = {
        ["%s"] = {
            ["ListName"] = "%s",
            ["Description"] = "%s",
            ["Aliases"] = {%s},
            ["Function"] = function(args, speaker)
%s
            end,
        },
    },
}

return Plugin]], 
    name, 
    desc, 
    cmd, 
    listName, 
    cmdD, 
    aliasFormatted, 
    code
    )
    
    local fileName = name .. ".iy"
    local success, err = pcall(function()
        writefile(fileName, finalStr)
    end)
    
    if success then
        if notify then
            notify("Plugin Saved: " .. fileName)
        end
        GenerateBtn.Text = "Success! Saved " .. fileName
        task.wait(2)
        GenerateBtn.Text = "Export to Workspace (.iy)"
    else
        warn("Writefile Error: ", err)
        if notify then notify("Plugin Creator Error: Check console") end
        GenerateBtn.Text = "Write Failed"
    end
end)

return "UI Loaded"
