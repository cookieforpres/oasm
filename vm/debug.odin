package vm

import "core:fmt"
import "../object"

@(private)
register_from_id :: proc(id: int) -> string {
    switch id {
        case 0: fallthrough
        case 1: fallthrough
        case 2: fallthrough
        case 3: fallthrough
        case 4: fallthrough
        case 5: fallthrough
        case 6: fallthrough
        case 7: fallthrough
        case 8: fallthrough
        case 9: fallthrough
        case 10: fallthrough
        case 11: fallthrough
        case 12: fallthrough
        case 13: return fmt.aprintf("r%d", id)
        case 14: return "sp"
        case 15: return "pc"
    }

    return "unknown"
}

@(private)
debug_registers :: proc(v: ^VM) {
    fmt.println("==== REGISTERS ====")
    for i := 0; i < REGISTER_CAPACITY-2; i += 1 {
        if i < 10 {
            fmt.printf("r%d  = %v\n", i, v.registers[i].o)
        } else {
            fmt.printf("r%d = %v\n", i, v.registers[i].o)
        }
    }

    fmt.printf("sp  = %v\n", v.registers[REGISTER_SP].o)
    fmt.printf("pc  = %v\n", v.registers[REGISTER_PC].o)
    fmt.println()
}

@(private)
debug_flags :: proc(v: ^VM) {
    fmt.println("==== FLAGS====")
    fmt.printf("eq  = %v\n", v.flags.eq)
    fmt.printf("ne  = %v\n", v.flags.ne)
    fmt.printf("lt  = %v\n", v.flags.lt)
    fmt.printf("gt  = %v\n", v.flags.gt)
    fmt.println()
}

@(private)
debug_stack :: proc(v: ^VM) {
    fmt.println("==== STACK ====")
    for i := 32; i < object.object_as_int(v.registers[REGISTER_SP].o) + 32; i -= 1 {
        fmt.printf("%04x: %v\n", i, v.memory[i])
    }
    fmt.println()
}

@(private)
debug_memory :: proc(v: ^VM, amount: int) {
    memory_index :: proc(v: ^VM, index: int) -> object.Object {
        if v.memory[index] == nil {
            return u8(0)
        }

        return v.memory[index]
    }

    fmt.println("==== MEMORY ====")
	for i := 0; i < amount; i += 16 {
		fmt.printf("%04x:  %02x %02x %02x %02x %02x %02x %02x %02x   %02x %02x %02x %02x %02x %02x %02x %02x\n",
			i, memory_index(v, i+0), memory_index(v, i+1), memory_index(v, i+2), memory_index(v, i+3),
			memory_index(v, i+4), memory_index(v, i+5), memory_index(v, i+6), memory_index(v, i+7),
			memory_index(v, i+8), memory_index(v, i+9), memory_index(v, i+10), memory_index(v, i+11),
			memory_index(v, i+12), memory_index(v, i+13), memory_index(v, i+14), memory_index(v, i+15))
	}
    fmt.println()
}