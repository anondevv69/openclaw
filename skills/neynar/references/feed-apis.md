# Neynar Feed APIs (LLM reference)

**Documentation index:** Fetch the complete documentation index at: **https://docs.neynar.com/llms.txt** — use this file to discover all available pages before exploring further.

---

## Trending feeds

Fetch trending casts on the global feed or on channel feeds. A **7d** time window is available for channel feeds only.

- **API:** `GET https://api.neynar.com/v2/farcaster/feed/trending/`
- **Auth:** `x-api-key: YOUR_NEYNAR_API_KEY`
- **Node.js SDK:** [fetchTrendingFeed](https://docs.neynar.com/nodejs-sdk/feed-apis/fetchTrendingFeed) — use for typed responses and better DX.

### Query parameters

| Parameter      | Type    | Default | Description |
|----------------|---------|--------|-------------|
| `limit`        | integer | 10     | Number of results (1–10). |
| `cursor`       | string  | —      | Pagination cursor. |
| `viewer_fid`   | integer | —      | If provided, feed respects this user's mutes/blocks and includes `viewer_context`. |
| `time_window`  | string  | 24h    | Time window: `1h`, `6h`, `12h`, `24h`, `7d` (7d for channel feeds only). |
| `channel_id`   | string  | —      | Channel ID to filter (e.g. `neynar`). Use either `channel_id` or `parent_url`, not both. |
| `parent_url`   | string  | —      | Parent URL to filter (e.g. `chain://eip155:1/erc721:0x...`). Use either `channel_id` or `parent_url`, not both. |
| `provider`     | string  | neynar | Provider of the feed; currently `neynar`. |

### Example

```bash
# Global trending (last 24h)
curl -s -H "x-api-key: $NEYNAR_API_KEY" \
  "https://api.neynar.com/v2/farcaster/feed/trending/?limit=5&time_window=24h"

# Channel trending (e.g. neynar channel, 7d window)
curl -s -H "x-api-key: $NEYNAR_API_KEY" \
  "https://api.neynar.com/v2/farcaster/feed/trending/?limit=5&channel_id=neynar&time_window=7d"
```

### Response

- **200:** `{ "casts": [ ... ], "next": { "cursor": "..." } }` — each cast includes `object`, `hash`, `author`, `text`, `timestamp`, `reactions`, `channel`, etc. (see Neynar Cast schema).
- **400 / 404 / 500:** Error body with `message`, `code`, etc.

Less active channels might have no casts for the selected time window; try a larger window (e.g. 7d for channel feeds) or a different channel.
