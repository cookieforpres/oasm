package object

import "core:fmt"

Object :: union {
    u8,
    u16,
    u32,
    u64,
    u128,
    i8,
    i16,
    i32,
    i64,
    i128,
    f32,
    f64,
}

ObjectKind :: enum u8 {
    I8 = 0,
    I16,
    I32,
    I64,
    I128,
    U8,
    U16,
    U32,
    U64,
    U128,
    F32,
    F64,
}

ObjectError :: union {
    NonMatchingTypesError,
    InvalidOperationForTypeError,
    OperationForTypeUnhandledError,
    DivisionByZeroError,
    InfiniteError,
}

NonMatchingTypesError :: struct {
    message: string
}

InvalidOperationForTypeError :: struct {
    message: string
}

OperationForTypeUnhandledError :: struct {
    message: string
}

DivisionByZeroError :: struct {
    message: string
}

InfiniteError :: struct {
    message: string
}

object_as_int :: proc(object: Object) -> int {
    #partial switch o in object {
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

object_as_u8 :: proc(object: Object) -> u8 {
    #partial switch o in object {
        case u8: return u8(o)
        case u16: return u8(o)
        case u32: return u8(o)
        case u64: return u8(o)
        case u128: return u8(o)
        case i8: return u8(o)
        case i16: return u8(o)
        case i32: return u8(o)
        case i64: return u8(o)
        case i128: return u8(o)
        case f32: return u8(o)
        case f64: return u8(o)
    }

    return 0
}

error_to_string :: proc(e: ObjectError) -> string {
    switch v in e {
        case NonMatchingTypesError: return v.message
        case InvalidOperationForTypeError: return v.message
        case OperationForTypeUnhandledError: return v.message
        case DivisionByZeroError: return v.message
        case InfiniteError: return v.message
    }

    return ""
}

add_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) + o2.(u8), nil
        case u16: return o1.(u16) + o2.(u16), nil
        case u32: return o1.(u32) + o2.(u32), nil
        case u64: return o1.(u64) + o2.(u64), nil
        case u128: return o1.(u128) + o2.(u128), nil
        case i8: return o1.(i8) + o2.(i8), nil
        case i16: return o1.(i16) + o2.(i16), nil
        case i32: return o1.(i32) + o2.(i32), nil
        case i64: return o1.(i64) + o2.(i64), nil
        case i128: return o1.(i128) + o2.(i128), nil
        case f32: return o1.(f32) + o2.(f32), nil
        case f64: return o1.(f64) + o2.(f64), nil
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support add", t1)}
    }
}

sub_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) - o2.(u8), nil
        case u16: return o1.(u16) - o2.(u16), nil
        case u32: return o1.(u32) - o2.(u32), nil
        case u64: return o1.(u64) - o2.(u64), nil
        case u128: return o1.(u128) - o2.(u128), nil
        case i8: return o1.(i8) - o2.(i8), nil
        case i16: return o1.(i16) - o2.(i16), nil
        case i32: return o1.(i32) - o2.(i32), nil
        case i64: return o1.(i64) - o2.(i64), nil
        case i128: return o1.(i128) - o2.(i128), nil
        case f32: return o1.(f32) - o2.(f32), nil
        case f64: return o1.(f64) - o2.(f64), nil
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support sub", t1)}
    }
}

mul_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) * o2.(u8), nil
        case u16: return o1.(u16) * o2.(u16), nil
        case u32: return o1.(u32) * o2.(u32), nil
        case u64: return o1.(u64) * o2.(u64), nil
        case u128: return o1.(u128) * o2.(u128), nil
        case i8: return o1.(i8) * o2.(i8), nil
        case i16: return o1.(i16) * o2.(i16), nil
        case i32: return o1.(i32) * o2.(i32), nil
        case i64: return o1.(i64) * o2.(i64), nil
        case i128: return o1.(i128) * o2.(i128), nil
        case f32: return o1.(f32) * o2.(f32), nil
        case f64: return o1.(f64) * o2.(f64), nil
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support mul", t1)}
    }
}

div_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    if object_is_zero(o2) {
        return nil, DivisionByZeroError{fmt.aprintf("attempted to div %v by 0", o1)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) / o2.(u8), nil
        case u16: return o1.(u16) / o2.(u16), nil
        case u32: return o1.(u32) / o2.(u32), nil
        case u64: return o1.(u64) / o2.(u64), nil
        case u128: return o1.(u128) / o2.(u128), nil
        case i8: return o1.(i8) / o2.(i8), nil
        case i16: return o1.(i16) / o2.(i16), nil
        case i32: return o1.(i32) / o2.(i32), nil
        case i64: return o1.(i64) / o2.(i64), nil
        case i128: return o1.(i128) / o2.(i128), nil
        case f32: return o1.(f32) / o2.(f32), nil
        case f64: return o1.(f64) / o2.(f64), nil
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support div", t1)}
    }
}

mod_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    if object_is_zero(o2) {
        return nil, InfiniteError{fmt.aprintf("attempted to mod %v by 0", o1)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) % o2.(u8), nil
        case u16: return o1.(u16) % o2.(u16), nil
        case u32: return o1.(u32) % o2.(u32), nil
        case u64: return o1.(u64) % o2.(u64), nil
        case u128: return o1.(u128) % o2.(u128), nil
        case i8: return o1.(i8) % o2.(i8), nil
        case i16: return o1.(i16) % o2.(i16), nil
        case i32: return o1.(i32) % o2.(i32), nil
        case i64: return o1.(i64) % o2.(i64), nil
        case i128: return o1.(i128) % o2.(i128), nil
        case f32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support mod", t1)}
        case f64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support mod", t1)}
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support mod", t1)}
    }
}

and_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) & o2.(u8), nil
        case u16: return o1.(u16) & o2.(u16), nil
        case u32: return o1.(u32) & o2.(u32), nil
        case u64: return o1.(u64) & o2.(u64), nil
        case u128: return o1.(u128) & o2.(u128), nil
        case i8: return o1.(i8) & o2.(i8), nil
        case i16: return o1.(i16) & o2.(i16), nil
        case i32: return o1.(i32) & o2.(i32), nil
        case i64: return o1.(i64) & o2.(i64), nil
        case i128: return o1.(i128) & o2.(i128), nil
        case f32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support and", t1)}
        case f64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support and", t1)}
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support and", t1)}
    }
}

or_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) | o2.(u8), nil
        case u16: return o1.(u16) | o2.(u16), nil
        case u32: return o1.(u32) | o2.(u32), nil
        case u64: return o1.(u64) | o2.(u64), nil
        case u128: return o1.(u128) | o2.(u128), nil
        case i8: return o1.(i8) | o2.(i8), nil
        case i16: return o1.(i16) | o2.(i16), nil
        case i32: return o1.(i32) | o2.(i32), nil
        case i64: return o1.(i64) | o2.(i64), nil
        case i128: return o1.(i128) | o2.(i128), nil
        case f32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support or", t1)}
        case f64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support or", t1)}
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support or", t1)}
    }
}

xor_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) ~ o2.(u8), nil
        case u16: return o1.(u16) ~ o2.(u16), nil
        case u32: return o1.(u32) ~ o2.(u32), nil
        case u64: return o1.(u64) ~ o2.(u64), nil
        case u128: return o1.(u128) ~ o2.(u128), nil
        case i8: return o1.(i8) ~ o2.(i8), nil
        case i16: return o1.(i16) ~ o2.(i16), nil
        case i32: return o1.(i32) ~ o2.(i32), nil
        case i64: return o1.(i64) ~ o2.(i64), nil
        case i128: return o1.(i128) ~ o2.(i128), nil
        case f32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support xor", t1)}
        case f64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support xor", t1)}
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support xor", t1)}
    }
}

shl_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) << o2.(u8), nil
        case u16: return o1.(u16) << o2.(u16), nil
        case u32: return o1.(u32) << o2.(u32), nil
        case u64: return o1.(u64) << o2.(u64), nil
        case u128: return o1.(u128) << o2.(u128), nil
        case i8: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i16: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i128: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case f32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case f64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support shl", t1)}
    }
}

shr_objects :: proc(o1: Object, o2: Object) -> (Object, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return nil, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) >> o2.(u8), nil
        case u16: return o1.(u16) >> o2.(u16), nil
        case u32: return o1.(u32) >> o2.(u32), nil
        case u64: return o1.(u64) >> o2.(u64), nil
        case u128: return o1.(u128) >> o2.(u128), nil
        case i8: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i16: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case i128: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case f32: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case f64: return nil, InvalidOperationForTypeError{fmt.aprintf("%v does not support shl", t1)}
        case: return nil, OperationForTypeUnhandledError{fmt.aprintf("%v does not support shl", t1)}
    }
}

objects_equal :: proc(o1: Object, o2:  Object) -> (bool, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return false, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) == o2.(u8), nil
        case u16: return o1.(u16) == o2.(u16), nil
        case u32: return o1.(u32) == o2.(u32), nil
        case u64: return o1.(u64) == o2.(u64), nil
        case u128: return o1.(u128) == o2.(u128), nil
        case i8: return o1.(i8) == o2.(i8), nil
        case i16: return o1.(i16) == o2.(i16), nil
        case i32: return o1.(i32) == o2.(i32), nil
        case i64: return o1.(i64) == o2.(i64), nil
        case i128: return o1.(i128) == o2.(i128), nil
        case f32: return o1.(f32) == o2.(f32), nil
        case f64: return o1.(f64) == o2.(f64), nil
        case: return false, OperationForTypeUnhandledError{fmt.aprintf("%v does not support equal", t1)}
    }
}

objects_not_equal :: proc(o1: Object, o2:  Object) -> (bool, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return false, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) != o2.(u8), nil
        case u16: return o1.(u16) != o2.(u16), nil
        case u32: return o1.(u32) != o2.(u32), nil
        case u64: return o1.(u64) != o2.(u64), nil
        case u128: return o1.(u128) != o2.(u128), nil
        case i8: return o1.(i8) != o2.(i8), nil
        case i16: return o1.(i16) != o2.(i16), nil
        case i32: return o1.(i32) != o2.(i32), nil
        case i64: return o1.(i64) != o2.(i64), nil
        case i128: return o1.(i128) != o2.(i128), nil
        case f32: return o1.(f32) != o2.(f32), nil
        case f64: return o1.(f64) != o2.(f64), nil
        case: return false, OperationForTypeUnhandledError{fmt.aprintf("%v does not support not equal", t1)}
    }
}

objects_less_than :: proc(o1: Object, o2:  Object) -> (bool, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return false, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) < o2.(u8), nil
        case u16: return o1.(u16) < o2.(u16), nil
        case u32: return o1.(u32) < o2.(u32), nil
        case u64: return o1.(u64) < o2.(u64), nil
        case u128: return o1.(u128) < o2.(u128), nil
        case i8: return o1.(i8) < o2.(i8), nil
        case i16: return o1.(i16) < o2.(i16), nil
        case i32: return o1.(i32) < o2.(i32), nil
        case i64: return o1.(i64) < o2.(i64), nil
        case i128: return o1.(i128) < o2.(i128), nil
        case f32: return o1.(f32) < o2.(f32), nil
        case f64: return o1.(f64) < o2.(f64), nil
        case: return false, OperationForTypeUnhandledError{fmt.aprintf("%v does not support less than", t1)}
    }
}

objects_greater_than :: proc(o1: Object, o2:  Object) -> (bool, ObjectError) {
    t1 := type_of_object(o1)
    t2 := type_of_object(o2)
    if t1 != t2 {
        return false, NonMatchingTypesError{fmt.aprintf("%v is not the same type as %v", t1, t2)}
    }

    #partial switch _ in o1 {
        case u8: return o1.(u8) > o2.(u8), nil
        case u16: return o1.(u16) > o2.(u16), nil
        case u32: return o1.(u32) > o2.(u32), nil
        case u64: return o1.(u64) > o2.(u64), nil
        case u128: return o1.(u128) > o2.(u128), nil
        case i8: return o1.(i8) > o2.(i8), nil
        case i16: return o1.(i16) > o2.(i16), nil
        case i32: return o1.(i32) > o2.(i32), nil
        case i64: return o1.(i64) > o2.(i64), nil
        case i128: return o1.(i128) > o2.(i128), nil
        case f32: return o1.(f32) > o2.(f32), nil
        case f64: return o1.(f64) > o2.(f64), nil
        case: return false, OperationForTypeUnhandledError{fmt.aprintf("%v does not support greater than", t1)}
    }
}

increment_object :: proc(object: Object, amount: int) -> Object {
    new_object := object
    #partial switch o in object {
        case u8: new_object = o + u8(amount)
        case u16: new_object = o + u16(amount)
        case u32: new_object = o + u32(amount)
        case u64: new_object = o + u64(amount)
        case u128: new_object = o + u128(amount)
        case i8: new_object = o + i8(amount)
        case i16: new_object = o + i16(amount)
        case i32: new_object = o + i32(amount)
        case i64: new_object = o + i64(amount)
        case i128: new_object = o + i128(amount)
        case f32: new_object = o + f32(amount)
        case f64: new_object = o + f64(amount)
    }
    return new_object
}

decrement_object :: proc(object: Object, amount: int) -> Object {
    new_object := object
    #partial switch o in object {
        case u8: new_object = o - u8(amount)
        case u16: new_object = o - u16(amount)
        case u32: new_object = o - u32(amount)
        case u64: new_object = o - u64(amount)
        case u128: new_object = o - u128(amount)
        case i8: new_object = o - i8(amount)
        case i16: new_object = o - i16(amount)
        case i32: new_object = o - i32(amount)
        case i64: new_object = o - i64(amount)
        case i128: new_object = o - i128(amount)
        case f32: new_object = o - f32(amount)
        case f64: new_object = o - f64(amount)
    }
    return new_object
}