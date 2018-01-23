//
//  VideonaRecorder.swift
//  vimojoRecord
//
//  Created by Alejandro Arjonilla Garcia on 1/11/17.
//  Copyright © 2017 MsHome. All rights reserved.
//

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
    var outputURL: URL
    var movieOutput: AVCaptureMovieFileOutput
    var activeInput: AVCaptureDeviceInput
    var delegate: RecorderDelegate
    
    var videoWriterInput: AVAssetWriterInput?
    var videoWriter: AVAssetWriter?
    var dataOutput: AVCaptureVideoDataOutput?
    var timeOffset: CMTime = kCMTimeZero
    var lastAudioPts: CMTime? = kCMTimeZero

    lazy var lastSampleTime: CMTime = {
        let lastSampleTime = kCMTimeZero
        return lastSampleTime
    }()
    lazy var isRecordingVideo: Bool = {
        let isRecordingVideo = false
        return isRecordingVideo
    }()
    lazy var frameCount: Int64 = {
        return 0
    }()
    
    init(with delegate: RecorderDelegate,
         parameters: RecorderParameters) {
        self.delegate = delegate
        self.movieOutput = parameters.movieOutput
        self.activeInput = parameters.activeInput
        self.dataOutput = parameters.dataOutput
        self.outputURL = parameters.outputURL
        super.init()
        let videoStreamingQueue = DispatchQueue(label: "com.somedomain.videoStreamingQueue")
        dataOutput?.setSampleBufferDelegate(self, queue: videoStreamingQueue)
    }
    
    private func setupWritter() {
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1080,
            AVVideoHeightKey: 720
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video,
                                                  outputSettings: videoSettings)
        self.videoWriterInput = videoWriterInput
        videoWriterInput.expectsMediaDataInRealTime = true
        do {
            self.videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
        } catch let error as NSError {
            print("ERROR:::::>>>>>>>>>>>>>Cannot init videoWriter, error:\(error.localizedDescription)")
        }
        guard let videoWriter = self.videoWriter else { fatalError("video writter is nil") }
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        } else {
            fatalError("ERROR:::Cannot add videoWriterInput into videoWriter")
        }
        if videoWriter.status != AVAssetWriterStatus.writing {
            let hasStartedWriting = videoWriter.startWriting()
            if hasStartedWriting {
                // If we want to calculate presentationTime based on the frames by ourself, here we should use kCMTimeZero.
                // self.videoWriter!.startSessionAtSourceTime(self.lastSampleTime)
                videoWriter.startSession(atSourceTime: kCMTimeZero)
                self.isRecordingVideo = true
            } else {
                print("WARN:::Fail to start writing on videoWriter")
            }
            
        } else {
            print("WARN:::The videoWriter.status is writting now, so cannot start writing action on videoWriter")
        }
    }
    
    func finishRecord() {
        self.isRecordingVideo = false
        
        self.videoWriterInput!.markAsFinished()
        self.videoWriter!.finishWriting {
            if self.videoWriter!.status == AVAssetWriterStatus.completed {
                self.delegate.recordStopped(with: .success(self.outputURL))
            } else {
                
                print("WARN:::The videoWriter status is not completed, stauts: \(self.videoWriter!.status)")
            }
        }
    }
    func startRecording() {
        self.timeOffset = CMTimeMake(0, 0)
        
        if isRecordingVideo == false {
            let connection = dataOutput?.connection(with: .video)
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
            setupWritter()
            //            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
        else {
            stopRecording()
        }
    }
    func stopRecording() {
        finishRecord()
        //        if movieOutput.isRecording == true {
        //            movieOutput.stopRecording()
        //        }
    }
}

extension VideonaRecorder: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    func ajustTimeStamp(sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);
        
        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("captureOutput")
        if self.isRecordingVideo
        {
            var buffer = sampleBuffer
            var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            let isAudioPtsValid = self.lastAudioPts!.flags.intersection(CMTimeFlags.valid)
            if isAudioPtsValid.rawValue != 0 {
                let isTimeOffsetPtsValid = self.timeOffset.flags.intersection(CMTimeFlags.valid)
                if isTimeOffsetPtsValid.rawValue != 0 {
                    pts = CMTimeSubtract(pts, self.timeOffset);
                }
                let offset = CMTimeSubtract(pts, self.lastAudioPts!);
                
                if (self.timeOffset.value == 0) { self.timeOffset = offset }
                else { self.timeOffset = CMTimeAdd(self.timeOffset, offset) }
            }
            self.lastAudioPts!.flags = CMTimeFlags()
            
            if self.timeOffset.value > 0 {
                buffer = self.ajustTimeStamp(sample: sampleBuffer,
                                             offset: self.timeOffset)
            }
            videoWriterInput?.append(buffer)
        }
    }
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

