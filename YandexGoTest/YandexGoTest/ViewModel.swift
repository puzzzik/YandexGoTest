//
//  ViewModel.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 11.02.2023.
//

import Combine
import Foundation

// MARK: - JobState

enum JobState {
    case creating
    case created
    case sorting
    case sorted
    case none
}

// MARK: - ViewModel

@MainActor
final class ViewModel: ObservableObject {
    @Published var progress = 0.0
    @Published var weight = 1.0
    @Published var state: JobState = .none

    private let fileWriteService = FileWriteService.shared
    private let fileSortService = FileSortService.shared
    private var url: URL? = FileManager.default
        .urls(for: .documentDirectory,
              in: .userDomainMask)[0].appending(path: "file.txt", directoryHint: .notDirectory)

    func generateFile() async {
        state = .creating

        let url = await fileWriteService.generateFile(size: weight) { progress in

            self.state = .creating
            self.progress = Double(progress)
        }

        if let url = url {
            state = .created
            self.url = url
        } else {
            state = .none
            progress = 0
        }
    }

    func sortFile() async {
        guard let url else { return }

        state = .sorting

        let result = await fileSortService.sortFile(url: url,
                                                    size: Int(weight * pow(2, 30))) { progress in
            self.state = .sorting
            self.progress = Double(progress)
        }

        if result != nil {
            state = .sorted
        } else {
            state = .none
        }
    }

    func cancelTasks() {
        fileWriteService.cancelTasks()
        fileSortService.cancelTasks()
    }
}
