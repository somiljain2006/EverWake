import SwiftUI
import UIKit

struct DriverProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showReportDialog = false
    @State private var showCopiedToast = false
    @State private var showShareSheet = false

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    var onExit: (() -> Void)? = nil

    private let bgColor = Color(hex: "#2D3135")
    private let cardTextColor = Color(hex: "#BDBDBD")
    private let accent = Color(hex: "#F05650")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack {
                header
                    .padding(.top, 18)
                    .padding(.horizontal, 16)

                Spacer(minLength: 16)

                avatarSection
                    .padding(.top, 8)

                Spacer(minLength: 20)

                optionsList
                    .padding(.horizontal, 20)

                Spacer()

                exitButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
            .foregroundColor(.white)
            
            if showReportDialog {
                reportIssueDialog
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Driver Profile")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 6)

            Spacer()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 116, height: 116)

                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.white)
            }

            Text(userName.isEmpty ? "Driver" : userName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text(userEmail.isEmpty ? "—" : userEmail)
                .font(.system(size: 15))
                .foregroundColor(cardTextColor)
        }
    }

    private var optionsList: some View {
        VStack(spacing: 20) {
            Button {
                withAnimation(.easeInOut) {
                    showReportDialog = true
                }
            } label: {
                profileRow(title: "Report Issue", systemImage: "ladybug.fill")
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                showShareSheet = true
            } label: {
                profileRow(title: "Share App", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func profileRow(title: String, systemImage: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 20))
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#9AA7D7").opacity(0.16), Color(hex: "#C4A7D7").opacity(0.16)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                )
                .shadow(radius: 6, y: 2)
        }
        .padding(.vertical, 6)
    }

    private var exitButton: some View {
        Button(action: {
            onExit?()
            dismiss()
        }) {
            Text("Exit Driver Mode")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(accent)
                .cornerRadius(14)
                .shadow(radius: 6)
        }
    }
    
    private var reportIssueDialog: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showReportDialog = false
                    }
                }

            VStack(spacing: 20) {
                HStack {
                    Text("Report Issue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        withAnimation {
                            showReportDialog = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                HStack {
                    Text(userEmail.isEmpty ? "email not provided" : userEmail)
                        .font(.system(size: 18))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        copyEmailToClipboard()
                    } label: {
                        Image("copy")
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                
                if showCopiedToast {
                    Text("Copied")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mint)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button {
                    withAnimation {
                        showReportDialog = false
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(hex: "#49494A"))
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "#2D3135"))
            )
            .shadow(radius: 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private func copyEmailToClipboard() {
        guard !userEmail.isEmpty else { return }

        UIPasteboard.general.string = userEmail

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.easeInOut) {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut) {
                showCopiedToast = false
            }
        }
    }
    
    private var shareItems: [Any] {
        let message = "Check out VisionAI – Stay awake, stay focused"
        let appLink = URL(string: "https://github.com/somiljain2006/VisionAI")!
        return [message, appLink]
    }

}

struct DriverProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DriverProfileView()
        }
        .previewDevice("iPhone 14 Pro")
    }
}
