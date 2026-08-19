# Devlyx

Devlyx is a UI library for Roblox scripts. It provides a window system with
tabs, sections, and a full set of interactive elements (buttons, toggles,
sliders, dropdowns, keybinds, text inputs, color pickers, progress bars),
along with notifications, confirmation dialogs, a config save/load system,
and an acrylic-style translucent background effect.

## Installation

Load the latest build directly into an executor or LocalScript:

```lua
local Library = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/main.lua"))()
```

This link always points to the most recently built version on the `main`
branch. Every push to `main` triggers a rebuild and republishes the `latest`
release automatically.

Every GUI instance the library creates has `AutoLocalize` disabled
automatically, so Roblox's in-game translation system never rewrites the
interface text (titles, buttons, labels, etc.) into another language.

## Table of contents

- [Window](#window)
- [Tabs](#tabs)
- [SubTabs](#subtabs)
- [Sections](#sections)
- [Elements](#elements)
  - [Button](#button)
  - [Toggle](#toggle)
  - [ToggleGroup](#togglegroup)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [MultiDropdown](#multidropdown)
  - [DropdownGroup](#dropdowngroup)
  - [Keybind](#keybind)
  - [Input](#input)
  - [Paragraph](#paragraph)
  - [CodeBlock](#codeblock)
  - [Links](#links)
  - [Divider](#divider)
  - [ColorPicker](#colorpicker)
  - [ProgressBar](#progressbar)
  - [BoxInfo](#boxinfo)
- [Tooltips](#tooltips)
- [Notifications](#notifications)
- [Dialogs](#dialogs)
- [Config saving and loading](#config-saving-and-loading)
- [Add-ons](#add-ons)
- [SafeFind and SafePlayer](#safefind-and-safeplayer)
- [Theming](#theming)
- [Icons](#icons)
- [Project structure](#project-structure)
- [Building from source](#building-from-source)
- [Sources and credits](#sources-and-credits)

## Window

```lua
local Window = Library:Window({
	Title = "Devlyx Hub",
	SubTitle = "roblox interface",
	TabWidth = 160,
	Size = UDim2.fromOffset(830, 525),
	Resize = true,
	Acrylic = true,
	Theme = "Purple",
	MinimizeKey = Enum.KeyCode.P,
	Search = false,
	Stats = true,
	Animation = true,
	icno = { work = true, IdIcon = "", Size = 44 },
	Background = { work = true, id = "rbxassetid://0" },
})
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | string | `"Devlyx"` | Window title, shown white in the top bar. |
| `SubTitle` | string | `""` | Secondary text next to the title, shown in grey. |
| `TabWidth` | number | `160` | Width of the sidebar when tabs are vertical. |
| `Size` | UDim2 | `UDim2.fromOffset(830, 525)` | Base window size. Automatically scaled down on small screens. |
| `Resize` | boolean | `false` | Lets the window be resized by dragging any edge or corner. |
| `Acrylic` | boolean | `false` | Enables a translucent, blurred background behind the window. |
| `Theme` | string or table | `"Dark"` | A preset name (see Theming), `"All"` for a random preset, or a custom theme table. |
| `MinimizeKey` | Enum.KeyCode | none | Keyboard key that shows/hides the whole window. |
| `Search` | boolean | `false` | Adds a search icon above the tab list to filter tabs by name. |
| `Animation` | boolean | `true` | When `false`, every animation in the interface (hovers, toggles, dropdowns, box-section transitions, notifications, dialogs) applies instantly instead of tweening. Can also be changed at runtime with `Window:SetAnimation(enabled)`. |
| `Stats` | boolean | `true` | Adds a small icon in the top bar that opens a popup with the player's avatar, name, FPS, and current player count. |
| `icno` | table | none | Floating toggle icon shown outside the window. |
| `Background` | table | none | Background image behind the window. |

`icno` fields: `work` (boolean, enables the floating icon), `IdIcon` (icon
name or asset id, empty for a plain circle), `Size` (number, icon diameter in
pixels, default 44).

`Background` fields: `work` (boolean, enables the background image), `id`
(asset id shown behind the window, matching the window's own transparency).
A dark scrim always sits between the image and everything else, so tabs,
buttons, and text stay readable no matter how bright or busy the image is —
it dims the image rather than letting it show through at full strength.

The window also has three built-in controls in the top-right corner: close,
maximize/restore, and collapse/expand. Collapsing shrinks the window down to
just the top bar, which stays draggable; the same button restores it.

### Window methods

```lua
Window:SetTheme("Rose")
Window:SetTitle("New title")
Window:SetSubTitle("New subtitle")
Window:SelectTab("Main")
Window:Destroy()
```

`Acrylic` only does work when something actually needs to change: it skips
its per-frame update entirely while the window is minimized or hidden, and
only recomputes the glass effect when the camera or the window has actually
moved, instead of recalculating on every rendered frame.

## Tabs

```lua
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })

-- or in bulk:
local Tabs = Window:AddTab({
	Main = { Name = "Main", Icon = "home" },
	Settings = { Name = "Settings", Icon = "settings" },
})
```

`Title` can be used interchangeably with `Name`. Tabs are placed as a
vertical sidebar when the window is wide, or as a horizontal strip at the top
when the window is closer to square, chosen automatically from the window's
aspect ratio.

Switching tabs crossfades the content as one block — the whole previous
page fades out while the new one fades in, instead of an instant cut — and
the indicator bar grows in from the middle of the active tab rather than
just fading in place. Leaving out both `Name` and `Title` makes an
icon-only tab: just the icon, centered, no label and no reserved space for
one. If every tab in the window is icon-only, tab switching (indicator,
crossfade, and hover highlight) becomes instant instead, since there's no
label for the animation to draw attention to. As soon as any tab in the
window has a name, normal animated switching resumes for all of them.

## SubTabs

```lua
local General = MainTab:AddSubTab({ Name = "General", Icon = "settings" })
local Advanced = MainTab:AddSubTab({ Name = "Advanced", Icon = "sliders" })

General:AddToggle({ Name = "Enable feature", Default = false })
Advanced:AddSlider("Speed", { Default = 5, Min = 0, Max = 20 })
```

`AddSubTab` splits a single tab into its own set of sub-pages, each with its
own top bar button. The first call creates a slim button bar at the top of
the tab; every following call adds another button next to it. Clicking a
button crossfades to that sub-tab's content in place — nothing else in the
tab moves or resizes, and only one sub-tab is visible at a time. The first
`AddSubTab` call is selected by default.

The active button shows a thin accent-colored underline and its label/icon
switch to the theme's accent color; hovering an inactive button turns its
label/icon white. Both the underline and the color switch tween smoothly
(unless `Animation = false`), alongside the content crossfade, so moving
between sub-tabs feels like one continuous transition.

If there are more sub-tabs than fit in the window's width, the button bar
scrolls horizontally on its own (drag or mouse wheel), the same way the
main tab sidebar scrolls when it runs out of vertical space. Selecting a
sub-tab that's scrolled out of view — including via code, not just a click
— automatically scrolls it back into view.

`Name`/`Title` sets the button's label and `Icon` is optional (any Lucide
icon name, asset id, or link, same as everywhere else). The returned object
supports every element method a regular section does (`AddButton`,
`AddToggle`, `AddSlider`, `AddDropdown`, etc.) since it's the same
underlying Section type — there's no need to also wrap it in `AddSection`.

## Sections

```lua
local Section = MainTab:AddSection({ Name = "General", Icon = "settings" })
```

A section is a titled group that holds elements. There's no bordered
background box around the group anymore — elements are laid out directly
under the title, each with its own thin outline.

## Sections (box tiles)

```lua
local Combat = MainTab:AddSectionsBox({ Name = "Combat", Image = "sword", Description = "Combat related tools" })
local Movement = MainTab:AddSectionsBox({ Name = "Movement", Image = "move" })

Combat:AddButton({ Name = "Attack", Callback = function() end })
Movement:AddSlider("Speed", { Default = 5, Min = 0, Max = 20 })
```

`AddSectionsBox` creates a compact card with a large icon/image, a title,
and an optional description below it, instead of a normal section. Cards
are transparent with a thin black outline until hovered, and two fit per
row with generous spacing between them. Clicking a card fades the whole
tab's normal content out and fades the card's elements in, with a back
arrow (top-right) to return. Only one card can be open at a time per tab.
The returned object supports every element method a regular section does
(`AddButton`, `AddToggle`, `AddSlider`, `AddDropdown`, etc.) since it's the
same underlying Section type.

`Name`/`Title` sets the card's title, `Image`/`Icon`/`Id` sets the picture
(accepts an icon name, a raw asset id, or a `rbxassetid://`/roblox.com
link, same as everywhere else in the library), and `Description`/`SubTitle`
sets an optional line of text under the title. The title is always shown
in clear white and the description in the theme's neutral gray, regardless
of the active theme. Regular `AddSection` calls in a tab that also uses
`AddSectionsBox` keep working normally and fade together with the card
grid.

## Elements

All elements accept an optional `Tooltip` string and, where noted, an
optional `Flag` string used by the config system.

### Button

```lua
Section:AddButton({
	Name = "Delete data",
	Description = "Removes your saved data",
	-- Icon = "settings", -- optional: override the default mouse-pointer icon
	Callback = function()
		print("deleted")
	end,
	--[[
	Confirm = {
		Title = "Are you sure?",
		Content = "This cannot be undone.",
		ConfirmText = "Delete",
		CancelText = "Cancel",
	}, ]]
})
```

If `Confirm` is set, the callback only runs after the user confirms in a
popup dialog. `Confirm.Buttons` can also be supplied directly, using the same
format as Dialogs, for full control over more than two buttons.

Every button always shows a small icon on the left (a mouse-pointer icon by
default) — there's no way to turn it off. Pass `Icon` with any Lucide icon
name (or asset id) to use a different one instead of the default.

Two `AddButton` calls made right after each other automatically share one
row, side by side, instead of stacking. Anything else added in between
breaks the pairing and both go back to full-width.

### Toggle

```lua
local MyToggle = Section:AddToggle({
	Name = "Enable feature",
	Description = "Turns the feature on or off",
	Default = false,
	-- Icon = "settings", -- optional: override the default icon
	Flag = "EnableFeature",
	Callback = function(value)
		print("toggle:", value)
	end,
})

MyToggle:Set(true)
MyToggle:Get()
```

The same auto-pairing as `AddButton` applies here too: two `AddToggle` calls
in a row share one line. Mixing the two also pairs up — a `Button` next to a
`Toggle` (in either order) always lands with the toggle on the left and the
button on the right.

### ToggleGroup

```lua
local Aimbot = Section:AddToggleGroup({
	Name = "Enable Aimbot",
	Description = "Locks onto the nearest target",
	Default = false,
	Flag = "AimbotEnabled",
	Callback = function(value)
		print("aimbot:", value)
	end,
})

Aimbot:AddSlider("FOV", { Default = 50, Min = 0, Max = 100 })
Aimbot:AddButton({ Name = "Panic Key" })
Aimbot:AddToggle({ Name = "Team Check" })
```

A regular toggle — same look, same `Set`/`Get`/`Flag`/`Callback`, same
pairing rules as `AddToggle` above — that also acts as a section. Whatever
you bind to it (`AddSlider`, `AddButton`, `AddToggle`, even another
`AddDropdownGroup`) appears right underneath it, but only while the toggle
itself is on. Flip it off and that content disappears with it; flip it back
on and it comes back. Like `DropdownGroup`, the bound content fades in and
out as a single block regardless of what or how many things are inside it,
so nothing pops in half-built. `Default = true` starts it already on and
expanded, with no animation on load.

Unlike `DropdownGroup`, there's no separate open/close click — the toggle's
own on/off state *is* what shows or hides the content, so it's one control
instead of two.

### Slider

```lua
local MySlider = Section:AddSlider("Speed", {
	Title = "Speed",
	Description = "Movement speed multiplier",
	Default = 2,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Flag = "Speed",
	Callback = function(value)
		print("slider:", value)
	end,
})
```

### Dropdown

```lua
local Region = Section:AddDropdown({
	Name = "Region",
	Description = "Choose your region",
	Options = { "EU", "NA", "ASIA" },
	Default = "NA",
	-- Icon = "settings", -- optional: override the default icon
	Flag = "Region",
	Callback = function(value)
		print("selected:", value)
	end,
})

Region:SetOptions({ "EU", "NA", "ASIA", "SA" })
```

`SetOptions` replaces the option list in place (rebuilding the rows) without
needing to recreate the dropdown — useful for lists that change at runtime,
like a folder of saved configs. It keeps the current selection if it's still
in the new list, otherwise clears it. Works the same way on MultiDropdown.

The open option list highlights whichever option is currently selected — a
soft accent tint, a matching border, and a checkmark — so you can see the
active choice without closing it first, the same way MultiDropdown already
showed checkmarks for its picks. Every other row gets a plain card with an
accent hover. That highlight stays correct through anything: picking a
different option, calling `:Set()` in code, closing and reopening the list,
or switching the whole window's theme.

### MultiDropdown

```lua
local Tags = Section:AddMultiDropdown({
	Name = "Tags",
	Options = { "PvP", "PvE", "Trading", "Events" },
	Default = { "PvP" },
	Flag = "Tags",
	Callback = function(list)
		print(table.concat(list, ", "))
	end,
})
```

### DropdownGroup

```lua
local Combat = Section:AddDropdownGroup({
	Name = "Combat Settings",
	Icon = "swords",
	-- Description = "Optional subtitle under the title",
	-- Open = true, -- start expanded instead of collapsed
})

Combat:AddToggle({ Name = "Auto Parry", Default = false, Flag = "AutoParry" })
Combat:AddSlider("Reach", { Default = 10, Min = 0, Max = 30, Flag = "Reach" })
Combat:AddInput({ Name = "Webhook", Placeholder = "https://...", Flag = "Webhook" })
```

Visually it's a dropdown header (icon chip, title, chevron) that you click to
expand, but instead of picking from a list of option strings, whatever you
bind to it is shown inside once it opens. The returned object is a regular
section — call `AddButton`, `AddToggle`, `AddSlider`, `AddInput`,
`AddDropdown`, `AddColorPicker`, even another `AddDropdownGroup`, exactly
like you would on `Section` itself. No separate wiring step is needed.

The whole body fades in/out as one clean block when you open or close it, no
matter what's bound inside or how many elements there are, so nothing pops
in half-built or overlaps mid-animation. `Open = true` starts it expanded.
You can also drive it from code:

```lua
Combat:SetOpen(true)
Combat:Toggle()
print(Combat:IsOpen())
```

### Keybind

```lua
local Keybind = Section:AddKeybind("Toggle ESP", {
	Title = "Toggle ESP",
	Mode = "Toggle", -- "Always", "Toggle", or "Hold"
	Default = "LeftControl", -- key name, or "MB1"/"MB2"/"MB3" for mouse buttons
	Flag = "ESPKey",
	Callback = function(value)
		print("state:", value)
	end,
	ChangedCallback = function(newKey)
		print("rebound to:", newKey)
	end,
})
```

Clicking the key display lets the user rebind it live; press Escape to
cancel. Keybinds are automatically ignored while a text box is focused
elsewhere in the interface.

### Input

```lua
local NameInput = Section:AddInput("Username", {
	Title = "Username",
	Default = "",
	Placeholder = "Enter a name",
	Icon = "type",
	Numeric = false,
	Finished = false,
	Multiline = false,
	Flag = "Username",
	Callback = function(value)
		print("typed:", value)
	end,
})
```

`Numeric` strips non-digit characters as the user types. `Finished` changes
the callback to fire only when Enter is pressed, instead of on every
keystroke. Set `Multiline = true` for a taller text box that accepts line
breaks (use `Lines = N` to size it for roughly N lines instead of the
default); the callback still fires the same way either mode.

### Paragraph

```lua
Section:AddParagraph({
	Title = "Note",
	Content = "This is a plain block of descriptive text.",
})
```

### CodeBlock

```lua
local Snippet = Section:AddCodeBlock({
	Title = "Example usage",
	Description = "Paste this into your init script",
	Code = [[
local Window = Devlyx:Window({ Title = "My Script" })

local Tab = Window:AddTab({ Title = "Main" })
local Section = Tab:AddSection({ Title = "General" })

Section:AddButton({
	Name = "Click me",
	Callback = function()
		print("clicked")
	end,
})
]],
	Collapsed = false,
	CollapsedLines = 8,
	Tooltip = "A ready-to-copy snippet",
})
```

Displays a block of Luau code with VSCode-style dark syntax highlighting
(keywords, strings, numbers, comments, and function calls are colored
separately). The code box background is derived from the window's current
accent color (same technique as `Background`/`Secondary` in `Theme.lua`), so
it reads as a proper dark editor on every preset — Purple, Rose, Blue,
etc. — instead of a flat gray box, and it updates live if the theme changes
via `Window:SetTheme`. A copy icon in the top-right corner copies the raw
code to the clipboard (via `setclipboard`, when the executor supports it).
If the code has more lines than `CollapsedLines` (default `8`), a chevron
button also appears to expand/collapse the block; `Collapsed` controls
whether it starts collapsed or expanded.

- `Title` — optional heading shown above the code box, always rendered white.
- `Description` — optional line under the title, always rendered gray.
- `Code` — the Luau source to display.
- `Collapsed` — `true` to start collapsed (only applies if the snippet is
  long enough to collapse). Defaults to `false` (expanded).
- `CollapsedLines` — number of lines visible while collapsed. Defaults to `8`.
- `Tooltip` — optional tooltip text for the whole block.

`Snippet:SetExpanded(true/false)` and `Snippet:Set(newCode)` are available
on the returned handle to control it after creation.

### Links

```lua
local Discord = Section:AddLinks({
	Icon = "discord",
	Title = "Discord Server",
	Description = "Join our community for support",
	Link = "https://discord.gg/example",
	Tooltip = "Click to copy the invite link",
})
```

A row with an optional icon, a title (always white), an optional
description under it (always gray), and a copy button on the right that
copies `Link` to the clipboard (via `setclipboard`). Everything is sized
and centered explicitly, so the row height adapts cleanly whether you pass
an icon, a description, both, or neither, with no overlapping elements.

- `Icon` — optional icon name/id shown in an accent-tinted badge on the left.
- `Title` — the link's title text.
- `Description` — optional secondary line under the title.
- `Link` — the URL copied when the copy button is pressed.
- `Tooltip` — optional tooltip text for the whole row.

The returned handle exposes `:Set(newLink)`, `:SetTitle(newTitle)`, and
`:SetDescription(newDescription)` to update it after creation.

### Divider

```lua
Section:AddDivider()
```

A thin horizontal line for separating groups of elements within a section.

### ColorPicker

```lua
Section:AddColorPicker({
	Name = "Interface color",
	Description = "Pick a theme for the whole window",
	Default = "Purple",
	Flag = "InterfaceColor",
	Callback = function(presetName)
		print("theme changed to", presetName)
	end,
})
```

This is a theme switcher: it renders as a dropdown listing every built-in
preset, and picking one applies it to the whole window immediately through
`Window:SetTheme`.

### ProgressBar

```lua
local Progress = Section:AddProgressBar({
	Title = "Loading",
	Default = 0,
	Min = 0,
	Max = 100,
	ShowPercent = true,
})

Progress:Set(80)
```

Display only; update it from your own script as work completes.

### BoxInfo

```lua
Section:AddBoxInfo({
	Title = "Player Info",
	ShowAvatar = true,
	ShowUsername = true,
	ShowName = true,
	ShowJoined = true,
	ShowCountPlayers = true,
	ShowServerId = true,
	ShowNameGame = true,
	ShowIP = true,
})
```

Purely decorative, for showing off who's running the script and where. A
square avatar sits on the left; next to it, two columns of info — on the
left `Username`, `Name`, and `Joined` (the `LocalPlayer`'s account), on the
right `CountPlayers`, `ServerId`, and `NameGame` (the current server). Below
all of that, centered on its own line, `ip:` shows the machine's detected
public IP in small gray text — deliberately smaller and dimmer than
everything else, since it's the least important line on the card; every
other line is solid white so it stays easy to read regardless of theme.

Everything is filled in automatically: `Username`/`Name` come straight from
the player, `Joined` is worked out from `AccountAge`, `CountPlayers` reads
`Players:GetPlayers()`/`MaxPlayers`, `ServerId` is `game.JobId` (shown as
`"Studio"` when run outside a live server), `NameGame` is `game.Name`, and
`ip` comes from a quick lookup at startup (shows `"Detecting..."` for a
moment, falls back to `"Unknown"` if the request fails or `game:HttpGet`
isn't available in the environment). Each piece can be turned off
individually with its own `Show...` flag.

To skip the automatic IP lookup and set it yourself instead:

```lua
Section:AddBoxInfo({
	Title = "Player Info",
	IP = "1.2.3.4",
})
```

`Title` adds a centered heading above the card: a line on each side with
the text in the middle, the same way a "── Settings ──" style divider
looks. The two side-lines automatically get shorter as the title text gets
longer, so it always stays centered no matter how long the title is.

Pass `Image` (an asset id, a full `rbxassetid://` string, or a Roblox link —
same as `Icon` everywhere else) to replace the avatar with your own picture,
e.g. a Discord/server logo instead of the player's headshot:

```lua
Section:AddBoxInfo({
	Title = "Join our Discord",
	Image = 15571818071, -- your server icon's asset id
	ShowUsername = false,
	ShowName = false,
	ShowJoined = false,
})
```

When `Image` is set, the avatar box is drawn bigger (since it's no longer a
small face-only headshot) and shown with no background fill or theme tint
behind it at all — just the picture, exactly as uploaded, since a logo like
that needs to stay recognizable.

Call `:Refresh()` on the returned object to re-read everything (player
info, server info, avatar) if you ever need to force an update.

## Tooltips

Any element above accepts a `Tooltip` string. A small label follows the
mouse while hovering that element and disappears on mouse leave.

## Notifications

```lua
Window:Notify({
	Title = "Notification",
	Content = "This is a notification",
	SubContent = "Optional secondary line",
	Duration = 5,
	idsound = "9125826312",
	Loopsound = false,
	Volumesound = 0.6,
	Speedsound = 1,
})
```

Notifications always stack from the bottom-right corner of the screen.
Leaving out `Duration` keeps the notification visible until the user
closes it manually.

`idsound` plays a sound alongside the notification (a raw asset id or a
`rbxassetid://...` string, same as everywhere else in the library).
`Loopsound` (default `false`) keeps it looping instead of playing once —
useful for alert-style notifications the user has to dismiss manually.
`Volumesound` (default `1`) and `Speedsound` (default `1`, playback speed)
are optional. Leaving `idsound` out plays no sound at all.

Each card shows a title and, optionally, a description (`Content`) and a
secondary line (`SubContent`) — there is no icon, no accent bar, and no
countdown/progress bar. The title is always shown in a clear white, and
both `Content` and `SubContent` in a fixed neutral gray, regardless of the
active theme.

## Dialogs

```lua
Window:Dialog({
	Title = "Confirm action",
	Content = "Are you sure you want to continue?",
	Buttons = {
		{ Title = "Confirm", Callback = function() print("confirmed") end },
		{ Title = "Cancel", Callback = function() print("cancelled") end },
	},
})
```

A modal popup with a dimmed backdrop and any number of buttons, each with its
own callback.

## Config saving and loading

Any element created with a `Flag` option is registered automatically. Saving
writes every flagged element's current value to a JSON file; loading reads
it back and applies it.

```lua
Window:SaveConfig("Profile1")
Window:LoadConfig("Profile1")
```

This requires an executor that provides `writefile`/`readfile`. If those are
not available, the library shows a notification explaining that saving is
not supported in the current environment instead of erroring.

## Add-ons

Two optional, standalone modules ship in `dist/` alongside `main.lua`. Load
them the same way, then attach them to any tab:

```lua
local Library = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/InterfaceManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/SaveManager.lua"))()

local Window = Library:Window({ Title = "My Hub" })
local SettingsTab = Window:AddTab({ Name = "Settings" })

InterfaceManager:SetLibrary(Window)
InterfaceManager:CreateInterfaceSection(SettingsTab)

SaveManager:SetLibrary(Window)
SaveManager:CreateConfigSection(SettingsTab)
```

**InterfaceManager** adds a section with a theme dropdown and toggles for
`Search`, `Resize`, `Stats`, and `Animation`, and persists the chosen
values to disk automatically. Call `SetFolder("MyHub")` before
`CreateInterfaceSection` to change where its settings file is written.

**SaveManager** adds a section with a config name field, a dropdown of
previously saved configs, and Save/Load/Refresh buttons, built on top of
`Window:SaveConfig`/`Window:LoadConfig`. Call `SetFolder("MyHub")` before
`CreateConfigSection` to change the folder configs are written to.

Both modules only need `SetLibrary(Window)` and their `Create...Section(Tab)`
call — nothing else has to be wired up manually.

## SafeFind and SafePlayer

Helpers that avoid hard script crashes from bad paths or missing players,
notifying the user instead of throwing.

```lua
local part = Window:SafeFind(workspace, "Map", "Spawn", "Part")
local target = Window:SafePlayer("SomeUsername")
```

## Theming

Built-in presets: `Dark`, `Purple`, `Rose`, `Blue`, `Green`, `Orange`,
`Cyan`, `Gold`. Pass a preset name, `"All"` (or `"Random"`) to pick one at
random on load, or a custom table:

```lua
Theme = { Accent = "#FF6B00" } -- rest of the palette is generated from this
```

A full custom table with `Background`, `Secondary`, `Accent`, `TitleColor`,
`DescColor`, `SectionColor`, and `Transparency` is also accepted for complete
control. Change the theme at runtime at any point with `Window:SetTheme(...)`.

## Icons

Icon names come from the Lucide icon set. Browse available icons and their
exact names here:

https://lucide.dev/icons

Use the name as shown on that site, with or without the `FrontEvill-` prefix:

```lua
Icon = "home"
Icon = "shopping-cart"
```

If an icon does not appear in the interface, that name is not part of the
available set.

For anything not in Lucide, upload the image as a decal through Roblox
Create, then use its asset id directly:

https://create.roblox.com/

Once uploaded, use either of these forms:

```lua
Icon = "https://www.roblox.com/asset/?id=YOUR_ASSET_ID"
Icon = "YOUR_ASSET_ID"
```

This reads every file under `src/Devlyx`, resolves the `require` calls
between them, and writes a single self-contained `dist/main.lua`. The GitHub
Actions workflow in `.github/workflows/release.yml` runs this automatically
on every push to `main` and publishes the result as the `latest` release
asset, which is what the installation link at the top of this document
points to.

## Sources and credits

- Icons: Lucide, MIT licensed, https://lucide.dev
- Roblox API reference: https://create.roblox.com/docs/reference/engine
- Asset uploads: https://create.roblox.com/
