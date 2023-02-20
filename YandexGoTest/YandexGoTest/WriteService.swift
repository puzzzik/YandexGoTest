//
//  WriteService.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 12.02.2023.
//

// MARK: - FileError

enum FileError: Error {
    case unexpected
}

// MARK: - FileWriteServiceProtocol

protocol FileWriteServiceProtocol {
    func generateFile(size: Double, completion: @escaping (Int) -> Void) async -> URL?
    func writeToFile(url: URL, array: [Int], completion: @escaping (Int) async -> Void) async -> Bool
    func cancelTasks()
}

import Foundation

// MARK: - FileWriteService

final class FileWriteService {
    static let shared: FileWriteServiceProtocol = FileWriteService()

    private init() {}

    private var task: Task<URL, Error>?
}

// MARK: FileWriteServiceProtocol

extension FileWriteService: FileWriteServiceProtocol {
    func cancelTasks() {
        if task != nil {
            task?.cancel()
        }
    }

    func writeToFile(url: URL, array: [Int], completion: @escaping (Int) async -> Void) async -> Bool {
        task = Task.detached(priority: .high) {
            FileManager.default.createFile(atPath: url.path(), contents: nil)

            guard let handle = try? FileHandle(forWritingTo: url) else { throw FileError.unexpected }
            defer {
                try? handle.close()
                self.task = nil
            }

            let bufferSize = 4 * 1024
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)
            var i = 0
            for number in array {
                let s = "\(number)\n"
                buffer.append(contentsOf: s.utf8)
                i += 1
                if buffer.count >= bufferSize {
                    try? handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }

                if i % 500_000 == 0 {
                    try Task.checkCancellation()
                    await completion(i)
                }
            }
            try handle.write(contentsOf: buffer)
            return url
        }
        guard let task else { return false }
        let result = await task.result
        switch result {
        case .success:
            return true
        case let .failure(failure):
            print(failure.localizedDescription)
            return false
        }
    }

    func generateFile(size: Double, completion: @escaping (Int) -> Void) async -> URL? {
        task = Task(priority: .high) {
            let fileManager = FileManager.default
            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "file.txt"
            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)

            fileManager.createFile(atPath: fileURL.path(), contents: nil)
            let fileSizeInBytes = Int(pow(2, 30) * size)
            let numbersCount = fileSizeInBytes / ("\(Int.max)\n".lengthOfBytes(using: .utf8))

            guard let handle = try? FileHandle(forWritingTo: fileURL) else { throw FileError.unexpected }
            defer {
                try? handle.close()
                self.task = nil
            }
            let bufferSize = 4 * 1024
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)
            for i in 0 ... numbersCount {
                let s = "\(Int.random(in: 1 ... Int.max))\n"

                buffer.append(contentsOf: s.utf8)
                if buffer.count >= bufferSize {
                    try handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
                if i % 500_000 == 0 {
                    try Task.checkCancellation()
                    await MainActor.run { [i] in
                        completion(i * 100 / numbersCount)
                    }
                }
            }
            try handle.write(contentsOf: buffer)
            return fileURL
        }

        guard let task else { return nil }
        let result = await task.result

        switch result {
        case let .success(success):
            return success
        case let .failure(failure):
            print(failure.localizedDescription)
        }
        return nil
    }
}
