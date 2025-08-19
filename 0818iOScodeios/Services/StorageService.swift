//
//  StorageService.swift
//  打咔 (Daka)
//
//  本地存储服务 - iOS 16兼容版本
//  Created by CodeBuddy on 2025/8/18.
//

import Foundation
import UIKit
import Combine

// MARK: - 存储服务 (iOS 16兼容版本)
class StorageService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StorageService()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Keys
    private enum StorageKeys {
        static let userTemplates = "user_templates"
        static let favoriteTemplates = "favorite_templates"
        static let recentTemplates = "recent_templates"
    }
    
    // MARK: - Initialization
    init() {
        setupDirectories()
    }
    
    // MARK: - User Templates Management
    
    /// 保存用户模板
    func saveUserTemplate(_ template: PoseTemplate) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 保存图片到本地
            if let coverImage = await loadImage(from: template.thumbnailURL) {
                let coverImagePath = try await saveImage(coverImage, withID: template.id.uuidString + "_cover")
                let originalImagePath = try await saveImage(coverImage, withID: template.id.uuidString + "_original")
                
                // 创建本地模板
                let localTemplate = PoseTemplate(
                    id: template.id,
                    name: template.name,
                    category: template.category,
                    difficulty: PoseDifficulty(rawValue: template.difficulty) ?? .easy,
                    tags: template.tags,
                    thumbnailURL: coverImagePath,
                    outlineData: template.outline ?? OutlineData(keyPoints: [], boundingBox: .zero),
                    createdAt: template.createdAt,
                    isUserCreated: true
                )
                
                // 保存到UserDefaults
                try saveTemplateToUserDefaults(localTemplate)
                
            } else {
                throw StorageError.imageLoadFailed
            }
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// 获取用户模板
    func getUserTemplates() async throws -> [PoseTemplate] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try loadTemplatesFromUserDefaults()
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// 删除用户模板
    func deleteUserTemplate(_ template: PoseTemplate) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 删除本地图片文件
            try await deleteTemplateImages(template)
            
            // 从UserDefaults中删除
            try removeTemplateFromUserDefaults(template)
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// 批量删除用户模板
    func deleteUserTemplates(_ templates: [PoseTemplate]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        for template in templates {
            try await deleteUserTemplate(template)
        }
    }
    
    // MARK: - Favorites Management
    
    /// 添加到收藏
    func addToFavorites(_ templateId: UUID) {
        var favorites = getFavoriteTemplateIds()
        favorites.insert(templateId.uuidString)
        saveFavoriteTemplateIds(favorites)
    }
    
    /// 从收藏中移除
    func removeFromFavorites(_ templateId: UUID) {
        var favorites = getFavoriteTemplateIds()
        favorites.remove(templateId.uuidString)
        saveFavoriteTemplateIds(favorites)
    }
    
    /// 检查是否收藏
    func isFavorite(_ templateId: UUID) -> Bool {
        let favorites = getFavoriteTemplateIds()
        return favorites.contains(templateId.uuidString)
    }
    
    /// 获取收藏的模板ID列表
    func getFavoriteTemplateIds() -> Set<String> {
        let array = userDefaults.array(forKey: StorageKeys.favoriteTemplates) as? [String] ?? []
        return Set(array)
    }
    
    // MARK: - Recent Templates Management
    
    /// 添加到最近使用
    func addToRecent(_ templateId: UUID) {
        var recent = getRecentTemplateIds()
        recent.removeAll { $0 == templateId.uuidString } // 移除重复项
        recent.insert(templateId.uuidString, at: 0) // 添加到开头
        
        // 限制最近使用的数量
        if recent.count > 20 {
            recent = Array(recent.prefix(20))
        }
        
        saveRecentTemplateIds(recent)
    }
    
    /// 获取最近使用的模板ID列表
    func getRecentTemplateIds() -> [String] {
        return userDefaults.array(forKey: StorageKeys.recentTemplates) as? [String] ?? []
    }
    
    // MARK: - Image Management
    
    /// 保存图片到本地
    func saveImage(_ image: UIImage, withID id: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: StorageError.serviceUnavailable)
                    return
                }
                
                do {
                    let imageData = image.jpegData(compressionQuality: 0.8)
                    guard let data = imageData else {
                        continuation.resume(throwing: StorageError.imageCompressionFailed)
                        return
                    }
                    
                    let fileName = "\(id).jpg"
                    let fileURL = self.documentsDirectory.appendingPathComponent(fileName)
                    
                    try data.write(to: fileURL)
                    continuation.resume(returning: fileURL.path)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 从本地加载图片
    func loadImage(from path: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if path.hasPrefix("http") {
                    // 网络图片 - 这里应该实现网络下载逻辑
                    continuation.resume(returning: nil)
                } else {
                    // 本地图片
                    let image = UIImage(contentsOfFile: path)
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    /// 删除模板相关的图片文件
    private func deleteTemplateImages(_ template: PoseTemplate) async throws {
        let paths = [template.thumbnailURL]
        
        for path in paths {
            if !path.hasPrefix("http") { // 只删除本地文件
                let fileURL = URL(fileURLWithPath: path)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
    
    // MARK: - Private UserDefaults Methods
    
    private func saveTemplateToUserDefaults(_ template: PoseTemplate) throws {
        var templates = try loadTemplatesFromUserDefaults()
        
        // 移除已存在的同ID模板
        templates.removeAll { $0.id == template.id }
        
        // 添加新模板
        templates.append(template)
        
        // 保存到UserDefaults
        let encoder = JSONEncoder()
        let data = try encoder.encode(templates)
        userDefaults.set(data, forKey: StorageKeys.userTemplates)
    }
    
    private func loadTemplatesFromUserDefaults() throws -> [PoseTemplate] {
        guard let data = userDefaults.data(forKey: StorageKeys.userTemplates) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([PoseTemplate].self, from: data)
    }
    
    private func removeTemplateFromUserDefaults(_ template: PoseTemplate) throws {
        var templates = try loadTemplatesFromUserDefaults()
        templates.removeAll { $0.id == template.id }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(templates)
        userDefaults.set(data, forKey: StorageKeys.userTemplates)
    }
    
    private func saveFavoriteTemplateIds(_ favorites: Set<String>) {
        let array = Array(favorites)
        userDefaults.set(array, forKey: StorageKeys.favoriteTemplates)
    }
    
    private func saveRecentTemplateIds(_ recent: [String]) {
        userDefaults.set(recent, forKey: StorageKeys.recentTemplates)
    }
    
    // MARK: - Setup Methods
    
    private func setupDirectories() {
        // 确保文档目录存在
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Cache Management
    
    /// 清理缓存
    func clearCache() async {
        isLoading = true
        defer { isLoading = false }
        
        // 清理临时文件
        let tempDirectory = documentsDirectory.appendingPathComponent("temp")
        if fileManager.fileExists(atPath: tempDirectory.path) {
            try? fileManager.removeItem(at: tempDirectory)
        }
    }
    
    /// 获取缓存大小
    func getCacheSize() -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: documentsDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case imageLoadFailed
    case imageCompressionFailed
    case serviceUnavailable
    case fileNotFound
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "图片加载失败"
        case .imageCompressionFailed:
            return "图片压缩失败"
        case .serviceUnavailable:
            return "存储服务不可用"
        case .fileNotFound:
            return "文件未找到"
        case .encodingFailed:
            return "数据编码失败"
        case .decodingFailed:
            return "数据解码失败"
        }
    }
}