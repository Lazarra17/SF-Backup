/* eslint-disable no-unused-vars,  @lwc/lwc/no-async-operation, no-shadow, no-empty, no-useless-return, no-dupe-class-members  */

import { LightningElement, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getPlans from "@salesforce/apex/GigaCommOrderWizardController.getPlans";
import Plan1gbFrame from "@salesforce/resourceUrl/Plan1gbFrame";
import Plan2gbFrame from "@salesforce/resourceUrl/Plan2gbFrame";
import Plan500and100mbFrame from "@salesforce/resourceUrl/Plan500and100mbFrame";
import PlanHomeIcon from "@salesforce/resourceUrl/PlanHomeIcon";
import SmallBuissnessPlan from "@salesforce/resourceUrl/SmallBuissnessPlan";
import IndividualPlan from "@salesforce/resourceUrl/IndividualPlan";
import IconUnlimited from "@salesforce/resourceUrl/IconUnlimited";
import IconInstall from "@salesforce/resourceUrl/IconInstall";
import IconRouter from "@salesforce/resourceUrl/IconRouter";
import IconCancellation from "@salesforce/resourceUrl/IconCancellation";
import IconFiber from "@salesforce/resourceUrl/IconFiber";
import ArrowRightPlan from "@salesforce/resourceUrl/arrow_right_plan";
import ArrowLeftPlan from "@salesforce/resourceUrl/arrow_left_plan";
import TerminationFee from "@salesforce/resourceUrl/TerminationFee";
import imgUnavailable from "@salesforce/resourceUrl/GigaCommNoImgAvailable";
import Fast500 from "@salesforce/resourceUrl/Fast500";

export default class GcPlans extends NavigationMixin(LightningElement) {
  // matching Figma: tile width 415px, gap 32px
  tileWidth = 415; // px (desktop default)
  gap = 32; // px
  viewportWidth = 980; // px (desktop default)
  plan1gbIcon = Plan1gbFrame;
  currentIndex = 2; // 1-based center index
  @api allowSelectPlan; // boolean
  @track result = [];
  @track inclusions = [];
  @track fallbackInclusions = [];
  @track activeTab = "Monthly";
  @track atStart = false; // NEW - viewport at extreme left
  @track atEnd = false; // NEW - viewport at extreme right
  desktopTrackStyle = "transform: translateX(0px);";
  _needsPlanNormalization = false;
  _centerInitDone = false;
  hideNolock = false;
  PREVIEW_COUNT = 3;
  RightPlanSliderArrow = ArrowRightPlan;
  LeftPlanSliderArrow = ArrowLeftPlan;
  isMobile = false;
  _mobilePointerId = null;
  _mobileStartX = 0;
  _mobileDragging = false;
  _mobileThreshold = 50; // px
  _mobileInitDone = false;
  _ignoreMobileScrollUntil = 0;
  // for scroll debounce
  _mobileScrollTimer = null;
  _mobileScrollDebounceMs = 80;
  _plans = [];

  connectedCallback() {
    if (!this._plans || this._plans.length === 0) {
      this.getPlans();
    }
  }
  _lead;

  @api
  get lead() {
    return this._lead;
  }
  set lead(value) {
    this._lead = value;
    // keep item-level flags in sync when lead is set/updated
    this.updateSelectionFlags();
  }

  @api
  get plans() {
    return this._plans;
  }
  set plans(value) {
    // debug
    //console.log('AURA SENT (setter):', value && value.length ? value.length : 'empty');

    // defensive copy so mutations by parent won't silently break update detection
    const incoming = Array.isArray(value)
      ? JSON.parse(JSON.stringify(value))
      : [];

    // reset internal visual state so centering/mobile init will run for the new list
    this._centerInitDone = false;
    this._mobileInitDone = false;
    this.desktopTrackStyle = "transform: translateX(0px);";
    this.result = []; // clear stale UI immediately

    this._plans = incoming;
    //console.log('response --- '+ JSON.stringify(this._plans));

    // apply immediately instead of waiting for renderedCallback
    if (this._plans && this._plans.length) {
      try {
        this.applyPlans(this._plans);
      } catch (err) {
        console.error("applyPlans failed in setter:", err);
        // fallback: clear result so UI doesn't show partial state
        this.result = [];
      }
    } else {
      // no plans -> ensure clean UI
      this.result = [];
    }
  }

  // --- existing getters for tabs ---
  get monthlyTab() {
    return this.activeTab === "Monthly" ? "nav-link active" : "nav-link";
  }
  get months12Tab() {
    return this.activeTab === "12 Months" ? "nav-link active" : "nav-link";
  }
  get months24Tab() {
    return this.activeTab === "24 Months" ? "nav-link active" : "nav-link";
  }

  // viewport class getter (used in template)
  get desktopViewportClass() {
    let cls = "desktop-viewport";
    if (this.atStart) cls += " at-start";
    if (this.atEnd) cls += " at-end";
    if (this.isMobile) cls += " is-mobile";
    return cls;
  }

  /* ----------------------
       CENTERING / SET CENTER
       ---------------------- */
  setCenter(center1Based) {
    if (!Array.isArray(this.result) || this.result.length === 0) return;
    let centerIdx;
    if (center1Based === undefined || center1Based === null)
      centerIdx = Math.floor(this.result.length / 2);
    else if (center1Based >= 1 && center1Based <= this.result.length)
      centerIdx = center1Based - 1;
    else centerIdx = Number(center1Based);

    if (isNaN(centerIdx)) centerIdx = Math.floor(this.result.length / 2);
    if (centerIdx < 0) centerIdx = 0;
    if (centerIdx > this.result.length - 1) centerIdx = this.result.length - 1;

    this.currentIndex = centerIdx + 1;

    const defaultBorder =
      "slds-grid slds-wrap slds-grid_vertical-stretch gc-order-wizard-border";
    const defaultBtn = "gc-btn";

    const newResult = this.result.map((itm, i) => {
      const baseBorder = itm.SelectedBorder
        ? itm.SelectedBorder
        : defaultBorder;
      const baseBtn = itm.SelectedBtn ? itm.SelectedBtn : defaultBtn;

      const distance = Math.abs(i - centerIdx);

      // compute wrapper class: always add center-tile when centered
      let wrapperClass = baseBorder;
      if (itm.isMostPopular) wrapperClass += " center-tile";
      else if (distance === 1) wrapperClass += " adjacent-tile";
      else wrapperClass += " dim-tile";

      // button class
      let btnClass =
        distance === 0 ? baseBtn + " center-btn" : baseBtn + " small-btn";

      // set flags / classes on the item
      itm.ClassName = wrapperClass;
      itm.ButtonClass = btnClass;
      itm.isCenter = distance === 0;

      // dot classes for dot bar
      itm.btnClass = itm.isCenter ? "dot-button active" : "dot-button";
      itm.dotClass = itm.isCenter ? "dot active" : "dot";

      return itm;
    });

    // reactive assignment
    this.result = newResult;

    // compute translate so center tile is centered in viewport (existing math)
    const n = this.result.length;
    const totalWidth = n * this.tileWidth + Math.max(0, n - 1) * this.gap;
    const viewport = this.viewportWidth;

    const desiredCenter =
      centerIdx * (this.tileWidth + this.gap) + this.tileWidth / 2;
    let leftEdge = desiredCenter - viewport / 2;
    const maxLeft = Math.max(0, totalWidth - viewport);
    if (leftEdge < 0) leftEdge = 0;
    if (leftEdge > maxLeft) leftEdge = maxLeft;

    const shift = Math.round(leftEdge);

    // NEW: set flags to hide left/right fades when at extremes
    const tol = 1;
    this.atStart = leftEdge <= tol;
    this.atEnd = leftEdge >= maxLeft - tol;

    // On desktop we continue to use the transform (existing behavior).
    // On mobile we don't set transform; instead _initMobileIfNeeded() sets tileWidth and we scroll the viewport.
    if (!this.isMobile) {
      this.desktopTrackStyle = `transform: translateX(-${shift}px); transition: transform 360ms cubic-bezier(.2,.9,.2,1);`;
    } else {
      // ensure no transform on mobile (css will handle visual)
      this.desktopTrackStyle = "";

      // compute the intended scroll position for the slide
      const doScrollTo = (vpElem) => {
        if (!vpElem) return;
        const vw = vpElem.clientWidth || this.tileWidth || 1;
        const idx = Math.max(0, Math.min(centerIdx, this.result.length - 1));
        const targetLeft = idx * vw;
        try {
          vpElem.scrollTo({ left: targetLeft, behavior: "smooth" });
        } catch (e) {
          vpElem.scrollLeft = targetLeft;
        }
      };

      const vp = this.template.querySelector(".desktop-viewport");
      if (vp && (vp.clientWidth || this.tileWidth)) {
        doScrollTo(vp);
      } else {
        window.requestAnimationFrame(() => {
          setTimeout(() => {
            const vp2 = this.template.querySelector(".desktop-viewport");
            if (vp2) doScrollTo(vp2);
          }, 40);
        });
      }
    }
  }

  /* ----------------------
       DATA LOAD
       ---------------------- */
  async getPlans() {
    try {
      const apiPlans = await getPlans();
      this.applyPlans(apiPlans); // <— Normalize + render in one method
    } catch (error) {
      console.error(error);
    }
  }

  /* ----------------------
       TAB, COLLAPSE, CAROUSEL HANDLERS
       ---------------------- */
  handleTabClick(event) {
    try {
      let tab = event.target.dataset.tab;
      this.activeTab = tab;

      this.result.forEach((element) => {
        // Update cost and month text based on selected tab
        if (this.activeTab === "Monthly") {
          element.minCost = Number(element.Plan.UnitPrice) + 125;
          element.monthText = "1-month plan";
          element.showAvailabilityNote = false;
          this.hideNolock = false;
        } else if (this.activeTab === "12 Months") {
          element.minCost = Number(element.Plan.UnitPrice) * 12;
          element.monthText = "12-month plans";
          element.showAvailabilityNote = true;
          this.hideNolock = true;
        } else if (this.activeTab === "24 Months") {
          element.minCost = Number(element.Plan.UnitPrice) * 24;
          element.monthText = "24-month plans";
          element.showAvailabilityNote = true;
          this.hideNolock = true;
        }

        if (element.PlansInclusions != null) {
          // Normalize/mark show (you already do this elsewhere)
          element.PlansInclusions.forEach((item) => {
            item.show = item.Payment_Term_bric__c === this.activeTab;
          });

          // Rebuild inclusions using matchIndex counter so preview is first PREVIEW_COUNT matching items
          let seenMatching = 0;
          element.inclusions = element.PlansInclusions.map((pi, rawIdx) => {
            const displayText = (
              pi.Inclusion_bric__c ||
              pi.Name ||
              pi.Label ||
              ""
            ).toString();
            const defaultShow = !!pi.show;
            const matchIndex = defaultShow ? seenMatching++ : -1;
            const visible = defaultShow && matchIndex < this.PREVIEW_COUNT;

            return {
              key: pi.Id || `${element.Id || "plan"}-inc-${rawIdx}`,
              iconUrl: this.pickInclusionIcon(displayText),
              text: displayText,
              defaultShow: defaultShow,
              index: rawIdx,
              matchIndex: matchIndex,
              visible: visible
            };
          });
          const matchingCount = (element.inclusions || []).filter(
            (inc) => !!inc.defaultShow
          ).length;
          element.showInclusionToggle = matchingCount > this.PREVIEW_COUNT;
        } else {
          element.inclusions = [];
          element.showInclusionToggle = false;
        }
      });

      if (this.currentIndex) this.setCenter(this.currentIndex);
    } catch (error) {
      console.error("Error in handleTabClick:", error);
    }
  }

  handleToggleCollapse(event) {
    const button = event.currentTarget;
    const targetId = button.dataset.target;
    const target = this.template.querySelector(`[data-id="${targetId}"]`);
    if (!target) return;

    const isCurrentlyExpanded = target.classList.contains("show");

    target.classList.toggle("show", !isCurrentlyExpanded);
    target.classList.toggle("collapse", isCurrentlyExpanded);

    this.result = this.result.map((item) => {
      if (item.dataIdPlanDetails === targetId) {
        const newExpanded = !isCurrentlyExpanded;
        const newInclusions = (item.inclusions || []).map((inc) => {
          // When expanded: show all items that are defaultShow
          // When collapsed: show only the first PREVIEW_COUNT matching items (matchIndex 0..PREVIEW_COUNT-1)
          const visible =
            inc.defaultShow &&
            (newExpanded
              ? true
              : typeof inc.matchIndex === "number" && inc.matchIndex >= 0
                ? inc.matchIndex < this.PREVIEW_COUNT
                : false);
          return {
            ...inc,
            visible: visible
          };
        });

        return {
          ...item,
          isExpanded: newExpanded,
          inclusions: newInclusions
        };
      }
      return item;
    });
  }

  handleCarousel(event) {
    let elWithAttr = event.target;
    if (!elWithAttr) return;

    if (!elWithAttr.getAttribute || !elWithAttr.getAttribute("data-slideto")) {
      elWithAttr =
        (elWithAttr.closest && elWithAttr.closest("[data-slideto]")) ||
        event.currentTarget;
    }

    const slideto = elWithAttr
      ? elWithAttr.dataset
        ? elWithAttr.dataset.slideto
        : elWithAttr.getAttribute("data-slideto")
      : null;
    if (!slideto) {
      console.warn(
        "handleCarousel: no data-slideto found on target or ancestors",
        event.target,
        elWithAttr
      );
      return;
    }

    const foundIndex = this.result.findIndex(
      (it) => it.dataIdCarousel === slideto
    );
    if (foundIndex >= 0) {
      this.setCenter(foundIndex + 1);
    } else {
      console.warn(
        "handleCarousel: slideto value not found in this.result",
        slideto
      );
    }

    this.result.forEach((el) => {
      el.carousel =
        el.dataIdCarousel === slideto
          ? "carousel-item active"
          : "carousel-item";
    });

    this.result = [...this.result];
  }

  prev() {
    if (!this.result.length) return;
    let newIndex = this.currentIndex - 1;
    if (newIndex < 1) newIndex = this.result.length;
    this.setCenter(newIndex);
  }

  next() {
    if (!this.result.length) return;
    let newIndex = this.currentIndex + 1;
    if (newIndex > this.result.length) newIndex = 1;
    this.setCenter(newIndex);
  }

  handleNavToOurPlanPage() {
    try {
      const pageref = {
        type: "standard__webPage",
        attributes: {
          url: "/giga/s/our-plans"
        }
      };
      this[NavigationMixin.Navigate](pageref);
    } catch (err) {
      console.error("Navigation error", err);
      // eslint-disable-next-line no-alert
      alert("Navigation error: " + (err?.message || err));
    }
  }

  /* ----------------------
       RENDER / MOBILE SETUP
       ---------------------- */
  renderedCallback() {
    // mobile init first (ensures tileWidth/viewportWidth are correct before centering)
    if (!this._mobileInitDone) {
      this._initMobileIfNeeded();
      this._mobileInitDone = true;
      // re-check on resize
      window.addEventListener("resize", () => {
        this._mobileInitDone = false;
        setTimeout(() => this._initMobileIfNeeded(), 50);
      });
    }

    // original center init (only once)
    if (
      !this._centerInitDone &&
      Array.isArray(this.result) &&
      this.result.length
    ) {
      if (!this.currentIndex) this.currentIndex = 2;
      this.setCenter(this.currentIndex);
      this._centerInitDone = true;
    }

    // existing speed toggle DOM tweaks (unchanged)
    this.template
      .querySelectorAll(".speed-toggle-fixed")
      .forEach((container) => {
        const checkbox = container.querySelector(".speed-checkbox");
        const morningLabel = container.querySelector(".speed-label.left");
        const eveningLabel = container.querySelector(".speed-label.right");

        if (morningLabel && eveningLabel) {
          morningLabel.classList.remove("bold");
          eveningLabel.classList.remove("bold");

          if (checkbox?.checked) {
            eveningLabel.classList.add("bold");
          } else {
            morningLabel.classList.add("bold");
          }
        }
      });

    // IMPORTANT: add pointer listeners to toggles to stop propagation
    this._addToggleListeners();
  }

  disconnectedCallback() {
    // cleanup listeners to avoid leaks
    this._removeToggleListeners();
    // also remove window listener we added in renderedCallback
    try {
      window.removeEventListener("resize", () => {
        /* noop: cannot remove anonymous */
      });
    } catch (e) {
      /* ignore */
    }
  }

  /* ----------------------
       SPEED TOGGLE HANDLERS
       ---------------------- */
  handleSpeedToggle(event) {
    const idx = parseInt(event.target.dataset.index, 10);
    if (Number.isNaN(idx)) return;

    const isEvening = event.target.checked; // true = Evening, false = Morning

    // immediate DOM label updates (unchanged behavior)
    const container = event.target.closest(".speed-toggle-fixed");
    if (container) {
      const morningLabel = container.querySelector(".speed-label.left");
      const eveningLabel = container.querySelector(".speed-label.right");
      if (morningLabel) morningLabel.classList.remove("bold");
      if (eveningLabel) eveningLabel.classList.remove("bold");
      if (isEvening) {
        if (eveningLabel) eveningLabel.classList.add("bold");
      } else {
        if (morningLabel) morningLabel.classList.add("bold");
      }
    }

    // Temporarily ignore mobile scrolls to avoid onMobileScroll/setCenter being called.
    // Keep a slightly longer window so any browser scroll jank is ignored.
    if (this.isMobile) {
      this._ignoreMobileScrollUntil = Date.now() + 350;
    }

    // Save current scroll position / index so we can restore after update
    let vp;
    let savedScrollLeft = null;
    if (this.isMobile) {
      vp = this.template.querySelector(".desktop-viewport");
      if (vp) savedScrollLeft = vp.scrollLeft;
    }

    // update model/UI values (existing behavior)
    this.updateSpeedValues(idx, isEvening);

    // On mobile, schedule a short restore of the scroll to keep the same slide visible.
    // We use requestAnimationFrame + small timeout to wait for layout/paint to finish.
    if (this.isMobile && vp) {
      // compute target left based on currentIndex (1-based)
      const targetIdx = Math.max(
        0,
        Math.min(
          (this.currentIndex || 1) - 1,
          Math.max(0, this.result.length - 1)
        )
      );
      const restoreLeft = targetIdx * (vp.clientWidth || this.tileWidth || 1);

      // cancel any previous restore timer if you add one (optional)
      if (this._mobileRestoreTimer) {
        clearTimeout(this._mobileRestoreTimer);
        this._mobileRestoreTimer = null;
      }

      // schedule restore after paint
      this._mobileRestoreTimer = window.requestAnimationFrame(() => {
        // tiny delay to allow DOM to settle (40ms is conservative)
        setTimeout(() => {
          try {
            // Use smooth behavior only if scroll moved a lot — otherwise set directly for stability
            const diff = Math.abs((vp.scrollLeft || 0) - restoreLeft);
            if (diff > 2) {
              // short instant scroll (avoid large smooth jumps)
              try {
                vp.scrollTo({ left: restoreLeft, behavior: "instant" });
              } catch (e) {
                vp.scrollLeft = restoreLeft;
              }
            } else {
              // no-op or minimal correction
              try {
                vp.scrollTo({ left: restoreLeft, behavior: "instant" });
              } catch (e) {
                vp.scrollLeft = restoreLeft;
              }
            }
          } catch (err) {
            // fallback: set scrollLeft
            try {
              vp.scrollLeft = restoreLeft;
            } catch (e) {
              /* ignore */
            }
          } finally {
            // clear timer ref
            this._mobileRestoreTimer = null;
          }
        }, 35);
      });
    }
  }

  updateSpeedValues(idx, isEvening) {
    // Guard: check data integrity
    if (!this.result || idx < 0 || idx >= this.result.length) return;

    // DESKTOP behavior: unchanged (triggers full re-render for desktop)
    if (!this.isMobile) {
      const updatedResults = [...this.result];
      const tile = { ...updatedResults[idx] };
      const p = tile.Plan && tile.Plan.Product2 ? tile.Plan.Product2 : {};

      tile.isEvening = !!isEvening;

      if (isEvening) {
        tile.displayDownload =
          p.Evening_Download_Limit__c !== undefined &&
          p.Evening_Download_Limit__c !== null
            ? p.Evening_Download_Limit__c
            : p.Download_Limit__c || "";
        tile.displayUpload =
          p.Evening_Upload_Limit__c !== undefined &&
          p.Evening_Upload_Limit__c !== null
            ? p.Evening_Upload_Limit__c
            : p.Upload_Limit__c || "";
        tile.tileClass = (tile.tileClass || "").replace("morning", "evening");
      } else {
        tile.displayDownload =
          p.Download_Limit__c !== undefined && p.Download_Limit__c !== null
            ? p.Download_Limit__c
            : "";
        tile.displayUpload =
          p.Upload_Limit__c !== undefined && p.Upload_Limit__c !== null
            ? p.Upload_Limit__c
            : "";
        tile.tileClass = (tile.tileClass || "").replace("evening", "morning");
      }

      updatedResults[idx] = tile;
      this.result = updatedResults; // triggers desktop re-render (intentional)
      return;
    }

    // MOBILE behavior: update DOM nodes directly to avoid re-render / flicker
    try {
      const tileModel = this.result[idx];
      if (!tileModel) return;
      const p =
        tileModel.Plan && tileModel.Plan.Product2
          ? tileModel.Plan.Product2
          : {};

      // update model lightly so data stays consistent for future operations
      tileModel.isEvening = !!isEvening;
      tileModel.displayDownload = isEvening
        ? (p.Evening_Download_Limit__c ?? p.Download_Limit__c ?? "")
        : (p.Download_Limit__c ?? "");
      tileModel.displayUpload = isEvening
        ? (p.Evening_Upload_Limit__c ?? p.Upload_Limit__c ?? "")
        : (p.Upload_Limit__c ?? "");

      // Find the tile element in the shadow DOM. Your template must include data-index on the tile root:
      // <div class="desktop-tile" data-index={index} ...>
      const tileEl = this.template.querySelector(
        `.desktop-tile[data-index="${idx}"]`
      );
      if (tileEl) {
        // update the numeric display elements directly
        const leftNum = tileEl.querySelector(".speed-left .speed-num");
        const rightNum = tileEl.querySelector(".speed-right .speed-num");
        if (leftNum)
          leftNum.textContent = String(tileModel.displayDownload ?? "");
        if (rightNum)
          rightNum.textContent = String(tileModel.displayUpload ?? "");

        // update checkbox state (use toggleId where possible)
        const checkbox =
          tileEl.querySelector(`input[data-index="${idx}"]`) ||
          tileEl.querySelector(`#${tileModel.toggleId}`);
        if (checkbox) checkbox.checked = !!isEvening;

        // update label bold class locally (so you keep the same immediate behavior)
        const morningLabel = tileEl.querySelector(".speed-label.left");
        const eveningLabel = tileEl.querySelector(".speed-label.right");
        if (morningLabel) morningLabel.classList.toggle("bold", !isEvening);
        if (eveningLabel) eveningLabel.classList.toggle("bold", !!isEvening);
      }

      // Prevent any tiny browser jank scrolling — restore viewport immediately.
      const vp = this.template.querySelector(".desktop-viewport");
      if (vp) {
        const targetIdx = Math.max(
          0,
          Math.min(
            (this.currentIndex || 1) - 1,
            Math.max(0, this.result.length - 1)
          )
        );
        const restoreLeft = targetIdx * (vp.clientWidth || this.tileWidth || 1);
        // instant jump to avoid smooth animation flashes; modern browsers may ignore 'instant' so fallback to setting scrollLeft
        try {
          vp.scrollTo({ left: restoreLeft, behavior: "auto" });
        } catch (e) {
          vp.scrollLeft = restoreLeft;
        }
      }

      // do NOT reassign this.result (keep same array) — avoids LWC re-render of siblings
      // but we kept model updated above so future code sees correct values
    } catch (err) {
      // fallback: if anything fails, use safe full-array replace (still better than crashing)
      console.error("updateSpeedValues mobile fallback", err);
      const updatedResults = [...this.result];
      const tile = { ...updatedResults[idx] };
      const p = tile.Plan && tile.Plan.Product2 ? tile.Plan.Product2 : {};

      tile.isEvening = !!isEvening;
      tile.displayDownload = isEvening
        ? (p.Evening_Download_Limit__c ?? p.Download_Limit__c)
        : (p.Download_Limit__c ?? "");
      tile.displayUpload = isEvening
        ? (p.Evening_Upload_Limit__c ?? p.Upload_Limit__c)
        : (p.Upload_Limit__c ?? "");

      updatedResults[idx] = tile;
      this.result = updatedResults;
    }
  }

  pickInclusionIcon(text) {
    if (!text) return IconInstall;
    const t = text.toString().toLowerCase();

    if (t.includes("business") || t.includes("recommended"))
      return SmallBuissnessPlan;
    if (t.includes("home") && t.includes("plan")) return PlanHomeIcon;
    if (t.includes("unlimited")) return IconUnlimited;
    if (t.includes("install") || t.includes("$")) return IconInstall;
    if (t.includes("router") || t.includes("wifi")) return IconRouter;
    if (t.includes("fiber") || t.includes("fibre")) return IconFiber;
    if (t.includes("individual")) return IndividualPlan;
    if (t.includes("termination")) return TerminationFee;
    if (
      t.includes("cancel") ||
      t.includes("cancellation") ||
      t.includes("notice")
    )
      return IconCancellation;

    return IconInstall;
  }

  /* ----------------------
       MOBILE INIT & SCROLL
       ---------------------- */
  _initMobileIfNeeded() {
    const bp = 767;
    const small = window.innerWidth <= bp;
    if (!small) {
      this.isMobile = false;
      this.tileWidth = 415;
      this.viewportWidth = 980;

      const vpOld =
        this.template &&
        this.template.querySelector &&
        this.template.querySelector(".desktop-viewport");
      if (vpOld && this._onMobileScrollBound)
        vpOld.removeEventListener("scroll", this._onMobileScrollBound);
      return;
    }

    this.isMobile = true;

    const vp = this.template.querySelector(".desktop-viewport");
    const width = vp && vp.clientWidth ? vp.clientWidth : window.innerWidth;

    this.tileWidth = width;
    this.viewportWidth = width;

    const track = this.template.querySelector(".desktop-track");
    if (track) track.style.touchAction = "pan-y";

    if (vp) {
      if (!this._onMobileScrollBound) {
        this._onMobileScrollBound = this.onMobileScroll.bind(this);
      }
      vp.addEventListener("scroll", this._onMobileScrollBound, {
        passive: true
      });
    }

    this.currentIndex = Math.min(
      this.currentIndex || 1,
      Math.max(1, this.result.length || 1)
    );
    this.setCenter(this.currentIndex);
  }

  onMobileScroll() {
    if (!this.isMobile) return;

    // If we've recently interacted with a toggle (or other UI) that may cause incidental
    // small scrolls, ignore scroll handler until the ignore window expires.
    if (Date.now() < (this._ignoreMobileScrollUntil || 0)) {
      return;
    }

    const vp = this.template.querySelector(".desktop-viewport");
    if (!vp) return;
    if (this._mobileScrollTimer) clearTimeout(this._mobileScrollTimer);
    this._mobileScrollTimer = setTimeout(() => {
      const vpW = vp.clientWidth || this.tileWidth || 1;
      const idx = Math.round(vp.scrollLeft / vpW);
      const clamped = Math.max(0, Math.min(idx, this.result.length - 1));
      if (clamped + 1 !== this.currentIndex) {
        this.setCenter(clamped + 1);
      }
    }, this._mobileScrollDebounceMs);
  }

  /* ----------------------
       POINTER / SWIPE HANDLERS
       (unchanged, still used for swipes)
       ---------------------- */
  onPointerDown(e) {
    if (!this.isMobile) return;
    if (e.isPrimary === false) return;
    if (e.pointerType === "mouse" && e.button !== 0) return;

    // If event started on an interactive control, ignore here.
    const interactive =
      e.target &&
      e.target.closest &&
      e.target.closest(
        "button, input, label, select, textarea, a, .speed-toggle-fixed"
      );
    if (interactive) {
      return;
    }

    try {
      e.preventDefault();
    } catch (err) {
      /* ignore */
    }

    this._mobilePointerId = e.pointerId;
    this._mobileStartX = e.clientX;
    this._mobileDragging = true;
    const el = this.template.querySelector(".desktop-viewport");
    if (el && el.setPointerCapture) {
      try {
        el.setPointerCapture(e.pointerId);
      } catch (err) {}
    }
  }

  onPointerMove(e) {
    if (
      !this.isMobile ||
      !this._mobileDragging ||
      e.pointerId !== this._mobilePointerId
    )
      return;
  }

  onPointerUp(e) {
    if (!this.isMobile) return;

    const interactive =
      e.target &&
      e.target.closest &&
      e.target.closest(
        "button, input, label, select, textarea, a, .speed-toggle-fixed"
      );
    if (interactive) {
      this._mobileDragging = false;
      this._mobilePointerId = null;
      return;
    }

    if (!this._mobileDragging || e.pointerId !== this._mobilePointerId) {
      this._mobileDragging = false;
      this._mobilePointerId = null;
      return;
    }

    this._mobileDragging = false;
    const deltaX = e.clientX - this._mobileStartX;

    if (deltaX > this._mobileThreshold) {
      this.prev();
    } else if (deltaX < -this._mobileThreshold) {
      this.next();
    } else {
      const clicked =
        e.target && e.target.closest && e.target.closest(".desktop-tile");
      if (clicked) {
        const idx = parseInt(clicked.dataset.index, 10);
        if (!Number.isNaN(idx)) this.setCenter(idx + 1);
      }
    }

    const el = this.template.querySelector(".desktop-viewport");
    if (el && el.releasePointerCapture) {
      try {
        el.releasePointerCapture(e.pointerId);
      } catch (err) {}
    }
    this._mobilePointerId = null;
  }
  onPointerCancel(e) {
    this.onPointerUp(e);
  }

  /* ----------------------
       NEW: toggle pointer stopper helpers
       ---------------------- */

  // Adds pointer listeners to each .speed-toggle-fixed element so pointer events stop propagating.
  _addToggleListeners() {
    const toggles = this.template.querySelectorAll(".speed-toggle-fixed");
    toggles.forEach((el) => {
      // store handler reference on element so we can remove later
      if (!el.__gc_toggleHandler) {
        el.__gc_toggleHandler = function stopAndAllow(e) {
          // Stop propagation so the viewport won't treat this pointer as a swipe/tap.
          e.stopPropagation();
          // Allow default so the control behaves normally (don't preventDefault here).
        };
        el.addEventListener("pointerdown", el.__gc_toggleHandler, {
          passive: false
        });
        el.addEventListener("pointerup", el.__gc_toggleHandler, {
          passive: false
        });
        // also listen for pointercancel to be safe
        el.addEventListener("pointercancel", el.__gc_toggleHandler, {
          passive: false
        });
      }
    });
  }

  // Remove listeners we added (cleanup)
  _removeToggleListeners() {
    const toggles = this.template
      ? this.template.querySelectorAll(".speed-toggle-fixed")
      : [];
    toggles.forEach((el) => {
      if (el.__gc_toggleHandler) {
        el.removeEventListener("pointerdown", el.__gc_toggleHandler);
        el.removeEventListener("pointerup", el.__gc_toggleHandler);
        el.removeEventListener("pointercancel", el.__gc_toggleHandler);
        try {
          delete el.__gc_toggleHandler;
        } catch (e) {
          el.__gc_toggleHandler = null;
        }
      }
    });
  }
  disconnectedCallback() {
    // cleanup listeners to avoid leaks
    this._removeToggleListeners();

    if (this._mobileRestoreTimer) {
      try {
        cancelAnimationFrame(this._mobileRestoreTimer);
      } catch (e) {
        /* ignore */
      }
      this._mobileRestoreTimer = null;
    }

    try {
      window.removeEventListener("resize", () => {
        /* noop: cannot remove anonymous */
      });
    } catch (e) {
      /* ignore */
    }
  }

  // convenience getter used in template
  get isServiceable() {
    return !!(this._lead && this._lead.Serviceable);
  }

  /**
   * Called when user clicks "Select" on a serviceable lead.
   * Dispatches 'planselected' with the same value string Aura used.
   */
  /**
   * Called when user clicks "Select" (wired in template to onclick).
   * Builds the same payload as the Aura helper.upsertLead, then dispatches a DOM event
   * named 'cmpEvent' with detail { payload, dml } so Aura parent can handle it.
   */
  // inside your GcPlans class
  handleSelectPlan(event) {
    // find the button element that has the value (handles clicks on inner spans/icons)
    const btn =
      event.currentTarget && event.currentTarget.tagName === "BUTTON"
        ? event.currentTarget
        : event.target && event.target.closest
          ? event.target.closest("button")
          : null;

    if (!btn) {
      console.warn(
        "handleSelectPlan: button element not found for event",
        event
      );
      return;
    }

    // value format expected: product2Id:term:planId
    const raw = btn.value || "";
    const parts = raw.split(":");
    const selectedPlan = parts[0] || "";
    const term = this.activeTab;
    const priceBookEntry = parts[2] || "";

    // clone existing lead to avoid mutating parent-provided object
    const payload = this._lead ? JSON.parse(JSON.stringify(this._lead)) : {};

    // determine DML type same as Aura helper
    const dml = payload && payload.Id ? "UPDATE" : "INSERT";

    // create / set PlanSelected
    payload.PlanSelected = payload.PlanSelected || {};
    payload.PlanSelected.Id = priceBookEntry;
    payload.PlanSelected.TECH_PriceBookEntryId_bric__c = priceBookEntry;
    payload.PlanSelected.Product_bric__c = selectedPlan;
    payload.PlanSelected.Quantity_bric__c = 1;

    payload.Status = "Plan Selected";
    payload.Term = term;

    // match Aura helper: clear Serviceable before sending to server
    payload.Serviceable = null;

    // Optional: promo code from cookie if you want to replicate Aura getCookie behaviour.
    // If you have a cookie helper in LWC you can set payload.PromoCodeReferral here.
    // e.g. payload.PromoCodeReferral = this.getCookie && this.getCookie('voucher');

    // Build detail exactly as your Aura event carried
    const detail = {
      payload: payload,
      dml: dml
    };

    // Dispatch DOM event named 'cmpEvent' (Aura listens via oncmpEvent)
    this.dispatchEvent(
      new CustomEvent("cmpEvent", {
        detail: detail,
        bubbles: true,
        composed: true
      })
    );

    // debug
    // console.log('LWC fired cmpEvent', detail);
  }

  /**
   * Update item-level flags so the template can bind only to properties (no function calls).
   * Called after getPlans() and whenever lead changes.
   */
  updateSelectionFlags() {
    if (!Array.isArray(this.result) || !this.result.length) return;

    const selectedProduct =
      this._lead &&
      this._lead.PlanSelected &&
      this._lead.PlanSelected.Product_bric__c;
    const leadTerm = this._lead && this._lead.Term ? this._lead.Term : "";

    const updated = this.result.map((item) => {
      const product2Id = item?.Plan?.Product2Id;
      const isSelected = !!(
        selectedProduct &&
        product2Id &&
        selectedProduct === product2Id
      );
      const selectValue = `${product2Id || ""}:${leadTerm}:${item?.Plan?.Id || ""}`;
      const availabilityClass =
        item?.Plan?.Product2 &&
        item.Plan.Product2.Home_Page_Pre_Selected_bric__c
          ? "gc-btn-selected"
          : "gc-btn";

      return {
        ...item,
        isSelected: isSelected,
        selectValue: selectValue,
        availabilityButtonClass: availabilityClass
      };
    });

    // reassign so LWC will re-render template with updated flags
    this.result = updated;
  }

  normalizePlans(rawPlans) {
    if (!Array.isArray(rawPlans)) return [];

    let num = 1;

    const processed = rawPlans.map((element, i) => {
      // ----------- everything copied AS-IS from your logic -----------

      if (!element.Plan.Product2.Desktop_URL_bric__c) {
        element.bannerDesktop = `background-image:URL('${imgUnavailable}');`;
        element.bannerMobile = `background-image:URL('${imgUnavailable}');`;
      } else {
        element.bannerDesktop = `background-image:URL('${element.Plan.Product2.Desktop_URL_bric__c}');`;
        element.bannerMobile = `background-image:URL('${element.Plan.Product2.Mobile_Image_bric__c}');`;
      }

      element.toggleId = "speedToggle" + i;
      element.isEvening = false;
      element.isExpanded = false;

      const p = element.Plan.Product2;
      const name = (p.Display_Name_Bric__c || "").toLowerCase();
      element.isMostPopular = p.Is_Most_Popular__c;

      if (
        name.includes("2gb") ||
        name.includes("2 gb") ||
        name.includes("fast 2gb")
      ) {
        element.planIcon = Plan2gbFrame;
        element.hideToggle = true;
      } else if (
        name.includes("1gb") ||
        name.includes("1 gb") ||
        name.includes("fast 1gb")
      ) {
        element.planIcon = Plan1gbFrame;
        element.hideToggle = false;
      } else if (name.includes("super") && name.includes("500")) {
        element.planIcon = Plan500and100mbFrame;
        element.hideToggle = false;
      } else if (name.includes("fast") && name.includes("100")) {
        element.planIcon = Fast500;
        element.hideToggle = false;
      }

      element.displayDownload = p?.Download_Limit__c || "";
      element.displayUpload = p?.Upload_Limit__c || "";

      element.tileClass =
        i === 1 ? "center-tile morning" : "gc-order-wizard-border";
      element.dataIdPlanDetails = "planDetails" + num;
      element.dataIdmPlanDetails = "m-planDetails" + num;
      element.dataIdCarousel = "carousel" + num;
      element.minCost = 0;

      if (this.activeTab === "Monthly") {
        element.minCost = Number(element.Plan.UnitPrice) + 125;
        element.monthText = "1-month plan";
        element.showAvailabilityNote = false;
      } else if (this.activeTab === "12 Months") {
        element.minCost = Number(element.Plan.UnitPrice) * 12;
        element.monthText = "12-month plans";
        element.showAvailabilityNote = true;
      } else if (this.activeTab === "24 Months") {
        element.minCost = Number(element.Plan.UnitPrice) * 24;
        element.monthText = "24-month plans";
        element.showAvailabilityNote = true;
      }

      element.carousel = i === 0 ? "carousel-item active" : "carousel-item";
      element.IndicatorClass = i === 0 ? "active" : "";
      element.AriaLabel = "Slide " + (i + 1);

      element.SelectedBorder =
        i === 1
          ? "slds-grid slds-wrap slds-grid_vertical-stretch gc-order-wizard-border-selected"
          : "slds-grid slds-wrap slds-grid_vertical-stretch gc-order-wizard-border";

      element.SelectedBtn = i === 1 ? "gc-btn-selected" : "gc-btn";

      element.isSelected = !!(
        this._lead?.PlanSelected?.Product_bric__c &&
        this._lead.PlanSelected.Product_bric__c === element.Plan.Product2Id
      );

      element.selectValue = `${element.Plan.Product2Id || ""}:${this._lead?.Term ?? ""}:${element.Plan.Id || ""}`;

      element.availabilityButtonClass = element.Plan?.Product2
        ?.Home_Page_Pre_Selected_bric__c
        ? "gc-btn-selected"
        : "gc-btn";

      if (element.PlansInclusions && Array.isArray(element.PlansInclusions)) {
        element.PlansInclusions.forEach((pi) => {
          pi.show = pi.Payment_Term_bric__c === this.activeTab;
        });

        let seenMatching = 0;

        element.inclusions = element.PlansInclusions.map((pi, rawIdx) => {
          const displayText = (
            pi.Inclusion_bric__c ||
            pi.Name ||
            pi.Label ||
            ""
          ).toString();
          const defaultShow = !!pi.show;
          const matchIndex = defaultShow ? seenMatching++ : -1;

          return {
            key: pi.Id || `${element.Id || "plan"}-inc-${rawIdx}`,
            iconUrl: this.pickInclusionIcon(displayText),
            text: displayText,
            defaultShow: defaultShow,
            index: rawIdx,
            matchIndex: matchIndex,
            visible: defaultShow && matchIndex < this.PREVIEW_COUNT
          };
        });

        const matchingCount = element.inclusions.filter(
          (i) => i.defaultShow
        ).length;
        element.showInclusionToggle = matchingCount > this.PREVIEW_COUNT;
      } else {
        element.inclusions = [];
        element.showInclusionToggle = false;
      }

      num++;
      return element;
    });

    return processed;
  }

  applyPlans(planList) {
    if (!Array.isArray(planList)) {
      this.result = [];
      return;
    }

    // normalize
    const normalized = this.normalizePlans(planList);

    // set result
    this.result = normalized;

    // update flags
    this.updateSelectionFlags();

    // center tiles
    const mpIdx = this.result.findIndex((r) => r.isMostPopular);
    if (mpIdx >= 0) this.setCenter(mpIdx + 1);
    else if (this.result.length >= 2) this.setCenter(2);
    else this.setCenter(1);
  }
}
