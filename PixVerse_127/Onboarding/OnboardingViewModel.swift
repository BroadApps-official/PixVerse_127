import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var steps: [OnboardingStep] = [
        OnboardingStep(imageName: "step1", title: "Photo and video", subtitle: "Generate with text and photos"),
        OnboardingStep(imageName: "step2", title: "Many effects", subtitle: "More than 40 unique effects"),
        OnboardingStep(imageName: "step3", title: "Share with friends", subtitle: "Show off your best generations"),
        OnboardingStep(imageName: "step4", title: "Rate our app in the \n AppStore", subtitle: ""),
        OnboardingStep(imageName: "step5", title: "Don't miss new \n trends", subtitle: "Allow notifications")
    ]
    
    @Published var currentPage = 0
    
    func nextPage() {
        if currentPage < steps.count - 1 {
            currentPage += 1
        } else {
            print("Onboarding Finished!")
        }
    }
}
