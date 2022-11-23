import Flutter
import UIKit
import AVFAudio
import MediaPlayer

public class SwiftSecureApplicationPlugin: NSObject, FlutterPlugin {
  var secured = false
  var opacity: CGFloat = 0.2
  var backgroundTask: UIBackgroundTaskIdentifier!
  internal let registrar: FlutterPluginRegistrar
  private let _screenProtector = _ScreenProtector()

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
    registrar.addApplicationDelegate(self)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "secure_application", binaryMessenger: registrar.messenger())
    let instance = SwiftSecureApplicationPlugin(registrar: registrar)
    let captureChannel = FlutterEventChannel(name: "capture_channel", binaryMessenger: registrar.messenger())
    let captureStreamHandler = CaptureStreamHandler()
    captureChannel.setStreamHandler(captureStreamHandler)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func applicationWillResignActive(_ application: UIApplication) {
    if secured {
      self.registerBackgroundTask()
      UIApplication.shared.ignoreSnapshotOnNextApplicationLaunch()
      if let window = UIApplication.shared.windows.filter({ (w) -> Bool in
        w.isHidden == false
      }).first {
        if let existingView = window.viewWithTag(99699), let existingBlurrView = window.viewWithTag(99698) {
          window.bringSubviewToFront(existingView)
          window.bringSubviewToFront(existingBlurrView)
          return
        } else {
          let colorView = UIView(frame: window.bounds);
          colorView.tag = 99699
          colorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          colorView.backgroundColor = UIColor(white: 1, alpha: opacity)
          window.addSubview(colorView)
          window.bringSubviewToFront(colorView)

          let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
          let blurEffectView = UIVisualEffectView(effect: blurEffect)
          blurEffectView.frame = window.bounds
          blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

          blurEffectView.tag = 99698

          window.addSubview(blurEffectView)
          window.bringSubviewToFront(blurEffectView)
          window.snapshotView(afterScreenUpdates: true)
          RunLoop.current.run(until: Date(timeIntervalSinceNow:0.5))
        }
      }
      endBackgroundTask()
    }
  }

  func registerBackgroundTask() {
    self.backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.endBackgroundTask()
    }
    assert(self.backgroundTask != UIBackgroundTaskIdentifier.invalid)
  }

  func endBackgroundTask() {
    print("Background task ended.")
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = UIBackgroundTaskIdentifier.invalid
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "secure":
      secured = true;
      if let args = call.arguments as? Dictionary<String, Any>,
         let opacity = args["opacity"] as? NSNumber {
        self.opacity = opacity as! CGFloat
      }
    case "open":
      secured = false;
    case "opacity":
      if let args = call.arguments as? Dictionary<String, Any>,
         let opacity = args["opacity"] as? NSNumber {
        self.opacity = opacity as! CGFloat
      }
    case "unlock":
      if let window = UIApplication.shared.windows.filter({ (w) -> Bool in
        return w.isHidden == false
      }).first, let view = window.viewWithTag(99699), let blurrView = window.viewWithTag(99698) {
        UIView.animate(withDuration: 0.5, animations: {
          view.alpha = 0.0
          blurrView.alpha = 0.0
        }, completion: { finished in
          view.removeFromSuperview()
          blurrView.removeFromSuperview()
        })
      }
    case "locale":
      if let args = call.arguments as? Dictionary<String, Any>,
         let lang = args["languageCode"] as? String {
        _screenProtector.setLocale(lang)
      }
    case "disableCapture":
      if let args = call.arguments as? Dictionary<String, Any>,
         let isDisable = args["isDisable"] as? Bool,
         isDisable {
        _screenProtector.startPreventRecording()
      }
    default:
      break
    }
  }
}

private final class _ScreenProtector {
  private var _warningWindow: UIWindow?
  private var _origVolume: Float = 0
  private var _locale = "ar"

  private var _window: UIWindow? {
    UIApplication.shared.delegate?.window!
  }

  func setLocale(_ languageCode: String) {
    _locale = languageCode
  }

  func startPreventRecording() {
    // _window?.setScreenCaptureProtection()
    _handleNotification()
    NotificationCenter.default
      .addObserver(self,
                   selector: #selector(_didDetectRecording),
                   name: UIScreen.capturedDidChangeNotification,
                   object: nil)
  }

  @objc private func _didDetectRecording() {
    DispatchQueue.main.async { [weak self] in
      self?._handleNotification()
    }
  }

  private func _handleNotification() {
    if UIScreen.main.isCaptured {
      _window?.isHidden = true
      _presentWarningWindow()
      _sound(false)
    } else {
      _window?.isHidden = false
      _destroyWarningWindow()
      _sound(true)
    }
  }

  private func _presentWarningWindow() {
    guard let frame = _window?.bounds else { return }

    // Warning window.
    var warningWindow = UIWindow(frame: frame)

    if #available(iOS 13, *) {
      let windowScene = UIApplication.shared
        .connectedScenes
        .first {
          $0.activationState == .foregroundActive
        }
      if let windowScene = windowScene as? UIWindowScene {
        warningWindow = UIWindow(windowScene: windowScene)
      }
    } else {
      warningWindow = UIWindow(frame: frame)
    }

    // warningWindow.frame = frame
    warningWindow.backgroundColor = .white
    warningWindow.windowLevel = UIWindow.Level.statusBar + 1
    warningWindow.clipsToBounds = true
    warningWindow.isHidden = false

    warningWindow.rootViewController = WarningViewController(languageCode: _locale)

    self._warningWindow = warningWindow

    warningWindow.makeKeyAndVisible()
  }

  private func _destroyWarningWindow() {
    _warningWindow?.removeFromSuperview()
    _warningWindow = nil
  }

  private func _sound(_ isOn: Bool) {
    func setVolume(_ volume: Float) {
      let subviews = MPVolumeView().subviews
      guard let volumeSlider = subviews.first(where: { NSStringFromClass($0.classForCoder) == "MPVolumeSlider" }) as? UISlider else { return }
      volumeSlider.setValue(0, animated: false)
    }

    // Get the singleton instance.
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Set the audio session category, mode, and options.
      try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
      try audioSession.setActive(true)

      if isOn {
        // Set the audio session category, mode, and options.
        try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
        try audioSession.setActive(true)

        // Save the original volume level, then turn up the system volume
        _origVolume = audioSession.outputVolume

        setVolume(0)
      } else {
        // Reset system audio?
        try audioSession.setActive(false)
        setVolume(_origVolume)
      }
    } catch {
      print("Failed to set audio session category.", error.localizedDescription)
    }
  }
}

// extension UIView {
//   func setScreenCaptureProtection() {
//     let guardTextField = UITextField()
//     guardTextField.backgroundColor = .white
//     guardTextField.translatesAutoresizingMaskIntoConstraints = false
//     guardTextField.isSecureTextEntry = true
//     guardTextField.isUserInteractionEnabled = false
//
//     addSubview(guardTextField)
//     NSLayoutConstraint.activate([
//       guardTextField.topAnchor.constraint(equalTo: topAnchor, constant: 0),
//       guardTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
//       guardTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
//       guardTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
//     ])
//
//     layer.superlayer?.addSublayer(guardTextField.layer)
//     guardTextField.layer.sublayers?.first?.addSublayer(layer)
//   }
// }
