# iOS相机应用 - 姿态检测与模板匹配

这是一个基于SwiftUI开发的iOS相机应用，集成了MediaPipe姿态检测功能，支持实时姿态识别和模板匹配。

## 功能特性

- 📸 实时相机预览
- 🤖 MediaPipe姿态检测
- 📋 姿态模板库
- 🎯 实时姿态匹配
- 💾 照片保存与管理
- 🔄 自定义姿态模板

## 技术栈

- SwiftUI
- AVFoundation
- MediaPipe
- Combine
- Core ML

## 项目结构

```
0818iOScodeios/
├── Models/              # 数据模型
├── Views/               # UI视图
├── ViewModels/          # 视图模型
├── Services/            # 服务层
├── Utils/               # 工具类
├── Resources/           # 资源文件
└── Config/              # 配置文件
```

## 安装与运行

1. 克隆项目
```bash
git clone https://github.com/maxecho20/0819IOScodebuddyxiangji.git
```

2. 打开Xcode项目
```bash
open 0818iOScodeios.xcodeproj
```

3. 运行项目
- 选择目标设备或模拟器
- 点击运行按钮或按 Cmd+R

## 权限要求

- 相机权限：用于实时预览和拍照
- 照片库权限：用于保存照片

## 开发文档

详细的开发文档请参考：
- [技术架构与流程图](技术架构与流程图.md)
- [完整开发计划](完整开发计划_PRD_DRD_TRD_MRD.md)

## 许可证

MIT License