/**
 * Bali Gantt Island - Lazy loader
 *
 * Import once in the MAIN bundle (it weighs nothing):
 *
 *   import 'bali-view-components/gantt-loader'
 *
 * The first time an element with the `gantt` controller appears in the DOM
 * (including content injected into drawers/modals via innerHTML, where
 * <script> tags never execute), this injects the <link> and <script> of the
 * real island bundle from the paths published by the helper:
 *
 *   <%= react_island_meta_tags('gantt', js: 'gantt-island.js',
 *                                       css: 'gantt-island.css') %>
 */
import { startIslandLoader } from './react-island'

startIslandLoader('gantt')
