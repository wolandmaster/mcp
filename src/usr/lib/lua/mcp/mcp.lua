#!/usr/bin/lua
-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local config = require "mcp.config"
local fs = require "mcp.fs"
local nixiofs = require "nixio.fs"
local naming = require "mcp.naming"
local db = require "mcp.discogs"
local img = require "mcp.weserv"
local id3 = require "mcp.id3"

local files = fs.get_files(".", "mp3")
table.sort(files, fs.sort_by_number)
print("local track count: " .. #files)
if #files == 0 then
	os.exit()
end

local album
if #arg == 1 then
	if tonumber(arg[1]) ~= nil then
		album = db.lookup(arg[1])
	else
		print("usage: mcp <id>")
	end
else	
	album = db.search(naming.format_title(
		nixiofs.basename(nixiofs.realpath("."))):gsub("_", " "), #files)
end
if album == nil then
	os.exit()
end

-- add source/dest file paths
for index, file in ipairs(files) do
	local track = album.tracklist[index]
	if track ~= nil then
		track.source = file
		track.dest = fs.join_path(
			naming.gen_folder(album.artist, album.year, album.title),
			naming.gen_filename(index, track.title)
		)
	else
		print("missing info in db for " .. file)
		os.exit()
	end
end

for _, track in ipairs(album.tracklist) do
	if nixiofs.stat(nixiofs.dirname(fs.join_path(config.music_folder(), track.dest)),  "type") == "dir" then
		print("album already exists in music folder!")
		os.exit()
	end
	print(track.source .. " -> " .. track.dest)
end

io.write("continue (y/n)? ")
if io.read():lower() == "y" then
	for index, track in ipairs(album.tracklist) do
		local dest = fs.join_path(config.music_folder(), track.dest)
		print("copy " .. nixiofs.basename(dest))
		nixiofs.mkdirr(nixiofs.dirname(dest))

		-- copy file without id3 tags
		local source_fd = nixio.open(track.source, "r")
		local dest_fd =  nixio.open(dest, "w")
		fs.copy(source_fd, dest_fd, id3.id3v2_header_offset(source_fd), 
			id3.id3v1_footer_offset(source_fd) + id3.id3v2_footer_offset(source_fd))
		source_fd:close()

		-- add id3v1 tag
		id3.add_id3v1(dest_fd, {
			artist = album.artist,
			album = album.title,
			year = album.year,
			comment = album.comment,
			genre = album.genre,
			track = index,
			title = track.title
		})
		dest_fd:close()

		-- save cover image
		local img_fd = nixio.open(fs.join_path(nixiofs.dirname(dest), config.cover_file()), "w")
		img_fd:write(img.resize(album.cover, config.cover_width(), config.cover_height()))
		img_fd:close()

		-- save cover thumb image
		img_fd = nixio.open(fs.join_path(nixiofs.dirname(dest), config.cover_thumb_file()), "w")
		img_fd:write(img.resize(album.cover, config.cover_thumb_width(), config.cover_thumb_height()))
		img_fd:close()
	end
end

