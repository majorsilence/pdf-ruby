#!/usr/bin/env ruby
# Example 11 — Font Registry
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so \
#   FONT_DIR=/usr/share/fonts/truetype/liberation \
#   ruby example_11_font_registry.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
font_dir  = ENV['FONT_DIR'].to_s
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89
sample = 'The quick brown fox jumps over the lazy dog  0123456789'

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Font Registry')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Font Registry', 72, 50, heading.handle); heading.close

y          = 80.0
font_files = font_dir.empty? ? [] : Dir.glob(File.join(font_dir, '*.ttf')).sort.first(12)

if font_files.any?
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(9).set_color(100, 100, 100)
  canvas.draw_text("Loaded #{font_files.size} font(s) from #{font_dir}", 72, y, s.handle); s.close
  y += 16

  font_files.each do |font_path|
    name = File.basename(font_path, '.*')
    lbl  = MajorsilencePdf::PdfStyle.new(lib); lbl.set_size(8).set_color(100, 100, 100)
    canvas.draw_text(name, 72, y, lbl.handle); lbl.close; y += 11
    s = MajorsilencePdf::PdfStyle.new(lib); s.set_font_file(font_path).set_size(12)
    canvas.draw_text(sample, 72, y, s.handle); s.close; y += 20
    canvas.draw_line(72, y, w - 72, y, 220, 220, 220, 0.3); y += 6
  end
else
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_color(180, 0, 0)
  canvas.draw_text('FONT_DIR not set — falling back to built-in Helvetica.', 72, y, s.handle); y += 16
  canvas.draw_text('Set FONT_DIR to a directory of .ttf files.', 72, y, s.handle); s.close; y += 30

  [
    ['Regular',     false, false],
    ['Bold',        true,  false],
    ['Italic',      false, true],
    ['Bold-Italic', true,  true],
  ].each do |variant, bold, italic|
    lbl = MajorsilencePdf::PdfStyle.new(lib); lbl.set_size(8).set_color(100, 100, 100)
    canvas.draw_text("Helvetica #{variant}", 72, y, lbl.handle); lbl.close; y += 11
    s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(12)
    s.set_bold   if bold
    s.set_italic if italic
    canvas.draw_text(sample, 72, y, s.handle); s.close; y += 20
  end
end

canvas.close
doc.save(File.join(output_dir, 'example_11_font_registry.pdf'))
doc.close
puts "Written to #{output_dir}/example_11_font_registry.pdf"
