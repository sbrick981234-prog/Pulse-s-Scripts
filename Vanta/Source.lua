-----/UI/-----
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/sbrick981234-prog/Pulse-s-Scripts/refs/heads/main/Larp%20UI/Source.lua"))()

-----/Services/-----
local Players = game:GetService("Players")

-----/Variables/-----
local Player = Players.LocalPlayer

local ESPColor = Color3.fromRGB(255, 255, 255)

-----/Functions/-----
local function ESPModel(Model : Model, State : boolean)
	local ESP = Model:FindFirstChild("LarpESP")

	if State then
		if not ESP then
			ESP = Instance.new("Highlight")
			ESP.Name = "LarpESP"
			ESP.FillColor = ESPColor
			ESP.FillTransparency = 0.5
			ESP.OutlineColor = ESPColor
			ESP.OutlineTransparency = 0
			ESP.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			ESP.Parent = Model
		end
	else
		if ESP then
			ESP:Destroy()
		end
	end
end

-----/Main/-----
local Window = UILib:CreateWindow("Vanta")

-----/Visual/-----
local VisualTab = Window:CreateTab("Visual")

VisualTab:CreateLabel("Main")

VisualTab:CreateToggle({
	Text = "ESP",
	Default = false,

	Callback = function(State)
		for _, Character in ipairs(workspace:GetDescendants()) do
			if Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") then
				ESPModel(Character, State)
			end
		end
	end
})

VisualTab:CreateLabel("Settings")
