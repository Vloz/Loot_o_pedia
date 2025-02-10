local addon, ns = ...

local base64 = LibStub('LibBase64-1.0')
local DataView = {}
function DataView:new(bin)
    local self = { offset = 1, bin = bin or "", LOG2_BASE = math.log(2) }

    self.dataLength = function(num)
        local bLength = 0;
        while num > 0 do
            num = bit.rshift(num, 7)
            bLength = bLength + 1
        end
        return bLength
    end

    self.writeInt = function(num, forcedLength)
        local bLength = 0;
        if forcedLength ~= nil then
            bLength = forcedLength;
        else
            bLength = self.dataLength(num);
        end
        if bLength == 0 then
            bLength = 1
        end
        local r = "";

        for i = 1, bLength, 1 do
            r = r .. string.char(bit.band(bit.rshift(num, 8 * (bLength - i)), 0xFF))
        end
        self.offset = self.offset + bLength
        self.bin = self.bin .. r
    end

    -- way faster than readString TODO: check if i rather not use it for string
    self.readVarBin = function()
        local length, o = self.readVarInt()
        local r = string.sub(self.bin, self.offset, self.offset + length - 1)
        self.offset = self.offset + length
        return r
    end

    self.readInt = function(length)
        local r = 0;
        for i = 0, length - 1, 1 do
            r = bit.bor(r, bit.lshift(string.byte(self.bin, self.offset + i), 8 * (length - i - 1)))
        end
        self.offset = self.offset + length
        return r;
    end

    self.writeVarInt = function(num)
        local required = math.ceil(math.log(num + 1) / self.LOG2_BASE);
        if required <= 7 then
            self.writeInt(num, 1);
        elseif required <= 14 then
            self.writeInt(bit.bor(num, 0x8000), 2)
        elseif required <= 21 then
            self.writeInt(bit.bor(num, 0xc00000), 3)
        elseif required <= 28 then
            self.writeInt(bit.bor(num, 0xe0000000), 4) -- max value 2^28
        else
            error("VarInt Value is too high (max value 2^28). Encoding aborted.")
            -- bin
        end
    end

    self.readVarInt = function()
        local b = string.byte(self.bin, self.offset)
        local v;
        local o;
        if b < 0x80 then
            o = 1
            v = b
        elseif b < 0xC0 then
            o = 2
            v = bit.band((bit.lshift(b, 8) + string.byte(self.bin, self.offset + 1)), 0x7FFF)
        elseif b < 0xE0 then
            o = 3
            v = bit.band(
                (bit.lshift(b, 16) + bit.lshift(string.byte(self.bin, self.offset + 1), 8) + string.byte(self.bin, self.offset + 2)),
                0x3FFFFF)
        elseif b < 0xF0 then
            o = 4
            v = bit.band(bit.lshift(b, 24) + bit.lshift(string.byte(self.bin, self.offset + 1), 16) +
                bit.lshift(string.byte(self.bin, self.offset + 2), 8) + string.byte(self.bin, self.offset + 3),
                0x1FFFFFFF)
        else
            error("VarInt Value is too high (max value 2^28). Decoding aborted.")
        end
        self.offset = self.offset + o
        return v, o
    end

    self.writeString = function(str)
        local t = { strbyte(str, 1, strlen(str)) }
        self.writeVarInt(strlen(str))
        for _, v in ipairs(t) do
            self.concat(string.char(v))
        end
    end

    self.readString = function()
        local length = self.readVarInt()
        local r = ""
        for i = 1, length, 1 do
            r = r .. string.char(string.byte(self.bin, self.offset + i - 1))
        end
        self.offset = self.offset + length
        return r
    end

    self.writeSum8 = function()
        local sum = 0
        for i = 1, #self.bin do
            sum = sum + string.byte(self.bin, i)
        end
        self.writeInt(bit.band(sum, 0xFF), 1)
    end

    self.checkSum8 = function()
        local sum = 0
        for i = 1, #self.bin - 1 do
            sum = sum + string.byte(self.bin, i)
        end
        return bit.band(sum, 0xFF) == string.byte(self.bin, #self.bin)
    end

    self.concat = function(bin)
        self.bin = self.bin .. bin
        self.offset = self.offset + strlen(bin)
    end


    self.toBase64 = function()
        return base64:encode(self.bin):gsub("+", "-"):gsub("/", "_")
    end

    return self
end

ns.DataView = DataView
