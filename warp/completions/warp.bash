# Bash completion for warp
# Installation: source this file or copy to /etc/bash_completion.d/warp

_warp_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Top-level commands
    local commands="init transpile version help"

    # Transpile targets
    local targets="crystal ruby rbs rbi inject-rbs round-trip cr rb rt"

    # Global options
    local global_opts="--help -h --version -v"

    # Transpile options
    local transpile_opts="--source -s --config -c --out -o --rbs --rbi --inline-rbs --stdout"

    # Handle subcommand completion
    if [ "${COMP_CWORD}" -eq 1 ]; then
        # Complete main commands
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi

    case "${COMP_WORDS[1]}" in
        transpile)
            if [ "${COMP_CWORD}" -eq 2 ]; then
                # Complete transpile targets
                COMPREPLY=( $(compgen -W "${targets}" -- ${cur}) )
                return 0
            fi

            # Complete options based on previous argument
            case "${prev}" in
                -s|--source|-c|--config|-o|--out|--rbs|--rbi)
                    # File/directory completion
                    COMPREPLY=( $(compgen -f -- ${cur}) )
                    return 0
                    ;;
                --inline-rbs)
                    COMPREPLY=( $(compgen -W "true false" -- ${cur}) )
                    return 0
                    ;;
                *)
                    # Complete transpile options
                    COMPREPLY=( $(compgen -W "${transpile_opts}" -- ${cur}) )
                    return 0
                    ;;
            esac
            ;;
        init|version|help)
            # These commands have no additional options
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${global_opts}" -- ${cur}) )
            return 0
            ;;
    esac
}

complete -F _warp_completions warp
