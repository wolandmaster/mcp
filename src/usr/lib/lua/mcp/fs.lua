-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "mcp.table"
require "mcp.string"

local nixio = require "nixio"
local fs = require "nixio.fs"

local table, unpack, tonumber, type = table, unpack, tonumber, type

module "mcp.fs"

-------------------------
-- P U B L I C   A P I --
-------------------------
function join_path(...)
	return (table.concat({...}, "/"):gsub("/+", "/"))
end

function get_files(path, ext)
	local files = {} 
	for entry in fs.dir(path) do
		entry_path = path .. "/" .. entry
		if fs.stat(entry_path, "type") == "reg"
		and entry:lower():ends("." .. ext) then
			table.insert(files, entry_path)
		elseif fs.stat(entry_path, "type") == "dir" then
			table.put(files, unpack(get_files(entry_path, ext)))
		end
	end
	return files
end

function sort_by_number(left, right)
	return tonumber(left:match("%d+")) < tonumber(right:match("%d+"))
end

function copy(source, dest, header_offset, footer_offset)
	header_offset = header_offset or 0
	footer_offset = footer_offset or 0
	source_fd = type(source) == "string" and nixio.open(source, "r") or source
	dest_fd = type(dest) == "string" and nixio.open(dest, "w") or dest
	source_fd:seek(header_offset, "set")
	source_fd:copyz(dest_fd, source_fd:stat("size") - header_offset - footer_offset)
	if type(dest) == "string" then
		dest_fd:close()
	end
	if type(source) == "string" then
		source_fd:close()
	end
end

