import { LightningElement, track } from 'lwc';
import getSlides from '@salesforce/apex/GigaCommOrderWizardController.getSlides';

export default class GcAddressFinderWrapperLWC extends LightningElement {

    @track slides = [];
    @track currentIndex = 1;
    videoLoaded = false;

    // saved handlers so we can remove them
    _resizeHandler = null;
    _mutationObserver = null;

    /* ---------------------------
       AUTOPLAY additions (start)
       --------------------------- */
    _autoPlayIntervalMs = 7000; // change to adjust autoplay speed (ms)
    _autoPlayTimer = null;
    _autoPlayPaused = false; // set when hovering, dragging, or temporarily after user interaction
    _userPauseTimeout = null;
    _pointerResumeTimeout = null;
    _autoplayWired = false;

    // bound listeners (so we can remove them)
    _boundPointerDown = null;
    _boundPointerUp = null;
    _boundMouseEnter = null;
    _boundMouseLeave = null;
    _boundClick = null;
    /* ---------------------------
       AUTOPLAY additions (end)
       --------------------------- */

    constructor() {
        super();
        // bind handlers used for adding/removing listeners
        this._boundPointerDown = () => this._pauseAutoPlay();
        this._boundPointerUp = () => this._maybeResumeAfterPointer();
        this._boundMouseEnter = () => this._pauseAutoPlay();
        this._boundMouseLeave = () => this._resumeAutoPlay();
        this._boundClick = () => this._temporarilyPauseAfterUserInteraction();
    }

    connectedCallback() {
        this.loadSlides();

        // resize listener to keep heights synced
        this._resizeHandler = () => this.adjustMediaHeight();
        window.addEventListener('resize', this._resizeHandler);
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this._resizeHandler);
        if (this._mutationObserver) {
            this._mutationObserver.disconnect();
            this._mutationObserver = null;
        }

        // AUTOPLAY cleanup
        this._stopAutoPlay();
        if (this._autoplayWired) {
            const root = this.template && this.template.querySelector ? this.template : null;
            // prefer outer container if present
            const outer = this.template.querySelector('.gc-hero-container') || this.template.querySelector('.hero-content-wrap') || this.template;
            if (outer) {
                outer.removeEventListener('pointerdown', this._boundPointerDown);
                outer.removeEventListener('pointerup', this._boundPointerUp);
                outer.removeEventListener('pointercancel', this._boundPointerUp);
                outer.removeEventListener('mouseenter', this._boundMouseEnter);
                outer.removeEventListener('mouseleave', this._boundMouseLeave);
                outer.removeEventListener('click', this._boundClick);
            }
            this._autoplayWired = false;
        }
        if (this._userPauseTimeout) {
            clearTimeout(this._userPauseTimeout);
            this._userPauseTimeout = null;
        }
        if (this._pointerResumeTimeout) {
            clearTimeout(this._pointerResumeTimeout);
            this._pointerResumeTimeout = null;
        }
    }

    async loadSlides() {
        try {
            const data = await getSlides();

            this.slides = (Array.isArray(data) ? data : []).map((s, i) => ({
                ...s,
                index: i,
                dotClass: i === 0 ? 'dot active' : 'dot',
                ariaLabel: `Go to slide ${i + 1}`,
                ariaSelected: i === 0 ? 'true' : 'false'
            }));

            this.currentIndex = this.slides.length > 0 ? 1 : 0;
            this.videoLoaded = false;

        } catch (err) {
            console.error('Error loading slides', err);
            this.slides = [];
            this.currentIndex = 0;
        }
    }

    get activeSlide() {
        if (!this.slides || this.slides.length === 0 || this.currentIndex < 1) {
            return null;
        }
        return this.slides[this.currentIndex - 1];
    }

    get isImageActive() {
        return !!this.activeSlide && (this.activeSlide.type || '').toLowerCase() === 'image';
    }

    get isVideoActive() {
        return !!this.activeSlide && (this.activeSlide.type || '').toLowerCase() === 'video';
    }

    get activeImageStyle() {
        const url = this.activeSlide?.imageUrl || '';
        return `background-image:url('${url}'); background-position:center; background-size:cover;`;
    }

    renderedCallback() {
        // Ensure subtitle is updated
        this.updateSubtitle();

        // Keep left column height synced to right column (text content)
        this.adjustMediaHeight();

        // Setup mutation observer once to detect dynamic text changes on right
        if (!this._mutationObserver) {
            const right = this.template.querySelector('.hero-content-wrap');
            if (right) {
                this._mutationObserver = new MutationObserver(() => {
                    // small delay to allow layout to settle
                    setTimeout(() => this.adjustMediaHeight(), 40);
                });
                this._mutationObserver.observe(right, { childList: true, subtree: true, characterData: true });
            }
        }

        // If it's a video slide and not injected yet, inject it
        if (this.isVideoActive && !this.videoLoaded) {
            this.injectVideo();
        }

        // If not a video slide, ensure we remove any iframe
        if (!this.isVideoActive) {
            const container = this.template.querySelector('.video-inner');
            if (container) container.innerHTML = '';
            this.videoLoaded = false;
        }

        /* ---------------------------
           AUTOPLAY wiring (added)
           --------------------------- */
        // Wire up pointer / mouse / click handlers once
        if (!this._autoplayWired) {
            // choose container for listeners (prefer hero container or entire component)
            const container = this.template.querySelector('.gc-hero-container') || this.template.querySelector('.hero-content-wrap') || this.template.querySelector('.hero') || this.template;
            if (container) {
                container.addEventListener('pointerdown', this._boundPointerDown, { passive: true });
                container.addEventListener('pointerup', this._boundPointerUp, { passive: true });
                container.addEventListener('pointercancel', this._boundPointerUp, { passive: true });

                container.addEventListener('mouseenter', this._boundMouseEnter, { passive: true });
                container.addEventListener('mouseleave', this._boundMouseLeave, { passive: true });

                // click anywhere (dots/controls) temporarily pauses autoplay so user can interact
                container.addEventListener('click', this._boundClick, { passive: true });

                this._autoplayWired = true;
            }
        }

        // Start autoplay if slides are available
        this._startAutoPlay();
        /* ---------------------------
           AUTOPLAY wiring end
           --------------------------- */
    }

    /**
     * adjustMediaHeight
     * Keep left column height matching right column so iframe can fill vertically.
     */
    adjustMediaHeight() {
        const right = this.template.querySelector('.hero-content-wrap');
        const left = this.template.querySelector('.gc-hero-container');

        if (!right || !left) return;

        // compute right height including margins
        const rightRect = right.getBoundingClientRect();
        const computedRightHeight = Math.max(Math.round(rightRect.height), 320); // fallback min

        // apply to left
        left.style.height = computedRightHeight + 'px';

        // ensure nested containers occupy full height
        const mediaWrap = left.querySelector('.media-wrap');
        const mediaVideo = left.querySelector('.media-video');
        const videoInner = left.querySelector('.video-inner');
        [mediaWrap, mediaVideo, videoInner].forEach(el => {
            if (el) {
                el.style.height = '100%';
                el.style.width = '100%';
                el.style.position = 'relative';
                el.style.overflow = 'hidden';
            }
        });

        // If iframe present, re-apply cover rules
        const iframe = this.template.querySelector('.video-inner iframe');
        if (iframe) {
            this.applyIframeCoverStyles(iframe);
        }
    }

    applyIframeCoverStyles(iframe) {
        // Make iframe behave like object-fit: cover
        iframe.style.position = 'absolute';
        iframe.style.top = '50%';
        iframe.style.left = '50%';
        iframe.style.transform = 'translate(-50%, -50%)';
        iframe.style.minWidth = '100%';
        iframe.style.minHeight = '100%';
        iframe.style.width = 'auto';
        iframe.style.height = 'auto';
        iframe.style.border = '0';
        iframe.style.background = 'transparent';

        const parent = iframe.parentElement;
        if (parent) {
            parent.style.overflow = 'hidden';
            parent.style.position = 'relative';
        }
    }

    /**
     * injectVideo()
     * - strips <script> tags
     * - extracts only the <iframe> from backend HTML (removes wrapper div with padding)
     * - rewrites the iframe src to add Vimeo background/autoplay/muted params
     * - ensures allow & frameborder attributes exist
     * - inserts the iframe and applies cover styles
     */
    injectVideo() {
    const container = this.template.querySelector('.video-inner');
    if (!container || !this.activeSlide?.videoHtml) return;

    // -------- STATIC RESOURCE MP4 HANDLING (NO IMPORT REQUIRED) --------
try {
    let backendVal = String(this.activeSlide.videoHtml || '').trim();

    // only if backend gives /resource/...
    if (backendVal.startsWith('/resource')) {
        // build the absolute URL
        const videoUrl = window.location.origin + backendVal;

        container.innerHTML = `
            <video
                src="${videoUrl}"
                autoplay
                muted
                loop
                playsinline
                preload="metadata"
                style="width:100%;height:100%;object-fit:cover;display:block;border:0;"
                aria-hidden="true"
            ></video>
        `;

        this.videoLoaded = true;

        setTimeout(() => this.adjustMediaHeight(), 40);
        return; // stop and skip iframe logic
    }

    // ALSO support direct .mp4 URL from backend
    if (backendVal.toLowerCase().endsWith('.mp4')) {
        container.innerHTML = `
            <video
                src="${backendVal}"
                autoplay
                muted
                loop
                playsinline
                preload="metadata"
                style="width:100%;height:100%;object-fit:cover;display:block;border:0;"
                aria-hidden="true"
            ></video>
        `;

        this.videoLoaded = true;
        setTimeout(() => this.adjustMediaHeight(), 40);
        return;
    }
} catch (e) {
    console.warn('MP4 static resource handling failed', e);
}
// -------- END STATIC RESOURCE HANDLING --------

}

    handlePlayClick() {
        const container = this.template.querySelector('.video-inner');
        if (!container || !this.activeSlide?.videoHtml) return;

        // fallback injection when user clicks play (we still strip scripts)
        const cleanHtml = this.activeSlide.videoHtml.replace(/<script[\s\S]*?<\/script>/gi, '');
        container.innerHTML = cleanHtml;
        this.videoLoaded = true;
        // reapply cover style if iframe present
        const iframe = container.querySelector('iframe');
        if (iframe) this.applyIframeCoverStyles(iframe);
    }

    prev() {
        if (!this.slides.length) return;

        this.currentIndex =
            this.currentIndex === 1 ? this.slides.length : this.currentIndex - 1;

        this.updateDots();
        this.videoLoaded = false;

        const container = this.template.querySelector('.video-inner');
        if (container) container.innerHTML = '';
    }

    next() {
        if (!this.slides.length) return;

        this.currentIndex =
            this.currentIndex === this.slides.length ? 1 : this.currentIndex + 1;

        this.updateDots();
        this.videoLoaded = false;

        const container = this.template.querySelector('.video-inner');
        if (container) container.innerHTML = '';
    }

    onDotClick(event) {
        const idx = Number(event.target.dataset.index);
        if (!Number.isNaN(idx)) {
            this.currentIndex = idx + 1;
            this.updateDots();
            this.videoLoaded = false;

            const container = this.template.querySelector('.video-inner');
            if (container) container.innerHTML = '';
        }
    }

    updateDots() {
        this.slides = this.slides.map((s, i) => ({
            ...s,
            dotClass: this.currentIndex - 1 === i ? 'dot active' : 'dot',
            ariaSelected: this.currentIndex - 1 === i ? 'true' : 'false'
        }));
    }

    // convert backend subtitle text to HTML with line breaks
    updateSubtitle() {
        const subtitleEl = this.template.querySelector('.gc-hero-subtitle');
        if (!subtitleEl) return;

        const raw = this.activeSlide?.subtitle
            ? String(this.activeSlide.subtitle)
            : '';

        const html = raw
            .replace(/\\n/g, '<br/>')     // escaped newline
            .replace(/\r\n|\r|\n/g, '<br/>') // real newline
            .replace(/\|\|/g, '<br/>');   // custom separator

        subtitleEl.innerHTML = html;
    }

    /* ---------------------------
       AUTOPLAY helper methods (added)
       --------------------------- */

    _startAutoPlay() {
        // don't start if already running or no slides
        if (this._autoPlayTimer || !this.slides || this.slides.length < 2) return;

        // create interval which advances via the existing next() method
        this._autoPlayTimer = setInterval(() => {
            // guard: don't advance if user is interacting or a video slide is active/injected
            if (this._autoPlayPaused) return;
            // use next() so existing logic runs (dots update, container cleared)
            try {
                this.next();
            } catch (e) {
                // swallow any errors
                console.error('autoplay next error', e);
            }
        }, this._autoPlayIntervalMs);
    }

    _stopAutoPlay() {
        if (this._autoPlayTimer) {
            clearInterval(this._autoPlayTimer);
            this._autoPlayTimer = null;
        }
        this._autoPlayPaused = false;
    }

    _pauseAutoPlay() {
        this._autoPlayPaused = true;
        // clear any pending resume timers
        if (this._userPauseTimeout) {
            clearTimeout(this._userPauseTimeout);
            this._userPauseTimeout = null;
        }
    }

    _resumeAutoPlay() {
        this._autoPlayPaused = false;
    }

    _temporarilyPauseAfterUserInteraction() {
        // Called on click - pause for a short while then resume
        this._pauseAutoPlay();
        if (this._userPauseTimeout) clearTimeout(this._userPauseTimeout);
        // pause for slightly longer than one interval to give user time
        this._userPauseTimeout = setTimeout(() => {
            this._resumeAutoPlay();
        }, Math.max(1200, this._autoPlayIntervalMs)); // at least 1.2s or one interval
    }

    _maybeResumeAfterPointer() {
        // pointerup / cancel — resume after a short delay to avoid immediate jump
        if (this._pointerResumeTimeout) clearTimeout(this._pointerResumeTimeout);
        this._pointerResumeTimeout = setTimeout(() => {
            this._resumeAutoPlay();
        }, 300);
    }

    /* ---------------------------
       AUTOPLAY helper methods end
       --------------------------- */
    handlePromoButtonClick() {
        const link = this.activeSlide && this.activeSlide.buttonLink ? String(this.activeSlide.buttonLink).trim() : '';

        if (!link) {
            // nothing to do for this slide
            return;
        }

        try {
            // new URL(link, base) will handle absolute and relative links
            const destination = new URL(link, window.location.href).toString();
            window.location.href = destination;
        } catch (e) {
            // fallback: if URL() fails, try direct assignment
            window.location.href = link;
        }
    }   
}