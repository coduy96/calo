// Scroll progress bar
const scrollProgress = document.querySelector('.scroll-progress');
if (scrollProgress) {
  window.addEventListener('scroll', () => {
    const scrollTop = window.scrollY;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    scrollProgress.style.width = (scrollTop / docHeight * 100) + '%';
  });
}

// Cursor glow follow
const cursorGlow = document.querySelector('.cursor-glow');
if (cursorGlow && window.innerWidth > 480) {
  let mouseX = 0, mouseY = 0, glowX = 0, glowY = 0;
  document.addEventListener('mousemove', (e) => {
    mouseX = e.clientX;
    mouseY = e.clientY;
  });
  function animateGlow() {
    glowX += (mouseX - glowX) * 0.08;
    glowY += (mouseY - glowY) * 0.08;
    cursorGlow.style.left = glowX + 'px';
    cursorGlow.style.top = glowY + 'px';
    requestAnimationFrame(animateGlow);
  }
  animateGlow();
}

// Nav scroll effect
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
});

// Scroll reveal (single elements)
const revealEls = document.querySelectorAll('.reveal');
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.1 });
revealEls.forEach(el => revealObserver.observe(el));

// Staggered reveal (grids)
const staggerEls = document.querySelectorAll('.reveal-stagger');
const staggerObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      staggerObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.05 });
staggerEls.forEach(el => staggerObserver.observe(el));

// 3D tilt on feature cards
const featureCards = document.querySelectorAll('.feature-card');
featureCards.forEach(card => {
  // Add glow div
  const glow = document.createElement('div');
  glow.classList.add('card-glow');
  card.appendChild(glow);

  card.addEventListener('mousemove', (e) => {
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const rotateX = (y - centerY) / centerY * -6;
    const rotateY = (x - centerX) / centerX * 6;

    card.style.transform = `perspective(800px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-6px)`;
    glow.style.left = x + 'px';
    glow.style.top = y + 'px';
  });

  card.addEventListener('mouseleave', () => {
    card.style.transform = 'perspective(800px) rotateX(0) rotateY(0) translateY(0)';
  });
});

// Parallax on hero phone
const heroPhone = document.querySelector('.hero-phone');
if (heroPhone && window.innerWidth > 768) {
  window.addEventListener('scroll', () => {
    const scrollY = window.scrollY;
    const speed = 0.15;
    heroPhone.style.transform = `translateY(${scrollY * speed}px)`;
  });
}

// Close mobile menu on link click
const navToggle = document.getElementById('nav-toggle');
document.querySelectorAll('.nav-links a').forEach(link => {
  link.addEventListener('click', () => { navToggle.checked = false; });
});

// Active nav link highlighting
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a');
const sectionObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const id = entry.target.id;
      navLinks.forEach(link => {
        link.classList.toggle('active', link.getAttribute('href') === '#' + id);
      });
    }
  });
}, { threshold: 0.3, rootMargin: '-80px 0px 0px 0px' });
sections.forEach(s => sectionObserver.observe(s));

// Screenshot dots
const scrollContainer = document.querySelector('.screenshots-scroll');
const dots = document.querySelectorAll('.screenshots-dots span');
if (scrollContainer && dots.length) {
  scrollContainer.addEventListener('scroll', () => {
    const items = scrollContainer.querySelectorAll('.screenshot-item');
    const center = scrollContainer.scrollLeft + scrollContainer.clientWidth / 2;
    let closestIdx = 0;
    let closestDist = Infinity;
    items.forEach((item, i) => {
      const itemCenter = item.offsetLeft + item.offsetWidth / 2;
      const dist = Math.abs(center - itemCenter);
      if (dist < closestDist) { closestDist = dist; closestIdx = i; }
    });
    dots.forEach((d, i) => d.classList.toggle('active', i === closestIdx));
  });

  // Click dots to scroll
  dots.forEach((dot, i) => {
    dot.addEventListener('click', () => {
      const items = scrollContainer.querySelectorAll('.screenshot-item');
      if (items[i]) {
        items[i].scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
      }
    });
  });
}
