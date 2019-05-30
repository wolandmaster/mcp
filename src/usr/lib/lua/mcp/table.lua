-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

function table.put(array, ...)
	for _, value in ipairs({...}) do
		table.insert(array, value)
	end
end

function table.to_qs(arg)
	local qs = {}
	for key, value in pairs(arg) do
		table.insert(qs, key .. "=" .. tostring(value):urlencode())
	end
	return "?" .. table.concat(qs, "&")
end

function table.ifilter(array, func)
	local out = {}
	for key, value in ipairs(array) do
		if func(value, key, array) then
			table.insert(out, value)
		end
	end
	return out
end

