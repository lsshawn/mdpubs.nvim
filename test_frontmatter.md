---
mdpubs:
title: Test Note Unquoted
author: Test User
---

# Test Note with Unquoted Neonote Field

This is a test markdown file to verify that the frontmatter parsing correctly detects the `mdpubs:` field when it's unquoted.

The mdpubs ID should be: 123

---

Here's another test case:

---
"mdpubs": 456
title: "Test Note Quoted"
date: "2024-01-15"
---

# Test Note with Quoted Neonote Field

This section tests the `"mdpubs":` field detection with quotes.

The mdpubs ID should be: 456

---

And a third test case with spacing:

---
mdpubs : 789
title: Test with Spaces
tags: ["test", "frontmatter"]
---

# Test Note with Spaced Neonote Field

This tests the mdpubs field with spaces around the colon.

The mdpubs ID should be: 789

---

Final test with quoted field and spacing:

---
"mdpubs" : 101112
"title" : "Fully Quoted Test"
published: false
---

# Test Note with Quoted Field and Spacing

This tests the `"mdpubs" :` pattern with both quotes and spacing.

The mdpubs ID should be: 101112

---

And a case with no value:

---
title: "foo"
mdpubs:
---

# Note with empty mdpubs field

This should be detected as having the field, but with no ID.

The mdpubs ID should be: nil
