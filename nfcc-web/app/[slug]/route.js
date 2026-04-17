import { kv } from '@vercel/kv';

const RESERVED_SLUGS = new Set([
  'favicon.ico',
  'robots.txt',
  'sitemap.xml',
  'manifest.json',
  'apple-touch-icon.png',
  'apple-touch-icon-precomposed.png',
  'login',
  'signin',
  'signup',
  'api',
]);

function notFoundHtml() {
  return `<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Card Not Found - NFCC</title></head>
<body style="min-height:100vh;margin:0;background:#0D1117;color:#E6EDF3;display:flex;flex-direction:column;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;text-align:center;padding:2rem;">
<h1 style="font-size:3rem;font-weight:700;margin:0 0 .5rem 0;">404</h1>
<p style="font-size:1.1rem;color:#8B949E;margin:0 0 2rem 0;">This card doesn't exist</p>
<a href="/" style="color:#58A6FF;text-decoration:none;font-size:.9rem;">Go to NFCC</a>
</body></html>`;
}

export async function GET(request, { params }) {
  try {
    const { slug } = params;

    if (slug.startsWith('_next') || slug.startsWith('.') || /\.[a-z0-9]+$/i.test(slug)) {
      return new Response(null, { status: 404 });
    }

    if (RESERVED_SLUGS.has(slug)) {
      return new Response(notFoundHtml(), {
        status: 404,
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    if (!process.env.KV_REST_API_URL || !process.env.KV_REST_API_TOKEN) {
      return new Response(notFoundHtml(), {
        status: 404,
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    const html = await kv.get(`card:${slug}`);

    if (!html) {
      return new Response(notFoundHtml(), {
        status: 404,
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      });
    }

    return new Response(html, {
      status: 200,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'public, max-age=60, s-maxage=300',
      },
    });
  } catch (error) {
    console.error('Card fetch error:', error);

    return new Response(
      '<html><body style="background:#0D1117;color:#E6EDF3;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;font-family:sans-serif;"><p>Something went wrong</p></body></html>',
      {
        status: 500,
        headers: { 'Content-Type': 'text/html; charset=utf-8' },
      }
    );
  }
}
