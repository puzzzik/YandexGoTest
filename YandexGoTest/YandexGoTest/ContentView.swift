//
//  ContentView.swift
//  YandexGoTest
//
//  Created by Иван Тазенков on 11.02.2023.
//

import SwiftUI
import Combine

// MARK: - ContentView

@MainActor
struct ContentView: View {
    @ObservedObject var viewModel: ViewModel
    @State var progress = 0.0
    @State var isCreating: Bool = false

    var body: some View {
        VStack {
            switch viewModel.state {
            case .creating:
                ProgressView(value: viewModel.progress, total: 100) {
                    Text("Создание файла - \(viewModel.progress.formatted()) %")
                }.padding([.bottom], 100)
            case .created:
                Text("Файл создан!").padding([.bottom], 100)
            case .sorting:
                ProgressView(value: viewModel.progress, total: 100) {
                    Text("Сортировка файла - \(viewModel.progress.formatted()) %")
                }.padding([.bottom], 100)
            case .sorted:
                Text("Файл отсортирован!").padding([.bottom], 100)
            case .none:
                Text("").padding([.bottom], 100)
            }

            Text("Размер файла")
            Slider(
                value: $viewModel.fileWeight,
                in: 0.1 ... 10
            ) {
            } minimumValueLabel: {
                Text("1")
            } maximumValueLabel: {
                Text("10")
            } onEditingChanged: { isEditing in
                if !isEditing {
                    viewModel.ramUsed = viewModel.fileWeight / 10
                }
            }
            Text(String(format: "%.02f ", viewModel.fileWeight) + "ГБ")

            Button {
                Task.detached(priority: .high) {
                    await viewModel.generateFile()
                }
            } label: {
                Text("Сгенерировать файл")
            }
            .padding(.bottom, 60)
            Text("Размер ОП")
            Slider(
                value: $viewModel.ramUsed,
                in: 0.1 ... 1
            ) {
            } minimumValueLabel: {
                Text("0.1")
            } maximumValueLabel: {
                Text("1")
            }
            Text(String(format: "%.03f ", viewModel.ramUsed) + "ГБ")

            Button {
                Task.detached(priority: .high) {
                    await viewModel.sortFile()
                }
            } label: {
                Text("Отсортировать файл")
            }
        }
        .padding()
        .buttonStyle(.bordered)
    }


}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ViewModel())
    }
}
