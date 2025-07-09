-- Simple debug test
local test_content = [[---
mdpubs: 123
title: Test Note
---

# Test content]]

print("Testing frontmatter parsing...")
print("Content length:", #test_content)
print("First 20 chars:", test_content:sub(1, 20):gsub("\n", "\\n"))

-- Test the basic patterns
local starts_with_frontmatter = test_content:match("^---\n")
print("Starts with ---\\n:", starts_with_frontmatter ~= nil)

if starts_with_frontmatter then
    local frontmatter_end = test_content:find("\n---\n", 4)
    print("Frontmatter end position:", frontmatter_end)
    
    if frontmatter_end then
        local frontmatter_text = test_content:sub(4, frontmatter_end - 1)
        print("Frontmatter text:", frontmatter_text:gsub("\n", "\\n"))
        
        -- Test mdpubs detection
        local has_mdpubs = frontmatter_text:match('mdpubs%s*:') ~= nil
        print("Has mdpubs field:", has_mdpubs)
    end
end 