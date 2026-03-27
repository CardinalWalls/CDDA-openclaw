---
name: cdda-agent-play-demo
description: Use when the user wants OpenClaw to directly play CDDA through the current text runtime, showing a clean gameplay loop with real observation, action, verification, and viewer-facing narration.
---

# CDDA Agent Play Demo for OpenClaw

Use this skill when the user wants OpenClaw to actually play CDDA, not just discuss it.

## Purpose

This skill should make OpenClaw:

1. connect to the current playable runtime
2. read the visible game state
3. choose one gameplay action
4. execute the action in the real game
5. verify the visible result
6. explain the turn in viewer-facing language

## Current Runtime Boundary

Current proven runtime:

- CDDA official text/curses runtime in `tmux`

Current proven interaction seam:

- observe with `tmux capture-pane`
- act with `tmux send-keys`

Do not claim this is already the final OpenClaw runtime.
Do claim this is the current real gameplay runtime that OpenClaw can drive.

## Required Loop

For every turn:

1. observe the current pane
2. identify current context:
   - map
   - look mode
   - inventory
   - character sheet
   - dialogue
   - menu
3. choose one action that is justified by visible evidence
4. execute the action
5. observe again
6. verify whether the expected state changed
7. narrate what happened and why it mattered

If the action fails, say so and recover cleanly.

## Demo Priorities

Prefer actions that create a legible, game-like showcase:

- `Look around`
- extended description
- inventory
- character sheet
- cautious movement

Avoid thin demos made only of repeated movement.

## Currently Proven Safe Commands

- `x`
- `e`
- `Escape`
- `i`
- `@`
- `h`
- `j`
- `l`

Treat these as the current stable demo surface.

## Coverage Rule

The long-term goal is wider command coverage.
The current skill must not pretend all commands are already stabilized.

For commands outside the proven surface:

- discover them through visible help/keybinding surfaces
- validate them live before treating them as stable
- record failures explicitly

## Good Requests

Examples:

- `@cdda-agent-play-demo play a short opening CDDA session and explain each turn`
- `@cdda-agent-play-demo show me map, stats, inventory, and movement in one clean loop`
- `@cdda-agent-play-demo actually play for a few turns and verify each action`

## Expected Result

A successful run should leave:

- a viewer-facing summary of the play loop
- the actions taken
- the visible evidence for each step
- the gameplay facts learned during the run
- any failed commands or recovery steps
