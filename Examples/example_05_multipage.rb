#!/usr/bin/env ruby
# Example 05 — Multi-Page Document
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_05_multipage.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB to the path of the pdfnative shared library.'
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib  = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h = 595.28, 841.89

doc = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Multi-Page Document')
doc.set_author('Majorsilence PDF')

# ── Page 1: Cover ──────────────────────────────────────────────────────────────
canvas = doc.add_page(w, h)
canvas.draw_rect(0, 0, w, 200, fill_rgb: [26, 86, 160])
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(32).set_bold.set_color(255, 255, 255)
canvas.draw_text('Annual Report 2025', 72, 80, s.handle); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(14).set_color(200, 220, 255)
canvas.draw_text('Majorsilence Corporation', 72, 130, s.handle); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(12)
canvas.draw_text('This document demonstrates a multi-page PDF with cover, content, and summary.', 72, 250, s.handle); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_color(120, 120, 120)
canvas.draw_text('Page 1 of 3', 72, h - 40, s.handle); s.close
canvas.close

# ── Page 2: Content ────────────────────────────────────────────────────────────
canvas = doc.add_page(w, h)
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(18).set_bold
canvas.draw_text('Section 1 — Overview', 72, 60, s.handle); s.close
canvas.draw_line(72, 80, w - 72, 80, 26, 86, 160, 1.5)
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11)
canvas.draw_textbox(
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor ' \
  'incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud ' \
  'exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
  72, 96, w - 144, 80, s.handle
); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(14).set_bold
canvas.draw_text('Key Metrics', 72, 200, s.handle); s.close

[
  ['Revenue', '$4.2M'], ['Customers', '1,840'],
  ['New Products', '12'], ['Net Score', '72'],
].each_with_index do |(name, value), i|
  col, row = i % 2, i / 2
  bx = 72 + col * 230; by = 220 + row * 80
  canvas.draw_rect(bx, by, 210, 65, fill_rgb: [240, 245, 252], stroke_rgb: [200, 210, 230], stroke_width: 0.5)
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_color(80, 80, 80)
  canvas.draw_text(name, bx + 10, by + 14, s.handle); s.close
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(20).set_bold.set_color(26, 86, 160)
  canvas.draw_text(value, bx + 10, by + 40, s.handle); s.close
end
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_color(120, 120, 120)
canvas.draw_text('Page 2 of 3', 72, h - 40, s.handle); s.close
canvas.close

# ── Page 3: Summary table ──────────────────────────────────────────────────────
canvas = doc.add_page(w, h)
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(18).set_bold
canvas.draw_text('Section 2 — Regional Summary', 72, 60, s.handle); s.close
canvas.draw_line(72, 80, w - 72, 80, 26, 86, 160, 1.5)

table = MajorsilencePdf::PdfTable.new(lib, [160, 90, 90, 90, 90])
table.set_header_bg(26, 86, 160)
table.set_alternate_bg(240, 245, 252)
table.set_border(200, 200, 200, 0.5)
table.set_cell_padding(5)
table.add_row('Region',        'Q1',    'Q2',    'Q3',    'Q4')
table.add_row('North America', '$1.1M', '$1.0M', '$1.2M', '$1.4M')
table.add_row('Europe',        '$0.7M', '$0.8M', '$0.9M', '$0.8M')
table.add_row('Asia Pacific',  '$0.3M', '$0.4M', '$0.4M', '$0.5M')
table.add_row('Other',         '$0.1M', '$0.1M', '$0.1M', '$0.1M')
table.add_row('Total',         '$2.2M', '$2.3M', '$2.6M', '$2.8M')
canvas.draw_table(table, 72, 96)
table.close

s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_color(120, 120, 120)
canvas.draw_text('Page 3 of 3', 72, h - 40, s.handle); s.close
canvas.close

doc.save(File.join(output_dir, 'example_05_multipage.pdf'))
doc.close
puts "Written to #{output_dir}/example_05_multipage.pdf"
