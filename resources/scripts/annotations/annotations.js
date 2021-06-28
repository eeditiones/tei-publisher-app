function disableButtons(disable) {
	document.querySelectorAll(".annotation-action").forEach((button) => {
		button.disabled = disable;
	});
}

window.addEventListener("WebComponentsReady", () => {
    const form = document.getElementById("edit-form");
	let selection = null;
	let activeSpan = null;
	const view = document.getElementById("view1");
	const occurDiv = document.getElementById("occurrences");
	const occurrences = occurDiv.querySelector('ul');
	const saveBtn = document.getElementById('form-save');
	const refInput = document.getElementById("form-ref");
	const authorityInfo = document.getElementById("authority-info");
	const authorityDialog = document.getElementById("authority-dialog");
	let autoSave = false;
	let type = "";
	let text = "";
	let enablePreview = true;

	/**
	 * Display the main form
	 * 
	 * @param {string} type the annotation type
	 * @param {any} data properties of the annotation (if any); used to prefill the form
	 */
    function showForm(type, data) {
		form.reset();
		if (autoSave) {
			saveBtn.style.display = 'none';
		} else {
			saveBtn.style.display = '';
		}
		form.style.display = "";
		form.querySelectorAll(`.annotation-form:not(.${type})`).forEach((elem) => {
			elem.style.display = "none";
		});
		form.querySelectorAll(`.annotation-form.${type}`).forEach((elem) => {
			elem.style.display = "";
		});
		occurDiv.style.display = "";
		occurrences.innerHTML = '';

		if (data) {
			Object.keys(data).forEach((key) => {
				const field = form.querySelector(`[name="${key}"]`);
				if (field) {
					field.value = data[key];
				}
			});
		}
	}

	function hideForm() {
		form.style.display = "none";
		occurDiv.style.display = "none";
	}
    
	/**
	 * The user selected an authority entry.
	 * 
	 * @param {any} data details of the selected authority entry
	 */
	function authoritySelected(data) {
		authorityDialog.close();
		refInput.value = data.properties.ref;
		if (autoSave) {
			save();
		}
	}

	function selectOccurrence(data, o) {
		if (!o.annotated) {
			const teiRange = {
				type,
				properties: data,
				context: o.context,
				start: o.start,
				end: o.end,
				text: o.text
			};
			return view.updateAnnotation(teiRange);
		} else {
			view.deleteAnnotation(o.textNode.parentNode);
		}
	}

	/**
	 * Search the text for other potential occurrences of an authority entry
	 * 
	 * @param {any} info details of the selected authority entry
	 */
	function findOther(info) {
		let strings = [text];
		if (info) {
			strings = strings.concat(info.strings);
		}
		const occur = view.search(type, strings);
		occurrences.innerHTML = "";
		occur.forEach((o) => {
			const li = document.createElement("li");
			const cb = document.createElement("paper-checkbox");
			cb._options = o;
			cb._info = info;
			if (o.annotated) {
				cb.setAttribute('checked', 'checked');
			}
			cb.addEventListener("click", () => {
				const data = form.serializeForm();
				selectOccurrence(data, o);
			});

			li.appendChild(cb);
			const span = document.createElement("span");
			span.innerHTML = o.kwic;
			li.appendChild(span);
			occurrences.appendChild(li);
			li.addEventListener("mouseenter", () => {
				view.scrollTo(o);
			});
			li.addEventListener('mouseleave', () => view.hideMarker());
		});
	}

	function save() {
		const data = form.serializeForm();
		// hideForm();
		if (activeSpan) {
			window.pbEvents.emit("pb-edit-annotation", "transcription", {
				target: activeSpan,
				properties: data,
			});
			activeSpan = null;
		} else {
			activeSpan = view.addAnnotation({
				type,
				properties: data
			});
		}
	}

	/**
	 * Preview the current document with annotations merged in.
	 * 
	 * @param {any} annotations the current list of annotations
	 */
	function preview(annotations) {
		const endpoint = document.querySelector("pb-page").getEndpoint();
		const doc = document.getElementById("document1");
		document.getElementById("json").innerText = JSON.stringify(annotations, null, 2);
		document.getElementById("output").code = "";
		console.log('Retrieving preview for %s', doc.path);
		fetch(`${endpoint}/api/annotations/merge/${doc.path}`, {
			method: "POST",
			mode: "cors",
			credentials: "same-origin",
			headers: {
				"Content-Type": "application/json",
			},
			body: JSON.stringify(annotations),
		})
			.then((response) => response.text())
			.then((text) => {
				document.getElementById("output").code = text;
				fetch(`${endpoint}/api/preview?odd=${doc.odd}.odd&base=${endpoint}/`, {
					method: "POST",
					mode: "cors",
					credentials: "same-origin",
					headers: {
						"Content-Type": "application/xml",
					},
					body: text,
				})
					.then((response) => response.text())
					.then((html) => {
						const iframe = document.getElementById("html");
						iframe.srcdoc = html;
					});
			});
	}

	hideForm();

	saveBtn.addEventListener("click", () => save());

	document.querySelector('#form-ref [slot="prefix"]').addEventListener("click", () => {
		window.pbEvents.emit("pb-authority-lookup", "transcription", {
			type,
			query: text,
		});
		authorityDialog.open();
	});
	refInput.addEventListener("value-changed", () => {
		const ref = refInput.value;
		if (ref && ref.length > 0) {
			document.querySelector("pb-authority-lookup").lookup(type, refInput.value, authorityInfo).then(findOther);
		}
	});
	document.querySelectorAll(".annotation-action").forEach((button) => {
		button.addEventListener("click", () => {
			if (selection) {
				type = button.getAttribute("data-type");
				if (button.classList.contains("authority")) {
					autoSave = true;
					window.pbEvents.emit("pb-authority-lookup", "transcription", {
						type,
						query: selection,
					});
					authorityDialog.open();
				}
				showForm(type);
				text = selection;
				activeSpan = null;
			}
			disableButtons(true);
		});
	});
	window.pbEvents.subscribe("pb-authority-select", "transcription", (ev) => authoritySelected(ev.detail));
	window.pbEvents.subscribe("pb-selection-changed", "transcription", (ev) => {
		disableButtons(!ev.detail.hasContent);
		if (ev.detail.hasContent) {
			selection = ev.detail.range.cloneContents().textContent;
		}
	});
	window.pbEvents.subscribe("pb-annotations-changed", "transcription", (ev) => {
		if (enablePreview) {
			const annotations = ev.detail.ranges;
			preview(annotations);
		}
	});

	window.pbEvents.subscribe("pb-annotation-edit", "transcription", (ev) => {
		activeSpan = ev.detail.target;
		text = activeSpan.textContent;
		type = ev.detail.type;
		showForm(type, ev.detail.properties);
	});

	const clearAll = document.getElementById("clear-all");
	clearAll.addEventListener("click", () => window.pbEvents.emit("pb-refresh", "transcription"));

	const markAll = document.getElementById('mark-all');
	markAll.addEventListener('click', () => {
		enablePreview = false;
		const data = form.serializeForm();
		const checkboxes = document.querySelectorAll('#occurrences li paper-checkbox:not([checked])');
		checkboxes.forEach(cb => {
			cb.checked = selectOccurrence(data, cb._options) !== null;
		});
		enablePreview = true;
		preview(view.annotations);
	});
});
