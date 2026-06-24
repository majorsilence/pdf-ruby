#!/usr/bin/env ruby
# Example 12 — Unicode Text
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_12_unicode.rb
#   PDFNATIVE_LIB=... UNICODE_FONT_PATH=/path/to/NotoSans-Regular.ttf ruby example_12_unicode.rb

# frozen_string_literal: true
$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
uni_font  = ENV['UNICODE_FONT_PATH'].to_s
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib  = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h = 595.28, 841.89

samples = [
  ['Latin (basic)',   'Hello, World! 0 1 2 3 4 5 6 7 8 9'],
  ['Latin extended',  'Héllo Wörld — café, naïve, résumé, façade'],
  ['Greek',           'Ελληνικά — Αλφάβητο Αβγδεζηθ'],
  ['Cyrillic',        'Привет мир — кириллица'],
  ['Symbols',         '© ® ™ € £ ¥ § ¶ † ‡ • … ‰'],
  ['Arrows & math',   '← → ↑ ↓ ↔ ∑ ∏ √ ∞ ≠ ≤ ≥ ∈'],
  ['Box drawing',     '┌─┬─┐  │ │ │  ├─┼─┤  └─┴─┘'],
]

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Unicode Text')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Unicode Text Rendering', 72, 50, heading.handle); heading.close

if !uni_font.empty? && File.exist?(uni_font)
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(9).set_color(80, 80, 80)
  canvas.draw_text("Using font: #{File.basename(uni_font)}", 72, 72, s.handle); s.close
end

y     = 90.0
lbl_s = MajorsilencePdf::PdfStyle.new(lib); lbl_s.set_size(8).set_color(100, 100, 100)
smp_s = MajorsilencePdf::PdfStyle.new(lib); smp_s.set_size(12)
smp_s.set_font_file(uni_font) if !uni_font.empty? && File.exist?(uni_font)

samples.each do |script, text|
  canvas.draw_text(script, 72, y, lbl_s.handle); y += 12
  canvas.draw_text(text,   72, y, smp_s.handle); y += 20
  canvas.draw_line(72, y, w - 72, y, 220, 220, 220, 0.3); y += 6
end
lbl_s.close; smp_s.close

note = MajorsilencePdf::PdfStyle.new(lib); note.set_size(8).set_color(130, 130, 130)
canvas.draw_text(
  'Tip: set UNICODE_FONT_PATH to a wide-coverage font (e.g. Noto Sans) for full glyph rendering.',
  72, y + 10, note.handle
); note.close

canvas.close
doc.save(File.join(output_dir, 'example_12_unicode.pdf'))
doc.close
puts "Written to #{output_dir}/example_12_unicode.pdf"
