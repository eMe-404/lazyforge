# Systematic Debugging Guide

This document establishes a four-phase methodology for addressing technical issues through root cause analysis rather than symptom-focused quick fixes.

## Core Principle

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.** Random patches are wasteful and counterproductive — they mask symptoms, create new bugs, and erode confidence in the codebase.

## The Four Phases

**Phase 1: Root Cause Investigation**
- Carefully examine error messages and stack traces
- Reproduce the issue consistently
- Review recent code changes
- For multi-component systems, add diagnostic instrumentation at each boundary
- Trace data flow backward to find the source

**Phase 2: Pattern Analysis**
- Locate similar working code
- Compare working versus broken implementations completely
- Identify all differences, however minor
- Understand dependencies and assumptions

**Phase 3: Hypothesis and Testing**
- Formulate a specific hypothesis about the root cause
- Test with minimal changes (one variable at a time)
- Form a new hypothesis if testing fails
- Acknowledge knowledge gaps rather than guessing

**Phase 4: Implementation**
- Create a failing test case first
- Implement a single fix addressing the root cause
- Verify the fix resolves the issue without breaking other tests
- After 3+ failed fix attempts, question the underlying architecture

## Critical Red Flags

Warning signs that indicate process violation:
- Attempting quick fixes before investigation
- Proposing multiple simultaneous changes
- Skipping test creation
- Continuing fix attempts beyond three failures without stepping back

## Key Insight

When you have already tried multiple fixes, or are experiencing repeated new problems in different areas, the appropriate response is architectural review — not additional fix attempts. Stop, zoom out, and re-examine the root cause from scratch.
