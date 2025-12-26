import process from 'node:process'

import { startApp } from './app.js'
import { loadConfig } from './config.js'

const main = () => {
  const configPath = process.argv[2] || 'config.json'
  startApp(loadConfig(configPath))
}

main()
