import Foundation
import PuntoCore

func runPointerEventPolicyTests() throws {
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.leftMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on left mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.rightMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on right mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: PointerEventPolicy.otherMouseDownRawValue),
        .clearTrackedText(reason: "pointer click"),
        "pointer event policy clears tracked text on other mouse down"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 2),
        .ignore,
        "pointer event policy ignores mouse up"
    )
    try expect(
        PointerEventPolicy.action(eventTypeRawValue: 10),
        .ignore,
        "pointer event policy ignores non-click events"
    )
}
