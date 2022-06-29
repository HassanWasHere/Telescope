local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Telescope = Workspace.Telescope
local ViewingLens = Telescope.Lens1
local LocalPlayer = game.Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Gui = script:WaitForChild("ScreenGui")
local CurrentGui = nil

local Distance = 10
local TelescopeActivated = false

local TelescopeProperties = { -- Settings for telescope
	Distance = 100,
	MoveSpeed = 1.2,
	MoveSmoothness = 0.05,
	RotationLimit = 80
}

local OriginalHeadCF = nil

local Tweens = { -- Animations, function to dynamically create the animation based on current character position
	["ViewingLens"] = function()
		return TweenService:Create(
			Camera, 
			TweenInfo.new(1), 
			{["CFrame"] = ViewingLens.CFrame * CFrame.Angles(0, 0, math.rad(90))}
		)
	end,
	["BackToCharacter"] = function() 
		return TweenService:Create(
			Camera,
			TweenInfo.new(1),
			{["CFrame"] = LocalPlayer.Character.Head.CFrame * OriginalHeadCF}
		)
	end
}

local Angles = { -- Store all the angles that are used for the rotation of the camera
	X = 0,
	Y = 0,
	TargetX = 0,
	TargetY = 0
}


ProximityPromptService.PromptTriggered:Connect(function(Prompt, Player) -- Hook onto the proximity prompt already placed into the telescope
	if Player == LocalPlayer and Prompt.Parent.Parent.Name == "Telescope" then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseDeltaSensitivity = 1
		OriginalHeadCF = LocalPlayer.Character.Head.CFrame:ToObjectSpace(Camera.CFrame)
		local CurrentTween = Tweens["ViewingLens"]()
		CurrentTween:Play()
		CurrentTween.Completed:Connect(function()
			CurrentGui = Gui:Clone()
			CurrentGui.Parent = LocalPlayer.PlayerGui
			TelescopeActivated = true
			Camera.CameraType = "Scriptable"
			Camera.FieldOfView = 10
			Telescope.Parent = LocalPlayer.Character
			Angles.X = 0
			Angles.Y = 0
			Angles.TargetX = 0
			Angles.TargetY = 0
		end)
	end
end)




UserInputService.InputChanged:connect(function(Object) -- Capture mouse movement, move camera accordingly
	if Object.UserInputType == Enum.UserInputType.MouseMovement and TelescopeActivated then
		local Delta = Vector2.new(Object.Delta.x/TelescopeProperties.MoveSpeed,Object.Delta.y/TelescopeProperties.MoveSpeed) * TelescopeProperties.MoveSmoothness

		local X = Angles.TargetX - Delta.y
		local Y = Angles.TargetY - Delta.x
		Angles.TargetX = (X >= TelescopeProperties.RotationLimit and TelescopeProperties.RotationLimit) or (X <= -TelescopeProperties.RotationLimit and -TelescopeProperties.RotationLimit) or X -- Lock rotation limit to rotation limit degrees
		Angles.TargetY = (Y >= TelescopeProperties.RotationLimit and TelescopeProperties.RotationLimit) or (Y <= -TelescopeProperties.RotationLimit and -TelescopeProperties.RotationLimit) or Y

		Angles.X += (Angles.TargetX - Angles.X) *0.35
		Angles.Y += (Angles.TargetY - Angles.Y) *0.15

		Camera.CFrame = CFrame.new(Telescope.Lens2.Position + Vector3.new(5,0,0), -Telescope.Lens2.CFrame.LookVector * Distance) * CFrame.Angles(math.rad(Angles.X), math.rad(Angles.Y),0)
		-- Move the camera, set the angle between the lens and where it's looking and set the rotation
	end
end)

UserInputService.InputBegan:connect(function(Object)
	if Object.KeyCode == Enum.KeyCode.E and TelescopeActivated then -- When E is pressed, exit the telescope
		Camera.FieldOfView = 70
		TelescopeActivated = false
		local CurrentTween = Tweens["BackToCharacter"]()
		CurrentTween:Play()
		if CurrentGui then
			CurrentGui:Destroy()
		end
		CurrentTween.Completed:connect(function()
			Camera.CameraType = "Custom"
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end
end)
