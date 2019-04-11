-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local nixio = require "nixio"

local string, ipairs = string, ipairs

local ID3V1_FIELD_LENGTH = 30
local ID3V2_HEADER_SIZE = 10
local GENRE = { [0] = "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk",
	"Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
	"Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", "Death Metal",
	"Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk",
	"Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip",
	"Gospel", "Noise", "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative",
	"Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave",
	"Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock",
	"Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle",
	"Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes", "Trailer", 
	"Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", 
	"Hard Rock", "Folk", "Folk-Rock", "National Folk", "Swing", "Fast Fusion", "Bebob",
	"Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock", "Progressive Rock", 
	"Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band", "Chorus", "Easy Listening", 
	"Acoustic", "Humour", "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", 
	"Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", 
	"Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet", "Punk Rock",
	"Drum Solo", "Acapella", "Euro-House", "Dance Hall" }

module "mcp.id3"

local function zero_pad(str, length)
	return str:sub(1, length) .. string.rep("\0", length - str:len())
end

local function to_int(synchsafe)
	local b1, b2, b3, b4 = string.byte(synchsafe, 1, 4)
	return b1*2^21 + b2*2^14 + b3*2^7 + b4
end

local function id3v1_genre(str)
	for index, genre in ipairs(GENRE) do
		if str:lower() == genre:lower() then
			return string.char(index)
		end
	end
	return string.char(255)
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function id3v1_footer_offset(fd)
	fd:seek(-128, "end")
	if fd:read(3) == "TAG" then
		return 128
	end
	return 0
end

function id3v2_header_offset(fd)
	fd:seek(0, "set")
	if fd:read(3) == "ID3" then
		fd:seek(3, "cur")
		return to_int(fd:read(4)) + ID3V2_HEADER_SIZE
	end
	return 0
end

function id3v2_footer_offset(fd)
	fd:seek(-ID3V2_HEADER_SIZE, "end")
	if fd:read(3) == "3DI" then
		fd:seek(3, "cur")
		return to_int(fd:read(4)) + ID3V2_HEADER_SIZE
	end
	return 0
end

function add_id3v1(fd, fields)
	fd:seek(0, "end")
	fd:write("TAG" ..
		zero_pad(fields.title or "", ID3V1_FIELD_LENGTH) ..
		zero_pad(fields.artist or "", ID3V1_FIELD_LENGTH) ..
		zero_pad(fields.album or "", ID3V1_FIELD_LENGTH) ..
		(fields.year or 1900) ..
		zero_pad(fields.comment or "", ID3V1_FIELD_LENGTH - 2) ..
		"\0" .. string.char(fields.track or 0) ..
		id3v1_genre(fields.genre or "")
	)
end

