import CustomCodable

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

@Codable
struct Person {
    var age: Int
    var name: String
}
