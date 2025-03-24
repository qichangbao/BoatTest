local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local MERGE_TAG = "MergePart"
local weldedParts = {}
local originalTransforms = {}

local function weldParts()
    for _, part in ipairs(CollectionService:GetTagged(MERGE_TAG)) do
        if not originalTransforms[part] then
            originalTransforms[part] = {
                CFrame = part.CFrame,
                CanCollide = part.CanCollide
            }
        end
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part.Parent.PrimaryPart or part.Parent:FindFirstChildWhichIsA("BasePart")
        weld.Part1 = part
        weld.Parent = part
        
        part.CanCollide = false
        table.insert(weldedParts, weld)
    end
end

local function restoreParts()
    for part, transform in pairs(originalTransforms) do
        part.CFrame = transform.CFrame
        part.CanCollide = transform.CanCollide
        part.Anchored = false
    end
    
    for _, weld in ipairs(weldedParts) do
        weld:Destroy()
    end
    weldedParts = {}
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.One then
        weldParts()
    elseif input.KeyCode == Enum.KeyCode.Two then
        restoreParts()
    end
end)