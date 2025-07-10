//
//  ContentView.swift
//  PixVerse_127
//
//  Created by Денис Николаев on 30.06.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var reloadTrigger = UUID()
    var body: some View {
        SplashScreenView()
            .tint(.white)
            .id(reloadTrigger)
            .onReceive(NotificationCenter.default.publisher(for: .reloadApp)) { _ in
                reloadTrigger = UUID()
            }
    }
}

#Preview {
    ContentView()
}
