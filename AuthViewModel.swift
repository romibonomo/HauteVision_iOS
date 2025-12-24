//
//  AuthViewModel.swift
//  HauteVision
//
//  Created by romi bonomo on 2025-02-10.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Network
import SwiftUI


class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private(set) var isConnected = true
    private var isCleanedUp = false
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
    
    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        monitor.cancel()
    }
    
    deinit {
        cleanup()
    }
}

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var networkAvailable = true
    @Published var error: Error?
    @Published var hasCompletedOnboarding: Bool = false
    private let monitor = NWPathMonitor()
    private var db: Firestore?
    private var currentTask: Task<Void, Never>?
    private var isCleanedUp = false
    
    init() {
        // Initialize with safe defaults - no Firebase access
        self.userSession = nil
        self.currentUser = nil
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        setupNetworkMonitoring()
        
        // Listen for app termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: .appWillTerminate,
            object: nil
        )
        
        // Defer all Firebase initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.initializeFirebase()
        }
    }
    
    private func initializeFirebase() {
        // Safely initialize Firebase components
        // Initialize Firestore
        self.db = Firestore.firestore()
        
        // Check for current user
        self.userSession = Auth.auth().currentUser
        
        // Fetch user data if logged in
        if self.userSession != nil {
            currentTask = Task {
                await fetchUser()
            }
        }
    }
    
    @objc private func handleAppTermination() {
        Task { @MainActor in
            cleanup()
        }
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task { @MainActor in
                self.networkAvailable = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "AuthNetworkMonitor", qos: .utility)
        monitor.start(queue: queue)
    }
    
    @MainActor
    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // Cancel any ongoing tasks
        currentTask?.cancel()
        currentTask = nil
        
        // Cancel network monitoring
        monitor.cancel()
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        let (_, duration) = PerformanceMonitor.measureTime {
            isLoading = true
        }
        PerformanceMonitor.logPerformance("SignIn UI Update", duration: duration)
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            self.userSession = result.user
            await fetchUser()
        } catch {
            ErrorLogger.shared.log(error, context: "SignIn")
            throw error
        }
    }
    
    func createUser(withEmail email: String, password: String, name: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = User(name: name, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(result.user.uid).setData(encodedUser)
            await MainActor.run {
                self.userSession = result.user
                self.currentUser = user
            }
        } catch {
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            throw error
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid,
              let db = db else { return }
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let snapshot = try await db.collection("users").document(uid).getDocument()
            
            // Check for cancellation after the request
            try Task.checkCancellation()
            
            self.currentUser = try snapshot.data(as: User.self)
        } catch is CancellationError {
            // Task was cancelled, this is expected during app termination
        } catch {
        }
    }
    
    func resetPassword(email: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw error
        }
    }
    
    func deleteAccount() async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        }
        
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        do {
            // Delete user data from Firestore
            try await Firestore.firestore().collection("users").document(user.uid).delete()
            
            // Delete the user account from Firebase Auth
            try await user.delete()
            
            // Sign out and clear local state
            await MainActor.run {
                try? self.signOut()
            }
        } catch {
            throw error
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard networkAvailable else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        }
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Reauthenticate user before changing password
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)
            
            // Change password
            try await user.updatePassword(to: newPassword)
        } catch {
            throw error
        }
    }
    
    func updateProfile(name: String, email: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        }
        
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update user document in Firestore with just the name
            let updatedUser = User(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: user.email ?? email
            )
            let encodedUser = try Firestore.Encoder().encode(updatedUser)
            try await Firestore.firestore().collection("users").document(user.uid).setData(encodedUser)
            
            // Update local user state
            await MainActor.run {
                self.currentUser = updatedUser
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Onboarding Management
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = false
    }
    
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }
    
    deinit {
        // Call cleanup without MainActor context since deinit cannot be @MainActor
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self)
        
        // Cancel any ongoing tasks
        currentTask?.cancel()
        currentTask = nil
        
        // Cancel network monitoring
        monitor.cancel()
    }
}
