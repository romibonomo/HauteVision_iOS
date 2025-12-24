//
//  SplashScreenView.swift
//  HauteVision
//
//  Created by AI Assistant on 2025-01-27.
//

import SwiftUI
import UIKit
import CBZSplashView

// MARK: - SwiftUI Wrapper for CBZSplashView
struct SplashScreenView: UIViewControllerRepresentable {
    let iconImage: UIImage?
    let backgroundColor: UIColor
    let iconColor: UIColor?
    let iconStartSize: CGSize
    let animationDuration: TimeInterval
    let onAnimationComplete: (() -> Void)?
    
    init(
        iconImage: UIImage? = nil,
        backgroundColor: UIColor = UIColor(red: 0.27, green: 0.22, blue: 0.92, alpha: 1.0), // AppConstants.primaryBlue
        iconColor: UIColor? = nil,
        iconStartSize: CGSize = CGSize(width: 100, height: 100),
        animationDuration: TimeInterval = 1.0,
        onAnimationComplete: (() -> Void)? = nil
    ) {
        self.iconImage = iconImage
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.iconStartSize = iconStartSize
        self.animationDuration = animationDuration
        self.onAnimationComplete = onAnimationComplete
    }
    
    func makeUIViewController(context: Context) -> SplashViewController {
        let viewController = SplashViewController()
        viewController.splashView = createSplashView()
        viewController.onAnimationComplete = onAnimationComplete
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: SplashViewController, context: Context) {
        // Update if needed
    }
    
    private func createSplashView() -> CBZSplashView {
        let splashView: CBZSplashView
        
        if let iconImage = iconImage {
            // Use rasterized image
            splashView = CBZSplashView.splashView(withIcon: iconImage, backgroundColor: backgroundColor)
        } else {
            // Use default app icon or create a simple path
            if let defaultIcon = UIImage(named: "HauteVision_AppIcon") {
                splashView = CBZSplashView.splashView(withIcon: defaultIcon, backgroundColor: backgroundColor)
            } else {
                // Fallback: create a simple circular path
                let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100))
                splashView = CBZSplashView.splashView(withBezierPath: path, backgroundColor: backgroundColor)
            }
        }
        
        // Customize the splash view
        splashView.iconStartSize = iconStartSize
        splashView.animationDuration = animationDuration
        
        if let iconColor = iconColor {
            splashView.iconColor = iconColor
        }
        
        return splashView
    }
}

// MARK: - View Controller to host CBZSplashView
class SplashViewController: UIViewController {
    var splashView: CBZSplashView?
    var onAnimationComplete: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let splashView = splashView else { return }
        
        view.addSubview(splashView)
        splashView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            splashView.topAnchor.constraint(equalTo: view.topAnchor),
            splashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splashView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splashView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start animation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.splashView?.startAnimation()
            
            // Call completion handler after animation duration
            if let duration = self.splashView?.animationDuration {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    self.onAnimationComplete?()
                }
            }
        }
    }
}

// MARK: - SwiftUI View Modifier
struct SplashScreenModifier: ViewModifier {
    @State private var showSplash = true
    let iconImage: UIImage?
    let backgroundColor: UIColor
    let iconColor: UIColor?
    let iconStartSize: CGSize
    let animationDuration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(showSplash ? 0 : 1)
            
            if showSplash {
                SplashScreenView(
                    iconImage: iconImage,
                    backgroundColor: backgroundColor,
                    iconColor: iconColor,
                    iconStartSize: iconStartSize,
                    animationDuration: animationDuration,
                    onAnimationComplete: {
                        withAnimation {
                            showSplash = false
                        }
                    }
                )
                .ignoresSafeArea()
            }
        }
    }
}

extension View {
    func splashScreen(
        iconImage: UIImage? = nil,
        backgroundColor: UIColor = UIColor(red: 0.27, green: 0.22, blue: 0.92, alpha: 1.0),
        iconColor: UIColor? = nil,
        iconStartSize: CGSize = CGSize(width: 100, height: 100),
        animationDuration: TimeInterval = 1.0
    ) -> some View {
        modifier(SplashScreenModifier(
            iconImage: iconImage,
            backgroundColor: backgroundColor,
            iconColor: iconColor,
            iconStartSize: iconStartSize,
            animationDuration: animationDuration
        ))
    }
}


