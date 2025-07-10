import SwiftUI

struct EffectSectionView: View {
    let title: String
    let effects: [Effect]
    @State private var showAll = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: SeeAllView(selectedCategory: title)) {
                    HStack(spacing: 4) {
                        Text("All")
                            .font(.system(size: 13))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
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
