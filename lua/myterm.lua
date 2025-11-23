local M = {}

M.MyTerm = {
	job_id = -1,
	buff_id = -1,
	win_id = -1,
	win_h = 12,
	float_win_id = -1,
}

M.default_config = {
	split_win = {
		height = 12,
	},
	float_win = {
		float_win_name = " MyTerm ",
		float_width = 0.8,
		float_height = 0.8,
	},
	usr_cmd = {
		enabled = true,
		toggleSplit = "MyTermSplit",
		toggleFloat = "MyTermFloat",
		sendCmd = "MyTermCmd",
		reloadTerm = "MyTermReload",
		info = "MyTermInfo",
	},
	keys = {
		enabled = true,
		toggleSplit = "<leader>tt",
		toggleFloat = "<leader>tf",
		sendCmd = "<leader>te",
	},
	hl = {
		split_win = {},
		float_win = {},
	},
}

M.config = {}

M.DefaultConfig = function()
	return M.default_config
end

M.ShowInfo = function()
	vim.print(vim.inspect(M.MyTerm))
end

M.CreateTerminalBuffer = function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_call(buf, function()
		vim.cmd.term()
		M.MyTerm.job_id = vim.bo.channel
	end)

	vim.keymap.set("n", "<Esc>", function()
		local cur_win = vim.api.nvim_get_current_win()
		if cur_win == M.MyTerm.win_id then
			vim.cmd("set ls=2")
			M.MyTerm.win_h = vim.api.nvim_win_get_height(cur_win)
			vim.api.nvim_win_hide(cur_win)
		elseif cur_win == M.MyTerm.float_win_id then
			vim.api.nvim_win_hide(cur_win)
		end
	end, { buffer = buf })

	M.MyTerm.buff_id = buf
	return buf
end

M.UpdateTermWinBuffer = function()
	if vim.api.nvim_buf_is_valid(M.MyTerm.buff_id) then
		if vim.api.nvim_win_is_valid(M.MyTerm.win_id) then
			vim.api.nvim_win_set_buf(M.MyTerm.win_id, M.MyTerm.buff_id)
		end
		if vim.api.nvim_win_is_valid(M.MyTerm.float_win_id) then
			vim.api.nvim_win_set_buf(M.MyTerm.float_win_id, M.MyTerm.buff_id)
		end
	else
		vim.print("MyTerm buffer " .. M.MyTerm.buff_id .. " is invalid")
	end
end

M.ReloadTerminalBufer = function()
	local old_buf = M.MyTerm.buff_id
	local buf = M.CreateTerminalBuffer()
	M.UpdateTermWinBuffer()
	if vim.api.nvim_buf_is_valid(old_buf) then
		vim.api.nvim_buf_delete(old_buf, { force = true })
	end
end

M.NewTermHsplit = function()
	vim.cmd.vnew()
	vim.cmd.wincmd("J")
	vim.cmd("set ls=0")
	vim.api.nvim_win_set_height(0, M.MyTerm.win_h)

	M.MyTerm.win_id = vim.api.nvim_get_current_win()

	local tmp_buf = vim.api.nvim_get_current_buf()
	local buf = M.MyTerm.buff_id

	if not vim.api.nvim_buf_is_valid(buf) then
		buf = M.CreateTerminalBuffer()
	end
	vim.cmd.buffer(buf)
	vim.api.nvim_buf_delete(tmp_buf, { force = true })
	vim.api.nvim_command("startinsert")
end

M.ToggleMyTermHsplit = function()
	if not vim.api.nvim_win_is_valid(M.MyTerm.win_id) then
		M.NewTermHsplit()
	else
		vim.cmd("set ls=2")
		M.MyTerm.win_h = vim.api.nvim_win_get_height(M.MyTerm.win_id)
		vim.api.nvim_win_hide(M.MyTerm.win_id)
	end
end

local function CreateMyTermFloating(opts)
	-- Get current UI dimensions
	local width = opts.width or vim.api.nvim_get_option_value("columns", {})
	local height = opts.height or vim.api.nvim_get_option_value("lines", {})

	-- Calculate float win size
	local win_width = math.floor(width * M.config.float_win.float_width)
	local win_height = math.floor(height * M.config.float_win.float_height)

	-- Calculate centered position
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)

	-- Get or Create term buff
	local buf = M.MyTerm.buff_id
	if not vim.api.nvim_buf_is_valid(M.MyTerm.buff_id) then
		buf = M.CreateTerminalBuffer()
	end

	-- Set window configuration
	local conf = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "rounded",
		title = { { M.config.float_win.float_win_name } },
		title_pos = "center",
	}

	-- Create the floating window
	local win = vim.api.nvim_open_win(buf, true, conf)
	M.MyTerm.float_win_id = win
	M.MyTerm.buff_id = buf
end

M.ToggleFloatTerm = function(opts)
	if not vim.api.nvim_win_is_valid(M.MyTerm.float_win_id) then
		CreateMyTermFloating(opts)
		if vim.bo[M.MyTerm.buff_id].buftype ~= "terminal" then
			vim.cmd.term()
			M.MyTerm.job_id = vim.bo.channel
		end
		vim.api.nvim_command("startinsert")
	else
		vim.api.nvim_win_hide(M.MyTerm.float_win_id)
	end
end

M.SendCmdToTerm = function()
	local cmd = vim.fn.input("to MyTerm")
	if vim.api.nvim_buf_is_valid(M.MyTerm.buff_id) and M.MyTerm.job_id > 0 then
		vim.fn.chansend(M.MyTerm.job_id, { cmd .. "\r\n" })
	end
end

M.setup = function(opts)
	-- load config
	M.config = vim.tbl_deep_extend("force", M.default_config, opts)
	M.MyTerm.win_h = M.config.split_win.height

	-- setting highlight groups
	-- local hl_split_win = vim.api.hl
	-- if M.config.hl.split_win then
	-- end

	-- Key mappings
	if M.config.keys.enabled then
		vim.keymap.set(
			"n",
			M.config.keys.toggleSplit,
			M.ToggleMyTermHsplit,
			{ desc = "Toggle MyTerm in hsplit", noremap = true }
		)

		vim.keymap.set(
			"n",
			M.config.keys.sendCmd,
			M.SendCmdToTerm,
			{ desc = "Send bash cmd to MyTerm", noremap = true }
		)

		vim.keymap.set("n", M.config.keys.toggleFloat, function()
			M.ToggleFloatTerm({})
		end, { desc = "Toggle MyTerm in floating window", noremap = true })
	end

	-- User Commands
	if M.config.usr_cmd.enabled then
		vim.api.nvim_create_user_command(
			M.config.usr_cmd.toggleSplit,
			M.ToggleMyTermHsplit,
			{ desc = "Toggle my term hsplit" }
		)
		vim.api.nvim_create_user_command(M.config.usr_cmd.toggleFloat, function()
			M.ToggleFloatTerm({})
		end, { desc = "Toogle MyTerm floating window" })
		vim.api.nvim_create_user_command(M.config.usr_cmd.sendCmd, M.SendCmdToTerm, { desc = "Send command to MyTerm" })
		vim.api.nvim_create_user_command(M.config.usr_cmd.info, M.ShowInfo, { desc = "Show myterm specs" })
		vim.api.nvim_create_user_command(
			M.config.usr_cmd.reloadTerm,
			M.ReloadTerminalBufer,
			{ desc = "Reload MyTerm terminal" }
		)
	end
end

return M
