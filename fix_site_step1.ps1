# PowerShell script: reset-images-and-write-site.ps1
# Run this from inside your Modern_Frame_Gallery folder in VS Code PowerShell.
# WARNING: deletes ./images directory (back up any custom images first).

# --- CONFIG: mapping of artists to Wikimedia file page URLs (these are Commons file pages) ---
$artists = @(
  @{
    id = "van-gogh"; name = "Vincent van Gogh";
    files = @(
      "https://commons.wikimedia.org/wiki/File:Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:Vincent_van_Gogh_-_Sunflowers_(1888,_National_Gallery_London).jpg",
      "https://commons.wikimedia.org/wiki/File:Vincent_van_Gogh_-_De_slaapkamer_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:Vincent_Willem_van_Gogh_-_Cafe_Terrace_at_Night_(Yorck).jpg",
      "https://commons.wikimedia.org/wiki/File:Vincent_Van_Gogh_-_Wheatfield_with_Crows.jpg"
    )
  },
  @{
    id = "monet"; name = "Claude Monet";
    files = @(
      "https://commons.wikimedia.org/wiki/File:Monet_-_Impression,_soleil_levant.jpg",
      "https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Waterlilies_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Woman_with_a_Parasol_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:Monet_-_Houses_of_Parliament,_Sunset.jpg",
      "https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Japanese_Bridge.jpg"
    )
  },
  @{
    id = "renoir"; name = "Pierre-Auguste Renoir";
    files = @(
      "https://commons.wikimedia.org/wiki/File:Auguste_Renoir_-_Dance_at_Le_Moulin_de_la_Galette_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:Pierre-Auguste_Renoir_-_Luncheon_of_the_Boating_Party_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:Pierre-Auguste_Renoir%2C_The_Umbrellas%2C_ca._1881-86.jpg",
      "https://commons.wikimedia.org/wiki/File:Renoir_-_The_Two_Sisters,_On_the_Terrace.jpg",
      "https://commons.wikimedia.org/wiki/File:Pierre_Auguste_Renoir_-_The_Bathers_-_Google_Art_Project.jpg"
    )
  },
  @{
    id = "turner"; name = "J. M. W. Turner";
    files = @(
      "https://commons.wikimedia.org/wiki/File:The_Fighting_T%C3%A9m%C3%A9raire,_JMW_Turner,_National_Gallery.jpg",
      "https://commons.wikimedia.org/wiki/File:Rain_Steam_and_Speed_the_Great_Western_Railway.jpg",
      "https://commons.wikimedia.org/wiki/File:Joseph_Mallord_William_Turner_-_Snow_Storm_-_Steam-Boat_off_a_Harbour%27s_Mouth.jpg",
      "https://commons.wikimedia.org/wiki/File:The_Slave_Ship.jpg",
      "https://commons.wikimedia.org/wiki/File:Norham_Castle,_Sunrise_-_J._M._W._Turner.jpg"
    )
  },
  @{
    id = "rembrandt"; name = "Rembrandt van Rijn";
    files = @(
      "https://commons.wikimedia.org/wiki/File:The_Nightwatch_by_Rembrandt_-_Rijksmuseum.jpg",
      "https://commons.wikimedia.org/wiki/File:Rembrandt_-_The_Anatomy_Lesson_of_Dr_Nicolaes_Tulp.jpg",
      "https://commons.wikimedia.org/wiki/File:Rembrandt_-_Zelfportret_1640.jpg",
      "https://commons.wikimedia.org/wiki/File:Rembrandt_-_The_Jewish_Bride_-_WGA19158.jpg",
      "https://commons.wikimedia.org/wiki/File:Rembrandt_-_Aristotle_with_a_Bust_of_Homer_-_WGA19232.jpg"
    )
  },
  @{
    id = "vermeer"; name = "Johannes Vermeer";
    files = @(
      "https://commons.wikimedia.org/wiki/File:Girl_with_a_Pearl_Earring.jpg",
      "https://commons.wikimedia.org/wiki/File:Vermeer_-_The_Milkmaid.jpg",
      "https://commons.wikimedia.org/wiki/File:Vermeer-view-of-delft.jpg",
      "https://commons.wikimedia.org/wiki/File:Woman_Holding_a_Balance_-_Johannes_Vermeer_-_Google_Art_Project.jpg",
      "https://commons.wikimedia.org/wiki/File:The_Art_of_Painting_-_Johannes_Vermeer_-_Google_Art_Project.jpg"
    )
  }
)

# --- Delete old images folder if exists ---
if (Test-Path -Path .\images) {
  Write-Host "Removing existing './images' folder..."
  Remove-Item -Path .\images -Recurse -Force -ErrorAction SilentlyContinue
}
# create images folder
New-Item -ItemType Directory -Path .\images | Out-Null

# helper function: given a Wikimedia file page URL, fetch the og:image meta and return the direct image URL
function Get-DirectImageUrlFromCommonsFilePage($filePageUrl) {
  try {
    $html = Invoke-WebRequest -Uri $filePageUrl -UseBasicParsing -ErrorAction Stop
    # try to get the og:image meta property first
    $og = ($html.AllElements | Where-Object { $_.tagName -eq 'meta' -and ($_.GetAttribute('property') -eq 'og:image') })
    if ($og -and $og.content) { return $og.content }
    # fallback: find link rel="image_src"
    $imgsrc = ($html.AllElements | Where-Object { $_.tagName -eq 'link' -and $_.GetAttribute('rel') -eq 'image_src' })
    if ($imgsrc -and $imgsrc.href) { return $imgsrc.href }
    # last resort: regex search for upload.wikimedia.org url in HTML
    $m = [regex]::Match($html.Content, 'https://upload.wikimedia.org/[^"''\s>]+')
    if ($m.Success) { return $m.Value }
  } catch {
    Write-Host "Error fetching $filePageUrl : $_" -ForegroundColor Yellow
  }
  return $null
}

# iterate artists and download images
foreach ($artist in $artists) {
  $aid = $artist.id
  $aname = $artist.name
  $adir = ".\images\$aid"
  New-Item -ItemType Directory -Path $adir -Force | Out-Null
  Write-Host "Downloading images for $aname into $adir ..."
  $i = 1
  foreach ($fileUrl in $artist.files) {
    Write-Host "  -> processing [$i] $fileUrl"
    $direct = Get-DirectImageUrlFromCommonsFilePage $fileUrl
    if (-not $direct) {
      Write-Host "     ! Could not find direct image URL for $fileUrl" -ForegroundColor Yellow
    } else {
      $outfile = Join-Path $adir ("$i.jpg")
      Write-Host "     -> downloading $direct"
      try {
        Invoke-WebRequest -Uri $direct -OutFile $outfile -UseBasicParsing -ErrorAction Stop
        Write-Host "     Saved $outfile"
      } catch {
        Write-Host "     Failed to download $direct : $_" -ForegroundColor Red
      }
    }
    $i++
  }
}

# --- Now overwrite the HTML and CSS files with the upgraded site files ---
# (index.html, gallery.html, about.html, contact.html, css/style.css, README.txt)
# For brevity of the script, the files are written from here-strings.

# CSS (css/style.css) - includes Swiper CSS via CDN in pages; local CSS here
$css = @"
:root{
  --site-width: 1100px;
  --bg: hsl(210 18% 97%);
  --card-bg: #ffffff;
  --text: #1f2933;
  --muted: rgb(120,120,120);
  --accent: #6b2dff;
  --shadow: 0 10px 30px rgba(23,25,28,0.08);
  --radius: 12px;
  --nav-height: 72px;
  --font-sans: "Inter", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

/* Basic reset */
*{ box-sizing: border-box; }
html,body{ margin:0; padding:0; height:100%; font-family:var(--font-sans); color:var(--text); background:var(--bg); -webkit-font-smoothing:antialiased; -moz-osx-font-smoothing:grayscale;}
a{ color:var(--accent); text-decoration:none; }
.container{ width:var(--site-width); margin:0 auto; padding:0 20px; }

/* Header */
.site-header{
  position:fixed; inset:0 0 auto 0; height:var(--nav-height); backdrop-filter: blur(6px);
  display:flex; align-items:center; justify-content:center; z-index:1000;
  background: linear-gradient(180deg, rgba(255,255,255,0.95), rgba(255,255,255,0.9));
  border-bottom:1px solid rgba(20,25,30,0.04);
}
.header-inner{ width:var(--site-width); display:flex; align-items:center; justify-content:space-between; gap:24px; padding:0 10px; }
.logo{ font-weight:700; letter-spacing:1px; text-transform:uppercase; font-size:1rem; color:var(--text) }
.main-nav ul{ list-style:none; margin:0; padding:0; display:flex; gap:20px; align-items:center; }
.main-nav a{ padding:8px 14px; display:inline-block; border-radius:12px; font-size:0.88rem; text-transform:uppercase; letter-spacing:0.08em; color:rgba(20,25,28,0.85); transition: transform .18s ease, background-color .2s ease, color .2s ease; }
.main-nav a:hover, .main-nav a:focus{ transform: translateY(-3px); background:var(--accent); color:white; box-shadow:0 6px 20px rgba(107,45,255,0.12); outline: none; }
.main-nav a.active{ background: var(--accent); color: #fff; box-shadow:0 8px 24px rgba(107,45,255,0.14); }

/* Spacing under fixed header */
main{ padding-top: calc(var(--nav-height) + 100px); padding-bottom: 80px; }

/* Cards and hero */
.card{ background:var(--card-bg); border-radius:12px; padding:18px; box-shadow: var(--shadow); border:1px solid rgba(12,14,20,0.03); }
.hero{ position:relative; overflow:hidden; border-radius:12px; margin-bottom:28px; }
.hero-media{ width:100%; height:420px; object-fit:cover; display:block; filter:contrast(1.02) saturate(1.02); }
.hero-content{ position:absolute; left:60px; bottom:36px; color:white; max-width:52%; text-shadow: 0 8px 30px rgba(0,0,0,0.45); }
.hero h1{ margin:0 0 6px 0; font-size:38px; line-height:1.02; letter-spacing:-0.02em; }
.lead{ font-size:17px; margin:6px 0 10px 0; opacity:0.95; }

/* Badge */
.badge{ position:absolute; right:30px; top:24px; background: linear-gradient(90deg, #ffd54a, #ffb74d); color:#111; padding:8px 12px; border-radius:10px; font-weight:700; box-shadow:0 6px 20px rgba(0,0,0,0.18); }

/* Grid */
.featured-grid{ display:grid; grid-template-columns: 1fr 380px; gap:20px; align-items:start; margin-top:18px; }
.art-grid{ display:grid; grid-template-columns: repeat(2, 1fr); gap:28px; margin-top:18px; }
.art-card{ border-radius:12px; overflow:hidden; background:var(--card-bg); }

/* thumbnail */
.thumb { position:relative; width:100%; height:240px; background-size:cover; background-position:center; display:block; border-radius:10px; }
.thumb img{ width:100%; height:100%; object-fit:cover; display:block; }

/* artist caption area */
.artist-meta{ padding:10px 12px; }
.artist-meta .artist-name{ font-weight:700; }
.artist-meta .art-title{ color:var(--muted); margin-top:6px; }

/* CTA button */
.cta{ display:inline-block; padding:10px 14px; border-radius:10px; background:var(--accent); color:white; font-weight:600; text-decoration:none; transition: transform .18s ease, box-shadow .2s ease; }
.cta:hover{ transform:translateY(-3px); box-shadow:0 8px 30px rgba(107,45,255,0.14); }

/* quick-view artist card (home) */
.quick-grid{ display:grid; grid-template-columns: repeat(3, 1fr); gap:24px; margin-top:24px; }

/* small footer */
.site-footer{ margin-top:34px; padding:22px 0; text-align:center; color:rgba(20,24,30,0.65); font-size:0.95rem; }

/* small utilities */
.muted{ color:var(--muted); }

/* Swiper overrides (presentational) */
.swiper-container { width:100%; height:100%; }
.swiper-slide img { width:100%; height:auto; display:block; }

/* responsive-ish */
@media (max-width:1100px){
  .container{ width:94%; }
  .featured-grid{ grid-template-columns: 1fr; }
  .art-grid{ grid-template-columns: 1fr; }
  .quick-grid{ grid-template-columns: 1fr 1fr; }
}
"@

# write css
if (-not (Test-Path -Path .\css)) { New-Item -ItemType Directory -Path .\css | Out-Null }
$css | Out-File -FilePath .\css\style.css -Encoding utf8 -Force

# INDEX HTML (home) - includes Swiper.js CDN and JS for auto-rotate thumbnails
$indexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>The Modern Frame — Home</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <!-- Swiper CSS -->
  <link rel="stylesheet" href="https://unpkg.com/swiper/swiper-bundle.min.css" />
  <style>
    /* small home-specific tweaks */
    .quick-artist { display:flex; flex-direction:column; align-items:stretch; }
    .auto-thumb { height:220px; border-radius:10px; overflow:hidden; position:relative; background-size:cover; background-position:center; }
    .auto-title { font-weight:700; margin-top:10px; }
    .auto-sub { color:var(--muted); margin-top:6px; }
  </style>
</head>
<body>
  <header class="site-header">
    <div class="header-inner">
      <div class="logo">THE MODERN FRAME</div>
      <nav class="main-nav">
        <ul>
          <li><a href="index.html" class="active">Home</a></li>
          <li><a href="gallery.html">Gallery</a></li>
          <li><a href="about.html">About</a></li>
          <li><a href="contact.html">Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class="container">
    <section class="hero card">
      <img class="hero-media" src="images/van-gogh/1.jpg" alt="Gallery hero">
      <div class="hero-content">
        <h1>Welcome to <span style="color:var(--accent)">The Modern Frame</span></h1>
        <p class="lead">A contemporary art gallery showcasing public-domain masterpieces and curated exhibitions.</p>
        <a href="gallery.html" class="cta">View the Gallery</a>
      </div>
      <div class="badge">Featured</div>
    </section>

    <section class="card">
      <h2 style="margin-top:0">Quick View — Artists</h2>
      <p class="muted">Hover / Tap an artist card to open their gallery; thumbnails auto-rotate every 12 seconds.</p>

      <div class="quick-grid" id="quickGrid">
        <!-- QUICK ARTIST CARDS injected by script -->
      </div>
    </section>

  </main>

  <footer class="site-footer">
    <div class="container">
      <p>© 2025 The Modern Frame — Public domain artworks (Wikimedia Commons)</p>
    </div>
  </footer>

  <!-- Modal area for Swiper slider -->
  <div id="artistModal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.85); z-index:3000; align-items:center; justify-content:center; padding:20px;">
    <div style="width:90%; max-width:1100px; position:relative;">
      <button id="modalClose" style="position:absolute; right:-10px; top:-40px; background:transparent; color:white; border:none; font-size:28px;">✕</button>
      <div class="swiper mySwiper">
        <div class="swiper-wrapper" id="swiperWrapper"></div>
        <!-- navigation -->
        <div class="swiper-button-next" style="color:white"></div>
        <div class="swiper-button-prev" style="color:white"></div>
        <div class="swiper-pagination" style="color:white"></div>
      </div>
      <div id="modalCaption" style="color:white; margin-top:10px; font-weight:600;"></div>
    </div>
  </div>

  <!-- Swiper JS -->
  <script src="https://unpkg.com/swiper/swiper-bundle.min.js"></script>

  <script>
  // --- Data: Artists and local images (must match images downloaded by the script) ---
  const ARTISTS = [
    { id: 'van-gogh', name: 'Vincent van Gogh', images: [
      'images/van-gogh/1.jpg','images/van-gogh/2.jpg','images/van-gogh/3.jpg','images/van-gogh/4.jpg','images/van-gogh/5.jpg'
    ], titles: ['Starry Night','Sunflowers','Bedroom in Arles','Cafe Terrace at Night','Wheatfield with Crows'] },

    { id: 'monet', name: 'Claude Monet', images: [
      'images/monet/1.jpg','images/monet/2.jpg','images/monet/3.jpg','images/monet/4.jpg','images/monet/5.jpg'
    ], titles: ['Impression, Sunrise','Water Lilies','Woman with a Parasol','Houses of Parliament, Sunset','Japanese Bridge'] },

    { id: 'renoir', name: 'Pierre-Auguste Renoir', images: [
      'images/renoir/1.jpg','images/renoir/2.jpg','images/renoir/3.jpg','images/renoir/4.jpg','images/renoir/5.jpg'
    ], titles: ['Dance at Le Moulin de la Galette','Luncheon of the Boating Party','The Umbrellas','Two Sisters (On the Terrace)','The Bathers'] },

    { id: 'turner', name: 'J. M. W. Turner', images: [
      'images/turner/1.jpg','images/turner/2.jpg','images/turner/3.jpg','images/turner/4.jpg','images/turner/5.jpg'
    ], titles: ['The Fighting Temeraire','Rain, Steam and Speed','Snow Storm: Steam-Boat off a Harbour','The Slave Ship','Norham Castle, Sunrise'] },

    { id: 'rembrandt', name: 'Rembrandt van Rijn', images: [
      'images/rembrandt/1.jpg','images/rembrandt/2.jpg','images/rembrandt/3.jpg','images/rembrandt/4.jpg','images/rembrandt/5.jpg'
    ], titles: ['The Night Watch','The Anatomy Lesson of Dr. Nicolaes Tulp','Self-Portrait (1640)','The Jewish Bride','Aristotle with a Bust of Homer'] },

    { id: 'vermeer', name: 'Johannes Vermeer', images: [
      'images/vermeer/1.jpg','images/vermeer/2.jpg','images/vermeer/3.jpg','images/vermeer/4.jpg','images/vermeer/5.jpg'
    ], titles: ['Girl with a Pearl Earring','The Milkmaid','View of Delft','Woman Holding a Balance','The Art of Painting'] }
  ];

  // build quick-grid cards
  const quickGrid = document.getElementById('quickGrid');
  ARTISTS.forEach(artist => {
    const card = document.createElement('div');
    card.className = 'quick-artist card';
    card.innerHTML = `
      <div class="auto-thumb" id="thumb-${artist.id}" style="background-image:url('${artist.images[0]}')"></div>
      <div class="artist-meta">
        <div class="artist-name">${artist.name}</div>
        <div class="art-title" id="title-${artist.id}">${artist.titles[0]}</div>
        <div style="margin-top:8px;">
          <a href="#" class="cta open-artist" data-artist="${artist.id}">Open</a>
          <a href="gallery.html#${artist.id}" style="margin-left:8px;" class="muted">View All</a>
        </div>
      </div>
    `;
    quickGrid.appendChild(card);

    // set up auto-rotate for this artist's thumbnail & title
    let idx = 0;
    setInterval(() => {
      idx = (idx + 1) % artist.images.length;
      const el = document.getElementById('thumb-'+artist.id);
      const titleEl = document.getElementById('title-'+artist.id);
      if (el) el.style.backgroundImage = `url('${artist.images[idx]}')`;
      if (titleEl) titleEl.textContent = artist.titles[idx];
    }, 12000); // 12 seconds
  });

  // Modal / Swiper setup
  const modal = document.getElementById('artistModal');
  const swiperWrapper = document.getElementById('swiperWrapper');
  let mySwiper = null;

  function openArtist(artistId) {
    const artist = ARTISTS.find(a => a.id === artistId);
    if (!artist) return;
    swiperWrapper.innerHTML = '';
    artist.images.forEach(src => {
      const slide = document.createElement('div');
      slide.className = 'swiper-slide';
      slide.innerHTML = `<img src="${src}" alt="">`;
      swiperWrapper.appendChild(slide);
    });
    // show modal
    modal.style.display = 'flex';
    // init swiper (destroy previous if exists)
    if (mySwiper) { mySwiper.destroy(true, true); mySwiper = null; }
    mySwiper = new Swiper('.mySwiper', {
      loop: false,
      navigation: { nextEl: '.swiper-button-next', prevEl: '.swiper-button-prev' },
      pagination: { el: '.swiper-pagination', clickable: true },
      spaceBetween: 20,
      centeredSlides: true,
    });
    // set caption initially
    const caption = document.getElementById('modalCaption');
    caption.textContent = artist.name + ' — ' + artist.titles[0];
    // update caption on slide change
    mySwiper.on('slideChange', function() {
      caption.textContent = artist.name + ' — ' + artist.titles[mySwiper.activeIndex];
    });
  }

  // open when clicking open-artist
  document.addEventListener('click', function(e){
    if (e.target.matches('.open-artist')) {
      e.preventDefault();
      const aid = e.target.getAttribute('data-artist');
      openArtist(aid);
    }
    if (e.target.id === 'modalClose' || e.target.id === 'artistModal') {
      document.getElementById('artistModal').style.display = 'none';
      if (mySwiper) { mySwiper.destroy(true, true); mySwiper = null; }
    }
  });

  // close by clicking outside the slider
  modal.addEventListener('click', function(e){
    if (e.target === modal) {
      modal.style.display = 'none';
      if (mySwiper) { mySwiper.destroy(true, true); mySwiper = null; }
    }
  });
  </script>
</body>
</html>
"@

$indexHtml | Out-File -FilePath .\index.html -Encoding utf8 -Force

# GALLERY HTML
$galleryHtml = @"
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='utf-8' />
  <title>The Modern Frame — Gallery</title>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <link href='https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap' rel='stylesheet'>
  <link rel='stylesheet' href='css/style.css'>
  <link rel='stylesheet' href='https://unpkg.com/swiper/swiper-bundle.min.css' />
</head>
<body>
  <header class='site-header'>
    <div class='header-inner'>
      <div class='logo'>THE MODERN FRAME</div>
      <nav class='main-nav'>
        <ul>
          <li><a href='index.html'>Home</a></li>
          <li><a href='gallery.html' class='active'>Gallery</a></li>
          <li><a href='about.html'>About</a></li>
          <li><a href='contact.html'>Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class='container'>
    <section class='card' style='margin-bottom:18px'>
      <h1 style='margin:0'>Gallery</h1>
      <p class='muted'>A curated selection of public-domain museum-quality works. Click a card to open the artist viewer.</p>
    </section>

    <!-- full artist grid -->
    <section style='margin-top:18px'>
      <div style='display:grid; grid-template-columns: repeat(2, 1fr); gap:28px;'>
        <!-- ARTIST BLOCKS injected by script -->
      </div>
    </section>
  </main>

  <footer class='site-footer'>
    <div class='container'>
      <p>© 2025 The Modern Frame</p>
    </div>
  </footer>

  <script>
    const ARTISTS = ${([System.Text.Json.JsonSerializer]::Serialize(ARTISTS) )}
    // same pattern to build gallery blocks
    (function(){
      const grid = document.querySelector('main section div');
      ARTISTS.forEach(artist => {
        const block = document.createElement('article');
        block.className = 'card art-card';
        block.innerHTML = `
          <div style="display:flex; gap:18px; align-items:flex-start;">
            <a href="#" class="open-artist" data-artist="${artist.id}" style="width:380px; display:block;">
              <div class="thumb" style="background-image:url('${artist.images[0]}'); height:260px;"></div>
            </a>
            <div style="flex:1;">
              <h3>${artist.name}</h3>
              <p class="muted">Representative works — click to open slideshow.</p>
              <div style="display:flex; gap:8px; margin-top:12px;">
                ${artist.images.map((img, idx) => `<img src="${img}" style="width:72px; height:56px; object-fit:cover; border-radius:6px;">`).join('')}
              </div>
              <div style="margin-top:12px;">
                <a class="cta open-artist" href="#" data-artist="${artist.id}">Open Artist</a>
              </div>
            </div>
          </div>
        `;
        grid.appendChild(block);
      });

      // copy of modal/swiper from index
      const modalHtml = `
        <div id="artistModal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.85); z-index:3000; align-items:center; justify-content:center; padding:20px;">
        <div style="width:90%; max-width:1100px; position:relative;">
          <button id="modalClose" style="position:absolute; right:-10px; top:-40px; background:transparent; color:white; border:none; font-size:28px;">✕</button>
          <div class="swiper mySwiper">
            <div class="swiper-wrapper" id="swiperWrapper"></div>
            <div class="swiper-button-next" style="color:white"></div>
            <div class="swiper-button-prev" style="color:white"></div>
            <div class="swiper-pagination" style="color:white"></div>
          </div>
          <div id="modalCaption" style="color:white; margin-top:10px; font-weight:600;"></div>
        </div>
        </div>
      `;
      document.body.insertAdjacentHTML('beforeend', modalHtml);

      // re-use open logic
      const modal = () => document.getElementById('artistModal');
      const swiperWrapper = () => document.getElementById('swiperWrapper');
      let mySwiper = null;
      function openArtist(artistId) {
        const artist = ARTISTS.find(a => a.id === artistId);
        if (!artist) return;
        document.getElementById('actor')?.remove();
        const wrapper = swiperWrapper();
        wrapper.innerHTML = '';
        artist.images.forEach(src => {
          const slide = document.createElement('div');
          slide.className = 'swiper-slide';
          slide.innerHTML = `<img src="${src}" alt="">`;
          wrapper.appendChild(slide);
        });
        modal().style.display = 'flex';
        if (mySwiper) { mySwiper.destroy(true, true); mySwiper = null; }
        mySwiper = new Swiper('.mySwiper', { loop:false, navigation:{nextEl:'.swiper-button-next', prevEl:'.swiper-button-prev'}, pagination:{el:'.swiper-pagination', clickable:true}, spaceBetween:20, centeredSlides:true });
        document.getElementById('modalCaption').textContent = artist.name + ' — ' + artist.titles[0];
        mySwiper.on('slideChange', function(){ document.getElementById('modalCaption').textContent = artist.name + ' — ' + artist.titles[mySwiper.activeIndex]; })
      }

      document.addEventListener('click', function(e){
        if (e.target.matches('.open-artist')) { e.preventDefault(); openArtist(e.target.getAttribute('data-artist')); }
        if (e.target.id === 'modalClose') { modal().style.display = 'none'; if (mySwiper) { mySwiper.destroy(true,true); mySwiper=null; } }
      });
      document.addEventListener('click', function(e){ if (e.target.id === 'artistModal') { modal().style.display='none'; if (mySwiper) {mySwiper.destroy(true,true); mySwiper=null;} } })
    })();
  </script>
  <script src='https://unpkg.com/swiper/swiper-bundle.min.js'></script>
</body>
</html>
"@

$galleryHtml | Out-File -FilePath .\gallery.html -Encoding utf8 -Force

# ABOUT HTML
$aboutHtml = @"
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='utf-8' />
  <title>The Modern Frame — About</title>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <link href='https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap' rel='stylesheet'>
  <link rel='stylesheet' href='css/style.css'>
</head>
<body>
  <header class='site-header'>
    <div class='header-inner'>
      <div class='logo'>THE MODERN FRAME</div>
      <nav class='main-nav'>
        <ul>
          <li><a href='index.html'>Home</a></li>
          <li><a href='gallery.html'>Gallery</a></li>
          <li><a href='about.html' class='active'>About</a></li>
          <li><a href='contact.html'>Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class='container'>
    <section class='card' style='margin-bottom:18px'>
      <h1 style='margin:0'>About The Modern Frame</h1>
      <p class='muted'>Founded to bring curated public-domain masterpieces to a wider audience.</p>
    </section>

    <section class='card'>
      <img class='thumb' src='images/monet/1.jpg' alt='Gallery interior'>
      <p style='margin-top:12px;'>We prioritize accessibility, thoughtful lighting, and clear labels.</p>
      <blockquote style='margin-top:12px;'>\"A space where modern voices are framed with care.\" — Curatorial note</blockquote>
    </section>

    <section class='card' style='margin-top:18px'>
      <h3 style='margin-top:0'>Notable Artists</h3>
      <ul style='list-style:none; padding-left:0;'>
        <li style='margin-bottom:8px;'>Vincent van Gogh</li>
        <li style='margin-bottom:8px;'>Claude Monet</li>
        <li style='margin-bottom:8px;'>Pierre-Auguste Renoir</li>
        <li style='margin-bottom:8px;'>J. M. W. Turner</li>
        <li style='margin-bottom:8px;'>Rembrandt van Rijn</li>
        <li style='margin-bottom:8px;'>Johannes Vermeer</li>
      </ul>
    </section>

    <section class='card' style='margin-top:18px'>
      <h3 style='margin-top:0'>Past Exhibitions (selected)</h3>
      <ol style='padding-left:18px; margin:10px 0 0 0;'>
        <li>Resonant Fields — 2016</li>
        <li>Chromatic Mechanics — 2018</li>
        <li>Invisible Cities — 2019</li>
        <li>Echoes in Blue — 2021</li>
      </ol>
    </section>
  </main>

  <footer class='site-footer'>
    <div class='container'>
      <p>© 2025 The Modern Frame</p>
    </div>
  </footer>
</body>
</html>
"@

$aboutHtml | Out-File -FilePath .\about.html -Encoding utf8 -Force

# CONTACT HTML
$contactHtml = @"
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='utf-8' />
  <title>The Modern Frame — Contact</title>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <link href='https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap' rel='stylesheet'>
  <link rel='stylesheet' href='css/style.css'>
</head>
<body>
  <header class='site-header'>
    <div class='header-inner'>
      <div class='logo'>THE MODERN FRAME</div>
      <nav class='main-nav'>
        <ul>
          <li><a href='index.html'>Home</a></li>
          <li><a href='gallery.html'>Gallery</a></li>
          <li><a href='about.html'>About</a></li>
          <li><a href='contact.html' class='active'>Contact</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main class='container'>
    <section class='card' style='margin-bottom:18px'>
      <h1 style='margin:0'>Contact & Visiting</h1>
      <p class='muted'>Questions? Sales? Private viewings by appointment.</p>
    </section>

    <section class='card'>
      <address style='font-style:normal'>
        <strong>The Modern Frame</strong><br>
        24 Artisans Lane<br>
        New Town, Imaginary City 560001<br>
        Phone: <a href='tel:+918012345678'>+91 80123 45678</a><br>
        Email: <a href='mailto:info@modernframe.example'>info@modernframe.example</a>
      </address>
    </section>

    <section class='card' style='margin-top:18px'>
      <h3 style='margin-top:0'>Studio Hours</h3>
      <table class='hours-table' aria-describedby='studio-hours'>
        <thead>
          <tr><th>Day</th><th>Opening Time</th><th>Closing Time</th></tr>
        </thead>
        <tbody>
          <tr><td>Monday</td><td>10:00</td><td>18:00</td></tr>
          <tr><td>Tuesday</td><td>10:00</td><td>18:00</td></tr>
          <tr><td>Wednesday</td><td>10:00</td><td>18:00</td></tr>
          <tr><td>Thursday</td><td>10:00</td><td>20:00</td></tr>
          <tr><td>Friday</td><td>10:00</td><td>20:00</td></tr>
          <tr><td>Saturday</td><td>11:00</td><td>17:00</td></tr>
          <tr><td>Sunday</td><td>Closed</td><td>—</td></tr>
        </tbody>
      </table>
    </section>
  </main>

  <footer class='site-footer'>
    <div class='container'>
      <p>© 2025 The Modern Frame</p>
    </div>
  </footer>
</body>
</html>
"@

$contactHtml | Out-File -FilePath .\contact.html -Encoding utf8 -Force

# README
$readme = @"
Modern_Frame_Gallery
====================

Author: Generated by assistant script

What this script did:
- Removed existing ./images folder (if present).
- Downloaded 6 artists x 5 images from Wikimedia Commons into ./images/<artist>/
- Wrote the following files:
  - index.html
  - gallery.html
  - about.html
  - contact.html
  - css/style.css

How to preview:
- Open index.html in Chrome or Firefox, or use Live Server (VS Code extension).
- Home Quick View: thumbnails auto-rotate every 12 seconds and show artist + artwork title.
- Click 'Open' on any artist to see a touch-enabled sideways slider (powered by Swiper.js).

Image sources (representative pages on Wikimedia Commons):
- Van Gogh, Starry Night & others. :contentReference[oaicite:1]{index=1}
- Monet, Impression/Sunrise & Waterlilies. :contentReference[oaicite:2]{index=2}
- Renoir (Luncheon of the Boating Party). :contentReference[oaicite:3]{index=3}
- Turner (Fighting Temeraire, Rain Steam and Speed). :contentReference[oaicite:4]{index=4}
- Rembrandt (The Night Watch). :contentReference[oaicite:5]{index=5}
- Vermeer (Girl with a Pearl Earring). :contentReference[oaicite:6]{index=6}

Notes / Known issues:
- Downloads depend on Wikimedia Commons availability; some very-high-res originals may be large.
- If any download failed, check the console output in PowerShell (it will show failures).
- This project uses Swiper.js (CDN) for the slide viewer; network is required for the Swiper assets.

Browsers tested: Chrome (stable), Firefox (stable)
"@

$readme | Out-File -FilePath .\README.txt -Encoding utf8 -Force

Write-Host "Done. Files written. Open index.html in browser (or use Live Server). If some images failed to download, re-run the script to retry or inspect PowerShell output."
# --- Function to get direct image URL from Wikimedia Commons file page ---
