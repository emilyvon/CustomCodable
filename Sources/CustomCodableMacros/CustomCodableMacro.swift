import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct CodableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typeName = declaration.as(StructDeclSyntax.self)?.name.text else { return [] }
        let memberList = declaration.memberBlock.members
        let propertyNames = memberList.compactMap { member -> String? in
            guard let propertyName = member
                .decl.as(VariableDeclSyntax.self)?.bindings.first?
                .pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { return nil }
            return propertyName
        }
        let propertyTypes = memberList.compactMap { member -> String? in
            guard let typeName = member
                .decl.as(VariableDeclSyntax.self)?.bindings.first?
                .typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text
            else { return nil }
            return typeName
        }

        let caseNames = propertyNames.map { "case \($0)" }

        let decodes = zip(propertyNames, propertyTypes).map {
            "self.\($0.0) = try container.decode(\($0.1).self, forKey: .\($0.0))"
        }

        let encodes = propertyNames.map {
            "try container.encode(self.\($0), forKey: .\($0))"
        }

        return [
        """
        enum CodingKeys: CodingKey {
            \(raw: caseNames.joined(separator: "\n"))
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            \(raw: decodes.joined(separator: "\n"))
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            \(raw: encodes.joined(separator: "\n"))
        }
        """
        ]
    }
}

public struct CodableKey: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}

@main
struct CustomCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        CodableMacro.self,
        CodableKey.self
    ]
}
