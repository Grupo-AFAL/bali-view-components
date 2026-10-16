// The BPMN editor island with the optional rule package, for the rules
// gallery preview only. The package registers its rules in the editor's rule
// registry, so it must sit in the same bundle as the editor; a second entry
// keeps it off every other preview (bpmn-editor-island.js does not import it).
// A host that wants the package writes these two lines in its one entry.
import 'bali/bpmn-editor-entry'
import 'bali/bpmn-editor-afal-rules'
