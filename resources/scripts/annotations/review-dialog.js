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
    reviewDocLink.addEventListener('click', () => {
        const doc = reviewDocs[currentReview];
        updateLocalStorage(doc, reviewData[doc]);
    });

    const saveCurrentBtn = reviewDialog.querySelector('.save-current');
    saveCurrentBtn.addEventListener('click', () => {
        _saveCurrent();
    });

    const closeBtn = reviewDialog.querySelector('.close');
    closeBtn.addEventListener('click', () => reviewDialog.close());
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
    reviewData = data;
    reviewDialog.querySelector('h3 .total').innerHTML = reviewDocs.length;
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
    reviewDialog.querySelector('h3 .current').innerHTML = currentReview + 1;
    const count = reviewDialog.querySelector('h3 .count');
    const matches = reviewData[doc];
    count.innerHTML = matches.length;
    reviewDocLink.innerHTML = doc;
    reviewDocLink.href = doc;

    const endpoint = document.querySelector("pb-page").getEndpoint();
    window.pbEvents.emit("pb-start-update", "transcription", {});
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
        const list = reviewDialog.querySelector('ul');
        list.innerHTML = '';
        matches.forEach((match) => {
            const li = document.createElement('li');
            const div = document.createElement('div');
            li.appendChild(div);
            if (match.type === 'modify') {
                div.innerHTML = kwicText(text, match.absolute, match.absolute + match.text.length, 10);
                const info = document.createElement('div');
                info.innerHTML = `${match.properties.corresp}`;
                li.appendChild(info);
            } else {
                div.innerHTML = kwicText(text, match.absolute, match.absolute + match.text.length, 10);
            }
            list.appendChild(li);
        });
        reviewDialog.show();
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
            reviewDialog.querySelector('h3 .total').innerHTML = reviewDocs.length;
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
        if (response.status === 401) {
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

function kwicText(str, start, end, words = 3) {
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
	return `... ${str.substring(p0, start)}<mark>${str.substring(start, end)}</mark>${str.substring(end, p1 + 1)} ...`;
}