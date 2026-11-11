# Content validator

The validator logic is `CatalogValidator` (`app/lib/domain/content/catalog_validator.dart`), so the
app, the tests and the CLI share one implementation.

```sh
cd app && dart run tool/validate_content.dart   # exit 1 on errors (CI)
```

It checks unique IDs, localization keys, asset keys, requirement targets (acts, gear, stats,
networks), curve shape, viral table consistency, story speakers and NPCs, "no dead end" choices and
a free first post for every niche.
