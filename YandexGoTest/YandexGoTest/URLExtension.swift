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

public extension Array where Element: Comparable {
    mutating func mergeSort() throws {
        let startSlice = self[0 ..< count]
        let slice = try mergeSort(startSlice)
        let array = Array(slice)
        self = array
    }

//    func mergeSorted() -> [Element] {
//        let startSlice = self[0 ..< count]
//        let slice = mergeSort(startSlice)
//        let array = Array(slice)
//        return array
//    }

    private func mergeSort(_ array: ArraySlice<Element>) throws -> ArraySlice<Element> {
        try Task.checkCancellation()
        if array.count < 2 {
            return array
        } else {
            let midIndex = (array.endIndex + array.startIndex) / 2
            let slice1 = try mergeSort(array[array.startIndex ..< midIndex])
            let slice2 = try mergeSort(array[midIndex ..< array.endIndex])
            return merge(slice1, slice2)
        }
    }

    private func merge(_ firstArray: ArraySlice<Element>, _ secondArray: ArraySlice<Element>) -> ArraySlice<Element> {
        var newArray = ArraySlice<Element>()
        newArray.reserveCapacity(firstArray.count + secondArray.count)
        var index1 = firstArray.startIndex
        var index2 = secondArray.startIndex

        while index1 < firstArray.endIndex, index2 < secondArray.endIndex {
            if firstArray[index1] < secondArray[index2] {
                newArray.append(firstArray[index1])
                index1 += 1
            } else {
                newArray.append(secondArray[index2])
                index2 += 1
            }
        }

        if index1 < firstArray.endIndex {
            let range = index1 ..< firstArray.endIndex
            let remainingElements = firstArray[range]
            newArray.append(contentsOf: remainingElements)
        }
        if index2 < secondArray.endIndex {
            let range = index2 ..< secondArray.endIndex
            let remainingElements = secondArray[range]
            newArray.append(contentsOf: remainingElements)
        }

        return newArray
    }
}
