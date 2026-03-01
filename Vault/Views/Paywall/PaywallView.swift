import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showCelebration = false
    @State private var animateFeatures = false

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("infinity", "Unlimited Collection", "Add every timepiece you own"),
        ("chart.line.uptrend.xyaxis", "Full Analytics", "Track values, trends & appreciation"),
        ("clock.arrow.circlepath", "Wear History", "Complete wear logging & statistics"),
        ("doc.text.fill", "Insurance Vault", "Store documents & service records"),
        ("bell.badge.fill", "Price Alerts", "Wishlist notifications & tracking"),
    ]

    var body: some View {
        ZStack {
            Color.vaultBackground.ignoresSafeArea()

            LinearGradient(
                colors: [Color.champagne.opacity(0.08), .clear, Color.champagne.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showCelebration {
                celebrationOverlay
            } else {
                mainContent
            }
        }
        .onChange(of: storeManager.purchaseState) { _, newState in
            if newState == .purchased || newState == .restored {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCelebration = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    dismiss()
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateFeatures = true
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    featuresSection
                    pricingSection
                    buttonsSection
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.champagne.opacity(0.3), Color.champagne.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.champagne)
            }

            Text("Unlock Vault")
                .font(.vaultTitle)
                .foregroundStyle(.white)

            Text("The complete watch collector's toolkit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 16) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(Color.champagne)
                        .frame(width: 36, height: 36)
                        .background(Color.champagne.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.champagne)
                }
                .padding(.vertical, 12)
                .opacity(animateFeatures ? 1 : 0)
                .offset(y: animateFeatures ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08), value: animateFeatures)

                if index < features.count - 1 {
                    Divider().overlay(Color.white.opacity(0.06))
                }
            }
        }
        .padding(20)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var pricingSection: some View {
        VStack(spacing: 8) {
            if let product = storeManager.product {
                Text(product.displayPrice)
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundStyle(Color.champagne)
            } else {
                Text("$6.99")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundStyle(Color.champagne)
            }

            Text("One-time purchase")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("No subscriptions. Own it forever.")
                .font(.caption)
                .foregroundStyle(Color.champagne.opacity(0.8))
                .padding(.top, 2)
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await storeManager.purchase() }
            } label: {
                Group {
                    if storeManager.purchaseState == .purchasing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Unlock Vault")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color.champagne, Color.darkGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.champagne.opacity(0.3), radius: 12, y: 6)
            }
            .disabled(storeManager.purchaseState == .purchasing)

            Button {
                Task { await storeManager.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(Color.champagne.opacity(0.7))
            }

            if case .failed(let msg) = storeManager.purchaseState {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Payment is charged to your Apple ID account.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://www.apple.com/privacy/")!)
            }
            .font(.caption2)
            .foregroundStyle(Color.champagne.opacity(0.5))
        }
        .padding(.top, 8)
    }

    private var celebrationOverlay: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.champagne)
                .symbolEffect(.bounce, value: showCelebration)

            Text("Welcome to Vault")
                .font(.vaultTitle)
                .foregroundStyle(.white)

            Text("Your collection is now unlimited")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
