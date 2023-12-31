# Easy use message buffer plugin
This plugin is modified on the basic of [bmessages.nvim](https://github.com/ariel-frischer/bmessages.nvim).

I modify some logic functinos and only keep one command `Bufmsg`.

This plugin removes all time loop codes and the buffer including messages is modifiable.

You can use `<cltr>-u` to update the new messages.

## config
```lua
{
  -- show messages in one buffer
  "OliverChao/bufmsg.nvim",
  -- dir = "~/code/lua/bufmsg.nvim",
  cmd = "Bufmsg",
  opts = {},
},
```
You can modify the following options:
```lua
opts = {
	split_type = "vsplit",
	split_size_vsplit = nil,
	split_size_split = nil,
	modifiable = true, -- the default messages buffer is modifiable
	mappings = {     -- you can map your favourate mappings for messages updating and clearing.
		update = "<C-u>",
		clear = "<C-r>",
	},
}
```
