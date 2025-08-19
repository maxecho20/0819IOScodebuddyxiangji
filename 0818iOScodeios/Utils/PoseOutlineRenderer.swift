//
//  PoseOutlineRenderer.swift
//  打咔 (Daka)
//
//  人体姿态轮廓渲染器 - 实现精确的骨骼连线
//  Created by CodeBuddy on 2025/8/18.
//

import SwiftUI
import CoreGraphics

// MARK: - 人体关键点连接定义
struct PoseConnection {
    let from: Int
    let to: Int
    let color: Color
    let lineWidth: CGFloat
    
    init(from: Int, to: Int, color: Color = .white, lineWidth: CGFloat = 3.0) {
        self.from = from
        self.to = to
        self.color = color
        self.lineWidth = lineWidth
    }
}

// MARK: - 人体姿态轮廓渲染器
class PoseOutlineRenderer {
    
    // MARK: - MediaPipe Pose关键点索引 (33个关键点)
    enum PoseLandmark: Int, CaseIterable {
        case nose = 0
        case leftEyeInner = 1
        case leftEye = 2
        case leftEyeOuter = 3
        case rightEyeInner = 4
        case rightEye = 5
        case rightEyeOuter = 6
        case leftEar = 7
        case rightEar = 8
        case mouthLeft = 9
        case mouthRight = 10
        case leftShoulder = 11
        case rightShoulder = 12
        case leftElbow = 13
        case rightElbow = 14
        case leftWrist = 15
        case rightWrist = 16
        case leftPinky = 17
        case rightPinky = 18
        case leftIndex = 19
        case rightIndex = 20
        case leftThumb = 21
        case rightThumb = 22
        case leftHip = 23
        case rightHip = 24
        case leftKnee = 25
        case rightKnee = 26
        case leftAnkle = 27
        case rightAnkle = 28
        case leftHeel = 29
        case rightHeel = 30
        case leftFootIndex = 31
        case rightFootIndex = 32
    }
    
    // MARK: - 人体骨骼连接定义 (类似附件4的样式)
    static let poseConnections: [PoseConnection] = [
        // 头部连接
        PoseConnection(from: PoseLandmark.leftEar.rawValue, to: PoseLandmark.leftEye.rawValue, color: .cyan),
        PoseConnection(from: PoseLandmark.leftEye.rawValue, to: PoseLandmark.nose.rawValue, color: .cyan),
        PoseConnection(from: PoseLandmark.nose.rawValue, to: PoseLandmark.rightEye.rawValue, color: .cyan),
        PoseConnection(from: PoseLandmark.rightEye.rawValue, to: PoseLandmark.rightEar.rawValue, color: .cyan),
        
        // 躯干连接
        PoseConnection(from: PoseLandmark.leftShoulder.rawValue, to: PoseLandmark.rightShoulder.rawValue, color: .white, lineWidth: 4.0),
        PoseConnection(from: PoseLandmark.leftShoulder.rawValue, to: PoseLandmark.leftHip.rawValue, color: .white, lineWidth: 4.0),
        PoseConnection(from: PoseLandmark.rightShoulder.rawValue, to: PoseLandmark.rightHip.rawValue, color: .white, lineWidth: 4.0),
        PoseConnection(from: PoseLandmark.leftHip.rawValue, to: PoseLandmark.rightHip.rawValue, color: .white, lineWidth: 4.0),
        
        // 左臂连接
        PoseConnection(from: PoseLandmark.leftShoulder.rawValue, to: PoseLandmark.leftElbow.rawValue, color: .green, lineWidth: 3.5),
        PoseConnection(from: PoseLandmark.leftElbow.rawValue, to: PoseLandmark.leftWrist.rawValue, color: .green, lineWidth: 3.5),
        
        // 右臂连接
        PoseConnection(from: PoseLandmark.rightShoulder.rawValue, to: PoseLandmark.rightElbow.rawValue, color: .red, lineWidth: 3.5),
        PoseConnection(from: PoseLandmark.rightElbow.rawValue, to: PoseLandmark.rightWrist.rawValue, color: .red, lineWidth: 3.5),
        
        // 左手连接
        PoseConnection(from: PoseLandmark.leftWrist.rawValue, to: PoseLandmark.leftThumb.rawValue, color: .green),
        PoseConnection(from: PoseLandmark.leftWrist.rawValue, to: PoseLandmark.leftIndex.rawValue, color: .green),
        PoseConnection(from: PoseLandmark.leftWrist.rawValue, to: PoseLandmark.leftPinky.rawValue, color: .green),
        
        // 右手连接
        PoseConnection(from: PoseLandmark.rightWrist.rawValue, to: PoseLandmark.rightThumb.rawValue, color: .red),
        PoseConnection(from: PoseLandmark.rightWrist.rawValue, to: PoseLandmark.rightIndex.rawValue, color: .red),
        PoseConnection(from: PoseLandmark.rightWrist.rawValue, to: PoseLandmark.rightPinky.rawValue, color: .red),
        
        // 左腿连接
        PoseConnection(from: PoseLandmark.leftHip.rawValue, to: PoseLandmark.leftKnee.rawValue, color: .blue, lineWidth: 3.5),
        PoseConnection(from: PoseLandmark.leftKnee.rawValue, to: PoseLandmark.leftAnkle.rawValue, color: .blue, lineWidth: 3.5),
        
        // 右腿连接
        PoseConnection(from: PoseLandmark.rightHip.rawValue, to: PoseLandmark.rightKnee.rawValue, color: .orange, lineWidth: 3.5),
        PoseConnection(from: PoseLandmark.rightKnee.rawValue, to: PoseLandmark.rightAnkle.rawValue, color: .orange, lineWidth: 3.5),
        
        // 左脚连接
        PoseConnection(from: PoseLandmark.leftAnkle.rawValue, to: PoseLandmark.leftHeel.rawValue, color: .blue),
        PoseConnection(from: PoseLandmark.leftAnkle.rawValue, to: PoseLandmark.leftFootIndex.rawValue, color: .blue),
        
        // 右脚连接
        PoseConnection(from: PoseLandmark.rightAnkle.rawValue, to: PoseLandmark.rightHeel.rawValue, color: .orange),
        PoseConnection(from: PoseLandmark.rightAnkle.rawValue, to: PoseLandmark.rightFootIndex.rawValue, color: .orange),
    ]
    
    // MARK: - 渲染方法
    
    /// 在Canvas中绘制姿态轮廓
    static func drawPoseOutline(
        context: GraphicsContext,
        size: CGSize,
        keyPoints: [OutlinePoint],
        isMirrored: Bool = false,
        opacity: Double = 0.8
    ) {
        guard keyPoints.count >= 33 else { return }
        
        // 绘制骨骼连线
        for connection in poseConnections {
            guard connection.from < keyPoints.count,
                  connection.to < keyPoints.count else { continue }
            
            let fromPoint = keyPoints[connection.from]
            let toPoint = keyPoints[connection.to]
            
            // 检查关键点置信度
            guard fromPoint.confidence > 0.5, toPoint.confidence > 0.5 else { continue }
            
            // 转换坐标
            let from = convertPoint(fromPoint, to: size, isMirrored: isMirrored)
            let to = convertPoint(toPoint, to: size, isMirrored: isMirrored)
            
            // 创建路径
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            
            // 绘制连线
            context.stroke(
                path,
                with: .color(connection.color.opacity(opacity)),
                style: StrokeStyle(
                    lineWidth: connection.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        
        // 绘制关键点
        drawKeyPoints(context: context, size: size, keyPoints: keyPoints, isMirrored: isMirrored, opacity: opacity)
    }
    
    /// 绘制关键点
    private static func drawKeyPoints(
        context: GraphicsContext,
        size: CGSize,
        keyPoints: [OutlinePoint],
        isMirrored: Bool,
        opacity: Double
    ) {
        for (index, point) in keyPoints.enumerated() {
            guard point.confidence > 0.5 else { continue }
            
            let position = convertPoint(point, to: size, isMirrored: isMirrored)
            let color = getKeyPointColor(for: index)
            let radius = getKeyPointRadius(for: index)
            
            // 绘制关键点
            let circle = Path { path in
                path.addEllipse(in: CGRect(
                    x: position.x - radius,
                    y: position.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }
            
            context.fill(circle, with: .color(color.opacity(opacity)))
            context.stroke(circle, with: .color(.white.opacity(opacity)), lineWidth: 1.5)
        }
    }
    
    /// 转换关键点坐标到屏幕坐标
    private static func convertPoint(
        _ point: OutlinePoint,
        to size: CGSize,
        isMirrored: Bool
    ) -> CGPoint {
        let x = isMirrored ? size.width * (1 - CGFloat(point.x)) : size.width * CGFloat(point.x)
        let y = size.height * CGFloat(point.y)
        return CGPoint(x: x, y: y)
    }
    
    /// 获取关键点颜色
    private static func getKeyPointColor(for index: Int) -> Color {
        switch index {
        case 0...10: return .cyan        // 头部
        case 11, 12: return .yellow      // 肩膀
        case 13, 15, 17, 19, 21: return .green   // 左臂和左手
        case 14, 16, 18, 20, 22: return .red     // 右臂和右手
        case 23, 24: return .purple      // 臀部
        case 25, 27, 29, 31: return .blue       // 左腿和左脚
        case 26, 28, 30, 32: return .orange     // 右腿和右脚
        default: return .white
        }
    }
    
    /// 获取关键点半径
    private static func getKeyPointRadius(for index: Int) -> CGFloat {
        switch index {
        case 0: return 6.0              // 鼻子
        case 11, 12, 23, 24: return 5.0 // 主要关节
        case 13, 14, 15, 16, 25, 26, 27, 28: return 4.0 // 次要关节
        default: return 3.0             // 其他点
        }
    }
    
    /// 创建姿态轮廓视图
    static func createPoseOutlineView(
        keyPoints: [OutlinePoint],
        isMirrored: Bool = false,
        opacity: Double = 0.8
    ) -> some View {
        Canvas { context, size in
            drawPoseOutline(
                context: context,
                size: size,
                keyPoints: keyPoints,
                isMirrored: isMirrored,
                opacity: opacity
            )
        }
        .allowsHitTesting(false)
    }
    
    /// 计算姿态匹配度
    static func calculatePoseMatchScore(
        currentPose: [OutlinePoint],
        templatePose: [OutlinePoint],
        threshold: Float = 0.1
    ) -> Float {
        guard currentPose.count == templatePose.count else { return 0.0 }
        
        var totalScore: Float = 0.0
        var validPoints = 0
        
        for i in 0..<min(currentPose.count, templatePose.count) {
            let current = currentPose[i]
            let template = templatePose[i]
            
            // 只计算置信度高的点
            guard current.confidence > 0.5, template.confidence > 0.5 else { continue }
            
            // 计算欧几里得距离
            let dx = current.x - template.x
            let dy = current.y - template.y
            let distance = sqrt(dx * dx + dy * dy)
            
            // 转换为相似度分数 (距离越小，分数越高)
            let similarity = max(0.0, 1.0 - distance / threshold)
            totalScore += similarity
            validPoints += 1
        }
        
        return validPoints > 0 ? totalScore / Float(validPoints) : 0.0
    }
}

// MARK: - SwiftUI扩展
extension View {
    /// 添加姿态轮廓覆盖层
    func poseOutlineOverlay(
        keyPoints: [OutlinePoint],
        isMirrored: Bool = false,
        opacity: Double = 0.8
    ) -> some View {
        self.overlay(
            PoseOutlineRenderer.createPoseOutlineView(
                keyPoints: keyPoints,
                isMirrored: isMirrored,
                opacity: opacity
            )
        )
    }
}