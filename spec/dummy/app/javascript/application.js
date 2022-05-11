// Entry point for the build script in your package.json
import { Application } from '@hotwired/stimulus'

import { TabsController } from '../../../../app/javascript/bali'

const application = Application.start()

application.register('tabs', TabsController)
