//  Core
    import UIKit
    //  Libraries
        import AVFoundation
        import SceneKit
        import Vision
    //  Flags
        let debugMode = false
        let frontCamera = true
        let targetTracking = true
    //  Variables
        let trackingController = TrackingController()
        var targetPosition = CGRect.zero
        var sceneLux = Double(0)
        var sceneLuxVariation = Double(0)
//  Application
    class TrackingController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    //  Setup AV Foundation Framework
        private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        private lazy var captureSession: AVCaptureSession = {
            let session = AVCaptureSession()
            //  Define Method
                session.sessionPreset = AVCaptureSession.Preset.photo
            //  Define Camera
                if (frontCamera == true) { guard
                    let activeCamera = AVCaptureDevice.default(
                        AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                        for: AVMediaType.video,
                        position: AVCaptureDevice.Position.front),
                    let input = try? AVCaptureDeviceInput(device: activeCamera) else { return session }
                    session.addInput(input) }
                else { guard
                    let activeCamera = AVCaptureDevice.default(
                        AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                        for: AVMediaType.video,
                        position: AVCaptureDevice.Position.back),
                    let input = try? AVCaptureDeviceInput(device: activeCamera) else { return session }
                    session.addInput(input) }
            return session }()
    //  Setup Vision Framework
        let visionSequenceHandler = VNSequenceRequestHandler()
        //  Define Variables
            var faceDetectionStatus = false
            let faceDetectionRequest = VNSequenceRequestHandler()
            var faceDetectionResult = VNDetectedObjectObservation()
        //  Define Method
            let visionMethod = VNDetectFaceRectanglesRequest()
    //  Initialize UI
        @IBOutlet weak var cameraView: UIView!
        @IBOutlet weak var highlightView: UIView! { didSet {
            self.highlightView?.frame = CGRect.zero
            self.highlightView?.backgroundColor = UIColor.clear
            self.highlightView?.layer.borderColor = UIColor.green.cgColor
            self.highlightView?.layer.borderWidth = 2 } }
    //  Start Application
        override func viewDidLoad() {
        super.viewDidLoad()
        //  Create Camera
            if (debugMode == true) {
            self.cameraView?.layer.addSublayer(self.cameraLayer)
            //  Setup Viewport
                self.cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                self.cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill }
            //  Stream Capture
                let videoOutput = AVCaptureVideoDataOutput()
                    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Queue"))
                self.captureSession.addOutput(videoOutput)
        //  Start Capture
            self.captureSession.startRunning() }
            //  Resize Viewport
                override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews()
                if (debugMode == true) { self.cameraLayer.frame = self.cameraView?.bounds ?? CGRect.zero } }
        //  Define Controller
            override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(false)
            //  Show Scene
                if (debugMode == false && sceneController.isViewLoaded == false) {
                performSegue(withIdentifier: "Scene", sender: self) }
            //  Debug Tracking
                else if (debugMode == true && self.cameraView.isHidden == true && self.highlightView.isHidden == true) {
                    self.cameraView.isHidden = false
                    self.highlightView.isHidden = false } }
        //  Process Capture
            func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            //  Capture Frame
                let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
                let ciRawMetadata = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
                //  Rotate Frame
                    let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: ciRawMetadata as! [String : Any]?)
                    var ciImageOriented = CIImage()
                        if (frontCamera == true) { ciImageOriented = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue)) }
                        else { ciImageOriented = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.downMirrored.rawValue)) }
                //  Retrieve Lux
                    let ciMetadata = CFDictionaryCreateMutableCopy(nil, 0, ciRawMetadata) as NSMutableDictionary
                    let ciExifData = ciMetadata.value(forKey: "{Exif}") as? NSMutableDictionary
                    //  Sensor Variables
                        let FNumber: Double = ciExifData?["FNumber"] as! Double
                        let ExposureTime: Double = ciExifData?["ExposureTime"] as! Double
                        let ISOSpeedRatingsArray = ciExifData!["ISOSpeedRatings"] as? NSArray
                        let ISOSpeedRatings: Double = ISOSpeedRatingsArray![0] as! Double
                        let CalibrationConstant: Double = 50
                    //  Absolute Value
                        if (sceneLux == Double(0) && (CalibrationConstant * FNumber * FNumber) / (ExposureTime * ISOSpeedRatings) < 50) {
                        sceneLux = (CalibrationConstant * FNumber * FNumber) / (ExposureTime * ISOSpeedRatings) }
                    //  Relative Value
                        else if (sceneLux != Double(0)) {
                            sceneLuxVariation = ((CalibrationConstant * FNumber * FNumber) / (ExposureTime * ISOSpeedRatings)) - sceneLux
                            sceneLux = (CalibrationConstant * FNumber * FNumber) / (ExposureTime * ISOSpeedRatings) }
            //  Detect Face
                if (targetTracking == false || faceDetectionStatus == false) {
                try? self.faceDetectionRequest.perform([self.visionMethod], on: ciImageOriented)
                //  Validate Swatch
                    if let result = self.visionMethod.results?.first as? VNFaceObservation {
                        faceDetectionStatus = true
                        faceDetectionResult = result }
                //  Discard Swatch
                    else {
                    DispatchQueue.main.async {
                    //  Update Flag
                        self.faceDetectionStatus = false
                    //  Update Target
                        if (debugMode == true) { self.highlightView?.frame = CGRect.zero }
                        targetPosition = CGRect.zero } } }
            //  Update Position
                if (targetTracking == false && faceDetectionStatus == true) {
                DispatchQueue.main.async {
                //  Target Swatch
                    if (self.faceDetectionStatus == true && self.faceDetectionResult.confidence > 0.75) {
                    //  Convert Coordinates
                        if (debugMode == true) {
                            let scale = CGAffineTransform.identity.scaledBy(x: self.cameraLayer.frame.width, y: self.cameraLayer.frame.height)
                            let transform = CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: (self.cameraLayer.frame.width * -1), y: (self.cameraLayer.frame.height * -1))
                    //  Pass Coordinates
                        self.highlightView.frame = self.faceDetectionResult.boundingBox.applying(scale).applying(transform) }
                        targetPosition = self.faceDetectionResult.boundingBox }
                //  Update Swatch
                    else { self.faceDetectionResult = VNDetectedObjectObservation() } } }
            //  Track Position
                else if (targetTracking == true && faceDetectionStatus == true) {
                //  Create Request
                    let request = VNTrackObjectRequest(detectedObjectObservation: faceDetectionResult, completionHandler: self.trackFace)
                    //  Define Accuracy
                        request.trackingLevel = VNRequestTrackingLevel.accurate
                    //  Send Request
                        try? self.visionSequenceHandler.perform([request], on: ciImageOriented) } }
                //  Run Request
                    func trackFace(_ request: VNRequest, error: Error?) {
                    DispatchQueue.main.async {
                    //  Target Swatch
                        guard let result = request.results?.first as? VNDetectedObjectObservation else { return }
                        if (result.confidence > 0.75) {
                        //  Convert Coordinates
                            if (debugMode == true) {
                                let scale = CGAffineTransform.identity.scaledBy(x: self.cameraLayer.frame.width, y: self.cameraLayer.frame.height)
                                let transform = CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: (self.cameraLayer.frame.width * -1), y: (self.cameraLayer.frame.height * -1))
                        //  Pass Coordinates
                            self.highlightView.frame = result.boundingBox.applying(scale).applying(transform) }
                            targetPosition = result.boundingBox
                    //  Update Swatch
                        self.faceDetectionResult = result }
                        else { self.faceDetectionResult = VNDetectedObjectObservation(); self.faceDetectionStatus = false } } } }
