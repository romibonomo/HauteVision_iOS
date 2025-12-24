import SwiftUI

// MARK: - Shared Tooltip Types
enum SharedTooltipType: String, CaseIterable {
    case ecd = "ecd"
    case pachymetry = "pachymetry"
    case iop = "iop"
    case medication = "medication"
    case vision = "vision"
    case crt = "crt"
    case reminder = "reminder"
    case k2 = "k2"
    case kMax = "kMax"
    case epithelial = "epithelial"
    case riskScore = "riskScore"
    case score = "score"
    case vfuchs = "vfuchs"
    case questionnaire = "questionnaire"
    case osmolarity = "osmolarity"
    case meibography = "meibography"
    case tmh = "tmh"
    case mmp9 = "mmp9"
    case ipl = "ipl"
    case rf = "rf"
    case md = "md"
    case psd = "psd"
    case rnfl = "rnfl"
    case gcc = "gcc"
    case regraft = "regraft"
}

// MARK: - Shared Data Entry Base Protocol
protocol DataEntryViewProtocol {
    var isEditing: Bool { get }
    var showingError: Bool { get set }
    var errorMessage: String { get set }
    var isSaving: Bool { get set }
    var showingEditWarning: Bool { get set }
    var showingDatePicker: Bool { get set }
    var activeTooltip: SharedTooltipType? { get set }
}

// MARK: - Shared Constants
struct AppConstants {
    // Colors
    static let primaryBlue = Color(red: 68/255, green: 55/255, blue: 235/255)
    static let backgroundGray = Color(.systemGray6)
    static let textGray = Color.gray
    
    // Spacing
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let largePadding: CGFloat = 24
    static let cardSpacing: CGFloat = 20
    
    // Corner Radius
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 10
    
    // Font Sizes
    static let titleFont = Font.largeTitle
    static let headlineFont = Font.headline
    static let subheadlineFont = Font.subheadline
    static let bodyFont = Font.body
    static let captionFont = Font.caption
    
    // Animation
    static let standardAnimation = Animation.easeInOut(duration: 0.2)
}

// MARK: - Shared Error Alert Component
struct ErrorAlert: View {
    @Binding var isPresented: Bool
    let message: String
    let onDismiss: (() -> Void)?
    
    init(isPresented: Binding<Bool>, message: String, onDismiss: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        EmptyView()
            .alert(LocalizedStringKey.error.localized(), isPresented: $isPresented) {
                Button(LocalizedStringKey.ok.localized()) {
                    onDismiss?()
                }
            } message: {
                Text(message)
            }
    }
}

// MARK: - Shared Loading Overlay
struct LoadingOverlay: View {
    let isVisible: Bool
    let message: String
    
    init(isVisible: Bool, message: String = "Saving...") {
        self.isVisible = isVisible
        self.message = message
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: AppConstants.smallPadding) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text(message)
                        .font(AppConstants.bodyFont)
                        .foregroundColor(.white)
                }
                .padding(AppConstants.largePadding)
                .background(Color.black.opacity(0.8))
                .cornerRadius(AppConstants.cardCornerRadius)
            }
        }
    }
}

// MARK: - Shared Info Button
struct InfoButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .foregroundColor(AppConstants.primaryBlue)
                .font(.title2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Show information")
        .accessibilityHint("Tap to view additional information")
    }
}

// MARK: - Shared Section Header
struct SectionHeader: View {
    let title: String
    let showInfoButton: Bool
    let infoAction: (() -> Void)?
    
    init(title: String, showInfoButton: Bool = false, infoAction: (() -> Void)? = nil) {
        self.title = title
        self.showInfoButton = showInfoButton
        self.infoAction = infoAction
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppConstants.headlineFont)
            Spacer()
            if showInfoButton, let infoAction = infoAction {
                InfoButton(action: infoAction)
            }
        }
    }
}

// MARK: - Shared Card Container
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppConstants.standardPadding)
            .background(AppConstants.backgroundGray)
            .cornerRadius(AppConstants.cardCornerRadius)
            .padding(.horizontal, AppConstants.standardPadding)
    }
}

// MARK: - Shared Tooltip Overlay
struct TooltipOverlay: View {
    let tooltip: SharedTooltipType?
    let onDismiss: () -> Void
    
    var body: some View {
        if let tooltip = tooltip {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            TooltipContent(tooltip: tooltip)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(AppConstants.cardCornerRadius)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Spacer()
                    }
                )
        }
    }
}

// MARK: - Tooltip Content
struct TooltipContent: View {
    let tooltip: SharedTooltipType
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
            Text(tooltipTitle)
                .font(AppConstants.headlineFont)
                .fontWeight(.bold)
            
            Text(tooltipDescription)
                .font(AppConstants.bodyFont)
        }
        .frame(maxWidth: 300)
    }
    
    private var tooltipTitle: String {
        switch tooltip {
        case .ecd: return "Endothelial Cell Density"
        case .pachymetry: return "Pachymetry"
        case .iop: return "Intraocular Pressure"
        case .medication: return "Medication"
        case .vision: return "Visual Acuity"
        case .crt: return "Central Retinal Thickness"
        case .reminder: return "Reminder"
        case .k2: return "K2 Value"
        case .kMax: return "K Max Value"
        case .epithelial: return "Epithelial Thickness"
        case .riskScore: return "Risk Score"
        case .score: return "Severity Score"
        case .vfuchs: return "VFuchs Questionnaire"
        case .questionnaire: return "OSDI Questionnaire"
        case .osmolarity: return "Tear Osmolarity"
        case .meibography: return "Meibography"
        case .tmh: return "Tear Meniscus Height"
        case .mmp9: return "MMP-9"
        case .ipl: return "IPL Treatment"
        case .rf: return "Radio Frequency"
        case .md: return "Mean Defect"
        case .psd: return "Pattern Standard Deviation"
        case .rnfl: return "RNFL Thickness"
        case .gcc: return "Macular GCC"
        case .regraft: return "Regraft Status"
        }
    }
    
    private var tooltipDescription: String {
        switch tooltip {
        case .ecd: return "The number of endothelial cells per square millimeter. Normal range is typically 2000-3000 cells/mm²."
        case .pachymetry: return "Measurement of corneal thickness in micrometers."
        case .iop: return "The pressure inside the eye, measured in mmHg. Normal range is 10-21 mmHg."
        case .medication: return "The medication being administered for treatment."
        case .vision: return "Visual acuity measurement using Snellen chart notation."
        case .crt: return "Thickness of the central retina measured in micrometers."
        case .reminder: return "Set a reminder for medication or follow-up appointments."
        case .k2: return "The second steepest corneal curvature measurement."
        case .kMax: return "The steepest corneal curvature measurement."
        case .epithelial: return "Thickness of the corneal epithelium layer."
        case .riskScore: return "Keratoconus risk assessment score (0-4)."
        case .score: return "Disease severity score based on clinical assessment."
        case .vfuchs: return "VFuchs questionnaire for endothelial dystrophy assessment."
        case .questionnaire: return "OSDI questionnaire for dry eye syndrome assessment."
        case .osmolarity: return "Tear osmolarity measurement in mOsm/L."
        case .meibography: return "Percentage of meibomian gland loss."
        case .tmh: return "Tear meniscus height measurement in millimeters."
        case .mmp9: return "Matrix metalloproteinase-9 test result."
        case .ipl: return "Intense Pulsed Light treatment status."
        case .rf: return "Radio Frequency treatment status."
        case .md: return "Mean defect in visual field testing (dB)."
        case .psd: return "Pattern standard deviation in visual field testing."
        case .rnfl: return "Retinal nerve fiber layer thickness in micrometers."
        case .gcc: return "Ganglion cell complex thickness in micrometers."
        case .regraft: return "Whether this is a regraft procedure."
        }
    }
}
