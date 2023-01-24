//
//  AddTextView.swift
//  Parakeet
//
//  Created by Chris Brind on 10/01/2023.
//

import SwiftUI
import AWSPolly

struct AddTextView: View {

    let voices = [
        PollyClientTypes.VoiceId.emma,
        PollyClientTypes.VoiceId.matthew,
        PollyClientTypes.VoiceId.justin,
        PollyClientTypes.VoiceId.salli,
    ].sorted(by: { $0.rawValue > $1.rawValue })

    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: Model

    @State var title: String = ""
    @State var text: String = ""
    @State var selectedVoice: PollyClientTypes.VoiceId = .emma

    var body: some View {
        VStack {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $text)
                    .border(.ultraThinMaterial, width: 3)
                Picker("Voice", selection: $selectedVoice) {
                    ForEach(voices, id: \.self) { voiceId in
                        Text(voiceId.rawValue)
                    }
                }
            }
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }

                Spacer()

                if model.isGeneratingSpeech {
                    ProgressView("Generating speech")
                }

                Spacer()

                Button {
                    model.createSpeech(text, withTitle: title, andVoice: selectedVoice)
                } label: {
                    Text("Create Speech")
                }
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .disabled(model.isGeneratingSpeech)
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }

}
