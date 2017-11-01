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

protocol BarcodeDelegate: class {
	func barcodeRead(barcode: String)
}

class RecordViewController: UIViewController {
	
	weak var delegate: BarcodeDelegate?
	
	var output = AVCaptureMetadataOutput()
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	var captureSession = AVCaptureSession()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupCamera()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if !captureSession.isRunning {
			captureSession.startRunning()
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
		
		captureSession.sessionPreset = AVCaptureSession.Preset.high
		
		guard let device = AVCaptureDevice.default(for: .video),
			let input = try? AVCaptureDeviceInput(device: device) else {
				return
		}
		
		if captureSession.canAddInput(input) {
			captureSession.addInput(input)
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.videoGravity = .resizeAspectFill
		previewLayer.frame = view.bounds
		view.layer.addSublayer(previewLayer)
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if captureSession.canAddOutput(metadataOutput) {
			captureSession.addOutput(metadataOutput)
			
			// metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			// metadataOutput.metadataObjectTypes = [.qr, .ean13]
		} else {
			print("Could not add metadata output")
		}

	}
}
