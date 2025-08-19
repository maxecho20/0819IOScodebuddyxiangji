//
//  _818iOScodeiosApp.swift
//  0818iOScodeios
//
//  Created by MAXECHO on 2025/8/18.
//

//
//  _818iOScodeiosApp.swift
//  打咔 (Daka)
//
//  应用入口文件
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI

@main
struct _818iOScodeiosApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(AppViewModel(storageService: StorageService.shared))
        }
    }
}