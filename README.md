# SimpleBase64.luau

Lightweight Base64 implementation for Luau (Roblox) using Roblox's buffer type.

## Features
- Buffer-based encoding/decoding (native Roblox buffer API)
- Standard Base64 with padding (`=`)
- URL-safe Base64 without padding (RFC 4648)
- Automatic alphabet detection on decode
- Zero dependencies, pure Luau

## API

```lua
-- Encode buffer to standard Base64 (with padding)
Base64.Encode(buffer) -> string

-- Encode buffer to URL-safe Base64 (no padding)
Base64.EncodeURL(buffer) -> string

-- Decode Base64 to buffer (auto-detects alphabet, throws on error)
Base64.Decode(string) -> buffer

-- Safe decode (returns error instead of throwing)
Base64.SafeDecode(string) -> (buffer?, string?)
```

## Example
```lua
local buffer = buffer.fromstring("Hello, World!")

local standard = Base64.Encode(buffer) -- "SGVsbG8sIFdvcmxkIQ=="
local urlSafe = Base64.EncodeURL(buffer) -- "SGVsbG8sIFdvcmxkIQ"

local decoded = Base64.Decode(standard) -- auto-detects alphabet
print(buffer.tostring(decoded)) -- "Hello, World!"
```

Optimized for DataStore keys, URL parameters, and binary data serialization.
