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

lowlight.register('css', css)
lowlight.register('javascript', javascript)
lowlight.register('json', json)
lowlight.register('ruby', ruby)
lowlight.register('scss', scss)
lowlight.register('sql', sql)
lowlight.register('xml', xml)
lowlight.register('yaml', yaml)

export default lowlight
