import { LightningElement, track } from 'lwc';
import BFPromoBanner1 from '@salesforce/resourceUrl/BFDeskview1';
import BFPromoBanner2 from '@salesforce/resourceUrl/BFDeskview2';
import LUPromoBanner1 from '@salesforce/resourceUrl/LEVELUPBanner1';
import LUPromoBanner2 from '@salesforce/resourceUrl/LEVELUPBanner2'; 


export default class GcPromoCodeBanner extends LightningElement {
  @track currentIndex = 0;

  // desktop and mobile arrays (you can replace these with multiple images if needed)
  desktopSlides = [BFPromoBanner1, BFPromoBanner2, LUPromoBanner1, LUPromoBanner2];
  mobileSlides = [BFPromoBanner1, BFPromoBanner2, LUPromoBanner1, LUPromoBanner2];

  // internal slides array used by template
  @track slides = [];

  // breakpoint for mobile (same as other components)
  MOBILE_BP = 520;

  // resize listener reference so we can remove it
  _resizeHandler = null;

  // mobile/drag state
  isMobile = false; // set by _updateSlidesForViewport()
  _mobileInitDone = false;
  _mobileDragging = false;
  _mobilePointerId = null;
  _mobileStartX = 0; // px where pointer started
  _mobileDragPercent = 0; // percent of slide width dragged (positive => dragged right)
  _mobileThresholdPx = 50; // threshold to change slide (px)
  _promoWrapWidth = 0;

  // --- AUTOPLAY additions (do not modify these unless you want different behavior) ---
  _autoPlayIntervalMs = 15000; // autoplay delay (ms) — change as needed
  _autoPlayTimer = null;
  _autoPlayPaused = false;       // manual pause (hover/drag)
  _autoPlayUserPauseMs = 10000;   // pause after a user interaction (click/dot) before resuming
  _pauseHandler = null;
  _resumeHandler = null;
  _pointerDownListener = null;
  _pointerUpListener = null;
  _mouseEnterListener = null;
  _mouseLeaveListener = null;
  _clickListener = null;
  // -------------------------------------------------------------------------------

  // pick initial slides at construction time (fallback to desktop)
  constructor() {
    super();
    this.slides = this.desktopSlides.slice(); // default
    this._resizeHandler = this._onWindowResize.bind(this);

    // bind autoplay methods so we can add/remove listeners
    this._pauseHandler = () => this._pauseAutoPlay();
    this._resumeHandler = () => this._resumeAutoPlay();
    this._pointerDownListener = () => this._pauseAutoPlay();
    this._pointerUpListener = () => this._maybeResumeAfterPointer();
    this._mouseEnterListener = () => this._pauseAutoPlay();
    this._mouseLeaveListener = () => this._resumeAutoPlay();
    this._clickListener = () => this._temporarilyPauseAfterUserInteraction();
  }

  renderedCallback() {
    // choose appropriate slides for current viewport
    this._updateSlidesForViewport();

    // attach resize handler once
    if (!this._resizeAttached) {
      window.addEventListener('resize', this._resizeHandler, { passive: true });
      this._resizeAttached = true;
    }

    // measure promo wrap width after render (used by drag math)
    const wrap = this.template.querySelector('.promo-track-wrap');
    if (wrap && wrap.clientWidth) {
      this._promoWrapWidth = wrap.clientWidth;
    }

    // --- AUTOPLAY wiring: attach listeners and start autoplay ---
    // Add pointer & mouse listeners on the visible wrap if available
    if (wrap && !this._autoplayWired) {
      // pause on pointer down (touch/pen/mouse) and resume on pointer up/cancel
      wrap.addEventListener('pointerdown', this._pointerDownListener, { passive: true });
      wrap.addEventListener('pointerup', this._pointerUpListener, { passive: true });
      wrap.addEventListener('pointercancel', this._pointerUpListener, { passive: true });

      // also pause on hover for desktop
      wrap.addEventListener('mouseenter', this._mouseEnterListener, { passive: true });
      wrap.addEventListener('mouseleave', this._mouseLeaveListener, { passive: true });

      // clicking anywhere inside (dots/buttons) should temporarily pause autoplay
      const outer = this.template.querySelector('.promo-outer') || this.template;
      if (outer) {
        outer.addEventListener('click', this._clickListener, { passive: true });
      }

      this._autoplayWired = true;
    }

    // Start autoplay (safe to call multiple times)
    this._startAutoPlay();
    // ------------------------------------------------------------------
  }

  disconnectedCallback() {
    // cleanup
    if (this._resizeHandler) {
      window.removeEventListener('resize', this._resizeHandler);
      this._resizeAttached = false;
    }

    // --- AUTOPLAY cleanup ---
    this._stopAutoPlay();

    const wrap = this.template && this.template.querySelector && this.template.querySelector('.promo-track-wrap');
    if (wrap && this._autoplayWired) {
      wrap.removeEventListener('pointerdown', this._pointerDownListener);
      wrap.removeEventListener('pointerup', this._pointerUpListener);
      wrap.removeEventListener('pointercancel', this._pointerUpListener);
      wrap.removeEventListener('mouseenter', this._mouseEnterListener);
      wrap.removeEventListener('mouseleave', this._mouseLeaveListener);
      const outer = this.template.querySelector('.promo-outer') || this.template;
      if (outer) outer.removeEventListener('click', this._clickListener);
      this._autoplayWired = false;
    }
    // ------------------------------------------------------------------
  }

  _onWindowResize() {
    // debounce lightly (simple)
    if (this._resizeTimer) clearTimeout(this._resizeTimer);
    this._resizeTimer = setTimeout(() => {
      this._updateSlidesForViewport();
      // update measured width on resize
      const wrap = this.template.querySelector('.promo-track-wrap');
      if (wrap && wrap.clientWidth) this._promoWrapWidth = wrap.clientWidth;
    }, 120);
  }

  _isMobileViewport() {
    try {
      return window.innerWidth <= this.MOBILE_BP;
    } catch (e) {
      // fallback (LTR rendering environments may not have window)
      return false;
    }
  }

  _updateSlidesForViewport() {
    const isMobile = this._isMobileViewport();
    this.isMobile = isMobile; // set flag used by pointer handlers and trackStyle

    const desired = isMobile ? this.mobileSlides : this.desktopSlides;

    // If slides are already the same reference, nothing to do
    // (compare lengths and first item)
    const same = (this.slides.length === desired.length &&
                  this.slides.length && this.slides[0] === desired[0]);

    if (!same) {
      // keep currentIndex within bounds after switching
      const prevIndex = this.currentIndex || 0;
      this.slides = desired.slice(); // replace with correct array
      // clamp currentIndex
      if (prevIndex >= this.slides.length) {
        this.currentIndex = 0;
      } else {
        this.currentIndex = prevIndex;
      }
    }
  }

  // Build a computed slides array that the template binds to
  get computedSlides() {
    return this.slides.map((src, i) => {
      const isActive = i === this.currentIndex;
      return {
        src,
        idx: i,
        isActive,
        ariaHidden: isActive ? 'false' : 'true',
        AriaLabel: `Slide ${i + 1}`,
        // match naming for classes & data attributes
        dataIdCarousel: `carousel${i + 1}`,
        btnClass: isActive ? 'dot-button active' : 'dot-button',
        dotClass: isActive ? 'dot active' : 'dot'
      };
    });
  }

  get trackStyle() {
    // If on mobile & currently dragging, reflect drag percentage without transition.
    if (this.isMobile && this._mobileDragging) {
      // Shift base translate by currentIndex*100% then add negative drag percent
      // positive _mobileDragPercent means user dragged right (we want to move track to the right)
      const base = this.currentIndex * 100;
      const current = base - this._mobileDragPercent;
      return `transform: translateX(-${current}%); transition: none;`;
    }

    // normal transform using percent (each slide is 100% width)
    return `transform: translateX(-${this.currentIndex * 100}%); transition: transform 420ms cubic-bezier(.2,.9,.2,1);`;
  }

  // The template uses the same handler name as your plans component
  handleCarousel(event) {
    // attempt to find data-slideto on the clicked element or ancestors
    let elWithAttr = event.currentTarget || event.target;
    if (!elWithAttr) return;

    if (!elWithAttr.getAttribute || !elWithAttr.getAttribute('data-slideto')) {
      elWithAttr = elWithAttr.closest && elWithAttr.closest('[data-slideto]') || event.currentTarget;
    }

    const slideto = elWithAttr ? (elWithAttr.dataset ? elWithAttr.dataset.slideto : elWithAttr.getAttribute('data-slideto')) : null;
    if (!slideto) return;

    // slideto format is "carouselX" -> parse number
    const match = slideto.match(/carousel(\d+)/);
    if (match && match[1]) {
      const idx = Number(match[1]) - 1;
      if (!Number.isNaN(idx) && idx >= 0 && idx < this.slides.length) {
        this.currentIndex = idx;
      }
    }
  }

  /* -------------------------
     Mobile pointer / drag handlers
     - only active when this.isMobile === true
     - uses pointer events (works with touch & pen)
     ------------------------- */
  onPointerDown(e) {
  // only enable drag on mobile
  if (!this.isMobile) return;

  // ignore non-primary pointers
  if (e.isPrimary === false) return;

  // if pointer started on a control (button, dot, etc.), do not begin drag
  // NOTE: removed '.promo-image' from this check so touches on the image will start a drag
  const interactive = e.target && e.target.closest && e.target.closest('button, a, input, textarea, select, label, .dot-button');
  if (interactive) {
    return;
  }

  // prevent default so browser doesn't start image dragging / text selection
  try { e.preventDefault(); } catch (err) { /* ignore */ }

  // use the element that the event was attached to (currentTarget) for pointer capture & measurements
  const wrapEl = e.currentTarget || this.template.querySelector('.promo-track-wrap');
  if (wrapEl && wrapEl.setPointerCapture) {
    try { wrapEl.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
  }

  this._mobileDragging = true;
  this._mobilePointerId = e.pointerId;
  // use clientX from event (touch uses pointer events on modern browsers)
  this._mobileStartX = (e.clientX != null) ? e.clientX : (e.touches && e.touches[0] && e.touches[0].clientX) || 0;

  // measure width of the area for percent math using the same wrapEl
  this._promoWrapWidth = wrapEl && wrapEl.clientWidth ? wrapEl.clientWidth : this._promoWrapWidth || window.innerWidth || 1;

  // reset drag percent
  this._mobileDragPercent = 0;
}


 onPointerMove(e) {
  if (!this.isMobile) return;
  if (!this._mobileDragging || e.pointerId !== this._mobilePointerId) return;

  // compute deltaX using event.clientX
  const clientX = (e.clientX != null) ? e.clientX : (e.touches && e.touches[0] && e.touches[0].clientX) || 0;
  const deltaX = clientX - this._mobileStartX;

  // compute percent of one slide width (positive means dragging right)
  const wrapWidth = this._promoWrapWidth || 1;
  const percent = (deltaX / wrapWidth) * 100;

  // limit drag percent to -100..100 to avoid huge overscroll visual
  this._mobileDragPercent = Math.max(Math.min(percent, 100), -100);

  // trackStyle getter uses _mobileDragPercent so UI updates automatically
}


 onPointerUp(e) {
  if (!this.isMobile) return;
  if (!this._mobileDragging) return;

  const clientX = (e.clientX != null) ? e.clientX : (e.changedTouches && e.changedTouches[0] && e.changedTouches[0].clientX) || 0;
  const deltaX = clientX - this._mobileStartX;

  // release pointer capture if available (use currentTarget)
  const wrapEl = e.currentTarget || this.template.querySelector('.promo-track-wrap');
  if (wrapEl && wrapEl.releasePointerCapture) {
    try { wrapEl.releasePointerCapture(e.pointerId || this._mobilePointerId); } catch (err) { /* ignore */ }
  }

  // determine if swipe is enough to move slides
  const wrapWidth = this._promoWrapWidth || 1;
  const threshold = Math.min(this._mobileThresholdPx, Math.round(wrapWidth * 0.18)); // fixed px or 18% width
  if (Math.abs(deltaX) > threshold) {
    // swipe left -> deltaX negative -> move to next slide
    if (deltaX < 0 && this.currentIndex < this.slides.length - 1) {
      this.currentIndex = this.currentIndex + 1;
    }
    // swipe right -> deltaX positive -> move to prev slide
    else if (deltaX > 0 && this.currentIndex > 0) {
      this.currentIndex = this.currentIndex - 1;
    }
  }

  // clear drag state, animate to new index
  this._mobileDragging = false;
  this._mobilePointerId = null;
  this._mobileStartX = 0;
  this._mobileDragPercent = 0;

  // ensure reactive update (trackStyle will now use currentIndex)
  setTimeout(() => { this.currentIndex = this.currentIndex; }, 0);
}


  onPointerCancel(e) {
    if (!this.isMobile) return;
    // treat cancel same as up (snapback)
    this._mobileDragging = false;
    this._mobilePointerId = null;
    this._mobileStartX = 0;
    this._mobileDragPercent = 0;
  }


  /* -------------------------
     AUTOPLAY helper methods (added)
     ------------------------- */
  _startAutoPlay() {
    
    // don't start if already running or no slides or only one slide
    if (this._autoPlayTimer || !this.slides || this.slides.length < 2) return;
    // create interval
    this._autoPlayTimer = setInterval(() => {
      // don't advance while user is dragging on mobile or autoplay paused
      if (this._mobileDragging || this._autoPlayPaused) return;
      // advance to next index (loop)
      const next = (this.currentIndex + 1) % this.slides.length;
      this.currentIndex = next;
    }, this._autoPlayIntervalMs);
  }

  _stopAutoPlay() {
    if (this._autoPlayTimer) {
      clearInterval(this._autoPlayTimer);
      this._autoPlayTimer = null;
    }
  }

  _pauseAutoPlay() {
    // set a flag so interval tick will skip; keep timer running to preserve scheduling
    this._autoPlayPaused = true;
  }

  _resumeAutoPlay() {
    // resume immediately
    this._autoPlayPaused = false;
  }

  _temporarilyPauseAfterUserInteraction() {
    // called on clicks (dots/buttons) — pause for a short while then resume
    this._pauseAutoPlay();
    // clear any pending resume timeouts
    if (this._userPauseTimeout) clearTimeout(this._userPauseTimeout);
    this._userPauseTimeout = setTimeout(() => {
      this._resumeAutoPlay();
    }, this._autoPlayUserPauseMs);
  }

  _maybeResumeAfterPointer() {
    // pointerup/ cancel — resume after a short delay to avoid immediate jump
    // small delay to let any pointerup logic finish
    if (this._pointerResumeTimeout) clearTimeout(this._pointerResumeTimeout);
    this._pointerResumeTimeout = setTimeout(() => {
      this._resumeAutoPlay();
    }, 300);
  }
  // ------------------------------------------------------------------

}