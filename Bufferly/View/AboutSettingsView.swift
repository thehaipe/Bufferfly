import SwiftUI
struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 15) {
                    Image(.appLogo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.2))
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bufferly").font(.headline)
                        Text("Version 0.1 (Alpha)").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Section("Links") {
                Link(destination: URL(string: "https://github.com/thehaipe/Bufferly")!) {
                    Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.black)
                }
                Link(destination: URL(string: "https://bufferfly.lemonsqueezy.com/checkout/buy/f2c0bafc-c7c7-4490-9e0b-80585135dadd")!) {
                    Label("Support Development", systemImage: "heart.fill")
                        .foregroundStyle(.black)
                }
                Link(destination: URL(string: "https://github.com/thehaipe/Bufferly/issues")!) {
                    Label {
                        Text("Report a Bug or Request a Feature")
                    } icon: {
                        Image(.bugIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
                Link(destination: URL(string: "www.linkedin.com/in/valentyn-m-65a30b287")!) {
                    Label{
                        Text("Also Visit My LinkedIn")
                    } icon: {
                        Image(.linkedInLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
#Preview{
    AboutSettingsView()
}
