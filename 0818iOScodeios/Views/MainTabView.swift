//
//  MainTabView.swift
//  打咔 (Daka)
//
//  主导航界面 - 三Tab导航结构
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        TabView(selection: $appViewModel.selectedTab) {
            // Tab 1: Pose库
            PoseLibraryView()
                .tabItem {
                    Image(systemName: appViewModel.selectedTab == .poseLibrary ? 
                          AppViewModel.TabSelection.poseLibrary.selectedIcon : 
                          AppViewModel.TabSelection.poseLibrary.icon)
                    Text(AppViewModel.TabSelection.poseLibrary.title)
                }
                .tag(AppViewModel.TabSelection.poseLibrary)
            
            // Tab 2: 拍照 (核心功能)
            CameraView()
                .tabItem {
                    Image(systemName: AppViewModel.TabSelection.camera.icon)
                        .font(.system(size: 24, weight: .medium))
                    Text(AppViewModel.TabSelection.camera.title)
                }
                .tag(AppViewModel.TabSelection.camera)
            
            // Tab 3: 我的模板
            MyTemplatesView()
                .tabItem {
                    Image(systemName: appViewModel.selectedTab == .myTemplates ? 
                          AppViewModel.TabSelection.myTemplates.selectedIcon : 
                          AppViewModel.TabSelection.myTemplates.icon)
                    Text(AppViewModel.TabSelection.myTemplates.title)
                }
                .tag(AppViewModel.TabSelection.myTemplates)
        }
        .environmentObject(appViewModel)
        .accentColor(.pink) // 主题色：粉色，符合女性用户审美
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - 私有方法
    private func setupTabBarAppearance() {
        // 设置TabBar外观
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // 设置选中状态的颜色
        appearance.selectionIndicatorTintColor = UIColor.systemPink
        
        // 应用外观设置
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - 预览
#Preview {
    MainTabView()
}