function addResizeHandler(resizeContainer, elementsToResize, direction) {
    if (!resizeContainer) {
        return;
    }
    const resizeData = {
        tracking: false,
        startWidth: null,
        startCursorScreenX: null,
    };

    const handler = document.createElement("div");
    handler.classList.add("resize-handler");
    if (direction === "left") {
        resizeContainer.appendChild(handler);
    } else {
        resizeContainer.insertBefore(
            handler,
            resizeContainer.firstElementChild,
        );
    }

    handler.addEventListener("mousedown", (event) => {
        if (event.button !== 0) {
            return;
        }

        event.preventDefault();
        event.stopPropagation();

        resizeData.startWidth = parseFloat(
            getComputedStyle(resizeContainer).getPropertyValue("width"),
        );
        resizeData.startCursorScreenX = event.screenX;
        resizeData.tracking = true;
        resizeData.handler = handler;
        handler.classList.add("active");
        console.log("resize started");
    });

    window.addEventListener("mousemove", (event) => {
        if (!resizeData.tracking) {
            return;
        }
        const cursorScreenXDelta =
            event.screenX - resizeData.startCursorScreenX;
        const newWidth =
            resizeData.startWidth +
            cursorScreenXDelta * (direction === "left" ? 1 : -1);

        elementsToResize.forEach((t) => (t.style.width = `${newWidth}px`));
    });

    window.addEventListener("mouseup", () => {
        if (!resizeData.tracking) {
            return;
        }
        resizeData.tracking = false;

        handler.classList.remove("active");
    });
}

function setUpResizeContainers() {
    const container = document.body.querySelector("pb-page");
    // Setup for left
    const [beforeTop, before] = container.querySelectorAll(
        ".fixed-layout > .before-top,.fixed-layout > .before",
    );

    addResizeHandler(before, [beforeTop, before], "left");

    const [afterTop, after] = container.querySelectorAll(".fixed-layout > .after-top,.fixed-layout > .after");
    addResizeHandler(after, [afterTop, after], "right");
}

document.addEventListener("DOMContentLoaded", function () {
    // hide/expand the before and after sidebars
    const asideToggles = document.querySelectorAll(".aside-toggle");
    asideToggles.forEach((toggle) => {
        const mobileToggle = toggle.classList.contains('mobile');
        const hiddenClass = mobileToggle ? 'hidden-mobile' : 'hidden';
        toggle.addEventListener("click", function () {
            toggle.classList.toggle('open');
            const target = this.dataset.toggle;
            const targetElement = document.querySelector(target);
            targetElement.classList.toggle(hiddenClass);
            if (mobileToggle) {
                document.querySelector('.fixed-layout > main').classList.toggle(hiddenClass);
            }
            const topPanel = this.closest(".fixed-layout > .before-top,.fixed-layout > .after-top");
            if (topPanel) {
                topPanel.classList.toggle(hiddenClass);
            }
        });
    });

    // hide/expand mobile menu
    const mobileMenuToggle = document.querySelector(".mobile.trigger button");
    if (mobileMenuToggle) {
        mobileMenuToggle.addEventListener("click", function () {
            const target = this.dataset.toggle;
            const targetElement = document.querySelector(target);
            targetElement.classList.toggle("hidden");
        });
    }

    // Hide mobile asides on pb-refresh event
    const mobileAsideToggles = document.querySelectorAll(".aside-toggle.mobile");
    if (mobileAsideToggles.length > 0) {
        document.addEventListener("pb-refresh", function () {
            mobileAsideToggles.forEach((toggle) => {
                const target = toggle.dataset.toggle;
                if (target) {
                    const targetElement = document.querySelector(target);
                    if (targetElement && !targetElement.classList.contains('hidden-mobile')) {
                        targetElement.classList.add('hidden-mobile');
                        toggle.classList.remove('open');
                    }
                    const topPanel = toggle.closest(".fixed-layout > .before-top,.fixed-layout > .after-top");
                    if (topPanel && !topPanel.classList.contains('hidden-mobile')) {
                        topPanel.classList.add('hidden-mobile');
                    }
                    const main = document.querySelector('.fixed-layout > main');
                    if (main && !main.classList.contains('hidden-mobile')) {
                        main.classList.add('hidden-mobile');
                    }
                }
            });
        });
    }

    setUpResizeContainers();
});

document.addEventListener('click', (e) => {
    const summary = e.target.closest('summary');
    if (summary) {
        // If clicking on a summary, close other details but keep current one open
        const currentDetails = e.target.closest('details');
        const allDetails = document.querySelectorAll('details.dropdown, details.dropdown-button');
        allDetails.forEach(details => {
            if (details !== currentDetails) {
                details.removeAttribute('open');
            }
        });
    } else if (!e.target.closest('details')) {
        // If clicking outside any details element, close all details
        const allDetails = document.querySelectorAll('details[open].dropdown, details[open].dropdown-button');
        allDetails.forEach(details => {
            details.removeAttribute('open');
        });
    }
});