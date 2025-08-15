//
//  GuillocheView.swift
//  cMail
//
//  Created by Daren Smith on 8/13/25.
//

import SwiftUI

// Size of the watch face base parameters
private var baseH = 120.00
private var baseW = 100.00


// Lets bring in the Guilloche Params
struct GuillocheView: View {
    private let guilloche = GuillocheConfig(
        lineWidth: 0.25,
        petalCount: 10,
        rings: 14,
        ringSpacing: 4.5,
        amplitude: 3,
        amplitudeFalloff: 1,
        centerRosetteRadius: 4,
        rotation: .degrees(0),
        color: .white,
        marginScale: 1.2,
        rectWidthScale: 1.0,
        rectHeightScale: 1.3,
        useRectBoundary: false,
        autoScaleToBoundary: false,
        allowOverflowBeyondBoundary: true,
        invert: false
    )
    
// Let's build a watch face - Make it nice and detailed.
    var body: some View {
        VStack {
            ZStack {
                    Rectangle()
                    
                    .frame(width: baseW, height: baseH)
                    .border(Color.gray.opacity(0.6), width: 12)
                        .cornerRadius(8)
                
                    GuillochePatternView(config: guilloche)
                    .frame(width: baseW-25, height: baseH-25)

                        
                
                .frame(width: baseW-20, height: baseH-20)
                .border(Color.gray.opacity(0.4), width: 12)
                
                
                .frame(width: baseW-21, height: baseH-21)
                .border(Color.white, width: 0.3)

                
                .frame(width: baseW-41, height: baseH-41)
                .border(Color.white, width: 0.5)
                .border(Color.black.opacity(0.2), width: 12)
                    
                    
                
                Text("Cartier")
                    .font(.custom("SnellRoundhand", size: 14, relativeTo: .caption))
                    .foregroundColor(.white)
                    .padding(.bottom, 48)
                    .padding(.horizontal, 2)
                
                Text("2022")
                    .font(.custom("Times New Roman", size: 10, relativeTo: .caption))
                    .foregroundColor(.white)
                    .padding(.top, 55)
                    .padding(.horizontal, 2)
                    
            }
            
            
        }
        
        .padding()
    }
}

#Preview {
    GuillocheView()
}
