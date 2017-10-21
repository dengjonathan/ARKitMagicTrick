//
//  ViewController.swift
//  Magic Trick
//
//  Created by Jonathan Deng on 10/11/17.
//  Copyright © 2017 Jonathan Deng. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
        print("starting up")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        print("did tap")
//        let tapLocation = sender.location(in: sceneView)
//        let results = sceneView.hitTest(tapLocation, types: .existingPlane)
//        if let result = results.first {
        let ballNode = placeBall()
        if let ball = ballNode {
            throwBall(ball)
        }
    }

    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        print("long press")
        // set a timer when the state is gesture began and then get the them time when state ended
    }
    
    private func placeBall() -> SCNNode? {
        print("placing ball")
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        let ball = SCNSphere(radius: 0.25)
        let ballNode = SCNNode(geometry: ball)
        let physicsShape = SCNPhysicsShape(geometry: SCNSphere())
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        if let transform = cameraTransform {
            ballNode.simdTransform = transform
            sceneView.scene.rootNode.addChildNode(ballNode)
            return ballNode
        }
        return nil
    }

    private func throwBall(_ ball: SCNNode) {
        print("throwing ball")
        let forwardForce = SCNVector3Make(0, 3, 8)
        ball.physicsBody?.applyForce(forwardForce, asImpulse: true)
    }

    // MARK: - ARSCNViewDelegate
    private var planeNode: SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        print("detecting anchor")
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Create an SNCPlane on the ARPlane
        print("adding new plane to anchor")
        guard let _ = anchor as? ARPlaneAnchor else {
            return
        }
//
//        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//
//        let planeMaterial = SCNMaterial()
//        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
//        plane.materials = [planeMaterial]
//
//        let planeNode = SCNNode(geometry: plane)
//        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
    
        let magicScene = SCNScene(named: "art.scnassets/magicHat.scn")
        let magicHat = magicScene?.rootNode.childNode(withName: "hat", recursively: false)
        // when a new plane node is added we add the magicHat node to it
        if let magicHatNode = magicHat {
            print("adding magic hat as node")
            node.addChildNode(magicHatNode)
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
