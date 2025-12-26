export type Account = {
  id: string
  password: string
  balance: number
  createdAt: number
  updatedAt: number | null
}

export const accounts = new Map<string, Account>()
