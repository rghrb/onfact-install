#!/bin/sh
# Public bootstrap. Keep the immutable private installer pin and hash together.

fail() {
    printf 'onfact bootstrap: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'USAGE'
Install onfact from its private GitHub repository.

Usage: sh -s -- [--version latest|vMAJOR.MINOR.PATCH] [--bin-dir DIRECTORY]
       sh -s -- --help

Requires gh, Bash, mktemp, rm, and sha256sum or shasum. Uses existing
GitHub authentication, or opens browser login when a terminal is available.
GitHub access to rghrb/onfact-cli is required. onfact API login is separate.
USAGE
}

valid_version() (
    [ "$1" = latest ] && exit 0
    case "$1" in v*) ;; *) exit 1 ;; esac
    version_numbers=${1#v}
    # Split only on dots, without filename expansion.
    IFS=.
    set -f
    set -- $version_numbers
    [ "$#" -eq 3 ] || exit 1
    for component do
        case "$component" in ''|*[!0-9]*|0[0-9]*) exit 1 ;; esac
    done
    # Field splitting discards a trailing delimiter; reject that explicitly.
    case "$version_numbers" in *.) exit 1 ;; esac
)

main() {
    # A streamed script must reach the complete final invocation before work.
    last_argument=
    for last_argument do :; done
    [ "$last_argument" = '__ONFACT_BOOTSTRAP_COMPLETE__' ] ||
        fail 'incomplete bootstrap download; download again'

    version=latest
    bin_dir=
    have_bin_dir=false
    while [ "$#" -gt 1 ]; do
        case "$1" in
            --help)
                usage
                return 0
                ;;
            --version|--bin-dir)
                option=$1
                [ "$#" -ge 3 ] && [ "$2" != '__ONFACT_BOOTSTRAP_COMPLETE__' ] ||
                    fail "$option requires a value"
                [ -n "$2" ] || fail "$option requires a nonempty value"
                case "$2" in --*) fail "$option requires a value, received an option" ;; esac
                if [ "$option" = --version ]; then
                    version=$2
                else
                    bin_dir=$2
                    have_bin_dir=true
                fi
                shift 2
                ;;
            *) fail "unknown argument: $1" ;;
        esac
    done
    valid_version "$version" || fail 'version must be latest or stable vMAJOR.MINOR.PATCH'

    for dependency in gh bash mktemp rm; do
        command -v "$dependency" >/dev/null 2>&1 || fail "required command not found: $dependency"
    done
    if command -v sha256sum >/dev/null 2>&1; then
        hash_command=sha256sum
    elif command -v shasum >/dev/null 2>&1; then
        hash_command=shasum
    else
        fail 'required command not found: sha256sum or shasum'
    fi

    if ! gh auth status --active --hostname github.com >/dev/null 2>&1; then
        if [ "${GH_TOKEN+x}" = x ] || [ "${GITHUB_TOKEN+x}" = x ]; then
            fail 'GitHub environment token authentication failed; fix or unset GH_TOKEN/GITHUB_TOKEN'
        fi
        if ! ( : </dev/tty >/dev/tty ) 2>/dev/null; then
            fail 'no terminal available; run gh auth login --hostname github.com --web first'
        fi
        gh auth login --hostname github.com --web --git-protocol https </dev/tty >/dev/tty 2>&1 ||
            fail 'GitHub browser login failed'
        gh auth status --active --hostname github.com >/dev/null 2>&1 ||
            fail 'GitHub authentication failed after browser login'
    fi

    umask 077
    temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/onfact-bootstrap.XXXXXXXX") ||
        fail 'could not create a private temporary directory'
    trap 'rm -rf "$temporary_directory"' 0
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    installer_path=$temporary_directory/install.sh
    if ! gh api --hostname github.com \
        -H 'Accept: application/vnd.github.raw+json' \
        'repos/rghrb/onfact-cli/contents/scripts/install.sh?ref=ede235294f32dcdeaf0b4b52a2d1672ffed3f870' \
        >"$installer_path"; then
        fail 'could not download the private installer; verify repository access'
    fi
    if [ "$hash_command" = sha256sum ]; then
        actual_hash=$(sha256sum "$installer_path") || fail 'could not hash the private installer'
    else
        actual_hash=$(shasum -a 256 "$installer_path") || fail 'could not hash the private installer'
    fi
    actual_hash=${actual_hash%% *}
    [ "$actual_hash" = bceaa159cb34ac827233eb42a6a4cb1c145275c680a334c58eaeb0cb8e4d3622 ] ||
        fail 'private installer SHA-256 verification failed'

    if [ "$have_bin_dir" = true ]; then
        bash "$installer_path" --version "$version" --bin-dir "$bin_dir" </dev/null
    else
        bash "$installer_path" --version "$version" </dev/null
    fi
    installer_status=$?
    return "$installer_status"
}

main "$@" '__ONFACT_BOOTSTRAP_COMPLETE__'
