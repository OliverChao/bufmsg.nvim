local M = {}

---maps the table|string of keys to the action
---@param keys table
---@param action function|string
function M.nmap(bufnr, keys, action)
	for _, lhs in ipairs(keys) do
		vim.keymap.set("n", lhs, action, { silent = true, noremap = true, buffer = bufnr })
	end
end

return M
