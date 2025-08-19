//
//  AppViewModel.swift
//  打咔 (Daka)
//
//  应用主ViewModel - 管理全局状态
//  Created by CodeBuddy on 2025/8/18.
//

import Foundation
import SwiftUI

// MARK: - 应用主ViewModel
class AppViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var selectedTab: TabSelection = .camera
    @Published var currentTemplate: PoseTemplate?
    @Published var isFirstLaunch: Bool = true
    
    // MARK: - Tab选择枚举
    enum TabSelection: String, CaseIterable {
        case poseLibrary = "pose_library"
        case camera = "camera"
        case myTemplates = "my_templates"
        
        var title: String {
            switch self {
            case .poseLibrary: return "Pose库"
            case .camera: return "拍照"
            case .myTemplates: return "我的模板"
            }
        }
        
        var icon: String {
            switch self {
            case .poseLibrary: return "square.grid.2x2"
            case .camera: return "camera.fill"
            case .myTemplates: return "bookmark.fill"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .poseLibrary: return "square.grid.2x2.fill"
            case .camera: return "camera.fill"
            case .myTemplates: return "bookmark.fill"
            }
        }
    }
    
    // MARK: - Services
    private let storageService: StorageService
    
    // MARK: - Shared Instance (临时用于修复构建)
    static let shared: AppViewModel = {
        let storageService = StorageService()
        return AppViewModel(storageService: storageService)
    }()
    
    // MARK: - 初始化
    init(storageService: StorageService) {
        self.storageService = storageService
        super.init()
        setupInitialState()
    }
    
    // MARK: - 私有方法
    private func setupInitialState() {
        // 检查是否首次启动
        checkFirstLaunch()
        
        // 设置默认选中拍照Tab
        selectedTab = .camera
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        isFirstLaunch = !hasLaunchedBefore
        
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
    }
    
    // MARK: - 公共方法
    
    /// 切换Tab
    func selectTab(_ tab: TabSelection) {
        selectedTab = tab
    }
    
    /// 设置当前使用的模板
    func setCurrentTemplate(_ template: PoseTemplate) {
        currentTemplate = template
        // 自动切换到拍照Tab
        selectedTab = .camera
    }
    
    /// 清除当前模板
    func clearCurrentTemplate() {
        currentTemplate = nil
    }
}