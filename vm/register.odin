package vm

import "../object"

REGISTER_SP :: REGISTER_CAPACITY - 2
REGISTER_PC :: REGISTER_CAPACITY - 1

Register :: struct {
    o: object.Object
}

@(private)
increment_register :: proc(v: ^VM, register: int, amount: int) {
    v.registers[register].o = object.increment_object(v.registers[register].o, amount)
}


@(private)
decrement_register :: proc(v: ^VM, register: int, amount: int) {
    v.registers[register].o = object.decrement_object(v.registers[register].o, amount)
}