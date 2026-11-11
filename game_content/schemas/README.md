# game_content schemas

JSON Schema (draft 2020-12) files describing every content file. They are documentation and
editor support; the authoritative runtime check is `CatalogValidator`
(`app/lib/domain/content/catalog_validator.dart`), which also checks cross-references
(asset keys, localization keys, requirement targets) that JSON Schema cannot express.

Run the validator: `cd app && dart run tool/validate_content.dart`.
