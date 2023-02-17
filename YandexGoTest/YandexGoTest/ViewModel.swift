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

final class ViewModel: ObservableObject {
    @Published var fileWeight = 1.0
    @Published var ramUsed = 0.1
    @Published var progress = 0.0
    @Published var state: JobState = .none
    private let fileWriteService = FileWriteService.shared
    private let fileSortService = FileSortService.shared
    private var url: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(path: "file.txt", directoryHint: .notDirectory)

    func generateFile() async {
        await MainActor.run {
            self.state = .creating
        }

        let result = await fileWriteService.generateFile(size: fileWeight) { progress in
            self.state = .creating
            self.progress = Double(progress)
        }
        switch result {
        case let .success(url):
            await MainActor.run {
                self.state = .created
                self.url = url
            }
        case let .failure(failure):
            await MainActor.run {
                print(failure)
                self.state = .none
            }
        }
    }

    func sortFile() async {
        guard let url else { return }
        await MainActor.run {
            self.state = .sorting
        }

        let result = await fileSortService.sortFile(url: url, size: Int(ramUsed * pow(2, 30)))
        await MainActor.run {
            if result {
                self.state = .sorted
            }
        }
    }

//    func generateFiles() async {
//        Task.detached(priority: .userInitiated) {
//        var files = [URL]()
//
//        let fileSizeInBytes = Int(pow(2, 30) * fullFileWeight)
//        let numbersCount = fileSizeInBytes / ("\(Int.max)\n".count)
//        let queue = DispatchQueue(label: "my", attributes: .concurrent)
//        let group = DispatchGroup()
//        let lock = NSLock()
//        let before = Date.now
//        for i in 1 ... 4 {
//            group.enter()
//
//            queue.async {
//                let file = WriteService().generateFile(i, numbersCount: numbersCount / 4)
//                lock.lock()
//                files.append(file)
//                lock.unlock()
//                group.leave()
//            }
//        }
//
//        group.notify(queue: queue) {
//            let fileName = "file.txt"
//            let fileManager = FileManager.default
//            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)
//            fileManager.createFile(atPath: fileURL.path(), contents: nil)
//            let fh = try? FileHandle(forUpdating: fileURL)
//
//            for file in files {
//                try? fh?.seekToEnd()
//                fh?.write(fileManager.contents(atPath: file.path()) ?? Data())
//            }
//            let after = Date.now
//            print(before.distance(to: after).formatted())
//        }

//        queue.async(flags: .barrier) {
//            let fileName = "file.txt"
//            let fileManager = FileManager.default
//            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)
//            fileManager.createFile(atPath: fileURL.path(), contents: nil)
//            let fh = try? FileHandle(forUpdating: fileURL)
//
//            for file in files {
//                try? fh?.seekToEnd()
//                fh?.write(fileManager.contents(atPath: file.path()) ?? Data())
//            }
//        }
//
//        Task.detached(priority: .high) {
//            let fileUrl = await WriteService().generateFile(0, numbersCount: numbersCount)
//        }
//
//        files = await withTaskGroup(of: URL.self, returning: [URL].self) { group in
//            for i in 1 ... 4 {
//                group.addTask {
//                }
//            }
//            return await group.reduce(into: [URL]()) { $0.append($1) }
//        }

//        Task.detached(priority: .userInitiated) { [files] in
//            let fileName = "file.txt"
//            let fileManager = FileManager.default
//            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)
//            fileManager.createFile(atPath: fileURL.path(), contents: nil)
//            let fh = try? FileHandle(forUpdating: fileURL)
//
//            for file in files {
//                try fh?.seekToEnd()
//                fh?.write(fileManager.contents(atPath: file.path()) ?? Data())
//            }
//        }
}
