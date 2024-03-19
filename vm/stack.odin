package vm

import "../object"

stack_push :: proc(v: ^VM, value: object.Object) {
    v.memory[object.object_as_int(v.registers[REGISTER_SP].o)] = value
    increment_register(v, REGISTER_SP, 1)
}

stack_pop :: proc(v: ^VM) -> object.Object {
    decrement_register(v, REGISTER_SP, 1)
    value := v.memory[object.object_as_int(v.registers[REGISTER_SP].o)]
    return value
}