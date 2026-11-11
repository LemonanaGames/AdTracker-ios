# Asset pipeline

## Today (M1)

`app/assets/asset_manifest.json` maps every `assetKey` used by content to an entry. **All entries are
placeholders** (`status: "placeholder"`), rendered by `AssetArt` as a tinted vector-icon tile. Tests
check that:

- every content `assetKey` exists in the manifest (`CatalogValidator`)
- every manifest icon name resolves to a bundled Material icon (`test/content/content_test.dart`)

## Replacing a placeholder with final art

1. Add the optimised file (WebP/PNG) under `app/assets/art/…` and register the folder in `pubspec.yaml`.
2. Set the manifest entry to `"status": "final", "file": "assets/art/…"`.
3. Extend `AssetArt` to render `file` when `status == final`. This is a one-time change and is planned
   alongside the first approved art.

## Planned generation workflow (GDD G1/G2; owner approval required first)

- `prompts/assets_bible.md` (creatorpop-v1) plus 3 approved test assets come before any batch work.
- Generation runs only in a local, developer-side script (`tools/asset_pipeline/`). The API key comes
  from the environment and is never committed or shipped.
- Steps: drafts → human review → crop/mask → dedupe hash → provenance log → compress → manifest → screenshot QA.
- Never generate images at runtime for player posts.
