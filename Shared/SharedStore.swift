import Foundation

/// App Group UserDefaults 저장소 (DATA_MODEL §5). 디코딩 실패·키 없음은 nil.
nonisolated struct SharedStore: @unchecked Sendable {

    enum Key: String {
        case goalSettings
        case progressSnapshot
        case onboardingState
        case healthAuthRequested
        case schemaVersion
        #if DEBUG
        case debugMockSteps
        #endif
    }

    static let currentSchemaVersion = 1

    /// App Group 컨테이너를 못 열면(entitlement 누락 등) 표준 UserDefaults로 대체한다.
    static let shared = SharedStore(defaults: UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard)

    let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var goalSettings: GoalSettings? {
        get { load(GoalSettings.self, .goalSettings) }
        nonmutating set { save(newValue, .goalSettings) }
    }

    var progressSnapshot: ProgressSnapshot? {
        get { load(ProgressSnapshot.self, .progressSnapshot) }
        nonmutating set { save(newValue, .progressSnapshot) }
    }

    var onboardingState: OnboardingState? {
        get { load(OnboardingState.self, .onboardingState) }
        nonmutating set { save(newValue, .onboardingState) }
    }

    var healthAuthRequested: Bool {
        get { defaults.bool(forKey: Key.healthAuthRequested.rawValue) }
        nonmutating set { defaults.set(newValue, forKey: Key.healthAuthRequested.rawValue) }
    }

    var schemaVersion: Int? {
        defaults.object(forKey: Key.schemaVersion.rawValue) as? Int
    }

    #if DEBUG
    var debugMockSteps: Int? {
        get { defaults.object(forKey: Key.debugMockSteps.rawValue) as? Int }
        nonmutating set { defaults.set(newValue, forKey: Key.debugMockSteps.rawValue) }
    }
    #endif

    // MARK: - Codable helpers

    private func load<T: Decodable>(_ type: T.Type, _ key: Key) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T?, _ key: Key) {
        guard let value else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
        defaults.set(Self.currentSchemaVersion, forKey: Key.schemaVersion.rawValue)
    }
}
