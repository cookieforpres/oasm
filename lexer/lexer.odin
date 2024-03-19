package lexer

import "core:strings"
import "core:strconv"
import "core:fmt"
import "../object"
import "../token"

Lexer :: struct {
    position: int,
    read_position: int,
    ch: byte,
    input: []byte,
}

new_lexer :: proc(input: []byte) -> Lexer {
    l := Lexer{input = input}
    read_char(&l)
    return l
}

next_token :: proc(l: ^Lexer) -> token.Token {
    tok: token.Token
    skip_whitespace(l)

    if l.ch == ';' {
        skip_comment(l)
        return next_token(l)
    }

    switch l.ch {
        case ',': tok = token.new_token([]byte{l.ch}, .Comma)
        case '"': {
            tok.literal = read_string(l)
            tok.kind = .String
        }
        case 0: {
            tok.literal = ""
            tok.kind = .Eof
        }
        case: {
            if is_digit(l.ch) || l.ch == '-' {
                return read_decimal(l)
            }

            tok.literal = read_identifier(l)

            if i, t, ok := has_explicit_type(tok.literal); ok {
                tok.kind = t
                tok.literal = i
            } else {
                tok.kind = token.lookup_identifier(tok.literal)
            }

            return tok
        }
    }

    read_char(l)
    return tok
}

@(private)
has_explicit_type :: proc(ident: string) -> (string, token.TokenKind, bool) {
    if strings.has_prefix(ident, "u8(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[3:len(ident)-1])
        _, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberU8, true
    } else if strings.has_prefix(ident, "u16(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberU16, true
    } else if strings.has_prefix(ident, "u32(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberU32, true
    } else if strings.has_prefix(ident, "u64(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberU64, true
    } else if strings.has_prefix(ident, "u128(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[5:len(ident)-1])
        _, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberU128, true
    } else if strings.has_prefix(ident, "i8(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[3:len(ident)-1])
        _, ok := strconv.parse_int(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberI8, true
    } else if strings.has_prefix(ident, "i16(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_int(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberI16, true
    } else if strings.has_prefix(ident, "i32(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_int(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberI32, true
    } else if strings.has_prefix(ident, "i64(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_int(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberI64, true
    } else if strings.has_prefix(ident, "i128(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[5:len(ident)-1])
        _, ok := strconv.parse_int(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberI128, true
    } else if strings.has_prefix(ident, "f32(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_f32(value)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberF32, true
    } else if strings.has_prefix(ident, "f64(") && strings.has_suffix(ident, ")") {
        value, _, _ := has_explicit_type(ident[4:len(ident)-1])
        _, ok := strconv.parse_f64(value)
        if !ok {
            return "", .Identifier, false
        }
        return value, .NumberF64, true
    } else if strings.has_prefix(ident, "$") {
        value := ident[1:]
        num, ok := strconv.parse_uint(value, 16)
        if !ok {
            return "", .Identifier, false
        }
        return fmt.aprintf("%d", num), .NumberU32, true
    } else if strings.has_prefix(ident, "#") {
        value := ident[1:]
        num, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return fmt.aprintf("%d", num), .NumberU32, true
    } else if strings.has_prefix(ident, "%") {
        value := ident[1:]
        num, ok := strconv.parse_uint(value, 2)
        if !ok {
            return "", .Identifier, false
        }
        return fmt.aprintf("%d", num), .NumberU32, true
    } else if strings.has_prefix(ident, "r") {
        value := ident[1:]
        num, ok := strconv.parse_uint(value, 10)
        if !ok {
            return "", .Identifier, false
        }
        return fmt.aprintf("%d", num), .Register, true
    } else if ident == "sp" {
        return "14", .Register, true
    }  else if ident == "pc" {
        return "15", .Register, true
    } else if strings.has_suffix(ident, ":") {
        value := ident[:len(ident)-1]
        return value, .Label, true
    }

    return ident, .Identifier, false
}

@(private)
read_char :: proc(l: ^Lexer) {
    if l.read_position >= len(l.input) {
        l.ch = 0
    } else {
        l.ch = l.input[l.read_position]
    }
    l.position = l.read_position
    l.read_position += 1
}

@(private)
read_identifier :: proc(l: ^Lexer) -> string {
    position := l.position
    for is_identifier(l.ch) {
        read_char(l)
    }

    return string(l.input[position:l.position])
}

@(private)
skip_whitespace :: proc(l: ^Lexer) {
    for is_whitespace(l.ch) {
        read_char(l)
    }
}

@(private)
skip_comment :: proc(l: ^Lexer) {
    for l.ch != '\n' && l.ch != 0 {
        read_char(l)
    }
    skip_whitespace(l)
}

@(private)
read_number :: proc(l: ^Lexer) -> string {
	position := l.position
	if l.ch == '-' {
		read_char(l)
	}
	for is_hex_digit(l.ch) {
		read_char(l)
	}
	return string(l.input[position:l.position])
}

@(private)
read_until_whitespace :: proc(l: ^Lexer) -> string {
	position := l.position
	for !is_whitespace(l.ch) && l.ch != 0 {
		read_char(l)
	}
	return string(l.input[position:l.position])
}

@(private)
read_decimal :: proc(l: ^Lexer) -> token.Token {
    // TODO: very shitty way of doing this, values that dont end in a whitespace will be a number ('-1meow', '32.1)', etc)
	integer := read_number(l)
	if is_empty(l.ch) || is_whitespace(l.ch) || l.ch == ',' {
		if strings.contains(integer, "-") {
            return token.Token{literal = integer, kind = .NumberI32}
        } else {
            return token.Token{literal = integer, kind = .NumberU32}
        }
	}
	decimal := read_until_whitespace(l)
	return token.Token{literal = integer, kind = .NumberF32}
}

@(private)
read_string ::proc(l: ^Lexer) -> string {
	out := strings.builder_make()

	for {
		read_char(l)
		if l.ch == '"' {
			break
		}

		if l.ch == '\\' {
			read_char(l)

			if l.ch == 'n' {
				l.ch = '\n'
			}
			if l.ch == 'r' {
				l.ch = '\r'
			}
			if l.ch == 't' {
				l.ch = '\t'
			}
			if l.ch == '"' {
				l.ch = '"'
			}
			if l.ch == '\\' {
				l.ch = '\\'
			}

		}
        strings.write_byte(&out, l.ch)
	}

	return strings.to_string(out)
}

@(private)
peek_char :: proc(l: ^Lexer) -> byte {
	if l.read_position >= len(l.input) {
		return 0
	}
	return l.input[l.read_position]
}

@(private)
is_identifier :: proc(ch: byte) -> bool {
	return ch != ',' && !is_whitespace(ch) && !is_empty(ch)
}

@(private)
is_whitespace :: proc(ch: byte) -> bool {
	return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

@(private)
is_empty :: proc(ch: byte) -> bool {
	return ch == 0
}

@(private)
is_digit :: proc(ch: byte) -> bool {
	return ch >= '0' && ch <= '9'
}

@(private)
is_hex_digit :: proc(ch: byte) -> bool {
	if is_digit(ch) {
		return true
	}
	if ch >= 'a' && ch <= 'f' {
		return true
	}
	if ch >= 'A' && ch <= 'F' {
		return true
	}
	if ch >= 'x' || ch >= 'X' {
		return true
	}
	return false
}
