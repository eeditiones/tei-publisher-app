// Lightweight helpers around fflate for reading ZIP buffers in Cypress specs
const { unzipSync, strFromU8 } = require('fflate')

// Convert Cypress binary response body into Uint8Array
const toU8 = (binaryBody) => new Uint8Array(Cypress.Buffer.from(binaryBody, 'binary'))

// Return an object where keys are entry names and values are Uint8Array contents
const entries = (u8) => unzipSync(u8)

// Return a list of all entry names in the zip
const names = (u8) => Object.keys(entries(u8))

// Does the zip contain a given entry name?
const containsEntry = (u8, name) => Object.prototype.hasOwnProperty.call(entries(u8), name)

// Read a single entry as string (default) or raw Uint8Array
const readEntry = (u8, name, as = 'string') => {
  const e = entries(u8)[name]
  if (!e) return undefined
  return as === 'string' ? strFromU8(e) : e
}

// Build a map of entryName -> string
const toTextMap = (u8) => {
  const out = {}
  const es = entries(u8)
  Object.keys(es).forEach((k) => { out[k] = strFromU8(es[k]) })
  return out
}

module.exports = { toU8, entries, names, containsEntry, readEntry, toTextMap }

