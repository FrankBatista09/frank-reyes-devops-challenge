import sequelize from './shared/database/database.js'
import { usersRouter } from "./users/router.js"
import express from 'express'

const app = express()
const PORT = process.env.PORT || 8000

if (process.env.NODE_ENV !== 'test') {
  sequelize.sync().then(() => console.log('db is ready'))
}

app.use(express.json())

app.get('/health/live', (_req, res) => {
  res.status(200).json({
    status: 'alive'
  })
})

app.get('/health/ready', async (_req, res) => {
  try {
    await sequelize.authenticate()

    res.status(200).json({
      status: 'ready'
    })
  } catch (_error) {
    res.status(503).json({
      status: 'not ready'
    })
  }
})

app.use('/api/users', usersRouter)

const server = app.listen(PORT, () => {
    console.log('Server running on port PORT', PORT)
})

export { app, server }