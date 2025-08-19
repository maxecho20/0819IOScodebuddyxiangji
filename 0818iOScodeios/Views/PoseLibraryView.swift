//
//  PoseLibraryView.swift
//  打咔 (Daka)
//
//  Pose库界面 - 官方模板展示
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI

struct PoseLibraryView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = PoseLibraryViewModel()
    
    // 网格布局配置 - 双栏瀑布流
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分类筛选栏
                CategoryFilterView(
                    selectedCategory: $viewModel.selectedCategory,
                    categories: PoseCategory.allCases
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // 模板网格
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredTemplates) { template in
                            PoseTemplateCard(template: template) {
                                // 点击模板，设置为当前模板并跳转到拍照
                                appViewModel.setCurrentTemplate(template)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    viewModel.refreshTemplates()
                }
            }
            .navigationTitle("Pose库")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清除筛选") {
                        viewModel.clearFilters()
                    }
                    .disabled(viewModel.selectedCategory == nil)
                }
            }
            .overlay {
                // 加载状态
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .alert("加载失败", isPresented: .constant(viewModel.hasError)) {
                Button("重试") {
                    viewModel.refreshTemplates()
                }
                Button("取消", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
        }
    }
}

// MARK: - 分类筛选视图
struct CategoryFilterView: View {
    @Binding var selectedCategory: PoseCategory?
    let categories: [PoseCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "全部" 选项
                CategoryChip(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }
                
                // 各分类选项
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: .blue
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - 分类筛选芯片
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(color, lineWidth: 1.5)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 模板卡片
struct PoseTemplateCard: View {
    let template: PoseTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 模板图片
                AsyncImage(url: URL(string: template.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(3/4, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(3/4, contentMode: .fill)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                }
                .clipped()
                .cornerRadius(12)
                
                // 模板信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: template.poseCategory.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        
                        Text(template.poseCategory.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !template.isUserCreated {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("加载中...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        PoseLibraryView()
            .environmentObject(AppViewModel.shared)
    }
}