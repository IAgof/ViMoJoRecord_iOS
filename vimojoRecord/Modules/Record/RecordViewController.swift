//
//  Record.swift
//  vimojoRecord
//
//  Created by Jesus Huerta on 31/10/2017.
//  Copyright © 2017 MsHome. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

struct RecorderParameters {
    let movieOutput: AVCaptureMovieFileOutput
    let activeOutput: AVCaptureDeviceInput
}
//protocol Presenter {
//    var interactor: Interactor { get set }
////    func sendRecorderParameters(recorderParameters: RecorderParameters)
//}
////Implementation on presenter, not in extension :)
//extension Presenter {
//    func sendRecorderParameters(recorderParameters: RecorderParameters) {
//        interactor.recorderParameters = recorderParameters
//    }
//}
//protocol Interactor {
//    var recorderParameters: RecorderParameters { get set }
//}
class RecordViewController: UIViewController {
    var cameraView: VideonaRecordView!
    var recorder: RecorderProtocol?
    var button: RecordButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView = VideonaRecordView(frame: self.view.frame)
        recorder = VideonaRecorder(with: self,
                                   parameters: RecorderParameters(movieOutput: cameraView.movieOutput,
                                                                  activeOutput: cameraView.activeInput))
        button = RecordButton(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        button.recordState = .stopped
        button.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        self.view.addSubview(cameraView)
        self.view.addSubview(button)
    }
    @objc func startRecording() {
        switch button.recordState {
        case .stopped: recorder?.stopRecording()
        case .recording: recorder?.startRecording()
        }
    }
}

extension RecordViewController: RecorderDelegate {
    func recordStopped(with response: VideoResponse) {
        switch response {
        case .error(let error): fatalError("Record stopped with error \n \(error)")
        case .success(let url):
            print("Record stopped with URK \n \(url)")
            let playerViewController = AVPlayerViewController()
            let player = AVPlayer(url: url)
            playerViewController.player = player
            self.present(playerViewController, animated: true, completion: nil)
        }
    }
}





