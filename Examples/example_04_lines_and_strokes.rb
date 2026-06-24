#!/usr/bin/env ruby
# Example 04 — Lines and Strokes
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_04_lines_and_strokes.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB to the path of the pdfnative shared library.'
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Lines and Strokes')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib)
heading.set_size(18).set_bold
canvas.draw_text('Lines and Strokes', 72, 40, heading.handle)
heading.close

label = MajorsilencePdf::PdfStyle.new(lib)
label.set_size(10)

y = 80.0

canvas.draw_text('Line widths (0.5 → 6 pt)', 72, y, label.handle)
y += 16
[0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0].each do |lw|
  canvas.draw_line(72, y, 420, y, 0, 0, 0, lw)
  canvas.draw_text("#{lw} pt", 430, y - 4, label.handle)
  y += 18
end
y += 12

canvas.draw_text('Coloured lines (2 pt)', 72, y, label.handle)
y += 16
[
  ['Black',  0,   0,   0  ],
  ['Red',    220, 0,   0  ],
  ['Blue',   0,   0,   200],
  ['Green',  0,   160, 0  ],
  ['Orange', 220, 120, 0  ],
  ['Purple', 130, 0,   180],
].each do |name, r, g, b|
  canvas.draw_line(72, y, 300, y, r, g, b, 2)
  canvas.draw_text(name, 310, y - 4, label.handle)
  y += 18
end
y += 12

canvas.draw_text('Diagonal lines', 72, y, label.handle)
y += 16
canvas.draw_line(72,  y,       300, y + 80, 0,   0,   0,   1)
canvas.draw_line(300, y,       72,  y + 80, 0,   0,   0,   1)
canvas.draw_line(72,  y + 40,  300, y + 40, 180, 180, 180, 0.5)
y += 100

canvas.draw_text('Rectangle drawn from four lines', 72, y, label.handle)
y += 16
x0, x1, y1 = 72, 300, y + 60
[[x0, y, x1, y], [x1, y, x1, y1], [x1, y1, x0, y1], [x0, y1, x0, y]].each do |ax, ay, bx, by|
  canvas.draw_line(ax, ay, bx, by, 60, 60, 60, 2)
end
canvas.draw_text('Border from 4 draw_line calls', x0 + 10, y + 26, label.handle)
y += 80

canvas.draw_text('Heavy rule separator', 72, y, label.handle)
y += 12
canvas.draw_line(72, y, w - 72, y, 26, 86, 160, 3)
y += 8
canvas.draw_line(72, y, w - 72, y, 26, 86, 160, 0.5)

label.close
canvas.close
doc.save(File.join(output_dir, 'example_04_lines_and_strokes.pdf'))
doc.close

puts "Written to #{output_dir}/example_04_lines_and_strokes.pdf"
