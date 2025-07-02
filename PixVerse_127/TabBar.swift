//
//  TabBar.swift
//  Higgsfield
//
//  Created by Денис Николаев on 17.06.2025.
//


import SwiftUI

struct TabBar: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        VStack {
                            Image(systemName: "play.rectangle.on.rectangle.fill")
                            Text("AI Video")
                                .font(.custom("SpaceGrotesk-Light_Medium", size: 11))
                        }
                    }
                    .tag(0)
                PhotoView()
                    .tabItem {
                        VStack {
                            Image(systemName: "camera.on.rectangle.fill")
                            Text("AI Photo")
                                .font(.custom("SpaceGrotesk-Light_Medium", size: 11))
                        }
                    }
                    .tag(1)
                
                HistoryView()
                    .tabItem {
                        VStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("History")
                                .font(.custom("SpaceGrotesk-Light_Medium", size: 11))
                        }
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        VStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                                .font(.custom("SpaceGrotesk-Light_Medium", size: 11))
                        }
                    }
                    .tag(3)
            }
            .tint(.accentColor)
        }
    }
}

#Preview {
    TabBar()
}
