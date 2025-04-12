import SwiftUI

struct MarkdownEditorView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var lastText: String = ""
    
    var body: some View {
        TextEditor(text: $text)
            .focused($isFocused)
            .font(.body)
            .padding(10)
            .onChange(of: text) { oldValue, newValue in
                handleTextChange(oldText: oldValue, newText: newValue)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: { insertBullet() }) {
                        Image(systemName: "list.bullet")
                    }
                    
                    Button(action: { insertNumberedList() }) {
                        Image(systemName: "list.number")
                    }
                    
                    Button(action: { insertHeading() }) {
                        Image(systemName: "textformat.size")
                    }
                    
                    Button(action: { formatBold() }) {
                        Image(systemName: "bold")
                    }
                    
                    Button(action: { formatItalic() }) {
                        Image(systemName: "italic")
                    }
                    
                    Spacer()
                    
                    Button("完了") {
                        isFocused = false
                    }
                }
            }
    }
    
    private func handleTextChange(oldText: String, newText: String) {
        // テキストが短くなった場合（バックスペースが押された可能性）
        if newText.count < oldText.count {
            handleBackspace(oldText: oldText, newText: newText)
        } else {
            // テキストが増えた場合（入力や改行）
            handleMarkdownShortcuts(oldText: oldText, newText: newText)
        }
        
        lastText = newText
    }
    
    private func handleBackspace(oldText: String, newText: String) {
        // 行ごとに分割
        let oldLines = oldText.components(separatedBy: "\n")
        let newLines = newText.components(separatedBy: "\n")
        
        // 行数が同じ場合（行内でのバックスペース）
        if oldLines.count == newLines.count && newLines.count > 0 {
            // 現在の行を特定
            for i in 0..<newLines.count {
                if i < oldLines.count && oldLines[i] != newLines[i] {
                    // この行でバックスペースが押された
                    
                    // 箇条書きの記号だけが残っている場合
                    if newLines[i] == "- " || newLines[i] == "* " {
                        // 箇条書き記号を完全に削除
                        var updatedLines = newLines
                        updatedLines[i] = ""
                        text = updatedLines.joined(separator: "\n")
                        return
                    }
                    
                    // 番号付きリストの記号だけが残っている場合
                    let numberedListPattern = #"^\d+\. $"#
                    if let regex = try? NSRegularExpression(pattern: numberedListPattern),
                       regex.firstMatch(in: newLines[i], range: NSRange(newLines[i].startIndex..., in: newLines[i])) != nil {
                        // 番号付きリスト記号を完全に削除
                        var updatedLines = newLines
                        updatedLines[i] = ""
                        text = updatedLines.joined(separator: "\n")
                        return
                    }
                    
                    break
                }
            }
        }
    }
    
    private func handleMarkdownShortcuts(oldText: String, newText: String) {
        // 改行が追加されたかチェック
        if newText.hasSuffix("\n") && !oldText.hasSuffix("\n") {
            // 最後の2行を取得
            let lines = newText.components(separatedBy: "\n")
            if lines.count >= 2 {
                let previousLine = lines[lines.count - 2]
                
                // 前の行が空の箇条書きかチェック
                if previousLine == "- " || previousLine == "* " {
                    // 空の箇条書きを削除して改行だけにする
                    var updatedLines = lines
                    updatedLines[lines.count - 2] = ""
                    text = updatedLines.joined(separator: "\n")
                    return
                }
                
                // 前の行が空の番号付きリストかチェック
                let numberedListPattern = #"^\d+\. $"#
                if let regex = try? NSRegularExpression(pattern: numberedListPattern),
                   regex.firstMatch(in: previousLine, range: NSRange(previousLine.startIndex..., in: previousLine)) != nil {
                    // 空の番号付きリストを削除して改行だけにする
                    var updatedLines = lines
                    updatedLines[lines.count - 2] = ""
                    text = updatedLines.joined(separator: "\n")
                    return
                }
                
                // 前の行が箇条書きで内容があるかチェック
                if previousLine.hasPrefix("- ") && previousLine.count > 2 {
                    // 新しい箇条書きを追加
                    text.append("- ")
                    return
                } else if previousLine.hasPrefix("* ") && previousLine.count > 2 {
                    // 新しい箇条書きを追加
                    text.append("* ")
                    return
                }
                
                // 前の行が番号付きリストで内容があるかチェック
                let contentNumberedListPattern = #"^(\d+)\. .+"#
                if let regex = try? NSRegularExpression(pattern: contentNumberedListPattern),
                   let match = regex.firstMatch(in: previousLine, range: NSRange(previousLine.startIndex..., in: previousLine)) {
                    
                    if let numberRange = Range(match.range(at: 1), in: previousLine),
                       let number = Int(previousLine[numberRange]) {
                        // 次の番号の番号付きリストを追加
                        text.append("\(number + 1). ")
                        return
                    }
                }
            }
        }
    }
    
    private func insertBullet() {
        // 現在位置に挿入
        text.append("- ")
    }
    
    private func insertNumberedList() {
        // 現在位置に挿入
        text.append("1. ")
    }
    
    private func insertHeading() {
        // 現在位置に挿入
        text.append("# ")
    }
    
    private func formatBold() {
        // 末尾に追加
        text.append("****")
    }
    
    private func formatItalic() {
        // 末尾に追加
        text.append("**")
    }
}
