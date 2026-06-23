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
    var role: MemberRole?
    var realName: String?
    var birthday: Date?
    var gender: MemberGender?
    var city: String?
    var school: String?
    var grade: String?
    var learningGoal: String?
    var interests: [MemberInterest]?
    var guardianName: String?
    var guardianPhone: String?
}

enum LoginProvider: String, Codable {
    case wechat
    case officialAccountCode
    case inviteCode
    case device
    case preview

    var title: String {
        switch self {
        case .wechat:
            "微信"
        case .officialAccountCode:
            "验证码"
        case .inviteCode:
            "邀请码"
        case .device:
            "认证设备"
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

enum MemberRole: String, Codable, CaseIterable, Identifiable {
    case superAdmin
    case admin
    case student

    var id: String { rawValue }

    var title: String {
        switch self {
        case .superAdmin:
            "超级管理员"
        case .admin:
            "普通管理员"
        case .student:
            "学员"
        }
    }

    var featureGroups: [RoleFeatureGroup] {
        switch self {
        case .superAdmin:
            [
                RoleFeatureGroup(title: "平台管理", items: ["学员管理", "课程管理", "邀请码管理", "会员审核"]),
                RoleFeatureGroup(title: "运营控制", items: ["节点控制台", "任务队列", "日志查看", "手动同步"]),
                RoleFeatureGroup(title: "教学支持", items: ["学习记录", "番茄钟", "即时通讯", "成长与成就"])
            ]
        case .admin:
            [
                RoleFeatureGroup(title: "教学管理", items: ["学员管理", "课程查看", "学习记录", "老师点评"]),
                RoleFeatureGroup(title: "沟通协作", items: ["即时通讯", "班级通知", "番茄钟陪伴"]),
                RoleFeatureGroup(title: "数据查看", items: ["学员成长", "课程进度", "基础榜单"])
            ]
        case .student:
            [
                RoleFeatureGroup(title: "我的学习", items: ["我的课程", "番茄钟", "学习记录", "作品成长"]),
                RoleFeatureGroup(title: "我的运动", items: ["跑步", "跳绳", "健康看板"]),
                RoleFeatureGroup(title: "我的成长", items: ["VIP 成长", "成就系统", "即时通讯"])
            ]
        }
    }
}

struct RoleFeatureGroup: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let items: [String]
}

enum MemberGender: String, Codable, CaseIterable, Identifiable {
    case unspecified
    case boy
    case girl
    case adult

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unspecified:
            "未设置"
        case .boy:
            "男生"
        case .girl:
            "女生"
        case .adult:
            "成人学员"
        }
    }
}

enum MemberInterest: String, Codable, CaseIterable, Identifiable {
    case science
    case maker
    case ai
    case running
    case jumpRope
    case reading
    case drawing
    case math

    var id: String { rawValue }

    var title: String {
        switch self {
        case .science:
            "科学实验"
        case .maker:
            "创客制作"
        case .ai:
            "人工智能"
        case .running:
            "跑步"
        case .jumpRope:
            "跳绳"
        case .reading:
            "阅读"
        case .drawing:
            "绘画"
        case .math:
            "数学"
        }
    }
}

enum VIPLevel: Int, Codable, CaseIterable, Identifiable {
    case vip0 = 0
    case vip1 = 1
    case vip2 = 2
    case vip3 = 3
    case vip4 = 4
    case vip5 = 5
    case vip6 = 6
    case vip7 = 7
    case vip8 = 8
    case vip9 = 9
    case vip10 = 10
    case vip11 = 11
    case vip12 = 12

    var id: Int { rawValue }

    var title: String {
        "VIP\(rawValue)"
    }

    var subtitle: String {
        switch self {
        case .vip0:
            "体验玩家"
        case .vip1:
            "入门学员"
        case .vip2:
            "稳定学习者"
        case .vip3:
            "初级包月玩家"
        case .vip4:
            "进阶学员"
        case .vip5:
            "项目实践者"
        case .vip6:
            "成长达人"
        case .vip7:
            "创客先锋"
        case .vip8:
            "AI 实践家"
        case .vip9:
            "学习队长"
        case .vip10:
            "小悟专家"
        case .vip11:
            "荣誉导师"
        case .vip12:
            "传奇会员"
        }
    }

    var requiredGrowthPoints: Int {
        switch self {
        case .vip0:
            0
        case .vip1:
            60
        case .vip2:
            150
        case .vip3:
            300
        case .vip4:
            520
        case .vip5:
            800
        case .vip6:
            1_150
        case .vip7:
            1_600
        case .vip8:
            2_150
        case .vip9:
            2_800
        case .vip10:
            3_600
        case .vip11:
            4_600
        case .vip12:
            6_000
        }
    }

    var benefits: [String] {
        switch self {
        case .vip0:
            ["体验健康看板", "体验跑步", "浏览课程介绍"]
        case .vip1:
            ["开启学员档案", "记录学习成长", "基础番茄钟"]
        case .vip2:
            ["学习记录汇总", "课程提醒", "基础成就"]
        case .vip3:
            ["三门课程开通", "月度学习陪伴", "基础 PK 榜单"]
        case .vip4:
            ["作品记录", "老师点评汇总", "运动周报"]
        case .vip5:
            ["项目实践档案", "课程阶段徽章", "挑战任务"]
        case .vip6:
            ["成长报告", "专属学习建议", "高级榜单"]
        case .vip7:
            ["创客作品集", "班级荣誉", "主题挑战"]
        case .vip8:
            ["AI 实践任务", "提示词作品集", "智能学习建议"]
        case .vip9:
            ["小组协作", "学习队长标识", "专题 PK"]
        case .vip10:
            ["专家徽章", "高阶项目", "个性化复盘"]
        case .vip11:
            ["荣誉导师徽章", "助教任务", "公开作品页"]
        case .vip12:
            ["传奇会员标识", "年度荣誉", "全域成就展示"]
        }
    }
}

struct VIPGrowthPlan {
    static func currentLevel(from points: Int) -> VIPLevel {
        VIPLevel.allCases.last { points >= $0.requiredGrowthPoints } ?? .vip0
    }

    static func nextLevel(after level: VIPLevel) -> VIPLevel? {
        VIPLevel(rawValue: level.rawValue + 1)
    }

    static func progress(from points: Int, current level: VIPLevel) -> Double {
        guard let nextLevel = nextLevel(after: level) else {
            return 1
        }

        let currentRequirement = level.requiredGrowthPoints
        let needed = nextLevel.requiredGrowthPoints - currentRequirement
        guard needed > 0 else { return 1 }

        let progress = Double(points - currentRequirement) / Double(needed)
        return min(max(progress, 0), 1)
    }
}

struct MemberAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let isUnlocked: Bool
}

enum AchievementPlan {
    static func achievements(for member: MemberProfile) -> [MemberAchievement] {
        [
            MemberAchievement(
                id: "first-login",
                title: "初见小悟",
                subtitle: "完成首次登录",
                systemImage: "person.crop.circle.badge.checkmark",
                isUnlocked: true
            ),
            MemberAchievement(
                id: "course-member",
                title: "课程启航",
                subtitle: "开通至少 1 门课程",
                systemImage: "book.closed.fill",
                isUnlocked: member.enrolledCourses.isEmpty == false
            ),
            MemberAchievement(
                id: "vip3",
                title: "月度学员",
                subtitle: "达到 VIP3",
                systemImage: "star.circle.fill",
                isUnlocked: member.vipLevel.rawValue >= 3 || member.growthPoints >= VIPLevel.vip3.requiredGrowthPoints
            ),
            MemberAchievement(
                id: "runner",
                title: "跑步伙伴",
                subtitle: "完成 1 次跑步记录",
                systemImage: "figure.run.circle.fill",
                isUnlocked: false
            ),
            MemberAchievement(
                id: "pomodoro",
                title: "专注 25 分钟",
                subtitle: "完成 1 次番茄钟",
                systemImage: "timer.circle.fill",
                isUnlocked: false
            ),
            MemberAchievement(
                id: "maker-work",
                title: "作品初成",
                subtitle: "提交 1 个课程作品",
                systemImage: "hammer.circle.fill",
                isUnlocked: false
            )
        ]
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

    var targetAudience: String {
        switch self {
        case .scienceInnovation:
            "10 岁及以下学员"
        case .futureMaker:
            "11 岁及以上学员"
        case .artificialIntelligence:
            "成人学员"
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
