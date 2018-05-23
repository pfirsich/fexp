# Bugs
* /

# Features
* Copy/Paste
* Implement a proper text input for the input/prompt

# Maybe
* Optimize rendering (only rerender if something changed) and only render panes that changed
    The easiest version triggers repaint on every keypressed/textinput event
* A nice feedback/progress screen for deletion/paste

# Non-Prototype stuff
* Use the system clipboard for copy/paste
* Proper pane resizing? How would that even work?
* Remove "escapeNonAscii" function and somehow handle it properly
    My locale encoding (1252) on Windows makes löve error in lg.print
    I either need to convert it to utf-8, or keep stripping like I am now
* Give all gui functions optional pane-indices (remove the half-assed code right now and add this when it's needed)
