-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui
local LoadingFrame
local LoadingStroke
local LoadingTitle
local LoadingStatus
local LoadingBar
local LoadingFill
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
local ShopTabBar
local CasesTabButton
local SkinsTabButton
local CasesPage
local CaseScroll
local CaseLayout
local ChancesPanel
local ChancesLayout
local OpenCaseButton
local SkinsPage
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
local RollFrame
local RollTitle
local RollResult
local SkipButton
local WheelMask
local WheelRotation
local WheelHub
local WheelPointer
local CaseRollFrame
local CaseRollTitle
local CaseRollViewport
local CaseRollReel
local CaseRollPointer
local CaseRollResult
local CaseRollSkipButton
local ChanceRows = {}
local SoundObjects = {}
local SelectedBearIndex = nil
local SelectedTargetId = nil
local SelectedCaseKey = nil
local IsMinimized = false
local IsRolling = false
local IsAdminAuthed = false
local ActiveTab = "upgrade"
local ActiveShopTab = "cases"
local Currency = 1000
local LuckMultiplier = 1.0
local WheelAngle = 0
local Connections = {}
local Inventory = {}

-----/Assets/-----
local MinimizeIcon = "rbxassetid://2406617031"
local CloseIcon = "rbxassetid://5054663650"

local CaseIcon = "rbxassetid://122235765585989"

local Sounds = {
	Select = "111174530730534",
	Hover = "119354387183704",
	Sell = "94786696538190",
	Buy = "133292918309565",
	Win = "127039883737564",
	Lose = "1844442622",
}

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
	Win = Color3.fromRGB(84, 168, 96),
	Lose = Color3.fromRGB(192, 76, 76),
}

local TitleColors = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 100, 200),
	Epic = Color3.fromRGB(200, 100, 100),
	Mythic = Color3.fromRGB(200, 50, 200),
	Legendary = Color3.fromRGB(200, 150, 0),
	God = Color3.fromRGB(255, 255, 150),
}

local TitleOrder = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Mythic",
	"Legendary",
	"God",
}

local Bears = {
	["4807224885"] = {Value = 50, Title = "Common", Color = TitleColors.Common},
	["18689032058"] = {Value = 75, Title = "Common", Color = TitleColors.Common},
	["5511217343"] = {Value = 100, Title = "Common", Color = TitleColors.Common},
	["5563184505"] = {Value = 150, Title = "Uncommon", Color = TitleColors.Uncommon},
	["5067973789"] = {Value = 200, Title = "Uncommon", Color = TitleColors.Uncommon},
	["5346908116"] = {Value = 250, Title = "Uncommon", Color = TitleColors.Uncommon},
	["5117670810"] = {Value = 500, Title = "Rare", Color = TitleColors.Rare},
	["5563188406"] = {Value = 750, Title = "Rare", Color = TitleColors.Rare},
	["9077053562"] = {Value = 1000, Title = "Rare", Color = TitleColors.Rare},
	["7742336085"] = {Value = 1500, Title = "Epic", Color = TitleColors.Epic},
	["18971808936"] = {Value = 2000, Title = "Epic", Color = TitleColors.Epic},
	["5511347255"] = {Value = 2500, Title = "Epic", Color = TitleColors.Epic},
	["9077042087"] = {Value = 5000, Title = "Mythic", Color = TitleColors.Mythic},
	["5630802995"] = {Value = 7500, Title = "Mythic", Color = TitleColors.Mythic},
	["12887392169"] = {Value = 10000, Title = "Mythic", Color = TitleColors.Mythic},
	["6001749167"] = {Value = 12500, Title = "Legendary", Color = TitleColors.Legendary},
	["5511339536"] = {Value = 15000, Title = "Legendary", Color = TitleColors.Legendary},
	["7851094473"] = {Value = 17500, Title = "Legendary", Color = TitleColors.Legendary},
	["18806629643"] = {Value = 20000, Title = "Legendary", Color = TitleColors.Legendary},
	["10819368697"] = {Value = 22500, Title = "Legendary", Color = TitleColors.Legendary},
	["5158184080"] = {Value = 25000, Title = "God", Color = TitleColors.God},
	["89728729764895"] = {Value = 27500, Title = "God", Color = TitleColors.God},
	["137552717223881"] = {Value = 30000, Title = "God", Color = TitleColors.God},
	["18818000762"] = {Value = 32500, Title = "God", Color = TitleColors.God},
	["124106062530871"] = {Value = 35000, Title = "God", Color = TitleColors.God},
	["18689074922"] = {Value = 37500, Title = "God", Color = TitleColors.God},
	["5630802542"] = {Value = 40000, Title = "God", Color = TitleColors.God},
}

local Cases = {
	Wooden = {
		Name = "Wooden",
		Price = 500,
		Icon = CaseIcon,
		Color = Color3.fromRGB(139, 90, 43),
		Chances = {
			Common = 60,
			Uncommon = 25,
			Rare = 10,
			Epic = 4,
			Mythic = 0.9,
			Legendary = 0.1,
			God = 0,
		},
	},
	Silver = {
		Name = "Silver",
		Price = 1000,
		Icon = CaseIcon,
		Color = Color3.fromRGB(192, 192, 192),
		Chances = {
			Common = 45,
			Uncommon = 28,
			Rare = 15,
			Epic = 8,
			Mythic = 3,
			Legendary = 0.9,
			God = 0.1,
		},
	},
	Gold = {
		Name = "Gold",
		Price = 2000,
		Icon = CaseIcon,
		Color = Color3.fromRGB(255, 200, 50),
		Chances = {
			Common = 30,
			Uncommon = 25,
			Rare = 20,
			Epic = 14,
			Mythic = 8,
			Legendary = 2.8,
			God = 0.2,
		},
	},
	Diamond = {
		Name = "Diamond",
		Price = 3000,
		Icon = CaseIcon,
		Color = Color3.fromRGB(120, 220, 255),
		Chances = {
			Common = 15,
			Uncommon = 22,
			Rare = 25,
			Epic = 20,
			Mythic = 12,
			Legendary = 5,
			God = 1,
		},
	},
	Cosmic = {
		Name = "Cosmic",
		Price = 5000,
		Icon = CaseIcon,
		Color = Color3.fromRGB(180, 100, 255),
		Chances = {
			Common = 0,
			Uncommon = 10,
			Rare = 20,
			Epic = 28,
			Mythic = 25,
			Legendary = 13,
			God = 4,
		},
	},
}

local CaseOrder = {
	"Wooden",
	"Silver",
	"Gold",
	"Diamond",
	"Cosmic",
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
	ShopTabHeight = 22,
}

local AdminConfig = {
	Size = UDim2.fromOffset(290, 350),
	PickerSize = UDim2.fromOffset(260, 260),
}

local RollConfig = {
	WheelSize = 180,
	Duration = 5,
	HoldTime = 0.9,
	MinSpinTurns = 4,
	MaxSpinTurns = 6,
	GridStep = 12,
	DotSize = 18,
}

local CaseRollConfig = {
	FrameSize = UDim2.fromOffset(340, 200),
	ViewportSize = UDim2.new(1, -20, 0, 90),
	ViewportOffset = UDim2.new(0, 10, 0, 40),
	TileSize = 80,
	TileGap = 8,
	Duration = 4.5,
	HoldTime = 1.2,
	TotalTiles = 50,
	WinIndex = 45,
	Jitter = 20,
}

local LoadingConfig = {
	FrameSize = UDim2.fromOffset(340, 90),
	FadeTime = 0.25,
	MinShowTime = 0.6,
}

local AdminCode = "123Admin"

local TileStyle = {
	IdleTransparency = 0.35,
	IdleThickness = 1,
	HoverTransparency = 0.05,
	HoverThickness = 2,
	SelectedTransparency = 0,
	SelectedThickness = 2,
	HoverLerp = 0.3,
	SelectedLerp = 0.5,
	TextLerp = 0.7,
}

-----/Functions/-----
local RefreshInventory, RefreshTarget, RefreshShop, RefreshPicker, RefreshCases, BuyBear, SellSelected, CreateBearTile, CreateCaseTile
local OpenAdminPanel, OpenCase, UpdateChancesPanel

local function Notify(Message : string, NotifType : string)
	local Notif = Instance.new("Frame")
	Notif.Name = "Notification"
	Notif.Size = UDim2.fromOffset(220, 36)
	Notif.Position = UDim2.new(1, -230, 1, -46)
	Notif.BackgroundColor3 = Colors.Background
	Notif.BorderSizePixel = 0
	Notif.ZIndex = 50
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
	Label.ZIndex = 51
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

local function PlaySound(Name : string)
	local Sound = SoundObjects[Name]

	if not Sound then

		return
	end

	Sound:Play()
end

local function CreateSound(Name : string, SoundId : string, Volume : number)
	local Sound = Instance.new("Sound")
	Sound.Name = Name
	Sound.SoundId = "rbxassetid://" .. SoundId
	Sound.Volume = Volume
	Sound.Parent = ScreenGui

	SoundObjects[Name] = Sound
end

local function UpdateMoney()
	if MoneyLabel then
		MoneyLabel.Text = "$" .. tostring(Currency)
	end
end

local function SetSelected(Tile : TextButton, Selected : boolean)
	local Stroke = Tile:FindFirstChildOfClass("UIStroke")
	local BaseColor = Tile:GetAttribute("BaseColor") or Colors.Button

	Tile:SetAttribute("Selected", Selected)

	if not Stroke then

		return
	end

	local TargetColor = Selected and BaseColor:Lerp(Colors.White, TileStyle.SelectedLerp) or BaseColor

	TweenService:Create(Stroke, TweenInfo.new(0.1), {
		Color = TargetColor,
		Transparency = Selected and TileStyle.SelectedTransparency or TileStyle.IdleTransparency,
		Thickness = Selected and TileStyle.SelectedThickness or TileStyle.IdleThickness,
	}):Play()
end

local function UpdateInfo()
	if SelectedBearIndex and Inventory[SelectedBearIndex] then
		local BearId = Inventory[SelectedBearIndex]
		BearLabel.Text = "Bear : $" .. tostring(Bears[BearId].Value)
	else
		BearLabel.Text = "Bear : —"
	end

	if SelectedTargetId then
		TargetInfoLabel.Text = "Target : $" .. tostring(Bears[SelectedTargetId].Value)
	else
		TargetInfoLabel.Text = "Target : —"
	end

	if SelectedBearIndex and SelectedTargetId then
		local BearPrice = Bears[Inventory[SelectedBearIndex]].Value
		local TargetPrice = Bears[SelectedTargetId].Value
		local RawChance = BearPrice / TargetPrice * 100 * LuckMultiplier
		local Chance = math.clamp(RawChance, 1, 99)
		local LuckTag = LuckMultiplier > 1 and string.format(" (x%.1f)", LuckMultiplier) or ""
		ChanceLabel.Text = string.format("Chance : %.1f%%%s", Chance, LuckTag)
	else
		ChanceLabel.Text = "Chance : —"
	end
end

local function RefreshSelection()
	if not InventoryScroll or not TargetScroll then

		return
	end

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

local function RefreshCaseSelection()
	if not CaseScroll then

		return
	end

	for _, Tile in ipairs(CaseScroll:GetChildren()) do
		if Tile:IsA("TextButton") then
			local Key = Tile:GetAttribute("CaseKey")
			SetSelected(Tile, Key == SelectedCaseKey)
		end
	end
end

CreateBearTile = function(BearId : string, Price : number, Panel : string, Key : any, Parent : Instance)
	local BearData = Bears[BearId]
	local BaseColor = BearData and BearData.Color or Colors.Button
	local TextColor = BaseColor:Lerp(Colors.White, TileStyle.TextLerp)

	local Tile = Instance.new("TextButton")
	Tile.Name = "Tile"
	Tile.Size = UDim2.fromOffset(62, 70)
	Tile.BackgroundTransparency = 1
	Tile.BorderSizePixel = 0
	Tile.AutoButtonColor = false
	Tile.Text = ""
	Tile:SetAttribute("BearId", BearId)
	Tile:SetAttribute("Panel", Panel)
	Tile:SetAttribute("Selected", false)
	Tile:SetAttribute("BaseColor", BaseColor)

	if type(Key) == "number" then
		Tile:SetAttribute("InventoryIndex", Key)
	end

	Tile.Parent = Parent

	local Stroke = Instance.new("UIStroke")
	Stroke.Name = "Stroke"
	Stroke.Color = BaseColor
	Stroke.Thickness = TileStyle.IdleThickness
	Stroke.Transparency = TileStyle.IdleTransparency
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Tile

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
	PriceLabel.Font = Enum.Font.SourceSansSemibold
	PriceLabel.Text = "$" .. tostring(Price)
	PriceLabel.TextColor3 = TextColor
	PriceLabel.TextSize = 14
	PriceLabel.Parent = Tile

	Tile.MouseEnter:Connect(function()
		if Tile:GetAttribute("Selected") then

			return
		end

		PlaySound("Hover")

		TweenService:Create(Stroke, TweenInfo.new(0.1), {
			Color = BaseColor:Lerp(Colors.White, TileStyle.HoverLerp),
			Transparency = TileStyle.HoverTransparency,
			Thickness = TileStyle.HoverThickness,
		}):Play()
	end)

	Tile.MouseLeave:Connect(function()
		if Tile:GetAttribute("Selected") then

			return
		end

		TweenService:Create(Stroke, TweenInfo.new(0.1), {
			Color = BaseColor,
			Transparency = TileStyle.IdleTransparency,
			Thickness = TileStyle.IdleThickness,
		}):Play()
	end)

	Tile.MouseButton1Click:Connect(function()
		if IsRolling then

			return
		end

		if Panel == "inventory" then
			PlaySound("Select")
			SelectedBearIndex = Key
			RefreshSelection()
			UpdateInfo()
		elseif Panel == "target" then
			PlaySound("Select")
			SelectedTargetId = BearId
			RefreshSelection()
			UpdateInfo()
		elseif Panel == "shop" then
			BuyBear(BearId)
		elseif Panel == "picker" then
			PlaySound("Buy")
			table.insert(Inventory, BearId)
			Notify("Given : $" .. tostring(Bears[BearId].Value) .. " bear", "success")
			RefreshInventory()
			BearPicker.Visible = false
		end
	end)

	return Tile
end

CreateCaseTile = function(CaseKey : string, Parent : Instance)
	local Case = Cases[CaseKey]

	if not Case then

		return
	end

	local BaseColor = Case.Color
	local TextColor = BaseColor:Lerp(Colors.White, TileStyle.TextLerp)

	local Tile = Instance.new("TextButton")
	Tile.Name = "CaseTile"
	Tile.Size = UDim2.fromOffset(62, 70)
	Tile.BackgroundTransparency = 1
	Tile.BorderSizePixel = 0
	Tile.AutoButtonColor = false
	Tile.Text = ""
	Tile:SetAttribute("CaseKey", CaseKey)
	Tile:SetAttribute("Selected", false)
	Tile:SetAttribute("BaseColor", BaseColor)
	Tile.Parent = Parent

	local Stroke = Instance.new("UIStroke")
	Stroke.Name = "Stroke"
	Stroke.Color = BaseColor
	Stroke.Thickness = TileStyle.IdleThickness
	Stroke.Transparency = TileStyle.IdleTransparency
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Tile

	local Icon = Instance.new("ImageLabel")
	Icon.Name = "Icon"
	Icon.Size = UDim2.new(1, -8, 0, 46)
	Icon.Position = UDim2.fromOffset(4, 4)
	Icon.BackgroundTransparency = 1
	Icon.Image = Case.Icon
	Icon.ImageColor3 = BaseColor
	Icon.ScaleType = Enum.ScaleType.Fit
	Icon.Parent = Tile

	local PriceLabel = Instance.new("TextLabel")
	PriceLabel.Name = "Price"
	PriceLabel.Size = UDim2.new(1, 0, 0, 16)
	PriceLabel.Position = UDim2.new(0, 0, 1, -18)
	PriceLabel.BackgroundTransparency = 1
	PriceLabel.Font = Enum.Font.SourceSansSemibold
	PriceLabel.Text = "$" .. tostring(Case.Price)
	PriceLabel.TextColor3 = TextColor
	PriceLabel.TextSize = 14
	PriceLabel.Parent = Tile

	Tile.MouseEnter:Connect(function()
		if Tile:GetAttribute("Selected") then

			return
		end

		PlaySound("Hover")

		TweenService:Create(Stroke, TweenInfo.new(0.1), {
			Color = BaseColor:Lerp(Colors.White, TileStyle.HoverLerp),
			Transparency = TileStyle.HoverTransparency,
			Thickness = TileStyle.HoverThickness,
		}):Play()
	end)

	Tile.MouseLeave:Connect(function()
		if Tile:GetAttribute("Selected") then

			return
		end

		TweenService:Create(Stroke, TweenInfo.new(0.1), {
			Color = BaseColor,
			Transparency = TileStyle.IdleTransparency,
			Thickness = TileStyle.IdleThickness,
		}):Play()
	end)

	Tile.MouseButton1Click:Connect(function()
		if IsRolling then

			return
		end

		PlaySound("Select")
		SelectedCaseKey = CaseKey
		RefreshCaseSelection()
		UpdateChancesPanel()
	end)

	return Tile
end

RefreshInventory = function()
	if not InventoryScroll then

		return
	end

	for _, Child in ipairs(InventoryScroll:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end

	for Index, BearId in ipairs(Inventory) do
		CreateBearTile(BearId, Bears[BearId].Value, "inventory", Index, InventoryScroll)
	end

	RefreshSelection()
end

RefreshTarget = function()
	if not TargetScroll then

		return
	end

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
		return Bears[A].Value < Bears[B].Value
	end)

	for _, BearId in ipairs(SortedIds) do
		CreateBearTile(BearId, Bears[BearId].Value, "target", BearId, TargetScroll)
	end

	RefreshSelection()
end

RefreshShop = function()
	if not ShopScroll then

		return
	end

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
		return Bears[A].Value < Bears[B].Value
	end)

	for _, BearId in ipairs(SortedIds) do
		CreateBearTile(BearId, Bears[BearId].Value, "shop", BearId, ShopScroll)
	end
end

RefreshPicker = function()
	if not BearPickerScroll then

		return
	end

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
		return Bears[A].Value < Bears[B].Value
	end)

	for _, BearId in ipairs(SortedIds) do
		CreateBearTile(BearId, Bears[BearId].Value, "picker", BearId, BearPickerScroll)
	end
end

RefreshCases = function()
	if not CaseScroll then

		return
	end

	for _, Child in ipairs(CaseScroll:GetChildren()) do
		if Child:IsA("GuiObject") then
			Child:Destroy()
		end
	end

	for _, CaseKey in ipairs(CaseOrder) do
		CreateCaseTile(CaseKey, CaseScroll)
	end

	RefreshCaseSelection()
	UpdateChancesPanel()
end

UpdateChancesPanel = function()
	if not ChancesPanel then

		return
	end

	if not SelectedCaseKey then
		for _, Title in ipairs(TitleOrder) do
			local Row = ChanceRows[Title]

			if Row then
				Row.Text = Title .. " : —"
			end
		end

		OpenCaseButton.Text = "SELECT A CASE"
		OpenCaseButton.BackgroundColor3 = Colors.Button

		return
	end

	local Case = Cases[SelectedCaseKey]

	for _, Title in ipairs(TitleOrder) do
		local Row = ChanceRows[Title]
		local Chance = Case.Chances[Title] or 0

		if Row then
			Row.Text = string.format("%s : %.1f%%", Title, Chance)
		end
	end

	OpenCaseButton.Text = "OPEN CASE ($" .. tostring(Case.Price) .. ")"
end

local function BuildCaseReel(WonId : string)
	for _, Child in ipairs(CaseRollReel:GetChildren()) do
		Child:Destroy()
	end

	local TileSize = CaseRollConfig.TileSize
	local TileGap = CaseRollConfig.TileGap
	local Step = TileSize + TileGap
	local TotalTiles = CaseRollConfig.TotalTiles
	local WinIndex = CaseRollConfig.WinIndex

	CaseRollReel.Size = UDim2.fromOffset(TotalTiles * Step, TileSize)

	local SortedIds = {}

	for Id in pairs(Bears) do
		table.insert(SortedIds, Id)
	end

	for Index = 1, TotalTiles do
		local BearId

		if Index == WinIndex then
			BearId = WonId
		else
			BearId = SortedIds[math.random(1, #SortedIds)]
		end

		local BearData = Bears[BearId]

		local Tile = Instance.new("Frame")
		Tile.Name = "Tile" .. Index
		Tile.Size = UDim2.fromOffset(TileSize, TileSize)
		Tile.Position = UDim2.fromOffset((Index - 1) * Step, 0)
		Tile.BackgroundColor3 = Colors.Background
		Tile.BorderSizePixel = 0
		Tile.ZIndex = 16
		Tile.Parent = CaseRollReel

		local Stroke = Instance.new("UIStroke")
		Stroke.Color = BearData.Color
		Stroke.Thickness = 2
		Stroke.Parent = Tile

		local Icon = Instance.new("ImageLabel")
		Icon.Name = "Icon"
		Icon.Size = UDim2.new(1, -8, 1, -8)
		Icon.Position = UDim2.fromOffset(4, 4)
		Icon.BackgroundTransparency = 1
		Icon.Image = "rbxassetid://" .. BearId
		Icon.ScaleType = Enum.ScaleType.Fit
		Icon.ZIndex = 17
		Icon.Parent = Tile
	end
end

local function PlayCaseAnimation(Case : any, WonId : string)
	CaseRollTitle.Text = "OPENING " .. string.upper(Case.Name) .. "..."
	CaseRollResult.Text = ""
	CaseRollResult.TextColor3 = Colors.White

	BuildCaseReel(WonId)

	local TileSize = CaseRollConfig.TileSize
	local TileGap = CaseRollConfig.TileGap
	local Step = TileSize + TileGap
	local WinIndex = CaseRollConfig.WinIndex
	local ViewportWidth = CaseRollViewport.AbsoluteSize.X

	if ViewportWidth <= 0 then
		ViewportWidth = CaseRollConfig.FrameSize.X.Offset - 20
	end

	CaseRollReel.Position = UDim2.new(0, 0, 0.5, 0)

	CaseRollFrame.Visible = true
	CaseRollSkipButton.Visible = true
	task.wait()

	local BaseOffset = -((WinIndex - 1) * Step) + (ViewportWidth / 2) - (TileSize / 2)
	local TargetOffset = BaseOffset + math.random(-CaseRollConfig.Jitter, CaseRollConfig.Jitter)

	local SlideTween = TweenService:Create(
		CaseRollReel,
		TweenInfo.new(CaseRollConfig.Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, TargetOffset, 0.5, 0) }
	)

	local Finished = false
	local FinishEvent = Instance.new("BindableEvent")
	local TweenConnection
	local SkipConnection

	local function Finish()
		if Finished then

			return
		end

		Finished = true
		FinishEvent:Fire()
	end

	TweenConnection = SlideTween.Completed:Connect(Finish)

	SkipConnection = CaseRollSkipButton.MouseButton1Click:Connect(function()
		PlaySound("Select")
		Finish()
	end)

	SlideTween:Play()
	FinishEvent.Event:Wait()

	TweenConnection:Disconnect()
	SkipConnection:Disconnect()
	FinishEvent:Destroy()

	SlideTween:Cancel()
	CaseRollReel.Position = UDim2.new(0, TargetOffset, 0.5, 0)
	CaseRollSkipButton.Visible = false

	local BearData = Bears[WonId]
	CaseRollResult.Text = string.upper(BearData.Title) .. " — $" .. tostring(BearData.Value)
	CaseRollResult.TextColor3 = BearData.Color

	PlaySound("Win")

	task.wait(CaseRollConfig.HoldTime)
	CaseRollFrame.Visible = false
end

OpenCase = function(CaseKey : string, Free : boolean)
	if IsRolling then

		return
	end

	local Case = Cases[CaseKey]

	if not Case then

		return
	end

	if not Free then
		if Currency < Case.Price then
			Notify("Not enough money", "error")

			return
		end

		Currency = Currency - Case.Price
		UpdateMoney()
	end

	local Roll = math.random() * 100
	local Cumulative = 0
	local PickedTitle = "Common"

	for _, Title in ipairs(TitleOrder) do
		Cumulative = Cumulative + (Case.Chances[Title] or 0)

		if Roll <= Cumulative then
			PickedTitle = Title
			break
		end
	end

	local Pool = {}

	for Id, Data in pairs(Bears) do
		if Data.Title == PickedTitle then
			table.insert(Pool, Id)
		end
	end

	if #Pool == 0 then
		for Id, Data in pairs(Bears) do
			if Data.Title == "Common" then
				table.insert(Pool, Id)
			end
		end
	end

	if #Pool == 0 then
		Notify("Case is empty", "error")

		return
	end

	local WonId = Pool[math.random(1, #Pool)]

	IsRolling = true
	PlayCaseAnimation(Case, WonId)
	IsRolling = false

	table.insert(Inventory, WonId)
	Notify(Case.Name .. " Case : " .. PickedTitle, "success")
	print("🟢 | Successfully : Opened " .. Case.Name .. " Case — got " .. PickedTitle)
	RefreshInventory()
end

BuyBear = function(BearId : string)
	if IsRolling then

		return
	end

	local Price = Bears[BearId].Value

	if not Price then

		return
	end

	if Currency < Price then
		Notify("Not enough money", "error")

		return
	end

	Currency = Currency - Price
	table.insert(Inventory, BearId)
	PlaySound("Buy")
	Notify("Bought : $" .. tostring(Price) .. " bear", "success")
	UpdateMoney()
	RefreshInventory()
end

SellSelected = function()
	if IsRolling then

		return
	end

	if not SelectedBearIndex or not Inventory[SelectedBearIndex] then
		Notify("Select a bear to sell", "error")

		return
	end

	local BearId = Inventory[SelectedBearIndex]
	local Price = Bears[BearId].Value

	Currency = Currency + Price
	table.remove(Inventory, SelectedBearIndex)
	SelectedBearIndex = nil

	PlaySound("Sell")
	Notify("Sold : $" .. tostring(Price), "success")
	UpdateMoney()
	RefreshInventory()
	UpdateInfo()
end

local function BuildWheelDots(Chance : number)
	for _, Child in ipairs(WheelRotation:GetChildren()) do
		Child:Destroy()
	end

	local Radius = RollConfig.WheelSize / 2
	local Step = RollConfig.GridStep
	local DotSize = RollConfig.DotSize
	local DotRadius = DotSize / 2
	local GreenEnd = Chance * 360
	local Coverage = Radius - DotRadius + 3
	local Index = 0
	local Row = 0

	for gx = -Radius, Radius, Step do
		local Stagger = (Row % 2 == 0) and 0 or Step / 2
		Row = Row + 1

		for gy = -Radius + Stagger, Radius, Step do
			local Dist = math.sqrt(gx * gx + gy * gy)

			if Dist <= Coverage then
				local DotAngle = (math.deg(math.atan2(gy, gx)) + 360) % 360
				local IsGreen = DotAngle <= GreenEnd

				local Dot = Instance.new("Frame")
				Dot.Name = "Dot" .. Index
				Dot.AnchorPoint = Vector2.new(0.5, 0.5)
				Dot.Position = UDim2.new(0.5, gx, 0.5, gy)
				Dot.Size = UDim2.fromOffset(DotSize, DotSize)
				Dot.BackgroundColor3 = IsGreen and Colors.Win or Colors.Lose
				Dot.BorderSizePixel = 0
				Dot.ZIndex = 16
				Dot.Parent = WheelRotation

				local Corner = Instance.new("UICorner")
				Corner.CornerRadius = UDim.new(1, 0)
				Corner.Parent = Dot

				Index = Index + 1
			end
		end
	end
end

local function PlayRollAnimation(Chance : number) : boolean
	RollTitle.Text = string.format("ROLLING... %.1f%%", Chance * 100)
	RollResult.Text = ""
	RollResult.TextColor3 = Colors.White

	BuildWheelDots(Chance)

	WheelRotation.Rotation = WheelAngle

	RollFrame.Visible = true
	SkipButton.Visible = true
	task.wait()

	local SpinTurns = math.random(RollConfig.MinSpinTurns, RollConfig.MaxSpinTurns)
	local DeltaRotation = SpinTurns * 360 + math.random(0, 359)
	local FinalRotation = WheelAngle + DeltaRotation

	local SpinTween = TweenService:Create(
		WheelRotation,
		TweenInfo.new(RollConfig.Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Rotation = FinalRotation }
	)

	local Finished = false
	local FinishEvent = Instance.new("BindableEvent")
	local TweenConnection
	local SkipConnection

	local function Finish()
		if Finished then

			return
		end

		Finished = true
		FinishEvent:Fire()
	end

	TweenConnection = SpinTween.Completed:Connect(Finish)

	SkipConnection = SkipButton.MouseButton1Click:Connect(function()
		PlaySound("Select")
		Finish()
	end)

	SpinTween:Play()
	FinishEvent.Event:Wait()

	TweenConnection:Disconnect()
	SkipConnection:Disconnect()
	FinishEvent:Destroy()

	SpinTween:Cancel()
	WheelRotation.Rotation = FinalRotation
	SkipButton.Visible = false

	WheelAngle = FinalRotation % 360
	WheelRotation.Rotation = WheelAngle

	local TopAngle = (270 - WheelAngle) % 360
	local IsWin = TopAngle < (Chance * 360)

	if IsWin then
		RollResult.Text = "WIN"
		RollResult.TextColor3 = Colors.Win
		PlaySound("Win")
	else
		RollResult.Text = "LOSE"
		RollResult.TextColor3 = Colors.Lose
		PlaySound("Lose")
	end

	task.wait(RollConfig.HoldTime)
	RollFrame.Visible = false

	return IsWin
end

local function PerformUpgrade()
	if IsRolling then

		return
	end

	if not SelectedBearIndex or not SelectedTargetId then
		Notify("Select a bear and target first", "error")

		return
	end

	local BetBearId = Inventory[SelectedBearIndex]
	local BetBearPrice = Bears[BetBearId].Value
	local TargetPrice = Bears[SelectedTargetId].Value

	if BetBearPrice >= TargetPrice then
		Notify("Target must be more valuable", "error")

		return
	end

	IsRolling = true
	UpgradeButton.Text = "ROLLING..."
	UpgradeButton.BackgroundColor3 = Colors.Button

	local RawChance = BetBearPrice / TargetPrice * LuckMultiplier
	local Chance = math.clamp(RawChance, 0.01, 0.99)

	local Win = PlayRollAnimation(Chance)

	table.remove(Inventory, SelectedBearIndex)
	SelectedBearIndex = nil

	if Win then
		table.insert(Inventory, SelectedTargetId)
		Notify("Won : $" .. tostring(TargetPrice) .. " bear", "success")
	else
		Notify("Lost : $" .. tostring(BetBearPrice) .. " bear", "error")
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
		if not IsDraggingLocal or not DragStart then

			return
		end

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

local function SetShopTab(Tab : string)
	ActiveShopTab = Tab

	if Tab == "cases" then
		CasesPage.Visible = true
		SkinsPage.Visible = false
		CasesTabButton.BackgroundColor3 = Colors.Dark
		SkinsTabButton.BackgroundColor3 = Colors.Tab
		CasesTabButton.TextColor3 = Colors.White
		SkinsTabButton.TextColor3 = Colors.Gray
	else
		CasesPage.Visible = false
		SkinsPage.Visible = true
		CasesTabButton.BackgroundColor3 = Colors.Tab
		SkinsTabButton.BackgroundColor3 = Colors.Dark
		CasesTabButton.TextColor3 = Colors.Gray
		SkinsTabButton.TextColor3 = Colors.White
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

local function GatherAssets() : {string}
	local Assets = {}

	table.insert(Assets, MinimizeIcon)
	table.insert(Assets, CloseIcon)
	table.insert(Assets, CaseIcon)

	for _, CaseData in pairs(Cases) do
		table.insert(Assets, CaseData.Icon)
	end

	for BearId in pairs(Bears) do
		table.insert(Assets, "rbxassetid://" .. BearId)
	end

	for _, SoundId in pairs(Sounds) do
		table.insert(Assets, "rbxassetid://" .. SoundId)
	end

	return Assets
end

local function PreloadAllAssets()
	local Assets = GatherAssets()
	local Total = #Assets
	local Loaded = 0

	LoadingStatus.Text = "Loading... 0/" .. Total
	LoadingFill.Size = UDim2.new(0, 0, 1, 0)

	local Success, Err = pcall(function()
		ContentProvider:PreloadAsync(Assets, function(ContentId, Status)
			Loaded = Loaded + 1

			local Progress = math.clamp(Loaded / Total, 0, 1)
			LoadingFill.Size = UDim2.new(Progress, 0, 1, 0)
			LoadingStatus.Text = "Loading... " .. Loaded .. "/" .. Total
		end)
	end)

	if not Success then
		print("🔴 | Error : Preload failed — " .. tostring(Err))
	end

	LoadingFill.Size = UDim2.new(1, 0, 1, 0)
	LoadingStatus.Text = "Ready"
end

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

LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingFrame.Size = LoadingConfig.FrameSize
LoadingFrame.Position = UDim2.fromScale(0.5, 0.5)
LoadingFrame.BackgroundColor3 = Colors.Background
LoadingFrame.BorderSizePixel = 0
LoadingFrame.ZIndex = 100
LoadingFrame.Parent = ScreenGui

LoadingStroke = Instance.new("UIStroke")
LoadingStroke.Color = Colors.Button
LoadingStroke.Thickness = 1
LoadingStroke.Parent = LoadingFrame

LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Name = "LoadingTitle"
LoadingTitle.Size = UDim2.new(1, -20, 0, 24)
LoadingTitle.Position = UDim2.fromOffset(10, 10)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Font = Enum.Font.SourceSansBold
LoadingTitle.Text = "UPGRADER"
LoadingTitle.TextColor3 = Colors.White
LoadingTitle.TextSize = 18
LoadingTitle.TextXAlignment = Enum.TextXAlignment.Left
LoadingTitle.ZIndex = 101
LoadingTitle.Parent = LoadingFrame

LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Name = "LoadingStatus"
LoadingStatus.Size = UDim2.new(1, -20, 0, 14)
LoadingStatus.Position = UDim2.new(0, 10, 1, -30)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Font = Enum.Font.SourceSans
LoadingStatus.Text = "Loading... 0/0"
LoadingStatus.TextColor3 = Colors.Gray
LoadingStatus.TextSize = 12
LoadingStatus.TextXAlignment = Enum.TextXAlignment.Right
LoadingStatus.ZIndex = 101
LoadingStatus.Parent = LoadingFrame

LoadingBar = Instance.new("Frame")
LoadingBar.Name = "LoadingBar"
LoadingBar.Size = UDim2.new(1, -20, 0, 6)
LoadingBar.Position = UDim2.new(0, 10, 1, -14)
LoadingBar.BackgroundColor3 = Colors.Dark
LoadingBar.BorderSizePixel = 0
LoadingBar.ZIndex = 101
LoadingBar.Parent = LoadingFrame

local LoadingBarCorner = Instance.new("UICorner")
LoadingBarCorner.CornerRadius = UDim.new(1, 0)
LoadingBarCorner.Parent = LoadingBar

LoadingFill = Instance.new("Frame")
LoadingFill.Name = "LoadingFill"
LoadingFill.Size = UDim2.new(0, 0, 1, 0)
LoadingFill.BackgroundColor3 = Colors.Accent
LoadingFill.BorderSizePixel = 0
LoadingFill.ZIndex = 102
LoadingFill.Parent = LoadingBar

local LoadingFillCorner = Instance.new("UICorner")
LoadingFillCorner.CornerRadius = UDim.new(1, 0)
LoadingFillCorner.Parent = LoadingFill

Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = WindowConfig.Size
Holder.Position = UDim2.new(0, 20, 0.5, -WindowConfig.Size.Y.Offset / 2)
Holder.BackgroundColor3 = Colors.Background
Holder.BorderSizePixel = 0
Holder.Visible = false
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

RollFrame = Instance.new("Frame")
RollFrame.Name = "RollFrame"
RollFrame.Size = UDim2.fromOffset(240, 260)
RollFrame.Position = UDim2.new(0.5, -120, 0.5, -130)
RollFrame.BackgroundColor3 = Colors.Dark
RollFrame.BorderSizePixel = 0
RollFrame.Visible = false
RollFrame.ZIndex = 15
RollFrame.Parent = Holder

RollTitle = Instance.new("TextLabel")
RollTitle.Name = "RollTitle"
RollTitle.Size = UDim2.new(1, -60, 0, 24)
RollTitle.Position = UDim2.fromOffset(0, 6)
RollTitle.BackgroundTransparency = 1
RollTitle.Font = Enum.Font.SourceSansSemibold
RollTitle.Text = "ROLLING..."
RollTitle.TextColor3 = Colors.White
RollTitle.TextSize = 15
RollTitle.ZIndex = 16
RollTitle.Parent = RollFrame

SkipButton = Instance.new("TextButton")
SkipButton.Name = "SkipButton"
SkipButton.Size = UDim2.fromOffset(52, 18)
SkipButton.Position = UDim2.new(1, -58, 0, 6)
SkipButton.BackgroundColor3 = Colors.Button
SkipButton.BorderSizePixel = 0
SkipButton.Font = Enum.Font.SourceSansBold
SkipButton.Text = "SKIP"
SkipButton.TextColor3 = Colors.Money
SkipButton.TextSize = 12
SkipButton.AutoButtonColor = false
SkipButton.Visible = false
SkipButton.ZIndex = 19
SkipButton.Parent = RollFrame

SkipButton.MouseEnter:Connect(function()
	TweenService:Create(SkipButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

SkipButton.MouseLeave:Connect(function()
	TweenService:Create(SkipButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
end)

WheelMask = Instance.new("Frame")
WheelMask.Name = "WheelMask"
WheelMask.AnchorPoint = Vector2.new(0.5, 0.5)
WheelMask.Position = UDim2.new(0.5, 0, 0, 130)
WheelMask.Size = UDim2.fromOffset(RollConfig.WheelSize, RollConfig.WheelSize)
WheelMask.BackgroundColor3 = Colors.Background
WheelMask.BorderSizePixel = 0
WheelMask.ClipsDescendants = true
WheelMask.ZIndex = 16
WheelMask.Parent = RollFrame

local WheelCorner = Instance.new("UICorner")
WheelCorner.CornerRadius = UDim.new(1, 0)
WheelCorner.Parent = WheelMask

local WheelStroke = Instance.new("UIStroke")
WheelStroke.Color = Colors.Button
WheelStroke.Thickness = 2
WheelStroke.Parent = WheelMask

WheelRotation = Instance.new("Frame")
WheelRotation.Name = "WheelRotation"
WheelRotation.AnchorPoint = Vector2.new(0.5, 0.5)
WheelRotation.Position = UDim2.fromScale(0.5, 0.5)
WheelRotation.Size = UDim2.fromOffset(RollConfig.WheelSize, RollConfig.WheelSize)
WheelRotation.BackgroundTransparency = 1
WheelRotation.ZIndex = 16
WheelRotation.Parent = WheelMask

WheelHub = Instance.new("Frame")
WheelHub.Name = "WheelHub"
WheelHub.AnchorPoint = Vector2.new(0.5, 0.5)
WheelHub.Position = UDim2.fromScale(0.5, 0.5)
WheelHub.Size = UDim2.fromOffset(30, 30)
WheelHub.BackgroundColor3 = Colors.Dark
WheelHub.BorderSizePixel = 0
WheelHub.ZIndex = 17
WheelHub.Parent = WheelMask

local HubCorner = Instance.new("UICorner")
HubCorner.CornerRadius = UDim.new(1, 0)
HubCorner.Parent = WheelHub

local HubStroke = Instance.new("UIStroke")
HubStroke.Color = Colors.Money
HubStroke.Thickness = 2
HubStroke.Parent = WheelHub

WheelPointer = Instance.new("Frame")
WheelPointer.Name = "WheelPointer"
WheelPointer.AnchorPoint = Vector2.new(0.5, 0)
WheelPointer.Position = UDim2.new(0.5, 0, 0, 36)
WheelPointer.Size = UDim2.fromOffset(6, 18)
WheelPointer.BackgroundColor3 = Colors.Money
WheelPointer.BorderSizePixel = 0
WheelPointer.ZIndex = 18
WheelPointer.Parent = RollFrame

local PointerCorner = Instance.new("UICorner")
PointerCorner.CornerRadius = UDim.new(0, 3)
PointerCorner.Parent = WheelPointer

RollResult = Instance.new("TextLabel")
RollResult.Name = "RollResult"
RollResult.Size = UDim2.new(1, 0, 0, 26)
RollResult.Position = UDim2.new(0, 0, 1, -32)
RollResult.BackgroundTransparency = 1
RollResult.Font = Enum.Font.SourceSansBold
RollResult.Text = ""
RollResult.TextColor3 = Colors.White
RollResult.TextSize = 20
RollResult.ZIndex = 16
RollResult.Parent = RollFrame

CaseRollFrame = Instance.new("Frame")
CaseRollFrame.Name = "CaseRollFrame"
CaseRollFrame.Size = CaseRollConfig.FrameSize
CaseRollFrame.Position = UDim2.new(0.5, -CaseRollConfig.FrameSize.X.Offset / 2, 0.5, -CaseRollConfig.FrameSize.Y.Offset / 2)
CaseRollFrame.BackgroundColor3 = Colors.Dark
CaseRollFrame.BorderSizePixel = 0
CaseRollFrame.Visible = false
CaseRollFrame.ZIndex = 15
CaseRollFrame.Parent = Holder

CaseRollTitle = Instance.new("TextLabel")
CaseRollTitle.Name = "CaseRollTitle"
CaseRollTitle.Size = UDim2.new(1, -60, 0, 24)
CaseRollTitle.Position = UDim2.fromOffset(10, 6)
CaseRollTitle.BackgroundTransparency = 1
CaseRollTitle.Font = Enum.Font.SourceSansSemibold
CaseRollTitle.Text = "OPENING..."
CaseRollTitle.TextColor3 = Colors.White
CaseRollTitle.TextSize = 15
CaseRollTitle.TextXAlignment = Enum.TextXAlignment.Left
CaseRollTitle.ZIndex = 16
CaseRollTitle.Parent = CaseRollFrame

CaseRollSkipButton = Instance.new("TextButton")
CaseRollSkipButton.Name = "CaseRollSkipButton"
CaseRollSkipButton.Size = UDim2.fromOffset(52, 18)
CaseRollSkipButton.Position = UDim2.new(1, -58, 0, 6)
CaseRollSkipButton.BackgroundColor3 = Colors.Button
CaseRollSkipButton.BorderSizePixel = 0
CaseRollSkipButton.Font = Enum.Font.SourceSansBold
CaseRollSkipButton.Text = "SKIP"
CaseRollSkipButton.TextColor3 = Colors.Money
CaseRollSkipButton.TextSize = 12
CaseRollSkipButton.AutoButtonColor = false
CaseRollSkipButton.Visible = false
CaseRollSkipButton.ZIndex = 19
CaseRollSkipButton.Parent = CaseRollFrame

CaseRollSkipButton.MouseEnter:Connect(function()
	TweenService:Create(CaseRollSkipButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

CaseRollSkipButton.MouseLeave:Connect(function()
	TweenService:Create(CaseRollSkipButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
end)

CaseRollViewport = Instance.new("Frame")
CaseRollViewport.Name = "CaseRollViewport"
CaseRollViewport.Size = CaseRollConfig.ViewportSize
CaseRollViewport.Position = CaseRollConfig.ViewportOffset
CaseRollViewport.BackgroundColor3 = Colors.Background
CaseRollViewport.BorderSizePixel = 0
CaseRollViewport.ClipsDescendants = true
CaseRollViewport.ZIndex = 16
CaseRollViewport.Parent = CaseRollFrame

local CaseRollViewportStroke = Instance.new("UIStroke")
CaseRollViewportStroke.Color = Colors.Button
CaseRollViewportStroke.Thickness = 1
CaseRollViewportStroke.Parent = CaseRollViewport

CaseRollReel = Instance.new("Frame")
CaseRollReel.Name = "CaseRollReel"
CaseRollReel.AnchorPoint = Vector2.new(0, 0.5)
CaseRollReel.Size = UDim2.fromOffset(CaseRollConfig.TotalTiles * (CaseRollConfig.TileSize + CaseRollConfig.TileGap), CaseRollConfig.TileSize)
CaseRollReel.Position = UDim2.new(0, 0, 0.5, 0)
CaseRollReel.BackgroundTransparency = 1
CaseRollReel.ZIndex = 16
CaseRollReel.Parent = CaseRollViewport

CaseRollPointer = Instance.new("Frame")
CaseRollPointer.Name = "CaseRollPointer"
CaseRollPointer.AnchorPoint = Vector2.new(0.5, 0)
CaseRollPointer.Size = UDim2.fromOffset(3, CaseRollConfig.ViewportSize.Y.Offset)
CaseRollPointer.Position = UDim2.new(0.5, 0, 0, CaseRollConfig.ViewportOffset.Y.Offset)
CaseRollPointer.BackgroundColor3 = Colors.Money
CaseRollPointer.BorderSizePixel = 0
CaseRollPointer.ZIndex = 18
CaseRollPointer.Parent = CaseRollFrame

CaseRollResult = Instance.new("TextLabel")
CaseRollResult.Name = "CaseRollResult"
CaseRollResult.Size = UDim2.new(1, -20, 0, 26)
CaseRollResult.Position = UDim2.new(0, 10, 1, -36)
CaseRollResult.BackgroundTransparency = 1
CaseRollResult.Font = Enum.Font.SourceSansBold
CaseRollResult.Text = ""
CaseRollResult.TextColor3 = Colors.White
CaseRollResult.TextSize = 18
CaseRollResult.ZIndex = 16
CaseRollResult.Parent = CaseRollFrame

ShopPage = Instance.new("Frame")
ShopPage.Name = "ShopPage"
ShopPage.Size = UDim2.new(1, 0, 1, -(WindowConfig.TitleHeight + WindowConfig.TabHeight))
ShopPage.Position = UDim2.fromOffset(0, WindowConfig.TitleHeight + WindowConfig.TabHeight)
ShopPage.BackgroundTransparency = 1
ShopPage.Visible = false
ShopPage.Parent = Holder

ShopTabBar = Instance.new("Frame")
ShopTabBar.Name = "ShopTabBar"
ShopTabBar.Size = UDim2.new(1, 0, 0, WindowConfig.ShopTabHeight)
ShopTabBar.BackgroundColor3 = Colors.Tab
ShopTabBar.BorderSizePixel = 0
ShopTabBar.Parent = ShopPage

CasesTabButton = Instance.new("TextButton")
CasesTabButton.Name = "CasesTab"
CasesTabButton.Size = UDim2.fromOffset(90, WindowConfig.ShopTabHeight)
CasesTabButton.Position = UDim2.fromOffset(0, 0)
CasesTabButton.BackgroundColor3 = Colors.Dark
CasesTabButton.BorderSizePixel = 0
CasesTabButton.Font = Enum.Font.SourceSansSemibold
CasesTabButton.Text = "Cases"
CasesTabButton.TextColor3 = Colors.White
CasesTabButton.TextSize = 13
CasesTabButton.AutoButtonColor = false
CasesTabButton.Parent = ShopTabBar

SkinsTabButton = Instance.new("TextButton")
SkinsTabButton.Name = "SkinsTab"
SkinsTabButton.Size = UDim2.fromOffset(90, WindowConfig.ShopTabHeight)
SkinsTabButton.Position = UDim2.fromOffset(90, 0)
SkinsTabButton.BackgroundColor3 = Colors.Tab
SkinsTabButton.BorderSizePixel = 0
SkinsTabButton.Font = Enum.Font.SourceSansSemibold
SkinsTabButton.Text = "Skins"
SkinsTabButton.TextColor3 = Colors.Gray
SkinsTabButton.TextSize = 13
SkinsTabButton.AutoButtonColor = false
SkinsTabButton.Parent = ShopTabBar

CasesPage = Instance.new("Frame")
CasesPage.Name = "CasesPage"
CasesPage.Size = UDim2.new(1, 0, 1, -WindowConfig.ShopTabHeight)
CasesPage.Position = UDim2.fromOffset(0, WindowConfig.ShopTabHeight)
CasesPage.BackgroundTransparency = 1
CasesPage.Visible = true
CasesPage.Parent = ShopPage

CaseScroll = Instance.new("ScrollingFrame")
CaseScroll.Name = "CaseScroll"
CaseScroll.Size = UDim2.new(1, -16, 0, 86)
CaseScroll.Position = UDim2.fromOffset(8, 4)
CaseScroll.BackgroundColor3 = Colors.Dark
CaseScroll.BorderSizePixel = 0
CaseScroll.ScrollBarThickness = 4
CaseScroll.ScrollBarImageColor3 = Colors.Button
CaseScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CaseScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
CaseScroll.ScrollingDirection = Enum.ScrollingDirection.X
CaseScroll.Parent = CasesPage

CaseLayout = Instance.new("UIListLayout")
CaseLayout.FillDirection = Enum.FillDirection.Horizontal
CaseLayout.Padding = UDim.new(0, 4)
CaseLayout.SortOrder = Enum.SortOrder.LayoutOrder
CaseLayout.Parent = CaseScroll

local CasePadding = Instance.new("UIPadding")
CasePadding.PaddingLeft = UDim.new(0, 4)
CasePadding.PaddingTop = UDim.new(0, 4)
CasePadding.PaddingRight = UDim.new(0, 4)
CasePadding.Parent = CaseScroll

ChancesPanel = Instance.new("Frame")
ChancesPanel.Name = "ChancesPanel"
ChancesPanel.Size = UDim2.new(1, -16, 0, 140)
ChancesPanel.Position = UDim2.fromOffset(8, 94)
ChancesPanel.BackgroundColor3 = Colors.Dark
ChancesPanel.BorderSizePixel = 0
ChancesPanel.Parent = CasesPage

ChancesLayout = Instance.new("UIListLayout")
ChancesLayout.FillDirection = Enum.FillDirection.Vertical
ChancesLayout.Padding = UDim.new(0, 0)
ChancesLayout.SortOrder = Enum.SortOrder.LayoutOrder
ChancesLayout.Parent = ChancesPanel

local ChancesPadding = Instance.new("UIPadding")
ChancesPadding.PaddingLeft = UDim.new(0, 8)
ChancesPadding.PaddingTop = UDim.new(0, 4)
ChancesPadding.PaddingRight = UDim.new(0, 8)
ChancesPadding.Parent = ChancesPanel

for Index, Title in ipairs(TitleOrder) do
	local Row = Instance.new("TextLabel")
	Row.Name = Title .. "Row"
	Row.Size = UDim2.new(1, 0, 0, 18)
	Row.BackgroundTransparency = 1
	Row.Font = Enum.Font.SourceSans
	Row.LayoutOrder = Index
	Row.Text = Title .. " : —"
	Row.TextColor3 = TitleColors[Title]
	Row.TextSize = 13
	Row.TextXAlignment = Enum.TextXAlignment.Left
	Row.Parent = ChancesPanel

	ChanceRows[Title] = Row
end

OpenCaseButton = Instance.new("TextButton")
OpenCaseButton.Name = "OpenCaseButton"
OpenCaseButton.Size = UDim2.new(1, -16, 0, 26)
OpenCaseButton.Position = UDim2.new(0, 8, 1, -32)
OpenCaseButton.BackgroundColor3 = Colors.Button
OpenCaseButton.BorderSizePixel = 0
OpenCaseButton.Font = Enum.Font.SourceSansSemibold
OpenCaseButton.Text = "SELECT A CASE"
OpenCaseButton.TextColor3 = Colors.White
OpenCaseButton.TextSize = 14
OpenCaseButton.AutoButtonColor = false
OpenCaseButton.Parent = CasesPage

SkinsPage = Instance.new("Frame")
SkinsPage.Name = "SkinsPage"
SkinsPage.Size = UDim2.new(1, 0, 1, -WindowConfig.ShopTabHeight)
SkinsPage.Position = UDim2.fromOffset(0, WindowConfig.ShopTabHeight)
SkinsPage.BackgroundTransparency = 1
SkinsPage.Visible = false
SkinsPage.Parent = ShopPage

ShopLabel = Instance.new("TextLabel")
ShopLabel.Name = "ShopLabel"
ShopLabel.Size = UDim2.new(1, -16, 0, 18)
ShopLabel.Position = UDim2.fromOffset(8, 6)
ShopLabel.BackgroundTransparency = 1
ShopLabel.Font = Enum.Font.SourceSans
ShopLabel.Text = "Click a bear to buy"
ShopLabel.TextColor3 = Colors.Gray
ShopLabel.TextSize = 14
ShopLabel.TextXAlignment = Enum.TextXAlignment.Left
ShopLabel.Parent = SkinsPage

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
ShopScroll.Parent = SkinsPage

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

AdminPanel = Instance.new("Frame")
AdminPanel.Name = "AdminPanel"
AdminPanel.Size = AdminConfig.Size
AdminPanel.Position = UDim2.new(1, -300, 0.5, -AdminConfig.Size.Y.Offset / 2)
AdminPanel.BackgroundColor3 = Colors.AdminDark
AdminPanel.BorderSizePixel = 0
AdminPanel.Visible = false
AdminPanel.ZIndex = 20
AdminPanel.Parent = ScreenGui

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

local CaseAdminHeader = Instance.new("TextLabel")
CaseAdminHeader.Size = UDim2.new(1, -20, 0, 16)
CaseAdminHeader.Position = UDim2.fromOffset(10, 174)
CaseAdminHeader.BackgroundTransparency = 1
CaseAdminHeader.Font = Enum.Font.SourceSansSemibold
CaseAdminHeader.Text = "Open Case (Free)"
CaseAdminHeader.TextColor3 = Colors.Accent
CaseAdminHeader.TextSize = 13
CaseAdminHeader.TextXAlignment = Enum.TextXAlignment.Left
CaseAdminHeader.ZIndex = 21
CaseAdminHeader.Parent = AdminPanel

local AdminCaseScroll = Instance.new("ScrollingFrame")
AdminCaseScroll.Name = "AdminCaseScroll"
AdminCaseScroll.Size = UDim2.new(1, -20, 0, 48)
AdminCaseScroll.Position = UDim2.fromOffset(10, 192)
AdminCaseScroll.BackgroundColor3 = Colors.Dark
AdminCaseScroll.BorderSizePixel = 0
AdminCaseScroll.ScrollBarThickness = 3
AdminCaseScroll.ScrollBarImageColor3 = Colors.Button
AdminCaseScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
AdminCaseScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
AdminCaseScroll.ScrollingDirection = Enum.ScrollingDirection.X
AdminCaseScroll.ZIndex = 21
AdminCaseScroll.Parent = AdminPanel

local AdminCaseLayout = Instance.new("UIListLayout")
AdminCaseLayout.FillDirection = Enum.FillDirection.Horizontal
AdminCaseLayout.Padding = UDim.new(0, 4)
AdminCaseLayout.SortOrder = Enum.SortOrder.LayoutOrder
AdminCaseLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
AdminCaseLayout.Parent = AdminCaseScroll

local AdminCasePadding = Instance.new("UIPadding")
AdminCasePadding.PaddingRight = UDim.new(0, 4)
AdminCasePadding.PaddingLeft = UDim.new(0, 4)
AdminCasePadding.PaddingTop = UDim.new(0, 4)
AdminCasePadding.PaddingBottom = UDim.new(0, 4)
AdminCasePadding.Parent = AdminCaseScroll

for Index, CaseKey in ipairs(CaseOrder) do
	local CaseData = Cases[CaseKey]

	local CaseBtn = Instance.new("TextButton")
	CaseBtn.Name = CaseKey .. "AdminBtn"
	CaseBtn.Size = UDim2.fromOffset(50, 40)
	CaseBtn.BackgroundColor3 = Colors.Button
	CaseBtn.BorderSizePixel = 0
	CaseBtn.Font = Enum.Font.SourceSansSemibold
	CaseBtn.Text = CaseKey
	CaseBtn.TextColor3 = Colors.White
	CaseBtn.TextSize = 11
	CaseBtn.LayoutOrder = Index
	CaseBtn.AutoButtonColor = false
	CaseBtn.ZIndex = 22
	CaseBtn.Parent = AdminCaseScroll

	local CaseBtnStroke = Instance.new("UIStroke")
	CaseBtnStroke.Color = CaseData.Color
	CaseBtnStroke.Thickness = 1
	CaseBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	CaseBtnStroke.Parent = CaseBtn

	CaseBtn.MouseEnter:Connect(function()
		TweenService:Create(CaseBtn, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
	end)

	CaseBtn.MouseLeave:Connect(function()
		TweenService:Create(CaseBtn, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
	end)

	CaseBtn.MouseButton1Click:Connect(function()
		PlaySound("Select")
		OpenCase(CaseKey, true)
	end)
end

local DupHeader = Instance.new("TextLabel")
DupHeader.Size = UDim2.new(1, -20, 0, 16)
DupHeader.Position = UDim2.fromOffset(10, 246)
DupHeader.BackgroundTransparency = 1
DupHeader.Font = Enum.Font.SourceSansSemibold
DupHeader.Text = "Duplicate"
DupHeader.TextColor3 = Colors.White
DupHeader.TextSize = 13
DupHeader.TextXAlignment = Enum.TextXAlignment.Left
DupHeader.ZIndex = 21
DupHeader.Parent = AdminPanel

local DupSelectedBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(10, 264), UDim2.fromOffset(132, 22), "Dup Selected", Colors.Button)
DupSelectedBtn.ZIndex = 21

local DupAllBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(148, 264), UDim2.fromOffset(132, 22), "Dup All", Colors.Button)
DupAllBtn.ZIndex = 21

DupSelectedBtn.MouseButton1Click:Connect(function()
	if not SelectedBearIndex or not Inventory[SelectedBearIndex] then
		Notify("Select a bear first", "error")

		return
	end

	local BearId = Inventory[SelectedBearIndex]
	table.insert(Inventory, BearId)
	Notify("Duplicated : $" .. tostring(Bears[BearId].Value), "success")
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
DangerHeader.Position = UDim2.fromOffset(10, 294)
DangerHeader.BackgroundTransparency = 1
DangerHeader.Font = Enum.Font.SourceSansSemibold
DangerHeader.Text = "Danger Zone"
DangerHeader.TextColor3 = Colors.Danger
DangerHeader.TextSize = 13
DangerHeader.TextXAlignment = Enum.TextXAlignment.Left
DangerHeader.ZIndex = 21
DangerHeader.Parent = AdminPanel

local ClearInvBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(10, 312), UDim2.fromOffset(132, 22), "Clear Inv", Colors.Button)
ClearInvBtn.ZIndex = 21

local MaxOutBtn = CreateAdminButton(AdminPanel, UDim2.fromOffset(148, 312), UDim2.fromOffset(132, 22), "Max Out", Colors.Button)
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
		return Bears[A].Value < Bears[B].Value
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
BearPicker.Parent = ScreenGui

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

NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "Notifications"
NotificationHolder.Size = UDim2.fromScale(1, 1)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 40
NotificationHolder.Parent = ScreenGui

-----/Init/-----
CreateSound("Select", Sounds.Select, 0.4)
CreateSound("Hover", Sounds.Hover, 0.2)
CreateSound("Sell", Sounds.Sell, 0.5)
CreateSound("Buy", Sounds.Buy, 0.5)
CreateSound("Win", Sounds.Win, 0.7)
CreateSound("Lose", Sounds.Lose, 0.5)

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
	if IsRolling then

		return
	end

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
	PlaySound("Select")
	SetTab("upgrade")
end)

ShopTabButton.MouseButton1Click:Connect(function()
	PlaySound("Select")
	SetTab("shop")
end)

UpgradeTabButton.MouseEnter:Connect(function()
	if ActiveTab == "upgrade" then

		return
	end

	TweenService:Create(UpgradeTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

UpgradeTabButton.MouseLeave:Connect(function()
	if ActiveTab == "upgrade" then

		return
	end

	TweenService:Create(UpgradeTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Tab }):Play()
end)

ShopTabButton.MouseEnter:Connect(function()
	if ActiveTab == "shop" then

		return
	end

	TweenService:Create(ShopTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

ShopTabButton.MouseLeave:Connect(function()
	if ActiveTab == "shop" then

		return
	end

	TweenService:Create(ShopTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Tab }):Play()
end)

CasesTabButton.MouseButton1Click:Connect(function()
	PlaySound("Select")
	SetShopTab("cases")
end)

SkinsTabButton.MouseButton1Click:Connect(function()
	PlaySound("Select")
	SetShopTab("skins")
end)

CasesTabButton.MouseEnter:Connect(function()
	if ActiveShopTab == "cases" then

		return
	end

	TweenService:Create(CasesTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

CasesTabButton.MouseLeave:Connect(function()
	if ActiveShopTab == "cases" then

		return
	end

	TweenService:Create(CasesTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Tab }):Play()
end)

SkinsTabButton.MouseEnter:Connect(function()
	if ActiveShopTab == "skins" then

		return
	end

	TweenService:Create(SkinsTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

SkinsTabButton.MouseLeave:Connect(function()
	if ActiveShopTab == "skins" then

		return
	end

	TweenService:Create(SkinsTabButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Tab }):Play()
end)

OpenCaseButton.MouseEnter:Connect(function()
	if not SelectedCaseKey then

		return
	end

	TweenService:Create(OpenCaseButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

OpenCaseButton.MouseLeave:Connect(function()
	if not SelectedCaseKey then

		return
	end

	TweenService:Create(OpenCaseButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Button }):Play()
end)

OpenCaseButton.MouseButton1Click:Connect(function()
	if not SelectedCaseKey then
		Notify("Select a case first", "error")

		return
	end

	OpenCase(SelectedCaseKey, false)
end)

UpgradeButton.MouseEnter:Connect(function()
	if IsRolling then

		return
	end

	TweenService:Create(UpgradeButton, TweenInfo.new(0.1), { BackgroundColor3 = Colors.Hover }):Play()
end)

UpgradeButton.MouseLeave:Connect(function()
	if IsRolling then

		return
	end

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

SetShopTab("cases")

RefreshInventory()
RefreshTarget()
RefreshShop()
RefreshCases()
UpdateInfo()
UpdateMoney()

task.spawn(function()
	local StartTime = tick()

	pcall(PreloadAllAssets)

	local Elapsed = tick() - StartTime

	if Elapsed < LoadingConfig.MinShowTime then
		task.wait(LoadingConfig.MinShowTime - Elapsed)
	end

	local FadeTime = LoadingConfig.FadeTime

	TweenService:Create(LoadingFrame, TweenInfo.new(FadeTime), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(LoadingStroke, TweenInfo.new(FadeTime), { Transparency = 1 }):Play()
	TweenService:Create(LoadingTitle, TweenInfo.new(FadeTime), { TextTransparency = 1 }):Play()
	TweenService:Create(LoadingStatus, TweenInfo.new(FadeTime), { TextTransparency = 1 }):Play()
	TweenService:Create(LoadingBar, TweenInfo.new(FadeTime), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(LoadingFill, TweenInfo.new(FadeTime), { BackgroundTransparency = 1 }):Play()

	task.wait(FadeTime)

	LoadingFrame:Destroy()

	Holder.Visible = true

	print("🟢 | Successfully : Assets loaded — UI revealed")
end)

print("🟢 | Successfully : Upgrader initialized")
