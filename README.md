# Simple neovim terminal plugin

Only purpose of this plugin is to keep same terminal buffer in splits and floating window. Why would anybody need another terminal plugin? I don't know, but I desided to create my own for myself.

What can plugin do?
- create terminal buffer (using default terminal configured in your neovim)
- open terminal window in horizontal split
    - keeps terminal window height after reopening it
- open terminal window in floating window
- reload terminal
- send command to terminal from neovim input
- keeps same terminal in all plugin's terminal windows

## Instalation

### Lazy.nvim (only tested)

```lua
return {
    "IKarasev/myterm.nvim",
    lazy = false,
	config = function()
		require("myterm").setup({})
	end,
}
```

`setup({})` is requared, config structure and default values are below

## Config

default config:
```lua
{
	split_win = {
		height = 12, -- initial split window height
	},
	float_win = {
		float_win_name = " MyTerm ", -- Title of terminal floating window
        float_height = 0.8,          -- window height relative to main window
		float_width = 0.8,           -- window width relative to main window
	},
	usr_cmd = {
		enabled = true,              -- enable user commands, 
		toggleSplit = "MyTermSplit", -- User command names (not recommeded to change)
		toggleFloat = "MyTermFloat",
		sendCmd = "MyTermCmd",
		reloadTerm = "MyTermReload",
		info = "MyTermInfo",
	},
	keys = {
		enabled = true,              -- enable keymappings
		toggleSplit = "<leader>tt", 
		toggleFloat = "<leader>tf",
		sendCmd = "<leader>te",
	},
}
```

## User commands

Default user commands:

| Command | Descriprion |
| -------------- | --------------- |
| MyTermSplit | Open terminal in horizontal split |
| MyTermFloat | Open terminal in floating window |
| MyTermCmd | Open input dialog for terminal command and send it to terminal |
| MyTermReload | Reload terminal |
| MyTermInfo | Show current plugin's state |



