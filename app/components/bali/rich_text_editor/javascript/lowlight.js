import { createLowlight } from 'lowlight'
import css from 'highlight.js/lib/languages/css'
import javascript from 'highlight.js/lib/languages/javascript'
import json from 'highlight.js/lib/languages/json'
import ruby from 'highlight.js/lib/languages/ruby'
import scss from 'highlight.js/lib/languages/scss'
import sql from 'highlight.js/lib/languages/sql'
import xml from 'highlight.js/lib/languages/xml'
import yaml from 'highlight.js/lib/languages/yaml'

const lowlight = createLowlight()

lowlight.registerLanguage('css', css)
lowlight.registerLanguage('javascript', javascript)
lowlight.registerLanguage('json', json)
lowlight.registerLanguage('ruby', ruby)
lowlight.registerLanguage('scss', scss)
lowlight.registerLanguage('sql', sql)
lowlight.registerLanguage('xml', xml)
lowlight.registerLanguage('yaml', yaml)

export default lowlight
