// Ini adalah file: config/plugins.ts
export default ({ env }) => ({
    // ... (konfigurasi plugin lain mungkin ada di sini)

    // Konfigurasi untuk plugin Email
    email: {
        config: {
            provider: 'nodemailer',
            providerOptions: {
                host: 'smtp.gmail.com', // Server SMTP Gmail
                port: 587,
                secure: false, // (false karena kita menggunakan TLS/STARTTLS)
                auth: {
                    user: env('SMTP_USERNAME'), // Ambil dari file .env
                    pass: env('SMTP_PASSWORD'), // Ambil dari file .env
                },
            },
            settings: {
                defaultFrom: env('SMTP_USERNAME'), // Email pengirim default
                defaultReplyTo: env('SMTP_USERNAME'),
            },
        },
    },
});