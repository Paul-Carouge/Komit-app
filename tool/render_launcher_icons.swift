// Renders the legacy launcher PNGs (Android 7, API 24-25) from docs/design/komit-launcher-icon.svg,
// offline, with macOS's own SVG renderer. Run from the repository root:
//   swift tool/render_launcher_icons.swift
import AppKit

let svgPath = "docs/design/komit-launcher-icon.svg"
let resourcesPath = "android/app/src/main/res"

/// The adaptive icon grid is 108 units; launchers show its central 72 units.
let adaptiveGridSize: CGFloat = 108
let visibleRegionOrigin: CGFloat = 18
let visibleRegionSize: CGFloat = 72

/// Legacy icons are drawn as a rounded square, like most launchers before adaptive icons.
let cornerRadiusShareOfSize: CGFloat = 0.22

let pixelSizeByDensity: [(String, Int)] = [
  ("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192),
]

guard let svgImage = NSImage(contentsOf: URL(fileURLWithPath: svgPath)) else {
  fatalError("Cannot read \(svgPath); run from the repository root.")
}

for (density, pixelSize) in pixelSizeByDensity {
  let size = CGFloat(pixelSize)
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)
  else { fatalError("Cannot allocate a \(pixelSize) px bitmap.") }
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
  let bounds = NSRect(x: 0, y: 0, width: size, height: size)
  NSBezierPath(roundedRect: bounds, xRadius: size * cornerRadiusShareOfSize, yRadius: size * cornerRadiusShareOfSize).addClip()
  // Scale the whole 108-unit grid so its visible 72-unit square fills the bitmap.
  let scale = size / visibleRegionSize
  let drawnSize = adaptiveGridSize * scale
  let offset = -visibleRegionOrigin * scale
  svgImage.draw(in: NSRect(x: offset, y: offset, width: drawnSize, height: drawnSize))
  NSGraphicsContext.restoreGraphicsState()
  guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot encode the \(density) icon.")
  }
  let outputPath = "\(resourcesPath)/mipmap-\(density)/ic_launcher.png"
  do {
    try png.write(to: URL(fileURLWithPath: outputPath))
  } catch {
    fatalError("Cannot write \(outputPath): \(error)")
  }
  print("\(outputPath): \(pixelSize) px")
}
