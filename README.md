The Modern Frame Art Gallery Static Website

Author: Varun.K

Overview:
A minimalistic, elegant, desktop-oriented website for a fictional art gallery. Built using only HTML5 and CSS3, featuring a fixed header, smooth hover effects, CSS Grid gallery, and a modern, muted aesthetic.

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
- Images are loaded from picsum.photos and change periodically; for strict offline demos, download assets to the images/ directory.
- YouTube embed depends on network connectivity.

Browsers Tested:
- Chrome (current)
- Firefox (current)

How to View:
Open index.html in a modern desktop browser. Navigate using the fixed header.




