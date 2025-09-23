# fix_site_step1.ps1
# Downloads Van Gogh + Monet verified artworks and builds basic site

$artists = @(
  @{ id='van-gogh'; name='Vincent van Gogh'; files=@(
    'https://upload.wikimedia.org/wikipedia/commons/e/eb/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/4/47/Vincent_van_Gogh_-_Sunflowers_-_VGM_F458.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/0/0a/Vincent_van_Gogh_-_Bedroom_in_Arles_-_Google_Art_Project.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/5/57/Vincent_Willem_van_Gogh_-_Cafe_Terrace_at_Night_%28Yorck%29.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/d/d4/Vincent_van_Gogh_-_Wheatfield_with_Crows_-_Google_Art_Project.jpg'
  )},
  @{ id='monet'; name='Claude Monet'; files=@(
    'https://upload.wikimedia.org/wikipedia/commons/9/9c/Claude_Monet%2C_Impression%2C_soleil_levant.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/0/0c/Claude_Monet_-_Water_Lilies_-_Google_Art_Project.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/0/0a/Claude_Monet_-_Woman_with_a_Parasol_-_Google_Art_Project.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/d/d6/Claude_Monet_-_The_Houses_of_Parliament%2C_Sunset.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/0/0d/Claude_Monet_-_The_Japanese_Bridge.jpg'
  )}
)

# Ensure images folder
if (Test-Path .\images) { Remove-Item .\images -Recurse -Force }
New-Item -ItemType Directory -Path .\images | Out-Null

# Download
foreach ($artist in $artists) {
  $adir = ".\images\$($artist.id)"
  New-Item -ItemType Directory -Path $adir | Out-Null
  $i=1
  foreach ($url in $artist.files) {
    $outfile = "$adir\$i.jpg"
    Invoke-WebRequest -Uri $url -OutFile $outfile -UseBasicParsing
    Write-Host "Downloaded $url -> $outfile"
    $i++
  }
}

Write-Host "`n✅ Images downloaded. Check images/van-gogh and images/monet"
