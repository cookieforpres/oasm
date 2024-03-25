package utils

import "core:os"
import "core:fmt"
import "core:strings"

read_file_to_bytes :: proc(name: string) -> []byte {
    data, success := os.read_entire_file(name);
    if !success {
        fmt.printf("error: failed to read file: %s\n", name)
        os.exit(1)
    }

    return data
}

unescape_string :: proc(value: string) -> string {
    output := strings.builder_make()

    for i := 0; i < len(value); i += 1 {
        switch value[i] {
            case '\n': strings.write_string(&output, "\\n")
            case '\r': strings.write_string(&output, "\\r")
            case '\t': strings.write_string(&output, "\\t")
            case: strings.write_byte(&output, value[i])
        }
    }

    return strings.to_string(output)
}

bubble_sort_string_slice :: proc(keys: []string) {
    n := len(keys)
    for i := 0; i < n-1; i += 1 {
        for j := 0; j < n-i-1; j += 1 {
            if len(keys[j]) < len(keys[j+1]) {
                keys[j], keys[j+1] = keys[j+1], keys[j]
            }
        }
    }
}