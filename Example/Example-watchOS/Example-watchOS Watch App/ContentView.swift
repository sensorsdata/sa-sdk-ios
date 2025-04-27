//
//  ContentView.swift
//  Example-watchOS Watch App
//
//  Created by 陈玉国 on 2025/4/1.
//

import SwiftUI
import SensorsAnalyticsSDK

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }.task {
            let options = SAConfigOptions(serverURL: "http://10.1.137.85:8106/sa?project=default", launchOptions: nil)
            options.enableLog = true
            SensorsAnalyticsSDK.start(configOptions: options)
            SensorsAnalyticsSDK.sharedInstance()?.track("HelloWorld")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
