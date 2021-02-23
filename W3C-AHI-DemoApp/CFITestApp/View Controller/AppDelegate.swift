//
//  AppDelegate.swift
//  W3CTestApp
//
//  Created by Ujjwal Chafle on 5/30/19.
//  Copyright © 2021 Mastercard. All rights reserved.
//

import UIKit
import CoreData
import MasterCard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var isLaunchedFromPayAction = false
    var hasPaymentRequested = false
    var register = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                        launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PaymentHandler.setup(withEnvironment: Constant.environment)
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "W3CTestApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

extension AppDelegate {
    //MARK: Handler for universal link
    
    /// Tells the delegate that the data for continuing an activity is available.
    ///
    /// - Parameters:
    ///   - application: The shared app object that controls and coordinates your app.
    ///   - userActivity: The activity object containing the data associated with the task the user was performing. Use the data to continue the user's activity in your iOS app.
    ///   - restorationHandler: A block to execute if your app creates objects to perform the task. Calling this block is optional and you can copy this block and call it at a later time. When calling a saved copy of the block, you must call it from the app’s main thread. This block has no return value and takes the following parameter:
    ///restorableObjects
    ///An array of UIResponder objects representing objects you created or fetched in order to perform the operation. The system calls the restoreUserActivityState: method of each object in the array to give it a chance to perform the operation.
    /// - Returns: true to indicate that your app handled the activity or false to let iOS know that your app did not handle the activity
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let url =  userActivity.webpageURL
        print(" url " + (url?.absoluteString)!)
        
        //Handler in framework
        guard let queryItem = PaymentHandler.shared.linkHandler(webURL: url) else { return true }
        //registration and un-registration flow
        let status = PaymentHandler.shared.parseResponseJson(items: queryItem)
        if status.action == MCConstant.ActionType.register.rawValue || status.action == MCConstant.ActionType.unregister.rawValue{
            //Put register and unregister logic here
            NotificationCenter.default.post(
                name: Notification.Name("ReceivedRegisterNotification"),
                object: self,
                userInfo: ["action": status.action,"status": status.responseStatus,"browser":status.browser]
            )
            return true
        }
        //Payment request event
        let paymentList = parsePaymentRequestData(items: queryItem)
        if let paymentList = paymentList {
            let paymentObject = PaymentHandler.shared.getPaymentRequestObject(paymentDict: paymentList)
            launchPaymentEventScreen(requestEvent: paymentObject, requestData: paymentList)
        }
        return true
    }
    
    public func parsePaymentRequestData(items: [URLQueryItem]?) -> [String:Any]? {
        guard let queryItemList = items else {
            return nil
        }
        if queryItemList.filter({$0.name == "requestData"}).first?.name == "requestData" {
            let encodedString = queryItemList.filter({$0.name == "requestData"}).first?.value ?? ""
            let requestDataList = Utility.encodedStringToDictionary(base64encodedString: encodedString)
            return requestDataList
        }
        return nil
    }
    
    /// Prepare the paymentScreen to be launched
    ///
    /// - Parameter requestEvent: Object which contains the request events.
    func launchPaymentEventScreen(requestEvent: PaymentRequestEvent?, requestData: [String:Any]) {
        hasPaymentRequested = true
        let loginVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginView") as! LoginViewController
        let navVC = UINavigationController()
        navVC.viewControllers = [loginVC]
        loginVC.paymentRequestEvent=requestEvent
        loginVC.item = requestData
        self.window!.rootViewController = navVC
    }
}

