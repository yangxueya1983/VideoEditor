//
//  Item.swift
//  VideoEditor
//
//  Created by NancyYang on 2024-07-29.
//

import Foundation
import SwiftData
import OSLog
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

protocol Animal {
    var name: String { get }
    var age: Int { get }
}

struct Dog: Animal {
    let name: String
    let age: Int
}

struct Cat: Animal {
    let name: String
    let age: Int
}

func printAnimal(animal: some Animal) -> some Animal {
//    Logger.viewCycle.debug("return a cat named \(animal.name)")
//    if let cat = animal as? Cat {
//        Logger.viewCycle.debug("cat name: \(cat.name)")
//        return cat
//    } else {
//        let dog = animal as! Dog
//        Logger.viewCycle.debug("dog name: \(dog.name)")
//        return dog
//    }
    return Cat(name: animal.name, age: animal.age)
}



let dog: Animal = Dog(name: "Rex", age:10)
let cat: Animal = Cat(name: "Mia", age: 12)
let cat2: Animal = Cat(name: "Mia2", age: 12)
let animals: [any Animal] = [cat2, cat]


