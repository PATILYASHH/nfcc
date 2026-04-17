# NFCC Cards

Digital business cards served via NFC tags. Cards are published from the NFCC Flutter app and hosted at clean URLs like `nfcc.vercel.app/yash`.

## Setup

1. **Deploy to Vercel** - Push this repo and import it in Vercel dashboard
2. **Create KV Store** - Go to Vercel dashboard > Storage > Create KV store
3. **Connect KV** - Link the KV store to this project (auto-sets `KV_REST_API_URL` and `KV_REST_API_TOKEN`)
4. **Set API Token** - Add `NFCC_API_TOKEN` in Vercel > Settings > Environment Variables (use a strong random string)
5. **Configure NFCC App** - Enter the deployment URL and API token in the NFCC Flutter app settings

## API Endpoints

### POST /api/publish
Publish or update a card.

```json
{
  "slug": "yash",
  "html": "<html>...</html>",
  "name": "Yash",
  "token": "your-api-token"
}
```

### GET /api/cards?token=your-api-token
List all published cards.

### GET /{slug}
View a card (public, no auth needed).
