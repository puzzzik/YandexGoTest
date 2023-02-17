//
//  FileSortService.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 15.02.2023.
//

import Foundation

// MARK: - FileSortServiceProtocol

protocol FileSortServiceProtocol {
    func sortFile(url: URL, size: Int) async -> Bool
}

// MARK: - FileSortService

final class FileSortService {
    static let shared: FileSortServiceProtocol = FileSortService()
//    private var numbers = Array(repeating: 0, count: 1_000_000)
    private let fileWriteService = FileWriteService.shared
    private init() {}

    private func sortPart(url: URL, i: Int, numbersInFile: Int) async throws -> [Int] {
        let task = Task.detached(priority: .high) {
            var i = 0
            var numbers = [Int]()

            for try await line in url.lines.prefix(i * numbersInFile) {
                numbers.append(Int(line) ?? 0)
                if i == numbersInFile { break }
            }
//
//            numbers = try await url
//                .lines
//                .prefix(i * numbersInFile)
//                .reduce(into: [Int]()) { partialResult, line in
//                    if i >= numbersInFile { break }
//                    partialResult.append(Int(line) ?? 0)
//                    i += 1
//                }
            numbers.sort()
            return numbers
        }
        return try await task.result.get()
    }
}

// MARK: FileSortServiceProtocol

extension FileSortService: FileSortServiceProtocol {
    func sortFile(url: URL, size ram: Int) async -> Bool {
        let before = Date.now

        guard let actualFileSize = try? FileManager.default.attributesOfItem(atPath: url.path())[.size] as? Int else { return false }
        let filesCount = actualFileSize / ram
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        if filesCount > 1 {
            let numbersInFile = ram / ("\(Int.max)\n".count)
            
            var numbers = [Int]()
            var file = 0
            var fileName = "file\(file).txt"
            var fileURL = directory.appending(component: fileName, directoryHint: .notDirectory)

            do {
                FileManager.default.createFile(atPath: fileURL.path(), contents: nil)
                var i = 1
                for try await line in url.lines {
                    numbers.append(Int(line) ?? 0)
                    if i % numbersInFile == 0 {
                        numbers.sort()
                        await FileWriteService().writeToFile(url: fileURL, array: numbers)
                        numbers.removeAll()
                        file += 1
                        fileName = "file\(file).txt"
                        fileURL = directory.appending(component: fileName, directoryHint: .notDirectory)
                    }
                    i += 1
                }
            } catch {
                await FileWriteService().writeToFile(url: fileURL, array: numbers.sorted())
                numbers.removeAll()
            }

//            for file in 0 ..< filesCount {
//                let fileName = "file\(file).txt"
//                let fileURL = directory.appending(component: fileName, directoryHint: .notDirectory)
//                FileManager.default.createFile(atPath: fileURL.path(), contents: nil)
            ////                try? FileManager.default.copyItem(at: url, to: fileURL)
//
//                guard
//                    let numbers = try? await sortPart(url: url, i: file, numbersInFile: numbersInFile)
//                else { return false }
            ////                    var i = 0
            ////                    var numbers = [Int]()
            ////
            ////                    for try await line in fileURL.lines.prefix(file * numbersInFile) {
            ////                        numbers.append(Int(line) ?? 0)
            ////                        if i == numbersInFile { break }
            ////                    }
            ////                    numbers.sort()
//
//                await FileWriteService().writeToFile(url: fileURL, array: numbers)
//            }
        } else {
            Task(priority: .high) {
                guard let handle = try? FileHandle(forReadingFrom: url) else { return }
                defer {
                    try? handle.close()
                }
                var numbers = try await url.lines.reduce(into: [Int]()) { $0.append(Int($1) ?? 0) }
                numbers.sort()
                let fileName = "fileSorted.txt"
                let fileURL = directory.appending(component: fileName, directoryHint: .notDirectory)

                await fileWriteService.writeToFile(url: fileURL, array: numbers)
            }
        }

        return true
    }
}
