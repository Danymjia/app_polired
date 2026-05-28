import Flutter
import UIKit
import MapboxMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapboxAccessToken = Bundle.main.object(forInfoDictionaryKey: "MapboxAccessToken") as? String ?? ""
    MapboxOptions.accessToken = mapboxAccessToken
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
