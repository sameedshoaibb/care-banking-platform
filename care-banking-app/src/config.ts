import { readFileSync } from 'node:fs'

export type Config = {
  port: string
  adminApiKey: string
}

export const loadConfig = (configPath: string): Config => {
  const config = JSON.parse(readFileSync(configPath, 'utf-8'))
  return config
}
