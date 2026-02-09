// Nav scroll effect
const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 40);
});

// Scroll reveal
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
}
