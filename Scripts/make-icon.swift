import AppKit
let root = URL(fileURLWithPath:CommandLine.arguments[1])
try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
for size in [16,32,128,256,512] {
    for scale in [1,2] {
        let pixels = size*scale
        let image = NSImage(size:NSSize(width:1024,height:1024))
        image.lockFocus()
        let rect = NSRect(x:64,y:64,width:896,height:896)
        let shape = NSBezierPath(roundedRect:rect,xRadius:200,yRadius:200)
        NSGradient(starting:NSColor(srgbRed:0.12,green:0.63,blue:1,alpha:1),ending:NSColor(srgbRed:0.1,green:0.23,blue:0.87,alpha:1))!.draw(in:shape,angle:-75)
        let font = NSFont.systemFont(ofSize:290,weight:.medium)
        let attributes: [NSAttributedString.Key:Any] = [.font:font,.foregroundColor:NSColor.white]
        ("A" as NSString).draw(at:NSPoint(x:173,y:403),withAttributes:attributes)
        ("Я" as NSString).draw(at:NSPoint(x:624,y:403),withAttributes:attributes)
        let path = NSBezierPath(); path.lineWidth = 31; path.lineCapStyle = .round; path.lineJoinStyle = .round
        path.move(to:NSPoint(x:245,y:310));path.line(to:NSPoint(x:764,y:310));path.move(to:NSPoint(x:712,y:362));path.line(to:NSPoint(x:764,y:310));path.line(to:NSPoint(x:712,y:258))
        path.move(to:NSPoint(x:778,y:746));path.line(to:NSPoint(x:259,y:746));path.move(to:NSPoint(x:311,y:798));path.line(to:NSPoint(x:259,y:746));path.line(to:NSPoint(x:311,y:694))
        NSColor.white.withAlphaComponent(0.9).setStroke();path.stroke()
        image.unlockFocus()
        let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
        NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:bitmap)
        image.draw(in:NSRect(x:0,y:0,width:pixels,height:pixels));NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try bitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent(name))
    }
}
