#!/usr/bin/env swift
// Generates raw mock screenshots for Vault app using CoreGraphics

import Cocoa
import Foundation

let bgColor = NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
let surfaceColor = NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
let champagne = NSColor(red: 0.84, green: 0.72, blue: 0.53, alpha: 1)
let darkGold = NSColor(red: 0.65, green: 0.53, blue: 0.33, alpha: 1)
let textWhite = NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
let textSecondary = NSColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1)
let greenColor = NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1)
let redColor = NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
let blueColor = NSColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)

let screenW: CGFloat = 430
let screenH: CGFloat = 932

struct WatchData {
    let brand: String; let model: String; let ref: String
    let value: Double; let purchasePrice: Double
    let movement: String; let material: String; let size: String
    let dial: String; let complications: [String]
}

let watches: [WatchData] = [
    WatchData(brand: "Rolex", model: "Submariner Date", ref: "126610LN", value: 14200, purchasePrice: 10550, movement: "Automatic", material: "Steel", size: "41mm", dial: "Black", complications: ["Date"]),
    WatchData(brand: "Omega", model: "Speedmaster Pro", ref: "310.30.42.50", value: 7500, purchasePrice: 6550, movement: "Manual", material: "Steel", size: "42mm", dial: "Black", complications: ["Chronograph"]),
    WatchData(brand: "Patek Philippe", model: "Nautilus", ref: "5711/1A-010", value: 128000, purchasePrice: 35000, movement: "Automatic", material: "Steel", size: "40mm", dial: "Blue", complications: ["Date"]),
    WatchData(brand: "Rolex", model: "GMT-Master II", ref: "126710BLNR", value: 18500, purchasePrice: 11300, movement: "Automatic", material: "Steel", size: "40mm", dial: "Black", complications: ["Date", "GMT"]),
    WatchData(brand: "A. Lange & Söhne", model: "Lange 1", ref: "191.032", value: 42000, purchasePrice: 38500, movement: "Manual", material: "Gold", size: "38.5mm", dial: "Silver", complications: ["Power Reserve"]),
    WatchData(brand: "Grand Seiko", model: "Snowflake", ref: "SBGA211", value: 5800, purchasePrice: 5600, movement: "Spring Drive", material: "Titanium", size: "41mm", dial: "White", complications: ["Power Reserve"]),
]

func fmt(_ v: Double) -> String { let nf = NumberFormatter(); nf.numberStyle = .decimal; nf.maximumFractionDigits = 0; return "$" + (nf.string(from: NSNumber(value: v)) ?? String(Int(v))) }

let outputDir: String = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func makeImage(_ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let w = Int(screenW * 3), h = Int(screenH * 3)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    cg.scaleBy(x: 3, y: 3)
    cg.translateBy(x: 0, y: screenH)
    cg.scaleBy(x: 1, y: -1)
    draw(cg)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    let path = "\(outputDir)/\(name)"
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("✓ \(name)")
}

func fill(_ cg: CGContext, _ r: CGRect, _ c: NSColor) {
    cg.setFillColor(c.cgColor); cg.fill(r)
}

func roundRect(_ cg: CGContext, _ r: CGRect, _ rad: CGFloat, _ c: NSColor) {
    cg.setFillColor(c.cgColor)
    cg.addPath(CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil))
    cg.fillPath()
}

func text(_ s: String, _ pt: CGPoint, _ font: NSFont, _ color: NSColor, maxW: CGFloat = screenW - 40) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let as_ = NSAttributedString(string: s, attributes: attrs)
    let fs = CTFramesetterCreateWithAttributedString(as_)
    let sz = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRangeMake(0,0), nil, CGSize(width: maxW, height: 200), nil)
    let cg = NSGraphicsContext.current!.cgContext
    cg.saveGState()
    cg.translateBy(x: pt.x, y: pt.y + sz.height)
    cg.scaleBy(x: 1, y: -1)
    let path = CGPath(rect: CGRect(origin: .zero, size: CGSize(width: maxW, height: sz.height + 5)), transform: nil)
    CTFrameDraw(CTFramesetterCreateFrame(fs, CFRangeMake(0,0), path, nil), cg)
    cg.restoreGState()
}

func centeredText(_ s: String, _ pt: CGPoint, _ font: NSFont, _ color: NSColor) {
    let sz = (s as NSString).size(withAttributes: [.font: font])
    text(s, CGPoint(x: pt.x - sz.width/2, y: pt.y), font, color)
}

func navBar(_ cg: CGContext, _ title: String) {
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: 60), bgColor)
    text("9:41", CGPoint(x: 30, y: 17), .boldSystemFont(ofSize: 16), textWhite)
    text(title, CGPoint(x: 20, y: 62), NSFont(name: "Georgia-Bold", size: 34) ?? .boldSystemFont(ofSize: 34), textWhite)
}

func tabBar(_ cg: CGContext, _ sel: Int) {
    let y = screenH - 90
    fill(cg, CGRect(x: 0, y: y, width: screenW, height: 90), surfaceColor)
    let tabs = ["Collection", "Wear", "Insurance", "Wishlist", "More"]
    let icons = ["⌚", "📅", "🛡️", "💫", "⋯"]
    let w = screenW / CGFloat(tabs.count)
    for (i, tab) in tabs.enumerated() {
        let x = CGFloat(i) * w + w/2
        let c = i == sel ? champagne : textSecondary
        centeredText(icons[i], CGPoint(x: x, y: y + 12), .systemFont(ofSize: 20), c)
        centeredText(tab, CGPoint(x: x, y: y + 38), .systemFont(ofSize: 10), c)
    }
}

// 1 - Collection
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    navBar(cg, "Collection")
    
    let sy: CGFloat = 110
    roundRect(cg, CGRect(x: 16, y: sy, width: screenW-32, height: 56), 12, surfaceColor)
    text("6 Watches", CGPoint(x: 30, y: sy+10), .systemFont(ofSize: 13, weight: .medium), textSecondary)
    text("$216,000", CGPoint(x: 30, y: sy+28), .systemFont(ofSize: 17, weight: .bold), champagne)
    text("+$114,550", CGPoint(x: 220, y: sy+28), .systemFont(ofSize: 17, weight: .bold), greenColor)
    
    let gridY: CGFloat = 182; let cw = (screenW-48)/2; let ch = cw + 70
    for (i, w) in watches.prefix(6).enumerated() {
        let col = CGFloat(i % 2), row = CGFloat(i / 2)
        let r = CGRect(x: 16 + col*(cw+16), y: gridY + row*(ch+12), width: cw, height: ch)
        roundRect(cg, r, 16, surfaceColor)
        roundRect(cg, CGRect(x: r.minX+8, y: r.minY+8, width: r.width-16, height: r.width-16), 12, NSColor(white: 0.15, alpha: 1))
        centeredText("⌚", CGPoint(x: r.midX, y: r.minY + r.width*0.35), .systemFont(ofSize: 40), textSecondary)
        let ty = r.minY + r.width + 4
        text(w.brand, CGPoint(x: r.minX+12, y: ty), .systemFont(ofSize: 11, weight: .medium), champagne, maxW: r.width-24)
        text(w.model, CGPoint(x: r.minX+12, y: ty+16), .systemFont(ofSize: 13, weight: .semibold), textWhite, maxW: r.width-24)
        text(fmt(w.value), CGPoint(x: r.minX+12, y: ty+34), .systemFont(ofSize: 12, weight: .medium), greenColor, maxW: r.width-24)
    }
    
    let fab = CGRect(x: screenW-76, y: screenH-160, width: 56, height: 56)
    roundRect(cg, fab, 28, champagne)
    centeredText("+", CGPoint(x: fab.midX, y: fab.minY+14), .boldSystemFont(ofSize: 28), bgColor)
    tabBar(cg, 0)
}, "01-collection.png")

// 2 - Detail
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    let w = watches[0]; let heroH: CGFloat = 360
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: heroH), NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1))
    centeredText("⌚", CGPoint(x: screenW/2, y: heroH*0.3), .systemFont(ofSize: 100), textSecondary)
    text("‹ Back", CGPoint(x: 16, y: 54), .systemFont(ofSize: 17, weight: .medium), champagne)
    
    for i in 0..<4 {
        roundRect(cg, CGRect(x: screenW/2-24+CGFloat(i)*16, y: heroH-25, width: 8, height: 8), 4, i==0 ? champagne : textSecondary)
    }
    
    var y = heroH + 20
    text(w.brand, CGPoint(x: 20, y: y), .systemFont(ofSize: 14, weight: .medium), champagne)
    y += 22
    text(w.model, CGPoint(x: 20, y: y), NSFont(name: "Georgia-Bold", size: 26) ?? .boldSystemFont(ofSize: 26), textWhite)
    y += 36; text("Ref. \(w.ref)", CGPoint(x: 20, y: y), .systemFont(ofSize: 14), textSecondary)
    
    y += 36; roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 90), 12, surfaceColor)
    text("Current Value", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 13), textSecondary)
    text(fmt(w.value), CGPoint(x: 30, y: y+32), .systemFont(ofSize: 28, weight: .bold), textWhite)
    let gain = w.value - w.purchasePrice
    text("+\(fmt(gain)) (+\(String(format:"%.1f", gain/w.purchasePrice*100))%)", CGPoint(x: 30, y: y+64), .systemFont(ofSize: 14, weight: .medium), greenColor)
    
    y += 108; text("Specifications", CGPoint(x: 20, y: y), .systemFont(ofSize: 18, weight: .bold), textWhite)
    y += 30
    for (l, v) in [("Movement", w.movement), ("Case Material", w.material), ("Case Size", w.size), ("Dial Color", w.dial), ("Complications", w.complications.joined(separator: ", "))] {
        roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 44), 10, surfaceColor)
        text(l, CGPoint(x: 30, y: y+13), .systemFont(ofSize: 14), textSecondary)
        text(v, CGPoint(x: 240, y: y+13), .systemFont(ofSize: 14, weight: .medium), textWhite)
        y += 50
    }
}, "02-detail.png")

// 3 - Value Tracking
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    navBar(cg, "Value Tracking")
    
    var y: CGFloat = 110
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 100), 12, surfaceColor)
    text("Portfolio Value", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 13), textSecondary)
    text("$216,000", CGPoint(x: 30, y: y+34), .systemFont(ofSize: 34, weight: .bold), textWhite)
    text("+$114,550 (+112.8%)", CGPoint(x: 30, y: y+72), .systemFont(ofSize: 15, weight: .medium), greenColor)
    y += 116
    
    // Chart
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 220), 12, surfaceColor)
    text("12 Month Trend", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 15, weight: .semibold), textWhite)
    
    cg.setStrokeColor(champagne.cgColor); cg.setLineWidth(2.5)
    let cx: CGFloat = 40, cw: CGFloat = screenW-80, cy = y+50, ch: CGFloat = 140
    let pts: [CGFloat] = [0.3,0.35,0.32,0.4,0.45,0.5,0.48,0.55,0.6,0.65,0.7,0.75]
    cg.beginPath()
    for (i,p) in pts.enumerated() {
        let px = cx+CGFloat(i)*cw/CGFloat(pts.count-1), py = cy+ch-p*ch
        if i==0 { cg.move(to: CGPoint(x: px, y: py)) } else { cg.addLine(to: CGPoint(x: px, y: py)) }
    }
    cg.strokePath()
    
    // Gradient fill
    cg.saveGState(); cg.beginPath()
    for (i,p) in pts.enumerated() {
        let px = cx+CGFloat(i)*cw/CGFloat(pts.count-1), py = cy+ch-p*ch
        if i==0 { cg.move(to: CGPoint(x: px, y: py)) } else { cg.addLine(to: CGPoint(x: px, y: py)) }
    }
    cg.addLine(to: CGPoint(x: cx+cw, y: cy+ch)); cg.addLine(to: CGPoint(x: cx, y: cy+ch)); cg.closePath(); cg.clip()
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [champagne.withAlphaComponent(0.3).cgColor, champagne.withAlphaComponent(0).cgColor] as CFArray, locations: [0,1])!
    cg.drawLinearGradient(grad, start: CGPoint(x: 0, y: cy), end: CGPoint(x: 0, y: cy+ch), options: [])
    cg.restoreGState()
    y += 236
    
    text("By Watch", CGPoint(x: 20, y: y), .systemFont(ofSize: 18, weight: .bold), textWhite); y += 30
    for w in watches.prefix(5) {
        roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 60), 10, surfaceColor)
        text(w.brand, CGPoint(x: 30, y: y+10), .systemFont(ofSize: 11), champagne)
        text(w.model, CGPoint(x: 30, y: y+26), .systemFont(ofSize: 14, weight: .medium), textWhite)
        let g = w.value-w.purchasePrice; let p = g/w.purchasePrice*100
        text(fmt(w.value), CGPoint(x: 300, y: y+10), .systemFont(ofSize: 15, weight: .bold), textWhite)
        text("\(g>=0 ? "+" : "")\(String(format:"%.1f",p))%", CGPoint(x: 300, y: y+32), .systemFont(ofSize: 12, weight: .medium), g>=0 ? greenColor : redColor)
        y += 68
    }
    tabBar(cg, 0)
}, "03-value.png")

// 4 - Wear Calendar
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    navBar(cg, "Wear History"); tabBar(cg, 1)
    
    var y: CGFloat = 110
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 44), 12, surfaceColor)
    centeredText("‹   February 2026   ›", CGPoint(x: screenW/2, y: y+12), .systemFont(ofSize: 17, weight: .semibold), textWhite)
    y += 56
    
    let dh = ["S","M","T","W","T","F","S"]; let cw = (screenW-32)/7
    for (i,d) in dh.enumerated() { centeredText(d, CGPoint(x: 16+CGFloat(i)*cw+cw/2, y: y), .systemFont(ofSize: 13, weight: .medium), textSecondary) }
    y += 28
    
    let worn: Set = [1,2,3,5,6,8,9,10,12,14,15,16,18,19,20,22,23,24,25,26,27,28]
    let colors: [NSColor] = [champagne, blueColor, greenColor, darkGold]
    for day in 1...28 {
        let idx = day-1, col = idx%7, row = idx/7
        let cx = 16+CGFloat(col)*cw+cw/2, cy = y+CGFloat(row)*50
        if worn.contains(day) {
            let c = colors[day%colors.count]
            roundRect(cg, CGRect(x: cx-16, y: cy, width: 32, height: 32), 16, c)
            centeredText("\(day)", CGPoint(x: cx, y: cy+7), .systemFont(ofSize: 14, weight: .bold), bgColor)
        } else {
            centeredText("\(day)", CGPoint(x: cx, y: cy+7), .systemFont(ofSize: 14), textSecondary)
        }
    }
    y += 5*50+24
    
    text("This Month", CGPoint(x: 20, y: y), .systemFont(ofSize: 18, weight: .bold), textWhite); y += 30
    let sw = (screenW-48)/2
    for (i,(l,v)) in [("Days Worn","22 / 28"),("Most Worn","Submariner"),("Streak","6 days"),("Variety","4 watches")].enumerated() {
        let r = CGRect(x: 16+CGFloat(i%2)*(sw+16), y: y+CGFloat(i/2)*76, width: sw, height: 68)
        roundRect(cg, r, 12, surfaceColor)
        text(l, CGPoint(x: r.minX+14, y: r.minY+12), .systemFont(ofSize: 12), textSecondary)
        text(v, CGPoint(x: r.minX+14, y: r.minY+32), .systemFont(ofSize: 18, weight: .bold), textWhite)
    }
}, "04-wear.png")

// 5 - Insurance
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    navBar(cg, "Insurance"); tabBar(cg, 2)
    
    var y: CGFloat = 110
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 100), 12, surfaceColor)
    text("Total Insured Value", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 13), textSecondary)
    text("$216,000", CGPoint(x: 30, y: y+34), .systemFont(ofSize: 32, weight: .bold), textWhite)
    text("6 watches  •  3 appraisals current", CGPoint(x: 30, y: y+72), .systemFont(ofSize: 13), textSecondary)
    y += 120
    
    text("Documents", CGPoint(x: 20, y: y), .systemFont(ofSize: 18, weight: .bold), textWhite); y += 30
    let docs = [
        ("📋", "Rolex Submariner", "Appraisal", "Valid until Dec 2026", greenColor),
        ("📋", "Patek Nautilus", "Appraisal", "Valid until Sep 2026", greenColor),
        ("📄", "Omega Speedmaster", "Purchase Receipt", "Jun 2024", champagne),
        ("📋", "GMT-Master II", "Appraisal", "Expires Mar 2026", redColor),
        ("📄", "Collection Policy", "Insurance Certificate", "Chubb Premium", champagne),
        ("📋", "Lange 1", "Appraisal", "Valid until Aug 2026", greenColor),
    ]
    for (icon, title, type, status, statusColor) in docs {
        roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 72), 12, surfaceColor)
        text(icon, CGPoint(x: 26, y: y+22), .systemFont(ofSize: 28), textWhite)
        text(title, CGPoint(x: 66, y: y+14), .systemFont(ofSize: 15, weight: .semibold), textWhite)
        text(type, CGPoint(x: 66, y: y+34), .systemFont(ofSize: 13), textSecondary)
        text(status, CGPoint(x: 66, y: y+52), .systemFont(ofSize: 12, weight: .medium), statusColor)
        y += 80
    }
}, "05-insurance.png")

// 6 - Wishlist
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    navBar(cg, "Wishlist"); tabBar(cg, 3)
    
    var y: CGFloat = 110
    let wishes = [
        ("Audemars Piguet", "Royal Oak 15500ST", "$38,500", "▼ $2,100 from peak", greenColor),
        ("Vacheron Constantin", "Overseas 4500V", "$28,900", "▲ $1,500 from 6mo ago", redColor),
        ("Cartier", "Santos de Cartier", "$8,200", "▼ $800 from peak", greenColor),
        ("IWC", "Portugieser Chrono", "$9,100", "Stable ±$200", champagne),
        ("Tudor", "Black Bay 58", "$3,800", "▼ $400 from peak", greenColor),
    ]
    for (brand, model, price, trend, tColor) in wishes {
        roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 100), 16, surfaceColor)
        // Image placeholder
        roundRect(cg, CGRect(x: 28, y: y+12, width: 76, height: 76), 12, NSColor(white: 0.15, alpha: 1))
        centeredText("⌚", CGPoint(x: 66, y: y+32), .systemFont(ofSize: 32), textSecondary)
        text(brand, CGPoint(x: 118, y: y+16), .systemFont(ofSize: 12, weight: .medium), champagne)
        text(model, CGPoint(x: 118, y: y+34), .systemFont(ofSize: 16, weight: .semibold), textWhite)
        text(price, CGPoint(x: 118, y: y+56), .systemFont(ofSize: 15, weight: .bold), textWhite)
        text(trend, CGPoint(x: 118, y: y+76), .systemFont(ofSize: 12, weight: .medium), tColor)
        
        // Bell icon
        text("🔔", CGPoint(x: screenW-60, y: y+40), .systemFont(ofSize: 20), champagne)
        y += 112
    }
    
    let fab = CGRect(x: screenW-76, y: screenH-160, width: 56, height: 56)
    roundRect(cg, fab, 28, champagne)
    centeredText("+", CGPoint(x: fab.midX, y: fab.minY+14), .boldSystemFont(ofSize: 28), bgColor)
}, "06-wishlist.png")

// 7 - Apple Watch
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    
    // Large Apple Watch frame
    let awW: CGFloat = 240, awH: CGFloat = 290
    let awX = (screenW-awW)/2, awY: CGFloat = 140
    roundRect(cg, CGRect(x: awX-12, y: awY-12, width: awW+24, height: awH+24), 50, NSColor(white: 0.2, alpha: 1))
    roundRect(cg, CGRect(x: awX, y: awY, width: awW, height: awH), 40, NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1))
    
    // Digital crown
    roundRect(cg, CGRect(x: awX+awW+12, y: awY+80, width: 8, height: 40), 3, NSColor(white: 0.25, alpha: 1))
    
    // Watch face content - complication
    centeredText("VAULT", CGPoint(x: screenW/2, y: awY+30), .systemFont(ofSize: 12, weight: .bold), champagne)
    centeredText("⌚", CGPoint(x: screenW/2, y: awY+55), .systemFont(ofSize: 50), textSecondary)
    centeredText("Submariner", CGPoint(x: screenW/2, y: awY+120), .systemFont(ofSize: 16, weight: .semibold), textWhite)
    centeredText("Wearing today", CGPoint(x: screenW/2, y: awY+142), .systemFont(ofSize: 11), champagne)
    
    // Quick log button
    roundRect(cg, CGRect(x: awX+30, y: awY+175, width: awW-60, height: 40), 20, champagne)
    centeredText("Log Wear", CGPoint(x: screenW/2, y: awY+187), .systemFont(ofSize: 14, weight: .bold), bgColor)
    
    // Complication preview below
    centeredText("3 Day Streak 🔥", CGPoint(x: screenW/2, y: awY+232), .systemFont(ofSize: 12, weight: .medium), greenColor)
    
    // Phone mockups below
    var y = awY + awH + 60
    centeredText("Quick Actions from Your Wrist", CGPoint(x: screenW/2, y: y), NSFont(name: "Georgia-Bold", size: 22) ?? .boldSystemFont(ofSize: 22), textWhite)
    y += 40
    let features = ["Log wear instantly", "View today's watch", "Check collection value", "Complications support"]
    for f in features {
        roundRect(cg, CGRect(x: 40, y: y, width: screenW-80, height: 44), 10, surfaceColor)
        text("✓  \(f)", CGPoint(x: 56, y: y+12), .systemFont(ofSize: 15, weight: .medium), textWhite)
        y += 52
    }
}, "07-watch.png")

// 8 - Analytics
save(makeImage { cg in
    fill(cg, CGRect(x: 0, y: 0, width: screenW, height: screenH), bgColor)
    navBar(cg, "Analytics"); tabBar(cg, 4)
    
    var y: CGFloat = 110
    // Top stats row
    let sw = (screenW-48)/3
    let topStats = [("Total Value", "$216K"), ("Watches", "6"), ("Appreciation", "+113%")]
    for (i,(l,v)) in topStats.enumerated() {
        let r = CGRect(x: 16+CGFloat(i)*(sw+8), y: y, width: sw, height: 68)
        roundRect(cg, r, 12, surfaceColor)
        centeredText(l, CGPoint(x: r.midX, y: r.minY+12), .systemFont(ofSize: 11), textSecondary)
        centeredText(v, CGPoint(x: r.midX, y: r.minY+34), .systemFont(ofSize: 20, weight: .bold), champagne)
    }
    y += 86
    
    // Brand breakdown
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 200), 12, surfaceColor)
    text("Brand Distribution", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 15, weight: .semibold), textWhite)
    
    // Donut chart mock
    let centerX = screenW/2 - 60, centerY = y + 115, radius: CGFloat = 65
    let slices: [(CGFloat, NSColor)] = [(0.35, champagne), (0.25, blueColor), (0.2, greenColor), (0.12, darkGold), (0.08, textSecondary)]
    var startAngle: CGFloat = -.pi/2
    for (frac, color) in slices {
        let endAngle = startAngle + frac * 2 * .pi
        cg.setFillColor(color.cgColor)
        cg.move(to: CGPoint(x: centerX, y: centerY))
        cg.addArc(center: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        cg.closePath(); cg.fillPath()
        startAngle = endAngle
    }
    // Donut hole
    roundRect(cg, CGRect(x: centerX-35, y: centerY-35, width: 70, height: 70), 35, surfaceColor)
    centeredText("6", CGPoint(x: centerX, y: centerY-12), .systemFont(ofSize: 22, weight: .bold), textWhite)
    
    // Legend
    let brands = [("Rolex", "2", champagne), ("Patek Philippe", "1", blueColor), ("A. Lange", "1", greenColor), ("Omega", "1", darkGold), ("Grand Seiko", "1", textSecondary)]
    var ly = y + 60
    for (name, count, color) in brands {
        roundRect(cg, CGRect(x: screenW/2+30, y: ly, width: 10, height: 10), 5, color)
        text("\(name) (\(count))", CGPoint(x: screenW/2+48, y: ly-2), .systemFont(ofSize: 12), textWhite)
        ly += 22
    }
    y += 216
    
    // Wear distribution
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 180), 12, surfaceColor)
    text("Wear Frequency", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 15, weight: .semibold), textWhite)
    
    let wearData = [("Submariner", 42, champagne), ("GMT-Master", 35, blueColor), ("Speedmaster", 28, greenColor), ("Nautilus", 22, darkGold), ("Lange 1", 15, redColor), ("Snowflake", 12, textSecondary)]
    var by = y + 40
    let maxW: CGFloat = screenW - 160
    for (name, count, color) in wearData {
        text(name, CGPoint(x: 30, y: by+2), .systemFont(ofSize: 12), textWhite, maxW: 100)
        let barW = CGFloat(count) / 42.0 * maxW
        roundRect(cg, CGRect(x: 130, y: by+2, width: barW, height: 16), 8, color)
        text("\(count)", CGPoint(x: 130+barW+8, y: by+1), .systemFont(ofSize: 12, weight: .medium), textSecondary)
        by += 24
    }
    y += 196
    
    // Cost per wear
    roundRect(cg, CGRect(x: 16, y: y, width: screenW-32, height: 80), 12, surfaceColor)
    text("Cost Per Wear", CGPoint(x: 30, y: y+12), .systemFont(ofSize: 15, weight: .semibold), textWhite)
    text("Submariner: $251/wear  •  Best value in collection", CGPoint(x: 30, y: y+38), .systemFont(ofSize: 13), champagne)
    text("Nautilus: $1,591/wear  •  Consider wearing more!", CGPoint(x: 30, y: y+56), .systemFont(ofSize: 13), textSecondary)
}, "08-analytics.png")

print("\nAll screenshots generated!")
