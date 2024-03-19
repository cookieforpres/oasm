package object 

import "core:fmt"

type_of_object :: proc(o: Object) -> ObjectKind {
    switch _ in o {
        case u8: return .U8
        case u16: return .U16
        case u32: return .U32
        case u64: return .U64
        case u128: return .U128
        case i8: return .I8
        case i16: return .I16
        case i32: return .I32
        case i64: return .I64
        case i128: return .I128
        case f32: return .F32
        case f64: return .F64
        case: panic(fmt.aprintf("invalid object type: %v\n", o))
    }
}

object_is_zero :: proc(o: Object) -> bool {
    switch _ in o {
        case u8: return  o.(u8) == 0
        case u16: return  o.(u16) == 0
        case u32: return  o.(u32) == 0
        case u64: return  o.(u64) == 0
        case u128: return  o.(u128) == 0
        case i8: return  o.(i8) == 0
        case i16: return  o.(i16) == 0
        case i32: return  o.(i32) == 0
        case i64: return  o.(i64) == 0
        case i128: return  o.(i128) == 0
        case f32: return  o.(f32) == 0
        case f64: return  o.(f64) == 0
        case: panic(fmt.aprintf("invalid object type: %v\n", o))
    }
}