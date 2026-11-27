# Rule Builder — visual editor for DocFlow approval rules

A Flutter app (web, desktop, mobile) that lets operations teams build and test
document-approval rules without writing code. It is the front end for
[DocFlow](https://github.com/kushallj/docflow), which reads invoices with PaddleOCR and runs
these rules to auto-approve, route to a review queue, or reject each document.

- **Nested conditions**: ALL / ANY groups, NOT, groups inside groups, colour-coded by depth.
- **Typed, server-driven dropdowns**: facts and the operators allowed for each fact come from
  DocFlow (`GET /api/document-types/{slug}/facts/`), so a string fact never offers
  "greater than", and new facts appear without an app release.
- **Right input for each value**: numbers, Yes / No toggles, date picker, day counts, ranges
  ("between"), comma-separated lists ("is one of"), or another fact
  ("tax greater than subtotal").
- **Try before you save**: run the rule against a real processed document and see every
  condition pass or fail with the actual value DocFlow read from the invoice.
- **Safe saves**: problems are caught in the app with a path to the exact condition
  (`root.rules[1] (Grand total): "lots" is not a number`), and DocFlow validates again on save.
  Every save bumps the rule version and is written to DocFlow's audit log.
- **Rule set settings**: action (auto-approve / review / reject), review queue, priority,
  reviewer-facing reason, on / off switch.

## Run it

Start DocFlow first (see its README), with demo data:

```bash
python manage.py migrate && python manage.py seed_demo && python manage.py runserver 8000
```

Then run the builder:

```bash
flutter pub get
flutter run -d chrome          # or: flutter run -d windows / macos / an emulator
```

Sign in with the DocFlow server URL (`http://localhost:8000`) and `admin` / `docflow-demo`.
Reviewers can view rules; only admins can change them.

For a hosted web build: `flutter build web`, serve `build/web/`, and add its origin to
DocFlow's `CORS_ALLOWED_ORIGINS`. In debug mode DocFlow already accepts any `localhost` port.

## How it maps to DocFlow

```
UI                                  JSON sent to DocFlow
──────────────────────────────────  ─────────────────────────────────────────────────────
ANY of these can match              {"type": "any", "rules": [
  Grand total  greater than  500000    {"fact": "total_amount", "operator": "greaterThan", "value": 500000},
  Vendor approved  equals  No          {"fact": "vendor_approved", "operator": "equalTo", "value": false}
                                    ]}
```

| Endpoint | Used for |
|---|---|
| `POST /api/auth/token/` | sign in (token stored on the device) |
| `GET /api/document-types/` and `/{slug}/facts/` | document types, fact and operator dropdowns |
| `GET/POST/PATCH/DELETE /api/rulesets/` | list, create, edit, switch off, delete |
| `POST /api/rulesets/test/` | dry run against a document, returns the trace |
| `GET /api/documents/` | documents to test against |

## Code

```
lib/
  api/docflow_api.dart        HTTP client, readable errors from DRF responses
  models/catalog.dart         facts, operators, document types
  models/rule_tree.dart       editable rule tree ↔ DocFlow JSON, typed value conversion
  state/session.dart          server URL + token, persisted with shared_preferences
  screens/                    sign in, rule set list, rule editor with dry run
  widgets/rule_tree_editor.dart   recursive group / condition editor
  widgets/trace_view.dart     pass / fail trace from DocFlow
test/                         model round-trip against DocFlow's real rule JSON, API client
                              against a mock server, editor widget test
```

```bash
flutter analyze && flutter test
```
