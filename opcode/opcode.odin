package opcode

Opcode :: enum byte {
    Nop = 0x00,         // no operation
    Halt,               // halt the program
    MovRegReg,          // move value in register 1 into register 0
    MovRegImm,          // move number in register
    AddRegRegReg,       // add register 1 and register 2 and store result in register 0
    AddRegRegImm,       // add register 1 and number and store result in register 0
    SubRegRegReg,       // sub register 1 and register 2 and store result in register 0
    SubRegRegImm,       // sub register 1 and number and store result in register 0
    MulRegRegReg,       // mul register 1 and register 2 and store result in register 0
    MulRegRegImm,       // mul register 1 and number and store result in register 0
    DivRegRegReg,       // div register 1 and register 2 and store result in register 0
    DivRegRegImm,       // div register 1 and number and store result in register 0
    ModRegRegReg,
    ModRegRegImm,
    AndRegRegReg,
    AndRegRegImm,
    OrRegRegReg,
    OrRegRegImm,
    XorRegRegReg,
    XorRegRegImm,
    ShlRegRegReg,
    ShlRegRegImm,
    ShrRegRegReg,
    ShrRegRegImm,
    IncReg,
    DecReg,
    CastRegType,        // cast new type to register
    PushReg,            // push value of register to stack
    PushImm,            // push number to stack
    PopReg,             // pop value from stack and store in register
    StrRegReg,        // store value in register 1 in memory at address in register 0
    StrRegImm,        // store value in memory at address in register 0
    StrImmReg,        // store value in register at address
    StrImmImm,        // store value at address
    StrRegStr,        // store string at address in register
    StrImmStr,        // store string at address
    LdRegReg,         // load register 0 with the value in memory at address in register 1
    LdRegImm,         // load register 0 with value in memory at adress 0xff 
    IntReg,            // trigger trap from value in register 0
    IntImm,            // trigger trap from value
    CmpRegReg,          // compare register 0 with registers 1 and update flags
    CmpRegImm,          // compare registe with number and update flags
    JmpImm,
    JeqImm,
    JneImm,
    JltImm,
    JgtImm,
    JleImm,
    JgeImm,
    CallImm,
    Ret,

    Debug,
}

from_byte :: proc(b: byte) -> Opcode {
    switch b {
        case 0x00: return .Nop
        case 0x01: return .Halt
        case 0x02: return .MovRegReg
        case 0x03: return .MovRegImm
        case 0x04: return .AddRegRegReg
        case 0x05: return .AddRegRegImm
        case 0x06: return .SubRegRegReg
        case 0x07: return .SubRegRegImm
        case 0x08: return .MulRegRegReg
        case 0x09: return .MulRegRegImm
        case 0x0a: return .DivRegRegReg
        case 0x0b: return .DivRegRegImm
        case 0x0c: return .ModRegRegReg
        case 0x0d: return .ModRegRegImm
        case 0x0e: return .AndRegRegReg
        case 0x0f: return .AndRegRegImm
        case 0x10: return .OrRegRegReg
        case 0x11: return .OrRegRegImm
        case 0x12: return .XorRegRegReg
        case 0x13: return .XorRegRegImm
        case 0x14: return .ShlRegRegReg
        case 0x15: return .ShlRegRegImm
        case 0x16: return .ShrRegRegReg
        case 0x17: return .ShrRegRegImm
        case 0x18: return .IncReg
        case 0x19: return .DecReg
        case 0x1a: return .CastRegType
        case 0x1b: return .PushReg
        case 0x1c: return .PushImm
        case 0x1d: return .PopReg
        case 0x1e: return .StrRegReg
        case 0x1f: return .StrRegImm
        case 0x20: return .StrImmReg
        case 0x21: return .StrImmImm
        case 0x22: return .StrRegStr
        case 0x23: return .StrImmStr
        case 0x24: return .LdRegReg
        case 0x25: return .LdRegImm
        case 0x26: return .IntReg
        case 0x27: return .IntImm
        case 0x28: return .CmpRegReg
        case 0x29: return .CmpRegImm
        case 0x2a: return .JmpImm
        case 0x2b: return .JeqImm
        case 0x2c: return .JneImm
        case 0x2d: return .JltImm
        case 0x2e: return .JgtImm
        case 0x2f: return .JleImm
        case 0x30: return .JgeImm
        case 0x31: return .CallImm
        case 0x32: return .Ret
        case 0x33: return .Debug
    }

    return nil
}

from_opcode :: proc(o: Opcode) -> byte {
    switch o {
        case .Nop: return 0x00
        case .Halt: return 0x01
        case .MovRegReg: return 0x02
        case .MovRegImm: return 0x03
        case .AddRegRegReg: return 0x04
        case .AddRegRegImm: return 0x05
        case .SubRegRegReg: return 0x06
        case .SubRegRegImm: return 0x07
        case .MulRegRegReg: return 0x08
        case .MulRegRegImm: return 0x09
        case .DivRegRegReg: return 0x0a
        case .DivRegRegImm: return 0x0b
        case .ModRegRegReg: return 0x0c
        case .ModRegRegImm: return 0x0d
        case .AndRegRegReg: return 0x0e
        case .AndRegRegImm: return 0x0f
        case .OrRegRegReg: return 0x10
        case .OrRegRegImm: return 0x11
        case .XorRegRegReg: return 0x12
        case .XorRegRegImm: return 0x13
        case .ShlRegRegReg: return 0x14
        case .ShlRegRegImm: return 0x15
        case .ShrRegRegReg: return 0x16
        case .ShrRegRegImm: return 0x17
        case .IncReg: return 0x18
        case .DecReg: return 0x19
        case .CastRegType: return 0x1a
        case .PushReg: return 0x1b
        case .PushImm: return 0x1c
        case .PopReg: return 0x1d
        case .StrRegReg: return 0x1e
        case .StrRegImm: return 0x1f
        case .StrImmReg: return 0x20
        case .StrImmImm: return 0x21
        case .StrRegStr: return 0x22
        case .StrImmStr: return 0x23
        case .LdRegReg: return 0x24
        case .LdRegImm: return 0x25
        case .IntReg: return 0x26
        case .IntImm: return 0x27
        case .CmpRegReg: return 0x28
        case .CmpRegImm: return 0x29
        case .JmpImm: return 0x2a
        case .JeqImm: return 0x2b
        case .JneImm: return 0x2c
        case .JltImm: return 0x2d
        case .JgtImm: return 0x2e
        case .JleImm: return 0x2f
        case .JgeImm: return 0x30
        case .CallImm: return 0x31
        case .Ret: return 0x32
        case .Debug: return 0x33
    }

    return 0xff
}