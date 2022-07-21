function Set-CachedToken([string]$Path,[string]$Token) {
    Set-Content -Path $Path -Value $Token
}
