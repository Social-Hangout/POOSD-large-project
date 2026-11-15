// Shared setup for the API tests. Each test file gets its own throwaway in-memory MongoDB, so tests
// never touch a real database: .env is never loaded here, and MONGO_URI is ignored.
const crypto = require('node:crypto');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

process.env.JWT_SECRET = crypto.randomBytes(32).toString('hex');
process.env.APP_URL = 'http://localhost:5173';

const app = require('../app');
const User = require('../models/User');

let mongo;
let server;
let baseUrl;

// Starts the in-memory database and the app on a random free port
async function start() {
  mongo = await MongoMemoryServer.create();
  await mongoose.connect(mongo.getUri('recipes-test'));
  // Wait for every model's indexes (such as the unique review index) before any test runs
  await Promise.all(Object.values(mongoose.models).map((model) => model.init()));

  server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
}

async function stop() {
  await new Promise((resolve) => server.close(resolve));
  await mongoose.disconnect();
  await mongo.stop();
}

// Empties every collection but keeps the indexes, so each test starts from a blank database
async function clearDatabase() {
  const collections = await mongoose.connection.db.collections();
  await Promise.all(collections.map((collection) => collection.deleteMany({})));
}

// A verified user, saved straight to the database (registering would send a real email)
async function createUser(firstName = 'Ana') {
  return User.create({
    firstName,
    lastName: 'Tester',
    email: `${firstName.toLowerCase()}.${crypto.randomUUID()}@test.com`,
    passwordHash: 'not-a-real-hash',
    verified: true,
  });
}

// A login token for the user, signed the same way POST /api/auth/login does
function tokenFor(user) {
  return jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { algorithm: 'HS256', expiresIn: '1h' });
}

// Calls the API as `user` and returns { status, body }
async function api(method, path, { user, body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (user) headers.Authorization = `Bearer ${tokenFor(user)}`;

  const res = await fetch(baseUrl + path, { method, headers, body: body && JSON.stringify(body) });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
}

// A recipe body that passes every contract limit
function validRecipe(overrides = {}) {
  return {
    title: 'Garlic Butter Pasta',
    ingredients: [
      { name: 'pasta', amount: '200 g' },
      { name: 'butter', amount: '2 tbsp' },
    ],
    steps: ['Boil the pasta.', 'Toss with butter and serve.'],
    ...overrides,
  };
}

module.exports = { start, stop, clearDatabase, createUser, api, validRecipe };
