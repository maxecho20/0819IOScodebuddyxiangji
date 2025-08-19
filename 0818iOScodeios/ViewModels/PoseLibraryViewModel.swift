//
//  PoseLibraryViewModel.swift
//  打咔 (Daka)
//
//  姿态库视图模型 - 官方模板管理
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI
import Combine

class PoseLibraryViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var templates: [PoseTemplate] = []
    @Published var selectedCategory: PoseCategory?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .newest
    
    // MARK: - Computed Properties
    var filteredTemplates: [PoseTemplate] {
        var result = templates
        
        // 分类筛选
        if let category = selectedCategory {
            result = result.filter { $0.poseCategory == category }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            result = result.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 排序
        switch sortOption {
        case .newest:
            result = result.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            result = result.sorted { $0.createdAt < $1.createdAt }
        case .nameAZ:
            result = result.sorted { $0.name < $1.name }
        case .nameZA:
            result = result.sorted { $0.name > $1.name }
        case .difficulty:
            result = result.sorted { $0.difficulty.rawValue < $1.difficulty.rawValue }
        }
        
        return result
    }
    
    // MARK: - Private Properties
    private let backendService = BackendService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadTemplates()
    }
    
    // MARK: - Public Methods
    
    func refreshTemplates() {
        loadTemplates()
    }
    
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
        sortOption = .newest
    }
    
    func selectTemplate(_ template: PoseTemplate) {
        // 这里可以添加选择模板的逻辑
        // 比如设置为当前模板，跳转到相机等
    }
    
    // MARK: - Private Methods
    
    private func loadTemplates() {
        isLoading = true
        
        Task {
            do {
                let loadedTemplates = try await backendService.fetchOfficialTemplates()
                
                await MainActor.run {
                    self.templates = loadedTemplates
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.setError(error)
                    self.isLoading = false
                    
                    // 如果网络加载失败，使用本地默认模板
                    self.loadDefaultTemplates()
                }
            }
        }
    }
    
    private func loadDefaultTemplates() {
        // 加载本地默认模板
        templates = PoseTemplates.defaultTemplates
    }
}

// MARK: - Sort Options
enum SortOption: String, CaseIterable {
    case newest = "最新"
    case oldest = "最早"
    case nameAZ = "名称A-Z"
    case nameZA = "名称Z-A"
    case difficulty = "难度"
    
    var icon: String {
        switch self {
        case .newest:
            return "clock.arrow.circlepath"
        case .oldest:
            return "clock"
        case .nameAZ:
            return "textformat.abc"
        case .nameZA:
            return "textformat.abc.dottedunderline"
        case .difficulty:
            return "star"
        }
    }
}