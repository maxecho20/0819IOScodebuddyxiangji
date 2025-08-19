//
//  CameraView.swift
//  打咔 (Daka)
//
//  相机界面 - 实时姿态检测与拍照
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingImagePicker = false
    @State private var showingPhotoPreview = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 相机预览层
                CameraPreviewView(viewModel: viewModel)
                    .ignoresSafeArea()
                
                // UI覆盖层
                VStack {
                    // 顶部工具栏
                    topToolbar
                    
                    Spacer()
                    
                    // 底部控制栏
                    bottomControls
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // 姿态匹配提示
                if let currentTemplate = appViewModel.currentTemplate {
                    poseMatchingOverlay(template: currentTemplate)
                }
                
                // 加载状态
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.startCamera()
            }
            .onDisappear {
                viewModel.stopCamera()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    capturedImage = image
                    showingPhotoPreview = true
                }
            }
            .sheet(isPresented: $showingPhotoPreview) {
                if let image = capturedImage {
                    PhotoPreviewView(image: image) { template in
                        // 保存用户创建的模板
                        Task {
                            await appViewModel.saveUserTemplate(template)
                        }
                    }
                }
            }
            .alert("相机错误", isPresented: .constant(viewModel.hasError)) {
                Button("确定") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            // 闪光灯控制
            Button(action: viewModel.toggleFlash) {
                Image(systemName: flashIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            Spacer()
            
            // 当前模板信息
            if let template = appViewModel.currentTemplate {
                VStack(spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(template.poseCategory.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.5))
                )
            }
            
            Spacer()
            
            // 切换摄像头
            Button(action: viewModel.switchCamera) {
                Image(systemName: "camera.rotate")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
        }
    }
    
    // MARK: - 底部控制栏
    private var bottomControls: some View {
        HStack(spacing: 40) {
            // 相册按钮
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            // 拍照按钮
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 90, height: 90)
                }
            }
            .scaleEffect(viewModel.isCapturing ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isCapturing)
            
            // 模板选择按钮
            Button(action: { appViewModel.selectTab(.poseLibrary) }) {
                Image(systemName: "square.grid.3x3")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - 姿态匹配覆盖层
    private func poseMatchingOverlay(template: PoseTemplate) -> some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // 匹配度显示
                    VStack(spacing: 4) {
                        Text("匹配度")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(Int(viewModel.poseMatchScore * 100))%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(matchScoreColor)
                    }
                    
                    // 匹配状态指示器
                    Circle()
                        .fill(matchScoreColor)
                        .frame(width: 12, height: 12)
                        .scaleEffect(viewModel.poseMatchScore > 0.8 ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.poseMatchScore)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 150)
        }
    }
    
    // MARK: - 计算属性
    private var flashIcon: String {
        switch viewModel.flashMode {
        case .off:
            return "bolt.slash"
        case .on:
            return "bolt"
        case .auto:
            return "bolt.badge.a"
        @unknown default:
            return "bolt.slash"
        }
    }
    
    private var matchScoreColor: Color {
        let score = viewModel.poseMatchScore
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - 方法
    private func capturePhoto() {
        viewModel.capturePhoto { image in
            if let image = image {
                capturedImage = image
                showingPhotoPreview = true
            }
        }
    }
}

// MARK: - 相机预览视图
struct CameraPreviewView: UIViewRepresentable {
    let viewModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        viewModel.setupPreview(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新预览层布局
        viewModel.updatePreviewLayout()
    }
}

// MARK: - 加载覆盖层
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("处理中...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - 预览
#Preview {
    CameraView()
        .environmentObject(AppViewModel.shared)
}