//
//  GOOALLApp.swift
//  GOOALL
//
//  Created by Mel Kwon on 10/24/26.
//

import SwiftUI
import UIKit

@main
struct GOOALLApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appDelegate.model)
        }
    }
}

/// 백그라운드 전달로 앱이 깨어날 때도 옵저버를 바로 다시 등록해야 해서 실행 시점에 시작한다 (F02-R4).
final class AppDelegate: NSObject, UIApplicationDelegate {
    let model = AppModel()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { await model.startBackgroundUpdates() }
        return true
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if model.onboarding.isCompleted {
                TodayView()
            } else {
                OnboardingView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // 앱이 열릴 때 즉시 갱신 (F02-R3)
            if phase == .active {
                Task { await model.refresh() }
            }
        }
    }
}
