import SwiftUI

struct MeasurementInfoSheet: View {
    let title: String
    let infoText: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text(infoText)
                    .font(.body)
                    .lineSpacing(4)
                
                // Additional educational content based on measurement type
                if infoText.contains("Endothelial Cell Density") || infoText.contains("ECD") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingEndothelialCellDensity.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures the number of endothelial cells per square millimeter")
                        Text("• Normal range: 2000-3000 cells/mm²")
                        Text("• Lower values indicate more severe disease")
                        Text("• Critical for maintaining corneal clarity")
                        Text("• Below 500 cells/mm² may require transplant")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Corneal Thickness") || infoText.contains("Pachymetry") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingCornealThickness.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Normal thickness: 500-550 μm")
                        Text("• Increased thickness indicates corneal swelling")
                        Text("• Swelling causes vision changes")
                        Text("• Important for monitoring disease progression")
                        Text("• Values above 600 μm are concerning")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("IOP") || infoText.contains("Intraocular Pressure") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingIntraocularPressure.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Normal range: 10-21 mmHg")
                        Text("• Elevated IOP can damage the optic nerve")
                        Text("• Can also damage the graft in transplant cases")
                        Text("• Important for long-term eye health")
                        Text("• Regular monitoring is crucial")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("K2") || infoText.contains("K Max") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingCornealCurvature.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Normal corneal curvature ranges from 41-46 diopters")
                        Text("• Higher values may indicate keratoconus progression")
                        Text("• Regular monitoring helps detect early changes")
                        Text("• Values above 50 diopters often require treatment")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Epithelial") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingEpithelialThickness.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Epithelium is the outermost layer of the cornea")
                        Text("• Thinning in certain areas may indicate early keratoconus")
                        Text("• Normal thickness varies by location")
                        Text("• Important for early detection")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Risk Score") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingRiskScores.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• 0-3: Low risk of progression")
                        Text("• 4-6: Moderate risk, monitor closely")
                        Text("• 7-10: High risk, consider treatment")
                        Text("• Based on multiple factors combined")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Questionnaire") || infoText.contains("Symptom Score") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingSymptomScores.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Standardized assessment of dry eye symptoms")
                        Text("• Higher scores indicate more severe symptoms")
                        Text("• Helps track treatment effectiveness")
                        Text("• Important for treatment planning")
                        Text("• Regular assessment is recommended")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Osmolarity") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingTearOsmolarity.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures concentration of particles in tears")
                        Text("• Normal range: 275-308 mOsm/L")
                        Text("• Elevated levels indicate tear film instability")
                        Text("• Important diagnostic tool")
                        Text("• Values above 316 mOsm/L are concerning")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Meibography") || infoText.contains("Gland Loss") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingMeibomianGlandFunction.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Meibomian glands produce oil for tear film")
                        Text("• Normal: 0-25% gland loss")
                        Text("• Moderate: 26-50% gland loss")
                        Text("• Severe: >50% gland loss")
                        Text("• Higher loss indicates more severe dysfunction")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("TMH") || infoText.contains("Tear Meniscus") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingTearMeniscusHeight.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures tear volume at lower eyelid")
                        Text("• Normal range: 0.2-0.5 mm")
                        Text("• Lower values may indicate reduced tear production")
                        Text("• Important for diagnosis")
                        Text("• Values below 0.2 mm are concerning")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("RNFL") || infoText.contains("Retinal Nerve Fiber Layer") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingRNFLThickness.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures nerve fiber thickness around optic nerve")
                        Text("• Normal range: 80-120 μm")
                        Text("• Thinning indicates glaucoma progression")
                        Text("• Superior and inferior quadrants are key")
                        Text("• Values below 80 μm are concerning")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("GCC") || infoText.contains("Ganglion Cell") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingMacularGCC.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures ganglion cells in the macula")
                        Text("• Normal range: 70-100 μm")
                        Text("• Thinning may indicate early glaucoma")
                        Text("• Important for early detection")
                        Text("• Values below 70 μm are concerning")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Mean Defect") || infoText.contains("MD") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingMeanDefect.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures average sensitivity loss")
                        Text("• Normal range: -2 to +2 dB")
                        Text("• Negative values indicate vision loss")
                        Text("• Progressively negative values are concerning")
                        Text("• Important for tracking progression")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Pattern Standard Deviation") || infoText.contains("PSD") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingPatternStandardDeviation.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures irregularity of vision loss")
                        Text("• Normal range: 0-2 dB")
                        Text("• Higher values indicate more irregular loss")
                        Text("• Important for glaucoma diagnosis")
                        Text("• Values above 2 dB are concerning")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("CRT") || infoText.contains("Central Retina Thickness") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingCentralRetinaThickness.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures thickness of the central retina")
                        Text("• Important for monitoring macular edema")
                        Text("• Helps assess treatment response")
                        Text("• Normal values vary by individual")
                        Text("• Changes indicate disease activity")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Visual Acuity") || infoText.contains("Vision") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingVisualAcuity.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• Measures clarity of vision")
                        Text("• Uses Snellen notation (20/y)")
                        Text("• Lower denominators indicate better vision")
                        Text("• Important for treatment monitoring")
                        Text("• Changes may indicate disease progression")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                } else if infoText.contains("Severity Score") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey.understandingSeverityScores.localized())
                            .font(.headline)
                            .padding(.top)
                        
                        Text("• 0: No symptoms")
                        Text("• 1-2: Mild symptoms, morning blur")
                        Text("• 3-4: Moderate symptoms, persistent blur")
                        Text("• 5-6: Severe symptoms, significant vision loss")
                        Text("• Helps guide treatment decisions")
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Measurement Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedStringKey.done.localized()) {
                    // This will be handled by the sheet dismissal
                }
            }
        }
    }
} 