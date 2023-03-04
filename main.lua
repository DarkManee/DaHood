if HUB_LOADED then
	return warn("Azure-Ware is already running!")
end

pcall(function() getgenv().HUB_LOADED = true end)

if game:GetService("RunService"):IsStudio() then
	lib = {

		flags = {},
		Items = {},
		
	}
else
	getgenv().lib = {

		flags = {},
		Items = {},
		
	}
end

local MPS = game:GetService("MarketplaceService")
local UIS = game:GetService("UserInputService")

local HTTPS = game:GetService("HttpService")

local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")

local StarterGui = game:GetService("StarterGui")
local PLYS = game:GetService("Players")

local LP = PLYS.LocalPlayer
local Mouse = LP:GetMouse()

local JoinTime = os.time() - (LP.AccountAge * 86400)
local JoinDate = os.date("!*t", JoinTime)

local TextService = game:GetService("TextService")
local COREGUI = game:GetService("CoreGui")

NotificationHolder = nil
Notification = nil

ESP = nil

local t = tick()

if not RS:IsStudio() then
	NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))()
	Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()
end

if not game:GetService("RunService"):IsStudio() then
	ESP = loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))()
	ESP:Toggle(true); ESP.Players = false; ESP.Names = true; ESP.Tracers = false; ESP.Boxes = false;
else
	ESP = {}
	function ESP:Toggle(bool) return end
end

_G.LocalLibrary_Data = {
	CloseBind = Enum.KeyCode.LeftAlt
}

_G.LocalLibrary_SupportedGames = {
	["TR:NE"] = {
		
		["PlaceId"] = 6053107323,
		["GameId"] = 0,
		
		["CreatorId"] = 721520494
	},

	["TOH"] = {
		
		["PlaceId"] = 1962086868,
		["GameId"] = 0,
		
		["CreatorId"] = 79745056
	},

	["NDS"] = {
		
		["PlaceId"] = 189707,
		["GameId"] = 0,
		
		["CreatorId"] = 80254
	},

	["Apeirophobia"] = {
	
		["PlaceId"] = 10277607801,
		["GameId"] = 0,
		
		["CreatorId"] = 459357168
	},

	["SPS"] = {
	
		["PlaceId"] = 164051105,
		["GameId"] = 0,
		
		["CreatorId"] = 35392
	},

	["Evade"] = {
	
		["PlaceId"] = 9872472334,
		["GameId"] = 0,
		
		["CreatorId"] = 49468107
	},
	
	["Forgotten Memories"] = {
		
		["PlaceId"] = 8482713490,
		["GameId"] = 3240343305,
		
		["CreatorId"] = 177068834
	},
	
	["WordBomb"] = {
	
		["PlaceId"] = 2653064683,
		["GameId"] = 0,
		
		["CreatorId"] = 9691536
	}
}

local SupportedGame = false;
local CurrentFPS = 0;

local PARENT = nil;

for _, v in pairs(_G.LocalLibrary_SupportedGames) do
	if v.PlaceId == game.PlaceId then
		
		SupportedGame = true
		
	elseif v.GameId == game.GameId then
		
		SupportedGame = true
		
	elseif RS:IsStudio() then
		
		SupportedGame = true
	end
end

local succes, info = pcall(MPS.GetProductInfo, MPS, game.PlaceId)

local Camera = workspace.CurrentCamera
cameraFov = Camera.FieldOfView
fcRunning = false

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)

local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value

Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = math.exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()

local velSpring = Spring.new(5, Vector3.new())
local panSpring = Spring.new(5, Vector2.new())

Input = {} do

	keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
	}

	mouse = {
		Delta = Vector2.new(),
	}

	NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	PAN_MOUSE_SPEED = Vector2.new(1, 1)*(math.pi/64)
	NAV_ADJ_SPEED = 0.75
	NAV_SHIFT_MUL = 0.25

	navSpeed = 1

	function Input.Vel(dt)
		navSpeed = math.clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A,
			keyboard.E - keyboard.Q,
			keyboard.S - keyboard.W
		)*NAV_KEYBOARD_SPEED

		local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift)

		return (kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kMouse
	end

	do
		function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			game:GetService("ContextActionService"):BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
			Enum.KeyCode.W,
			Enum.KeyCode.A,
			Enum.KeyCode.S,
			Enum.KeyCode.D,
			Enum.KeyCode.E,
			Enum.KeyCode.Q,
			Enum.KeyCode.Up,
			Enum.KeyCode.Down
			)
			game:GetService("ContextActionService"):BindActionAtPriority("FreecamMousePan", MousePan, false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(keyboard)
			Zero(mouse)
			game:GetService("ContextActionService"):UnbindAction("FreecamKeyboard")
			game:GetService("ContextActionService"):UnbindAction("FreecamMousePan")
		end
	end
end

function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*math.tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))

	local zoomFactor = math.sqrt(math.tan(math.rad(70/2))/math.tan(math.rad(cameraFov/2)))

	cameraRot = cameraRot + pan*Vector2.new(0.75, 1)*8*(dt/zoomFactor)
	cameraRot = Vector2.new(math.clamp(cameraRot.x, -math.rad(90), math.rad(90)), cameraRot.y%(2*math.pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*Vector3.new(1, 1, 1)*64*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end

local PlayerState = {} do
	mouseBehavior = ""
	mouseIconEnabled = ""
	cameraType = ""
	cameraFocus = ""
	cameraCFrame = ""
	cameraFieldOfView = ""

	function PlayerState.Push()
		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70

		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseIconEnabled = UIS.MouseIconEnabled
		UIS.MouseIconEnabled = true

		mouseBehavior = UIS.MouseBehavior
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end

	function PlayerState.Pop()
		Camera.FieldOfView = 70

		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UIS.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		UIS.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

function StartFreecam(pos)
	if fcRunning then
		StopFreecam()
	end
	local cameraCFrame = Camera.CFrame
	
	if pos then
		cameraCFrame = pos
	end
	
	cameraRot = Vector2.new()
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())

	PlayerState.Push()
	game:GetService("RunService"):BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
	fcRunning = true
end

function StopFreecam()
	if not fcRunning then return end
	Input.StopCapture()
	game:GetService("RunService"):UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
	workspace.Camera.FieldOfView = 70
	fcRunning = false
end

function Create(instance, properties, children)
	
	local obj = Instance.new(instance)
	
	for i, v in pairs(properties or {}) do
		
		obj[i] = v
		
		for _, child in pairs(children or {}) do
			child.Parent = obj
		end
	end
	
	return obj
end

function Format(Int)
	return string.format("%02i", Int)
end

function ConvertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	
	return Format(Hours).."H "..Format(Minutes).."M "..Format(Seconds)..'S'
end

function Tween(instance, tweentime, properties, callback)
	
	callback = callback or function() end
	
	local Tween = TS:Create(instance, TweenInfo.new(tweentime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
	Tween:Play()
	
	Tween.Completed:Connect(function()
		callback()
	end)
end

function isNumber(str)
	if tonumber(str) ~= nil or str == 'inf' then
		return true
	end
end

function getRoot(CHARACTER)
	local RootPart = CHARACTER:FindFirstChild('HumanoidRootPart') or CHARACTER:FindFirstChild('Torso') or CHARACTER:FindFirstChild('UpperTorso')
	return RootPart
end

function GetCharacter_HumanoidRigType(PLR)
	if PLR.Character:FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R15 then
		return true
	end
end

function GetPlayer(PlayerName)
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if string.find(v.Name, PlayerName) or string.find(v.DisplayName, PlayerName)  then
			return v
		elseif v.Name:sub(1, PlayerName:len()):lower() == PlayerName:lower() then
			return v
		end
	end
end

local Ver = "2.0.1"

function lib:GetVersion()
	return Ver
end

function lib:Notify(Title, Description, Time, Type, OutlineColor, Icon, callback)
	
	Title = Title or "NOTIFICATION"
	Description = Description or ""
	
	Type = Type or "default"
	Time = Time or 5
	
	callback = callback or function() end
	
	OutlineColor = OutlineColor or _G.LocalLibrary_Data.AccentColor
	
	if not RS:IsStudio() then
		Notification:Notify({
			Title = tostring(Title),
			Description = Description--[[tostring(_G.LocalLibrary_Data.Name).." loaded in: " .. tick() - t .. "s (seconds)"]]

		}, {
			OutlineColor = OutlineColor,
			Time = Time, Type = Type

		})
	else
		if Type == "default" then
			StarterGui:SetCore("SendNotification", {
				Title = Title,

				Text = Description,
				Duration = Time,	
			})
		elseif Type == "image" then
			StarterGui:SetCore("SendNotification", {
				Title = Title,

				Icon = Icon,

				Text = Description,
				Duration = Time,	
			})
		elseif Type == "option" then
			StarterGui:SetCore("SendNotification", {
				Title = Title,

				Text = Description,
				Duration = Time,
				
				Button1 = "OK",
				
				Callback = callback
			})
		end
	end
end

function lib:GetCurrentExecutor_Name()
	
	if RS:IsStudio() then
		return "Roblox_Studio"
	end
	
	local SynV3 = syn and DrawingImmediate
	
	if (not is_sirhurt_closure) and (not SynV3) and (syn) then
		
		return "Synapse X"
		
	elseif (not is_sirhurt_closure) and (SynV3) and (syn) then
		
		return "Synapse X-V3"
		
	elseif (getexecutorname) then
		
		return "Script-Ware"
		
	elseif (KRNL_LOADED) then
		
		return "Krnl"
		
	elseif (identifyexecutor) then
		return "Fluxus"
	else
		return "unknown"
	end
end

function lib:GetCurrentExecutor_function(functionName)
	
	if tostring(lib:GetCurrentExecutor_Name()) == "RobloxStudio" then
		return nil
	end
	
	local _function = nil

	if functionName == "sethidden" then
		
		_function = sethiddenproperty or set_hidden_property or set_hidden_prop
		return _function

	elseif functionName == "gethidden" then
		
		_function = gethiddenproperty or get_hidden_property or get_hidden_prop
		return _function
		
	elseif functionName == "queueteleport" then
		
		_function = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport 
		return _function
		
	elseif functionName == "setconstant" then
		
		_function = (debug and debug.setconstant) or setconstant
		return _function
		
	elseif functionName == "getconstants" then

		_function = (debug and debug.getconstants) or getconstants
		return _function
		
	elseif functionName == "clipBoard" then
		
		_function = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
		return _function
		
	elseif functionName == "protect_gui" then
		
		_function = syn and syn.protect_gui or get_hidden_gui or gethui
		return _function
		
	elseif functionName == "http_request" then
		
		_function = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request
		return _function
		
	elseif functionName == "Base64Encode" then
		
		_function = syn and syn.crypt.base64.encode or base64_encode or fluxus and fluxus.crypt.base64.encode or crypt and crypt.base64encode
		return _function
		
	elseif functionName == "Base64Decode" then
		
		_function = syn and syn.crypt.base64.decode or base64_decode or fluxus and fluxus.crypt.base64.decode or crypt and crypt.base64decode
		return _function
	else
		print("Unknown functionName, "..functionName)
	end
end

local MissingFunctionsTable = {}

local CheckCurrentExecutor_functions = function()
	
	if not lib:GetCurrentExecutor_function("sethidden") then
		table.insert(MissingFunctionsTable, "sethiddenproperty")
	end
	
	if not lib:GetCurrentExecutor_function("gethidden") then
		table.insert(MissingFunctionsTable, "gethiddenproperty")
	end
	
	if not lib:GetCurrentExecutor_function("queueteleport") then
		table.insert(MissingFunctionsTable, "queueteleport")
	end
	
	if not lib:GetCurrentExecutor_function("setconstant") then
		table.insert(MissingFunctionsTable, "setconstant")
	end
	
	if not lib:GetCurrentExecutor_function("getconstants") then
		table.insert(MissingFunctionsTable, "getconstants")
	end
	
	if not lib:GetCurrentExecutor_function("clipBoard") then
		table.insert(MissingFunctionsTable, "setclipboard")
	end
	
	if not lib:GetCurrentExecutor_function("protect_gui") then
		table.insert(MissingFunctionsTable, "protect_gui")
	end
	
	if not lib:GetCurrentExecutor_function("http_request") then
		table.insert(MissingFunctionsTable, "http_request")
	end
	
	if not lib:GetCurrentExecutor_function("Base64Encode") then
		table.insert(MissingFunctionsTable, "base64encode")
	end
	
	if not lib:GetCurrentExecutor_function("Base64Decode") then
		table.insert(MissingFunctionsTable, "base64decode")
	end
	
	task.wait(1)
	
	local MissingFunctions = false
	local MissingFunctions2 = ""

	for _, v in pairs(MissingFunctionsTable) do
		MissingFunctions2 = MissingFunctions2..", "..tostring(v)
		MissingFunctions = true
	end

	if not RS:IsStudio() and MissingFunctions then
		return warn("ERROR: 495 Missing function(s): "..tostring(MissingFunctions2)), LP:Kick("ERROR: 495 Missing function(s): "..tostring(MissingFunctions2))
	elseif RS:IsStudio() and MissingFunctions then
		return warn("ERROR: 495 Missing function(s): "..tostring(MissingFunctions2))--[[, LP:Kick("ERROR: 495 Missing function(s): "..tostring(MissingFunctions))]]
	end
end

---------------| UI Initializer |---------------

pcall(function()
	local CurrentExecutorName = lib:GetCurrentExecutor_Name()
	CheckCurrentExecutor_functions()
end)

---------------| UI Main |---------------

function lib:CreateWindow(UI_Name, UI_AccentColor)
	
	UI_AccentColor = UI_AccentColor or Color3.fromRGB(144, 41, 246)
	UI_Name = UI_Name or "AzureWare"
	
	local windowSettings = {
		Font = Enum.Font.GothamSemibold,
		AccentColor = UI_AccentColor,
		Name = UI_Name,
	}
	
	_G.LocalLibrary_Data.AccentColor = windowSettings.AccentColor
	_G.LocalLibrary_Data.Name = windowSettings.Name

	local GUI = Instance.new("ScreenGui");
	GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	GUI.IgnoreGuiInset = true;
	
	function lib:DestroyUI()
		
		GUI:Destroy()
		PARENT = nil
		
		pcall(function() getgenv().HUB_LOADED = false end)
	end

	if not game:GetService("RunService"):IsStudio() then
		local SynV3 = syn and DrawingImmediate
		if (not is_sirhurt_closure) and (not SynV3) and (syn and syn.protect_gui) then

			syn.protect_gui(GUI)

			GUI.Parent = COREGUI
			PARENT = GUI

		elseif get_hidden_gui or gethui then

			local hiddenUI = get_hidden_gui or gethui
			GUI.Parent = hiddenUI()

			PARENT = GUI
			
		elseif COREGUI:FindFirstChild('RobloxGui') then
			PARENT = COREGUI.RobloxGui

		else
			GUI.Parent = COREGUI
			PARENT = GUI
		end
	else
		GUI.Parent = LP.PlayerGui
		PARENT = GUI
	end
	
	local ShadowEffect = Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Transparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Name = "ShadowEffect",
		Parent = PARENT,
	},
	{
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(1.00, 0.25)},
		}),
	})
	
	local MainFrame = Create("Frame", {
		BackgroundTransparency = 1.000,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "MainFrame",
		Parent = PARENT,
	},
	{
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 23),
			PaddingLeft = UDim.new(0, 48),
			PaddingRight = UDim.new(0, 48),
			PaddingTop = UDim.new(0, 48),
		}),
		Create("Frame", {
			BackgroundTransparency = 1.000,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "Main",
		},{Create("UIPadding", {
			PaddingBottom = UDim.new(0, 80),
		}),
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Name = "HomeMainFrame",
		}),
		}),
	})
	
	local TextButton = Create("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderSizePixel = 0,
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14.000,
		TextTransparency = 1.000,
		Parent = PARENT
	})
	
	local TextButton2 = Create("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1.000,
		BorderSizePixel = 0,
		Modal = true,
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14.000,
		TextTransparency = 1.000,
		Parent = PARENT
	})
	
	function lib:LockMouse(Value)
		TextButton.Modal = Value
	end
	
	local SupportedGamesFrame = Create("ScrollingFrame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1.000,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Position = UDim2.new(0, -1170, 0, 0),
		Selectable = false,
		Visible = false,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 0,
		Name = "SupportedGamesFrame",
		Parent = MainFrame.Main,
	},{
		Create("UIGridLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		CellPadding = UDim2.new(0, 80, 0, 80),
		CellSize = UDim2.new(0, 380, 0, 250),
		})
	})
	
	local OptionsBar = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0, 400, 0, 56),
		Parent = MainFrame,
		Name = "OptionsBar",
	},{
		Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.700,
			ZIndex = 2,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "BarMain",

		}, {
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Create("UICorner", {})
		}),
		
		Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			ClipsDescendants = true,
			Position = UDim2.new(0.018, 0, 0, 0),
			Size = UDim2.new(0, 86, 0, 56),
			Name = "IndicatorFrame",
		}, {
			
			Create("UIGradient", {
				Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, windowSettings.AccentColor), ColorSequenceKeypoint.new(1.00, windowSettings.AccentColor)},
				Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.50), NumberSequenceKeypoint.new(1.00, 0.50)},
			}),
			
			Create("UICorner", {})
		}),
		
		Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.12, 0, 0, -18),
			Size = UDim2.new(0, 148, 0, 104),
			Image = "rbxassetid://8992238178",
			ImageColor3 = windowSettings.AccentColor,
			Name = "Glow",
		})
	})
	
	local HomeInfoFrame = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0, -1170, 0, 0),
		Size = UDim2.new(0, 326, 0, 648),
		Name = "HomeInfoFrame",
		Parent = MainFrame.Main.HomeMainFrame,
	},{Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.700,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "HomeMain",
	},{
		Create("UICorner", {
			CornerRadius = UDim.new(0, 16),
		}),
		Create("UIStroke", {
			Color = windowSettings.AccentColor,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 2,
		})
	}),
	Create("Frame", {		
		BackgroundTransparency = 1.000,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "HomeMain2",
	},{
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 24),
		}),
		Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0, 24),
			Size = UDim2.new(0, 186, 0, 186),
			Name = "PlayerIconMainFrame",
		}, {
			Create("Frame", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 4, 0, 4),
				Size = UDim2.new(1, -8, 1, -8),
				Name = "PlayerIconCircle",
			},{
				Create("UIStroke", {
					Color = windowSettings.AccentColor,
					LineJoinMode = Enum.LineJoinMode.Round,
					Thickness = 4,
				}),
				
				Create("UICorner", {
					CornerRadius = UDim.new(1, 0)
				})
			}),
			Create("ImageLabel", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.700,
				Position = UDim2.new(0, 18, 0, 18),
				Size = UDim2.new(0, 150, 0, 150),
				Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..LP.UserId.."&width=150&height=150&format=png",
				Name = "PlayerRenderedIcon",
			},{
				Create("UICorner", {
					CornerRadius = UDim.new(1, 0)
				})
			})
		}),
		Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0, 231),
			Size = UDim2.new(0, 278, 0, 49),
			Name = "PlayerNameHolder",
		}, {
			Create("TextLabel", {
				BackgroundTransparency = 1.000,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.GothamBlack,
				Text = LP.DisplayName,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20.000,
				TextYAlignment = Enum.TextYAlignment.Top,
				Name = "PlayerDisplayName",
			}),
			Create("TextLabel", {
				BackgroundTransparency = 1.000,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "@"..LP.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16.000,
				TextTransparency = 0.700,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				Name = "PlayerName",
			})
		}),
		Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0, 300),
			Size = UDim2.new(0, 278, 0, 48),
			Name = "PlayerDataHolder",
		}, {
			Create("Frame", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 90, 0, 11),
				Size = UDim2.new(0, 0, 0, 26),
				Name = "Line",
			}, {
				Create("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					LineJoinMode = Enum.LineJoinMode.Round,
					Thickness = 0.5,
					Transparency = 0.7,
				})
			}),
			Create("Frame", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 187, 0, 11),
				Size = UDim2.new(0, 0, 0, 26),
				Name = "Line",
			},{
				Create("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = 0.5,
				Transparency = 0.7,
			})}),
			Create("TextLabel", {
				BackgroundTransparency = 1.000,
				Size = UDim2.new(0, 85, 0, 48),
				Font = Enum.Font.GothamBold,
				Text = "Joined".."\n"..JoinDate.day.."/"..JoinDate.month.."/".. JoinDate.year,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 13.000,
				TextTransparency = 0.200,
				RichText = true,
				Name = "JoinedDate",
			}),
			Create("TextLabel", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 97, 0, 0),
				Size = UDim2.new(0, 85, 0, 48),
				Font = Enum.Font.GothamBold,
				Text = "0 friends".."\n".."joined",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 13.000,
				TextTransparency = 0.200,
				RichText = true,
				Name = "FriendsJoined",
			}),
			Create("TextLabel", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 193, 0, 0),
				Size = UDim2.new(0, 85, 0, 48),
				Font = Enum.Font.GothamBold,
				Text = "0 friends".."\n".."online",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 13.000,
				TextTransparency = 0.200,
				RichText = true,
				Name = "FriendsOnline",
			})
		}),
		Create("Frame", {
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 0, 0, 368),
			Size = UDim2.new(0, 278, 0, 187),
			Name = "RandomInfoFrame",
		},{
			Create("Frame", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 0, 0, 69),
				Size = UDim2.new(0, 278, 0, 49),
				Name = "CurrentFPS_MainFrame",
			},{
				Create("Frame", {
					BackgroundTransparency = 1.000,
					Size = UDim2.new(0, 278, 0, 49),
					Name = "CurrentFPS_Main"
				},{
					Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.500,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "CurrentFPS_Fade",
					},{
						Create("UICorner", {})
					}),
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0.0431654677, 0, 0, 0),
						Size = UDim2.new(0.956834555, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = "Current FPS: "..tostring(CurrentFPS),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 15.000,
						TextTransparency = 0.500,
						TextXAlignment = Enum.TextXAlignment.Left,
						Name = "CurrentFPS_Text",
					})
				})
			}),
			Create("Frame",{
				BackgroundTransparency = 1.000,
				Size = UDim2.new(0, 278, 0, 49),
				Name = "PlaceName_MainFrame",
			},{
				Create("Frame",{
					BackgroundTransparency = 1.000,
					Size = UDim2.new(0, 278, 0, 49),
					Name = "PlaceName_Main",
				},{
					Create("Frame",{
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.500,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "PlaceName_Fade",
					},{
						Create("UICorner", {})
					}),
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0.0431654677, 0, 0, 0),
						Size = UDim2.new(0.956834555, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = "Game: "..tostring(info.Name),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 15.000,
						TextTransparency = 0.500,
						TextXAlignment = Enum.TextXAlignment.Left,
						Name = "PlaceName_Text",
					})
				})
			}),
			Create("Frame", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 0, 0, 138),
				Size = UDim2.new(0, 278, 0, 49),
				Name = "DiscordServer_MainFrame",
			},{
				Create("Frame", {
					BackgroundTransparency = 1.000,
					Size = UDim2.new(0, 278, 0, 49),
					Name = "DiscordServer_Main",
				},{
					Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.500,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "DiscordServer_Fade",
					}, {
						Create("UICorner", {})
					}),
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0.0431654677, 0, 0, 0),
						Size = UDim2.new(0.956834555, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = "Discord Server: ech544bz4b",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 15.000,
						TextTransparency = 0.500,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						Name = "DiscordServer_Text",
					})
				})
			})
		})
	}),
	})
	
	local UniversalButtons = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0.5, 0, 0, 575),
		Size = UDim2.new(0, 278, 0, 49),
		Parent = HomeInfoFrame.HomeMain2,
		Name = "UniversalButtons"
	},{
		Create("Frame", {
			BackgroundTransparency = 1.000,
			Size = UDim2.new(0, 61, 0, 49),
			Name = "ResetChar_MainFrame",
		},{
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.500,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "ResetChar_Main",
			}, {
				Create("UICorner", {})
			}),
			Create("ImageButton", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 12, 0, 6),
				Selectable = false,
				Size = UDim2.new(0, 36, 0, 36),
				Image = "rbxassetid://8992253511",
				ImageTransparency = 0.500,
				Name = "ResetChar_Button",
			})
		}),
		Create("Frame", {
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 72, 0, 0),
			Size = UDim2.new(0, 61, 0, 49),
			Name = "InvisibleChar_MainFrame",
		}, {
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.500,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "InvisibleChar_Main",
			}, {
				Create("UICorner", {})
			}),
			Create("ImageButton", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 12, 0, 6),
				Selectable = false,
				Size = UDim2.new(0, 36, 0, 36),
				Image = "rbxassetid://8992253792",
				ImageTransparency = 0.500,
				Name = "InvisibleChar_Button",
			})
		}),
		Create("Frame", {
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 145, 0, 0),
			Size = UDim2.new(0, 61, 0, 49),
			Name = "Godmode_MainFrame",
		},{
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.500,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "Godmode_Main",
			},{
				Create("UICorner", {})
			}),
			Create("ImageButton", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 12, 0, 6),
				Selectable = false,
				Size = UDim2.new(0, 36, 0, 36),
				Image = "rbxassetid://8992253678",
				ImageTransparency = 0.500,
				Name = "Godmode_Button",
			})
		}),
		Create("Frame", {
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 217, 0, 0),
			Size = UDim2.new(0, 61, 0, 49),
			Name = "FreeCam_MainFrame",
		},{
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.500,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "FreeCam_Main",
			},{
				Create("UICorner", {})
			}),
			
			Create("ImageButton", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 12, 0, 6),
				Size = UDim2.new(0, 36, 0, 36),
				Image = "rbxassetid://8992253933",
				ImageTransparency = 0.500,
				Name = "FreeCam_Button",
			})
		})
	})
	
	local UpdateLogsFrame = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0, -1170, 0, 0),
		Size = UDim2.new(0, 326, 0, 416),
		Name = "UpdateLogsFrame",
		Parent = MainFrame.Main.HomeMainFrame

	}, {
		Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.700,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "LogsMain",
		}, {Create("UIStroke", {
			Color = windowSettings.AccentColor,
			LineJoinMode = Enum.LineJoinMode.Round,
			Thickness = 2,
		}),Create("UICorner", {
			CornerRadius = UDim.new(0, 16)}),
		}),
		Create("TextLabel", {
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 24, 0, 24),
			Font = Enum.Font.GothamBlack,
			Text = "Update Logs",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20.000,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Name = "UpdateLogsTitle",
		}),

		Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 344),
			Name = "UpdateLogsListHolder",
		},{
			Create("ScrollingFrame", {
				BackgroundTransparency = 1.000,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				CanvasSize = UDim2.new(0, 0, 0, 580),
				ScrollBarThickness = 0,
			}, {
				Create("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				})
			})
		})
	})
	
	---------------| WorkInProgressFrameCreator |---------------
	
	local Work_in_Prgress = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		Name = "Work_in_Prgress",
		Parent = MainFrame.Main,
	}, {
		
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.302872062, 0, 0.832822084, 0),
			Size = UDim2.new(0, 850, 0, 435),
		}, {
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.700,
				Position = UDim2.new(0.060707137, 0, 0.280352831, 0),
				Size = UDim2.new(0.587690651, 0, 0.600000024, 0),
			}, {
				Create("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					Position = UDim2.new(0.134928524, 0, 0.206896558, 0),
					Size = UDim2.new(0, 364, 0, 153),
					Font = Enum.Font.Gotham,
					Text = "Work in Progress..".."\n".."Please come back later when this fuction is fully released",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14.000,
					RichText = true,
					TextWrapped = true,
				}),
				
				Create("UIStroke", {
					Color = windowSettings.AccentColor,
					Thickness = 2
				}),
				
				Create("UICorner", {
					CornerRadius = UDim.new(0, 16)
				})
			})
		}),
		
		Create("UIScale", {})
	})
	
	---------------| ConfigurationSystem |---------------
	
	
	
	---------------| OptionsBarFuctions |---------------
	
	local HomeButton = Create("TextButton", {
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0.699999988, 0, 0, 0),
		Size = UDim2.new(0, 100, 0, 56),
		ZIndex = 2,
		AutoButtonColor = false,
		Text = "",
		Parent = OptionsBar.BarMain,
		Name = "HomeButton",
	}, {
		Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 36, 0, 36),
			Image = "rbxassetid://8992031167",
			Name = "Icon",
		})
	})
	
	local SupportedGamesButton = Create("TextButton", {
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0.699999988, 0, 0, 0),
		Size = UDim2.new(0, 100, 0, 56),
		ZIndex = 2,
		AutoButtonColor = false,
		Text = "",
		Parent = OptionsBar.BarMain,
		Name = "SupportedGamesButton",
	}, {
		Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 36, 0, 36),
			Image = "rbxassetid://8992031246",
			ImageTransparency = 0.75,
			Name = "Icon",
		})
	})
	
	local ScriptsButton = Create("TextButton", {
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0.699999988, 0, 0, 0),
		Size = UDim2.new(0, 100, 0, 56),
		ZIndex = 2,
		AutoButtonColor = false,
		Text = "",
		Parent = OptionsBar.BarMain,
		Name = "ScriptsButton",
	}, {
		Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 36, 0, 36),
			Image = "rbxassetid://8992030918",
			ImageTransparency = 0.75,
			Name = "Icon",
		})
	})
	
	local SettingsButton = Create("TextButton", {
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0.699999988, 0, 0, 0),
		Size = UDim2.new(0, 100, 0, 56),
		ZIndex = 2,
		AutoButtonColor = false,
		Text = "",
		Parent = OptionsBar.BarMain,
		Name = "SettingsButton",
	}, {
		Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 36, 0, 36),
			Image = "rbxassetid://8992031056",
			ImageTransparency = 0.75,
			Name = "Icon",
		})
	})
	
	task.spawn(function()
		
		repeat wait() until game:IsLoaded()
		
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		
		task.wait()
		
		Tween(ShadowEffect, .45, {BackgroundTransparency = 0})
		
		Tween(MainFrame.Main.HomeMainFrame.UpdateLogsFrame, .45, {Position = UDim2.new(0, 374, 0.8, 0)})
		wait(.15)
		Tween(MainFrame.Main.HomeMainFrame.HomeInfoFrame, .45, {Position = UDim2.new(0, 0, 1, 0)})
	end)
	
	local CurrentSection = "HomeMainFrame"
	
	HomeButton.MouseButton1Click:Connect(function()
		for _, v in pairs(OptionsBar.BarMain:GetChildren()) do
			if v:IsA("TextButton") then
				if v.Name == HomeButton.Name then			
					Tween(v.Icon, .45, {ImageTransparency = 0})
				else
					Tween(v.Icon, .45, {ImageTransparency = .75})
				end
			end
		end

		for _, v in pairs(MainFrame.Main:GetChildren()) do
			if v:IsA("Frame") or v:IsA("ScrollingFrame") then
				if v.Name == "HomeMainFrame" then 
					
					v.Visible = true
					
					Tween(v.UpdateLogsFrame, .45, {Position = UDim2.new(0, 374, 0.8, 0)})
					wait(.15)
					Tween(v.HomeInfoFrame, .45, {Position = UDim2.new(0, 0, 1, 0)})
					
					CurrentSection = v.Name
				else
					for _, v2 in pairs(v:GetChildren()) do
						if v2:IsA("Frame") or v2:IsA("ScrollingFrame") then
							Tween(v2, .25, {Position = UDim2.new(0, -1170, 0, 0)})
						end
					end
					if v:IsA("ScrollingFrame") then
						Tween(v, .25, {Position = UDim2.new(0, -1170, 0, 0)})
					end
				end
			end
		end
		
		Tween(OptionsBar.IndicatorFrame, 1, {Position = UDim2.new(.018, 0, 0, 0)})
		Tween(OptionsBar.Glow, 1, {Position = UDim2.new(.12, 0, 0, -18)})
	end)
	
	SupportedGamesButton.MouseButton1Click:Connect(function()	
		for _, v in pairs(OptionsBar.BarMain:GetChildren()) do
			if v:IsA("TextButton") then
				if v.Name == SupportedGamesButton.Name then			
					Tween(v.Icon, .45, {ImageTransparency = 0})
				else
					Tween(v.Icon, .45, {ImageTransparency = .75})
				end
			end
		end

		for _, v in pairs(MainFrame.Main:GetChildren()) do
			if v:IsA("Frame") or v:IsA("ScrollingFrame") then
				if v.Name == "SupportedGamesFrame" then
					Tween(v, .45, {Position = UDim2.new(0, 0, 1, 0)})
					v.Visible = true
					CurrentSection = v.Name
				else
					for _, v2 in pairs(v:GetChildren()) do
						if v2:IsA("Frame") or v2:IsA("ScrollingFrame") then
							Tween(v2, .25, {Position = UDim2.new(0, -1170, 0, 0)})
						end
					end
					if v:IsA("ScrollingFrame") then
						Tween(v, .25, {Position = UDim2.new(0, -1170, 0, 0)})
					end
				end
			end
		end

		Tween(OptionsBar.IndicatorFrame, 1, {Position = UDim2.new(.275, 0, 0, 0)})
		Tween(OptionsBar.Glow, 1, {Position = UDim2.new(.385, 0, 0, -18)})
	end)
	
	ScriptsButton.MouseButton1Click:Connect(function()		
		for _, v in pairs(OptionsBar.BarMain:GetChildren()) do
			if v:IsA("TextButton") then
				if v.Name == ScriptsButton.Name then			
					Tween(v.Icon, .45, {ImageTransparency = 0})
				else
					Tween(v.Icon, .45, {ImageTransparency = .75})
				end
			end
		end

		for _, v in pairs(MainFrame.Main:GetChildren()) do
			if v:IsA("Frame") or v:IsA("ScrollingFrame") then
				if v.Name == "ScriptsMainFrame" then
					
					v.Visible = true
					
					Tween(v.SectionsFrame, .45, {Position = UDim2.new(0.303, 0, 0.833, 0)})
					wait(.15)
					Tween(v.TabsFrame, .45, {Position = UDim2.new(0, 0, 1, 0)})
					
					CurrentSection = v.Name
					
				else
					for _, v2 in pairs(v:GetChildren()) do
						if v2:IsA("Frame") or v2:IsA("ScrollingFrame") then
							Tween(v2, .25, {Position = UDim2.new(0, -1170, 0, 0)})
						end
					end
					if v:IsA("ScrollingFrame") then
						Tween(v, .25, {Position = UDim2.new(0, -1170, 0, 0)})
					end
				end
			end
		end

		Tween(OptionsBar.IndicatorFrame, 1, {Position = UDim2.new(.52, 0, 0, 0)})
		Tween(OptionsBar.Glow, 1, {Position = UDim2.new(.62, 0, 0, -18)})
	end)
	
	SettingsButton.MouseButton1Click:Connect(function()
		for _, v in pairs(OptionsBar.BarMain:GetChildren()) do
			if v:IsA("TextButton") then
				if v.Name == SettingsButton.Name then			
					Tween(v.Icon, .45, {ImageTransparency = 0})
				else
					Tween(v.Icon, .45, {ImageTransparency = .75})
				end
			end
		end

		for _, v in pairs(MainFrame.Main:GetChildren()) do
			if v:IsA("Frame") or v:IsA("ScrollingFrame") then
				if v.Name == "Work_in_Prgress"--[["SettingsMainFrame"]] then 
					v.Frame.Position = UDim2.new(0.303, 0, 0.833, 0)
					v.Visible = true
					CurrentSection = v.Name
				else
					for _, v2 in pairs(v:GetChildren()) do
						if v2:IsA("Frame") or v2:IsA("ScrollingFrame") then
							Tween(v2, .25, {Position = UDim2.new(0, -1170, 0, 0)})
						end
					end
					if v:IsA("ScrollingFrame") then
						Tween(v, .25, {Position = UDim2.new(0, -1170, 0, 0)})
					end
				end
			end
		end
		
		Tween(OptionsBar.IndicatorFrame, 1, {Position = UDim2.new(.768, 0, 0, 0)})
		Tween(OptionsBar.Glow, 1, {Position = UDim2.new(.87, 0, 0, -18)})
	end)
	
	---------------| Fuctions |---------------
	

	local CreateGame_Icon = function(Parent, CreatorId, PlaceId)
		
		local GameIcon = Create("ImageLabel", {
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, 24, 0, 0),
			Size = UDim2.new(0, 278, 0, 156),
			Image = "https://www.roblox.com/asset-thumbnail/image?assetId="..tostring(PlaceId).."&width=768&height=832&format=png",
			ScaleType = Enum.ScaleType.Crop,
			Parent = Parent,
			Name = "GameIcon",
		},{
			
			Create("ScrollingFrame", {
				BackgroundTransparency = 1.000,
				BorderSizePixel = 0,
				ClipsDescendants = false,
				Position = UDim2.new(0, 0, 1, -24),
				Size = UDim2.new(1, 0, 0, 64),
				CanvasSize = UDim2.new(0, 154, 0, 0),
				ScrollBarThickness = 0,
				Name = "FriendIconFrame",
			}, {
				Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),
				
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 10)
				}),
				
				Create("Frame", {
					BackgroundTransparency = 1.000,
					Size = UDim2.new(0, 48, 0, 48),
					Name = "FriendIconHolder",
				}, {
					Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.700,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "Circle",
					}, {
						Create("UICorner", {
							CornerRadius = UDim.new(0, 24)
						})
					}),
					
					Create("Frame", {
						BackgroundTransparency = 1.000,
						ClipsDescendants = true,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "JoinButtonFrame",
					}, {
						Create("ImageLabel", {
							BackgroundTransparency = 1.000,
							Position = UDim2.new(0, 48, 0, 6),
							Size = UDim2.new(0, 36, 0, 36),
							Image = "rbxassetid://8992244380",
							Name = "Icon",
						})
					}),
					
					Create("TextButton", {
						BackgroundTransparency = 1.000,
						Size = UDim2.new(1, 0, 1, 0),
						AutoButtonColor = false,
						Text = "",
						Name = "JoinButton",
					}),
					
					Create("ImageLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, -14, 0, -10),
						Size = UDim2.new(0, 76, 0, 74),
						Image = "rbxassetid://8992244272",
						ImageColor3 = Color3.fromRGB(0, 0, 0),
						ImageTransparency = 0.400,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(42, 42, 42, 42),
						Name = "Shadow",
					}),
					
					Create("ImageLabel", {
						BackgroundTransparency = 1.000,
						Size = UDim2.new(0, 48, 0, 48),
						Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..tostring(CreatorId).."&width=48&height=48&format=png",
						ScaleType = Enum.ScaleType.Crop,
						Name = "FriendPlayerIcon",
					}, {
						Create("UICorner", {
							CornerRadius = UDim.new(1, 0)
						})
					})
				})
			}),
			
			Create("UICorner" ,{}),
		})
		
		---------------| SupportedGamesScripts |---------------
		
		local FriendIconFrame = GameIcon.FriendIconFrame
		local FriendIconHolder =  FriendIconFrame.FriendIconHolder
		
		local JoinButton = FriendIconHolder.JoinButton
		local Circle = FriendIconHolder.Circle
		
		local TweenCompleted = false
		local FirstTween = false		

		local CanClick = false
		local WaitTime = .25

		JoinButton.MouseEnter:Connect(function()
			if TweenCompleted or not FirstTween then
				
				Tween(Circle, WaitTime, {BackgroundColor3 = Color3.fromRGB(0, 255, 0)})

				FriendIconHolder:TweenSize(UDim2.new(0, 95, 0, 48),	Enum.EasingDirection.In, Enum.EasingStyle.Sine, WaitTime, false, function()
					CanClick = true
					FirstTween = true
				end)

				FriendIconHolder:TweenSize(UDim2.new(0, 95, 0, 48),	Enum.EasingDirection.In, Enum.EasingStyle.Sine, WaitTime)
			end
		end)

		JoinButton.MouseLeave:Connect(function()
			
			Tween(Circle, WaitTime, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)})

			FriendIconHolder:TweenSize(UDim2.new(0, 48, 0, 48),	Enum.EasingDirection.In, Enum.EasingStyle.Sine, WaitTime, false, function()
				CanClick = false
				TweenCompleted = true
			end)

			FriendIconHolder:TweenSize(UDim2.new(0, 48, 0, 48),	Enum.EasingDirection.In, Enum.EasingStyle.Sine, WaitTime)
		end)

		JoinButton.MouseButton1Click:Connect(function()
			if CanClick then		
				FriendIconHolder:TweenSize(UDim2.new(0, 48, 0, 48),	Enum.EasingDirection.In, Enum.EasingStyle.Sine, WaitTime)
				task.wait()
				game:GetService("TeleportService"):Teleport(PlaceId, game.Players.LocalPlayer)
			end
		end)

		Parent.Changed:Connect(function()
			if Parent:IsA("ScrollingFrame") then
				if Parent:FindFirstChildOfClass("UIListLayout") then

					Parent.CanvasSize = UDim2.new(0, 0, Parent.UIListLayout.AbsoluteContentSize.Y ,0)

				elseif Parent:FindFirstChildOfClass("UIGridLayout") then
					Parent.CanvasSize = UDim2.new(0, 0, Parent.UIGridLayout.AbsoluteContentSize.Y ,0)	
				end
			end
		end)
	end
	
	for i, v in pairs(_G.LocalLibrary_SupportedGames) do
		CreateGame_Icon(MainFrame.Main.SupportedGamesFrame, v.CreatorId, v.PlaceId)
	end
	
	function lib:ToggleUI()

		local WaitDebounce = false

		if not GUI.Enabled and not WaitDebounce then

			WaitDebounce = true
			GUI.Enabled = true

			repeat wait() until GUI.Enabled
			
			TextButton2.Modal = true
			Tween(ShadowEffect, .45, {BackgroundTransparency = 0})
			
			repeat wait() until ShadowEffect.BackgroundTransparency == 0
			
			Tween(MainFrame.OptionsBar, .45, {Position = UDim2.new(0.5, 0, 1, 0)})

			repeat wait() until MainFrame.OptionsBar.Position == UDim2.new(0.5, 0, 1, 0)
			
			for _, v in pairs(MainFrame.Main:GetChildren()) do
				if v:IsA("Frame") or v:IsA("ScrollingFrame") then
					if v.Name == tostring(CurrentSection) then
						
						local Section = MainFrame.Main:FindFirstChild(CurrentSection)
						
						Section.Visible = true
						
						if tostring(CurrentSection) == "Work_in_Prgress" then

							Section:FindFirstChild("Frame").Position = UDim2.new(0.303, 0, 0.833, 0)
							Section.Visible = true

						elseif tostring(CurrentSection) == "ScriptsMainFrame" then
							
							Tween(Section:FindFirstChild("SectionsFrame"), .45, {Position = UDim2.new(0.303, 0, 0.833, 0)})
							wait(.15)
							Tween(Section:FindFirstChild("TabsFrame"), .45, {Position = UDim2.new(0, 0, 1, 0)})
							
						elseif tostring(CurrentSection) == "SupportedGamesButton" then
							
							Tween(Section, .45, {Position = UDim2.new(0, 0, 1, 0)})
							
						elseif tostring(CurrentSection) == "HomeMainFrame" then
							Tween(Section:FindFirstChild("UpdateLogsFrame"), .45, {Position = UDim2.new(0, 374, 0.8, 0)})
							wait(.15)
							Tween(Section:FindFirstChild("HomeInfoFrame"), .45, {Position = UDim2.new(0, 0, 1, 0)})
						end
					else
						for _, v2 in pairs(v:GetChildren()) do
							if v2:IsA("Frame") or v2:IsA("ScrollingFrame") then
								Tween(v2, .25, {Position = UDim2.new(0, -1170, 0, 0)})
							end
						end
						if v:IsA("ScrollingFrame") then
							Tween(v, .25, {Position = UDim2.new(0, -1170, 0, 0)})
						end
						v.Visible = false
					end
				end
			end
			
			repeat wait() until GUI.Enabled and ShadowEffect.BackgroundTransparency == 0 and MainFrame.OptionsBar.Position == UDim2.new(0.5, 0, 1, 0)
			
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			
			wait(.45)
			
			WaitDebounce = false
			
		elseif GUI.Enabled and not WaitDebounce then

			WaitDebounce = true
			
			for _, v in pairs(MainFrame.Main:GetChildren()) do
				if v:IsA("Frame") or v:IsA("ScrollingFrame") then
					for _, v2 in pairs(v:GetChildren()) do
						if v2:IsA("Frame") or v2:IsA("ScrollingFrame") then
							Tween(v2, .25, {Position = UDim2.new(0, -1170, 0, 0)}, function()
								v.Visible = false
							end)
						end
					end
					if v:IsA("ScrollingFrame") then
						Tween(v, .25, {Position = UDim2.new(0, -1170, 0, 0)}, function()
							v.Visible = false
						end)
					end
					repeat wait() until v.Visible == false
				end
			end
			
			Tween(MainFrame.OptionsBar, 3, {Position = UDim2.new(0.5, 0, 3, 0)})
			
			task.wait(.45)
			
			Tween(ShadowEffect, .45, {BackgroundTransparency = 1}, function()
				GUI.Enabled = false
			end)
			
			repeat wait() until not GUI.Enabled
			
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			TextButton2.Modal = false

			wait(.45)

			WaitDebounce = false
		end
	end
	
	UIS.InputBegan:Connect(function(Input, GamePaused)
		if Input.KeyCode == _G.LocalLibrary_Data.CloseBind and not GamePaused then
			lib:ToggleUI()
		end
	end)
	
	---------------| PlayerFriendSystem |---------------
	
	local HomeMain = HomeInfoFrame.HomeMain2
	local PlayerDataHolder = HomeMain.PlayerDataHolder
	
	local FriendsJoined = 0
	
	local FriendsJoined_List = {}
	
	local ErrorDisplayed = false

	local UpdateFriends = function()
		local s, e = pcall(function()
			for i, v in pairs(LP:GetFriendsOnline()) do

				if v.PlaceId == game.PlaceId then

					if table.find(FriendsJoined_List, v.VisitorId) then
						break
					end

					FriendsJoined += 1

					table.insert(FriendsJoined_List, v.VisitorId)
				end

				PLYS.PlayerRemoving:Connect(function(Player)
					if Player.UserId == v.VisitorId then
						
						FriendsJoined -= 1
						
						for _, visitorId in pairs(FriendsJoined_List) do
							if visitorId == v.VisitorId then
								table.remove(FriendsJoined_List, visitorId)
							end
						end
					end
				end)

				PlayerDataHolder.FriendsOnline.Text = i.." friends".."\n".."online"
				PlayerDataHolder.FriendsJoined.Text = FriendsJoined.." friends".."\n".."joined"
				
				for i, v in pairs(FriendsJoined_List) do
					print(i, v)
				end
			end
		end)

		if not s and not ErrorDisplayed then
			ErrorDisplayed = true
			return warn(e)
		end
	end

	UpdateFriends()
	
	---------------| UpdateLogsSystem |---------------
	
	local CreateUpdateLog_Frame = function(Text)
		local UpdateLog = Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.700,
			BorderSizePixel = 0,
			Selectable = true,
			Size = UDim2.new(0, 280, 0, 50),
			Name = "UpdateLog",
			Parent = UpdateLogsFrame.UpdateLogsListHolder.ScrollingFrame
		}, {
			
			Create("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1.000,
				BorderSizePixel = 0,
				Position = UDim2.new(0.0571428575, 0, 0, 0),
				Selectable = true,
				Size = UDim2.new(0, 264, 0, 50),
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14.000,
				Text = tostring(Text),
				TextXAlignment = Enum.TextXAlignment.Left,
				Name = "UpdateLogText",
			}),
			
			Create("UICorner", {})
		})
		
		local UIListLayoutSize = UpdateLogsFrame.UpdateLogsListHolder.ScrollingFrame.UIListLayout.AbsoluteContentSize
		
		UpdateLogsFrame.UpdateLogsListHolder.ScrollingFrame.Changed:Connect(function(Chanage)
			if Chanage == "Size" then
				UpdateLogsFrame.UpdateLogsListHolder.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayoutSize.Y + 25)
			end
		end)
	end
	
	CreateUpdateLog_Frame("[!] Hub Released to public!")
	CreateUpdateLog_Frame("[*] Some Bugs fixed!")
	
	CreateUpdateLog_Frame("[+] Added Natural Disater Script")
	CreateUpdateLog_Frame("[+] Added Tower of Hell Script")
	
	CreateUpdateLog_Frame("[+] Added Forgotten Memories Script")
	CreateUpdateLog_Frame("[+] Added TR:NE Script")
	
	---------------| UniversalButtonsFuctions |---------------
	
	local ResetChar_Button = UniversalButtons.ResetChar_MainFrame.ResetChar_Button
	local InvisibleChar_Button = UniversalButtons.InvisibleChar_MainFrame.InvisibleChar_Button
	local Godmode_Button = UniversalButtons.Godmode_MainFrame.Godmode_Button
	local FreeCam_Button = UniversalButtons.FreeCam_MainFrame.FreeCam_Button
	
	local Buttondebounce1 = false
	ResetChar_Button.MouseButton1Click:Connect(function()
		
		if Buttondebounce1 then
			return
		end
		
		Buttondebounce1 = true
		
		Tween(ResetChar_Button.Parent.ResetChar_Main, 1, {BackgroundTransparency = 0})
		Tween(ResetChar_Button.Parent.ResetChar_Main, 1, {BackgroundColor3 = windowSettings.AccentColor})
		
		pcall(function()
			LP.Character:BreakJoints()
		end)
		
		wait(.25)
		
		Tween(ResetChar_Button.Parent.ResetChar_Main, 1, {BackgroundTransparency = .5})
		Tween(ResetChar_Button.Parent.ResetChar_Main, 1, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)})
		
		Buttondebounce1 = false	
	end)
	
	local function fixcam()
		
		StopFreecam()
		
		workspace.CurrentCamera:remove()
		
		wait(.1)
		
		repeat wait() until LP.Character ~= nil
		
		workspace.CurrentCamera.CameraSubject = LP.Character:FindFirstChildWhichIsA("Humanoid")
		workspace.CurrentCamera.CameraType = "Custom"
		
		LP.CameraMinZoomDistance = 0.5
		LP.CameraMaxZoomDistance = 400
		
		LP.CameraMode = "Classic"
		LP.Character.Head.Anchored = false
	end
	
	local invisRunning = false
	local Buttondebounce2 = false
	
	InvisibleChar_Button.MouseButton1Click:Connect(function()
		
		if Buttondebounce1 then
			return
		end
		
		Buttondebounce1 = true
		
		Tween(InvisibleChar_Button.Parent.InvisibleChar_Main, 1, {BackgroundTransparency = 0})
		Tween(InvisibleChar_Button.Parent.InvisibleChar_Main, 1, {BackgroundColor3 = windowSettings.AccentColor})
		
		pcall(function()
			if invisRunning then return end
			invisRunning = true

			repeat wait(.1) until LP.Character
			local Character = LP.Character

			Character.Archivable = true

			local IsInvis = false
			local IsRunning = true

			local InvisibleCharacter = Character:Clone()
			InvisibleCharacter.Parent = game:GetService("Lighting")

			local Void = workspace.FallenPartsDestroyHeight
			InvisibleCharacter.Name = ""

			local CF

			local invisFix = RS.Stepped:Connect(function()
				pcall(function()

					local IsInteger

					if tostring(Void):find'-' then
						IsInteger = true
					else
						IsInteger = false
					end

					local Pos = LP.Character.HumanoidRootPart.Position
					local Pos_String = tostring(Pos)

					local Pos_Seperate = Pos_String:split(', ')

					local X = tonumber(Pos_Seperate[1])
					local Y = tonumber(Pos_Seperate[2])
					local Z = tonumber(Pos_Seperate[3])

					if IsInteger == true then
						if Y <= Void then
							Respawn()
						end
					elseif IsInteger == false then
						if Y >= Void then
							Respawn()
						end
					end
				end)
			end)

			for i,v in pairs(InvisibleCharacter:GetDescendants())do
				if v:IsA("BasePart") then
					if v.Name == "HumanoidRootPart" then
						v.Transparency = 1
					else
						v.Transparency = .5
					end
				end
			end

			function Respawn()

				IsRunning = false

				if IsInvis == true then
					pcall(function()

						LP.Character = Character

						wait()

						Character.Parent = workspace
						Character:FindFirstChildWhichIsA("Humanoid"):Destroy()

						IsInvis = false

						InvisibleCharacter.Parent = nil
						invisRunning = false
					end)
				elseif IsInvis == false then
					pcall(function()

						LP.Character = Character

						wait()

						Character.Parent = workspace

						Character:FindFirstChildWhichIsA("Humanoid"):Destroy()
						TurnVisible()
					end)
				end
			end

			local invisDied

			invisDied = InvisibleCharacter:FindFirstChildOfClass("Humanoid").Died:Connect(function()
				Respawn()
				invisDied:Disconnect()
			end)

			if IsInvis == true then return end

			IsInvis = true

			CF = workspace.CurrentCamera.CFrame
			local CF_1 = LP.Character.HumanoidRootPart.CFrame

			Character:MoveTo(Vector3.new(0,math.pi*1000000,0))
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

			wait(.2)

			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			InvisibleCharacter = InvisibleCharacter

			Character.Parent = game:GetService("Lighting")
			InvisibleCharacter.Parent = workspace

			InvisibleCharacter.HumanoidRootPart.CFrame = CF_1
			LP.Character = InvisibleCharacter

			fixcam()

			LP.Character.Animate.Disabled = true
			LP.Character.Animate.Disabled = false

			function TurnVisible()

				if IsInvis == false then return end

				invisFix:Disconnect()
				invisDied:Disconnect()

				CF = workspace.CurrentCamera.CFrame
				Character = Character

				local CF_1 = LP.Character.HumanoidRootPart.CFrame
				Character.HumanoidRootPart.CFrame = CF_1

				InvisibleCharacter:Destroy()

				LP.Character = Character
				Character.Parent = workspace

				IsInvis = false

				LP.Character.Animate.Disabled = true
				LP.Character.Animate.Disabled = false

				invisDied = Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
					Respawn()
					invisDied:Disconnect()
				end)
				invisRunning = false
			end
		end)
		
		wait(.25)
		
		Tween(InvisibleChar_Button.Parent.InvisibleChar_Main, 1, {BackgroundTransparency = .5})
		Tween(InvisibleChar_Button.Parent.InvisibleChar_Main, 1, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)})
		
		Buttondebounce2 = false
	end)
	
	local Buttondebounce3 = false
	Godmode_Button.MouseButton1Click:Connect(function()
		
		if Buttondebounce3 then
			return
		end
		
		Buttondebounce3 = true
		
		Tween(Godmode_Button.Parent.Godmode_Main, 1, {BackgroundTransparency = 0})
		Tween(Godmode_Button.Parent.Godmode_Main, 1, {BackgroundColor3 = windowSettings.AccentColor})
		
		pcall(function()
			local Cam = workspace.CurrentCamera

			local Pos, Char = Cam.CFrame, LP.Character
			local Human = Char and Char.FindFirstChildWhichIsA(Char, "Humanoid")
			local nHuman = Human.Clone(Human)

			nHuman.Parent, LP.Character = Char, nil

			nHuman.SetStateEnabled(nHuman, 15, false)
			nHuman.SetStateEnabled(nHuman, 1, false)
			nHuman.SetStateEnabled(nHuman, 0, false)

			nHuman.BreakJointsOnDeath, Human = true, Human.Destroy(Human)
			LP.Character, Cam.CameraSubject, Cam.CFrame = Char, nHuman, wait() and Pos
			nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

			local Script = Char.FindFirstChild(Char, "Animate")

			if Script then
				Script.Disabled = true
				wait()
				Script.Disabled = false
			end

			nHuman.Health = nHuman.MaxHealth
		end)
		
		wait(.25)
		
		Tween(Godmode_Button.Parent.Godmode_Main, 1, {BackgroundTransparency = .5})
		Tween(Godmode_Button.Parent.Godmode_Main, 1, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)})
		
		Buttondebounce3 = false
	end)
	
	local Buttondebounce4 = false
	FreeCam_Button.MouseButton1Click:Connect(function()
		
		if Buttondebounce4 then
			return
		end
		
		Buttondebounce4 = true

		if not fcRunning then
			
			Tween(FreeCam_Button.Parent.FreeCam_Main, 1, {BackgroundTransparency = 0})
			Tween(FreeCam_Button.Parent.FreeCam_Main, 1, {BackgroundColor3 = windowSettings.AccentColor})
			
			if LP.Character then
				if LP.Character:WaitForChild("Head") then
					local Head = LP.Character:WaitForChild("Head")
					StartFreecam(Head.CFrame + Vector3.new(0, 0, -3))
				else
					StopFreecam()
					wait(.5)
					StartFreecam()
				end
			else
				StopFreecam()
				wait(.5)
				StartFreecam()
			end

		else		

			Tween(FreeCam_Button.Parent.FreeCam_Main, 1, {BackgroundTransparency = .5})
			Tween(FreeCam_Button.Parent.FreeCam_Main, 1, {BackgroundColor3 = Color3.fromRGB(0, 0, 0)})
			
			StopFreecam()

		end
		
		wait(.25)

		Buttondebounce4 = false
	end)
	
	---------------| RandomFuctions |---------------
	
	local RandomInfoFrame = HomeInfoFrame.HomeMain2.RandomInfoFrame
	
	local CurrentFPS_Main = RandomInfoFrame.CurrentFPS_MainFrame.CurrentFPS_Main
	local CurrentFPS_Text = CurrentFPS_Main.CurrentFPS_Text

	coroutine.resume(coroutine.create(function()
		while task.wait(1) do	
			
			CurrentFPS_Text.Text = "Current FPS: "..tostring(CurrentFPS)
			CurrentFPS = 0
			
			UpdateFriends()
		end
	end))
	
	RS.RenderStepped:Connect(function()
		CurrentFPS += 1
	end)
	
	---------------| UI_Library_System |---------------
	
	local ScriptsMainFrame = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1.000,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Name = "ScriptsMainFrame",
		Parent = MainFrame.Main,
		Visible = false
	},{
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, -1170, 0, 0),
			Size = UDim2.new(0, 326, 0, 648),
			Name = "TabsFrame",
		}, {
			Create("TextLabel", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 24, 0, 24),
				Font = Enum.Font.GothamBlack,
				Text = "Tabs",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20.000,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Name = "TabsTitle"
			}),
			
			Create("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 0, 0.973765433, 0),
				Selectable = true,
				Size = UDim2.new(0.898773015, 0, 0.351851851, 344),
				ZIndex = 0,
				Name = "TabsListHolder",
			}, {
				Create("ScrollingFrame", {
					BackgroundTransparency = 1.000,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0.996503472, 0),
					ZIndex = 0,
					CanvasSize = UDim2.new(0, 0, 0, 580),
					ScrollBarThickness = 0,
				}, {
					Create("UIGridLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						CellPadding = UDim2.new(0, 8, 0, 8),
						CellSize = UDim2.new(0, 220, 0, 35),
						FillDirectionMaxCells = 1,
					})
				})
			}),
			
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.700,
				Position = UDim2.new(-0.0429447852, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Name = "TabsMain",
			},{
				Create("UICorner", {
					CornerRadius = UDim.new(0, 16)
				}),
				
				Create("UIStroke", {
					Color = windowSettings.AccentColor,
					Thickness = 2
				})
			})
		}),
		
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1.000,
			Position = UDim2.new(0, -1170, 0, 0),
			Size = UDim2.new(0, 852, 0, 430),
			Name = "SectionsFrame",
		}, {
			Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.700,
				Position = UDim2.new(0.00776600279, 0, -0.00930232555, 0),
				Size = UDim2.new(0.998278856, 0, 1, 0),
				Name = "SectionsMain",
			}, {
				Create("UICorner", {
					CornerRadius = UDim.new(0, 16)
				}), 
				
				Create("UIStroke", {
					Color = windowSettings.AccentColor,
					Thickness = 2
				})
			}),
		}),
		
		Create("UIScale", {})
	})
	
	local Pages = {}

	function Pages:NewPage(TabName, AssetId)

		TabName = TabName or "Tab"
		AssetId = AssetId or 0
		
		local Priority = 1
		
		local TabsFrame = ScriptsMainFrame.TabsFrame
		local SectionsFrame = ScriptsMainFrame.SectionsFrame
		
		local TabsListHolder = TabsFrame.TabsListHolder.ScrollingFrame
		
		local PageFrame = Create("ScrollingFrame", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1.000,
			BorderSizePixel = 0,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.new(0.0270504653, 0, 0.942220688, 0),
			Size = UDim2.new(0, 817, 0, 382),
			Visible = false,
			ScrollBarThickness = 0,
			Name = tostring(TabName) .. "_Holder",
			Parent = SectionsFrame,
			LayoutOrder = Priority
		}, {
			Create("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10)
			})
		})
		
		local PageButton = Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.750,
			ClipsDescendants = true,
			Size = UDim2.new(0, 220, 0, 35),
			Name = "Tab",
			Parent = TabsListHolder,
		}, {
			Create("TextButton", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 0, 0.058763776, 0),
				Size = UDim2.new(0, 220, 0, 35),
				Font = Enum.Font.SourceSans,
				Text = "",
				ZIndex = 2,
				TextSize = 14.000,
				Name = "MainButton",
			}, {
				Create("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					Position = UDim2.new(0.300000012, 0, 0, 0),
					Size = UDim2.new(0, 136, 0, 35),
					Font = Enum.Font.GothamBold,
					Text = tostring(TabName),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.75,
					TextSize = 14.000,
					Name = "Title",
				}),
				
				Create("ImageLabel", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					Position = UDim2.new(0.08, 0, 0.12, 0),
					Size = UDim2.new(0, 22, 0, 22),
					Image = "rbxassetid://"..tostring(AssetId),
					ImageTransparency = 0.75,
					Name = "Icon",
				})
			}),
			
			Create("UICorner", {
				CornerRadius = UDim.new(0, 16)
			})
		})
		
		PageButton.MainButton.MouseButton1Click:Connect(function()
			for _, v in pairs(TabsListHolder:GetChildren()) do
				if v:IsA("Frame") and v.Name == "Tab" then
					
					local Title = v.MainButton.Title
					local Icon = v.MainButton.Icon
					
					if Title.Text == TabName then
						Tween(Title, 1, {TextTransparency = 0})
						Tween(Icon, 1, {ImageTransparency = 0})
						
					else
						Tween(Title, 1, {TextTransparency = 0.75})
						Tween(Icon, 1, {ImageTransparency = 0.75})
					end
				end
			end
			
			for _, v in pairs(SectionsFrame:GetChildren()) do
				if v:IsA("ScrollingFrame") then
					if not (v.Name == "SectionsMain") and v.Name == TabName .. "_Holder" then
						v.Visible = true
					else
						v.Visible = false
					end
				end
			end
		end)
		
		local function UpdateSize()
			local cS = PageFrame.UIListLayout.AbsoluteContentSize
			PageFrame.CanvasSize = UDim2.new(0, 0, 0, cS.Y + 85)
		end
		
		Priority = Priority +1

--[[ 
		function Sections:CreateConfigSystem()

			local configSystemTable = {}

			configSystemTable.configFolder = windowSettings.Name .. "/" .. tostring(game.PlaceId)

			pcall(function()
				if (not isfolder(configSystemTable.configFolder)) then
					makefolder(configSystemTable.configFolder)
				end
			end)

			
			local Configs = Sections:AddSection("Configs")

			local ConfigName = Configs:AddTextbox("Config Name", "", ConfigName, function() end, "")
			local default = tostring(listfiles(configSystemTable.configFolder)[1] or ""):gsub(configSystemTable.configFolder .. "\\", ""):gsub(".txt", "")

			local Config = Configs:AddDropdown("Configs", {}, default, function() end, "")

			for i,v in pairs(listfiles(configSystemTable.configFolder)) do
				if v:find(".txt") then
					Config:Add(tostring(v):gsub(configSystemTable.configFolder .. "\\", ""):gsub(".txt", ""))
				end
			end

			configSystemTable.Create = Configs:AddButton("Create", function()
				for i,v in pairs(listfiles(configSystemTable.configFolder)) do
					Config:Remove(tostring(v):gsub(configSystemTable.configFolder .. "\\", ""):gsub(".txt", ""))
				end

				if ConfigName:GetValue() and ConfigName:GetValue() ~= "" then
					local config = {}

					for i,v in pairs(lib.flags) do
						if (v ~= nil and v ~= "") then
							if (typeof(v) == "Color3") then
								config[i] = { v.R, v.G, v.B }
							elseif (tostring(v):find("Enum.KeyCode")) then
								config[i] = v.Name
							elseif (typeof(v) == "table") then
								config[i] = { v }
							else
								config[i] = v
							end
						end
					end

					writefile(configSystemTable.configFolder .. "/" .. ConfigName:GetValue() .. ".txt", HTTPS:JSONEncode(config))

					for i,v in pairs(listfiles(configSystemTable.configFolder)) do
						if v:find(".txt") then
							Config:Add(tostring(v):gsub(configSystemTable.configFolder .. "\\", ""):gsub(".txt", ""))
						end
					end
				end
			end)

			configSystemTable.Save = Configs:AddButton("Save", function()
				local config = {}
				if Config:GetValue() and Config:GetValue() ~= "" then
					for i,v in pairs(lib.flags) do
						if (v ~= nil and v ~= "") then
							if (typeof(v) == "Color3") then
								config[i] = { v.R, v.G, v.B }
							elseif (tostring(v):find("Enum.KeyCode")) then
								config[i] = "Enum.KeyCode." .. v.Name
							elseif (typeof(v) == "table") then
								config[i] = { v }
							else
								config[i] = v
							end
						end
					end

					writefile(configSystemTable.configFolder .. "/" .. Config:GetValue() .. ".txt", HTTPS:JSONEncode(config))
				end
			end)

			configSystemTable.Load = Configs:AddButton("Load", function()
				local Success = pcall(readfile, configSystemTable.configFolder .. "/" .. Config:GetValue() .. ".txt")
				if (Success) then
					pcall(function() 
						local ReadConfig = HTTPS:JSONDecode(readfile(configSystemTable.configFolder .. "/" .. Config:GetValue() .. ".txt"))
						local NewConfig = {}

						for i,v in pairs(ReadConfig) do
							if (typeof(v) == "table") then
								if (typeof(v[1]) == "number") then
									NewConfig[i] = Color3.new(v[1], v[2], v[3])
								elseif (typeof(v[1]) == "table") then
									NewConfig[i] = v[1]
								end
							elseif (tostring(v):find("Enum.KeyCode.")) then
								NewConfig[i] = Enum.KeyCode[tostring(v):gsub("Enum.KeyCode.", "")]
							else
								NewConfig[i] = v
							end
							
							print(i, v)
						end

						lib.flags = NewConfig

						for i,v in pairs(lib.flags) do
							for i2,v2 in pairs(lib.Items) do
								if (i ~= nil and i ~= "" and i ~= "Configs_Name" and i ~= "Configs" and v2.flag ~= nil) then
									if (v2.flag == i) then
										pcall(function() 
											v2:SetValue(v)
										end)
									end
								end
							end
						end
					end)
				end
			end)

			configSystemTable.Delete = Configs:AddButton("Delete", function()
				
				for i,v in pairs(listfiles(configSystemTable.configFolder)) do
					Config:Remove(tostring(v):gsub(configSystemTable.configFolder .. "\\", ""):gsub(".txt", ""))
				end

				if (not Config:GetValue() or Config:GetValue() == "") then return end
				if (not isfile(configSystemTable.configFolder .. "/" .. Config:GetValue() .. ".txt")) then return end
				
				delfile(configSystemTable.configFolder .. "/" .. Config:GetValue() .. ".txt")

				for i,v in pairs(listfiles(configSystemTable.configFolder)) do
					if v:find(".txt") then
						Config:Add(tostring(v):gsub(configSystemTable.configFolder .. "\\", ""):gsub(".txt", ""))
					end
				end
			end)

			return configSystemTable
		end
		
		UpdateSize()
		]]--
		local Sections = {}
		
		function Sections:AddSection(SectionName)

			local SectionFrame = Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.750,
				ClipsDescendants = true,
				Position = UDim2.new(0.0223529413, 0, 0, 0),
				Size = UDim2.new(0.977647066, 0, 0, 45),
				Name = "Section",
				Parent = SectionsFrame:FindFirstChild(TabName.."_Holder"),
			}, {
				Create("ImageButton", {
					BackgroundTransparency = 1.000,
					Position = UDim2.new(0, 770, 0, 8),
					Size = UDim2.new(0, 20, 0, 20),
				}, {
					Create("ImageLabel", {
						BackgroundTransparency = 1.000,
						Rotation = 90.000,
						Size = UDim2.new(1, 0, 1, 0),
						Image = "rbxassetid://6031094670",
						Name = "Icon"
					})
				}),
				
				Create("TextLabel", {
					BackgroundTransparency = 1.000,
					Position = UDim2.new(0, 24, 0, 8),
					Font = Enum.Font.GothamBlack,
					Text = tostring(SectionName),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 20.000,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Name = "SectionTitle",
				}),
				
				Create("ScrollingFrame", {
					Active = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					BorderSizePixel = 0,
					Position = UDim2.new(0.0136457281, 0, 0.118710294, 0),
					Size = UDim2.new(0, 797, 0, 318),
					CanvasPosition = Vector2.new(0, 129.605896),
					ScrollBarThickness = 0,
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 88),
					})
				}),
				
				Create("UICorner", {})
			})
			
			local Container = Create("Frame", {
				BackgroundTransparency = 1.000,
				Position = UDim2.new(0, 10, 0, 48),
				Size = UDim2.new(0.978048801, 0, 0, 245),
				Parent = SectionFrame.ScrollingFrame,
			}, {
				Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5)
				})
			})
			
			local UIListLayoutSize = SectionFrame.ScrollingFrame.UIListLayout.AbsoluteContentSize
			
			local WaitingDebounce = false
			local secCollapsed = false
			
			local order = 0
			
			local function UpdateSectionFrame()				
				SectionFrame.Size = UDim2.new(0.977647066, 0, 0, UIListLayoutSize.Y + 25)
				SectionFrame.ScrollingFrame.Size = UDim2.new(0.977647066, 0, 0, UIListLayoutSize.Y + 85)
			end
			
			SectionFrame.ImageButton.MouseButton1Click:Connect(function()
				
				if WaitingDebounce then
					return
				end
				
				if SectionFrame.ImageButton.Icon.Rotation == 90 then
					
					WaitingDebounce = true
					secCollapsed = true
					
					wait(.45)
					
					WaitingDebounce = false
					
				else
					
					WaitingDebounce = true
					secCollapsed = false
					
					wait(.45)
					
					WaitingDebounce = false
				end

				Tween(SectionFrame, 1, {Size = secCollapsed and UDim2.new(0.977647066, 0, -0.028862942, 60) or UDim2.new(0.977647066, 0, 0, UIListLayoutSize.Y + 85)})		
				Tween(SectionFrame.ScrollingFrame, 1, {Size = secCollapsed and UDim2.new(0.977647066, 0, -0.028862942, 60) or UDim2.new(0.977647066, 0, 0, UIListLayoutSize.Y + 85)})
				
				Tween(SectionFrame.ImageButton.Icon, 1, {Rotation = secCollapsed and -90 or 90})
				
				task.wait(.45)
				
				SectionFrame.ScrollingFrame.Visible = not SectionFrame.ScrollingFrame.Visible
			end)
			
function lib:UpdateSectionName(newText)
				if SectionFrame.SectionTitle.Text ~= newText then
					SectionFrame.SectionTitle.Text = newText
				end
			end
			
			function lib:RemoveItems()
				for _, v in pairs(SectionFrame.ScrollingFrame.Frame:GetChildren()) do
					if v:IsA("Frame") or v:IsA("TextButton") then
						
						for i, _ in pairs(lib.Items) do
							if table.find(lib.Items, v) then
								table.remove(lib.Items, i)
							end
						end
						
						v:Remove()
						
						UpdateSize()
						UpdateSectionFrame()
					end
				end
			end

			UpdateSize()
			UpdateSectionFrame()

			--Tween(SectionFrame, 1, {Size = UDim2.new(0.977647066, 0, 0, UIListLayoutSize.Y + 25)})
			--Tween(SectionFrame.ScrollingFrame, 1, {Size = UDim2.new(0.977647066, 0, 0, UIListLayoutSize.Y + 25)})

			SectionFrame.ScrollingFrame.Frame.ChildAdded:Connect(UpdateSectionFrame)
			SectionFrame.ScrollingFrame.Frame.ChildRemoved:Connect(UpdateSectionFrame)
			
			SectionFrame.ScrollingFrame.ChildAdded:Connect(UpdateSectionFrame)
			SectionFrame.ScrollingFrame.ChildRemoved:Connect(UpdateSectionFrame)

			local Components = {}
			
			function Components:AddLabel(Text)
				
				local LabelFunctions = {}
				Text = Text or ""
				
				local b1 = Create("TextButton", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = UDim2.new(0, 0, 0.142857149, 0),
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					AutoButtonColor = false,
					Text = "",
					Parent = Container,
					LayoutOrder = order
				}, {
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0.5, -8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})
				})
				
				function LabelFunctions:UpdateLabel(newText)
					if b1.TextLabel.Text ~= newText then
						b1.TextLabel.Text = newText
					end
				end
				
				UpdateSize()
				UpdateSectionFrame()
				
				order = order +1
				table.insert(lib.Items, b1)

				return LabelFunctions
			end
			
			function Components:AddButton(Text, callback)
				
				local b1 = {}
				
				local ButtonFunctions = {}
				local btn_debounce = false
				
				callback = callback or function() end
				Text = Text or ""
				
				b1.TextButton = Create("TextButton", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					AutoButtonColor = false,
					Text = "",
					Parent = Container,
					LayoutOrder = order
				}, {
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0.5, -8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("ImageLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(1, -30, 0.5, -12),
						Size = UDim2.new(0, 24, 0, 24),
						Image = "rbxassetid://6023565895",
						ImageTransparency = 0,
					}),
					
					Create("UICorner", {})
				})
				
				b1.TextButton.MouseButton1Click:Connect(function()
					
					if btn_debounce then
						return
					end
					
					callback()
					
					btn_debounce = true
					
					Tween(b1.TextButton.ImageLabel, .3, {ImageColor3 = windowSettings.AccentColor})
					
					wait(.25)
					
					Tween(b1.TextButton.ImageLabel, .3, {ImageColor3 = Color3.fromRGB(255, 255, 255)})

					btn_debounce = false
				end)
				
				function ButtonFunctions:UpdateButton(newText)
					if b1.TextButton.TextLabel.Text ~= newText then
						b1.TextButton.TextLabel.Text = newText
					end
				end
				
				UpdateSize()
				UpdateSectionFrame()
				
				order = order +1
				table.insert(lib.Items, b1)
				
				return ButtonFunctions
			end
			
			function Components:AddToggle(Text, callback, flag)
				
				callback = callback or function() end
				Text = Text or ""
				
				local b1 = {}
				
				b1.flag = flag or Text or ""
				
				local ToggleFunctions = {}
				local Toggled = false
				

				
				b1.Toggle = Create("TextButton", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					AutoButtonColor = false,
					Text = "",
					Parent = Container,
					LayoutOrder = order
				}, {
					
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0.5, -8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(20, 21, 25),
						Position = UDim2.new(1, -30, 0.5, -12),
						Size = UDim2.new(0, 24, 0, 24),
					}, {
						
						Create("ImageLabel", {
							BackgroundTransparency = 1.000,
							Position = UDim2.new(0.5, -10, 0.5, -10),
							Size = UDim2.new(0, 20, 0, 20),
							Image = "rbxassetid://6031094667",
							ImageTransparency = 1,
							ImageColor3 = windowSettings.AccentColor
						}),
						
						Create("UIStroke", {
							Color = Color3.fromRGB(23, 24, 29),
							Thickness = 1,
						}),
						
						Create("UICorner", {
							CornerRadius = UDim.new(0, 4)
						})
					}),
					
					Create("UICorner", {})
				})
				
				if b1.flag and b1.flag ~= "" then
					lib.flags[b1.flag] = Toggled or false
				end

				function ToggleFunctions:SetValue(Value)
					
					Toggled = Value
					
					if b1.flag and b1.flag ~= "" then
						lib.flags[b1.flag] = Toggled or false
					end
					
					Tween(b1.Toggle.Frame.UIStroke, .3, {Color = Toggled and windowSettings.AccentColor or Color3.fromRGB(23, 24, 29)})
					Tween(b1.Toggle.Frame.ImageLabel, .3, {ImageTransparency = Toggled and 0 or 1})
					
					callback(Toggled)
				end
				
				function ToggleFunctions:GetValue()
					return Toggled
				end
				
				b1.Toggle.MouseButton1Click:Connect(function()			
					if Toggled then
						ToggleFunctions:SetValue(false)
					else
						ToggleFunctions:SetValue(true)
					end
				end)
				
				UpdateSize()
				UpdateSectionFrame()
				
				order = order +1
				table.insert(lib.Items, b1)
				
				return ToggleFunctions
			end
			
			function Components:AddTextbox(Text, Place_Holder, Default, callback, flag)
				
				callback = callback or function() end
				Place_Holder = Place_Holder or ""
				
				local b1 = {}
				
				b1.flag = flag or Text or ""
				
				Default = Default or ""
				Text = Text or ""

				local TextboxFunctions = {}
				
				b1.TextBox = Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					Parent = Container,
					LayoutOrder = order
				}, {
					
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0.5, -8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("TextBox", {
						BackgroundColor3 = Color3.fromRGB(13, 14, 16),
						Position = UDim2.new(1, -155, 0.5, -12),
						Size = UDim2.new(0, 150, 0, 24),
						Font = Enum.Font.GothamBlack,
						PlaceholderColor3 = Color3.fromRGB(80, 80, 80),
						PlaceholderText = tostring(Place_Holder),
						Text = tostring(Default),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextWrapped = true,
					}, {
						Create("UICorner", {
							CornerRadius = UDim.new(0, 4)
						}),
						
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(23, 24, 29),
							Thickness = 1,
						})
					}),
					
					Create("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})
				})
				
				if b1.flag and b1.flag ~= "" then
					lib.flags[b1.flag] = Default or ""
				end

				b1.TextBox.TextBox.Focused:Connect(function()
					Tween(b1.TextBox.TextBox.UIStroke, .3, {Color = windowSettings.AccentColor})
				end)
				
				function TextboxFunctions:SetValue(Newtext)
					
					b1.TextBox.TextBox.Text = Newtext
					
					if b1.flag and b1.flag ~= "" then
						lib.flags[b1.flag] = Newtext or ""
					end
					
					callback(b1.TextBox.TextBox.Text)
				end
				
				function TextboxFunctions:GetValue()
					return b1.TextBox.TextBox.Text
				end
				
				b1.TextBox.TextBox.FocusLost:Connect(function()
					Tween(b1.TextBox.TextBox.UIStroke, .3, {Color = Color3.fromRGB(24, 25, 30)})
					TextboxFunctions:SetValue(b1.TextBox.TextBox.Text)
				end)
				
				UpdateSize()
				UpdateSectionFrame()
				
				order = order +1
				table.insert(lib.Items, b1)
				
				return TextboxFunctions
			end
			
			function Components:AddDropdown(Text, Items, Default, callback, flag)
				
				callback = callback or function() end
				Items = Items or {}
				
				local b1 = {}
				
				b1.flag = flag or Text or ""

				Default = Default or ""
				Text = Text or ""

				local DropdownFunctions = {}
				
				local dropdownOpen = false
				local listcount = 1
				
				b1.Dropdown = Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					ClipsDescendants = true,
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					Parent = Container,
					LayoutOrder = order
				}, {
					
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0, 8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("TextBox", {
						BackgroundColor3 = Color3.fromRGB(13, 14, 16),
						Position = UDim2.new(1, -185, 0, 3),
						Size = UDim2.new(0, 150, 0, 24),
						Font = Enum.Font.GothamBlack,
						PlaceholderText = "...",
						Text = tostring(Default),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextWrapped = true,
					}, {
						Create("UICorner", {
							CornerRadius = UDim.new(0, 4)
						})
					}),
					
					Create("ImageButton", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(1, -30, 0, 3),
						Size = UDim2.new(0, 24, 0, 24),
					}, {
						
						Create("ImageLabel", {
							BackgroundTransparency = 1.000,
							Rotation = 270.000,
							Size = UDim2.new(1, 0, 1, 0),
							Image = "rbxassetid://6031094670",
							Name = "Icon"
						}),
						
						Create("UICorner", {
							CornerRadius = UDim.new(0, 4)
						})
					}),
					
					Create("ScrollingFrame", {
						BackgroundTransparency = 1.000,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 2, 0, 32),
						Size = UDim2.new(1, -4, 1, -32),
						BottomImage = "",
						CanvasSize = UDim2.new(0, 0, 0, 108),
						ScrollBarThickness = 6,
						TopImage = "",
						VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					}, {
						Create("UIListLayout", {
							Padding = UDim.new(0, 5)
						}),
						
						Create("UIPadding", {
							PaddingBottom = UDim.new(0, 5),
							PaddingLeft = UDim.new(0, 5),
							PaddingRight = UDim.new(0, 5),
							PaddingTop = UDim.new(0, 5),
						})
					}),
					
					Create("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})
				})
				
				if b1.flag and b1.flag ~= "" then
					lib.flags[b1.flag] = Default or Items[1] or ""
				end
				
				b1.Dropdown.ImageButton.MouseButton1Click:Connect(function()
					dropdownOpen = not dropdownOpen
					
					Tween(b1.Dropdown.ImageButton.Icon, 0.5, {Rotation = dropdownOpen and 90 or 270})
					Tween(b1.Dropdown, 0.5, {Size = dropdownOpen and UDim2.new(1, 0, 0, 120) or UDim2.new(1, 0, 0, 30)})
				end)

				b1.Dropdown.Changed:Connect(function(Chanage)
					if Chanage == "Size" then
						UpdateSize()
						UpdateSectionFrame()
					end
				end)
				
				function DropdownFunctions:Add(v)

					local btndebounce = false;

					local b3 = Create("TextButton", {
						BackgroundColor3 = Color3.fromRGB(13, 14, 16),
						Size = UDim2.new(1, 0, 0, 30),
						Parent = b1.Dropdown.ScrollingFrame,
						Text = "",
						Name = tostring(v),
						AutoButtonColor = false,
					}, {
						Create("UIStroke", {
							ApplyStrokeMode = 1,
							Color = Color3.fromRGB(24, 25, 30)
						}),
						Create("UICorner", {
							CornerRadius = UDim.new(0, 4)
						}),
						Create("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 10, 0.5, -8),
							Size = UDim2.new(1, -10, 0, 14),
							Font = Enum.Font.GothamBlack,
							Text = listcount.." - "..v,
							TextColor3 = Color3.new(1, 1, 1),
							TextSize = 14,
							TextXAlignment = Enum.TextXAlignment.Left
						})
					})

					b1.Dropdown.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, b1.Dropdown.ScrollingFrame.CanvasSize.Y.Offset + 36)

					b3.MouseButton1Click:Connect(function()

						b1.Dropdown.TextBox.Text = v
						
						callback(b1.Dropdown.TextBox.Text)
						
						if b1.flag and b1.flag ~= "" then
							lib.flags[b1.flag] = b1.Dropdown.TextBox.Text or Default or Items[1] or ""
						end

						if not btndebounce then
							btndebounce = true
							TS:Create(b3.UIStroke, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {Color = windowSettings.AccentColor}):Play()
							wait(0.4)
							btndebounce = false
						end
					end)

					--UpdateSize()
					--UpdateSectionFrame()

					listcount = listcount +1
				end

				function DropdownFunctions:Update(newlist)
					
					for i, v in pairs(b1.Dropdown.ScrollingFrame:GetChildren()) do
						if v:IsA("TextButton") then
							v:Destroy()
						end
					end
					
					Items = newlist
					b1.Dropdown.TextBox.Text = ""
					
					for i, v in pairs(Items) do
						DropdownFunctions:Add(v)
					end
				end

				for i, v in pairs(Items) do
					DropdownFunctions:Add(v)
				end
				
				function DropdownFunctions:Remove(value)
					
					local item = b1.Dropdown.ScrollingFrame:FindFirstChild(value)
					
					if item then
						for i,v in pairs(Items) do
							if v == value then
								table.remove(Items, i)
							end
						end

						b1.Dropdown.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, b1.Dropdown.ScrollingFrame.CanvasSize.Y.Offset + 36)

						item:Remove()
					end
				end
				
				function DropdownFunctions:SetValue(value)
					if type(value) == "table" then
						Items = value
						callback(value)
						b1.Dropdown.TextBox.text = tostring(value)
					else
						Items = { value }
						callback(value)
						b1.Dropdown.TextBox.text = tostring(value)
					end
					
					if b1.flag and b1.flag ~= "" then
						lib.flags[b1.flag] = value or Default or Items[1] or ""
					end
				end

				function DropdownFunctions:GetValue()
					for i, v in pairs(Items) do
						if string.match(v, b1.Dropdown.TextBox.Text)then
							return v
						else
							return b1.Dropdown.TextBox.Text
						end
					end
				end
				
				UpdateSize()
				UpdateSectionFrame()
				
				order = order +1
				table.insert(lib.Items, b1)
				
				return DropdownFunctions
			end
			
			function Components:AddSlider(Text, minValue, maxValue, default, callback, flag)
				
				
				local SliderFunctions = {}
				
				minValue = minValue or 0
				maxValue = maxValue or 1
				
				local b1 = {}
				
				b1.flag = flag or Text or ""
				
				default = default or 0
				
				callback = callback or function() end
				local valuee = 0
				
				b1.Slider = Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					LayoutOrder = 3,
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					Parent = Container,
				}, {
					
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0.5, -8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text).." "..tostring(default).." / "..tostring(maxValue),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(13, 14, 16),
						ClipsDescendants = true,
						Position = UDim2.new(1, -155, 0.5, -6),
						Size = UDim2.new(0, 150, 0, 12),
					}, {
						
						Create("Frame", {
							BackgroundColor3 = windowSettings.AccentColor,
							Size = UDim2.new(default / maxValue, 0, 1, 0),
							Name = "sliderVal"
						}, {
							Create("UICorner", {
								CornerRadius = UDim.new(1, 0)
							})
						}),
						
						Create("UICorner", {
							CornerRadius = UDim.new(1, 0)
						})
					}),
					
					Create("UIStroke", {
						Color = windowSettings.AccentColor,
						Thickness = 0,
					}),
					
					Create("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})
				})
				
				if b1.flag and b1.flag ~= "" then
					lib.flags[b1.flag] = default or minValue or 0
				end
				
				local draggingg = false
				
				local function moveSlider(input)
					local pos = UDim2.new(math.clamp((input.Position.X - b1.Frame.AbsolutePosition.X) / b1.Frame.AbsoluteSize.X, 0, 1), 0, 1, 0)
					Tween(b1.Frame.sliderVal, 0.3, {Size = pos})
					
					--local SliderPrecise = ((pos.X.Scale * maxValue) / maxValue) * (maxValue - minValue) + minValue
					local SliderNotPrecise = math.floor(((pos.X.Scale * maxValue) / maxValue) * (maxValue - minValue) + minValue)
					
					valuee = tonumber(string.format("%.2f", SliderNotPrecise))--tonumber(SliderNotPrecise)
					
					task.wait()
					
					b1.PercentageText.Text = tostring(valuee).." / "..tostring(maxValue)--tostring(string.format("[%f/%f]", valuee, maxValue))
					callback(valuee)
				end
				
				local function updateSlider(value, min, max)

					local percent = (Mouse.X - b1.Slider.Frame.sliderVal.AbsolutePosition.X) / b1.Slider.Frame.sliderVal.AbsoluteSize.X

					if value then
						percent = (value - min) / (max - min)
					end

					percent = math.clamp(percent, 0, 1)
					value = value or math.floor(min + (max - min) * percent)

					b1.Slider.TextLabel.Text = tostring(Text).." "..tostring(value).." / "..tostring(maxValue)
					Tween(b1.Slider.Frame.sliderVal, 0.1, {Size = UDim2.new(percent, 0, 1, 0)})

					return value
				end
				

				
				function SliderFunctions:SetValue(Value)

					Tween(b1.Slider.Frame.sliderVal, 0.3, {Size = UDim2.new(Value / maxValue, 0, 1, 0)})
					valuee = updateSlider(nil, minValue, maxValue)--Value
					
					if b1.flag and b1.flag ~= "" then
						lib.flags[b1.flag] = valuee
					end
					
					callback(valuee)
				end

				function SliderFunctions:GetValue()
					return valuee;
				end
				
				function SliderFunctions:Refresh()
					local mousePos = Camera:WorldToViewportPoint(Mouse.Hit.p)

					local percent = math.clamp(mousePos.X - b1.Slider.Frame.sliderVal.AbsolutePosition.X, 0, b1.Slider.Frame.AbsoluteSize.X) / b1.Slider.Frame.AbsoluteSize.X
					local value = math.floor((minValue + (maxValue - minValue) * percent) * 1) / 1

					value = math.clamp(value, minValue, maxValue)
					SliderFunctions:SetValue(value)
				end

				b1.Slider.Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						SliderFunctions:Refresh()
						draggingg = true
					end
				end)

				b1.Slider.Frame.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						draggingg = false
					end
				end)

				UIS.InputChanged:Connect(function(input)
					if draggingg and input.UserInputType == Enum.UserInputType.MouseMovement then
						SliderFunctions:Refresh()
					end
				end)
				
				UpdateSize()
				UpdateSectionFrame()

				order = order +1
				table.insert(lib.Items, b1)
				
				return SliderFunctions
			end
			
			function Components:AddKeybind(Text, key, callback, flag)
				
				local KeyBindFunctions = {}
				
				local btndebounce = false
				local KeyName = key.Name

				callback = callback or function() end
				
				local b1 = {}
				
				b1.flag = flag or Text or ""
				
				Text = Text or ""
				key = key or nil
				
				b1.KeyBind = Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(13, 14, 16),
					BackgroundTransparency = 0.500,
					Size = UDim2.new(1, 0, 0.0759999976, 20),
					Parent = Container,
					LayoutOrder = order
				}, {
					
					Create("TextLabel", {
						BackgroundTransparency = 1.000,
						Position = UDim2.new(0, 10, 0.5, -8),
						Size = UDim2.new(1, -10, 0, 14),
						Font = Enum.Font.GothamBlack,
						Text = tostring(Text),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					
					Create("TextButton", {
						BackgroundColor3 = Color3.fromRGB(13, 14, 16),
						Position = UDim2.new(1, -155, 0.5, -12),
						Size = UDim2.new(0, 150, 0, 24),
						Font = Enum.Font.RobotoMono,
						Text = tostring(KeyName),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14.000,
						TextWrapped = true,
					}, {
						
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(24, 25, 30),
							Thickness = 1
						}),
						
						Create("UICorner", {
							CornerRadius = UDim.new(0, 4)
						})
					}),
					
					Create("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})
				})

				if b1.flag and b1.flag ~= "" then
					lib.flags[b1.flag] = key
				end
				
				b1.KeyBind.TextButton.MouseButton1Click:Connect(function()
					
					Tween(b1.KeyBind.TextButton.UIStroke, 0.3, {Color = windowSettings.AccentColor})

					if not (b1.KeyBind.TextButton.Text == "...") then						
						b1.KeyBind.TextButton.Text = "..."
						wait(.35)
						Tween(b1.KeyBind.TextButton.UIStroke, 0.3, {Color = Color3.fromRGB(24, 25, 30)})
						return
					end

					if not (b1.KeyBind.TextButton.Text == "...") then
						return 
					end

					local InputBeganWait = game:GetService("UserInputService").InputBegan:Wait()

					if InputBeganWait.KeyCode.Name ~= "Unknown" then
						
						b1.KeyBind.TextButton.Text = InputBeganWait.KeyCode.Name
						KeyName = InputBeganWait.KeyCode.Name
						
						if b1.flag and b1.flag ~= "" then
							lib.flags[b1.flag] = InputBeganWait.KeyCode
						end
					end
				end)
				
				UIS.InputBegan:Connect(function(current, pressed)
					if not pressed then
						if current.KeyCode.Name == KeyName then
							Tween(b1.KeyBind.TextButton.UIStroke, 0.3, {Color = windowSettings.AccentColor})
							callback(current.KeyCode)
							wait(.15)
							Tween(b1.KeyBind.TextButton.UIStroke, 0.3, {Color = Color3.fromRGB(24, 25, 30)})
						end
					end
				end)
				
				function KeyBindFunctions:SetValue(value)
					if KeyName then
						if tostring(value):find("Enum.KeyCode.") then
							
							b1.KeyBind.TextButton.Text = tostring(value.Name)
							KeyName = value.Name
							
							if b1.flag and b1.flag ~= "" then
								lib.flags[b1.flag] = value
							end
							
							Tween(b1.KeyBind.TextButton.UIStroke, 0.3, {Color = Color3.fromRGB(24, 25, 30)})
							callback(value)
						end
					end
				end
				
				function KeyBindFunctions:GetValue()
					return "Enum.KeyCode."..KeyName
				end
				
				UpdateSize()
				UpdateSectionFrame()
				
				order = order +1
				table.insert(lib.Items, b1)
				
				return KeyBindFunctions
			end
			return Components
		end
		return Sections
	end	
	return Pages
end

local MyTable = {1, 2, 3}

for i, v in pairs(MyTable) do
	if v == 2 then
		print(MyTable)
		
		wait(1)
		
		table.remove(MyTable, v)
		
		wait(1)
		
		print(MyTable)
	end
end

local MPS = game:GetService("MarketplaceService")
local UIS = game:GetService("UserInputService")

local HTTPS = game:GetService("HttpService")

local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")

local StarterGui = game:GetService("StarterGui")
local PLYS = game:GetService("Players")

local LP = PLYS.LocalPlayer
local Mouse = LP:GetMouse()

local TextService = game:GetService("TextService")
local COREGUI = game:GetService("CoreGui")

local camera = workspace.CurrentCamera

local ESP = nil

local t = tick()

if not game:GetService("RunService"):IsStudio() then
	ESP = loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))()
	ESP:Toggle(true); ESP.Players = false; ESP.Names = true; ESP.Tracers = false; ESP.Boxes = false;
else
	ESP = {}
	function ESP:Toggle(bool) return end
end

function Format(Int)
	return string.format("%02i", Int)
end

function ConvertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60

	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60

	return Format(Hours).."H "..Format(Minutes).."M "..Format(Seconds)..'S'
end

function isNumber(str)
	if tonumber(str) ~= nil or str == 'inf' then
		return true
	end
end

function getRoot(CHARACTER)
	local RootPart = CHARACTER:FindFirstChild('HumanoidRootPart') or CHARACTER:FindFirstChild('Torso') or CHARACTER:FindFirstChild('UpperTorso')
	return RootPart
end

function GetCharacter_HumanoidRigType(PLR)
	if PLR.Character:FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R15 then
		return true
	end
end

function GetPlayer(PlayerName)
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if string.find(v.Name, PlayerName) or string.find(v.DisplayName, PlayerName)  then
			return v
		elseif v.Name:sub(1, PlayerName:len()):lower() == PlayerName:lower() then
			return v
		end
	end
end

if RS:IsStudio() then
	lib = require(LP:WaitForChild("PlayerGui"):WaitForChild("AzureWare_UI_Library"))
end

local Main_UI = lib:CreateWindow("Azure-Ware", Color3.fromRGB(38, 55, 189))

local UniversalPage = Main_UI:NewPage("Universal", 7072717348)
local CharacterPage = Main_UI:NewPage("Character", 6887023120)

local ScriptsPage = Main_UI:NewPage("Scripts", 4621599120)

local MiscPage = Main_UI:NewPage("Misc", 7072716775)
local CreditsPage = Main_UI:NewPage("Credits", 6883783410)

local ExperimentalPage = Main_UI:NewPage("Experimental", 7072707647)

print(lib)

---------------| Universal Section |---------------

local UniversalSection = UniversalPage:AddSection("Visuals")

UniversalSection:AddToggle("Toggle ESP", "You can enable/disable this to see the players ESP", false, function(t)
	ESP:Toggle(t)
end)

UniversalSection:AddToggle("Players ESP", "You will all the players and the player distance from you", false, function(t)
	ESP.Players = t
end)

UniversalSection:AddToggle("ESP Nametags", "You Will able see the player name", true, function(t)
	ESP.Names = t
end)

UniversalSection:AddToggle("ESP Tracers", "You Will able to track the player in his current position", false, function(t)
	ESP.Tracers = t
end)

UniversalSection:AddToggle("ESP Boxes", "You Will able see the player HitBox", false, function(t)
	ESP.Boxes = t
end)
local materials = true
local objects = {}

function scan(object)
	local objectlist = object:GetChildren()

	for i = 1, #objectlist do
		if objectlist[i]:IsA('BasePart') then
			objects[objectlist[i]] = objectlist[i].Material
		end
		scan(objectlist[i])
	end
end

scan(workspace)

UniversalSection:AddToggle("Remove Textures", function(arg)

	materials = not materials

	if materials then
		for i in pairs(objects) do
			i.Material = objects[i]
			i.CastShadow = true
		end
	else
		for i in pairs(objects) do
			i.Material = Enum.Material.SmoothPlastic
			i.CastShadow = false
		end
	end
end)

function x_ray(v)
	if v then
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				v.LocalTransparencyModifier = 0.5
			end
		end
	else
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				v.LocalTransparencyModifier = 0
			end
		end
	end
end

UniversalSection:AddToggle("Xrays", function(t)
	if t then
		x_ray(t)
	else
		x_ray(t)
	end
end)

UniversalSection:AddButton("See Chat Logs", function()
	pcall(function()
		LP.PlayerGui.Chat.Frame.ChatChannelParentFrame.Visible = true
		LP.PlayerGui.Chat.Frame.ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -42)
	end)
end)

UniversalSection:AddToggle("Reset Button", function(t)
	pcall(function() StarterGui:SetCore("ResetButtonCallback", t) end)
end)

local UniversalSection2 = UniversalPage:AddSection("LocalPlayer")

FLYING = false
QEfly = true

flyspeed = 1

flyKeyDown = nil
flyKeyUp = nil

function sFLY()

	repeat wait() until LP and LP.Character and getRoot(LP.Character) and LP.Character:FindFirstChildOfClass("Humanoid") and Mouse

	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end

	local T = getRoot(LP.Character)
	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0

	local function FLY()

		FLYING = true

		local BG = Instance.new('BodyGyro')
		local BV = Instance.new('BodyVelocity')

		BG.P = 9e4
		BG.Parent = T
		BV.Parent = T

		BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.cframe = T.CFrame

		BV.velocity = Vector3.new(0, 0, 0)
		BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

		task.spawn(function()
			repeat wait()

				if LP.Character:FindFirstChildOfClass('Humanoid') then
					LP.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
				end

				if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
					SPEED = 50
				elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
					SPEED = 0
				end

				if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
					BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
					lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
				elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
					BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
				else
					BV.velocity = Vector3.new(0, 0, 0)
				end

				BG.cframe = workspace.CurrentCamera.CoordinateFrame
			until not FLYING

			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}

			SPEED = 0

			BG:Destroy()
			BV:Destroy()

			if LP.Character:FindFirstChildOfClass('Humanoid') then
				LP.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
			end
		end)
	end

	flyKeyDown = Mouse.KeyDown:Connect(function(KEY)
		if KEY:lower() == 'w' then
			CONTROL.F = (flyspeed)
		elseif KEY:lower() == 's' then
			CONTROL.B = - (flyspeed)
		elseif KEY:lower() == 'a' then
			CONTROL.L = - (flyspeed)
		elseif KEY:lower() == 'd' then 
			CONTROL.R = (flyspeed)
		elseif QEfly and KEY:lower() == 'e' then
			CONTROL.Q = (flyspeed)*2
		elseif QEfly and KEY:lower() == 'q' then
			CONTROL.E = -(flyspeed)*2
		end
		pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
	end)

	flyKeyUp = Mouse.KeyUp:Connect(function(KEY)
		if KEY:lower() == 'w' then
			CONTROL.F = 0
		elseif KEY:lower() == 's' then
			CONTROL.B = 0
		elseif KEY:lower() == 'a' then
			CONTROL.L = 0
		elseif KEY:lower() == 'd' then
			CONTROL.R = 0
		elseif KEY:lower() == 'e' then
			CONTROL.Q = 0
		elseif KEY:lower() == 'q' then
			CONTROL.E = 0
		end
	end)
	FLY()
end

function NOFLY()

	FLYING = false

	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end

	if LP.Character:FindFirstChildOfClass('Humanoid') then
		LP.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end

	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end


UniversalSection2:AddToggle("Fly Script", function(arg)
	if FLYING then
		NOFLY()
	else

		NOFLY()

		task.wait()

		sFLY()
	end
end)

UniversalSection2:AddTextbox("Fly Speed", "Fly Speed", 1, function(t)
	flyspeed = t:gsub("%D",""):sub(0,5)
	getRoot(LP.Character).BodyVelocity.velocity = Vector3.new(0, t:gsub("%D",""):sub(0,5), 0)
end)

flinging = false

local flingtbl = {

	Noclipping = nil,
	OldVelocity = nil,

	bv = nil,
}

UniversalSection2:AddToggle("Fling (requiere players collison)", function(t)
	if flinging then

		local rootpart = getRoot(LP.Character)

		if not rootpart then return end
		flingtbl.OldPos = rootpart.CFrame

		local Char = LP.Character:GetChildren()

		if flingtbl.bv ~= nil then
			flingtbl.bv:Destroy()
			flingtbl.bv = nil
		end

		if flingtbl.Noclipping ~= nil then
			flingtbl.Noclipping:Disconnect()
			flingtbl.Noclipping = nil
		end

		for i, v in next, Char do
			if v:IsA("BasePart") then
				v.CanCollide = true
				v.Massless = false
			end
		end

		flingtbl.isRunning = game:GetService("RunService").Stepped:Connect(function()
			if flingtbl.OldPos ~= nil then
				rootpart.CFrame = flingtbl.OldPos
			end
			if flingtbl.OldVelocity ~= nil then
				rootpart.Velocity = flingtbl.OldVelocity
			end
		end)

		task.wait(2)

		rootpart.Anchored = true

		if flingtbl.isRunning ~= nil then
			flingtbl.isRunning:Disconnect()
			flingtbl.isRunning = nil
		end

		rootpart.Anchored = false

		if flingtbl.OldVelocity ~= nil then
			rootpart.Velocity = flingtbl.OldVelocity
		end

		if flingtbl.OldPos ~= nil then
			rootpart.CFrame = flingtbl.OldPos
		end

		rootpart.Anchored = true

		task.wait(1)

		flingtbl.OldVelocity = nil
		flingtbl.OldPos = nil

		flinging = false

		rootpart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootpart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		task.wait(1)

		rootpart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootpart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		rootpart.Anchored = false
	else

		local rootpart = getRoot(LP.Character)

		if not rootpart then return end
		flingtbl.OldVelocity = rootpart.Velocity

		local bv = Instance.new("BodyAngularVelocity")
		flingtbl.bv = bv

		bv.MaxTorque = Vector3.new(1, 1, 1) * math.huge
		bv.P = math.huge

		bv.AngularVelocity = Vector3.new(0, 9e5, 0)
		bv.Parent = rootpart

		local Char = LP.Character:GetChildren()

		for i, v in next, Char do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Massless = true
				v.Velocity = Vector3.new(0, 0, 0)
			end
		end

		flingtbl.Noclipping = game:GetService("RunService").Stepped:Connect(function()
			for i, v in next, Char do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
		end)

		flinging = true
	end
end)

UniversalSection2:AddTextbox("Kill Player", "PlayerName", nil, function(t)

	local target = GetPlayer(t or LP.Name)

	if not target then
		lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", tostring(t).." is not a valid palyer!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
		return
	end

	LP.Character.Humanoid.Name = 1

	local l = LP.Character["1"]:Clone()

	l.Parent = LP.Character
	l.Name = "Humanoid"

	task.wait(.2)

	LP.Character["1"]:Destroy()
	workspace.CurrentCamera.CameraSubject = LP.Character
	LP.Character.Humanoid.DisplayDistanceType = "None"

	LP.Character.Humanoid:UnequipTools()
	local Tool = LP.Backpack:FindFirstChildOfClass("Tool")

	if not Tool then
		lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Tool not found!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
		return
	end

	Tool.Parent = LP.Character
	Tool.Parent = LP.Character.HumanoidRootPart

	firetouchinterest(target.Character.HumanoidRootPart, Tool.Handle, 0)
	firetouchinterest(target.Character.HumanoidRootPart, Tool.Handle, 1)

	pcall(function() LP.Character.HumanoidRootPart.CFrame = CFrame.new(0, workspace.FallenPartsDestroyHeight + 5, 0) end)

	task.wait(.3)

	LP.Character:Remove()
	LP.CharacterAdded:Wait()
end)

InfJump_Enabled = false
UniversalSection2:AddToggle("Inf Jump", function(t)
	InfJump_Enabled = t

	UIS.JumpRequest:connect(function()
		if InfJump_Enabled then
			LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
		end
	end)
end)

NoClip_Enabled = false
UniversalSection2:AddToggle("NoClip", function(t)

	NoClip_Enabled = t

	RS.Stepped:Connect(function()
		for i, v in next, LP.Character:GetChildren() do
			if v:IsA("BasePart") and NoClip_Enabled then
				v.CanCollide = false
			end
		end
	end)
end)

AntiAFK_Enabled = false
UniversalSection2:AddToggle("Anti-AFK", function(t)
	AntiAFK_Enabled = t

	LP.Idled:connect(function()

		if not AntiAFK_Enabled then return end

		local VirtualUser = game:GetService("VirtualUser")

		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

local UniversalSection3 = UniversalPage:AddSection("Camera")

NoclipCamera_Enabled = false
UniversalSection3:AddToggle("NoClip Camera", function(t)

	NoclipCamera_Enabled = t

	local _setconstant = lib:GetCurrentExecutor_function("setconstant")
	local _getconstants = lib:GetCurrentExecutor_function("getconstants")

	if not getgc and not NoclipCamera_Enabled then
		return
	end

	local Popper = LP.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper

	for _, v in pairs(getgc()) do
		if type(v) == 'function' and getfenv(v).script == Popper then
			for i, v1 in pairs(_getconstants(v)) do
				if tonumber(v1) == .25 then
					_setconstant(v, i, 0)
				elseif tonumber(v1) == 0 then
					_setconstant(v, i, .25)
				end
			end
		end
	end
end)

UniversalSection3:AddTextbox("Spectate Player", "Player Name", nil, function(t)
	local PlayerName = GetPlayer(t)
	Camera.CameraSubject = PlayerName.Character:FindFirstChild("Humanoid")
end)

UniversalSection3:AddButton("Stop spectate player", function()
	Camera.CameraSubject = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
end)

local UniversalSection4 = UniversalPage:AddSection("Mouse")

UniversalSection4:AddKeybind("Lock/UnLock Mouse", Enum.KeyCode.Z, function(t)
	lib:LockMouse(t)
end)

ClickTP_Enabled = false
UniversalSection4:AddToggle("Click to TP", function(t)
	ClickTP_Enabled = t
end)

ClickDel_Enabled = false
UniversalSection4:AddToggle("Click to Delete", function(t)
	ClickDel_Enabled = t
end)

local function clicktpFunc()
	pcall(function()
		if LP.Character:FindFirstChildOfClass('Humanoid') and LP.Character:FindFirstChildOfClass('Humanoid').SeatPart then
			LP.Character:FindFirstChildOfClass('Humanoid').Sit = false
			wait(.1)
		end
		getRoot(LP.Character).CFrame = Mouse.Hit + Vector3.new(0,8,0)
	end)
end


Mouse.Button1Down:Connect(function()
	if ClickTP_Enabled then

		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and LP.Character then
			clicktpFunc()
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and LP.Character then
			clicktpFunc()
		end

	elseif ClickDel_Enabled then

		if  UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			pcall(function() Mouse.Target:Destroy() end)
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			pcall(function() Mouse.Target:Destroy() end)
		end

	end
end)

local UniversalSection5 = UniversalPage:AddSection("Anti-Exploits")

Antikick_Enabled = false
UniversalSection5:AddToggle("Client Anti-kick", function(t)

	Antikick_Enabled = t

	if not Antikick_Enabled then
		return
	end

	if not hookmetamethod then 
		return error("Your exploit does not support this command (missing hookmetamethod")
	end

	local oldhmmi
	local oldhmmnc

	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if self == LP and method:lower() == "kick" then
			return error("Expected ':' not '.' calling member function Kick")
		end
		return oldhmmi(self, method)
	end)

	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if self == LP and getnamecallmethod():lower() == "kick" and Antikick_Enabled then
			return
		end
		return oldhmmnc(self, ...)
	end)
end)

AntiTP_Enabled = false
UniversalSection5:AddToggle("Client Anti-Teleport", "Client Anti-Exploits cant teleport you back", false, function(t)

	AntiTP_Enabled = t

	if not AntiTP_Enabled then
		return
	end

	if not hookmetamethod then 
		return error("Your exploit does not support this command (missing hookmetamethod")
	end

	local TeleportService = game:GetService('TeleportService')

	local oldhmmi
	local oldhmmnc

	oldhmmi = hookmetamethod(game, "__index", function(self, method)
		if self == TeleportService then
			if method:lower() == "teleport" then
				return error("Expected ':' not '.' calling member function Kick")
			elseif method == "TeleportToPlaceInstance" then
				return error("Expected ':' not '.' calling member function TeleportToPlaceInstance")
			end
		end
		return oldhmmi(self, method)
	end)

	oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
		if self == TeleportService and getnamecallmethod():lower() == "teleport" or getnamecallmethod() == "TeleportToPlaceInstance" and AntiTP_Enabled then
			return
		end
		return oldhmmnc(self, ...)
	end)
end)

---------------| Character Section |---------------

pcall(function()
	local CharacterSection = CharacterPage:AddSection("Humanoid")

	local OldWalkSpeed = LP.Character:FindFirstChildOfClass("Humanoid").WalkSpeed 
	local OldJumpPower = LP.Character:FindFirstChildOfClass("Humanoid").JumpPower

	CharacterSection:AddSlider("Set WalkSpeed", OldWalkSpeed, 180, OldJumpPower, function(t)
		LP.Character:FindFirstChild("Humanoid").WalkSpeed = t
	end)

	CharacterSection:AddSlider("Set JumpPower", OldJumpPower, 180, OldJumpPower, function(t)
		LP.Character:FindFirstChild("Humanoid").JumpPower = t
	end)

	CharacterSection:AddButton("Reset WalkSpeed & JumpPower", function()
		LP.Character:FindFirstChild("Humanoid").WalkSpeed = OldWalkSpeed
		LP.Character:FindFirstChild("Humanoid").JumpPower = OldJumpPower
	end)

	CharacterSection:AddLabel("More features coming soon..!")
end)

---------------| Scripts Section |---------------

local Generate_SupportedGame_Script = function()

	local TR_NE = function()

		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Lighting = game:GetService("Lighting")

		local ESP2 = loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))()
		ESP2:Toggle(false); ESP2.Players = false; ESP2.Tracers = false; ESP2.Boxes = false; ESP2.Names = false

		ESP2:AddObjectListener(workspace, {

			Name = "RakoofNPC",
			CustomName = "RakeOOF",

			PrimaryPart = function(obj)
				local root = obj:FindFirstChild("HumanoidRootPart")

				while not root do 
					task.wait()
					root = obj:FindFirstChild("HumanoidRootPart")
				end

				return root 
			end, 

			Color = Color3.fromRGB(255, 0, 0),
			IsEnabled = "TheRake"
		})

		for i,v in pairs(game:GetService("Workspace").LocationsBillboardGuis:GetDescendants()) do
			if v:IsA("Part") then 

				local newname = tostring(string.gsub(v.Name, "Part", ""))

				ESP2:Add(v, {

					Name = newname,
					IsEnabled = "Locations",
					Color = Color3.fromRGB(170, 255, 255)
				})
			end 
		end

		ESP2:AddObjectListener(workspace, {
			Name = "FlareGun",
			Color = Color3.fromRGB(255, 85, 0),

			PrimaryPart = function(obj)
				local handle = obj:FindFirstChild("Handle")

				while not handle do 
					task.wait()
					handle = obj:FindFirstChild("Handle")
				end

				return handle 
			end, 

			Validator = function(obj)
				if obj:IsA("Tool") then 
					return true 
				else 
					return false 
				end
			end, 

			CustomName = "FlareGun",
			IsEnabled = "FlareGun"
		})

		ESP2:AddObjectListener(workspace, {

			Name = "SupplyDrop",
			Type = "Model",

			CustomName = "SupplyDrop",

			PrimaryPart = function(obj)
				local root = obj:FindFirstChild("Supply Crate", true)

				while not root do
					task.wait()
					root = obj:FindFirstChild("Supply Crate", true)
				end

				return root
			end, 

			Color = Color3.fromRGB(85, 255, 0),
			IsEnabled = "SupplyDrop"
		})

		local RakeName = "RakoofNPC"
		local AutoKillRake = false

		local ScriptsSection = ScriptsPage:AddSection("Visuals")

		if ReplicatedStorage:FindFirstChild("GameTimer") and ReplicatedStorage:FindFirstChild("PowerTimer") then

			local GameTimerBtn = ScriptsSection:AddButton("GameTimer: "..ReplicatedStorage:FindFirstChild("GameTimer").Value)
			local PowerTimerBtn = ScriptsSection:AddButton("PowerTimer: "..ReplicatedStorage:FindFirstChild("PowerTimer").Value)


			RS.RenderStepped:Connect(function()
				GameTimerBtn:UpdateButton("GameTimer: "..ReplicatedStorage:FindFirstChild("GameTimer").Value)
				PowerTimerBtn:UpdateButton("PowerTimer: "..ReplicatedStorage:FindFirstChild("PowerTimer").Value)
			end)
		end

		if workspace:FindFirstChild(RakeName) and workspace:FindFirstChild(RakeName):FindFirstChildOfClass("Humanoid") then
			local RakeHealthBtn = ScriptsSection:AddButton("Rake Health: "..workspace:FindFirstChild(RakeName):FindFirstChildOfClass("Humanoid").Health)

			RS.RenderStepped:Connect(function()
				for i,v in pairs(workspace:GetChildren()) do
					if string.find(v.Name, RakeName) then
						if v:FindFirstChildOfClass("Humanoid") ~= nil then
							RakeHealthBtn:UpdateButton("Rake Health: "..v:FindFirstChildOfClass("Humanoid").Health)
						end				
					end
				end
			end)
		end

		local CheckHoursValues = function()	
			ReplicatedStorage:FindFirstChild("HourIsHappening").Changed:Connect(function()
				if ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and ReplicatedStorage:FindFirstChild("BeingBloodHour").Value == true then

					return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Hour Detected (BloodHour)!", 10, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

				elseif ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and ReplicatedStorage:FindFirstChild("BeingNightmareHour").Value == true then

					return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Hour Detected (NightmareHour)!", 10, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

				elseif ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and ReplicatedStorage:FindFirstChild("BeingCorruptedHour").Value == true then

					return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Hour Detected (CorruptedHour)!", 10, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

				elseif ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and ReplicatedStorage:FindFirstChild("BeingCheeseHour").Value == true then

					return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Hour Detected (CheeseHour)!", 1, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

				elseif ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and ReplicatedStorage:FindFirstChild("BeingOrangesHour").Value == true then

					return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Hour Detected (OrangesHour)!", 10, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
				end
			end)
		end

		local TimeChanged = false

		local ChangeTime = function()
			if ReplicatedStorage:WaitForChild("Day").Value == false then
				if TimeChanged then

					TimeChanged = false

					Lighting.Ambient = Lighting:GetAttribute("DayAmbient")

					Lighting.Atmosphere.Density = tonumber(Lighting:GetAttribute("DayDensity"))
					Lighting.Brightness = tonumber(Lighting:GetAttribute("DayBrightness"))	
					Lighting.ClockTime = 14

				else

					TimeChanged = true

					Lighting.Ambient = Lighting:GetAttribute("NightAmbient")

					Lighting.Atmosphere.Density = tonumber(Lighting:GetAttribute("NightDensity"))
					Lighting.Brightness = tonumber(Lighting:GetAttribute("NightBrightness"))	
					Lighting.ClockTime = 0

				end
			end
		end

		local lookDown = function()
			Camera.CFrame = CFrame.new(264.744202, 44.9857788, 19.0272675, 0.917633414, -0.391390145, 0.0690128133, 0, 0.173648611, 0.984807611, -0.397428036, -0.903692365, 0.159345)
		end

		ScriptsSection:AddToggle("Enable ESPS", function(t)
			ESP2:Toggle(t)
		end)

		ScriptsSection:AddToggle("Players ESP", function(t)
			ESP2.Players = t
		end)

		ScriptsSection:AddToggle("RakeOOF ESP", function(t)
			ESP2.TheRake = t 
		end)

		ScriptsSection:AddToggle("Locations ESP", function(t)
			ESP2.Locations = t 
		end)

		ScriptsSection:AddToggle("FlareGun ESP", function(t)
			ESP2.FlareGun = t 
		end)

		ScriptsSection:AddToggle("SupplyDrop ESP", function(t)
			ESP2.SupplyDrop = t 
		end)

		local HoursNotify = false
		ScriptsSection:AddToggle("Hours Notification", function(t)

			HoursNotify = t

			if HoursNotify then
				CheckHoursValues()
			end
		end)

			
	
	local ShowJoseDucks = false
	local ShowShips = false
	local ShowCoins = false
	


		local ScriptsSection2 = ScriptsPage:AddSection("Features")

		ScriptsSection2:AddButton("Remove FallDamage", function()
			local Character = LP.Character

			while task.wait() do
				if Character then
					Character.FallDamage:Remove()
				end
			end
		end)

		ScriptsSection2:AddButton("Remove PowerDamage", function()
			workspace.LocationsFolder.PowerStation.PowerDamage:Remove()
		end)

		local CrawlingDisabled = false
		ScriptsSection2:AddToggle("Disable Crawling", function(t)
			CrawlingDisabled = t
		end)

		local InfStamina = false
		local InfStaminaToggle = ScriptsSection2:AddToggle("Infinite Stamina", function(t)
			InfStamina = t
		end)

		ScriptsSection2:AddToggle("Night Full Bright", function(t)
			TimeChanged = t
			ChangeTime()
		end)

		local DisableHourEffects = false
		ScriptsSection2:AddToggle("Disable Some Hour Effects", function(t)

			DisableHourEffects = t

			pcall(function()
				if DisableHourEffects then

					Lighting:FindFirstChild("HourCC").Enabled = false
					LP.PlayerGui:FindFirstChild("HoursGui").Enabled = false

				else

					Lighting:FindFirstChild("HourCC").Enabled = true
					LP.PlayerGui:FindFirstChild("HoursGui").Enabled = true
				end
			end)
		end)

		ScriptsSection2:AddButton("Bring RakOOF", function()
			pcall(function()
				for i,v in pairs(game.Workspace:GetChildren()) do
					if v.Name == RakeName then
						if v:FindFirstChild("HumanoidRootPart") ~= nil and v:FindFirstChild("NPC").Health > 0 and not AutoKillRake then

							v:FindFirstChild("HumanoidRootPart").Anchored = true
							v:FindFirstChild("HumanoidRootPart").CFrame = getRoot(LP.Character).CFrame * CFrame.new(0, 0, -3)
						end
					end
				end
			end)
		end)

		local PowerStationStatus = nil

		local CheckPowerStationStatus = function()
			if ReplicatedStorage:FindFirstChild("PowerTimer").Value <= 0 then

				PowerStationStatus = "Power Station Fixed! wait a little for it to start up!"
				return true

			elseif ReplicatedStorage:FindFirstChild("PowerTimer").Value > 0 then

				PowerStationStatus = "Power Station is already fixed! Current PowerTimer: "..tostring(ReplicatedStorage:FindFirstChild("PowerTimer").Value).."%"
				return false

			elseif ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true then

				PowerStationStatus = "There is a hour in progress, Come back later!"
				return false
			end
		end

		ScriptsSection2:AddButton("Fix Power Station", function()
			if CheckPowerStationStatus() then

				local InteractPart = workspace.LocationsFolder.PowerStation.ControlButtons.Buttons.InteractPart
				local OldPos = getRoot(LP.Character).CFrame

				lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Attempting to fix Power Station", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

				lookDown()

				getRoot(LP.Character).CFrame = InteractPart.CFrame

				task.wait(0.3)

				fireproximityprompt(InteractPart.ProximityPrompt)

				task.wait(0.3)

				getRoot(game.Players.LocalPlayer.Character).CFrame  = OldPos 

				lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", tostring(PowerStationStatus), 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
			else 
				lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", tostring(PowerStationStatus), 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
			end
		end)

		ScriptsSection2:AddButton("Get FlareGun", function()

			if not workspace:FindFirstChild("FlareGun") then
				return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "FlareGun not found", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
			end

			firetouchinterest(getRoot(game.Players.LocalPlayer.Character), workspace.FlareGun.Handle, 0)
		end)

		local ScriptsSection3 = ScriptsPage:AddSection("AutoFarm")

		local AutoFarmRequiredToolList = {"GoldenPan", "Pan", "RedBanHammer", "MiniRedBanHammer", "RedBanHammer", "BigSpoon"}

		local ScrapMetalsAutoFarmTog = nil
		local HoursafeModeTog = nil

		local ScrapMetalsAura = false
		local HoursSafeMode = false

		local CheckAutoFarmRequiredTool = function()

			repeat wait() until LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")

			LP.Character.Humanoid:UnequipTools()

			for _, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
				if table.find(AutoFarmRequiredToolList, v.Name) then
					return v.Name
				end
			end
		end

		local SendAutoFarmNotify = function()
			for i,v in pairs(workspace:GetChildren()) do
				if v.Name == tostring(RakeName) and v:FindFirstChild("HumanoidRootPart") then

					local Tool = CheckAutoFarmRequiredTool()

					local RakeRootPart = v:FindFirstChild("HumanoidRootPart") 
					local RakeHumanoid = v:FindFirstChildOfClass("Humanoid")

					if AutoKillRake == false then

						return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Disabled AFK AutoFarm!, Teleported to your old position", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

					elseif workspace:FindFirstChild("Day").Value == true and RakeHumanoid.Health > 1 then

						lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Oops it looks like it's day try it the next night!, Teleported to your old position", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

					elseif LP.Character:FindFirstChild("Humanoid").Health <= 0 then

						lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "You died, AFK AutoFarm un-initialized", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

					elseif RakeHumanoid.Health <= 0 then

						lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "RakeOOF Killed Succesfully!, Teleported to your old position", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

					elseif Tool == nil then

						local ToolList = ""

						for _, v in pairs(LP.Backpack:GetChildren()) do
							ToolList = ToolList..", "..tostring(v)
						end

						lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Tool Not Found!, Accepted Tools: "..tostring(ToolList), 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)

					elseif LP:GetAttribute("InServerMenuValue") and AutoKillRake then
						lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "AutoFarm Stopped!, Waiting Until Player teleport to the map..", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
					end
				end
			end
		end

		local InitializeAutoFarm = function()

			repeat wait() until LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")

			ReplicatedStorage:WaitForChild("Day").Changed:Connect(function()

				if not ReplicatedStorage:WaitForChild("Day").Value and AutoKillRake then
					for i,v in pairs(workspace:GetChildren()) do
						if v.Name == tostring(RakeName) and v:FindFirstChild("HumanoidRootPart") then

							local Tool = CheckAutoFarmRequiredTool()

							if InfStamina then
								InfStaminaToggle:SetValue(true)
							end

							HoursafeModeTog:SetValue(false)
							HoursSafeMode = false

							ScrapMetalsAutoFarmTog:SetValue(false)
							ScrapMetalsAura = false

							local RakeRootPart = v:FindFirstChild("HumanoidRootPart") 
							local RakeHumanoid = v:FindFirstChildOfClass("Humanoid")

							if Tool and RakeHumanoid.Health > 0 and LP.Character:FindFirstChildOfClass("Humanoid").Health > 0 then

								LP.CameraMode = Enum.CameraMode.LockFirstPerson

								pcall(function()
									repeat
										task.wait()
									until isrbxactive()

									local Viewport = workspace.CurrentCamera.ViewportSize
									mousemoveabs(Viewport.X / 2, Viewport.Y / 2)
								end)

								LP.Character.Humanoid:UnequipTools()

								local OldPos = getRoot(LP.Character).CFrame

								task.wait(1)

								getRoot(LP.Character).CFrame = workspace.RakeCaveParts.RakeBoxPos.CFrame

								RakeRootPart.CFrame = getRoot(LP.Character).CFrame * CFrame.new(0, 0, -2)
								RakeRootPart.Anchored = true

								LP.Character.Humanoid:EquipTool(LP.Backpack:FindFirstChild(Tool))

								repeat task.wait()


									RakeRootPart.CFrame = getRoot(LP.Character).CFrame * CFrame.new(0, 0, -2)
									getRoot(LP.Character).CFrame = RakeRootPart.CFrame * CFrame.new(0, 0, -2)

									RakeRootPart.Anchored = true

									getRoot(LP.Character).CFrame = workspace.RakeCaveParts.RakeBoxPos.CFrame

									pcall(function()
										mouse1click()
									end)

								until RakeHumanoid.Health == 0 or LP.Character:FindFirstChild("Humanoid").Health == 0 or AutoKillRake == false or ReplicatedStorage:FindFirstChild("Day").Value

								LP.CameraMode = Enum.CameraMode.Classic

								LP.Character.Humanoid:UnequipTools()
								getRoot(LP.Character).CFrame = OldPos

								SendAutoFarmNotify()
							end
						end
					end
				end
			end)
		end

		InitializeAutoFarm()

		ScriptsSection3:AddToggle("Survivals AutoFarm [BETA]", function(t)			
			AutoKillRake = t
		end)

		ScrapMetalsAutoFarmTog = ScriptsSection3:AddToggle("ScrapMetals AutoFarm", function(t)	

			pcall(function()
				if AutoKillRake then

					ScrapMetalsAutoFarmTog:SetValue(false)
					ScrapMetalsAura = false

					return
				end
			end)

			ScrapMetalsAura = t
		end)

		HoursafeModeTog = ScriptsSection3:AddToggle("Hours Safe Mode", function(t)

			HoursSafeMode = t

			pcall(function()
				if AutoKillRake then

					HoursafeModeTog:SetValue(false)
					HoursSafeMode = false

					return
				end
			end)

			local OldPos = getRoot(LP.Character).CFrame

			if ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and HoursSafeMode and not AutoKillRake then
				getRoot(LP.Character).CFrame = workspace:FindFirstChild("PlayerStartMenuPart").CFrame	
			end

			ReplicatedStorage:FindFirstChild("HourIsHappening").Changed:Connect(function()
				if ReplicatedStorage:FindFirstChild("HourIsHappening").Value == true and HoursSafeMode and not AutoKillRake then

					getRoot(LP.Character).CFrame = workspace:FindFirstChild("PlayerStartMenuPart").CFrame	

				elseif workspace:FindFirstChild("HourIsHappening").Value == false and not AutoKillRake then

					getRoot(LP.Character).CFrame = OldPos
				end
			end)
		end)

		ScriptsSection3:AddButton("Collect All JoseDucks", function()
			for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.DuckParts:GetDescendants()) do
				if v:IsA("ClickDetector") then 
					fireclickdetector(v)
				end 
			end
		end)

		ScriptsSection3:AddButton("Collect All Ships", function()
			for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.ChipsGiversFolder:GetDescendants()) do
				if v:IsA("ClickDetector") then 
					fireclickdetector(v)
				end 
			end
		end)

		ScriptsSection3:AddButton("Collect All Coins", function()
			local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame

			for _, v in pairs(workspace.StuffGiversFolder.CoinsGiverSpawns:GetDescendants()) do
				if v.Name == "CoinGiverPart" then 

					lookDown()

					getRoot(LP.Character).CFrame = v.CFrame

					task.wait(0.3)

					fireproximityprompt(v:FindFirstChild("ProximityPrompt"))

					task.wait(0.3)
				end 
			end
			getRoot(LP.Character).CFrame = OldPos
		end)

		local ScriptsSection4 = ScriptsPage:AddSection("Teleports")

		local LocationsList = {"Shop", "Destroyed Cabin", "PlayGround", "Unfinished House", "Survival SafeHouse", "Crashed Car", "Power Station", "RakOOF Spawn"}
		local TeleporTO = "Shop"

		ScriptsSection4:AddDropdown("Teleport To Place", LocationsList, tostring(TeleporTO), function(t)
			TeleporTO = tostring(t)
		end)

		ScriptsSection4:AddButton("Teleport to selected location", function()
			print("Teleported to: ".. tostring(TeleporTO) .."!")
		end)

		local ScriptsSection5 = ScriptsPage:AddSection("Misc")

		ScriptsSection5:AddButton("Give Cheese", function()
			LP.PlayerGui.CodeGui.SendTextBoxRE:FireServer("cheese")
			wait(4.50)
			LP.PlayerGui.CodeGui.CodeFrame.Visible = false
		end)

		ScriptsSection5:AddButton("Give BloxyCola", function()
			LP.PlayerGui.CodeGui.SendTextBoxRE:FireServer("code")
			wait(4.50)
			LP.PlayerGui.CodeGui.CodeFrame.Visible = false
		end)

		ScriptsSection5:AddButton("Give Bright Flashlight", function()
			LP.PlayerGui.CodeGui.SendTextBoxRE:FireServer("brightness")
			wait(4.50)
			LP.PlayerGui.CodeGui.CodeFrame.Visible = false
		end)

		ScriptsSection5:AddButton("Give Impostor Suit", function()
			LP.PlayerGui.CodeGui.SendTextBoxRE:FireServer("imposter")
			wait(4.50)
			LP.PlayerGui.CodeGui.CodeFrame.Visible = false
		end)

		ScriptsSection5:AddButton("Show Shop Gui", function()
			firetouchinterest(getRoot(LP.Character),game:GetService("Workspace").LocationsFolder.Shop.EnterShopPart, 0)
		end)

		ScriptsSection5:AddButton("Show Supply Gui", function()
			for i,v in pairs(game.Workspace:GetChildren()) do
				if v:IsA("Model") and v.Name == "SupplyDrop" then
					LP.PlayerGui.SupplyDropGui.RemoteEvent:FireServer()
				end
			end	
		end)

		local ScriptsSection6 = ScriptsPage:AddSection("Config")

		local NametagsToggle = ScriptsSection6:AddToggle("ESP Nametags", function(t)
			ESP2.Names = t
		end)

		ScriptsSection6:AddToggle("ESP Tracers", function(t)
			ESP2.Tracers = t
		end)

		ScriptsSection6:AddToggle("ESP Boxes", function(t)
			ESP2.Boxes = t
		end)

		NametagsToggle:SetValue(true)

		task.spawn(function()
			while task.wait() do
				if DisableHourEffects then
					pcall(function()
						Lighting:FindFirstChild("HourCC").Enabled = false
						LP.PlayerGui:FindFirstChild("HoursGui").Enabled = false
					end)
				end
			end
		end)

		task.spawn(function()
			while task.wait() do
				if ScrapMetalsAura and not AutoKillRake then
					for _, v in pairs(workspace.StuffGiversFolder.ScrapMetals:GetDescendants()) do
						if v.Name == "ProximityPrompt" and v.Parent and v.Enabled then

							v.HoldDuration = 0

							task.wait(0.3)

							getRoot(LP.Character).CFrame = v.Parent.CFrame
							fireproximityprompt(v)

							task.wait(0.3)
						end
					end
				end
			end
		end)

		ReplicatedStorage:FindFirstChild("HourIsHappening").Changed:Connect(function()
			if HoursNotify then
				CheckHoursValues()
			end
		end)

		Lighting.Changed:Connect(function()
			if TimeChanged then
				ChangeTime()
			end
		end)

		pcall(function()

			local mt = getrawmetatable(game)
			make_writeable(mt)

			local old_index = mt.__index

			mt.__index = function(a, b)
				if tostring(a) == "StaminaPercentValue" then
					if tostring(b) == "Value" then
						if InfStamina then
							return 100
						end
					end
				end
				if tostring(a) == "Crawling" then
					if tostring(b) == "Value" then
						if CrawlingDisabled then
							return false
						end
					end
				end
				return old_index(a, b)
			end
		end)
	end

	local Tower_Of_Hell = function()

		local ScriptsSection = ScriptsPage:AddSection("Features")

		ScriptsSection:AddButton("Bypass Anti-Cheat", function()

			for _, v in next, getreg() do
				if type(v) == 'function' then
					if getinfo(v).name == 'kick' then
						if (hookfunction(getinfo(v).func, function(...)end)) then
							warn("succesfully hooked kick")
						else
							warn("failed to hook kick")
						end
					end
				end
			end

			local PlayerScripts = LP.PlayerScripts

			local LocalScript = PlayerScripts.LocalScript
			local LocalScript2 = PlayerScripts.LocalScript2

			for _, v in next, getconnections(LocalScript.Changed) do
				v:Disable()
			end

			for _, v in next, getconnections(LocalScript2.Changed) do
				v:Disable()
			end

			LocalScript:Destroy()
			LocalScript2:Destroy()
		end)

		local TOH_Godmode = false
		ScriptsSection:AddToggle("God Mode (Remove KillParts)",function(t)
			for i,v in pairs(workspace:FindFirstChild("tower"):GetDescendants()) do
				if v:IsA("BoolValue") and v.Name == "kills" then
					v.Parent:Destroy()
				end
			end

			TOH_Godmode = t
		end)

		local InfiniteJump = false
		ScriptsSection:AddToggle("Infinite Jump", function(t)

			InfiniteJump = t

			UIS.JumpRequest:connect(function()
				if InfiniteJump then
					LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
				end
			end)
		end) 

		ScriptsSection:AddButton("Go to the Top", function()
			getRoot(LP.Character).CFrame = workspace:FindFirstChild("tower").sections.finish.FinishGlow.CFrame
		end)

		local TOH_AutoFarm = false
		ScriptsSection:AddToggle("AutoFarm [BETA]", function(t)
			TOH_AutoFarm = t
		end)

		ScriptsSection:AddButton("Get All Items/Tools", function()

			for _, v in pairs(LP.Backpack:GetDescendants()) do
				if v:IsA("Tool") then
					v:Destroy()
				end
			end

			wait() 

			for _, v in pairs(game :GetService("ReplicatedStorage").Gear:GetDescendants()) do
				if v:IsA("Tool") then
					local CloneThings = v:Clone()
					CloneThings.Parent = LP.Backpack
				end
			end
		end)

		task.spawn(function()
			while task.wait(1) do
				for _, v in pairs(workspace:FindFirstChild("tower"):GetDescendants()) do
					if v:IsA("BoolValue") and v.Name == "kills" then
						v.Parent:Destroy()
					end
				end 
			end
		end)

		task.spawn(function()
			while task.wait(1) do
				local player = game.Players.LocalPlayer.Character
				getRoot(LP.Character).CFrame = workspace:FindFirstChild("tower").sections.finish.FinishGlow.CFrame
			end
		end)
	end

	local Natural_Disaster_Survival = function()

		local ScriptsSection = ScriptsPage:AddSection("Features")
		local DisasterWarnings = false

		local CheckForDisaster = function(Character)
			Character.ChildAdded:connect(function(Child)
				if Child.Name == "SurvivalTag" then
					lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | DISASTER DETECTED", tostring(Child.Value), 10, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
				end
			end)
		end

		ScriptsSection:AddToggle("Notify Disaster", function(t)

			DisasterWarnings = t

			if DisasterWarnings then

				local Character = LP.Character
				local Tag = Character:FindFirstChild("SurvivalTag")

				if Tag then
					lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | DISASTER DETECTED", tostring(Tag.Value), 10, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
				end

				CheckForDisaster(Character)

				LP.CharacterAdded:connect(function(Character)
					CheckForDisaster(Character)
				end)
			end
		end)

		ScriptsSection:AddToggle("Open Golden ComPass", function(t)
			LP.PlayerGui.MainGui.MapVotePage.Visible = not LP.PlayerGui.MainGui.MapVotePage.Visible
		end)

		local RemoveFallDamage = false
		ScriptsSection:AddToggle("Remove FallDamage", function(t)
			RemoveFallDamage = t
		end)

		ScriptsSection:AddButton("Interact all", function()
			for i, v in pairs(workspace.Structure:GetDescendants()) do
				if v:IsA("ClickDetector") then
					if fireclickdetector then
						fireclickdetector(v)
					else
						lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Executor not supported!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
					end
				end
			end
		end)

		local ScriptsSection2 = ScriptsPage:AddSection("Game Mods")

		local BalloonClone

		ScriptsSection2:AddButton("Copy Green Balloon",function()
			if LP.Character:FindFirstChild("GreenBalloon") and not LP.Backpack:FindFirstChild("GreenBalloon") then
				return
			end

			while wait() do
				for _, Plr in pairs(game:GetService("Players"):GetPlayers()) do
					for _, v in ipairs(Plr.Character:GetChildren()) do
						if (tostring(v.Name) == "GreenBalloon") then

							BalloonClone = v:Clone()
							BalloonClone.Parent = LP.Backpack

							break
						else
							return lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Green Balloon not Found!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
						end
					end
				end 
			end
		end)

		local RemoveLava = false
		ScriptsSection2:AddToggle("Remove Volcan Lava", function(t)
			RemoveLava = t
		end)

		local RemoveMeteors = false
		ScriptsSection2:AddToggle("Remove Meteors", function(t)	
			RemoveMeteors = t
		end)

		local RemoveVirusParticles = false
		ScriptsSection2:AddToggle("Remove Virus Partticles", function(t)
			RemoveVirusParticles = t
		end)

		local IsalndRocksCollide = false
		ScriptsSection2:AddToggle("Island Rocks Collidable", function(t)
			IsalndRocksCollide = t
		end)

		local ScriptsSection3 = ScriptsPage:AddSection("Teleports")

		ScriptsSection3:AddButton("Teleport To Lobby",function()
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-243, 194, 331)
		end)

		ScriptsSection3:AddButton("Teleport To Map",function()
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-117, 47, 5)
		end)

		task.spawn(function()
			while task.wait() do
				if RemoveFallDamage then
					if LP.Character:FindFirstChild("FallDamageScript") then
						LP.Character:FindFirstChild("FallDamageScript"):Destroy()
					end
				end
			end
		end)

		workspace.Structure.ChildAdded:Connect(function(Child)
			if Child.Name == "Lava" and RemoveLava then
				game:GetService("Debris"):AddItem(Child, 0)
			end
		end)

		task.spawn(function()
			while task.wait() do
				if workspace.Structure:FindFirstChild("MeteorFolder") then
					workspace.Structure.MeteorFolder.ChildAdded:Connect(function(Child)
						if Child.Name == "MeteorTemplate" and RemoveMeteors then
							game:GetService("Debris"):AddItem(Child, 0)
						end
					end)
				end
			end
		end)

		task.spawn(function()
			while task.wait() do
				if workspace.Structure:FindFirstChild("VirusParticles") then
					workspace.Structure.VirusParticles.ChildAdded:Connect(function(Child)
						if Child.Name == "VirusParticle" and RemoveVirusParticles then
							game:GetService("Debris"):AddItem(Child, 0)
						end
					end)
				end
			end
		end)

		task.spawn(function()
			while task.wait() do
				for _, v in pairs(game:GetService("Workspace").Island:GetChildren()) do
					if v.Name == "LowerRocks" and IsalndRocksCollide then
						v.CanCollide = true
					elseif v.Name == "LowerRocks" and not IsalndRocksCollide then
						v.CanCollide = false
					end
				end
			end
		end)
	end

	local Apeirophobia = function()
		print("XD")
	end

	local Super_Bomb_Survival = function()
		print("XD3")
	end

	local Evade = function()
		print("XD4")
	end

	local Forgotten_Memories = function()

		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local WorkspaceUtilities = workspace:FindFirstChild("WorkspaceUtilities")
		local BatteryPositions = WorkspaceUtilities:WaitForChild("BatteryPositions")

		local GameSettings = ReplicatedStorage:FindFirstChild("GameSettings")
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

		local Client = Remotes:FindFirstChild("Client")

		local ScriptsSection1 = ScriptsPage:AddSection("Visuals")

		local AnimatronicsTable = {"Freddy", "Bonnie", "Chica", "Foxy"}

		local ESP2 = loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))()
		ESP2:Toggle(true); ESP2.Names = true; ESP2.Tracers = false; ESP2.Boxes = false;

		pcall(function()
			for _, v in pairs(workspace:GetChildren()) do
				if table.find(AnimatronicsTable, v.Name) then
					ESP2:AddObjectListener(workspace, {

						Name = tostring(v.Name),
						CustomName = tostring(v.Name),

						PrimaryPart = function(obj)
							local root = obj:FindFirstChild("HumanoidRootPart")

							while not root do 
								task.wait()
								root = obj:FindFirstChild("HumanoidRootPart")
							end

							return root 
						end, 

						Color = Color3.fromRGB(255, 0, 0),
						IsEnabled = tostring(v.Name)
					})
				end
			end
		end)

		ScriptsSection1:AddToggle("Entity ESP", function(t)
			pcall(function()
				ESP2.Freddy = t
				ESP2.Bonnie = t
				ESP2.Chica = t 
				ESP2.Foxy = t
				ESP2:Toggle(true)
			end)
		end)

		ScriptsSection1:AddToggle("Tracers", function(t)
			ESP2.Tracers = t
		end)

		ScriptsSection1:AddToggle("Boxes", function(t)
			ESP2.Boxes = t
		end)

		ScriptsSection1:AddToggle("Face Camera", function(t)
			ESP2.FaceCamera = t
		end)

		local ScriptsSection2 = ScriptsPage:AddSection("Features")

		ScriptsSection2:AddButton("Repair Generators", function()
			for _, v in pairs(WorkspaceUtilities:GetChildren()) do
				if v.Name == "Generator" then
					Client:FireServer("Restart Gen", v)
				end
			end
		end)

		ScriptsSection2:AddButton("Repair Oxygen", function()
			Client:FireServer("Restart Ventilation", WorkspaceUtilities.VentsLever)
		end)

		ScriptsSection2:AddButton("Close Curtain", function()
			Client:FireServer("Close Curtain", WorkspaceUtilities.Curtains)
		end)

		ScriptsSection2:AddButton("Collect All Batteries", function()

			for _, v in pairs(BatteryPositions:GetChildren()) do
				if v.Name == "Battery" then
					Client:FireServer("Collect Battery", v)
				end
			end
		end)

		local ScriptsSection3 = ScriptsPage:AddSection("Automatization")

		local AutoRepairGens = false
		ScriptsSection3:AddToggle("Auto Repair generators", function(t)
			AutoRepairGens = t
		end)

		local AutoRepairOxygen = false
		ScriptsSection3:AddToggle("Auto Repair Oxygen", function(t)
			AutoRepairOxygen = t
		end)

		local AutoCloseCurtain = false
		ScriptsSection3:AddToggle("Auto Close Curtain", function(t)
			AutoCloseCurtain = t
		end)

		local NoPower = false
		ScriptsSection3:AddToggle("No Power", function(t)
			NoPower = t
		end)

		local ScriptsSection4 = ScriptsPage:AddSection("Notifications")

		local NotifyPower = false
		ScriptsSection4:AddToggle("Notify Power", function(t)
			NotifyPower = t
		end)

		local NotifyOxygen = false
		ScriptsSection4:AddToggle("Notify Oxygen", function(t)
			NotifyOxygen = t
		end)

		local NofyMarionette = false
		ScriptsSection4:AddToggle("Nofy Marionette", function(t)
			NofyMarionette = t
		end)

		task.spawn(function()
			while task.wait(1) do
				if AutoRepairGens then
					for _, v in pairs(WorkspaceUtilities:GetChildren()) do
						if v.Name == "Generator" then
							Client:FireServer("Restart Gen", v)
						end
					end
				end
			end
		end)

		task.spawn(function()
			while task.wait(1) do
				if AutoRepairOxygen then
					Client:FireServer("Restart Ventilation", WorkspaceUtilities.VentsLever)
				end
			end
		end)

		task.spawn(function()
			while task.wait(1) do
				if AutoCloseCurtain then
					Client:FireServer("Close Curtain", WorkspaceUtilities.Curtains)
				end
			end
		end)

		task.spawn(function()
			while task.wait() do
				if NoPower and GameSettings:FindFirstChild("POWER").Value > 0 then
					Client:FireServer("Blast Door Interact", WorkspaceUtilities.FrontBlastDoor)
					Client:FireServer("Blast Door Interact",  WorkspaceUtilities.RightBlastDoor)
				end
			end
		end)


		task.spawn(function()
			while task.wait(1) do
				if NotifyPower then
					for _, v in pairs(WorkspaceUtilities:GetChildren()) do
						if v.Name == "Generator" and v:FindFirstChild("Properties") then

							local Properties = v:FindFirstChild("Properties")

							if Properties.Shutdown and Properties.Location then
								if Properties.Shutdown.Value and Properties.Location.Value then
									lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", tostring(Properties.Location.Value).." generator has a failure!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
								end
							end
						end
					end
				end
			end
		end)

		task.spawn(function()
			while task.wait(1) do
				if NotifyOxygen and GameSettings:FindFirstChild("OXYGEN").Value < 100 then
					lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "Oxygen is failing!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
				end
			end
		end)
	end

	local Word_Bomb  = function()

local keys = {
			["A"] = 0x41,
			["B"] = 0x42,
			["C"] = 0x43,
			["D"] = 0x44,
			["E"] = 0x45,
			["F"] = 0x46,
			["G"] = 0x47,
			["H"] = 0x48,
			["I"] = 0x49,
			["J"] = 0x4A,
			["K"] = 0x4B,
			["L"] = 0x4C,
			["M"] = 0x4D,
			["N"] = 0x4E,
			["O"] = 0x4F,
			["P"] = 0x50,
			["Q"] = 0x51,
			["R"] = 0x52,
			["S"] = 0x53,
			["T"] = 0x54,
			["U"] = 0x55,
			["V"] = 0x56,
			["W"] = 0x57,
			["X"] = 0x58,
			["Y"] = 0x59,
			["Z"] = 0x5A,
			["-"] = 0xBD,
			["'"] = 0xDE
		}
		local usedWords = {}
		
		local WordList = {
			Normal    = loadstring(game:HttpGet("https://gist.githubusercontent.com/raw/6f3d37a9f5068a0fc2203ac77077ce06/", true))(),
			LongWords = loadstring(game:HttpGet("https://pastebin.com/raw/UuzSb9XV", true))()
		}
		
		local Word = nil
		local Id = nil
		
		local AutoTypeDelayPointer = 0
		local TypeDelayPointer = 0
		
		-- functions --
		local FindLetters = function()
			for _,v in pairs(getgc()) do
				if type(v) == "function" and not is_synapse_function(v) and islclosure(v) and debug.getinfo(v).name == "updateInfoFrame" then
					for __,vv in pairs(debug.getupvalues(v)) do
						if type(vv) == "table" and vv.Prompt ~= nil then
							Word = vv.Prompt
						end
					end
				end
			end
			return Word
		end

		local MyTurn = function()
			for _,v in pairs(getgc()) do
				if type(v) == "function" and not is_synapse_function(v) and islclosure(v) and debug.getinfo(v).name == "updateInfoFrame" then
					for __,vv in pairs(debug.getupvalues(v)) do
						if type(vv) == "table" and vv.PlayerID ~= nil then
							Id = vv.PlayerID
						end
					end
				end
			end
			return Id
		end

		local Used = function(Word)
			for i,v in pairs(usedWords) do
				if v == Word then return true end
			end
			return false
		end

		local FindWord = function(l)
			local word
			for i,v in pairs(WordList[Library.pointers.WordListPointer.current]) do
				if string.find(v, string.lower(l)) and not Used(string.upper(v)) and v ~= nil then
					word = string.upper(v)
				end
			end
			return word
		end

		local TableLength = function(Table)
			local A=0
			for i,v in pairs(Table) do A=A+1 end
			return A
		end

		local TypeAnswer = function()
			local A = false
			if A == false then
				A = true
				local Word = FindWord(FindLetters())
				if Word and Word ~= "nil" then
					for v in string.gmatch(Word,".") do
						keypress(keys[v])
						wait(TypeDelayPointer)
					end
					table.insert(usedWords, 
						Word)
					wait(TypeDelayPointer)
					keypress(0x0D)
					A = false
				end
			end         
		end
		
		local ScriptsSection1 = ScriptsPage:AddSection("Main")
		
		ScriptsSection1:AddButton("TypeAnswer", function()
			
			if MyTurn() == game:GetService("Players").LocalPlayer.UserId then
				TypeAnswer()
			end
			
			for _,v in pairs(MainSection.visibleContent) do
				if v.Size == 13 and string.find(v.Text, "Used Words:") then
					v.Text = "Used Words:"..tostring(TableLength(usedWords))
				end
			end
		end)
		
		ScriptsSection1:AddToggle("AutoType")
		ScriptsSection1:ADdDropdown("WordList", {"Normal","LongWords"}, "Normal")
		
        ScriptsSection1:AddSlider({Name = "Type Delay", min = 0,max = 1,def = 0,decimals = 0.01,Pointer = "TypeDelayPointer"})
        ScriptsSection1:AddSlider({Name = "AutoType Delay",min = 0,max = 8,def = 0,decimals = 0.01,Pointer = "AutoTypeDelayPointer"})
		
		ScriptsSection1:AddButton({Name = "Clear Used Words",callback = function()
			for _,v in pairs(MainSection.visibleContent) do
				if v.Size == 13 and string.find(v.Text,"Used Words:") then
					v.Text = "Used Words:"..0
				end
			end
			usedWords = {}
		end})
		
		ScriptsSection1:AddLabel("Used Words:".."0")
		
		local ScriptsSection2 = ScriptsPage:AddSection("Server")
		
		ScriptsSection2:AddButton("Rejoin", function()
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
		end)
		
		ScriptsSection2:Button("ServerHop", function()
			local s = {}
			for i,v in pairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data) do
				if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= game.JobId then
					s[#s+1] = v.id
				end
			end
			if #s > 0 then
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s[math.random(1, #s)])
			end
			
		end)
		
		ScriptsSection2:Button("JoinLargestServer", function()
			local Amazing = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Kozenomenon/RBX_Pub/main/Misc/Rejoin_Preferred_Server.lua"))
			Amazing({SizeSort="desc",MinPlayers=0,MaxPlayers=0,ExcludeFull=true,ExcludeSame=true,MinFps=55,MaxPing=190,FpsSortWeight=1,PingSortWeight=1,SizeSortWeight=5,PrintVerbose=false,PrintPrefixTime=false,PrintUseConsoleWindow=false})
		end)
		
		if LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI:FindFirstChild("GameContainer") and LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox then
			LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox:GetPropertyChangedSignal("Visible"):Connect(function()
				repeat
					wait(0.1)
					if LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox.Visible == true and Library.pointers.AutoTypePointer.current == true and MyTurn() == game:GetService("Players").LocalPlayer.UserId then
						wait(AutoTypeDelayPointer)
						local a = TypeAnswer() 
						for _,v in pairs(MainSection.visibleContent) do
							if v.Size == 13 and string.find(v.Text,"Used Words:") then
								v.Text = "Used Words:"..tostring(TableLength(usedWords))
							end
						end
					end
					wait(1)
				until LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox.Visible == false
			end)
		end
		
		LP.PlayerGui.GameUI.DescendantAdded:Connect(function(Child)
			if Child.Name == "Typebox" then
				LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox:GetPropertyChangedSignal("Visible"):Connect(function()
					wait(AutoTypeDelayPointer)
					if LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox.Visible == true and Library.pointers.AutoTypePointer.current == true and MyTurn() == game:GetService("Players").LocalPlayer.UserId then
						repeat
							TypeAnswer()
							for _,v in pairs(MainSection.visibleContent) do
								if v.Size == 13 and string.find(v.Text,"Used Words:") then
									v.Text = "Used Words:"..tostring(TableLength(usedWords))
								end
							end
							wait(1)
						until LP.PlayerGui.GameUI.Container.GameSpace.DefaultUI.GameContainer.DesktopContainer.Typebar.Typebox.Visible == false
					end
				end)
			end
		end)
	end

	if game.PlaceId == 6053107323 then

		return TR_NE()

	elseif game.PlaceId == 1962086868 then

		return Tower_Of_Hell()

	elseif game.PlaceId == 189707 then

		return Natural_Disaster_Survival()

	elseif game.PlaceId == 10277607801 then

		return Apeirophobia()

	elseif game.PlaceId == 164051105 then

		return Super_Bomb_Survival()

	elseif game.PlaceId == 9872472334 then

		return Evade()

	elseif game.GameId == 3240343305 then

		return Forgotten_Memories()

	elseif game.PlaceId == 2653064683 then

		return Word_Bomb()

	elseif game.PlaceId == 8482713490 then

		local ScriptsSection1 = ScriptsPage:AddSection("Error")
		ScriptsSection1:AddLabel("Join to the Main Game and Restart the Script")

	else

		local ScriptsSection1 = ScriptsPage:AddSection("Error")
		ScriptsSection1:AddLabel("Game not Supported or UI is in RobloxStudio Mode")
	end
end

Generate_SupportedGame_Script()

---------------| Misc Section |---------------

local MiscSection = MiscPage:AddSection("Misc")
local toClipboard = lib:GetCurrentExecutor_function("clipBoard")

MiscSection:AddButton("Kill Roblox Process", function()
	game:Shutdown()
end)

MiscSection:AddButton("Kill " .. tostring(_G.LocalLibrary_Data.Name) .. " UI Process", function()
	lib:DestroyUI()
end)

MiscSection:AddButton("Game JobId: "..tostring(game.JobId), function()
	if toClipboard then
		toClipboard(tostring(game.JobId))
		--library:CoreNotification('Game JobId', 'Copied to clipboard!\n'..tostring(game.JobId))
	else
		--library:CoreNotification('Game JobId', tostring(game.JobId))
	end
end)

MiscSection:AddTextbox("Join to Server", "Enter JobId", nil, function(t)
	game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, t, LP)
end)

---------------| Credits Section |---------------

local CreditsSection = CreditsPage:AddSection("Credits")
local toClipboard = lib:GetCurrentExecutor_function("clipBoard")

CreditsSection:AddButton("! $Icey - Owner (! $Icey#2239)", function()
	if toClipboard then
		toClipboard('! $Icey#2239')
		--library:CoreNotification('Discord DevTag', 'Copied to clipboard!\n! $Icey#2239')
	else
		--library:CoreNotification('Discord DevTag', '! $Icey#2239')
	end
end)

CreditsSection:AddButton("0nlyyAlxn - Co-Owner (0nlyyAlxn#5429)", function()
	if toClipboard then
		toClipboard('0nlyyAlxn#5429')
		--library:CoreNotification('Discord DevTag', 'Copied to clipboard!\n0nlyyAlxn#5429')
	else
		--library:CoreNotification('Discord DevTag', '0nlyyAlxn#5429')
	end
end)

CreditsSection:AddButton("VxlennXx - Developer (Vxlenn♡♡♡#3628)", function()
	if toClipboard then
		toClipboard('Vxlenn♡♡♡#3628')
		--library:CoreNotification('Discord DevTag', 'Copied to clipboard!\nVxlenn♡♡♡#3628')
	else
		--library:CoreNotification('Discord DevTag', 'Vxlenn♡♡♡#3628')
	end
end)

CreditsSection:AddButton("JeyLex - BETA TESTER (A L E - RM#6989)", function()
	if toClipboard then
		toClipboard('A L E - RM#6989')
		library:CoreNotification('Discord DevTag', 'Copied to clipboard!\nA L E - RM#6989')
	else
		library:CoreNotification('Discord DevTag', 'A L E - RM#6989')
	end
end)

CreditsSection:AddButton("Offcial Server: Azure Ware", function()
	if toClipboard then
		toClipboard('https://discord.com/invite/24kYCDh6wd')
		library:CoreNotification('Discord Invite', 'Copied to clipboard!\ndiscord.gg/24kYCDh6wd')
	else
		library:CoreNotification('Discord Invite', 'discord.gg/24kYCDh6wd')
	end

	local http_request = lib:GetCurrentExecutor_function("http_request")

	if http_request then
		http_request({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HTTPS:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HTTPS:GenerateGUID(false),
				args = {code = '24kYCDh6wd'}
			})
		})
	end
end)
---------------| TEST Section |---------------

if RS:IsStudio() then
	local ExperimentalTab = Main_UI:NewPage("Experimental_Tab", 7072707647)

	local Test_Section1 = ExperimentalTab:AddSection("Testing")
	local Test_Section2 = ExperimentalTab:AddSection("Others")

	local Test_Section3 = ExperimentalTab:AddSection("Flag System")

	Test_Section1:AddLabel("This is a TextLabel")

	Test_Section1:AddButton("Kill all", function()
		print("Killed all players successfully!")
	end)

	Test_Section1:AddToggle("AutoFarm Coins", function(t)
		print("Toggle Value: "..tostring(t))
	end)

	Test_Section1:AddTextbox("GunPower", "GunPower", 0, function(t)
		print("Textbox Value: "..tostring(t))
	end)

	Test_Section1:AddDropdown("Aim Part", {"Head","Root","Torso"}, "Torso", function(t)
		print("Dropdown Value: "..tostring(t))
	end)


	Test_Section1:AddSlider("Aim Range", 10, 180, 25, function(t)
		print("Slider Value: "..tostring(t))
	end)

	Test_Section1:AddKeybind("Kill Bind", Enum.KeyCode.Q, function(t)
		print("Killed a random person!", "Keybind Value: "..tostring(t))
	end)

	Test_Section1:AddKeybind("Toggle UI", _G.LocalLibrary_Data.CloseBind, function(t)
		_G.LocalLibrary_Data.CloseBind = t
	end)


	Test_Section2:AddButton("Test Notify", function()
		lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", "This is a test notification!", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
	end)

	Test_Section2:AddButton("Remove Items", function()
		warn("WORK IN PROGRESS!")
	end)

	Test_Section2:AddTextbox("New Section Text", "SectionText", "Testing", function(t)
		warn("WORK IN PROGRESS!")
	end)


	Test_Section3:AddButton("PRINT CURRENT FLAGS", function()
		for i, v in pairs(lib.flags) do
			print(i, v)
		end
	end)

	Test_Section3:AddButton("PRINT CURRENT ITEMS", function()
		for i, v in pairs(lib.Items) do
			print(i, v)
		end
	end)
end


local s, e = pcall(function()
	if not RS:IsStudio() then
		local ConfigPage = lib2:NewPage("Configuration", 8992030918, nil)
		ConfigPage:CreateConfigSystem()
	end
end)

if not succes then
	local ConfigPage = lib2:NewPage("Configuration", 8992030918, nil)
	ConfigPage:CreateConfigSystem()
end


lib:Notify(tostring(_G.LocalLibrary_Data.Name).." | NOTIFICATION", tostring(_G.LocalLibrary_Data.Name).." loaded in: " .. tick() - t .. "s (seconds)", 5, "default", _G.LocalLibrary_Data.AccentColor, nil, nil)
return lib
