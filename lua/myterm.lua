local M = {}

M.MyTerm = {
	job_id = -1,
	buff_id = -1,
	win_id = -1,
	win_h = 12,
	float_win_id = -1,
	float_win_name = " MyTerm ",
	active_mode = "",
}

local default_config = {
	usrCmd = {
		toggleSplit = "MyTermSplit",
		toggleFloat = "MyTermFloat",
		sendCmd = "MyTermCmd",
	},
	keys = {
		toggleSplit = "<leader>tt",
		toggleFloat = "<leader>tf",
		sendCmd = "<leader>te",
	},
}

M.DefaultConfig = function()
	return default_config
end

M.Show = function()
	vim.print(vim.inspect(M.MyTerm))
end

M.CreateTerminalBuff = function()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_call(buf, function()
		vim.cmd.term()
		M.MyTerm.job_id = vim.bo.channel
	end)

	-- vim.api.nvim_buf_set_keymap(buf, "n", "<super>bb", function()
	-- 	vim.notify("ESC is pressed")
	-- 	local win_id = vim.api.nvim_get_current_win()
	-- 	if win_id == M.MyTerm.float_win_id then
	-- 		vim.api.nvim_win_hide(M.MyTerm.float_win_id)
	-- 	elseif win_id == M.MyTerm.win_id then
	-- 		M.MyTerm.win_h = vim.api.nvim_win_get_height(M.MyTerm.win_id)
	-- 		vim.api.nvim_win_close(M.MyTerm.win_id, true)
	-- 	end
	-- end, { noremap = false })

	vim.keymap.set("n", "<Esc>", function()
		vim.print("Hide terminal")
		local cur_win = vim.api.nvim_get_current_win()
		if win_id == M.win_id then
			M.MyTerm.win_h = vim.api.nvim_win_get_height(M.MyTerm.win_id)
			vim.api.nvim_win_close(cur_win, true)
		elseif win_id == M.float_win_id then
			vim.api.nvim_win_close(cur_win, true)
		end
	end, { buffer = buf })

	M.MyTerm.buff_id = buf
	return buf
end

M.SetBufferKeyHide = function(buffer)
	print("buffer num: " .. buffer)
	vim.keymap.set("n", "<super>bb", function()
		vim.notify("ESC is pressed")
		local win_id = vim.api.nvim_get_current_win()
		if win_id == M.MyTerm.float_win_id then
			vim.api.nvim_win_hide(M.MyTerm.float_win_id)
		elseif win_id == M.MyTerm.win_id then
			M.MyTerm.win_h = vim.api.nvim_win_get_height(M.MyTerm.win_id)
			vim.api.nvim_win_close(M.MyTerm.win_id, true)
		end
	end, { buffer = buffer, noremap = false })
end

M.NewTermVsplit = function()
	vim.cmd.vnew()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, M.MyTerm.win_h)
	M.MyTerm.win_id = vim.api.nvim_get_current_win()

	if vim.api.nvim_buf_is_valid(M.MyTerm.buff_id) then
		local tmpbuf = vim.api.nvim_win_get_buf(M.MyTerm.win_id)
		vim.cmd.buffer(M.MyTerm.buff_id)
		vim.api.nvim_buf_delete(tmpbuf, { force = true })
	else
		-- vim.cmd.term()
		-- M.MyTerm.job_id = vim.bo.channel
		-- M.MyTerm.buff_id = vim.fn.bufnr()
		-- M.SetBufferKeyHide(M.MyTerm.buff_id)
		local buf = M.CreateTerminalBuff()
		vim.cmd.buffer(buf)
	end
	-- vim.api.nvim_command("startinsert")
end

M.ToggleMyTermHsplit = function()
	if not vim.api.nvim_win_is_valid(M.MyTerm.win_id) then
		M.NewTermVsplit()
	else
		M.MyTerm.win_h = vim.api.nvim_win_get_height(M.MyTerm.win_id)
		vim.api.nvim_win_close(M.MyTerm.win_id, true)
	end
end

local function CreateMyTermFloating(opts)
	-- Get current UI dimensions
	local width = opts.width or vim.api.nvim_get_option("columns")
	local height = opts.height or vim.api.nvim_get_option("lines")

	-- Calculate 80% of screen dimensions
	local win_width = math.floor(width * 0.8)
	local win_height = math.floor(height * 0.8)

	-- Calculate centered position
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)

	-- Get or Create term buff
	local buf = nil
	if vim.api.nvim_buf_is_valid(M.MyTerm.buff_id) then
		buf = M.MyTerm.buff_id
	else
		buf = vim.api.nvim_create_buf(false, true)
		M.SetBufferKeyHide(buf)
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
		title = { { M.MyTerm.float_win_name, "MyTermFloatBorder" } },
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
		vim.api.nvim_win_set_option(
			M.MyTerm.float_win_id,
			"winhl",
			"Normal:MyTermFloatBg,FloatBorder:MyTermFloatBorder"
		)
	else
		vim.api.nvim_win_hide(M.MyTerm.float_win_id)
	end
end

M.SendCmdToTerm = function()
	local cmd = vim.fn.input("to MyTerm")
	vim.notify(M.MyTerm.buff_id)
	if vim.api.nvim_buf_is_valid(M.MyTerm.buff_id) and M.MyTerm.job_id > 0 then
		vim.fn.chansend(M.MyTerm.job_id, { cmd .. "\r\n" })
	end
end

M.setup = function(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts)
	vim.api.nvim_set_hl(0, "MyTermFloatBg", { bg = "#111317" })
	vim.api.nvim_set_hl(0, "MyTermFloatBorder", { bg = "#111317", fg = "#589ED7" })

	vim.keymap.set("n", opts.keys.toggleSplit, M.ToggleMyTermHsplit, { desc = "Toggle MyTerm in hsplit" })

	vim.keymap.set("n", opts.keys.sendCmd, M.SendCmdToTerm, { desc = "Send bash cmd to MyTerm" })

	vim.keymap.set("n", opts.keys.toggleFloat, function()
		M.ToggleFloatTerm({})
	end, { desc = "Toggle MyTerm in floating window" })

	if opts.usrCmd.toggleSplit and opts.usrCmd.toggleSplit ~= "" then
		vim.api.nvim_create_user_command(
			opts.usrCmd.toggleSplit,
			M.ToggleMyTermHsplit,
			{ desc = "Toggle my term hsplit" }
		)
	end
	if opts.usrCmd.toggleFloat and opts.usrCmd.toggleFloat ~= "" then
		vim.api.nvim_create_user_command(opts.usrCmd.toggleFloat, function()
			M.ToggleFloatTerm({})
		end, { desc = "Toogle MyTerm floating window" })
	end
	if opts.usrCmd.sendCmd and opts.usrCmd.sendCmd ~= "" then
		vim.api.nvim_create_user_command(opts.usrCmd.sendCmd, M.SendCmdToTerm, { desc = "Send command to MyTerm" })
	end
	vim.api.nvim_create_user_command("MyTermShow", M.Show, { desc = "Show myterm specs" })
end

return M
