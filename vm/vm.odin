package vm

import "core:fmt"
import "core:os"
import "core:strings"
import "core:thread"
import "vendor:sdl2"
import "../opcode"
import "../object"

// TODO: make these cli args
REGISTER_CAPACITY :: 16
MEMORY_CAPACITY   :: (1 << 16)
STACK_CAPACITY    :: (1 << 10)

VM :: struct {
    program: []byte,
    registers: [REGISTER_CAPACITY]Register,
    memory: [MEMORY_CAPACITY]object.Object,
    flags: Flags,
    running: bool,
    debug: bool,

    display: Display
}

new_vm :: proc(program: []byte) -> VM {
    v := VM{}
    v.program = program
    v.running = true
    v.display = {nil, nil}

    for i := 0; i < REGISTER_CAPACITY-2; i += 1 {
        v.registers[i] = Register{u32(0)}
    }

    v.registers[REGISTER_PC] = Register{u64(0)}
    v.registers[REGISTER_SP] = Register{u64(0)}

    v.memory = [MEMORY_CAPACITY]object.Object{}

    return v
}

vm_run :: proc(v: ^VM, render_display: bool) {
    if (render_display) {
        init_sdl := sdl2.Init(sdl2.INIT_VIDEO | sdl2.INIT_EVENTS)
        if init_sdl != 0 {
            fmt.printf("error: failed to initalize new display: %s\n", sdl2.GetErrorString())
            os.exit(1)
        }
        v.display = new_display()

        thread.create_and_start_with_poly_data(v, proc(v: ^VM) {
            a := sdl2.GetTicks()
            b := sdl2.GetTicks()
            delta := u32(0)

            for v.running {
                a = sdl2.GetTicks()
                delta = a - b

                if delta > SCREEN_TPS {
                    pixels := make([]byte, PIXEL_COUNT)
                    for i := 0; i < PIXEL_COUNT; i += 1 {
                        pixels[i] = object.object_as_u8(v.memory[VRAM_START_ADDR+i])
                    }
                    display_draw(v, pixels)
                    b = a
                }
            }
        })
    }

    loop: for v.running && object.object_as_int(v.registers[REGISTER_PC].o) < len(v.program) {
        op_byte := read_program(v)
        op := opcode.from_byte(op_byte)

        #partial switch op {
            case .Nop: handle_nop(v)
            case .Halt: handle_halt(v)
            case .MovRegReg: handle_mov_reg_reg(v)
            case .MovRegImm: handle_mov_reg_imm(v)
            case .AddRegRegReg: handle_artithmetic_rrr(v, "add")
            case .AddRegRegImm: handle_artithmetic_rri(v, "add")
            case .SubRegRegReg: handle_artithmetic_rrr(v, "sub")
            case .SubRegRegImm: handle_artithmetic_rri(v, "sub")
            case .MulRegRegReg: handle_artithmetic_rrr(v, "mul")
            case .MulRegRegImm: handle_artithmetic_rri(v, "mul")
            case .DivRegRegReg: handle_artithmetic_rrr(v, "div")
            case .DivRegRegImm: handle_artithmetic_rri(v, "div")
            case .ModRegRegReg: handle_artithmetic_rrr(v, "mod")
            case .ModRegRegImm: handle_artithmetic_rri(v, "mod")
            case .AndRegRegReg: handle_artithmetic_rrr(v, "and")
            case .AndRegRegImm: handle_artithmetic_rri(v, "and")
            case .OrRegRegReg: handle_artithmetic_rrr(v, "or")
            case .OrRegRegImm: handle_artithmetic_rri(v, "or")
            case .XorRegRegReg: handle_artithmetic_rrr(v, "xor")
            case .XorRegRegImm: handle_artithmetic_rri(v, "xor")
            case .ShlRegRegReg: handle_artithmetic_rrr(v, "shl")
            case .ShlRegRegImm: handle_artithmetic_rri(v, "shl")
            case .ShrRegRegReg: handle_artithmetic_rrr(v, "shr")
            case .ShrRegRegImm: handle_artithmetic_rri(v, "shr")
            case .IncReg: handle_inc(v)
            case .DecReg: handle_dec(v)
            case .CastRegType: handle_cast_reg_type(v)
            case .PushReg: handle_push_reg(v)
            case .PushImm: handle_push_imm(v)
            case .PopReg: handle_pop_reg(v)
            case .StrRegReg: handle_str_reg_reg(v)
            case .StrRegImm: handle_str_reg_imm(v)
            case .StrImmReg: handle_str_imm_reg(v)
            case .StrImmImm: handle_str_imm_imm(v)
            case .StrRegStr: handle_str_reg_str(v)
            case .StrImmStr: handle_str_imm_str(v)
            case .LdRegReg: handle_ld_reg_reg(v)
            case .LdRegImm: handle_ld_reg_imm(v)
            case .IntImm: handle_int_imm(v)
            case .IntReg: handle_int_reg(v)
            case .CmpRegReg: handle_cmp_reg_reg(v)
            case .CmpRegImm: handle_cmp_reg_imm(v)
            case .JmpImm: handle_jump_imm(v, "jmp")
            case .JeqImm: handle_jump_imm(v, "jeq")
            case .JneImm: handle_jump_imm(v, "jne")
            case .JltImm: handle_jump_imm(v, "jlt")
            case .JgtImm: handle_jump_imm(v, "jgt")
            case .JleImm: handle_jump_imm(v, "jle")
            case .JgeImm: handle_jump_imm(v, "jge")
            case .CallImm: handle_call_imm(v)
            case .Ret: handle_ret(v)
            case .Debug: handle_debug(v)
            case: {
                fmt.printf("error: unhandled opcode: %v\n", op_byte)
                increment_register(v, REGISTER_PC, 1)
            }
        }

        if render_display {
            event: sdl2.Event
            for sdl2.PollEvent(&event) {
                #partial switch event.type {
                    case .KEYDOWN:
                        #partial switch event.key.keysym.sym {
                            case .ESCAPE:
                                break loop
                        }
                    case .QUIT:
                        break loop
                }
            }
        }
    }
}

@(private)
handle_nop :: proc(v: ^VM) {
    if v.debug {
        fmt.println("nop")
    }

    increment_register(v, REGISTER_PC, 1)
}

@(private)
handle_halt :: proc(v: ^VM) {
    if v.debug {
        fmt.println("halt")
    }

    v.running = false
}

@(private)
handle_mov_reg_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register0 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    register1 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("mov %s, %s\n", register_from_id(register0), register_from_id(register1))
    }

    v.registers[register0].o = v.registers[register1].o
}

@(private)
handle_mov_reg_imm :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    value := read_immediate(v)

    if v.debug {
        fmt.printf("mov %s, %v\n", register_from_id(register), value)
    }

    v.registers[register].o = value
}

@(private)
handle_artithmetic_rrr :: proc(v: ^VM, operation: string) {
    increment_register(v, REGISTER_PC, 1)
    dest := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    lhs := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    rhs := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("%s %s, %s, %s\n", operation, register_from_id(dest), register_from_id(lhs), register_from_id(rhs))
    }

    switch operation {
        case "add": {
            value, err := object.add_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "sub": {
            value, err := object.sub_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "mul": {
            value, err := object.mul_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "div": {
            value, err := object.div_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "mod": {
            value, err := object.mod_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "and": {
            value, err := object.and_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "or": {
            value, err := object.or_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "xor": {
            value, err := object.xor_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "shl": {
            value, err := object.shl_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "shr": {
            value, err := object.shr_objects(v.registers[lhs].o, v.registers[rhs].o)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
    }
}

@(private)
handle_artithmetic_rri :: proc(v: ^VM, operation: string) {
    increment_register(v, REGISTER_PC, 1)
    dest := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    lhs := int(read_program(v))    
    rhs := read_immediate(v) 

    if v.debug {
        fmt.printf("%s %s, %s, %d\n", operation, register_from_id(dest), register_from_id(lhs), rhs)
    }
    
    switch operation {
        case "add": {
            value, err := object.add_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "sub": {
            value, err := object.sub_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "mul": {
            value, err := object.mul_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "div": {
            value, err := object.div_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "mod": {
            value, err := object.mod_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "and": {
            value, err := object.and_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "or": {
            value, err := object.or_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "xor": {
            value, err := object.xor_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "shl": {
            value, err := object.shl_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
        case "shr": {
            value, err := object.shr_objects(v.registers[lhs].o, rhs)
            if err != nil {
                fmt.printf("error: %s\n", object.error_to_string(err))
                os.exit(1)
            }
            v.registers[dest].o = value
        }
    }
}

@(private)
handle_inc :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("inc %s\n", register_from_id(register))
    }

    increment_register(v, register, 1)   
}

@(private)
handle_dec :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("dec %s\n", register_from_id(register))
    }

    decrement_register(v, register, 1)   
}


@(private)
handle_cast_reg_type :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    kind := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        v := fmt.aprintf("cast %s, %v\n", register_from_id(register), object.type_of_object(v.registers[register].o))
        fmt.print(strings.to_lower(v))
    }

    v.registers[register].o = cast_immediate(v.registers[register].o, kind)
}

@(private)
handle_push_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("push %s\n", register_from_id(register))
    }

    stack_push(v, v.registers[register].o)
}

@(private)
handle_push_imm :: proc(v: ^VM) {
    value := read_immediate(v)

    if v.debug {
        fmt.printf("push %v\n", value)
    }

    stack_push(v, value)
}

@(private)
handle_pop_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("pop %s\n", register_from_id(register))
    }

    v.registers[register].o = stack_pop(v)
}

@(private)
handle_str_reg_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register0 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    register1 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    addr := object.object_as_int(v.registers[register0].o)

    if v.debug {
        fmt.printf("str %s, %s\n", register_from_id(register0), register_from_id(register1))
    }

    v.memory[addr] = v.registers[register1].o
}

@(private)
handle_str_reg_imm :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    value := read_immediate(v)

    addr := object.object_as_int(v.registers[register].o)

    if v.debug {
        fmt.printf("str %s, %v\n", register_from_id(register), value)
    }

    v.memory[addr] = value
}

@(private)
handle_str_imm_reg :: proc(v: ^VM) {
    addr := object.object_as_int(read_immediate(v))
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("str %d, %s\n", addr, register_from_id(register))
    }

    v.memory[addr] = v.registers[register].o
}

@(private)
handle_str_imm_imm :: proc(v: ^VM) {
    addr := object.object_as_int(read_immediate(v))
    decrement_register(v, REGISTER_PC, 1)
    value := read_immediate(v)

    if v.debug {
        fmt.printf("str %d, %d\n", addr, value)
    }

    v.memory[addr] = value
}

@(private)
handle_str_reg_str :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    str := read_string(v)
    increment_register(v, REGISTER_PC, 1)

    addr := object.object_as_int(v.registers[register].o)

    if v.debug {
        fmt.printf("str %s, \"%s\"\n", register_from_id(register), unescape_string(str))
    }

    for i := 0; i < len(str); i += 1 {
        v.memory[addr+i] = str[i]
    }
}

@(private)
handle_str_imm_str :: proc(v: ^VM) {
    addr := object.object_as_int(read_immediate(v))
    decrement_register(v, REGISTER_PC, 1)
    str := read_string(v)
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("str %v, \"%s\"\n", addr, unescape_string(str))
    }

    for i := 0; i < len(str); i += 1 {
        v.memory[addr+i] = str[i]
    }
}


@(private)
handle_ld_reg_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register0 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    register1 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("ld %s, %s\n", register_from_id(register0), register_from_id(register1))
    }

    addr := object.object_as_int(v.registers[register1].o)
    v.registers[register0].o = v.memory[addr]
}

@(private)
handle_ld_reg_imm :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))    
    addr := object.object_as_int(read_immediate(v))

    if v.debug {
        fmt.printf("ld %s, %v\n", register_from_id(register), addr)
    }

    v.registers[register].o = v.memory[addr]
}

@(private)
handle_int_imm :: proc(v: ^VM) {
    value := object.object_as_int(read_immediate(v))

    if v.debug {
        fmt.printf("int %v\n", value)
    }

    handle_int(v, value)
}

@(private)
handle_int_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("int %s\n", register_from_id(register))
    }

    value := object.object_as_int(v.registers[register].o)
    handle_int(v, value)
}

@(private)
handle_cmp_reg_reg :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register0 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)
    register1 := int(read_program(v))
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("cmp %s, %s\n", register_from_id(register0), register_from_id(register1))
    }

    equals, err1 := object.objects_equal(v.registers[register0].o, v.registers[register1].o)
    if err1 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err1))
        os.exit(1)
    }

    not_equals, err2 := object.objects_not_equal(v.registers[register0].o, v.registers[register1].o)
    if err2 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err2))
        os.exit(1)
    }

    less_than, err3 := object.objects_less_than(v.registers[register0].o, v.registers[register1].o)
    if err3 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err3))
        os.exit(1)
    }

    greater_than, err4 := object.objects_greater_than(v.registers[register0].o, v.registers[register1].o)
    if err4 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err4))
        os.exit(1)
    }

    v.flags.eq = equals
    v.flags.ne = not_equals
    v.flags.lt = less_than
    v.flags.gt = greater_than
}

@(private)
handle_cmp_reg_imm :: proc(v: ^VM) {
    increment_register(v, REGISTER_PC, 1)
    register := int(read_program(v))    
    value := read_immediate(v)

    if v.debug {
        fmt.printf("cmp %s, %v\n", register_from_id(register), value)
    }

    equals, err1 := object.objects_equal(v.registers[register].o, value)
    if err1 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err1))
        os.exit(1)
    }

    not_equals, err2 := object.objects_not_equal(v.registers[register].o, value)
    if err2 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err2))
        os.exit(1)
    }

    less_than, err3 := object.objects_less_than(v.registers[register].o, value)
    if err3 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err3))
        os.exit(1)
    }

    greater_than, err4 := object.objects_greater_than(v.registers[register].o, value)
    if err4 != nil {
        fmt.printf("error: %s\n", object.error_to_string(err4))
        os.exit(1)
    }

    v.flags.eq = equals
    v.flags.ne = not_equals
    v.flags.lt = less_than
    v.flags.gt = greater_than
}

@(private)
handle_jump_imm :: proc(v: ^VM, operation: string) {
    addr := read_immediate(v)

    if v.debug {
        fmt.printf("%s %v\n", operation, addr)
    }

    switch operation {
        case "jmp": v.registers[REGISTER_PC].o = addr
        case "jeq": {
            if v.flags.eq {
                v.registers[REGISTER_PC].o = addr
            }
        }
        case "jne": {
            if v.flags.ne {
                v.registers[REGISTER_PC].o = addr
            }
        }
        case "jlt": {
            if v.flags.lt {
                v.registers[REGISTER_PC].o = addr
            }
        }
        case "jgt": {
            if v.flags.gt {
                v.registers[REGISTER_PC].o = addr
            }
        }
        case "jle": {
            if v.flags.lt || v.flags.eq {
                v.registers[REGISTER_PC].o = addr
            }
        }
        case "jge": {
            if v.flags.gt || v.flags.eq {
                v.registers[REGISTER_PC].o = addr
            }
        }
    }
}

@(private)
handle_call_imm :: proc(v: ^VM) {
    addr := read_immediate(v)

    if v.debug {
        fmt.printf("call %v\n", addr)
    }

    stack_push(v, object.increment_object(v.registers[REGISTER_PC].o, 1))
    v.registers[REGISTER_PC].o = addr
}

@(private)
handle_ret :: proc(v: ^VM) {
    addr := object.decrement_object(stack_pop(v), 1)

    if v.debug {
        fmt.printf("ret\n")
    }

    v.registers[REGISTER_PC].o = addr
}

@(private)
handle_debug :: proc(v: ^VM) {
    str := read_string(v)
    increment_register(v, REGISTER_PC, 1)

    if v.debug {
        fmt.printf("!debug \"%s\"\n", str)
    }

    for c in str {
        switch c {
            case '*': {
                debug_registers(v)
                debug_flags(v)
                debug_stack(v)
                debug_memory(v, 256)
            }
            case 'i': v.debug = !v.debug
            case 'r': debug_registers(v)
            case 'f': debug_flags(v)
            case 's': debug_stack(v)
            case 'm': debug_memory(v, 256)
        }
    }
}

@(private)
cast_immediate :: proc(value: object.Object, kind: int) -> object.Object {
    out := value
    switch kind {
        case 0: { // u8
            switch v in value {
                case u8: out = u8(v)
                case u16: out = u8(v)
                case u32: out = u8(v)
                case u64: out = u8(v)
                case u128: out = u8(v)
                case i8: out = u8(v)
                case i16: out = u8(v)
                case i32: out = u8(v)
                case i64: out = u8(v)
                case i128: out = u8(v)
                case f32: out = u8(v)
                case f64: out = u8(v)
            }
        }
        case 1: { // i8
            switch v in value {
                case u8: out = i8(v)
                case u16: out = i8(v)
                case u32: out = i8(v)
                case u64: out = i8(v)
                case u128: out = i8(v)
                case i8: out = i8(v)
                case i16: out = i8(v)
                case i32: out = i8(v)
                case i64: out = i8(v)
                case i128: out = i8(v)
                case f32: out = i8(v)
                case f64: out = i8(v)
            }
        }
        case 2: { // u16
            switch v in value {
                case u8: out = u16(v)
                case u16: out = u16(v)
                case u32: out = u16(v)
                case u64: out = u16(v)
                case u128: out = u16(v)
                case i8: out = u16(v)
                case i16: out = u16(v)
                case i32: out = u16(v)
                case i64: out = u16(v)
                case i128: out = u16(v)
                case f32: out = u16(v)
                case f64: out = u16(v)
            }
        }
        case 3: { // i16
            switch v in value {
                case u8: out = i16(v)
                case u16: out = i16(v)
                case u32: out = i16(v)
                case u64: out = i16(v)
                case u128: out = i16(v)
                case i8: out = i16(v)
                case i16: out = i16(v)
                case i32: out = i16(v)
                case i64: out = i16(v)
                case i128: out = i16(v)
                case f32: out = i16(v)
                case f64: out = i16(v)
            }
        }
        case 4: { // u32
            switch v in value {
                case u8: out = u32(v)
                case u16: out = u32(v)
                case u32: out = u32(v)
                case u64: out = u32(v)
                case u128: out = u32(v)
                case i8: out = u32(v)
                case i16: out = u32(v)
                case i32: out = u32(v)
                case i64: out = u32(v)
                case i128: out = u32(v)
                case f32: out = u32(v)
                case f64: out = u32(v)
            }
        }
        case 5: { // i32
            switch v in value {
                case u8: out = i32(v)
                case u16: out = i32(v)
                case u32: out = i32(v)
                case u64: out = i32(v)
                case u128: out = i32(v)
                case i8: out = i32(v)
                case i16: out = i32(v)
                case i32: out = i32(v)
                case i64: out = i32(v)
                case i128: out = i32(v)
                case f32: out = i32(v)
                case f64: out = i32(v)
            }
        }
        case 6: { // u64
            switch v in value {
                case u8: out = u64(v)
                case u16: out = u64(v)
                case u32: out = u64(v)
                case u64: out = u64(v)
                case u128: out = u64(v)
                case i8: out = u64(v)
                case i16: out = u64(v)
                case i32: out = u64(v)
                case i64: out = u64(v)
                case i128: out = u64(v)
                case f32: out = u64(v)
                case f64: out = u64(v)
            }
        }
        case 7: { // i64
            switch v in value {
                case u8: out = i64(v)
                case u16: out = i64(v)
                case u32: out = i64(v)
                case u64: out = i64(v)
                case u128: out = i64(v)
                case i8: out = i64(v)
                case i16: out = i64(v)
                case i32: out = i64(v)
                case i64: out = i64(v)
                case i128: out = i64(v)
                case f32: out = i64(v)
                case f64: out = i64(v)
            }
        }
        case 8: { // u128
            switch v in value {
                case u8: out = u128(v)
                case u16: out = u128(v)
                case u32: out = u128(v)
                case u64: out = u128(v)
                case u128: out = u128(v)
                case i8: out = u128(v)
                case i16: out = u128(v)
                case i32: out = u128(v)
                case i64: out = u128(v)
                case i128: out = u128(v)
                case f32: out = u128(v)
                case f64: out = u128(v)
            }
        }
        case 9: { // i128
            switch v in value {
                case u8: out = i128(v)
                case u16: out = i128(v)
                case u32: out = i128(v)
                case u64: out = i128(v)
                case u128: out = i128(v)
                case i8: out = i128(v)
                case i16: out = i128(v)
                case i32: out = i128(v)
                case i64: out = i128(v)
                case i128: out = i128(v)
                case f32: out = i128(v)
                case f64: out = i128(v)
            }
        }
        case 10: { // f32
            switch v in value {
                case u8: out = f32(v)
                case u16: out = f32(v)
                case u32: out = f32(v)
                case u64: out = f32(v)
                case u128: out = f32(v)
                case i8: out = f32(v)
                case i16: out = f32(v)
                case i32: out = f32(v)
                case i64: out = f32(v)
                case i128: out = f32(v)
                case f32: out = f32(v)
                case f64: out = f32(v)
            }
        }
        case 11: { // f64
            switch v in value {
                case u8: out = f64(v)
                case u16: out = f64(v)
                case u32: out = f64(v)
                case u64: out = f64(v)
                case u128: out = f64(v)
                case i8: out = f64(v)
                case i16: out = f64(v)
                case i32: out = f64(v)
                case i64: out = f64(v)
                case i128: out = f64(v)
                case f32: out = f64(v)
                case f64: out = f64(v)
            }
        }
    }

    return out
}

@(private)
read_string :: proc(v: ^VM) -> string {
    increment_register(v, REGISTER_PC, 1)
    length := int(read_program(v))
    output := strings.builder_make()

    for i := 0; i < length; i += 1 {
        increment_register(v, REGISTER_PC, 1)
        c := read_program(v)

        strings.write_byte(&output, c)
    }

    return strings.to_string(output)
}

@(private)
read_immediate :: proc(v: ^VM) -> object.Object {
    increment_register(v, REGISTER_PC, 1)
    if !program_can_continue(v) {
        fmt.printf("error: failed to read immediate pc goes out of program scope\n")
        os.exit(1)
    }

    it := read_program(v)
    switch it {
        case 0: {
            increment_register(v, REGISTER_PC, 1)
            value := read_program(v)
            increment_register(v, REGISTER_PC, 1)
            return u8(value)
        }
        case 1: {
            increment_register(v, REGISTER_PC, 1)
            value := read_program(v)
            increment_register(v, REGISTER_PC, 1)
            return i8(value)
        }
        case 2: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(u16)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 2; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return u16(value)
        }
        case 3: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(i16)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 2; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return i16(value)
        }
        case 4: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(u32)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 4; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return u32(value)
        }
        case 5: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(i32)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 4; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return i32(value)
        }
        case 6: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(u64)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 8; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return u64(value)
        }
        case 7: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(i64)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 8; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return i64(value)
        }
        case 8: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(u128)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 16; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return u128(value)
        }
        case 9: {
            increment_register(v, REGISTER_PC, 1)

            size := size_of(i128)
            if ((len(v.program) - size) < program_count_as_int(v)) {
                fmt.printf("error: failed to read immediate pc goes out of program scope\n")
                os.exit(1)
            }

            value := 0
            for idx := 0; idx < 16; idx += 1 {
                value |= int(read_program(v)) << byte(idx * 8)
                increment_register(v, REGISTER_PC, 1)
            }

            return i128(value)
        }
    }

    fmt.printf("error: failed to read immediate type: %v\n", it)
    os.exit(1)
}

@(private)
read_program :: proc(v: ^VM) -> byte {
    #partial switch o in v.registers[REGISTER_PC].o {
        case u8: return v.program[o]
        case u16: return v.program[o]
        case u32: return v.program[o]
        case u64: return v.program[o]
        case u128: return v.program[o]
        case i8: return v.program[o]
        case i16: return v.program[o]
        case i32: return v.program[o]
        case i64: return v.program[o]
        case i128: return v.program[o]
        case f32: return v.program[cast(int)o]
        case f64: return v.program[cast(int)o]
    }

    fmt.printf("error: failed to read program due to its type: %v\n", v.registers[REGISTER_PC].o)
    os.exit(1)
}

@(private)
program_can_continue :: proc(v: ^VM) -> bool {
    #partial switch o in v.registers[REGISTER_PC].o {
        case u8: if (int(o+1) >= len(v.program)) {
            return false
        }
        case u16: if (int(o+1) >= len(v.program)) {
            return false
        }
        case u32: if (int(o+1) >= len(v.program)) {
            return false
        }
        case u64: if (int(o+1) >= len(v.program)) {
            return false
        }
        case u128: if (int(o+1) >= len(v.program)) {
            return false
        }
        case i8: if (int(o+1) >= len(v.program)) {
            return false
        }
        case i16: if (int(o+1) >= len(v.program)) {
            return false
        }
        case i32: if (int(o+1) >= len(v.program)) {
            return false
        }
        case i64: if (int(o+1) >= len(v.program)) {
            return false
        }
        case i128: if (int(o+1) >= len(v.program)) {
            return false
        }
        case f32: if (int(o+1) >= len(v.program)) {
            return false
        }
        case f64: if (int(o+1) >= len(v.program)) {
            return false
        }
    }

    return true
}

@(private)
program_count_as_int :: proc(v: ^VM) -> int {
    #partial switch o in v.registers[REGISTER_PC].o {
        case u8: return int(o)
        case u16: return int(o)
        case u32: return int(o)
        case u64: return int(o)
        case u128: return int(o)
        case i8: return int(o)
        case i16: return int(o)
        case i32: return int(o)
        case i64: return int(o)
        case i128: return int(o)
        case f32: return int(o)
        case f64: return int(o)
    }

    return -1
}