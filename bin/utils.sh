#!/usr/bin/env bash

draw_line() {
    printf '%*s\n' "${1:-40}" '' | tr ' ' '-'
}

print_table_header() {
    echo "ID   | Título"
    draw_line 40
}
