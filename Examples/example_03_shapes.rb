#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 03 — Shapes
#
# Draws lines, rectangles (filled/stroked/both), and ellipses.
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_03_shapes.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf/pdf_native'

lib_path = ENV.fetch('PDFNATIVE_LIB', '')
if lib_path.empty?
  warn 'Set PDFNATIVE_LIB to the path of the pdfnative shared library.'
  exit 1
end

output_dir = File.join(__dir__, 'output')
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

fns = PdfLibrary.load(lib_path)

doc    = PdfDocument.new(fns)
doc.set_title('Shapes')
canvas = doc.add_page(*PAGE_A4)

y = 50.0

canvas.draw_text('Lines', 72, y)
y += 20

[[0, 0, 0, 0.5], [200, 0, 0, 1.0], [0, 0, 200, 2.0], [0, 150, 0, 3.0]].each_with_index do |(r, g, b, w), i|
  canvas.draw_line(72, y + i * 14, 400, y + i * 14, r: r, g: g, b: b, width: w)
end
y += 80

canvas.draw_text('Filled rectangles', 72, y)
y += 16

colors = [[220, 50, 50], [50, 150, 50], [50, 50, 220], [200, 150, 0]]
colors.each_with_index do |(r, g, b), i|
  canvas.draw_rect(72 + i * 110, y, 100, 60, fill_rgb: [r, g, b])
end
y += 80

canvas.draw_text('Stroked rectangles', 72, y)
y += 16

colors.each_with_index do |(r, g, b), i|
  canvas.draw_rect(72 + i * 110, y, 100, 60, stroke_rgb: [r, g, b], stroke_width: 2.0)
end
y += 80

canvas.draw_text('Filled + stroked rectangles', 72, y)
y += 16

canvas.draw_rect(72,  y, 100, 60, fill_rgb: [240, 200, 200], stroke_rgb: [180, 0, 0],   stroke_width: 2.0)
canvas.draw_rect(182, y, 100, 60, fill_rgb: [200, 240, 200], stroke_rgb: [0, 160, 0],   stroke_width: 2.0)
canvas.draw_rect(292, y, 100, 60, fill_rgb: [200, 220, 255], stroke_rgb: [0, 0, 180],   stroke_width: 2.0)
y += 90

canvas.draw_text('Ellipses', 72, y)
y += 16

canvas.draw_ellipse(72,  y, 120, 80, fill_rgb: [220, 80, 80])
canvas.draw_ellipse(210, y, 120, 80, fill_rgb: [80, 200, 80])
canvas.draw_ellipse(348, y, 100, 80, stroke_rgb: [0, 0, 200], stroke_width: 2.0)
y += 100

canvas.draw_text('Crosshair in circle', 72, y)
y += 16

cx = 160; cy = y + 50; r = 40
canvas.draw_ellipse(cx - r, cy - r, r * 2, r * 2, stroke_rgb: [0, 0, 0], stroke_width: 1.0)
canvas.draw_line(cx - r, cy, cx + r, cy, r: 0, g: 0, b: 0, width: 0.5)
canvas.draw_line(cx, cy - r, cx, cy + r, r: 0, g: 0, b: 0, width: 0.5)

canvas.close
out = File.join(output_dir, 'example_03_shapes.pdf')
doc.save(out)
doc.close

puts "Written to #{out}"
