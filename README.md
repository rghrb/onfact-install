# onFact installer bootstrap

Latest v0.4.0 is **Linux x86_64 GNU only** (glibc 2.39+). There is no v0.4.0
Mac artifact. Apple Silicon users should pin the previous verified native build:

```sh
curl -fsSL https://raw.githubusercontent.com/rghrb/onfact-install/main/install.sh | sh -s -- --version v0.2.0
```

This small public repository provides a convenient way to fetch the onFact
command-line installer. The installer downloads the latest stable `onfact`
binary from a private GitHub release and verifies its SHA-256 checksum before
installation.

## Install or upgrade

```sh
curl -fsSL https://raw.githubusercontent.com/rghrb/onfact-install/main/install.sh | sh
```

The default destination is `$HOME/.local/bin`. Select a release version or a
different destination with:

```sh
curl -fsSL https://raw.githubusercontent.com/rghrb/onfact-install/main/install.sh | sh -s -- --version v0.4.0 --bin-dir "$HOME/bin"
```

Pass `--help` for the available options. Rerun the command to upgrade.

## Requirements and access

The script requires Bash, GitHub CLI (`gh`), `uname`, `mktemp`, `tar`, standard
core utilities, and either `sha256sum` or `shasum -a 256`. Install `gh`
separately. The script does not install Rust or a package manager.

You need access to the private GitHub release. The script reuses an existing
GitHub login, or starts browser login on the fixed GitHub host when a
controlling terminal is available. Headless use can reuse a saved GitHub login
or use `GH_TOKEN` or `GITHUB_TOKEN`. An invalid supplied token fails without
starting browser login. GitHub access is separate from onFact API authentication, which is
configured after installation. Existing saved onFact credentials are preserved
and reused by CLI commands. On first use without saved credentials, run
`onfact auth login`.

The latest v0.4.0 artifacts support Linux x86_64 with GNU libc (glibc) 2.39
or newer (Ubuntu 24.04 or newer). The previous native v0.2.0 release supports
Apple Silicon (`arm64`) on macOS 15 or newer; Mac users must explicitly pin
that version as shown above. Other operating systems, architectures, and
Linux libc variants are not supported by these release artifacts.
