//
//  MyTemplatesView.swift
//  打咔 (Daka)
//
//  我的模板界面 - 用户自创模板管理
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI

struct MyTemplatesView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = MyTemplatesViewModel()
    
    // 三栏网格布局配置 (类似相册)
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasTemplates {
                    // 有模板时显示网格
                    templatesGridView
                } else {
                    // 无模板时显示空状态
                    emptyStateView
                }
            }
            .navigationTitle("我的模板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.hasTemplates {
                        editButton
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .alert("删除模板", isPresented: $viewModel.showingDeleteAlert) {
                Button("删除", role: .destructive) {
                    viewModel.deleteSelectedTemplates()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除选中的 \(viewModel.selectedCount) 个模板吗？此操作无法撤销。")
            }
        }
    }
    
    // MARK: - 模板网格视图
    private var templatesGridView: some View {
        VStack(spacing: 0) {
            // 编辑模式工具栏
            if viewModel.isEditMode {
                editModeToolbar
            }
            
            // 模板网格
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.userTemplates) { template in
                        MyTemplateCard(
                            template: template,
                            isEditMode: viewModel.isEditMode,
                            isSelected: viewModel.selectedTemplates.contains(template.id)
                        ) {
                            if viewModel.isEditMode {
                                viewModel.toggleSelection(for: template.id)
                            } else {
                                // 点击模板，设置为当前模板并跳转到拍照
                                appViewModel.setCurrentTemplate(template)
                            }
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
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("还没有自创模板")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("在拍照界面选择照片，AI会帮你生成专属的姿势模板")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("开始创建") {
                appViewModel.selectTab(.camera)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 编辑按钮
    private var editButton: some View {
        Button(viewModel.isEditMode ? "完成" : "编辑") {
            viewModel.toggleEditMode()
        }
        .fontWeight(.medium)
    }
    
    // MARK: - 编辑模式工具栏
    private var editModeToolbar: some View {
        HStack {
            Button(viewModel.selectedTemplates.isEmpty ? "全选" : "取消全选") {
                if viewModel.selectedTemplates.isEmpty {
                    viewModel.selectAll()
                } else {
                    viewModel.deselectAll()
                }
            }
            .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Text("已选择 \(viewModel.selectedCount) 项")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("删除") {
                viewModel.confirmDelete()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
            .disabled(viewModel.selectedTemplates.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
        .border(Color(.separator), width: 0.5)
    }
}

// MARK: - 我的模板卡片
struct MyTemplateCard: View {
    let template: PoseTemplate
    let isEditMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 模板图片
                AsyncImage(url: URL(string: template.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                }
                .clipped()
                .cornerRadius(8)
                
                // 编辑模式覆盖层
                if isEditMode {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .cornerRadius(8)
                    
                    // 选择指示器
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(isSelected ? .blue : .white)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(isSelected ? 0 : 0.3))
                                )
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                
                // 分类标签 (非编辑模式)
                if !isEditMode {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: template.poseCategory.icon)
                                    .font(.system(size: 10))
                                Text(template.poseCategory.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.6))
                            )
                            
                            Spacer()
                        }
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        MyTemplatesView()
            .environmentObject(AppViewModel.shared)
    }
}