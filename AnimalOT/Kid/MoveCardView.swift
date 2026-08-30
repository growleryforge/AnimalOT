import SwiftUI
import SwiftData
import UIKit

// MARK: - Animal-move card (full-body "become the animal" mirror)
//
// He props the iPad (or a parent holds it) so the front camera sees his whole
// body, picks a move (Bear Walk, Frog Jumps…), and sees HIMSELF transformed —
// animal ears, snout, paws and a tail pinned to his body. Doing the move fills a
// STRENGTH meter (from his actual movement, no button) to a big celebration and a
// medal. Easy first win, a little longer each medal. No fail, capture rides along.

struct MoveCardView: View {
    let card: MoveCard

    @Environment(\.modelContext) private var context
    @Environment(Provisioning.self) private var provisioning
    @Environment(\.dismiss) private var dismiss

    @State private var sound = SoundEngine()
    @State private var controller: KidSessionController?

    @State private var points: [String: CGPoint] = [:]
    @State private var progress = 0.0        // toward the current medal
    @State private var medals = 0
    @State private var celebrating = false
    @State private var showCoach = true
    @State private var confetti: [GleeBurst] = []

    private let bigHaptic = UIImpactFeedbackGenerator(style: .heavy)

    /// Movement needed for a medal. Easy first, a little more each time.
    private var need: Double { 1.0 + Double(medals) * 0.6 }
    /// Effort → progress. Tunable on-device (see note in BodyPoseView).
    private let gain = 0.08

    private var bodySeen: Bool { points.count >= 6 }

    var body: some View {
        ZStack {
            // Live full-body mirror.
            BodyPoseView(onPose: { points = $0 }, onEffort: handleEffort)
                .ignoresSafeArea()

            // Animal features pinned to his body.
            AnimalBodyOverlay(points: points, color: card.color)
                .ignoresSafeArea()

            // Soft themed vignette so the features pop.
            card.color.opacity(0.12).ignoresSafeArea().allowsHitTesting(false)

            VStack {
                topBar
                Spacer()
                if showCoach { coachBubble }
                Spacer()
                if !bodySeen {
                    Text("Hop in so I can see you! 🎥")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(.black.opacity(0.35), in: Capsule())
                }
                strengthMeter
            }
            .padding()

            ForEach(confetti) { burst in
                Text(burst.symbol)
                    .font(.system(size: 60 + burst.escalation * 70))
                    .position(burst.position)
            }

            if celebrating {
                ZStack {
                    card.color.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("🏅").font(.system(size: 150))
                        Text("SO STRONG!")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(.white).shadow(radius: 8)
                        Text("Medal #\(medals) 🎉")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .statusBarHidden()
        .onAppear(perform: begin)
        .onDisappear { controller?.end() }
    }

    private var topBar: some View {
        HStack {
            Button { controller?.end(); dismiss() } label: {
                Image(systemName: "house.fill")
                    .font(.title2).foregroundStyle(.white.opacity(0.85))
                    .padding(12).background(.black.opacity(0.35), in: Circle())
            }
            Button { withAnimation { showCoach = true } } label: {
                Image(systemName: "questionmark")
                    .font(.title2.weight(.bold)).foregroundStyle(.white.opacity(0.85))
                    .padding(12).background(.black.opacity(0.35), in: Circle())
            }
            Spacer()
            if medals > 0 {
                Text("🏅 ✕ \(medals)")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.black.opacity(0.35), in: Capsule())
            }
        }
    }

    private var coachBubble: some View {
        VStack(spacing: 8) {
            Text(card.emoji).font(.system(size: 64))
            Text(card.name)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(card.kidInstruction)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 26).padding(.vertical, 20)
        .background(card.color.opacity(0.85), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.6), lineWidth: 3))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        .padding(.horizontal, 30)
        .transition(.scale.combined(with: .opacity))
    }

    private var strengthMeter: some View {
        VStack(spacing: 6) {
            Text(progress >= need ? "STRONG!" : "Keep moving like a \(card.name)! 💪")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white).shadow(radius: 3)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.3))
                    Capsule().fill(.white)
                        .frame(width: max(16, geo.size.width * min(1, progress / need)))
                        .overlay(alignment: .trailing) {
                            Text("💪").font(.system(size: 26)).offset(x: 8)
                        }
                        .animation(.easeOut(duration: 0.15), value: progress)
                }
            }
            .frame(height: 26)
        }
        .padding(.horizontal, 12)
    }

    // MARK: Wiring

    private func begin() {
        sound.preload(["roar"])
        let c = KidSessionController(context: context, deviceId: provisioning.deviceId)
        c.begin(moveCard: card)
        controller = c
        showCoach = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeInOut(duration: 0.5)) { showCoach = false }
        }
    }

    private func handleEffort(_ effort: Double) {
        guard !celebrating else { return }
        progress += effort * gain
        if progress >= need { celebrate() }
    }

    private func celebrate() {
        medals += 1
        controller?.log(.complete, value: "\(card.name) medal \(medals)")
        bigHaptic.impactOccurred()
        sound.fire("roar", escalation: 1.0)

        let syms = ["🏅", "💪", "⭐️", "🎉", "✨", "🥳", card.emoji]
        confetti = (0..<36).map { _ in
            GleeBurst(symbol: syms.randomElement() ?? "🎉",
                      escalation: Double.random(in: 0.4...1.0),
                      position: CGPoint(x: .random(in: 30...380), y: .random(in: 80...760)))
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { celebrating = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            confetti = []
            withAnimation(.easeInOut(duration: 0.4)) { celebrating = false }
            progress = 0   // next round; `need` grows via medals
        }
    }
}
