const { sendEmail } = require('./mailer');

// Links point at React pages on APP_URL, which then call the API with the token
function appLink(path, token) {
  const url = new URL(path, process.env.APP_URL);
  url.searchParams.set('token', token);
  return url.toString();
}

function sendVerificationEmail(to, token) {
  const link = appLink('/verify', token);

  return sendEmail({
    to,
    subject: 'Verify your email',
    text: `Confirm your email to finish creating your account:\n\n${link}\n\nThis link expires in 24 hours. If you didn't sign up, you can ignore this email.`,
    html: `<p>Confirm your email to finish creating your account:</p>
<p><a href="${link}">Verify my email</a></p>
<p>This link expires in 24 hours. If you didn't sign up, you can ignore this email.</p>`,
  });
}

module.exports = { sendVerificationEmail };
