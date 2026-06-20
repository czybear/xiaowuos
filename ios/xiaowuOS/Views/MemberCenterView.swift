import SwiftUI

struct MemberCenterView: View {
    @EnvironmentObject private var accountManager: AccountManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let member = accountManager.currentMember {
                        profileCard(member)
                        opsEntry
                        vipGrowthCard(member)
                        membershipCard
                        wechatStatusCard
                        signOutButton
                    } else {
                        MemberSignInView()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的")
        }
    }

    private func profileCard(_ member: MemberProfile) -> some View {
        HStack(spacing: 14) {
            Text(member.avatarInitials)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.orange, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(member.displayName)
                    .font(.headline)
                Text("\(member.memberLevel.title) · \(member.source.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(member.vipLevel.title) · \(member.vipLevel.subtitle) · \(member.provider.title)登录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var opsEntry: some View {
        NavigationLink {
            OpsDashboardView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "server.rack")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("节点控制台")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("查看 a/b/c、dashboard、Ollama、任务队列和日志。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func vipGrowthCard(_ member: MemberProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP 成长")
                        .font(.headline)
                    Text("\(member.vipLevel.title) · \(member.vipLevel.subtitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(member.growthPoints) 成长值")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            ProgressView(value: VIPGrowthPlan.progress(from: member.growthPoints))
                .tint(.orange)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP0")
                        .font(.caption.weight(.semibold))
                    Text("体验玩家")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("VIP3")
                        .font(.caption.weight(.semibold))
                    Text("初级包月玩家")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(member.vipLevel == .vip3 ? "已开启初级包月权益。VIP4 及以上先保留，等课程和服务包更清楚后再定。" : "VIP0 可体验核心功能；升级到 VIP3 后进入初级包月权益。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("会员权益", systemImage: "person.badge.shield.checkmark.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                MemberBenefitRow(systemImage: "heart.text.square.fill", title: "健康数据同步", value: "已开启")
                MemberBenefitRow(systemImage: "figure.run.circle.fill", title: "跑步伴侣", value: "已开启")
                MemberBenefitRow(systemImage: "graduationcap.fill", title: "三门课程", value: "\(accountManager.currentMember?.enrolledCourses.count ?? 0) 门")
                MemberBenefitRow(systemImage: "trophy.fill", title: "PK 与榜单", value: "规划中")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var wechatStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("微信联合登录", systemImage: "link.circle.fill")
                .font(.headline)

            Text("等待微信开放平台 AppID 后即可接入真授权。当前会员状态先保存在本机。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            accountManager.signOut()
        } label: {
            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct MemberSignInView: View {
    @EnvironmentObject private var accountManager: AccountManager
    @State private var phoneNumber = ""
    @State private var verificationCode = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 8) {
                    Text("登录小悟同学")
                        .font(.title2.weight(.semibold))
                    Text("登录后继续使用健康管理、跑步伴侣和后续 PK 榜单。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                TextField("手机号", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .padding(14)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 10) {
                    TextField("验证码", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding(14)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                    Button {
                        accountManager.requestOfficialAccountCode(phoneNumber: phoneNumber)
                    } label: {
                        Text("公众号收码")
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(width: 98)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button {
                    accountManager.signInWithOfficialAccountCode(phoneNumber: phoneNumber, code: verificationCode)
                } label: {
                    Label("验证码登录", systemImage: "checkmark.shield.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            VStack(spacing: 12) {
                Button {
                    accountManager.signInWithWeChat()
                } label: {
                    Label("微信联合登录", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    accountManager.signInForPreview()
                } label: {
                    Label("开发预览进入", systemImage: "person.fill.checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if let loginMessage = accountManager.loginMessage {
                Text(loginMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MemberBenefitRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MemberCenterView()
        .environmentObject(AccountManager())
}
