-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local fs = require "mcp.fs"

local string, ipairs = string, ipairs

module "mcp.naming"

local function format_number(number)
	return string.format("%02d", number)
end

local function contains(list, x)
	for _, v in ipairs(list) do
		if v == x then
			return true
		end
	end
	return false
end

local function string.titlecase(str)
	local conjs = {
		"a", "an", "and", "at", "but", "by", "for", "from",
		"in", "nor", "of", "on", "or", "so", "the", "to",
		"az", "es"
	}
	return str:gsub("(%a)(%w*)", function(first, rest)
		return first:upper() .. rest:lower()
	end):gsub("%a+", function(str)
		return contains(conjs, str:lower()) and str:lower() or str
	end)
end

local function string.unaccent(str)
	local chr = string.char
	local charconv_c3 = {
		[chr(0xa1)] = "a", [chr(0x81)] = "A",	-- a'
		[chr(0xa4)] = "a", [chr(0x84)] = "A",	-- a:
		[chr(0xa9)] = "e", [chr(0x89)] = "E",	-- e'
		[chr(0xad)] = "i", [chr(0x8d)] = "I",	-- i'
		[chr(0xb3)] = "o", [chr(0x93)] = "O",	-- o'
		[chr(0xb6)] = "o", [chr(0x96)] = "O",	-- o:
		[chr(0xba)] = "u", [chr(0x9a)] = "U",	-- u:
		[chr(0xbc)] = "u", [chr(0x9c)] = "U"	-- u'
	}
	local charconv_c5 = {
		[chr(0x91)] = "o", [chr(0x90)] = "O",	-- o"
		[chr(0xb1)] = "u", [chr(0xb0)] = "U"	-- u"
	}
	return str:gsub(chr(0xc3) .. "(.)", charconv_c3)
			  :gsub(chr(0xc5) .. "(.)", charconv_c5)
end

local function string.remove_bracket(str)
	return str:gsub("%s*%b()", "")
end

local function string.remove_non_word(str)
	return str:gsub("[.,;:!?'-]", " ")
			:gsub("&", "and")
end

local function string.replace_space(str)
	return str:gsub("%s+", "_")
end

local function string.uppercase_first(str)
	return str:gsub("%a", string.upper, 1)
end

-------------------------
-- P U B L I C   A P I --
-------------------------
function gen_folder(artist, date, album)
	return fs.join_path(
		format_title(artist),
		date .. "-" .. format_title(album)
	)
end

function gen_filename(number, title)
	local name = format_number(number) .. "-"
		.. format_title(title) .. ".mp3"
	return name
end

function format_title(title)
	return title:unaccent()
				:titlecase()
				:remove_bracket()
				:remove_non_word()
				:replace_space()
				:uppercase_first()
end

