-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui
local Holder
local TitleBar
local TitleText
local MoneyLabel
local MinimizeButton
local CloseButton
local AdminButton
local TabBar
local UpgradeTabButton
local ShopTabButton
local UpgradePage
local ShopPage
local InventoryLabel
local InventoryScroll
local InventoryLayout
local TargetLabel
local TargetScroll
local TargetLayout
local InfoBar
local BearLabel
local TargetInfoLabel
local ChanceLabel
local SellButton
local UpgradeButton
local ShopLabel
local ShopScroll
local ShopLayout
local NotificationHolder
local AdminPanel
local AdminCloseButton
local BearPicker
local BearPickerCloseButton
local BearPickerScroll
local BearPickerLayout
local UpgradeSound
local SelectedBearIndex = nil
local SelectedTargetId = nil
local IsMinimized = false
local IsRolling = false
local IsAdminAuthed = false
local ActiveTab = "upgrade"
local Currency = 1000
local LuckMultiplier = 1.0
local Connections = {}
local Inventory = {}

-----/Assets/-----
local MinimizeIcon = "rbxassetid://2406617031"
local CloseIcon = "rbxassetid://5054663650"

local UpgradeSoundId = "4718483268"

-----/Values/-----
local Colors = {
	Dark = Color3.fromRGB(36, 36, 37),
	Background = Color3.fromRGB(46, 46, 47),
	Button = Color3.fromRGB(78, 78, 79),
	Hover = Color3.fromRGB(95, 95, 96),
	Selected = Color3.fromRGB(70, 110, 70),
	Tab = Color3.fromRGB(30, 30, 31),
	White = Color3.fromRGB(255, 255, 255),
	Gray = Color3.fromRGB(180, 180, 180),
	Accent = Color3.fromRGB(120, 180, 120),
	Money = Color3.fromRGB(230, 200, 100),
	Danger = Color3.fromRGB(180, 90, 90),
	Admin = Color3.fromRGB(96, 116, 156),
	AdminHover = Color3.fromRGB(116, 136, 176),
	AdminDark = Color3.fromRGB(40, 41, 46),
}

local Bears = {
	["4807224885"] = 50,
	["10005005232"] = 75,
	["5511217343"] = 100,
	["5563184505"] = 150,
	["5067973789"] = 200,
	["5346908116"] = 250,
	["5117670810"] = 500,
	["5563188406"] = 750,
	["5630802542"] = 1000,
	["7742336085"] = 1500,
	["4813803052"] = 2000,
	["5511347255"] = 2500,
	["9077042087"] = 5000,
	["5630802995"] = 7500,
	["12887392169"] = 10000,
	["6001749167"] = 12500,
	["5511339536"] = 15000,
	["7851094473"] = 17500,
	["18806629643"] = 20000,
}

local StarterBears = {
	"4807224885",
	"4807224885",
	"4807224885",
}

local WindowConfig = {
	Size = UDim2.fromOffset(430, 360),
	TitleHeight = 26,
	TabHeight = 24,
}

local AdminConfig = {
	Size = UDim2.fromOffset(290, 280),
	PickerSize = UDim2.fromOffset(260, 260),
}

local AdminCode = "123Admin"

-----/Functions/-----
local RefreshInventory, RefreshTarget, RefreshShop, RefreshPicker, BuyBear, SellSelected, CreateBearTile
local OpenAdminPanel

local function Notify(Message : string, NotifType : string)
	local Notif = Instance.new("Frame")
	Notif.Name = "Notification"
	Notif.Size = UDim2.fromOffset(220, 36)
	Notif.Position = UDim2.new(1, -230, 1, -46)
	Notif.BackgroundColor3 = Colors.Background
	Notif.BorderSizePixel = 0
	Notif.Parent = NotificationHolder

	local Label = Instance.new("TextLabel")
	Label.Name = "Text"
	Label.Size = UDim2.new(1, -20, 1, 0)
	Label.Position = UDim2.fromOffset(10, 0)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.SourceSans
	Label.Text = Message
	Label.TextColor3 = NotifType == "error" and Colors.Danger or Colors.White
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Notif

	task.delay(2, function()
		local Fade = TweenService:Create(Notif, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
		Fade:Play()

		local TextFade = TweenService:Create(Label, TweenInfo.new(0.2), { TextTransparency = 1 })
		TextFade:Play()
		TextFade.Completed:Wait()

		Notif:Destroy()
	end)
end

local function UpdateMoney()
	if MoneyLabel then
		MoneyLabel.Text = "$" .. tostring(Currency)
	end
end

local function SetSelected(Tile : TextButton, Selected : boolean)
	Tile:SetAttribute("Selected", Selected)
	TweenService:Create(Tile, TweenInfo.new(0.1), {
		BackgroundColor3 = Selected and Colors.Selected or Colors.Button,
	}):Play()
end

local function UpdateInfo()
	if SelectedBearIndex and Inventory[SelectedBearIndex] then
		local BearId = Inventory[SelectedBearIndex]
		BearLabel.Text = "Bear : $" .. tostring(Bears[BearId])
	else
		BearLabel.Text = "Bear : —"
	end

	if SelectedTargetId then
		TargetInfoLabel.Text = "Target : $" .. tostring(Bears[SelectedTargetId])
	else
		TargetInfoLabel.Text = "Target : —"
	end

	if SelectedBearIndex and SelectedTargetId then
		local BearPrice = Bears[Inventory[SelectedBearIndex]]
		local TargetPrice = Bears[SelectedTargetId]
		local RawChance = BearPrice / TargetPrice * 100 * LuckMultiplier
		local Chance = math.clamp(RawChance, 1, 99)
		local LuckTag = LuckMultiplier > 1 and string.format(" (x%.1f)", LuckMultiplier) or ""
		ChanceLabel.Text = string.format("Chance : %.1f%%%s", Chance, LuckTag)
	else
		ChanceLabel.Text = "Chance : —"
	end
end

local function RefreshSelection()
	if not InventoryScroll or not TargetScroll then return end

	for _, Tile in ipairs(InventoryScroll:GetChildren()) do
		if Tile:IsA("TextButton") then
			local Index = Tile:GetAttribute("InventoryIndex")
			SetSelected(Tile, Index == SelectedBearIndex)
		end
	end

	for _, Tile in ipairs(TargetScroll:GetChildren()) do
		if Tile:IsA("TextButton") then
			local Id = Tile:GetAttribute("BearId")
			SetSelected(Tile, Id == SelectedTargetId)
		end
	end
end

CreateBearTile = function(BearId : string, Price : number, Panel : string, Key : any, Parent : Instance)
	local Tile = Instance.new("TextButton")
	Tile.Name = "Tile"
	Tile.Size = UDim2.fromOffset(62, 70)
	Tile.BackgroundColor3 = Colors.Button
	Tile.BorderSizePixel = 0
	Tile.AutoButtonColor = false
	Tile.Text = ""
	Tile:SetAttribute("BearId", BearId)
	Tile:SetAttribute("Panel", Panel)
	Tile:SetAttribute("Selected", false)

	if type(Key) == "number" then
		Tile:SetAttribute("InventoryIndex", Key)
	end

	Tile.Parent = Parent

	local Icon = Instance.new("ImageLabel")
	Icon.Name = "Icon"
	Icon.Size = UDim2.new(1, -8, 0, 46)
	Icon.Position = UDim2.fromOffset(4, 4)
	Icon.BackgroundTransparency = 1
	Icon.Image = "rbxassetid://" .. BearId
	Icon.ScaleType = Enum.ScaleType.Fit
	Icon.Parent = Tile

	local PriceLabel = Instance.new("TextLabel")
	PriceLabel.Name = "Price"
	PriceLabel.Size = UDim2.new(1, 0, 0, 16)
	PriceLabel.Position = UDim2.new(0, 0, 1, -18)
	PriceLabel.BackgroundTransparency = 1
	PriceLabel.Font = Enum.Font.SourceSans
	PriceLabel.Text = "$" .. tostring(Price)
	PriceLabel.TextColor3 = Colors.White
	PriceLabel.TextSize = 14
	PriceLabel.Parent = Tile

	Tile.MouseEnter:Connect(function()
		if Tile:GetAttribute("Selected") then return end

		TweenService:Create(Tile, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
	end)

	Tile.MouseLeave:Connect(function()
		if Tile:GetAttribute("Selected") then return end

		TweenService:Create(Tile, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
	end)

	Tile.MouseButton1Click:Connect(function()
		if IsRolling then return end

		if Panel == "inventory" then
			SelectedBearIndex = Key
			RefreshSelection()
			UpdateInfo()
		elseif Panel == "target" then
			SelectedTargetId = BearId
			RefreshSelection()
			UpdateInfo()
		elseif Panel == "shop" then
			BuyBear(BearId)
		elseif Panel == "picker" then
			table.insert(Inventory, BearId)
			Notify("Given : $" .. tostring(Bears[BearId]) .. " bear", "success")
			RefreshInventory()
			BearPicker.Visible = false
		end
	end)

	return Tile
end

RefreshInventory = function()
	if not InventoryScroll then return end

	for _, Child in ipairs(InventoryScroll:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end

	for Index, BearId in ipairs(Inventory) do
		CreateBearTile(BearId, Bears[BearId], "inventory", Index, InventoryScroll)
	end

	RefreshSelection()
end

RefreshTarget = function()
	if not TargetScroll then return end

	for _, Child in ipairs(TargetScroll:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end

	local SortedIds = {}

	for Id in pairs(Bears) do
		table.insert(SortedIds, Id)
	end

	table.sort(SortedIds, function(A, B)
		return Bears[A] < Bears[B]
	end)

	for _, BearId in ipairs(SortedIds) do
		CreateBearTile(BearId, Bears[BearId], "target", BearId, TargetScroll)
	end

	RefreshSelection()
end

RefreshShop = function()
	if not ShopScroll then return end

	for _, Child in ipairs(ShopScroll:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end

	local SortedIds = {}

	for Id in pairs(Bears) do
		table.insert(SortedIds, Id)
	end

	table.sort(SortedIds, function(A, B)
		return Bears[A] < Bears[B]
	end)

	for _, BearId in ipairs(SortedIds) do
		CreateBearTile(BearId, Bears[BearId], "shop", BearId, ShopScroll)
	end
end

RefreshPicker = function()
	if not BearPickerScroll then return end

	for _, Child in ipairs(BearPickerScroll:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end

	local SortedIds = {}

	for Id in pairs(Bears) do
		table.insert(SortedIds, Id)
	end

	table.sort(SortedIds, function(A, B)
		return Bears[A] < Bears[B]
	end)

	for _, BearId in ipairs(SortedIds) do
		CreateBearTile(BearId, Bears[BearId], "picker", BearId, BearPickerScroll)
	end
end

BuyBear = function(BearId : string)
	if IsRolling then return end

	local Price = Bears[BearId]

	if not Price then return end

	if Currency < Price then
		Notify("Not enough money", "error")

		return
	end

	Currency = Currency - Price
	table.insert(Inventory, BearId)
	Notify("Bought : $" .. tostring(Price) .. " bear", "success")
	UpdateMoney()
	RefreshInventory()
end

SellSelected = function()
	if IsRolling then return end

	if not SelectedBearIndex or not Inventory[SelectedBearIndex] then
		Notify("Select a bear to sell", "error")

		return
	end

	local BearId = Inventory[SelectedBearIndex]
	local Price = Bears[BearId]

	Currency = Currency + Price
	table.remove(Inventory, SelectedBearIndex)
	SelectedBearIndex = nil

	Notify("Sold : $" .. tostring(Price), "success")
	UpdateMoney()
	RefreshInventory()
	UpdateInfo()
end

local function PerformUpgrade()
	if IsRolling then return end

	if not SelectedBearIndex or not SelectedTargetId then
		Notify("Select a bear and target first", "error")

		return
	end

	local BearId = Inventory[SelectedBearIndex]
	local BearPrice = Bears[BearId]
	local TargetPrice = Bears[SelectedTargetId]

	if BearPrice >= TargetPrice then
		Notify("Target must be more valuable", "error")

		return
	end

	IsRolling = true
	UpgradeButton.Text = "ROLLING..."
	UpgradeButton.BackgroundColor3 = Colors.Button

	if UpgradeSound and UpgradeSound.SoundId ~= "" then
		UpgradeSound:Play()
	end

	local Chance = math.clamp(BearPrice / TargetPrice * LuckMultiplier, 0.01, 0.99)
	local Win = math.random() < Chance

	task.wait(0.9)

	table.remove(Inventory, SelectedBearIndex)
	SelectedBearIndex = nil

	if Win then
		table.insert(Inventory, SelectedTargetId)
		Notify("Won : $" .. tostring(TargetPrice) .. " bear", "success")
		print("🟢 | Successfully : Upgrade won")
	else
		Notify("Lost : $" .. tostring(BearPrice) .. " bear", "error")
		print("🔴 | Error : Upgrade lost")
	end

	IsRolling = false
	UpgradeButton.Text = "UPGRADE"
	RefreshInventory()
	UpdateInfo()
end

local function SetupDragging(DragFrame : GuiObject, Handle : GuiObject)
	local DragStart = nil
	local StartPosition = nil
	local IsDraggingLocal = false

	table.insert(Connections, Handle.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			IsDraggingLocal = true
			DragStart = Input.Position
			StartPosition = DragFrame.Position
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input)
		if not IsDraggingLocal or not DragStart then return end

		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			local Delta = Input.Position - DragStart
			DragFrame.Position = UDim2.new(
				StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
				StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
			)
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			IsDraggingLocal = false
			DragStart = nil
		end
	end))
end

local function SetTab(Tab : string)
	ActiveTab = Tab

	if Tab == "upgrade" then
		UpgradePage.Visible = true
		ShopPage.Visible = false
		UpgradeTabButton.BackgroundColor3 = Colors.Background
		ShopTabButton.BackgroundColor3 = Colors.Tab
		UpgradeTabButton.TextColor3 = Colors.White
		ShopTabButton.TextColor3 = Colors.Gray
	else
		UpgradePage.Visible = false
		ShopPage.Visible = true
		UpgradeTabButton.BackgroundColor3 = Colors.Tab
		ShopTabButton.BackgroundColor3 = Colors.Background
		UpgradeTabButton.TextColor3 = Colors.Gray
		ShopTabButton.TextColor3 = Colors.White
	end
end

local function CreateInputBox(Parent : Instance, Position : UDim2, Size : UDim2, Placeholder : string, Default : string)
	local Box = Instance.new("TextBox")
	Box.Size = Size
	Box.Position = Position
	Box.BackgroundColor3 = Colors.Dark
	Box.BorderSizePixel = 0
	Box.Font = Enum.Font.SourceSans
	Box.PlaceholderText = Placeholder
	Box.Text = Default or ""
	Box.TextColor3 = Colors.White
	Box.PlaceholderColor3 = Colors.Gray
	Box.TextSize = 13
	Box.TextXAlignment = Enum.TextXAlignment.Left
	Box.ClearTextOnFocus = false
	Box.Parent = Parent

	local Pad = Instance.new("UIPadding")
	Pad.PaddingLeft = UDim.new(0, 6)
	Pad.Parent = Box

	return Box
end

local function CreateAdminButton(Parent : Instance, Position : UDim2, Size : UDim2, Text : string, Color : Color3)
	local Button = Instance.new("TextButton")
	Button.Size = Size
	Button.Position = Position
	Button.BackgroundColor3 = Color or Colors.Button
	Button.BorderSizePixel = 0
	Button.Font = Enum.Font.SourceSansSemibold
	Button.Text = Text
	Button.TextColor3 = Colors.White
	Button.TextSize = 13
	Button.AutoButtonColor = false
	Button.Parent = Parent

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), { BackgroundColor3 = Color or Colors.Button }):Play()
	end)

	return Button
end

OpenAdminPanel = function()
	if IsAdminAuthed then
		AdminPanel.Visible = not AdminPanel.Visible

		return
	end

	local Prompt = Instance.new("Frame")
	Prompt.Name = "AdminPrompt"
	Prompt.Size = UDim2.fromOffset(240, 116)
	Prompt.Position = UDim2.new(0.5, -120, 0.5, -58)
	Prompt.BackgroundColor3 = Colors.AdminDark
	Prompt.BorderSizePixel = 0
	Prompt.ZIndex = 30
	Prompt.Parent = ScreenGui

	local PromptTitle = Instance.new("TextLabel")
	PromptTitle.Size = UDim2.new(1, 0, 0, 24)
	PromptTitle.BackgroundColor3 = Colors.Admin
	PromptTitle.BorderSizePixel = 0
	PromptTitle.Font = Enum.Font.SourceSansSemibold
	PromptTitle.Text = "ADMIN ACCESS"
	PromptTitle.TextColor3 = Colors.White
	PromptTitle.TextSize = 14
	PromptTitle.ZIndex = 31
	PromptTitle.Parent = Prompt

	local PromptInput = CreateInputBox(Prompt, UDim2.fromOffset(12, 36), UDim2.new(1, -24, 0, 28), "Enter code...", "")
	PromptInput.ZIndex = 31

	local ConfirmBtn = CreateAdminButton(Prompt, UDim2.fromOffset(12, 76), UDim2.new(0.5, -18, 0, 26), "OK", Colors.Admin)
	ConfirmBtn.ZIndex = 31

	local CancelBtn = CreateAdminButton(Prompt, UDim2.new(0.5, 6, 0, 76), UDim2.new(0.5, -18, 0, 26), "Cancel", Colors.Button)
	CancelBtn.ZIndex = 31

	local function TrySubmit()
		if PromptInput.Text == AdminCode then
			IsAdminAuthed = true
			
			Notify("Admin access granted", "success")
			
			AdminPanel.Visible = true
			
			Prompt:Destroy()
		else
			Notify("Wrong code", "error")
			PromptInput.Text = ""
		end
	end

	ConfirmBtn.MouseButton1Click:Connect(TrySubmit)
	PromptInput.FocusLost:Connect(function(EnterPressed)
		if EnterPressed then TrySubmit() end
	end)
	CancelBtn.MouseButton1Click:Connect(function()
		Prompt:Destroy()
	end)
end

-----/Admin Panel/-----
AdminPanel = Instance.new("Frame")
AdminPanel.Name = "AdminPanel"
AdminPanel.Size = AdminConfig.Size
AdminPanel.Position = UDim2.new(1, -300, 0.5, -AdminConfig.Size.Y.Offset / 2)
AdminPanel.BackgroundColor3 = Colors.AdminDark
AdminPanel.BorderSizePixel = 0
AdminPanel.Visible = false
AdminPanel.ZIndex = 20

local AdminTitle = Instance.new("TextLabel")
AdminTitle.Size = UDim2.new(1, 0, 0, 24)
AdminTitle.BackgroundColor3 = Colors.Admin
AdminTitle.BorderSizePixel = 0
AdminTitle.Font = Enum.Font.SourceSansSemibold
AdminTitle.Text = "ADMIN PANEL"
AdminTitle.TextColor3 = Colors.White
AdminTitle.TextSize = 14
AdminTitle.ZIndex = 21
AdminTitle.Parent = AdminPanel

AdminCloseButton = Instance.new("ImageButton")
AdminCloseButton.Name = "AdminCloseButton"
AdminCloseButton.Size = UDim2.fromOffset(10, 10)
AdminCloseButton.Position = UDim2.new(1, -18, 0, 7)
AdminCloseButton.BackgroundTransparency = 1
AdminCloseButton.Image = CloseIcon
AdminCloseButton.ImageColor3 = Colors.White
AdminCloseButton.AutoButtonColor = false
AdminCloseButton.ZIndex = 22
AdminCloseButton.Parent = AdminPanel
AdminCloseButton.MouseButton1Click:Connect(function()
	AdminPanel.Visible = false
end)

local MoneyHeader = Instance.new("TextLabel")
MoneyHeader.Size = UDim2.new(1, -20, 0, 16)
MoneyHeader.Position = UDim2.fromOffset(10, 30)
MoneyHeader.BackgroundTransparency = 1
MoneyHeader.Font = Enum.Font.SourceSansSemibold
MoneyHeader.Text = "Money"
MoneyHeader.TextColor3 = Colors.Money
MoneyHeader.TextSize = 13
MoneyHeader.TextXAlignment = Enum.TextXAlignment.Left
MoneyHeader.ZIndex = 21
MoneyHeader.Parent = AdminPanel

local MoneyInput = CreateInputBox(AdminPanel, UDim2.fromOffset(10, 48), UDim2.new(0, 160, 0, 22), "amount", "1000")
MoneyInput.ZIndex = 21

local GiveMoneyBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(178, 48), UDim2.fromOffset(50, 22), "Give", Colors.Selected)
GiveMoneyBtn.ZIndex = 21

local SetMoneyBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(232, 48), UDim2.fromOffset(48, 22), "Set", Colors.Button)
SetMoneyBtn.ZIndex = 21

local LuckHeader = Instance.new("TextLabel")
LuckHeader.Size = UDim2.new(1, -20, 0, 16)
LuckHeader.Position = UDim2.fromOffset(10, 78)
LuckHeader.BackgroundTransparency = 1
LuckHeader.Font = Enum.Font.SourceSansSemibold
LuckHeader.Text = "Luck Multiplier"
LuckHeader.TextColor3 = Colors.Accent
LuckHeader.TextSize = 13
LuckHeader.TextXAlignment = Enum.TextXAlignment.Left
LuckHeader.ZIndex = 21
LuckHeader.Parent = AdminPanel

local LuckInput = CreateInputBox(AdminPanel, UDim2.fromOffset(10, 96), UDim2.new(0, 150, 0, 22), "multiplier", tostring(LuckMultiplier))
LuckInput.ZIndex = 21

local SetLuckBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(164, 96), UDim2.fromOffset(55, 22), "Set", Colors.Selected)
SetLuckBtn.ZIndex = 21

local ResetLuckBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(223, 96), UDim2.fromOffset(57, 22), "Reset", Colors.Button)
ResetLuckBtn.ZIndex = 21

SetLuckBtn.MouseButton1Click:Connect(function()
	local Value = tonumber(LuckInput.Text)

	if not Value or Value < 0.1 then
		Notify("Invalid luck value", "error")

		return
	end

	LuckMultiplier = Value
	Notify("Luck set to x" .. tostring(Value), "success")
	UpdateInfo()
end)

ResetLuckBtn.MouseButton1Click:Connect(function()
	LuckMultiplier = 1.0
	LuckInput.Text = "1"
	Notify("Luck reset", "success")
	UpdateInfo()
end)

local GiveHeader = Instance.new("TextLabel")
GiveHeader.Size = UDim2.new(1, -20, 0, 16)
GiveHeader.Position = UDim2.fromOffset(10, 126)
GiveHeader.BackgroundTransparency = 1
GiveHeader.Font = Enum.Font.SourceSansSemibold
GiveHeader.Text = "Give Bear"
GiveHeader.TextColor3 = Colors.Accent
GiveHeader.TextSize = 13
GiveHeader.TextXAlignment = Enum.TextXAlignment.Left
GiveHeader.ZIndex = 21
GiveHeader.Parent = AdminPanel

local GiveBearBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(10, 144), UDim2.new(1, -20, 0, 22), "Open Bear List", Colors.Selected)
GiveBearBtn.ZIndex = 21

GiveBearBtn.MouseButton1Click:Connect(function()
	BearPicker.Visible = not BearPicker.Visible

	if BearPicker.Visible then
		RefreshPicker()
	end
end)

local DupHeader = Instance.new("TextLabel")
DupHeader.Size = UDim2.new(1, -20, 0, 16)
DupHeader.Position = UDim2.fromOffset(10, 174)
DupHeader.BackgroundTransparency = 1
DupHeader.Font = Enum.Font.SourceSansSemibold
DupHeader.Text = "Duplicate"
DupHeader.TextColor3 = Colors.White
DupHeader.TextSize = 13
DupHeader.TextXAlignment = Enum.TextXAlignment.Left
DupHeader.ZIndex = 21
DupHeader.Parent = AdminPanel

local DupSelectedBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(10, 192), UDim2.fromOffset(132, 22), "Dup Selected", Colors.Button)
DupSelectedBtn.ZIndex = 21

local DupAllBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(148, 192), UDim2.fromOffset(132, 22), "Dup All", Colors.Button)
DupAllBtn.ZIndex = 21

DupSelectedBtn.MouseButton1Click:Connect(function()
	if not SelectedBearIndex or not Inventory[SelectedBearIndex] then
		Notify("Select a bear first", "error")

		return
	end

	local BearId = Inventory[SelectedBearIndex]
	table.insert(Inventory, BearId)
	Notify("Duplicated : $" .. tostring(Bears[BearId]), "success")
	RefreshInventory()
end)

DupAllBtn.MouseButton1Click:Connect(function()
	local Copy = {}

	for _, Id in ipairs(Inventory) do
		table.insert(Copy, Id)
	end

	for _, Id in ipairs(Copy) do
		table.insert(Inventory, Id)
	end

	Notify("Duplicated all bears (" .. tostring(#Copy) .. ")", "success")
	RefreshInventory()
end)

local DangerHeader = Instance.new("TextLabel")
DangerHeader.Size = UDim2.new(1, -20, 0, 16)
DangerHeader.Position = UDim2.fromOffset(10, 222)
DangerHeader.BackgroundTransparency = 1
DangerHeader.Font = Enum.Font.SourceSansSemibold
DangerHeader.Text = "Danger Zone"
DangerHeader.TextColor3 = Colors.Danger
DangerHeader.TextSize = 13
DangerHeader.TextXAlignment = Enum.TextXAlignment.Left
DangerHeader.ZIndex = 21
DangerHeader.Parent = AdminPanel

local ClearInvBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(10, 240), UDim2.fromOffset(132, 22), "Clear Inv", Colors.Button)
ClearInvBtn.ZIndex = 21

local MaxOutBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(148, 240), UDim2.fromOffset(132, 22), "Max Out", Colors.Button)
MaxOutBtn.ZIndex = 21

ClearInvBtn.MouseButton1Click:Connect(function()
	table.clear(Inventory)
	SelectedBearIndex = nil
	Notify("Inventory cleared", "success")
	RefreshInventory()
	UpdateInfo()
end)

MaxOutBtn.MouseButton1Click:Connect(function()
	table.clear(Inventory)

	local SortedIds = {}

	for Id in pairs(Bears) do
		table.insert(SortedIds, Id)
	end

	table.sort(SortedIds, function(A, B)
		return Bears[A] < Bears[B]
	end)

	for _, Id in ipairs(SortedIds) do
		table.insert(Inventory, Id)
		table.insert(Inventory, Id)
		table.insert(Inventory, Id)
	end

	Notify("Maxed out inventory", "success")
	RefreshInventory()
end)

SetupDragging(AdminPanel, AdminTitle)

BearPicker = Instance.new("Frame")
BearPicker.Name = "BearPicker"
BearPicker.Size = AdminConfig.PickerSize
BearPicker.Position = UDim2.new(0.5, -AdminConfig.PickerSize.X.Offset / 2, 0.5, -AdminConfig.PickerSize.Y.Offset / 2)
BearPicker.BackgroundColor3 = Colors.AdminDark
BearPicker.BorderSizePixel = 0
BearPicker.Visible = false
BearPicker.ZIndex = 25

local PickerTitle = Instance.new("TextLabel")
PickerTitle.Size = UDim2.new(1, 0, 0, 24)
PickerTitle.BackgroundColor3 = Colors.Admin
PickerTitle.BorderSizePixel = 0
PickerTitle.Font = Enum.Font.SourceSansSemibold
PickerTitle.Text = "SELECT BEAR"
PickerTitle.TextColor3 = Colors.White
PickerTitle.TextSize = 14
PickerTitle.ZIndex = 26
PickerTitle.Parent = BearPicker

BearPickerCloseButton = Instance.new("ImageButton")
BearPickerCloseButton.Name = "BearPickerCloseButton"
BearPickerCloseButton.Size = UDim2.fromOffset(10, 10)
BearPickerCloseButton.Position = UDim2.new(1, -18, 0, 7)
BearPickerCloseButton.BackgroundTransparency = 1
BearPickerCloseButton.Image = CloseIcon
BearPickerCloseButton.ImageColor3 = Colors.White
BearPickerCloseButton.AutoButtonColor = false
BearPickerCloseButton.ZIndex = 27
BearPickerCloseButton.Parent = BearPicker
BearPickerCloseButton.MouseButton1Click:Connect(function()
	BearPicker.Visible = false
end)

BearPickerScroll = Instance.new("ScrollingFrame")
BearPickerScroll.Name = "BearPickerScroll"
BearPickerScroll.Size = UDim2.new(1, -12, 1, -32)
BearPickerScroll.Position = UDim2.fromOffset(6, 26)
BearPickerScroll.BackgroundColor3 = Colors.Dark
BearPickerScroll.BorderSizePixel = 0
BearPickerScroll.ScrollBarThickness = 4
BearPickerScroll.ScrollBarImageColor3 = Colors.Button
BearPickerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
BearPickerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
BearPickerScroll.ScrollingDirection = Enum.ScrollingDirection.Y
BearPickerScroll.ZIndex = 26
BearPickerScroll.Parent = BearPicker

BearPickerLayout = Instance.new("UIGridLayout")
BearPickerLayout.CellSize = UDim2.fromOffset(62, 70)
BearPickerLayout.CellPadding = UDim2.fromOffset(4, 4)
BearPickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
BearPickerLayout.Parent = BearPickerScroll

local PickerPadding = Instance.new("UIPadding")
PickerPadding.PaddingLeft = UDim.new(0, 4)
PickerPadding.PaddingTop = UDim.new(0, 4)
PickerPadding.PaddingRight = UDim.new(0, 4)
PickerPadding.PaddingBottom = UDim.new(0, 4)
PickerPadding.Parent = BearPickerScroll

SetupDragging(BearPicker, PickerTitle)

-----/Main/-----
local Existing = PlayerGui:FindFirstChild("UpgraderUI")

if Existing then
	Existing:Destroy()
end

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UpgraderUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

AdminPanel.Parent = ScreenGui
BearPicker.Parent = ScreenGui

UpgradeSound = Instance.new("Sound")
UpgradeSound.Name = "UpgradeSound"
UpgradeSound.SoundId = UpgradeSoundId
UpgradeSound.Volume = 1
UpgradeSound.Parent = ScreenGui

NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "Notifications"
NotificationHolder.Size = UDim2.fromScale(1, 1)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = ScreenGui

Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = WindowConfig.Size
Holder.Position = UDim2.new(0, 20, 0.5, -WindowConfig.Size.Y.Offset / 2)
Holder.BackgroundColor3 = Colors.Background
Holder.BorderSizePixel = 0
Holder.Parent = ScreenGui

TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, WindowConfig.TitleHeight)
TitleBar.BackgroundColor3 = Colors.Dark
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Holder

TitleText = Instance.new("TextLabel")
TitleText.Name = "TitleText"
TitleText.Size = UDim2.new(1, -240, 1, 0)
TitleText.Position = UDim2.fromOffset(8, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.SourceSans
TitleText.Text = "Upgrader"
TitleText.TextColor3 = Colors.White
TitleText.TextSize = 16
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

AdminButton = Instance.new("TextButton")
AdminButton.Name = "AdminButton"
AdminButton.Size = UDim2.fromOffset(50, 16)
AdminButton.Position = UDim2.new(1, -175, 0, 5)
AdminButton.BackgroundColor3 = Colors.Admin
AdminButton.BorderSizePixel = 0
AdminButton.Font = Enum.Font.SourceSansBold
AdminButton.Text = "ADMIN"
AdminButton.TextColor3 = Colors.White
AdminButton.TextSize = 11
AdminButton.AutoButtonColor = false
AdminButton.Parent = TitleBar

MoneyLabel = Instance.new("TextLabel")
MoneyLabel.Name = "MoneyLabel"
MoneyLabel.Size = UDim2.new(0, 110, 1, 0)
MoneyLabel.Position = UDim2.new(1, -162, 0, 0)
MoneyLabel.BackgroundTransparency = 1
MoneyLabel.Font = Enum.Font.SourceSansSemibold
MoneyLabel.Text = "$" .. tostring(Currency)
MoneyLabel.TextColor3 = Colors.Money
MoneyLabel.TextSize = 15
MoneyLabel.TextXAlignment = Enum.TextXAlignment.Right
MoneyLabel.Parent = TitleBar

MinimizeButton = Instance.new("ImageButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.fromOffset(10, 10)
MinimizeButton.Position = UDim2.new(1, -36, 0, 8)
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Image = MinimizeIcon
MinimizeButton.ImageColor3 = Colors.Gray
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = TitleBar

CloseButton = Instance.new("ImageButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(10, 10)
CloseButton.Position = UDim2.new(1, -18, 0, 8)
CloseButton.BackgroundTransparency = 1
CloseButton.Image = CloseIcon
CloseButton.ImageColor3 = Colors.Gray
CloseButton.AutoButtonColor = false
CloseButton.Parent = TitleBar

TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, WindowConfig.TabHeight)
TabBar.Position = UDim2.fromOffset(0, WindowConfig.TitleHeight)
TabBar.BackgroundColor3 = Colors.Tab
TabBar.BorderSizePixel = 0
TabBar.Parent = Holder

UpgradeTabButton = Instance.new("TextButton")
UpgradeTabButton.Name = "UpgradeTab"
UpgradeTabButton.Size = UDim2.fromOffset(90, WindowConfig.TabHeight)
UpgradeTabButton.Position = UDim2.fromOffset(0, 0)
UpgradeTabButton.BackgroundColor3 = Colors.Background
UpgradeTabButton.BorderSizePixel = 0
UpgradeTabButton.Font = Enum.Font.SourceSansSemibold
UpgradeTabButton.Text = "Upgrade"
UpgradeTabButton.TextColor3 = Colors.White
UpgradeTabButton.TextSize = 14
UpgradeTabButton.AutoButtonColor = false
UpgradeTabButton.Parent = TabBar

ShopTabButton = Instance.new("TextButton")
ShopTabButton.Name = "ShopTab"
ShopTabButton.Size = UDim2.fromOffset(90, WindowConfig.TabHeight)
ShopTabButton.Position = UDim2.fromOffset(90, 0)
ShopTabButton.BackgroundColor3 = Colors.Tab
ShopTabButton.BorderSizePixel = 0
ShopTabButton.Font = Enum.Font.SourceSansSemibold
ShopTabButton.Text = "Shop"
ShopTabButton.TextColor3 = Colors.Gray
ShopTabButton.TextSize = 14
ShopTabButton.AutoButtonColor = false
ShopTabButton.Parent = TabBar

UpgradePage = Instance.new("Frame")
UpgradePage.Name = "UpgradePage"
UpgradePage.Size = UDim2.new(1, 0, 1, -(WindowConfig.TitleHeight + WindowConfig.TabHeight))
UpgradePage.Position = UDim2.fromOffset(0, WindowConfig.TitleHeight + WindowConfig.TabHeight)
UpgradePage.BackgroundTransparency = 1
UpgradePage.Parent = Holder

InventoryLabel = Instance.new("TextLabel")
InventoryLabel.Name = "InventoryLabel"
InventoryLabel.Size = UDim2.new(1, -16, 0, 18)
InventoryLabel.Position = UDim2.fromOffset(8, 6)
InventoryLabel.BackgroundTransparency = 1
InventoryLabel.Font = Enum.Font.SourceSans
InventoryLabel.Text = "Inventory"
InventoryLabel.TextColor3 = Colors.Gray
InventoryLabel.TextSize = 14
InventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
InventoryLabel.Parent = UpgradePage

InventoryScroll = Instance.new("ScrollingFrame")
InventoryScroll.Name = "InventoryScroll"
InventoryScroll.Size = UDim2.new(1, -16, 0, 88)
InventoryScroll.Position = UDim2.fromOffset(8, 26)
InventoryScroll.BackgroundColor3 = Colors.Dark
InventoryScroll.BorderSizePixel = 0
InventoryScroll.ScrollBarThickness = 4
InventoryScroll.ScrollBarImageColor3 = Colors.Button
InventoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
InventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
InventoryScroll.ScrollingDirection = Enum.ScrollingDirection.X
InventoryScroll.Parent = UpgradePage

InventoryLayout = Instance.new("UIListLayout")
InventoryLayout.FillDirection = Enum.FillDirection.Horizontal
InventoryLayout.Padding = UDim.new(0, 4)
InventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
InventoryLayout.Parent = InventoryScroll

local InventoryPadding = Instance.new("UIPadding")
InventoryPadding.PaddingLeft = UDim.new(0, 4)
InventoryPadding.PaddingTop = UDim.new(0, 4)
InventoryPadding.PaddingRight = UDim.new(0, 4)
InventoryPadding.Parent = InventoryScroll

TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "TargetLabel"
TargetLabel.Size = UDim2.new(1, -16, 0, 18)
TargetLabel.Position = UDim2.fromOffset(8, 120)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Font = Enum.Font.SourceSans
TargetLabel.Text = "Target"
TargetLabel.TextColor3 = Colors.Gray
TargetLabel.TextSize = 14
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = UpgradePage

TargetScroll = Instance.new("ScrollingFrame")
TargetScroll.Name = "TargetScroll"
TargetScroll.Size = UDim2.new(1, -16, 0, 88)
TargetScroll.Position = UDim2.fromOffset(8, 140)
TargetScroll.BackgroundColor3 = Colors.Dark
TargetScroll.BorderSizePixel = 0
TargetScroll.ScrollBarThickness = 4
TargetScroll.ScrollBarImageColor3 = Colors.Button
TargetScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TargetScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
TargetScroll.ScrollingDirection = Enum.ScrollingDirection.X
TargetScroll.Parent = UpgradePage

TargetLayout = Instance.new("UIListLayout")
TargetLayout.FillDirection = Enum.FillDirection.Horizontal
TargetLayout.Padding = UDim.new(0, 4)
TargetLayout.SortOrder = Enum.SortOrder.LayoutOrder
TargetLayout.Parent = TargetScroll

local TargetPadding = Instance.new("UIPadding")
TargetPadding.PaddingLeft = UDim.new(0, 4)
TargetPadding.PaddingTop = UDim.new(0, 4)
TargetPadding.PaddingRight = UDim.new(0, 4)
TargetPadding.Parent = TargetScroll

InfoBar = Instance.new("Frame")
InfoBar.Name = "InfoBar"
InfoBar.Size = UDim2.new(1, -16, 0, 22)
InfoBar.Position = UDim2.new(0, 8, 1, -64)
InfoBar.BackgroundColor3 = Colors.Dark
InfoBar.BorderSizePixel = 0
InfoBar.Parent = UpgradePage

BearLabel = Instance.new("TextLabel")
BearLabel.Name = "BearLabel"
BearLabel.Size = UDim2.new(1 / 3, 0, 1, 0)
BearLabel.BackgroundTransparency = 1
BearLabel.Font = Enum.Font.SourceSans
BearLabel.Text = "Bear : —"
BearLabel.TextColor3 = Colors.White
BearLabel.TextSize = 14
BearLabel.Parent = InfoBar

TargetInfoLabel = Instance.new("TextLabel")
TargetInfoLabel.Name = "TargetInfoLabel"
TargetInfoLabel.Size = UDim2.new(1 / 3, 0, 1, 0)
TargetInfoLabel.Position = UDim2.new(1 / 3, 0, 0, 0)
TargetInfoLabel.BackgroundTransparency = 1
TargetInfoLabel.Font = Enum.Font.SourceSans
TargetInfoLabel.Text = "Target : —"
TargetInfoLabel.TextColor3 = Colors.White
TargetInfoLabel.TextSize = 14
TargetInfoLabel.Parent = InfoBar

ChanceLabel = Instance.new("TextLabel")
ChanceLabel.Name = "ChanceLabel"
ChanceLabel.Size = UDim2.new(1 / 3, 0, 1, 0)
ChanceLabel.Position = UDim2.new(2 / 3, 0, 0, 0)
ChanceLabel.BackgroundTransparency = 1
ChanceLabel.Font = Enum.Font.SourceSans
ChanceLabel.Text = "Chance : —"
ChanceLabel.TextColor3 = Colors.Accent
ChanceLabel.TextSize = 14
ChanceLabel.Parent = InfoBar

SellButton = Instance.new("TextButton")
SellButton.Name = "SellButton"
SellButton.Size = UDim2.new(0, 70, 0, 28)
SellButton.Position = UDim2.new(0, 8, 1, -36)
SellButton.BackgroundColor3 = Colors.Button
SellButton.BorderSizePixel = 0
SellButton.Font = Enum.Font.SourceSansSemibold
SellButton.Text = "SELL"
SellButton.TextColor3 = Colors.White
SellButton.TextSize = 14
SellButton.AutoButtonColor = false
SellButton.Parent = UpgradePage

UpgradeButton = Instance.new("TextButton")
UpgradeButton.Name = "UpgradeButton"
UpgradeButton.Size = UDim2.new(1, -94, 0, 28)
UpgradeButton.Position = UDim2.new(0, 86, 1, -36)
UpgradeButton.BackgroundColor3 = Colors.Button
UpgradeButton.BorderSizePixel = 0
UpgradeButton.Font = Enum.Font.SourceSansSemibold
UpgradeButton.Text = "UPGRADE"
UpgradeButton.TextColor3 = Colors.White
UpgradeButton.TextSize = 16
UpgradeButton.AutoButtonColor = false
UpgradeButton.Parent = UpgradePage

ShopPage = Instance.new("Frame")
ShopPage.Name = "ShopPage"
ShopPage.Size = UDim2.new(1, 0, 1, -(WindowConfig.TitleHeight + WindowConfig.TabHeight))
ShopPage.Position = UDim2.fromOffset(0, WindowConfig.TitleHeight + WindowConfig.TabHeight)
ShopPage.BackgroundTransparency = 1
ShopPage.Visible = false
ShopPage.Parent = Holder

ShopLabel = Instance.new("TextLabel")
ShopLabel.Name = "ShopLabel"
ShopLabel.Size = UDim2.new(1, -16, 0, 18)
ShopLabel.Position = UDim2.fromOffset(8, 6)
ShopLabel.BackgroundTransparency = 1
ShopLabel.Font = Enum.Font.SourceSans
ShopLabel.Text = "Shop — Click a bear to buy"
ShopLabel.TextColor3 = Colors.Gray
ShopLabel.TextSize = 14
ShopLabel.TextXAlignment = Enum.TextXAlignment.Left
ShopLabel.Parent = ShopPage

ShopScroll = Instance.new("ScrollingFrame")
ShopScroll.Name = "ShopScroll"
ShopScroll.Size = UDim2.new(1, -16, 1, -32)
ShopScroll.Position = UDim2.fromOffset(8, 26)
ShopScroll.BackgroundColor3 = Colors.Dark
ShopScroll.BorderSizePixel = 0
ShopScroll.ScrollBarThickness = 4
ShopScroll.ScrollBarImageColor3 = Colors.Button
ShopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ShopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ShopScroll.ScrollingDirection = Enum.ScrollingDirection.Y
ShopScroll.Parent = ShopPage

ShopLayout = Instance.new("UIGridLayout")
ShopLayout.CellSize = UDim2.fromOffset(62, 70)
ShopLayout.CellPadding = UDim2.fromOffset(4, 4)
ShopLayout.SortOrder = Enum.SortOrder.LayoutOrder
ShopLayout.Parent = ShopScroll

local ShopPadding = Instance.new("UIPadding")
ShopPadding.PaddingLeft = UDim.new(0, 4)
ShopPadding.PaddingTop = UDim.new(0, 4)
ShopPadding.PaddingRight = UDim.new(0, 4)
ShopPadding.PaddingBottom = UDim.new(0, 4)
ShopPadding.Parent = ShopScroll

-----/Init/-----
AdminButton.MouseButton1Click:Connect(OpenAdminPanel)

AdminButton.MouseEnter:Connect(function()
	TweenService:Create(AdminButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.AdminHover }):Play()
end)

AdminButton.MouseLeave:Connect(function()
	TweenService:Create(AdminButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Admin }):Play()
end)

GiveMoneyBtn.MouseButton1Click:Connect(function()
	local Amount = tonumber(MoneyInput.Text)

	if not Amount then
		Notify("Invalid amount", "error")

		return
	end

	Currency = Currency + math.floor(Amount)
	Notify("Added $" .. tostring(math.floor(Amount)), "success")
	UpdateMoney()
end)

SetMoneyBtn.MouseButton1Click:Connect(function()
	local Amount = tonumber(MoneyInput.Text)

	if not Amount then
		Notify("Invalid amount", "error")

		return
	end

	Currency = math.floor(Amount)
	Notify("Money set to $" .. tostring(Currency), "success")
	UpdateMoney()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	IsMinimized = not IsMinimized
	TabBar.Visible = not IsMinimized
	UpgradePage.Visible = not IsMinimized and ActiveTab == "upgrade"
	ShopPage.Visible = not IsMinimized and ActiveTab == "shop"

	if IsMinimized then
		Holder.Size = UDim2.new(WindowConfig.Size.X.Scale, WindowConfig.Size.X.Offset, 0, WindowConfig.TitleHeight)
	else
		Holder.Size = WindowConfig.Size
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	for _, Connection in ipairs(Connections) do
		Connection:Disconnect()
	end

	table.clear(Connections)
	ScreenGui:Destroy()
end)

UpgradeTabButton.MouseButton1Click:Connect(function()
	SetTab("upgrade")
end)

ShopTabButton.MouseButton1Click:Connect(function()
	SetTab("shop")
end)

UpgradeTabButton.MouseEnter:Connect(function()
	if ActiveTab == "upgrade" then return end

	TweenService:Create(UpgradeTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

UpgradeTabButton.MouseLeave:Connect(function()
	if ActiveTab == "upgrade" then return end

	TweenService:Create(UpgradeTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Tab }):Play()
end)

ShopTabButton.MouseEnter:Connect(function()
	if ActiveTab == "shop" then return end

	TweenService:Create(ShopTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

ShopTabButton.MouseLeave:Connect(function()
	if ActiveTab == "shop" then return end

	TweenService:Create(ShopTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Tab }):Play()
end)

UpgradeButton.MouseEnter:Connect(function()
	if IsRolling then return end

	TweenService:Create(UpgradeButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

UpgradeButton.MouseLeave:Connect(function()
	if IsRolling then return end

	TweenService:Create(UpgradeButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
end)

UpgradeButton.MouseButton1Click:Connect(PerformUpgrade)

SellButton.MouseEnter:Connect(function()
	TweenService:Create(SellButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

SellButton.MouseLeave:Connect(function()
	TweenService:Create(SellButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
end)

SellButton.MouseButton1Click:Connect(SellSelected)

SetupDragging(Holder, TitleBar)

for _, BearId in ipairs(StarterBears) do
	table.insert(Inventory, BearId)
end

RefreshInventory()
RefreshTarget()
RefreshShop()
UpdateInfo()
UpdateMoney()

print("🟢 | Successfully : Upgrader initialized")
