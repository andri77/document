# PDF Visual Comparison Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visual regression testing for PDF invoices — render to PNG, mask the dynamic timestamp, diff against a stored baseline, and fail if pixel difference exceeds a configurable threshold.

**Architecture:** A new `PdfComparison` module in `features/support/` handles conversion (PDF→PNG via ImageMagick/Ghostscript), masking, and diffing. On first run the baseline is auto-created; subsequent runs compare and fail if `diff_percent > PDF_DIFF_THRESHOLD`. The module is wired in via a new Cucumber step and scenario.

**Tech Stack:** Ruby, `mini_magick ~> 4.12`, ImageMagick (v6 or v7), Ghostscript, Cucumber 9, RSpec expectations

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `features/support/pdf_comparison.rb` | Convert PDF→PNG, mask timestamp, diff against baseline |
| Modify | `features/step_definitions/api_steps.rb` | Add `Then the PDF should match the visual baseline` step |
| Modify | `features/invoice_api.feature` | Add `@pdf_visual` scenario |
| Modify | `Gemfile` | Add `mini_magick ~> 4.12` |
| Modify | `.gitignore` | Ignore `features/fixtures/` |
| Modify | `.github/workflows/test.yml` | Install imagemagick + ghostscript on CI |

---

## Task 1: Install system dependencies + add gem

**Files:**
- Modify: `Gemfile`
- Modify: `.gitignore`
- Modify: `.github/workflows/test.yml`

- [ ] **Step 1: Verify imagemagick and ghostscript are installed locally**

```bash
magick --version
gs --version
```

Expected: version strings for both. If missing on macOS: `brew install imagemagick ghostscript`

- [ ] **Step 2: Add mini_magick to Gemfile**

In `Gemfile`, add inside the `group :test do` block:

```ruby
group :test do
  gem 'cucumber', '~> 9.2'
  gem 'selenium-webdriver', '~> 4.20'
  gem 'rspec-expectations', '~> 3.13'
  gem 'rack-test', '~> 2.1'
  gem 'mini_magick', '~> 4.12'
end
```

- [ ] **Step 3: Install the gem**

```bash
bundle install
```

Expected: `Fetching mini_magick 4.x.x` then `Bundle complete!`

- [ ] **Step 4: Update .gitignore**

Add to `.gitignore`:

```
features/fixtures/
```

- [ ] **Step 5: Update CI workflow to install imagemagick + ghostscript**

In `.github/workflows/test.yml`, add a new step after `Set up Ruby` and before `Set up Chrome`:

```yaml
      - name: Install imagemagick and ghostscript
        run: sudo apt-get install -y imagemagick ghostscript
```

- [ ] **Step 6: Commit**

```bash
git add Gemfile Gemfile.lock .gitignore .github/workflows/test.yml
git commit -m "chore: add mini_magick gem and imagemagick CI dependency"
```

---

## Task 2: Write the failing Cucumber scenario

**Files:**
- Modify: `features/invoice_api.feature`

- [ ] **Step 1: Add the `@pdf_visual` scenario to `features/invoice_api.feature`**

Append to the end of the file:

```gherkin
  @api @pdf_visual
  Scenario: PDF invoice matches visual baseline
    Given an invoice exists with ID "1"
    When I GET "/api/invoices/1/pdf"
    Then the PDF should match the visual baseline "invoice_standard"
```

- [ ] **Step 2: Start the Sinatra app (in a separate terminal)**

```bash
bundle exec ruby app/app.rb
```

- [ ] **Step 3: Run the scenario and confirm it fails with "undefined step"**

```bash
bundle exec cucumber features/invoice_api.feature --tags @pdf_visual
```

Expected output: `Undefined step: "the PDF should match the visual baseline "invoice_standard""` and scenario shown as `undefined`.

- [ ] **Step 4: Commit**

```bash
git add features/invoice_api.feature
git commit -m "test: add failing pdf visual baseline scenario"
```

---

## Task 3: Create the PdfComparison module

**Files:**
- Create: `features/support/pdf_comparison.rb`

- [ ] **Step 1: Create `features/support/pdf_comparison.rb` with the full implementation**

```ruby
require 'mini_magick'
require 'tmpdir'
require 'fileutils'
require 'open3'

module PdfComparison
  # Pixels from top of PNG at 100dpi on US Letter (850x1100px).
  # Covers the "Generated: <timestamp>" line rendered by pdf_generator.rb:20.
  # Adjust if coordinates drift — run Task 4 Step 2 to verify.
  TIMESTAMP_MASK_REGION = { x: 0, y: 240, width: 500, height: 35 }.freeze

  def self.compare(pdf_bytes, baseline_name)
    validate!(pdf_bytes)

    threshold     = ENV.fetch('PDF_DIFF_THRESHOLD', '0.0').to_f
    baseline_dir  = ENV.fetch('PDF_BASELINE_DIR', 'features/fixtures/baselines')
    actual_dir    = ENV.fetch('PDF_ACTUAL_DIR',   'features/fixtures/actuals')
    FileUtils.mkdir_p(baseline_dir)
    FileUtils.mkdir_p(actual_dir)

    actual_path   = File.join(actual_dir,   "#{baseline_name}.png")
    baseline_path = File.join(baseline_dir, "#{baseline_name}.png")
    diff_path     = File.join(actual_dir,   "#{baseline_name}_diff.png")

    pdf_to_png(pdf_bytes, actual_path)
    apply_mask(actual_path)

    unless File.exist?(baseline_path)
      FileUtils.cp(actual_path, baseline_path)
      $stdout.puts "PDF baseline created: #{baseline_path}"
      return { diff_percent: 0.0, threshold: threshold, actual_path: actual_path, diff_path: diff_path }
    end

    diff_percent = pixel_diff_percent(baseline_path, actual_path, diff_path)
    { diff_percent: diff_percent, threshold: threshold, actual_path: actual_path, diff_path: diff_path }
  end

  def self.validate!(pdf_bytes)
    raise 'PDF bytes are empty' if pdf_bytes.nil? || pdf_bytes.empty?
    raise 'Data is not a valid PDF (missing %PDF header)' unless pdf_bytes[0..3] == '%PDF'
  end

  def self.pdf_to_png(pdf_bytes, output_path)
    Dir.mktmpdir do |dir|
      pdf_path = File.join(dir, 'input.pdf')
      File.binwrite(pdf_path, pdf_bytes)
      MiniMagick::Tool::Convert.new do |cmd|
        cmd.density(100)
        cmd << "#{pdf_path}[0]"
        cmd.flatten
        cmd << output_path
      end
    end
  rescue MiniMagick::Error => e
    raise "mini_magick requires ImageMagick + Ghostscript: #{e.message}"
  end

  def self.apply_mask(image_path)
    r = TIMESTAMP_MASK_REGION
    image = MiniMagick::Image.open(image_path)
    image.combine_options do |cmd|
      cmd.fill('black')
      cmd.draw("rectangle #{r[:x]},#{r[:y]} #{r[:x] + r[:width] - 1},#{r[:y] + r[:height] - 1}")
    end
    image.write(image_path)
  end

  def self.pixel_diff_percent(baseline_path, actual_path, diff_path)
    baseline     = MiniMagick::Image.open(baseline_path)
    total_pixels = baseline.width * baseline.height

    _out, stderr, _status = Open3.capture3(
      'compare', '-metric', 'AE',
      baseline_path, actual_path, diff_path
    )
    error_pixels = stderr.strip.to_f
    (error_pixels / total_pixels) * 100
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add features/support/pdf_comparison.rb
git commit -m "feat: add PdfComparison module with ImageMagick diff"
```

---

## Task 4: Add the Cucumber step definition

**Files:**
- Modify: `features/step_definitions/api_steps.rb`

- [ ] **Step 1: Add the step to the bottom of `features/step_definitions/api_steps.rb`**

```ruby
Then('the PDF should match the visual baseline {string}') do |name|
  result = PdfComparison.compare(@last_response.body, name)
  expect(result[:diff_percent]).to be <= result[:threshold],
    "PDF diff #{result[:diff_percent].round(4)}% exceeds threshold #{result[:threshold]}%.\n" \
    "Actual: #{result[:actual_path]}\nDiff:   #{result[:diff_path]}"
end
```

- [ ] **Step 2: Run the scenario — first run should auto-create the baseline and pass**

Ensure the Sinatra app is still running, then:

```bash
bundle exec cucumber features/invoice_api.feature --tags @pdf_visual
```

Expected: `1 scenario (1 passed)` and output line: `PDF baseline created: features/fixtures/baselines/invoice_standard.png`

If you see a `MiniMagick::Error` about Ghostscript, ensure `gs` is on your PATH: `brew install ghostscript`

- [ ] **Step 3: Verify the baseline PNG was created and inspect the mask position**

```bash
open features/fixtures/baselines/invoice_standard.png
```

Look at where the black mask rectangle falls relative to the "Generated:" line:
- If the mask **covers** the timestamp text: coordinates are correct, proceed.
- If the mask is **above or below** the text: edit `TIMESTAMP_MASK_REGION` in `features/support/pdf_comparison.rb` and adjust `y` up or down in increments of 20px. Delete the baseline and re-run to regenerate.

To find the exact y coordinate, run:

```bash
magick identify -verbose features/fixtures/baselines/invoice_standard.png | grep Geometry
```

Then open the PNG in Preview (macOS) → Tools → Inspector to read pixel coordinates of the "Generated:" text.

- [ ] **Step 4: Run the scenario a second time to confirm comparison passes (not just baseline creation)**

```bash
bundle exec cucumber features/invoice_api.feature --tags @pdf_visual
```

Expected: `1 scenario (1 passed)` with no baseline-created message (comparison ran and passed).

- [ ] **Step 5: Commit**

```bash
git add features/step_definitions/api_steps.rb
git commit -m "feat: add pdf visual baseline step definition"
```

---

## Task 5: Verify threshold configuration works

**Files:** none (env var test only)

- [ ] **Step 1: Run with a non-zero threshold to confirm the env var is respected**

```bash
PDF_DIFF_THRESHOLD=1.0 bundle exec cucumber features/invoice_api.feature --tags @pdf_visual
```

Expected: `1 scenario (1 passed)` — should still pass since same PDF produces 0% diff.

- [ ] **Step 2: Verify a corrupted PDF is rejected cleanly**

```bash
bundle exec ruby -e "
require_relative 'features/support/pdf_comparison'
begin
  PdfComparison.compare('not a pdf', 'test')
rescue => e
  puts \"Caught: \#{e.message}\"
end
"
```

Expected: `Caught: Data is not a valid PDF (missing %PDF header)`

- [ ] **Step 3: Run the full API test suite to confirm no regressions**

```bash
bundle exec cucumber features/invoice_api.feature
```

Expected: all scenarios pass.

- [ ] **Step 4: Commit**

```bash
git add features/invoice_api.feature features/step_definitions/api_steps.rb
git commit -m "feat: complete pdf visual comparison testing"
```

---

## Task 6: Run full suite and clean up

- [ ] **Step 1: Run both feature files to confirm nothing is broken**

```bash
bundle exec cucumber features/invoice_api.feature features/invoice_ui.feature
```

Expected: all scenarios pass (Sinatra app and Chrome must be running).

- [ ] **Step 2: Confirm fixtures are gitignored**

```bash
git status
```

Expected: `features/fixtures/` does **not** appear in untracked files.

- [ ] **Step 3: Final commit if any cleanup was needed**

If any files were adjusted:

```bash
git add -p
git commit -m "chore: verify pdf visual comparison integration"
```
