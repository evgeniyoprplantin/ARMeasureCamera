//
//  ARMeasureViewController.swift
//
//
//  Created by Evgeniy Opryshko on 20.07.2023.
//

import SceneKit
import ARKit
import SwiftUI
import Combine

final public class ARMeasureViewController: UIViewController, ARSCNViewDelegate {

    private(set) var sceneView: ARSCNView!
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var line_node: SCNNode?
    private var textNode: SCNNode?
    private var focusNode: SCNNode!
    private var focusNodeTracker: ARNodeTracker = ARNodeTracker()
    private var cancellables = Set<AnyCancellable>()
    private var manager: ARMeasureCameraManager!
    let coachingOverlay = ARCoachingOverlayView()
        
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.ARMeasureViewCamera.serialSceneKitQueue")
    
    // Settings
    public var indicatorForegroundColor: UIColor?
    public var indicatorFont: UIFont?
    public var planeDetection: ARWorldTrackingConfiguration.PlaneDetection = [.horizontal]
    
    //MARK: - Life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        initScene()
        initARSession()
        initFocusNode()
        
        // Set up coaching overlay.
        setupCoachingOverlay()
        
        subscriptions()
        
        setState(.initial)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.frame = view.frame
        
        initFocusNodeTracker()
        initIndicatorNode(with: " ")
        
        setState(.ready)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK: - Configure
    
    public func configureWith(manager: ARMeasureCameraManager, indicatorForegroundColor: UIColor? = .green, indicatorFont: UIFont? = UIFont.systemFont(ofSize: 1)) {
        self.manager = manager
        self.indicatorForegroundColor = indicatorForegroundColor
        self.indicatorFont = indicatorFont
    }
    
    //MARK: - Actions
    
    public func addPoint() {
        guard endNode == nil else {
            reset()
            setState(.ready)
            return
        }
        
        if let position = self.doHitTestOnExistingPlanes() {
            // add node at hit-position
            let node = self.nodeWithPosition(position)
            updateQueue.async {
                if self.startNode == nil {
                    // set start node
                    self.startNode = node
                    self.setState(.measuring)
                } else {
                    self.endNode = node
                    self.setState(.measurementCompleted)
                }
                
                self.sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }
    
    func subscriptions() {
        manager.publisher
            .sink { [weak self] action in
                switch action {
                case .point:
                    self?.addPoint()
                case .reset:
                    self?.reset()
                }
            }
            .store(in: &cancellables)
    }
    
    public func reset() {
        startNode?.removeFromParentNode()
        startNode = nil
        
        endNode?.removeFromParentNode()
        endNode = nil
        
        line_node?.removeFromParentNode()
        line_node = nil
        
        textNode?.opacity = 0
        
        setState(.ready)
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
 
    //TODO EO: figure out what's going on ?
//    func createIndicatorNodeFromUIView() -> SCNNode {
//        let plane = SCNPlane(width: 10, height: 10)
//
//        let arMarkView = indicatorView ?? UIHostingController(rootView: IndicatorView(manager: manager)).view
//        arMarkView?.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        arMarkView?.isOpaque = false
//        arMarkView?.backgroundColor = UIColor.clear
//
//        let material = SCNMaterial()
//        material.isDoubleSided = true
//        material.diffuse.contents = arMarkView
//
//        plane.materials = [material]
//
//        let node = SCNNode(geometry: plane)
//        node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
//        node.pivot = SCNMatrix4MakeTranslation(-1, -1, 0)
//        return node
//    }
    
    func createIndicatorNode(with text: String) -> SCNNode {
        let text = SCNText(string: text, extrusionDepth: 0.1)
        text.font = indicatorFont
        text.flatness = 0.005
        let textNode = SCNNode(geometry: text)
        let fontScale: Float = 0.01
        textNode.scale = SCNVector3(fontScale, fontScale, fontScale)
        textNode.geometry?.firstMaterial?.diffuse.contents = indicatorForegroundColor
        
        // Get the bounding box of the text
        let (min, max) = (text.boundingBox.min, text.boundingBox.max)
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        let width = (max.x - min.x) * fontScale
        let height = (max.y - min.y) * fontScale
        
        // Add padding around the text
        let paddingX: Float = 0.005
        let paddingY: Float = 0.0025
        let paddedWidth = width + paddingX * 2
        let paddedHeight = height + paddingY * 2
        
        // Create a rounded corner plane with the padded dimensions
        let plane = SCNPlane(width: CGFloat(paddedWidth), height: CGFloat(paddedHeight))
        plane.cornerRadius = CGFloat(paddedHeight * 0.5) // Set the corner radius to half of the height for rounded corners
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = textNode.position
        textNode.eulerAngles = planeNode.eulerAngles
        planeNode.addChildNode(textNode)
        
        return planeNode
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
    func getDistanceStringBetween(pos1: SCNVector3?, pos2: SCNVector3?) -> CGFloat? {
        guard let pos1 = pos1, let pos2 = pos2 else { return nil }
        
        let distance = distanceBetweenPoints(A: pos1, B: pos2)
        guard distance > 0.01 else { return nil }
        
        return distance
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
    
    //MARK: - Private methods
    
    private func setState(_ state: ARMeasureCameraManager.ARMeasureState) {
        DispatchQueue.main.async {
            self.manager.state = state
        }
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

        guard !coachingOverlay.isActive else { return }
        
        DispatchQueue.main.async {
            // focus node
            self.updateQueue.async {
                self.focusNodeTracker.updateAt(time: time)
            }
            
            // check if start-node is available
            guard let start = self.startNode else { return }
            
            // get current hit position
            guard let currentPosition = self.doHitTestOnExistingPlanes() else { return }
            
            let endPosition = self.endNode?.position ?? currentPosition
            
            // line-node
            self.line_node?.removeFromParentNode()
            self.line_node = self.cylinderLine(from: endPosition, to: start.position)
            self.sceneView.scene.rootNode.addChildNode(self.line_node!)
            
            if let distance = self.getDistanceStringBetween(pos1: endPosition, pos2: start.position),
               let camera = self.sceneView.session.currentFrame?.camera {
                self.textNode?.removeFromParentNode()
                
                let text = self.manager.updateMarkText(with: distance)
                self.textNode = self.createIndicatorNode(with: text)
                
                self.textNode?.opacity = 1
                
                self.textNode?.position.x = endPosition.x + 0.015
                self.textNode?.position.y = endPosition.y + 0.015
                self.textNode?.position.z = endPosition.z
                
                self.textNode?.eulerAngles.x = camera.eulerAngles.x
                self.textNode?.eulerAngles.y = camera.eulerAngles.y
                
                self.sceneView.scene.rootNode.addChildNode(self.textNode!)
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
        sceneView = ARSCNView()
        view.addSubview(sceneView)
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            setState(.error)
            return
        }

        let config = ARWorldTrackingConfiguration()

        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.planeDetection = planeDetection
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic

        sceneView.session.run(config)
    }

    func resetARSession() {
        let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
        config.planeDetection = planeDetection
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: - Node Management

extension ARMeasureViewController {
    
    func initFocusNode() {
        if let url = Bundle.module.url(forResource: "Focus", withExtension: "scn") {
            do {
                let focusScene = try SCNScene(url: url)
                focusNode = focusScene.rootNode.childNode(withName: "Focus", recursively: false)
                
                updateQueue.async {
                    self.sceneView.scene.rootNode.addChildNode(self.focusNode)
                }
            } catch {
                print("Error loading Focus scene: \(error)")
            }
        }
    }

    func initFocusNodeTracker() {
        focusNodeTracker.sceneView = sceneView
        focusNodeTracker.trackedNode = focusNode
        focusNodeTracker.trackingNode = sceneView.pointOfView
    }
    
    func initIndicatorNode(with text: String) {
        updateQueue.async {
            self.textNode = self.createIndicatorNode(with: text)
            self.textNode?.position = SCNVector3(x: 0, y: 0, z: 0)
            self.textNode?.opacity = 0.001
        
            self.sceneView.scene.rootNode.addChildNode(self.textNode!)
        }
    }
}
