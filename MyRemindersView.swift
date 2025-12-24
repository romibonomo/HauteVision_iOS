import SwiftUI

struct MyRemindersView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedDate = Date()
    @State private var showingAddReminderSheet = false
    
    // Calendar configuration
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private var month: Date {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        return calendar.date(from: components)!
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar header
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: month))
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdaySymbol(for: index))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            CalendarDayView(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                                .onTapGesture {
                                    selectedDate = date
                                }
                        } else {
                            // Empty cell for days not in this month
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Selected day reminders
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(LocalizedStringKey.remindersFor.localized()) \(formattedSelectedDate())")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if hasRemindersForSelectedDate() {
                        ScrollView {
                            VStack(spacing: 12) {
                                // This would be replaced with actual reminders from a data source
                                ReminderItemView(title: "Eye Drops", time: "9:00 AM", isCompleted: true)
                                ReminderItemView(title: "Contact Lens Removal", time: "9:00 PM", isCompleted: false)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding(.top, 30)
                            
                            Text(LocalizedStringKey.noRemindersForThisDay.localized())
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text(LocalizedStringKey.remindersFunctionalityWillBeAdded.localized())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
                
                Spacer()
            }
            .background(Color(.systemGray6))
            .navigationTitle("My Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddReminderSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(true) // Disabled until functionality is implemented
                }
            }
            .sheet(isPresented: $showingAddReminderSheet) {
                Text(LocalizedStringKey.addReminderFunctionalityComingSoon.localized())
                    .padding()
            }
        }
    }
    
    // Helper functions for calendar
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: month) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: month) {
            selectedDate = newDate
        }
    }
    
    private func weekdaySymbol(for index: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        // Adjust index to match your calendar's first day of week
        let adjustedIndex = (index + calendar.firstWeekday - 1) % 7
        return symbols[adjustedIndex]
    }
    
    private func daysInMonth() -> [Date?] {
        var days = [Date?]()
        
        // Get the first day of the month
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        // Calculate the number of empty cells before the first day
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Add empty cells for days before the first of the month
        for _ in 0..<offsetDays {
            days.append(nil)
        }
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: month)!.count
        
        // Add a cell for each day of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Add empty cells to complete the last week if needed
        let remainingCells = 42 - days.count // 6 rows of 7 days
        if remainingCells > 0 && remainingCells < 7 {
            for _ in 0..<remainingCells {
                days.append(nil)
            }
        }
        
        return days
    }
    
    private func formattedSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private func hasRemindersForSelectedDate() -> Bool {
        // This would check a data source for reminders on the selected date
        // For now, just return true for today and false for other days
        return calendar.isDateInToday(selectedDate)
    }
}

// Calendar day view
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(height: 40)
            
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return Color.blue.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
}

// Reminder item view
struct ReminderItemView: View {
    let title: String
    let time: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isCompleted ? .gray : .primary)
                    .strikethrough(isCompleted)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct MyRemindersView_Previews: PreviewProvider {
    static var previews: some View {
        MyRemindersView()
            .environmentObject(AuthViewModel())
    }
} 
