-- Create the autocmd group properly
local bufcheck_group = vim.api.nvim_create_augroup("bufcheck", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
	group = "bufcheck",
	pattern = "*.swift",
	callback = function(ev)
		local lines = #vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)

		if lines > 1 then
			return
		end

		local filename = string.match(ev.file, "([^/]*)%.swift")
		local name = filename

		-- TODO: make sure this path leads to your folder with templates!!
		local basepath = os.getenv("HOME") .. "/.config/nvim/lua/templates/"
		print(basepath)
		local templates = { "View", "ViewModel", "UseCase" }

		local template
		local cursor

		for _, templateSuffix in ipairs(templates) do
			if vim.endswith(filename, templateSuffix) then
				template = vim.fn.readfile(basepath .. string.lower(templateSuffix) .. ".txt")
				name = string.gsub(name, templateSuffix, "")
				break
			end
		end

		template = template or vim.fn.readfile(basepath .. "empty.txt")

		for i = 1, #template do
			template[i] = string.gsub(template[i], "{date}", os.date("%d/%m/%Y"))
			template[i] = string.gsub(template[i], "{filename}", filename)
			template[i] = string.gsub(template[i], "{name}", name)

			if cursor == nil and string.find(template[i], "{cursor}") then
				cursor = { i, tonumber(string.find(template[i], "{cursor}")) + 1 }
			end
			template[i] = string.gsub(template[i], "{cursor}", " ")
		end

		vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, template)

		if cursor then
			vim.api.nvim_win_set_cursor(0, cursor)
		end

		vim.cmd("w")
	end,
})
