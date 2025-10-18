import SwiftUI

struct LoginView: View {
    // Define color constants for reusability
    let primaryColor = Color(red: 255/255, green: 200/255, blue: 124/255)
    let accentColor = Color(red: 193/255, green: 129/255, blue: 40/255)
    let backgroundColor = Color(red: 46/255, green: 33/255, blue: 27/255)
    
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 60) {
                VStack(spacing: 10) {
                    Image("knightIcon")
                    
                    VStack(spacing: 20) {
                        welcomeText
                        descriptionText
                    }
                }
                NavigationLink (destination: ScanningView()){
                    actionButton
                }
                
                learnMoreText
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Subviews

    private var welcomeText: some View {
        VStack(spacing: 7) {
            Text("Welcome to")
                .font(Font.custom("SFProDisplay-Bold", size: 40))
                .fontWeight(.heavy)
                .foregroundStyle(.white)
            
            Text("Chess Mentor")
                .font(Font.custom("SFProDisplay-Bold", size: 40))
                .fontWeight(.heavy)
                .foregroundStyle(primaryColor)
        }
    }

    private var descriptionText: some View {
        Text("AI-powered insights to elevate your chess game.")
            .font(Font.custom("SFProDisplay-Regular", size: 16))
            .foregroundStyle(.white)
    }

    private var actionButton: some View {
        Text("Get Started")
        .frame(width: 150, height: 50)
        .background(LinearGradient(colors: [accentColor, primaryColor], startPoint: .leading, endPoint: .trailing))
        .cornerRadius(13)
        .foregroundColor(.white)
        .font(Font.custom("SFProDisplay-Regular", size: 24))
    }

    private var learnMoreText: some View {
        Text("Learn more...")
            .font(Font.custom("SFProDisplay-Regular", size: 17))
            .underline()
            .foregroundStyle(primaryColor)
    }
}

#Preview {
    LoginView()
}
