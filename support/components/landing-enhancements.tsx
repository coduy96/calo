"use client";

import { useEffect } from "react";

/**
 * Progressive enhancement for the landing page. The markup is rendered on the
 * server (good for SEO); this component just wires up the interactive bits
 * from the original Claude Design prototype:
 *   - sticky nav background on scroll
 *   - mobile menu toggle
 *   - reveal-on-scroll via IntersectionObserver (with safety fallbacks so
 *     above-the-fold content never stays hidden)
 * It renders nothing.
 */
export function LandingEnhancements() {
  useEffect(() => {
    const nav = document.getElementById("nav");
    const onScroll = () =>
      nav?.classList.toggle("scrolled", window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });

    // Mobile menu
    const toggle = document.getElementById("navToggle");
    const menu = document.getElementById("mobileMenu");
    const onToggle = () => menu?.classList.toggle("open");
    const closeMenu = () => menu?.classList.remove("open");
    toggle?.addEventListener("click", onToggle);
    const menuLinks = menu ? Array.from(menu.querySelectorAll("a")) : [];
    menuLinks.forEach((a) => a.addEventListener("click", closeMenu));

    // Reveal on scroll
    const reveals = Array.from(document.querySelectorAll(".reveal"));
    const inView = (el: Element) => {
      const r = el.getBoundingClientRect();
      return r.top < (window.innerHeight || 0) * 0.96 && r.bottom > 0;
    };
    // Show anything already visible on load immediately (no wait for observer)
    reveals.forEach((el) => {
      if (inView(el)) el.classList.add("in");
    });
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add("in");
            io.unobserve(e.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" },
    );
    reveals.forEach((el) => {
      if (!el.classList.contains("in")) io.observe(el);
    });
    // Safety net: never leave content hidden
    const safety = window.setTimeout(() => {
      reveals.forEach((el) => {
        if (inView(el)) el.classList.add("in");
      });
    }, 1500);

    return () => {
      window.removeEventListener("scroll", onScroll);
      toggle?.removeEventListener("click", onToggle);
      menuLinks.forEach((a) => a.removeEventListener("click", closeMenu));
      io.disconnect();
      window.clearTimeout(safety);
    };
  }, []);

  return null;
}
