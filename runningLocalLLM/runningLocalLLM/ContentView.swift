//
//  ContentView.swift
//  runningLocalLLM
//
//

import SwiftUI
import MarkdownUI
struct ContentView: View {
    // Make sure to disable sandbox (It should be disabled but double check), As well as got System Settings -> Privacy & Security -> Click on "Full Disk Access" and then upload the app into it.
    // To upload the app right click the icon on the macOS navigation corresponding to the app and click Show in Finder then drag it into the "Full Disk Access" Area.
    @State private var userInput: String = ""
    @State private var responseText: String = "Response will appear here..."
    @State private var isLoading: Bool = false
    @State private var modelName: String = "defaultModel" // Default model meaning when the app opens what model you want to show first. Ex: do ollama list then you may get something like model:latest just write the model name not the :latest part.
    var body: some View {
        VStack {
            Text("💡 Local LLM (Ollama) in SwiftUI")
                .font(.title)
                .padding()
            Picker("Select Model", selection: $modelName) {
                ForEach(["\(modelName)", "second_model", "third_model"], id: \.self) { // Do ollama list, then copy and paste the name for example when you do it you may get a response like llama3.1:latest, copy the llama3.1 do not include the :latest.
                    Text($0)
                }
                
            }
            TextField("Enter your prompt...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: generateResponse) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Generate")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)
            .padding()
            
            ScrollView {
                Markdown(responseText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    func generateResponse() {
        // Check if the userInput is not empty
        guard !userInput.isEmpty else { return }
        // Change isLoading to get the progress view
        isLoading = true
        // Change the response to thinking so we can see what the model is doing
        responseText = "Thinking..."
        // 👇 Use 127.0.0.1 instead of localhost
        // Get the url which is the ollama serve numbers and http://(theNumbers/api/generate)
        let url = URL(string: "http://ollama_serve/api/generate")! // Do ollama serve then copy those numbers and replace the ollama_serve placeholder
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": modelName,  // Change to another model if needed
            "prompt": userInput,
            "stream": false
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // ⏱️ Create a custom URLSession with extended timeout settings
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 600 // 10 minutes for request timeout
        config.timeoutIntervalForResource = 600 // 10 minutes for entire resource load
        let session = URLSession(configuration: config)
        
        // 🧠 Send the request and handle the response
        session.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any],
                   let rawResponse = jsonResponse["response"] as? String {
                    
                    // 🔍 Clean up leading/trailing whitespace (optional)
                    let trimmedResponse = rawResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // ✅ Set it for Markdown rendering
                    responseText = trimmedResponse
                }
                else {
                    responseText = "⚠️ Error: Could not fetch response."
                }
            }
        }.resume()
    }
    
    
}



#Preview {
    ContentView()
}
