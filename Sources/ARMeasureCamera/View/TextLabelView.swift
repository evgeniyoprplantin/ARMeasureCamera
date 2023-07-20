//
//  TextLabelView.swift
//
//
//  Created by Evgeniy Opryshko on 20.07.2023.
//

import SwiftUI

public class TextLabelViewViewModel: ObservableObject {
    
    @Published var text: String = "13"
    
    func updateText(_ text: String) {
        print("-->> \(text)")
        self.text = text
    }
}


public struct TextLabelView: View {
    
    @ObservedObject var model: TextLabelViewViewModel

    public var body: some View {
        Text(model.text)
            .foregroundColor(.green)
            .padding(.horizontal, 6)
            .background(Color.white)
            .clipShape(Capsule())
    }
}
