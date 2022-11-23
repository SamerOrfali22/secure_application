//
//  CaptureStreamHandler.swift
//  secure_application
//
//  Created by Balázs Kilvády on 05/11/22.
//

import Foundation
import Flutter

class CaptureStreamHandler: NSObject, FlutterStreamHandler{
    private var _sink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _sink = events

        events(UIScreen.main.isCaptured)
        NotificationCenter.default
          .addObserver(self,
                       selector: #selector(_captureDidChange),
                       name: UIScreen.capturedDidChangeNotification,
                       object: nil)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _sink = nil
        NotificationCenter.default
            .removeObserver(self,
                            name: UIScreen.capturedDidChangeNotification,
                            object: nil)
        return nil
    }

    @objc private func _captureDidChange() {
        guard let sink = _sink else { return }

        DispatchQueue.main.async {
            sink(UIScreen.main.isCaptured)
        }
    }
}
