package main

import "core:fmt"
import "core:os"
import "core:runtime"
import "core:strconv"
import "core:strings"
import "vm"
import "lexer"
import "compiler"
import "preprocessor"
import "utils"

print_usage :: proc(which: string="") {
    switch which {
        case "build": {
            fmt.printf("usage: %s build <input> <output>\n", os.args[0])
        }
        case "run": {
            fmt.printf("usage: %s run <input>\n", os.args[0])
        }
        case: {
            fmt.printf("usage: %s <command>\n", os.args[0])
            fmt.printf("commands:\n")
            fmt.printf("  build: compile file to byte code\n")
            fmt.printf("  run: run compiled file\n")
        }
    }
}

main :: proc() {
    if len(os.args) < 2 {
        print_usage()
        os.exit(1)
    }

    command := os.args[1]

    switch command {
        case "build": {
            if len(os.args) < 4 {
                print_usage("build")
                os.exit(1)
            }

            dump := false
            for i := 0; i < len(os.args); i += 1 {
                if os.args[i] == "--dump" {
                    dump = true
                }
            }

            input_file := os.args[2]
            output_file := os.args[3]

            input := utils.read_file_to_bytes(input_file)
            l := lexer.new_lexer(input)
            p := preprocessor.new_preprocessor(&l, false)
            preprocessor.process(&p)
            l = lexer.new_lexer(transmute([]byte)preprocessor.output(&p))
            c := compiler.new_compiler(&l)

            if dump {
                compiler.dump(&c)
            } else {
                compiler.compile(&c)
                compiler.write_to_file(&c, output_file)
            }
        }
        case "run": {
            if len(os.args) < 3 {
                print_usage("run")
                os.exit(1)
            }

            render_display := false
            for i := 0; i < len(os.args); i += 1 {
                if os.args[i] == "-d" || os.args[i] == "--display" {
                    render_display = true
                }
            }

            input_file := os.args[2]

            input := utils.read_file_to_bytes(input_file)
            v := vm.new_vm(input)
            vm.vm_run(&v, render_display)
        }
        case: {
            print_usage()
            os.exit(1)
        }
    }
}