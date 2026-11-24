local Players = ref(game:GetService("Players"))
local UIS = ref(game:GetService("UserInputService"))
local player = Players.LocalPlayer

----------------------------------------------------------------- theme (Win11 light)
local T = {
	window   = Color3.fromRGB(243, 243, 243),
	titlebar = Color3.fromRGB(251, 251, 251),
	toolbar  = Color3.fromRGB(249, 249, 249),
	sidebar  = Color3.fromRGB(240, 240, 240),
	content  = Color3.fromRGB(255, 255, 255),
	border   = Color3.fromRGB(225, 225, 225),
	accent   = Color3.fromRGB(0, 103, 192),
	accentBg = Color3.fromRGB(204, 232, 255),
	accentHv = Color3.fromRGB(229, 243, 255),
	hover    = Color3.fromRGB(240, 240, 240),
	text     = Color3.fromRGB(32, 32, 32),
	textDim  = Color3.fromRGB(110, 110, 110),
	textOff  = Color3.fromRGB(170, 170, 170),
	folder   = Color3.fromRGB(255, 196, 61),
	folderDk = Color3.fromRGB(235, 170, 40),
	file     = Color3.fromRGB(240, 240, 240),
	fileEdge = Color3.fromRGB(120, 160, 210),
	danger   = Color3.fromRGB(196, 43, 28),
	menu     = Color3.fromRGB(249, 249, 249),
}
local FONT, FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium
local BAD_CHARS = '[\\/:%*%?"<>|]'

----------------------------------------------------------------- path helpers
local function baseName(p)
	p = tostring(p):gsub("[/\\]+$", "")
	return p:match("([^/\\]+)$") or p
end
local function join(folder, name)
	if folder == "" then return name end
	return (folder:gsub("/+$", "")) .. "/" .. name
end
local function parentOf(p)
	p = tostring(p):gsub("[/\\]+$", "")
	return p:match("^(.*)[/\\][^/\\]+$") or ""
end
local function splitExt(name)
	local stem, ext = name:match("^(.+)(%.[^%.]+)$")
	if stem then return stem, ext end
	return name, ""
end

----------------------------------------------------------------- filesystem (safe wrappers)
local FS = {}
function FS.list(path)
	local ok, res = pcall(listfiles, path)
	if ok and type(res) == "table" then return res end
	return {}
end
function FS.isFolder(p) local ok, r = pcall(isfolder, p) return ok and r == true end
function FS.isFile(p)   local ok, r = pcall(isfile, p)   return ok and r == true end
function FS.exists(p) return FS.isFile(p) or FS.isFolder(p) end
function FS.read(p)     local ok, r = pcall(readfile, p) if ok then return r end return nil, tostring(r) end
function FS.write(p, s) local ok, r = pcall(writefile, p, s) if ok then return true end return false, tostring(r) end
function FS.mkdir(p)    local ok, r = pcall(makefolder, p) if ok then return true end return false, tostring(r) end
function FS.children(folder)
	local out = {}
	for _, raw in FS.list(folder) do
		local nm = baseName(raw)
		if nm ~= "" and nm ~= ".folder" then table.insert(out, join(folder, nm)) end
	end
	return out
end
function FS.remove(p)
	if FS.isFolder(p) then
		for _, child in FS.children(p) do
			local ok, err = FS.remove(child)
			if not ok then return false, err end
		end
		local ok, err = pcall(delfolder, p)
		if not ok then return false, tostring(err) end
		return true
	end
	local ok, err = pcall(delfile, p)
	if not ok then return false, tostring(err) end
	return true
end
function FS.copy(src, dst)
	if FS.isFolder(src) then
		local ok, err = FS.mkdir(dst)
		if not ok then return false, err end
		for _, child in FS.children(src) do
			local ok2, err2 = FS.copy(child, join(dst, baseName(child)))
			if not ok2 then return false, err2 end
		end
		return true
	end
	local data, err = FS.read(src)
	if data == nil then return false, err end
	return FS.write(dst, data)
end
function FS.move(src, dst)
	local ok, err = FS.copy(src, dst)
	if not ok then return false, err end
	return FS.remove(src)
end
function FS.uniqueName(folder, name, copySuffix)
	if not FS.exists(join(folder, name)) then return name end
	local stem, ext = splitExt(name)
	if FS.isFolder(join(folder, name)) then stem, ext = name, "" end
	local base = copySuffix and (stem .. " - Copy") or stem
	if copySuffix and not FS.exists(join(folder, base .. ext)) then return base .. ext end
	local n = 2
	while FS.exists(join(folder, ("%s (%d)%s"):format(base, n, ext))) do n += 1 end
	return ("%s (%d)%s"):format(base, n, ext)
end

----------------------------------------------------------------- ui helpers
local function corner(inst, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 6) c.Parent = inst return c end
local function stroke(inst, col, th) local s = Instance.new("UIStroke") s.Color = col or T.border s.Thickness = th or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = inst return s end
local function pad(inst, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0) p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingTop = UDim.new(0, t or 0) p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = inst return p
end
local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do i[k] = v end
	if parent then i.Parent = parent end
	return i
end
local function ctrlDown()
	return UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
end
local function shiftDown()
	return UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
end
local function fmtBytes(n)
	if n < 1024 then return n .. " bytes" end
	if n < 1024 * 1024 then return ("%.1f KB"):format(n / 1024) end
	return ("%.2f MB"):format(n / 1024 / 1024)
end

----------------------------------------------------------------- root gui
local gui = new("ScreenGui", { Name = "kAPI_FileExplorer", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true })
gui.Parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")

local window = new("Frame", {
	Size = UDim2.fromOffset(900, 580), Position = UDim2.new(0.5, -450, 0.5, -290),
	BackgroundColor3 = T.window, BorderSizePixel = 0, Active = true,
}, gui)
corner(window, 8) stroke(window, Color3.fromRGB(200, 200, 200), 1)

local function mouseInWindow()
	local m = UIS:GetMouseLocation()
	local p, s = window.AbsolutePosition, window.AbsoluteSize
	return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end
local function mouseLocal()
	local m = UIS:GetMouseLocation()
	return m.X - window.AbsolutePosition.X, m.Y - window.AbsolutePosition.Y
end

----------------------------------------------------------------- state
local state = {
	current = "", history = {}, idx = 0,
	records = {},          -- ordered list of row records for the current folder
	selected = {},         -- [path] = true
	anchor = nil,          -- index for shift-select
	clipboard = nil,       -- { mode = "copy"|"cut", paths = {...} }
	focused = true,        -- keyboard shortcuts only act when the explorer was last clicked
	busy = false,
	modalCount = 0,
	suppressSearch = false,
}
local render, setStatus, refreshVisuals, startRename, confirmDelete, openEditor, showProperties, openPreview, mediaKind
local closeMenu

----------------------------------------------------------------- title bar
local titlebar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.titlebar, BorderSizePixel = 0 }, window)
corner(titlebar, 8)
new("Frame", { Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = T.titlebar, BorderSizePixel = 0 }, titlebar)
local titleText = new("TextLabel", {
	Size = UDim2.new(1, -160, 1, 0), Position = UDim2.fromOffset(16, 0),
	BackgroundTransparency = 1, Font = FONT_B, Text = "File Explorer", TextColor3 = T.text,
	TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, titlebar)

local function titleButton(txt, xoff, hoverCol)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(46, 40), Position = UDim2.new(1, xoff, 0, 0),
		BackgroundTransparency = 1, BackgroundColor3 = T.hover, Text = txt, Font = FONT, TextSize = 14, TextColor3 = T.text, AutoButtonColor = false,
	}, titlebar)
	b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 b.BackgroundColor3 = hoverCol or T.hover end)
	b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
	return b
end
local minBtn = titleButton("—", -138)
local maxBtn = titleButton("☐", -92)
local closeBtn = titleButton("✕", -46, T.danger)
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.new(1, 1, 1) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = T.text end)

----------------------------------------------------------------- toolbar row 1: nav + address + search
local toolbar = new("Frame", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 40), BackgroundColor3 = T.toolbar, BorderSizePixel = 0 }, window)

local function navButton(parent, glyph, x, y, w, cb, tip)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(w or 32, 32), Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = glyph, Font = FONT, TextSize = 14, TextColor3 = T.text, AutoButtonColor = false,
	}, parent)
	corner(b, 5)
	b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
	b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
	b.MouseButton1Click:Connect(cb)
	return b
end

local backBtn = navButton(toolbar, "←", 8, 6, 32, function()
	if state.idx > 1 then state.idx -= 1 render(state.history[state.idx], true) end
end)
local fwdBtn = navButton(toolbar, "→", 42, 6, 32, function()
	if state.idx < #state.history then state.idx += 1 render(state.history[state.idx], true) end
end)
navButton(toolbar, "↑", 76, 6, 32, function() if state.current ~= "" then render(parentOf(state.current)) end end)
navButton(toolbar, "⟳", 110, 6, 32, function() render(state.current, true, true) end)

local addrFrame = new("Frame", { Size = UDim2.new(1, -390, 0, 32), Position = UDim2.fromOffset(150, 6), BackgroundColor3 = T.content, BorderSizePixel = 0 }, toolbar)
corner(addrFrame, 5) stroke(addrFrame, T.border, 1)
local addrBox = new("TextBox", {
	Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
	Font = FONT, Text = "", PlaceholderText = "Path", TextColor3 = T.text, TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, addrFrame)
addrBox.FocusLost:Connect(function(enter)
	if not enter then
		addrBox.Text = state.current == "" and "Workspace" or state.current
		return
	end
	local p = addrBox.Text
	if p == "Workspace" or p == "workspace" then p = "" end
	p = p:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "")
	if p == "" or FS.isFolder(p) then
		render(p)
	elseif FS.isFile(p) then
		if mediaKind(baseName(p)) then openPreview(p) else openEditor(p) end
		addrBox.Text = state.current == "" and "Workspace" or state.current
	else
		setStatus("Can't find '" .. p .. "'. Check the spelling and try again.", true)
		addrBox.Text = state.current == "" and "Workspace" or state.current
	end
end)

local searchFrame = new("Frame", { Size = UDim2.fromOffset(220, 32), Position = UDim2.new(1, -230, 0, 6), BackgroundColor3 = T.content, BorderSizePixel = 0 }, toolbar)
corner(searchFrame, 5) stroke(searchFrame, T.border, 1)
local searchBox = new("TextBox", {
	Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
	Font = FONT, Text = "", PlaceholderText = "Search this folder", TextColor3 = T.text, TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, searchFrame)

----------------------------------------------------------------- toolbar row 2: command bar
local cmdbar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 84), BackgroundColor3 = T.toolbar, BorderSizePixel = 0 }, window)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, cmdbar)
local cmdButtons = {}
local function cmdButton(label, x, w, cb)
	local b = navButton(cmdbar, label, x, 4, w, cb)
	b.TextSize = 12
	cmdButtons[label] = b
	return b
end

----------------------------------------------------------------- body: sidebar + content
local BODY_TOP = 124
local body = new("Frame", { Size = UDim2.new(1, 0, 1, -BODY_TOP - 26), Position = UDim2.fromOffset(0, BODY_TOP), BackgroundTransparency = 1 }, window)

local sidebar = new("Frame", { Size = UDim2.new(0, 190, 1, 0), BackgroundColor3 = T.sidebar, BorderSizePixel = 0 }, body)
new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.border, BorderSizePixel = 0 }, sidebar)
local sideScroll = new("ScrollingFrame", {
	Size = UDim2.new(1, -1, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, sidebar)
pad(sideScroll, 8, 8, 10, 8)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, sideScroll)

local sideButtons = {}
local function sideItem(label, path, order, indent)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.hover, BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, LayoutOrder = order,
	}, sideScroll)
	corner(b, 5)
	local ic = new("Frame", { Size = UDim2.fromOffset(16, 12), Position = UDim2.fromOffset(8 + (indent or 0), 8), BackgroundColor3 = T.folder, BorderSizePixel = 0 }, b)
	corner(ic, 2)
	new("TextLabel", {
		Size = UDim2.new(1, -34 - (indent or 0), 1, 0), Position = UDim2.fromOffset(30 + (indent or 0), 0), BackgroundTransparency = 1,
		Text = label, Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, b)
	b.MouseEnter:Connect(function() if state.current ~= path then b.BackgroundTransparency = 0 b.BackgroundColor3 = T.hover end end)
	b.MouseLeave:Connect(function() if state.current ~= path then b.BackgroundTransparency = 1 end end)
	b.MouseButton1Click:Connect(function() render(path) end)
	sideButtons[path] = b
	return b
end
local function rebuildSidebar()
	for _, c in sideScroll:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
	sideButtons = {}
	new("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Quick access", Font = FONT_B, TextSize = 11, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 }, sideScroll)
	sideItem("Workspace", "", 1, 0)
	local folders = {}
	for _, p in FS.children("") do
		if FS.isFolder(p) then table.insert(folders, p) end
	end
	table.sort(folders, function(a, b) return a:lower() < b:lower() end)
	for i, p in folders do sideItem(baseName(p), p, 1 + i, 14) end
end
local function highlightSidebar()
	for path, b in sideButtons do
		if path == state.current then b.BackgroundTransparency = 0 b.BackgroundColor3 = T.accentBg else b.BackgroundTransparency = 1 end
	end
end

-- content area
local contentWrap = new("Frame", { Size = UDim2.new(1, -190, 1, 0), Position = UDim2.fromOffset(190, 0), BackgroundColor3 = T.content, BorderSizePixel = 0 }, body)
local header = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.content, BorderSizePixel = 0 }, contentWrap)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, header)
new("TextLabel", { Size = UDim2.new(1, -170, 1, 0), Position = UDim2.fromOffset(44, 0), BackgroundTransparency = 1, Text = "Name", Font = FONT_B, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left }, header)
new("TextLabel", { Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -130, 0, 0), BackgroundTransparency = 1, Text = "Type", Font = FONT_B, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left }, header)

local scroll = new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Active = true,
}, contentWrap)
new("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
pad(scroll, 4, 4, 4, 4)

----------------------------------------------------------------- status bar
local status = new("Frame", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 1, -26), BackgroundColor3 = T.titlebar, BorderSizePixel = 0 }, window)
corner(status, 8)
new("Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = T.titlebar, BorderSizePixel = 0 }, status)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, status)
local statusLabel = new("TextLabel", {
	Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1,
	Text = "", Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left,
}, status)
local statusMsgToken = 0
local statusMsgActive = false
local function baseStatus()
	local n, sel = #state.records, 0
	for _ in state.selected do sel += 1 end
	local s = ("%d item%s"):format(n, n == 1 and "" or "s")
	if sel > 0 then s ..= ("   |   %d item%s selected"):format(sel, sel == 1 and "" or "s") end
	return s
end
function setStatus(msg, isError)
	statusMsgToken += 1
	local token = statusMsgToken
	statusLabel.TextColor3 = isError and T.danger or T.textDim
	statusLabel.Text = msg or baseStatus()
	statusMsgActive = msg ~= nil
	if msg then
		task.delay(4, function()
			if statusMsgToken == token then statusMsgActive = false statusLabel.TextColor3 = T.textDim statusLabel.Text = baseStatus() end
		end)
	end
end

----------------------------------------------------------------- icons (drawn, no assets)
local function folderIcon(parent)
	local f = new("Frame", { Size = UDim2.fromOffset(22, 17), Position = UDim2.fromOffset(12, 9), BackgroundColor3 = T.folder, BorderSizePixel = 0 }, parent)
	corner(f, 3)
	new("Frame", { Size = UDim2.fromOffset(10, 5), Position = UDim2.fromOffset(0, -3), BackgroundColor3 = T.folderDk, BorderSizePixel = 0 }, f)
	new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = T.folderDk, BackgroundTransparency = 0.4, BorderSizePixel = 0 }, f)
	return f
end
local function fileIcon(parent, ext)
	local f = new("Frame", { Size = UDim2.fromOffset(17, 21), Position = UDim2.fromOffset(14, 7), BackgroundColor3 = T.file, BorderSizePixel = 0 }, parent)
	corner(f, 3) stroke(f, T.fileEdge, 1)
	new("Frame", { Size = UDim2.new(1, 0, 0, 7), Position = UDim2.new(0, 0, 1, -7), BackgroundColor3 = T.fileEdge, BorderSizePixel = 0 }, f)
	new("TextLabel", { Size = UDim2.new(1, 0, 0, 7), Position = UDim2.new(0, 0, 1, -7), BackgroundTransparency = 1, Text = (ext or ""):upper():sub(1, 3), Font = FONT_B, TextSize = 6, TextColor3 = Color3.new(1, 1, 1) }, f)
	return f
end
local function typeName(name, isDir)
	if isDir then return "File folder" end
	local _, ext = splitExt(name)
	ext = ext:sub(2)
	if ext == "" then return "File" end
	local known = { gif = "GIF Image", ttf = "TrueType Font", otf = "OpenType Font", obj = "3D Object", mov = "MOV Video", avi = "AVI Video", txt = "Text Document", lua = "Lua Source File", luau = "Luau Source File", json = "JSON File", md = "Markdown File", png = "PNG Image", jpg = "JPEG Image", jpeg = "JPEG Image", mp3 = "MP3 Audio", ogg = "OGG Audio", wav = "WAV Audio", mp4 = "MP4 Video", webm = "WEBM Video", rbxm = "Roblox Model", rbxmx = "Roblox Model", html = "HTML Document", css = "CSS File", js = "JavaScript File", iy = "IY Settings" }
	return known[ext:lower()] or (ext:upper() .. " File")
end
local TEXT_EXT = { txt = true, lua = true, luau = true, json = true, md = true, html = true, css = true, js = true, iy = true, cfg = true, ini = true, log = true, xml = true, csv = true, yml = true, yaml = true, toml = true }
local MEDIA = {
	png = "image", gif = "image", jpg = "image", jpeg = "image",
	mp3 = "audio", wav = "audio", ogg = "audio",
	mp4 = "video", m4v = "video", webm = "video", mov = "video", mkv = "video", avi = "video",
	ttf = "font", otf = "font",
	obj = "model",
}
function mediaKind(name)
	local _, ext = splitExt(name)
	return MEDIA[ext:sub(2):lower()]
end
local function isTextFile(name)
	local _, ext = splitExt(name)
	ext = ext:sub(2):lower()
	return ext == "" or TEXT_EXT[ext] == true
end

----------------------------------------------------------------- modal helpers
local function modalShell(w, h, titleStr)
	state.modalCount += 1
	local shade = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 50, Text = "", AutoButtonColor = false }, window)
	corner(shade, 8)
	local box = new("Frame", { Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2), BackgroundColor3 = T.content, BorderSizePixel = 0, ZIndex = 51, Active = true }, shade)
	corner(box, 8) stroke(box, Color3.fromRGB(200, 200, 200), 1)
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.titlebar, BorderSizePixel = 0, ZIndex = 52 }, box)
	corner(bar, 8)
	new("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = T.titlebar, BorderSizePixel = 0, ZIndex = 52 }, bar)
	local title = new("TextLabel", { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = titleStr, Font = FONT_B, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53, TextTruncate = Enum.TextTruncate.AtEnd }, bar)
	local x = new("TextButton", { Size = UDim2.fromOffset(46, 38), Position = UDim2.new(1, -46, 0, 0), BackgroundColor3 = T.danger, BackgroundTransparency = 1, Text = "✕", Font = FONT, TextSize = 14, TextColor3 = T.text, ZIndex = 53, AutoButtonColor = false }, bar)
	corner(x, 8)
	x.MouseEnter:Connect(function() x.BackgroundTransparency = 0 x.TextColor3 = Color3.new(1, 1, 1) end)
	x.MouseLeave:Connect(function() x.BackgroundTransparency = 1 x.TextColor3 = T.text end)
	local closed = false
	local function close()
		if closed then return end
		closed = true
		state.modalCount -= 1
		shade:Destroy()
	end
	return shade, box, close, x, title
end
local function dialogButton(parent, label, xFromRight, primary, cb, z)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(96, 32), Position = UDim2.new(1, xFromRight, 1, -44),
		BackgroundColor3 = primary and T.accent or T.toolbar, Text = label, Font = FONT, TextSize = 13,
		TextColor3 = primary and Color3.new(1, 1, 1) or T.text, AutoButtonColor = true, ZIndex = z or 53,
	}, parent)
	corner(b, 5)
	if not primary then stroke(b, T.border, 1) end
	b.MouseButton1Click:Connect(cb)
	return b
end

----------------------------------------------------------------- context menu
local menuFrame
function closeMenu()
	if menuFrame then menuFrame:Destroy() menuFrame = nil end
end
local function openMenu(items)
	closeMenu()
	local x, y = mouseLocal()
	local h = 8
	for _, it in items do h += (it == "-" and 9 or 30) end
	local w = 230
	if x + w > window.AbsoluteSize.X then x -= w end
	if y + h > window.AbsoluteSize.Y then y = math.max(0, y - h) end
	menuFrame = new("Frame", { Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y), BackgroundColor3 = T.menu, BorderSizePixel = 0, ZIndex = 100, Active = true }, window)
	corner(menuFrame, 8) stroke(menuFrame, Color3.fromRGB(205, 205, 205), 1)
	pad(menuFrame, 4, 4, 4, 4)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, menuFrame)
	for i, it in items do
		if it == "-" then
			local sep = new("Frame", { Size = UDim2.new(1, 0, 0, 9), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 101 }, menuFrame)
			new("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(8, 4), BackgroundColor3 = T.border, BorderSizePixel = 0, ZIndex = 101 }, sep)
		else
			local enabled = it.enabled ~= false
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i, ZIndex = 101 }, menuFrame)
			corner(b, 5)
			new("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = it.label, Font = it.bold and FONT_B or FONT, TextSize = 13, TextColor3 = enabled and T.text or T.textOff, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102 }, b)
			if it.key then
				new("TextLabel", { Size = UDim2.fromOffset(90, 30), Position = UDim2.new(1, -98, 0, 0), BackgroundTransparency = 1, Text = it.key, Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 102 }, b)
			end
			if enabled then
				b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
				b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
				b.MouseButton1Click:Connect(function()
					closeMenu()
					it.cb()
				end)
			end
		end
	end
end

----------------------------------------------------------------- selection
local function selectedPaths()
	local out = {}
	for _, rec in state.records do if state.selected[rec.path] then table.insert(out, rec.path) end end
	return out
end
local function recordFor(path)
	for i, rec in state.records do if rec.path == path then return rec, i end end
end
local function isCut(path)
	local cb = state.clipboard
	if not cb or cb.mode ~= "cut" then return false end
	for _, p in cb.paths do if p == path then return true end end
	return false
end
function refreshVisuals()
	for _, rec in state.records do
		local sel = state.selected[rec.path]
		if sel then
			rec.row.BackgroundTransparency = 0
			rec.row.BackgroundColor3 = T.accentBg
		elseif rec.hover then
			rec.row.BackgroundTransparency = 0
			rec.row.BackgroundColor3 = T.accentHv
		else
			rec.row.BackgroundTransparency = 1
		end
		local cut = isCut(rec.path)
		rec.nameLabel.TextTransparency = cut and 0.5 or 0
		rec.icon.BackgroundTransparency = cut and 0.5 or 0
	end
	local count = #selectedPaths()
	for _, label in { "Cut", "Copy", "Rename", "Delete", "Properties" } do
		local b = cmdButtons[label]
		if b then b.TextColor3 = (count > 0 and not (label == "Rename" and count ~= 1)) and T.text or T.textOff end
	end
	local pb = cmdButtons["Paste"]
	if pb then pb.TextColor3 = state.clipboard and T.text or T.textOff end
	if not statusMsgActive then statusLabel.Text = baseStatus() end
end
local function selectOnly(path)
	state.selected = {}
	if path then state.selected[path] = true end
	local _, i = recordFor(path)
	state.anchor = i
	refreshVisuals()
end
local function clickSelect(index)
	local rec = state.records[index]
	if not rec then return end
	if shiftDown() and state.anchor and state.records[state.anchor] then
		if not ctrlDown() then state.selected = {} end
		local a, b = math.min(state.anchor, index), math.max(state.anchor, index)
		for i = a, b do state.selected[state.records[i].path] = true end
	elseif ctrlDown() then
		if state.selected[rec.path] then state.selected[rec.path] = nil else state.selected[rec.path] = true end
		state.anchor = index
	else
		state.selected = { [rec.path] = true }
		state.anchor = index
	end
	refreshVisuals()
end

----------------------------------------------------------------- operations
local function runOp(label, fn)
	if state.busy then setStatus("Still working on the last action...", true) return end
	state.busy = true
	setStatus(label .. "...")
	task.spawn(function()
		local ok, err = pcall(fn)
		state.busy = false
		if not ok then setStatus(tostring(err), true) end
	end)
end

local function openItem(rec)
	if rec.isDir then
		render(rec.path)
	elseif mediaKind(rec.name) then
		openPreview(rec.path)
	else
		openEditor(rec.path)
	end
end

local function doCopy(cut)
	local paths = selectedPaths()
	if #paths == 0 then return end
	state.clipboard = { mode = cut and "cut" or "copy", paths = paths }
	refreshVisuals()
	setStatus(("%s %d item%s"):format(cut and "Cut" or "Copied", #paths, #paths == 1 and "" or "s"))
end

local function doPaste()
	local cb = state.clipboard
	if not cb then return end
	local dest = state.current
	runOp(cb.mode == "cut" and "Moving" or "Copying", function()
		local done, newPaths = 0, {}
		for _, src in cb.paths do
			if not FS.exists(src) then continue end
			if FS.isFolder(src) and (dest == src or dest:sub(1, #src + 1) == src .. "/") then
				error("The destination folder is inside the folder you're moving.", 0)
			end
			local name = baseName(src)
			if cb.mode == "cut" and parentOf(src) == dest then
				table.insert(newPaths, src)
				continue
			end
			local finalName = FS.uniqueName(dest, name, cb.mode == "copy" and parentOf(src) == dest)
			local dst = join(dest, finalName)
			local ok, err
			if cb.mode == "cut" then ok, err = FS.move(src, dst) else ok, err = FS.copy(src, dst) end
			if not ok then error(("Couldn't paste '%s': %s"):format(name, tostring(err)), 0) end
			done += 1
			table.insert(newPaths, dst)
		end
		if cb.mode == "cut" then state.clipboard = nil end
		render(state.current, true, true)
		state.selected = {}
		for _, p in newPaths do state.selected[p] = true end
		refreshVisuals()
		setStatus(("Pasted %d item%s"):format(done, done == 1 and "" or "s"))
		rebuildSidebar() highlightSidebar()
	end)
end

local function doNewFolder()
	runOp("Creating folder", function()
		local name = FS.uniqueName(state.current, "New folder")
		local p = join(state.current, name)
		local ok, err = FS.mkdir(p)
		if not ok then error("Couldn't create the folder: " .. tostring(err), 0) end
		render(state.current, true, true)
		rebuildSidebar() highlightSidebar()
		selectOnly(p)
		startRename(p)
	end)
end

local function doNewFile()
	runOp("Creating file", function()
		local name = FS.uniqueName(state.current, "New Text Document.txt")
		local p = join(state.current, name)
		local ok, err = FS.write(p, "")
		if not ok then error("Couldn't create the file: " .. tostring(err), 0) end
		render(state.current, true, true)
		selectOnly(p)
		startRename(p)
	end)
end

local function copyPathToClipboard()
	local paths = selectedPaths()
	if #paths == 0 then paths = { state.current } end
	local text = table.concat(paths, "\n")
	local ok = pcall(function() (setclipboard or toclipboard)(text) end)
	setStatus(ok and "Path copied" or "Clipboard isn't available", not ok)
end

----------------------------------------------------------------- inline rename
function startRename(path)
	local rec = recordFor(path)
	if not rec then return end
	local oldName = rec.name
	rec.nameLabel.Visible = false
	local box = new("TextBox", {
		Size = UDim2.new(1, -180, 0, 24), Position = UDim2.fromOffset(42, 5), BackgroundColor3 = T.content,
		Font = FONT, Text = oldName, TextColor3 = T.text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, ZIndex = 5,
	}, rec.row)
	corner(box, 3) stroke(box, T.accent, 1) pad(box, 4, 4, 0, 0)
	box:CaptureFocus()
	local stem = rec.isDir and oldName or (splitExt(oldName))
	box.CursorPosition = #stem + 1
	box.SelectionStart = 1

	local finished = false
	box.FocusLost:Connect(function(_, input)
		if finished then return end
		finished = true
		local cancelled = input and input.KeyCode == Enum.KeyCode.Escape
		local newName = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
		box:Destroy()
		rec.nameLabel.Visible = true
		if cancelled or newName == "" or newName == oldName then return end
		if newName:find(BAD_CHARS) then
			setStatus('A name can\'t contain any of these characters: \\ / : * ? " < > |', true)
			return
		end
		local dst = join(parentOf(path), newName)
		if FS.exists(dst) and newName:lower() ~= oldName:lower() then
			setStatus("There's already an item named '" .. newName .. "' here.", true)
			return
		end
		runOp("Renaming", function()
			local ok, err = FS.move(path, dst)
			if not ok then error("Couldn't rename: " .. tostring(err), 0) end
			render(state.current, true, true)
			selectOnly(dst)
			if rec.isDir then rebuildSidebar() highlightSidebar() end
		end)
	end)
end

----------------------------------------------------------------- delete confirmation
function confirmDelete(paths)
	if #paths == 0 then return end
	local msg
	if #paths == 1 then
		msg = ("Are you sure you want to permanently delete '%s'?"):format(baseName(paths[1]))
		if FS.isFolder(paths[1]) then msg ..= "\nEverything inside this folder will be deleted too." end
	else
		msg = ("Are you sure you want to permanently delete these %d items?"):format(#paths)
	end
	local _, box, close, x = modalShell(420, 170, #paths == 1 and "Delete File" or "Delete Multiple Items")
	x.MouseButton1Click:Connect(close)
	new("TextLabel", {
		Size = UDim2.new(1, -40, 0, 70), Position = UDim2.fromOffset(20, 48), BackgroundTransparency = 1,
		Text = msg, Font = FONT, TextSize = 13, TextColor3 = T.text, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 53,
	}, box)
	dialogButton(box, "Yes", -212, true, function()
		close()
		runOp("Deleting", function()
			local done = 0
			for _, p in paths do
				local ok, err = FS.remove(p)
				if not ok then error(("Couldn't delete '%s': %s"):format(baseName(p), tostring(err)), 0) end
				done += 1
			end
			state.selected = {}
			render(state.current, true, true)
			rebuildSidebar() highlightSidebar()
			setStatus(("Deleted %d item%s"):format(done, done == 1 and "" or "s"))
		end)
	end)
	dialogButton(box, "No", -108, false, close)
end

----------------------------------------------------------------- editor
function openEditor(path, force)
	local name = baseName(path)
	if not force and not isTextFile(name) then
		local _, box, close, x = modalShell(420, 160, name)
		x.MouseButton1Click:Connect(close)
		new("TextLabel", {
			Size = UDim2.new(1, -40, 0, 60), Position = UDim2.fromOffset(20, 50), BackgroundTransparency = 1,
			Text = "This file type can't be opened as text.\nOpen it anyway?", Font = FONT, TextSize = 13, TextColor3 = T.text,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 53,
		}, box)
		dialogButton(box, "Open", -212, true, function()
			close()
			task.defer(openEditor, path, true)
		end)
		dialogButton(box, "Cancel", -108, false, close)
		return
	end

	local content, err = FS.read(path)
	local readOnly = content == nil or #content > 200000
	local shade, box, close, x, title = modalShell(720, 470, name)
	local dirty = false
	local function updateTitle() title.Text = (dirty and "*" or "") .. name .. (readOnly and "   (read-only)" or "") end
	updateTitle()

	local area = new("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -100), Position = UDim2.fromOffset(10, 46), BackgroundColor3 = Color3.fromRGB(250, 250, 250), BorderSizePixel = 0,
		ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY, ZIndex = 52,
	}, box)
	corner(area, 6) stroke(area, T.border, 1)
	local text = content or ("Couldn't read this file:\n" .. tostring(err))
	if content and #content > 200000 then text = content:sub(1, 200000) .. "\n\n... (file too large to edit here, showing the first 200,000 characters)" end
	local editor = new("TextBox", {
		Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromOffset(8, 6), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1, Font = Enum.Font.Code, Text = text, TextColor3 = T.text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		MultiLine = true, ClearTextOnFocus = false, TextEditable = not readOnly, ZIndex = 53,
	}, area)
	editor:GetPropertyChangedSignal("Text"):Connect(function()
		if not readOnly and not dirty then dirty = true updateTitle() end
	end)

	local info = new("TextLabel", {
		Size = UDim2.new(1, -260, 0, 32), Position = UDim2.new(0, 14, 1, -44), BackgroundTransparency = 1,
		Text = "", Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53,
	}, box)

	local function save()
		if readOnly then return end
		info.Text = "Saving..."
		task.spawn(function()
			local ok, e = FS.write(path, editor.Text)
			if ok then
				dirty = false updateTitle()
				info.TextColor3 = T.textDim
				info.Text = "Saved " .. os.date("%H:%M:%S")
			else
				info.TextColor3 = T.danger
				info.Text = "Couldn't save: " .. tostring(e)
			end
		end)
	end
	local function tryClose()
		if not dirty then close() return end
		local _, ask, closeAsk, ax = modalShell(400, 160, "File Explorer")
		ax.MouseButton1Click:Connect(closeAsk)
		new("TextLabel", {
			Size = UDim2.new(1, -40, 0, 50), Position = UDim2.fromOffset(20, 50), BackgroundTransparency = 1,
			Text = "Do you want to save changes to '" .. name .. "'?", Font = FONT, TextSize = 13, TextColor3 = T.text,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 53,
		}, ask)
		dialogButton(ask, "Save", -316, true, function()
			closeAsk()
			local ok, e = FS.write(path, editor.Text)
			if ok then close() else info.TextColor3 = T.danger info.Text = "Couldn't save: " .. tostring(e) end
		end)
		dialogButton(ask, "Don't save", -212, false, function() closeAsk() close() end)
		dialogButton(ask, "Cancel", -108, false, closeAsk)
	end

	if not readOnly then dialogButton(box, "Save", -212, true, save) end
	dialogButton(box, "Close", -108, false, tryClose)
	x.MouseButton1Click:Connect(tryClose)

	local conn
	conn = UIS.InputBegan:Connect(function(input)
		if not shade.Parent then conn:Disconnect() return end
		if input.KeyCode == Enum.KeyCode.S and ctrlDown() then save() end
	end)
end

----------------------------------------------------------------- media preview (getcustomasset)
local function fmtTime(t)
	t = math.max(0, math.floor(tonumber(t) or 0))
	return ("%d:%02d"):format(t // 60, t % 60)
end

----------------------------------------------------------------- music player (Media Player style)
local MP = {
	bg1    = Color3.fromRGB(30, 26, 46),
	bg2    = Color3.fromRGB(16, 22, 38),
	panel  = Color3.fromRGB(40, 40, 54),
	text   = Color3.fromRGB(245, 245, 250),
	dim    = Color3.fromRGB(170, 172, 188),
	track  = Color3.fromRGB(90, 92, 110),
	accent = Color3.fromRGB(118, 185, 255),
	accent2 = Color3.fromRGB(170, 120, 255),
	hover  = Color3.fromRGB(62, 62, 80),
}
local SPEEDS = { 0.5, 0.75, 1, 1.25, 1.5, 2 }

-- Plays audio (Sound) and video (VideoFrame) the same way: the queue is the folder's files of
-- the same kind, and a video gets a screen where the album art and visualizer would be.
local function openMusicPlayer(startPath)
	local isVideo = mediaKind(baseName(startPath)) == "video"
	local mediaType = if isVideo then "video" else "audio"
	local shade, box, close, x, title = modalShell(if isVideo then 900 else 780, if isVideo then 600 else 480, "Media Player")
	x.MouseButton1Click:Connect(close)

	-- dark body under the title bar
	local body = new("Frame", {
		Size = UDim2.new(1, 0, 1, -38), Position = UDim2.fromOffset(0, 38),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 52,
	}, box)
	corner(body, 8)
	new("UIGradient", { Rotation = 35, Color = ColorSequence.new(MP.bg1, MP.bg2) }, body)
	-- square off the top corners against the title bar
	local topFill = new("Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 52 }, body)
	new("UIGradient", { Rotation = 35, Color = ColorSequence.new(MP.bg1, MP.bg2) }, topFill)

	local cleanup, connections = {}, {}
	local alive = true
	shade.Destroying:Connect(function()
		alive = false
		for _, c in connections do pcall(function() c:Disconnect() end) end
		for _, f in cleanup do pcall(f) end
	end)
	local function on(signal, fn) local c = signal:Connect(fn) table.insert(connections, c) return c end

	local function label(parent, props)
		props.BackgroundTransparency = 1
		props.Font = props.Font or FONT
		props.TextColor3 = props.TextColor3 or MP.text
		props.ZIndex = props.ZIndex or 54
		return new("TextLabel", props, parent)
	end
	local function iconButton(parent, glyph, size, pos, cb, textSize)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(size, size), Position = pos, AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = MP.hover, BackgroundTransparency = 1, Text = glyph, Font = FONT_B,
			TextSize = textSize or 18, TextColor3 = MP.text, AutoButtonColor = false, ZIndex = 55,
		}, parent)
		corner(b, size // 2)
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.2 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.MouseButton1Click:Connect(cb)
		return b
	end

	-- a horizontal slider: onChange(fraction, final) while dragging and on release
	local function slider(parent, pos, size, color, onChange)
		local hit = new("TextButton", {
			Size = size, Position = pos, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 55,
		}, parent)
		local rail = new("Frame", {
			Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), BackgroundColor3 = MP.track,
			BorderSizePixel = 0, ZIndex = 55,
		}, hit)
		corner(rail, 2)
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 56 }, rail)
		corner(fill, 2)
		local knob = new("Frame", {
			Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 57, Visible = false,
		}, rail)
		corner(knob, 7) stroke(knob, color, 2)
		local dragging, value = false, 0
		local function set(f)
			value = math.clamp(f, 0, 1)
			fill.Size = UDim2.fromScale(value, 1)
			knob.Position = UDim2.fromScale(value, 0.5)
		end
		local function fromMouse()
			local m = UIS:GetMouseLocation()
			local p, s = rail.AbsolutePosition, rail.AbsoluteSize
			return (m.X - p.X) / math.max(s.X, 1)
		end
		hit.MouseEnter:Connect(function() knob.Visible = true end)
		hit.MouseLeave:Connect(function() if not dragging then knob.Visible = false end end)
		on(hit.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				set(fromMouse())
				onChange(value, false)
			end
		end)
		on(UIS.InputChanged, function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				set(fromMouse())
				onChange(value, false)
			end
		end)
		on(UIS.InputEnded, function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				knob.Visible = false
				onChange(value, true)
			end
		end)
		return { set = function(f) if not dragging then set(f) end end, dragging = function() return dragging end }
	end

	----------------------------------------------------------------- now playing: art + info + visualizer
	local art = new("Frame", {
		Size = UDim2.fromOffset(210, 210), Position = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 53,
	}, body)
	corner(art, 10)
	local artGradient = new("UIGradient", { Rotation = 45, Color = ColorSequence.new(MP.accent2, MP.accent) }, art)
	label(art, { Size = UDim2.fromScale(1, 1), Text = "♪", Font = FONT_B, TextSize = 96, TextColor3 = Color3.new(1, 1, 1), TextTransparency = 0.15 })

	local titleLabel = label(body, {
		Size = UDim2.new(1, -300, 0, 34), Position = UDim2.fromOffset(268, 40), Text = "", Font = FONT_B, TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local subLabel = label(body, {
		Size = UDim2.new(1, -300, 0, 20), Position = UDim2.fromOffset(268, 78), Text = "", TextSize = 14, TextColor3 = MP.dim,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local statusLabel = label(body, {
		Size = UDim2.new(1, -300, 0, 18), Position = UDim2.fromOffset(268, 102), Text = "", TextSize = 12, TextColor3 = MP.dim,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	})

	-- visualizer: bars driven by PlaybackLoudness
	local vis = new("Frame", {
		Size = UDim2.new(1, -300, 0, 110), Position = UDim2.fromOffset(268, 132), BackgroundTransparency = 1, ZIndex = 53,
	}, body)
	local BARS = 40
	local bars, heights = {}, {}
	for i = 1, BARS do
		local b = new("Frame", {
			Size = UDim2.new(1 / BARS, -3, 0, 2), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / BARS, 0, 1, 0),
			BackgroundColor3 = MP.accent:Lerp(MP.accent2, i / BARS), BorderSizePixel = 0, ZIndex = 54,
		}, vis)
		corner(b, 2)
		bars[i], heights[i] = b, 0
	end

	-- video: a screen over the art / info / visualizer area (the "Loading..." line sits on it)
	local screen
	if isVideo then
		art.Visible, titleLabel.Visible, subLabel.Visible, vis.Visible = false, false, false, false
		screen = new("Frame", {
			Size = UDim2.new(1, -32, 1, -198), Position = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 53,
		}, body)
		corner(screen, 10)
		statusLabel.Parent = screen
		statusLabel.Size = UDim2.new(1, -40, 1, 0)
		statusLabel.Position = UDim2.fromOffset(20, 0)
		statusLabel.TextXAlignment = Enum.TextXAlignment.Center
		statusLabel.TextWrapped = true
		statusLabel.TextSize = 14
		statusLabel.ZIndex = 56
	end

	----------------------------------------------------------------- transport bar
	local bar = new("Frame", {
		Size = UDim2.new(1, -32, 0, 150), Position = UDim2.new(0, 16, 1, -166),
		BackgroundColor3 = MP.panel, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 53,
	}, body)
	corner(bar, 10)

	local posLabel = label(bar, { Size = UDim2.fromOffset(56, 20), Position = UDim2.fromOffset(14, 16), Text = "0:00", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
	local lenLabel = label(bar, { Size = UDim2.fromOffset(56, 20), Position = UDim2.new(1, -70, 0, 16), Text = "0:00", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })

	----------------------------------------------------------------- player state
	local sound
	local queue, index = {}, 1
	local looped, shuffle, muted = false, false, false
	local volume, speedIndex = 0.6, 3
	local wantPlaying, lastPos, endedAt = false, 0, nil
	local generation = 0

	local seek = slider(bar, UDim2.fromOffset(74, 14), UDim2.new(1, -148, 0, 24), MP.accent, function(f, final)
		if not sound then return end
		local len = sound.TimeLength
		if len and len > 0 then
			posLabel.Text = fmtTime(f * len)
			if final then pcall(function() sound.TimePosition = f * len end) end
		end
	end)

	local function applyVolume()
		if sound then pcall(function() sound.Volume = if muted then 0 else volume end) end
	end

	local function buildQueue(path)
		local folder = parentOf(path)
		local list = {}
		for _, p in FS.children(folder) do
			if FS.isFile(p) and mediaKind(baseName(p)) == mediaType then table.insert(list, p) end
		end
		table.sort(list, function(a, b) return baseName(a):lower() < baseName(b):lower() end)
		if #list == 0 then list = { path } end
		queue, index = list, table.find(list, path) or 1
	end

	local function load(path, autoplay)
		generation += 1
		local mine = generation
		if sound then
			local old = sound
			sound = nil
			pcall(function() old:Stop() end)
			pcall(function() old:Destroy() end)
		end
		local stem, ext = splitExt(baseName(path))
		title.Text = "Media Player — " .. stem
		titleLabel.Text = stem
		subLabel.Text = ("%s  •  %s"):format(typeName(baseName(path), false), parentOf(path) == "" and "Workspace" or parentOf(path))
		statusLabel.Text = "Loading..."
		posLabel.Text, lenLabel.Text = "0:00", "0:00"
		seek.set(0)
		lastPos, endedAt = 0, nil
		-- a fresh tint per track
		local hue = (#stem * 37 % 360) / 360
		artGradient.Color = ColorSequence.new(Color3.fromHSV(hue, 0.55, 0.95), Color3.fromHSV((hue + 0.15) % 1, 0.65, 0.85))

		local ok, id = pcall(getcustomasset, path)
		if mine ~= generation or not alive then return end
		if not ok then
			statusLabel.Text = "Couldn't load: " .. tostring(id)
			statusLabel.TextColor3 = Color3.fromRGB(255, 140, 130)
			return
		end
		statusLabel.TextColor3 = MP.dim
		local s
		if isVideo then
			-- a VideoFrame behind a Sound-shaped wrapper, so the rest of the player treats both alike
			statusLabel.Visible = true
			local vf = new("VideoFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Looped = looped, ZIndex = 54 }, screen)
			vf.Video = id
			local methods = {
				Play = function() vf:Play() end, Resume = function() vf:Play() end,
				Pause = function() vf:Pause() end,
				Stop = function() vf:Pause() vf.TimePosition = 0 end,
				Destroy = function() pcall(function() vf:Pause() end) vf:Destroy() end,
			}
			s = setmetatable({}, {
				__index = function(_, k)
					if methods[k] then return methods[k] end
					if k == "IsPlaying" then return vf.Playing == true end
					if k == "PlaybackLoudness" then return 0 end
					if k == "PlaybackSpeed" then return 1 end
					return vf[k]
				end,
				__newindex = function(_, k, v)
					if k == "PlaybackSpeed" then return end -- videos play at 1x
					vf[k] = v
				end,
			})
			task.spawn(function()
				pcall(function() vf.Loaded:Wait() end)
				if mine ~= generation or not alive then return end
				local okL, isLoaded = pcall(function() return vf.IsLoaded end)
				if not (okL and isLoaded) then
					statusLabel.Text = "Couldn't play this video (see the output for why).\nkAPI plays .mp4 (H.264) and .webm (VP8 / VP9) videos."
					statusLabel.TextColor3 = Color3.fromRGB(255, 140, 130)
					return
				end
				statusLabel.Visible = false
				-- loop / volume set while it was loading didn't reach the player yet
				pcall(function() vf.Looped = looped end)
				applyVolume()
				local okR, res = pcall(function() return vf.Resolution end)
				if okR and res then
					title.Text = ("Media Player — %s  (%dx%d)"):format((splitExt(baseName(path))), res.X, res.Y)
				end
			end)
		else
			s = new("Sound", { Looped = looped, PlaybackSpeed = SPEEDS[speedIndex] }, box)
			s.SoundId = id
		end
		sound = s
		applyVolume()
		if autoplay then
			wantPlaying = true
			pcall(function() s:Play() end)
		end
	end
	table.insert(cleanup, function()
		if sound then pcall(function() sound:Stop() end) pcall(function() sound:Destroy() end) end
	end)

	local function step(direction, auto)
		if #queue == 0 then return end
		if shuffle and #queue > 1 then
			local n = index
			while n == index do n = math.random(1, #queue) end
			index = n
		else
			index += direction
			if index > #queue then
				if auto and not looped then index = #queue wantPlaying = false return end
				index = 1
			elseif index < 1 then
				index = #queue
			end
		end
		task.spawn(load, queue[index], true)
	end

	local function togglePlay()
		if not sound then return end
		pcall(function()
			if sound.IsPlaying then
				wantPlaying = false
				sound:Pause()
			else
				wantPlaying = true
				local len = sound.TimeLength
				if sound.TimePosition > 0 and not (len > 0 and sound.TimePosition >= len - 0.25) then sound:Resume() else sound:Play() end
			end
		end)
	end
	local function nudge(seconds)
		if not sound then return end
		pcall(function()
			local len = sound.TimeLength
			local t = sound.TimePosition + seconds
			if len > 0 then t = math.clamp(t, 0, len - 0.05) else t = math.max(0, t) end
			sound.TimePosition = t
		end)
	end
	local function previous()
		-- like every player: restart the song unless it just began
		if sound and (tonumber(sound.TimePosition) or 0) > 3 then
			pcall(function() sound.TimePosition = 0 end)
		else
			step(-1, false)
		end
	end

	----------------------------------------------------------------- controls row
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 64), Position = UDim2.fromOffset(0, 52), BackgroundTransparency = 1, ZIndex = 54 }, bar)
	local shuffleBtn, loopBtn
	shuffleBtn = iconButton(row, "⤮", 36, UDim2.new(0.5, -170, 0.5, 0), function()
		shuffle = not shuffle
		shuffleBtn.TextColor3 = if shuffle then MP.accent else MP.text
	end, 18)
	iconButton(row, "⏮", 40, UDim2.new(0.5, -118, 0.5, 0), previous, 18)
	iconButton(row, "↺", 40, UDim2.new(0.5, -66, 0.5, 0), function() nudge(-10) end, 20)
	label(row, { Size = UDim2.fromOffset(20, 12), Position = UDim2.new(0.5, -76, 0.5, 9), Text = "10", TextSize = 9, Font = FONT_B, ZIndex = 56 })
	local playBtn = new("TextButton", {
		Size = UDim2.fromOffset(52, 52), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = MP.accent, Text = "▶", Font = FONT_B, TextSize = 22, TextColor3 = Color3.fromRGB(20, 24, 40),
		AutoButtonColor = true, ZIndex = 55,
	}, row)
	corner(playBtn, 26)
	playBtn.MouseButton1Click:Connect(togglePlay)
	iconButton(row, "↻", 40, UDim2.new(0.5, 66, 0.5, 0), function() nudge(10) end, 20)
	label(row, { Size = UDim2.fromOffset(20, 12), Position = UDim2.new(0.5, 56, 0.5, 9), Text = "10", TextSize = 9, Font = FONT_B, ZIndex = 56 })
	iconButton(row, "⏭", 40, UDim2.new(0.5, 118, 0.5, 0), function() step(1, false) end, 18)
	loopBtn = iconButton(row, "🔁", 36, UDim2.new(0.5, 170, 0.5, 0), function()
		looped = not looped
		loopBtn.TextTransparency = if looped then 0 else 0.55
		if sound then pcall(function() sound.Looped = looped end) end
	end, 16)
	loopBtn.TextTransparency = 0.55

	-- left: queue position
	local queueLabel = label(row, {
		Size = UDim2.fromOffset(170, 20), Position = UDim2.new(0, 16, 0.5, -10), Text = "", TextSize = 12, TextColor3 = MP.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- right: speed + volume
	local speedBtn
	speedBtn = new("TextButton", {
		Size = UDim2.fromOffset(46, 26), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -212, 0.5, 0),
		BackgroundColor3 = MP.hover, BackgroundTransparency = 0.3, Text = "1x", Font = FONT_B, TextSize = 12,
		TextColor3 = MP.text, AutoButtonColor = true, ZIndex = 55,
	}, row)
	corner(speedBtn, 6)
	speedBtn.Visible = not isVideo
	speedBtn.MouseButton1Click:Connect(function()
		speedIndex = speedIndex % #SPEEDS + 1
		speedBtn.Text = tostring(SPEEDS[speedIndex]) .. "x"
		if sound then pcall(function() sound.PlaybackSpeed = SPEEDS[speedIndex] end) end
	end)
	local muteBtn
	local volSlider
	local function volumeIcon()
		muteBtn.Text = if muted or volume == 0 then "🔇" elseif volume < 0.5 then "🔉" else "🔊"
	end
	muteBtn = iconButton(row, "🔊", 32, UDim2.new(1, -144, 0.5, 0), function()
		muted = not muted
		volumeIcon()
		applyVolume()
		volSlider.set(if muted then 0 else volume)
	end, 15)
	volSlider = slider(row, UDim2.new(1, -124, 0.5, -12), UDim2.fromOffset(104, 24), MP.text, function(f)
		volume = f
		muted = false
		volumeIcon()
		applyVolume()
	end)
	volSlider.set(volume)

	-- shortcuts hint
	label(bar, {
		Size = UDim2.new(1, -28, 0, 16), Position = UDim2.new(0, 14, 1, -24), TextSize = 11, TextColor3 = MP.dim,
		Text = "Space play/pause  •  ← → 5s  •  ↑ ↓ volume  •  L loop  •  M mute  •  N / P next / previous",
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	on(UIS.InputBegan, function(input, processed)
		if processed or not alive or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local k = input.KeyCode
		if k == Enum.KeyCode.Space then togglePlay()
		elseif k == Enum.KeyCode.Left then nudge(-5)
		elseif k == Enum.KeyCode.Right then nudge(5)
		elseif k == Enum.KeyCode.Up or k == Enum.KeyCode.Down then
			volume = math.clamp(volume + (if k == Enum.KeyCode.Up then 0.05 else -0.05), 0, 1)
			muted = false
			volSlider.set(volume)
			volumeIcon()
			applyVolume()
		elseif k == Enum.KeyCode.L then
			looped = not looped
			loopBtn.TextTransparency = if looped then 0 else 0.55
			if sound then pcall(function() sound.Looped = looped end) end
		elseif k == Enum.KeyCode.M then
			muted = not muted
			volumeIcon()
			applyVolume()
			volSlider.set(if muted then 0 else volume)
		elseif k == Enum.KeyCode.N then step(1, false)
		elseif k == Enum.KeyCode.P then previous()
		end
	end)

	----------------------------------------------------------------- update loop
	on(game:GetService("RunService").RenderStepped, function(dt)
		if not alive then return end
		local s = sound
		local pos, len, playing, loud = 0, 0, false, 0
		if s then
			pcall(function()
				pos, len, playing, loud = s.TimePosition, s.TimeLength, s.IsPlaying, s.PlaybackLoudness
			end)
		end
		pos, len, loud = tonumber(pos) or 0, tonumber(len) or 0, tonumber(loud) or 0

		playBtn.Text = if playing then "❚❚" else "▶"
		queueLabel.Text = if #queue > 1 then ("%d of %d in this folder"):format(index, #queue) else ""
		if s and len > 0 then
			if statusLabel.Text == "Loading..." and not isVideo then
				statusLabel.Text = ("%s long"):format(fmtTime(len))
			end
			lenLabel.Text = "-" .. fmtTime(len - pos)
			if not seek.dragging() then
				posLabel.Text = fmtTime(pos)
				seek.set(pos / len)
			end
		end

		-- the song ran out: next one in the folder (or stop at the end)
		if s and wantPlaying and not looped and len > 0 and not playing and lastPos >= len - 1 then
			endedAt = endedAt or os.clock()
			if os.clock() - endedAt > 0.4 then
				endedAt = nil
				wantPlaying = false
				if #queue > 1 then step(1, true) end
			end
		else
			endedAt = nil
		end
		if playing then lastPos = pos end

		-- visualizer
		if isVideo then return end
		local level = if playing then math.clamp(loud / 400, 0, 1) else 0
		local t = os.clock()
		for i = 1, BARS do
			local shape = 0.35 + 0.65 * math.sin(math.pi * (i - 0.5) / BARS) ^ 0.6
			local wiggle = 0.55 + 0.45 * math.noise(i * 0.37, t * 3.1)
			local target = level * shape * (0.6 + wiggle)
			heights[i] += (target - heights[i]) * math.min(1, dt * (if target > heights[i] then 18 else 6))
			bars[i].Size = UDim2.new(1 / BARS, -3, math.clamp(heights[i], 0.02, 1), 0)
		end
	end)

	buildQueue(startPath)
	task.spawn(load, startPath, true)
end

function openPreview(path)
	local name = baseName(path)
	local kind = mediaKind(name)
	if kind == "audio" or kind == "video" then return openMusicPlayer(path) end
	local shade, box, close, x = modalShell(720, 500, name)
	x.MouseButton1Click:Connect(close)

	local stage = new("Frame", {
		Size = UDim2.new(1, -20, 1, -100), Position = UDim2.fromOffset(10, 46),
		BackgroundColor3 = Color3.fromRGB(32, 32, 32), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 52,
	}, box)
	corner(stage, 6)
	local info = new("TextLabel", {
		Size = UDim2.new(1, -140, 0, 32), Position = UDim2.new(0, 14, 1, -44), BackgroundTransparency = 1,
		Text = "", Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 53,
	}, box)
	local loading = new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Loading...", Font = FONT,
		TextSize = 14, TextColor3 = Color3.fromRGB(200, 200, 200), ZIndex = 53,
	}, stage)
	dialogButton(box, "Close", -108, false, close)

	local cleanup = {}
	shade.Destroying:Connect(function()
		for _, f in cleanup do pcall(f) end
	end)

	local function controlButton(label, xOff, cb)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(70, 32), Position = UDim2.new(1, xOff, 1, -44),
			BackgroundColor3 = T.toolbar, Text = label, Font = FONT, TextSize = 13, TextColor3 = T.text,
			AutoButtonColor = true, ZIndex = 53,
		}, box)
		corner(b, 5) stroke(b, T.border, 1)
		b.MouseButton1Click:Connect(cb)
		return b
	end

	task.spawn(function()
		local ok, id = pcall(getcustomasset, path)
		if not shade.Parent then return end
		if not ok then
			loading.Text = "Couldn't load this file:\n" .. tostring(id)
			loading.TextWrapped = true
			loading.TextColor3 = Color3.fromRGB(255, 140, 130)
			return
		end
		loading.Visible = false

		if kind == "image" then
			-- checkerboard, so transparency shows
			for gy = 0, 40 do
				for gx = 0, 60 do
					if (gx + gy) % 2 == 0 then
						new("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(gx * 12, gy * 12), BackgroundColor3 = Color3.fromRGB(44, 44, 44), BorderSizePixel = 0, ZIndex = 52 }, stage)
					end
				end
			end
			local img = new("ImageLabel", {
				Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit, Image = id, ZIndex = 54,
			}, stage)
			task.defer(function()
				local okS, size = pcall(function() return img.ImageContent.Object.Size end)
				info.Text = (okS and size) and ("%d × %d  •  %s"):format(size.X, size.Y, name) or name
			end)

		elseif kind == "video" then
			local video = new("VideoFrame", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Video = id, Looped = false, ZIndex = 54,
			}, stage)
			table.insert(cleanup, function() video:Pause() end)
			info.Text = name
			controlButton("Pause", -192, function() pcall(function() video:Pause() end) end)
			controlButton("Play", -268, function() pcall(function() video:Play() end) end)

		elseif kind == "model" then
			local viewport = new("ViewportFrame", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(32, 32, 32), BackgroundTransparency = 0,
				Ambient = Color3.fromRGB(170, 170, 170), LightColor = Color3.fromRGB(255, 255, 255),
				LightDirection = Vector3.new(-1, -1, -1), ZIndex = 53,
			}, stage)
			local camera = new("Camera", { FieldOfView = 40 }, viewport)
			viewport.CurrentCamera = camera
			local part = new("MeshPart", { Anchored = true, Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.SmoothPlastic }, viewport)
			local status = new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Building mesh...", Font = FONT,
				TextSize = 14, TextColor3 = Color3.fromRGB(200, 200, 200), ZIndex = 54,
			}, stage)
			part.MeshId = id -- kAPI builds the mesh and applies it to this part

			-- wait for the mesh to land, then show it at its own size and frame it
			local started, before = os.clock(), part.MeshSize
			while shade.Parent and part.MeshSize == before and os.clock() - started < 20 do task.wait(0.1) end
			if not shade.Parent then return end
			if part.MeshSize == before then
				status.Text = "Couldn't build this mesh (see the output for details)"
				status.TextColor3 = Color3.fromRGB(255, 140, 130)
				return
			end
			status:Destroy()
			part.Size = part.MeshSize
			local radius = part.Size.Magnitude / 2
			local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.15
			info.Text = ("%s  •  %.2f × %.2f × %.2f studs"):format(name, part.Size.X, part.Size.Y, part.Size.Z)
			local angle = 0
			while shade.Parent do
				angle += math.rad(0.6)
				part.CFrame = CFrame.Angles(0, angle, 0)
				camera.CFrame = CFrame.new(Vector3.new(0, radius * 0.35, distance), Vector3.zero)
				task.wait()
			end

		elseif kind == "font" then
			local list = new("Frame", {
				Size = UDim2.new(1, -40, 1, -30), Position = UDim2.fromOffset(20, 15), BackgroundTransparency = 1, ZIndex = 53,
			}, stage)
			new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
			for i, size in { 14, 20, 28, 40 } do
				local label = new("TextLabel", {
					Size = UDim2.new(1, 0, 0, size + 8), BackgroundTransparency = 1, LayoutOrder = i,
					Text = "The quick brown fox jumps over the lazy dog 0123456789",
					TextSize = size, TextColor3 = Color3.fromRGB(235, 235, 235), TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54,
				}, list)
				pcall(function() label.FontFace = id end)
			end
			info.Text = name
		end
	end)
end

----------------------------------------------------------------- properties
function showProperties(paths)
	if #paths == 0 then paths = { state.current } end
	local _, box, close, x = modalShell(380, 300, (#paths == 1 and (paths[1] == "" and "Workspace" or baseName(paths[1])) or (#paths .. " items")) .. " Properties")
	x.MouseButton1Click:Connect(close)
	local list = new("Frame", { Size = UDim2.new(1, -40, 1, -110), Position = UDim2.fromOffset(20, 50), BackgroundTransparency = 1, ZIndex = 53 }, box)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local rows = {}
	local function line(label, value, order)
		local f = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 53 }, list)
		new("TextLabel", { Size = UDim2.fromOffset(90, 20), BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54 }, f)
		local v = new("TextLabel", { Size = UDim2.new(1, -96, 1, 0), Position = UDim2.fromOffset(96, 0), BackgroundTransparency = 1, Text = value, Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54 }, f)
		rows[label] = v
	end
	if #paths == 1 then
		local p = paths[1]
		local isDir = p == "" or FS.isFolder(p)
		line("Name:", p == "" and "Workspace" or baseName(p), 1)
		line("Type:", typeName(baseName(p), isDir), 2)
		line("Location:", p == "" and "(root)" or (parentOf(p) == "" and "Workspace" or parentOf(p)), 3)
		line("Size:", "Calculating...", 4)
		if isDir then line("Contains:", "Calculating...", 5) end
	else
		line("Items:", tostring(#paths), 1)
		line("Location:", state.current == "" and "Workspace" or state.current, 2)
		line("Size:", "Calculating...", 3)
	end
	dialogButton(box, "OK", -108, true, close)

	task.spawn(function()
		local bytes, files, folders = 0, 0, 0
		local function walk(p)
			if p == "" or FS.isFolder(p) then
				if p ~= "" then folders += 1 end
				for _, c in FS.children(p) do walk(c) end
			else
				files += 1
				local data = FS.read(p)
				if data then bytes += #data end
			end
		end
		for _, p in paths do walk(p) end
		if rows["Size:"] and rows["Size:"].Parent then rows["Size:"].Text = fmtBytes(bytes) end
		if rows["Contains:"] and rows["Contains:"].Parent then
			local sub = (#paths == 1 and paths[1] ~= "") and (folders - 1) or folders
			rows["Contains:"].Text = ("%d file%s, %d folder%s"):format(files, files == 1 and "" or "s", sub, sub == 1 and "" or "s")
		end
	end)
end

----------------------------------------------------------------- menus
local function itemMenu(rec)
	local sel = selectedPaths()
	local single = #sel == 1
	openMenu({
		{ label = rec.isDir and "Open" or "Open", bold = true, key = "Enter", cb = function() openItem(rec) end, enabled = single },
		{ label = "Edit", cb = function() openEditor(rec.path, true) end, enabled = single and not rec.isDir },
		"-",
		{ label = "Cut", key = "Ctrl+X", cb = function() doCopy(true) end },
		{ label = "Copy", key = "Ctrl+C", cb = function() doCopy(false) end },
		{ label = "Paste", key = "Ctrl+V", cb = doPaste, enabled = state.clipboard ~= nil },
		"-",
		{ label = "Copy as path", cb = copyPathToClipboard },
		{ label = "Rename", key = "F2", cb = function() startRename(rec.path) end, enabled = single },
		{ label = "Delete", key = "Del", cb = function() confirmDelete(selectedPaths()) end },
		"-",
		{ label = "Properties", key = "Alt+Enter", cb = function() showProperties(selectedPaths()) end },
	})
end
local function backgroundMenu()
	openMenu({
		{ label = "Refresh", key = "F5", cb = function() render(state.current, true, true) end },
		"-",
		{ label = "Paste", key = "Ctrl+V", cb = doPaste, enabled = state.clipboard ~= nil },
		"-",
		{ label = "New folder", key = "Ctrl+Shift+N", cb = doNewFolder },
		{ label = "New text document", cb = doNewFile },
		"-",
		{ label = "Select all", key = "Ctrl+A", cb = function()
			for _, r in state.records do state.selected[r.path] = true end
			refreshVisuals()
		end },
		{ label = "Copy as path", cb = function() state.selected = {} refreshVisuals() copyPathToClipboard() end },
		{ label = "Properties", cb = function() showProperties({ state.current }) end },
	})
end

----------------------------------------------------------------- command bar buttons
cmdButton("+ New folder", 8, 96, doNewFolder)
cmdButton("+ New file", 108, 84, doNewFile)
new("Frame", { Size = UDim2.fromOffset(1, 22), Position = UDim2.fromOffset(200, 9), BackgroundColor3 = T.border, BorderSizePixel = 0 }, cmdbar)
cmdButton("Cut", 210, 44, function() doCopy(true) end)
cmdButton("Copy", 256, 48, function() doCopy(false) end)
cmdButton("Paste", 306, 50, doPaste)
cmdButton("Rename", 358, 62, function() local s = selectedPaths() if #s == 1 then startRename(s[1]) end end)
cmdButton("Delete", 422, 56, function() confirmDelete(selectedPaths()) end)
new("Frame", { Size = UDim2.fromOffset(1, 22), Position = UDim2.fromOffset(486, 9), BackgroundColor3 = T.border, BorderSizePixel = 0 }, cmdbar)
cmdButton("Properties", 496, 80, function() showProperties(selectedPaths()) end)

----------------------------------------------------------------- rows
local function makeRow(name, path, isDir, order, index)
	local row = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.accentHv, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order }, scroll)
	corner(row, 4)
	local iconHolder = new("Frame", { Size = UDim2.fromOffset(44, 34), BackgroundTransparency = 1 }, row)
	local _, ext = splitExt(name)
	local icon = isDir and folderIcon(iconHolder) or fileIcon(iconHolder, ext:sub(2))
	local nameLabel = new("TextLabel", { Size = UDim2.new(1, -180, 1, 0), Position = UDim2.fromOffset(44, 0), BackgroundTransparency = 1, Text = name, Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
	new("TextLabel", { Size = UDim2.fromOffset(120, 34), Position = UDim2.new(1, -126, 0, 0), BackgroundTransparency = 1, Text = typeName(name, isDir), Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)

	local rec = { name = name, path = path, isDir = isDir, row = row, nameLabel = nameLabel, icon = icon, index = index, hover = false }
	row.MouseEnter:Connect(function() rec.hover = true refreshVisuals() end)
	row.MouseLeave:Connect(function() rec.hover = false refreshVisuals() end)

	local lastClick = 0
	row.MouseButton1Click:Connect(function()
		closeMenu()
		state.focused = true
		local now = os.clock()
		if now - lastClick < 0.35 and not ctrlDown() and not shiftDown() then
			lastClick = 0
			openItem(rec)
			return
		end
		lastClick = now
		clickSelect(rec.index)
	end)
	row.MouseButton2Click:Connect(function()
		state.focused = true
		if not state.selected[rec.path] then clickSelect(rec.index) end
		itemMenu(rec)
	end)
	return rec
end

-- empty space: clicking clears the selection, right-click opens the background menu
scroll.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		closeMenu()
		state.focused = true
		if not ctrlDown() then state.selected = {} refreshVisuals() end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		state.focused = true
		state.selected = {}
		refreshVisuals()
		backgroundMenu()
	end
end)

----------------------------------------------------------------- render a folder
function render(path, fromHistory, keepSelection)
	closeMenu()
	path = tostring(path or ""):gsub("\\", "/"):gsub("/+$", "")
	local changed = path ~= state.current
	state.current = path
	addrBox.Text = path == "" and "Workspace" or path
	titleText.Text = (path == "" and "Workspace" or baseName(path)) .. " - File Explorer"

	if not fromHistory then
		for i = #state.history, state.idx + 1, -1 do state.history[i] = nil end
		table.insert(state.history, path)
		state.idx = #state.history
	end
	backBtn.TextTransparency = state.idx > 1 and 0 or 0.6
	fwdBtn.TextTransparency = state.idx < #state.history and 0 or 0.6

	if changed or not keepSelection then state.selected = {} state.anchor = nil end
	if changed and searchBox.Text ~= "" then
		state.suppressSearch = true
		searchBox.Text = ""
		state.suppressSearch = false
	end

	for _, c in scroll:GetChildren() do if c:IsA("GuiButton") or (c:IsA("TextLabel")) then c:Destroy() end end
	state.records = {}

	local filter = searchBox.Text:lower()
	local folders, files = {}, {}
	for _, p in FS.children(path) do
		local nm = baseName(p)
		if filter == "" or nm:lower():find(filter, 1, true) then
			if FS.isFolder(p) then table.insert(folders, { nm, p }) else table.insert(files, { nm, p }) end
		end
	end
	table.sort(folders, function(a, b) return a[1]:lower() < b[1]:lower() end)
	table.sort(files, function(a, b) return a[1]:lower() < b[1]:lower() end)

	local order = 0
	for _, f in folders do order += 1 table.insert(state.records, makeRow(f[1], f[2], true, order, order)) end
	for _, f in files do order += 1 table.insert(state.records, makeRow(f[1], f[2], false, order, order)) end

	-- drop selections that no longer exist
	for p in state.selected do if not recordFor(p) then state.selected[p] = nil end end

	if order == 0 then
		new("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = filter ~= "" and "No items match your search." or "This folder is empty.", Font = FONT, TextSize = 13, TextColor3 = T.textDim, LayoutOrder = 1 }, scroll)
	end
	highlightSidebar()
	refreshVisuals()
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if state.suppressSearch then return end
	render(state.current, true, true)
end)

----------------------------------------------------------------- window buttons
local minimized, maximized = false, false
local restore = { size = window.Size, pos = window.Position }
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	for _, f in { toolbar, cmdbar, body, status } do f.Visible = not minimized end
	if minimized then
		restore.size = window.Size
		window.Size = UDim2.fromOffset(window.AbsoluteSize.X, 40)
	else
		window.Size = maximized and UDim2.new(1, 0, 1, 0) or restore.size
	end
end)
maxBtn.MouseButton1Click:Connect(function()
	if minimized then return end
	maximized = not maximized
	if maximized then
		restore.size, restore.pos = window.Size, window.Position
		window.Size, window.Position = UDim2.new(1, 0, 1, 0), UDim2.new()
		maxBtn.Text = "❐"
	else
		window.Size, window.Position = restore.size, restore.pos
		maxBtn.Text = "☐"
	end
end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- drag by the title bar
do
	local dragging, startPos, startMouse
	titlebar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and not maximized then
			dragging = true startPos = window.Position startMouse = UIS:GetMouseLocation()
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = UIS:GetMouseLocation() - startMouse
			window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

----------------------------------------------------------------- global input: close menus, focus, shortcuts
UIS.InputBegan:Connect(function(input, processed)
	if not gui.Parent then return end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 then
		if menuFrame then
			local m = UIS:GetMouseLocation()
			local p, s = menuFrame.AbsolutePosition, menuFrame.AbsoluteSize
			local inside = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
			if not inside then task.defer(function() if t == Enum.UserInputType.MouseButton1 then closeMenu() end end) end
		end
		state.focused = mouseInWindow()
		return
	end
	if t ~= Enum.UserInputType.Keyboard then return end
	if not state.focused or state.modalCount > 0 then return end
	if UIS:GetFocusedTextBox() then return end

	local k = input.KeyCode
	local ctrl, shift = ctrlDown(), shiftDown()
	local sel = selectedPaths()

	if k == Enum.KeyCode.Escape then
		if menuFrame then closeMenu() else state.selected = {} refreshVisuals() end
	elseif k == Enum.KeyCode.Delete then
		confirmDelete(sel)
	elseif k == Enum.KeyCode.F2 then
		if #sel == 1 then startRename(sel[1]) end
	elseif k == Enum.KeyCode.F5 then
		render(state.current, true, true)
	elseif k == Enum.KeyCode.Backspace then
		if state.current ~= "" then render(parentOf(state.current)) end
	elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter then
		if UIS:IsKeyDown(Enum.KeyCode.LeftAlt) or UIS:IsKeyDown(Enum.KeyCode.RightAlt) then
			showProperties(sel)
		elseif #sel == 1 then
			local rec = recordFor(sel[1])
			if rec then openItem(rec) end
		end
	elseif ctrl and k == Enum.KeyCode.A then
		for _, r in state.records do state.selected[r.path] = true end
		refreshVisuals()
	elseif ctrl and k == Enum.KeyCode.C then
		doCopy(false)
	elseif ctrl and k == Enum.KeyCode.X then
		doCopy(true)
	elseif ctrl and k == Enum.KeyCode.V then
		doPaste()
	elseif ctrl and shift and k == Enum.KeyCode.N then
		doNewFolder()
	elseif k == Enum.KeyCode.Up or k == Enum.KeyCode.Down then
		local n = #state.records
		if n == 0 then return end
		local i = state.anchor or 0
		i = k == Enum.KeyCode.Down and math.min(n, i + 1) or math.max(1, i - 1)
		if shift and state.anchor then
			state.selected[state.records[i].path] = true
			state.anchor = i
			refreshVisuals()
		else
			selectOnly(state.records[i].path)
		end
	end
end)

----------------------------------------------------------------- go
rebuildSidebar()
render("")
