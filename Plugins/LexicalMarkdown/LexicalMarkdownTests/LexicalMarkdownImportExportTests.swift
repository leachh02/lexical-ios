//
//  LexicalMarkdownImportExportTests.swift
//  Lexical
//
//  Created by Harrison Leach on 4/8/2025.
//


import XCTest

@testable import Lexical
@testable import LexicalListPlugin
@testable import LexicalMarkdown
@testable import Markdown

final class LexicalMarkdownImportExportTests: XCTestCase {
    var lexicalView: LexicalView?
    var editor: Editor? {
      get {
        return lexicalView?.editor
      }
    }
    
    override func setUp() {
      lexicalView = LexicalView(editorConfig: EditorConfig(theme: Theme(), plugins: []), featureFlags: FeatureFlags())
    }

    override func tearDown() {
      lexicalView = nil
    }

    // MARK: - Helpers

    private func performRoundTrip(inputMarkdown: String, verboseDebug: Bool = false) throws -> String {
        guard let editor = self.editor else {
            XCTFail("Editor not initialized")
            throw NSError(domain: "Editor nil", code: 1)
        }

        try editor.update {
            guard let root = getRoot() else {
                XCTFail("Expected root node")
                return
            }

            // Clear existing content
            try root.getChildren().forEach { try $0.remove() }

            let document = Markdown.Document(parsing: inputMarkdown)
            if verboseDebug {print(document.debugDescription())}
            var importer = MarkdownImporter()
            try root.append(importer.visit(document))
        }
        if verboseDebug {
            let currentEditorState = editor.getEditorState()
            print(try currentEditorState.toJSON())
        }

        let exported = try LexicalMarkdown.generateMarkdown(from: editor, selection: nil)
        
        if verboseDebug {
            let document = Markdown.Document(parsing: exported)
            print(document.debugDescription())
        }
        return exported
    }

    // MARK: - Paragraph

    func testParagraphRoundTrip() throws {
        let input = "This is a simple paragraph."
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Headings

    func testHeadingRoundTrip() throws {
        let input = "# Heading One"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Bold / Italic

    func testBoldTextRoundTrip() throws {
        let input = "**Bold**"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    func testItalicTextRoundTrip() throws {
        let input = "*Italic*"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    func testBoldItalicMixedRoundTrip() throws {
        let input = "***Bold and Italic***"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    
    func testStrikethroughTextRoundTrip() throws {
        let input = "~Strikethrough~"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Block Quotes

    func testBlockQuoteRoundTrip() throws {
        let input = "> Block quote content."
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Lists

    func testLinkRoundTrip() throws {
        let input = "[Link](https://example.com)"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    
    func testUnorderedListRoundTrip() throws {
        let input = """
        - Item 1
        - Item 2
        - Item 3
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    func testOrderedListRoundTrip() throws {
        let input = """
        1. First
        1. Second
        1. Third
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Code Blocks

    func testCodeBlockRoundTrip() throws {
        let input = """
        ```
        let x = 10
        print(x)
        ```
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Horizontal Rule

    func testHorizontalRuleRoundTrip() throws {
        let input = "-----"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Complex

    func testMixedMarkdownRoundTrip() throws {
        let input = """
        # Title

        This is a paragraph with **bold** and *italic* text.

        > A quote block.

        - Bullet 1
        - Bullet 2

        1. Step 1
        1. Step 2
        
        [Link](https://example.com)

        ```
        print("code")
        ```
        
        -----
        """
        let output = try performRoundTrip(inputMarkdown: input, verboseDebug: true)
        XCTAssertEqual(output, input)
    }
    
    // MARK: - Heading Levels

    func testH6HeadingRoundTrip() throws {
        let input = "###### H6 Heading"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    // MARK: - Link Titles

    func testLinkWithTitleRoundTrip() throws {
        let input = #"[Link with title](https://www.example.com/ "Example Website")"#
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Images

    func testImageWithAltAndTitleRoundTrip() throws {
        let input = #"![alt text](https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg "titleeee")"#
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    
    func testImageWithAltRoundTrip() throws {
        let input = #"![alt text](https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg)"#
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    
    //This method is interpreted as just text
    func testLocalImageWithAltRoundTrip() throws {
        let input = #"![[Pasted image 20250802123635.png]]"#
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    
    func testLocalImageWithAltAndTitleRoundTrip() throws {
        let input = #"![alt text](Pasted%20image%2020250802123635.png "titleeee")"#
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
    

    // MARK: - Code Block Languages

    func testJavaScriptCodeBlockRoundTrip() throws {
        let input = """
        ```javascript
        function hello() {
            console.log("Hello, World!");
        }
        ```
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    func testPythonCodeBlockRoundTrip() throws {
        let input = """
        ```python
        def quicksort(arr):
            return arr
        ```
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Tables

    func testBasicTableRoundTrip() throws {
        let input = """
        |Header 1|Header 2|Header 3|
        |--------|--------|--------|
        |Cell 1  |Cell 2  |Cell 3  |
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    func testAlignedTableRoundTrip() throws {
        let input = """
        |Left Aligned|Center Aligned|Right Aligned|
        |:-----------|:------------:|------------:|
        |Left        |Center        |Right        |
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Task Lists

    func testTaskListRoundTrip() throws {
        let input = """
        - [x] Completed task
        - [ ] Incomplete task
        - [x] Another completed task
        - normal
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - HTML Elements

    func testHTMLBlockRoundTrip() throws {
        let input = #"<h1>testing this one ouyt</h1><img src="https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg">"#
        let output = try performRoundTrip(inputMarkdown: input, verboseDebug: true)
        XCTAssertEqual(output, input)
    }

    func testDetailsElementRoundTrip() throws {
        let input = """
        <details> <summary>Click to expand</summary>

        This content is hidden by default and can be expanded.

        </details>
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    func testKbdElementRoundTrip() throws {
        let input = "<kbd>Ctrl</kbd> + <kbd>C</kbd> for copy"
        let output = try performRoundTrip(inputMarkdown: input, verboseDebug: true)
        XCTAssertEqual(output, input)
    }

    // MARK: - Footnotes

    func testFootnoteRoundTrip() throws {
        let input = """
        Here’s a sentence with a footnote[^1].

        [^1]: This is a simple footnote.
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Special Characters

    func testEscapedCharactersRoundTrip() throws {
        let input = "Escaped characters: * _ # [ ] ( ) ` \\ { }"
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }

    // MARK: - Final Test
    
    func testLargeMarkdownFileRoundTrip() throws {
        let input = """
        # Comprehensive Markdown Test File

        This file contains examples of all major Markdown features to test your editor’s rendering capabilities.

        ## Headings

        # H1 Heading

        ## H2 Heading

        ### H3 Heading

        #### H4 Heading

        ##### H5 Heading

        ###### H6 Heading

        # Alternative H1

        ## Alternative H2

        ## Text Formatting

        **Bold text** and **also bold**

        *Italic text* and *also italic*

        ***Bold and italic*** and ***also bold and italic***

        ~Strikethrough text~

        `Inline code` with backticks

        ## Links

        [Basic link](https://www.example.com/)

        [Link with title](https://www.example.com/ "Example Website")

        [https://www.autolink.com](https://www.autolink.com/)

        [Reference link](https://www.reference1.com/ "Reference 1")

        [Another reference](https://www.reference2.com/ "Reference 2")

        ## Images

        local:  
        ![[Pasted image 20250802123635.png]]

        ![alt text](https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg "titleeee")

        html:

        <h1>testing this one ouyt</h1><img src="https://images.pexels.com/photos/674010/pexels-photo-674010.jpeg">
        ## Lists

        ### Unordered Lists

        - Item 1
        - Item 2
          - Nested item 2.1
          - Nested item 2.2
            - Deep nested item 2.2.1
        - Item 3
        - Alternative bullet
        - Another alternative

        ### Ordered Lists

        1. First item
        1. Second item
           1. Nested numbered item
           1. Another nested item
              1. Deep nested numbered item
        1. Third item

        ### Mixed Lists

        1. Numbered item
        
        - Bulleted sub-item
        - Another bulleted sub-item
        
        1. Another numbered item

        ## Code Blocks

        ### Inline Code

        Here’s some `inline code` in a sentence.

        ### Code Blocks (Indented)

        ```
        function hello() {
            console.log("Hello, World!");
        }
        ```

        ### Fenced Code Blocks

        ```
        Plain code block
        No syntax highlighting
        ```

        ```javascript
        // JavaScript code with syntax highlighting
        function fibonacci(n) {
            if (n <= 1) return n;
            return fibonacci(n - 1) + fibonacci(n - 2);
        }

        console.log(fibonacci(10));
        ```

        ```python
        # Python code example
        def quicksort(arr):
            if len(arr) <= 1:
                return arr
            pivot = arr[len(arr) // 2]
            left = [x for x in arr if x < pivot]
            middle = [x for x in arr if x == pivot]
            right = [x for x in arr if x > pivot]
            return quicksort(left) + middle + quicksort(right)

        print(quicksort([3, 6, 8, 10, 1, 2, 1]))
        ```

        ```json
        {
          "name": "Test JSON",
          "version": "1.0.0",
          "features": ["markdown", "syntax highlighting"],
          "nested": {
            "property": true,
            "number": 42
          }
        }
        ```

        ## Blockquotes

        > This is a blockquote. It can span multiple lines.

        > This is a blockquote with multiple paragraphs.
        > 
        > Here’s the second paragraph.

        > ## Blockquote with heading
        > 
        > **Bold text in blockquote**
        > 
        > - List item in blockquote
        > - Another item

        ### Nested Blockquotes

        > This is the first level of quoting.
        > > This is nested blockquote.
        > > > And this is a third level.
        > 
        > Back to first level.

        ## Tables

        ### Basic Table

        |Header 1|Header 2|Header 3|
        |--------|--------|--------|
        |Cell 1  |Cell 2  |Cell 3  |
        |Cell 4  |Cell 5  |Cell 6  |

        ### Aligned Table

        |Left Aligned|Center Aligned|Right Aligned|
        |:-----------|:------------:|------------:|
        |Left        |Center        |Right        |
        |Text        |Text          |Text         |
        |More        |Content       |Here         |

        ### Table with Various Content

        |Feature                     |Supported|Notes            |
        |----------------------------|:-------:|-----------------|
        |**Bold**                    |✅        |Works great      |
        |*Italic*                    |✅        |Also supported   |
        |`Code`                      |✅        |Inline code works|
        |[Links](http://example.com/)|✅        |Links work too   |

        ## Horizontal Rules

        -----

        ## Line Breaks

        This line ends with two spaces  
        So this line appears below it.

        This line has a manual line break  
        Using a backslash.

        This paragraph has no line break so this text continues on the same line.

        ## HTML Elements (if supported)

        <details> <summary>Click to expand</summary>

        This content is hidden by default and can be expanded.

        - Item 1
        - Item 2
        - Item 3

        </details>

        <kbd>Ctrl</kbd> + <kbd>C</kbd> for copy

        <mark>Highlighted text</mark>

        <sub>Subscript</sub> and <sup>Superscript</sup>

        ## Special Characters and Escaping

        Escaped characters: * _ # [ ] ( ) ` \\ { }

        Em dash: — En dash: – Ellipsis: … Quote marks: “smart” ‘quotes’

        ## Task Lists (GitHub Flavored Markdown)

        - [x] Completed task
        - [ ] Incomplete task
        - [x] Another completed task
          - [ ] Nested incomplete task
          - [x] Nested completed task

        ## Footnotes (if supported)

        Here’s a sentence with a footnote[^1].

        Here’s another with a longer footnote[^longnote].

        [^1]: This is a simple footnote.

        [^longnote]: This is a longer footnote with multiple paragraphs.

        ```
        It can contain code blocks, lists, and other elements.

        - Like this list
        - With multiple items
        ```

        ## Definition Lists (if supported)

        Term 1 : Definition for term 1

        Term 2 : Definition for term 2 : Another definition for term 2

        ## Emoji (if supported)

        :smile: :heart: :thumbsup: :rocket: :fire:

        ## Mathematical Expressions (if supported)

        Inline math: $E = mc^2$

        Block math: $$ \\sum_{i=1}^n x_i = x_1 + x_2 + \\cdots + x_n $$

        ## Complex Mixed Content

        Here’s a complex example combining multiple features:

        ### Project Overview

        Our **markdown editor** supports *most* standard features. Here’s what we’ve tested:

        1. **Text formatting** - Works ✅
        1. **Code highlighting** - Partially supported ⚠️
           
           ```swift
           let message = "Hello, World!"print(message)
           ```
        1. **Tables and lists** - Fully supported ✅

        > **Note**: Some advanced features like footnotes and math may not be supported in all renderers.

        |Feature       |Status    |Priority|
        |--------------|:--------:|:------:|
        |Basic Markdown|✅ Complete|High    |
        |Tables        |✅ Complete|Medium  |
        |Code Blocks   |⚠️ Partial |High    |
        |Math          |❌ Missing |Low     |

        For more information, visit our [documentation](https://example.com/docs).

        -----

        ## Testing Notes

        When testing your markdown editor, pay attention to:

        - **Rendering accuracy**: Does the output match expected formatting?
        - **Performance**: How does it handle large documents?
        - **Real-time editing**: Does formatting update as you type?
        - **Cursor behavior**: Does the cursor stay in the right place during formatting changes?
        - **Syntax highlighting**: Are code blocks properly highlighted?
        - **Link handling**: Do links open correctly?
        - **Image loading**: Do images display properly?

        Happy testing! 🚀
        """
        let output = try performRoundTrip(inputMarkdown: input)
        XCTAssertEqual(output, input)
    }
}
