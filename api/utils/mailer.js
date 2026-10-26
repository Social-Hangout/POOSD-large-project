const nodemailer = require('nodemailer');

const REQUIRED_VARS = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASS', 'MAIL_FROM'];

let transporter;

// Created on first use so callers can load dotenv in any order
function getTransporter() {
  if (transporter) return transporter;

  const missing = REQUIRED_VARS.filter((name) => !process.env[name]);
  if (missing.length) {
    throw new Error(`Missing email settings in .env: ${missing.join(', ')}`);
  }

  // Default 2525 because DigitalOcean blocks outbound 25, 465 and 587
  const port = Number(process.env.SMTP_PORT) || 2525;

  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port,
    secure: port === 465,
    // On every other port, refuse to send credentials unless STARTTLS succeeds
    requireTLS: port !== 465,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  return transporter;
}

async function sendEmail({ to, subject, html, text }) {
  return getTransporter().sendMail({
    from: process.env.MAIL_FROM,
    to,
    subject,
    html,
    text,
  });
}

module.exports = { sendEmail };
