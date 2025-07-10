import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    ForEach(viewModel.steps.indices, id: \.self) { index in
                        OnboardingStepView(step: viewModel.steps[index], index: index, viewModel: viewModel)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .tabViewStyle(viewModel.currentPage == 4 ? PageTabViewStyle(indexDisplayMode: .never) : PageTabViewStyle(indexDisplayMode: .automatic))
                .ignoresSafeArea(edges: .top)
                
                if viewModel.currentPage != 4 {
                    HStack {
                        ForEach(viewModel.steps.indices, id: \.self) { index in
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundColor(viewModel.currentPage == index ? .white : .gray.opacity(0.5))
                        }
                    }
                    .padding(.bottom, 7)
                }
                
                if viewModel.currentPage == 4 {
                    NavigationLink(destination: TabBar().navigationBarBackButtonHidden(true))
                    {
                        Text("Maybe Later")
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
            }
            .background(Color(hex: "#131313"))
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    OnboardingView()
}
