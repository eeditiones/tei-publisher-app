/* ------------------------------------- */
/* Review occurrences in other documents */
/* ------------------------------------- */

let currentReview = 0;
let reviewDocs = [];
let reviewData = {};
let reviewDialog;
let reviewDocLink;

document.addEventListener('DOMContentLoaded', () => {
    reviewDialog = document.getElementById('d-review');
    reviewDialog.querySelector('.next').addEventListener('click', () => {
        if (currentReview < reviewDocs.length - 1) {
            currentReview += 1;
            _reviewNext();
        }
    });

    reviewDialog.querySelector('.previous').addEventListener('click', () => {
        if (currentReview > -1) {
            currentReview -= 1;
            _reviewNext();
        }
    });

    // clicking on link to document opens annotation editor on this document in new tab
    // annotations for the document are first stored to local storage, so the editor
    // will pick them up
    reviewDocLink = reviewDialog.querySelector('h3 a');
    reviewDocLink.addEventListener('click', (ev) => {
        ev.preventDefault();
        const href = reviewDocLink.href;
        const doc = reviewDocs.splice(currentReview, 1);
        updateLocalStorage(doc, reviewData[doc[0]]);
        if (reviewDocs.length === 0) {
            reviewDialog.close();
        } else {
            if (currentReview === reviewDocs.length) {
                currentReview = 0;
            }
            _reviewNext();
        }
        window.open(href, '_blank');
    });

    const saveCurrentBtn = reviewDialog.querySelector('.save-current');
    saveCurrentBtn.addEventListener('click', () => {
        _saveCurrent();
    });

    const closeBtn = reviewDialog.querySelector('.close');
    closeBtn.addEventListener('click', () => {
        document.getElementById('discard-review-dialog').confirm()
			.then(() => reviewDialog.close());
    });
});

/**
 * Start a review
 * 
 * @param {Array} docs list of documents to review
 * @param {Object} data object mapping document paths to annotation list
 */
function review(docs, data) {
    currentReview = 0;
    reviewDocs = docs;
    reviewOffsets = data;
    reviewData = {};
    _reviewNext();
}

/**
 * Review the next document
 * 
 */
function _reviewNext() {
    reviewDialog.querySelector('.previous').disabled = currentReview === 0;
    reviewDialog.querySelector('.next').disabled = currentReview === reviewDocs.length - 1;

    const doc = reviewDocs[currentReview];
    if (!doc) {
        return;
    }
    const counts = {
        total: reviewDocs.length,
        count: currentReview + 1
    };
    reviewDialog.querySelector('h3 [key="annotations.doc-count"]').options = counts;
    const count = reviewDialog.querySelector('h3 .count');
    const matches = reviewOffsets[doc];
    count.innerHTML = matches.length;
    reviewDocLink.innerHTML = doc;
    reviewDocLink.href = `${doc}?apply`;

    const endpoint = document.querySelector("pb-page").getEndpoint();
    window.pbEvents.emit("pb-start-update", "transcription", {});

    const body = {};
    body[doc] = matches;
    const list = reviewDialog.querySelector('ul');
    list.innerHTML = '';
    fetch(`${endpoint}/api/nlp/strings`, {
        method: "POST",
        mode: "cors",
        credentials: "same-origin",
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    })
    .then((response) => {
        if (response.ok) {
            return response.json();
        }
    })
    .then((json) => {
        if (!json) {
            reviewDialog.show();
            const li = document.createElement('li');
            li.innerHTML = 'No applicable matches in this document! Skipping.';
            list.appendChild(li);
            window.pbEvents.emit("pb-end-update", "transcription", {});
            if (reviewDocs.length === 0) {
                reviewDialog.close();
            } else {
                if (currentReview === reviewDocs.length) {
                    currentReview = 0;
                }
                _reviewNext();
            }
            return;
        }
        reviewData[doc] = json[doc];
        fetch(`${endpoint}/api/nlp/text/${doc}?debug=true`, {
            method: "GET",
            mode: "cors",
            credentials: "same-origin"
        })
        .then((response) => {
            window.pbEvents.emit("pb-end-update", "transcription", {});
            if (response.ok) {
                return response.text();
            }
        })
        .then((text) => {
            const occurrences = json[doc];
            occurrences.forEach((occur) => {
                const li = document.createElement('li');
                const cb = document.createElement('paper-checkbox');
                cb.setAttribute("checked", "checked");
                cb.addEventListener("click", () => {
                    if (cb.checked) {
                        occurrences.push(occur);
                    } else {
                        const n = occurrences.findIndex((m) => m.context === occur.context && m.absolute === occur.absolute);
                        occurrences.splice(n, 1);
                    }
                });
                li.appendChild(cb);
                const div = document.createElement('div');
                li.appendChild(div);
                kwicText(text, occur, 10).then((kwic) => div.innerHTML = kwic);
                list.appendChild(li);
            });
            reviewDialog.show();
        });
    });
}

/**
 * Save and merge the current document
 * 
 */
function _saveCurrent() {
    const doc = reviewDocs[currentReview];
    if (!doc) {
        return;
    }
    const endpoint = document.querySelector("pb-page").getEndpoint();
    window.pbEvents.emit("pb-start-update", "transcription", {});
    fetch(`${endpoint}/api/annotations/merge/${doc}`, {
        method: "PUT",
        mode: "cors",
        credentials: "same-origin",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(reviewData[doc]),
    })
    .then((response) => {
        window.pbEvents.emit("pb-end-update", "transcription", {});
        if (response.ok) {
            reviewDocs.splice(currentReview, 1);
            if (reviewDocs.length === 0) {
                reviewDialog.close();
            } else {
                if (currentReview === reviewDocs.length) {
                    currentReview = 0;
                }
                _reviewNext();
            }
            return response.json();
        }
        if (response.status === 403) {
            document.getElementById('permission-denied-dialog').show();
            return;
        }
        document.getElementById('error-dialog').show();
        return;
    });
}

function updateLocalStorage(path, json) {
    const value = window.localStorage.getItem(`tei-publisher.annotations.${path}`);
    if (value) {
        const ranges = JSON.parse(value);
        json.forEach((newRange) => {
            const pos = ranges.findIndex(range => rangeEQ(range, newRange));
            if (pos > -1) {
                ranges.splice(pos, 1, newRange);
            } else {
                ranges.push(newRange);
            }
        });
        window.localStorage.setItem(`tei-publisher.annotations.${path}`, JSON.stringify(ranges));
    } else {
        window.localStorage.setItem(`tei-publisher.annotations.${path}`, JSON.stringify(json));
    }
}

function rangeEQ(range, newRange) {
    return range.text === newRange.text && range.start === newRange.start && 
        range.type === newRange.type;
}

async function kwicText(str, match, words = 3) {
    const start = match.absolute;
    const end = match.absolute + match.text.length;
	let p0 = start - 1;
	let count = 0;
	while (p0 >= 0) {
	  if (/[\p{P}\s]/.test(str.charAt(p0))) {
		while (p0 > 1 && /[\p{P}\s]/.test(str.charAt(p0 - 1))) {
		  p0 -= 1;
		}
		count += 1;
		if (count === words) {
		  break;
		}
	  }
	  p0 -= 1;
	}
	let p1 = end + 1;
	count = 0;
	while (p1 < str.length) {
	  if (/[\p{P}\s]/.test(str.charAt(p1))) {
		while (p1 < str.length - 1 && /[\p{P}\s]/.test(str.charAt(p1 + 1))) {
		  p1 += 1;
		}
		count += 1;
		if (count === words) {
		  break;
		}
	  }
	  p1 += 1;
	}
    const mark = await createMark(str.substring(start, end), match);
	return `... ${str.substring(p0, start)}${mark}${str.substring(end, p1 + 1)} ...`;
}

function createMark(str, match) {
    return new Promise((resolve) => {
        if (match.type === 'modify') {
            const view = document.getElementById("view1");
            const key = match.key;
            if (!key || key === '') {
                resolve(`<mark class="incomplete">${str}</mark>`);
            } else {
                const container = document.createElement('div');
                document.querySelector("pb-authority-lookup")
                    .lookup(match.entityType, key, container)
                    .then(() => {
                        resolve(`<pb-popover>
                            <mark slot="default" class="modify">${str}</mark>
                            <div slot="alternate">${container.innerHTML}</div>
                        </pb-popover>`);
                    })
                    .catch((msg) => {
                        resolve(`<pb-popover>
                            <mark slot="default" class="modify">${str}</mark>
                            <div slot="alternate">Failed to load ${key}: ${msg}</div>
                        </pb-popover>`);
                    });
            }
        } else {
            resolve(`<mark>${str}</mark>`);
        }
    });
}