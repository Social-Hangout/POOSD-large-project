// Sends one sample verification email to check delivery and spam placement.
// Usage (from api/): node scripts/test-email.js someone@ucf.edu

const path = require('path');

require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { sendEmail } = require('../utils/mailer');

const to = process.argv[2];

if (!to || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to)) {
  console.error('Usage: node scripts/test-email.js <recipient email>');
  process.exit(1);
}

const appUrl = process.env.APP_URL || 'http://localhost:5173';
const verifyUrl = `${appUrl}/verify?token=test-token-not-real`;

const text = `Hi there,

Thanks for signing up. Please confirm your email address by opening this link:

${verifyUrl}

The link expires in 24 hours.

If you didn't create an account, you can ignore this email.`;

const html = `<!doctype html>
<html>
  <body style="margin:0;padding:24px;background:#f5f5f5;font-family:Arial,Helvetica,sans-serif;color:#222;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;margin:0 auto;background:#ffffff;border-radius:8px;">
      <tr>
        <td style="padding:32px;">
          <h1 style="margin:0 0 16px;font-size:22px;">Verify your email address</h1>
          <p style="margin:0 0 16px;line-height:1.5;">Hi there,</p>
          <p style="margin:0 0 24px;line-height:1.5;">Thanks for signing up. Please confirm your email address to finish creating your account.</p>
          <p style="margin:0 0 24px;">
            <a href="${verifyUrl}" style="display:inline-block;padding:12px 20px;background:#2f6f4f;color:#ffffff;text-decoration:none;border-radius:6px;">Verify email</a>
          </p>
          <p style="margin:0 0 8px;line-height:1.5;font-size:14px;color:#555;">Or copy this link into your browser:</p>
          <p style="margin:0 0 24px;font-size:14px;word-break:break-all;"><a href="${verifyUrl}" style="color:#2f6f4f;">${verifyUrl}</a></p>
          <p style="margin:0;line-height:1.5;font-size:14px;color:#555;">The link expires in 24 hours. If you didn't create an account, you can ignore this email.</p>
        </td>
      </tr>
    </table>
  </body>
</html>`;

sendEmail({ to, subject: 'Verify your account', text, html })
  .then((info) => {
    console.log(`Sent to ${to}`);
    console.log(`Message ID: ${info.messageId}`);
    console.log(`Server response: ${info.response}`);
  })
  .catch((err) => {
    console.error(`Failed to send: ${err.message}`);
    process.exit(1);
  });
