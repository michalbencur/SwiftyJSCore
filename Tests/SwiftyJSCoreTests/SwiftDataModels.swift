//
//  SwiftDataModels.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 08.08.24.
//

import SwiftData

@Model
class User: Codable {
    enum CodingKeys: CodingKey {
        case id, name, posts
    }
    
    var id: Int
    var name: String
    var posts: [Post]
    
    init(id: Int, name: String, posts: [Post]) {
        self.id = id
        self.name = name
        self.posts = posts
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        posts = try container.decode([Post].self, forKey: .posts)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(posts, forKey: .posts)
    }
}

@Model
class Post: Codable {
    enum CodingKeys: CodingKey {
        case title, content
    }
    
    var title: String
    var content: String
    
    init(title: String, content: String) {
        self.title = title
        self.content = content
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
    }
}
