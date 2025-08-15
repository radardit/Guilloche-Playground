//
//  GuillochePattern.swift
//  GuillocheLogo
//
//  Created by Daren Smith on 8/13/25.
//

import SwiftUI

// MARK: - Codable Extensions
extension Color: Codable {
    private struct ColorComponents: Codable {
        let red: Double
        let green: Double  
        let blue: Double
        let opacity: Double
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let components = try container.decode(ColorComponents.self, forKey: .components)
        
        self = Color(.sRGB, red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Try to resolve to NSColor (macOS) or UIColor (iOS)
        #if os(macOS)
        let nsColor = NSColor(self)
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        let components = ColorComponents(
            red: Double(rgbColor.redComponent),
            green: Double(rgbColor.greenComponent), 
            blue: Double(rgbColor.blueComponent),
            opacity: Double(rgbColor.alphaComponent)
        )
        #else
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let components = ColorComponents(
            red: Double(red),
            green: Double(green),
            blue: Double(blue), 
            opacity: Double(alpha)
        )
        #endif
        
        try container.encode(components, forKey: .components)
    }
    
    private enum CodingKeys: String, CodingKey {
        case components
    }
}

extension Angle: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let radians = try container.decode(Double.self)
        self = .radians(radians)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.radians)
    }
}


public struct GuillocheConfig: Equatable, Hashable, Codable {
    public var lineWidth: CGFloat
    public var petalCount: Int
    public var rings: Int
    public var ringSpacing: CGFloat
    public var amplitude: CGFloat
    public var amplitudeFalloff: CGFloat
    public var centerRosetteRadius: CGFloat
    public var rotation: Angle
    public var color: Color
    public var marginScale: CGFloat
    public var rectWidthScale: CGFloat
    public var rectHeightScale: CGFloat
    public var useRectBoundary: Bool
    public var autoScaleToBoundary: Bool
    public var allowOverflowBeyondBoundary: Bool
    public var invert: Bool
    public init(
        lineWidth: CGFloat = 0.75,
        petalCount: Int = 32,
        rings: Int = 5,
        ringSpacing: CGFloat = 6.0,
        amplitude: CGFloat = 3.0,
        amplitudeFalloff: CGFloat = 0.99,
        centerRosetteRadius: CGFloat = 10.0,
        rotation: Angle = .degrees(0),
        color: Color = .secondary,
        marginScale: CGFloat = 0.45,
        rectWidthScale: CGFloat = 1.0,
        rectHeightScale: CGFloat = 1.0,
        useRectBoundary: Bool = false,
        autoScaleToBoundary: Bool = false,
        allowOverflowBeyondBoundary: Bool = false,
        invert: Bool = false
    ) {
        self.lineWidth = lineWidth
        self.petalCount = max(1, petalCount)
        self.rings = max(1, rings)
        self.ringSpacing = max(0.1, ringSpacing)
        self.amplitude = max(0, amplitude)
        self.amplitudeFalloff = max(0, min(1, amplitudeFalloff))
        self.centerRosetteRadius = max(0, centerRosetteRadius)
        self.rotation = rotation
        self.color = color
        self.marginScale = max(0.05, marginScale)
        self.rectWidthScale = max(0.1, rectWidthScale)
        self.rectHeightScale = max(0.1, rectHeightScale)
        self.useRectBoundary = useRectBoundary
        self.autoScaleToBoundary = autoScaleToBoundary
        self.allowOverflowBeyondBoundary = allowOverflowBeyondBoundary
        self.invert = invert
    }

    public static let `default` = GuillocheConfig()
}



public enum GuillocheGeometry {
    public static func ringPath(in rect: CGRect, ringIndex i: Int, config: GuillocheConfig) -> Path {
        let size = rect.size
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Use the inscribed circle budget as baseline for circular geometry
        let circleR = min(size.width, size.height) * 0.5 * config.marginScale
        if circleR <= 0 { return Path() }

        let lastIndex = max(0, config.rings - 1)

        let baseRRaw = config.centerRosetteRadius + CGFloat(i) * config.ringSpacing
        let ampRaw: CGFloat
        if config.invert {
            let distFromOuter = max(0, lastIndex - i)
            ampRaw = config.amplitude * pow(config.amplitudeFalloff, CGFloat(distFromOuter))
        } else {
            ampRaw = config.amplitude * pow(config.amplitudeFalloff, CGFloat(i))
        }

        // Optional scaling to touch boundary only applies when not overflowing and not using rect
        let scale: CGFloat
        if !config.allowOverflowBeyondBoundary && !config.useRectBoundary && config.autoScaleToBoundary {
            let lastIndex = max(0, config.rings - 1)
            let baseRLast = config.centerRosetteRadius + CGFloat(lastIndex) * config.ringSpacing
            let ampLast: CGFloat
            if config.invert {
                ampLast = config.amplitude * pow(config.amplitudeFalloff, 0)
            } else {
                ampLast = config.amplitude * pow(config.amplitudeFalloff, CGFloat(lastIndex))
            }
            let denom = baseRLast + ampLast
            scale = denom > 0 ? min(1.0, circleR / denom) : 1.0
        } else {
            scale = 1.0
        }

        let baseR = baseRRaw * scale
        let amp = ampRaw * scale

        // For overflow, don’t reject big rings
        if !config.allowOverflowBeyondBoundary {
            let maxRadius = baseR + amp
            if maxRadius <= 0 || baseR - amp < 0 || maxRadius > circleR {
                return Path()
            }
        } else {
            if baseR + amp <= 0 { return Path() }
        }

        let k = max(1, config.petalCount)
        let segments = max(360, min(k * 60, 2160))
        let twoPi = CGFloat.pi * 2
        let dθ = twoPi / CGFloat(segments)
        let rot = CGFloat(config.rotation.radians)

        var p = Path()
        var first = true

        for s in 0...segments {
            let θ = CGFloat(s) * dθ
            let aθ = θ + rot
            let rPolar = baseR + amp * cos(CGFloat(k) * θ)

            // No rectangular mapping; keep circular nature. If overflowing, no normalization clamp.
            let r: CGFloat
            if config.allowOverflowBeyondBoundary {
                r = rPolar
            } else {
                let ρ = max(0, min(1, rPolar / circleR))
                r = ρ * circleR
            }

            let x = center.x + r * cos(aθ)
            let y = center.y + r * sin(aθ)

            if first {
                p.move(to: CGPoint(x: x, y: y))
                first = false
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }

        p.closeSubpath()
        return p
    }

    
    
    private static func rectangleBoundaryRadius(halfWidth a: CGFloat, halfHeight b: CGFloat, angle: CGFloat) -> CGFloat {
        let c = cos(angle)
        let s = sin(angle)
        let eps: CGFloat = 1e-6

        if abs(c) < eps && abs(s) < eps { return 0 }

        var candidates: [CGFloat] = []
        if abs(c) >= eps { candidates.append(a / abs(c)) }
        if abs(s) >= eps { candidates.append(b / abs(s)) }

        let Rb = candidates.min() ?? 0
        return max(0, Rb)
    }


    
    public static func fullPath(in rect: CGRect, config: GuillocheConfig) -> Path {
        var p = Path()
        for i in 0..<config.rings {
            let ring = ringPath(in: rect, ringIndex: i, config: config)
            if !ring.isEmpty {
                p.addPath(ring)
            }
        }
        return p
    }
}
