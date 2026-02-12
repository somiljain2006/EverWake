import SwiftUI
import UIKit

struct DriverProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showReportDialog = false
    @State private var showCopiedToast = false
    @State private var showShareSheet = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isEditingName = false
    @FocusState private var isNameFocused: Bool

    @AppStorage("profileImageData") private var profileImageData: Data?
    @AppStorage("userName") private var userName: String = "Driver"
    @AppStorage("studyAlertSound") private var studyAlertSoundId: String = "bell"

    var onExit: (() -> Void)? = nil

    private let bgColor = Color(hex: "#2D3135")
    private let cardTextColor = Color(hex: "#BDBDBD")
    private let accent = Color(hex: "#F05650")
    
    let showStudyOptions: Bool

    init(showStudyOptions: Bool = false, onExit: (() -> Void)? = nil) {
        self.showStudyOptions = showStudyOptions
        self.onExit = onExit
    }

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
            ZStack(alignment: .bottomTrailing) {

                Group {
                    if let data = profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(28)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 116, height: 116)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())

                Button {
                    showImagePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#6CB8C9"))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .offset(x: -6, y: -6)
            }

            if isEditingName {
                TextField("Driver", text: $userName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        finishEditingName()
                    }
                    .onAppear {
                        isNameFocused = true
                    }
            } else {
                Button {
                    isEditingName = true
                } label: {
                    HStack(spacing: 6) {
                        Text(userName.isEmpty ? "Driver" : userName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if let image = selectedImage,
                       let data = image.jpegData(compressionQuality: 0.8) {
                        profileImageData = data
                    }
                }
        }
    }

    private var optionsList: some View {
        VStack(spacing: 20) {
            if showStudyOptions {
                NavigationLink {
                    StudyAlertSoundPickerView()
                } label: {
                    profileRow(title: "Choose Alert Sound", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.plain)
            }
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
                .font(.system(size: 18, weight: .semibold))
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
                    withAnimation { showReportDialog = false }
                }

            VStack(spacing: 20) {
                HStack {
                    Text("Report Issue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        withAnimation { showReportDialog = false }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Text("Please report at https://github.com/somiljain2006/VisionAI")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation { showReportDialog = false }
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
    
    private var shareItems: [Any] {
        let message = "Check out VisionAI – Stay awake, stay focused"
        let appLink = URL(string: "https://github.com/somiljain2006/VisionAI")!
        return [message, appLink]
    }
    
    private func finishEditingName() {
        userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if userName.isEmpty {
            userName = "Driver"
        }
        isEditingName = false
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

