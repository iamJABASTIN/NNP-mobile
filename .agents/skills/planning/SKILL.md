---
name: planning
description: Generates detailed, step-by-step implementation plans for coding tasks. Use when the user needs a plan, spec, or roadmap for a feature, or before writing complex code.
---

# Planning Implementation

## When to use this skill
- When the user asks to "plan" a feature or task.
- When the user wants a "roadmap" or "spec" before coding.
- When the task is complex and requires breaking down into smaller steps.

## Workflow
1.  **Analyze Request**: Understand the user's goal and the current codebase context.
2.  **Draft Plan**: Create a comprehensive implementation plan starting with the goal, architecture, and tech stack.
3.  **Break Down Tasks**: Divide the work into bite-sized, verifyable tasks (2-5 minutes each).
4.  **Review**: Ask the user to review the plan before execution.

## Instructions

### Plan Document Header

Every plan MUST start with this header in `implementation_plan.md` or a similar artifact:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### Task Structure

Break down the work into tasks that are small and verifiable. Use the following format for each task:

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**
[Code snippet]

**Step 2: Run test to verify it fails**
[Command and expected output]

**Step 3: Write minimal implementation**
[Code snippet]

**Step 4: Run test to verify it passes**
[Command and expected output]

**Step 5: Commit**
[Git command]
```

### Key Principles
- **Exact File Paths**: Always use absolute or relative paths meaningful to the project root.
- **Complete Code**: Provide the exact code to be written, not just descriptions.
- **Verification**: Every step must have a verification method (test, build, or visual check).
- **YAGNI & DRY**: Do not over-engineer; keep the plan enabling the specific goal.
