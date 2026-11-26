local Players = ref(game:GetService("Players"))
local UIS = ref(game:GetService("UserInputService"))
local RunService = ref(game:GetService("RunService"))
local TweenService = ref(game:GetService("TweenService"))
local HttpService = ref(game:GetService("HttpService"))
local AssetService = ref(game:GetService("AssetService"))
local player = Players.LocalPlayer

----------------------------------------------------------------- settings (saved in the workspace root)
local SETTINGS_FILE = ".kapi_explorer.json"
local DEFAULTS = {
	dark = false, view = "details", showExt = true, showSize = true, confirmDelete = true,
	showHidden = false, sortKey = "name", sortAsc = true,
}
local Settings = table.clone(DEFAULTS)
do
	local ok, raw = pcall(readfile, SETTINGS_FILE)
	if ok and type(raw) == "string" then
		local ok2, t = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok2 and type(t) == "table" then
			for k, v in t do
				if DEFAULTS[k] ~= nil and type(v) == type(DEFAULTS[k]) then Settings[k] = v end
			end
		end
	end
end
local function saveSettings()
	pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings)) end)
end

----------------------------------------------------------------- themes (Win11 light / dark)
local rgb = Color3.fromRGB
local THEMES = {
	light = {
		window = rgb(243, 243, 243), titlebar = rgb(238, 238, 238), toolbar = rgb(249, 249, 249),
		sidebar = rgb(243, 243, 243), content = rgb(255, 255, 255), border = rgb(225, 225, 225),
		borderStrong = rgb(200, 200, 200), accent = rgb(0, 103, 192), accentText = rgb(255, 255, 255),
		accentBg = rgb(204, 232, 255), accentHv = rgb(229, 243, 255), hover = rgb(234, 234, 234),
		text = rgb(32, 32, 32), textDim = rgb(110, 110, 110), textOff = rgb(170, 170, 170),
		folder = rgb(255, 202, 72), folderDk = rgb(232, 168, 32), page = rgb(255, 255, 255),
		pageEdge = rgb(176, 176, 176), danger = rgb(196, 43, 28), menu = rgb(249, 249, 249),
		input = rgb(255, 255, 255), editor = rgb(250, 250, 250), switchOff = rgb(140, 140, 140),
		link = rgb(0, 95, 184),
	},
	dark = {
		window = rgb(32, 32, 32), titlebar = rgb(28, 28, 28), toolbar = rgb(39, 39, 39),
		sidebar = rgb(32, 32, 32), content = rgb(25, 25, 25), border = rgb(58, 58, 58),
		borderStrong = rgb(80, 80, 80), accent = rgb(76, 194, 255), accentText = rgb(0, 0, 0),
		accentBg = rgb(0, 84, 140), accentHv = rgb(45, 45, 45), hover = rgb(52, 52, 52),
		text = rgb(240, 240, 240), textDim = rgb(165, 165, 165), textOff = rgb(100, 100, 100),
		folder = rgb(255, 202, 72), folderDk = rgb(222, 160, 30), page = rgb(235, 235, 235),
		pageEdge = rgb(150, 150, 150), danger = rgb(232, 17, 35), menu = rgb(44, 44, 44),
		input = rgb(45, 45, 45), editor = rgb(30, 30, 30), switchOff = rgb(160, 160, 160),
		link = rgb(120, 190, 255),
	},
}
local T = Settings.dark and THEMES.dark or THEMES.light
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
local function extOf(name)
	local _, ext = splitExt(name)
	return ext:sub(2):lower()
end
local function isInside(child, folder)
	return child == folder or child:sub(1, #folder + 1) == folder .. "/"
end

----------------------------------------------------------------- filesystem (safe wrappers)
local FS = {}
local sizeCache = {}
function FS.list(path)
	local ok, res = pcall(listfiles, path)
	if ok and type(res) == "table" then return res end
	return {}
end
function FS.isFolder(p) local ok, r = pcall(isfolder, p) return ok and r == true end
function FS.isFile(p) local ok, r = pcall(isfile, p) return ok and r == true end
function FS.exists(p) return FS.isFile(p) or FS.isFolder(p) end
function FS.read(p) local ok, r = pcall(readfile, p) if ok and type(r) == "string" then return r end return nil, tostring(r) end
function FS.write(p, s)
	sizeCache[p] = nil
	local ok, r = pcall(writefile, p, s)
	if ok then return true end
	return false, tostring(r)
end
function FS.mkdir(p) local ok, r = pcall(makefolder, p) if ok then return true end return false, tostring(r) end
function FS.children(folder, includeHidden)
	local out = {}
	for _, raw in FS.list(folder) do
		local nm = baseName(raw)
		if nm ~= "" and nm ~= ".folder" and (includeHidden or Settings.showHidden or nm:sub(1, 1) ~= ".") then
			table.insert(out, join(folder, nm))
		end
	end
	return out
end
function FS.size(p)
	if sizeCache[p] then return sizeCache[p] end
	local n
	if getfilesize then
		local ok, r = pcall(getfilesize, p)
		if ok and type(r) == "number" then n = r end
	end
	if not n then
		local d = FS.read(p)
		n = d and #d or nil
	end
	sizeCache[p] = n
	return n
end
function FS.remove(p)
	sizeCache[p] = nil
	if FS.isFolder(p) then
		for _, child in FS.children(p, true) do
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
		for _, child in FS.children(src, true) do
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

----------------------------------------------------------------- file kinds
local KIND = {
	txt = "text", md = "text", log = "text", cfg = "text", ini = "text", csv = "text", yml = "text", yaml = "text", toml = "text",
	lua = "code", luau = "code", js = "code", ts = "code", css = "code", xml = "code", py = "code",
	json = "json", html = "html", htm = "html",
	png = "image", jpg = "image", jpeg = "image", gif = "image", jxl = "image",
	mp3 = "audio", wav = "audio", ogg = "audio",
	mp4 = "video", m4v = "video", webm = "video", mov = "video", mkv = "video", avi = "video",
	ttf = "font", otf = "font", obj = "model", rbxm = "roblox", rbxmx = "roblox", iy = "iy",
	zip = "archive", rar = "archive", ["7z"] = "archive",
}
local KIND_COLOR = {
	text = rgb(100, 116, 139), code = rgb(124, 77, 255), json = rgb(217, 140, 6), html = rgb(234, 88, 12),
	image = rgb(22, 163, 74), audio = rgb(219, 39, 119), video = rgb(220, 38, 38), font = rgb(13, 148, 136),
	model = rgb(249, 115, 22), roblox = rgb(37, 99, 235), iy = rgb(14, 165, 233), archive = rgb(161, 98, 7),
	file = rgb(130, 130, 130),
}
local TYPE_NAME = {
	gif = "GIF Image", jxl = "JPEG XL Image", ttf = "TrueType Font", otf = "OpenType Font", obj = "3D Object",
	mov = "MOV Video", avi = "AVI Video", mkv = "MKV Video", txt = "Text Document", lua = "Lua Source File",
	luau = "Luau Source File", json = "JSON File", md = "Markdown File", png = "PNG Image", jpg = "JPEG Image",
	jpeg = "JPEG Image", mp3 = "MP3 Audio", ogg = "OGG Audio", wav = "WAV Audio", mp4 = "MP4 Video",
	webm = "WEBM Video", rbxm = "Roblox Model", rbxmx = "Roblox Model (XML)", html = "HTML Document",
	htm = "HTML Document", css = "CSS File", js = "JavaScript File", iy = "IY Settings", zip = "ZIP Archive",
}
local TEXT_EXT = {
	txt = true, lua = true, luau = true, json = true, md = true, html = true, htm = true, css = true, js = true,
	ts = true, py = true, iy = true, cfg = true, ini = true, log = true, xml = true, csv = true, yml = true,
	yaml = true, toml = true, rbxmx = true,
}
local MEDIA = {
	png = "image", gif = "image", jpg = "image", jpeg = "image", jxl = "image",
	mp3 = "audio", wav = "audio", ogg = "audio",
	mp4 = "video", m4v = "video", webm = "video", mov = "video", mkv = "video", avi = "video",
	ttf = "font", otf = "font", obj = "model",
}
local function kindOf(name, isDir)
	if isDir then return "folder" end
	return KIND[extOf(name)] or "file"
end
local function typeName(name, isDir)
	if isDir then return "File folder" end
	local ext = extOf(name)
	if ext == "" then return "File" end
	return TYPE_NAME[ext] or (ext:upper() .. " File")
end
local function mediaKind(name) return MEDIA[extOf(name)] end
local function isHtml(name) local e = extOf(name) return e == "html" or e == "htm" end
local function isTextFile(name)
	local ext = extOf(name)
	return ext == "" or TEXT_EXT[ext] == true
end
local function displayName(name, isDir)
	if isDir or Settings.showExt then return name end
	local stem = splitExt(name)
	return stem
end
local function fmtBytes(n)
	if not n then return "" end
	if n < 1024 then return n .. " bytes" end
	if n < 1024 * 1024 then return ("%.1f KB"):format(n / 1024) end
	return ("%.2f MB"):format(n / 1024 / 1024)
end
local function fmtTime(t)
	t = math.max(0, math.floor(tonumber(t) or 0))
	if t >= 3600 then return ("%d:%02d:%02d"):format(t // 3600, t // 60 % 60, t % 60) end
	return ("%d:%02d"):format(t // 60, t % 60)
end

----------------------------------------------------------------- tiny ui helpers
local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in props do i[k] = v end
	if parent then i.Parent = parent end
	return i
end
local function corner(inst, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, inst) end
local function stroke(inst, col, th)
	return new("UIStroke", { Color = col or T.border, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst)
end
local function pad(inst, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
	}, inst)
end
local function tween(inst, t, props)
	local tw = TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function ctrlDown() return UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) end
local function shiftDown() return UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) end
local function altDown() return UIS:IsKeyDown(Enum.KeyCode.LeftAlt) or UIS:IsKeyDown(Enum.KeyCode.RightAlt) end
local function pointIn(gui, x, y)
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y
end
local function mousePos()
	local m = UIS:GetMouseLocation()
	return m.X, m.Y
end

----------------------------------------------------------------- icon rasterizer (EditableImage)
-- Icons are drawn from a few shapes (rounded rects, strokes, lines, circles, arcs, triangles) with
-- 3x3 supersampling, written into an EditableImage once and cached. Nothing touches the drive.
-- If EditableImage isn't available, every icon falls back to plain frames / text.
local Raster = { ok = false, cache = {} }
local function toContent(img)
	local ok, c = pcall(function() return Content.fromObject(img) end)
	if ok and c then return c end
	if getrealinstance then
		local ok2, c2 = pcall(function() return Content.fromObject(getrealinstance(img)) end)
		if ok2 and c2 then return c2 end
	end
	return nil
end
do
	Raster.ok = pcall(function()
		local img = AssetService:CreateEditableImage({ Size = Vector2.new(4, 4) })
		local c = assert(toContent(img), "no content")
		local probe = Instance.new("ImageLabel")
		probe.ImageContent = c
		probe:Destroy()
	end)
end

local function compileShapes(list)
	local out = {}
	for _, s in list do
		local k = s[1]
		local c = s.c or Color3.new(1, 1, 1)
		local sh = { k = k, r = c.R, g = c.G, b = c.B, a = s.a or 1 }
		if k == "rect" or k == "srect" then
			local x, y, w, h, r = s[2], s[3], s[4], s[5], s[6] or 0
			sh.x0, sh.y0, sh.x1, sh.y1, sh.rr = x, y, x + w, y + h, math.min(r, w / 2, h / 2)
			if k == "srect" then
				local t = s[7] or 1.5
				sh.ix0, sh.iy0, sh.ix1, sh.iy1, sh.ir = x + t, y + t, x + w - t, y + h - t, math.max(0, sh.rr - t)
			end
			sh.bx0, sh.by0, sh.bx1, sh.by1 = sh.x0, sh.y0, sh.x1, sh.y1
		elseif k == "line" then
			local hw = (s[6] or 1.6) / 2
			sh.ax, sh.ay, sh.dx, sh.dy, sh.hw = s[2], s[3], s[4] - s[2], s[5] - s[3], hw
			sh.len2 = math.max(sh.dx * sh.dx + sh.dy * sh.dy, 1e-9)
			sh.bx0, sh.by0 = math.min(s[2], s[4]) - hw, math.min(s[3], s[5]) - hw
			sh.bx1, sh.by1 = math.max(s[2], s[4]) + hw, math.max(s[3], s[5]) + hw
		elseif k == "circle" then
			sh.cx, sh.cy, sh.rad = s[2], s[3], s[4]
			sh.bx0, sh.by0, sh.bx1, sh.by1 = s[2] - s[4], s[3] - s[4], s[2] + s[4], s[3] + s[4]
		elseif k == "ring" then
			local hw = (s[5] or 1.6) / 2
			sh.cx, sh.cy, sh.rad, sh.hw = s[2], s[3], s[4], hw
			sh.a0, sh.a1 = s[6], s[7]
			local R = s[4] + hw
			sh.bx0, sh.by0, sh.bx1, sh.by1 = s[2] - R, s[3] - R, s[2] + R, s[3] + R
		elseif k == "tri" then
			sh.p = { s[2], s[3], s[4], s[5], s[6], s[7] }
			sh.bx0, sh.by0 = math.min(s[2], s[4], s[6]), math.min(s[3], s[5], s[7])
			sh.bx1, sh.by1 = math.max(s[2], s[4], s[6]), math.max(s[3], s[5], s[7])
		end
		table.insert(out, sh)
	end
	return out
end

local function inRR(x, y, x0, y0, x1, y1, r)
	if x < x0 or x > x1 or y < y0 or y > y1 then return false end
	local dx, dy = 0, 0
	if x < x0 + r then dx = x0 + r - x elseif x > x1 - r then dx = x - (x1 - r) end
	if y < y0 + r then dy = y0 + r - y elseif y > y1 - r then dy = y - (y1 - r) end
	return dx * dx + dy * dy <= r * r
end
local function inside(s, x, y)
	local k = s.k
	if k == "rect" then
		return inRR(x, y, s.x0, s.y0, s.x1, s.y1, s.rr)
	elseif k == "srect" then
		return inRR(x, y, s.x0, s.y0, s.x1, s.y1, s.rr) and not inRR(x, y, s.ix0, s.iy0, s.ix1, s.iy1, s.ir)
	elseif k == "line" then
		local px, py = x - s.ax, y - s.ay
		local t = math.clamp((px * s.dx + py * s.dy) / s.len2, 0, 1)
		local qx, qy = px - s.dx * t, py - s.dy * t
		return qx * qx + qy * qy <= s.hw * s.hw
	elseif k == "circle" then
		local dx, dy = x - s.cx, y - s.cy
		return dx * dx + dy * dy <= s.rad * s.rad
	elseif k == "ring" then
		local dx, dy = x - s.cx, y - s.cy
		local d = math.sqrt(dx * dx + dy * dy)
		if math.abs(d - s.rad) > s.hw then return false end
		if s.a0 then
			local ang = math.deg(math.atan2(dy, dx)) % 360
			local a0, a1 = s.a0 % 360, s.a1
			local span = (a1 - s.a0) % 360
			if span == 0 then span = 360 end
			return (ang - a0) % 360 <= span
		end
		return true
	elseif k == "tri" then
		local p = s.p
		local d1 = (x - p[3]) * (p[2] - p[4]) - (p[1] - p[3]) * (y - p[4])
		local d2 = (x - p[5]) * (p[4] - p[6]) - (p[3] - p[5]) * (y - p[6])
		local d3 = (x - p[1]) * (p[6] - p[2]) - (p[5] - p[1]) * (y - p[2])
		local neg = d1 < 0 or d2 < 0 or d3 < 0
		local pos = d1 > 0 or d2 > 0 or d3 > 0
		return not (neg and pos)
	end
	return false
end

local SS = 3
local function rasterize(size, shapes, unit)
	local list = compileShapes(shapes)
	local scale = unit / size
	local buf = buffer.create(size * size * 4)
	local inv = 1 / (SS * SS)
	for py = 0, size - 1 do
		local y0, y1 = py * scale, (py + 1) * scale
		for px = 0, size - 1 do
			local x0, x1 = px * scale, (px + 1) * scale
			local r, g, b, a = 0, 0, 0, 0
			for _, s in list do
				if s.bx1 >= x0 and s.bx0 <= x1 and s.by1 >= y0 and s.by0 <= y1 then
					local cnt = 0
					for sy = 0, SS - 1 do
						local y = (py + (sy + 0.5) / SS) * scale
						for sx = 0, SS - 1 do
							if inside(s, (px + (sx + 0.5) / SS) * scale, y) then cnt += 1 end
						end
					end
					if cnt > 0 then
						local sa = cnt * inv * s.a
						local na = sa + a * (1 - sa)
						if na > 0 then
							r = (s.r * sa + r * a * (1 - sa)) / na
							g = (s.g * sa + g * a * (1 - sa)) / na
							b = (s.b * sa + b * a * (1 - sa)) / na
						end
						a = na
					end
				end
			end
			local o = (py * size + px) * 4
			buffer.writeu8(buf, o, math.floor(r * 255 + 0.5))
			buffer.writeu8(buf, o + 1, math.floor(g * 255 + 0.5))
			buffer.writeu8(buf, o + 2, math.floor(b * 255 + 0.5))
			buffer.writeu8(buf, o + 3, math.floor(a * 255 + 0.5))
		end
	end
	return buf
end
local function rasterContent(key, size, shapes, unit)
	if not Raster.ok then return nil end
	local cached = Raster.cache[key]
	if cached ~= nil then return cached or nil end
	local ok, content = pcall(function()
		local buf = rasterize(size, shapes, unit)
		local img = AssetService:CreateEditableImage({ Size = Vector2.new(size, size) })
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(size, size), buf)
		return { content = assert(toContent(img)), img = img }
	end)
	if ok then
		Raster.cache[key] = content
		return content
	end
	Raster.cache[key] = false
	return nil
end

----------------------------------------------------------------- glyphs (white, 24-unit grid, tinted with ImageColor3)
local function arcArrow(cw)
	if cw then
		return { { "ring", 12, 12, 7, 2, 300, 230 }, { "tri", 19.5, 3.5, 20.5, 10.5, 13.8, 8.2 } }
	end
	return { { "ring", 12, 12, 7, 2, 310, 240 }, { "tri", 4.5, 3.5, 3.5, 10.5, 10.2, 8.2 } }
end
local GLYPH = {
	close = { { "line", 6, 6, 18, 18, 1.5 }, { "line", 18, 6, 6, 18, 1.5 } },
	min = { { "line", 6, 12, 18, 12, 1.4 } },
	max = { { "srect", 6, 6, 12, 12, 1.5, 1.4 } },
	restore = { { "srect", 5.5, 8.5, 10, 10, 1.5, 1.3 }, { "line", 8.5, 5.5, 17, 5.5, 1.3 }, { "line", 18.5, 7, 18.5, 15.5, 1.3 }, { "line", 17, 5.5, 18.5, 7, 1.3 } },
	back = { { "line", 19, 12, 5.5, 12, 1.7 }, { "line", 5.5, 12, 11, 6.5, 1.7 }, { "line", 5.5, 12, 11, 17.5, 1.7 } },
	forward = { { "line", 5, 12, 18.5, 12, 1.7 }, { "line", 18.5, 12, 13, 6.5, 1.7 }, { "line", 18.5, 12, 13, 17.5, 1.7 } },
	up = { { "line", 12, 19, 12, 5.5, 1.7 }, { "line", 12, 5.5, 6.5, 11, 1.7 }, { "line", 12, 5.5, 17.5, 11, 1.7 } },
	refresh = arcArrow(true),
	search = { { "ring", 10, 10, 5.5, 1.8 }, { "line", 14.2, 14.2, 19.5, 19.5, 2.2 } },
	chevRight = { { "line", 9.5, 6, 15.5, 12, 1.7 }, { "line", 15.5, 12, 9.5, 18, 1.7 } },
	chevLeft = { { "line", 14.5, 6, 8.5, 12, 1.7 }, { "line", 8.5, 12, 14.5, 18, 1.7 } },
	chevUp = { { "line", 6, 14.5, 12, 8.5, 1.7 }, { "line", 12, 8.5, 18, 14.5, 1.7 } },
	chevDown = { { "line", 6, 9.5, 12, 15.5, 1.7 }, { "line", 12, 15.5, 18, 9.5, 1.7 } },
	check = { { "line", 5.5, 12.5, 10, 17, 2 }, { "line", 10, 17, 18.5, 7, 2 } },
	gear = (function()
		local t = { { "ring", 12, 12, 5, 3.2 } }
		for i = 0, 7 do
			local a = math.rad(i * 45)
			table.insert(t, { "line", 12 + math.cos(a) * 6, 12 + math.sin(a) * 6, 12 + math.cos(a) * 9, 12 + math.sin(a) * 9, 3.2 })
		end
		return t
	end)(),
	list = { { "line", 5, 7, 19, 7, 1.8 }, { "line", 5, 12, 19, 12, 1.8 }, { "line", 5, 17, 19, 17, 1.8 } },
	grid = { { "rect", 4.5, 4.5, 6.5, 6.5, 1.2 }, { "rect", 13, 4.5, 6.5, 6.5, 1.2 }, { "rect", 4.5, 13, 6.5, 6.5, 1.2 }, { "rect", 13, 13, 6.5, 6.5, 1.2 } },
	play = { { "tri", 7, 4.5, 7, 19.5, 19.5, 12 } },
	pause = { { "rect", 6.5, 5, 4, 14, 1 }, { "rect", 13.5, 5, 4, 14, 1 } },
	nextTrack = { { "tri", 5, 5, 5, 19, 15.5, 12 }, { "rect", 16, 5, 3, 14, 0.8 } },
	prevTrack = { { "tri", 19, 5, 19, 19, 8.5, 12 }, { "rect", 5, 5, 3, 14, 0.8 } },
	volume = { { "rect", 3.5, 9, 4.5, 6, 1 }, { "tri", 6, 12, 12, 5, 12, 19 }, { "ring", 12.5, 12, 4, 1.7, 315, 45 }, { "ring", 12.5, 12, 7.5, 1.7, 315, 45 } },
	volumeLow = { { "rect", 3.5, 9, 4.5, 6, 1 }, { "tri", 6, 12, 12, 5, 12, 19 }, { "ring", 12.5, 12, 4, 1.7, 315, 45 } },
	mute = { { "rect", 3.5, 9, 4.5, 6, 1 }, { "tri", 6, 12, 12, 5, 12, 19 }, { "line", 15, 9, 21, 15, 1.7 }, { "line", 21, 9, 15, 15, 1.7 } },
	loop = { { "srect", 4, 7, 16, 10, 4, 1.7 }, { "tri", 13, 4, 13, 10, 17, 7 } },
	shuffle = { { "line", 4, 7, 9, 7, 1.6 }, { "line", 9, 7, 15, 17, 1.6 }, { "line", 15, 17, 19, 17, 1.6 }, { "line", 4, 17, 9, 17, 1.6 }, { "line", 9, 17, 15, 7, 1.6 }, { "line", 15, 7, 19, 7, 1.6 }, { "tri", 18, 4.5, 18, 9.5, 21.5, 7 }, { "tri", 18, 14.5, 18, 19.5, 21.5, 17 } },
	theater = { { "srect", 3, 6, 18, 12, 1.5, 1.6 } },
	theaterOff = { { "srect", 5, 8, 14, 8, 1.5, 1.6 } },
	back10 = arcArrow(false),
	fwd10 = arcArrow(true),
	newFolder = { { "rect", 3, 6, 8, 4, 1.2 }, { "srect", 3, 8, 18, 11, 1.5, 1.5 }, { "line", 12, 10.5, 12, 16.5, 1.6 }, { "line", 9, 13.5, 15, 13.5, 1.6 } },
	newFile = { { "srect", 6, 3, 12, 18, 1.5, 1.5 }, { "line", 12, 8.5, 12, 15.5, 1.6 }, { "line", 8.5, 12, 15.5, 12, 1.6 } },
	cut = { { "ring", 7.5, 17, 2.8, 1.5 }, { "ring", 16.5, 17, 2.8, 1.5 }, { "line", 9.3, 14.8, 17, 4, 1.5 }, { "line", 14.7, 14.8, 7, 4, 1.5 } },
	copy = { { "srect", 8, 8, 11, 13, 1.5, 1.5 }, { "line", 5, 16, 5, 4.5, 1.5 }, { "line", 5, 4.5, 15, 4.5, 1.5 } },
	paste = { { "srect", 5, 5, 14, 16, 1.5, 1.5 }, { "rect", 9, 3, 6, 4, 1 } },
	rename = { { "srect", 3, 7, 18, 10, 1.5, 1.5 }, { "line", 7, 10, 7, 14, 1.5 } },
	trash = { { "line", 4.5, 6.5, 19.5, 6.5, 1.6 }, { "line", 9.5, 6.5, 10, 4, 1.4 }, { "line", 10, 4, 14, 4, 1.4 }, { "line", 14, 4, 14.5, 6.5, 1.4 }, { "srect", 6.5, 6.5, 11, 14, 1.5, 1.5 } },
	info = { { "ring", 12, 12, 8, 1.6 }, { "line", 12, 11, 12, 16.5, 1.8 }, { "circle", 12, 8, 1.2 } },
	sort = { { "line", 7, 5, 7, 19, 1.5 }, { "line", 7, 19, 4, 16, 1.5 }, { "line", 7, 19, 10, 16, 1.5 }, { "line", 17, 19, 17, 5, 1.5 }, { "line", 17, 5, 14, 8, 1.5 }, { "line", 17, 5, 20, 8, 1.5 } },
	eye = { { "ring", 12, 12, 3, 1.6 }, { "ring", 12, 22, 12, 1.5, 230, 310 }, { "ring", 12, 2, 12, 1.5, 50, 130 } },
	note = { { "circle", 8.5, 17.5, 3.2 }, { "line", 11.4, 17.5, 11.4, 4.5, 1.8 }, { "line", 11.4, 4.8, 18, 7, 2.4 }, { "line", 18, 7, 18, 10, 1.6 } },
	home = { { "line", 4, 11.5, 12, 4.5, 1.6 }, { "line", 12, 4.5, 20, 11.5, 1.6 }, { "srect", 6.5, 10, 11, 10, 1, 1.6 } },
}
local GLYPH_TEXT = {
	close = "X", min = "_", max = "[ ]", restore = "[]", back = "<", forward = ">", up = "^", refresh = "R",
	search = "", chevRight = ">", chevLeft = "<", chevUp = "^", chevDown = "v", check = "*", gear = "*",
	list = "=", grid = "#", play = ">", pause = "||", nextTrack = ">|", prevTrack = "|<", volume = "V",
	volumeLow = "v", mute = "M", loop = "L", shuffle = "S", theater = "[ ]", theaterOff = "[]", back10 = "-10",
	fwd10 = "+10", newFolder = "+", newFile = "+", cut = "", copy = "", paste = "", rename = "", trash = "",
	info = "i", sort = "", eye = "", home = "",
}
local function glyph(name, px, color, parent, pos)
	local size = math.clamp(math.floor(px * 2), 16, 96)
	local content = GLYPH[name] and rasterContent("g:" .. name .. ":" .. size, size, GLYPH[name], 24)
	local obj
	if content then
		obj = new("ImageLabel", {
			Size = UDim2.fromOffset(px, px), BackgroundTransparency = 1, ImageColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = pos or UDim2.fromScale(0.5, 0.5),
		})
		obj.ImageContent = content.content
	else
		obj = new("TextLabel", {
			Size = UDim2.fromOffset(px, px), BackgroundTransparency = 1, Text = GLYPH_TEXT[name] or "",
			Font = FONT_B, TextSize = math.max(10, math.floor(px * 0.7)), TextColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = pos or UDim2.fromScale(0.5, 0.5),
		})
	end
	if parent then obj.Parent = parent end
	return obj
end
local function tint(obj, color)
	if obj:IsA("ImageLabel") then obj.ImageColor3 = color else obj.TextColor3 = color end
end
local function setGlyph(obj, name)
	if obj:IsA("ImageLabel") then
		local px = obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.X or obj.Size.X.Offset
		local size = math.clamp(math.floor(px * 2), 16, 96)
		local content = GLYPH[name] and rasterContent("g:" .. name .. ":" .. size, size, GLYPH[name], 24)
		if content then obj.ImageContent = content.content end
	else
		obj.Text = GLYPH_TEXT[name] or ""
	end
end

----------------------------------------------------------------- file type icons (multicolor, 32-unit grid)
local function kindGlyphShapes(kind, C, P)
	if kind == "text" then
		return { { "line", 10, 8, 22, 8, 1.6, c = C }, { "line", 10, 12, 22, 12, 1.6, c = C }, { "line", 10, 16, 18, 16, 1.6, c = C } }
	elseif kind == "code" then
		return { { "line", 13, 8, 10, 12, 1.7, c = C }, { "line", 10, 12, 13, 16, 1.7, c = C }, { "line", 19, 8, 22, 12, 1.7, c = C }, { "line", 22, 12, 19, 16, 1.7, c = C }, { "line", 17.5, 7.5, 14.5, 16.5, 1.6, c = C } }
	elseif kind == "json" then
		local t = {}
		for _, side in { 1, -1 } do
			local function X(v) return side == 1 and v or 32 - v end
			for _, seg in { { 13.5, 7, 12, 8 }, { 12, 8, 12, 10.8 }, { 12, 10.8, 10.3, 12 }, { 10.3, 12, 12, 13.2 }, { 12, 13.2, 12, 16 }, { 12, 16, 13.5, 17 } } do
				table.insert(t, { "line", X(seg[1]), seg[2], X(seg[3]), seg[4], 1.5, c = C })
			end
		end
		return t
	elseif kind == "html" then
		return { { "ring", 16, 12, 5.5, 1.4, c = C }, { "line", 10.5, 12, 21.5, 12, 1.3, c = C }, { "line", 16, 6.5, 16, 17.5, 1.3, c = C }, { "ring", 16, 12, 2.6, 1.2, c = C, a = 0.8 } }
	elseif kind == "image" then
		return { { "circle", 20.5, 8.5, 1.9, c = rgb(245, 179, 1) }, { "tri", 8.5, 17.5, 13.8, 9.5, 19, 17.5, c = C }, { "tri", 14.5, 17.5, 18.6, 12, 23.5, 17.5, c = C } }
	elseif kind == "audio" then
		return { { "circle", 12, 15.5, 2.4, c = C }, { "circle", 20, 14, 2.4, c = C }, { "line", 14.2, 15.5, 14.2, 7.5, 1.5, c = C }, { "line", 22.2, 14, 22.2, 6.5, 1.5, c = C }, { "line", 14.2, 7.5, 22.2, 6.5, 2.2, c = C } }
	elseif kind == "video" then
		return { { "rect", 9, 6.5, 14, 11, 2.2, c = C }, { "tri", 14, 8.8, 14, 14.2, 18.6, 11.5, c = P } }
	elseif kind == "font" then
		return { { "line", 11, 17, 16, 6.5, 2, c = C }, { "line", 16, 6.5, 21, 17, 2, c = C }, { "line", 13, 13.5, 19, 13.5, 1.6, c = C } }
	elseif kind == "model" then
		local t = {}
		for _, seg in { { 16, 6, 22, 9 }, { 22, 9, 16, 12 }, { 16, 12, 10, 9 }, { 10, 9, 16, 6 }, { 10, 9, 10, 15 }, { 22, 9, 22, 15 }, { 16, 12, 16, 18 }, { 10, 15, 16, 18 }, { 16, 18, 22, 15 } } do
			table.insert(t, { "line", seg[1], seg[2], seg[3], seg[4], 1.4, c = C })
		end
		return t
	elseif kind == "roblox" then
		local t, pts = {}, {}
		local a0 = math.rad(16)
		for i = 0, 3 do
			local a = a0 + i * math.pi / 2 + math.pi / 4
			pts[i + 1] = { 16 + math.cos(a) * 6.6, 12 + math.sin(a) * 6.6 }
		end
		table.insert(t, { "tri", pts[1][1], pts[1][2], pts[2][1], pts[2][2], pts[3][1], pts[3][2], c = C })
		table.insert(t, { "tri", pts[1][1], pts[1][2], pts[3][1], pts[3][2], pts[4][1], pts[4][2], c = C })
		table.insert(t, { "rect", 14.8, 10.8, 2.4, 2.4, 0.3, c = P })
		return t
	elseif kind == "iy" then
		return { { "ring", 12.8, 12, 3.1, 1.6, c = C }, { "ring", 19.2, 12, 3.1, 1.6, c = C } }
	elseif kind == "archive" then
		return { { "rect", 14.5, 5, 2.5, 2, 0.4, c = C }, { "rect", 17, 7, 2.5, 2, 0.4, c = C }, { "rect", 14.5, 9, 2.5, 2, 0.4, c = C }, { "rect", 17, 11, 2.5, 2, 0.4, c = C }, { "rect", 14.8, 13.5, 4.4, 4.5, 1, c = C } }
	end
	return {}
end
local function iconShapes(kind)
	if kind == "folder" then
		return {
			{ "rect", 2, 5.5, 12, 7, 2, c = T.folderDk },
			{ "rect", 2, 8.5, 28, 19.5, 2.5, c = T.folderDk },
			{ "rect", 2, 11, 28, 17, 2.5, c = T.folder },
		}
	end
	local C = KIND_COLOR[kind] or KIND_COLOR.file
	local P = T.page
	local t = {
		{ "rect", 5, 1.5, 22, 29, 3, c = T.pageEdge },
		{ "rect", 6, 2.5, 20, 27, 2.2, c = P },
		{ "rect", 6, 21, 20, 8.5, 2.2, c = C },
		{ "rect", 6, 21, 20, 3, 0, c = C },
	}
	for _, s in kindGlyphShapes(kind, C, P) do table.insert(t, s) end
	return t
end
local function fallbackIcon(holder, kind, px)
	local s = px / 32
	if kind == "folder" then
		local f = new("Frame", { Size = UDim2.fromOffset(26 * s, 18 * s), Position = UDim2.fromOffset(3 * s, 9 * s), BackgroundColor3 = T.folder, BorderSizePixel = 0 }, holder)
		corner(f, 3)
		new("Frame", { Size = UDim2.fromOffset(11 * s, 5 * s), Position = UDim2.fromOffset(0, -3 * s), BackgroundColor3 = T.folderDk, BorderSizePixel = 0 }, f)
		return
	end
	local C = KIND_COLOR[kind] or KIND_COLOR.file
	local f = new("Frame", { Size = UDim2.fromOffset(20 * s, 27 * s), Position = UDim2.fromOffset(6 * s, 2.5 * s), BackgroundColor3 = T.page, BorderSizePixel = 0 }, holder)
	corner(f, 3) stroke(f, T.pageEdge, 1)
	new("Frame", { Size = UDim2.new(1, 0, 0, 8 * s), Position = UDim2.new(0, 0, 1, -8 * s), BackgroundColor3 = C, BorderSizePixel = 0 }, f)
end
-- a px x px holder with the icon for this item; large icons also print the extension in the band
local function typeIcon(name, isDir, px)
	local holder = new("Frame", { Size = UDim2.fromOffset(px, px), BackgroundTransparency = 1 })
	local kind = kindOf(name, isDir)
	local size = math.clamp(math.floor(px * 2), 32, 128)
	local content = rasterContent(("i:%s:%d:%s"):format(kind, size, Settings.dark and "d" or "l"), size, iconShapes(kind), 32)
	if content then
		local img = new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, holder)
		img.ImageContent = content.content
	else
		fallbackIcon(holder, kind, px)
	end
	if not isDir and px >= 40 then
		local ext = extOf(name)
		if ext ~= "" then
			new("TextLabel", {
				Size = UDim2.new(20 / 32, 0, 8 / 32, 0), Position = UDim2.fromScale(6 / 32, 21 / 32), BackgroundTransparency = 1,
				Text = ext:upper():sub(1, 4), Font = FONT_B, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 3,
			}, holder)
		end
	end
	return holder
end

----------------------------------------------------------------- HTML -> rich text blocks
local ENT = {
	amp = "&", lt = "<", gt = ">", quot = '"', apos = "'", nbsp = " ", copy = "©", reg = "®", trade = "™",
	mdash = "—", ndash = "–", hellip = "…", bull = "•", middot = "·", laquo = "«", raquo = "»", deg = "°",
	times = "×", larr = "←", rarr = "→", hearts = "♥",
}
local function decodeEntities(s)
	return (s:gsub("&(#?)([xX]?)(%w+);", function(hash, hex, body)
		if hash == "#" then
			local n = tonumber(body, hex ~= "" and 16 or 10)
			if n then
				local ok, ch = pcall(utf8.char, n)
				if ok then return ch end
			end
			return nil
		end
		return ENT[(hex .. body):lower()]
	end))
end
local function escRich(s)
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end
local function ci(word)
	return (word:gsub("%a", function(c) return "[" .. c:lower() .. c:upper() .. "]" end))
end
local function attr(attrs, name)
	return attrs:match(name .. '%s*=%s*"([^"]*)"') or attrs:match(name .. "%s*=%s*'([^']*)'") or attrs:match(name .. "%s*=%s*([^%s>]+)")
end
local INLINE = {
	b = { "<b>", "</b>" }, strong = { "<b>", "</b>" }, i = { "<i>", "</i>" }, em = { "<i>", "</i>" },
	u = { "<u>", "</u>" }, ins = { "<u>", "</u>" }, s = { "<s>", "</s>" }, del = { "<s>", "</s>" },
	strike = { "<s>", "</s>" }, small = { '<font size="12">', "</font>" }, mark = { '<mark color="#ffe066" transparency="0.3">', "</mark>" },
	code = { '<font face="RobotoMono">', "</font>" }, kbd = { '<font face="RobotoMono">', "</font>" },
	span = { "", "" }, sub = { "", "" }, sup = { "", "" }, label = { "", "" }, abbr = { "", "" },
}
local BLOCK = {
	p = true, div = true, section = true, article = true, header = true, footer = true, main = true, nav = true,
	aside = true, figure = true, figcaption = true, table = true, tr = true, form = true, center = true, dl = true,
	dt = true, dd = true, address = true, details = true, summary = true, thead = true, tbody = true,
}
local HEAD_SIZE = { 30, 24, 20, 17, 15, 14 }
local function parseHtml(src, linkColor)
	local title = src:match("<" .. ci("title") .. "[^>]*>(.-)</") or nil
	src = src:gsub("<!%-%-.-%-%->", ""):gsub("<!%a[^>]*>", "")
	for _, tag in { "script", "style", "head", "noscript", "template", "svg" } do
		src = src:gsub("<" .. ci(tag) .. "[^>]*>.-</" .. ci(tag) .. "%s*>", "")
	end
	local blocks, lists, stack = {}, {}, {}
	local cur, pre, quote = nil, false, 0
	local function newBlock(props)
		cur = props or { kind = "p" }
		cur.parts = {}
		for _, t in stack do table.insert(cur.parts, t.open) end
		cur.hasText = false
		cur.indent = (cur.indent or 0) + quote * 18
		cur.quote = quote > 0
	end
	local function flush()
		if cur and cur.hasText then
			for i = #stack, 1, -1 do table.insert(cur.parts, stack[i].close) end
			cur.text = table.concat(cur.parts):gsub("^%s+", ""):gsub("%s+$", "")
			table.insert(blocks, cur)
		end
		newBlock()
	end
	local function addText(t)
		if t == "" then return end
		if not pre then
			t = t:gsub("%s+", " ")
			if not cur.hasText then t = t:gsub("^ ", "") end
			if t == "" then return end
		end
		t = escRich(decodeEntities(t))
		table.insert(cur.parts, t)
		cur.hasText = true
	end
	newBlock()
	local pos = 1
	while pos <= #src do
		local s, e, slash, name, attrs = src:find("<(/?)([%w]+)([^>]*)>", pos)
		if not s then addText(src:sub(pos)) break end
		addText(src:sub(pos, s - 1))
		pos = e + 1
		name = name:lower()
		local closing = slash == "/"
		local h = name:match("^h([1-6])$")
		if h then
			if closing then flush() else flush() newBlock({ kind = "h", size = HEAD_SIZE[tonumber(h)] }) end
		elseif BLOCK[name] then
			flush()
		elseif name == "br" then
			table.insert(cur.parts, "\n")
		elseif name == "hr" then
			flush()
			table.insert(blocks, { kind = "hr" })
		elseif name == "ul" or name == "ol" then
			flush()
			if closing then table.remove(lists) else table.insert(lists, { ordered = name == "ol", n = 0 }) end
		elseif name == "li" then
			flush()
			if not closing then
				local l = lists[#lists]
				local bullet = "•"
				if l then
					l.n += 1
					if l.ordered then bullet = l.n .. "." end
				end
				newBlock({ kind = "li", indent = math.max(1, #lists) * 18, bullet = bullet })
			end
		elseif name == "blockquote" then
			flush()
			quote = math.max(0, quote + (closing and -1 or 1))
			newBlock()
		elseif name == "pre" then
			flush()
			pre = not closing
			if pre then newBlock({ kind = "pre", mono = true }) end
		elseif name == "td" or name == "th" then
			if not closing and cur.hasText then table.insert(cur.parts, "    ") end
			if name == "th" then
				if closing then table.insert(cur.parts, "</b>") else table.insert(cur.parts, "<b>") end
			end
		elseif name == "img" then
			flush()
			table.insert(blocks, { kind = "img", src = attr(attrs, "src"), alt = attr(attrs, "alt") })
		elseif name == "a" or INLINE[name] then
			local open, close
			if name == "a" then
				open, close = ('<font color="#%s"><u>'):format(linkColor:ToHex()), "</u></font>"
			else
				open, close = INLINE[name][1], INLINE[name][2]
			end
			if closing then
				for i = #stack, 1, -1 do
					if stack[i].name == name then
						for j = #stack, i, -1 do table.insert(cur.parts, stack[j].close) end
						local reopen = {}
						for j = i + 1, #stack do table.insert(reopen, stack[j]) end
						for j = #stack, i, -1 do stack[j] = nil end
						for _, t in reopen do
							table.insert(stack, t)
							table.insert(cur.parts, t.open)
						end
						break
					end
				end
			elseif not attrs:match("/%s*$") then
				table.insert(stack, { name = name, open = open, close = close })
				table.insert(cur.parts, open)
			end
		end
	end
	flush()
	return blocks, title and decodeEntities(title)
end

----------------------------------------------------------------- the explorer
local SPEEDS = { 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2 }
local PITCHES = { 0.5, 0.75, 1, 1.25, 1.5, 2 }
local build

build = function(carry)
	carry = carry or {}
	T = Settings.dark and THEMES.dark or THEMES.light
	local conns = {}
	local function track(c) table.insert(conns, c) return c end

	local gui = new("ScreenGui", { Name = "kAPI_FileExplorer", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 50 })
	gui.Parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
	gui.Destroying:Connect(function()
		for _, c in conns do pcall(function() c:Disconnect() end) end
	end)

	local window = new("Frame", {
		Size = carry.size or UDim2.fromOffset(980, 620), Position = carry.pos or UDim2.new(0.5, -490, 0.5, -310),
		BackgroundColor3 = T.window, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
	}, gui)
	corner(window, 8) stroke(window, T.borderStrong, 1)

	local function mouseLocal()
		local x, y = mousePos()
		return x - window.AbsolutePosition.X, y - window.AbsolutePosition.Y
	end

	----------------------------------------------------------------- state
	local state = {
		current = "", history = carry.history or {}, idx = carry.idx or 0,
		records = {}, selected = {}, anchor = nil,
		clipboard = carry.clipboard,
		focused = true, busy = false, modalCount = 0, suppressSearch = false,
		suppressClick = 0, keyGuard = 0, renameToken = 0, renaming = false,
		typeBuffer = "", typeTime = 0,
	}
	local render, setStatus, refreshVisuals, startRename, confirmDelete, openEditor, showProperties, openPreview, openHtml, openSettings
	local closeMenu, openMenu, rebuildSidebar, highlightSidebar, buildCrumbs

	----------------------------------------------------------------- title bar
	local titlebar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.titlebar, BorderSizePixel = 0 }, window)
	local titleIcon = typeIcon("", true, 18)
	titleIcon.Position = UDim2.fromOffset(14, 11)
	titleIcon.Parent = titlebar
	local titleText = new("TextLabel", {
		Size = UDim2.new(1, -200, 1, 0), Position = UDim2.fromOffset(42, 0),
		BackgroundTransparency = 1, Font = FONT, Text = "File Explorer", TextColor3 = T.text,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, titlebar)
	local function titleButton(gname, xoff, hoverCol, hoverGlyph)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(46, 40), Position = UDim2.new(1, xoff, 0, 0),
			BackgroundTransparency = 1, BackgroundColor3 = T.hover, Text = "", AutoButtonColor = false,
		}, titlebar)
		local g = glyph(gname, 16, T.text, b)
		b.MouseEnter:Connect(function()
			b.BackgroundTransparency = 0
			b.BackgroundColor3 = hoverCol or T.hover
			if hoverGlyph then tint(g, hoverGlyph) end
		end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 tint(g, T.text) end)
		return b, g
	end
	local minBtn = titleButton("min", -138)
	local maxBtn, maxGlyph = titleButton("max", -92)
	local closeBtn = titleButton("close", -46, rgb(196, 43, 28), Color3.new(1, 1, 1))

	----------------------------------------------------------------- toolbar row: nav + breadcrumb + search
	local toolbar = new("Frame", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 40), BackgroundColor3 = T.toolbar, BorderSizePixel = 0 }, window)
	local function iconButton(parent, gname, x, y, cb, size)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(size or 32, size or 32), Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		}, parent)
		corner(b, 5)
		local g = glyph(gname, 16, T.text, b)
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.MouseButton1Click:Connect(cb)
		return b, g
	end
	local function goBack() if state.idx > 1 then state.idx -= 1 render(state.history[state.idx], true) end end
	local function goForward() if state.idx < #state.history then state.idx += 1 render(state.history[state.idx], true) end end
	local function goUp() if state.current ~= "" then render(parentOf(state.current)) end end
	local _, backGlyph = iconButton(toolbar, "back", 8, 6, goBack)
	local _, fwdGlyph = iconButton(toolbar, "forward", 42, 6, goForward)
	local _, upGlyph = iconButton(toolbar, "up", 76, 6, goUp)
	iconButton(toolbar, "refresh", 110, 6, function() sizeCache = {} render(state.current, true, true) end)

	local addrFrame = new("Frame", { Size = UDim2.new(1, -400, 0, 32), Position = UDim2.fromOffset(150, 6), BackgroundColor3 = T.input, BorderSizePixel = 0, ClipsDescendants = true }, toolbar)
	corner(addrFrame, 5) stroke(addrFrame, T.border, 1)
	local addrHit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, addrFrame)
	local crumbs = new("Frame", { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0), BackgroundTransparency = 1 }, addrFrame)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, crumbs)
	local addrBox = new("TextBox", {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
		Font = FONT, Text = "", PlaceholderText = "Path", TextColor3 = T.text, PlaceholderColor3 = T.textDim, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Visible = false,
	}, addrFrame)
	local crumbButtons = {}
	local function editAddress()
		crumbs.Visible = false
		addrBox.Visible = true
		addrBox.Text = state.current == "" and "Workspace" or state.current
		addrBox:CaptureFocus()
		addrBox.SelectionStart = 1
		addrBox.CursorPosition = #addrBox.Text + 1
	end
	addrHit.MouseButton1Click:Connect(editAddress)
	addrBox.FocusLost:Connect(function(enter)
		state.keyGuard = os.clock() + 0.3
		addrBox.Visible = false
		crumbs.Visible = true
		if not enter then return end
		local p = addrBox.Text
		if p:lower() == "workspace" then p = "" end
		p = p:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "")
		if p == "" or FS.isFolder(p) then
			render(p)
		elseif FS.isFile(p) then
			openPreview(p)
		else
			setStatus("Can't find '" .. p .. "'. Check the spelling and try again.", true)
		end
	end)

	local searchFrame = new("Frame", { Size = UDim2.fromOffset(230, 32), Position = UDim2.new(1, -240, 0, 6), BackgroundColor3 = T.input, BorderSizePixel = 0 }, toolbar)
	corner(searchFrame, 5) stroke(searchFrame, T.border, 1)
	glyph("search", 14, T.textDim, searchFrame, UDim2.new(1, -16, 0.5, 0))
	local searchBox = new("TextBox", {
		Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
		Font = FONT, Text = "", PlaceholderText = "Search this folder", PlaceholderColor3 = T.textDim, TextColor3 = T.text, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
	}, searchFrame)
	searchBox.FocusLost:Connect(function() state.keyGuard = os.clock() + 0.3 end)

	----------------------------------------------------------------- command bar
	local cmdbar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 84), BackgroundColor3 = T.toolbar, BorderSizePixel = 0 }, window)
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, cmdbar)
	local cmdButtons = {}
	local function cmdButton(label, gname, x, w, cb, rightAligned)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(w, 32), Position = rightAligned and UDim2.new(1, x, 0, 4) or UDim2.fromOffset(x, 4),
			BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		}, cmdbar)
		corner(b, 5)
		local g = gname and glyph(gname, 16, T.text, b, UDim2.new(0, 18, 0.5, 0))
		local l = new("TextLabel", {
			Size = UDim2.new(1, gname and -32 or -12, 1, 0), Position = UDim2.fromOffset(gname and 30 or 6, 0), BackgroundTransparency = 1,
			Text = label, Font = FONT, TextSize = 12, TextColor3 = T.text, TextXAlignment = gname and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
		}, b)
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.MouseButton1Click:Connect(function() cb(b) end)
		cmdButtons[label] = { button = b, glyph = g, label = l }
		return b
	end
	local function separator(x)
		new("Frame", { Size = UDim2.fromOffset(1, 22), Position = UDim2.fromOffset(x, 9), BackgroundColor3 = T.border, BorderSizePixel = 0 }, cmdbar)
	end

	----------------------------------------------------------------- body: sidebar + content
	local BODY_TOP = 124
	local body = new("Frame", { Size = UDim2.new(1, 0, 1, -BODY_TOP - 26), Position = UDim2.fromOffset(0, BODY_TOP), BackgroundTransparency = 1 }, window)
	local sidebar = new("Frame", { Size = UDim2.new(0, 200, 1, 0), BackgroundColor3 = T.sidebar, BorderSizePixel = 0 }, body)
	new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.border, BorderSizePixel = 0 }, sidebar)
	local sideScroll = new("ScrollingFrame", {
		Size = UDim2.new(1, -1, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.borderStrong, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, sidebar)
	pad(sideScroll, 8, 8, 10, 8)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, sideScroll)

	local sideButtons = {}
	local function sideItem(label, path, order, indent, gname)
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.hover, BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, LayoutOrder = order,
		}, sideScroll)
		corner(b, 5)
		if gname then
			glyph(gname, 16, T.text, b, UDim2.fromOffset(18 + indent, 14))
		else
			local ic = typeIcon("", true, 18)
			ic.Position = UDim2.fromOffset(9 + indent, 5)
			ic.Parent = b
		end
		new("TextLabel", {
			Size = UDim2.new(1, -36 - indent, 1, 0), Position = UDim2.fromOffset(32 + indent, 0), BackgroundTransparency = 1,
			Text = label, Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, b)
		b.MouseEnter:Connect(function() if state.current ~= path then b.BackgroundTransparency = 0 b.BackgroundColor3 = T.hover end end)
		b.MouseLeave:Connect(function() if state.current ~= path then b.BackgroundTransparency = 1 end end)
		b.MouseButton1Click:Connect(function() render(path) end)
		sideButtons[path] = b
		return b
	end
	function rebuildSidebar()
		for _, c in sideScroll:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		sideButtons = {}
		new("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Quick access", Font = FONT_B, TextSize = 11, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 }, sideScroll)
		sideItem("Workspace", "", 1, 0, "home")
		local folders = {}
		for _, p in FS.children("") do
			if FS.isFolder(p) then table.insert(folders, p) end
		end
		table.sort(folders, function(a, b) return a:lower() < b:lower() end)
		for i, p in folders do sideItem(baseName(p), p, 1 + i, 12) end
	end
	function highlightSidebar()
		for path, b in sideButtons do
			if path == state.current then b.BackgroundTransparency = 0 b.BackgroundColor3 = T.accentBg else b.BackgroundTransparency = 1 end
		end
	end

	local contentWrap = new("Frame", { Size = UDim2.new(1, -200, 1, 0), Position = UDim2.fromOffset(200, 0), BackgroundColor3 = T.content, BorderSizePixel = 0, ClipsDescendants = true }, body)
	local header = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.content, BorderSizePixel = 0 }, contentWrap)
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, header)
	local scroll = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 30), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 8, ScrollBarImageColor3 = T.borderStrong,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Active = true,
	}, contentWrap)
	local listLayout

	-- columns: Name | Type | Size
	local COL_TYPE, COL_SIZE = 150, 100
	local function sizeColWidth() return Settings.showSize and COL_SIZE or 0 end
	local headerButtons = {}
	local function headerButton(label, key, pos, size, align)
		local b = new("TextButton", { Size = size, Position = pos, BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, header)
		local l = new("TextLabel", {
			Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(align == "right" and 0 or 8, 0), BackgroundTransparency = 1, Text = label, Font = FONT_B, TextSize = 12,
			TextColor3 = T.textDim, TextXAlignment = align == "right" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
		}, b)
		local arrow = glyph("chevUp", 10, T.textDim, b, UDim2.new(1, -10, 0.5, 0))
		arrow.Visible = false
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.MouseButton1Click:Connect(function()
			if Settings.sortKey == key then Settings.sortAsc = not Settings.sortAsc else Settings.sortKey, Settings.sortAsc = key, true end
			saveSettings()
			render(state.current, true, true)
		end)
		headerButtons[key] = { button = b, arrow = arrow, label = l }
	end
	local function layoutHeader()
		for _, h in headerButtons do h.button:Destroy() end
		headerButtons = {}
		local sw = sizeColWidth()
		headerButton("Name", "name", UDim2.fromOffset(36, 0), UDim2.new(1, -(36 + COL_TYPE + sw + 12), 1, -1))
		headerButton("Type", "type", UDim2.new(1, -(COL_TYPE + sw + 12), 0, 0), UDim2.new(0, COL_TYPE, 1, -1))
		if Settings.showSize then
			headerButton("Size", "size", UDim2.new(1, -(sw + 12), 0, 0), UDim2.new(0, sw, 1, -1), "right")
		end
		for key, h in headerButtons do
			h.arrow.Visible = Settings.sortKey == key
			setGlyph(h.arrow, Settings.sortAsc and "chevUp" or "chevDown")
		end
	end

	----------------------------------------------------------------- status bar
	local status = new("Frame", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 1, -26), BackgroundColor3 = T.window, BorderSizePixel = 0 }, window)
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, status)
	local statusLabel = new("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1,
		Text = "", Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, status)
	local viewButtons = {}
	for i, v in { { "details", "list" }, { "large", "grid" } } do
		local b = new("TextButton", {
			Size = UDim2.fromOffset(26, 20), Position = UDim2.new(1, -24 - (2 - i) * 30 - 30, 0.5, -10),
			BackgroundColor3 = T.accentBg, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		}, status)
		corner(b, 4)
		glyph(v[2], 14, T.text, b)
		b.MouseButton1Click:Connect(function()
			if Settings.view ~= v[1] then Settings.view = v[1] saveSettings() render(state.current, true, true) end
		end)
		viewButtons[v[1]] = b
	end
	-- resize grip
	local grip = new("TextButton", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, Text = "", ZIndex = 20, AutoButtonColor = false }, window)
	for i = 0, 2 do
		new("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(12 - i * 4, 12), BackgroundColor3 = T.textOff, BorderSizePixel = 0, ZIndex = 21 }, grip)
		if i < 2 then new("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(12, 8 - i * 4), BackgroundColor3 = T.textOff, BorderSizePixel = 0, ZIndex = 21 }, grip) end
	end
	new("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = T.textOff, BorderSizePixel = 0, ZIndex = 21 }, grip)

	local statusMsgToken, statusMsgActive = 0, false
	local function baseStatus()
		local n, sel = #state.records, 0
		for _ in state.selected do sel += 1 end
		local s = ("%d item%s"):format(n, n == 1 and "" or "s")
		if sel > 0 then
			s ..= ("   |   %d item%s selected"):format(sel, sel == 1 and "" or "s")
			local bytes, known = 0, true
			for _, rec in state.records do
				if state.selected[rec.path] and not rec.isDir then
					local sz = sizeCache[rec.path]
					if sz then bytes += sz else known = false end
				end
			end
			if known and bytes > 0 then s ..= "   " .. fmtBytes(bytes) end
		end
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
				if statusMsgToken == token and statusLabel.Parent then
					statusMsgActive = false
					statusLabel.TextColor3 = T.textDim
					statusLabel.Text = baseStatus()
				end
			end)
		end
	end

	----------------------------------------------------------------- modals
	local function modalShell(w, h, titleStr)
		state.modalCount += 1
		local shade = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 50, Text = "", AutoButtonColor = false }, window)
		local box = new("Frame", { Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2), BackgroundColor3 = T.content, BorderSizePixel = 0, ZIndex = 51, Active = true, ClipsDescendants = true }, shade)
		corner(box, 8) stroke(box, T.borderStrong, 1)
		local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.titlebar, BorderSizePixel = 0, ZIndex = 52 }, box)
		local title = new("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = titleStr, Font = FONT_B, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53, TextTruncate = Enum.TextTruncate.AtEnd }, bar)
		local x = new("TextButton", { Size = UDim2.fromOffset(46, 38), Position = UDim2.new(1, -46, 0, 0), BackgroundColor3 = rgb(196, 43, 28), BackgroundTransparency = 1, Text = "", ZIndex = 53, AutoButtonColor = false }, bar)
		local xg = glyph("close", 15, T.text, x)
		xg.ZIndex = 54
		x.MouseEnter:Connect(function() x.BackgroundTransparency = 0 tint(xg, Color3.new(1, 1, 1)) end)
		x.MouseLeave:Connect(function() x.BackgroundTransparency = 1 tint(xg, T.text) end)
		local closed = false
		local function close()
			if closed then return end
			closed = true
			state.modalCount -= 1
			shade:Destroy()
		end
		return shade, box, close, x, title, bar
	end
	local function dialogButton(parent, label, xFromRight, primary, cb, z)
		local b = new("TextButton", {
			Size = UDim2.fromOffset(96, 32), Position = UDim2.new(1, xFromRight, 1, -44),
			BackgroundColor3 = primary and T.accent or T.toolbar, Text = label, Font = FONT, TextSize = 13,
			TextColor3 = primary and T.accentText or T.text, AutoButtonColor = true, ZIndex = z or 53,
		}, parent)
		corner(b, 5)
		if not primary then stroke(b, T.border, 1) end
		b.MouseButton1Click:Connect(cb)
		return b
	end

	----------------------------------------------------------------- context menus
	local menuFrame
	function closeMenu()
		if menuFrame then menuFrame:Destroy() menuFrame = nil end
	end
	-- items: { label, cb, key, enabled, bold, checked, glyph } or "-"; at: optional {x, y} in window space
	function openMenu(items, at)
		closeMenu()
		local x, y
		if at then x, y = at[1], at[2] else x, y = mouseLocal() end
		local h = 8
		for _, it in items do h += (it == "-" and 9 or 30) end
		local w = 240
		if x + w > window.AbsoluteSize.X then x = math.max(0, x - w) end
		if y + h > window.AbsoluteSize.Y then y = math.max(0, y - h) end
		menuFrame = new("Frame", { Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y), BackgroundColor3 = T.menu, BorderSizePixel = 0, ZIndex = 100, Active = true }, window)
		corner(menuFrame, 8) stroke(menuFrame, T.borderStrong, 1)
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
				local col = enabled and T.text or T.textOff
				if it.checked then
					local g = glyph("check", 14, col, b, UDim2.fromOffset(16, 15))
					g.ZIndex = 102
				elseif it.glyph then
					local g = glyph(it.glyph, 15, col, b, UDim2.fromOffset(16, 15))
					g.ZIndex = 102
				end
				new("TextLabel", { Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(32, 0), BackgroundTransparency = 1, Text = it.label, Font = it.bold and FONT_B or FONT, TextSize = 13, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102 }, b)
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
	local function menuUnder(button, items)
		local p = button.AbsolutePosition - window.AbsolutePosition
		openMenu(items, { p.X, p.Y + button.AbsoluteSize.Y + 2 })
	end

	----------------------------------------------------------------- selection
	local function selectedPaths()
		local out = {}
		for _, rec in state.records do if state.selected[rec.path] then table.insert(out, rec.path) end end
		return out
	end
	local function recordFor(path)
		for i, rec in state.records do if rec.path == path then return rec, i end end
		return nil
	end
	local function isCut(path)
		local cb = state.clipboard
		if not cb or cb.mode ~= "cut" then return false end
		for _, p in cb.paths do if p == path then return true end end
		return false
	end
	local dropTarget -- GuiObject currently highlighted as a drop target
	local function paintRow(rec)
		do
			local sel = state.selected[rec.path]
			if rec.row == dropTarget then
				rec.row.BackgroundTransparency = 0
				rec.row.BackgroundColor3 = T.accentBg
			elseif sel then
				rec.row.BackgroundTransparency = 0
				rec.row.BackgroundColor3 = T.accentBg
			elseif rec.hover then
				rec.row.BackgroundTransparency = 0
				rec.row.BackgroundColor3 = T.accentHv
			else
				rec.row.BackgroundTransparency = 1
			end
			local cut = isCut(rec.path)
			if rec.cut ~= cut then
				rec.cut = cut
				rec.nameLabel.TextTransparency = cut and 0.5 or 0
				for _, d in rec.icon:GetDescendants() do
					if d:IsA("ImageLabel") then d.ImageTransparency = cut and 0.5 or 0 end
				end
			end
		end
	end
	function refreshVisuals()
		for _, rec in state.records do paintRow(rec) end
		local count = #selectedPaths()
		for _, label in { "Cut", "Copy", "Rename", "Delete" } do
			local c = cmdButtons[label]
			if c then
				local on = count > 0 and not (label == "Rename" and count ~= 1)
				c.label.TextColor3 = on and T.text or T.textOff
				if c.glyph then tint(c.glyph, on and T.text or T.textOff) end
			end
		end
		local pb = cmdButtons["Paste"]
		if pb then
			pb.label.TextColor3 = state.clipboard and T.text or T.textOff
			if pb.glyph then tint(pb.glyph, state.clipboard and T.text or T.textOff) end
		end
		for v, b in viewButtons do b.BackgroundTransparency = Settings.view == v and 0 or 1 end
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
		state.renameToken += 1
		if rec.isDir then render(rec.path) else openPreview(rec.path) end
	end
	-- copies or moves paths into dest; returns the new paths
	local function transfer(paths, dest, mode)
		local newPaths = {}
		for _, src in paths do
			if not FS.exists(src) then continue end
			if FS.isFolder(src) and isInside(dest, src) then
				error(("Can't put '%s' inside itself."):format(baseName(src)), 0)
			end
			local name = baseName(src)
			if mode == "move" and parentOf(src) == dest then
				table.insert(newPaths, src)
				continue
			end
			local finalName = FS.uniqueName(dest, name, mode == "copy" and parentOf(src) == dest)
			local dst = join(dest, finalName)
			local ok, err
			if mode == "move" then ok, err = FS.move(src, dst) else ok, err = FS.copy(src, dst) end
			if not ok then error(("Couldn't %s '%s': %s"):format(mode, name, tostring(err)), 0) end
			table.insert(newPaths, dst)
		end
		return newPaths
	end
	local function afterChange(newPaths)
		render(state.current, true, true)
		if newPaths then
			state.selected = {}
			for _, p in newPaths do state.selected[p] = true end
		end
		refreshVisuals()
		rebuildSidebar() highlightSidebar()
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
		runOp(cb.mode == "cut" and "Moving" or "Copying", function()
			local newPaths = transfer(cb.paths, state.current, cb.mode == "cut" and "move" or "copy")
			if cb.mode == "cut" then state.clipboard = nil end
			afterChange(newPaths)
			setStatus(("Pasted %d item%s"):format(#newPaths, #newPaths == 1 and "" or "s"))
		end)
	end
	local function doDuplicate()
		local paths = selectedPaths()
		if #paths == 0 then return end
		runOp("Duplicating", function()
			local newPaths = transfer(paths, state.current, "copy")
			afterChange(newPaths)
			setStatus(("Duplicated %d item%s"):format(#newPaths, #newPaths == 1 and "" or "s"))
		end)
	end
	local TEMPLATES = {
		{ label = "Text document", name = "New Text Document.txt", body = "" },
		{ label = "Lua script", name = "New Script.lua", body = 'print("Hello from kAPI")\n' },
		{ label = "JSON file", name = "New JSON.json", body = "{\n\t\n}\n" },
		{ label = "HTML page", name = "New Page.html", body = "<!DOCTYPE html>\n<html>\n<head><title>New page</title></head>\n<body>\n\t<h1>Hello</h1>\n\t<p>Edit me, then open me in the explorer.</p>\n</body>\n</html>\n" },
	}
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
	local function doNewFile(tpl)
		tpl = tpl or TEMPLATES[1]
		runOp("Creating file", function()
			local name = FS.uniqueName(state.current, tpl.name)
			local p = join(state.current, name)
			local ok, err = FS.write(p, tpl.body)
			if not ok then error("Couldn't create the file: " .. tostring(err), 0) end
			render(state.current, true, true)
			selectOnly(p)
			startRename(p)
		end)
	end
	local function newMenuItems()
		local items = {
			{ label = "Folder", glyph = "newFolder", key = "Ctrl+Shift+N", cb = doNewFolder },
			"-",
		}
		for _, tpl in TEMPLATES do
			table.insert(items, { label = tpl.label, glyph = "newFile", cb = function() doNewFile(tpl) end })
		end
		return items
	end
	local function copyPathToClipboard()
		local paths = selectedPaths()
		if #paths == 0 then paths = { state.current } end
		local text = table.concat(paths, "\n")
		local ok = pcall(function() (setclipboard or toclipboard)(text) end)
		setStatus(ok and "Path copied" or "Clipboard isn't available", not ok)
	end
	local function selectAll()
		for _, r in state.records do state.selected[r.path] = true end
		refreshVisuals()
	end
	local function invertSelection()
		local new = {}
		for _, r in state.records do if not state.selected[r.path] then new[r.path] = true end end
		state.selected = new
		refreshVisuals()
	end

	----------------------------------------------------------------- inline rename (F2 / slow second click)
	function startRename(path)
		local rec = recordFor(path)
		if not rec or state.renaming then return end
		state.renaming = true
		state.renameToken += 1
		local oldName = rec.name
		rec.nameLabel.Visible = false
		local large = Settings.view == "large"
		local box = new("TextBox", {
			Size = rec.nameLabel.Size, Position = rec.nameLabel.Position, BackgroundColor3 = T.input,
			Font = FONT, Text = oldName, TextColor3 = T.text, TextSize = 13,
			TextXAlignment = large and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
			TextWrapped = large, ClearTextOnFocus = false, ZIndex = 5,
		}, rec.nameLabel.Parent)
		corner(box, 3) stroke(box, T.accent, 1) pad(box, 4, 4, 0, 0)
		box:CaptureFocus()
		local stem = rec.isDir and oldName or (splitExt(oldName))
		box.CursorPosition = #stem + 1
		box.SelectionStart = 1

		local finished = false
		box.FocusLost:Connect(function(_, input)
			if finished then return end
			finished = true
			state.renaming = false
			-- the Enter that confirms the rename must not also open the item
			state.keyGuard = os.clock() + 0.35
			local cancelled = input and input.KeyCode == Enum.KeyCode.Escape
			local newName = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
			box:Destroy()
			rec.nameLabel.Visible = true
			if cancelled or newName == "" or newName == oldName then return end
			if newName:find(BAD_CHARS) then
				setStatus('A name can\'t contain any of these characters: \\ / : * ? " < > |', true)
				return
			end
			if not rec.isDir and not Settings.showExt then
				local _, oldExt = splitExt(oldName)
				local _, newExt = splitExt(newName)
				if newExt == "" and oldExt ~= "" then newName ..= oldExt end
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

	----------------------------------------------------------------- delete
	function confirmDelete(paths)
		if #paths == 0 then return end
		local function doDelete()
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
		end
		if not Settings.confirmDelete then doDelete() return end
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
		dialogButton(box, "Yes", -212, true, function() close() doDelete() end)
		dialogButton(box, "No", -108, false, close)
	end

	----------------------------------------------------------------- text editor
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
			dialogButton(box, "Open", -212, true, function() close() task.defer(openEditor, path, true) end)
			dialogButton(box, "Cancel", -108, false, close)
			return
		end
		local content, err = FS.read(path)
		local readOnly = content == nil or #content > 200000
		local shade, box, close, x, title = modalShell(760, 500, name)
		local dirty = false
		local function updateTitle() title.Text = (dirty and "*" or "") .. name .. (readOnly and "   (read-only)" or "") end
		updateTitle()
		local area = new("ScrollingFrame", {
			Size = UDim2.new(1, -20, 1, -100), Position = UDim2.fromOffset(10, 46), BackgroundColor3 = T.editor, BorderSizePixel = 0,
			ScrollBarThickness = 8, ScrollBarImageColor3 = T.borderStrong, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY, ZIndex = 52,
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
			Size = UDim2.new(1, -340, 0, 32), Position = UDim2.new(0, 14, 1, -44), BackgroundTransparency = 1,
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
		if isHtml(name) then
			dialogButton(box, "Preview", -316, false, function() openHtml(path, editor.Text) end)
		end
		x.MouseButton1Click:Connect(tryClose)
		local conn
		conn = UIS.InputBegan:Connect(function(input)
			if not shade.Parent then conn:Disconnect() return end
			if input.KeyCode == Enum.KeyCode.S and ctrlDown() then save() end
		end)
		track(conn)
	end

	----------------------------------------------------------------- HTML viewer
	function openHtml(path, sourceOverride)
		local name = baseName(path)
		local src = sourceOverride or FS.read(path)
		local _, box, close, x, title = modalShell(800, 540, name)
		x.MouseButton1Click:Connect(close)
		local page = new("ScrollingFrame", {
			Size = UDim2.new(1, -20, 1, -100), Position = UDim2.fromOffset(10, 46), BackgroundColor3 = T.editor, BorderSizePixel = 0,
			ScrollBarThickness = 8, ScrollBarImageColor3 = T.borderStrong, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 52,
		}, box)
		corner(page, 6) stroke(page, T.border, 1)
		pad(page, 28, 28, 20, 24)
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		dialogButton(box, "Close", -108, false, close)
		if not sourceOverride then
			dialogButton(box, "View source", -212, false, function() close() openEditor(path, true) end)
		end
		if not src then
			new("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Couldn't read this file.", Font = FONT, TextSize = 14, TextColor3 = T.danger, ZIndex = 53 }, page)
			return
		end
		local ok, blocks, pageTitle = pcall(parseHtml, src, T.link)
		if not ok then
			new("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Couldn't read this page: " .. tostring(blocks), Font = FONT, TextSize = 14, TextColor3 = T.danger, ZIndex = 53, TextWrapped = true }, page)
			return
		end
		if pageTitle and pageTitle ~= "" then title.Text = pageTitle .. "  —  " .. name end
		local folder = parentOf(path)
		for i, b in blocks do
			if b.kind == "hr" then
				new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.border, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 53 }, page)
			elseif b.kind == "img" then
				local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 220), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 53 }, page)
				local img = new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 53 }, holder)
				local srcPath = b.src and b.src:gsub("\\", "/") or nil
				local okImg = false
				if srcPath and not srcPath:match("^%a+://") and not srcPath:match("^data:") then
					local full = srcPath:sub(1, 1) == "/" and srcPath:sub(2) or join(folder, srcPath)
					okImg = pcall(function() img.Image = getcustomasset(full) end)
				end
				if not okImg then
					img:Destroy()
					holder.Size = UDim2.new(1, 0, 0, 24)
					new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "[image: " .. (b.alt or b.src or "?") .. "]", Font = FONT, TextSize = 13, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53 }, holder)
				end
			else
				local text = b.text
				if b.bullet then text = b.bullet .. "  " .. text end
				local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 53 }, page)
				if b.quote then
					new("Frame", { Size = UDim2.new(0, 3, 1, 0), Position = UDim2.fromOffset((b.indent or 0) - 12, 0), BackgroundColor3 = T.borderStrong, BorderSizePixel = 0, ZIndex = 53 }, holder)
				end
				local lbl = new("TextLabel", {
					Size = UDim2.new(1, -(b.indent or 0), 0, 0), Position = UDim2.fromOffset(b.indent or 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = b.kind == "pre" and 0 or 1, BackgroundColor3 = T.hover, BorderSizePixel = 0,
					RichText = true, Text = text, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = b.quote and T.textDim or T.text,
					Font = b.kind == "h" and Enum.Font.GothamBold or (b.mono and Enum.Font.RobotoMono or FONT),
					TextSize = b.size or (b.mono and 13 or 15), LineHeight = b.kind == "h" and 1 or 1.25, ZIndex = 53,
				}, holder)
				if b.kind == "pre" then corner(lbl, 4) pad(lbl, 10, 10, 8, 8) end
			end
		end
		if #blocks == 0 then
			new("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "This page is empty.", Font = FONT, TextSize = 14, TextColor3 = T.textDim, ZIndex = 53 }, page)
		end
	end

	----------------------------------------------------------------- media player (YouTube style, audio + video)
	local function openPlayer(startPath)
		local isVideo = mediaKind(baseName(startPath)) == "video"
		local mediaType = isVideo and "video" or "audio"
		local W, H = 900, 560
		local shade, box, close, x, title = modalShell(W, H, "Media Player")
		x.MouseButton1Click:Connect(close)
		box.BackgroundColor3 = rgb(15, 15, 15)

		local alive = true
		local connections, cleanup = {}, {}
		shade.Destroying:Connect(function()
			alive = false
			for _, c in connections do pcall(function() c:Disconnect() end) end
			for _, f in cleanup do pcall(f) end
		end)
		local function on(signal, fn) local c = signal:Connect(fn) table.insert(connections, c) return c end

		local screen = new("Frame", {
			Size = UDim2.new(1, -16, 1, -46), Position = UDim2.fromOffset(8, 40),
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 52,
		}, box)
		corner(screen, 8)

		-- audio backdrop: tinted gradient, album art, title, visualizer
		local backdrop, art, artGradient, bigTitle, bigSub, vis
		local bars, heights, BARS = {}, {}, 56
		if not isVideo then
			backdrop = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 52 }, screen)
			local bdGrad = new("UIGradient", { Rotation = 35, Color = ColorSequence.new(rgb(30, 26, 46), rgb(12, 16, 28)) }, backdrop)
			art = new("Frame", { Size = UDim2.fromOffset(190, 190), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.42, -20), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 53 }, screen)
			corner(art, 12)
			artGradient = new("UIGradient", { Rotation = 45, Color = ColorSequence.new(rgb(170, 120, 255), rgb(118, 185, 255)) }, art)
			local note = glyph("note", 90, Color3.new(1, 1, 1), art)
			note.ZIndex = 54
			tint(note, Color3.new(1, 1, 1))
			if note:IsA("ImageLabel") then note.ImageTransparency = 0.15 end
			bigTitle = new("TextLabel", { Size = UDim2.new(1, -80, 0, 30), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 90), BackgroundTransparency = 1, Text = "", Font = FONT_B, TextSize = 22, TextColor3 = Color3.new(1, 1, 1), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 53 }, screen)
			bigSub = new("TextLabel", { Size = UDim2.new(1, -80, 0, 20), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.42, 122), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 13, TextColor3 = rgb(180, 182, 196), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 53 }, screen)
			vis = new("Frame", { Size = UDim2.new(1, -24, 0, 90), Position = UDim2.new(0, 12, 1, -96), BackgroundTransparency = 1, ZIndex = 53 }, screen)
			for i = 1, BARS do
				local b = new("Frame", {
					Size = UDim2.new(1 / BARS, -3, 0, 2), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / BARS, 0, 1, 0),
					BackgroundColor3 = rgb(118, 185, 255):Lerp(rgb(170, 120, 255), i / BARS), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 53,
				}, vis)
				corner(b, 2)
				bars[i], heights[i] = b, 0
			end
			table.insert(cleanup, function() bdGrad:Destroy() end)
		end
		local loading = new("TextLabel", { Size = UDim2.new(1, -40, 0, 60), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Text = "Loading...", Font = FONT, TextSize = 15, TextColor3 = rgb(220, 220, 220), TextWrapped = true, ZIndex = 58 }, screen)

		-- click area (single click = play/pause, double click = theater)
		local clickArea = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 57 }, screen)

		-- overlay with the controls; fades in when the mouse moves over the screen
		local ui = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60, GroupTransparency = 0 }, screen)
		local topShade = new("Frame", { Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 60 }, ui)
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.35, 1) }, topShade)
		local botShade = new("Frame", { Size = UDim2.new(1, 0, 0, 130), Position = UDim2.new(0, 0, 1, -130), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 60 }, ui)
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.2) }, botShade)
		local overTitle = new("TextLabel", { Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(18, 12), BackgroundTransparency = 1, Text = "", Font = FONT_B, TextSize = 17, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 61 }, ui)

		local RED = rgb(255, 0, 51)
		-- progress bar
		local prog = new("TextButton", { Size = UDim2.new(1, -24, 0, 16), Position = UDim2.new(0, 12, 1, -62), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 62 }, ui)
		local rail = new("Frame", { Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.65, BorderSizePixel = 0, ZIndex = 62 }, prog)
		local hoverFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 63, Visible = false }, rail)
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = RED, BorderSizePixel = 0, ZIndex = 64 }, rail)
		local knob = new("Frame", { Size = UDim2.fromOffset(13, 13), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = RED, BorderSizePixel = 0, ZIndex = 65, Visible = false }, rail)
		corner(knob, 7)
		local tip = new("TextLabel", { Size = UDim2.fromOffset(60, 22), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 0, 0, -6), BackgroundColor3 = rgb(28, 28, 28), BackgroundTransparency = 0.1, Text = "0:00", Font = FONT_B, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), ZIndex = 66, Visible = false }, prog)
		corner(tip, 4)

		-- controls row
		local row = new("Frame", { Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 1, -50), BackgroundTransparency = 1, ZIndex = 62 }, ui)
		local function ctl(gname, xpos, anchorRight, size)
			local b = new("TextButton", {
				Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(anchorRight and 1 or 0, 0.5),
				Position = anchorRight and UDim2.new(1, -xpos, 0.5, 0) or UDim2.new(0, xpos, 0.5, 0),
				BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 63,
			}, row)
			local g = glyph(gname, size or 22, Color3.new(1, 1, 1), b)
			g.ZIndex = 64
			b.MouseEnter:Connect(function() tint(g, rgb(255, 255, 255)) g.Size = UDim2.fromOffset((size or 22) + 2, (size or 22) + 2) end)
			b.MouseLeave:Connect(function() g.Size = UDim2.fromOffset(size or 22, size or 22) end)
			return b, g
		end
		local prevBtn = ctl("prevTrack", 0, false, 18)
		local playBtn, playGlyph = ctl("play", 40, false, 24)
		local nextBtn = ctl("nextTrack", 80, false, 18)
		local volBtn, volGlyph = ctl("volume", 120, false, 22)
		local volWrap = new("Frame", { Size = UDim2.fromOffset(0, 40), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 160, 0.5, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 63 }, row)
		local volRail = new("TextButton", { Size = UDim2.fromOffset(64, 20), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 63 }, volWrap)
		local volTrack = new("Frame", { Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 63 }, volRail)
		local volFill = new("Frame", { Size = UDim2.fromScale(0.6, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 64 }, volTrack)
		local volKnob = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.6, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 65 }, volTrack)
		corner(volKnob, 6)
		local timeLabel = new("TextLabel", { Size = UDim2.fromOffset(150, 40), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 166, 0.5, 0), BackgroundTransparency = 1, Text = "0:00 / 0:00", Font = FONT, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63 }, row)
		local theaterBtn, theaterGlyph = ctl("theater", 0, true, 22)
		local gearBtn, gearGlyph = ctl("gear", 40, true, 20)
		local loopBtn, loopGlyph = ctl("loop", 80, true, 20)
		local shuffleBtn, shuffleGlyph = ctl("shuffle", 120, true, 20)
		local queueLabel = new("TextLabel", { Size = UDim2.fromOffset(160, 40), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -166, 0.5, 0), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 12, TextColor3 = rgb(200, 200, 200), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 63 }, row)

		-- big center flash on play / pause
		local flash = new("Frame", { Size = UDim2.fromOffset(68, 68), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 70 }, screen)
		corner(flash, 34)
		local flashGlyph = glyph("play", 30, Color3.new(1, 1, 1), flash)
		flashGlyph.ZIndex = 71
		local function setFlashT(t)
			flash.BackgroundTransparency = 0.4 + 0.6 * t
			if flashGlyph:IsA("ImageLabel") then flashGlyph.ImageTransparency = t else flashGlyph.TextTransparency = t end
		end
		setFlashT(1)
		local flashToken = 0
		local function flashIcon(gname)
			flashToken += 1
			local mine = flashToken
			setGlyph(flashGlyph, gname)
			flash.Size = UDim2.fromOffset(60, 60)
			setFlashT(0)
			task.spawn(function()
				local t0 = os.clock()
				while alive and mine == flashToken do
					local k = math.min(1, (os.clock() - t0) / 0.5)
					setFlashT(k)
					flash.Size = UDim2.fromOffset(60 + 24 * k, 60 + 24 * k)
					if k >= 1 then break end
					task.wait()
				end
			end)
		end

		----------------------------------------------------------------- player state
		local sound, shifter
		local queue, index = {}, 1
		local looped, shuffle, muted = false, false, false
		local volume, speed, pitch = 0.6, 1, 1
		local wantPlaying, lastPos, endedAt = false, 0, nil
		local generation = 0
		local seeking, seekFrac = false, 0
		local theater = false
		local settingsOpen, settingsFrame = false, nil
		local lastMove, lastMouse = os.clock(), Vector2.zero

		local function applyVolume()
			if sound then pcall(function() sound.Volume = muted and 0 or volume end) end
			local v = muted and 0 or volume
			volFill.Size = UDim2.fromScale(v, 1)
			volKnob.Position = UDim2.fromScale(v, 0.5)
			setGlyph(volGlyph, (muted or volume == 0) and "mute" or (volume < 0.5 and "volumeLow" or "volume"))
		end
		local function applyRate()
			if isVideo or not sound then return end
			pcall(function() sound.PlaybackSpeed = speed end)
			local octave = math.clamp(pitch / speed, 0.5, 2)
			if math.abs(octave - 1) < 1e-3 then
				if shifter then shifter:Destroy() shifter = nil end
			else
				if not shifter or not shifter.Parent then
					local ok, ps = pcall(function() return new("PitchShiftSoundEffect", { Octave = octave }, sound) end)
					shifter = ok and ps or nil
				end
				if shifter then pcall(function() shifter.Octave = octave end) end
			end
		end
		local function setLooped(v)
			looped = v
			tint(loopGlyph, looped and RED or Color3.new(1, 1, 1))
			if sound then pcall(function() sound.Looped = looped end) end
		end
		local function setShuffle(v)
			shuffle = v
			tint(shuffleGlyph, shuffle and RED or Color3.new(1, 1, 1))
		end
		shuffleBtn.Visible = true

		local function setTheater(v)
			theater = v
			if theater then
				box.Size = UDim2.new(1, -20, 1, -20)
				box.Position = UDim2.fromOffset(10, 10)
			else
				box.Size = UDim2.fromOffset(W, H)
				box.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
			end
			setGlyph(theaterGlyph, theater and "theaterOff" or "theater")
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
				sound, shifter = nil, nil
				pcall(function() old:Stop() end)
				pcall(function() old:Destroy() end)
			end
			local stem = splitExt(baseName(path))
			title.Text = "Media Player — " .. stem
			overTitle.Text = stem
			if bigTitle then
				bigTitle.Text = stem
				bigSub.Text = ("%s  •  %s"):format(typeName(baseName(path), false), parentOf(path) == "" and "Workspace" or parentOf(path))
				local hue = (#stem * 37 % 360) / 360
				artGradient.Color = ColorSequence.new(Color3.fromHSV(hue, 0.55, 0.95), Color3.fromHSV((hue + 0.15) % 1, 0.65, 0.85))
			end
			loading.Visible = true
			loading.Text = "Loading..."
			loading.TextColor3 = rgb(220, 220, 220)
			lastPos, endedAt = 0, nil
			local ok, id = pcall(getcustomasset, path)
			if mine ~= generation or not alive then return end
			if not ok then
				loading.Text = "Couldn't load: " .. tostring(id)
				loading.TextColor3 = rgb(255, 140, 130)
				return
			end
			local s
			if isVideo then
				local vf = new("VideoFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Looped = looped, ZIndex = 53 }, screen)
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
						if k == "PlaybackSpeed" then return end
						vf[k] = v
					end,
				})
				task.spawn(function()
					pcall(function() vf.Loaded:Wait() end)
					if mine ~= generation or not alive then return end
					local okL, isLoaded = pcall(function() return vf.IsLoaded end)
					if not (okL and isLoaded) then
						loading.Text = "Couldn't play this video (see the output for why).\nkAPI plays .mp4 (H.264) and .webm (VP8 / VP9) videos."
						loading.TextColor3 = rgb(255, 140, 130)
						return
					end
					loading.Visible = false
					pcall(function() vf.Looped = looped end)
					applyVolume()
					local okR, res = pcall(function() return vf.Resolution end)
					if okR and res then title.Text = ("Media Player — %s  (%dx%d)"):format(stem, res.X, res.Y) end
				end)
			else
				s = new("Sound", { Looped = looped }, box)
				s.SoundId = id
				loading.Visible = false
			end
			sound = s
			applyVolume()
			applyRate()
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
			local nowPlaying = false
			pcall(function()
				if sound.IsPlaying then
					wantPlaying = false
					sound:Pause()
				else
					wantPlaying = true
					nowPlaying = true
					local len = sound.TimeLength
					if sound.TimePosition > 0 and not (len > 0 and sound.TimePosition >= len - 0.25) then sound:Resume() else sound:Play() end
				end
			end)
			flashIcon(nowPlaying and "play" or "pause")
		end
		local function nudge(seconds)
			if not sound then return end
			pcall(function()
				local len = sound.TimeLength
				local t = sound.TimePosition + seconds
				if len > 0 then t = math.clamp(t, 0, len - 0.05) else t = math.max(0, t) end
				sound.TimePosition = t
			end)
			flashIcon(seconds < 0 and "back10" or "fwd10")
		end
		local function seekTo(frac)
			if not sound then return end
			pcall(function()
				local len = sound.TimeLength
				if len > 0 then sound.TimePosition = math.clamp(frac, 0, 1) * math.max(0, len - 0.05) end
			end)
		end
		local function previous()
			if sound and (tonumber(sound.TimePosition) or 0) > 3 then
				pcall(function() sound.TimePosition = 0 end)
			else
				step(-1, false)
			end
		end

		playBtn.MouseButton1Click:Connect(togglePlay)
		prevBtn.MouseButton1Click:Connect(previous)
		nextBtn.MouseButton1Click:Connect(function() step(1, false) end)
		loopBtn.MouseButton1Click:Connect(function() setLooped(not looped) end)
		shuffleBtn.MouseButton1Click:Connect(function() setShuffle(not shuffle) end)
		theaterBtn.MouseButton1Click:Connect(function() setTheater(not theater) end)
		volBtn.MouseButton1Click:Connect(function() muted = not muted applyVolume() end)

		-- click / double click on the picture
		local clickToken, lastClickAt = 0, 0
		clickArea.MouseButton1Click:Connect(function()
			if settingsOpen then
				settingsOpen = false
				if settingsFrame then settingsFrame:Destroy() settingsFrame = nil end
				return
			end
			local now = os.clock()
			clickToken += 1
			local mine = clickToken
			if now - lastClickAt < 0.3 then
				lastClickAt = 0
				setTheater(not theater)
				return
			end
			lastClickAt = now
			task.delay(0.25, function()
				if mine == clickToken and alive then togglePlay() end
			end)
		end)

		-- volume slider (opens when hovering the speaker)
		local volOpen = false
		local function setVolOpen(v)
			if v == volOpen then return end
			volOpen = v
			tween(volWrap, 0.15, { Size = UDim2.fromOffset(v and 76 or 0, 40) })
			tween(timeLabel, 0.15, { Position = UDim2.new(0, v and 242 or 166, 0.5, 0) })
		end
		local volDragging = false
		local function volFromMouse()
			local mx = mousePos()
			local p, sz = volTrack.AbsolutePosition, volTrack.AbsoluteSize
			volume = math.clamp((mx - p.X) / math.max(sz.X, 1), 0, 1)
			muted = false
			applyVolume()
		end
		on(volRail.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then volDragging = true volFromMouse() end
		end)

		-- progress dragging
		on(prog.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				seeking = true
				local mx = mousePos()
				seekFrac = math.clamp((mx - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
			end
		end)
		on(UIS.InputChanged, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local mx = mousePos()
			if seeking then seekFrac = math.clamp((mx - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1) end
			if volDragging then volFromMouse() end
		end)
		on(UIS.InputEnded, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if seeking then seeking = false seekTo(seekFrac) end
			volDragging = false
		end)

		-- settings popup (speed, pitch, loop)
		local function speedText(v) return v == 1 and "Normal" or (tostring(v) .. "x") end
		local renderSettings
		local function settingsRow(parent, order, label, value, cb, enabled, checked)
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order, ZIndex = 81 }, parent)
			corner(b, 6)
			local col = enabled == false and rgb(130, 130, 130) or Color3.new(1, 1, 1)
			if checked ~= nil then
				local g = glyph("check", 14, col, b, UDim2.fromOffset(18, 18))
				g.ZIndex = 82
				g.Visible = checked
			end
			new("TextLabel", { Size = UDim2.new(1, -130, 1, 0), Position = UDim2.fromOffset(checked ~= nil and 36 or 14, 0), BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 82 }, b)
			if value then
				new("TextLabel", { Size = UDim2.fromOffset(110, 36), Position = UDim2.new(1, -132, 0, 0), BackgroundTransparency = 1, Text = value, Font = FONT, TextSize = 13, TextColor3 = rgb(200, 200, 200), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 82 }, b)
				local g = glyph("chevRight", 12, rgb(200, 200, 200), b, UDim2.new(1, -12, 0.5, 0))
				g.ZIndex = 82
			end
			if enabled ~= false then
				b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.88 end)
				b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
				b.MouseButton1Click:Connect(cb)
			end
			return b
		end
		function renderSettings(page)
			if settingsFrame then settingsFrame:Destroy() end
			settingsOpen = true
			settingsFrame = new("Frame", { Size = UDim2.fromOffset(270, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -60), BackgroundColor3 = rgb(28, 28, 28), BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 80, Active = true }, screen)
			corner(settingsFrame, 10)
			pad(settingsFrame, 6, 6, 6, 6)
			new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, settingsFrame)
			if page == "speed" or page == "pitch" then
				local hdr = new("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0, ZIndex = 81 }, settingsFrame)
				local g = glyph("chevLeft", 14, Color3.new(1, 1, 1), hdr, UDim2.fromOffset(16, 19))
				g.ZIndex = 82
				new("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(34, 0), BackgroundTransparency = 1, Text = page == "speed" and "Playback speed" or "Pitch", Font = FONT_B, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 82 }, hdr)
				hdr.MouseButton1Click:Connect(function() renderSettings("main") end)
				new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = rgb(70, 70, 70), BorderSizePixel = 0, LayoutOrder = 1, ZIndex = 81 }, settingsFrame)
				local list = page == "speed" and SPEEDS or PITCHES
				for i, v in list do
					local current = page == "speed" and speed or pitch
					settingsRow(settingsFrame, 1 + i, speedText(v), nil, function()
						if page == "speed" then speed = v else pitch = v end
						applyRate()
						renderSettings("main")
					end, true, math.abs(current - v) < 1e-3)
				end
				return
			end
			local mediaNote = isVideo and "(audio only)" or nil
			settingsRow(settingsFrame, 1, "Playback speed", mediaNote or speedText(speed), function() renderSettings("speed") end, not isVideo)
			settingsRow(settingsFrame, 2, "Pitch", mediaNote or speedText(pitch), function() renderSettings("pitch") end, not isVideo)
			settingsRow(settingsFrame, 3, "Loop", looped and "On" or "Off", function() setLooped(not looped) renderSettings("main") end, true)
			settingsRow(settingsFrame, 4, "Shuffle folder", shuffle and "On" or "Off", function() setShuffle(not shuffle) renderSettings("main") end, true)
		end
		gearBtn.MouseButton1Click:Connect(function()
			if settingsOpen then
				settingsOpen = false
				if settingsFrame then settingsFrame:Destroy() settingsFrame = nil end
				tween(gearGlyph, 0.2, { Rotation = 0 })
			else
				renderSettings("main")
				tween(gearGlyph, 0.2, { Rotation = 30 })
			end
		end)

		-- keyboard (YouTube keys)
		on(UIS.InputBegan, function(input, processed)
			if processed or not alive or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if UIS:GetFocusedTextBox() then return end
			local k = input.KeyCode
			lastMove = os.clock()
			if k == Enum.KeyCode.Space or k == Enum.KeyCode.K then togglePlay()
			elseif k == Enum.KeyCode.J then nudge(-10)
			elseif k == Enum.KeyCode.L then nudge(10)
			elseif k == Enum.KeyCode.Left then nudge(-5)
			elseif k == Enum.KeyCode.Right then nudge(5)
			elseif k == Enum.KeyCode.Up or k == Enum.KeyCode.Down then
				volume = math.clamp(volume + (k == Enum.KeyCode.Up and 0.05 or -0.05), 0, 1)
				muted = false
				applyVolume()
			elseif k == Enum.KeyCode.M then muted = not muted applyVolume()
			elseif k == Enum.KeyCode.F or k == Enum.KeyCode.T then setTheater(not theater)
			elseif k == Enum.KeyCode.N then step(1, false)
			elseif k == Enum.KeyCode.P then previous()
			elseif k == Enum.KeyCode.Escape then
				if theater then setTheater(false) else close() end
			else
				local digit = ({ Zero = 0, One = 1, Two = 2, Three = 3, Four = 4, Five = 5, Six = 6, Seven = 7, Eight = 8, Nine = 9 })[k.Name]
				if digit then seekTo(digit / 10) end
			end
		end)

		----------------------------------------------------------------- update loop
		local overlayShown = true
		on(RunService.RenderStepped, function(dt)
			if not alive then return end
			local m = UIS:GetMouseLocation()
			local over = pointIn(screen, m.X, m.Y)
			if over and (m - lastMouse).Magnitude > 0.5 then lastMove = os.clock() end
			lastMouse = m

			local s = sound
			local pos, len, playing, loud = 0, 0, false, 0
			if s then
				pcall(function() pos, len, playing, loud = s.TimePosition, s.TimeLength, s.IsPlaying, s.PlaybackLoudness end)
			end
			pos, len, loud = tonumber(pos) or 0, tonumber(len) or 0, tonumber(loud) or 0

			-- show the controls while paused, while seeking / in a menu, or for 2.5 s after the mouse moves
			local show = (not playing) or seeking or settingsOpen or volDragging or (over and os.clock() - lastMove < 2.5)
			if show ~= overlayShown then
				overlayShown = show
				if show then ui.Visible = true end
				tween(ui, 0.2, { GroupTransparency = show and 0 or 1 })
				if not show then
					setVolOpen(false)
					task.delay(0.21, function() if not overlayShown and alive then ui.Visible = false end end)
				end
			end
			-- volume slider opens while hovering the speaker area
			local vp, vs = volBtn.AbsolutePosition, volBtn.AbsoluteSize
			local hoverVol = m.X >= vp.X and m.X <= vp.X + vs.X + (volOpen and 80 or 0) and m.Y >= vp.Y and m.Y <= vp.Y + vs.Y
			if show then setVolOpen(hoverVol or volDragging) end

			setGlyph(playGlyph, playing and "pause" or "play")
			queueLabel.Text = #queue > 1 and ("%d / %d"):format(index, #queue) or ""
			local shownPos = seeking and seekFrac * len or pos
			timeLabel.Text = ("%s / %s"):format(fmtTime(shownPos), fmtTime(len))
			local frac = len > 0 and math.clamp(shownPos / len, 0, 1) or 0
			fill.Size = UDim2.fromScale(frac, 1)
			knob.Position = UDim2.fromScale(frac, 0.5)

			-- progress hover: thicker bar, knob, time tooltip
			local hoverProg = pointIn(prog, m.X, m.Y) and show
			local thick = (hoverProg or seeking) and 5 or 3
			rail.Size = UDim2.new(1, 0, 0, thick)
			knob.Visible = hoverProg or seeking
			hoverFill.Visible = hoverProg and not seeking
			tip.Visible = (hoverProg or seeking) and len > 0
			if tip.Visible then
				local hf = seeking and seekFrac or math.clamp((m.X - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
				hoverFill.Size = UDim2.fromScale(hf, 1)
				tip.Text = fmtTime(hf * len)
				local half = 30
				local px = math.clamp(hf * rail.AbsoluteSize.X, half, rail.AbsoluteSize.X - half)
				tip.Position = UDim2.new(0, px, 0, -4)
			end

			-- the track ran out: next one in the folder
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
			local level = playing and math.clamp(loud / 400, 0, 1) or 0
			local t = os.clock()
			for i = 1, BARS do
				local shape = 0.35 + 0.65 * math.sin(math.pi * (i - 0.5) / BARS) ^ 0.6
				local wiggle = 0.55 + 0.45 * math.noise(i * 0.37, t * 3.1)
				local target = level * shape * (0.6 + wiggle)
				heights[i] += (target - heights[i]) * math.min(1, dt * (target > heights[i] and 18 or 6))
				bars[i].Size = UDim2.new(1 / BARS, -3, math.clamp(heights[i], 0.02, 1), 0)
			end
			art.Size = UDim2.fromOffset(190 + level * 10, 190 + level * 10)
		end)

		setLooped(false)
		setShuffle(false)
		applyVolume()
		buildQueue(startPath)
		task.spawn(load, startPath, true)
	end

	----------------------------------------------------------------- image / 3D model / font viewer
	function openPreview(path)
		local name = baseName(path)
		local kind = mediaKind(name)
		if kind == "audio" or kind == "video" then return openPlayer(path) end
		if isHtml(name) then return openHtml(path) end
		if not kind then return openEditor(path) end
		local shade, box, close, x = modalShell(780, 540, name)
		x.MouseButton1Click:Connect(close)
		local stage = new("Frame", {
			Size = UDim2.new(1, -20, 1, -100), Position = UDim2.fromOffset(10, 46),
			BackgroundColor3 = rgb(32, 32, 32), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 52,
		}, box)
		corner(stage, 6)
		local info = new("TextLabel", {
			Size = UDim2.new(1, -460, 0, 32), Position = UDim2.new(0, 14, 1, -44), BackgroundTransparency = 1,
			Text = "", Font = FONT, TextSize = 12, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 53,
		}, box)
		local loading = new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Loading...", Font = FONT,
			TextSize = 14, TextColor3 = rgb(200, 200, 200), ZIndex = 53,
		}, stage)
		dialogButton(box, "Close", -108, false, close)
		local alive = true
		local connections = {}
		shade.Destroying:Connect(function()
			alive = false
			for _, c in connections do pcall(function() c:Disconnect() end) end
		end)
		local function on(signal, fn) local c = signal:Connect(fn) table.insert(connections, c) return c end
		local btnX = -108
		local function controlButton(label, cb)
			btnX -= 84
			local b = new("TextButton", {
				Size = UDim2.fromOffset(78, 32), Position = UDim2.new(1, btnX, 1, -44),
				BackgroundColor3 = T.toolbar, Text = label, Font = FONT, TextSize = 12, TextColor3 = T.text,
				AutoButtonColor = true, ZIndex = 53,
			}, box)
			corner(b, 5) stroke(b, T.border, 1)
			b.MouseButton1Click:Connect(function() cb(b) end)
			return b
		end

		task.spawn(function()
			local ok, id = pcall(getcustomasset, path)
			if not alive then return end
			if not ok then
				loading.Text = "Couldn't load this file:\n" .. tostring(id)
				loading.TextWrapped = true
				loading.TextColor3 = rgb(255, 140, 130)
				return
			end
			loading.Visible = false

			if kind == "image" then
				-- checkerboard so transparency shows; wheel to zoom, drag to pan
				local checker = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 52 }, stage)
				for gy = 0, 44 do
					for gx = 0, 64 do
						if (gx + gy) % 2 == 0 then
							new("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(gx * 12, gy * 12), BackgroundColor3 = rgb(44, 44, 44), BorderSizePixel = 0, ZIndex = 52 }, checker)
						end
					end
				end
				local img = new("ImageLabel", {
					Size = UDim2.new(1, -16, 1, -16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = id, ZIndex = 54,
				}, stage)
				local zoom, panX, panY = 1, 0, 0
				local function apply()
					img.Size = UDim2.new(zoom, -16 * zoom, zoom, -16 * zoom)
					img.Position = UDim2.new(0.5, panX, 0.5, panY)
					info.Text = ("%s  •  %d%%"):format(info:GetAttribute("base") or name, math.floor(zoom * 100 + 0.5))
				end
				local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 55 }, stage)
				local dragging, last
				on(hit.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging, last = true, UIS:GetMouseLocation() end
				end)
				on(UIS.InputChanged, function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
						local m = UIS:GetMouseLocation()
						panX += m.X - last.X
						panY += m.Y - last.Y
						last = m
						apply()
					elseif input.UserInputType == Enum.UserInputType.MouseWheel then
						local m = UIS:GetMouseLocation()
						if pointIn(stage, m.X, m.Y) then
							zoom = math.clamp(zoom * (input.Position.Z > 0 and 1.15 or 1 / 1.15), 0.1, 16)
							apply()
						end
					end
				end)
				on(UIS.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)
				controlButton("Fit", function() zoom, panX, panY = 1, 0, 0 apply() end)
				controlButton("Zoom in", function() zoom = math.min(16, zoom * 1.25) apply() end)
				controlButton("Zoom out", function() zoom = math.max(0.1, zoom / 1.25) apply() end)
				task.defer(function()
					local okS, size = pcall(function() return img.ImageContent.Object.Size end)
					info:SetAttribute("base", (okS and size) and ("%d × %d  •  %s"):format(size.X, size.Y, name) or name)
					apply()
				end)

			elseif kind == "model" then
				-- orbit (drag), zoom (wheel), auto-rotate, colors, lighting
				local viewport = new("ViewportFrame", {
					Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(32, 32, 32), BackgroundTransparency = 0,
					Ambient = rgb(150, 150, 150), LightColor = rgb(255, 255, 255),
					LightDirection = Vector3.new(-1, -1.4, -0.8), ZIndex = 53,
				}, stage)
				local camera = new("Camera", { FieldOfView = 40 }, viewport)
				viewport.CurrentCamera = camera
				local part = new("MeshPart", { Anchored = true, Color = rgb(200, 200, 205), Material = Enum.Material.SmoothPlastic }, viewport)
				local floor = new("Part", { Anchored = true, Size = Vector3.new(1, 0.05, 1), Color = rgb(60, 60, 64), Material = Enum.Material.SmoothPlastic, Transparency = 0.2 }, viewport)
				local status = new("TextLabel", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Building mesh...", Font = FONT,
					TextSize = 14, TextColor3 = rgb(200, 200, 200), ZIndex = 54,
				}, stage)
				part.MeshId = id
				local started, before = os.clock(), part.MeshSize
				while alive and part.MeshSize == before and os.clock() - started < 20 do task.wait(0.1) end
				if not alive then return end
				if part.MeshSize == before then
					status.Text = "Couldn't build this mesh (see the output for details)"
					status.TextColor3 = rgb(255, 140, 130)
					return
				end
				status:Destroy()
				part.Size = part.MeshSize
				local radius = part.Size.Magnitude / 2
				floor.Size = Vector3.new(radius * 4, 0.02 * radius, radius * 4)
				floor.CFrame = CFrame.new(0, -part.Size.Y / 2 - 0.02 * radius, 0)
				local baseDist = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.15
				local yaw, pitchA, dist = 0, math.rad(18), baseDist
				local auto = true
				info.Text = ("%s  •  %.2f × %.2f × %.2f studs  •  drag to orbit, wheel to zoom"):format(name, part.Size.X, part.Size.Y, part.Size.Z)
				local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 55 }, stage)
				local dragging, last
				on(hit.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging, last = true, UIS:GetMouseLocation() auto = false end
				end)
				on(UIS.InputChanged, function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
						local m = UIS:GetMouseLocation()
						yaw -= (m.X - last.X) * 0.01
						pitchA = math.clamp(pitchA + (m.Y - last.Y) * 0.01, -1.4, 1.4)
						last = m
					elseif input.UserInputType == Enum.UserInputType.MouseWheel then
						local m = UIS:GetMouseLocation()
						if pointIn(stage, m.X, m.Y) then
							dist = math.clamp(dist * (input.Position.Z > 0 and 0.88 or 1.14), baseDist * 0.2, baseDist * 6)
						end
					end
				end)
				on(UIS.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)
				local colors = { { "Clay", rgb(200, 200, 205) }, { "White", rgb(245, 245, 245) }, { "Dark", rgb(70, 70, 76) }, { "Gold", rgb(214, 170, 70) }, { "Blue", rgb(80, 140, 235) } }
				local ci = 1
				local lightBright = true
				controlButton("Reset view", function() yaw, pitchA, dist, auto = 0, math.rad(18), baseDist, true end)
				controlButton("Auto-rotate", function() auto = not auto end)
				controlButton("Color", function(b)
					ci = ci % #colors + 1
					part.Color = colors[ci][2]
					b.Text = colors[ci][1]
				end)
				controlButton("Lighting", function()
					lightBright = not lightBright
					viewport.Ambient = lightBright and rgb(150, 150, 150) or rgb(80, 80, 95)
					viewport.LightColor = lightBright and rgb(255, 255, 255) or rgb(255, 214, 170)
				end)
				while alive do
					if auto then yaw += math.rad(0.5) end
					local offset = CFrame.Angles(0, yaw, 0) * CFrame.Angles(-pitchA, 0, 0) * Vector3.new(0, 0, dist)
					camera.CFrame = CFrame.lookAt(offset, Vector3.zero)
					task.wait()
				end

			elseif kind == "font" then
				local list = new("ScrollingFrame", {
					Size = UDim2.new(1, -40, 1, -30), Position = UDim2.fromOffset(20, 15), BackgroundTransparency = 1, BorderSizePixel = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6, ZIndex = 53,
				}, stage)
				new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, list)
				local samples = {
					"The quick brown fox jumps over the lazy dog 0123456789",
					"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
					"abcdefghijklmnopqrstuvwxyz  !?&@#%()[]{}",
				}
				local order = 0
				for _, size in { 14, 20, 28, 40, 56 } do
					for si, text in samples do
						if size >= 40 and si > 1 then continue end
						order += 1
						local label = new("TextLabel", {
							Size = UDim2.new(1, 0, 0, size + 8), BackgroundTransparency = 1, LayoutOrder = order,
							Text = text, TextSize = size, TextColor3 = rgb(235, 235, 235), TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54,
						}, list)
						pcall(function() label.FontFace = id end)
					end
				end
				info.Text = name
			end
		end)
	end

	----------------------------------------------------------------- properties
	function showProperties(paths)
		if #paths == 0 then paths = { state.current } end
		local single = #paths == 1
		local _, box, close, x = modalShell(400, 320, (single and (paths[1] == "" and "Workspace" or baseName(paths[1])) or (#paths .. " items")) .. " Properties")
		x.MouseButton1Click:Connect(close)
		if single then
			local p = paths[1]
			local isDir = p == "" or FS.isFolder(p)
			local ic = typeIcon(baseName(p), isDir, 40)
			ic.Position = UDim2.fromOffset(20, 50)
			ic.ZIndex = 53
			ic.Parent = box
			for _, d in ic:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex = 54 end end
			new("TextLabel", { Size = UDim2.new(1, -90, 0, 40), Position = UDim2.fromOffset(72, 50), BackgroundTransparency = 1, Text = p == "" and "Workspace" or baseName(p), Font = FONT_B, TextSize = 14, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 53 }, box)
		end
		local list = new("Frame", { Size = UDim2.new(1, -40, 1, -160), Position = UDim2.fromOffset(20, single and 104 or 50), BackgroundTransparency = 1, ZIndex = 53 }, box)
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		local rows = {}
		local function line(label, value, order)
			local f = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 53 }, list)
			new("TextLabel", { Size = UDim2.fromOffset(90, 20), BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54 }, f)
			local v = new("TextLabel", { Size = UDim2.new(1, -96, 1, 0), Position = UDim2.fromOffset(96, 0), BackgroundTransparency = 1, Text = value, Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 54 }, f)
			rows[label] = v
		end
		if single then
			local p = paths[1]
			local isDir = p == "" or FS.isFolder(p)
			line("Type:", typeName(baseName(p), isDir), 1)
			line("Location:", p == "" and "(root)" or (parentOf(p) == "" and "Workspace" or parentOf(p)), 2)
			line("Path:", p == "" and "/" or p, 3)
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
					for _, c in FS.children(p, true) do walk(c) end
				else
					files += 1
					bytes += FS.size(p) or 0
				end
			end
			for _, p in paths do walk(p) end
			if rows["Size:"] and rows["Size:"].Parent then rows["Size:"].Text = ("%s (%d bytes)"):format(fmtBytes(bytes), bytes) end
			if rows["Contains:"] and rows["Contains:"].Parent then
				local sub = (single and paths[1] ~= "") and (folders - 1) or folders
				rows["Contains:"].Text = ("%d file%s, %d folder%s"):format(files, files == 1 and "" or "s", sub, sub == 1 and "" or "s")
			end
		end)
	end

	----------------------------------------------------------------- settings
	local rebuild
	function openSettings()
		local _, box, close, x = modalShell(440, 420, "Settings")
		x.MouseButton1Click:Connect(close)
		local list = new("Frame", { Size = UDim2.new(1, -40, 1, -110), Position = UDim2.fromOffset(20, 50), BackgroundTransparency = 1, ZIndex = 53 }, box)
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
		local changed = false
		local needsRebuild = false
		local function toggleRow(order, label, sub, key, rebuilds)
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order, ZIndex = 53 }, list)
			corner(b, 6)
			new("TextLabel", { Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(10, 5), BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54 }, b)
			new("TextLabel", { Size = UDim2.new(1, -80, 0, 16), Position = UDim2.fromOffset(10, 25), BackgroundTransparency = 1, Text = sub, Font = FONT, TextSize = 11, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54 }, b)
			local trackF = new("Frame", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -52, 0.5, -10), BackgroundColor3 = T.accent, BorderSizePixel = 0, ZIndex = 54 }, b)
			corner(trackF, 10)
			local trackStroke = stroke(trackF, T.switchOff, 1)
			local dot = new("Frame", { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = T.accentText, BorderSizePixel = 0, ZIndex = 55 }, trackF)
			corner(dot, 6)
			local function paint(animate)
				local v = Settings[key]
				trackF.BackgroundTransparency = v and 0 or 1
				trackStroke.Transparency = v and 1 or 0
				dot.BackgroundColor3 = v and T.accentText or T.switchOff
				local target = v and UDim2.new(0, 24, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
				if animate then tween(dot, 0.15, { Position = target }) else dot.Position = target end
			end
			paint(false)
			b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
			b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
			b.MouseButton1Click:Connect(function()
				Settings[key] = not Settings[key]
				changed = true
				if rebuilds then needsRebuild = true end
				paint(true)
				saveSettings()
			end)
		end
		toggleRow(1, "Dark mode", "Use the dark Windows 11 theme", "dark", true)
		toggleRow(2, "Show file name extensions", "Like .txt and .png at the end of names", "showExt")
		toggleRow(3, "Show size column", "File sizes in the details view", "showSize")
		toggleRow(4, "Show hidden items", "Files and folders that start with a dot", "showHidden")
		toggleRow(5, "Confirm before deleting", "Ask before deleting files and folders", "confirmDelete")
		local viewRow = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, LayoutOrder = 6, ZIndex = 53 }, list)
		new("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "View", Font = FONT, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 54 }, viewRow)
		local segButtons = {}
		for i, v in { { "details", "Details" }, { "large", "Large icons" } } do
			local sb = new("TextButton", { Size = UDim2.fromOffset(96, 28), Position = UDim2.new(1, -206 + (i - 1) * 100, 0.5, -14), BackgroundColor3 = T.toolbar, Text = v[2], Font = FONT, TextSize = 12, TextColor3 = T.text, AutoButtonColor = true, ZIndex = 54 }, viewRow)
			corner(sb, 5) stroke(sb, T.border, 1)
			segButtons[v[1]] = sb
			sb.MouseButton1Click:Connect(function()
				Settings.view = v[1]
				changed = true
				saveSettings()
				for k, other in segButtons do
					other.BackgroundColor3 = k == Settings.view and T.accent or T.toolbar
					other.TextColor3 = k == Settings.view and T.accentText or T.text
				end
			end)
		end
		for k, other in segButtons do
			other.BackgroundColor3 = k == Settings.view and T.accent or T.toolbar
			other.TextColor3 = k == Settings.view and T.accentText or T.text
		end
		new("TextLabel", { Size = UDim2.new(1, -240, 0, 32), Position = UDim2.new(0, 20, 1, -44), BackgroundTransparency = 1, Text = "Saved to " .. SETTINGS_FILE, Font = FONT, TextSize = 11, TextColor3 = T.textDim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53 }, box)
		dialogButton(box, "Done", -108, true, function()
			close()
			if needsRebuild then
				rebuild()
			elseif changed then
				sizeCache = {}
				rebuildSidebar()
				render(state.current, true, true)
			end
		end)
	end

	----------------------------------------------------------------- menus
	local function openWithItems(rec)
		local items = {}
		if not rec.isDir then
			local kind = mediaKind(rec.name)
			if kind then table.insert(items, { label = kind == "audio" and "Media Player" or (kind == "video" and "Media Player" or "Preview"), cb = function() openPreview(rec.path) end }) end
			if isHtml(rec.name) then table.insert(items, { label = "HTML viewer", cb = function() openHtml(rec.path) end }) end
			table.insert(items, { label = "Text editor", cb = function() openEditor(rec.path, true) end })
		end
		return items
	end
	local function itemMenu(rec)
		local sel = selectedPaths()
		local single = #sel == 1
		local items = {
			{ label = "Open", bold = true, key = "Enter", cb = function() openItem(rec) end, enabled = single },
		}
		if single and not rec.isDir then
			for _, it in openWithItems(rec) do
				it.label = "Open with " .. it.label
				table.insert(items, it)
			end
		end
		for _, it in {
			"-",
			{ label = "Cut", glyph = "cut", key = "Ctrl+X", cb = function() doCopy(true) end },
			{ label = "Copy", glyph = "copy", key = "Ctrl+C", cb = function() doCopy(false) end },
			{ label = "Paste", glyph = "paste", key = "Ctrl+V", cb = doPaste, enabled = state.clipboard ~= nil },
			{ label = "Duplicate", key = "Ctrl+D", cb = doDuplicate },
			"-",
			{ label = "Copy as path", cb = copyPathToClipboard },
			{ label = "Rename", glyph = "rename", key = "F2", cb = function() startRename(rec.path) end, enabled = single },
			{ label = "Delete", glyph = "trash", key = "Del", cb = function() confirmDelete(selectedPaths()) end },
			"-",
			{ label = "Properties", glyph = "info", key = "Alt+Enter", cb = function() showProperties(selectedPaths()) end },
			} do table.insert(items, it) end
		openMenu(items)
	end
	local function sortItems()
		local items = {}
		for _, k in { { "name", "Name" }, { "type", "Type" }, { "size", "Size" } } do
			table.insert(items, { label = k[2], checked = Settings.sortKey == k[1], cb = function() Settings.sortKey = k[1] saveSettings() render(state.current, true, true) end })
		end
		table.insert(items, "-")
		table.insert(items, { label = "Ascending", checked = Settings.sortAsc, cb = function() Settings.sortAsc = true saveSettings() render(state.current, true, true) end })
		table.insert(items, { label = "Descending", checked = not Settings.sortAsc, cb = function() Settings.sortAsc = false saveSettings() render(state.current, true, true) end })
		return items
	end
	local function viewItems()
		return {
			{ label = "Large icons", glyph = "grid", checked = Settings.view == "large", cb = function() Settings.view = "large" saveSettings() render(state.current, true, true) end },
			{ label = "Details", glyph = "list", checked = Settings.view == "details", cb = function() Settings.view = "details" saveSettings() render(state.current, true, true) end },
			"-",
			{ label = "File name extensions", checked = Settings.showExt, cb = function() Settings.showExt = not Settings.showExt saveSettings() render(state.current, true, true) end },
			{ label = "Hidden items", checked = Settings.showHidden, cb = function() Settings.showHidden = not Settings.showHidden saveSettings() render(state.current, true, true) rebuildSidebar() highlightSidebar() end },
		}
	end
	local function backgroundMenu()
		local items = {
			{ label = "View", glyph = Settings.view == "large" and "grid" or "list", cb = function() openMenu(viewItems()) end },
			{ label = "Sort by", glyph = "sort", cb = function() openMenu(sortItems()) end },
			{ label = "Refresh", glyph = "refresh", key = "F5", cb = function() sizeCache = {} render(state.current, true, true) end },
			"-",
			{ label = "Paste", glyph = "paste", key = "Ctrl+V", cb = doPaste, enabled = state.clipboard ~= nil },
			"-",
		}
		for _, it in newMenuItems() do
			if it ~= "-" then it.label = "New " .. it.label:lower() end
			table.insert(items, it)
		end
		for _, it in {
			"-",
			{ label = "Select all", key = "Ctrl+A", cb = selectAll },
			{ label = "Invert selection", cb = invertSelection },
			{ label = "Copy as path", cb = function() state.selected = {} refreshVisuals() copyPathToClipboard() end },
			{ label = "Properties", glyph = "info", cb = function() showProperties({ state.current }) end },
			} do table.insert(items, it) end
		openMenu(items)
	end

	----------------------------------------------------------------- command bar buttons
	cmdButton("New", "newFile", 8, 76, function(b) menuUnder(b, newMenuItems()) end)
	separator(90)
	cmdButton("Cut", "cut", 98, 58, function() doCopy(true) end)
	cmdButton("Copy", "copy", 158, 64, function() doCopy(false) end)
	cmdButton("Paste", "paste", 224, 66, doPaste)
	cmdButton("Rename", "rename", 292, 80, function() local s = selectedPaths() if #s == 1 then startRename(s[1]) end end)
	cmdButton("Delete", "trash", 374, 74, function() confirmDelete(selectedPaths()) end)
	separator(454)
	cmdButton("Sort", "sort", 462, 64, function(b) menuUnder(b, sortItems()) end)
	cmdButton("View", Settings.view == "large" and "grid" or "list", 528, 66, function(b) menuUnder(b, viewItems()) end)
	cmdButton("Settings", "gear", -100, 92, function() openSettings() end, true)

	----------------------------------------------------------------- drag & drop + drag-select
	local press -- { rec, x, y }
	local drag -- { paths, ghost, target, targetPath }
	local band -- { frame, x0, y0, base }
	local function dropTargetAt(x, y, paths)
		local function ok(path)
			for _, p in paths do
				if path == p or isInside(path, p) or parentOf(p) == path and not ctrlDown() then return false end
			end
			return true
		end
		for _, rec in state.records do
			if rec.isDir and pointIn(rec.row, x, y) and ok(rec.path) then return rec.row, rec.path end
		end
		if pointIn(sidebar, x, y) then
			for path, b in sideButtons do
				if pointIn(b, x, y) and ok(path) then return b, path end
			end
		end
		for _, cb in crumbButtons do
			if pointIn(cb.button, x, y) and ok(cb.path) then return cb.button, cb.path end
		end
		return nil
	end
	local function setDropTarget(obj)
		if obj == dropTarget then return end
		local prev = dropTarget
		dropTarget = obj
		if prev and prev.Parent then
			prev.BackgroundTransparency = 1
		end
		refreshVisuals()
		highlightSidebar()
		if obj then
			obj.BackgroundTransparency = 0
			obj.BackgroundColor3 = T.accentBg
		end
	end
	local function endDrag(commit)
		if not drag then return end
		local d = drag
		drag = nil
		d.ghost:Destroy()
		local targetPath = d.targetPath
		setDropTarget(nil)
		state.suppressClick = os.clock() + 0.15
		if commit and targetPath then
			local mode = ctrlDown() and "copy" or "move"
			runOp(mode == "copy" and "Copying" or "Moving", function()
				local newPaths = transfer(d.paths, targetPath, mode)
				afterChange(nil)
				setStatus(("%s %d item%s to %s"):format(mode == "copy" and "Copied" or "Moved", #newPaths, #newPaths == 1 and "" or "s", targetPath == "" and "Workspace" or baseName(targetPath)))
			end)
		end
	end
	local function onRowPress(rec)
		local x, y = mousePos()
		press = { rec = rec, x = x, y = y }
	end
	scroll.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			closeMenu()
			state.focused = true
			local x, y = mousePos()
			for _, rec in state.records do if pointIn(rec.row, x, y) then return end end
			-- empty space: clear (unless Ctrl) and start a drag-select box
			local base = {}
			if ctrlDown() then for p in state.selected do base[p] = true end else state.selected = {} refreshVisuals() end
			local f = new("Frame", { BackgroundColor3 = T.accent, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 30, Visible = false }, window)
			stroke(f, T.accent, 1)
			band = { frame = f, x0 = x, y0 = y, base = base }
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			local x, y = mousePos()
			for _, rec in state.records do if pointIn(rec.row, x, y) then return end end
			state.focused = true
			state.selected = {}
			refreshVisuals()
			backgroundMenu()
		end
	end)
	track(UIS.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local x, y = mousePos()
		if press and not drag then
			if math.abs(x - press.x) + math.abs(y - press.y) > 6 and not state.renaming then
				state.renameToken += 1
				local rec = press.rec
				if not state.selected[rec.path] then selectOnly(rec.path) end
				local paths = selectedPaths()
				local ghost = new("Frame", { Size = UDim2.fromOffset(200, 30), BackgroundColor3 = T.menu, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 200 }, gui)
				corner(ghost, 6) stroke(ghost, T.borderStrong, 1)
				local ic = typeIcon(rec.name, rec.isDir, 20)
				ic.Position = UDim2.fromOffset(6, 5)
				ic.Parent = ghost
				for _, dsc in ic:GetDescendants() do if dsc:IsA("GuiObject") then dsc.ZIndex = 201 end end
				local lbl = new("TextLabel", { Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(32, 0), BackgroundTransparency = 1, Text = "", Font = FONT, TextSize = 12, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 201 }, ghost)
				drag = { paths = paths, ghost = ghost, label = lbl, count = #paths, name = rec.name }
			end
		end
		if drag then
			drag.ghost.Position = UDim2.fromOffset(x + 14, y + 12)
			local obj, path = dropTargetAt(x, y, drag.paths)
			setDropTarget(obj)
			drag.targetPath = obj and path or nil
			local what = drag.count == 1 and drag.name or (drag.count .. " items")
			if obj then
				drag.label.Text = ("%s %s to %s"):format(ctrlDown() and "Copy" or "Move", what, path == "" and "Workspace" or baseName(path))
			else
				drag.label.Text = what
			end
		end
		if band then
			local x0, y0 = math.min(band.x0, x), math.min(band.y0, y)
			local x1, y1 = math.max(band.x0, x), math.max(band.y0, y)
			if x1 - x0 + y1 - y0 > 4 then
				local wp = window.AbsolutePosition
				band.frame.Visible = true
				band.frame.Position = UDim2.fromOffset(x0 - wp.X, y0 - wp.Y)
				band.frame.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
				local sel = table.clone(band.base)
				for _, rec in state.records do
					local p, s = rec.row.AbsolutePosition, rec.row.AbsoluteSize
					if p.X < x1 and p.X + s.X > x0 and p.Y < y1 and p.Y + s.Y > y0 then sel[rec.path] = true end
				end
				state.selected = sel
				refreshVisuals()
			end
		end
	end))
	track(UIS.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		press = nil
		if drag then endDrag(true) end
		if band then
			band.frame:Destroy()
			band = nil
		end
	end))

	----------------------------------------------------------------- rows (details) and tiles (large icons)
	local function makeRecord(name, path, isDir, order)
		local large = Settings.view == "large"
		local row, iconHolder, nameLabel, sizeLabel
		if large then
			row = new("TextButton", { BackgroundColor3 = T.accentHv, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order }, scroll)
			corner(row, 5)
			iconHolder = typeIcon(name, isDir, 52)
			iconHolder.AnchorPoint = Vector2.new(0.5, 0)
			iconHolder.Position = UDim2.new(0.5, 0, 0, 8)
			iconHolder.Parent = row
			nameLabel = new("TextLabel", {
				Size = UDim2.new(1, -8, 0, 34), Position = UDim2.fromOffset(4, 64), BackgroundTransparency = 1,
				Text = displayName(name, isDir), Font = FONT, TextSize = 12, TextColor3 = T.text, TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)
		else
			row = new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.accentHv, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order }, scroll)
			corner(row, 4)
			iconHolder = typeIcon(name, isDir, 20)
			iconHolder.Position = UDim2.fromOffset(12, 5)
			iconHolder.Parent = row
			local sw = sizeColWidth()
			nameLabel = new("TextLabel", {
				Size = UDim2.new(1, -(40 + COL_TYPE + sw + 16), 1, 0), Position = UDim2.fromOffset(40, 0), BackgroundTransparency = 1,
				Text = displayName(name, isDir), Font = FONT, TextSize = 13, TextColor3 = T.text,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)
			new("TextLabel", {
				Size = UDim2.fromOffset(COL_TYPE - 8, 30), Position = UDim2.new(1, -(COL_TYPE + sw + 4), 0, 0), BackgroundTransparency = 1,
				Text = typeName(name, isDir), Font = FONT, TextSize = 12, TextColor3 = T.textDim,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)
			if Settings.showSize then
				sizeLabel = new("TextLabel", {
					Size = UDim2.fromOffset(sw - 8, 30), Position = UDim2.new(1, -(sw + 4), 0, 0), BackgroundTransparency = 1,
					Text = isDir and "" or fmtBytes(sizeCache[path]), Font = FONT, TextSize = 12, TextColor3 = T.textDim,
					TextXAlignment = Enum.TextXAlignment.Right,
				}, row)
			end
		end
		local rec = { name = name, path = path, isDir = isDir, row = row, nameLabel = nameLabel, sizeLabel = sizeLabel, icon = iconHolder, index = order, hover = false, lastClick = 0, cut = false }
		row.MouseEnter:Connect(function() rec.hover = true if not drag then paintRow(rec) end end)
		row.MouseLeave:Connect(function() rec.hover = false if not drag then paintRow(rec) end end)
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then onRowPress(rec) end
		end)
		row.MouseButton1Click:Connect(function()
			if drag or os.clock() < state.suppressClick then return end
			closeMenu()
			state.focused = true
			local now = os.clock()
			-- fast double click: open
			if now - rec.lastClick < 0.4 and not ctrlDown() and not shiftDown() then
				rec.lastClick = 0
				openItem(rec)
				return
			end
			local wasOnly = state.selected[rec.path] and #selectedPaths() == 1
			rec.lastClick = now
			-- slow second click on the item that was already selected: rename (unless it becomes a double click)
			if wasOnly and not ctrlDown() and not shiftDown() then
				state.renameToken += 1
				local token = state.renameToken
				task.delay(0.45, function()
					if state.renameToken == token and row.Parent and state.selected[rec.path] and #selectedPaths() == 1 then
						startRename(rec.path)
					end
				end)
				return
			end
			state.renameToken += 1
			clickSelect(rec.index)
		end)
		row.MouseButton2Click:Connect(function()
			state.focused = true
			if not state.selected[rec.path] then clickSelect(rec.index) end
			itemMenu(rec)
		end)
		return rec
	end

	----------------------------------------------------------------- breadcrumb
	function buildCrumbs()
		for _, c in crumbs:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
		crumbButtons = {}
		local parts = {}
		if state.current ~= "" then
			local acc = ""
			for seg in state.current:gmatch("[^/]+") do
				acc = acc == "" and seg or (acc .. "/" .. seg)
				table.insert(parts, { seg, acc })
			end
		end
		table.insert(parts, 1, { "Workspace", "" })
		local order = 0
		for i, part in parts do
			order += 1
			local b = new("TextButton", { Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.hover, BackgroundTransparency = 1, Text = part[1], Font = FONT, TextSize = 13, TextColor3 = T.text, AutoButtonColor = false, LayoutOrder = order }, crumbs)
			corner(b, 4) pad(b, 6, 6, 0, 0)
			b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
			b.MouseLeave:Connect(function() if b ~= dropTarget then b.BackgroundTransparency = 1 end end)
			b.MouseButton1Click:Connect(function() render(part[2]) end)
			table.insert(crumbButtons, { button = b, path = part[2] })
			if i < #parts then
				order += 1
				local holder = new("Frame", { Size = UDim2.fromOffset(16, 24), BackgroundTransparency = 1, LayoutOrder = order }, crumbs)
				glyph("chevRight", 11, T.textDim, holder)
			end
		end
	end

	----------------------------------------------------------------- render a folder
	local sizeJob = 0
	function render(path, fromHistory, keepSelection)
		closeMenu()
		path = tostring(path or ""):gsub("\\", "/"):gsub("/+$", "")
		if path ~= "" and not FS.isFolder(path) then path = "" end
		local changed = path ~= state.current
		state.current = path
		titleText.Text = (path == "" and "Workspace" or baseName(path)) .. " - File Explorer"
		buildCrumbs()

		if not fromHistory then
			for i = #state.history, state.idx + 1, -1 do state.history[i] = nil end
			table.insert(state.history, path)
			state.idx = #state.history
		end
		tint(backGlyph, state.idx > 1 and T.text or T.textOff)
		tint(fwdGlyph, state.idx < #state.history and T.text or T.textOff)
		tint(upGlyph, path ~= "" and T.text or T.textOff)

		if changed or not keepSelection then state.selected = {} state.anchor = nil end
		if changed and searchBox.Text ~= "" then
			state.suppressSearch = true
			searchBox.Text = ""
			state.suppressSearch = false
		end

		for _, c in scroll:GetChildren() do
			if c:IsA("GuiObject") or c:IsA("UIGridStyleLayout") then c:Destroy() end
		end
		state.records = {}
		local large = Settings.view == "large"
		header.Visible = not large
		scroll.Size = large and UDim2.fromScale(1, 1) or UDim2.new(1, 0, 1, -30)
		scroll.Position = large and UDim2.new() or UDim2.fromOffset(0, 30)
		if large then
			listLayout = new("UIGridLayout", { CellSize = UDim2.fromOffset(100, 104), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
		else
			listLayout = new("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
			layoutHeader()
		end
		local scrollPad = scroll:FindFirstChildOfClass("UIPadding") or pad(scroll, 6, 6, 6, 6)
		scrollPad.Parent = scroll

		local filter = searchBox.Text:lower()
		local folders, files = {}, {}
		for _, p in FS.children(path) do
			local nm = baseName(p)
			if filter == "" or nm:lower():find(filter, 1, true) then
				if FS.isFolder(p) then table.insert(folders, { nm, p }) else table.insert(files, { nm, p }) end
			end
		end
		local key, asc = Settings.sortKey, Settings.sortAsc
		if key == "size" then for _, f in files do FS.size(f[2]) end end
		local function cmp(a, b)
			local av, bv
			if key == "type" then
				av, bv = typeName(a[1], false):lower(), typeName(b[1], false):lower()
				if av == bv then av, bv = a[1]:lower(), b[1]:lower() end
			elseif key == "size" then
				av, bv = sizeCache[a[2]] or 0, sizeCache[b[2]] or 0
				if av == bv then av, bv = a[1]:lower(), b[1]:lower() end
			else
				av, bv = a[1]:lower(), b[1]:lower()
			end
			if asc then return av < bv else return av > bv end
		end
		table.sort(folders, function(a, b) if asc then return a[1]:lower() < b[1]:lower() end return a[1]:lower() > b[1]:lower() end)
		table.sort(files, cmp)

		local order = 0
		for _, f in folders do order += 1 table.insert(state.records, makeRecord(f[1], f[2], true, order)) end
		for _, f in files do order += 1 table.insert(state.records, makeRecord(f[1], f[2], false, order)) end
		for p in state.selected do if not recordFor(p) then state.selected[p] = nil end end
		if order == 0 then
			new("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = filter ~= "" and "No items match your search." or "This folder is empty.", Font = FONT, TextSize = 13, TextColor3 = T.textDim, LayoutOrder = 1 }, scroll)
		end
		highlightSidebar()
		refreshVisuals()

		-- fill in sizes in the background
		sizeJob += 1
		local job = sizeJob
		if Settings.showSize and not large then
			local recs = state.records
			task.spawn(function()
				local n = 0
				for _, rec in recs do
					if job ~= sizeJob or not gui.Parent then return end
					if not rec.isDir and rec.sizeLabel and rec.sizeLabel.Parent then
						local had = sizeCache[rec.path] ~= nil
						rec.sizeLabel.Text = fmtBytes(FS.size(rec.path))
						if not had then
							n += 1
							if n % 6 == 0 then task.wait() end
						end
					end
				end
				if not statusMsgActive and statusLabel.Parent then statusLabel.Text = baseStatus() end
			end)
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if state.suppressSearch then return end
		render(state.current, true, true)
	end)

	----------------------------------------------------------------- window buttons, drag, resize
	local minimized, maximized = false, false
	local restore = { size = window.Size, pos = window.Position }
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		for _, f in { toolbar, cmdbar, body, status, grip } do f.Visible = not minimized end
		if minimized then
			restore.size = window.Size
			window.Size = UDim2.fromOffset(window.AbsoluteSize.X, 40)
		else
			window.Size = maximized and UDim2.new(1, 0, 1, 0) or restore.size
		end
	end)
	local function setMaximized(v)
		if minimized then return end
		maximized = v
		if maximized then
			restore.size, restore.pos = window.Size, window.Position
			window.Size, window.Position = UDim2.new(1, 0, 1, 0), UDim2.new()
		else
			window.Size, window.Position = restore.size, restore.pos
		end
		setGlyph(maxGlyph, maximized and "restore" or "max")
		grip.Visible = not maximized
	end
	maxBtn.MouseButton1Click:Connect(function() setMaximized(not maximized) end)
	closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
	do
		local dragging, startPos, startMouse, lastTitleClick = false, nil, nil, 0
		titlebar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				local mx, my = mousePos()
				if pointIn(minBtn, mx, my) or pointIn(maxBtn, mx, my) or pointIn(closeBtn, mx, my) then return end
				local now = os.clock()
				if now - lastTitleClick < 0.35 then lastTitleClick = 0 setMaximized(not maximized) return end
				lastTitleClick = now
				if not maximized then dragging = true startPos = window.Position startMouse = UIS:GetMouseLocation() end
			end
		end)
		local resizing, startSize, resizeMouse = false, nil, nil
		grip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = true
				startSize = window.AbsoluteSize
				resizeMouse = UIS:GetMouseLocation()
			end
		end)
		track(UIS.InputChanged:Connect(function(i)
			if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if dragging then
				local d = UIS:GetMouseLocation() - startMouse
				window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			elseif resizing then
				local d = UIS:GetMouseLocation() - resizeMouse
				window.Size = UDim2.fromOffset(math.max(640, startSize.X + d.X), math.max(380, startSize.Y + d.Y))
			end
		end))
		track(UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false resizing = false end
		end))
	end

	----------------------------------------------------------------- keyboard + global clicks
	local DIGITS = { Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9" }
	track(UIS.InputBegan:Connect(function(input, processed)
		if not gui.Parent then return end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 then
			if menuFrame then
				local x, y = mousePos()
				if not pointIn(menuFrame, x, y) then
					task.defer(function() if t == Enum.UserInputType.MouseButton1 then closeMenu() end end)
				end
			end
			local x, y = mousePos()
			state.focused = pointIn(window, x, y)
			return
		end
		if t ~= Enum.UserInputType.Keyboard then return end
		-- typing in a box (rename, address, search, editor) or a key that just confirmed one
		if processed or UIS:GetFocusedTextBox() or os.clock() < state.keyGuard or state.renaming then return end
		if not state.focused or state.modalCount > 0 then return end

		local k = input.KeyCode
		local ctrl, shift, alt = ctrlDown(), shiftDown(), altDown()
		local sel = selectedPaths()

		if k == Enum.KeyCode.Escape then
			if drag then endDrag(false) elseif menuFrame then closeMenu() else state.selected = {} refreshVisuals() end
		elseif k == Enum.KeyCode.Delete then
			confirmDelete(sel)
		elseif k == Enum.KeyCode.F2 then
			if #sel == 1 then startRename(sel[1]) end
		elseif k == Enum.KeyCode.F5 then
			sizeCache = {}
			render(state.current, true, true)
		elseif k == Enum.KeyCode.Backspace or (alt and k == Enum.KeyCode.Up) then
			goUp()
		elseif alt and k == Enum.KeyCode.Left then
			goBack()
		elseif alt and k == Enum.KeyCode.Right then
			goForward()
		elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter then
			if alt then
				showProperties(sel)
			elseif #sel == 1 then
				local rec = recordFor(sel[1])
				if rec then openItem(rec) end
			end
		elseif ctrl and k == Enum.KeyCode.A then selectAll()
		elseif ctrl and k == Enum.KeyCode.C then doCopy(false)
		elseif ctrl and k == Enum.KeyCode.X then doCopy(true)
		elseif ctrl and k == Enum.KeyCode.V then doPaste()
		elseif ctrl and k == Enum.KeyCode.D then doDuplicate()
		elseif ctrl and shift and k == Enum.KeyCode.N then doNewFolder()
		elseif ctrl and k == Enum.KeyCode.L then
			editAddress()
		elseif ctrl and k == Enum.KeyCode.F then
			searchBox:CaptureFocus()
		elseif k == Enum.KeyCode.Up or k == Enum.KeyCode.Down or k == Enum.KeyCode.Left or k == Enum.KeyCode.Right or k == Enum.KeyCode.Home or k == Enum.KeyCode.End then
			local n = #state.records
			if n == 0 then return end
			local i = state.anchor or 0
			local perRow = 1
			if Settings.view == "large" then perRow = math.max(1, math.floor((scroll.AbsoluteSize.X - 12) / 106)) end
			if k == Enum.KeyCode.Down then i = math.min(n, i + perRow)
			elseif k == Enum.KeyCode.Up then i = math.max(1, i - perRow)
			elseif k == Enum.KeyCode.Right and Settings.view == "large" then i = math.min(n, i + 1)
			elseif k == Enum.KeyCode.Left and Settings.view == "large" then i = math.max(1, i - 1)
			elseif k == Enum.KeyCode.Home then i = 1
			elseif k == Enum.KeyCode.End then i = n
			else return end
			if shift and state.anchor then
				state.selected[state.records[i].path] = true
				state.anchor = i
				refreshVisuals()
			else
				selectOnly(state.records[i].path)
			end
		elseif not ctrl and not alt then
			-- type-to-select
			local ch = #k.Name == 1 and k.Name:lower() or DIGITS[k.Name]
			if ch then
				local now = os.clock()
				if now - state.typeTime > 1 then state.typeBuffer = "" end
				state.typeTime = now
				state.typeBuffer ..= ch
				for _, rec in state.records do
					if rec.name:lower():sub(1, #state.typeBuffer) == state.typeBuffer then
						selectOnly(rec.path)
						break
					end
				end
			end
		end
	end))

	----------------------------------------------------------------- rebuild (theme change keeps the folder, history and window)
	rebuild = function()
		local c = {
			path = state.current, history = state.history, idx = state.idx, clipboard = state.clipboard,
			size = window.Size, pos = window.Position,
		}
		gui:Destroy()
		Raster.cache = {}
		build(c)
	end

	----------------------------------------------------------------- go
	rebuildSidebar()
	render(carry.path or "", carry.path ~= nil, false)
	if not Raster.ok then setStatus("EditableImage isn't available here, so icons use the simple style.") end
end

build()
