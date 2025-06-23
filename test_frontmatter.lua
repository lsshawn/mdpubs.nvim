-- Test script for frontmatter parsing
local utils = require("neonote.utils")

-- Test cases from the markdown file
local test_cases = {
	{
		name = "Unquoted neonote field",
		content = [[---
neonote: 123
title: Test Note Unquoted
author: Test User
---

# Test Note with Unquoted Neonote Field
This is a test.]],
		expected_id = 123,
		expected_has_field = true,
	},
	{
		name = "Quoted neonote field",
		content = [[---
"neonote": 456
title: "Test Note Quoted"
date: "2024-01-15"
---

# Test Note with Quoted Neonote Field
This section tests the quoted field.]],
		expected_id = 456,
		expected_has_field = true,
	},
	{
		name = "Unquoted with spacing",
		content = [[---
neonote : 789
title: Test with Spaces
tags: ["test", "frontmatter"]
---

# Test Note with Spaced Neonote Field
This tests spacing.]],
		expected_id = 789,
		expected_has_field = true,
	},
	{
		name = "Quoted with spacing",
		content = [[---
"neonote" : 101112
"title" : "Fully Quoted Test"
published: false
---

# Test Note with Quoted Field and Spacing
Final test case.]],
		expected_id = 101112,
		expected_has_field = true,
	},
	{
		name = "No neonote field",
		content = [[---
title: Regular Note
author: Test User
---

# Regular Note
This note has no neonote field.]],
		expected_id = nil,
		expected_has_field = false,
	},
	{
		name = "Neonote field with no value",
		content = [[---
title: "foo"
neonote:
---

# Note with empty neonote field
This should be detected as having the field, but with no ID.]],
		expected_id = nil,
		expected_has_field = true,
	},
}

print("=== NeoNote Frontmatter Detection Test ===\n")

for i, test_case in ipairs(test_cases) do
	print(string.format("Test %d: %s", i, test_case.name))
	print(string.rep("-", 40))
	
	local neonote_id, has_neonote_field, body = utils.extract_neonote_id(test_case.content)
	
	print(string.format("Expected ID: %s", tostring(test_case.expected_id)))
	print(string.format("Actual ID: %s", tostring(neonote_id)))
	print(string.format("Has neonote field: %s", tostring(has_neonote_field)))
	
	-- Check if test passed
	local passed = (neonote_id == test_case.expected_id) and (has_neonote_field == test_case.expected_has_field)
	
	print(string.format("Result: %s", passed and "✓ PASS" or "✗ FAIL"))
	print()
end

print("=== Test Complete ===") 
