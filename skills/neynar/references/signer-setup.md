# Neynar Signer Setup (post, like, follow from Moltbot)

To have Moltbot cast, like, recast, or follow on Farcaster on your behalf, you need a **Neynar signer** linked to your Farcaster account.

## Steps

1. **Farcaster account**  
   You need a Farcaster account (e.g. [Warpcast](https://warpcast.com)).

2. **Neynar API key**  
   Already in `skills/neynar/config.json` as `apiKey`. Get one at [dev.neynar.com](https://dev.neynar.com) if needed.

3. **Create a signer (managed)**  
   - Go to [Neynar Dashboard](https://dashboard.neynar.com) or use the [Create Signer API](https://docs.neynar.com/reference/create-signer).  
   - Create a **managed signer** (Neynar holds the key; you approve once).  
   - You get an **approval URL**. Open it in a browser and **approve with your Farcaster account** (e.g. Warpcast).  
   - After approval, copy the **signer UUID** (e.g. `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

4. **Add signer to config**  
   In `skills/neynar/config.json`:

   ```json
   {
     "apiKey": "YOUR_NEYNAR_API_KEY",
     "signerUuid": "YOUR_SIGNER_UUID"
   }
   ```

5. **Restart gateway and new chat**  
   Restart the Moltbot gateway and start a new chat so the agent sees the updated skill. Then you can say e.g. “Post to Farcaster: gm world” or “Cast hello base in the base channel.”

## What Moltbot can do with a signer

- **Post:** `./scripts/neynar.sh post "text"` or `post "text" --channel base`
- **Reply:** `post "reply text" --reply-to <cast_hash>`
- **Like / Recast:** `like <hash>`, `recast <hash>`
- **Follow / Unfollow:** `follow username`, `unfollow username`

## Troubleshooting

### Signer not found (but posting works)

The Neynar signer lookup endpoint (`GET /v2/farcaster/signer?signer_uuid=...`) may return "Signer not found" even when the signer is valid and posting works fine. This can happen with:
- Signers created via different methods (dashboard vs API)
- Recently approved signers

**Test by posting directly** rather than relying on the lookup:
```bash
./scripts/neynar.sh post "test"
```

### Wrong account

If posts appear from the wrong Farcaster account:
1. **Check signer FID** — Each signer is linked to ONE Farcaster account (FID)
2. **Verify the signer** — The signer UUID must be approved by the account you want to post from
3. **Create new signer** — If you changed accounts, create a fresh signer and approve it with the correct account

### Finding your FID

Search for your username:
```bash
curl -s -H "x-api-key: YOUR_KEY" \
  "https://api.neynar.com/v2/farcaster/user/search?q=yourusername" | jq '.result.users[0].fid'
```

### Checking notifications for an FID

```bash
curl -s -H "x-api-key: YOUR_KEY" \
  "https://api.neynar.com/v2/farcaster/notifications?fid=YOUR_FID&limit=10" | jq '.notifications'
```

## Docs

- [Write data with managed signers](https://docs.neynar.com/docs/integrate-managed-signers)
- [How writes work with Neynar managed signers](https://docs.neynar.com/docs/how-writes-to-farcaster-work-with-neynar-managed-signers)
