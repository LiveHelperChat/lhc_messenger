import UIKit
import Flutter
import FirebaseCore
import flutter_downloader

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
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}

/* import UIKit

import Flutter
import FirebaseCore
import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
  GeneratedPluginRegistrant.register(with: self)
  FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
  if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  }
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    @available(iOS 10.0, *)
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound,.badge])
    }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
} */

