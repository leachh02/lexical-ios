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
  typealias Result = [Lexical.Node]

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
    let node = createCodeNode()
    let children = codeBlock.children.flatMap { visit($0) }
    try? node.append(children)
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
      default:
        node = createHeadingNode(headingTag: .h1)
      }
    try? node.append([createTextNode(text: heading.plainText)])
    return [node]
  }

  mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> Result {
    return defaultVisit(thematicBreak)
  }

  mutating func visitHTMLBlock(_ html: HTMLBlock) -> Result {
    return defaultVisit(html)
  }

  mutating func visitListItem(_ listItem: ListItem) -> Result {
    let node = ListItemNode()
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
    let node = createListNode(listType: .bullet)
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
    let text = createTextNode(text: emphasis.plainText)
    var format = text.getFormat()
    format.italic = true
    return [(try? text.setFormat(format: format)) ?? text]
  }

  mutating func visitImage(_ image: Image) -> Result {
    return defaultVisit(image)
  }

  mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> Result {
    return defaultVisit(inlineHTML)
  }

  mutating func visitLineBreak(_ lineBreak: LineBreak) -> Result {
    return [Lexical.LineBreakNode()]
  }

  mutating func visitLink(_ link: Link) -> Result {
    let node = LinkPlugin().createLinkNode(url: link.destination ?? "")
    let children = link.children.flatMap { visit($0) }
    try? node.append(children)
    return [node]
  }

  mutating func visitSoftBreak(_ softBreak: SoftBreak) -> Result {
    return [Lexical.LineBreakNode()]
  }

  mutating func visitStrong(_ strong: Strong) -> Result {
    let text = createTextNode(text: strong.plainText)
    var format = text.getFormat()
    format.bold = true
    return [(try? text.setFormat(format: format)) ?? text]
  }

  mutating func visitText(_ text: Text) -> Result {
    return [Lexical.TextNode(text: text.string)]
  }

  mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> Result {
    let text = createTextNode(text: strikethrough.plainText)
    var format = text.getFormat()
    format.strikethrough = true
    return [(try? text.setFormat(format: format)) ?? text]
  }

  mutating func visitTable(_ table: Table) -> Result {
    return defaultVisit(table)
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
}
