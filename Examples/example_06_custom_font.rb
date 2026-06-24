#!/usr/bin/env ruby
# Example 06 — Custom Font
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so \
#   CUSTOM_FONT_PATH=/path/to/MyFont.ttf \
#   ruby example_06_custom_font.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB']       or abort 'Set PDFNATIVE_LIB.'
font_path = ENV['CUSTOM_FONT_PATH'].to_s
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Custom Font')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib)
heading.set_size(18).set_bold
canvas.draw_text('Custom Font Embedding', 72, 50, heading.handle)
heading.close

if !font_path.empty? && File.exist?(font_path)
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_color(80, 80, 80)
  canvas.draw_text("Font file: #{File.basename(font_path)}", 72, 78, s.handle); s.close

  y = 100.0
  [10, 12, 14, 18, 24, 32].each do |size|
    s = MajorsilencePdf::PdfStyle.new(lib); s.set_font_file(font_path).set_size(size)
    canvas.draw_text("#{size} pt — The quick brown fox jumps over the lazy dog", 72, y, s.handle); s.close
    y += size + 8
  end
  y += 10
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_font_file(font_path).set_size(14).set_bold
  canvas.draw_text('Bold variant (if supported by the font file):', 72, y, s.handle); s.close
  y += 22
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_font_file(font_path).set_size(12).set_italic
  canvas.draw_text('Italic variant (if supported by the font file):', 72, y, s.handle); s.close
else
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_color(180, 0, 0)
  canvas.draw_text('CUSTOM_FONT_PATH not set or file not found.', 72, 100, s.handle)
  canvas.draw_text('Set CUSTOM_FONT_PATH=/path/to/a/TrueType.ttf and re-run.', 72, 118, s.handle); s.close

  y = 152.0
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_color(80, 80, 80)
  canvas.draw_text('Falling back to built-in Helvetica:', 72, y, s.handle); s.close
  y += 18
  [10, 12, 14, 18, 24].each do |size|
    s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(size)
    canvas.draw_text("#{size} pt — The quick brown fox (Helvetica)", 72, y, s.handle); s.close
    y += size + 8
  end
end

canvas.close
doc.save(File.join(output_dir, 'example_06_custom_font.pdf'))
doc.close
puts "Written to #{output_dir}/example_06_custom_font.pdf"
