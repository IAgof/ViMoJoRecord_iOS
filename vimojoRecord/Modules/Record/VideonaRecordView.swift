//
//  VideonaRecordView.swift
//  vimojoRecord
//
//  Created by Alejandro Arjonilla Garcia on 1/11/17.
//  Copyright © 2017 MsHome. All rights reserved.
//

import UIKit
import AVFoundation

class VideonaRecordView: UIView {
    let cameraButton = UIView()
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    var outputURL: URL!
    var videoQueue: DispatchQueue { return DispatchQueue.main }
    var movieOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    var isCameraConfigured: Bool = false
    
    var tempURL: URL? {
        let directory = NSTemporaryDirectory() as NSString
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    var captureSessionPreset: AVCaptureSession.Preset = AVCaptureSession.Preset.hd1920x1080 {
        didSet{
            captureSession.beginConfiguration()
            if captureSession.canSetSessionPreset(captureSessionPreset)
            { captureSession.sessionPreset = captureSessionPreset }
            captureSession.commitConfiguration()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCamera()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureCamera()
    }
    private func configureCamera() {
        if !isCameraConfigured {
            setupRecorder()
            isCameraConfigured = true
        }
    }
    func setupRecorder() {
        setupSession(completion: { (isEnabled) in
            if isEnabled {
                setupPreview()
                startSession()
            }
        })
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let connection =  self.previewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                }
            }
        }
    }
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        previewLayer.frame = self.bounds
    }
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = self.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.layer.addSublayer(previewLayer)
    }
    //MARK:- Setup Camera
    func setupSession(completion: (Bool) -> Void) {
        var sessionIsEnabled = false
        sessionIsEnabled = setupCamera() && setupMic()
        captureSessionPreset = .hd1920x1080
        completion(sessionIsEnabled)
    }
    private func setupCamera() -> Bool {
        guard let camera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera)
            else { return false }
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            activeInput = input
        }
        return true
    }
    private func setupMic() -> Bool {
        guard let microphone = AVCaptureDevice.default(for: AVMediaType.audio),
            let micInput = try? AVCaptureDeviceInput(device: microphone) else { return false }
        if captureSession.canAddInput(micInput) {
            captureSession.addInput(micInput)
        }
        return true
    }
    //MARK:- Camera Session
    func startSession() {
        if !captureSession.isRunning {
            videoQueue.async {
                self.captureSession.startRunning()
            }
        }
    }
    func stopSession() {
        if captureSession.isRunning {
            videoQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
}
