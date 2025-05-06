Import-Module AMH2W
# Dot source iss.ps1 from script root
$script = "all/my/homies/luv/iss.ps1"
. $script

$landmarks = @(
    @{ Name = "Fortaleza, Brazil"; Lat = -3.7139; Lon = -38.5409; Symbol = "🏠" },
    @{ Name = "International Space Station (near Luanda)"; Lat = -14.1278; Lon = 0.0277; Symbol = "🛰️" },
    @{ Name = "North Pole"; Lat = 90; Lon = 0; Symbol = "🧊" },
    @{ Name = "South Pole"; Lat = -90; Lon = 0; Symbol = "🧊" },
    @{ Name = "Prime Meridian/Equator"; Lat = 0; Lon = 0; Symbol = "📍" },
    @{ Name = "International Date Line/Equator"; Lat = 0; Lon = 180; Symbol = "📅" },
    @{ Name = "Luanda, Angola"; Lat = -8.8399; Lon = 13.2894; Symbol = "📌" }
)

#plot each landmark
$landmarks | ForEach-Object {
    Write-Host $_.Name
    #plot one then ask the user to continue
    Show-ISSWorldMap -Latitude $_.Lat -Longitude $_.Lon -UserLat -3.7139 -UserLon -38.5409
    Read-Host "Press Enter to continue"
}
