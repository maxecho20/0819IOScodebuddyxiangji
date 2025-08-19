//
//  BaseViewModel.swift
//  打咔 (Daka)
//
//  基础ViewModel - 提供通用功能
//  Created by CodeBuddy on 2025/8/18.
//

import Foundation
import Combine

// MARK: - 基础ViewModel协议
protocol BaseViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var hasError: Bool { get }
}

// MARK: - 基础ViewModel实现
class BaseViewModel: BaseViewModelProtocol {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    var hasError: Bool {
        return errorMessage != nil
    }
    
    internal var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - 通用方法
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    
    /// 设置错误信息
    func setError(_ message: String) {
        errorMessage = message
        isLoading = false
    }
    
    /// 开始加载
    func startLoading() {
        isLoading = true
        clearError()
    }
    
    /// 结束加载
    func stopLoading() {
        isLoading = false
    }
}

// MARK: - 应用状态管理
enum AppState {
    case idle           // 空闲状态
    case loading        // 加载中
    case success        // 成功
    case error(String)  // 错误状态
}