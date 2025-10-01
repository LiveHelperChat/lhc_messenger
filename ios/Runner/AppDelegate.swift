import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var fcmTokenChannel: FlutterMethodChannel?
  private var pendingFcmToken: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Check if Firebase has already been configured
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }

    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("Notification permission granted: \(granted)")
          if let error = error {
            print("Notification permission error: \(error)")
          }
        }
      )
    } else {
      let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    // Set messaging delegate to receive token
    Messaging.messaging().delegate = self

    // Setup method channel for FCM token communication
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    fcmTokenChannel = FlutterMethodChannel(name: "fcm_token_channel", binaryMessenger: controller.binaryMessenger)

    fcmTokenChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getFCMToken" {
        if let token = self?.pendingFcmToken {
          result(token)
        } else {
          // Try to get the token directly
          Messaging.messaging().token { token, error in
            if let error = error {
              print("Error fetching FCM registration token: \(error)")
              result(FlutterError(code: "TOKEN_ERROR", message: error.localizedDescription, details: nil))
            } else if let token = token {
              print("FCM registration token retrieved: \(token)")
              self?.pendingFcmToken = token
              result(token)
            } else {
              result(FlutterError(code: "NO_TOKEN", message: "No FCM token available", details: nil))
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notification presentation when app is in foreground
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo

    // Print message ID.
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }

    // Allow notification to show when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }

  // Handle user interaction with notifications
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      didReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    // Print message ID.
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }

    completionHandler()
  }

  // Handle registration of remote notifications
  override func application(_ application: UIApplication,
                           didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass device token to auth
    Messaging.messaging().apnsToken = deviceToken

    // Required for the token refresh
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")

    // Store the token for later use
    if let token = fcmToken {
      pendingFcmToken = token

      // Notify Flutter that token is available
      fcmTokenChannel?.invokeMethod("onTokenReceived", arguments: token)
    }

    // Note: This callback is fired at each app startup and whenever a new token is generated.
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    // Only register FlutterDownloaderPlugin for testing - we'll handle downloads differently
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}