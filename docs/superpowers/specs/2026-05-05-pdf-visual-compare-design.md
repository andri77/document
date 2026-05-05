# PDF Visual Comparison — Design Spec

**Date:** 2026-05-05  
**Status:** Approved

## Overview

Add visual regression testing for generated PDF invoices. PDFs are rendered to PNG images, a timestamp region is masked out, and the result is diffed against a stored baseline. Tests pass when the pixel difference is within a configurable threshold.

## Architecture & Components

### New files

| Path | Purpose |
|---|---|
| `features/support/pdf_comparison.rb` | `PdfComparison` helper module — converts, masks, diffs |
| `features/fixtures/baselines/` | Auto-generated baseline PNGs (gitignored) |
| `features/fixtures/actuals/` | Per-run actual + diff PNGs (gitignored) |

### Modified files

| Path | Change |
|---|---|
| `features/step_definitions/api_steps.rb` | Add `Then the PDF should match the visual baseline` step |
| `features/invoice_api.feature` | Add `@pdf_visual` scenario |
| `Gemfile` | Add `mini_magick ~> 4.12` |
| `.gitignore` | Ignore `features/fixtures/` |

### System dependencies

- `imagemagick` — image processing and diff
- `ghostscript` — PDF → PNG rasterisation (required by ImageMagick)

Both must be installed on the host. CI pipeline must install them before running tests.

## Mask Region

The `Generated: <timestamp>` line in `pdf_generator.rb:20` is dynamic and excluded from comparison via a black rectangle mask applied before diffing.

```
TIMESTAMP_MASK_REGION = { x: 0, y: 610, width: 400, height: 30 }
```

Coordinates are in pixels at 100dpi on a US Letter page (850×1100px). Verified by rendering a sample PDF during implementation.

## Configuration

| Env var | Default | Purpose |
|---|---|---|
| `PDF_DIFF_THRESHOLD` | `0.0` | Max allowed pixel difference as a percentage (e.g. `0.5` = 0.5%) |
| `PDF_BASELINE_DIR` | `features/fixtures/baselines` | Baseline PNG storage path |
| `PDF_ACTUAL_DIR` | `features/fixtures/actuals` | Actual + diff PNG output path |

## Baseline Management

- **First run**: no baseline exists → actual PNG is copied to `baselines/` and test passes with an informational message.
- **Subsequent runs**: actual is diffed against baseline; test fails if `diff_percent > threshold`.
- **Updating a baseline**: delete the baseline PNG and re-run to regenerate.
- Baselines are **gitignored** — not committed. Each developer/CI agent generates them on first run.

## `PdfComparison` Module Interface

```ruby
PdfComparison.compare(pdf_bytes, baseline_name)
# => {
#      diff_percent: Float,   # % of pixels that differ
#      threshold:    Float,   # configured threshold
#      actual_path:  String,  # path to actual PNG
#      diff_path:    String   # path to diff PNG
#    }
```

### Internal steps

1. Validate `pdf_bytes` is non-empty and starts with `%PDF`
2. Write bytes to a temp file
3. Use `MiniMagick::Tool::Convert` to rasterise page 0 to PNG at 100dpi
4. Draw `TIMESTAMP_MASK_REGION` as a filled black rectangle
5. If no baseline: copy to `baselines/`, return `diff_percent: 0.0`
6. Run `MiniMagick::Tool::Compare` with `-metric AE` to get absolute error pixel count
7. Calculate `diff_percent = (error_pixels / total_pixels) * 100`
8. Write diff image to `actuals/<name>_diff.png`
9. Return result hash

## Cucumber Step

```ruby
Then('the PDF should match the visual baseline {string}') do |name|
  result = PdfComparison.compare(@last_response.body, name)
  expect(result[:diff_percent]).to be <= result[:threshold],
    "PDF diff #{result[:diff_percent].round(4)}% exceeds threshold #{result[:threshold]}%.\n" \
    "Actual: #{result[:actual_path]}\nDiff:   #{result[:diff_path]}"
end
```

## New Feature Scenario

```gherkin
@api @pdf_visual
Scenario: PDF invoice matches visual baseline
  Given an invoice exists with ID "1"
  When I GET "/api/invoices/1/pdf"
  Then the PDF should match the visual baseline "invoice_standard"
```

## Error Handling

| Scenario | Behaviour |
|---|---|
| No baseline | Save actual as baseline, pass with info message |
| ImageMagick not installed | Raise with message: "mini_magick requires ImageMagick + Ghostscript" |
| PDF empty or corrupt | Raise before attempting conversion |
| Diff exceeds threshold | Fail with diff %, threshold, actual path, and diff image path |

## Out of Scope

- Multi-page PDF comparison (only page 0 is compared)
- Committing baselines to git
- Applitools or any cloud visual testing service
