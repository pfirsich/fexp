# Bugs
* `normpath(/..) = /..` - is that desired?
* (Linux only) If you Goto a path and it's a file (instead of a dir), it will show you "..", which does not actually go to the directory that file is in.

# Maybe
* Introduce some unified "item" class.
* A nice feedback/progress screen for deletion/paste (maybe make a "mock-directory" in which each item is one copy operation with progress, eta in brackets, deleting the items aborts them) - `path`, `showModCol`, `showSizeCol` do not fit this. Columns and item data should be generalized.
* Make reload not sort by name/type, but the last used sorting for that directory

# Non-Prototype stuff
* Query Filter
    - Implement parseTime properly
* Use the system clipboard for copy/paste
* Proper pane resizing? How would that even work?
* Remove "escapeNonAscii" function and somehow handle it properly (My locale encoding (1252) on Windows makes löve error in lg.print. utf8 characters that are not part of my locale encoding are broken all together -> Replace luafilesystem?)
    - https://github.com/keplerproject/luafilesystem/issues/56
    - https://github.com/keplerproject/luafilesystem/pull/57
* Trigger repaint by pane and cache panes in Canvases
* Give all gui functions optional pane-indices (remove the half-assed code right now and add this when it's needed)
* Input History (favor most common used entries) - first step: keep the input and show the last input when opening the prompt
* Mouse controls?
