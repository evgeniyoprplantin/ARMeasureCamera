//
//  ARMeasureViewController.swift
//
//
//  Created by Evgeniy Opryshko on 20.07.2023.
//

import UIKit
import SceneKit
import ARKit
import SwiftUI

final public class ARMeasureViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var startNode: SCNNode?
    var endNode: SCNNode?
    var line_node: SCNNode?
    var textNode: SCNNode?

    var focusNode: SCNNode!
    var focusNodeTracker: ARNodeTracker = ARNodeTracker()
    
    let model = TextLabelViewViewModel()
    
    //MARK: - Life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        initScene()
        initARSession()
        initFocusNode()
        initFocusNodeTracker()
        initTextNode()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK: - Actions
    
    @IBAction func addPointAction(_ sender: Any) {
        guard endNode == nil else {
            reset()
            return
        }
        
        if let position = self.doHitTestOnExistingPlanes() {
            // add node at hit-position
            let node = self.nodeWithPosition(position)
            
            if startNode == nil {
                // set start node
                startNode = node
            } else {
                endNode = node
            }
            
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func reset() {
        startNode?.removeFromParentNode()
        startNode = nil
        
        endNode?.removeFromParentNode()
        endNode = nil
        
        line_node?.removeFromParentNode()
        line_node = nil
        
        textNode?.opacity = 0
    }
    
    func doHitTestOnExistingPlanes() -> SCNVector3? {
        // hit-test of view's center with existing-planes
        let results = sceneView.hitTest(view.center, types: .existingPlaneUsingExtent)
        // check if result is available
        if let result = results.first {
            // get vector from transform
            let hitPos = self.positionFromTransform(result.worldTransform)
            return hitPos
        }
        return nil
    }
    
    // get position 'vector' from 'transform'
    func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x,
                              transform.columns.3.y,
                              transform.columns.3.z)
    }
    
    // add dot node with given position
    func nodeWithPosition(_ position: SCNVector3) -> SCNNode {
        // create sphere geometry with radius
        let sphere = SCNSphere(radius: 0.002)
        // set color
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        // set lighting model
        sphere.firstMaterial?.lightingModel = .constant
        sphere.firstMaterial?.isDoubleSided = true
        // create node with 'sphere' geometry
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        return node
    }
 
    func createTextNod() -> SCNNode {
        let plane = SCNPlane(width: 10, height: 10)
        let arVC = UIHostingController(rootView: TextLabelView(model: model)).view
        
        let material = SCNMaterial()
        material.isDoubleSided = true
        arVC?.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        arVC?.isOpaque = false
        arVC?.backgroundColor = UIColor.clear
        material.diffuse.contents = arVC
        
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        return node
    }
    
    func cylinderLine(from: SCNVector3, to: SCNVector3) -> SCNNode {

        let x1 = from.x
        let x2 = to.x

        let y1 = from.y
        let y2 = to.y

        let z1 = from.z
        let z2 = to.z

        let distance = sqrtf((x2 - x1) * (x2 - x1) +
                             (y2 - y1) * (y2 - y1) +
                             (z2 - z1) * (z2 - z1))

        let cylinder = SCNCylinder(radius: 0.0005, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = UIColor.white
        cylinder.firstMaterial?.lightingModel = .constant
        cylinder.firstMaterial?.isDoubleSided = true

        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = SCNVector3(((from.x + to.x)/2),
                                       ((from.y + to.y)/2),
                                       ((from.z + to.z)/2))
        lineNode.eulerAngles = SCNVector3(Float.pi/2,
                                          acos((to.z - from.z)/distance),
                                          atan2(to.y - from.y, to.x - from.x))
        return lineNode
    }
    
    /**
     Distance string
     */
    func getDistanceStringBetween(pos1: SCNVector3?, pos2: SCNVector3?) -> String? {
        guard let pos1 = pos1, let pos2 = pos2 else { return nil }
        
        let distance = distanceBetweenPoints(A: pos1, B: pos2)
        guard distance > 0.1 else { return nil }
        
        
//        let meter = stringValue(v: Float(d), unit: "meters")
//        result.append(meter)
//        result.append("\n")
//
//        let f = self.foot_fromMeter(m: Float(d))
//        let feet = stringValue(v: Float(f), unit: "feet")
//        result.append(feet)
//        result.append("\n")
//
//        let inch = self.Inch_fromMeter(m: Float(d))
//        let inches = stringValue(v: Float(inch), unit: "inch")
//        result.append(inches)
//        result.append("\n")
        
        let cm = self.CM_fromMeter(m: Float(distance))
        print(stringValue(v: Float(cm), unit: "cm"))
        return stringValue(v: Float(cm), unit: "cm")
    }
    
    /**
     Distance between 2 points
     */
    func distanceBetweenPoints(A: SCNVector3, B: SCNVector3) -> CGFloat {
        let l = sqrt(
            (A.x - B.x) * (A.x - B.x)
                +   (A.y - B.y) * (A.y - B.y)
                +   (A.z - B.z) * (A.z - B.z)
        )
        return CGFloat(l)
    }
    
    /**
     String with float value and unit
     */
    func stringValue(v: Float, unit: String) -> String {
        let s = String(format: "%.1f %@", v, unit)
        return s
    }
    
    /**
     feet from meter
     */
    func foot_fromMeter(m: Float) -> Float {
        let v = m * 3.28084
        return v
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

// MARK: - Session Management (ARSessionObserver)

extension ARMeasureViewController {

    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {}

    public func session(_ session: ARSession, didFailWithError error: Error) {}

    public func sessionWasInterrupted(_ session: ARSession) {}

    public func sessionInterruptionEnded(_ session: ARSession) {}
}

// MARK: - Render Management

extension ARMeasureViewController {
    
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            
            // focus node
            self.focusNodeTracker.updateAt(time: time)
            
            // get current hit position
            // and check if start-node is available
            guard let start = self.startNode,
                  let currentPosition = self.doHitTestOnExistingPlanes() else { return }
            
            let endPosition = self.endNode?.position ?? currentPosition
            
            // line-node
            self.line_node?.removeFromParentNode()
            self.line_node = self.cylinderLine(from: endPosition, to: start.position)
            self.sceneView.scene.rootNode.addChildNode(self.line_node!)
            
            if let desc = self.getDistanceStringBetween(pos1: endPosition, pos2: start.position),
               let camera = self.sceneView.session.currentFrame?.camera {
                self.textNode?.opacity = 1
                
                
                //                    self.textNode?.eulerAngles.x = camera.eulerAngles.x //line_node.eulerAngles.x
                //                    self.textNode?.eulerAngles.y = line_node.eulerAngles.y
                //                    self.textNode?.eulerAngles.z = line_node.eulerAngles.z
                //                    self.textNode?.eulerAngles.x = camera.eulerAngles.x + .pi / 2
                //                    self.textNode?.eulerAngles.y = camera.eulerAngles.y
                //                    self.textNode?.eulerAngles.z = line_node.eulerAngles.z
                
                //self.textNode?.eulerAngles = line_node.eulerAngles
                //                    self.textNode?.eulerAngles.x = line_node.eulerAngles.x //+ .pi / 2
                //                    self.textNode?.eulerAngles.y = line_node.eulerAngles.y
                //                self.textNode?.eulerAngles = line_node.eulerAngles
                self.textNode?.eulerAngles.x = camera.eulerAngles.x //+ .pi / 2
                self.textNode?.eulerAngles.y = camera.eulerAngles.y
                
                
                self.textNode?.position.x = endPosition.x + 0.05
                self.textNode?.position.y = endPosition.y
                self.textNode?.position.z = endPosition.z
                
                self.model.updateText(desc)
            } else {
                self.textNode?.opacity = 0
            }
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {}

    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {}

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {}
}

// MARK: - Scene Management

extension ARMeasureViewController {
    func initScene() {
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR World Tracking not supported")
            return
        }

        let config = ARWorldTrackingConfiguration()

        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.planeDetection = [.horizontal]
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic

        sceneView.session.run(config)
    }

    func resetARSession() {
        let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
        config.planeDetection = [.horizontal]
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: - Node Management

extension ARMeasureViewController {
    
    func initFocusNode() {
        let focusScene = SCNScene(named: "art.scnassets/Focus.scn")!
        focusNode = focusScene.rootNode.childNode(withName: "Focus", recursively: false)
        sceneView.scene.rootNode.addChildNode(focusNode)
    }

    func initFocusNodeTracker() {
        focusNodeTracker.sceneView = sceneView
        focusNodeTracker.trackedNode = focusNode
        focusNodeTracker.trackingNode = sceneView.pointOfView!
    }
    
    func initTextNode() {
        textNode = createTextNod()
        textNode?.position = SCNVector3(x: 0, y: 0, z: 0)
        sceneView.scene.rootNode.addChildNode(self.textNode!)
    }
}
