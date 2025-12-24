import SwiftUI

// MARK: - Lazy Loading Views for Performance
struct LazyChartView<Content: View>: View {
    let content: Content
    let isVisible: Bool
    
    init(isVisible: Bool, @ViewBuilder content: () -> Content) {
        self.isVisible = isVisible
        self.content = content()
    }
    
    var body: some View {
        if isVisible {
            content
        } else {
            // Placeholder view to maintain layout
            Rectangle()
                .fill(Color.clear)
                .frame(height: 200)
        }
    }
}

// MARK: - Optimized List View
struct OptimizedListView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    
    init(data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: AppConstants.cardSpacing) {
            ForEach(data) { item in
                content(item)
            }
        }
    }
}

// MARK: - Memory-Efficient Image Loading
struct OptimizedAsyncImage: View {
    let url: URL?
    let placeholder: String
    let width: CGFloat
    let height: CGFloat
    
    init(url: URL?, placeholder: String = "photo", width: CGFloat = 100, height: CGFloat = 100) {
        self.url = url
        self.placeholder = placeholder
        self.width = width
        self.height = height
    }
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            Image(systemName: placeholder)
                .foregroundColor(.gray)
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

// MARK: - Debounced Text Field for Search
struct DebouncedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let onTextChanged: (String) -> Void
    
    @State private var debounceTask: Task<Void, Never>?
    
    init(title: String, placeholder: String, text: Binding<String>, onTextChanged: @escaping (String) -> Void) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.onTextChanged = onTextChanged
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
            Text(title)
                .font(AppConstants.bodyFont)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: text) { _, newValue in
                    // Cancel previous task
                    debounceTask?.cancel()
                    
                    // Create new debounced task
                    debounceTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                        if !Task.isCancelled {
                            await MainActor.run {
                                onTextChanged(newValue)
                            }
                        }
                    }
                }
        }
    }
}

// MARK: - View State Management
class ViewStateManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError: Bool = false
    
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    func setError(_ message: String?) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.hasError = message != nil
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.hasError = false
        }
    }
}

// MARK: - Performance Monitoring
struct PerformanceMonitor {
    static func measureTime<T>(_ operation: () throws -> T) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    static func logPerformance(_ operation: String, duration: TimeInterval) {
        if duration > 0.1 { // Log operations taking more than 100ms
            print("⚠️ Performance: \(operation) took \(String(format: "%.3f", duration))s")
        }
    }
}

// MARK: - Memory Management Helpers
extension View {
    func onMemoryWarning(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            action()
        }
    }
    
    func optimizeForLargeDataSets() -> some View {
        self
            .drawingGroup() // Rasterize complex views
            .clipped() // Prevent overdraw
    }
}

// MARK: - Efficient Data Processing
struct DataProcessor {
    static func chunkArray<T>(_ array: [T], chunkSize: Int) -> [[T]] {
        return stride(from: 0, to: array.count, by: chunkSize).map {
            Array(array[$0..<min($0 + chunkSize, array.count)])
        }
    }
    
    static func processInBackground<T, U>(_ data: [T], transform: @escaping ([T]) -> [U], completion: @escaping ([U]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = transform(data)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

// MARK: - View Recycling for Large Lists
struct RecycledView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    let visibleRange: Range<Int>
    
    init(data: Data, visibleRange: Range<Int>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.visibleRange = visibleRange
        self.content = content
    }
    
    var body: some View {
        let visibleData = Array(data)[visibleRange]
        LazyVStack {
            ForEach(visibleData) { item in
                content(item)
            }
        }
    }
}
