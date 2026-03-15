--[[
	Simple Base64 implementation
	@based on: https://devforum.roblox.com/t/1719860

	Author: @manee_too
	GitRepo: https://github.com/maneetoo/Simple-Base64
	License: MIT (See LICENSE.md)
]]--


--!strict
--!native

-- Standard alphabet and URL-safe alphabet (RFC 4648)
local STD_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local URL_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

-- Build encode/decode lookup tables for both alphabets once at module load
local function buildTables(chars: string)
	local enc: {[number]: string} = {}
	local dec: {[number]: number} = {}
	for i = 0, 63 do
		enc[i] = string.sub(chars, i + 1, i + 1)
		dec[string.byte(chars, i + 1)] = i
	end
	return enc, dec
end

local STD_ENC, STD_DEC = buildTables(STD_CHARS)
local URL_ENC, URL_DEC = buildTables(URL_CHARS)
local buf_create, buf_len, buf_readu8, buf_writeu8, buf_copy = buffer.create, buffer.len, buffer.readu8, buffer.writeu8, buffer.copy
local lshift, rshift, band, bor = bit32.lshift, bit32.rshift, bit32.band, bit32.bor
local mfloor, tconcat, tcreate = math.floor, table.concat, table.create








--------------------------------------------------------------------------------
-- Core encode/decode (shared by both alphabet variants)
--------------------------------------------------------------------------------

local function encodeBuffer(b: buffer, enc: {[number]: string}, urlSafe: boolean): string
	local len  = buf_len(b)
	local chunks = tcreate(mfloor((len + 2) / 3) * 4)
	local ci, i = 0, 0

	while i + 2 < len do
		local b0, b1, b2 = buf_readu8(b, i), buf_readu8(b, i + 1), buf_readu8(b, i + 2)
		ci += 1; chunks[ci] = enc[rshift(b0, 2)]
		ci += 1; chunks[ci] = enc[bor(lshift(band(b0, 3), 4), rshift(b1, 4))]
		ci += 1; chunks[ci] = enc[bor(lshift(band(b1, 15), 2), rshift(b2, 6))]
		ci += 1; chunks[ci] = enc[band(b2, 63)]
		i += 3
	end

	local rem = len - i
	if rem == 1 then
		local b0 = buf_readu8(b, i)
		ci += 1; chunks[ci] = enc[rshift(b0, 2)]
		ci += 1; chunks[ci] = enc[lshift(band(b0, 3), 4)]

		if not urlSafe then
			ci += 1; chunks[ci] = "="
			ci += 1; chunks[ci] = "="
		end
	elseif rem == 2 then
		local b0, b1 = buf_readu8(b, i), buf_readu8(b, i + 1)
		ci += 1; chunks[ci] = enc[rshift(b0, 2)]
		ci += 1; chunks[ci] = enc[bor(lshift(band(b0, 3), 4), rshift(b1, 4))]
		ci += 1; chunks[ci] = enc[lshift(band(b1, 15), 2)]
		if not urlSafe then
			ci += 1; chunks[ci] = "="
		end
	end

	return tconcat(chunks)
end

local function decodeString(s: string, dec: {[number]: number}): buffer
	s = s:gsub("[=%s]", "")
	local slen = #s
	local outLen = mfloor(slen * 3 / 4)
	local b = buf_create(outLen)
	local bi, i = 0, 1

	while i + 3 <= slen do
		local c0 = dec[string.byte(s, i)]     or 0
		local c1 = dec[string.byte(s, i + 1)] or 0
		local c2 = dec[string.byte(s, i + 2)] or 0
		local c3 = dec[string.byte(s, i + 3)] or 0
		buf_writeu8(b, bi,     bor(lshift(c0, 2), rshift(c1, 4)))
		buf_writeu8(b, bi + 1, band(bor(lshift(c1, 4), rshift(c2, 2)), 0xFF))
		buf_writeu8(b, bi + 2, band(bor(lshift(c2, 6), c3), 0xFF))
		bi += 3
		i  += 4
	end

	return b
end





--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

local Base64 = {}

--- Encode a buffer to standard base64 (with `=` padding).
--- @param b buffer
--- @return string
function Base64.Encode(b: buffer): string
	assert(typeof(b) == "buffer", "[Base64.Encode] expected buffer")
	return encodeBuffer(b, STD_ENC, false)
end

--- Encode a buffer to URL-safe base64 (RFC 4648 §5, no padding).
--- Safe for use in URLs, filenames, and DataStore string keys.
--- @param b buffer
--- @return string
function Base64.EncodeURL(b: buffer): string
	assert(typeof(b) == "buffer", "[Base64.EncodeURL] expected buffer")
	return encodeBuffer(b, URL_ENC, true)
end

--- Decode a standard or URL-safe base64 string.
--- Accepts both alphabets and handles padding transparently.
--- @param s string
--- @return buffer?, string?
function Base64.SafeDecode(s: string): (buffer?, string?)
	if type(s) ~= "string" then return nil, `[Base64.SafeDecode] expected string (got {type(s)})` end
	-- Detect alphabet by checking for URL-safe characters.
	local isURL = s:find("[-_]") ~= nil
	local dec = if isURL then URL_DEC else STD_DEC
	local success, result = pcall(decodeString, s, dec)
	if not success then return nil, `[Base64.SafeDecode] decode failed: {result}` end
	return result :: buffer, nil
end

--- Like SafeDecode but throws on invalid input.
--- @param s string
--- @return buffer
function Base64.Decode(s: string): buffer
	assert(type(s) == "string", "[Base64.Decode] expected string")
	local isURL = s:find("[-_]") ~= nil
	return decodeString(s, if isURL then URL_DEC else STD_DEC)
end

return Base64