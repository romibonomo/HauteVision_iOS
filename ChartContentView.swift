import SwiftUI

struct ChartContentView: View {
    let data: [(Date, Double, Bool)]
    let color: Color
    let selectedIndex: Int?
    let onSelectIndex: (Int) -> Void
    let forceShowAllPoints: Bool
    
    var body: some View {
        GeometryReader { geometry in
            // Move these outside ZStack for wider scope
            let range = getValueRange(data)
            let minValue = range.lowerBound
            let maxValue = range.upperBound
            let midValue = (maxValue + minValue) / 2
            let horizontalPadding: CGFloat = 20
            let availableWidth = geometry.size.width - 2 * horizontalPadding
            let calculateYPosition: (Double) -> CGFloat = { value in
                let chartHeight = geometry.size.height * 0.85
                let topPadding: CGFloat = 10
                let yScale = chartHeight / (maxValue - minValue)
                return topPadding + chartHeight - ((value - minValue) * yScale)
            }
            ZStack(alignment: .leading) {
                let chartHeight = geometry.size.height * 0.85
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width / 2, y: calculateYPosition(maxValue))
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width / 2, y: calculateYPosition(midValue))
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width / 2, y: calculateYPosition(minValue))
                let maxGridLines = forceShowAllPoints ? data.count : min(data.count, 7)
                let step = data.count > 1 ? max(1, data.count / maxGridLines) : 1
                ForEach(0..<data.count, id: \.self) { index in
                    if forceShowAllPoints || index % step == 0 || index == data.count - 1 {
                        let xPosition = horizontalPadding + CGFloat(index) / CGFloat(max(data.count - 1, 1)) * availableWidth
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 1, height: chartHeight)
                            .position(x: xPosition, y: calculateYPosition(data[index].1))
                    }
                }
                Path { path in
                    guard !data.isEmpty else { return }
                    var startPoint = CGPoint(
                        x: horizontalPadding,
                        y: calculateYPosition(data[0].1)
                    )
                    path.move(to: startPoint)
                    for i in 1..<data.count {
                        let point = CGPoint(
                            x: horizontalPadding + CGFloat(i) / CGFloat(max(data.count - 1, 1)) * availableWidth,
                            y: calculateYPosition(data[i].1)
                        )
                        let control1 = CGPoint(
                            x: startPoint.x + (point.x - startPoint.x) / 2,
                            y: startPoint.y
                        )
                        let control2 = CGPoint(
                            x: startPoint.x + (point.x - startPoint.x) / 2,
                            y: point.y
                        )
                        path.addCurve(to: point, control1: control1, control2: control2)
                        startPoint = point
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                Path { path in
                    guard !data.isEmpty else { return }
                    let chartHeight = geometry.size.height * 0.85
                    var startPoint = CGPoint(
                        x: horizontalPadding,
                        y: calculateYPosition(data[0].1)
                    )
                    path.move(to: CGPoint(x: startPoint.x, y: chartHeight + 10))
                    path.addLine(to: startPoint)
                    for i in 1..<data.count {
                        let point = CGPoint(
                            x: horizontalPadding + CGFloat(i) / CGFloat(max(data.count - 1, 1)) * availableWidth,
                            y: calculateYPosition(data[i].1)
                        )
                        let control1 = CGPoint(
                            x: startPoint.x + (point.x - startPoint.x) / 2,
                            y: startPoint.y
                        )
                        let control2 = CGPoint(
                            x: startPoint.x + (point.x - startPoint.x) / 2,
                            y: point.y
                        )
                        path.addCurve(to: point, control1: control1, control2: control2)
                        startPoint = point
                    }
                    path.addLine(to: CGPoint(x: horizontalPadding + availableWidth, y: chartHeight + 10))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .position(x: geometry.size.width / 2, y: calculateYPosition(maxValue))
                ForEach(0..<data.count, id: \.self) { index in
                    if forceShowAllPoints || index % step == 0 || index == data.count - 1 || index == (selectedIndex ?? -1) {
                        let xPosition = horizontalPadding + CGFloat(index) / CGFloat(max(data.count - 1, 1)) * availableWidth
                        let yPosition = calculateYPosition(data[index].1)
                        let point = CGPoint(x: xPosition, y: yPosition)
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .position(point)
                            .onTapGesture {
                                onSelectIndex(index)
                            }
                        if index == (selectedIndex ?? (data.count - 1)) {
                            Rectangle()
                                .fill(data[index].2 ? Color.red.opacity(0.3) : color.opacity(0.3))
                                .frame(width: 1, height: geometry.size.height * 0.85)
                                .position(x: point.x, y: calculateYPosition(data[index].1))
                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                                .position(point)
                            Circle()
                                .fill(data[index].2 ? .red : color)
                                .frame(width: 10, height: 10)
                                .position(point)
                        } else {
                            Circle()
                                .fill(data[index].2 ? Color.red.opacity(0.3) : color.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .position(point)
                        }
                    }
                }
            }
            .frame(height: 180)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !data.isEmpty else { return }
                        let adjustedX = value.location.x - horizontalPadding
                        let tapPositionFraction = adjustedX / availableWidth
                        let index = Int((tapPositionFraction * CGFloat(data.count - 1)).rounded())
                        if index >= 0 && index < data.count {
                            onSelectIndex(index)
                        }
                    }
            )
            Rectangle()
                .fill(Color.clear)
                .frame(height: 2)
        }
        .frame(height: 210)
    }
    // Helper to format dates for x-axis in a more compact way
    private func formatDateForXAxis(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    // Helper to get value range for chart
    private func getValueRange(_ data: [(Date, Double, Bool)]) -> ClosedRange<Double> {
        guard !data.isEmpty else { return 0...1 }
        let values = data.map { $0.1 }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        if minValue == maxValue {
            return (minValue - 0.5)...(maxValue + 0.5)
        }
        return minValue...maxValue
    }
} 
