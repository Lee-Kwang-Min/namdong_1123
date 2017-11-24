//
//  AppDelegate.swift
//  Namdong
//
//  Created by Chris Song on 2017. 7. 31..
//  Copyright © 2017년 Chris Song. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import RNNotificationView

let keyCookie = "Cookie"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let gcmMessageIDKey = "gcm.message_id"
    let apsKey = "aps"
    let dataKey = "data"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        configureBidu(launchOptions)
        
        Messaging.messaging().delegate = self
        
        // Regist Device token to fcm
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func configureBidu(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        
        BPush.registerChannel(launchOptions, apiKey: ApplicationData.shared.getBiduKey(), pushMode: .development, withFirstAction: "Open", withSecondAction: "Reply", withCategory: "test", useBehaviorTextInput: true, isDebug: true)
        let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification]
        if let result = userInfo {
            BPush.handleNotification(result as! [AnyHashable : Any])
        }
    }
    
    func showNotification(_ object: Dictionary<AnyHashable, Any>){
        guard
            let aps     = object["aps"] as? NSDictionary,
            let alert   = aps["alert"] as? NSDictionary,
            let title   = alert["title"] as? String,
            let message = alert["body"] as? String
        else {
            return;
        }
        let urlLink = object["gcm.notification.link_url"] as? String
        let iconImage = UIImage.init(named: "AppIcon60x60")
        
        RNNotificationView.show(withImage: iconImage, title: title, message: message) {
            if urlLink != nil {
                RNNotificationView.hide()
                // move to url
                ApplicationData.shared.reservedUrl = urlLink?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UrlNoti"), object: urlLink)
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // FCM
        if UIApplication.shared.applicationState == .inactive {
            let urlLink = userInfo["gcm.notification.link_url"] as? String
            ApplicationData.shared.reservedUrl = urlLink?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let menuid = userInfo["gcm.notification.menuid"] as? String {
                ApplicationData.shared.menuid = menuid
            }
            if let paramdata = userInfo["gcm.notification.paramdata"] as? String {
                ApplicationData.shared.paramdata = paramdata
            }
        }else{
            self.showNotification(userInfo)
        }
        
        // Bidu
        BPush.handleNotification(userInfo)
        if application.applicationState == .inactive {
            
        }else {
            self.showNotification(userInfo)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Under iOS 10: Using
        if UIApplication.shared.applicationState == .inactive {
            let urlLink = userInfo["gcm.notification.link_url"] as? String
            ApplicationData.shared.reservedUrl = urlLink?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if let menuid = userInfo["gcm.notification.menuid"] as? String {
                ApplicationData.shared.menuid = menuid
            }
            if let paramdata = userInfo["gcm.notification.paramdata"] as? String {
                ApplicationData.shared.paramdata = paramdata
            }
        }else{
            self.showNotification(userInfo)
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // set Bidu
        BPush.registerDeviceToken(deviceToken)
        BPush.bindChannel { (result, error) in
            guard error == nil else { return }
            
            if let data = result as? NSDictionary {
                BPush.setTag("namsung", withCompleteHandler: { (result, error) in
                    let channelID = data["channel_id"]
                    ApplicationData.shared.baiduToken = channelID as! String
                    UserDefaults.standard.set(channelID, forKey: "baiduToken")
                    UserDefaults.standard.synchronize()
                })
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // save cookie to keychain
        ApplicationData.shared.saveCookieData()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // load cookie from keychain
        let cookiesData = UserDefaults.standard.object(forKey: keyCookie)
        if cookiesData != nil {
            let cookies = NSKeyedUnarchiver.unarchiveObject(with: cookiesData as! Data)
            for cookie in cookies as! [HTTPCookie] {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}


// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        self.showNotification(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let urlLink = userInfo["gcm.notification.link_url"] as? String
        ApplicationData.shared.reservedUrl = urlLink?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let menuid = userInfo["gcm.notification.menuid"] as? String {
            ApplicationData.shared.menuid = menuid
        }
        if let paramdata = userInfo["gcm.notification.paramdata"] as? String {
            ApplicationData.shared.paramdata = paramdata
        }
        
        completionHandler()
    }
}
// [END ios_10_message_handling]


extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")

        ApplicationData.shared.fcmToken = fcmToken;
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TokenChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TokenChanged2"), object: nil)
    }
    // [END refresh_token]
    
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

