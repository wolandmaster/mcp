-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "mcp.table"

local ltn12 = require "ltn12"
local http = require "socket.http"

local table = table

module "mcp.weserv"

local WESERV = "http://images.weserv.nl/"

-------------------------
-- P U B L I C   A P I --
-------------------------
function resize(url, width, height)
	local response = {}
	local body, status, header = http.request({
		url = WESERV .. table.to_qs({ url = url, t = "letterbox",
			w = width, h = height, bg = "black" }),
		sink = ltn12.sink.table(response)})
	if status ~= 200 then return nil, status end
	return table.concat(response)
end

