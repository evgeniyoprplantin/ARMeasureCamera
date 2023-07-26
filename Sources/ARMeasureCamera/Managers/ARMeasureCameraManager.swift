//
//  ARMeasureCameraManager.swift
//  
//
//  Created by Evgeniy Opryshko on 21.07.2023.
//

import SwiftUI
import Combine

public class ARMeasureCameraManager: ObservableObject {
    
    @Published public var state: ARMeasureState = .initial
    @Published public var unitSystem: UnitSystem = .metric
    @Published public var measureText: String = ""
    public var measure: Float?
    
    public let publisher = PassthroughSubject<ARMeasureAction, Never>()
    
    //MARK: - Init
    
    public init(unitSystem: ARMeasureCameraManager.UnitSystem = .metric) {
        self.unitSystem = unitSystem
    }
    
    public func addPoint() {
        publisher.send(.point)
    }
    
    public func reset() {
        publisher.send(.reset)
    }
    
    public func updateMarkText(with text: String) {
        measureText = text
    }
    
    public func updateMarkText(with distance: CGFloat) -> String {
        let cm = self.CM_fromMeter(m: Float(distance))
        measure = cm
        
        switch unitSystem {
        case .imperial:
            let inch = Inch_fromMeter(m: Float(distance))
            return stringValue(v: Float(inch), unit: "in")
        case .metric:
            return stringValue(v: Float(cm), unit: "cm")
        }
    }
    
    public func changeUnitSystem(to unitSystem: ARMeasureCameraManager.UnitSystem) {
        self.unitSystem = unitSystem
    }
    
    /**
     String with float value and unit
     */
    func stringValue(v: Float, unit: String) -> String {
        let s = String(format: "%.1f %@", v, unit)
        return s
    }
        
    /**
     Inch from meter
     */
    func Inch_fromMeter(m: Float) -> Float {
        let v = m * 39.3701
        return v
    }
    
    /**
     centimeter from meter
     */
    func CM_fromMeter(m: Float) -> Float {
        let v = m * 100.0
        return v
    }
}
