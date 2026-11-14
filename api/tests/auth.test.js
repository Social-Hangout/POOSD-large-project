// Account route fixes: verify links that can be opened again, and the rate limits
// (docs/api-contract.md, "2. verify" and "Rate limits").
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

// Replace the mailer before the app loads, so tests never send real email and can read the links
const sent = [];
const mailerPath = path.join(__dirname, '..', 'utils', 'mailer.js');
require.cache[mailerPath] = {
  id: mailerPath,
  filename: mailerPath,
  loaded: true,
  exports: {
    sendEmail: async (message) => {
      sent.push(message);
    },
  },
};

const User = require('../models/User');
const { start, stop, clearDatabase, api } = require('./helpers');

before(start);
after(stop);
beforeEach(() => {
  sent.length = 0;
  return clearDatabase();
});

// Rate-limit counts last for the whole file, so every test uses its own email addresses
let counter = 0;
const newEmail = () => `user${++counter}@test.com`;
const PASSWORD = 'Passw0rd!';

// Resend and forgot-password send in the background, so give the stub a moment to run
const settle = () => new Promise((resolve) => setImmediate(resolve));

// The token from the newest email sent to `email`
function linkToken(email) {
  const message = sent.findLast((m) => m.to === email);
  assert.ok(message, `no email sent to ${email}`);
  return /token=([a-f0-9]{64})/.exec(message.text)[1];
}

function register(email) {
  return api('POST', '/auth/register', {
    body: { firstName: 'Ana', lastName: 'Diaz', email, password: PASSWORD },
  });
}

describe('POST /api/auth/verify', () => {
  it('still says verified when the link is opened a second time', async () => {
    // An email scanner (such as UCF's Microsoft Safe Links) opens the link first, then the user clicks it
    const email = newEmail();
    await register(email);
    const token = linkToken(email);

    const scanner = await api('POST', '/auth/verify', { body: { token } });
    const user = await api('POST', '/auth/verify', { body: { token } });

    assert.equal(scanner.status, 200);
    assert.equal(user.status, 200);
    assert.deepEqual(user.body, { message: 'Email verified. You can log in now.' });
    assert.equal((await User.findOne({ email })).verified, true);
  });

  it('rejects the old link after a new one is sent', async () => {
    const email = newEmail();
    await register(email);
    const oldToken = linkToken(email);

    await api('POST', '/auth/resend-verification', { body: { email } });
    await settle();

    assert.equal((await api('POST', '/auth/verify', { body: { token: oldToken } })).status, 400);
    assert.equal((await api('POST', '/auth/verify', { body: { token: linkToken(email) } })).status, 200);
  });

  it('rejects the link after a password reset', async () => {
    const email = newEmail();
    await register(email);
    const verifyToken = linkToken(email);

    await api('POST', '/auth/forgot-password', { body: { email } });
    await settle();
    const reset = await api('POST', '/auth/reset-password', {
      body: { token: linkToken(email), newPassword: 'N3wPassw0rd!' },
    });
    assert.equal(reset.status, 200);

    const res = await api('POST', '/auth/verify', { body: { token: verifyToken } });
    assert.equal(res.status, 400);
    assert.deepEqual(res.body, { error: 'Invalid or expired link' });
  });

  it('rejects an expired link', async () => {
    const email = newEmail();
    await register(email);
    await User.updateOne({ email }, { $set: { verifyExpires: new Date(Date.now() - 1000) } });

    const res = await api('POST', '/auth/verify', { body: { token: linkToken(email) } });
    assert.equal(res.status, 400);
  });
});

describe('email rate limits', () => {
  it('counts each email route separately', async () => {
    const email = newEmail();
    await register(email);

    // Use up resend-verification's 3 per hour for this email
    const resends = [];
    for (let i = 0; i < 4; i++) {
      resends.push((await api('POST', '/auth/resend-verification', { body: { email } })).status);
    }
    assert.deepEqual(resends, [200, 200, 200, 429]);

    // forgot-password has its own count, so it still works
    const forgot = await api('POST', '/auth/forgot-password', { body: { email } });
    assert.equal(forgot.status, 200);
  });
});

describe('login rate limit', () => {
  it('does not count successful logins', async () => {
    const email = newEmail();
    await register(email);
    await api('POST', '/auth/verify', { body: { token: linkToken(email) } });

    for (let i = 0; i < 7; i++) {
      const res = await api('POST', '/auth/login', { body: { email, password: PASSWORD } });
      assert.equal(res.status, 200, `login ${i + 1}`);
    }
  });

  it('blocks after 5 wrong passwords, even with the right one', async () => {
    const email = newEmail();
    await register(email);
    await api('POST', '/auth/verify', { body: { token: linkToken(email) } });

    const statuses = [];
    for (let i = 0; i < 6; i++) {
      statuses.push((await api('POST', '/auth/login', { body: { email, password: 'wrong-password' } })).status);
    }
    assert.deepEqual(statuses, [401, 401, 401, 401, 401, 429]);

    const right = await api('POST', '/auth/login', { body: { email, password: PASSWORD } });
    assert.equal(right.status, 429);
    assert.deepEqual(right.body, { error: 'Too many login attempts. Try again later.' });
  });
});
