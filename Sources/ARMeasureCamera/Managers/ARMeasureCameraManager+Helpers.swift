//
//  File.swift
//  
//
//  Created by Evgeniy Opryshko on 23.07.2023.
//

import Foundation

public extension ARMeasureCameraManager {
    
    enum ARMeasureAction {
        case point, reset
    }
}

public extension ARMeasureCameraManager {
    
    enum ARMeasureState: Equatable {
        case initial, ready, measuring, measurementCompleted, error
    }
}

public extension ARMeasureCameraManager {
    
    enum UnitSystem: String {
        case imperial, metric
        
        public init(_ value: String) {
            switch value {
            case UnitSystem.imperial.rawValue:
                self = .imperial
            case UnitSystem.metric.rawValue:
                self = .metric
            default:
                self = .metric
            }
        }
    }
}
