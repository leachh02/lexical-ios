//
//  UnsupportedMarkdownNode.swift
//  Lexical
//
//  Created by Harrison Leach on 4/8/2025.
//


import Foundation
import Lexical

extension NodeType {
  public static let unsupportedMarkdown = NodeType(rawValue: "unsupportedMarkdown")
}

public enum UnsupportedMarkdownType: String, CaseIterable, Codable {
  case thematicBreak = "thematicBreak"
  case table = "table"
  case HTMLBlock = "HTMLBlock"
  case inlineHTML = "inlineHTML"
}

open class UnsupportedMarkdownNode: TextNode {
  
  enum CodingKeys: String, CodingKey {
    case markdownType
  }
  
  private var markdownType: UnsupportedMarkdownType = .thematicBreak
  
  override public init() {
    super.init()
  }
  
    required public init(text: String, markdownType: UnsupportedMarkdownType, key: NodeKey? = nil) {
    super.init(text: text, key: key)
    self.markdownType = markdownType
  }
  
  public required convenience init(rawMarkdown: String, markdownType: UnsupportedMarkdownType, key: NodeKey?) {
    self.init(text: rawMarkdown, markdownType: markdownType, key: key)
  }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try super.init(from: decoder)
    self.markdownType = try container.decode(UnsupportedMarkdownType.self, forKey: .markdownType)
  }
  
  public required convenience init(text: String, key: NodeKey?) {
    self.init(text: text, markdownType: .thematicBreak, key: key)
  }

  override open class func getType() -> NodeType {
    return .unsupportedMarkdown
  }
  
  override public func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.markdownType, forKey: .markdownType)
  }
  
  override public func clone() -> Self {
    return Self(text: self.getText_dangerousPropertyAccess(), markdownType: self.markdownType, key: key)
  }
  
  public func getRawMarkdown() -> String {
    let latest: UnsupportedMarkdownNode = getLatest()
    return latest.getTextPart()
  }
  
  public func getMarkdownType() -> UnsupportedMarkdownType {
    let latest: UnsupportedMarkdownNode = getLatest()
    return latest.markdownType
  }
}
