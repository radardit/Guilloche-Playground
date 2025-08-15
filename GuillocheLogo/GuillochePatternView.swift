//
//  GuillochePatternView.swift
//  GuillocheLogo
//
//  Created by Daren Smith on 8/13/25.
//

import SwiftUI


public struct GuillochePatternView: View {
    public var config: GuillocheConfig

    public init(config: GuillocheConfig) {
        self.config = config
    }

    
    public var body: some View {
        GeometryReader { proxy in
            Canvas { context, canvasSize in

                guard canvasSize.width > 0 && canvasSize.height > 0 else { return }
                
                let rect = CGRect(origin: .zero, size: canvasSize)
                let path = GuillocheGeometry.fullPath(in: rect, config: config)

                if path.isEmpty {
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
                        miterLimit: 10
                    )
                    context.stroke(path, with: .color(config.color), style: strokeStyle)
                }
            }
            .drawingGroup()
        }
        .accessibilityHidden(true)
    }
}



public extension View {
    func guillocheBackground(_ config: GuillocheConfig, size: CGSize? = nil, alignment: Alignment = .center) -> some View {
        background(alignment: alignment) {
            if let size {
                GuillochePatternView(config: config)
                    .frame(width: size.width, height: size.height)
            } else {
                GuillochePatternView(config: config)
            }
        }
    }
}
