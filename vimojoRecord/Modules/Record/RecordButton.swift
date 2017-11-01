//
//  RecordButton.swift
//  vimojoRecord
//
//  Created by Alejandro Arjonilla Garcia on 1/11/17.
//  Copyright © 2017 MsHome. All rights reserved.
//

import Foundation
import UIKit

enum RecordButtonState {
    case recording
    case stopped
    
    var title: String {
        switch self {
        case .recording: return "Stop Record"
        case .stopped: return "Start record"
        }
    }
    mutating func toggle() {
        self = (self == .recording) ? .stopped:.recording
    }
}
class RecordButton: UIButton {
    var recordState: RecordButtonState = .stopped {
        didSet{
            self.setTitle(recordState.title, for: .normal)
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(toggle), for: .touchUpInside)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    @objc private func toggle() {
        recordState.toggle()
    }
}
