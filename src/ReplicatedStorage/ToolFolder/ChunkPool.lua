local ChunkPool = {}
ChunkPool.__index = ChunkPool

function ChunkPool.new()
    local self = setmetatable({}, ChunkPool)
    self.pool = {}
    self.inUse = {}
    return self
end

function ChunkPool:GetChunk()
    if #self.pool > 0 then
        local chunk = table.remove(self.pool)
        self.inUse[chunk] = true
        return chunk
    end
    return nil
end

function ChunkPool:ReturnChunk(chunk)
    if self.inUse[chunk] then
        self.inUse[chunk] = nil
        table.insert(self.pool, chunk)
    end
end

return ChunkPool