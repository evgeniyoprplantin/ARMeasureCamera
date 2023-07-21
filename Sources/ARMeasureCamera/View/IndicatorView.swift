//
//  IndicatorView.swift
//
//
//  Created by Evgeniy Opryshko on 20.07.2023.
//

import SwiftUI

public struct IndicatorView: View {
    
    @ObservedObject var manager: ARMeasureCameraManager
    
    public init(manager: ARMeasureCameraManager) {
        self.manager = manager
    }

    public var body: some View {
        Text(manager.measureText)
            .foregroundColor(.green)
            .padding(.horizontal, 6)
            .background(Color.white)
            .clipShape(Capsule())
    }
}
