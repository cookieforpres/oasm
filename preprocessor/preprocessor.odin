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
    imports: map[string]bool,
}

new_preprocessor :: proc(l: ^lexer.Lexer) -> Preprocessor {
    p := Preprocessor {lexer = l, pre_output = transmute(string)l.input}

    next_token(&p)
    next_token(&p)

    return p
}

process :: proc(p: ^Preprocessor) {
    for p.current_token.kind != .Eof {
        if p.current_token.kind == .Entry {
            handle_entry(p)
        }

        next_token(p)
    }

    nl := lexer.new_lexer(transmute([]byte)p.pre_output)
    reset_lexer(p, &nl)

    for p.current_token.kind != .Eof {
        if p.current_token.kind == .Import {
            handle_import(p)
        }

        next_token(p)
    }
}

output :: proc(p: ^Preprocessor) -> string {
    return p.pre_output
}

@(private)
handle_entry :: proc(p: ^Preprocessor) {
    if !expect_peek(p, .Identifier) {
        return
    }

    entry := p.current_token.literal
    raw := fmt.aprintf("!entry %s", entry)

    p.pre_output, _ = strings.replace_all(p.pre_output, raw, "")
    p.pre_output = strings.trim_space(p.pre_output)

    fix := fmt.aprintf("\tjmp %s\n", entry)
    p.pre_output = fmt.aprintf("%s%s", fix, p.pre_output)
}

@(private)
handle_import :: proc(p: ^Preprocessor) {
    if !expect_peek(p, .String) {
        return
    }

    contents := ""
    file_path := p.current_token.literal
    whole_path := fmt.aprintf("%s/%s", os.get_current_directory(), file_path)
    if !strings.has_suffix(whole_path, ".oasm") {
        whole_path = fmt.aprintf("%s.oasm", whole_path)
    }
    if _, ok := p.imports[whole_path]; !ok {
        file_contents := utils.read_file_to_bytes(whole_path)

        nl := lexer.new_lexer(file_contents)
        np := new_preprocessor(&nl)
        process(&np)

        contents = output(&np)
        p.imports[whole_path] = true
    }

    raw := fmt.aprintf("!import \"%s\"", file_path)

    p.pre_output, _ = strings.replace(p.pre_output, raw, contents, 1)
    p.pre_output = strings.trim_space(p.pre_output)
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