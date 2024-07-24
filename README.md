`fzp` is a terminal audio player suppoorting fuzzy finding, navigating by directory, sixel graphics, managing playlists, and resuming playback from history, including within individual tracks (useful for audiobooks).

### Installation

`fzp` is a Bash script based on the awesome `fzf` and `mpv`, and as such requires no compilation or installation using a package manager. Just install the dependencies below using your favourite package manager:

* fzf >= 0.54.0
* mpv >= 0.38.0, ideally compiled with sixel support
* fd
* soxi

Then clone this repository or download just the raw the script, make it executable with `chmod +x /path/to/fzp` (the script, not the folder) and run it with `./fzp` from its directory, or place it in a directory in your `$PATH` to run it from anywhere with `fzp`. For instance, if `~/.local/bin` is in your `$PATH`, `curl -o ~/.local/bin/fzp https://git.sr.ht/~mlaparie/fzp/blob/master/fzp && chmod +x ~/.local/bin/fzp` should do.

### Usage

`fzp` accepts the following runtime options:

```
usage: fzp [options]

Options:
  -d, --dirs, --directories     List directories only (default)
  -f, --files                   List audio files recursively with directories
  -c, --continue, --history     Resume playback from history/playlists
  -i, --interface <value>       Primary playback interface: tui (default) or gui
  -a, --alt-interface <value>   Alternate interface if primary is tui: gui (default) or sixel
  -p, --path <path>             Path to media (default: ~/Music)
  -h, --help                    Show this help message and exit
```

Upon its first execution, `fzp` will create `~/.config/fzp` (by default) where it will store your saved playlists, as well as an auto-generated `mpv` Lua script used for formatting the TUI playback view and monitoring queue changes. You can review the content of this Lua script near the end of `fzp` itself.

Some configuration values can be changed and made default within the `fzp` script itself, by modifying the variables at the top:

```
#### Configuration ##############################################################
# Folders
media="$HOME/Music/"
CONFIG_DIR="$HOME/.config/fzp"
HISTORY_DIR="$CONFIG_DIR/history"

# Set default playback interface: one of "tui" or "gui":
# "gui" automatically opens a mpv window on top of fzp, and the extra
# window can be hidden without interrupting playback ("tui" mode) on a key
# press, while setting this to "tui" will default to not opening a mpv
# window, but can also be toggled during playback, see alt_interface below
interface="tui"

# Set secondary playback interface ('_' key): one of "sixel" or "gui"
# "gui" will open a separate mpv window upon pressing that key, while
# "sixel" will show the mpv interface within the fzp window; the latter
# requires a compatible terminal emulator and mpv built with libsixel
# This option has no effect if the primary interface is "gui", in which
# case the '_' key will always switch to "tui" (sixel switching not supported)
alt_interface="gui"

#### End of configuration #######################################################
```


`fzp` has three main modes to browse and add tracks to the queue: directory mode (default, `C-d`), files (`C-f`, which lists audio files recursively) and history (`C-h`, which lists saved and temporary playlists). By design, `fzp` always plays tracks from a temporary playlist located by default in `~/.config/fzp/history/tmp`, regardless of the mode in use. Even when in history mode and resuming a playlist saved under another name, that playlist is actually copied to the temporary playlist under the hood.

As a consequence, to alter the list of tracks after starting playback, you want to edit the temporary playlist named `tmp`, not the saved playlist that was used as a reference to create `tmp`.`tmp` can be saved at any time using `C-s`. This mechanism ensures that saved playlists are never altered by mistake when updating the play queue without remembering which playlist was activated in the first place, but only when they are intentionally managed from history mode.

### Demo
Screenshots/videos will go here.

### Quirks
`fzp` entirely relies on `mpv`'s built-in features to remember position in individual tracks and playlists. As of now, there may be some edge cases where this can be limiting, see [this culprit](https://github.com/mpv-player/mpv/issues/8138).
