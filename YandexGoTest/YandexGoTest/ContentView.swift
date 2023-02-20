//
//  ContentView.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 11.02.2023.
//

import SwiftUI
import Combine

// MARK: - ContentView

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack {
            weightView
            Spacer()
            progressView
            fileView
        }
        .padding()
        .buttonStyle(.bordered)
    }

    private var sliderRange: ClosedRange<Double> {
        if viewModel.state == .none || viewModel.state == .sorted {
            return 0.1 ... 10
        } else if viewModel.state == .created {
            return 0.1 ... 1
        }
        return 0 ... 0
    }

    @ViewBuilder
    private var progressView: some View {
        switch viewModel.state {
        case .creating, .sorting:
            ProgressView(value: viewModel.progress, total: 100) {
                if viewModel.state == .creating {
                    Text("Создание файла - \(viewModel.progress.formatted()) %")
                } else {
                    Text("Сортировка файла - \(viewModel.progress.formatted()) %")
                }
            }
            .padding([.bottom], 100)
            .progressViewStyle(.circular)
            .scaleEffect(1.2)

        case .created:
            Text("Файл создан!").padding([.bottom], 100)
        case .sorted:
            Text("Файл отсортирован!").padding([.bottom], 100)
        case .none:
            Text("").padding([.bottom], 100)
        }
    }

    @ViewBuilder
    private var fileView: some View {
        if viewModel.state == .none || viewModel.state == .sorted {
            Text("Размер файла")
        } else if viewModel.state == .created {
            Text("Размер ОП")
        }

        if viewModel.state != .creating, viewModel.state != .sorting {
            Slider(
                value: $viewModel.weight,
                in: sliderRange
            ) {
            } minimumValueLabel: {
                Text(String(format: "%.01f ", sliderRange.lowerBound))
            } maximumValueLabel: {
                Text(String(format: "%.01f ", sliderRange.upperBound))
            }

            Text(String(format: "%.02f ", viewModel.weight) + "ГБ")
        }
        button
            .padding(.bottom, 60)
    }

    @ViewBuilder
    private var button: some View {
        Button {
            switch viewModel.state {
            case .creating, .sorting:
                viewModel.cancelTasks()
            case .none, .sorted:
                Task.detached(priority: .high) {
                    await viewModel.generateFile()
                }
            case .created:
                Task.detached(priority: .high) {
                    await viewModel.sortFile()
                }
            }
        } label: {
            switch viewModel.state {
            case .creating, .sorting:
                Text("Отменить")
            case .none, .sorted:
                Text("Сгенерировать файл")
            case .created:
                Text("Отсортировать файл")
            }
        }
    }

    @ViewBuilder
    private var weightView: some View {
        if viewModel.state == .creating {
            Text("Размер файла")
        } else if viewModel.state == .sorting {
            Text("Размер ОП")
        }
        if viewModel.state != .sorted, viewModel.state != .created, viewModel.state != .none {
            Text(String(format: "%.02f ", viewModel.weight) + "ГБ")
        }
    }
}
