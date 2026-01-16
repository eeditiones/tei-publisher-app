document.addEventListener('DOMContentLoaded', () => {
    const customForms = document.querySelectorAll('.facets');
    customForms.forEach((facets) => {
        facets.addEventListener('pb-custom-form-loaded', function(ev) {
            const elems = ev.detail.querySelectorAll('.facet');
            elems.forEach(facet => {
                facet.addEventListener('change', () => {
                    const table = facet.closest('table');
                    if (table) {
                        const nested = table.querySelectorAll('.nested .facet').forEach(nested => {
                            if (nested != facet) {
                                nested.checked = false;
                            }
                        });
                    }
                    facets.submit();
                });
            });

            ev.detail.querySelectorAll('pb-combo-box').forEach((select) => {
                select.renderFunction = (data, escape) => {
                    if (data) {
                        return `<div>${escape(data.text)} <span class="freq">${escape(data.freq || '')}</span></div>`;
                    }
                    return '';
                }
            });
        });

        // if there's a combo box, synchronize any changes to it with existing checkboxes
        pbEvents.subscribe('pb-combo-box-change', null, function(ev) {
            const parent = ev.target.parentNode;
            const values = ev.detail.value;
            // walk through checkboxes and select the ones in the combo box
            parent.querySelectorAll('.facet').forEach((cb) => {
                const idx = values.indexOf(cb.value);
                cb.checked =  idx > -1;
                if (cb.checked) {
                    values.splice(idx, 1);
                }
            });
            // add a hidden input for any facet value which is not in the checkbox list
            // the hidden inputs will be removed again when display refreshes
            values.forEach((value) => {
                const hidden = document.createElement('input');
                hidden.type = 'hidden';
                hidden.name = parent.dataset.dimension;
                hidden.value = value;
                parent.appendChild(hidden);
            });
            facets.submit();
        });
    });
});