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

import SwiftUI

struct NotificationView: View {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    
    private let lastDeniedKey = "lastNotificationDeniedDate"
    
    var isPortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
    
    var isLandscape: Bool {
        verticalSizeClass == .compact && horizontalSizeClass == .regular
    }
    
    var body: some View {
        VStack {
            if isPortrait {
                ZStack {
                    Image("BGforNotifications")
                        .resizable()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                                .font(.custom("Inter-Bold", size: 18))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            
                            Text("Stay tuned with best offers from\nour casino")
                                .font(.custom("Inter-Italic", size: 15))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 40)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                requestNotificationPermission()
                            }) {
                                Image("bonuses")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 350, height: 70)
                            }
                            
                            Button(action:{
                                saveDeniedDate()
                                presentationMode.wrappedValue.dismiss()
                                NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            }) {
                                Image("skip")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 320, height: 40)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            } else {
                ZStack {
                    Image("BGforNotificationsLandscape")
                        .resizable()
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                                    .font(.custom("Inter-Bold", size: 18))
                                    .foregroundStyle(.white)
                                
                                Text("Stay tuned with best offers from our casino")
                                    .font(.custom("Inter-Italic", size: 16))
                                    .foregroundStyle(Color.white)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 10) {
                                Button(action: {
                                    requestNotificationPermission()
                                }) {
                                    Image("bonuses")
                                        .resizable()
                                        .frame(width: 260, height: 50)
                                }
                                
                                Button(action:{
                                    saveDeniedDate()
                                    presentationMode.wrappedValue.dismiss()
                                    NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                                }) {
                                    Image("skip")
                                        .resizable()
                                        .frame(width: 240, height: 30)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": true])
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        saveDeniedDate()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .notificationPermissionResult, object: nil, userInfo: ["granted": false])
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            case .denied:
                presentationMode.wrappedValue.dismiss()
            case .authorized, .provisional, .ephemeral:
                print("razresheni")
            @unknown default:
                break
            }
        }
    }
    
    private func saveDeniedDate() {
        UserDefaults.standard.set(Date(), forKey: lastDeniedKey)
        print("Saved last denied date: \(Date())")
    }
}



struct URLModel: Identifiable, Equatable {
    let id = UUID()
    let urlString: String
}

struct LoadingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasCheckedAuthorization = false
    @State  var url: URLModel? = nil
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var conversionDataReceived: Bool = false
    @State var isNotif = false
    let lastDeniedKey = "lastNotificationDeniedDate"
    let configExpiresKey = "config_expires"
    let configUrlKey = "config_url"
    let configNoMoreRequestsKey = "config_no_more_requests"
    @State var isMain = false
    @State  var isRequestingConfig = false
    @StateObject  var networkMonitor = NetworkMonitor.shared
    @State var isInet = false
    @State private var hasHandledConversion = false
    
    var isPortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
    
    var isLandscape: Bool {
        verticalSizeClass == .compact && horizontalSizeClass == .regular
    }
    @State var urlFromNotification: String? = nil
    
    var body: some View {
        VStack {
            if isPortrait {
                ZStack {
                    Image("loading")
                        .resizable()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 50) {
                        Spacer()
                        
                        VStack(spacing: 30) {
                            Spacer()
                            
                            ProgressView()
                                .scaleEffect(3.0)
                                .padding(.top)
                                .tint(.white)
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 20)
                }
            } else {
                ZStack {
                    Image("BGforNotificationsLandscape")
                        .resizable()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        ProgressView()
                            .scaleEffect(3.0)
                            .tint(.white)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onReceive(networkMonitor.$isDisconnected) { disconnected in
            if disconnected {
                isInet = true
            } else {
            }
        }
        .fullScreenCover(item: $url) { item in
            Egg(urlString: item.urlString)
                .onReceive(NotificationCenter.default.publisher(for: .openUrlFromNotification)) { notification in
                    if let userInfo = notification.userInfo,
                       let url = userInfo["url"] as? String {
                        urlFromNotification = url
                    }
                }
                .fullScreenCover(isPresented: Binding<Bool>(
                    get: { urlFromNotification != nil },
                    set: { newValue in if !newValue { urlFromNotification = nil } }
                )) {
                    if let urlToOpen = urlFromNotification {
                        Egg(urlString: urlToOpen)
                            .ignoresSafeArea()
                    } else {
                    }
                }
                .ignoresSafeArea(.keyboard)
                .ignoresSafeArea()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openUrlFromNotification)) { notification in
            if let userInfo = notification.userInfo,
               let url = userInfo["url"] as? String {
                urlFromNotification = url
            }
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { urlFromNotification != nil },
            set: { newValue in if !newValue { urlFromNotification = nil } }
        )) {
            if let urlToOpen = urlFromNotification {
                Egg(urlString: urlToOpen)
                    .ignoresSafeArea()
            } else {
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .datraRecieved)) { notification in
            DispatchQueue.main.async {
                guard !isInet else { return }
                if !hasHandledConversion {
                    let isOrganic = UserDefaults.standard.bool(forKey: "is_organic_conversion")
                    if isOrganic {
                        isMain = true
                    } else {
                        checknotif()
                    }
                    hasHandledConversion = true
                } else {
                    print("Conversion event ignored due to recent handling")
                }
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .notificationPermissionResult)) { notification in
            req()
        }
        .fullScreenCover(isPresented: $isNotif) {
            NotificationView()
        }
        .fullScreenCover(isPresented: $isMain) {
            ContentView()
                .environmentObject(RecordStore())
        }
        .fullScreenCover(isPresented: $isInet) {
            NoInternet()
        }
    }
}

#Preview {
    LoadingView()
}


import Network
import Combine

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isDisconnected: Bool = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isDisconnected = (path.status != .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

import SwiftUI

extension View {
    func outlineText(color: Color, width: CGFloat) -> some View {
        modifier(StrokeModifier(strokeSize: width, strokeColor: color))
    }
}

struct StrokeModifier: ViewModifier {
    private let id = UUID()
    var strokeSize: CGFloat = 1
    var strokeColor: Color = .blue
    
    func body(content: Content) -> some View {
        content
            .padding(strokeSize*2)
            .background (Rectangle()
                .foregroundStyle(strokeColor)
                .mask({
                    outline(context: content)
                })
            )}
    
    func outline(context:Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
                if let text = context.resolveSymbol(id: id) {
                    layer.draw(text, at: .init(x: size.width/2, y: size.height/2))
                }
            }
        } symbols: {
            context.tag(id)
                .blur(radius: strokeSize)
        }
    }
}

extension LoadingView {
    func checknotif() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                if again() {
                    isNotif = true
                } else {
                    req()
                }
            case .denied:
                req()
            case .authorized, .provisional, .ephemeral:
                req()
            @unknown default:
                req()
            }
        }
    }
    
    func again() -> Bool {
        if let lastDenied = UserDefaults.standard.object(forKey: lastDeniedKey) as? Date {
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            return lastDenied < threeDaysAgo
        }
        return true
    }
    
    func req() {
        let configNoMoreRequestsKey = "config_no_more_requests"
        if UserDefaults.standard.bool(forKey: configNoMoreRequestsKey) {
            print("Config requests are disabled by flag, exiting sendConfigRequest")
            DispatchQueue.main.async {
                finishWithou()
            }
            return
        }

        guard let conversionDataJson = UserDefaults.standard.data(forKey: "conversion_data") else {
            print("Conversion data not found in UserDefaults")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                finishWithou()
            }
            return
        }

        guard var conversionData = (try? JSONSerialization.jsonObject(with: conversionDataJson, options: [])) as? [String: Any] else {
            print("Failed to deserialize conversion data")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                finishWithou()
            }
            return
        }

        conversionData["push_token"] = UserDefaults.standard.string(forKey: "fcmToken") ?? ""
        conversionData["af_id"] = UserDefaults.standard.string(forKey: "apps_flyer_id") ?? ""
        conversionData["bundle_id"] = "com.app.harvestleadgerrsharvest"
        conversionData["os"] = "iOS"
        conversionData["store_id"] = "6755046445"
        conversionData["locale"] = Locale.current.identifier
        conversionData["firebase_project_id"] = "7953984922"

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: conversionData, options: [])
                    let url = URL(string: "https://harrvestledger.com/config.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Request error: \(error)")
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                        finishWithou()
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response")
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                        finishWithou()
                    }
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("Server returned status code \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                        finishWithou()
                    }
                    return
                }

                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("Config response JSON: \(json)")
                            DispatchQueue.main.async {
                                handleResp(json)
                            }
                        }
                    } catch {
                        print("Failed to parse response JSON: \(error)")
                        DispatchQueue.main.async {
                            UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                            finishWithou()
                        }
                    }
                }
            }

            task.resume()
        } catch {
            print("Failed to serialize request body: \(error)")
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
                finishWithou()
            }
        }
    }

    func handleResp(_ jsonResponse: [String: Any]) {
        if let ok = jsonResponse["ok"] as? Bool, ok,
           let url = jsonResponse["url"] as? String,
           let expires = jsonResponse["expires"] as? TimeInterval {
            UserDefaults.standard.set(url, forKey: configUrlKey)
            UserDefaults.standard.set(expires, forKey: configExpiresKey)
            UserDefaults.standard.removeObject(forKey: configNoMoreRequestsKey)
            UserDefaults.standard.synchronize()
            
            guard urlFromNotification == nil else {
                return
            }
            self.url = URLModel(urlString: url)
            print("Config saved: url = \(url), expires = \(expires)")
            
        } else {
            UserDefaults.standard.set(true, forKey: configNoMoreRequestsKey)
            UserDefaults.standard.synchronize()
            print("No valid config or error received, further requests disabled")
            finishWithou()
        }
    }
    
    func finishWithou() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isMain = true
        }
    }
}

struct NoInternet: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
 
    var isPortrait: Bool {
        verticalSizeClass == .regular && horizontalSizeClass == .compact
    }
    
    var isLandscape: Bool {
        verticalSizeClass == .compact && horizontalSizeClass == .regular
    }
    
    
    var body: some View {
        VStack {
            if isPortrait {
                ZStack {
                    Image("inet")
                        .resizable()
                        .ignoresSafeArea()
                }
            } else {
                ZStack {
                    Image("BGforNotificationsLandscape")
                        .resizable()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(.error)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 170, height: 150)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 10)
                    }
                }
            }
        }
    }
}

import SwiftUI
import UIKit
@preconcurrency import WebKit

private var asdqw: String = {
    WKWebView().value(forKey: "userAgent") as? String ?? ""
}()

class CreateDetail: UIViewController, WKNavigationDelegate, WKUIDelegate {
    var czxasd: WKWebView!
    var newPopupWindow: WKWebView?
    private var lastRedirectURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func showControls() async {
        let configURL = UserDefaults.standard.string(forKey: "config_url") ?? ""
        let lastURLString = UserDefaults.standard.string(forKey: "lastURL")

        let initialURLString = lastURLString?.isEmpty == false ? lastURLString : configURL
        guard let initialURL = URL(string: initialURLString ?? "") else { return }
        
        loadCookie()

        await MainActor.run {
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
            webConfiguration.allowsInlineMediaPlayback = true

            let source: String = """
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.getElementsByTagName('head')[0].appendChild(meta);
            """
            let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            webConfiguration.userContentController.addUserScript(script)

            self.czxasd = WKWebView(frame: .zero, configuration: webConfiguration)
            self.czxasd.customUserAgent = asdqw
            self.czxasd.navigationDelegate = self
            self.czxasd.uiDelegate = self

            self.czxasd.scrollView.isScrollEnabled = true
            self.czxasd.scrollView.pinchGestureRecognizer?.isEnabled = false
            self.czxasd.scrollView.keyboardDismissMode = .interactive
            self.czxasd.scrollView.minimumZoomScale = 1.0
            self.czxasd.scrollView.maximumZoomScale = 1.0
            self.czxasd.allowsBackForwardNavigationGestures = true
            view.backgroundColor = .black
            self.view.addSubview(self.czxasd)
            self.czxasd.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.czxasd.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                self.czxasd.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
                self.czxasd.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                self.czxasd.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
            ])
            
            self.loadInfo(with: initialURL)
        }
    }

    
    func loadInfo(with url: URL) {
        czxasd.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        saveCookie()
        UserDefaults.standard.set(webView.url?.absoluteString, forKey: "lastURL")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorHTTPTooManyRedirects {
            if let url = lastRedirectURL {
                webView.load(URLRequest(url: url))
                return
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() {
            lastRedirectURL = url
            
            if scheme != "http" && scheme != "https" {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    if webView.canGoBack {
                        webView.goBack()
                    }
                    
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            let status = response.statusCode
            
            if (300...399).contains(status) {
                decisionHandler(.allow)
                return
            } else if status == 200 {
                if webView.superview == nil {
                    view.addSubview(webView)
                    
                    webView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                    ])
                }
                decisionHandler(.allow)
                return
            } else if status >= 400 {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func loadCookie() {
        let ud: UserDefaults = UserDefaults.standard
        let data: Data? = ud.object(forKey: "cookie") as? Data
        if let cookie = data {
            do {
                let datas: NSArray? = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: cookie)
                if let cookies = datas {
                    for c in cookies {
                        if let cookieObject = c as? HTTPCookie {
                            HTTPCookieStorage.shared.setCookie(cookieObject)
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func saveCookie() {
        let cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieJar.cookies {
            do {
                let data: Data = try NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false)
                let ud: UserDefaults = UserDefaults.standard
                ud.set(data, forKey: "cookie")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        DispatchQueue.main.async {
            decisionHandler(.grant)
        }
    }
}

struct Egg: UIViewControllerRepresentable {
    var urlString: String
    
    func makeUIViewController(context: Context) -> CreateDetail {
        let viewController = CreateDetail()
        UserDefaults.standard.set(urlString, forKey: "config_url")
        Task {
            await viewController.showControls()
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CreateDetail, context: Context) {}
}

extension CreateDetail {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
        newPopupWindow = nil
    }
}
