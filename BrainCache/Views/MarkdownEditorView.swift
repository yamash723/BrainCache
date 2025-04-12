import SwiftUI
import UIKit

struct MarkdownEditorView: View {
    @Binding var text: String
    
    var body: some View {
        UITextViewRepresentable(text: $text)
            .padding(10)
    }
}

struct UITextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.autocapitalizationType = .sentences
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.autocorrectionType = .default
        
        // キーボードツールバーの設定
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let bulletButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: context.coordinator, action: #selector(Coordinator.insertBullet))
        let numberedListButton = UIBarButtonItem(image: UIImage(systemName: "list.number"), style: .plain, target: context.coordinator, action: #selector(Coordinator.insertNumberedList))
        let headingButton = UIBarButtonItem(image: UIImage(systemName: "textformat.size"), style: .plain, target: context.coordinator, action: #selector(Coordinator.insertHeading))
        let boldButton = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: context.coordinator, action: #selector(Coordinator.formatBold))
        let italicButton = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: context.coordinator, action: #selector(Coordinator.formatItalic))
        let indentButton = UIBarButtonItem(image: UIImage(systemName: "increase.indent"), style: .plain, target: context.coordinator, action: #selector(Coordinator.increaseIndent))
        let outdentButton = UIBarButtonItem(image: UIImage(systemName: "decrease.indent"), style: .plain, target: context.coordinator, action: #selector(Coordinator.decreaseIndent))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        
        toolbar.items = [bulletButton, numberedListButton, headingButton, boldButton, italicButton, indentButton, outdentButton, spacer, doneButton]
        
        textView.inputAccessoryView = toolbar
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewRepresentable
        private var lastText: String = ""
        
        init(_ parent: UITextViewRepresentable) {
            self.parent = parent
            self.lastText = parent.text
        }
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // 改行が入力された場合
            if text == "\n" {
                let nsText = textView.text as NSString
                let lineRange = nsText.lineRange(for: NSRange(location: range.location, length: 0))
                let currentLine = nsText.substring(with: lineRange)
                
                // デバッグ用に現在行を出力
                print("Current line: '\(currentLine)'")
                
                // 箇条書きの行かチェック
                if let match = currentLine.firstMatch(pattern: "^(\\s*)[-*]\\s+(.*)$") {
                    let indentation = match.group(at: 1) ?? ""
                    let bulletPrefix = currentLine.firstMatch(pattern: "^\\s*([-*])")?.group(at: 1) ?? "-"
                    let content = match.group(at: 2) ?? ""
                    
                    // デバッグ用に解析結果を出力
                    print("Bullet line detected: indent='\(indentation)', prefix='\(bulletPrefix)', content='\(content)'")
                    
                    // カーソル位置が行の途中かどうかを確認
                    let isCursorInMiddle = range.location < lineRange.location + lineRange.length - 1
                    
                    if isCursorInMiddle {
                        // 行の途中での改行の場合
                        // 改行を許可し、次のイベントループで処理
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            // カーソル位置を取得
                            if let selectedRange = textView.selectedTextRange {
                                // 新しい行の先頭に箇条書き記号を挿入
                                let bulletText = "\(indentation)\(bulletPrefix) "
                                textView.replace(selectedRange, withText: bulletText)
                            }
                        }
                        return true
                    } else {
                        // 行末での改行の場合
                        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            // 内容がある場合は新しい箇条書きを追加
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                // 改行後に箇条書きを挿入
                                if let selectedRange = textView.selectedTextRange {
                                    let bulletText = "\(indentation)\(bulletPrefix) "
                                    textView.replace(selectedRange, withText: bulletText)
                                }
                            }
                            return true
                        } else {
                            // 空の箇条書きの場合、箇条書きを削除して改行だけにする
                            textView.text = (nsText.replacingCharacters(in: lineRange, with: ""))
                            
                            // カーソル位置を調整
                            if let newPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location) {
                                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                            }
                            
                            // テキスト変更を通知
                            parent.text = textView.text
                            lastText = textView.text
                            
                            return false // テキスト変更をキャンセル（すでに処理したため）
                        }
                    }
                }
                
                // 箇条書きの行で、末尾に余分なスペースがある場合（"- asdasdsa    "のような場合）
                if let match = currentLine.firstMatch(pattern: "^(\\s*)[-*]\\s+(.+?)\\s+$") {
                    let indentation = match.group(at: 1) ?? ""
                    let bulletPrefix = currentLine.firstMatch(pattern: "^\\s*([-*])")?.group(at: 1) ?? "-"
                    let content = match.group(at: 2) ?? ""
                    
                    // デバッグ用に解析結果を出力
                    print("Bullet line with trailing spaces: indent='\(indentation)', prefix='\(bulletPrefix)', content='\(content)'")
                    
                    // 内容がある場合は新しい箇条書きを追加
                    if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            // 改行後に箇条書きを挿入
                            if let selectedRange = textView.selectedTextRange {
                                let bulletText = "\(indentation)\(bulletPrefix) "
                                textView.replace(selectedRange, withText: bulletText)
                            }
                        }
                        return true
                    }
                }
                
                // 番号付きリストの行かチェック
                if let match = currentLine.firstMatch(pattern: "^(\\s*)(\\d+)\\.\\s+(.*)$") {
                    let indentation = match.group(at: 1) ?? ""
                    let number = Int(match.group(at: 2) ?? "0") ?? 0
                    let content = match.group(at: 3) ?? ""
                    
                    // カーソル位置が行の途中かどうかを確認
                    let isCursorInMiddle = range.location < lineRange.location + lineRange.length - 1
                    
                    if isCursorInMiddle {
                        // 行の途中での改行の場合
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            // カーソル位置を取得
                            if let selectedRange = textView.selectedTextRange {
                                // 新しい行の先頭に番号付きリスト記号を挿入
                                let listPrefix = "\(indentation)\(number + 1). "
                                textView.replace(selectedRange, withText: listPrefix)
                            }
                        }
                        return true
                    } else {
                        // 行末での改行の場合
                        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            // 内容がある場合は新しい番号付きリストを追加
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                // 改行後に番号付きリストを挿入
                                if let selectedRange = textView.selectedTextRange {
                                    let listPrefix = "\(indentation)\(number + 1). "
                                    textView.replace(selectedRange, withText: listPrefix)
                                }
                            }
                            return true
                        } else {
                            // 空の番号付きリストの場合、リストを削除して改行だけにする
                            textView.text = (nsText.replacingCharacters(in: lineRange, with: ""))
                            
                            // カーソル位置を調整
                            if let newPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location) {
                                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                            }
                            
                            // テキスト変更を通知
                            parent.text = textView.text
                            lastText = textView.text
                            
                            return false // テキスト変更をキャンセル（すでに処理したため）
                        }
                    }
                }
            }
            
            return true // デフォルトの処理を許可
        }

        // テキスト変更後の処理
        func textViewDidChange(_ textView: UITextView) {
            let newText = textView.text
            
            // テキストが変更されたときの処理
            if newText != lastText {
                // 改行以外のテキスト変更の処理
                handleNonNewlineTextChange(textView: textView, oldText: lastText, newText: newText ?? "")
            }
            
            parent.text = newText ?? ""
            lastText = newText ?? ""
        }
        
        // 改行以外のテキスト変更を処理
        private func handleNonNewlineTextChange(textView: UITextView, oldText: String, newText: String) {
            // テキストが短くなった場合（バックスペースが押された可能性）
            if newText.count < oldText.count {
                handleBackspace(textView: textView, oldText: oldText, newText: newText)
            }
        }
        
        // バックスペースの処理
        private func handleBackspace(textView: UITextView, oldText: String, newText: String) {
            guard let selectedRange = textView.selectedTextRange else { return }
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            
            // 現在の行を取得
            let nsText = newText as NSString
            let lineRange = nsText.lineRange(for: NSRange(location: min(cursorPosition, nsText.length - 1), length: 0))
            let currentLine = nsText.substring(with: lineRange)
            
            // 箇条書きの記号だけが残っている場合
            if currentLine == "- " || currentLine == "* " {
                // 箇条書き記号を完全に削除
                let updatedText = (nsText.replacingCharacters(in: lineRange, with: ""))
                textView.text = updatedText
                parent.text = updatedText
                lastText = updatedText
                
                // カーソル位置を調整
                if let newPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location) {
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
            }
            
            // 番号付きリストの記号だけが残っている場合
            let numberedListPattern = #"^\d+\. $"#
            if currentLine.matches(pattern: numberedListPattern) {
                // 番号付きリスト記号を完全に削除
                let updatedText = (nsText.replacingCharacters(in: lineRange, with: ""))
                textView.text = updatedText
                parent.text = updatedText
                lastText = updatedText
                
                // カーソル位置を調整
                if let newPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location) {
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
            }
        }
        
        // 現在の行インデックスを取得するヘルパーメソッド
        private func getCurrentLineIndex(textView: UITextView, position: Int) -> Int {
            let text = textView.text ?? ""
            let lines = text.components(separatedBy: "\n")
            
            var charCount = 0
            for (index, line) in lines.enumerated() {
                charCount += line.count + 1 // +1 は改行文字の分
                if charCount > position {
                    return index
                }
            }
            
            return max(0, lines.count - 1)
        }
        
        private func removeEmptyListItem(textView: UITextView, lineIndex: Int, lines: [String]) {
            var updatedLines = lines
            updatedLines[lineIndex] = ""
            
            // テキストを更新
            let newText = updatedLines.joined(separator: "\n")
            textView.text = newText
            parent.text = newText
            lastText = newText
            
            // カーソル位置を調整
            if let position = textView.position(from: textView.beginningOfDocument, offset: calculateOffset(for: lineIndex, in: updatedLines)) {
                textView.selectedTextRange = textView.textRange(from: position, to: position)
            }
        }
        
        private func calculateOffset(for lineIndex: Int, in lines: [String]) -> Int {
            var offset = 0
            for i in 0..<lineIndex {
                offset += lines[i].count + 1 // +1 は改行文字の分
            }
            return offset
        }
        
        private func insertAtCurrentPosition(textView: UITextView, text: String) {
            guard let selectedRange = textView.selectedTextRange else { return }
            textView.replace(selectedRange, withText: text)
        }
        
        @objc func insertBullet() {
            guard let textView = currentTextView() else { return }
            
            // テキストが空かどうかをチェック
            if textView.text.isEmpty {
                // テキストが空の場合、単に箇条書きを挿入
                textView.text = "- "
                
                // カーソル位置を箇条書きの後ろに設定
                if let endPosition = textView.position(from: textView.beginningOfDocument, offset: 2) {
                    textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
                }
                
                // 親のテキストを更新
                parent.text = textView.text
                lastText = textView.text
                return
            }
            
            // 現在行のインデントを取得
            let indentation = getCurrentLineIndentation(textView: textView)
            insertAtCurrentPosition(textView: textView, text: "\(indentation)- ")
        }

        @objc func insertNumberedList() {
            guard let textView = currentTextView() else { return }
            
            // テキストが空かどうかをチェック
            if textView.text.isEmpty {
                // テキストが空の場合、単に番号付きリストを挿入
                textView.text = "1. "
                
                // カーソル位置を番号付きリストの後ろに設定
                if let endPosition = textView.position(from: textView.beginningOfDocument, offset: 3) {
                    textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
                }
                
                // 親のテキストを更新
                parent.text = textView.text
                lastText = textView.text
                return
            }
            
            // 現在行のインデントを取得
            let indentation = getCurrentLineIndentation(textView: textView)
            insertAtCurrentPosition(textView: textView, text: "\(indentation)1. ")
        }

        @objc func insertHeading() {
            guard let textView = currentTextView() else { return }
            
            // テキストが空かどうかをチェック
            if textView.text.isEmpty {
                // テキストが空の場合、単に見出しを挿入
                textView.text = "# "
                
                // カーソル位置を見出しの後ろに設定
                if let endPosition = textView.position(from: textView.beginningOfDocument, offset: 2) {
                    textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
                }
                
                // 親のテキストを更新
                parent.text = textView.text
                lastText = textView.text
                return
            }
            
            // 現在行のインデントを取得
            let indentation = getCurrentLineIndentation(textView: textView)
            insertAtCurrentPosition(textView: textView, text: "\(indentation)# ")
        }

        @objc func formatBold() {
            guard let textView = currentTextView() else { return }
            
            // テキストが空かどうかをチェック
            if textView.text.isEmpty {
                // テキストが空の場合、太字マークアップを挿入
                textView.text = "****"
                
                // カーソル位置を中央に設定
                if let middlePosition = textView.position(from: textView.beginningOfDocument, offset: 2) {
                    textView.selectedTextRange = textView.textRange(from: middlePosition, to: middlePosition)
                }
                
                // 親のテキストを更新
                parent.text = textView.text
                lastText = textView.text
                return
            }
            
            if let selectedRange = textView.selectedTextRange {
                if textView.selectedRange.length > 0 {
                    // テキストが選択されている場合
                    let selectedText = textView.text(in: selectedRange) ?? ""
                    textView.replace(selectedRange, withText: "**\(selectedText)**")
                } else {
                    // テキストが選択されていない場合
                    insertAtCurrentPosition(textView: textView, text: "****")
                    
                    // カーソルを中央に移動
                    if let newPosition = textView.position(from: selectedRange.start, offset: 2) {
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
        }

        @objc func formatItalic() {
            guard let textView = currentTextView() else { return }
            
            // テキストが空かどうかをチェック
            if textView.text.isEmpty {
                // テキストが空の場合、斜体マークアップを挿入
                textView.text = "**"
                
                // カーソル位置を中央に設定
                if let middlePosition = textView.position(from: textView.beginningOfDocument, offset: 1) {
                    textView.selectedTextRange = textView.textRange(from: middlePosition, to: middlePosition)
                }
                
                // 親のテキストを更新
                parent.text = textView.text
                lastText = textView.text
                return
            }
            
            if let selectedRange = textView.selectedTextRange {
                if textView.selectedRange.length > 0 {
                    // テキストが選択されている場合
                    let selectedText = textView.text(in: selectedRange) ?? ""
                    textView.replace(selectedRange, withText: "*\(selectedText)*")
                } else {
                    // テキストが選択されていない場合
                    insertAtCurrentPosition(textView: textView, text: "**")
                    
                    // カーソルを中央に移動
                    if let newPosition = textView.position(from: selectedRange.start, offset: 1) {
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
        }

        @objc func increaseIndent() {
            guard let textView = currentTextView() else { return }
            
            // 現在の行の範囲を取得
            if let lineRange = getCurrentLineRange(textView: textView) {
                let currentLine = textView.text(in: lineRange) ?? ""
                
                // カーソル位置の相対位置を計算
                var relativePosition = 0
                let cursorOffset = textView.selectedRange.location
                let lineStart = textView.offset(from: textView.beginningOfDocument, to: lineRange.start)
                relativePosition = cursorOffset - lineStart
                
                // インデントを追加
                let indentedLine = "    " + currentLine
                textView.replace(lineRange, withText: indentedLine)
                
                // カーソル位置を調整（相対位置を維持）
                let lineStartOffset = textView.offset(from: textView.beginningOfDocument, to: lineRange.start)
                let newCursorOffset = lineStartOffset + relativePosition + 4
                
                if let newPosition = textView.position(from: textView.beginningOfDocument, offset: newCursorOffset) {
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
            }
        }

        @objc func decreaseIndent() {
            guard let textView = currentTextView() else { return }
            
            // 現在の行の範囲を取得
            if let lineRange = getCurrentLineRange(textView: textView) {
                let currentLine = textView.text(in: lineRange) ?? ""
                
                // カーソル位置の相対位置を計算
                var relativePosition = 0
                let cursorOffset = textView.selectedRange.location
                let lineStart = textView.offset(from: textView.beginningOfDocument, to: lineRange.start)
                relativePosition = cursorOffset - lineStart
                
                // インデントを削除
                var unindentedLine = currentLine
                var indentRemoved = 0
                
                if currentLine.hasPrefix("    ") {
                    unindentedLine = String(currentLine.dropFirst(4))
                    indentRemoved = 4
                } else if currentLine.hasPrefix("\t") {
                    unindentedLine = String(currentLine.dropFirst(1))
                    indentRemoved = 1
                } else if currentLine.hasPrefix("  ") {
                    unindentedLine = String(currentLine.dropFirst(2))
                    indentRemoved = 2
                } else if currentLine.hasPrefix(" ") {
                    unindentedLine = String(currentLine.dropFirst(1))
                    indentRemoved = 1
                }
                
                if indentRemoved > 0 {
                    textView.replace(lineRange, withText: unindentedLine)
                    
                    // カーソル位置を調整（相対位置を維持）
                    let lineStartOffset = textView.offset(from: textView.beginningOfDocument, to: lineRange.start)
                    let newRelativePosition = max(relativePosition - indentRemoved, 0)
                    let newCursorOffset = lineStartOffset + newRelativePosition
                    
                    if let newPosition = textView.position(from: textView.beginningOfDocument, offset: newCursorOffset) {
                        textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
        }
        
        @objc func doneButtonTapped() {
            currentTextView()?.resignFirstResponder()
        }
        
        // 現在のUITextViewを取得
        private func currentTextView() -> UITextView? {
            // iOS 15以降の推奨方法
            if #available(iOS 15.0, *) {
                // 現在のシーンからウィンドウを取得
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = scene.windows.first else {
                    return nil
                }
                return window.rootViewController?.view.findFirstResponder() as? UITextView
            } else {
                // iOS 14以前の方法（後方互換性のため）
                return UIApplication.shared.windows.first?.rootViewController?.view.findFirstResponder() as? UITextView
            }
        }
        
        // 現在行の範囲を取得
        private func getCurrentLineRange(textView: UITextView) -> UITextRange? {
            // テキストが空の場合
            if textView.text.isEmpty {
                if let startPosition = textView.position(from: textView.beginningOfDocument, offset: 0),
                   let endPosition = textView.position(from: textView.beginningOfDocument, offset: 0) {
                    return textView.textRange(from: startPosition, to: endPosition)
                }
                return nil
            }
            
            guard let selectedRange = textView.selectedTextRange else { return nil }
            
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            let text = textView.text as NSString
            
            // 現在行の範囲を取得
            let lineRange = text.lineRange(for: NSRange(location: min(cursorPosition, text.length - 1), length: 0))
            
            guard let startPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location),
                  let endPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location + lineRange.length) else {
                return nil
            }
            
            return textView.textRange(from: startPosition, to: endPosition)
        }

        // 現在行のインデントを取得
        private func getCurrentLineIndentation(textView: UITextView) -> String {
            // テキストが空の場合
            if textView.text.isEmpty {
                return ""
            }
            
            guard let lineRange = getCurrentLineRange(textView: textView) else { return "" }
            
            let currentLine = textView.text(in: lineRange) ?? ""
            if let match = currentLine.firstMatch(pattern: "^(\\s*).*$") {
                return match.group(at: 1) ?? ""
            }
            
            return ""
        }

    }

}

// MARK: - Helper Extensions

extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        
        for subview in subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        
        return nil
    }
}

extension String {
    func matches(pattern: String) -> Bool {
        return firstMatch(pattern: pattern) != nil
    }
    
    struct RegexMatch {
        let match: NSTextCheckingResult
        let string: String
        
        func group(at index: Int) -> String? {
            let range = match.range(at: index)
            if range.location != NSNotFound {
                return (string as NSString).substring(with: range)
            }
            return nil
        }
    }
    
    func firstMatch(pattern: String) -> RegexMatch? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            if let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.count)) {
                return RegexMatch(match: match, string: self)
            }
        } catch {
            print("正規表現エラー: \(error)")
        }
        return nil
    }
}
