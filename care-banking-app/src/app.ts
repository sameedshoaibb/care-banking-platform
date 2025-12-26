import express from 'express'

import { setupAdminRoutes } from './adminRoutes.js'
import { setupUserRoutes } from './userRoutes.js'
import { Config } from './config.js'

export const startApp = (config: Config) => {
  const app = express()

  app.get('/ping', (req, res) => {
    res.status(200).end()
  })

  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' })
  })

  app.use(express.json())

  setupAdminRoutes(app, config)

  setupUserRoutes(app, config)

  app.listen(config.port, () =>
    console.log(`Server ready at port ${config.port}`)
  )
}
