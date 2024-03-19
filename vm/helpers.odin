package vm

import "core:strings"

@(private)
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