//
//  CameraPermissions.swift
//  vimojoRecord
//
//  Created by Jesus Huerta on 01/11/2017.
//  Copyright © 2017 MsHome. All rights reserved.
//

import Foundation
import AVFoundation

class CameraPermissions {
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
