//
//  ContentView.swift
//  Parakeet
//
//  Created by Chris Brind on 10/01/2023.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var model = Model()

    @ViewBuilder
    func folderChooser() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Folder")
                .font(.caption)
                .textCase(.uppercase)

            HStack {
                TextField("Folder", text: $model.folder)
                    .disabled(true)
                Button {
                    model.selectFolder()
                } label: {
                    Image(systemName: "ellipsis")
                }
                Button {
                    Task {
                        await model.refreshView()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }

            Text(model.folderError)
                .font(.footnote)
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    func file(_ entry: String) -> some View {
        ZStack {
            HStack {
                ZStack {
                    GeometryReader { r in
                        Capsule()
                            .frame(width: r.size.width * model.progressForFile(entry))
                            .foregroundColor(.yellow.opacity(0.5))
                    }

                    HStack {
                        Text(entry)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    if model.playingFile == entry {
                        GeometryReader { r in
                            Capsule()
                                .foregroundColor(.white.opacity(0.1))
                                .gesture(DragGesture().onChanged({ value in
                                    let position = value.location.x / r.size.width
                                    self.model.userIsSeeking(toPosition: position)
                                }).onEnded({ value in
                                    let position = value.location.x / r.size.width
                                    self.model.setPlayingPosition(position)
                                }))
                        }
                    }
                }

                if model.playingFile == entry {
                    Button {
                        model.stopPlaying()
                    } label: {
                        Image(systemName: "stop")
                    }
                } else {
                    Button {
                        model.play(file: entry)
                    } label: {
                        Image(systemName: "play")
                    }
                }
            }
            .padding(4)
        }
    }

    @ViewBuilder
    func fileList() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("MP3s")
                .font(.caption)
                .textCase(.uppercase)

            List(selection: $model.selectedFile) {
                ForEach(model.contents, id: \.self) { entry in
                    file(entry)
                        .contextMenu {
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([
                                    model.urlForEntry(entry)
                                ])
                            } label: {
                                Text("Show in Finder")
                            }
                        }
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
        }
    }

    @ViewBuilder
    func toolbar() -> some View {
        HStack {
            Spacer()

            Button {
                model.isShowingAddText = true
            } label: {
                Image(systemName: "plus")
            }
            .disabled(model.folder.isEmpty)
        }.sheet(isPresented: $model.isShowingAddText, content: {
            AddTextView(model: model)
        })
    }

    var body: some View {
        VStack(spacing: 4) {
            folderChooser()
            fileList()
            toolbar()
        }
        .padding()
    }

}
