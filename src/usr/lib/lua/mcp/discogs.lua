-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

require "mcp.string"
require "mcp.table"

local config = require "mcp.config"
local socket = require "socket"
local ssl = require "ssl"
local ltn12 = require "ltn12"
local json = require "luci.json"
local nixiofs = require "nixio.fs"

local io, ipairs, table, tonumber = io, ipairs, table, tonumber

module "mcp.discogs"

local DISCOGS = "api.discogs.com"

local function receive_status(sock)
	local status, err = sock:receive()
	local code = socket.skip(2, status:find("HTTP/%d*%.%d* (%d%d%d)"))
	return tonumber(code), status
end

local function receive_headers(sock)
	local headers = {}
	local line, err = sock:receive()
	if err then return nil, err end
	while line ~= "" do
		local name, value = socket.skip(2, line:find("^(.-):%s*(.*)"))
		if not (name and value) then
			return nil, "malformed reponse headers"
		end
		headers[name:lower()] = value
		line, err  = sock:receive()
		if err then return nil, err end
	end
	return headers
end

local function receive_body(sock, length)
	local body = {}
	local source = socket.source("by-length", sock, length)
	local sink = ltn12.sink.table(body)
	local step = ltn12.pump.step
	ltn12.pump.all(source, sink, step)
	return table.concat(body)
end

-- the socket.http lib is hardcode the "TE: trailers"
-- and "Connection: close, TE" headers to the http request.
-- discogs is using http/2 protocol that does not support these headers
local function request(host, port, uri)
	local params = {
		mode = "client",
		protocol = "tlsv1_2",
		verify = "none",
		options = "all",
	}
	local sock = socket.tcp()
	sock:connect(host, port)
	sock = ssl.wrap(sock, params)
	sock:dohandshake()
	sock:send("GET " .. uri .. " HTTP/1.1\r\n"
		.. "Host: " .. host .. "\r\n"
		.. "User-Agent: mcp\r\n\r\n")
	local code, status = receive_status(sock)
	if code ~= 200 then return nil, status end
	local headers = receive_headers(sock)
	local length = tonumber(headers["content-length"])
	local body = receive_body(sock, length)
	return body
end

local function discogs(action, arg)
	local url = "/" .. action .. table.to_qs(arg or {})
	return json.decode(request(DISCOGS, 443, url))
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function lookup(id)
	local response = {}
	local album = discogs("releases/" .. id,
		{ token = config.discogs_token() })
	local master = discogs("masters/" .. album.master_id,
		{ token = config.discogs_token() })
	local artist = discogs("artists/" .. master.artists[1].id,
		{ token = config.discogs_token() })
	return {
		id = album.id,
		artist = album.artists_sort,
		title = master.title,
		year = master.year,
		comment = "discogs:" .. album.id,
		genre = master.genres[1],
		tracklist = table.ifilter(album.tracklist, function(value)
			return value.type_ == "track"
		end),
		cover = master.images[1].uri,
		artist_cover = artist.images[1].uri
	}
end

function search(query, track_count)
	io.write("looking for \"" .. query .. "\"...")
	io.flush()
	for _, result in ipairs(discogs("database/search", {
		q = query, type = "release",
		token = config.discogs_token(),
		page = 1, per_page = 25
	}).results) do
		io.write(".")
		io.flush()
		local album = lookup(tonumber(nixiofs.basename(result.uri)))
		if table.getn(album.tracklist) == track_count then
			io.write(" found:" .. album.id .. "\n")
			return album
		end
	end
	io.write("not found\n")
end

