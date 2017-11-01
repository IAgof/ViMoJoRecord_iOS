//
//  Record.swift
//  vimojoRecord
//
//  Created by Jesus Huerta on 31/10/2017.
//  Copyright © 2017 MsHome. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
	
	var output = AVCaptureMetadataOutput()
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	var captureSession = AVCaptureSession()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// TO-DO: The app crashes if the user doesn't allow to access the camera & mic
		CameraPermissions().askCameraIfNeeded()
		MicrophonePermissions().askMicIfNeeded()
		setupCamera()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		// After permissions are granted
		if !captureSession.isRunning {
			let serialQueue = DispatchQueue(label: "vimojo.capture")
			serialQueue.async {
				self.captureSession.startRunning()
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if captureSession.isRunning {
			captureSession.stopRunning()
		}
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
	
	private func setupCamera() {
		getQuality(quality: "high")
		captureSession.beginConfiguration()
		setDataInputs()
		setDataOutputs()
		captureSession.commitConfiguration()
		previewCapture()
	}
	
	private func getQuality(quality: String) {
		switch quality {
		case "low":
			captureSession.sessionPreset = AVCaptureSession.Preset.low
			break
		case "medium":
			captureSession.sessionPreset = AVCaptureSession.Preset.medium
			break
		case "high":
			captureSession.sessionPreset = AVCaptureSession.Preset.high
			break
		default:
			captureSession.sessionPreset = AVCaptureSession.Preset.high
			break
		}
	}
	
	func setDataInputs() {
		/* For Xcode 9 beta 5:
		let deviceTypes = [
			AVCaptureDevice.DeviceType.builtInTelephotoCamera,
			AVCaptureDevice.DeviceType.builtInDualCamera,
			AVCaptureDevice.DeviceType.builtInWideAngleCamera
		]
		let mediaType = AVMediaType.video
		let position = AVCaptureDevice.Position.back
		if let input = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
		                                                                 mediaType: mediaType,
		                                                                 position: position).devices.first?.localizedName {}*/

		guard let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .back),
			let input = try? AVCaptureDeviceInput(device: device) else {
				return
		}
		
		if captureSession.canAddInput(input) {
			captureSession.addInput(input)
		}
	}
	
	func setDataOutputs() {
		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.DevStarlight.vimojoRecordQueue"))
		
		videoOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
		
		// Posibiltity to add metadata to the video (Blockchain? ÔwÔ)
		/* let metadataOutput = AVCaptureMetadataOutput()*/
		
		if captureSession.canAddOutput(videoOutput) {
			captureSession.addOutput(videoOutput)
		}
	}
	
	func previewCapture() {
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.videoGravity = .resizeAspectFill
		previewLayer.frame = view.bounds
		view.layer.addSublayer(previewLayer)
	}
	
	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
		
	}
}
