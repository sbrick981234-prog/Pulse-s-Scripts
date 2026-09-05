local UILib = require(game.ReplicatedStorage.LarpUI)

local Window = UILib:CreateWindow("Test")
local Tab = Window:CreateTab("Main")

Tab:CreateButton({
	Text = "Click",
	
	Callback = function()
		print("Clicked")
	end
})

Tab:CreateToggle({
	Text = "Toggle",
	Default = false,
	
	Callback = function(State)
		print(State)
	end
})

Tab:CreateSlider({
	Text = "Slider",
	Min = 0,
	Max = 100,
	Default = 50,
	
	Callback = function(Value)
		print(Value)
	end
})

Tab:CreateDropdown({
	Text = "ABC",
	Options = {"A", "B", "C"},
	Default = "A",
	
	Callback = function(Option)
		print(Option)
	end
})

Tab:CreateTextbox({
	Text = "",
	Placeholder = "Enter text here",
	
	Callback = function(Text, EnterPressed)
		print(Text)
	end
})

Tab:CreateLabel("Cool text")
