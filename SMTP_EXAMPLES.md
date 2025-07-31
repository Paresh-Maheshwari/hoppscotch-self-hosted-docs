# SMTP Configuration Examples

This document provides various SMTP configuration examples for different email providers.

## Development (MailHog)

```env
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local
```

## Gmail

### Using App Password
```env
MAILER_SMTP_URL=smtps://your-email@gmail.com:your-app-password@smtp.gmail.com:465
MAILER_ADDRESS_FROM=your-email@gmail.com
```

### Using OAuth2 (Advanced)
```env
MAILER_SMTP_URL=smtps://your-email@gmail.com@smtp.gmail.com:465
MAILER_ADDRESS_FROM=your-email@gmail.com
# Additional OAuth2 configuration required in code
```

## Outlook/Hotmail

```env
MAILER_SMTP_URL=smtps://your-email@outlook.com:your-password@smtp-mail.outlook.com:587
MAILER_ADDRESS_FROM=your-email@outlook.com
```

## SendGrid

```env
MAILER_SMTP_URL=smtps://apikey:your-sendgrid-api-key@smtp.sendgrid.net:465
MAILER_ADDRESS_FROM=noreply@yourdomain.com
```

## Mailgun

```env
MAILER_SMTP_URL=smtps://your-username:your-password@smtp.mailgun.org:465
MAILER_ADDRESS_FROM=noreply@yourdomain.com
```

## Amazon SES

```env
MAILER_SMTP_URL=smtps://your-access-key:your-secret-key@email-smtp.us-east-1.amazonaws.com:465
MAILER_ADDRESS_FROM=noreply@yourdomain.com
```

## Custom SMTP Server

### With Authentication
```env
MAILER_SMTP_URL=smtp://username:password@smtp.yourdomain.com:587
MAILER_ADDRESS_FROM=noreply@yourdomain.com
```

### Without Authentication
```env
MAILER_SMTP_URL=smtp://smtp.yourdomain.com:25
MAILER_ADDRESS_FROM=noreply@yourdomain.com
```

### With TLS
```env
MAILER_SMTP_URL=smtps://username:password@smtp.yourdomain.com:465
MAILER_ADDRESS_FROM=noreply@yourdomain.com
```

## URL Format Explanation

The SMTP URL format is: `protocol://[username:password@]hostname:port`

- **protocol**: `smtp` (plain), `smtps` (SSL/TLS)
- **username**: SMTP username (optional)
- **password**: SMTP password (optional)
- **hostname**: SMTP server hostname
- **port**: SMTP server port (25, 587, 465, etc.)

## Common Ports

| Port | Description |
|------|-------------|
| 25   | Standard SMTP (usually blocked by ISPs) |
| 587  | SMTP with STARTTLS (recommended) |
| 465  | SMTP over SSL (legacy but widely supported) |
| 2525 | Alternative SMTP port (some providers) |

## Testing SMTP Configuration

### Using Python
```python
import smtplib
from email.mime.text import MIMEText

def test_smtp(smtp_url, from_addr, to_addr):
    # Parse SMTP URL
    # smtp://username:password@hostname:port
    
    msg = MIMEText('Test email from Hoppscotch')
    msg['Subject'] = 'SMTP Test'
    msg['From'] = from_addr
    msg['To'] = to_addr
    
    try:
        server = smtplib.SMTP('hostname', port)
        server.starttls()  # Enable TLS if needed
        server.login('username', 'password')
        server.send_message(msg)
        server.quit()
        print('✅ SMTP test successful')
    except Exception as e:
        print(f'❌ SMTP test failed: {e}')

# Example usage
test_smtp('smtp://localhost:1025', 'test@example.com', 'recipient@example.com')
```

### Using curl
```bash
# Test SMTP connection
curl -v --url 'smtp://smtp.gmail.com:587' \
     --ssl-reqd \
     --mail-from 'sender@gmail.com' \
     --mail-rcpt 'recipient@example.com' \
     --user 'sender@gmail.com:password' \
     --upload-file email.txt
```

## Security Best Practices

1. **Use App Passwords**: For Gmail, use app-specific passwords instead of your main password
2. **Enable 2FA**: Always enable two-factor authentication on email accounts
3. **Use Environment Variables**: Never hardcode credentials in configuration files
4. **Rotate Credentials**: Regularly update SMTP passwords and API keys
5. **Monitor Usage**: Keep track of email sending patterns and quotas
6. **Use TLS**: Always prefer encrypted connections (smtps:// or STARTTLS)

## Troubleshooting

### Common Errors

#### Authentication Failed
- Check username/password
- Verify app password is used (Gmail)
- Ensure 2FA is properly configured

#### Connection Timeout
- Check firewall settings
- Verify SMTP server hostname and port
- Test network connectivity

#### TLS/SSL Errors
- Try different ports (587 vs 465)
- Check if STARTTLS is required
- Verify certificate validity

#### Rate Limiting
- Check provider's sending limits
- Implement proper retry logic
- Consider using dedicated email service

---

*For more information, consult your email provider's SMTP documentation.*
