import SwiftUI

// Update the DataGraphView to use automatic y-axis range based on data and support regrafts
struct DataGraphView: View {
    let data: [(Date, Double, Bool?)] // Added Bool for isRegraft flag
    let color: Color
    let title: String
    let valueLabel: (Double) -> String
    let yAxisRange: ClosedRange<Double> // Keep for fallback but don't use directly
    let yAxisStepSize: Double
    let normalRange: ClosedRange<Double>?
    let recommendedInterval: String // Added recommended monitoring interval
    @State private var selectedPoint: Int? = nil
    @State private var showingNormalRangeInfo = false
    @State private var showingIntervalInfo = false
    @State private var showingRegraftLegend = false
    
    // Initialize with default parameters for backward compatibility
    init(data: [(Date, Double)], 
         color: Color, 
         title: String, 
         valueLabel: @escaping (Double) -> String, 
         yAxisRange: ClosedRange<Double>, 
         yAxisStepSize: Double, 
         normalRange: ClosedRange<Double>?,
         recommendedInterval: String = "") {
        self.data = data.map { ($0.0, $0.1, nil) }
        self.color = color
        self.title = title
        self.valueLabel = valueLabel
        self.yAxisRange = yAxisRange
        self.yAxisStepSize = yAxisStepSize
        self.normalRange = normalRange
        self.recommendedInterval = recommendedInterval
    }
    
    // New initializer that supports regraft data
    init(data: [(Date, Double, Bool)], 
         color: Color, 
         title: String, 
         valueLabel: @escaping (Double) -> String, 
         yAxisRange: ClosedRange<Double>, 
         yAxisStepSize: Double, 
         normalRange: ClosedRange<Double>?,
         recommendedInterval: String = "") {
        self.data = data
        self.color = color
        self.title = title
        self.valueLabel = valueLabel
        self.yAxisRange = yAxisRange
        self.yAxisStepSize = yAxisStepSize
        self.normalRange = normalRange
        self.recommendedInterval = recommendedInterval
    }
    
    // Check if we have any regraft data points
    private var hasRegraftPoints: Bool {
        return data.contains { $0.2 == true }
    }
    
    // Get indices of all regraft points
    private var regraftIndices: [Int] {
        return data.indices.filter { data[$0].2 == true }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var normalRangeText: String {
        // Hard-coded normal ranges based on the graph title
        if title.contains("Endothelial Cell Density") || title.contains("ECD") {
            return "Normal range: orders of 100-1000s magnitudes"
        } else if title.contains("Corneal Thickness") || title.contains("Pachymetry") {
            return "Normal range: average of 500 microns"
        } else if title.contains("Fuchs Score") || title.contains("Symptom Score") {
            return "Normal range: 0-4 (lower is better)"
        } else if let range = normalRange {
            // Fallback to the original range if title doesn't match
            return "Normal range: \(valueLabel(range.lowerBound)) - \(valueLabel(range.upperBound))"
        } else {
            return ""
        }
    }
    
    // Calculate the actual data range directly from the data
    private var dataYRange: ClosedRange<Double> {
        if data.isEmpty {
            // Default range if no data
            return yAxisRange
        }
        
        let values = data.map { $0.1 }
        let minValue = values.min() ?? yAxisRange.lowerBound
        let maxValue = values.max() ?? yAxisRange.upperBound
        
        // Handle case where all values are the same
        if abs(maxValue - minValue) < 0.001 {
            // Create a range centered around the single value with significant padding
            let baseValue = minValue
            let padding = Swift.max(baseValue * 0.2, 20.0) // At least 20 units of padding or 20% of the value
            
            return Swift.max(baseValue - padding, 0.0)...baseValue + padding
        }
        
        // Normal case with multiple different values
        // Add padding to the top and bottom (15% padding)
        let range = maxValue - minValue
        let paddingPercent = 0.15
        let bottomPadding = range * paddingPercent
        let topPadding = range * paddingPercent
        
        // Ensure the lower bound is never negative for values that shouldn't be negative
        let lowerBound = Swift.max(minValue - bottomPadding, 0.0)
        let upperBound = maxValue + topPadding
        
        return lowerBound...upperBound
    }
    
    // Calculate step size based on the actual data range
    private var dynamicStepSize: Double {
        let range = dataYRange.upperBound - dataYRange.lowerBound
        
        // Handle very small ranges
        if range < 0.001 {
            return 1.0 // Default step size for tiny ranges
        }
        
        // Special case for integer-based scores with small ranges (like 0-10)
        let allValuesAreIntegers = data.allSatisfy { floor($0.1) == $0.1 }
        let smallIntegerRange = range <= 10 && allValuesAreIntegers
        
        if smallIntegerRange {
            // For small integer ranges (like symptom scores), use step size of 1
            return 1.0
        }
        
        // Use the provided step size if it fits well
        if range / yAxisStepSize >= 3 && range / yAxisStepSize <= 8 {
            return yAxisStepSize
        }
        
        let steps = 5.0 // Aim for about 5 steps
        
        // Round to a nice number
        let rawStep = range / steps
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude
        
        if normalized < 1.5 {
            return magnitude
        } else if normalized < 3.5 {
            return 2 * magnitude
        } else if normalized < 7.5 {
            return 5 * magnitude
        } else {
            return 10 * magnitude
        }
    }
    
    // Generate nice looking y-axis values
    private var yAxisValues: [Double] {
        // Safety check for invalid ranges
        if dataYRange.lowerBound >= dataYRange.upperBound {
            return [0, 100] // Fallback to a simple range
        }
        
        // Store dynamicStepSize in a local variable to avoid any confusion
        let stepSize = dynamicStepSize
        
        // Special case for integer-based scores with small ranges (like 0-10)
        let allValuesAreIntegers = data.allSatisfy { floor($0.1) == $0.1 }
        let smallIntegerRange = (dataYRange.upperBound - dataYRange.lowerBound) <= 10 && allValuesAreIntegers
        
        if smallIntegerRange {
            // For small integer ranges (like symptom scores), use integer values
            let min = Int(floor(dataYRange.lowerBound))
            let max = Int(ceil(dataYRange.upperBound))
            return Array(min...max).map { Double($0) }
        }
        
        // Normal case for continuous values
        let min = floor(dataYRange.lowerBound / stepSize) * stepSize
        let max = ceil(dataYRange.upperBound / stepSize) * stepSize
        
        var values: [Double] = []
        var current = min
        
        // Safety check to prevent infinite loops
        let maxIterations = 100
        var iteration = 0
        
        while current <= max && iteration < maxIterations {
            values.append(current)
            current += stepSize
            iteration += 1
        }
        
        // Ensure we have at least 2 values for the y-axis
        if values.count < 2 {
            if let singleValue = values.first {
                // If we only have one value, add another value to create a range
                if singleValue == 0 {
                    values.append(stepSize) // If the value is 0, add a step above
                } else {
                    // Otherwise add values above and below
                    let lowerValue = Swift.max(Double(singleValue - stepSize), 0.0)
                    values = [lowerValue, singleValue, singleValue + stepSize]
                }
            } else {
                // If we have no values (shouldn't happen), add default values
                values = [0, 100]
            }
        }
        
        return values
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Graph title with info buttons
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(.darkText))
                
                Spacer()
                
                // Add regraft legend button if we have regraft points
                if hasRegraftPoints {
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            showingRegraftLegend.toggle()
                            if showingRegraftLegend {
                                showingIntervalInfo = false
                                showingNormalRangeInfo = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(LocalizedStringKey.regraft.localized())
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        if showingRegraftLegend {
                            VStack(alignment: .trailing) {
                                Spacer().frame(height: 25)
                                
                                Text(LocalizedStringKey.redPointsIndicateRegraft.localized())
                                    .font(.caption)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6)
                                    .onTapGesture {
                                        showingRegraftLegend.toggle()
                                    }
                            }
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(), value: showingRegraftLegend)
                        }
                    }
                    .zIndex(100) // Ensure tooltip is on top of everything
                    .padding(.trailing, 8)
                }
                
                // Add info button for recommended interval
                if !recommendedInterval.isEmpty {
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            showingIntervalInfo.toggle()
                            if showingIntervalInfo {
                                showingNormalRangeInfo = false
                                showingRegraftLegend = false
                            }
                        }) {
                            Image(systemName: "clock.circle")
                                .foregroundColor(.blue)
                        }
                        
                        if showingIntervalInfo {
                            VStack(alignment: .trailing) {
                                Spacer().frame(height: 25)
                                
                                Text("\(LocalizedStringKey.recommended.localized()) \(recommendedInterval)")
                                    .font(.caption)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6)
                                    .onTapGesture {
                                        showingIntervalInfo.toggle()
                                    }
                            }
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(), value: showingIntervalInfo)
                        }
                    }
                    .zIndex(100) // Ensure tooltip is on top of everything
                    .padding(.trailing, 8)
                }
                
                // Add info button for normal range
                if normalRange != nil {
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            showingNormalRangeInfo.toggle()
                            if showingNormalRangeInfo {
                                showingIntervalInfo = false
                                showingRegraftLegend = false
                            }
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        
                        if showingNormalRangeInfo {
                            VStack(alignment: .trailing) {
                                Spacer().frame(height: 25)
                                
                                // Check if the text contains "TODO" and use a special format
                                if normalRangeText.contains("TODO") {
                                    HStack(spacing: 4) {
                                        Text(LocalizedStringKey.normalRange.localized())
                                            .font(.caption)
                                        
                                        Text(LocalizedStringKey.todo.localized())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 4)
                                            .background(Color.yellow)
                                            .foregroundColor(.black)
                                    }
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
                                    .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                                    .onTapGesture {
                                        showingNormalRangeInfo.toggle()
                                    }
                                } else {
                                    Text(normalRangeText)
                                        .font(.caption)
                                        .padding(10)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                                        .onTapGesture {
                                            showingNormalRangeInfo.toggle()
                                        }
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(), value: showingNormalRangeInfo)
                        }
                    }
                    .zIndex(100) // Ensure tooltip is on top of everything
                }
            }
            .padding(.horizontal)
            
            // Main graph container
            ZStack(alignment: .center) {
                VStack(spacing: 0) {
                    // Graph with axes
                    GeometryReader { geometry in
                        ZStack {
                            // Background grid
                            VStack(spacing: 0) {
                                ForEach(yAxisValues.reversed(), id: \.self) { value in
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(height: gridRowHeight(for: value, in: geometry))
                                        .overlay(
                                            Rectangle()
                                                .fill(Color(.systemGray5))
                                                .frame(height: 1)
                                                .opacity(0.5),
                                            alignment: .top
                                        )
                                }
                            }
                            
                            // Y-axis labels
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(yAxisValues.reversed(), id: \.self) { value in
                                    Text(valueLabel(value))
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                        .frame(width: 40, alignment: .trailing)
                                        .frame(height: gridRowHeight(for: value, in: geometry), alignment: .center)
                                        .offset(y: -gridRowHeight(for: value, in: geometry) / 2) // Align with grid lines
                                }
                            }
                            .frame(width: 40, alignment: .trailing)
                            .position(x: 20, y: geometry.size.height / 2)
                            
                            // Graph content
                            if data.count > 0 {
                                if !regraftIndices.isEmpty {
                                    drawRegraftSegments(regraftIndices: regraftIndices, geometry: geometry)
                                } else {
                                    drawNormalSegments(geometry: geometry)
                                }
                                
                                // Invisible touch areas for each data point
                                ForEach(Array(data.indices), id: \.self) { i in
                                    let x = calculateXPosition(index: i, in: geometry)
                                    let y = calculateYPosition(data[i].1, in: geometry)
                                    
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 80, height: 80)
                                        .contentShape(Circle())
                                        .position(x: x, y: y)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedPoint = (selectedPoint == i) ? nil : i
                                            }
                                        }
                                }
                                
                                // Data points (visible circles)
                                ForEach(Array(data.indices), id: \.self) { i in
                                    let x = calculateXPosition(index: i, in: geometry)
                                    let y = calculateYPosition(data[i].1, in: geometry)
                                    let isRegraft = data[i].2 ?? false
                                    let pointColor = isRegraft ? Color.red : color
                                    
                                    Circle()
                                        .fill(selectedPoint == i ? pointColor : Color.white)
                                        .frame(width: selectedPoint == i ? 12 : 8, height: selectedPoint == i ? 12 : 8)
                                        .overlay(
                                            Circle()
                                                .stroke(pointColor, lineWidth: 2)
                                        )
                                        .position(x: x, y: y)
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                        .zIndex(5)
                                }
                                
                                // Add regraft indicators with more prominence
                                ForEach(Array(data.indices), id: \.self) { i in
                                    if data[i].2 == true {
                                        let x = calculateXPosition(index: i, in: geometry)
                                        let y = calculateYPosition(data[i].1, in: geometry)
                                        
                                        // Add a larger highlight circle behind the regraft indicator
                                        Circle()
                                            .fill(Color.red.opacity(0.2))
                                            .frame(width: 24, height: 24)
                                            .position(x: x, y: y)
                                        
                                        // Add the "R" indicator
                                        Text(LocalizedStringKey.rightEyeIndicator.localized())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 16, height: 16)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .position(x: x, y: y - 16)
                                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                                            .zIndex(6)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: calculateGraphHeight())
                    .padding(.bottom, 30) // Space for x-axis labels
                    
                    // X-axis labels
                    if data.count > 0 {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                // Y-axis space
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 40)
                                
                                // X-axis labels
                                ZStack(alignment: .top) {
                                    ForEach(Array(data.indices), id: \.self) { i in
                                        Text(dateFormatter.string(from: data[i].0))
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                            .rotationEffect(.degrees(-45))
                                            .position(
                                                x: calculateXPosition(index: i, in: geometry) - 40, // Adjust for y-axis space
                                                y: 10
                                            )
                                    }
                                }
                                .frame(height: 30)
                            }
                        }
                        .frame(height: 30)
                    }
                }
                .padding(.horizontal, 8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .zIndex(10) // Add zIndex to ensure proper layering
                
                // Selected point popup - now displayed as an overlay on top of the graph
                if let selectedPoint = selectedPoint, selectedPoint < data.count {
                    let point = data[selectedPoint]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedStringKey.selectedDataPoint.localized())
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    self.selectedPoint = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedStringKey.date.localized())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(fullDateFormatter.string(from: point.0))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(LocalizedStringKey.value.localized())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(valueLabel(point.1))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(color)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .frame(width: Swift.min(CGFloat(UIScreen.main.bounds.width - 60), CGFloat(300)))
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                    .zIndex(20) // Ensure popup is on top of everything
                }
            }
            
            // Instructions for interaction (only shown when there are multiple data points and none is selected)
            if data.count > 1 && selectedPoint == nil {
                Text(LocalizedStringKey.tapOnDataPoints.localized())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8) // Add horizontal padding to the entire graph component
        .zIndex(20) // Ensure the entire graph container has proper layering
    }
    
    // Calculate the appropriate graph height based on data points
    private func calculateGraphHeight() -> CGFloat {
        // Base height for empty or single data point
        if data.count <= 1 {
            return 150
        }
        
        // Scale height based on number of data points
        let baseHeight: CGFloat = 150
        let additionalHeight = Swift.min(CGFloat(data.count) * 10, CGFloat(100)) // Add up to 100 points for many data points
        
        return baseHeight + additionalHeight
    }
    
    // Calculate grid row height
    private func gridRowHeight(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let values = yAxisValues
        
        // Safety checks
        guard values.count >= 2 else {
            return geometry.size.height / 2 // Return half height if we don't have enough values
        }
        
        guard let minValue = values.min(), let maxValue = values.max() else {
            return geometry.size.height / CGFloat(values.count)
        }
        
        // If min and max are too close, return a default height
        if abs(maxValue - minValue) < 0.001 {
            return geometry.size.height / CGFloat(values.count)
        }
        
        // Special case for integer-based scores with small ranges (like 0-10)
        let allValuesAreIntegers = data.allSatisfy { floor($0.1) == $0.1 }
        let smallIntegerRange = (maxValue - minValue) <= 10 && allValuesAreIntegers
        
        if smallIntegerRange {
            // For small integer ranges, ensure equal spacing between all values
            return geometry.size.height / CGFloat(values.count - 1)
        }
        
        // Calculate height based on the full range and distribute evenly
        let totalHeight = geometry.size.height
        
        // For evenly spaced grid lines, we need to calculate based on the number of segments
        let numberOfSegments = CGFloat(values.count - 1)
        let segmentHeight = totalHeight / numberOfSegments
        
        // Return the same height for each segment to ensure consistent spacing
        return segmentHeight
    }
    
    // Calculate Y position based on value
    private func calculateYPosition(_ value: Double, in geometry: GeometryProxy) -> CGFloat {
        // Get the min and max values from yAxisValues to ensure alignment with labels
        guard let minValue = yAxisValues.min(), let maxValue = yAxisValues.max() else {
            // Fallback to dataYRange if yAxisValues is empty
            let range = CGFloat(dataYRange.upperBound - dataYRange.lowerBound)
            if range < 0.001 {
                return geometry.size.height / 2
            }
            let normalizedValue = CGFloat(value - dataYRange.lowerBound) / range
            let clampedValue = Swift.max(CGFloat(0), Swift.min(CGFloat(1), normalizedValue))
            return geometry.size.height - (clampedValue * geometry.size.height)
        }
        
        // Calculate using the same range as the y-axis labels
        let range = maxValue - minValue
        
        // Handle case where range is very small or zero
        if range < 0.001 {
            // Center the point vertically if there's effectively no range
            return geometry.size.height / 2
        }
        
        // Calculate normalized value (0 to 1) where 0 is the lowest value and 1 is the highest
        let normalizedValue = CGFloat(value - minValue) / CGFloat(range)
        
        // Safety check for normalized value
        if normalizedValue.isNaN || normalizedValue.isInfinite {
            return geometry.size.height / 2
        }
        
        // Clamp normalized value between 0 and 1
        let clampedValue = Swift.max(CGFloat(0), Swift.min(CGFloat(1), normalizedValue))
        
        // Convert to y-coordinate where top of graph is for highest values
        // and bottom of graph is for lowest values
        return geometry.size.height - (clampedValue * geometry.size.height)
    }
    
    // Calculate X position based on index
    private func calculateXPosition(index: Int, in geometry: GeometryProxy) -> CGFloat {
        let yAxisWidth: CGFloat = 50 // Width of y-axis area
        let horizontalPadding: CGFloat = 20 // Padding on each side
        let availableWidth = geometry.size.width - yAxisWidth - (horizontalPadding * 2) // Subtract y-axis width and padding
        
        if data.count <= 1 {
            return yAxisWidth + horizontalPadding + (availableWidth / 2) // Center the single point
        }
        
        let segmentWidth = availableWidth / CGFloat(Swift.max(data.count - 1, 1))
        return yAxisWidth + horizontalPadding + (CGFloat(index) * segmentWidth) // Add y-axis width and padding
    }
    
    // Helper function to draw an area segment
    private func drawAreaSegment(for segmentData: [(Date, Double, Bool?)], in geometry: GeometryProxy, color: Color) -> Path {
        Path { path in
            guard !segmentData.isEmpty else { return }
            
            let startX = calculateXPosition(index: data.firstIndex(where: { $0.0 == segmentData[0].0 }) ?? 0, in: geometry)
            let startY = calculateYPosition(segmentData[0].1, in: geometry)
            
            // Start at the bottom of the graph at the first x-position
            path.move(to: CGPoint(x: startX, y: geometry.size.height))
            // Draw line to the first data point
            path.addLine(to: CGPoint(x: startX, y: startY))
            
            // Draw lines to each data point
            for i in 1..<segmentData.count {
                let dataIndex = data.firstIndex(where: { $0.0 == segmentData[i].0 }) ?? i
                let x = calculateXPosition(index: dataIndex, in: geometry)
                let y = calculateYPosition(segmentData[i].1, in: geometry)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Draw line to the bottom of the graph at the last x-position
            let lastDataIndex = data.firstIndex(where: { $0.0 == segmentData.last?.0 }) ?? (segmentData.count - 1)
            let lastX = calculateXPosition(index: lastDataIndex, in: geometry)
            path.addLine(to: CGPoint(x: lastX, y: geometry.size.height))
            path.closeSubpath()
        }
    }
    
    // Helper function to draw a line segment
    private func drawLineSegment(from startIndex: Int, to endIndex: Int, in geometry: GeometryProxy, color: Color) -> Path {
        Path { path in
            // Guard against invalid indices
            guard startIndex < endIndex && startIndex >= 0 && endIndex < data.count else {
                return
            }
            
            let startX = calculateXPosition(index: startIndex, in: geometry)
            let startY = calculateYPosition(data[startIndex].1, in: geometry)
            
            path.move(to: CGPoint(x: startX, y: startY))
            
            for i in stride(from: startIndex + 1, through: endIndex, by: 1) {
                let x = calculateXPosition(index: i, in: geometry)
                let y = calculateYPosition(data[i].1, in: geometry)
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
    }
    
    // Helper method to create area segments
    private func renderAreaSegments(regraftIndices: [Int], geometry: GeometryProxy) -> [AnyView] {
        var segments: [AnyView] = []
        var startIndex = 0
        
        // Create segments between regraft points
        for regraftIndex in regraftIndices {
            if regraftIndex > startIndex {
                // Draw area for this segment
                let segmentData = Array(data[startIndex..<regraftIndex])
                let segment = drawAreaSegment(for: segmentData, in: geometry, color: color.opacity(0.1))
                    .fill(color.opacity(0.1))
                segments.append(AnyView(segment))
            }
            
            // Start a new segment
            startIndex = regraftIndex
        }
        
        // Draw the final segment
        if startIndex < data.count - 1 {
            let segmentData = Array(data[startIndex..<data.count])
            let segment = drawAreaSegment(for: segmentData, in: geometry, color: Color.red.opacity(0.1))
                .fill(Color.red.opacity(0.1))
            segments.append(AnyView(segment))
        }
        
        return segments
    }
    
    // Helper method to create line segments
    private func createLineSegments(geometry: GeometryProxy) -> [AnyView] {
        guard !data.isEmpty else { return [] }
        
        var segments: [AnyView] = []
        var currentSegmentStart = 0
        var isRegraftSegment = data[0].2 == true
        
        for i in 1..<data.count {
            let currentIsRegraft = data[i].2 == true
            
            // If we hit a regraft point or transition between normal/regraft, draw the previous segment
            if currentIsRegraft != isRegraftSegment || currentIsRegraft {
                // Only draw segment if there are points to connect
                if i - 1 > currentSegmentStart {
                    // Draw the line for the completed segment
                    let segmentColor = isRegraftSegment ? Color.red : color
                    let segment = drawLineSegment(from: currentSegmentStart, to: i-1, in: geometry, color: segmentColor)
                        .stroke(segmentColor, lineWidth: 2)
                    segments.append(AnyView(segment))
                }
                
                // Start a new segment
                currentSegmentStart = i-1
                isRegraftSegment = currentIsRegraft
            }
        }
        
        // Draw the final segment only if there are points to connect
        if data.count - 1 > currentSegmentStart {
            let finalSegmentColor = isRegraftSegment ? Color.red : color
            let segment = drawLineSegment(from: currentSegmentStart, to: data.count-1, in: geometry, color: finalSegmentColor)
                .stroke(finalSegmentColor, lineWidth: 2)
            segments.append(AnyView(segment))
        }
        
        return segments
    }
    
    @ViewBuilder
    private func drawRegraftSegments(regraftIndices: [Int], geometry: GeometryProxy) -> some View {
        ZStack {
            // Draw area segments
            ForEach(0..<regraftIndices.count, id: \.self) { i in
                let regraftIndex = regraftIndices[i]
                let startIndex = i > 0 ? regraftIndices[i-1] : 0
                
                if regraftIndex > startIndex {
                    // Draw area for this segment
                    let segmentData = Array(data[startIndex..<regraftIndex])
                    drawAreaSegment(for: segmentData, in: geometry, color: color.opacity(0.1))
                        .fill(color.opacity(0.1))
                }
            }
            
            // Draw the final segment for area
            if let lastRegraftIndex = regraftIndices.last, lastRegraftIndex < data.count - 1 {
                let segmentData = Array(data[lastRegraftIndex..<data.count])
                drawAreaSegment(for: segmentData, in: geometry, color: Color.red.opacity(0.1))
                    .fill(Color.red.opacity(0.1))
            }
            
            // Draw line segments
            let lineSegments = createLineSegments(geometry: geometry)
            ForEach(0..<lineSegments.count, id: \.self) { index in
                lineSegments[index]
            }
        }
    }
    
    @ViewBuilder
    private func drawNormalSegments(geometry: GeometryProxy) -> some View {
        ZStack {
            // Area fill
            Path { path in
                let startX = calculateXPosition(index: 0, in: geometry)
                let startY = calculateYPosition(data[0].1, in: geometry)
                
                // Start at the bottom of the graph at the first x-position
                path.move(to: CGPoint(x: startX, y: geometry.size.height))
                // Draw line to the first data point
                path.addLine(to: CGPoint(x: startX, y: startY))
                
                // Draw lines to each data point
                for i in 1..<data.count {
                    let x = calculateXPosition(index: i, in: geometry)
                    let y = calculateYPosition(data[i].1, in: geometry)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                // Draw line to the bottom of the graph at the last x-position
                let lastX = calculateXPosition(index: data.count - 1, in: geometry)
                path.addLine(to: CGPoint(x: lastX, y: geometry.size.height))
                path.closeSubpath()
            }
            .fill(color.opacity(0.1))
            
            // Line connecting points
            Path { path in
                let startX = calculateXPosition(index: 0, in: geometry)
                let startY = calculateYPosition(data[0].1, in: geometry)
                
                path.move(to: CGPoint(x: startX, y: startY))
                
                for i in 1..<data.count {
                    let x = calculateXPosition(index: i, in: geometry)
                    let y = calculateYPosition(data[i].1, in: geometry)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
} 