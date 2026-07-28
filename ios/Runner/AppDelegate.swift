import AVFoundation
import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var feedbackChannel: FlutterMethodChannel?
  private var successPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String,
       !mapsKey.isEmpty,
       !mapsKey.contains("$(") {
      GMSServices.provideAPIKey(mapsKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.testified/device_feedback",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler {
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      switch call.method {
      case "playPrescriptionSuccess":
        self?.playPrescriptionSuccess(result: result)
      case "isRingerModeNormal":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    feedbackChannel = channel
  }

  private func playPrescriptionSuccess(result: FlutterResult) {
    let assetKey = FlutterDartProject.lookupKey(
      forAsset: "assets/audio/prescription_sent.wav"
    )
    guard let assetPath = Bundle.main.path(forResource: assetKey, ofType: nil) else {
      result(
        FlutterError(
          code: "SUCCESS_SOUND_UNAVAILABLE",
          message: "The prescription success sound is missing.",
          details: nil
        )
      )
      return
    }

    do {
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: assetPath))
      player.volume = 0.46
      player.prepareToPlay()
      player.play()
      successPlayer = player
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "SUCCESS_SOUND_UNAVAILABLE",
          message: "The prescription success sound could not be played.",
          details: error.localizedDescription
        )
      )
    }
  }
}
