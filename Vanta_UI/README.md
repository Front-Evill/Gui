# Vanta

Vanta is a UI library for Roblox scripts. It gives you a complete window
system — tabs, sections, and a full set of interactive elements — so you can
build a clean script hub without writing UI code from scratch.

## Features

- **Window system** — draggable, resizable, minimizable, with an optional
  acrylic-style translucent background and a custom background image.
- **Tabs & sections** — organize settings into tabs and titled sections, or
  use `AddSectionsBox` for square image + title cards that expand into a
  full panel with a smooth fade animation.
- **Full element set** — buttons (with confirmation prompts), toggles,
  sliders, dropdowns, multi-dropdowns, keybinds, text inputs, color pickers,
  progress bars, dividers, and paragraphs.
- **Notifications & dialogs** — toast notifications and confirmation popups
  out of the box.
- **Config saving & loading** — persist every flagged element to a JSON file
  and restore it later with two function calls.
- **Theming** — a set of built-in color presets, or generate a theme from
  any accent color.

## Get started

The easiest way to grab the library and a ready-to-use loader script is
through the dashboard:

**[vanta-obf.netlify.app/dashboard](https://vanta-obf.netlify.app/dashboard)**

Everything you need to load Vanta into your script is available there.

## Documentation

Full API reference, every element's options, and code examples live in
**[Vanta.md](./Vanta.md)**. It covers:

- Window, tab, and section setup
- Every element type with its config fields
- Notifications, dialogs, and config save/load
- Theming and icons
- Project structure and building from source

## Example

A complete, ready-to-run example that demonstrates every feature across
multiple tabs is included at [`Vanta_Example.lua`](./Vanta_Example.lua).

```lua
local Window = Library:Window({
	Title = "Vanta Hub",
	Theme = "Purple",
	Acrylic = true,
})

local Tabs = Window:AddTab({
	Main = { Name = "Main", Icon = "home" },
	Settings = { Name = "Settings", Icon = "settings" },
})

local Section = Tabs.Main:AddSection({ Name = "General" })

Section:AddToggle({
	Name = "Enable feature",
	Default = false,
	Callback = function(value)
		print("toggled:", value)
	end,
})
```

## Sources & credits

- Icons — [Lucide](https://lucide.dev), MIT licensed.
- Roblox API reference — [create.roblox.com/docs](https://create.roblox.com/docs/reference/engine).
- Built and maintained by **FrontEvill**.

## Support

For questions, issues, or the latest builds, use the dashboard linked above.
