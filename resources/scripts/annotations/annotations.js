function disableButtons(disable) {
	document.querySelectorAll(".annotation-action").forEach((button) => {
		button.disabled = disable;
	});
}

window.addEventListener("WebComponentsReady", () => {
    const form = document.getElementById("edit-form");
    
    function showForm(type) {
		form.style.display = "";
		form.querySelectorAll(`.annotation-form:not(.${type})`).forEach((elem) => {
			elem.style.display = "none";
		});
		form.querySelectorAll(`.annotation-form.${type}`).forEach((elem) => {
			elem.style.display = "";
		});
	}

	function hideForm() {
		form.style.display = "none";
	}
    
	hideForm();

	let selection = null;
	let activeSpan = null;
	const refInput = document.getElementById("form-ref");
	const authorityInfo = document.getElementById("authority-info");
	const authorityDialog = document.getElementById("authority-dialog");
	let type = "";
	let text = "";
	document.getElementById("form-save").addEventListener("click", () => {
		const data = form.serializeForm();
		form.reset();
		refInput.value = "";
		hideForm();
		if (activeSpan) {
			window.pbEvents.emit("pb-edit-annotation", "transcription", {
				target: activeSpan,
				properties: data,
			});
			activeSpan = null;
		} else {
			window.pbEvents.emit("pb-add-annotation", "transcription", {
				type,
				properties: data,
			});
		}
	});
	document.querySelector('#form-ref [slot="prefix"]').addEventListener("click", () => {
		window.pbEvents.emit("pb-authority-lookup", "transcription", {
			type,
			query: text,
		});
		authorityDialog.open();
	});
	refInput.addEventListener("value-changed", () => {
		document.querySelector("pb-authority-lookup").lookup(type, refInput.value, authorityInfo);
	});
	document.querySelectorAll(".annotation-action").forEach((button) => {
		button.addEventListener("click", () => {
			if (selection) {
				type = button.getAttribute("data-type");
				showForm(type);
				text = selection;
				activeSpan = null;
				if (button.classList.contains("authority")) {
					window.pbEvents.emit("pb-authority-lookup", "transcription", {
						type,
						query: selection,
					});
					authorityDialog.open();
				}
			}
			disableButtons(true);
		});
	});
	window.pbEvents.subscribe("pb-authority-select", "transcription", (ev) => {
		authorityDialog.close();
		refInput.value = ev.detail.properties.ref;
	});
	window.pbEvents.subscribe("pb-selection-changed", "transcription", (ev) => {
		disableButtons(!ev.detail.hasContent);
		if (ev.detail.hasContent) {
			selection = ev.detail.range.cloneContents().textContent;
		}
	});
	window.pbEvents.subscribe("pb-annotations-changed", "transcription", (ev) => {
		const annotations = ev.detail.ranges;
		const endpoint = document.querySelector("pb-page").getEndpoint();
		const doc = document.getElementById("document1");
		document.getElementById("json").innerText = JSON.stringify(annotations, null, 2);
		document.getElementById("output").code = "";
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
	});
	window.pbEvents.subscribe("pb-annotation-edit", "transcription", (ev) => {
		activeSpan = ev.detail.target;
		text = activeSpan.textContent;
		type = ev.detail.type;
		showForm(type);
		refInput.value = ev.detail.properties.ref;
	});
	const clearAll = document.getElementById("clear-all");
	clearAll.addEventListener("click", () => window.pbEvents.emit("pb-refresh", "transcription"));
});
