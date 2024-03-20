package compiler

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "../lexer"
import "../token"
import "../opcode"
import "../object"

Compiler :: struct {
    lexer: ^lexer.Lexer,

    current_token: token.Token,
    peek_token: token.Token,

    bytecode: [dynamic]byte,

    labels: map[string]u32,
    fixups: map[u32]string,
}

new_compiler :: proc(lexer: ^lexer.Lexer) -> Compiler {
    c := Compiler{lexer = lexer}

    c.bytecode = make([dynamic]byte)

    c.labels = make(map[string]u32)
    c.fixups = make(map[u32]string)

    next_token(&c)
    next_token(&c)

    return c
}

output :: proc(c: ^Compiler) -> []byte {
    out := make([]byte, len(c.bytecode))
    for i := 0; i < len(c.bytecode); i += 1 {
        out[i] = c.bytecode[i]
    }
    return out
}

write_to_file :: proc(c: ^Compiler, path: string) {
    out := output(c)
    fmt.printf("our bytecode is %d bytes long\n", len(out))
    ok := os.write_entire_file(path, out)
    if !ok {
        fmt.printf("error: failed to write to file: %s\n", path)
        os.exit(1)
    }
    fmt.printf("wrote bytecode to %s\n", path)
}

dump :: proc(c: ^Compiler) {
    for c.current_token.kind != .Eof {
        fmt.printf("%v\n", c.current_token)
        next_token(c)
    }
}

compile :: proc(c: ^Compiler) {
    for c.current_token.kind != .Eof {
        #partial switch c.current_token.kind {
            case .Label: {
                label := c.current_token.literal
                c.labels[label] = u32(len(c.bytecode))
            }
            case .Nop: handle_nop(c)
            case .Halt: handle_halt(c)
            case .Mov: handle_mov(c)
            case .Add: handle_arithemtic_op(c, "add")
            case .Sub: handle_arithemtic_op(c, "sub")
            case .Mul: handle_arithemtic_op(c, "mul")
            case .Div: handle_arithemtic_op(c, "div")
            case .Mod: handle_arithemtic_op(c, "mod")
            case .And: handle_arithemtic_op(c, "and")
            case .Or: handle_arithemtic_op(c, "or")
            case .Xor: handle_arithemtic_op(c, "xor")
            case .Shl: handle_arithemtic_op(c, "shl")
            case .Shr: handle_arithemtic_op(c, "shr")
            case .Inc: handle_inc(c)
            case .Dec: handle_dec(c)
            case .Cast: handle_cast(c)
            case .Push: handle_push(c)
            case .Pop: handle_pop(c)
            case .Str: handle_str(c)
            case .Ld: handle_ld(c)
            case .Int: handle_int(c)
            case .Cmp: handle_cmp(c)
            case .Jmp: handle_jump_op(c, "jmp")
            case .Jeq: handle_jump_op(c, "jeq")
            case .Jne: handle_jump_op(c, "jne")
            case .Jlt: handle_jump_op(c, "jlt")
            case .Jgt: handle_jump_op(c, "jgt")
            case .Jle: handle_jump_op(c, "jle")
            case .Jge: handle_jump_op(c, "jge")
            case .Call: handle_call(c)
            case .Ret: handle_ret(c)
            case .Debug: handle_debug(c)
            
            case: fmt.printf("error: unhandled token: %v\n", c.current_token)
        }

        next_token(c)
    }

    for addr, name in c.fixups {
        if _, ok := c.labels[name]; ok {
            value := make_compiler_object(c.labels[name])
            for i := 0; i < len(value); i += 1 {
                c.bytecode[int(addr) + i] = byte(value[i])
            }
        } else {
            fmt.printf("warning: possible use of undefined label: %s\n", name)
        }
    }
}

@(private)
handle_nop :: proc(c: ^Compiler) {
    append(&c.bytecode, opcode.from_opcode(.Nop))
}

@(private)
handle_halt :: proc(c: ^Compiler) {
    append(&c.bytecode, opcode.from_opcode(.Halt))
}

@(private)
handle_mov :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    if !expect_peek(c, .Comma) {
        return
    }

    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            reg1 := get_register(c.current_token.literal)

            append(&c.bytecode, opcode.from_opcode(.MovRegReg))
            append(&c.bytecode, byte(reg0))
            append(&c.bytecode, byte(reg1))
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, opcode.from_opcode(.MovRegImm))
            append(&c.bytecode, byte(reg0))
            append(&c.bytecode, ..imm1)
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_arithemtic_op :: proc(c: ^Compiler, op: string) {
    if !expect_peek(c, .Register) {
        return
    }

    dest := get_register(c.current_token.literal)

    if !expect_peek(c, .Comma) {
        return
    }

    if !expect_peek(c, .Register) {
        return
    }

    src1 := get_register(c.current_token.literal)

    if !expect_peek(c, .Comma) {
        return
    }

    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            src2 := get_register(c.current_token.literal)

            code: byte

            switch op {
                case "add": code = opcode.from_opcode(.AddRegRegReg)
                case "sub": code = opcode.from_opcode(.SubRegRegReg)
                case "mul": code = opcode.from_opcode(.MulRegRegReg)
                case "div": code = opcode.from_opcode(.DivRegRegReg)
                case "mod": code = opcode.from_opcode(.ModRegRegReg)
                case "and": code = opcode.from_opcode(.AndRegRegReg)
                case "or": code = opcode.from_opcode(.OrRegRegReg)
                case "xor": code = opcode.from_opcode(.XorRegRegReg)
                case "shl": code = opcode.from_opcode(.ShlRegRegReg)
                case "shr": code = opcode.from_opcode(.ShrRegRegReg)
            }

            append(&c.bytecode, code)
            append(&c.bytecode, byte(dest))
            append(&c.bytecode, byte(src1))
            append(&c.bytecode, byte(src2))
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            src2 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            code: byte

            switch op {
                case "add": code = opcode.from_opcode(.AddRegRegImm)
                case "sub": code = opcode.from_opcode(.SubRegRegImm)
                case "mul": code = opcode.from_opcode(.MulRegRegImm)
                case "div": code = opcode.from_opcode(.DivRegRegImm)
                case "mod": code = opcode.from_opcode(.ModRegRegImm)
                case "and": code = opcode.from_opcode(.AndRegRegImm)
                case "or": code = opcode.from_opcode(.OrRegRegImm)
                case "xor": code = opcode.from_opcode(.XorRegRegImm)
                case "shl": code = opcode.from_opcode(.ShlRegRegImm)
                case "shr": code = opcode.from_opcode(.ShrRegRegImm)
            }

            append(&c.bytecode, code)
            append(&c.bytecode, byte(dest))
            append(&c.bytecode, byte(src1))
            append(&c.bytecode, ..src2)
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_inc :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    append(&c.bytecode, opcode.from_opcode(.IncReg))
    append(&c.bytecode, byte(reg0))
}

@(private)
handle_dec :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    append(&c.bytecode, opcode.from_opcode(.DecReg))
    append(&c.bytecode, byte(reg0))
}


@(private)
handle_cast :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    if !expect_peek(c, .Comma) {
        return
    }
    
    if !expect_type(c) {
        return
    }

    t1: byte
    switch c.current_token.literal {
        case "u8": t1 = 0
        case "i8": t1 = 1
        case "u16": t1 = 2
        case "i16": t1 = 3
        case "u32": t1 = 4
        case "i32": t1 = 5
        case "u64": t1 = 6
        case "i64": t1 = 7
        case "u128": t1 = 8
        case "i128": t1 = 9
        case "f32": t1 = 10
        case "f364": t1 = 11
    }

    append(&c.bytecode, opcode.from_opcode(.CastRegType))
    append(&c.bytecode, byte(reg0))
    append(&c.bytecode, t1)
}

@(private)
handle_push :: proc(c: ^Compiler) {
    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            reg0 := get_register(c.current_token.literal)

            append(&c.bytecode, opcode.from_opcode(.PushReg))
            append(&c.bytecode, byte(reg0))
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm0 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, opcode.from_opcode(.PushImm))
            append(&c.bytecode, ..imm0)
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_pop :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    append(&c.bytecode, opcode.from_opcode(.PopReg))
    append(&c.bytecode, byte(reg0))
}

@(private)
handle_str :: proc(c: ^Compiler) {
    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            reg0 := get_register(c.current_token.literal)

            if !expect_peek(c, .Comma) {
                return
            }

            next_token(c)
            #partial switch c.current_token.kind {
                case .Register: {
                    reg1 := get_register(c.current_token.literal)

                    append(&c.bytecode, opcode.from_opcode(.StrRegReg))
                    append(&c.bytecode, byte(reg0))
                    append(&c.bytecode, byte(reg1))
                }
                case .NumberU8: fallthrough
                case .NumberU16: fallthrough
                case .NumberU32: fallthrough
                case .NumberU64: fallthrough
                case .NumberU128: fallthrough
                case .NumberI8: fallthrough
                case .NumberI16: fallthrough
                case .NumberI32: fallthrough
                case .NumberI64: fallthrough
                case .NumberI128: fallthrough
                case .NumberF32: fallthrough
                case .NumberF64: {
                    imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

                    append(&c.bytecode, opcode.from_opcode(.StrRegImm))
                    append(&c.bytecode, byte(reg0))
                    append(&c.bytecode, ..imm1)
                }
                case .String: {
                    str1 := make_compiler_string(c.current_token.literal)

                    append(&c.bytecode, opcode.from_opcode(.StrRegStr))
                    append(&c.bytecode, byte(reg0))
                    append(&c.bytecode, ..str1)
                }
                case: {
                    expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64, .String)
                }
            }
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm0 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            if !expect_peek(c, .Comma) {
                return
            }

            next_token(c)
            #partial switch c.current_token.kind {
                case .Register: {
                    reg1 := get_register(c.current_token.literal)

                    append(&c.bytecode, opcode.from_opcode(.StrImmReg))
                    append(&c.bytecode, ..imm0)
                    append(&c.bytecode, byte(reg1))
                }
                case .NumberU8: fallthrough
                case .NumberU16: fallthrough
                case .NumberU32: fallthrough
                case .NumberU64: fallthrough
                case .NumberU128: fallthrough
                case .NumberI8: fallthrough
                case .NumberI16: fallthrough
                case .NumberI32: fallthrough
                case .NumberI64: fallthrough
                case .NumberI128: fallthrough
                case .NumberF32: fallthrough
                case .NumberF64: {
                    imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

                    append(&c.bytecode, opcode.from_opcode(.StrImmImm))
                    append(&c.bytecode, ..imm0)
                    append(&c.bytecode, ..imm1)
                }
                case .String: {
                    str1 := make_compiler_string(c.current_token.literal)

                    append(&c.bytecode, opcode.from_opcode(.StrImmStr))
                    append(&c.bytecode, ..imm0)
                    append(&c.bytecode, ..str1)
                }
                case: {
                    expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64, .String)
                }
            }
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_ld :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    if !expect_peek(c, .Comma) {
        return
    }

    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            reg1 := get_register(c.current_token.literal)

            append(&c.bytecode, opcode.from_opcode(.LdRegReg))
            append(&c.bytecode, byte(reg0))
            append(&c.bytecode, byte(reg1))
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, opcode.from_opcode(.LdRegImm))
            append(&c.bytecode, byte(reg0))
            append(&c.bytecode, ..imm1)
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_int :: proc(c: ^Compiler) {
    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            reg0 := get_register(c.current_token.literal)

            append(&c.bytecode, opcode.from_opcode(.IntReg))
            append(&c.bytecode, byte(reg0))
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm0 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, opcode.from_opcode(.IntImm))
            append(&c.bytecode, ..imm0)
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_cmp :: proc(c: ^Compiler) {
    if !expect_peek(c, .Register) {
        return
    }

    reg0 := get_register(c.current_token.literal)

    if !expect_peek(c, .Comma) {
        return
    }

    next_token(c)
    #partial switch c.current_token.kind {
        case .Register: {
            reg1 := get_register(c.current_token.literal)

            append(&c.bytecode, opcode.from_opcode(.CmpRegReg))
            append(&c.bytecode, byte(reg0))
            append(&c.bytecode, byte(reg1))
        }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, opcode.from_opcode(.CmpRegImm))
            append(&c.bytecode, byte(reg0))
            append(&c.bytecode, ..imm1)
        }
        case: {
            expect_error(c, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64)
        }
    }
}

@(private)
handle_jump_op :: proc(c: ^Compiler, op: string) {
    code: byte

    switch op {
        case "jmp": code = opcode.from_opcode(.JmpImm)
        case "jeq": code = opcode.from_opcode(.JeqImm)
        case "jne": code = opcode.from_opcode(.JneImm)
        case "jlt": code = opcode.from_opcode(.JltImm)
        case "jgt": code = opcode.from_opcode(.JgtImm)
        case "jle": code = opcode.from_opcode(.JleImm)
        case "jge": code = opcode.from_opcode(.JgeImm)
    }

    next_token(c)
    #partial switch c.current_token.kind {
        // TODO: jmp can read from register
        // case .Register: {

        // }
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, code)
            append(&c.bytecode, ..imm1)
        }
        case .Identifier: {
            label := c.current_token.literal
            c.fixups[u32(len(c.bytecode))+1] = label

            placeholder := make_compiler_object(u32(0))
            append(&c.bytecode, code)
            append(&c.bytecode, ..placeholder)
        }
        case: {
            expect_error(c, false, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64, .Identifier)
        }
    }
}

@(private)
handle_call :: proc(c: ^Compiler) {
    next_token(c)
    #partial switch c.current_token.kind {
        case .NumberU8: fallthrough
        case .NumberU16: fallthrough
        case .NumberU32: fallthrough
        case .NumberU64: fallthrough
        case .NumberU128: fallthrough
        case .NumberI8: fallthrough
        case .NumberI16: fallthrough
        case .NumberI32: fallthrough
        case .NumberI64: fallthrough
        case .NumberI128: fallthrough
        case .NumberF32: fallthrough
        case .NumberF64: {
            imm1 := make_compiler_object(make_object(c.current_token.literal, c.current_token.kind))

            append(&c.bytecode, opcode.from_opcode(.CallImm))
            append(&c.bytecode, ..imm1)
        }
        case .Identifier: {
            label := c.current_token.literal
            c.fixups[u32(len(c.bytecode))+1] = label

            placeholder := make_compiler_object(u32(0))
            append(&c.bytecode, opcode.from_opcode(.CallImm))
            append(&c.bytecode, ..placeholder)
        }
        case: {
            expect_error(c, false, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64, .Identifier)
        }
    }
}

@(private)
handle_ret :: proc(c: ^Compiler) {
    append(&c.bytecode, opcode.from_opcode(.Ret))
}

@(private)
handle_debug :: proc(c: ^Compiler) {
    if !expect_peek(c, .String) {
        return
    }

    str0 := make_compiler_string(c.current_token.literal)

    append(&c.bytecode, opcode.from_opcode(.Debug))
    append(&c.bytecode, ..str0)
}

@(private)
get_register :: proc(register: string) -> int {
    return strconv.atoi(register)
}

@(private)
next_token :: proc(c: ^Compiler) {
    c.current_token = c.peek_token
    c.peek_token = lexer.next_token(c.lexer)
}

@(private)
peek_token_is :: proc(c: ^Compiler, kind: token.TokenKind) -> bool {
    return c.peek_token.kind == kind
}

@(private)
expect_error :: proc(c: ^Compiler, peek: bool, kind: ..token.TokenKind) -> bool {
    if peek {
        fmt.printf("expected next token to be %v got %v instead\n", kind, c.peek_token.kind)
    } else {
        fmt.printf("expected next token to be %v got %v instead\n", kind, c.current_token.kind)
    }
    os.exit(1)
}

@(private)
expect_peek :: proc(c: ^Compiler, kind: token.TokenKind) -> bool {
    if peek_token_is(c, kind) {
        next_token(c)
        return true
    }

    expect_error(c, true, kind)
    return false
}

@(private)
expect_type :: proc(c: ^Compiler) -> bool {
    types := []token.TokenKind{.TypeU8, .TypeU16, .TypeU32, .TypeU64, .TypeU128, .TypeI8, .TypeI16, .TypeI32, .TypeI64, .TypeI128, .TypeF32, .TypeF64}
    for i in types {
        if peek_token_is(c, i) {
            next_token(c)
            return true
        }
    }

    expect_error(c, true, ..types)
    return false
}

@(private)
make_compiler_string :: proc(str: string) -> []byte {
    str_len := len(str)

    out := make([]byte, str_len+1)
    out[0] = byte(str_len)

    for i := 0; i < str_len; i += 1 {
        out[i+1] = str[i]
    }

    return out
}

@(private)
make_compiler_object :: proc(value: object.Object) -> []byte {
    bytes: []byte

    #partial switch o in value {
        case u8: {
            bytes = make([]byte, 2)
            bytes[0] = 0
            bytes[1] = o
        }
        case i8: {
            bytes = make([]byte, 2)
            bytes[0] = 1
            bytes[1] = byte(o)
        }
        case u16: {
            bytes = make([]byte, 3)
            bytes[0] = 2
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
        }
        case i16: {
            bytes = make([]byte, 3)
            bytes[0] = 3
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
        }
        case u32: {
            bytes = make([]byte, 5)
            bytes[0] = 4
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
        }
        case i32: {
            bytes = make([]byte, 5)
            bytes[0] = 5
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
        }
        case u64: {
            bytes = make([]byte, 9)
            bytes[0] = 6
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
            bytes[5] = byte((o >> 32) & 0xFF)
            bytes[6] = byte((o >> 40) & 0xFF)
            bytes[7] = byte((o >> 48) & 0xFF)
            bytes[8] = byte((o >> 56) & 0xFF)
        }
        case i64: {
            bytes = make([]byte, 9)
            bytes[0] = 7
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
            bytes[5] = byte((o >> 32) & 0xFF)
            bytes[6] = byte((o >> 40) & 0xFF)
            bytes[7] = byte((o >> 48) & 0xFF)
            bytes[8] = byte((o >> 56) & 0xFF)
        }
        case u128: {
            bytes = make([]byte, 17)
            bytes[0] = 8
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
            bytes[5] = byte((o >> 32) & 0xFF)
            bytes[6] = byte((o >> 40) & 0xFF)
            bytes[7] = byte((o >> 48) & 0xFF)
            bytes[8] = byte((o >> 56) & 0xFF)
            bytes[9] = byte((o >> 64) & 0xFF)
            bytes[10] = byte((o >> 72) & 0xFF)
            bytes[11] = byte((o >> 80) & 0xFF)
            bytes[12] = byte((o >> 88) & 0xFF)
            bytes[13] = byte((o >> 96) & 0xFF)
            bytes[14] = byte((o >> 104) & 0xFF)
            bytes[15] = byte((o >> 112) & 0xFF)
            bytes[16] = byte((o >> 120) & 0xFF)
        }
        case i128: {
            bytes = make([]byte, 17)
            bytes[0] = 9
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
            bytes[5] = byte((o >> 32) & 0xFF)
            bytes[6] = byte((o >> 40) & 0xFF)
            bytes[7] = byte((o >> 48) & 0xFF)
            bytes[8] = byte((o >> 56) & 0xFF)
            bytes[9] = byte((o >> 64) & 0xFF)
            bytes[10] = byte((o >> 72) & 0xFF)
            bytes[11] = byte((o >> 80) & 0xFF)
            bytes[12] = byte((o >> 88) & 0xFF)
            bytes[13] = byte((o >> 96) & 0xFF)
            bytes[14] = byte((o >> 104) & 0xFF)
            bytes[15] = byte((o >> 112) & 0xFF)
            bytes[16] = byte((o >> 120) & 0xFF)
        }
        case f32: {
            o := transmute(u32)o
            bytes = make([]byte, 5)
            bytes[0] = 10
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
        }
        case f64: {
            o := transmute(u64)o
            bytes = make([]byte, 5)
            bytes[0] = 11
            bytes[1] = byte(o & 0xFF)
            bytes[2] = byte((o >> 8) & 0xFF)
            bytes[3] = byte((o >> 16) & 0xFF)
            bytes[4] = byte((o >> 24) & 0xFF)
        }
    }

    return bytes
}

@(private)
make_object :: proc(number: string, kind: token.TokenKind) -> object.Object {
    #partial switch kind {
        case .NumberU8: {
            num, ok := strconv.parse_uint(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return u8(num)
        }
        case .NumberU16: {
            num, ok := strconv.parse_uint(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return u16(num)
        }
        case .NumberU32: {
            num, ok := strconv.parse_uint(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return u32(num)
        }
        case .NumberU64: {
            num, ok := strconv.parse_uint(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return u64(num)
        }
        case .NumberU128: {
            num, ok := strconv.parse_uint(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return u128(num)
        }
        case .NumberI8: {
            num, ok := strconv.parse_int(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return i8(num)
        }
        case .NumberI16: {
            num, ok := strconv.parse_int(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return i16(num)
        }
        case .NumberI32: {
            num, ok := strconv.parse_int(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return i32(num)
        }
        case .NumberI64: {
            num, ok := strconv.parse_int(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return i64(num)
        }
        case .NumberI128: {
            num, ok := strconv.parse_int(number, 10)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return i128(num)
        }
        case .NumberF32: {
            num, ok := strconv.parse_f32(number)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return f32(num)
        }
        case .NumberF64: {
            num, ok := strconv.parse_f64(number)
            if !ok {
                panic(fmt.aprintf("error: failed to convert to number: %s", number))
            }
            return f64(num)
        }
    }

    panic(fmt.aprintf("error: invalid kind to convert: %v", kind))
}