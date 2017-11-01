//
//  Record.swift
//  vimojoRecord
//
//  Created by Jesus Huerta on 31/10/2017.
//  Copyright © 2017 MsHome. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraFramesDelegate {
	// func processCameraFrames(sampleBuffer : CMSampleBufferRef)
}

class RecordViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
	
	@IBOutlet weak var camPreview: UIView!
	
	let cameraButton = UIView()
	
	let captureSession = AVCaptureSession()
	
	let movieOutput = AVCaptureMovieFileOutput()
	
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	var activeInput: AVCaptureDeviceInput!
	
	var outputURL: URL!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if setupSession() {
			setupPreview()
			startSession()
		}
		
		cameraButton.isUserInteractionEnabled = true
		
		let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(RecordViewController.startCapture))
		
		cameraButton.addGestureRecognizer(cameraButtonRecognizer)
		
		cameraButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
		
		cameraButton.backgroundColor = UIColor.red
		
		camPreview.addSubview(cameraButton)
		
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
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
		
		previewLayer.frame = self.view.bounds
		
	}
	
	
	func setupPreview() {
		// Configure previewLayer
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.frame = camPreview.bounds
		previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
		camPreview.layer.addSublayer(previewLayer)
	}
	
	//MARK:- Setup Camera
	
	func setupSession() -> Bool {
		
		captureSession.sessionPreset = AVCaptureSession.Preset.high
		
		// Setup Camera
		do {
			guard let camera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .back),
				let input = try? AVCaptureDeviceInput(device: camera) else {
					return false
			}
			
			if captureSession.canAddInput(input) {
				captureSession.addInput(input)
				activeInput = input
			}
		} catch {
			print("Error setting device video input: \(error)")
			return false
		}
		
		// Setup Microphone
		do {
			guard let microphone = AVCaptureDevice.default(for: AVMediaType.audio),
				let micInput = try? AVCaptureDeviceInput(device: microphone) else {
					return false
			}
			
			if captureSession.canAddInput(micInput) {
				captureSession.addInput(micInput)
			}
		} catch {
			print("Error setting device audio input: \(error)")
			return false
		}
		
		
		// Movie output
		if captureSession.canAddOutput(movieOutput) {
			captureSession.addOutput(movieOutput)
		}
		
		return true
	}
	
	func setupCaptureMode(_ mode: Int) {
		// Video Mode
		
	}
	
	//MARK:- Camera Session
	func startSession() {
		
		
		if !captureSession.isRunning {
			videoQueue().async {
				self.captureSession.startRunning()
			}
		}
	}
	
	func stopSession() {
		if captureSession.isRunning {
			videoQueue().async {
				self.captureSession.stopRunning()
			}
		}
	}
	
	func videoQueue() -> DispatchQueue {
		return DispatchQueue.main
	}
	
	
	
	func currentVideoOrientation() -> AVCaptureVideoOrientation {
		var orientation: AVCaptureVideoOrientation
		
		switch UIDevice.current.orientation {
		case .portrait:
			orientation = AVCaptureVideoOrientation.portrait
		case .landscapeRight:
			orientation = AVCaptureVideoOrientation.landscapeLeft
		case .portraitUpsideDown:
			orientation = AVCaptureVideoOrientation.portraitUpsideDown
		default:
			orientation = AVCaptureVideoOrientation.landscapeRight
		}
		
		return orientation
	}
	
	@objc func startCapture() {
		
		startRecording()
		
	}
	
	//EDIT 1: I FORGOT THIS AT FIRST
	
	func tempURL() -> URL? {
		let directory = NSTemporaryDirectory() as NSString
		
		if directory != "" {
			let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
			return URL(fileURLWithPath: path)
		}
		
		return nil
	}
	
	
	func startRecording() {
		
		if movieOutput.isRecording == false {
			
			let connection = movieOutput.connection(with: AVMediaType.video)
			if (connection?.isVideoOrientationSupported)! {
				connection?.videoOrientation = currentVideoOrientation()
			}
			
			if (connection?.isVideoStabilizationSupported)! {
				connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
			}
			
			let device = activeInput.device
			if (device.isSmoothAutoFocusSupported) {
				do {
					try device.lockForConfiguration()
					device.isSmoothAutoFocusEnabled = false
					device.unlockForConfiguration()
				} catch {
					print("Error setting configuration: \(error)")
				}
				
			}
			
			//EDIT2: And I forgot this
			outputURL = tempURL()
			movieOutput.startRecording(to: outputURL, recordingDelegate: self)
			
		}
		else {
			stopRecording()
		}
		
	}
	
	func stopRecording() {
		
		if movieOutput.isRecording == true {
			movieOutput.stopRecording()
		}
	}
	
	func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
		
	}
	
	func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
		if (error != nil) {
			print("Error recording movie: \(error!.localizedDescription)")
		} else {
			
			_ = outputURL as URL
			
		}
		outputURL = nil
	}
}
