//
//  MyTemplatesViewModel.swift
//  打咔 (Daka)
//
//  我的模板视图模型 - 用户模板管理
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI
import Combine

class MyTemplatesViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var userTemplates: [PoseTemplate] = []
    @Published var isEditMode = false
    @Published var selectedTemplates: Set<UUID> = []
    @Published var showingDeleteAlert = false
    
    // MARK: - Computed Properties
    var hasTemplates: Bool {
        !userTemplates.isEmpty
    }
    
    var selectedCount: Int {
        selectedTemplates.count
    }
    
    // MARK: - Private Properties
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadUserTemplates()
        observeStorageChanges()
    }
    
    // MARK: - Public Methods
    
    func refreshTemplates() {
        loadUserTemplates()
    }
    
    func toggleEditMode() {
        isEditMode.toggle()
        if !isEditMode {
            selectedTemplates.removeAll()
        }
    }
    
    func toggleSelection(for templateId: UUID) {
        if selectedTemplates.contains(templateId) {
            selectedTemplates.remove(templateId)
        } else {
            selectedTemplates.insert(templateId)
        }
    }
    
    func selectAll() {
        selectedTemplates = Set(userTemplates.map { $0.id })
    }
    
    func deselectAll() {
        selectedTemplates.removeAll()
    }
    
    func confirmDelete() {
        guard !selectedTemplates.isEmpty else { return }
        showingDeleteAlert = true
    }
    
    func deleteSelectedTemplates() {
        let templatesToDelete = userTemplates.filter { selectedTemplates.contains($0.id) }
        
        Task {
            do {
                try await storageService.deleteUserTemplates(templatesToDelete)
                
                await MainActor.run {
                    self.selectedTemplates.removeAll()
                    self.isEditMode = false
                    self.loadUserTemplates()
                }
                
            } catch {
                await MainActor.run {
                    self.setError(error)
                }
            }
        }
    }
    
    func deleteTemplate(_ template: PoseTemplate) {
        Task {
            do {
                try await storageService.deleteUserTemplate(template)
                
                await MainActor.run {
                    self.loadUserTemplates()
                }
                
            } catch {
                await MainActor.run {
                    self.setError(error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUserTemplates() {
        isLoading = true
        
        Task {
            do {
                let templates = try await storageService.getUserTemplates()
                
                await MainActor.run {
                    self.userTemplates = templates.sorted { $0.createdAt > $1.createdAt }
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.setError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    private func observeStorageChanges() {
        // 监听存储服务的变化
        storageService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isStorageLoading in
                if !isStorageLoading {
                    // 存储操作完成，刷新数据
                    self?.loadUserTemplates()
                }
            }
            .store(in: &cancellables)
    }
}