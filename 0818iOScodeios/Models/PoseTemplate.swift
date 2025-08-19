//
//  PoseTemplate.swift
//  0818iOScodeios
//
//  Created by CodeBuddy on 2025/8/18.
//  iOS 16兼容版本 - 移除SwiftData依赖
//

import Foundation

// MARK: - Pose分类枚举
enum PoseCategory: String, CaseIterable, Codable {
    case fullBody = "全身照"
    case halfBody = "半身照" 
    case selfie = "自拍照"
    case couple = "情侣照"
    case group = "合照"
    case creative = "创意照"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .fullBody: return "person.fill"
        case .halfBody: return "person.crop.rectangle"
        case .selfie: return "camera.fill"
        case .couple: return "heart.fill"
        case .group: return "person.3.fill"
        case .creative: return "sparkles"
        }
    }
}

// MARK: - Pose难度枚举
enum PoseDifficulty: String, CaseIterable, Codable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange" 
        case .hard: return "red"
        }
    }
}

// MARK: - 轮廓点类型
enum OutlinePointType: String, Codable {
    case head = "head"
    case leftShoulder = "leftShoulder"
    case rightShoulder = "rightShoulder"
    case leftElbow = "leftElbow"
    case rightElbow = "rightElbow"
    case leftWrist = "leftWrist"
    case rightWrist = "rightWrist"
    case leftHip = "leftHip"
    case rightHip = "rightHip"
    case leftKnee = "leftKnee"
    case rightKnee = "rightKnee"
    case leftAnkle = "leftAnkle"
    case rightAnkle = "rightAnkle"
    case leftHand = "leftHand"
    case rightHand = "rightHand"
    case leftFoot = "leftFoot"
    case rightFoot = "rightFoot"
    case contour = "contour"
}

// MARK: - 轮廓点数据
struct OutlinePoint: Codable, Identifiable {
    let id: UUID
    let x: Float
    let y: Float
    let type: OutlinePointType
    let confidence: Float
    
    init(x: Float, y: Float, type: OutlinePointType, confidence: Float = 1.0) {
        self.id = UUID()
        self.x = x
        self.y = y
        self.type = type
        self.confidence = confidence
    }
}

// MARK: - 轮廓数据
struct OutlineData: Codable {
    let keyPoints: [OutlinePoint]
    let boundingBox: CGRect
    let confidence: Float
    
    init(keyPoints: [OutlinePoint], boundingBox: CGRect, confidence: Float = 0.9) {
        self.keyPoints = keyPoints
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

// MARK: - Pose模板数据模型 (iOS 16兼容版本)
class PoseTemplate: ObservableObject, Codable, Identifiable, Equatable {
    let id: UUID
    @Published var name: String
    @Published var category: String
    @Published var difficulty: String
    @Published var tags: [String]
    @Published var thumbnailURL: String
    @Published var outlineData: Data // 存储序列化的OutlineData
    @Published var createdAt: Date
    @Published var isUserCreated: Bool
    
    // Codable支持
    enum CodingKeys: String, CodingKey {
        case id, name, category, difficulty, tags, thumbnailURL, outlineData, createdAt, isUserCreated
    }
    
    init(id: UUID = UUID(), name: String, category: String, difficulty: PoseDifficulty, tags: [String], thumbnailURL: String, outlineData: OutlineData, createdAt: Date = Date(), isUserCreated: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.difficulty = difficulty.rawValue
        self.tags = tags
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.isUserCreated = isUserCreated
        
        // 序列化OutlineData
        do {
            self.outlineData = try JSONEncoder().encode(outlineData)
        } catch {
            print("Failed to encode outline data: \(error)")
            self.outlineData = Data()
        }
    }
    
    // Codable解码
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        tags = try container.decode([String].self, forKey: .tags)
        thumbnailURL = try container.decode(String.self, forKey: .thumbnailURL)
        outlineData = try container.decode(Data.self, forKey: .outlineData)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isUserCreated = try container.decode(Bool.self, forKey: .isUserCreated)
    }
    
    // Codable编码
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(tags, forKey: .tags)
        try container.encode(thumbnailURL, forKey: .thumbnailURL)
        try container.encode(outlineData, forKey: .outlineData)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isUserCreated, forKey: .isUserCreated)
    }
    
    // 获取反序列化的轮廓数据
    var outline: OutlineData? {
        do {
            return try JSONDecoder().decode(OutlineData.self, from: outlineData)
        } catch {
            print("Failed to decode outline data: \(error)")
            return nil
        }
    }
    
    // 获取分类枚举
    var poseCategory: PoseCategory {
        return PoseCategory(rawValue: category) ?? .fullBody
    }
    
    // 获取难度枚举
    var poseDifficulty: PoseDifficulty {
        return PoseDifficulty(rawValue: difficulty) ?? .easy
    }
    
    // Equatable协议实现
    static func == (lhs: PoseTemplate, rhs: PoseTemplate) -> Bool {
        return lhs.id == rhs.id
    }
}