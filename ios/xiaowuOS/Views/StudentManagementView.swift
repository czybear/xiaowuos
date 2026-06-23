import SwiftUI

struct StudentManagementView: View {
    @StateObject private var viewModel = StudentRecordViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                filters
                studentList
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("学员管理")
        .task {
            if viewModel.records.isEmpty {
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("参考课时记")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(viewModel.records.count) 名学员")
                .font(.title2.weight(.semibold))
        }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            TextField("搜索学员 / 班级 / 状态", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(13)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Picker("班级", selection: $viewModel.selectedCourse) {
                Text("全部班级").tag("")
                ForEach(viewModel.courses, id: \.self) { course in
                    Text(course).tag(course)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Picker("绑定状态", selection: $viewModel.selectedStatus) {
                Text("全部绑定状态").tag("")
                ForEach(viewModel.statuses, id: \.self) { status in
                    Text(status).tag(status)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Text("筛选")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task { await viewModel.resetFilters() }
                } label: {
                    Text("重置")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var studentList: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            } else if viewModel.records.isEmpty {
                Text("暂无学员")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(viewModel.records) { record in
                    StudentRecordCard(record: record)
                }
            }
        }
    }
}

private struct StudentRecordCard: View {
    let record: StudentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.studentName.isEmpty ? "未命名学员" : record.studentName)
                        .font(.headline)

                    Text(record.courseTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(record.status.isEmpty ? "未设置" : record.status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 10) {
                StudentInfoPill(title: "最新上课", value: record.recordTime.isEmpty ? "--" : record.recordTime)
                StudentInfoPill(title: "老师", value: record.teacher.isEmpty ? "--" : record.teacher)
            }

            if record.remark.isEmpty == false {
                Text(record.remark)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("编辑")
                Text("缴费")
                Text("调班")
                Text("打卡记录")
                Text("请假记录")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.orange)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StudentInfoPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        StudentManagementView()
    }
}
