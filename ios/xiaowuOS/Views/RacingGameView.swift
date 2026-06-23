import SwiftUI

struct RacingGameView: View {
    @StateObject private var game = RacingGameModel()

    var body: some View {
        VStack(spacing: 0) {
            scoreBar

            RacingRoadView(
                playerLane: game.playerLane,
                items: game.items,
                isGameOver: game.isGameOver
            )
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            controls
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("赛车")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            game.pause()
        }
    }

    private var scoreBar: some View {
        HStack(spacing: 10) {
            RacingStat(title: "得分", value: "\(game.score)")
            RacingStat(title: "路程", value: "\(game.distance)m")
            RacingStat(title: "生命", value: String(repeating: "♥", count: max(game.lives, 0)))
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if game.isGameOver {
                Text("完成 \(game.distance)m")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    game.moveLeft()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(game.isRunning == false)

                Button {
                    game.isRunning ? game.pause() : game.start()
                } label: {
                    Label(game.primaryActionTitle, systemImage: game.primaryActionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    game.moveRight()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(game.isRunning == false)
            }

            Button {
                game.reset()
            } label: {
                Label("重新开始", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(18)
        .background(.regularMaterial)
    }
}

@MainActor
private final class RacingGameModel: ObservableObject {
    @Published private(set) var playerLane = 1
    @Published private(set) var score = 0
    @Published private(set) var distance = 0
    @Published private(set) var lives = 3
    @Published private(set) var isRunning = false
    @Published private(set) var isGameOver = false
    @Published private(set) var items: [RacingItem] = []

    private var timer: Timer?
    private var spawnTicks = 0
    private var tickCount = 0

    var primaryActionTitle: String {
        if isGameOver { return "再玩一次" }
        return isRunning ? "暂停" : "开始"
    }

    var primaryActionIcon: String {
        if isGameOver { return "play.fill" }
        return isRunning ? "pause.fill" : "play.fill"
    }

    func start() {
        if isGameOver {
            reset()
        }

        guard isRunning == false else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        playerLane = 1
        score = 0
        distance = 0
        lives = 3
        isGameOver = false
        items = []
        spawnTicks = 0
        tickCount = 0
    }

    func moveLeft() {
        guard isRunning else { return }
        playerLane = max(playerLane - 1, 0)
    }

    func moveRight() {
        guard isRunning else { return }
        playerLane = min(playerLane + 1, 2)
    }

    private func tick() {
        guard isRunning else { return }

        tickCount += 1
        if tickCount % 6 == 0 {
            distance += 1
        }

        let speed = 0.010 + min(CGFloat(distance), 500) * 0.000012
        items = items.map { item in
            var updated = item
            updated.y += speed
            return updated
        }

        handleCollisions()
        removePassedItems()
        spawnIfNeeded()
    }

    private func handleCollisions() {
        var remaining: [RacingItem] = []

        for item in items {
            let hitZone = item.y > 0.76 && item.y < 0.93
            if hitZone, item.lane == playerLane {
                switch item.kind {
                case .star:
                    score += 10
                case .cone:
                    lives -= 1
                    if lives <= 0 {
                        endGame()
                    }
                }
            } else {
                remaining.append(item)
            }
        }

        items = remaining
    }

    private func removePassedItems() {
        var remaining: [RacingItem] = []

        for item in items {
            if item.y > 1.08 {
                if item.kind == .cone {
                    score += 1
                }
            } else {
                remaining.append(item)
            }
        }

        items = remaining
    }

    private func spawnIfNeeded() {
        guard isGameOver == false else { return }

        spawnTicks -= 1
        guard spawnTicks <= 0 else { return }

        let lane = Int.random(in: 0...2)
        let kind: RacingItem.Kind = Int.random(in: 0...4) == 0 ? .star : .cone
        items.append(RacingItem(lane: lane, y: -0.10, kind: kind))
        spawnTicks = max(12, 30 - min(distance / 25, 12))
    }

    private func endGame() {
        isGameOver = true
        pause()
    }
}

private struct RacingItem: Identifiable {
    enum Kind {
        case cone
        case star
    }

    let id = UUID()
    let lane: Int
    var y: CGFloat
    let kind: Kind
}

private struct RacingRoadView: View {
    let playerLane: Int
    let items: [RacingItem]
    let isGameOver: Bool

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawRoad(in: &context, size: size)
                drawItems(in: &context, size: size)
                drawPlayer(in: &context, size: size)

                if isGameOver {
                    drawGameOver(in: &context, size: size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func drawRoad(in context: inout GraphicsContext, size: CGSize) {
        let road = CGRect(origin: .zero, size: size)
        context.fill(Path(road), with: .linearGradient(
            Gradient(colors: [Color(red: 0.18, green: 0.20, blue: 0.23), Color(red: 0.08, green: 0.09, blue: 0.11)]),
            startPoint: CGPoint(x: size.width * 0.5, y: 0),
            endPoint: CGPoint(x: size.width * 0.5, y: size.height)
        ))

        let laneWidth = size.width / 3
        for index in 1...2 {
            let x = laneWidth * CGFloat(index)
            var y: CGFloat = 18
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: min(y + 24, size.height)))
                context.stroke(path, with: .color(.white.opacity(0.36)), lineWidth: 3)
                y += 44
            }
        }

        context.fill(Path(CGRect(x: 0, y: 0, width: 6, height: size.height)), with: .color(.orange))
        context.fill(Path(CGRect(x: size.width - 6, y: 0, width: 6, height: size.height)), with: .color(.orange))
    }

    private func drawItems(in context: inout GraphicsContext, size: CGSize) {
        let laneWidth = size.width / 3

        for item in items {
            let center = CGPoint(x: laneWidth * (CGFloat(item.lane) + 0.5), y: size.height * item.y)
            switch item.kind {
            case .cone:
                var cone = Path()
                cone.move(to: CGPoint(x: center.x, y: center.y - 21))
                cone.addLine(to: CGPoint(x: center.x - 18, y: center.y + 18))
                cone.addLine(to: CGPoint(x: center.x + 18, y: center.y + 18))
                cone.closeSubpath()
                context.fill(cone, with: .color(.orange))
                context.stroke(cone, with: .color(.white.opacity(0.55)), lineWidth: 2)
            case .star:
                context.fill(Path(ellipseIn: CGRect(x: center.x - 17, y: center.y - 17, width: 34, height: 34)), with: .color(.yellow))
                context.stroke(Path(ellipseIn: CGRect(x: center.x - 17, y: center.y - 17, width: 34, height: 34)), with: .color(.white.opacity(0.75)), lineWidth: 2)
            }
        }
    }

    private func drawPlayer(in context: inout GraphicsContext, size: CGSize) {
        let laneWidth = size.width / 3
        let center = CGPoint(x: laneWidth * (CGFloat(playerLane) + 0.5), y: size.height * 0.84)
        let body = CGRect(x: center.x - 24, y: center.y - 36, width: 48, height: 72)
        let window = CGRect(x: center.x - 15, y: center.y - 23, width: 30, height: 23)

        context.fill(Path(roundedRect: body, cornerRadius: 12), with: .color(.blue))
        context.fill(Path(roundedRect: window, cornerRadius: 6), with: .color(.cyan.opacity(0.75)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 29, y: center.y - 24, width: 12, height: 18)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x + 17, y: center.y - 24, width: 12, height: 18)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 29, y: center.y + 12, width: 12, height: 18)), with: .color(.black))
        context.fill(Path(ellipseIn: CGRect(x: center.x + 17, y: center.y + 12, width: 12, height: 18)), with: .color(.black))
    }

    private func drawGameOver(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.fill(Path(rect), with: .color(.black.opacity(0.45)))

        let text = Text("游戏结束")
            .font(.title.weight(.bold))
            .foregroundStyle(.white)
        context.draw(text, at: CGPoint(x: size.width * 0.5, y: size.height * 0.48), anchor: .center)
    }
}

private struct RacingStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "-" : value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        RacingGameView()
    }
}
