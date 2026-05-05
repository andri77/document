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
