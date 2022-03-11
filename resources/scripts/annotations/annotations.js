/*
 * This file contains the javascript code, which connects the various elements of the
 * user interface for the annotation editor.
 * 
 * You should not need to change this unless you want to add new features.
 */


function disableButtons(disable, range) {
	document.querySelectorAll(".annotation-action:not([data-type=edit])").forEach((button) => {
		button.disabled = disable;
	});
	const editBtn = document.querySelector(".annotation-action[data-type=edit]");
	if (!disable && range.startContainer === range.endContainer && range.startContainer.nodeType === Node.TEXT_NODE) {
		editBtn.disabled = false;
	} else {
		editBtn.disabled = true;
	}
}

/**
 * Create a handle to a new (text) file on the local file system.
 *
 * @return {!Promise<FileSystemFileHandle>} Handle to the new file.
 */
function getNewFileHandle(name) {
	const opts = {
		suggestedName: name,
		types: [{
			description: 'XML Document',
			accept: { 'application/xml': ['.xml'] },
		}],
	};
	return window.showSaveFilePicker(opts);
}

/**
 * Writes the contents to disk.
 *
 * @param {FileSystemFileHandle} fileHandle File handle to write to.
 * @param {string} contents Contents to write.
 */
async function writeFile(fileHandle, contents) {
	// For Chrome 83 and later.
	// Create a FileSystemWritableFileStream to write to.
	const writable = await fileHandle.createWritable();
	// Write the contents of the file to the stream.
	await writable.write(contents);
	// Close the file and write the contents to disk.
	await writable.close();
}

/**
 * Verify the user has granted permission to read or write to the file, if
 * permission hasn't been granted, request permission.
 *
 * @param {FileSystemFileHandle} fileHandle File handle to check.
 * @param {boolean} withWrite True if write permission should be checked.
 * @return {boolean} True if the user has granted read/write permission.
 */
async function verifyPermission(fileHandle, withWrite) {
	const opts = {};
	if (withWrite) {
		opts.writable = true;
		// For Chrome 86 and later...
		opts.mode = 'readwrite';
	}
	// Check if we already have permission, if so, return true.
	if (await fileHandle.queryPermission(opts) === 'granted') {
		return true;
	}
	// Request permission to the file, if the user grants permission, return true.
	if (await fileHandle.requestPermission(opts) === 'granted') {
		return true;
	}
	// The user did nt grant permission, return false.
	return false;
}

window.addEventListener("WebComponentsReady", () => {
	const form = document.getElementById("edit-form");
	let selection = null;
	let activeSpan = null;
	const view = document.getElementById("view1");
	const occurDiv = document.getElementById("occurrences");
	const occurrences = occurDiv.querySelector("ul");
	const saveBtn = document.getElementById("form-save");
	const refInput = document.querySelectorAll(".form-ref");
	const authorityDialog = document.getElementById("authority-dialog");
	const nerDialog = document.getElementById("ner-dialog");
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
			saveBtn.style.display = "none";
		} else {
			saveBtn.style.display = "";
		}
		form.style.display = "";
		form.querySelectorAll(`.annotation-form:not(.${type})`).forEach((elem) => {
			elem.style.display = "none";
		});
		form.querySelectorAll(`.annotation-form.${type}`).forEach((elem) => {
			elem.style.display = "";
		});
		occurDiv.style.display = "";
		occurrences.innerHTML = "";

		if (data) {
			Object.keys(data).forEach((key) => {
				const field = form.querySelector(`[name="${key}"]`);
				if (field) {
					field.value = data[key];
				}
			});
			form.querySelectorAll('pb-repeat').forEach(repeat => repeat.setData(data));
		} else if (type === 'edit') {
			form.querySelector('.annotation-form.edit [name=content]').value = selection;
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
		refInput.forEach((input) => { input.value = data.properties.ref });
		if (autoSave) {
			save();
		}
	}

	/**
	 * Called if user selects or deselects an occurrence
	 * 
	 * @param {any} data form data
	 * @param {any} o range data associated with the selected occurrence
	 * @param {boolean} inBatch true if this is a batch operation
	 * @returns 
	 */
	function selectOccurrence(data, o, inBatch) {
		try {
			if (!o.annotated) {
				const teiRange = {
					type,
					properties: data,
					context: o.context,
					start: o.start,
					end: o.end,
					text: o.text,
				};
				return view.updateAnnotation(teiRange, inBatch);
			} else if (data[view.key] !== o[view.key]) {
				view.editAnnotation(o.textNode.parentNode, data);
			} else {
				view.deleteAnnotation(o.textNode.parentNode);
			}
		} catch (e) {
			console.error(e);
			return false;
		}
	}

	/**
	 * Search the text for other potential occurrences of an authority entry
	 *
	 * @param {any} info details of the selected authority entry
	 */
	function findOther(info) {
		if (info) {
			strings = info.strings || [];
			strings.push(text);
		} else {
			strings = [text];
		}
		try {
			const key = view.getKey(type);
			const occur = view.search(type, strings);
			occurrences.innerHTML = "";
			occur.forEach((o) => {
				const li = document.createElement("li");
				const cb = document.createElement("paper-checkbox");
				cb._options = o;
				cb._info = info;
				if (o.annotated && o[key] === info.id) {
					cb.setAttribute("checked", "checked");
				}
				cb.addEventListener("click", () => {
					const data = form.serializeForm();
					view.saveHistory();
					selectOccurrence(data, o);
					findOther(info);
				});

				li.appendChild(cb);
				const span = document.createElement("span");
				if (info.id && o[key] && o[key] !== info.id) {
					span.className = "id-warning";
				}
				span.innerHTML = o.kwic;
				li.appendChild(span);
				occurrences.appendChild(li);

				const mark = span.querySelector('mark');
				mark.addEventListener("mouseenter", () => {
					view.scrollTo(o);
				});
				mark.addEventListener("mouseleave", () => {
					view.hideMarker();
				});
			});
		} catch (e) {
			console.error(e);
		}
	}

	/**
	 * Apply the current annotation.
	 */
	function save() {
		view.saveHistory();
		const data = form.serializeForm();
		if (!autoSave) {
			hideForm();
		}
		if (activeSpan) {
			window.pbEvents.emit("pb-edit-annotation", "transcription", {
				target: activeSpan,
				properties: data,
			});
			activeSpan = null;
		} else {
			try {
				view.addAnnotation({
					type,
					properties: data,
				});
			} catch (e) {
				document.getElementById('runtime-error-dialog').show('Error', e);
			}
		}
	}

	/**
	 * Preview the current document with annotations merged in.
	 *
	 * @param {any} annotations the current list of annotations
	 */
	function preview(annotations, doStore) {
		const endpoint = document.querySelector("pb-page").getEndpoint();
		const doc = document.getElementById("document1");
		document.getElementById("output").code = "";
		return new Promise((resolve, reject) => {
			fetch(`${endpoint}/api/annotations/merge/${doc.path}`, {
				method: doStore ? "PUT" : "POST",
				mode: "cors",
				credentials: "same-origin",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify(annotations),
			})
			.then((response) => {
				if (response.ok) {
					return response.json();
				}
				if (response.status === 401) {
					document.getElementById('permission-denied-dialog').show();
					throw new Error(response.statusText);
				}
				document.getElementById('error-dialog').show();
				throw new Error(response.statusText);
			})
			.then((json) => {
				const changeList = document.getElementById("changes");
				changeList.innerHTML = "";
				document.getElementById("json").innerText = '';
				document.getElementById("output").code = json.content;
				if (doStore) {
					window.localStorage.removeItem(`tei-publisher.annotations.${doc.path}`);
					window.localStorage.removeItem(`tei-publisher.annotations.${doc.path}.history`);
					view.clearHistory();
					hideForm();
					window.pbEvents.emit("pb-refresh", "transcription", { preserveScroll: true });
				} else {
					document.getElementById("json").innerText = JSON.stringify(annotations, null, 2);
					json.changes.forEach((change) => {
						const pre = document.createElement("pb-code-highlight");
						pre.setAttribute("language", "xml");
						pre.textContent = change;
						changeList.appendChild(pre);
					});
				}
				resolve(json.content);
				fetch(
					`${endpoint}/api/preview?odd=${doc.odd}.odd&base=${encodeURIComponent(
						endpoint
					)}%2F`,
					{
						method: "POST",
						mode: "cors",
						credentials: "same-origin",
						headers: {
							"Content-Type": "application/xml",
						},
						body: json.content,
					}
				)
					.then((response) => response.text())
					.then((html) => {
						const iframe = document.getElementById("html");
						iframe.srcdoc = html;
					});
			});
		});
	}

	/**
	 * Handler called if user clicks on an annotation action.
	 * 
	 * @param {HTMLButton} button the button
	 * @returns 
	 */
	function actionHandler(button) {
		if (selection) {
			type = button.getAttribute("data-type");
			if (button.classList.contains("toggle")) {
				save();
				return;
			}
			autoSave = false;
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
	}

	/**
	 * Handler called if user clicks the mark-all occurrences button.
	 * 
	 * @param {Event} ev event
	 */
	function markAll(ev) {
		ev.preventDefault();
		ev.stopPropagation();
		window.pbEvents.emit("pb-start-update", "transcription", {});
		enablePreview = false;
		const data = form.serializeForm();
		const checkboxes = document.querySelectorAll(
			"#occurrences li paper-checkbox:not([checked])"
		);
		if (checkboxes.length > 0) {
			view.saveHistory();
			try {
				checkboxes.forEach((cb) => {
					cb.checked = selectOccurrence(data, cb._options, true) !== null;
				});
				view.refreshMarkers();
			} catch (e) {
				console.error(e);
			}
			findOther(checkboxes[0]._info);
			enablePreview = true;
			preview(view.annotations);
		}
		window.pbEvents.emit("pb-end-update", "transcription", {});
	}

	function checkNERAvailable() {
		const endpoint = document.querySelector("pb-page").getEndpoint();
		fetch(`${endpoint}/api/nlp/status`, {
			method: "GET",
			mode: "cors",
			credentials: "same-origin"
		})
		.then((response) => {
			if (response.ok) {
				document.getElementById('ner-action').style.display = 'block';
				response.json().then(json => console.log(`NER: found spaCy version ${json.spacy_version}.`));
			} else {
				console.error("NER endpoint not available");
			}
		}).catch(() => console.error("NER endpoint not available"));
	}

	function ner() {
		const endpoint = document.querySelector("pb-page").getEndpoint();
		fetch(`${endpoint}/api/nlp/status/models`, {
			method: "GET",
			mode: "cors",
			credentials: "same-origin"
		})
		.then((response) => {
			if (response.ok) {
				return response.json();
			}
		})
		.then((json) => {
			const list = [];
			json.forEach((item) => {
				list.push(`<paper-item>${item}</paper-item>`);
			});
			nerDialog.querySelector('paper-listbox').innerHTML = list.join('\n');
			nerDialog.open();
		});
	}

	function runNER() {
		const endpoint = document.querySelector("pb-page").getEndpoint();
		const cb = nerDialog.querySelector('paper-checkbox');
		let url;
		if (cb && cb.checked) {
			const lang = nerDialog.querySelector('paper-input').value;
			url = `${endpoint}/api/nlp/patterns/${doc.path}?lang=${lang}`;
		} else {
			const model = nerDialog.querySelector('paper-dropdown-menu').selectedItemLabel;
			console.log('Using model %s', model)
			url = `${endpoint}/api/nlp/entities/${doc.path}?model=${model}`;
		}
		window.pbEvents.emit("pb-start-update", "transcription", {});
		fetch(url, {
			method: "GET",
			mode: "cors",
			credentials: "same-origin"
		})
		.then((response) => {
			if (response.ok) {
				return response.json();
			}
		}).then((json) => {
			view.annotations = json;
			window.pbEvents.emit("pb-end-update", "transcription", {});
			preview(view.annotations);
		});
	}

	hideForm();

	// apply annotation action
	saveBtn.addEventListener("click", () => save());
	document.getElementById('ner-action').addEventListener('click', () => {
		if (view.annotations.length > 0) {
			document.getElementById('ner-denied-dialog').show();
		} else {
			ner();
		}
	});
	document.getElementById('ner-run').addEventListener('click', () => runNER());
	// reload source TEI, discarding current annotations
	document.getElementById('reload-all').addEventListener('click', () => {
		function reload() {
			window.pbEvents.emit("pb-refresh", "transcription", { preserveScroll: true });
			hideForm();
		}
		if (view.annotations.length > 0) {
			document.getElementById('confirm-reload-dialog').confirm()
			.then(reload);
		} else {
			reload();
		}
	});
	// reload the preview action
	document.getElementById("reload-preview").addEventListener("click", () => preview(view.annotations));
	// undo action
	document.getElementById('undo-history').addEventListener('click', () => {
		hideForm();
		view.popHistory();
	});
	// save document action
	const saveDocBtn = document.getElementById("document-save");
	saveDocBtn.addEventListener("click", () => preview(view.annotations, true));
	if (saveDocBtn.dataset.shortcut) {
		window.hotkeys(saveDocBtn.dataset.shortcut, () => preview(view.annotations, true));
	}

	// save and download merged TEI to local file
	const downloadBtn = document.getElementById('document-download');
	if ('showSaveFilePicker' in window) {
		downloadBtn.addEventListener('click', () => {
			const doc = document.getElementById("document1");
			getNewFileHandle(doc.getFileName())
			.then((fh) => {
				if (verifyPermission(fh, true)) {
					preview(view.annotations, true)
					.then((xml) => {
						writeFile(fh, xml);
					});
				} else {
					alert('Permission denied to store files locally');
				}
			});
		});
	} else {
		downloadBtn.style.display = 'none';
	}

	// mark-all occurrences action
	const markAllBtn = document.getElementById("mark-all");
	if (markAllBtn.dataset.shortcut) {
		window.hotkeys(markAllBtn.dataset.shortcut, markAll);
	}
	markAllBtn.addEventListener("click", markAll);

	// display configured keyboard shortcuts on mouseover
	document.addEventListener('pb-page-ready', () => {
		document.querySelectorAll('[data-shortcut]').forEach((elem) => {
			const shortcut = elem.dataset.shortcut;
            const keys = shortcut.split(/\s*,\s*/);
			let output = keys[0];
			if (navigator.userAgent.indexOf('Mac OS X') === -1) {
                output = keys[1];
            }
			const title = elem.getAttribute('title') || '';
			elem.title = `${title} [${output.replaceAll('+', ' ')}]`;
		});
		checkNERAvailable();
	});

	document.querySelectorAll('.form-ref [slot="prefix"]').forEach(elem => {
		elem.addEventListener("click", () => {
			window.pbEvents.emit("pb-authority-lookup", "transcription", {
				type,
				query: text,
			});
			authorityDialog.open();
		});
	});

	// check if annotations were saved to local storage
	const doc = view.getDocument();
	if (doc && doc.path) {
		const ranges = window.localStorage.getItem(`tei-publisher.annotations.${doc.path}`);
		if (ranges) {
			const annotations = JSON.parse(ranges);
			if (annotations.length > 0) {
				document.getElementById('restore-dialog').confirm()
				.then(() => {
					console.log('loading annotations from local storage: %o', annotations);
					view.annotations = annotations;
					const history = window.localStorage.getItem(`tei-publisher.annotations.${doc.path}.history`);
					if (history) {
						view.clearHistory(JSON.parse(history));
					}
					window.localStorage.removeItem(`tei-publisher.annotations.${doc.path}`);
					window.localStorage.removeItem(`tei-publisher.annotations.${doc.path}.history`);
					preview(annotations);
				});
			}
		}
	}

	/**
	 * Reference changed: update authority information and search for other occurrences
	 */
	refInput.forEach(input => {
		input.addEventListener("value-changed", () => {
			const ref = input.value;
			const authorityInfo = input.parentElement.querySelector('.authority-info');
			if (ref && ref.length > 0) {
				authorityInfo.innerHTML = `Loading ${ref}...`;
				document
					.querySelector("pb-authority-lookup")
					.lookup(type, input.value, authorityInfo)
					.then(findOther)
					.catch((msg) => {
						authorityInfo.innerHTML = `Failed to load ${ref}: ${msg}`;
					});
			} else {
				authorityInfo.innerHTML = "";
			}
		});
	});

	/**
	 * Handle click on one of the toolbar buttons for adding a new annotation.
	 */
	document.querySelectorAll(".annotation-action").forEach((button) => {
		const shortcut = button.getAttribute("data-shortcut");
		if (shortcut) {
			window.hotkeys(shortcut, (ev) => {
				ev.preventDefault();
				ev.stopPropagation();
				actionHandler(button);
			});
		}
		button.addEventListener("click", () => {
			actionHandler(button);
		});
	});
	window.pbEvents.subscribe("pb-authority-select", "transcription", (ev) =>
		authoritySelected(ev.detail)
	);
	window.pbEvents.subscribe("pb-selection-changed", "transcription", (ev) => {
		disableButtons(!ev.detail.hasContent, ev.detail.range);
		if (ev.detail.hasContent) {
			selection = ev.detail.range.cloneContents().textContent.replace(/\s+/g, " ");
		}
	});
	/* Annotations changed: reload the preview panels */
	window.pbEvents.subscribe("pb-annotations-changed", "transcription", (ev) => {
		const doc = view.getDocument();
		if (doc && doc.path) {
			window.localStorage.setItem(`tei-publisher.annotations.${doc.path}`, JSON.stringify(ev.detail.ranges));
		}
		if (enablePreview && !ev.detail.refresh) {
			preview(ev.detail.ranges);
		}
	});
	window.pbEvents.subscribe('pb-annotations-history', 'transcription', (ev) => {
		const doc = view.getDocument();
		if (doc && doc.path) {
			window.localStorage.setItem(`tei-publisher.annotations.${doc.path}.history`, JSON.stringify(view.getHistory()));
		}
	});
	
	window.pbEvents.subscribe("pb-annotation-edit", "transcription", (ev) => {
		activeSpan = ev.detail.target;
		text = activeSpan.textContent.replace(/\s+/g, " ");
		type = ev.detail.type;
		autoSave = false;
		const trigger = document.querySelector(`[data-type=${type}]`);
		if (trigger && trigger.classList.contains("authority")) {
			autoSave = true;
			window.pbEvents.emit("pb-authority-lookup", "transcription", {
				type,
				query: text,
			});
			authorityDialog.open();
		}
		showForm(type, ev.detail.properties);
	});

	window.pbEvents.subscribe("pb-annotation-detail", "transcription", (ev) => {
		switch (ev.detail.type) {
			case "note":
				const data = JSON.parse(ev.detail.span.dataset.annotation);
				ev.detail.container.innerHTML = data.properties.note;
				break;
			default:
				document
					.querySelector("pb-authority-lookup")
					.lookup(ev.detail.type, ev.detail.id, ev.detail.container)
					.catch((msg) => {
						const div = document.createElement('div');
						const h = document.createElement('h3');
						if (msg) {
							h.innerHTML = msg;
						} else {
							h.innerHTML = 'Not found';
						}
						div.appendChild(h);
						const pre = document.createElement('pre');
						pre.className = 'error-notFound';
						const json = JSON.parse(ev.detail.span.dataset.annotation);
						pre.innerText = JSON.stringify(json, null, 2);
						div.appendChild(pre);
						ev.detail.container.innerHTML = '';
						ev.detail.container.appendChild(div);
					});
				break;
		}
	});

	window.pbEvents.subscribe("pb-annotation-colors", "transcription", (ev) => {
		const colors = ev.detail.colors;
		const styles = [];
		colors.forEach((color, type) => {
			styles.push(`
				.annotation-action[data-type=${type}] {
					color: ${color.color};
					border-bottom: 2px solid ${color.color};
				}
			`);
		});

		let css = document.head.querySelector('#annotation_colors');
		if (!css) {
			css = document.createElement('style');
			css.id = 'annotation_colors';
			document.head.appendChild(css);
		}
		css.innerHTML = styles.join('\n');
	});

	// wire the ODD selector for the preview
	const oddSelector = document.querySelector('pb-select-odd');
	oddSelector.odd = doc.odd;
	window.pbEvents.subscribe('pb-refresh', 'preview', (ev) => {
		doc.odd = ev.detail.odd;
	});
});
