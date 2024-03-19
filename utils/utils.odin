package utils

import "core:os"
import "core:fmt"

read_file_to_bytes :: proc(name: string) -> []byte {
    data, success := os.read_entire_file(name);
    if !success {
        fmt.printf("error: failed to read file: %s\n", name)
        os.exit(1)
    }

    return data
}