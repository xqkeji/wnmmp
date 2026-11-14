# ssl-enable.ps1 - switch the wnmmp nginx sites between HTTP (80) and HTTPS (443).
#
# ASCII only on purpose: Windows PowerShell 5.1 reads a BOM-less file as ANSI,
# so non-ASCII literals in a .ps1 break the parse. bin\make-ssl.bat owns all
# user-facing text.
#
# etc\nginx\nginx.conf and etc\nginx\conf.d\*.conf SHIP in the enabled shape
# below, so on a fresh install "enable" finds nothing to rewrite and only the
# certificate step has to run; "disable" is the direction that actually edits,
# and it puts back exactly the plain-HTTP config earlier releases shipped with.
#
# The certificate directives live in etc\nginx\ssl.conf and the port-80 redirect
# lives in etc\nginx\http_redirect.conf; both are included ONCE at http level,
# so a server block never carries them and a block with two listen lines
# ([::]:443 next to 443) still cannot duplicate them. The switch is four exact
# inverse edits:
#
#   enable : nginx.conf           + include ssl.conf;
#                                 + include http_redirect.conf;
#            listen 80 [params]    -> listen 443 ssl [params]
#            proxy_pass http://127.0.0.1/  ->  https://
#   disable: the same four, back to plain HTTP. With both include lines gone
#            nginx no longer reads any certificate file, so switching off does
#            not depend on etc\nginx\ssl still being there, and port 80 goes
#            back to the sites instead of the redirect block.
#
# The loopback proxy only needs its scheme changed: proxy_ssl_verify defaults to
# off in nginx, so a locally trusted certificate is never re-checked there.
# http -> https is what keeps a proxied sub-path working, because the virtual
# host behind it only listens on 443 after the switch has run; any other
# proxy_pass target is left exactly as its author wrote it.

param(
    [Parameter(Mandatory = $true)][string] $Root,
    [ValidateSet('enable', 'disable')][string] $Action = 'enable'
)

$ErrorActionPreference = 'Stop'

$confDir   = Join-Path $Root 'etc\nginx\conf.d'
$nginxConf = Join-Path $Root 'etc\nginx\nginx.conf'

if (-not (Test-Path -LiteralPath $confDir) -or -not (Test-Path -LiteralPath $nginxConf)) {
    Write-Output "ssl-enable: MISSING $confDir or $nginxConf"
    exit 2
}

# --- the http-level include ---------------------------------------------------
$siteInclude  = [regex] '(?m)^([ \t]*)include[ \t]+conf\.d/\*\.conf;([ \t]*)(\r?\n)'
$httpOpen     = [regex] '(?m)^http[ \t]*\{(\r?\n)'
$sslInclude   = [regex] '(?m)^([ \t]*)include[ \t]+ssl\.conf;([ \t]*)(\r?\n)'
$redirectInclude = [regex] '(?m)^([ \t]*)include[ \t]+http_redirect\.conf;([ \t]*)(\r?\n)'

# --- listen / proxy shapes ----------------------------------------------------
# 1 indent  2 spacing  3 optional [::]:  4 extra params  5 after-semicolon  6 newline
$onListening  = [regex] '(?m)^([ \t]*)listen([ \t]+)(\[::\]:)?80([ \t][^;\r\n]*)?;([ \t]*)(\r?\n)'
$offListening = [regex] '(?m)^([ \t]*)listen([ \t]+)(\[::\]:)?443([ \t]+ssl)([ \t][^;\r\n]*)?;([ \t]*)(\r?\n)'
$onProxying   = [regex] 'proxy_pass([ \t]+)http://127\.0\.0\.1'
$offProxying  = [regex] 'proxy_pass([ \t]+)https://127\.0\.0\.1'

function Add-Include([string] $Text, [regex] $Pattern, [string] $Line) {
    # Each include is added on its own test, so a config that already carries
    # one of them - switched by an older build of this tool, which knew only
    # ssl.conf - gains the missing line instead of a duplicate certificate
    # include that nginx -t would reject.
    if ($Pattern.IsMatch($Text)) { return $Text }
    if ($siteInclude.IsMatch($Text)) {
        return $siteInclude.Replace($Text, ('$1' + $Line + ';$2$3$0'), 1)
    }
    if ($httpOpen.IsMatch($Text)) {
        return $httpOpen.Replace($Text, ('$0$1' + $Line + ';$1'), 1)
    }
    return $Text
}

function Switch-NginxConf([string] $Text) {
    if ($Action -ne 'enable') {
        return $sslInclude.Replace($redirectInclude.Replace($Text, ''), '')
    }
    $t = Add-Include $Text $sslInclude 'include ssl.conf'
    return Add-Include $t $redirectInclude 'include http_redirect.conf'
}

function Switch-Site([string] $Text) {
    # No "already done" test is needed in either direction: the patterns only
    # match the plain-HTTP shape and their own output is the 443/https shape, so
    # a second run finds nothing to change - while a site file that later gains
    # a new port-80 block is still picked up.
    if ($Action -eq 'enable') {
        $script:Note = 'listen={0} proxy={1}' -f $onListening.Matches($Text).Count, $onProxying.Matches($Text).Count
        $t = $onListening.Replace($Text, '${1}listen${2}${3}443 ssl${4};${5}${6}')
        return $onProxying.Replace($t, 'proxy_pass${1}https://127.0.0.1')
    }
    $script:Note = 'listen={0} proxy={1}' -f $offListening.Matches($Text).Count, $offProxying.Matches($Text).Count
    $t = $offListening.Replace($Text, '${1}listen${2}${3}80${5};${6}${7}')
    return $offProxying.Replace($t, 'proxy_pass${1}http://127.0.0.1')
}

$main = [System.IO.File]::ReadAllText($nginxConf)
$newMain = Switch-NginxConf $main
if ($newMain -eq $main) {
    Write-Output ('ssl-enable: {0} nginx.conf (no change)' -f $Action)
}
elseif ($Action -eq 'enable' -and (-not $sslInclude.IsMatch($newMain) -or -not $redirectInclude.IsMatch($newMain))) {
    # No usable anchor in nginx.conf. Leaving the sites on 443 without the
    # certificate include would start nginx with no TLS context at all, so the
    # switch is refused instead of half applied.
    Write-Output 'ssl-enable: nginx.conf has neither "include conf.d/*.conf;" nor an "http {" line to anchor on'
    exit 3
}
else {
    [System.IO.File]::WriteAllText($nginxConf, $newMain)
    Write-Output ('ssl-enable: {0} nginx.conf (ssl={1} redirect={2})' -f $Action, $sslInclude.IsMatch($newMain), $redirectInclude.IsMatch($newMain))
}

$changed = 0
foreach ($file in Get-ChildItem -LiteralPath $confDir -Filter '*.conf' -File) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $new = Switch-Site $text
    if ($new -ne $text) {
        [System.IO.File]::WriteAllText($file.FullName, $new)
        $changed++
        Write-Output ('ssl-enable: {0} {1} ({2})' -f $Action, $file.Name, $script:Note)
    }
    else {
        Write-Output ('ssl-enable: {0} {1} (no change)' -f $Action, $file.Name)
    }
}
Write-Output ('ssl-enable: {0} site file(s) updated' -f $changed)
exit 0
