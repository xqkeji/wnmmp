# mkcert

https://github.com/FiloSottile/mkcert

A small utility for creating locally trusted HTTPS certificates. It creates a
local certificate authority, installs that CA into the system (and Firefox)
trust stores, and then signs server certificates against it, so browsers show
a valid padlock for `localhost` and any custom local domain.

## Bundled binary

| file            | `bin\mkcert.exe`                                                     |
| --------------- | -------------------------------------------------------------------- |
| version         | v1.4.4                                                               |
| asset           | `mkcert-v1.4.4-windows-amd64.exe` (x64 only)                          |
| download URL    | `https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-amd64.exe` |
| SHA-256         | `d2660b50a9ed59eada480750561c96abc2ed4c9a38c6a24d93e30e0977631398`   |
| size            | 4896256 bytes                                                        |
| license         | BSD 3-Clause (see `LICENSE` in this directory)                        |

The SHA-256 above is the digest of the file committed in this repository, so a
future copy can be checked against it; it is not published by upstream.

## How wnmmp uses it

`bin\make-ssl.bat` is the front end. It runs `mkcert -install` once, then
requests a certificate whose Subject Alternative Names cover `localhost`,
`127.0.0.1`, `::1` and `*.xqkeji.com`, and writes the PEM pair into
`etc\nginx\ssl\` (not tracked by git - the private key belongs to one machine
only).
The CA itself stays where mkcert keeps it, by default
`%LOCALAPPDATA%\mkcert`, which `make-ssl.bat` prints so the same file can be
used as `curl.cainfo` / `openssl.cafile` in PHP.

Run `bin\make-ssl.bat --help` for the available sub-commands
(`--renew`, `--disable`, `--uninstall`).
