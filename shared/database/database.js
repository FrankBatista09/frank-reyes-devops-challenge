import * as dotenv from 'dotenv'
import { Sequelize } from 'sequelize'

dotenv.config()

const storage =
  process.env.DATABASE_STORAGE ||
  (process.env.NODE_ENV === 'test' ? ':memory:' : './dev.sqlite')

const sequelize = new Sequelize('test-db', process.env.DATABASE_USER, process.env.DATABASE_PASSWORD, {
  dialect: 'sqlite',
  storage,
  logging: process.env.DATABASE_LOGGING === 'true' ? console.log : false
})

export default sequelize
