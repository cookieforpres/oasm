package token

import "core:strings"

TokenKind :: enum {
    Eof,
    Illegal,
    
    Identifier,
    Label,
    NumberU8,
    NumberU16,
    NumberU32,
    NumberU64,
    NumberU128,
    NumberI8,
    NumberI16,
    NumberI32,
    NumberI64,
    NumberI128,
    NumberF32,
    NumberF64,
    String,
    Register,

    Comma,

    Nop,
    Halt,
    Mov,
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    And,
    Or,
    Xor,
    Shl,
    Shr,
    Inc,
    Dec,
    Cast,
    Push,
    Pop,
    Str,
    Ld,
    Int,
    Cmp,
    Jmp,
    Jeq,
    Jne,
    Jlt,
    Jgt,
    Jle,
    Jge,
    Call,
    Ret,

    Entry,
    Include,
    Define,
    Debug,

    TypeU8,
    TypeU16,
    TypeU32,
    TypeU64,
    TypeU128,
    TypeI8,
    TypeI16,
    TypeI32,
    TypeI64,
    TypeI128,
    TypeF32,
    TypeF64,  
}

Token :: struct {
    literal: string,
    kind: TokenKind,
}

new_token_from_bytes :: proc(data: []byte, kind: TokenKind) -> Token {
    builder := strings.builder_make()
    strings.write_bytes(&builder, data)
    literal := strings.to_string(builder)
    return Token{literal, kind}
}

new_token_from_string :: proc(literal: string, kind: TokenKind) -> Token {
    return Token{literal, kind}
}

new_token :: proc {
    new_token_from_bytes,
    new_token_from_string,
}

lookup_identifier :: proc(ident: string) -> TokenKind {
    switch ident {
        case "nop": return .Nop
        case "halt": return .Halt
        case "mov": return .Mov
        case "add": return .Add
        case "sub": return .Sub
        case "mul": return .Mul
        case "div": return .Div
        case "mod": return .Mod
        case "and": return .And
        case "or": return .Or
        case "xor": return .Xor
        case "shl": return .Shl
        case "shr": return .Shr
        case "inc": return .Inc
        case "dec": return .Dec
        case "cast": return .Cast
        case "push": return .Push
        case "pop": return .Pop
        case "str": return .Str
        case "ld": return .Ld
        case "int": return .Int
        case "cmp": return .Cmp
        case "jmp": return .Jmp
        case "jeq": return .Jeq
        case "jne": return .Jne
        case "jlt": return .Jlt
        case "jgt": return .Jgt
        case "jle": return .Jle
        case "jge": return .Jge
        case "call": return .Call
        case "ret": return .Ret

        case "@entry": return .Entry
        case "@include": return .Include
        case "@define": return .Define
        case "@debug": return .Debug

        case "u8": return .TypeU8
        case "u16": return .TypeU16
        case "u32": return .TypeU32
        case "u64": return .TypeU64
        case "u128": return .TypeU128
        case "i8": return .TypeI8
        case "i16": return .TypeI16
        case "i32": return .TypeI32
        case "i64": return .TypeI64
        case "i128": return .TypeI128
        case "f32": return .TypeF32
        case "f64": return .TypeF64
    }

    return .Identifier
}