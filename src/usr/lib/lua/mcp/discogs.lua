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
		if not (name and value) then return nil, "malformed reponse headers" end
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

-- the socket.http lib is hardcode the "TE: trailers" and "Connection: close, TE" headers
-- to the http request. discogs is using http/2 protocol that does not support these headers
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
	return json.decode(request(DISCOGS, 443, "/" .. action .. table.to_qs(arg or {})))
end

-------------------------
-- P U B L I C   A P I --
-------------------------
-- music database lookup result format:
--	{
--		id = 123456
--		artist = "album artist",
--		title = "album title",
--		year = 1900,
--		genre = "album genre",
--		cover = "cover url",
--		comment = "db name:" .. id,
--		tracklist = {
--			{
--				position = 1,
--				title = "track 1 title"
--			}
--		}
--	}
function lookup(id)
	local album = discogs("releases/" .. id,
		{ token = config.discogs_token() })
	album.artist = album.artists_sort
	album.comment = "discogs:" .. album.id
	album.genre = album.genres[1]
	album.cover = album.images[1].uri
	return album
end

-- music database search result format:
-- returns lookup("best match id")
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

