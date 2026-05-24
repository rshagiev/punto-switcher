import Foundation
import PuntoCore

func runKeyboardFocusPolicyTests() throws {
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy accepts typed enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Ghostty",
                role: "AXTextArea",
                isEnabled: true,
                isFocused: false
            )
        ),
        true,
        "keyboard focus policy allows typed enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "TextEdit",
                role: "AXTextArea",
                isEnabled: false,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "Finder",
                role: "AXButton",
                isEnabled: true,
                isFocused: true
            )
        ),
        false,
        "keyboard focus policy rejects typed non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .focusedElement(
                appName: "UnknownApp",
                role: nil,
                isEnabled: true,
                isFocused: true
            )
        ),
        true,
        "keyboard focus policy keeps unknown roles eligible"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedElement(appName: "TextEdit", errorCode: -25205)
        ),
        false,
        "keyboard focus policy rejects typed missing focused element"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedApplication(errorCode: -25212),
            targetApplication: KeyboardTargetApplicationEvidence(
                appName: "Codex",
                isActive: true,
                isHidden: false
            )
        ),
        true,
        "keyboard focus policy allows active visible frontmost target when AX focused application is unavailable"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedApplication(errorCode: -25212),
            targetApplication: KeyboardTargetApplicationEvidence(
                appName: "Codex",
                isActive: false,
                isHidden: false
            )
        ),
        false,
        "keyboard focus policy rejects inactive target when AX focused application is unavailable"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedApplication(errorCode: -25212),
            targetApplication: KeyboardTargetApplicationEvidence(
                appName: "Codex",
                isActive: true,
                isHidden: true
            )
        ),
        false,
        "keyboard focus policy rejects hidden target when AX focused application is unavailable"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusEvidence: .noFocusedElement(appName: "TextEdit", errorCode: -25205),
            targetApplication: KeyboardTargetApplicationEvidence(
                appName: "TextEdit",
                isActive: true,
                isHidden: false
            )
        ),
        false,
        "keyboard focus policy still rejects focused app without focused element"
    )
    try expect(
        KeyboardFocusEvidence.focusedElement(
            appName: "TextEdit",
            role: "AXTextArea",
            isEnabled: true,
            isFocused: false
        ).logDescription,
        "app='TextEdit' role='AXTextArea' enabled=true focused=false",
        "keyboard focus evidence preserves legacy log shape"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy accepts enabled focused target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Ghostty' role='AXTextArea' enabled=true focused=false"
        ),
        true,
        "keyboard focus policy allows enabled target with unreliable focused flag"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled=false focused=true"
        ),
        false,
        "keyboard focus policy rejects disabled target"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' role='AXTextArea' enabled = 'false' focused=true"
        ),
        false,
        "keyboard focus policy rejects spaced quoted disabled evidence"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Finder' role='AXButton' enabled=true focused=true"
        ),
        false,
        "keyboard focus policy rejects non-editable focused role"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='Finder' role = 'AXButton' enabled=true focused=true"
        ),
        false,
        "keyboard focus policy rejects spaced role evidence for non-editable targets"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='UnknownApp' role='?' enabled=true focused=true"
        ),
        true,
        "keyboard focus policy preserves unknown string role eligibility"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(
            focusDescription: "app='TextEdit' NO_FOCUSED_ELEMENT (error=-25205)"
        ),
        false,
        "keyboard focus policy rejects missing focused element"
    )
    try expect(
        KeyboardFocusPolicy.shouldAttemptKeyboardReplacement(focusDescription: "  "),
        false,
        "keyboard focus policy rejects empty focus evidence"
    )
}
