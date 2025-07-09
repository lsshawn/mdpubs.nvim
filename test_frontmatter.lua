-- Test script for frontmatter parsing
local utils = require("mdpubs.utils")

-- Test cases from the markdown file
local test_cases = {
	{
		name = "Unquoted mdpubs field",
		content = [[---
mdpubs: 123
title: Test Note Unquoted
author: Test User
---

# Test Note with Unquoted Neonote Field
This is a test.]],
		expected_id = 123,
		expected_has_field = true,
	},
	{
		name = "Quoted mdpubs field",
		content = [[---
"mdpubs": 456
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
mdpubs : 789
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
"mdpubs" : 101112
"title" : "Fully Quoted Test"
published: false
---

# Test Note with Quoted Field and Spacing
Final test case.]],
		expected_id = 101112,
		expected_has_field = true,
	},
	{
		name = "No mdpubs field",
		content = [[---
title: Regular Note
author: Test User
---

# Regular Note
This note has no mdpubs field.]],
		expected_id = nil,
		expected_has_field = false,
	},
	{
		name = "Neonote field with no value",
		content = [[---
title: "foo"
mdpubs:
---

# Note with empty mdpubs field
This should be detected as having the field, but with no ID.]],
		expected_id = nil,
		expected_has_field = true,
	},
}

print("=== MdPubs Frontmatter Detection Test ===\n")

for i, test_case in ipairs(test_cases) do
	print(string.format("Test %d: %s", i, test_case.name))
	print(string.rep("-", 40))
	
	local mdpubs_id, has_mdpubs_field, body = utils.extract_mdpubs_id(test_case.content)
	
	print(string.format("Expected ID: %s", tostring(test_case.expected_id)))
	print(string.format("Actual ID: %s", tostring(mdpubs_id)))
	print(string.format("Has mdpubs field: %s", tostring(has_mdpubs_field)))
	
	-- Check if test passed
	local passed = (mdpubs_id == test_case.expected_id) and (has_mdpubs_field == test_case.expected_has_field)
	
	print(string.format("Result: %s", passed and "✓ PASS" or "✗ FAIL"))
	print()
end

print("=== Test Complete ===") 
