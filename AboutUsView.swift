import SwiftUI
import MapKit


struct AboutUsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    private let clinicCoordinate = CLLocationCoordinate2D(latitude: 45.4955, longitude: -73.6302)
    private let mainColor = Color(hex: "#4437EB")
    
    // Force view updates when language changes
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        Image("HauteVision_AppIcon")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 120)
                            .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("about_us".localized())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .id(currentLanguage) // Force re-render on language change
                        
                        Text("visionary_approach".localized())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .id(currentLanguage) // Force re-render on language change
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                .background(Color.white)
                
                // Content Sections
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("our_mission".localized())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("mission_text".localized())
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("our_vision".localized())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("vision_text".localized())
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("our_core_values".localized())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            FullWidthValueCard(
                                icon: "lightbulb.max.fill",
                                title: "innovation".localized(),
                                description: "innovation_description".localized()
                            )
                            FullWidthValueCard(
                                icon: "shield.fill",
                                title: "integrity".localized(),
                                description: "integrity_description".localized()
                            )
                            FullWidthValueCard(
                                icon: "star.fill",
                                title: "excellence".localized(),
                                description: "excellence_description".localized()
                            )
                            FullWidthValueCard(
                                icon: "person.3.fill",
                                title: "collaboration".localized(),
                                description: "collaboration_description".localized()
                            )
                            FullWidthValueCard(
                                icon: "heart.fill",
                                title: "compassion".localized(),
                                description: "compassion_description".localized()
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("our_expertise".localized())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("expertise_text".localized())
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("contact_us".localized())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Opening Hours
                            VStack(alignment: .leading, spacing: 8) {
                                Text("opening_hours".localized())
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\("saturday_to_sunday".localized()): \("closed".localized())")
                                    Text("\("monday_to_friday".localized()): 8AM - 4PM")
                                }
                                .font(.body)
                                .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 32) {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(Color(hex: "#4437EB"))
                                        .font(.title3)
                                    Text("(514) 782-8282")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "faxmachine.fill")
                                        .foregroundColor(Color(hex: "#4437EB"))
                                        .font(.title3)
                                    Text("(514) 788-6499")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color(hex: "#4437EB"))
                                    .font(.title3)
                                Text("info@hautevision.com")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(Color(hex: "#4437EB"))
                                    .font(.title3)
                                Text("5301 Av. de Courtrai #311, Montréal, QC, H3W 0B1")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "car.fill")
                                    .foregroundColor(Color(hex: "#4437EB"))
                                    .font(.title3)
                                Text("on_site_parking".localized())
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .id(currentLanguage) // Force re-render on language change
                            }
                        }
                        
                        Map(
                            position: .constant(
                                MapCameraPosition.region(
                                    MKCoordinateRegion(
                                        center: clinicCoordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    )
                                )
                            )
                        ) {
                            Marker("Haute Vision", coordinate: clinicCoordinate)
                                .tint(Color(hex: "#4437EB"))
                        }
                        .mapStyle(.standard(elevation: .flat))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray6), lineWidth: 0.5)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        Text("trust_your_vision".localized())
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            if let url = URL(string: "https://hautevision.com/en/") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("visit_our_website".localized())
                                .font(.body)
                                .foregroundColor(mainColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                    .padding(.bottom, 40) // Normal bottom padding
                }
            }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 0)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 80) // Space for tab bar
            }
        }
        .navigationTitle("about".localized())
        .navigationBarTitleDisplayMode(.inline)
        .id(currentLanguage) // Force re-render on language change
    }
}

struct FullWidthValueCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4437EB").opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#4437EB"))
                    .font(.title3)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        )
    }
}

struct ValueCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4437EB").opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#4437EB"))
                    .font(.title3)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        )
    }
}

struct ValueRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#4437EB"))
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


struct AboutUsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutUsView()
                .environmentObject(LocalizationManager.shared)
        }
    }
}
