-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

local fs = require "mcp.fs"

local string, ipairs, pairs = string, ipairs, pairs

local chr = string.char

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

function string.titlecase(str)
	local force_lower = {
		"a", "an", "and", "as", "at", "but", "by", "for", "from",
		"in", "into", "nor", "of", "off", "on", "onto", "or", "out",
		"over", "so", "the", "to", "up", "with", "yet",
		"st", "nd", "rd", "th",
		"az", "es"
	}
	local force_upper = {
		"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
		"AC", "DC", "HP"
	}
	return str:gsub("(%a)(%w*)", function(first, rest)
		return first:upper() .. rest:lower()
	end):gsub("%a+", function(str)
		return contains(force_lower, str:lower()) and str:lower() or str
	end):gsub("%a+", function(str)
		return contains(force_upper, str:upper()) and str:upper() or str
	end)
end

function string.unaccent(str)
	local charconv_c3 = {
		[chr(0xa0)] = "a", [chr(0x80)] = "A",	-- a`
		[chr(0xa1)] = "a", [chr(0x81)] = "A",	-- a'
		[chr(0xa2)] = "a", [chr(0x82)] = "A",	-- a^
		[chr(0xa3)] = "a", [chr(0x83)] = "A",	-- a~
		[chr(0xa4)] = "a", [chr(0x84)] = "A",	-- a:
		[chr(0xa5)] = "a", [chr(0x85)] = "A",	-- ao
		[chr(0xa6)] = "a", [chr(0x86)] = "A",	-- ae
		[chr(0xa7)] = "c", [chr(0x87)] = "C",	-- c'
		[chr(0xa8)] = "e", [chr(0x88)] = "E",	-- e`
		[chr(0xa9)] = "e", [chr(0x89)] = "E",	-- e'
		[chr(0xaa)] = "e", [chr(0x8a)] = "E",	-- e^
		[chr(0xab)] = "e", [chr(0x8b)] = "E",	-- e:
		[chr(0xac)] = "i", [chr(0x8c)] = "I",	-- i`
		[chr(0xad)] = "i", [chr(0x8d)] = "I",	-- i'
		[chr(0xae)] = "i", [chr(0x8e)] = "I",	-- i^
		[chr(0xaf)] = "i", [chr(0x8f)] = "I",	-- i:
		[chr(0xb1)] = "n", [chr(0x91)] = "N",	-- n~
		[chr(0xb2)] = "o", [chr(0x92)] = "O",	-- o`
		[chr(0xb3)] = "o", [chr(0x93)] = "O",	-- o'
		[chr(0xb4)] = "o", [chr(0x94)] = "O",	-- o^
		[chr(0xb5)] = "o", [chr(0x95)] = "O",	-- o~
		[chr(0xb6)] = "o", [chr(0x96)] = "O",	-- o:
		[chr(0xb8)] = "o", [chr(0x98)] = "O",	-- o/
		[chr(0xb9)] = "u", [chr(0x99)] = "U",	-- u`
		[chr(0xba)] = "u", [chr(0x9a)] = "U",	-- u'
		[chr(0xbb)] = "u", [chr(0x9b)] = "U",	-- u^
		[chr(0xbc)] = "u", [chr(0x9c)] = "U",	-- u:
		[chr(0xbd)] = "y", [chr(0x9d)] = "Y"	-- y^
	}
	local charconv_c5 = {
		[chr(0x91)] = "o", [chr(0x90)] = "O",	-- o"
		[chr(0xb1)] = "u", [chr(0xb0)] = "U"	-- u"
	}
	return str:gsub(chr(0xc3) .. "(.)", charconv_c3)
			  :gsub(chr(0xc5) .. "(.)", charconv_c5)
end

function string.remove_bracket(str)
	return str:gsub("%s*%b()", "")
end

function string.remove_non_word(str)
	return str:gsub("[.,;:!?'-]", " ")
		:gsub(chr(0xe2) .. chr(0x80) .. chr(0x99), "")	-- `
end

function string.replace_word(str)
	local words = {
		["&"] = "and", ["'"] = "", ["#"] = "number", ["/"] = ""
	}
	for word, replacement in pairs(words) do
		str = str:gsub(word, replacement)
	end
	return str
end

function string.replace_space(str)
	return str:gsub("%s+", "_")
end

function string.uppercase_first(str)
	return str:gsub("%w", string.upper, 1)
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
				:lower()
				:remove_bracket()
				:replace_word()
				:remove_non_word()
				:titlecase()
				:replace_space()
				:uppercase_first()
end

