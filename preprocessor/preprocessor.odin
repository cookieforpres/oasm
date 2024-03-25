package preprocessor

import "core:fmt"
import "core:os"
import "core:strings"
import "../lexer"
import "../token"
import "../utils"

Preprocessor :: struct {
    lexer: ^lexer.Lexer,
    current_token: token.Token,
    peek_token: token.Token,
    pre_output: string,
    includes: map[string]bool,
    definitions: map[string]string,
    only_includes: bool,
}

new_preprocessor :: proc(l: ^lexer.Lexer, only_includes: bool) -> Preprocessor {
    p := Preprocessor {lexer = l, pre_output = transmute(string)l.input, only_includes = only_includes}

    next_token(&p)
    next_token(&p)

    return p
}

process :: proc(p: ^Preprocessor) {
    handle_directives(p, .Include, false, handle_include)

    if !p.only_includes {
        handle_directives(p, .Define, true, handle_define)
        handle_directives(p, .Entry, true, handle_entry)
        replace_definitions(p)
    }
}

output :: proc(p: ^Preprocessor) -> string {
    return p.pre_output
}

@(private)
handle_directives :: proc(p: ^Preprocessor, kind: token.TokenKind, reset_lex: bool, handler: proc(p: ^Preprocessor)) {
    if reset_lex {
        nl := lexer.new_lexer(transmute([]byte)p.pre_output)
        reset_lexer(p, &nl)
    }
    
    for p.current_token.kind != .Eof {
        if p.current_token.kind == kind {
            handler(p)
        }

        next_token(p)
    }
}

@(private)
replace_definitions :: proc(p: ^Preprocessor) {
    keysd: [dynamic]string
    for key in p.definitions {
        append(&keysd, key)
    }

    keys := no_dynamics(keysd)
    utils.bubble_sort_string_slice(keys)

    for key in keys {
        value := p.definitions[key]
        p.pre_output, _ = strings.replace_all(p.pre_output, strings.trim_space(key), strings.trim_space(value))
    }
}

@(private)
handle_entry :: proc(p: ^Preprocessor) {
    if !expect_peek(p, .Identifier) {
        return
    }

    entry := p.current_token.literal
    raw := fmt.aprintf("@entry %s", entry)

    p.pre_output, _ = strings.replace_all(p.pre_output, raw, "")
    p.pre_output = strings.trim_space(p.pre_output)

    fix := fmt.aprintf("\tjmp %s\n", entry)
    p.pre_output = fmt.aprintf("%s%s", fix, p.pre_output)
}

@(private)
handle_include :: proc(p: ^Preprocessor) {
    if !expect_peek(p, .String) {
        return
    }

    contents := ""
    file_path := p.current_token.literal
    whole_path := fmt.aprintf("%s/%s", os.get_current_directory(), file_path)
    if !strings.has_suffix(whole_path, ".oasm") {
        whole_path = fmt.aprintf("%s.oasm", whole_path)
    }
    if _, ok := p.includes[whole_path]; !ok {
        file_contents := utils.read_file_to_bytes(whole_path)

        nl := lexer.new_lexer(file_contents)
        np := new_preprocessor(&nl, true)
        process(&np)

        contents = output(&np)

        p.includes[whole_path] = true
    }

    raw := fmt.aprintf("@include \"%s\"", file_path)

    p.pre_output, _ = strings.replace(p.pre_output, raw, contents, 1)
    p.pre_output = strings.trim_space(p.pre_output)
}

@(private)
handle_define :: proc(p: ^Preprocessor) {
    if !expect_peek(p, .Identifier) {
        return
    }

    key := p.current_token.literal
    value: string

    next_token(p)
    #partial switch p.current_token.kind {
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
            value = p.current_token.literal
        }
        case .String: {
            value = fmt.aprintf("\"%s\"", utils.unescape_string(p.current_token.literal))
        }
        case .Register: {
            value = fmt.aprintf("r%s", p.current_token.literal)
        }
        case: {
            expect_error(p, false, .Register, .NumberU8, .NumberU16, .NumberU32, .NumberU64, .NumberU128, .NumberI8, .NumberI16, .NumberI32, .NumberI64, .NumberI128, .NumberF32, .NumberF64, .String)
        }
    }

    raw := fmt.aprintf("@define %s %s", key, value)
    p.pre_output, _ = strings.replace_all(p.pre_output, raw, "")
    p.pre_output = strings.trim_space(p.pre_output)

    p.definitions[key] = value
}

@(private)
reset_lexer :: proc(p: ^Preprocessor, l: ^lexer.Lexer) {
    p.lexer = l
    p.current_token = {}
    p.peek_token = {}

    next_token(p)
    next_token(p)
}

@(private)
next_token :: proc(p: ^Preprocessor) {
    p.current_token = p.peek_token
    p.peek_token = lexer.next_token(p.lexer)
}

@(private)
peek_token_is :: proc(p: ^Preprocessor, kind: token.TokenKind) -> bool {
    return p.peek_token.kind == kind
}

@(private)
expect_error :: proc(p: ^Preprocessor, peek: bool, kind: ..token.TokenKind) -> bool {
    if peek {
        fmt.printf("expected next token to be %v got %v instead\n", kind, p.peek_token.kind)
    } else {
        fmt.printf("expected next token to be %v got %v instead\n", kind, p.current_token.kind)
    }
    os.exit(1)
}

@(private)
expect_peek :: proc(p: ^Preprocessor, kind: token.TokenKind) -> bool {
    if peek_token_is(p, kind) {
        next_token(p)
        return true
    }

    expect_error(p, true, kind)
    return false
}

@(private)
no_dynamics :: proc(values: [dynamic]string) -> []string {
    out := make([]string, len(values))
    for i := 0; i < len(values); i += 1 {
        out[i] = values[i]
    }
    return out
}