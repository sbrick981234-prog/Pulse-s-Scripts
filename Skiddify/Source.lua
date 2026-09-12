-----/Services/-----
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-----/Variables/-----
local Player = Players.LocalPlayer
local Skiddify = script.Parent

local MainFrame = Skiddify:WaitForChild("MainFrame")
local MusicList = MainFrame:WaitForChild("MusicList")

local PlayerFrame = MainFrame:FindFirstChild("PlayerFrame")
local Settings = MainFrame:FindFirstChild("Settings")
local MusicIcon = MainFrame:FindFirstChild("MusicIcon", true)

local CurrentSound = nil
local CurrentIndex = 0

local IsPlaying = false
local IsMuted = false
local IsLooped = false

local DefaultVolume = 1
local DefaultSpeed = 1
local DefaultPitch = 1

local IconID = "103855092595603"

local Tracks = {}

-----/Assets/-----
local SkiddifySound = Instance.new("Sound")
SkiddifySound.Name = "SkiddifySound"
SkiddifySound.Volume = 1
SkiddifySound.PlaybackSpeed = 1
SkiddifySound.Looped = false
SkiddifySound.Parent = SoundService

CurrentSound = SkiddifySound

-----/Modules/-----
local function Create(ClassName, Properties, Parent)
	local Object = Instance.new(ClassName)

	for Property, Value in pairs(Properties) do
		Object[Property] = Value
	end

	Object.Parent = Parent

	return Object
end

local function Tween(Object, Time, Properties)
	local Animation = TweenService:Create(
		Object,
		TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Properties
	)

	Animation:Play()

	return Animation
end

local function CreateCorner(Object, Radius)
	local Corner = Object:FindFirstChildOfClass("UICorner")

	if not Corner then
		Corner = Instance.new("UICorner")
		Corner.Parent = Object
	end

	Corner.CornerRadius = UDim.new(0, Radius)

	return Corner
end

local function CreateStroke(Object)
	local Stroke = Object:FindFirstChildOfClass("UIStroke")

	if not Stroke then
		Stroke = Instance.new("UIStroke")
		Stroke.Parent = Object
	end

	Stroke.Color = Color3.fromRGB(255, 255, 255)
	Stroke.Transparency = 0.8
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	return Stroke
end

local function FindObject(Name)
	return MainFrame:FindFirstChild(Name, true)
end

local function FindTextButton(Name)
	local Object = FindObject(Name)

	if Object and Object:IsA("TextButton") then
		return Object
	end

	return nil
end

local function GetSoundId(Id)
	Id = tostring(Id)

	Id = Id:gsub("rbxassetid://", "")
	Id = Id:gsub("rbxasset://", "")
	Id = Id:gsub("%s+", "")

	return Id
end

-----/Icon/-----
local function SetIconID(Id)
	Id = tostring(Id)

	Id = Id:gsub("rbxassetid://", "")
	Id = Id:gsub("rbxasset://", "")
	Id = Id:gsub("%s+", "")

	if Id == "" then
		return false
	end

	IconID = Id

	if MusicIcon and MusicIcon:IsA("ImageLabel") then
		MusicIcon.Image = "rbxassetid://" .. IconID
	end

	return true
end

SetIconID(IconID)

-----/PlayerFrame/-----
if not PlayerFrame then
	PlayerFrame = Create("Frame", {
		Name = "PlayerFrame",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 50)
	}, MainFrame)
end

local ButtonContainer = PlayerFrame:FindFirstChild("Container")

if not ButtonContainer then
	ButtonContainer = Create("Frame", {
		Name = "Container",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0)
	}, PlayerFrame)
end

local ButtonLayout = ButtonContainer:FindFirstChildOfClass("UIListLayout")

if not ButtonLayout then
	ButtonLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, ButtonContainer)
end

-----/Buttons/-----
local function CreateButton(Name, Text, LayoutOrder)
	local Existing = FindTextButton(Name)

	if Existing then
		return Existing
	end

	local Button = Create("TextButton", {
		Name = Name,
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 38, 0, 30),
		Font = Enum.Font.Code,
		Text = Text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		AutoButtonColor = false,
		LayoutOrder = LayoutOrder
	}, ButtonContainer)

	CreateCorner(Button, 10)
	CreateStroke(Button)

	Button.MouseEnter:Connect(function()
		Tween(Button, 0.1, {
			BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		})
	end)

	Button.MouseLeave:Connect(function()
		Tween(Button, 0.1, {
			BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		})
	end)

	return Button
end

local PreviousButton = CreateButton("PreviousButton", "◀", 1)
local PlayButton = CreateButton("PlayButton", "▶", 2)
local NextButton = CreateButton("NextButton", "▶", 3)
local AddButton = CreateButton("AddButton", "+", 4)
local ImportButton = CreateButton("ImportButton", "↓", 5)
local ExportButton = CreateButton("ExportButton", "↑", 6)
local IconButton = CreateButton("IconButton", "Icon", 7)

-----/Functions/-----
local function StopSound()
	if not CurrentSound then
		return
	end

	CurrentSound:Stop()

	IsPlaying = false
	PlayButton.Text = "▶"
end

local function ApplyTrackSettings(Track)
	if not CurrentSound then
		return
	end

	local Volume = tonumber(Track.Volume) or DefaultVolume
	local Speed = tonumber(Track.Speed) or DefaultSpeed
	local Pitch = tonumber(Track.Pitch) or DefaultPitch

	if IsMuted then
		CurrentSound.Volume = 0
	else
		CurrentSound.Volume = Volume
	end

	CurrentSound.PlaybackSpeed = Speed

	local PitchEffect = CurrentSound:FindFirstChild("PitchEffect")

	if not PitchEffect then
		PitchEffect = Instance.new("PitchShiftSoundEffect")
		PitchEffect.Name = "PitchEffect"
		PitchEffect.Parent = CurrentSound
	end

	PitchEffect.Octave = Pitch
end

local function PlayTrack(Index)
	local Track = Tracks[Index]

	if not Track then
		return
	end

	CurrentIndex = Index

	CurrentSound:Stop()

	CurrentSound.SoundId = "rbxassetid://" .. GetSoundId(Track.Id)

	ApplyTrackSettings(Track)

	local Success, ErrorMessage = pcall(function()
		CurrentSound:Play()
	end)

	if not Success then
		print("Skiddify | Play Error | " .. tostring(ErrorMessage))
		return
	end

	IsPlaying = true
	PlayButton.Text = "Ⅱ"

	if MusicIcon and MusicIcon:IsA("ImageLabel") then
		MusicIcon.Image = "rbxassetid://" .. IconID
	end
end

local function PlayCurrent()
	if #Tracks == 0 then
		return
	end

	if CurrentIndex <= 0 then
		CurrentIndex = 1
	end

	if IsPlaying then
		CurrentSound:Pause()

		IsPlaying = false
		PlayButton.Text = "▶"

		return
	end

	if CurrentSound.TimePosition > 0 then
		CurrentSound:Resume()
	else
		PlayTrack(CurrentIndex)

		return
	end

	IsPlaying = true
	PlayButton.Text = "Ⅱ"
end

local function NextTrack()
	if #Tracks == 0 then
		return
	end

	CurrentIndex += 1

	if CurrentIndex > #Tracks then
		CurrentIndex = 1
	end

	PlayTrack(CurrentIndex)
end

local function PreviousTrack()
	if #Tracks == 0 then
		return
	end

	CurrentIndex -= 1

	if CurrentIndex < 1 then
		CurrentIndex = #Tracks
	end

	PlayTrack(CurrentIndex)
end

-----/MusicList/-----
local function CreateTrackItem(Track, Index)
	local Existing = MusicList:FindFirstChild("Track_" .. Index)

	if Existing then
		Existing:Destroy()
	end

	local Item = Create("TextButton", {
		Name = "Track_" .. Index,
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -10, 0, 42),
		Font = Enum.Font.Code,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = Index
	}, MusicList)

	CreateCorner(Item, 8)
	CreateStroke(Item)

	local Title = Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Font = Enum.Font.Code,
		Text = Track.Name or Track.Id,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Item)

	local Delete = Create("TextButton", {
		Name = "Delete",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -40, 0, 0),
		Size = UDim2.new(0, 40, 1, 0),
		Font = Enum.Font.Code,
		Text = "×",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AutoButtonColor = false
	}, Item)

	Item.MouseEnter:Connect(function()
		Tween(Item, 0.1, {
			BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		})
	end)

	Item.MouseLeave:Connect(function()
		Tween(Item, 0.1, {
			BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		})
	end)

	Item.MouseButton1Click:Connect(function()
		PlayTrack(Index)
	end)

	Delete.MouseButton1Click:Connect(function()
		local WasCurrent = CurrentIndex == Index

		table.remove(Tracks, Index)

		if WasCurrent then
			StopSound()

			if #Tracks > 0 then
				CurrentIndex = math.clamp(Index, 1, #Tracks)
				PlayTrack(CurrentIndex)
			else
				CurrentIndex = 0
			end
		elseif CurrentIndex > Index then
			CurrentIndex -= 1
		end

		RefreshList()
	end)

	return Item
end

function RefreshList()
	for _, Child in ipairs(MusicList:GetChildren()) do
		if Child:IsA("TextButton") and Child.Name:match("^Track_") then
			Child:Destroy()
		end
	end

	for Index, Track in ipairs(Tracks) do
		CreateTrackItem(Track, Index)
	end

	MusicList.CanvasSize = UDim2.new(
		0,
		0,
		0,
		#Tracks * 47
	)
end

local function AddTrack(Id, Name, Volume, Speed, Pitch)
	Id = GetSoundId(Id)

	if Id == "" then
		return
	end

	table.insert(Tracks, {
		Id = Id,
		Name = Name or Id,
		Volume = tonumber(Volume) or 1,
		Speed = tonumber(Speed) or 1,
		Pitch = tonumber(Pitch) or 1
	})

	RefreshList()

	if CurrentIndex == 0 then
		CurrentIndex = 1
	end
end

-----/AddWindow/-----
local AddFrame = Create("Frame", {
	Name = "AddMusic",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -150, 0.5, -70),
	Size = UDim2.new(0, 300, 0, 140),
	Visible = false,
	ZIndex = 100
}, Skiddify)

CreateCorner(AddFrame, 10)
CreateStroke(AddFrame)

local AddTitle = Create("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 5),
	Size = UDim2.new(1, -30, 0, 25),
	Font = Enum.Font.Code,
	Text = "Add Music",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 101
}, AddFrame)

local AddBox = Create("TextBox", {
	Name = "SoundId",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 0, 35),
	Size = UDim2.new(1, -30, 0, 40),
	ClearTextOnFocus = false,
	Font = Enum.Font.Code,
	PlaceholderText = "Sound ID",
	Text = "",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 14,
	ZIndex = 101
}, AddFrame)

CreateCorner(AddBox, 8)
CreateStroke(AddBox)

local ConfirmAdd = Create("TextButton", {
	Name = "Confirm",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 1, -55),
	Size = UDim2.new(1, -30, 0, 35),
	Font = Enum.Font.Code,
	Text = "Add",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	ZIndex = 101
}, AddFrame)

CreateCorner(ConfirmAdd, 8)
CreateStroke(ConfirmAdd)

local function OpenAdd()
	AddFrame.Visible = true
	AddBox:CaptureFocus()
end

local function CloseAdd()
	AddFrame.Visible = false
	AddBox:ReleaseFocus()
end

-----/IconSettings/-----
local IconSettings = Create("Frame", {
	Name = "IconSettings",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -150, 0.5, -70),
	Size = UDim2.new(0, 300, 0, 160),
	Visible = false,
	ZIndex = 100
}, Skiddify)

CreateCorner(IconSettings, 10)
CreateStroke(IconSettings)

local IconTitle = Create("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 8),
	Size = UDim2.new(1, -30, 0, 25),
	Font = Enum.Font.Code,
	Text = "Icon ID",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 101
}, IconSettings)

local IconBox = Create("TextBox", {
	Name = "IconID",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 0, 40),
	Size = UDim2.new(1, -30, 0, 40),
	ClearTextOnFocus = false,
	Font = Enum.Font.Code,
	PlaceholderText = "Icon ID",
	Text = IconID,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	ZIndex = 101
}, IconSettings)

CreateCorner(IconBox, 8)
CreateStroke(IconBox)

local ApplyIcon = Create("TextButton", {
	Name = "Apply",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 1, -55),
	Size = UDim2.new(1, -30, 0, 35),
	Font = Enum.Font.Code,
	Text = "Apply",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	ZIndex = 101
}, IconSettings)

CreateCorner(ApplyIcon, 8)
CreateStroke(ApplyIcon)

-----/ImportExport/-----
local ImportFrame = Create("Frame", {
	Name = "ImportExport",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, -175, 0.5, -100),
	Size = UDim2.new(0, 350, 0, 200),
	Visible = false,
	ZIndex = 100
}, Skiddify)

CreateCorner(ImportFrame, 10)
CreateStroke(ImportFrame)

local ImportTitle = Create("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 15, 0, 10),
	Size = UDim2.new(1, -30, 0, 25),
	Font = Enum.Font.Code,
	Text = "Import / Export",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 101
}, ImportFrame)

local ImportBox = Create("TextBox", {
	Name = "Input",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 0, 45),
	Size = UDim2.new(1, -30, 0, 70),
	ClearTextOnFocus = false,
	Font = Enum.Font.Code,
	MultiLine = true,
	PlaceholderText = "IconID-123456|123456:Volume-1:Speed-1:Pitch-1",
	Text = "",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ZIndex = 101
}, ImportFrame)

CreateCorner(ImportBox, 8)
CreateStroke(ImportBox)

local ConfirmImport = Create("TextButton", {
	Name = "ConfirmImport",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0, 15, 1, -45),
	Size = UDim2.new(0.48, -18, 0, 30),
	Font = Enum.Font.Code,
	Text = "Import",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	ZIndex = 101
}, ImportFrame)

CreateCorner(ConfirmImport, 8)
CreateStroke(ConfirmImport)

local CopyExport = Create("TextButton", {
	Name = "CopyExport",
	BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	BorderSizePixel = 0,
	Position = UDim2.new(0.52, 3, 1, -45),
	Size = UDim2.new(0.48, -18, 0, 30),
	Font = Enum.Font.Code,
	Text = "Copy",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	ZIndex = 101
}, ImportFrame)

CreateCorner(CopyExport, 8)
CreateStroke(CopyExport)

-----/ImportExportFunctions/-----
local function ExportTracks()
	local Exported = {}

	table.insert(
		Exported,
		"IconID-" .. tostring(IconID)
	)

	for _, Track in ipairs(Tracks) do
		table.insert(
			Exported,
			string.format(
				"%s:Volume-%s:Speed-%s:Pitch-%s",
				Track.Id,
				tostring(Track.Volume),
				tostring(Track.Speed),
				tostring(Track.Pitch)
			)
		)
	end

	return table.concat(Exported, "|")
end

local function ImportTracks(Data)
	if typeof(Data) ~= "string" then
		return
	end

	Tracks = {}
	CurrentIndex = 0

	local Parts = {}

	for Part in Data:gmatch("[^|]+") do
		table.insert(Parts, Part)
	end

	for _, Entry in ipairs(Parts) do
		Entry = Entry:gsub("^%s+", "")
		Entry = Entry:gsub("%s+$", "")

		local ImportedIconID = Entry:match("^IconID%-([^|]+)$")

		if ImportedIconID then
			SetIconID(ImportedIconID)
		else
			local Id = Entry:match("^([^:]+)")
			local Volume = Entry:match("Volume%-([^:]+)")
			local Speed = Entry:match("Speed%-([^:]+)")
			local Pitch = Entry:match("Pitch%-([^:]+)")

			if Id then
				AddTrack(
					Id,
					Id,
					tonumber(Volume) or 1,
					tonumber(Speed) or 1,
					tonumber(Pitch) or 1
				)
			end
		end
	end

	RefreshList()

	if #Tracks > 0 then
		CurrentIndex = 1
	end
end

local function OpenImport(Data)
	ImportFrame.Visible = true

	if Data then
		ImportBox.Text = Data
	else
		ImportBox.Text = ""
	end

	ImportBox:CaptureFocus()
end

local function CloseImport()
	ImportBox:ReleaseFocus()
	ImportFrame.Visible = false
end

-----/Events/-----
PreviousButton.MouseButton1Click:Connect(function()
	PreviousTrack()
end)

PlayButton.MouseButton1Click:Connect(function()
	PlayCurrent()
end)

NextButton.MouseButton1Click:Connect(function()
	NextTrack()
end)

AddButton.MouseButton1Click:Connect(function()
	OpenAdd()
end)

ConfirmAdd.MouseButton1Click:Connect(function()
	local Id = AddBox.Text

	if Id ~= "" then
		AddTrack(Id, Id, 1, 1, 1)
	end

	AddBox.Text = ""

	CloseAdd()
end)

IconButton.MouseButton1Click:Connect(function()
	IconBox.Text = IconID
	IconSettings.Visible = true
	IconBox:CaptureFocus()
end)

ApplyIcon.MouseButton1Click:Connect(function()
	if SetIconID(IconBox.Text) then
		IconBox.Text = IconID
		IconSettings.Visible = false
	end
end)

ImportButton.MouseButton1Click:Connect(function()
	OpenImport()
end)

ExportButton.MouseButton1Click:Connect(function()
	OpenImport(ExportTracks())
end)

ConfirmImport.MouseButton1Click:Connect(function()
	ImportTracks(ImportBox.Text)
	CloseImport()
end)

CopyExport.MouseButton1Click:Connect(function()
	local Data = ExportTracks()

	ImportBox.Text = Data

	if setclipboard then
		pcall(function()
			setclipboard(Data)
		end)
	end
end)

-----/Sound/-----
CurrentSound.Ended:Connect(function()
	IsPlaying = false
	PlayButton.Text = "▶"

	if IsLooped then
		PlayTrack(CurrentIndex)
	else
		NextTrack()
	end
end)

-----/Keyboard/-----
UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then
		return
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end

	if Input.KeyCode == Enum.KeyCode.Space then
		PlayCurrent()
	elseif Input.KeyCode == Enum.KeyCode.Right then
		NextTrack()
	elseif Input.KeyCode == Enum.KeyCode.Left then
		PreviousTrack()
	end
end)

-----/Init/-----
RefreshList()
SetIconID(IconID)

print("Skiddify | Loaded")
print("Skiddify | Tracks : " .. tostring(#Tracks))
print("Skiddify | IconID : " .. tostring(IconID))
print("Skiddify | Import / Export : Ready")
