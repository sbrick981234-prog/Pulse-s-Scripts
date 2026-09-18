-----/Services/-----
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-----/Variables/-----
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
local Animator = Humanoid:FindFirstChildOfClass("Animator") or Humanoid:WaitForChild("Animator")
local Backpack = Player:FindFirstChild("Backpack") or Player:WaitForChild("Backpack")

local Doing = false
local AnimTrack = nil
local Animation = nil

-----/Assets/-----
local R6AnimationId = "rbxassetid://186904307"

-----/Values/-----
local Settings = {
	AnimationSpeed = 0.1,
	LoopDelay = 0.3,
	StopTimePosition = 0.6,
	NotifyRetries = 10,
	NotifyRetryDelay = 0.5,
}

-----/Functions/-----
local function GetRigType() : string
	return Humanoid.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
end

local function Notify(Title : string, Text : string, Duration : number)
	for _ = 1, Settings.NotifyRetries do
		local Success = pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = Title,
				Text = Text or "",
				Duration = Duration,
			})
		end)

		if Success then
			return
		end

		task.wait(Settings.NotifyRetryDelay)
	end
end

local function DestroyAnimTrack()
	if AnimTrack then
		AnimTrack:Stop()
		AnimTrack:Destroy()
		AnimTrack = nil
	end
end

local function StartSalute()
	Doing = true

	while Doing do
		if not AnimTrack and Animation then
			AnimTrack = Animator:LoadAnimation(Animation)
		end

		if AnimTrack then
			AnimTrack:Play()
			AnimTrack:AdjustSpeed(Settings.AnimationSpeed)
		end

		task.wait(Settings.LoopDelay)

		while Doing and AnimTrack and AnimTrack.TimePosition < Settings.StopTimePosition do
			task.wait(1)
		end

		DestroyAnimTrack()
	end
end

local function StopSalute()
	Doing = false
	DestroyAnimTrack()
end

-----/Main/-----
if workspace:FindFirstChild("Heil") then
	workspace:FindFirstChild("Heil"):Destroy()
end

Notify("skidded by gpjc", "Salute on them!", 4)

Animation = Instance.new("Animation")
Animation.Name = "Heil"
Animation.AnimationId = R6AnimationId
Animation.Parent = workspace

local Tool = Instance.new("Tool")
Tool.Name = "Salute!"
Tool.RequiresHandle = false
Tool.Parent = Backpack

Tool.Equipped:Connect(StartSalute)
Tool.Unequipped:Connect(StopSalute)
Humanoid.Died:Connect(StopSalute)
