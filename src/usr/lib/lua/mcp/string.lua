-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

function string.urlencode(str)
	return str:gsub("([^%w %-%_%.%~])", function (c)
		return string.format ("%%%02X", string.byte(c)) end):gsub("%s+", "+")
end

function string.ends(str, tail)
	return tail == "" or string.sub(str, -string.len(tail)) == tail
end

