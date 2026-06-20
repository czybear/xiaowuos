import Foundation

struct MemberProfile: Codable, Identifiable, Equatable {
    let id: String
    var displayName: String
    var avatarInitials: String
    var provider: LoginProvider
    var memberLevel: MemberLevel
    var source: MemberSource
    var enrolledCourses: [CourseTrack]
    var vipLevel: VIPLevel
    var growthPoints: Int
    var joinedAt: Date
}

enum LoginProvider: String, Codable {
    case wechat
    case officialAccountCode
    case preview

    var title: String {
        switch self {
        case .wechat:
            "微信"
        case .officialAccountCode:
            "验证码"
        case .preview:
            "开发预览"
        }
    }
}

enum MemberLevel: String, Codable {
    case basic
    case course
    case plus

    var title: String {
        switch self {
        case .basic:
            "普通会员"
        case .course:
            "课程会员"
        case .plus:
            "小悟 Plus"
        }
    }
}

enum VIPLevel: Int, Codable, CaseIterable, Identifiable {
    case vip0 = 0
    case vip3 = 3

    var id: Int { rawValue }

    var title: String {
        "VIP\(rawValue)"
    }

    var subtitle: String {
        switch self {
        case .vip0:
            "体验玩家"
        case .vip3:
            "初级包月玩家"
        }
    }

    var requiredGrowthPoints: Int {
        switch self {
        case .vip0:
            0
        case .vip3:
            300
        }
    }

    var benefits: [String] {
        switch self {
        case .vip0:
            ["体验健康看板", "体验跑步伴侣", "浏览课程介绍"]
        case .vip3:
            ["三门课程开通", "月度学习陪伴", "基础 PK 榜单"]
        }
    }
}

struct VIPGrowthPlan {
    static let nextDefinedLevel = VIPLevel.vip3

    static func progress(from points: Int) -> Double {
        guard nextDefinedLevel.requiredGrowthPoints > 0 else {
            return 1
        }

        let progress = Double(points) / Double(nextDefinedLevel.requiredGrowthPoints)
        return min(max(progress, 0), 1)
    }
}

enum MemberSource: String, Codable, CaseIterable, Identifiable {
    case direct
    case joint
    case channel
    case school
    case staff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .direct:
            "自招会员"
        case .joint:
            "联招会员"
        case .channel:
            "渠道会员"
        case .school:
            "校区会员"
        case .staff:
            "内部会员"
        }
    }
}

enum CourseTrack: String, Codable, CaseIterable, Identifiable {
    case scienceInnovation
    case futureMaker
    case artificialIntelligence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scienceInnovation:
            "科创启蒙"
        case .futureMaker:
            "未来创客"
        case .artificialIntelligence:
            "人工智能"
        }
    }

    var subtitle: String {
        switch self {
        case .scienceInnovation:
            "从观察、实验和表达开始，建立科学探究兴趣。"
        case .futureMaker:
            "围绕动手项目、结构搭建和创意作品完成学习闭环。"
        case .artificialIntelligence:
            "理解 AI 概念、提示词实践和智能应用创作。"
        }
    }

    var systemImage: String {
        switch self {
        case .scienceInnovation:
            "sparkles"
        case .futureMaker:
            "hammer.fill"
        case .artificialIntelligence:
            "brain.head.profile"
        }
    }
}
