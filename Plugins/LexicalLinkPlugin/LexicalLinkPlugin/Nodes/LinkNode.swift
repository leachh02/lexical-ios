/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */


import Lexical
import UIKit

extension NodeType {
  public static let link = NodeType(rawValue: "link")
}

open class LinkNode: ElementNode {
  enum CodingKeys: String, CodingKey {
    case url
    case title
  }

  public var url: String = ""
  public var title: String? = nil

  override public init() {
    super.init()
  }

  public required init(url: String, title: String? = nil, key: NodeKey?) {
    super.init(key)
    self.url = url
    self.title = title
  }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    try super.init(from: decoder)

    self.url = try container.decode(String.self, forKey: .url)
    self.title = try container.decodeIfPresent(String.self, forKey: .title)
  }
  
  override open class func getType() -> NodeType {
    return .link
  }

  override open func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.url, forKey: .url)
    try container.encodeIfPresent(self.title, forKey: .title)
  }

  public func getURL() -> String {
    let latest: LinkNode = getLatest()
    return latest.url
  }

  public func setURL(_ url: String) throws {
    try errorOnReadOnly()
    try getWritable().url = url
  }
  
  public func getTitle() -> String? {
    let latest: LinkNode = getLatest()
    return latest.title
  }

  public func setTitle(_ title: String?) throws {
    try errorOnReadOnly()
    try getWritable().title = title
  }

  override public func canInsertTextBefore() -> Bool {
    return false
  }

  override public func canInsertTextAfter() -> Bool {
    return false
  }

  override public func canBeEmpty() -> Bool {
    return false
  }

  override public func isInline() -> Bool {
    return true
  }

  override open func clone() -> Self {
    Self(url: url, title: title, key: key)
  }

  override public func getAttributedStringAttributes(theme: Theme) -> [NSAttributedString.Key: Any] {
    if url.isEmpty {
      return [:]
    }

    var attribs: [NSAttributedString.Key: Any] = theme.link ?? [:]
    attribs[.link] = url
    return attribs
  }

  override open func insertNewAfter(selection: RangeSelection?) throws -> Node? {
    if let element = try getParentOrThrow().insertNewAfter(selection: selection) as? ElementNode {
      let linkNode = LinkNode(url: url, title: title, key: nil)
      try element.append([linkNode])
      return linkNode
    }

    return nil
  }
}
