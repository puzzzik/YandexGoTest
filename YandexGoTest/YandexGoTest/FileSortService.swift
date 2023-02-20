//
//  FileSortService.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 15.02.2023.
//

import Foundation

// MARK: - FileSortServiceProtocol

protocol FileSortServiceProtocol {
    func sortFile(url: URL, size: Int, completion: @escaping (Int) -> Void) async -> URL?
    func cancelTasks()
}

// MARK: - FileSortService

final class FileSortService {
    static let shared: FileSortServiceProtocol = FileSortService()

    private let fileWriteService = FileWriteService.shared
    private init() {}

    private var task: Task<URL, Error>?
}

// MARK: FileSortServiceProtocol

extension FileSortService: FileSortServiceProtocol {
    func cancelTasks() {
        if task != nil {
            task?.cancel()
        }
    }

    func sortFile(url: URL, size ram: Int, completion: @escaping (Int) -> Void) async -> URL? {
        task = Task.detached(priority: .high) {
            guard
                let actualFileSize = try FileManager.default
                .attributesOfItem(atPath: url.path())[.size] as? Int
            else { throw FileError.unexpected }

            let numbersInFile = (ram * 60 / 100) / (Int.bitWidth / 8)
            let filesCount = Double(actualFileSize) / Double(numbersInFile * "\(Int.max)\n".lengthOfBytes(using: .utf8))
            var newURL: URL
            var progress = 0

            let updateProgress = { (num: Int) async in
                progress = num
                await MainActor.run {
                    completion(num)
                }
            }

            if filesCount > 1 {
                let sortedFilesURLs = try await self.splitToSortedFiles(url: url,
                                                                        ram: ram,
                                                                        completion: updateProgress)
                newURL = try await self.mergeSortedFiles(urls: sortedFilesURLs,
                                                         originURL: url,
                                                         currentProgress: progress,
                                                         completion: updateProgress)
                self.deleteTempFiles(urls: sortedFilesURLs)
            } else {
                newURL = try await self.sortAndWrite(url: url, completion: updateProgress)
            }
            guard newURL != .temporaryDirectory else { throw FileError.unexpected }
            return newURL
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

extension FileSortService {
    private func deleteTempFiles(urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension FileSortService {
    private func sortAndWrite(url: URL, completion: @escaping (Int) async -> Void) async throws -> URL {
        guard
            let handle = try? FileHandle(forReadingFrom: url),
            let actualFileSize = try FileManager.default.attributesOfItem(atPath: url.path())[.size] as? Int
        else { throw FileError.unexpected }

        var totalNumbersCount = actualFileSize / "\(Int.max)\n".lengthOfBytes(using: .utf8)

        let sortSteps = {
            totalNumbersCount * Int(log(Double(totalNumbersCount)))
        }

        let totalSteps = {
            totalNumbersCount * 2 + sortSteps()
        }
        var progress = 0
        var numbers = [Int]()
        var i = 0
        var created = false

        for try await line in url.lines {
            guard let num = Int(line) else { throw FileError.unexpected }
            numbers.append(num)
            i += 1
            if i % 100_000 == 0 {
                progress = i * 100 / totalSteps()
                await completion(progress)
            }
        }
        totalNumbersCount = i

        let updateProgressWhileSoritngTask = Task(priority: .background) { [progress, totalSteps] in
            var newProgress = progress
            for i in 0 ... sortSteps() {
                if i % 100_000 == 0 {
                    try Task.checkCancellation()
                    newProgress = progress + i * 100 / totalSteps()
                    await completion(newProgress)
                }
            }
        }

        defer {
            numbers.removeAll()
            try? handle.close()
            updateProgressWhileSoritngTask.cancel()
        }
        numbers.sort()
        updateProgressWhileSoritngTask.cancel()
        progress = (totalNumbersCount + sortSteps()) * 100 / totalSteps()
        await completion(progress)

        let oldProgress = progress
        let newURL = url.addingSuffix(suffix: "_sorted")
        created = await fileWriteService.writeToFile(url: newURL, array: numbers) { num in
            progress = oldProgress + num * 100 / totalSteps()
            await completion(progress)
        }
        guard created else { throw FileError.unexpected }

        return newURL
    }

    private func splitToSortedFiles(url: URL,
                                    ram: Int,
                                    completion: @escaping (Int) async -> Void) async throws -> [URL] {
        guard
            let actualFileSize = try FileManager.default.attributesOfItem(atPath: url.path())[.size] as? Int
        else { throw FileError.unexpected }
        var filesURLS = [URL]()
        let numbersInFile = (ram * 60 / 100) / (Int.bitWidth / 8)
        let filesCount = Double(actualFileSize) / Double(numbersInFile * "\(Int.max)\n".lengthOfBytes(using: .utf8))

        var numbers = [Int]()
        defer {
            numbers.removeAll()
        }
        numbers.reserveCapacity(numbersInFile)
        var file = 0
        var fileURL = url.addingSuffix(suffix: "\(file)")
        var i = 1
        var progress = 0
        var created = false
        let totalNumbers = actualFileSize / "\(Int.max)\n".lengthOfBytes(using: .utf8)
        let sortStepsForFile = numbersInFile * Int(log(Double(numbersInFile)))
        let totalSteps = Int(filesCount) * sortStepsForFile + 3 * totalNumbers

        var oldProgress = 0
        for try await line in url.lines {
            numbers.append(Int(line) ?? 0)
            try Task.checkCancellation()
            if i % 100_000 == 0 {
                progress += 1 * 100 / totalSteps
                await completion(progress)
            }
            if i % numbersInFile == 0 {
                let currentProgress = progress
                let updateProgressWhileSoritngTask = Task(priority: .background) { [currentProgress] in
                    var newProgress = currentProgress
                    for i in 0 ... sortStepsForFile {
                        if i % 100_000 == 0 {
                            try Task.checkCancellation()
                            newProgress = currentProgress + i * 100 / totalSteps
                            await completion(newProgress)
                        }
                    }
                }
                numbers.sort()
                updateProgressWhileSoritngTask.cancel()
                progress = sortStepsForFile * (file + 1) * 100 / totalSteps
                await completion(progress)
                oldProgress = progress
                created = await fileWriteService.writeToFile(url: fileURL, array: numbers) { num in
                    progress = oldProgress + (num * 100 / totalSteps)
                    await completion(progress)
                }
                guard created else { throw FileError.unexpected }
                filesURLS.append(fileURL)
                numbers.removeAll(keepingCapacity: true)
                file += 1
                fileURL = url.addingSuffix(suffix: "\(file)")
            }
            i += 1
        }
        oldProgress = progress
        if filesCount.rounded() != filesCount {
            numbers.sort()
            created = await fileWriteService.writeToFile(url: fileURL, array: numbers) { num in
                progress = oldProgress + (num * 100 / totalSteps)
                await completion(progress)
            }
            guard created else { throw FileError.unexpected }
            filesURLS.append(fileURL)
        }

        await completion((2 * totalNumbers + Int(filesCount) * sortStepsForFile) * 100 / totalSteps)
        return filesURLS
    }

    private func mergeSortedFiles(urls: [URL],
                                  originURL: URL,
                                  currentProgress: Int,
                                  completion: @escaping (Int) async -> Void) async throws -> URL {
        var iterators = urls.map { $0.lines.makeAsyncIterator() }
        let newURL = originURL.addingSuffix(suffix: "_sorted")
        guard
            let actualFileSize = try FileManager.default.attributesOfItem(atPath: originURL.path())[.size] as? Int
        else { throw FileError.unexpected }

        let totalNumbers = actualFileSize / "\(Int.max)\n".lengthOfBytes(using: .utf8)
        let numbersInFile = totalNumbers / urls.count
        let filesCount = Double(actualFileSize) / Double(numbersInFile * "\(Int.max)\n".lengthOfBytes(using: .utf8))
        let sortStepsForFile = numbersInFile * Int(log(Double(numbersInFile)))
        let totalSteps = Int(filesCount) * sortStepsForFile + 3 * totalNumbers
        var progress = currentProgress
        FileManager.default.createFile(atPath: newURL.path(), contents: nil)
        guard let handle = try? FileHandle(forWritingTo: newURL) else { throw FileError.unexpected }

        var iterator = 0
        var numbers = [Int?]()
        let bufferSize = 4 * 1024
        var buffer: [UInt8] = []
        buffer.reserveCapacity(bufferSize)
        var minNumber = Int.max
        var k = 0

        for i in 0 ..< iterators.count {
            numbers.append(try await Int(iterators[i].next() ?? ""))
        }

        while !iterators.isEmpty {
            for i in 0 ..< numbers.count {
                if let currentNumber = numbers[i],
                   currentNumber < minNumber {
                    minNumber = currentNumber
                    iterator = i
                } else if numbers[i] == nil {
                    numbers.remove(at: i)
                    iterators.remove(at: i)
                }
            }

            let s = "\(minNumber)\n"
            buffer.append(contentsOf: s.utf8)
            k += 1
            if buffer.count >= bufferSize {
                try handle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
                try Task.checkCancellation()
                progress += (k * 100 / totalSteps)
                await completion(progress)
                k = 0
            }

            minNumber = Int.max
            if let str = try await iterators[iterator].next() {
                numbers[iterator] = Int(str)
            } else {
                iterators.remove(at: iterator)
                numbers.remove(at: iterator)
            }
        }
        return newURL
    }
}
