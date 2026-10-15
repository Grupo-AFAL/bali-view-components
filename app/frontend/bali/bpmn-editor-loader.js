/**
 * Bali BPMN Editor Island - Lazy loader
 *
 * Import once in the MAIN bundle (it weighs nothing):
 *
 *   import 'bali-view-components/bpmn-editor-loader'
 *
 * The first time an element with the `bpmn-editor` controller appears, this
 * injects the island bundle published by
 *
 *   <%= react_island_meta_tags('bpmn-editor', js: 'bpmn-editor-island.js',
 *                                             css: 'bpmn-editor-island.css') %>
 */
import { startIslandLoader } from './react-island'

startIslandLoader('bpmn-editor')
