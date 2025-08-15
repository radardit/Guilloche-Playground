//
//  GuillochePatternView.swift
//  cMail
//
//  Created by Daren Smith on 8/13/25.
//

import SwiftUI

/// A SwiftUI View that renders a multi-ring guilloché pattern.
/// This view expands to fill its container; use `.frame(width:height:)` on it or the background modifier to control size.
public struct GuillochePatternView: View {
    public var config: GuillocheConfig

    public init(config: GuillocheConfig) {
        self.config = config
    }

    public var body: some View {
        GeometryReader { proxy in
            Canvas { context, canvasSize in
                // Debug: ensure we have a valid canvas size
                guard canvasSize.width > 0 && canvasSize.height > 0 else { return }
                
                let rect = CGRect(origin: .zero, size: canvasSize)
                let path = GuillocheGeometry.fullPath(in: rect, config: config)
                
                // Debug: Check if path is empty
                if path.isEmpty {
                    // Draw a debug circle to show the view is working
                    let debugPath = Path { p in
                        p.addEllipse(in: CGRect(x: canvasSize.width/4, y: canvasSize.height/4,
                                               width: canvasSize.width/4, height: canvasSize.height/2))
                    }
                    context.stroke(debugPath, with: .color(.red), style: StrokeStyle(lineWidth: 0.5))
                } else {
                    let strokeStyle = StrokeStyle(
                        lineWidth: config.lineWidth, 
                        lineCap: .round, 
                        lineJoin: .round, 
                        miterLimit: 10 // Increased miter limit
                    )
                    context.stroke(path, with: .color(config.color), style: strokeStyle)
                }
            }
            .drawingGroup() // improves antialiasing and can help performance for many paths
        }
        // The pattern itself is purely decorative
        .accessibilityHidden(true)
    }
}

/// A convenience modifier to apply the guilloché as a background to any view.
/// Optionally pass a size for the background independent of the view's own size.
public extension View {
    func guillocheBackground(_ config: GuillocheConfig, size: CGSize? = nil, alignment: Alignment = .center) -> some View {
        background(alignment: alignment) {
            if let size {
                GuillochePatternView(config: config)
                    .frame(width: size.width, height: size.height)
            } else {
                // Match the parent view's proposed size by default
                GuillochePatternView(config: config)
            }
        }
    }
}
