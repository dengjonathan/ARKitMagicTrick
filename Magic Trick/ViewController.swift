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
        let scene = SCNScene(named: "art.scnassets/magicHat.scn")!
        
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
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
