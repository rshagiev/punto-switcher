<!--
Sync Impact Report
==================
Version change: 0.0.0 → 1.0.0
Modified principles: N/A (initial creation)
Added sections: Core Principles (5), Quality Standards, Development Workflow, Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ Compatible (Constitution Check section exists)
  - .specify/templates/spec-template.md: ✅ Compatible
  - .specify/templates/tasks-template.md: ✅ Compatible
Follow-up TODOs: None
-->

# Punto Constitution

## Core Principles

### I. Native macOS First

Punto MUST be a native macOS application using Swift and system frameworks (AppKit, CoreGraphics, Accessibility API). No Electron, no cross-platform frameworks. This ensures:
- Minimal memory footprint (<50MB)
- Instant response to hotkeys (<50ms)
- Proper integration with macOS security model

**Rationale**: Layout conversion requires real-time keyboard interception. Only native implementation can achieve the responsiveness users expect.

### II. Invisible Operation

Punto MUST operate as a background menu bar utility that never interrupts user workflow. The app:
- MUST NOT show dock icons or windows unless explicitly requested
- MUST NOT require user attention for normal operation
- MUST provide visual feedback only through subtle menu bar icon changes

**Rationale**: A layout converter must be invisible to be useful. Any friction defeats its purpose.

### III. Privacy & Security

Punto MUST NOT:
- Transmit any keystroke data over the network
- Store typed content beyond the current word buffer (max 50 characters)
- Request permissions beyond Accessibility (required for operation)

All processing MUST happen locally. The word buffer MUST be cleared on each conversion or word boundary.

**Rationale**: Users trust Punto with their keystrokes. This trust must never be violated.

### IV. Defensive Event Handling

All CGEvent tap operations MUST:
- Implement debouncing (minimum 0.5s between conversions)
- Use `ignoreEvents` flag during text replacement to prevent re-capture
- Handle `tapDisabledByTimeout` and `tapDisabledByUserInput` by re-enabling the tap
- Reset state flags when all modifiers are released

**Rationale**: Event taps are fragile. Defensive coding prevents the app from becoming unresponsive or causing conversion loops.

### V. Graceful Degradation

When Accessibility API fails (Chrome, Electron apps), Punto MUST:
- Fall back to clipboard-based text access (Cmd+C/V)
- Maintain functionality with acceptable latency (<200ms)
- Never crash or hang due to uncooperative applications

**Rationale**: Users expect Punto to work everywhere. When perfect operation is impossible, acceptable operation is required.

## Quality Standards

### Code Quality

- All public APIs MUST have clear, testable contracts
- Error handling MUST log to `/tmp/punto.log` with sufficient context for debugging
- Timing constants MUST be defined as named constants, not magic numbers

### Testing Requirements

- Core conversion logic (`LayoutConverter`) MUST have comprehensive unit tests
- Integration testing via `swift run PuntoTest all` MUST pass before releases
- Manual testing checklist in TECHNICAL_SPEC.md MUST be verified for releases

### Performance Budgets

| Metric | Budget |
|--------|--------|
| Hotkey detection latency | <50ms |
| Text conversion (100 chars) | <100ms |
| Memory usage (idle) | <50MB |
| CPU usage (idle) | <1% |

## Development Workflow

### Build Process

1. Development builds: `swift build -c release --arch arm64`
2. Release builds: Universal binary via `./Scripts/build.sh`
3. Testing: `swift run PuntoTest all` before any merge

### Change Management

- All changes affecting hotkey detection MUST be tested on at least 3 different apps (TextEdit, VSCode, Chrome)
- Changes to `HotkeyManager.swift` require extra scrutiny due to complexity
- Timing constant changes MUST document the reason in commit message

### Debugging

- Logs at `/tmp/punto.log` with format `[HH:mm:ss.SSS] [File:Line] LEVEL: Message`
- Diagnostics via `swift run PuntoDiag all`

## Governance

1. This constitution supersedes all other project practices when conflicts arise
2. Amendments require:
   - Documentation of the change and rationale
   - Update to this file with version increment
   - Propagation check across templates in `.specify/templates/`
3. All code reviews MUST verify compliance with these principles
4. Complexity beyond these standards MUST be justified in the PR description

**Version**: 1.0.0 | **Ratified**: 2026-01-17 | **Last Amended**: 2026-01-17
