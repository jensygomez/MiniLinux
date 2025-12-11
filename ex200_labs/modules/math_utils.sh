


# lab_001/library/math_utils.sh
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

rand_from_list() { 
    local arr=("$@"); 
    printf "%s" "${arr[RANDOM % ${#arr[@]}]}"; 
}

rand_size_mb() { 
    local range=$((MAX_MB - MIN_MB + 1)); 
    printf "%d" $(( (RANDOM % range) + MIN_MB )); 
}

percent_random() { 
    echo $(( (RANDOM % 41) + 60 )); 
}  # 60..100