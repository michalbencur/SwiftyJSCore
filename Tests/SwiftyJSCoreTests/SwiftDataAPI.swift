//
//  SwiftDataAPI.swift
//  SwiftyJSCore
//
//  Created by Michal Bencur on 08.08.24.
//

import SwiftData
import Foundation

actor DatabaseAPI {
    let context: ModelContext
    
    init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: User.self, Post.self,
            configurations: configuration
        )
        context = ModelContext(container)

        let user = User(id: 1, name: "Max", posts: [
            Post(title: "Spring", content: "Spring is amazing."),
            Post(title: "Summer", content: "Summer is great."),
            Post(title: "Fall", content: "Fall is beautiful."),
            Post(title: "Winter", content: "Winter is cold.")
        ])
        context.insert(user)
    }
    
    func fetchUser(id: Int) throws -> User {
        let deccriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == id })
        let user: User = try context.fetch(deccriptor).first!
        return user
    }
}
