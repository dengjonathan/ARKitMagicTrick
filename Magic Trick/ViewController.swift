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
    private var hat: SCNNode? {
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
        // uncomment to show debug shapes
        // sceneView.debugOptions = [.showPhysicsShapes, .showPhysicsFields]
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

    @IBAction func didTapMagic(_ sender: UIButton) {
        print("tapped magic button")
        let balls = getBallsInHat()
        toggleHiddenPropertyOfBalls(balls)
    }

    private func createBallNode() -> SCNNode {
        let ball = SCNSphere(radius: 0.05)
        let ballNode = SCNNode(geometry: ball)
        let physicsShape = SCNPhysicsShape(geometry: ball)
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        ballNode.physicsBody?.damping = 0.5
        ballNode.name = "ball"
        return ballNode
    }
    
    private func doesContain(inner: SCNNode, outer: SCNNode) -> Bool {
        // get center point of inner node
        let localPoint = inner.presentation.position
        let (localMin, localMax) = outer.boundingBox
        // convert the point to the hat's coordinate space
        let rootNode = sceneView.scene.rootNode
        let point = inner.convertPosition(localPoint, to: rootNode)
        let min = outer.convertPosition(localMin, to: rootNode)
        let max = outer.convertPosition(localMax, to: rootNode)
        // balls on the edge of the hat can sometimes get missed for some reason
        let error: Float = 0.2
        return  min.x - error <= point.x &&
            min.y - error <= point.y &&
            min.z - error <= point.z &&
            max.x + error > point.x &&
            max.y + error > point.y &&
            max.z + error > point.z
    }

    private func getBallsInHat() -> Array<SCNNode> {
        guard let hatNode = hat else {
            return [] as Array<SCNNode>
        }
        let balls = sceneView.scene.rootNode.childNodes(passingTest: { (node: SCNNode, _unsafeValue) in node.name == "ball" })
        print(balls.count)
        print(balls.filter({ball in doesContain(inner: ball, outer: hatNode)}).count)
        return balls.filter({ball in doesContain(inner: ball, outer: hatNode)});
    }

    private func toggleHiddenPropertyOfBalls(_ balls: Array<SCNNode>) {
        balls.forEach({ ball in ball.isHidden = !ball.isHidden})
    }

    @IBAction func didTapButton(_ sender: UIButton) {
        throwBall()
    }

    private func throwBall() {
        let ball = createBallNode()
        // get camera position as the ball's position
        let (_, position) = getUserVector()
        ball.position = position
        // this is an arbitrary force that we rotate based on direction of the camera
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
        if hat == nil {
            let magicScene = SCNScene(named: "art.scnassets/magicHat.scn")
            let magicHat = magicScene?.rootNode.childNode(withName: "hat", recursively: false)
            let floor = magicScene?.rootNode.childNode(withName: "floor", recursively: false)
            // when a new plane node is added we add the magicHat node to it
            if let magicHatNode = magicHat, let floorNode = floor {
                magicHatNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
                floorNode.position = SCNVector3Make(planeAnchor.center.x, -0.25, planeAnchor.center.z)
                node.addChildNode(magicHatNode)
                node.addChildNode(floorNode)
                hat = magicHatNode
            }
        }
    }
}
