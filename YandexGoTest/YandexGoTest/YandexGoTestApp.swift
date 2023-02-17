//
//  YandexGoTestApp.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 11.02.2023.
//

import SwiftUI

@main
struct YandexGoTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ViewModel())
        }
    }
}
