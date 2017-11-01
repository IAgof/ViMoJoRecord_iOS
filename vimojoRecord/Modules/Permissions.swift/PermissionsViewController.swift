//
//  Permissions.swift
//  vimojoRecord
//
//  Created by Jesus Huerta on 31/10/2017.
//  Copyright © 2017 MsHome. All rights reserved.
//

import UIKit
import AVFoundation

class PermissionsViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		askMicIfNeeded()
		askCameraIfNeeded()
		navigateToRecord()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func navigateToRecord() {
		// let storyboard = UIStoryboard(name: "Record", bundle: Bundle.main)
		// storyboard.instantiateViewController(withIdentifier: "RecordViewController") as! RecordViewController
	}
	
	let avSession = AVAudioSession.sharedInstance()
	public func askMicIfNeeded() {
		switch (avSession.recordPermission()) {
		case AVAudioSessionRecordPermission.denied, AVAudioSessionRecordPermission.undetermined:
			avSession.requestRecordPermission({
				granted in
				if !granted {
					self.askMicIfNeeded()
				}
			})
			
			break
		default:
			break
		}
	}
	
	public func askCameraIfNeeded() {
		let authorizationState = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		switch authorizationState {
		case .notDetermined,
		     .restricted,
		     .denied:
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (didAllow) in
				if !didAllow {
					self.askCameraIfNeeded()
				}
			})
		default:
			break
		}
	}
}
