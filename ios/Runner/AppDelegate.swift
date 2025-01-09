import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Check if Firebase has already been configured. This is crucial to prevent
    // multiple FirebaseApp instances, which can lead to crashes or unexpected behavior.
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}