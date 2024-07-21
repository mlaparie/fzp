local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- Function to get the current folder name and its parent directory
local function get_current_and_parent_folder()
    local path = mp.get_property("path")
    if path then
        -- Escape single quotes in the path
        path = path:gsub("'", "'\\''")
        -- Use Lua's built-in functions to extract the directory and basename
        local folder_path = path:match("(.*/)")
        if folder_path then
            local current_folder = folder_path:match("([^/]+)/$")
            local parent_folder_path = folder_path:match("(.*/)[^/]+/$")
            local parent_folder = parent_folder_path and parent_folder_path:match("([^/]+)/$")
            if current_folder and parent_folder then
                return parent_folder .. "/" .. current_folder
            elseif current_folder then
                return current_folder
            end
        end
    end
    return "Unknown"
end

-- Function to run a shell command and capture its output
local function run_command(cmd)
    local file = assert(io.popen(cmd, 'r'))
    local output = file:read('*all')
    file:close()
    return output
end

-- Function to get the playlist lines
local function get_playlist_lines(file_path)
    local lines = {}
    local cmd = string.format("cat '%s' | rev | cut -d / -f 1 | rev", file_path)
    local output = run_command(cmd)
    for line in output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

-- Function to print the rolling playlist
local function print_rolling_playlist(lines, current_index)
    local num_files = #lines
    local start_index = math.max(1, current_index - 4)
    local end_index = math.min(num_files, start_index + 9)
    
    local formatted_output = ""
    if start_index > 1 then
        formatted_output = formatted_output .. string.format("  ↑ (%d hidden items)\n", start_index - 1)
    end
    for i = start_index, end_index do
        local prefix = (i == current_index) and "  ● " or "  ○ "
        formatted_output = formatted_output .. prefix .. lines[i] .. "\n"
    end
    if end_index < num_files then
        formatted_output = formatted_output .. string.format("  ↓ (%d hidden items)\n", num_files - end_index)
    elseif end_index == num_files and num_files > 10 then
        formatted_output = formatted_output .. "  …\n"
    end

    return formatted_output
end

-- Function to get the current file index
local function get_current_file_index(lines)
    local current_file = mp.get_property("filename")
    if not current_file then
        return 1 -- Default to the first file if current_file is nil
    end
    for i, line in ipairs(lines) do
        if line:find(current_file, 1, true) then
            return i
        end
    end
    return 1 -- Default to the first file if not found
end

-- Function to print the playlist, keybindings, and additional message
local function print_playlist_and_keybindings()
    -- Get the playlist lines
    local lines = get_playlist_lines("/tmp/fzplayer-playlist")
    local current_index = get_current_file_index(lines)
    local num_files = #lines

    -- Get the rolling playlist output
    local playlist_output = print_rolling_playlist(lines, current_index)

    -- Command to count the number of lines in the playlist
    local file_count_cmd = "wc -l < /tmp/fzplayer-playlist"
    local file_count = run_command(file_count_cmd):gsub("\n", "")

    -- Get the current and parent folder name
    local current_and_parent_folder = get_current_and_parent_folder()

    -- Formatted message
    local playing_message = string.format("printf '\\033[34mPlaying %s (%d on %s file(s)):\\033[0m\n\n'", current_and_parent_folder, current_index, file_count)

    -- Keybindings
    local keybindings = [[
printf '\033[34mKeybindings:\033[0m

  \033[1;7m space \033[0;27m play/pause              \033[1;7m 9 0 m \033[0;27m vol-/vol+/mute
  \033[1;7m   ← → \033[0;27m seek -5/+5 seconds      \033[1;7m     l \033[0;27m A/B loop
  \033[1;7m   ↑ ↓ \033[0;27m seek -60/+60 seconds    \033[1;7m    F8 \033[0;27m show playlist
  \033[1;7m   < > \033[0;27m prev/next track         \033[1;7m     _ \033[0;27m toggle interface type\033[0m
  \033[1;7m     L \033[0;27m repeat track            \033[1;7m     q \033[0;27m stop playback and go back 

'
]]

    -- Clear the terminal
    mp.command('run clear')

    -- Print the keybindings
    os.execute(keybindings)

    -- Print the playing message
    os.execute(playing_message)
    
    -- Print the playlist
    io.write(playlist_output)
    io.write("\n") -- Add an empty line after the playlist output
end

-- Function to toggle the screen state between mpv and fzf
local screen_toggled = false
local function toggle_screen()
    if screen_toggled then
        -- Clear the terminal and print the playlist
        print_playlist_and_keybindings()
        screen_toggled = false
    else
        -- Clear the terminal and send mpv to the background
        mp.command('run clear')
        mp.command_native({"script-message", "osc", "no-osd"})
        screen_toggled = true
    end
end

-- Register event to clear the terminal and print playlist, keybindings, and additional message on end-file
mp.register_event('end-file', function()
    print_playlist_and_keybindings()
end)

-- Register event to clear the terminal and print playlist, keybindings, and additional message on file-loaded
mp.register_event('file-loaded', function()
    print_playlist_and_keybindings()
end)

-- Add keybinding to toggle the screen state
mp.add_key_binding("ctrl+g", "toggle-screen", toggle_screen)
