//
//  HauteVisionApp.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-03-09.
//

//Website Colors:
//  Gray: FAF9FD 
//  Purple: E8DEF5
//  Green: CEFFAE
//  White: FFFFFF
//  DarkGray: EEEEEE
//  Black: 000000
//  DarkPurple: E0D3F1
//  MainBlue: 4437EB

import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Configure global navigation and tab bar appearance
        configureAppearance()
        
        return true
    }
    
    private func configureAppearance() {
        // Configure Tab Bar Appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabBarAppearance.shadowImage = UIImage()
        tabBarAppearance.shadowColor = .clear
        let offset = UIOffset(horizontal: 0, vertical: 4)
        tabBarAppearance.stackedLayoutAppearance.normal.titlePositionAdjustment = offset
        tabBarAppearance.stackedLayoutAppearance.selected.titlePositionAdjustment = offset
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Configure Navigation Bar Appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.backgroundColor = .white
        navBarAppearance.shadowImage = UIImage()
        navBarAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = navBarAppearance
        }
    }

    // Handle notification delivery and reschedule for custom intervals
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let interval = userInfo["customInterval"] as? TimeInterval,
           let medicationName = userInfo["medicationName"] as? String {
            // Schedule the next notification for the same interval
            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = "It's time to take your medication: \(medicationName)"
            content.sound = .default
            content.userInfo = ["customInterval": interval, "medicationName": medicationName]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let identifier = "medication_reminder_\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { _ in
                // Notification rescheduled successfully
            }
            // Optionally update UserDefaults if you want to keep track of the latest identifier
            UserDefaults.standard.set(identifier, forKey: "currentMedicationReminderID")
        }
        completionHandler()
    }
}

@main
struct HauteVisionApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize AuthViewModel only after Firebase is ready
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var errorHandler = DefaultErrorHandler()
    
    var body: some Scene {
        WindowGroup {
            ErrorBoundary {
                ContentView()
                    .environmentObject(viewModel)
                    .environmentObject(localizationManager)
                    .environmentObject(errorHandler)
            }
            .onAppear {
                // Log app launch for performance monitoring
                let (_, duration) = PerformanceMonitor.measureTime {
                    // App initialization complete
                }
                PerformanceMonitor.logPerformance("App Launch", duration: duration)
            }
            .onMemoryWarning {
                // Handle memory warnings
                ErrorLogger.shared.log(AppError.unknownError("Memory warning received"), context: "App")
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appWillTerminate = Notification.Name("appWillTerminate")
}
