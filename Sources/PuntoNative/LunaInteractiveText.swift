import AppKit
import SwiftUI
import PuntoCore

private let placeholderAttribute = NSAttributedString.Key("PuntoDisplayPlaceholder")
private final class ReviewTextView:NSTextView {
    override func copy(_ sender:Any?) {
        guard let storage = textStorage, selectedRange().length > 0 else { return }
        let selection = storage.attributedSubstring(from:selectedRange())
        var plain = ""
        selection.enumerateAttribute(placeholderAttribute,in:NSRange(location:0,length:selection.length)) { value,range,_ in
            if value == nil { plain += (selection.string as NSString).substring(with:range) }
        }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(plain,forType:.string)
    }
}

struct LunaInteractiveText:NSViewRepresentable {
    let diff:ProofreadingDiff
    let plain:String
    let right:Bool
    let rejected:Set<Int>
    let enabled:Bool
    let toggle:(Int)->Void
    final class Coordinator:NSObject,NSTextViewDelegate {
        var toggle:(Int)->Void
        init(_ toggle:@escaping(Int)->Void) { self.toggle = toggle }
        func textView(_ textView:NSTextView,clickedOnLink link:Any,at charIndex:Int) -> Bool {
            guard let url = link as? URL, let id = Int(url.host ?? "") else { return false }
            toggle(id); return true
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(toggle) }
    func makeNSView(context:Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false; scroll.hasVerticalScroller = true; scroll.autohidesScrollers = true
        let view = ReviewTextView(frame:scroll.contentView.bounds)
        view.isEditable = false; view.isSelectable = true; view.drawsBackground = false
        view.isVerticallyResizable = true; view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.textContainer?.containerSize = NSSize(width:scroll.contentSize.width,height:CGFloat.greatestFiniteMagnitude)
        view.textContainerInset = NSSize(width:12,height:16)
        view.linkTextAttributes = [.foregroundColor:NSColor.labelColor,.underlineStyle:0]
        view.delegate = context.coordinator
        scroll.documentView = view
        return scroll
    }
    func updateNSView(_ scroll:NSScrollView,context:Context) {
        guard let view = scroll.documentView as? NSTextView else { return }
        context.coordinator.toggle = toggle
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 5
        let base:[NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:13),.foregroundColor:NSColor.labelColor,.paragraphStyle:paragraph]
        let result = NSMutableAttributedString(string:"")
        func append(_ text:String,_ attributes:[NSAttributedString.Key:Any] = [:]) {
            result.append(NSAttributedString(string:text,attributes:base.merging(attributes,uniquingKeysWith:{$1})))
        }
        if diff.edits.isEmpty { append(plain) }
        else {
            let ns = diff.original as NSString
            var cursor = 0
            for edit in diff.edits {
                append(ns.substring(with:NSRange(location:cursor,length:edit.range.location-cursor)))
                let accepted = !rejected.contains(edit.id)
                let text = right && accepted ? edit.replacement : edit.original
                let tint:NSColor = accepted ? (right ? .systemGreen : .systemOrange) : .secondaryLabelColor
                var attributes:[NSAttributedString.Key:Any] = [
                    .backgroundColor:tint.withAlphaComponent(accepted ? 0.18 : 0.10),
                    .font:NSFont.systemFont(ofSize:13,weight:.medium),
                    .toolTip:accepted ? "Нажмите, чтобы оставить исходный вариант" : "Нажмите, чтобы вернуть исправление"
                ]
                if enabled { attributes[.link] = URL(string:"punto-change://\(edit.id)")! }
                // Empty insertions/deletions need a visible target for reversing the choice.
                // This display-only marker is excluded from Copy and never enters Apply.
                if text.isEmpty {
                    attributes[placeholderAttribute] = true
                    attributes[.foregroundColor] = NSColor.tertiaryLabelColor
                    append("·",attributes)
                } else { append(text,attributes) }
                cursor = NSMaxRange(edit.range)
            }
            append(ns.substring(from:cursor))
        }
        if view.textStorage?.isEqual(to:result) != true {
            let origin = scroll.contentView.bounds.origin
            view.textStorage?.setAttributedString(result)
            scroll.contentView.scroll(to:origin); scroll.reflectScrolledClipView(scroll.contentView)
        }
    }
}
