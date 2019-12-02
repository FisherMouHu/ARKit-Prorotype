//
//  ViewController.swift
//  ARKit Prototype
//
//  Created by Vineet Joshi on 11/21/19.
//  Copyright © 2019 Vineet Joshi. All rights reserved.
//

//  3D Model retrieved from: https://poly.google.com/view/7Q_Ab2HLll1

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    enum BodyType : Int {
        case ObjectModel = 2;
    }

    var currentAngleY: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Improves the lighting of the sceneView
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.debugOptions = [.showFeaturePoints]
        
        registerGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func registerGestureRecognizers(){
        // Handle tap gesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Handle pan gesture ( to move the 3D model )
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        
        // Handle pinch gesture ( to resize the 3D model )
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        // Handle rotate gesture
        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate))
        self.sceneView.addGestureRecognizer(rotateGestureRecognizer)
    }
    
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else {return}
        
        let touch = recognizer.location(in: recognizerView)
        
        guard let hitTestResult = recognizerView.hitTest(touch, types: .existingPlane).first else { return }

        let couchAnchor = ARAnchor(name:"couch", transform: hitTestResult.worldTransform)
        
        self.sceneView.session.add(anchor: couchAnchor)
    }
    
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: recognizerView)
        
        let hitTestResult = self.sceneView.hitTest(
            touch,
            options: [SCNHitTestOption.categoryBitMask: BodyType.ObjectModel.rawValue]
        )
        
        guard let modelNodeHit = getParentNodeOf(hitTestResult.first?.node)?.parent else { return }
        
        var planeHit : ARHitTestResult!
        
        if recognizer.state == .changed {
            let hitTestPlane = self.sceneView.hitTest(touch, types: .existingPlane)
            
            guard hitTestPlane.first != nil else { return }
            
            planeHit = hitTestPlane.first!
            
            modelNodeHit.position = SCNVector3(
                planeHit.worldTransform.columns.3.x,
                // planeHit.worldTransform.columns.3.y,
                modelNodeHit.position.y,
                planeHit.worldTransform.columns.3.z
            )
        }
        else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
            
        }
    }
    
    @objc func handlePinch(recognizer: UIPinchGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: recognizerView)
        
        let hitTestResult = self.sceneView.hitTest(
            touch,
            options: [SCNHitTestOption.categoryBitMask: BodyType.ObjectModel.rawValue]
        )
        
        guard let modelNodeHit = getParentNodeOf(hitTestResult.first?.node)?.parent else { return }
        
        if recognizer.state == .changed {
            let pinchScaleX: CGFloat = recognizer.scale * CGFloat((modelNodeHit.scale.x))
            
            let pinchScaleY: CGFloat = recognizer.scale * CGFloat((modelNodeHit.scale.y))
            
            let pinchScaleZ: CGFloat = recognizer.scale * CGFloat((modelNodeHit.scale.z))
            
            modelNodeHit.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            
            recognizer.scale = 1
        }
        else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
            
        }
    }
    
    @objc func handleRotate(recognizer: UIRotationGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: recognizerView)
        
        let hitTestResult = self.sceneView.hitTest(
            touch,
            options: [SCNHitTestOption.categoryBitMask: BodyType.ObjectModel.rawValue]
        )
        
        guard let modelNodeHit = getParentNodeOf(hitTestResult.first?.node)?.parent else { return }
        
        // Get the current rotation
        let rotation = Float(recognizer.rotation)
        
        if recognizer.state == .changed {
            modelNodeHit.eulerAngles.y = currentAngleY + rotation
        }
        else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
            currentAngleY = modelNodeHit.eulerAngles.y
        }
    }
    
    // Find the parent node for 3D model
    func getParentNodeOf(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == "couchModel" {
                return node
            } else if let parent = node.parent {
                return getParentNodeOf(parent)
            }
        }
        return nil
    }
    
    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    // Called whenever a new anchor is created and returns a new node associated with that specific anchor.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Execute the correct code depending on the name of the newly created anchor.
        // Add more if statesments for new models eg. if(anchor.name == "house")...
        let rootNode = SCNNode()
        
        if (anchor.name == "couch") {
            if let couchScene = SCNScene(named: "art.scnassets/couch.dae") {
                if let couchNode = couchScene.rootNode.childNode(withName: "couchModel", recursively: true) {
            
                    couchNode.categoryBitMask = BodyType.ObjectModel.rawValue
                    
                    couchNode.enumerateChildNodes { (node, _) in
                        node.categoryBitMask = BodyType.ObjectModel.rawValue
                    }
                        
                    rootNode.addChildNode(couchNode)
                }
            }
        }
            
        return rootNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            print("Plane Detected")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
