import './globals.css';

export const metadata = {
  title: 'NFC Control — One Tap. Infinite Automations.',
  description:
    'NFC Control turns any NFC tag into a launcher for your phone and PC. IF/ELSE conditions, 60+ actions, local-first, zero cloud.',
  openGraph: {
    title: 'NFC Control — One Tap. Infinite Automations.',
    description:
      'Tap an NFC tag and fire a full workflow across phone and PC. Released April 2026.',
    type: 'website',
  },
};

export const viewport = {
  themeColor: '#000000',
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
