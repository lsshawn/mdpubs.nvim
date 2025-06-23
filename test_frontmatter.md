---
neonote:
title: Test Note Unquoted
author: Test User
---

# Test Note with Unquoted Neonote Field

This is a test markdown file to verify that the frontmatter parsing correctly detects the `neonote:` field when it's unquoted.

The neonote ID should be: 123

---

Here's another test case:

---
"neonote": 456
title: "Test Note Quoted"
date: "2024-01-15"
---

# Test Note with Quoted Neonote Field

This section tests the `"neonote":` field detection with quotes.

The neonote ID should be: 456

---

And a third test case with spacing:

---
neonote : 789
title: Test with Spaces
tags: ["test", "frontmatter"]
---

# Test Note with Spaced Neonote Field

This tests the neonote field with spaces around the colon.

The neonote ID should be: 789

---

Final test with quoted field and spacing:

---
"neonote" : 101112
"title" : "Fully Quoted Test"
published: false
---

# Test Note with Quoted Field and Spacing

This tests the `"neonote" :` pattern with both quotes and spacing.

The neonote ID should be: 101112

---

And a case with no value:

---
title: "foo"
neonote:
---

# Note with empty neonote field

This should be detected as having the field, but with no ID.

The neonote ID should be: nil
