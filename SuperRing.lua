--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--// SETTINGS
local radius = 50
local rotationSpeed = 2
local ringEnabled = false
local orbitAngle = 0
local parts = {}
local rainbowConnection
local telekinesisEnabled = false
local draggedPart = nil

--// GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SuperRingV9"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 260)
Main.Position = UDim2.new(0.5, -150, 0.5, -130)
Main.BackgroundColor3 = Color3.fromRGB(25,25,25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,15)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(0,170,255)
Stroke.Thickness = 2

-- TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundTransparency = 1
Title.Text = "Super Ring V9"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Stroke.Color
Title.Parent = Main

-- FULL DRAGGING
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Main.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- MINIMIZE & CLOSE
local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.new(0,30,0,30)
Minimize.Position = UDim2.new(1,-70,0,5)
Minimize.Text = "-"
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18
Minimize.BackgroundColor3 = Color3.fromRGB(45,45,45)
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.Parent = Main
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(1,0)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0,30,0,30)
Close.Position = UDim2.new(1,-35,0,5)
Close.Text = "X"
Close.Font = Enum.Font.GothamBold
Close.TextSize = 16
Close.BackgroundColor3 = Color3.fromRGB(170,50,50)
Close.TextColor3 = Color3.new(1,1,1)
Close.Parent = Main
Instance.new("UICorner", Close).CornerRadius = UDim.new(1,0)

local minimized = false
local originalSize = Main.Size
local uiElements = {} -- all buttons + frames

-- track all UI elements (excluding frame + stroke + title)
for _,v in pairs(Main:GetChildren()) do
	if v:IsA("TextButton") or v:IsA("Frame") then
		if v ~= Minimize and v ~= Close then
			table.insert(uiElements, v)
		end
	end
end

Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		Main:TweenSize(UDim2.new(0,300,0,45),"Out","Quad",0.25,true)
		for _,v in pairs(uiElements) do
			v.Visible = false
		end
		Minimize.Text = "+"
	else
		Main:TweenSize(originalSize,"Out","Quad",0.25,true)
		for _,v in pairs(uiElements) do
			v.Visible = true
		end
		Minimize.Text = "-"
	end
end)

Close.MouseButton1Click:Connect(function()
	ringEnabled = false
	telekinesisEnabled = false
	if rainbowConnection then rainbowConnection:Disconnect() end
	for _,part in ipairs(parts) do
		if part and part.Parent then
			part.Velocity = Vector3.zero
		end
	end
	ScreenGui:Destroy()
end)

-- TOGGLE BUTTON
local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1,-20,0,40)
Toggle.Position = UDim2.new(0,10,0,50)
Toggle.Text = "Ring: OFF"
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 16
Toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
Toggle.TextColor3 = Color3.new(1,1,1)
Toggle.Parent = Main
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0,10)
table.insert(uiElements, Toggle)

Toggle.MouseButton1Click:Connect(function()
	ringEnabled = not ringEnabled
	Toggle.Text = ringEnabled and "Ring: ON" or "Ring: OFF"
	Toggle.BackgroundColor3 = ringEnabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(40,40,40)
end)

-- TELEKINESIS BUTTON
local TeleBtn = Instance.new("TextButton")
TeleBtn.Size = UDim2.new(1,-20,0,40)
TeleBtn.Position = UDim2.new(0,10,0,100)
TeleBtn.Text = "Telekinesis: OFF"
TeleBtn.Font = Enum.Font.GothamBold
TeleBtn.TextSize = 16
TeleBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
TeleBtn.TextColor3 = Color3.new(1,1,1)
TeleBtn.Parent = Main
Instance.new("UICorner", TeleBtn).CornerRadius = UDim.new(0,10)
table.insert(uiElements, TeleBtn)

TeleBtn.MouseButton1Click:Connect(function()
	telekinesisEnabled = not telekinesisEnabled
	draggedPart = nil
	TeleBtn.Text = telekinesisEnabled and "Telekinesis: ON" or "Telekinesis: OFF"
end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if telekinesisEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local part = workspace:FindPartOnRay(ray, LocalPlayer.Character)
		if part and not part.Anchored then
			draggedPart = part
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if telekinesisEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggedPart = nil
	end
end)

-- VALUE FRAMES
local function createValueFrame(text, default, min, max, step, yPos, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1,-20,0,45)
	Frame.Position = UDim2.new(0,10,0,yPos)
	Frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
	Frame.Parent = Main
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,10)
	table.insert(uiElements, Frame)

	local Minus = Instance.new("TextButton")
	Minus.Size = UDim2.new(0,40,1,0)
	Minus.Text = "-"
	Minus.Font = Enum.Font.GothamBold
	Minus.TextSize = 18
	Minus.BackgroundTransparency = 1
	Minus.TextColor3 = Color3.new(1,1,1)
	Minus.Parent = Frame

	local Plus = Minus:Clone()
	Plus.Text = "+"
	Plus.Position = UDim2.new(1,-40,0,0)
	Plus.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1,-80,1,0)
	Label.Position = UDim2.new(0,40,0,0)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 14
	Label.TextColor3 = Color3.new(1,1,1)
	Label.Parent = Frame

	local value = default
	Label.Text = text .. ": " .. value

	local function updateValue()
		Label.Text = text .. ": " .. value
		callback(value)
	end

	Minus.MouseButton1Click:Connect(function()
		value = math.max(min, value - step)
		updateValue()
	end)

	Plus.MouseButton1Click:Connect(function()
		value = math.min(max, value + step)
		updateValue()
	end)

	updateValue()
end

createValueFrame("Radius",50,10,200,5,155,function(v) radius=v end)
createValueFrame("Turn Speed",2,1,15,1,210,function(v) rotationSpeed=v end)

-- THEMES
local ThemeButton = Instance.new("TextButton")
ThemeButton.Size = UDim2.new(1,-20,0,35)
ThemeButton.Position = UDim2.new(0,10,0,265)
ThemeButton.Text = "Themes"
ThemeButton.Font = Enum.Font.GothamBold
ThemeButton.TextSize = 14
ThemeButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
ThemeButton.TextColor3 = Color3.new(1,1,1)
ThemeButton.Parent = Main
Instance.new("UICorner", ThemeButton).CornerRadius = UDim.new(0,10)
table.insert(uiElements, ThemeButton)

local ThemePanel = Instance.new("Frame")
ThemePanel.Size = UDim2.new(0,180,0,260)
ThemePanel.Position = UDim2.new(1,5,0,0)
ThemePanel.BackgroundColor3 = Color3.fromRGB(30,30,30)
ThemePanel.Visible = false
ThemePanel.Parent = Main
Instance.new("UICorner", ThemePanel).CornerRadius = UDim.new(0,15)
table.insert(uiElements, ThemePanel)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,1,0)
Scroll.CanvasSize = UDim2.new(0,0,0,400)
Scroll.ScrollBarThickness = 6
Scroll.BackgroundTransparency = 1
Scroll.Parent = ThemePanel

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0,5)

local function applyTheme(name)
	if rainbowConnection then rainbowConnection:Disconnect() end
	if name == "Default" then
		Stroke.Color = Color3.fromRGB(0,170,255)
	elseif name == "Red" then
		Stroke.Color = Color3.fromRGB(255,0,0)
	elseif name == "Purple" then
		Stroke.Color = Color3.fromRGB(170,0,255)
	elseif name == "Neon" then
		Stroke.Color = Color3.fromRGB(0,255,150)
	elseif name == "Transparent" then
		Stroke.Color = Color3.fromRGB(0,0,0)
	elseif name == "Rainbow" then
		rainbowConnection = RunService.RenderStepped:Connect(function()
			Stroke.Color = Color3.fromHSV((tick()%5)/5,1,1)
		end)
	end
end

local themes = {"Default","Red","Purple","Neon","Transparent","Rainbow"}
for _,theme in ipairs(themes) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,-10,0,30)
	btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Text = theme
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
	btn.MouseButton1Click:Connect(function()
		applyTheme(theme)
	end)
end

ThemeButton.MouseButton1Click:Connect(function()
	ThemePanel.Visible = not ThemePanel.Visible
end)

-- PARTS MANAGEMENT
local function updateParts()
	parts = {}
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) and not obj.Anchored then
			table.insert(parts,obj)
		end
	end
end

workspace.DescendantAdded:Connect(updateParts)
RunService.Heartbeat:Connect(updateParts)

-- ORBIT SYSTEM
RunService.Heartbeat:Connect(function(dt)
	if not ringEnabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	orbitAngle += rotationSpeed * dt
	local center = hrp.Position
	local count = #parts
	if count == 0 then return end

	for i,part in ipairs(parts) do
		if part and part.Parent and not part.Anchored then
			local angle = orbitAngle + (i * (math.pi*2/count))
			local target = center + Vector3.new(math.cos(angle)*radius, 5, math.sin(angle)*radius)
			part.Velocity = (target - part.Position) * 12
		end
	end

	-- TELEKINESIS
	if telekinesisEnabled and draggedPart and draggedPart.Parent then
		local mousePos = UIS:GetMouseLocation()
		local ray = workspace.CurrentCamera:ScreenPointToRay(mousePos.X, mousePos.Y)
		local targetPos = ray.Origin + ray.Direction * 50
		draggedPart.Velocity = (targetPos - draggedPart.Position) * 12
	end
end)
