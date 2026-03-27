# CDDA Agent Play - Architecture Analysis

## Problem Statement

Goal: Create a live streaming experience where an AI agent plays CDDA text mode, narrating its actions in real-time to viewers.

Claim: A single OpenClaw agent cannot continuously play and narrate simultaneously due to OpenClaw's turn-based architecture.

---

## OpenClaw Architecture Analysis

### How OpenClaw Works

OpenClaw (built on OpenCode) is a **turn-based interactive system**:

```
User sends message → OpenClaw processes → Agent responds → Waiting for next message
```

Each agent response is a discrete "turn" with latency between turns. This is designed for coding agents, not continuous streaming.

### Key Limitations

1. **Turn-based, not streaming**: Agent completes one action cycle before waiting for next user input
2. **Latency between turns**: Each model response has processing delay
3. **No native concurrent agents**: Subagents run on-demand, not continuously in parallel

### Why Single Agent Fails for Streaming

A single agent attempting continuous narration falls into this pattern:

```
Turn 1: "I press x to look around..." → (delay) → (delay)
Turn 2: "I see a zombie..." → (delay) → (delay)
Turn 3: "I press . to wait..." → (delay) → (delay)
```

Viewer experience: Staccato messages with visible gaps, no flowing narrative.

---

## Architecture Options

### Option A: Single Agent Loop (Current)

Agent executes continuous loop, outputting narration after each action.

**Pros:**
- Simple architecture
- Single context window

**Cons:**
- Turn latency visible to viewers
- Agent tends to pause between turns waiting for "confirmation"
- No true parallel action and narration

**Verdict:** Works but feels disconnected, not true streaming.

---

### Option B: Dual Agent with Shared Log

```
Session A (Game Agent)
├── Sends commands to tmux
├── Reads screen state
├── Writes action + state to shared log
└── Continues loop

Session B (Narrator Agent)
├── Reads from shared log (tail -f)
└── Outputs narration continuously
```

**Pros:**
- True parallel action and narration
- Clean separation of concerns

**Cons:**
- Complex coordination
- Narrator agent doesn't run automatically in OpenClaw
- Shared log state management adds latency
- Two context windows to manage

**Verdict:** Theoretically sound but OpenClaw doesn't support continuously running agents.

---

### Option C: Agent + External Narrator Process

```
OpenClaw Agent (Game Controller)
├── Sends tmux commands
├── Reads screen
└── Writes to log

External Process (Narrator)
├── Runs outside OpenClaw
├── Tail -f on shared log
└── Streams narration to viewers
```

**Pros:**
- No OpenClaw limitations on narrator
- True streaming possible

**Cons:**
- Narrator is not an OpenClaw agent
- Requires external process management
- Harder to coordinate with agent decision-making

**Verdict:** Most viable for true streaming, but narrator is not an agent.

---

### Option D: Optimized Single Agent Loop

Keep single agent but optimize skill to minimize pauses:

- Explicit "do not ask, continue immediately" directives
- Batch narration within single response
- Aggressive loop continuation

**Pros:**
- No architectural complexity
- Works within OpenClaw constraints

**Cons:**
- Still has turn latency
- Requires careful prompt engineering
- May still have pauses

**Verdict:** Best practical approach for OpenClaw-native solution.

---

## Recommended Architecture

### For True Streaming (External Narrator)

If real streaming is required:

```
┌─────────────────────────────────────────────────────┐
│  OpenClaw Session (Game Agent)                      │
│  ├── tmux send-keys → CDDA game                    │
│  ├── tmux capture-pane → read screen              │
│  └── Write to: /tmp/cdda-game-log.txt             │
│       [timestamp] ACTION: h                         │
│       [timestamp] STATE: screen summary...          │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│  External Narrator Process (Python/Node/Bash)      │
│  ├── tail -f /tmp/cdda-game-log.txt              │
│  ├── Parse action + state                          │
│  └── Stream narration to output (Discord/Chat)    │
└─────────────────────────────────────────────────────┘
```

### For OpenClaw-Native (Current Best)

Single agent loop with optimized skill:

```
┌─────────────────────────────────────────────────────┐
│  OpenClaw Agent (Game + Narrator)                  │
│  └── Skill: cdda-agent-play-demo                  │
│       ├── Loop: observe → act → narrate → repeat   │
│       ├── No pauses between turns                  │
│       └── No user confirmation requests            │
└─────────────────────────────────────────────────────┘
```

---

## Current Status

### What Works

- CDDA text mode runs in tmux
- Agent can observe screen, send commands
- Basic game loop: observe → act → verify

### What Doesn't Work

- True streaming narration (OpenClaw is turn-based)
- Seamless continuous narration without pauses

### Open Questions

1. Can OpenClaw support continuously running subagents?
2. Is there an MCP or webhook mechanism for real-time streaming?
3. Should we pursue external narrator architecture?

---

## Next Steps

1. **Validate Option D**: Test optimized single agent loop with current skill
2. **Research Option C**: Investigate external narrator viability
3. **Document findings**: Update this doc with experimental results

---

## Related Documents

- `docs/AGENT-PLAY-DEMO.md` - Stable demo contract
- `docs/OPENCLAW-SKILL-CONTRACT.md` - OpenClaw-facing skill contract
- `cdda-live-demo/skills/cdda-agent-play-demo/SKILL.md` - Live streaming skill
