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

    @IBOutlet weak var directonLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    private var isHatPlaced: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.directonLabel.isHidden = true
            }
        }
    }
    
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
        sceneView.debugOptions = [.showPhysicsShapes, .showPhysicsFields]
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
        throwBall()
    }

    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        print("long press")
        // set a timer when the state is gesture began and then get the them time when state ended
    }

    @IBAction func didTapMagic(_ sender: UIButton) {
        print("tapped magic button")
    }

    private func createBallNode() -> SCNNode {
        let ball = SCNSphere(radius: 0.1)
        let ballNode = SCNNode(geometry: ball)
        let physicsShape = SCNPhysicsShape(geometry: SCNSphere())
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        return ballNode
    }
    
//    private func getBallsInHat() -> Array<SCNNode> {
//        
//    }
//    
    private func destroyBalls(balls: Array<SCNNode>) {
        
    }

    @IBAction func didTapButton(_ sender: UIButton) {
        print("tapped button")
        throwBall()
    }

    private func throwBall() {
        let ball = createBallNode()
        let (direction, position) = getUserVector()
        ball.position = position
//        let forceLocation = SCNVector3(direction.x + position.x + 3, direction.y + position.y + 2, direction.z + position.z)
        let original = SCNVector3(x: 0, y: 1, z: -3)
        let force = simd_make_float4(original.x, original.y, original.z, 0)
        let currentFrame = self.sceneView.session.currentFrame
        if let frame = currentFrame {
            let currentTransform = frame.camera.transform
            let rotatedForce = simd_mul(currentTransform, force)
            let vectorForce = SCNVector3(x: rotatedForce.x, y: rotatedForce.y, z: rotatedForce.z)
            ball.physicsBody?.applyForce(vectorForce, asImpulse: true)
            sceneView.scene.rootNode.addChildNode(ball)
        }
    }
    
    func getDirection(for point: CGPoint, in view: SCNView) -> SCNVector3 {
        let farPoint  = view.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 1))
        let nearPoint = view.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 0))
        
        return SCNVector3Make(farPoint.x - nearPoint.x, farPoint.y - nearPoint.y, farPoint.z - nearPoint.z)
    }
    
    private func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32 + 2, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }

    // MARK: - ARSCNViewDelegate
    private var planeNode: SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Create an SNCPlane on the ARPlane
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        if !isHatPlaced {
            let magicScene = SCNScene(named: "art.scnassets/magicHat.scn")
            let magicHat = magicScene?.rootNode.childNode(withName: "hat", recursively: false)
            // when a new plane node is added we add the magicHat node to it
            if let magicHatNode = magicHat {
                magicHatNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
                print("adding magic hat as node")
                node.addChildNode(magicHatNode)
                isHatPlaced = true
            }
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
