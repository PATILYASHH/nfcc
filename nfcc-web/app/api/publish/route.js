import { kv } from '@vercel/kv';
import { NextResponse } from 'next/server';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const token = process.env.NFCC_API_TOKEN;
    if (!token) {
      return NextResponse.json(
        { error: 'Server misconfigured: API token not set' },
        { status: 500, headers: corsHeaders }
      );
    }

    const body = await request.json();
    const { slug, html, name, token: reqToken } = body;

    // Validate token
    if (!reqToken || reqToken !== token) {
      return NextResponse.json(
        { error: 'Invalid or missing token' },
        { status: 401, headers: corsHeaders }
      );
    }

    // Validate required fields
    if (!slug || !html) {
      return NextResponse.json(
        { error: 'Missing required fields: slug, html' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Validate slug format (alphanumeric, hyphens, underscores only)
    if (!/^[a-zA-Z0-9_-]+$/.test(slug)) {
      return NextResponse.json(
        { error: 'Invalid slug: use only letters, numbers, hyphens, underscores' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Store HTML
    await kv.set(`card:${slug}`, html);

    // Store metadata
    const metadata = {
      name: name || slug,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // Check if metadata already exists (update case)
    const existing = await kv.get(`meta:${slug}`);
    if (existing) {
      metadata.createdAt = existing.createdAt;
    }

    await kv.set(`meta:${slug}`, metadata);

    const host = request.headers.get('host') || 'nfcc.vercel.app';
    const protocol = host.includes('localhost') ? 'http' : 'https';

    return NextResponse.json(
      {
        success: true,
        url: `${protocol}://${host}/${slug}`,
        slug,
      },
      { status: 200, headers: corsHeaders }
    );
  } catch (error) {
    console.error('Publish error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500, headers: corsHeaders }
    );
  }
}
