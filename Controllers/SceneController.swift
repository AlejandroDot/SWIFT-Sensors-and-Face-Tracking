//  Core
    import UIKit
    //  Libraries
        import CoreMotion
        import SceneKit
    //  Extensions
        extension CMDeviceMotion {
            func gaze(atOrientation orientation: UIInterfaceOrientation) -> SCNVector4 {
                let attitude = self.attitude.quaternion
                let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
                let final: SCNVector4
                switch orientation {
                case .landscapeRight:
                    let cq = GLKQuaternionMakeWithAngleAndAxis(Float(Double.pi / 2), 0, 1, 0)
                    let q = GLKQuaternionMultiply(cq, aq)
                    final = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)
                case .landscapeLeft:
                    let cq = GLKQuaternionMakeWithAngleAndAxis(Float(-Double.pi / 2), 0, 1, 0)
                    let q = GLKQuaternionMultiply(cq, aq)
                    final = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)
                case .portraitUpsideDown:
                    let cq = GLKQuaternionMakeWithAngleAndAxis(Float(Double.pi / 2), 1, 0, 0)
                    let q = GLKQuaternionMultiply(cq, aq)
                    final = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)
                case .unknown:
                    fallthrough
                case .portrait:
                    let cq = GLKQuaternionMakeWithAngleAndAxis(Float(-Double.pi / 2), 1, 0, 0)
                    let q = GLKQuaternionMultiply(cq, aq)
                    final = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w) }
                return final } }
        extension Double {
            func truncate(places: Int)-> Double {
            return Double(floor(pow(10.0, Double(places)) * self) / pow(10.0, Double(places))) }
        }
    //  Flags
        var cameraPanning = false
    //  Variables
        let sceneController = SceneController()
//  Application
    class SceneController: UIViewController, SCNSceneRendererDelegate {
    //  Declare Variables
        let motionManager = CMMotionManager()
        var descriptionText = String("What I can do?")
    //  Initialize Scene
        let scene = SCNScene()
        let sceneNode = SCNNode()
        //  Camera
            let cameraNode = SCNNode()
        //  Backgrounds
            var backgroundNode = SCNNode()
            var activeBackgroundMap = UIImage()
                let backgroundMap = UIImage(contentsOfFile: Bundle.main.path(forResource: "BackgroundMap", ofType: "jpg")!)
                let SGBackgroundMap = UIImage(contentsOfFile: Bundle.main.path(forResource: "SGBackgroundMap", ofType: "jpg")!)
                let HKBackgroundMap = UIImage(contentsOfFile: Bundle.main.path(forResource: "HKBackgroundMap", ofType: "jpg")!)
        //  Foregrounds
            var foregroundNode = SCNNode()
            var activeForegroundMap = UIImage()
                let foregroundMap = UIImage(contentsOfFile: Bundle.main.path(forResource: "ForegroundMap", ofType: "png")!)
                let foregroundNightMap = UIImage(contentsOfFile: Bundle.main.path(forResource: "ForegroundNightMap", ofType: "png")!)
    //  Initialize UI
        @IBOutlet weak var sceneLabel: UILabel!
        @IBOutlet weak var sceneView: SCNView!
    //  Start Application
        override func viewDidLoad() {
        super.viewDidLoad()
        //  Initialize Scene
            sceneView.scene = scene
            sceneView.allowsCameraControl = false
            //  Setup Interpolation
                sceneView.preferredFramesPerSecond = 21
                motionManager.deviceMotionUpdateInterval = 1 / 21
            //  Setup Camera
                cameraNode.camera = SCNCamera()
                //  Define Orbit
                    sceneNode.position = SCNVector3Make(0, 0, 5.0)
                    scene.rootNode.addChildNode(sceneNode)
                //  Define Position
                    cameraNode.position = SCNVector3Make(0, 0, -5.0)
                    sceneNode.addChildNode(cameraNode)
                //  Define Rotation
                    motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { data, error in guard let data = data else { return }
                        if (cameraPanning == true) { self.cameraNode.eulerAngles = SCNVector3Make(0, 0, 0) }
                        else { self.cameraNode.orientation = data.gaze(atOrientation: UIInterfaceOrientation.portrait) }
                //  Define Deadpoint
                    if (data.gravity.z < -0.75 && self.descriptionText == "What I can do?") {
                        self.sceneView.isHidden = true
                        self.descriptionText = "What I can do?" }
                        else if (data.gravity.z > -0.75 && self.descriptionText == "What I can do?") {
                            self.sceneView.isHidden = false
                            self.descriptionText = String() }
                    else if (data.gravity.z < -0.75 && self.descriptionText != "This is what I can do.") {
                        self.sceneView.isHidden = true
                        self.descriptionText = "This is what I can do." }
                        else if (data.gravity.z > -0.75 && self.descriptionText == "This is what I can do.") {
                            self.sceneView.isHidden = false
                            self.descriptionText = String() }
            //  Setup Background
                if (data.gravity.z > 0.75 && self.descriptionText == String()) {
                //  Define Scene
                    if (self.activeBackgroundMap == self.HKBackgroundMap) {
                        self.activeBackgroundMap = self.backgroundMap!
                        self.descriptionText = "Worldwide" }
                    //  Load Singapore
                        else if (self.activeBackgroundMap == self.backgroundMap) {
                            self.activeBackgroundMap = self.SGBackgroundMap!
                            self.descriptionText = "Singapore" }
                    //  Load HongKong
                        else if (self.activeBackgroundMap == self.SGBackgroundMap) {
                            self.activeBackgroundMap = self.HKBackgroundMap!
                            self.descriptionText = "Hong Kong" } }
                    self.backgroundNode.geometry?.firstMaterial!.diffuse.contents = self.activeBackgroundMap })
                //  Define Geometry
                    let background = SCNSphere(radius: 20)
                    //  Load Texture
                        activeBackgroundMap = backgroundMap!
                            background.firstMaterial!.diffuse.contents = activeBackgroundMap
                            background.firstMaterial!.isDoubleSided = true
                    //  Append Node
                        backgroundNode = SCNNode(geometry: background)
                            backgroundNode.position = SCNVector3Make(0, 0, 0)
                            backgroundNode.eulerAngles.y = Float(Double.pi)
                            scene.rootNode.addChildNode(backgroundNode)
            //  Setup Foreground
                let foreground = SCNSphere(radius: 5)
                //  Load Texture
                    activeForegroundMap = foregroundMap!
                        foreground.firstMaterial!.diffuse.contents = activeForegroundMap
                        foreground.firstMaterial!.isDoubleSided = true
                //  Append Node
                    foregroundNode = SCNNode(geometry: foreground)
                        foregroundNode.position = SCNVector3Make(0, 0, 0)
                        foregroundNode.eulerAngles.y = Float(Double.pi)
                        scene.rootNode.addChildNode(foregroundNode)
        //  Update Scene
            sceneView.delegate = self; sceneView.isPlaying = true }
            func renderer(_ renderer:SCNSceneRenderer, updateAtTime time:TimeInterval) {
            //  Handle Descriptions
                DispatchQueue.main.async {
                //  Show Transition
                    if (self.descriptionText != "What I can do?" && self.descriptionText != "This is what I can do.") {
                    //  Show Layer
                        if (self.descriptionText != String() && self.sceneView.isHidden == false) {
                        self.sceneView.isHidden = true
                    //  Hide Layer
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
                            self.descriptionText = String()
                            self.sceneView.isHidden = false }) } }
                //  Update Orientation
                    if (UIDevice.current.orientation.isPortrait == true) { self.sceneLabel.transform = CGAffineTransform(rotationAngle: 0) }
                    else if (UIDevice.current.orientation.isLandscape == true) { self.sceneLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2) }
                //  Update Text
                    self.sceneLabel.text = self.descriptionText }
            //  Handle Lighting
                DispatchQueue.main.async {
                //  Show Daylight
                    if (sceneLuxVariation > 10.0 && self.activeForegroundMap != self.foregroundMap) {
                        self.activeForegroundMap = self.foregroundMap!
                        self.foregroundNode.geometry?.firstMaterial!.diffuse.contents = self.activeForegroundMap }
                //  Show Nightlight
                    else if (sceneLuxVariation < -10.0 && self.activeForegroundMap != self.foregroundNightMap) {
                        self.activeForegroundMap = self.foregroundNightMap!
                        self.foregroundNode.geometry?.firstMaterial!.diffuse.contents = self.activeForegroundMap } }
            //  Handle Tracking
                DispatchQueue.main.async {
                if (cameraPanning == true) {
                //  Update Orbit
                    if (targetPosition != CGRect.zero) {
                    //  Handle Gap
                        if ((self.sceneNode.eulerAngles.x == 0 || self.sceneNode.eulerAngles.y == 0) && self.sceneView.isHidden == false) {
                        //  Show Transition
                            self.sceneView.isHidden = true
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
                                self.descriptionText = String()
                                self.sceneView.isHidden = false })
                        //  Update Text
                            self.descriptionText = "Hello!"
                            self.sceneLabel.text = self.descriptionText }
                    //  Update Axis
                        else { self.sceneNode.eulerAngles = SCNVector3Make(
                            Float(targetPosition.midY - 0.5),
                            Float((targetPosition.midX - 0.5) * -1),
                            Float(0)) } }
                //  Reset Orbit
                    else if (targetPosition == CGRect.zero) {
                    //  Handle Gap
                        if ((self.sceneNode.eulerAngles.x != 0 || self.sceneNode.eulerAngles.y != 0) && self.sceneView.isHidden == false) {
                        //  Show Transition
                            self.sceneView.isHidden = true
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
                                self.descriptionText = String()
                                self.sceneView.isHidden = false })
                        //  Update Text
                            self.descriptionText = "Goodbye!"
                            self.sceneLabel.text = self.descriptionText }
                    //  Update Axis
                        else { self.sceneNode.eulerAngles = SCNVector3Make(0, 0, 0) } } } } }
        //  Toggle Tracking
            override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
            if (motion == UIEventSubtype.motionShake) {
            //  Lock Scene
                if (self.descriptionText != "What I can do?" && self.descriptionText != "This is what I can do.") {
            //  Enable Tracking
                if (cameraPanning == false) { self.descriptionText = "Face Tracking"
                cameraPanning = true }
            //  Disable Tracking
                else { self.descriptionText = "360 Navigation"
                cameraPanning = false} } } } }
