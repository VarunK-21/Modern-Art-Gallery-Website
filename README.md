Overview:
A minimalistic, elegant, desktop-oriented website for a fictional art gallery. Built using only HTML5 and CSS3, featuring a fixed header, smooth hover effects, CSS Grid gallery, and a modern, muted aesthetic.

# 🎨 The Modern Frame — Art Gallery Website
_A minimalistic, elegant, desktop-oriented website built with only **HTML5 & CSS3**._

---

## 📸 Preview

### Home Page  
<img width="2521" height="1440" alt="Screenshot 2025-09-23 220240" src="https://github.com/user-attachments/assets/23b136c5-4210-4109-8161-86e50af99811" />


### Gallery Page  
<img width="2517" height="1416" alt="Screenshot 2025-09-23 220256" src="https://github.com/user-attachments/assets/c39c0401-7a17-4449-ae06-11b7ee9f7360" />


### About Page  
<img width="2514" height="1413" alt="Screenshot 2025-09-23 220308" src="https://github.com/user-attachments/assets/c715e2fd-332a-4867-a163-2df10e464a03" />


### Contact Page  
<img width="2539" height="1432" alt="Screenshot 2025-09-23 220320" src="https://github.com/user-attachments/assets/9e30444f-c7dc-4f01-be5c-c82478b20299" />

---
## 🎥 Virtual Gallery Tour  

[![Watch the Virtual Gallery Tour](https://artsandculture.google.com/project/virtual-tours)](https://artsandculture.google.com/project/virtual-tours)


Structure:
- index.html — Home: hero with background image, featured badge, animated banner, welcome + upcoming exhibition
- gallery.html — Gallery: 6 artworks laid out in a responsive CSS Grid with hover scale
- about.html — About: gallery history, ordered list of past exhibitions, staff list, embedded video tour
- contact.html — Contact: address, phone, email, hours table, external Virtual Tour link
- css/style.css — Global theme, navigation, layouts (flex/grid), animations, utilities
- images/ — placeholders (served via picsum.photos URLs in markup)
- videos/ — optional placeholder (not required for static build)

Implemented Features:
- Semantic HTML5 structure across all pages
- Fixed, translucent header with flexbox navigation
- Smooth hover transitions on nav and artworks
- Hero section with background image and absolutely positioned “Featured!” badge
- CSS @keyframes animation for the “Open House!” banner
- CSS Grid gallery (3x2 on desktop; responsive downshifts)
- Image presentation with borders, shadows, and rounded corners
- Contact table for studio hours
- External Virtual Tour link using target="_blank" and rel="noopener"
- Consistent typography and color palette with custom CSS variables

Known Issues:
- Images are loaded from manually uploaded photos and change periodically; for strict offline demos, download assets to the images/ directory.
- Virtual Tour depends on network connectivity.
- The images are already provided in the repositroy, after downloading the files shift all the images into images folder.

Browsers Tested:
- Chrome (current)
- Firefox (current)
  
How to View:
Open index.html in a modern desktop browser. Navigate using the fixed header.

Author: Varun Kilari



