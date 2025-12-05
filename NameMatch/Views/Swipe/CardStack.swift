import SwiftUI

struct CardStack: View {
    @EnvironmentObject var store: AppStore

    @State private var offset: CGSize = .zero
    @State private var activeCardRotation: Double = 0
    @State private var isDragging = false
    @State private var isAnimatingAway = false

    private let swipeThreshold: CGFloat = 80
    private let velocityThreshold: CGFloat = 300
    private let maxRotation: Double = 12

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background cards (show up to 2)
                ForEach(Array(store.currentNameQueue.prefix(3).enumerated().reversed()), id: \.element.id) { index, name in
                    if index > 0 && !isAnimatingAway {
                        NameCard(name: name, isTopCard: false)
                            .frame(
                                width: geometry.size.width - 40 - CGFloat(index * 8),
                                height: geometry.size.height - CGFloat(index * 12)
                            )
                            .offset(y: CGFloat(index * 6))
                    }
                }

                // Top card with gesture
                if let topName = store.currentNameQueue.first {
                    ZStack {
                        NameCard(name: topName, isTopCard: true)

                        // Like/Pass overlay
                        SwipeOverlay(offset: offset, threshold: swipeThreshold)
                    }
                    .frame(
                        width: geometry.size.width - 40,
                        height: geometry.size.height
                    )
                    .offset(offset)
                    .rotationEffect(.degrees(activeCardRotation))
                    .scaleEffect(isDragging ? 1.02 : 1.0)
                    .shadow(
                        color: .black.opacity(isDragging ? 0.2 : 0.1),
                        radius: isDragging ? 20 : 10,
                        y: isDragging ? 10 : 5
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isAnimatingAway {
                                    isDragging = true
                                    // Apply curved path - card follows an arc instead of finger
                                    let curvedOffset = applyCurvedPath(to: value.translation)
                                    offset = curvedOffset
                                    activeCardRotation = Double(curvedOffset.width / 25)
                                        .clamped(to: -maxRotation...maxRotation)
                                }
                            }
                            .onEnded { value in
                                if !isAnimatingAway {
                                    handleSwipeEnd(
                                        translation: value.translation,
                                        velocity: value.velocity,
                                        name: topName
                                    )
                                }
                            }
                    )
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func handleSwipeEnd(translation: CGSize, velocity: CGSize, name: BabyName) {
        let horizontalVelocity = velocity.width

        // Check if swipe was fast enough OR far enough
        let swipedRight = translation.width > swipeThreshold || horizontalVelocity > velocityThreshold
        let swipedLeft = translation.width < -swipeThreshold || horizontalVelocity < -velocityThreshold

        if swipedRight {
            swipeOff(to: .right, velocity: horizontalVelocity, name: name, liked: true)
        } else if swipedLeft {
            swipeOff(to: .left, velocity: horizontalVelocity, name: name, liked: false)
        } else {
            // Snap back with a satisfying spring
            isDragging = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = .zero
                activeCardRotation = 0
            }
        }
    }

    private func swipeOff(to direction: SwipeDirection, velocity: CGFloat, name: BabyName, liked: Bool) {
        isAnimatingAway = true
        isDragging = false

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: liked ? .medium : .light)
        impact.impactOccurred()

        // Calculate throw distance based on velocity
        let baseDistance: CGFloat = 400
        let velocityBoost = min(abs(velocity) / 2, 300)
        let throwDistance = baseDistance + velocityBoost

        // Animate the card flying off with momentum
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(
                width: direction == .right ? throwDistance : -throwDistance,
                height: offset.height + 50 // Slight downward arc
            )
            activeCardRotation = direction == .right ? 15 : -15
        }

        // Record swipe and prepare next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            store.swipe(name: name, liked: liked)

            // Reset state for next card
            offset = .zero
            activeCardRotation = 0
            isAnimatingAway = false
        }
    }

    func swipeRight() {
        guard let topName = store.currentNameQueue.first, !isAnimatingAway else { return }
        swipeOff(to: .right, velocity: 0, name: topName, liked: true)
    }

    func swipeLeft() {
        guard let topName = store.currentNameQueue.first, !isAnimatingAway else { return }
        swipeOff(to: .left, velocity: 0, name: topName, liked: false)
    }

    // MARK: - Curved Path Animation

    /// Applies a curved path to the drag translation for a more natural swipe feel
    /// The card moves along an arc instead of directly following the finger
    private func applyCurvedPath(to translation: CGSize) -> CGSize {
        let horizontalDistance = translation.width

        // Calculate vertical offset purely based on horizontal distance
        // This creates a fixed parabolic path that the card follows (ignores vertical finger movement)
        let normalizedDistance = abs(horizontalDistance) / 150.0
        let curveFactor: CGFloat = 35.0

        // Parabolic curve: card moves down as it's swiped horizontally
        let curvedVerticalOffset = normalizedDistance * normalizedDistance * curveFactor

        return CGSize(
            width: horizontalDistance,
            height: curvedVerticalOffset
        )
    }

    enum SwipeDirection {
        case left, right
    }
}

struct SwipeOverlay: View {
    let offset: CGSize
    let threshold: CGFloat

    var body: some View {
        ZStack {
            // Like overlay (right swipe)
            HStack {
                LikeLabel()
                    .opacity(likeOpacity)
                    .scaleEffect(0.9 + likeOpacity * 0.1)
                    .rotationEffect(.degrees(-15))
                    .padding(.leading, 30)
                Spacer()
            }

            // Pass overlay (left swipe)
            HStack {
                Spacer()
                PassLabel()
                    .opacity(passOpacity)
                    .scaleEffect(0.9 + passOpacity * 0.1)
                    .rotationEffect(.degrees(15))
                    .padding(.trailing, 30)
            }
        }
        .padding(.top, 40)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var likeOpacity: Double {
        guard offset.width > 0 else { return 0 }
        return Double(offset.width / threshold).clamped(to: 0...1)
    }

    private var passOpacity: Double {
        guard offset.width < 0 else { return 0 }
        return Double(-offset.width / threshold).clamped(to: 0...1)
    }
}

struct LikeLabel: View {
    var body: some View {
        Text("LIKE")
            .font(.system(size: 36, weight: .black))
            .foregroundColor(.green)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green, lineWidth: 3)
            )
    }
}

struct PassLabel: View {
    var body: some View {
        Text("NOPE")
            .font(.system(size: 36, weight: .black))
            .foregroundColor(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.red, lineWidth: 3)
            )
    }
}

// MARK: - Clamped Extension

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    CardStack()
        .environmentObject(AppStore.shared)
        .padding()
}
