import SwiftUI

struct RegisterSocietyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: IncParStore

    let initialSocietyName: String?
    let onSave: ((Society) -> Void)?

    @State private var societyName = ""
    @State private var city = ""
    @State private var state = ""
    @State private var pulsingStep: Int?
    @FocusState private var isCityFocused: Bool
    @FocusState private var isStateFocused: Bool
    @FocusState private var isNameFocused: Bool

    init(initialSocietyName: String? = nil, onSave: ((Society) -> Void)? = nil) {
        self.initialSocietyName = initialSocietyName
        self.onSave = onSave
        _societyName = State(initialValue: initialSocietyName ?? "")
    }

    private let indianStates = IndianStateCatalog.allStates
    private let indianCities = IndianCityCatalog.citiesByState
    private let curatedCities = IndianCityCatalog.curatedCitiesByState
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        stepChip(number: 1, title: "State", state: stepState(for: 1))
                        stepChip(number: 2, title: "City", state: stepState(for: 2))
                        stepChip(number: 3, title: "Name", state: stepState(for: 3))
                    }
                    .padding(.bottom, 4)

                    HStack(spacing: 6) {
                        progressSegment(for: 1)
                        progressSegment(for: 2)
                        progressSegment(for: 3)
                    }
                    .padding(.bottom, 2)
                    .onChange(of: activeProgressStep) { _, newStep in
                        triggerStepPulse(for: newStep)
                    }

                    ZStack(alignment: .topLeading) {
                        TextField("State", text: $state)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .focused($isStateFocused)
                            .padding(.bottom, showStateSuggestions ? 96 : 0)
                            .onChange(of: state) { _, newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if indianStates.contains(trimmed) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                        isStateFocused = false
                                        isCityFocused = true
                                    }
                                }
                            }

                        if showStateSuggestions {
                            stateSuggestionsPanel
                                .offset(y: 44)
                        }
                    }

                    if !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.green.opacity(0.85))

                            Text(state)
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                    }

                    ZStack(alignment: .topLeading) {
                        TextField("City", text: $city)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .focused($isCityFocused)
                            .disabled(state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .padding(.bottom, showCitySuggestions ? 88 : 0)
                            .onChange(of: city) { _, newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty && filteredCities.count == 1 && filteredCities.first == trimmed {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                                        isCityFocused = false
                                        isNameFocused = true
                                    }
                                }
                            }

                        if showCitySuggestions {
                            citySuggestionsPanel
                                .offset(y: 44)
                        }
                    }

                    TextField("Society Name", text: $societyName)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .focused($isNameFocused)
                } footer: {
                    Text("Saved locally. It will sync with the master file when the app is online.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Button("Save Society") {
                    let trimmedName = societyName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)
                    let newSociety = Society(name: trimmedName, city: trimmedCity, state: trimmedState)
                    store.addSociety(name: trimmedName, city: trimmedCity, state: trimmedState)
                    onSave?(newSociety)
                    dismiss()
                }
            }
            .navigationTitle("Register Society")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isStateFocused = true
                triggerStepPulse(for: activeProgressStep)
            }
        }
    }

    private enum StepChipState {
        case completed
        case current
        case pending
    }

    private var activeProgressStep: Int {
        let hasState = !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCity = !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasName = !societyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !hasState { return 1 }
        if !hasCity { return 2 }
        if !hasName { return 3 }
        return 3
    }

    private func stepState(for step: Int) -> StepChipState {
        let hasState = !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCity = !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasName = !societyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        switch step {
        case 1:
            return hasState ? .completed : .current
        case 2:
            if hasState && hasCity { return .completed }
            return hasState ? .current : .pending
        default:
            if hasState && hasCity && hasName { return .completed }
            return hasState && hasCity ? .current : .pending
        }
    }

    private func stepChip(number: Int, title: String, state: StepChipState) -> some View {
        let isCompleted = state == .completed
        let isCurrent = state == .current

        return HStack(spacing: 6) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.95),
                                    Color.green.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.cyan.opacity(0.18), radius: 6, y: 2)
                } else if isCurrent {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.88),
                                    Color.white.opacity(0.58)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(width: 18, height: 18)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold, design: .default))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .foregroundStyle(isCurrent ? Color.primary : Color.secondary)
            }

            Text(title)
                .font(.system(size: 11, weight: isCurrent || isCompleted ? .semibold : .medium, design: .default))
                .foregroundStyle(isCompleted ? Color.primary : isCurrent ? Color.primary.opacity(0.92) : Color.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(isCompleted ? .thinMaterial : .ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    isCompleted ? Color.cyan.opacity(0.24) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .shadow(color: isCompleted ? Color.cyan.opacity(0.10) : .black.opacity(0.04), radius: 8, y: 2)
    }

    private func progressSegment(for step: Int) -> some View {
        let status = stepState(for: step)
        let isCompleted = status == .completed
        let isCurrent = status == .current
        let width: CGFloat = isCompleted ? 1 : isCurrent ? 0.72 : 0.42
        let isPulsing = pulsingStep == step

        return Capsule(style: .continuous)
            .fill(
                isCompleted
                ? LinearGradient(
                    colors: [Color.cyan.opacity(0.88), Color.green.opacity(0.68)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : isCurrent
                ? LinearGradient(
                    colors: [Color.white.opacity(0.65), Color.white.opacity(0.40)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : LinearGradient(
                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .scaleEffect(x: width, y: 1, anchor: .leading)
            .scaleEffect(y: isPulsing ? 1.22 : 1, anchor: .center)
            .animation(
                .spring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.08),
                value: stepState(for: step)
            )
            .animation(
                .spring(response: 0.24, dampingFraction: 0.58, blendDuration: 0.02),
                value: isPulsing
            )
            .shadow(
                color: isCompleted ? Color.cyan.opacity(isPulsing ? 0.16 : 0.10) : .clear,
                radius: isPulsing ? 5 : 4,
                y: 1
            )
    }

    private func triggerStepPulse(for step: Int) {
        guard pulsingStep != step else { return }
        pulsingStep = step

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            guard pulsingStep == step else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.76, blendDuration: 0.04)) {
                pulsingStep = nil
            }
        }
    }

    private var filteredStates: [String] {
        let query = state.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return indianStates
        }

        return indianStates.filter { option in
            option.range(of: query, options: [.caseInsensitive, .anchored]) != nil
        }
    }

    private var filteredCities: [String] {
        let query = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let stateKey = state.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = curatedCities[stateKey] ?? indianCities[stateKey] ?? []

        guard !query.isEmpty else {
            return Array(source.prefix(5))
        }

        return source.filter { option in
            option.range(of: query, options: [.caseInsensitive, .anchored]) != nil
        }
    }

    private var showCitySuggestions: Bool {
        let hasState = !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasState && isCityFocused
    }

    private var showStateSuggestions: Bool {
        isStateFocused
    }

    private var citySuggestionsPanel: some View {
        suggestionPanel(
            title: nil,
            emptyMessage: state.isEmpty ? "Choose a state first" : "No city matches \"\(city)\"",
            options: Array(filteredCities.prefix(5)),
            onSelect: { option in
                withAnimation(.easeInOut(duration: 0.18)) {
                    city = option
                    isCityFocused = false
                }
            }
        )
    }

    private var stateSuggestionsPanel: some View {
        suggestionPanel(
            title: nil,
            emptyMessage: "No Indian state matches \"\(state)\"",
            options: Array(filteredStates.prefix(7)),
            onSelect: { option in
                withAnimation(.easeInOut(duration: 0.18)) {
                    state = option
                    isStateFocused = false
                }
            }
        )
    }

    private func suggestionPanel(
        title: String?,
        emptyMessage: String,
        options: [String],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            } else if options.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(emptyMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                onSelect(option)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "location")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary.opacity(0.75))

                                    Text(option)
                                        .font(.system(size: 14, weight: .regular, design: .default))
                                        .foregroundStyle(.primary)

                                    Spacer()
                                }
                                .padding(.vertical, 9)
                                .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)

                            if option != options.last {
                                Divider()
                                    .opacity(0.4)
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(maxHeight: 132)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        .padding(.top, 2)
    }
}

private enum IndianStateCatalog {
    static let allStates: [String] = [
        "Andhra Pradesh",
        "Arunachal Pradesh",
        "Assam",
        "Bihar",
        "Chhattisgarh",
        "Goa",
        "Gujarat",
        "Haryana",
        "Himachal Pradesh",
        "Jharkhand",
        "Karnataka",
        "Kerala",
        "Madhya Pradesh",
        "Maharashtra",
        "Manipur",
        "Meghalaya",
        "Mizoram",
        "Nagaland",
        "Odisha",
        "Punjab",
        "Rajasthan",
        "Sikkim",
        "Tamil Nadu",
        "Telangana",
        "Tripura",
        "Uttar Pradesh",
        "Uttarakhand",
        "West Bengal",
        "Andaman and Nicobar Islands",
        "Chandigarh",
        "Dadra and Nagar Haveli and Daman and Diu",
        "Delhi",
        "Jammu and Kashmir",
        "Ladakh",
        "Lakshadweep",
        "Puducherry"
    ]
}

private enum IndianCityCatalog {
    static let citiesByState: [String: [String]] = [
        "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Guntur", "Tirupati", "Kakinada"],
        "Arunachal Pradesh": ["Itanagar", "Naharlagun"],
        "Assam": ["Guwahati", "Dibrugarh", "Silchar", "Jorhat"],
        "Bihar": ["Patna", "Gaya", "Bhagalpur", "Muzaffarpur", "Darbhanga"],
        "Chhattisgarh": ["Raipur", "Bilaspur", "Bhilai", "Durg"],
        "Goa": ["Panaji", "Margao", "Vasco da Gama"],
        "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Jamnagar", "Bhavnagar", "Gandhinagar"],
        "Haryana": ["Faridabad", "Gurugram", "Panipat", "Hisar", "Rohtak", "Karnal"],
        "Himachal Pradesh": ["Shimla", "Mandi", "Solan", "Dharamshala"],
        "Jharkhand": ["Ranchi", "Jamshedpur", "Dhanbad", "Bokaro Steel City"],
        "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru", "Hubballi-Dharwad", "Belagavi", "Kalaburagi"],
        "Kerala": ["Kochi", "Thiruvananthapuram", "Kozhikode", "Thrissur", "Kollam", "Kannur"],
        "Madhya Pradesh": ["Indore", "Bhopal", "Jabalpur", "Gwalior", "Ujjain"],
        "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik", "Aurangabad", "Solapur", "Kolhapur", "Amravati", "Nanded"],
        "Manipur": ["Imphal"],
        "Meghalaya": ["Shillong", "Tura"],
        "Mizoram": ["Aizawl"],
        "Nagaland": ["Dimapur", "Kohima"],
        "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela", "Berhampur"],
        "Punjab": ["Amritsar", "Ludhiana", "Jalandhar", "Patiala", "Mohali"],
        "Rajasthan": ["Jaipur", "Jodhpur", "Kota", "Udaipur", "Ajmer", "Bikaner"],
        "Sikkim": ["Gangtok"],
        "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli", "Salem", "Tirunelveli", "Vellore", "Erode", "Thanjavur"],
        "Telangana": ["Hyderabad", "Warangal", "Karimnagar", "Nizamabad"],
        "Tripura": ["Agartala"],
        "Uttar Pradesh": ["Lucknow", "Kanpur", "Noida", "Agra", "Varanasi", "Prayagraj", "Ghaziabad", "Meerut", "Gorakhpur", "Bareilly", "Mathura"],
        "Uttarakhand": ["Dehradun", "Haridwar", "Roorkee", "Haldwani"],
        "West Bengal": ["Kolkata", "Siliguri", "Asansol", "Durgapur", "Howrah"],
        "Andaman and Nicobar Islands": ["Port Blair"],
        "Chandigarh": ["Chandigarh"],
        "Dadra and Nagar Haveli and Daman and Diu": ["Silvassa", "Daman"],
        "Delhi": ["New Delhi", "Delhi"],
        "Jammu and Kashmir": ["Srinagar", "Jammu"],
        "Ladakh": ["Leh", "Kargil"],
        "Lakshadweep": ["Kavaratti"],
        "Puducherry": ["Puducherry", "Karaikal", "Mahe", "Yanam"]
    ]

    static let curatedCitiesByState: [String: [String]] = [
        "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Tirupati"],
        "Assam": ["Guwahati", "Dibrugarh"],
        "Bihar": ["Patna", "Gaya", "Muzaffarpur"],
        "Chhattisgarh": ["Raipur", "Bilaspur"],
        "Delhi": ["New Delhi", "Delhi"],
        "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
        "Haryana": ["Gurugram", "Faridabad", "Panipat"],
        "Karnataka": ["Bengaluru", "Mysuru", "Mangaluru", "Hubballi-Dharwad"],
        "Kerala": ["Kochi", "Thiruvananthapuram", "Kozhikode"],
        "Madhya Pradesh": ["Indore", "Bhopal", "Jabalpur"],
        "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
        "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela"],
        "Punjab": ["Amritsar", "Ludhiana", "Jalandhar"],
        "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur"],
        "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli"],
        "Telangana": ["Hyderabad", "Warangal", "Karimnagar"],
        "Uttar Pradesh": ["Lucknow", "Noida", "Kanpur", "Agra"],
        "Uttarakhand": ["Dehradun", "Haridwar", "Roorkee"],
        "West Bengal": ["Kolkata", "Siliguri", "Asansol"]
    ]
}
