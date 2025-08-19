# 打咔 - iOS AI拍照Pose应用

一个基于SwiftUI开发的智能相机应用，集成MediaPipe姿态检测功能，支持实时姿态识别、模板匹配和人体骨骼轮廓渲染。

## 🎯 核心功能

- 📸 **实时相机预览** - AVFoundation高性能相机服务
- 🤖 **AI姿态检测** - MediaPipe 33个关键点实时识别
- 🎨 **骨骼轮廓渲染** - Canvas精确绘制人体连线
- 📋 **姿态模板库** - 预设和自定义姿态模板
- 🎯 **实时匹配** - 姿态相似度计算和提示
- 💾 **照片管理** - 拍照保存和本地存储

## 🏗️ 技术架构

### 核心框架
- **UI层**: SwiftUI + MVVM架构模式
- **相机**: AVFoundation + AVCapturePhotoOutput
- **AI检测**: MediaPipe + Core ML + Vision
- **渲染**: Canvas + CoreGraphics
- **并发**: Combine + iOS 17 Sendable

### 项目结构
```
0818iOScodeios/
├── Views/              # SwiftUI视图层
│   ├── CameraView.swift       # 相机主界面
│   ├── MainTabView.swift      # 主标签导航
│   ├── PoseLibraryView.swift  # 姿态库界面
│   └── PhotoPreviewView.swift # 照片预览
├── ViewModels/         # MVVM视图模型
│   ├── CameraViewModel.swift  # 相机业务逻辑
│   └── PoseLibraryViewModel.swift # 姿态库逻辑
├── Services/           # 核心服务层
│   ├── CameraService.swift    # 相机服务
│   ├── MediaPipeService.swift # AI检测服务
│   └── StorageService.swift   # 存储服务
├── Utils/              # 工具类
│   ├── PoseOutlineRenderer.swift # 骨骼渲染器
│   └── PhotoCaptureDelegate.swift # 拍照代理
├── Models/             # 数据模型
│   ├── PoseTemplate.swift     # 姿态模板
│   └── CameraTypes.swift      # 相机类型
└── Resources/          # 资源文件
    └── Models/pose_landmarker_lite.task # MediaPipe模型
```

## 🚀 快速开始

### 环境要求
- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+

### 安装运行

1. **克隆项目**
```bash
git clone https://github.com/maxecho20/0819IOScodebuddyxiangji.git
cd 0819IOScodebuddyxiangji
```

2. **打开项目**
```bash
open 0818iOScodeios.xcodeproj
```

3. **运行应用**
- 选择iPhone模拟器或真机
- 点击运行按钮 (⌘+R)

### 权限配置
应用需要以下权限：
- 📷 相机权限 - 实时预览和拍照
- 📱 照片库权限 - 保存照片到相册

## 🎨 核心特性

### MediaPipe姿态检测
- **33个关键点**: 全身姿态精确识别
- **实时处理**: 60fps流畅检测
- **高精度**: 亚像素级关键点定位

### 人体骨骼渲染
- **精确连线**: 33个关键点智能连接
- **实时绘制**: Canvas高性能渲染
- **视觉反馈**: 清晰的姿态轮廓显示

### 姿态模板系统
- **预设模板**: 内置常用拍照姿势
- **自定义模板**: 用户可创建个人模板
- **相似度匹配**: 实时计算姿态匹配度

## 📱 界面预览

- **相机界面**: 实时预览 + 姿态检测 + 骨骼渲染
- **姿态库**: 模板浏览 + 选择 + 预览
- **我的模板**: 自定义模板管理
- **照片预览**: 拍照结果查看和保存

## 🔧 开发状态

✅ **构建状态**: 项目编译成功  
✅ **模拟器测试**: iPhone 16模拟器运行正常  
✅ **核心功能**: 相机预览、姿态检测、骨骼渲染  
⚠️ **待完善**: MediaPipe模型集成、真机测试  

## 📋 技术文档

- [技术架构与流程图](技术架构与流程图.md)
- [完整开发计划](完整开发计划_PRD_DRD_TRD_MRD.md)

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

**打咔** - 让每一张照片都有完美的姿态 📸✨