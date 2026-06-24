#!/usr/bin/env ruby
# Example 15 — RTL Text
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_15_rtl_text.rb
#   PDFNATIVE_LIB=... RTL_FONT_PATH=/path/to/NotoSansArabic.ttf ruby example_15_rtl_text.rb

# frozen_string_literal: true
$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
rtl_font  = ENV['RTL_FONT_PATH'].to_s
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib  = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h = 595.28, 841.89

rtl_samples = [
  ['Arabic — مرحبا بالعالم',  'مرحبا بالعالم! هذا مثال على النص العربي في ملف PDF.'],
  ['Arabic — رقم',             '١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩ ٠'],
  ['Hebrew — שלום עולם',       'שלום! זהו טקסט עברי בתוך קובץ PDF.'],
  ['Bidirectional — EN/AR',    'Price: ٢٥٠ USD — السعر: ٢٥٠ دولار'],
]

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('RTL Text')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Right-to-Left Text', 72, 50, heading.handle); heading.close

info = MajorsilencePdf::PdfStyle.new(lib); info.set_size(10)
if !rtl_font.empty? && File.exist?(rtl_font)
  info.set_color(0, 100, 0)
  canvas.draw_text("RTL font: #{File.basename(rtl_font)}", 72, 72, info.handle)
else
  info.set_color(160, 80, 0)
  canvas.draw_text('RTL_FONT_PATH not set. Glyphs may not render correctly.', 72, 72, info.handle)
end
info.close

y     = 100.0
lbl_s = MajorsilencePdf::PdfStyle.new(lib); lbl_s.set_size(9).set_color(100, 100, 100)
rtl_s = MajorsilencePdf::PdfStyle.new(lib); rtl_s.set_size(14).set_alignment(MajorsilencePdf::ALIGN_RIGHT)
rtl_s.set_font_file(rtl_font) if !rtl_font.empty? && File.exist?(rtl_font)

rtl_samples.each do |label, text|
  canvas.draw_text(label, 72, y, lbl_s.handle); y += 14
  canvas.draw_text(text,  72, y, rtl_s.handle); y += 24
  canvas.draw_line(72, y, w - 72, y, 220, 220, 220, 0.3); y += 8
end
lbl_s.close; rtl_s.close

note = MajorsilencePdf::PdfStyle.new(lib); note.set_size(9).set_color(130, 130, 130)
canvas.draw_textbox(
  'Note: Full RTL shaping (ligatures, contextual forms) requires an OpenType font ' \
  'with Arabic/Hebrew GSUB/GPOS tables and a shaping engine (e.g. HarfBuzz).',
  72, y + 10, w - 144, 60, note.handle
); note.close

canvas.close
doc.save(File.join(output_dir, 'example_15_rtl_text.pdf'))
doc.close
puts "Written to #{output_dir}/example_15_rtl_text.pdf"
