//
//  MarkdownImporter.swift
//  Lexical
//
//  Created by Harrison Leach on 3/8/2025.
//
import Foundation
import Lexical
import LexicalLinkPlugin
import LexicalListPlugin
import LexicalInlineImagePlugin
import Markdown

struct MarkdownImporter: MarkupVisitor {
  typealias Result = [Lexical.Node]

  // if the importer can not handle type, retain md syntax
  mutating func defaultVisit(_ markup: Markup) -> Result {
    let paragraph = createParagraphNode()
    let children = markup.children.flatMap { visit($0) }
    try? paragraph.append(children)
    return [paragraph]
  }

  mutating func visit(_ markup: Markup) -> Result {
    return markup.accept(&self)
  }

  mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Result {
    let node = createQuoteNode()
    let children = blockQuote.children.flatMap { visit($0) }
    try? node.append(children)
    return [node]
  }

  mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Result {
    let node = createCodeNode(language: codeBlock.language ?? "")
    let codeTextnode = Lexical.TextNode(text: codeBlock.code)
    try? node.append([codeTextnode])
    return [node]
  }

  mutating func visitCustomBlock(_ customBlock: CustomBlock) -> Result {
    return defaultVisit(customBlock)
  }

  mutating func visitDocument(_ document: Document) -> Result {
    return document.children.flatMap { visit($0) }
  }

  mutating func visitHeading(_ heading: Heading) -> Result {
      var node: HeadingNode
      switch heading.level {
      case 1:
        node = createHeadingNode(headingTag: .h1)
      case 2:
        node = createHeadingNode(headingTag: .h2)
      case 3:
        node = createHeadingNode(headingTag: .h3)
      case 4:
        node = createHeadingNode(headingTag: .h4)
      case 5:
        node = createHeadingNode(headingTag: .h5)
      case 6:
        node = createHeadingNode(headingTag: .h6)
      default:
        node = createHeadingNode(headingTag: .h1)
      }
    try? node.append([createTextNode(text: heading.plainText)])
    return [node]
  }

  mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result {
      let node = UnsupportedMarkdownNode(
        rawMarkdown: thematicBreak.format(),
          markdownType: UnsupportedMarkdownType.thematicBreak,
          key: nil
      )
      return [node]
  }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> Result {
          let node = UnsupportedMarkdownNode(
            rawMarkdown: html.rawHTML,
              markdownType: UnsupportedMarkdownType.HTMLBlock,
              key: nil
          )
          return [node]
      }

    mutating func visitListItem(_ listItem: ListItem) -> Result {
        let isTask = listItem.checkbox != nil
        let isChecked = listItem.checkbox == .checked
        
        let node = ListItemNode(isTask: isTask, isChecked: isChecked, key: nil)
        
        let children = listItem.children.flatMap { visit($0) }
        try? node.append(children)
        return [node]
    }
    
  mutating func visitOrderedList(_ orderedList: OrderedList) -> Result {
    var node = createListNode(listType: .number)
    if let newNode = try? node.setStart(Int(orderedList.startIndex)) {
      node = newNode
    }
    let children = orderedList.children.flatMap { visit($0) }
    try? node.append(children)
    return [node]
  }
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> Result {
        // Check if any list items have checkboxes
        let hasAnyCheckboxes = unorderedList.children.contains { child in
            if let listItem = child as? ListItem {
                return listItem.checkbox != nil
            }
            return false
        }
        
        let listType: ListType = hasAnyCheckboxes ? .check : .bullet
        let node = createListNode(listType: listType)
        
        let children = unorderedList.children.flatMap { visit($0) }
        try? node.append(children)
        return [node]
    }

  mutating func visitParagraph(_ paragraph: Paragraph) -> Result {
    let node = createParagraphNode()
    let children = paragraph.children.flatMap { visit($0) }
    try? node.append(children)
    return [node]
  }

  mutating func visitBlockDirective(_ blockDirective: BlockDirective) -> Result {
    return defaultVisit(blockDirective)
  }

  mutating func visitInlineCode(_ inlineCode: InlineCode) -> Result {
    let node = createTextNode(text: inlineCode.code)
    var format = node.getFormat()
    format.code = true
    return [(try? node.setFormat(format: format)) ?? node]
  }

  mutating func visitCustomInline(_ customInline: CustomInline) -> Result {
    return defaultVisit(customInline)
  }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> Result {
        applyInlineFormat(to: emphasis) { $0.italic = true }
    }
    
    mutating func visitImage(_ image: Image) -> Result {
      // Extract alt text from children (assuming only Text nodes)
      let altText = image.children.compactMap { child -> String? in
        if let textNode = child as? Text {
          return textNode.string
        }
        return nil
      }.joined(separator: "")
      
      let imageNode = ImageNode(
        url: image.source!,
        title: image.title,
        altText: altText,
        size: CGSize(width: 300, height: 300),
        sourceID: ""
      )
      return [imageNode]
    }
    
  mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> Result {
          let node = UnsupportedMarkdownNode(
            rawMarkdown: inlineHTML.rawHTML,
              markdownType: UnsupportedMarkdownType.inlineHTML,
              key: nil
          )
          return [node]
      }

  mutating func visitLineBreak(_ lineBreak: LineBreak) -> Result {
    return [Lexical.LineBreakNode()]
  }

  mutating func visitLink(_ link: Link) -> Result {
    let node = LinkPlugin().createLinkNode(url: link.destination ?? "", title: link.title)
    let children = link.children.flatMap { visit($0) }
    try? node.append(children)
    return [node]
  }

  mutating func visitSoftBreak(_ softBreak: SoftBreak) -> Result {
    return [Lexical.LineBreakNode()]
  }

mutating func visitStrong(_ strong: Strong) -> Result {
    applyInlineFormat(to: strong) { $0.bold = true }
}

  mutating func visitText(_ text: Text) -> Result {
    return [Lexical.TextNode(text: text.string)]
  }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> Result {
        applyInlineFormat(to: strikethrough) { $0.strikethrough = true }
    }
    
  mutating func visitTable(_ table: Table) -> Result {
        let node = UnsupportedMarkdownNode(
            rawMarkdown: table.format(),
            markdownType: UnsupportedMarkdownType.table,
            key: nil
        )
        return [node]
    }

  mutating func visitTableHead(_ tableHead: Table.Head) -> Result {
    return defaultVisit(tableHead)
  }

  mutating func visitTableBody(_ tableBody: Table.Body) -> Result {
    return defaultVisit(tableBody)
  }

  mutating func visitTableRow(_ tableRow: Table.Row) -> Result {
    return defaultVisit(tableRow)
  }

  mutating func visitTableCell(_ tableCell: Table.Cell) -> Result {
    return defaultVisit(tableCell)
  }

  mutating func visitSymbolLink(_ symbolLink: SymbolLink) -> Result {
    return defaultVisit(symbolLink)
  }

  mutating func visitInlineAttributes(_ attributes: InlineAttributes) -> Result {
    return defaultVisit(attributes)
  }

  mutating func visitDoxygenParameter(_ doxygenParam: DoxygenParameter) -> Result {
    return defaultVisit(doxygenParam)
  }

  mutating func visitDoxygenReturns(_ doxygenReturns: DoxygenReturns) -> Result {
    return defaultVisit(doxygenReturns)
  }
    
    mutating func applyInlineFormat(
        to inlineMarkup: InlineMarkup,
        applyFormat: (inout TextFormat) -> Void
    ) -> [Node] {
        var result: [Node] = []

        for child in inlineMarkup.children {
            guard let inline = child as? InlineMarkup else { continue }
            let visited = try? visit(inline)

            for case let text as TextNode in visited ?? [] {
                var format = text.getFormat()
                applyFormat(&format)
                _ = try? text.setFormat(format: format)
                result.append(text)
            }
        }

        return result
    }
}
