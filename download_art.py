# download_art_resilient.py
# Robust downloader: fetches artworks (6 artists x 5 images)
# - uses a browser-like User-Agent
# - retries failures
# - falls back to a Picsum placeholder if an artwork cannot be downloaded
#
# Usage:
#   pip install requests
#   python download_art_resilient.py

import os
import requests
import time

OUT_DIR = "images"
os.makedirs(OUT_DIR, exist_ok=True)

# Artist -> list of direct upload.wikimedia.org URLs (these are the links we attempted earlier)
ARTISTS = {
    "van-gogh": [
        "https://upload.wikimedia.org/wikipedia/commons/e/eb/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/4/47/Vincent_van_Gogh_-_Sunflowers_-_VGM_F458.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0a/Vincent_van_Gogh_-_Bedroom_in_Arles_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/5/57/Vincent_Willem_van_Gogh_-_Cafe_Terrace_at_Night_%28Yorck%29.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/d/d4/Vincent_van_Gogh_-_Wheatfield_with_Crows_-_Google_Art_Project.jpg"
    ],
    "monet": [
        "https://upload.wikimedia.org/wikipedia/commons/9/9c/Claude_Monet%2C_Impression%2C_soleil_levant.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0c/Claude_Monet_-_Water_Lilies_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0a/Claude_Monet_-_Woman_with_a_Parasol_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/d/d6/Claude_Monet_-_The_Houses_of_Parliament%2C_Sunset.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0d/Claude_Monet_-_The_Japanese_Bridge.jpg"
    ],
    "renoir": [
        "https://upload.wikimedia.org/wikipedia/commons/6/6d/Auguste_Renoir_-_Dance_at_Le_Moulin_de_la_Galette_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/3/3c/Pierre-Auguste_Renoir_-_Luncheon_of_the_Boating_Party.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/f/f0/Pierre-Auguste_Renoir_-_The_Umbrellas.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/5/5a/Pierre-Auguste_Renoir_-_Two_Sisters_%28On_the_Terrace%29.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/6/67/Pierre-Auguste_Renoir_-_The_Bathers_-_Google_Art_Project.jpg"
    ],
    "rembrandt": [
        "https://upload.wikimedia.org/wikipedia/commons/2/28/The_Nightwatch_by_Rembrandt_-_Rijksmuseum.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0f/Rembrandt_-_The_Anatomy_Lesson_of_Dr_Nicolaes_Tulp.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/b/b8/Rembrandt_van_Rijn_-_Self-Portrait_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/7/7a/Rembrandt_-_The_Jewish_Bride.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/02/Rembrandt_-_Aristotle_with_a_Bust_of_Homer.jpg"
    ],
    "vermeer": [
        "https://upload.wikimedia.org/wikipedia/commons/d/d7/Meisje_met_de_parel.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0f/Johannes_Vermeer_-_The_Milkmaid.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/d/d1/View_of_Delft%2C_by_Johannes_Vermeer.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/f/f6/Johannes_Vermeer_-_Woman_Holding_a_Balance_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/1/1e/Johannes_Vermeer_-_The_Art_of_Painting_-_Google_Art_Project.jpg"
    ],
    "degas": [
        "https://upload.wikimedia.org/wikipedia/commons/5/58/Edgar_Degas_-_L%27Absinthe.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/5/5a/Edgar_Degas_-_The_Ballet_Class_-_Google_Art_Project.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/f/f6/Edgar_Degas_-_The_Dance_Class.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/f/fc/Edgar_Degas_-_Place_de_la_Concorde.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/0/0d/Edgar_Degas_-_Dancers_in_Blue_-_Musee_d%27Orsay_RF_1990.jpg"
    ]
}

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36"}
RETRIES = 3
BACKOFF = 2  # seconds
PLACEHOLDER = "https://picsum.photos/1200/800"  # used if real image can't be downloaded

def download_url(url, outpath):
    for attempt in range(1, RETRIES+1):
        try:
            with requests.get(url, headers=HEADERS, stream=True, timeout=30) as r:
                r.raise_for_status()
                # Save streaming to file
                with open(outpath, "wb") as f:
                    for chunk in r.iter_content(8192):
                        if chunk:
                            f.write(chunk)
            return True
        except Exception as e:
            print(f"    attempt {attempt} failed for {url}: {e}")
            time.sleep(BACKOFF * attempt)
    return False

def ensure_images():
    summary = []
    for artist, urls in ARTISTS.items():
        folder = os.path.join(OUT_DIR, artist)
        os.makedirs(folder, exist_ok=True)
        print(f"\nDownloading {artist} -> {folder}")
        i = 1
        for url in urls:
            outpath = os.path.join(folder, f"{i}.jpg")
            print(f"  {i}. {url}")
            ok = download_url(url, outpath)
            if not ok:
                print(f"    ! Failed to download artwork {i} for {artist}, fetching placeholder...")
                # try placeholder
                try:
                    download_url(PLACEHOLDER, outpath)
                    print(f"    placeholder saved to {outpath}")
                    summary.append((artist, i, "placeholder"))
                except Exception as e:
                    print(f"    placeholder also failed: {e}")
                    summary.append((artist, i, "missing"))
            else:
                summary.append((artist, i, "ok"))
            i += 1
    return summary

if __name__ == "__main__":
    print("Starting download (requests). This may take a few minutes...\n")
    results = ensure_images()
    print("\nSummary:")
    counts = {}
    for artist, idx, status in results:
        counts.setdefault(status, 0)
        counts[status] += 1
    print(f"  OK images: {counts.get('ok',0)}")
    print(f"  Placeholder used: {counts.get('placeholder',0)}")
    print(f"  Missing: {counts.get('missing',0)}")
    print("\nFiles are in the ./images folder. If many placeholders were used, tell me and I will curate replacement links manually.")
