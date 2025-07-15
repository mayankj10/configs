local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Color schemes for different projects/contexts
local project_colors = {
	default = "#83a598",
	backend = "#fb4934",
	frontend = "#b8bb26",
	devops = "#d3869b",
	database = "#fabd2f",
}

-- Enhanced hyperlink rules for developers
config.hyperlink_rules = {
	-- URLs
	{ regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b", format = "$0" },
	-- File paths (clickable)
	{ regex = "\\b(/[^\\s:]+):?(\\d+)?\\b", format = "file://$1" },
}

-- Enhanced quick select patterns for developers
config.quick_select_patterns = {
	-- UUIDs
	"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
	-- IP addresses
	"\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}:\\d+\\b",
	-- Git commit hashes
	"\\b[0-9a-fA-F]{7,40}\\b",
	-- JSON keys
	'"[^"]+":',
	-- File paths with line numbers
	"[^\\s:]+:\\d+",
	-- URLs
	"https?://[^\\s]+",
}

-- Leader key setup
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 1000 }

-- Enhanced keybindings with developer workflow focus
config.keys = {
	-- Send literal Ctrl-Q if pressed twice
	{ key = "q", mods = "LEADER|CTRL", action = act.SendKey({ key = "q", mods = "CTRL" }) },

	-- Pane management (tmux-style)
	{ key = "%", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = '"', mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Navigation
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- Resizing
	{ key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- Tab management
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },

	-- Search and copy mode
	{ key = "/", mods = "LEADER", action = act.Search({ CaseSensitiveString = "" }) },
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },

	-- Quick select mode
	{ key = "Space", mods = "LEADER", action = act.QuickSelect },

	-- Workspace management
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }) },

	-- Tab switching (numbers)
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },

	-- Font size adjustment
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- Command palette
	{ key = "P", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
}

-- Launch menu for quick project access
config.launch_menu = {
	{ label = "htop", args = { "htop" } },
	{ label = "zsh", args = { "zsh", "-l" } },
	{ label = "bash", args = { "bash", "-l" } },
	{ label = "Docker Stats", args = { "docker", "stats" } },
	{ label = "Kubernetes Pods", args = { "kubectl", "get", "pods" } },
}

-- Better window title that shows useful info
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local zoomed = ""
	if tab.active_pane.is_zoomed then
		zoomed = "[Z] "
	end

	local index = ""
	if #tabs > 1 then
		index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
	end

	local cwd = tab.active_pane.current_working_dir
	local hostname = ""
	if cwd then
		hostname = cwd.host or wezterm.hostname()
		cwd = cwd.file_path or ""
		-- Show only the last 2 directories
		cwd = cwd:match("([^/]+/[^/]+)/?$") or cwd:match("([^/]+)/?$") or cwd
	end

	return zoomed .. index .. (cwd or "") .. " - " .. (hostname or "")
end)

-- Dynamic tab titles based on running process
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local background = "#3c3836"
	local foreground = "#a89984"

	if tab.is_active then
		background = "#1d2021"
		foreground = "#ebdbb2"
	elseif hover then
		background = "#504945"
		foreground = "#ebdbb2"
	end

	-- Get process info using multiple methods to ensure we get something
	local process_name = tab.active_pane.foreground_process_name
	local title = tab.active_pane.title
	local cwd = tab.active_pane.current_working_dir
	local cwd_path = ""

	-- Get current working directory
	if cwd then
		cwd_path = cwd.file_path
		if cwd_path then
			-- Extract just the last directory name
			cwd_path = cwd_path:match("([^/\\]+)$") or cwd_path
		end
	end

	-- Extract just the process name
	if process_name then
		process_name = process_name:match("([^/\\]+)$") or process_name
	end

	-- Use process name if available, otherwise use title, then cwd, then fallback to "shell"
	local tab_title = process_name or title or cwd_path or "shell"

	-- Add indicators
	local indicators = ""
	if tab.active_pane.is_zoomed then
		indicators = indicators .. "🔍"
	end

	-- Add mode indicator
	local mode_indicator = ""
	if tab.active_pane.is_copy_mode then
		mode_indicator = " [COPY]"
	end

	-- Debug the tab title components
	wezterm.log_info("Tab " .. tab.tab_index + 1 .. " process_name: " .. (process_name or "nil"))
	wezterm.log_info("Tab " .. tab.tab_index + 1 .. " title: " .. (title or "nil"))
	wezterm.log_info("Tab " .. tab.tab_index + 1 .. " tab_title: " .. tab_title)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = " " .. tab.tab_index + 1 .. ": " .. tab_title .. indicators .. mode_indicator .. " " },
	}
end)

-- Visual configuration
config.color_scheme = "Gruvbox Dark (Gogh)"
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 12
config.line_height = 1.1

-- Window appearance
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
config.window_background_opacity = 0.95
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false

-- Cursor and visual feedback
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.7,
}

-- Performance and behavior
config.scrollback_lines = 10000
config.enable_scroll_bar = true
config.audible_bell = "Disabled"
config.check_for_updates = false

-- Copy mode configuration
config.key_tables = {
	copy_mode = {
		{ key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{ key = "Tab", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
		{ key = "Enter", mods = "NONE", action = act.CopyMode("MoveToStartOfNextLine") },
		{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "Space", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
		{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
		{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
		{ key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
		{ key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
		{ key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
		{ key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
		{ key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
		{ key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
		{ key = "O", mods = "SHIFT", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
		{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
		{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
		{ key = "b", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
		{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
		{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
		{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
		{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
		{ key = "g", mods = "CTRL", action = act.CopyMode("Close") },
		{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
		{ key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
		{ key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
		{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
		{ key = "t", mods = "CTRL", action = act.CopyMode("MoveForwardWord") },
		{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
		{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{
			key = "y",
			mods = "NONE",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "Close" },
			}),
		},
		{ key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
		{ key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
	},
}

return config
