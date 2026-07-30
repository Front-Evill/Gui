# Vanta

Vanta is a UI library for Roblox scripts. It provides a window system with
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

## Table of contents

- [Window](#window)
- [Tabs](#tabs)
- [Sections](#sections)
- [Elements](#elements)
  - [Button](#button)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [MultiDropdown](#multidropdown)
  - [Keybind](#keybind)
  - [Input](#input)
  - [Paragraph](#paragraph)
  - [CodeBlock](#codeblock)
  - [Links](#links)
  - [Divider](#divider)
  - [ColorPicker](#colorpicker)
  - [ProgressBar](#progressbar)
- [Tooltips](#tooltips)
- [Notifications](#notifications)
- [Dialogs](#dialogs)
- [Config saving and loading](#config-saving-and-loading)
- [SafeFind and SafePlayer](#safefind-and-safeplayer)
- [Theming](#theming)
- [Icons](#icons)
- [Project structure](#project-structure)
- [Building from source](#building-from-source)
- [Sources and credits](#sources-and-credits)

## Window

```lua
local Window = Library:Window({
	Title = "Vanta Hub",
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
| `Title` | string | `"Vanta"` | Window title, shown white in the top bar. |
| `SubTitle` | string | `""` | Secondary text next to the title, shown in grey. |
| `TabWidth` | number | `160` | Width of the sidebar when tabs are vertical. |
| `Size` | UDim2 | `UDim2.fromOffset(830, 525)` | Base window size. Automatically scaled down on small screens. |
| `Resize` | boolean | `false` | Adds a drag handle in the bottom-right corner. |
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

## Sections

```lua
local Section = MainTab:AddSection({ Name = "General", Icon = "settings", Box = true })
```

A section is a titled box that holds elements. `Box` (boolean, default
`true`) controls whether the bordered background box is drawn around the
elements; set it to `false` for a plain, unboxed list. Elements added to a
section appear as individually boxed rows stacked inside it.

## Sections (box tiles)

```lua
local Combat = MainTab:AddSectionsBox({ Name = "Combat", Image = "sword" })
local Movement = MainTab:AddSectionsBox({ Name = "Movement", Image = "move" })

Combat:AddButton({ Name = "Attack", Callback = function() end })
Movement:AddSlider("Speed", { Default = 5, Min = 0, Max = 20 })
```

`AddSectionsBox` creates a compact card with a small icon box and a title
below it, instead of a normal section. Cards are transparent with a thin
black outline until hovered, and two fit per row with generous spacing
between them. Clicking a card fades the whole tab's normal content out and
fades the card's elements in, with a back arrow (top-right) to return. Only
one card can be open at a time per tab. The returned object supports every
element method a regular section does (`AddButton`, `AddToggle`,
`AddSlider`, `AddDropdown`, etc.) since it's the same underlying Section
type.

`Name`/`Title` sets the card's title, `Image`/`Icon`/`Id` sets the picture
(accepts an icon name, a raw asset id, or a `rbxassetid://`/roblox.com
link, same as everywhere else in the library). Regular `AddSection` calls in
a tab that also uses `AddSectionsBox` keep working normally and fade
together with the card grid.

## Elements

All elements accept an optional `Tooltip` string and, where noted, an
optional `Flag` string used by the config system.

### Button

```lua
Section:AddButton({
	Name = "Delete data",
	Description = "Removes your saved data",
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

### Toggle

```lua
local MyToggle = Section:AddToggle({
	Name = "Enable feature",
	Description = "Turns the feature on or off",
	Default = false,
	Flag = "EnableFeature",
	Callback = function(value)
		print("toggle:", value)
	end,
})

MyToggle:Set(true)
MyToggle:Get()
```

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
	Flag = "Region",
	Callback = function(value)
		print("selected:", value)
	end,
})
```

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
	Numeric = false,
	Finished = false,
	Flag = "Username",
	Callback = function(value)
		print("typed:", value)
	end,
})
```

`Numeric` strips non-digit characters as the user types. `Finished` changes
the callback to fire only when Enter is pressed, instead of on every
keystroke.

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
local Window = Vanta:CreateWindow({ Title = "My Script" })

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

This is a theme switcher: it shows one swatch per built-in preset, and
picking one applies it to the whole window immediately through
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
	icone = true, -- or a table: { Work = true, IdIcon = "check", Type = "up" }
	SoundID = "9125826312",
	SoundVolume = 0.6,
})
```

`icone.Type` is `"up"` or `"down"`, controlling which corner of the screen
notifications stack from. Leaving out `Duration` keeps the notification
visible until the user closes it manually — passing `Duration` also shows a
thin progress bar along the bottom edge that drains down as time runs out.

The title is always shown in a clear white, `Content` in the theme's gray
description color, and `SubContent` slightly dimmer still for a clean
three-level hierarchy. A colored accent bar marks the left edge, and the
icon (when enabled) sits in a tinted rounded badge instead of floating on
its own.

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

## Project structure

```
src/Vanta/
  init.lua      entry point, composes all modules into the returned library
  Window.lua    window creation, theming, tabs, top bar controls
  Tab.lua       tab object and section creation
  Section.lua   all interactive elements
  Notify.lua    notification system
  Dialog.lua    modal dialogs
  Config.lua    save/load system
  Acrylic.lua   translucent background effect
  Theme.lua     color resolution and built-in presets
  Icons.lua     icon name resolution and the Lucide id table
  Keybinds.lua  keybind string/enum conversion
  Utils.lua     shared helpers (instance creation, dragging, tweening, tooltips)
dist/main.lua   bundled, single-file build produced from src/
build.py        the bundler
```

The source is organized as real Roblox ModuleScripts using `require`, so it
can be synced into Studio with Rojo (`default.project.json` is included) for
local development and testing.

## Building from source

```
python3 build.py
```

This reads every file under `src/Vanta`, resolves the `require` calls
between them, and writes a single self-contained `dist/main.lua`. The GitHub
Actions workflow in `.github/workflows/release.yml` runs this automatically
on every push to `main` and publishes the result as the `latest` release
asset, which is what the installation link at the top of this document
points to.

## Sources and credits

- Icons: Lucide, MIT licensed, https://lucide.dev
- Roblox API reference: https://create.roblox.com/docs/reference/engine
- Asset uploads: https://create.roblox.com/