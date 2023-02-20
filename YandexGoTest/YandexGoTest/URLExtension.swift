//
//  URLExtension.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 19.02.2023.
//

import Foundation
extension URL {
    func addingSuffix(suffix: String) -> URL {
        deletingLastPathComponent()
            .appending(
                component: deletingPathExtension().lastPathComponent + suffix)
            .appendingPathExtension(pathExtension)
    }
}
