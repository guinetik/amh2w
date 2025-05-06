function translate {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Text = "",

        [Parameter(Position = 1)]
        [string]$TargetLangCode = "all"
    )

    try {
        if (-not $Text) {
            $Text = Read-Host "Enter the text to translate"
        }

        if ($TargetLangCode -eq "all") {
            $langs = @("ar", "de", "es", "fr", "ga", "hi", "it", "ja", "ko", "pt", "ru", "zh")
            $translations = @()

            foreach ($lang in $langs) {
                Write-Host "🌍 Translating to [$lang]..." -ForegroundColor Cyan
                try {
                    $translated = Use-GoogleTranslate $Text $lang
                    $translations += [PSCustomObject]@{
                        Flag        = Get-LanguageFlag $lang
                        Language    = $lang
                        Translation = $translated
                    }
                } catch {
                    $translations += [PSCustomObject]@{
                        Flag        = Get-LanguageFlag $lang
                        Language    = $lang
                        Translation = "(error)"
                    }
                }
                Start-Sleep -Milliseconds 1000
            }            

            Show-JsonTable $translations
            return Ok -Value $translations -Message "Translated using Google"
        } else {
            $translated = Use-GoogleTranslate $Text $TargetLangCode
            Write-Host "🗣️ [$TargetLangCode]: $translated" -ForegroundColor Green
            return Ok -Value $translated -Message "Translation complete"
        }
    }
    catch {
        Write-Host "⚠️ Translation failed: $_" -ForegroundColor Yellow
        return Err -Message "Translation failed: $_"
    }
}

function Use-GoogleTranslate {
    param([string]$Text, [string]$TargetLangCode)

    $encoded = [System.Net.WebUtility]::UrlEncode($Text)
    $url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$TargetLangCode&dt=t&q=$encoded"

    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
    $json = $response.Content | ConvertFrom-Json
    return ($json[0] | ForEach-Object { $_[0] }) -join ""
}

function Get-LanguageFlag {
    param([string]$Lang)

    switch ($Lang.ToLower()) {
        "en" { "🇺🇸" }
        "fr" { "🇫🇷" }
        "es" { "🇪🇸" }
        "pt" { "🇧🇷" }
        "de" { "🇩🇪" }
        "it" { "🇮🇹" }
        "zh" { "🇨🇳" }
        "ja" { "🇯🇵" }
        "ko" { "🇰🇷" }
        "ru" { "🇷🇺" }
        "ar" { "🇸🇦" }
        "hi" { "🇮🇳" }
        "ga" { "🇮🇪" }
        default { "🌐" }
    }
}
