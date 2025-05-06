function treeview {
    [CmdletBinding()]
    param([string]$path = "$PWD")

    function GetFileIcon([string]$suffix) {
        switch ($suffix) {
            ".csv"	    { return "📊" }
            ".epub"	    { return "📓" }
            ".exe"      { return "⚙️" }
            ".gif"	    { return "📸" }
            ".iso"	    { return "📀" }
            ".jpg"	    { return "📸" }
            ".mp3"	    { return "🎵" }
            ".mkv"	    { return "🎬" }
            ".png"	    { return "📸" }
            ".rar"      { return "📦" }
            ".tar"      { return "📦" }
            ".zip"      { return "📦" }
            default     { return "📄" }
        }
    }
    
    function Bytes2String([int64]$bytes) {
        if ($bytes -lt 1000) { return "$bytes bytes" }
        $bytes /= 1000
        if ($bytes -lt 1000) { return "$($bytes)K" }
        $bytes /= 1000
        if ($bytes -lt 1000) { return "$($bytes)MB" }
        $bytes /= 1000
        if ($bytes -lt 1000) { return "$($bytes)GB" }
        $bytes /= 1000
        return "$($Bytes)TB"
    }
    
    function ListDir([string]$path, [int]$depth) {
        $depth++
        $items = Get-ChildItem -path $path
        foreach ($item in $items) {
            $filename = $item.Name
            for ($i = 1; $i -lt $depth; $i++) { Write-Host "│ " -noNewline }
            if ($item.Mode -like "d*") {
                Write-Output "├📂$Filename"
                ListDir "$path\$filename" $depth
            }
            else {
                $icon = GetFileIcon $item.Extension
                Write-Output "├$($icon)$filename ($(Bytes2String $item.Length))"
                $global:files++
                $global:bytes += $item.Length
            }
        }
        $global:folders++
    }
    
    try {
        [int64]$global:folders = 0
        [int64]$global:files = 0
        [int64]$global:bytes = 0
        ListDir $path 0
        Write-Output " ($($global:folders) folders, $($global:files) files, $(Bytes2String $global:bytes) total)"
        return Ok "Treeview generated successfully."
    }
    catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        return Err "Failed to generate treeview."
    }
}