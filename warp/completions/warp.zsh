#compdef warp
# Zsh completion for warp
# Installation: copy to /usr/local/share/zsh/site-functions/_warp

_warp() {
    local -a commands targets transpile_opts

    commands=(
        'init:Create a default .warp.yaml configuration'
        'transpile:Transpile between Ruby and Crystal'
        'version:Show version information'
        'help:Show help message'
    )

    targets=(
        'crystal:Ruby → Crystal (default)'
        'cr:Ruby → Crystal (alias)'
        'ruby:Crystal → Ruby'
        'rb:Crystal → Ruby (alias)'
        'rbs:Generate .rbs files from Sorbet sigs'
        'rbi:Generate .rbi files from Sorbet sigs'
        'inject-rbs:Inject inline # @rbs comments into Ruby source'
        'round-trip:Validate round-trip (Ruby ↔ Crystal)'
        'rt:Validate round-trip (alias)'
    )

    transpile_opts=(
        '(-s --source)'{-s,--source}'[Source file or directory]:file:_files'
        '(-c --config)'{-c,--config}'[Config file]:file:_files -g "*.yaml"'
        '(-o --out)'{-o,--out}'[Output directory]:directory:_files -/'
        '--rbs[RBS file to load]:file:_files -g "*.rbs"'
        '--rbi[RBI file to load]:file:_files -g "*.rbi"'
        '--inline-rbs[Parse inline # @rbs comments]:bool:(true false)'
        '--stdout[Write output to stdout]'
        '(-h --help)'{-h,--help}'[Show help message]'
    )

    _arguments -C \
        '(-h --help)'{-h,--help}'[Show help message]' \
        '(-v --version)'{-v,--version}'[Show version information]' \
        '1: :->command' \
        '*:: :->args'

    case $state in
        command)
            _describe 'warp commands' commands
            ;;
        args)
            case $words[1] in
                transpile)
                    if (( CURRENT == 1 )); then
                        _describe 'transpile targets' targets
                    else
                        _arguments $transpile_opts
                    fi
                    ;;
                init|version|help)
                    # No additional arguments
                    ;;
            esac
            ;;
    esac
}

_warp "$@"
