//
//  VideonaRecorder.swift
//  vimojoRecord
//
//  Created by Alejandro Arjonilla Garcia on 1/11/17.
//  Copyright © 2017 MsHome. All rights reserved.
//

import Foundation
import AVFoundation

enum VideoResponse {
    case error(Error)
    case success(URL)
}
protocol RecorderProtocol {
    func startRecording()
    func stopRecording()
}
protocol RecorderDelegate {
    func recordStopped(with response: VideoResponse )
}
class VideonaRecorder: NSObject, RecorderProtocol {
    var outputURL: URL!
    var movieOutput: AVCaptureMovieFileOutput
    var activeInput: AVCaptureDeviceInput
    var delegate: RecorderDelegate
    
    init(with delegate: RecorderDelegate,
         parameters: RecorderParameters) {
        self.delegate = delegate
        self.movieOutput = parameters.movieOutput
        self.activeInput = parameters.activeOutput
    }
    
    var tempURL: URL? {
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
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = activeInput.device.currentVideoOrientation
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
            outputURL = tempURL
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
}

extension VideonaRecorder:  AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    //TODO: make it rain
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("Start capture didStartRecordingToOutputFileAt with fileURL \n\(fileURL)")
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("fileOutput didFinishRecordingTo with fileURL \n\(outputFileURL)")
        let response: VideoResponse!
        if let hasError = error { response = .error(hasError) }
        else { response = .success(outputFileURL) }
        delegate.recordStopped(with: response)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) { }
}


import UIKit
extension AVCaptureDevice {
    var currentVideoOrientation: AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return AVCaptureVideoOrientation.portrait
        case .landscapeRight: return  AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
        default: return AVCaptureVideoOrientation.landscapeRight
        }
    }
}

