import SwiftUI

struct EffectSectionView: View {
    let title: String
    let effects: [Effect]
    @State private var showAll = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.custom("SpaceGrotesk-Light_Bold", size: 22))
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                NavigationLink(destination: SeeAllView(selectedCategory: title)) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.custom("SpaceGrotesk-Light_Regular", size: 13))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(effects.enumerated()), id: \ .element.id) { index, effect in
                        NavigationLink(destination: EffectsPageView(effects: effects, currentIndex: index)) {
                            EffectCardView(effect: effect)
                        }
                    }
                }
            }
        }
    }
}
