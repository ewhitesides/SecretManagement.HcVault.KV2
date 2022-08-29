function Get-CachedToken([hashtable]$AP) {

    #get token from cache file
    $Output = Get-Content -Path $AP.TokenCachePath

    #if TokenRenewable $true, renew token
    if ($AP.TokenRenewable) {
        $Params = @{
            Method  = 'Post'
            Uri     = $AP.Server + $AP.ApiVersion + '/auth/token/renew-self'
            Headers = @{"X-Vault-Token"="$Output"}
        }
        $Output = (Invoke-RestMethod @Params).auth.client_token
    }

    #return token
    $Output
}
