-- This plugin generates AwesomeWM hotkey menu files for use
-- with the Dynamic AwesomeWM Hotekey Menu plugin

-- The ~/.config/nvim/awesome_hotkeys is the default location the Awesome
-- dynamic hotkeys will be loaded from
local config_path = vim.fn.stdpath('config')
local keymap_menus_path = config_path .. "/awesome_hotkeys"
local program_header = "NVIM: "

if vim.fn.isdirectory(keymap_menus_path) == 0 then
    vim.fn.mkdir(keymap_menus_path, "p")
end

local awesome_hotkey = {}
awesome_hotkey.desc_format = "%s: %s"

-- The description field for keymaps need to contain a common keyword
-- to uniquely identify that group of keymaps
local function filter_keymaps_by_name(module_name, mode)
    local all_keymaps = vim.api.nvim_get_keymap(mode)
    local filtered_keymaps = {}
    for _, map in ipairs(all_keymaps) do
        if string.match(map.desc or "", "^" .. module_name) then
            table.insert(filtered_keymaps, map)
        end
    end
    return filtered_keymaps
end

-- We need to replace special characters and create a modifier mapping
-- compatible with the Awesome hotkey format
local function extract_modifiers_and_key(keymap_str)
    local modifiers = {}
    local key = keymap_str

    local mod_map = {
        ["%<C%-"] = "Ctrl",
        ["%<M%-"] = "Meta",
        ["%<A%-"] = "Alt",
        ["%<S%-"] = "Shift",
    }


    for mod_key, mod_name in pairs(mod_map) do
        if string.find(key, mod_key) then
            table.insert(modifiers, mod_name)
            key = string.gsub(key, mod_key, "")
        end
    end

    for _, modifier in ipairs({"Ctrl", "Meta", "Alt", "Shift"}) do
        if table.concat(modifiers, "-"):find(modifier) then
            local prefix = string.sub(modifier, 1, 1)
            key = key:gsub("^" .. prefix .. "%-", "")
        end
    end

    if string.find(key, "<leader>") then
        local leader_key = vim.g.mapleader or "\\"
        key = key:gsub("<leader>", leader_key)
    end

    if string.find(key, " ") then
        key = key:gsub(" ", "Space ")
    end

    key = key:gsub(">$", "")
    key = key:gsub("^%s*(.-)%s*$", "%1")
    return modifiers, key
end

local function write_hotkeys_file(module_name, final_format)
    local file_path = keymap_menus_path .. "/" .. module_name .. ".ahk"
    local file, err = io.open(file_path, "w")

    if not file then
        return
    end

    local output_str = 'return function()\n'
    output_str = output_str .. '    return {\n'
    output_str = output_str .. '        ["' .. program_header .. module_name .. '"] = {\n'
    for _, mappings in ipairs(final_format) do
	    output_str = output_str .. "    {\n"
	    output_str = output_str .. "    modifiers = {\"" .. table.concat(mappings.modifiers, "\", \"") .. "\"},\n"
	    output_str = output_str .. "    keys = {\n"
	    for key, description in pairs(mappings.keys) do
	         output_str = output_str .. string.format("['%s']=\"%s\",\n", key, description)
	    end
	    output_str = output_str .. "    }\n"
	    output_str = output_str .. "    },\n"
	end
	output_str = output_str .. "    }\n"
    output_str = output_str .. "}\n"
    output_str = output_str .. 'end\n'

    file:write(output_str)
    file:close()
end

function awesome_hotkey.generate(module_name, mode)
    local hotkeys = {}
    local desc_format = module_name .. ": %s"
    local keymaps = filter_keymaps_by_name(module_name, mode)

    for _, map in ipairs(keymaps) do
        local description = map.desc:match(": (.+)$") 
        local modifiers, key = extract_modifiers_and_key(map.lhs)
        local mod_str = table.concat(modifiers, "-")
        
        if not hotkeys[mod_str] then
            hotkeys[mod_str] = {
                modifiers = modifiers,
                keys = {}
            }
        end

        hotkeys[mod_str].keys[key] = description
    end

    local final_format = {}
    for _, mappings in pairs(hotkeys) do
        table.insert(final_format, mappings)
    end

    write_hotkeys_file(module_name, final_format)
end

return awesome_hotkey
