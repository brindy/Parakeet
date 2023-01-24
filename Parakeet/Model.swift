//
//  Model.swift
//  Parakeet
//
//  Created by Chris Brind on 10/01/2023.
//

import Foundation
import AWSPolly
import AWSClientRuntime
import AppKit

class Model: ObservableObject {

    lazy var player: Player = {
        return Player { file, position in
            self.playingFile = file
            self.playingPosition = position
        } audioFinished: { file in
            if self.playingFile == file {
                self.playingFile = nil
                self.playingPosition = 0.0
            }
        }
    } ()

    let client: PollyClient = {
        do {
            let config = Config.load()
            let creds = try AWSClientRuntime.AWSCredentialsProvider.fromStatic(config.creds)
            let clientConfig = try PollyClient.PollyClientConfiguration(credentialsProvider: creds, region: config.region)
            return PollyClient(config: clientConfig)
        } catch {
            fatalError(error.localizedDescription)
        }
    } ()

    @Published var folder = ""
    @Published var folderError = ""
    @Published var contents = [String]()
    @Published var selectedFile: String?
    @Published var playingFile: String?
    @Published var playingPosition = 0.0
    @Published var isShowingAddText = false

    @Published var isGeneratingSpeech = false

    @MainActor
    func createSpeech(_ text: String, withTitle title: String, andVoice voice: PollyClientTypes.VoiceId) {
        isGeneratingSpeech = true

        guard !text.isEmpty, !title.isEmpty else { return }

        let url = URL(fileURLWithPath: folder)
            .appending(path: title)
            .appendingPathExtension("mp3")
            .standardizedFileURL
        print(#function, url)

        Task {
            do {
                try await downloadSpeech(text: text, usingVoice: voice, toURL: url)
                await refreshView()
                Task { @MainActor in
                    self.isGeneratingSpeech = false
                    self.isShowingAddText = false
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    func downloadSpeech(text: String, usingVoice voice: PollyClientTypes.VoiceId, toURL url: URL) async throws {
        print(#function, text)

        var input = SynthesizeSpeechInput()
        input.text = text
        input.voiceId = voice
        input.outputFormat = .mp3
        input.engine = .neural

        let result = try await client.synthesizeSpeech(input: input)
        print(result.contentType as Any)

        guard let data = result.audioStream?.toBytes().toData() else {
            print("Failed to convert stream to Data")
            return
        }

        try data.write(to: url)
        print(url)
    }

    @MainActor
    func selectFolder() {

        Task {
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            openPanel.canChooseFiles = false

            switch await openPanel.begin() {
            case .OK:
                folder = openPanel.url?.path ?? ""
                folderError = ""
                await refreshView()

            default: break
            }
        }
    }

    func urlForEntry(_ entry: String) -> URL {
        return URL(fileURLWithPath: folder).appending(path: entry)
    }

    @MainActor
    func refreshView() async {
        let fm = FileManager.default
        do {
            contents = try fm.contentsOfDirectory(atPath: folder)
                .filter { $0.hasSuffix(".mp3") }
                .sorted(by: { $0.lowercased() < $1.lowercased() })
        } catch {
            folderError = "\(error.localizedDescription)"
        }
    }

    func userIsSeeking(toPosition position: Double) {
        playingPosition = position
        player.pause()
    }

    func play(file: String) {
        player.play(file: file, inFolder: folder)
        playingFile = file
    }

    func stopPlaying() {
        player.stop()
    }

    func progressForFile(_ file: String) -> Double {
        if file == playingFile {
            return playingPosition
        }
        return 0.0
    }

    func setPlayingPosition(_ position: Double) {
        player.setPosition(min(max(0.0, position), 1.0))
    }
}

extension Model {
    
    // This could also have some UI and then store the credentials somewhere, e.g. UserDefaults
    struct Config {

        static func load() -> (creds: AWSCredentialsProviderStaticConfig, region: String) {

            let url = FileManager.default.homeDirectoryForCurrentUser.appending(path: "config").appendingPathExtension("json")

            // We're just going to crash for now if we can't read the file or this format is wrong, check the console for info
            let data = try! Data(contentsOf: url)
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: String]
            let accessKey = json["accessKey"]!
            let secret = json["secret"]!
            let region = json["region"]!

            return (creds: AWSCredentialsProviderStaticConfig(accessKey: accessKey, secret: secret), region: region)
        }

    }

}
