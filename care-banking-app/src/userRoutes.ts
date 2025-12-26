import { Express, Request, Response } from 'express'

import { Config } from './config.js'
import { Account, accounts } from './state.js'

const withAccount = (
  req: Request,
  res: Response,
  f: (account: Account) => void
): void => {
  if (!accounts.has(req.params.accountId)) {
    return void res.status(404).send({ error: 'Unknown account' })
  }
  const account = accounts.get(req.params.accountId)!
  if (req.body.password !== account.password) {
    return void res.status(401).send({ error: 'Wrong password' })
  }
  return f(account)
}

export const setupUserRoutes = (app: Express, _config: Config) => {
  app.post('/account/:accountId/info', (req, res) => {
    withAccount(req, res, (account) => {
      res.json({
        balance: account.balance,
      })
    })
  })

  app.post('/account/:accountId/deposit', (req, res) => {
    withAccount(req, res, (account) => {
      const amount = req.body.amount
      if (!Number.isFinite(amount) || amount <= 0) {
        return void res.status(422).send({ error: 'Invalid amount' })
      }
      const newBalance = account.balance + amount
      account.balance = newBalance
      account.updatedAt = Date.now()
      res.json({
        balance: newBalance,
      })
    })
  })

  app.post('/account/:accountId/withdraw', (req, res) => {
    withAccount(req, res, (account) => {
      const amount = req.body.amount
      if (!Number.isFinite(amount) || amount <= 0) {
        return void res.status(422).send({ error: 'Invalid amount' })
      }
      const newBalance = account.balance - amount
      account.balance = newBalance
      account.updatedAt = Date.now()
      res.json({
        balance: newBalance,
      })
    })
  })
}
