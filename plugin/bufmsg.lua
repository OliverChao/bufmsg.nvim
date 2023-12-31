if vim.fn.has("nvim-0.9.0") == 0 then
	vim.api.nvim_err_writeln("bmessages requires at least nvim-0.9")
	return
end

-- make sure this file is loaded only once
if vim.g.loaded_bufmsg == 1 then
	return
end
vim.g.loaded_bufmsg = 1

-- create any global command that does not depend on user setup
-- usually it is better to define most commands/mappings in the setup function
-- Be careful to not overuse this file!
local bufmsg = require("bufmsg")
