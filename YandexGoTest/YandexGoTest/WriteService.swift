//
//  WriteService.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 12.02.2023.
//

// MARK: - FileError

enum FileError: Error {
    case unexpected
    case full
}

// MARK: - FileWriteServiceProtocol

protocol FileWriteServiceProtocol {
    func generateFile(size: Double, completion: @escaping (Int) -> Void) async -> Result<URL, Error>
    func generateFiles(size: Double) async
    func writeToFile(url: URL, array: [Int]) async
}

import Foundation

// MARK: - FileWriteService

final class FileWriteService {
    static let shared: FileWriteServiceProtocol = FileWriteService()

//    private init() {}

    private var task: Task<URL, Error>?
    private var completion: ((Int) -> Void)?
}

// MARK: FileWriteServiceProtocol

extension FileWriteService: FileWriteServiceProtocol {
    func writeToFile(url: URL, array: [Int]) async {
        let task = Task.detached(priority: .high) {
            FileManager.default.createFile(atPath: url.path(), contents: nil)
            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            defer {
                try? handle.close()
            }

            let bufferSize = 4 * 1024
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)

            for number in array {
                let s = "\(number)\n"
                buffer.append(contentsOf: s.utf8)
                if buffer.count >= bufferSize {
                    try? handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
            }
            try? handle.write(contentsOf: buffer)
        }
        await task.result
    }

    func generateFile(size: Double, completion: @escaping (Int) -> Void) async -> Result<URL, Error> {
        if task != nil {
            await MainActor.run {
                self.task?.cancel()
                if let _ = self.completion {
                    self.completion = nil
                }
            }
        } else {
            self.completion = completion
        }

        task = Task(priority: .high) {
            let fileManager = FileManager.default
            let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "file.txt"
            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)

            fileManager.createFile(atPath: fileURL.path(), contents: nil)
            let fileSizeInBytes = Int(pow(2, 30) * size)
            let numbersCount = fileSizeInBytes / ("\(Int.max)\n".count)
//            let numbersCount = fileSizeInBytes / 10

            guard let handle = try? FileHandle(forWritingTo: fileURL) else { return URL.temporaryDirectory }
            defer {
                try? handle.close()
                self.task = nil
                self.completion = nil
            }
            let bufferSize = 4 * 1024
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)
            var progress = 0
            for i in 0 ... numbersCount {
                let s = "\(Int.random(in: 1 ... Int.max))\n"

                buffer.append(contentsOf: s.utf8)
                if buffer.count >= bufferSize {
                    try? handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
                let newProgress = i * 100 / numbersCount
                if progress < newProgress {
                    guard let currentCompletion = self.completion else {
                        return URL.temporaryDirectory
                    }

                    await MainActor.run {
                        currentCompletion(newProgress)
                    }
                    progress = newProgress
                }
            }
            try handle.write(contentsOf: buffer)
            guard
                let actualSize = try fileManager.attributesOfItem(atPath: fileURL.path())[.size] as? Double,
                size * 1_000_000_000 < actualSize
            else {
                throw FileError.unexpected
            }
            return fileURL
        }

        guard let task else { return .failure(FileError.unexpected) }
        let result = await task.result
        self.completion = completion
        switch result {
        case .failure:
            break
        case let .success(url):
            guard url != .temporaryDirectory else { return .failure(FileError.unexpected) }
        }
        return result
    }

    func generateFiles(size: Double) async {
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileSizeInBytes = Int(pow(2, 30) * size)
        let numbersCount = fileSizeInBytes / ("\(Int.max)\n".count)
        let bufferSize = 4 * 1024

        Task.detached(priority: .high) {
            let fileName = "file1.txt"
            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)
            fileManager.createFile(atPath: fileURL.path(), contents: nil)
            guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
            defer {
                try? handle.close()
            }
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)

            for i in 0 ... numbersCount / 3 {
                let s = "\(Int.random(in: 1 ... Int.max))\n"

                buffer.append(contentsOf: s.utf8)
                if buffer.count >= bufferSize {
                    try? handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
            }
            try handle.write(contentsOf: buffer)
        }

        Task.detached(priority: .high) {
            let fileName = "file2.txt"
            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)
            fileManager.createFile(atPath: fileURL.path(), contents: nil)
            guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
            defer {
                try? handle.close()
            }
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)

            for i in 0 ... numbersCount / 3 {
                let s = "\(Int.random(in: 1 ... Int.max))\n"

                buffer.append(contentsOf: s.utf8)
                if buffer.count >= bufferSize {
                    try? handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
            }
            try handle.write(contentsOf: buffer)
        }
        Task.detached(priority: .high) {
            let fileName = "file3.txt"
            let fileURL = directoryURL.appending(component: fileName, directoryHint: .notDirectory)
            fileManager.createFile(atPath: fileURL.path(), contents: nil)
            guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
            defer {
                try? handle.close()
            }
            var buffer: [UInt8] = []
            buffer.reserveCapacity(bufferSize)

            for i in 0 ... numbersCount / 3 {
                let s = "\(Int.random(in: 1 ... Int.max))\n"

                buffer.append(contentsOf: s.utf8)
                if buffer.count >= bufferSize {
                    try? handle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
            }
            try handle.write(contentsOf: buffer)
        }
    }
}
