local function ResolveKeybind(name)
	if not name or name == "" then
		return nil, nil
	end

	if name == "MB1" then
		return Enum.UserInputType.MouseButton1, "MouseButton"
	end

	if name == "MB2" then
		return Enum.UserInputType.MouseButton2, "MouseButton"
	end

	if name == "MB3" then
		return Enum.UserInputType.MouseButton3, "MouseButton"
	end

	local ok, keycode = pcall(function()
		return Enum.KeyCode[name]
	end)

	if ok and keycode then
		return keycode, "KeyCode"
	end

	return nil, nil
end

local function KeybindDisplayName(boundValue, boundType)
	if not boundValue then
		return "None"
	end

	if boundType == "MouseButton" then
		if boundValue == Enum.UserInputType.MouseButton1 then
			return "MB1"
		elseif boundValue == Enum.UserInputType.MouseButton2 then
			return "MB2"
		elseif boundValue == Enum.UserInputType.MouseButton3 then
			return "MB3"
		end
	end

	return boundValue.Name
end

return {
	ResolveKeybind = ResolveKeybind,
	KeybindDisplayName = KeybindDisplayName,
}
