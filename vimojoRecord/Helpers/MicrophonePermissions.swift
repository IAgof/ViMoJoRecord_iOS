//
//  MicrophonePermissions.swift
//  vimojoRecord
//
//  Created by Jesus Huerta on 01/11/2017.
//  Copyright © 2017 MsHome. All rights reserved.
//

import Foundation
import AVFoundation

class MicrophonePermissions {
	
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
}
