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
import Markdown

struct MarkdownImporter: MarkupVisitor {
  typealias Result = Lexical.Node

  mutating func defaultVisit(_ markup: Markup) -> Lexical.Node {
    let paragraph = createParagraphNode()
    try? paragraph.append(markup.children.map({
      return visit($0)
    }))
    return paragraph
  }

  mutating func visit(_ markup: Markup) -> Lexical.Node {
    return markup.accept(&self)
  }

  mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> Lexical.Node {
    let node = createQuoteNode()
    try? node.append(blockQuote.children.map {
      visit($0)
    })
    return node
  }

  mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> Lexical.Node {
    let node = createCodeNode()
    try? node.append(codeBlock.children.map {
      visit($0)
    })
    return node
  }

  mutating func visitCustomBlock(_ customBlock: CustomBlock) -> Lexical.Node {
    return defaultVisit(customBlock)
  }

  mutating func visitDocument(_ document: Document) -> Lexical.Node {
    let paragraph = createParagraphNode()
    try? paragraph.append(document.children.map({
      return visit($0)
    }))
    return paragraph
  }

  mutating func visitHeading(_ heading: Heading) -> HeadingNode {
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
    default:
      node = createHeadingNode(headingTag: .h1)
    }
    try? node.append([createTextNode(text: heading.plainText)])
    return node
  }

  mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Lexical.Node {
    return defaultVisit(thematicBreak)
  }

  mutating func visitHTMLBlock(_ html: HTMLBlock) -> Lexical.Node {
    return defaultVisit(html)
  }

  mutating func visitListItem(_ listItem: ListItem) -> Lexical.Node {
    let node = ListItemNode()
    try? node.append(listItem.children.map {
      return visit($0)
    })
    return node
  }

  mutating func visitOrderedList(_ orderedList: OrderedList) -> Lexical.Node {
    var node = createListNode(listType: .number)
    if let newNode = try? node.setStart(Int(orderedList.startIndex)) {
      node = newNode
    }
    try? node.append(orderedList.children.map {
      visit($0)
    })
    return node
  }

  mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> Lexical.Node {
    // TODO (mani) - we need to figure out how to to checked lists
    let node = createListNode(listType: .bullet)
    try? node.append(unorderedList.children.map {
      visit($0)
    })
    return node
  }

  mutating func visitParagraph(_ paragraph: Paragraph) -> Lexical.Node {
    let node = createParagraphNode()
    try? node.append(paragraph.children.map {
      visit($0)
    })
    return node
  }

  mutating func visitBlockDirective(_ blockDirective: BlockDirective) -> Lexical.Node {
    return defaultVisit(blockDirective)
  }

  mutating func visitInlineCode(_ inlineCode: InlineCode) -> Lexical.Node {
    let node = createTextNode(text: inlineCode.code)
    var format = node.getFormat()
    format.code = true
    return (try? node.setFormat(format: format)) ?? node
  }

  mutating func visitCustomInline(_ customInline: CustomInline) -> Lexical.Node {
    return defaultVisit(customInline)
  }

  mutating func visitEmphasis(_ emphasis: Emphasis) -> Lexical.Node {
    let text = createTextNode(text: emphasis.plainText)
    var format = text.getFormat()
    format.italic = true
    return (try? text.setFormat(format: format)) ?? text
  }

  mutating func visitImage(_ image: Image) -> Lexical.Node {
    return defaultVisit(image)
  }

  mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> Lexical.Node {
    return defaultVisit(inlineHTML)
  }

  mutating func visitLineBreak(_ lineBreak: LineBreak) -> Lexical.Node {
    Lexical.LineBreakNode()
  }

  mutating func visitLink(_ link: Link) -> Lexical.Node {
    let node = LinkPlugin().createLinkNode(url: link.destination ?? "")
    // TODO (mani) - what about formatted text that is a link?
    try? node.append([TextNode(text: link.title ?? "")])
    return defaultVisit(link)
  }

  mutating func visitSoftBreak(_ softBreak: SoftBreak) -> Lexical.Node {
    return defaultVisit(softBreak)
  }

  mutating func visitStrong(_ strong: Strong) -> Lexical.Node {
    let text = createTextNode(text: strong.plainText)
    var format = text.getFormat()
    format.bold = true
    return (try? text.setFormat(format: format)) ?? text
  }

  mutating func visitText(_ text: Text) -> Lexical.Node {
    return Lexical.TextNode(text: text.string)
  }

  mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> Lexical.Node {
    let text = createTextNode(text: strikethrough.plainText)
    var format = text.getFormat()
    format.strikethrough = true
    return (try? text.setFormat(format: format)) ?? text
  }

  mutating func visitTable(_ table: Table) -> Lexical.Node {
    return defaultVisit(table)
  }

  mutating func visitTableHead(_ tableHead: Table.Head) -> Lexical.Node {
    return defaultVisit(tableHead)
  }

  mutating func visitTableBody(_ tableBody: Table.Body) -> Lexical.Node {
    return defaultVisit(tableBody)
  }

  mutating func visitTableRow(_ tableRow: Table.Row) -> Lexical.Node {
    return defaultVisit(tableRow)
  }

  mutating func visitTableCell(_ tableCell: Table.Cell) -> Lexical.Node {
    return defaultVisit(tableCell)
  }

  mutating func visitSymbolLink(_ symbolLink: SymbolLink) -> Lexical.Node {
    return defaultVisit(symbolLink)
  }

  mutating func visitInlineAttributes(_ attributes: InlineAttributes) -> Lexical.Node {
    return defaultVisit(attributes)
  }

  mutating func visitDoxygenParameter(_ doxygenParam: DoxygenParameter) -> Lexical.Node {
    return defaultVisit(doxygenParam)
  }

  mutating func visitDoxygenReturns(_ doxygenReturns: DoxygenReturns) -> Lexical.Node {
    return defaultVisit(doxygenReturns)
  }
}
