package compiler

import "core:testing"
import "../lexer"

@(private)
a_da_equals :: proc(a1: []byte, a2: [dynamic]byte) -> bool {
    if len(a1) != len(a2) {
        return false
    }

    for i := 0; i < len(a1); i += 1 {
        if a1[i] != a2[i] {
            return false
        }
    }

    return true
}

@(private)
a_a_equals :: proc(a1: []byte, a2: []byte) -> bool {
    if len(a1) != len(a2) {
        return false
    }

    for i := 0; i < len(a1); i += 1 {
        if a1[i] != a2[i] {
            return false
        }
    }

    return true
}

@(test)
test_nop_compilation :: proc(t: ^testing.T) {
    input := "nop"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x00}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_halt_compilation :: proc(t: ^testing.T) {
    input := "halt"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x01}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_mov_reg_reg_compilation :: proc(t: ^testing.T) {
    input := "mov r0, r1"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x02, 0x00, 0x01}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_mov_reg_imm_compilation :: proc(t: ^testing.T) {
    input := "mov r0, u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x03, 0x00, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_math_reg_reg_compilation :: proc(t: ^testing.T) {
    input := `
    add r0, r1, r2
    sub r0, r1, r2
    mul r0, r1, r2
    div r0, r1, r2
    `
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{
        0x04, 0x00, 0x01, 0x02,
        0x06, 0x00, 0x01, 0x02,
        0x08, 0x00, 0x01, 0x02,
        0x0a, 0x00, 0x01, 0x02,
    }

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_math_reg_imm_compilation :: proc(t: ^testing.T) {
    input := `
    add r0, r1, u8(10)
    sub r0, r1, u8(10)
    mul r0, r1, u8(10)
    div r0, r1, u8(10)
    `
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{
        0x05, 0x00, 0x01, 0x00, 0x0a,
        0x07, 0x00, 0x01, 0x00, 0x0a,
        0x09, 0x00, 0x01, 0x00, 0x0a,
        0x0b, 0x00, 0x01, 0x00, 0x0a,
    }

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_cast_reg_type_compilation :: proc(t: ^testing.T) {
    input := "cast r0, u8"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x0c, 0x00, 0x00}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_push_reg_compilation :: proc(t: ^testing.T) {
    input := "push r0"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x0d, 0x00}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_push_imm_compilation :: proc(t: ^testing.T) {
    input := "push u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x0e, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_pop_reg_compilation :: proc(t: ^testing.T) {
    input := "pop r0"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x0f, 0x00}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_str_reg_reg_compilation :: proc(t: ^testing.T) {
    input := "str r0, r1"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x10, 0x00, 0x01}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_str_reg_imm_compilation :: proc(t: ^testing.T) {
    input := "str r0, u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x11, 0x00, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_str_imm_reg_compilation :: proc(t: ^testing.T) {
    input := "str u8(10), r0"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x12, 0x00, 0x0a, 0x00}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_str_imm_imm_compilation :: proc(t: ^testing.T) {
    input := "str u8(10), u8(20)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x13, 0x00, 0x0a, 0x00, 0x14}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_str_reg_str_compilation :: proc(t: ^testing.T) {
    input := `str r0, "Hello World!\n"`
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x14, 0x00, 0x0d, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64, 0x21, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_str_imm_str_compilation :: proc(t: ^testing.T) {
    input := `str u8(10), "Hello World!\n"`
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x15, 0x00, 0x0a, 0x0d, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64, 0x21, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_ld_reg_reg_compilation :: proc(t: ^testing.T) {
    input := "ld r0, r1"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x16, 0x00, 0x01}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_ld_reg_imm_compilation :: proc(t: ^testing.T) {
    input := "ld r0, u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x17, 0x00, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_int_reg_compilation :: proc(t: ^testing.T) {
    input := "int r0"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x18, 0x00}

    testing.expect(t, a_da_equals(code, c.bytecode))
}


@(test)
test_int_imm_compilation :: proc(t: ^testing.T) {
    input := "int u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x19, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_cmp_reg_reg_compilation :: proc(t: ^testing.T) {
    input := "cmp r0, r1"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x1a, 0x00, 0x01}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_cmp_reg_imm_compilation :: proc(t: ^testing.T) {
    input := "cmp r0, u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x1b, 0x00, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_jmp_compilation :: proc(t: ^testing.T) {
    input := `
        jmp u8(10)
        jeq u8(10)
        jne u8(10)
        jlt u8(10)
        jgt u8(10)
        jle u8(10)
        jge u8(10)
    `
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{
        0x1c, 0x00, 0x0a,
        0x1d, 0x00, 0x0a,
        0x1e, 0x00, 0x0a,
        0x1f, 0x00, 0x0a,
        0x20, 0x00, 0x0a,
        0x21, 0x00, 0x0a,
        0x22, 0x00, 0x0a,
    }

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_call_compilation :: proc(t: ^testing.T) {
    input := "call u8(10)"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x23, 0x00, 0x0a}

    testing.expect(t, a_da_equals(code, c.bytecode))
}

@(test)
test_ret_compilation :: proc(t: ^testing.T) {
    input := "ret"
    l := lexer.new_lexer(transmute([]byte)input)
    c := new_compiler(&l)
    compile(&c)

    code := []byte{0x24}

    testing.expect(t, a_da_equals(code, c.bytecode))
}