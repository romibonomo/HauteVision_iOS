import SwiftUI
import Foundation

// MARK: - Custom Error Types
enum AppError: LocalizedError, Identifiable {
    case networkError(String)
    case authenticationError(String)
    case dataValidationError(String)
    case firebaseError(String)
    case unknownError(String)
    
    var id: String {
        switch self {
        case .networkError(let message): return "network_\(message.hashValue)"
        case .authenticationError(let message): return "auth_\(message.hashValue)"
        case .dataValidationError(let message): return "validation_\(message.hashValue)"
        case .firebaseError(let message): return "firebase_\(message.hashValue)"
        case .unknownError(let message): return "unknown_\(message.hashValue)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .dataValidationError(let message):
            return "Validation Error: \(message)"
        case .firebaseError(let message):
            return "Database Error: \(message)"
        case .unknownError(let message):
            return "Unexpected Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationError:
            return "Please sign in again or contact support if the problem persists."
        case .dataValidationError:
            return "Please check your input and try again."
        case .firebaseError:
            return "There was a problem saving your data. Please try again."
        case .unknownError:
            return "An unexpected error occurred. Please try again or contact support."
        }
    }
}

// MARK: - Error Handler Protocol
protocol ErrorHandler {
    func handle(_ error: AppError)
    func handle(_ error: Error)
}

// MARK: - Default Error Handler
class DefaultErrorHandler: ErrorHandler, ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    func handle(_ error: AppError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showingError = true
        }
    }
    
    func handle(_ error: Error) {
        let appError: AppError
        appError = .firebaseError(error.localizedDescription)
        handle(appError)
    }
}

// MARK: - Error Alert View
struct ErrorAlertView: View {
    @ObservedObject var errorHandler: DefaultErrorHandler
    
    var body: some View {
        EmptyView()
            .alert(LocalizedStringKey.error.localized(), isPresented: $errorHandler.showingError) {
                Button(LocalizedStringKey.ok.localized()) {
                    errorHandler.currentError = nil
                }
                if let error = errorHandler.currentError, error.recoverySuggestion != nil {
                    Button(LocalizedStringKey.getHelp.localized()) {
                        // Could open support or help documentation
                        errorHandler.currentError = nil
                    }
                }
            } message: {
                if let error = errorHandler.currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.errorDescription ?? LocalizedStringKey.anErrorOccurred.localized())
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
            }
    }
}

// MARK: - Error Boundary View
struct ErrorBoundary<Content: View>: View {
    let content: Content
    @StateObject private var errorHandler = DefaultErrorHandler()
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(errorHandler)
            .overlay(
                ErrorAlertView(errorHandler: errorHandler)
            )
    }
}

// MARK: - Retry Button Component
struct RetryButton: View {
    let action: () -> Void
    let isRetrying: Bool
    
    init(action: @escaping () -> Void, isRetrying: Bool = false) {
        self.action = action
        self.isRetrying = isRetrying
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isRetrying {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isRetrying ? LocalizedStringKey.retrying.localized() : LocalizedStringKey.retry.localized())
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppConstants.largePadding)
            .padding(.vertical, AppConstants.standardPadding)
            .background(AppConstants.primaryBlue)
            .cornerRadius(AppConstants.buttonCornerRadius)
        }
        .disabled(isRetrying)
        .accessibilityLabel(LocalizedStringKey.retryOperation.localized())
        .accessibilityHint(LocalizedStringKey.doubleTapToRetry.localized())
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    @State private var isRetrying = false
    
    init(error: AppError, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            VStack(spacing: AppConstants.smallPadding) {
                Text(LocalizedStringKey.somethingWentWrong.localized())
                    .font(AppConstants.headlineFont)
                    .fontWeight(.bold)
                
                Text(error.errorDescription ?? LocalizedStringKey.anUnexpectedErrorOccurred.localized())
                    .font(AppConstants.bodyFont)
                    .foregroundColor(AppConstants.textGray)
                    .multilineTextAlignment(.center)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(AppConstants.captionFont)
                        .foregroundColor(AppConstants.textGray)
                        .multilineTextAlignment(.center)
                }
            }
            
            HStack(spacing: AppConstants.standardPadding) {
                if let onDismiss = onDismiss {
                    Button(LocalizedStringKey.dismiss.localized()) {
                        onDismiss()
                    }
                    .foregroundColor(AppConstants.primaryBlue)
                }
                
                if let onRetry = onRetry {
                    RetryButton(
                        action: {
                            isRetrying = true
                            onRetry()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isRetrying = false
                            }
                        },
                        isRetrying: isRetrying
                    )
                }
            }
        }
        .padding(AppConstants.largePadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(LocalizedStringKey.errorOccurred.localized()) \(error.errorDescription ?? LocalizedStringKey.unknownError.localized())")
    }
}

// MARK: - Validation Helpers
struct ValidationHelper {
    static func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    static func validateNumericInput(_ input: String, range: ClosedRange<Double>? = nil) -> Bool {
        guard let value = Double(input) else { return false }
        if let range = range {
            return range.contains(value)
        }
        return true
    }
    
    static func validateRequired(_ input: String) -> Bool {
        return !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Safe Async Operations
extension View {
    func safeAsync<T>(_ operation: @escaping () async throws -> T, onSuccess: @escaping (T) -> Void, onError: @escaping (Error) -> Void) -> some View {
        self.onAppear {
            Task {
                do {
                    let result = try await operation()
                    await MainActor.run {
                        onSuccess(result)
                    }
                } catch {
                    await MainActor.run {
                        onError(error)
                    }
                }
            }
        }
    }
}

// MARK: - Error Logging
class ErrorLogger {
    static let shared = ErrorLogger()
    
    private init() {}
    
    func log(_ error: Error, context: String = "") {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(context.isEmpty ? "Error" : context): \(error.localizedDescription)"
        
        // In production, this would send to a logging service
        print("📝 Error Log: \(logMessage)")
    }
    
    func log(_ appError: AppError, context: String = "") {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(context.isEmpty ? "App Error" : context): \(appError.errorDescription ?? "Unknown error")"
        
        // In production, this would send to a logging service
        print("📝 App Error Log: \(logMessage)")
    }
}
