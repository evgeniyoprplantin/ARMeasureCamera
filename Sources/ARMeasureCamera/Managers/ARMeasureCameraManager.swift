//
//  ARMeasureCameraManager.swift
//  
//
//  Created by Evgeniy Opryshko on 21.07.2023.
//

import SwiftUI
import Combine

public class ARMeasureCameraManager: ObservableObject {
    
    public enum ARMeasureAction {
        case point, reset
    }
    
    public enum ARMeasureState: Equatable {
        case initial, ready, measuring, measurementCompleted, error
    }
    
    @Published public var state: ARMeasureState = .initial
    @Published var measureText: String = ""
    public let publisher = PassthroughSubject<ARMeasureAction, Never>()
    
    public init() { }
    
    public func addPoint() {
        publisher.send(.point)
    }
    
    public func reset() {
        publisher.send(.reset)
    }
    
    public func updateMarkText(_ text: String) {
        self.measureText = text
    }
}
