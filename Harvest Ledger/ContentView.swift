import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Statistics")
                }
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Categories")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(Color(hex: "#F4B400")) // золотисто-жёлтый акцент
        .background(Color(hex: "#FFF8E6")) // светло-бежевый основной фон
    }
}

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: RecordStore
    
    @State private var showAddRecord: Bool = false
    @State private var selectedRecordType: RecordType = .income
    
    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
    }
    
    // Считаем баланс по текущим данным
    var balance: Double {
        let totalIncome = store.records.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = store.records.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return totalIncome - totalExpense
    }
    
    // Получаем данные расходов за последние 7 дней (дата + сумма)
    var last7DaysExpenses: [(String, Double)] {
        let calendar = Calendar.current
        var result: [(String, Double)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Например, 'Mon', 'Tue', для компактного отображения
        
        for offset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let dayStart = calendar.startOfDay(for: day)
                let total = store.records.filter {
                    $0.type == .expense && calendar.isDate($0.date, inSameDayAs: dayStart)
                }.reduce(0) { $0 + $1.amount }
                result.append((formatter.string(from: day), total))
            }
        }
        return result.reversed()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFF8E6")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Верхний бар с месяцем
                    HStack {
                        Text(monthYear.capitalized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#7A7A7A"))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Карточка баланса
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                            .frame(height: 150)
                        VStack(spacing: 12) {
                            Text("Balance")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#7A7A7A"))
                            Text(String(format: "%.2f ₽", balance))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#4CAF50"))
                                .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Кнопки Добавить доход / расход
                    HStack(spacing: 20) {
                        Button {
                            selectedRecordType = .income
                            showAddRecord = true
                        } label: {
                            Text("Add Income")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#F4B400"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(color: Color(hex: "#F4B400").opacity(0.6), radius: 7, x: 0, y: 4)
                        }
                        Button {
                            selectedRecordType = .expense
                            showAddRecord = true
                        } label: {
                            Text("Add Expense")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#F28C38"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(color: Color(hex: "#F28C38").opacity(0.6), radius: 7, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Weekly Expenses Chart")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#7A7A7A"))
                        .padding(.top)
                    
                    // Реальный график расходов за неделю
                    GeometryReader { geo in
                        let width = geo.size.width
                        let height = geo.size.height
                        
                        Path { path in
                            for idx in last7DaysExpenses.indices {
                                let x = CGFloat(idx) / CGFloat(last7DaysExpenses.count - 1) * width
                                let maxExpense = last7DaysExpenses.map { $0.1 }.max() ?? 1
                                let y = maxExpense > 0 ? height - CGFloat(last7DaysExpenses[idx].1 / maxExpense) * height : height
                                
                                if idx == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color(hex: "#E53935"), lineWidth: 3)
                        
                        // Опционально — добавить точки на графике
                        ForEach(last7DaysExpenses.indices, id: \.self) { idx in
                            let x = CGFloat(idx) / CGFloat(last7DaysExpenses.count - 1) * width
                            let maxExpense = last7DaysExpenses.map { $0.1 }.max() ?? 1
                            let y = maxExpense > 0 ? height - CGFloat(last7DaysExpenses[idx].1 / maxExpense) * height : height
                            
                            Circle()
                                .fill(Color(hex: "#E53935"))
                                .frame(width: 10, height: 10)
                                .position(x: x, y: y)
                        }
                    }
                    .frame(height: 150)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 6)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddRecord) {
                AddRecordView(recordType: selectedRecordType)
            }
        }
    }
}

import SwiftUI

// Модель одной операции
struct Record: Identifiable, Codable {
    let id: UUID
    let type: RecordType
    let category: Category
    let amount: Double
    let date: Date
    let comment: String?
}

enum RecordType: String, Codable {
    case income, expense
}

// UserDefaults ключи и хранилище
class RecordStore: ObservableObject {
    @Published var records: [Record] = []
    @Published var categories: [Category] = []

    private let recordsKey = "farmRecords"
    private let categoriesKey = "categoriesKey"

    init() {
        loadRecords()
        loadCategories()
    }

    func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else { return }
        if let decoded = try? JSONDecoder().decode([Record].self, from: data) {
            records = decoded.sorted { $0.date > $1.date }
        }
    }

    func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }

    func add(record: Record) {
        records.append(record)
        records.sort { $0.date > $1.date }
        saveRecords()
    }

    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        saveRecords()
    }

    // MARK: - Categories methods

    func loadCategories() {
        guard let data = UserDefaults.standard.data(forKey: categoriesKey) else {
            // Инициализация дефолтных категорий
            categories = [
                Category(name: "Feed", icon: "🪶", colorHex: "#4CAF50"),
                Category(name: "Egg Sales", icon: "🥚", colorHex: "#F28C38"),
                Category(name: "Equipment", icon: "🔧", colorHex: "#3E7BB6"),
                Category(name: "Transport", icon: "🚜", colorHex: "#3E7BB6"),
                Category(name: "Other", icon: "📦", colorHex: "#7A7A7A"),
            ]
            saveCategories()
            return
        }
        if let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            categories = decoded
        }
    }

    func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }

    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
        saveCategories()
    }

    func deleteCategory(_ id: UUID) {
        categories.removeAll { $0.id == id }
        saveCategories()
        // Дополнительно можно очистить записи с данной категорией, если нужно
    }
}


struct AddRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: RecordStore

    @State private var recordType: RecordType
    @State private var selectedCategory: Category = categories[0]
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var comment: String = ""

    @State private var showCoinAnimation = false

    init(recordType: RecordType) {
        _recordType = State(initialValue: recordType)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Picker("Type", selection: $recordType) {
                    Text("Income").tag(RecordType.income)
                    Text("Expense").tag(RecordType.expense)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: recordType) { _ in
                    // Можно менять категории под тип или сбрасывать выбор
                }

                Menu {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(store.categories) { category in
                            Text("\(category.icon) \(category.name)").tag(category)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory.icon)
                            .font(.largeTitle)
                        Text(selectedCategory.name)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)
                }

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)

                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)

                TextField("Comment (optional)", text: $comment)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)

                Button(action: saveRecord) {
                    Text("Save Record")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#F4B400"))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
                .disabled(!isAmountValid)

                Spacer()
            }
            .navigationTitle("Add Record")
            .background(Color(hex: "#FFF8E6").ignoresSafeArea())
            .overlay(coinAnimationOverlay)
        }
    }

    var isAmountValid: Bool {
        Double(amount) != nil && (Double(amount) ?? 0) > 0
    }

    private func saveRecord() {
        guard let amountValue = Double(amount) else { return }

        let newRecord = Record(
            id: UUID(),
            type: recordType,
            category: selectedCategory,
            amount: amountValue,
            date: date,
            comment: comment.isEmpty ? nil : comment
        )
        store.add(record: newRecord)

        withAnimation(.easeOut(duration: 1.2)) {
            showCoinAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showCoinAnimation = false
            presentationMode.wrappedValue.dismiss()
        }
    }

    @ViewBuilder
    private var coinAnimationOverlay: some View {
        if showCoinAnimation {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#F4B400"))
                .transition(.move(edge: .top).combined(with: .opacity))
                .offset(y: -200)
                .animation(.easeOut(duration: 1.2), value: showCoinAnimation)
        }
    }
}

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: RecordStore

    @State private var filterType: RecordType? = nil  // nil = все
    @State private var filterCategory: Category? = nil
    @State private var searchText: String = ""

    var filteredRecords: [Record] {
        var filtered = store.records
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }
        if let category = filterCategory {
            filtered = filtered.filter { $0.category.id == category.id }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.comment?.lowercased().contains(searchText.lowercased()) ?? false) ||
                $0.category.name.lowercased().contains(searchText.lowercased())
            }
        }
        return filtered
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.category.icon)
                                    .font(.title2)
                                Text(record.category.name)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(String(format: "%@ %.2f ₽", record.type == .income ? "+" : "−", record.amount))
                                    .foregroundColor(record.type == .income ? Color(hex: "#4CAF50") : Color(hex: "#E53935"))
                                    .fontWeight(.bold)
                            }
                            Text(record.date, style: .date)
                                .font(.caption)
                                .foregroundColor(Color(hex: "#7A7A7A"))
                            if let comment = record.comment {
                                Text(comment)
                                    .font(.caption2)
                                    .foregroundColor(Color(hex: "#7A7A7A"))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        // Для удаления — можно добавить swipe actions с iOS 15+
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(record)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(hex: "#FFF8E6").ignoresSafeArea())
            .navigationTitle("History")
            .searchable(text: $searchText, placement: .automatic)
        }
    }

    private func delete(_ record: Record) {
        store.delete(id: record.id)
    }
}



// Категория модели и список с иконками и цветами
struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String

    init(id: UUID = UUID(), name: String, icon: String, colorHex: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}



// Пример категорий для выборки
let categories = [
    Category(name: "Feed", icon: "🪶", colorHex: "#4CAF50"),
    Category(name: "Egg Sales", icon: "🥚", colorHex: "#F28C38"),
    Category(name: "Equipment", icon: "🔧", colorHex: "#3E7BB6"),
    Category(name: "Transport", icon: "🚜", colorHex: "#3E7BB6"),
    Category(name: "Other", icon: "📦", colorHex: "#7A7A7A"),
]

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var store: RecordStore
    
    var expenseByCategory: [(Category, Double)] {
        let filtered = store.records.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        let mapped = grouped.map { (category, records) -> (Category, Double) in
            let totalAmount = records.reduce(0) { $0 + $1.amount }
            return (category, totalAmount)
        }
        return mapped.sorted { $0.1 > $1.1 }
    }

    var topCategoriesByFrequency: [(Category, Int)] {
        let grouped = Dictionary(grouping: store.records, by: { $0.category })
        let mapped = grouped.map { (category, records) -> (Category, Int) in
            return (category, records.count)
        }
        return mapped.sorted { $0.1 > $1.1 }
    }

    var totalOperationsCount: Int {
        store.records.count
    }

    var totalExpense: Double {
        expenseByCategory.reduce(0) { $0 + $1.1 }
    }

    var totalProfit: Double {
        totalIncome - totalExpense
    }
    
    // Данные для линейного графика — доходы и расходы по дням
    var dailyData: [(String, Double, Double)] {
        let calendar = Calendar.current
        var result: [(String, Double, Double)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"

        for offset in 0..<30 {
            if let day = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let dayStart = calendar.startOfDay(for: day)
                let incomeSum = store.records.filter {
                    $0.type == .income && calendar.isDate($0.date, inSameDayAs: dayStart)
                }.reduce(0) { $0 + $1.amount }
                let expenseSum = store.records.filter {
                    $0.type == .expense && calendar.isDate($0.date, inSameDayAs: dayStart)
                }.reduce(0) { $0 + $1.amount }

                result.append((formatter.string(from: day), incomeSum, expenseSum))
            }
        }

        return result.reversed()
    }

    var totalIncome: Double {
        store.records.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }


    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Statistics")
                    .font(.largeTitle)
                    .padding(.top)

                // Топ категории
                VStack(alignment: .leading) {
                    Text("Top Categories")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(topCategoriesByFrequency.prefix(3), id: \.0.id) { item in
                        let percent = totalOperationsCount > 0 ? Double(item.1) / Double(totalOperationsCount) : 0
                        HStack {
                            Text("\(item.0.icon) \(item.0.name)")
                            Spacer()
                            Text(String(format: "%.0f%%", percent * 100))
                        }
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                        .padding(.horizontal)
                    }
                }

                // Линейный график доходов и расходов
                GeometryReader { geo in
                    ZStack {
                        // Линия доходов
                        Path { path in
                            for (index, day) in dailyData.enumerated() {
                                let x = CGFloat(index) / CGFloat(dailyData.count - 1) * geo.size.width
                                let maxIncome = dailyData.map { $0.1 }.max() ?? 1
                                let y = maxIncome > 0 ? geo.size.height * CGFloat(1 - day.1 / maxIncome) : geo.size.height
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color(hex: "#4CAF50"), lineWidth: 2)

                        // Линия расходов
                        Path { path in
                            for (index, day) in dailyData.enumerated() {
                                let x = CGFloat(index) / CGFloat(dailyData.count - 1) * geo.size.width
                                let maxExpense = dailyData.map { $0.2 }.max() ?? 1
                                let y = maxExpense > 0 ? geo.size.height * CGFloat(1 - day.2 / maxExpense) : geo.size.height
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color(hex: "#E53935"), lineWidth: 2)
                    }
                }
                .frame(height: 150)
                .padding()

                VStack(spacing: 8) {
                    HStack {
                        Text("Income:")
                        Spacer()
                        Text(String(format: "+ %.2f ₽", totalIncome))
                            .foregroundColor(Color(hex: "#4CAF50"))
                    }
                    HStack {
                        Text("Expense:")
                        Spacer()
                        Text(String(format: "− %.2f ₽", totalExpense))
                            .foregroundColor(Color(hex: "#E53935"))
                    }
                    HStack {
                        Text("Profit:")
                        Spacer()
                        Text(String(format: "%.2f ₽", totalProfit))
                            .foregroundColor(totalProfit >= 0 ? Color(hex: "#4CAF50") : Color(hex: "#E53935"))
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal)

                Button(action: {
                    exportStatisticsToPDF()
                }) {
                    Text("Export PDF Report")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#F4B400"))
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(hex: "#FFF8E6").ignoresSafeArea())
    }
    
    func exportStatisticsToPDF() {
        let pdfMetaData = [kCGPDFContextCreator: "Harvest Ledger", kCGPDFContextAuthor: "Me"]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            let title = "Statistics Report"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)

            let body = """
            Total Income: \(totalIncome)
            Total Expense: \(totalExpense)
            Total Profit: \(totalProfit)
            """
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16)
            ]
            body.draw(at: CGPoint(x: 20, y: 60), withAttributes: bodyAttributes)
            // Здесь можно добавить реализацию рисования графиков в PDF, если нужно
        }
        // Сохранить или поделиться PDF
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("StatisticsReport.pdf")
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activityVC, animated: true, completion: nil)
            }
        } catch {
            print("Ошибка сохранения PDF: \(error)")
        }
    }
}

struct PieSliceView: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2
            Path { path in
                path.move(to: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                path.addArc(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
                            radius: radius,
                            startAngle: Angle(degrees: startAngle - 90),
                            endAngle: Angle(degrees: endAngle - 90),
                            clockwise: false)
            }
            .fill(color)
        }
    }
}

// Хелпер для цветов из hex (если не вставляли ранее)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        if hex.count == 6 {
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        } else {
            (r, g, b) = (1,1,0)
        }
        self.init(
            .sRGB,
            red: Double(r)/255,
            green: Double(g)/255,
            blue: Double(b)/255,
            opacity: 1
        )
    }
}

struct CategoriesView: View {
    @EnvironmentObject var store: RecordStore

    @State private var showingAddCategory = false
    @State private var editingCategory: Category?

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFF8E6").ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(store.categories) { category in
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: category.colorHex))
                                        .frame(width: 48, height: 48)
                                    Text(category.icon)
                                        .font(.title2)
                                }
                                Text(category.name)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                            .contentShape(Rectangle())  // Чтобы тап работал по всей карте
                            .onTapGesture {
                                editingCategory = category
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.deleteCategory(category.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#F4B400"))
                }
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditView(category: category)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView()
                    .environmentObject(store)
            }
        }
    }
}


// View для добавления или редактирования категории
struct CategoryEditView: View {
    @EnvironmentObject var store: RecordStore
    @Environment(\.presentationMode) var presentationMode

    @State var category: Category
    @State private var name: String = ""
    @State private var icon: String = ""
    @State private var colorHex: String = "#F4B400" // по умолчанию золотисто-жёлтый

    init(category: Category? = nil) {
        if let category = category {
            _category = State(initialValue: category)
            _name = State(initialValue: category.name)
            _icon = State(initialValue: category.icon)
            _colorHex = State(initialValue: category.colorHex)
        } else {
            _category = State(initialValue: Category(name: "", icon: "", colorHex: "#F4B400"))
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFF8E6").ignoresSafeArea() // Фоновый цвет

                Form {
                    Section(header: Text("Icon (emoji)")) {
                        TextField("Icon", text: $icon)
                            .font(.largeTitle)
                            .frame(height: 50)
                    }
                    Section(header: Text("Name")) {
                        TextField("Name", text: $name)
                    }
                    Section(header: Text("Color (hex)")) {
                        TextField("#F4B400", text: $colorHex)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textCase(.none)
                    }
                }
                .background(Color.clear) // Чтобы форма была прозрачная и фон виден
            }
            .navigationTitle(category.name.isEmpty ? "New Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || icon.isEmpty || !isValidHex(colorHex))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func saveCategory() {
        let updatedCategory = Category(id: category.id, name: name, icon: icon, colorHex: colorHex)
        store.updateCategory(updatedCategory)
    }

    private func isValidHex(_ hex: String) -> Bool {
        let r = try? NSRegularExpression(pattern: "^#[0-9A-Fa-f]{6}$")
        return (r?.firstMatch(in: hex, options: [], range: NSRange(location: 0, length: hex.count)) != nil)
    }
}

struct SettingsView: View {
    @AppStorage("appCurrency") private var appCurrency: String = "₽"
    @AppStorage("dateFormat") private var dateFormat: String = "dd.MM.yyyy"
    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = false
    @AppStorage("appTheme") private var appTheme: String = "Farmer"

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#FFF8E6")
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Reminders: Daily expense entry", isOn: $remindersEnabled)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        Button(action: openPrivacyPolicy) {
                            Text("Privacy Policy")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                        }

                        Button(action: openSupportURL) {
                            Text("Support")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 10)
            }
            .navigationTitle("Settings")
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://www.freeprivacypolicy.com/live/9d7a6e18-f2b8-4d8b-b691-c804f6f412d9") {
            UIApplication.shared.open(url)
        }
    }

    private func openSupportURL() {
        if let url = URL(string: "https://docs.google.com/document/d/e/2PACX-1vTQFyJiEKJaDEqSKKkmrkx3CNMc80joQ-eUZ_K4kJc-jQIScXoc_2p9PUgY6t1DWIORvUXAFoKOo7m1/pub") {
            UIApplication.shared.open(url)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(RecordStore())
}
