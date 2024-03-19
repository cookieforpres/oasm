package vm

import "core:fmt"
import "core:strings"
import "core:bytes"
import "core:os"
import "core:strconv"
import "core:time"
import "core:net"
import "../object"

@(private)
handle_int :: proc(v: ^VM, index: int) {
    switch index {
        case 0: exit_int(v)
        case 1: read_int(v)
        case 2: write_int(v)
        case 3: open_int(v)
        case 4: close_int(v)
        
        case 5: listen_tcp_int(v)
        case 6: connect_tcp_int(v)
        case 7: accept_tcp_int(v)

        case 10: itoa_int(v)

        case 20: clock_int(v)
    }
}

@(private)
exit_int :: proc(v: ^VM) {
    status := object.object_as_int(v.registers[0].o)
    os.exit(status)
}

@(private)
read_int :: proc(v: ^VM) {
    fd := object.object_as_int(v.registers[0].o)
    addr := object.object_as_int(v.registers[1].o)
    length := object.object_as_int(v.registers[2].o)

    buffer := make([]byte, length)

    n, err := os.read(cast(os.Handle)fd, buffer)
    if err < 0 {
        v.registers[0].o = i64(err)
    } else {
        for i := 0; i < length; i += 1 {
            v.memory[addr+i] = buffer[i]
        }

        v.registers[0].o = i64(n)
    }
}

@(private)
write_int :: proc(v: ^VM) {
    fd := object.object_as_int(v.registers[0].o)
    addr := object.object_as_int(v.registers[1].o)
    length := object.object_as_int(v.registers[2].o)

    text_builder: bytes.Buffer
    for i := 0; i < length; i += 1 {
        bytes.buffer_write_byte(&text_builder, object.object_as_u8(v.memory[addr+i]))
    }
    text := bytes.buffer_to_bytes(&text_builder)
    
    os.write(cast(os.Handle)fd, text)
    v.registers[0].o = i64(len(text))
}

@(private)
open_int :: proc(v: ^VM) {
    addr := object.object_as_int(v.registers[0].o)
    length := object.object_as_int(v.registers[1].o)
    mode := object.object_as_int(v.registers[2].o)
    perm := object.object_as_int(v.registers[3].o)

    path_builder := strings.builder_make()
    for i := 0; i < length; i += 1 {
        strings.write_byte(&path_builder, object.object_as_u8(v.memory[addr+i]))
    }
    path := strings.to_string(path_builder)

    fd, err := os.open(path, int(mode), int(perm))
    if err < 0 {
        v.registers[0].o = i64(err)
    } else {
        v.registers[0].o = i64(fd)
    }
}

@(private)
close_int :: proc(v: ^VM) {
    fd := object.object_as_int(v.registers[0].o)
    if os.close(cast(os.Handle)fd) {
        v.registers[0].o = i64(0)
    } else {
        v.registers[0].o = i64(-1)
    }
}

@(private)
listen_tcp_int :: proc(v: ^VM) {
    endpoint_addr := object.object_as_int(v.registers[0].o)
    endpoint_len := object.object_as_int(v.registers[1].o)
    backlog := object.object_as_int(v.registers[2].o)

    endpoint_builder := strings.builder_make()
    for i := 0; i < endpoint_len; i += 1 {
        strings.write_byte(&endpoint_builder, object.object_as_u8(v.memory[endpoint_addr+i]))
    }
    endpoint_string := strings.to_string(endpoint_builder)

    endpoint, endpoint_parsed := net.parse_endpoint(endpoint_string)
    if !endpoint_parsed {
        v.registers[0].o = i64(-1)
        return
    }

    socket, err := net.listen_tcp(endpoint, backlog)
    if err != nil {
        v.registers[0].o = i64(-2)
        return
    }

    v.registers[0].o = i64(socket)
}

@(private)
connect_tcp_int :: proc(v: ^VM) {
    endpoint_addr := object.object_as_int(v.registers[0].o)
    endpoint_len := object.object_as_int(v.registers[1].o)

    endpoint_builder := strings.builder_make()
    for i := 0; i < endpoint_len; i += 1 {
        strings.write_byte(&endpoint_builder, object.object_as_u8(v.memory[endpoint_addr+i]))
    }
    endpoint_string := strings.to_string(endpoint_builder)

    endpoint, endpoint_parsed := net.parse_endpoint(endpoint_string)
    if !endpoint_parsed {
        v.registers[0].o = i64(-1)
        return
    }

    socket, err := net.dial_tcp(endpoint)
    if err != nil {
        v.registers[0].o = i64(-1)
        return
    }

    v.registers[0].o = i64(socket)
}

@(private)
accept_tcp_int :: proc(v: ^VM) {
    socket := object.object_as_int(v.registers[0].o)

    client, _, err := net.accept_tcp(cast(net.TCP_Socket)socket)
    if err != nil {
        v.registers[0].o = i64(-1)
        return
    }

    v.registers[0].o = i64(client)
}

@(private)
itoa_int :: proc(v: ^VM) {
    num_addr := object.object_as_int(v.registers[0].o)
    ret_addr := object.object_as_int(v.registers[1].o)

    value := fmt.aprintf("%v", v.memory[num_addr])

    for i := 0; i < len(value); i += 1 {
        v.memory[ret_addr+i] = value[i]
    }

    v.registers[0].o = i64(len(value))
}

@(private)
clock_int :: proc(v: ^VM) {
    now := time.now()
    v.registers[0].o = i64(time.to_unix_nanoseconds(now) / 1000000)
}

@(private)
int_to_addr_family :: proc(num: int) -> net.Address_Family {
    af: net.Address_Family
    switch num {
        case 0: af = .IP4
        case 1: af = .IP6
    }
    return af
}

@(private)
int_to_socket_protocol :: proc(num: int) -> net.Socket_Protocol {
    st: net.Socket_Protocol
    switch num {
        case 0: st = .TCP
        case 1: st = .UDP
    }
    return st
}