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
//        await MainActor.run {
            self.state = .creating
//        }

        let url = await fileWriteService.generateFile(size: weight) { progress in
//            await MainActor.run {
                self.state = .creating
                self.progress = Double(progress)
//            }
        }
//        await MainActor.run {
            if let url = url {
                self.state = .created
                self.url = url
            } else {
                self.state = .none
                self.progress = 0
            }
//        }
    }

    func sortFile() async {
        guard let url else { return }
//        await MainActor.run {
            self.state = .sorting
//        }

        let result = await fileSortService.sortFile(url: url,
                                                    size: Int(weight * pow(2, 30))) { progress in
            self.state = .sorting
            self.progress = Double(progress)
        }
//        await MainActor.run {
            if result != nil {
                self.state = .sorted
            } else {
                self.state = .none
            }
//        }
    }

    func cancelTasks() {
        fileWriteService.cancelTasks()
        fileSortService.cancelTasks()
    }
}
