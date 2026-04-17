import { kv } from '@vercel/kv';
import { NextResponse } from 'next/server';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET(request) {
  try {
    const token = process.env.NFCC_API_TOKEN;
    if (!token) {
      return NextResponse.json(
        { error: 'Server misconfigured: API token not set' },
        { status: 500, headers: corsHeaders }
      );
    }

    // Check token from query param or Authorization header
    const { searchParams } = new URL(request.url);
    const queryToken = searchParams.get('token');
    const authHeader = request.headers.get('Authorization');
    const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
    const reqToken = queryToken || bearerToken;

    if (!reqToken || reqToken !== token) {
      return NextResponse.json(
        { error: 'Invalid or missing token' },
        { status: 401, headers: corsHeaders }
      );
    }

    // Scan all meta keys
    const cards = [];
    let cursor = 0;

    do {
      const [nextCursor, keys] = await kv.scan(cursor, {
        match: 'meta:*',
        count: 100,
      });
      cursor = nextCursor;

      for (const key of keys) {
        const meta = await kv.get(key);
        const slug = key.replace('meta:', '');
        const host = request.headers.get('host') || 'nfcc.vercel.app';
        const protocol = host.includes('localhost') ? 'http' : 'https';

        cards.push({
          slug,
          name: meta.name,
          createdAt: meta.createdAt,
          updatedAt: meta.updatedAt,
          url: `${protocol}://${host}/${slug}`,
        });
      }
    } while (cursor !== 0);

    // Sort by most recently created
    cards.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return NextResponse.json(cards, { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('List cards error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    );
  }
}
