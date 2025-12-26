import { Express, Request, Response, NextFunction } from 'express'

import { Config } from './config.js'
import { accounts } from './state.js'

const apiKeyMiddleware =
  (apiKey: string) =>
  (req: Request, res: Response, next: NextFunction): void => {
    const requestApiKey = req.header('x-api-key')
    if (requestApiKey !== apiKey) {
      return void res.status(401).json({ error: 'Unauthorized' })
    }
    next()
  }

export const setupAdminRoutes = (app: Express, config: Config) => {
  app.use('/admin', apiKeyMiddleware(config.adminApiKey))

  app.get('/admin/accounts', (_req, res) => {
    res.json({
      accounts: Object.fromEntries(accounts.entries()),
    })
  })

  app.post('/admin/account', (req, res) => {
    const accountId = req.body.accountId
    if (!accountId) {
      return void res.status(422).json({ error: 'Empty account id' })
    }
    if (!req.body.password) {
      return void res.status(422).json({ error: 'Empty password' })
    }
    if (accounts.has(accountId)) {
      return void res.status(409).json({ error: 'Account id exists already' })
    }
    const account = {
      id: accountId,
      password: req.body.password,
      balance: 0,
      createdAt: Date.now(),
      updatedAt: null,
    }
    accounts.set(accountId, account)
    res.json({
      account,
    })
  })

  app.delete('/admin/account/:accountId', (req, res) => {
    const accountId = req.params.accountId
    if (!accounts.has(req.params.accountId)) {
      return void res.status(404).json({ error: 'Account does not exist' })
    }
    const account = accounts.get(accountId)!
    if (account.balance !== 0) {
      return void res.status(409).json({ error: 'Account is unbalanced' })
    }
    accounts.delete(accountId)
    res.json({
      account,
    })
  })
}
