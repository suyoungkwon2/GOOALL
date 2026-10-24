import Foundation
import HealthKit

/// HealthKit 접근 추상화 (F02-R7). v0.2에 지표가 늘면 이 프로토콜의 구현만 추가한다.
protocol HealthDataSource: AnyObject {
    var isAvailable: Bool { get }
    func requestAuthorization() async
    /// start..<end 합계. 기기가 잠겨 있는 등 읽을 수 없으면 throw (호출 측은 마지막 스냅샷 유지).
    func total(from start: Date, to end: Date) async throws -> Int
    /// 새 데이터가 들어오면 onUpdate를 부르고, 처리가 끝나면 넘겨받은 done을 호출해야 한다.
    func startObserving(onUpdate: @escaping @Sendable (_ done: @escaping @Sendable () -> Void) -> Void) async
}

/// MVP: 걸음 수 (F02-R1, R2, R4, R6)
final class HealthKitStepSource: HealthDataSource {
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType(.stepCount)
    private var observer: HKObserverQuery?
    private static let zeroValueErrors: Set<HKError.Code> = [
        .errorNoData, .errorAuthorizationNotDetermined, .errorAuthorizationDenied,
    ]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        try? await healthStore.requestAuthorization(toShare: [], read: [stepType])
    }

    func total(from start: Date, to end: Date) async throws -> Int {
        guard isAvailable else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        // 통계 쿼리가 아이폰·워치 소스를 병합해 중복을 제거한다 (F02-R6)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let statistics = try await descriptor.result(for: healthStore)
            return Int(statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        } catch let error as HKError where Self.zeroValueErrors.contains(error.code) {
            // 데이터 없음·권한 없음은 0으로 본다. 잠금(errorDatabaseInaccessible) 등은 throw해서 마지막 스냅샷을 유지한다.
            return 0
        }
    }

    func startObserving(onUpdate: @escaping @Sendable (_ done: @escaping @Sendable () -> Void) -> Void) async {
        guard isAvailable, observer == nil else { return }
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { @Sendable _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }
            onUpdate { completionHandler() }
        }
        observer = query
        healthStore.execute(query)
        try? await healthStore.enableBackgroundDelivery(for: stepType, frequency: .hourly)
    }
}
