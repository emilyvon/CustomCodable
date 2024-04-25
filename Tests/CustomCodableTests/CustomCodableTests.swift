import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CustomCodableMacros)
import CustomCodableMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
]
#endif

final class CustomCodableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(CustomCodableMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(CustomCodableMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testCodable() {
        assertMacroExpansion(
            """
            @Codable
            struct Person {
                var age: Int
                var name: String
            }
            """,
            expandedSource: "",
            macros: ["Codable": CodableMacro.self]
        )
    }

//    func testCodable() {
//        assertMacroExpansion(
//            """
//@Codable
//struct Person {
//    var age: Int
//    var name: String
//}
//""",
//            expandedSource: """
//struct Person {
//    var age: Int
//    var name: String
//
//    enum CodingKeys: CodingKey {
//        case age
//        case name
//    }
//
//    init(from decoder: any Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.age = try container.decode(Int.self, forKey: .age)
//        self.name = try container.decode(String.self, forKey: .name)
//    }
//
//    func encode(to encoder: any Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.age, forKey: .age)
//        try container.encode(self.name, forKey: .name)
//    }
//}
//""",
//            macros: testMacros
//        )
//    }
}
