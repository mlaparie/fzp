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
        formatted_output = formatted_output .. string.format("  \\033[30m↑ (%d hidden items)\\033[0m\n", start_index - 1)
    end
    for i = start_index, end_index do
        local prefix = (i == current_index) and "  \\033[37m●\\033[0m " or "  ○ "
        formatted_output = formatted_output .. prefix .. "\\033[2m" .. lines[i] .. "\\033[0m\n"
    end
    if end_index < num_files then
        formatted_output = formatted_output .. string.format("  \\033[30m↓ (%d hidden items)\\033[0m\n", num_files - end_index)
    elseif end_index == num_files and num_files > 10 then
        formatted_output = formatted_output .. "  \\033[30m…\\033[0m\n"
    end

    return formatted_output
end

-- Function to get the current file index
local function get_current_file_index(lines)
    local current_file = mp.get_property("media-title")
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

-- Variables to track visibility states
local show_keybindings = false
local show_playlist = true

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
    local playing_message = string.format("printf '\\033[36mPlaying %s (%d on %s file(s)):\\033[0m\n\n'", current_and_parent_folder, current_index, file_count)

    -- Keybindings
    local keybindings = [[
printf '\033[36mKeybindings:\033[0m

  \033[1;7m  space \033[0;27m  \033[2mplay/pause \033[0m                \033[1;7m     l \033[0;27m  \033[2mA/B loop \033[0m
  \033[1;7m    ← → \033[0;27m  \033[2mseek -5/+5 seconds \033[0m        \033[1;7m     v \033[0;27m  \033[2mtoggle .lrc lyrics \033[0m
  \033[1;7m    ↑ ↓ \033[0;27m  \033[2mseek -60/+60 seconds \033[0m      \033[1;7m     P \033[0;27m  \033[2mtoggle playlist \033[0m
  \033[1;7m [ ] ⌫  \033[0;27m  \033[2mdec/inc/reset speed \033[0m       \033[1;7m     M \033[0;27m  \033[2mtoggle minimal TUI \033[0m
  \033[1;7m    < > \033[0;27m  \033[2mprev/next track \033[0m           \033[1;7m     _ \033[0;27m  \033[2mtoggle cover art \033[0m
  \033[1;7m      L \033[0;27m  \033[2mrepeat track \033[0m              \033[1;7m     ? \033[0;27m  \033[2mtoggle help   \033[0m
  \033[1;7m  9 0 m \033[0;27m  \033[2mvol-/vol+/mute \033[0m            \033[1;7m     q \033[0;27m  \033[2mstop and go to browser \033[0m

'
]]

    -- Clear the terminal
    mp.command('run clear')

    -- Conditionally print the keybindings
    if show_keybindings then
        os.execute(keybindings)
    else
        os.execute('printf "\\033[2m? Help\\033[27;0m\n\n"')
    end
    
    -- Print the playing message
    os.execute(playing_message)
    
    -- Conditionally print the playlist
    if show_playlist then
        local playlist_output_cmd = string.format('printf "%s"', playlist_output)
        os.execute(playlist_output_cmd)
        io.write("\n") -- Add an empty line after the playlist output
    end
end

-- Function to toggle the screen state between mpv and fzf
local screen_toggled = false
local function toggle_all()
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

-- Function to toggle keybindings display
local function toggle_help()
    show_keybindings = not show_keybindings
    print_playlist_and_keybindings()
end

-- Function to toggle playlist display
local function toggle_playlist()
    show_playlist = not show_playlist
    print_playlist_and_keybindings()
end

-- Register event to clear the terminal and print playlist, keybindings, and additional message on end-file
mp.register_event('end-file', function()
    print_playlist_and_keybindings()
end)

-- Register event to clear the terminal and print playlist, keybindings, and additional message on file-loaded
mp.register_event('file-loaded', function()
    print_playlist_and_keybindings()
end)

-- Add keybindings to toggle the screen state, keybindings, and playlist
mp.add_key_binding("M", "toggle-all", toggle_all)
mp.add_key_binding("?", "toggle-keybindings", toggle_help)
mp.add_key_binding("P", "toggle-playlist", toggle_playlist)
