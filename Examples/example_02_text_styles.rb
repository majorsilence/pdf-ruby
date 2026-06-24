#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 02 — Text Styles
#
# Demonstrates font sizes, bold, italic, colours, alignment, and decorations.
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_02_text_styles.rb

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
doc.set_title('Text Styles')
canvas = doc.add_page(*PAGE_A4)

y = 50.0

h = PdfStyle.new(fns).set_size(24).set_bold
canvas.draw_text('Text Styles', 72, y, h.handle)
h.close
y += 36

# Font sizes
h = PdfStyle.new(fns).set_size(18).set_bold
canvas.draw_text('Font sizes', 72, y, h.handle)
h.close
y += 26

[8, 10, 12, 14, 18, 24].each do |size|
  s = PdfStyle.new(fns).set_size(size)
  canvas.draw_text("#{size} pt — The quick brown fox", 72, y, s.handle)
  s.close
  y += size + 6
end
y += 12

# Bold / italic
h = PdfStyle.new(fns).set_size(18).set_bold
canvas.draw_text('Bold and italic', 72, y, h.handle)
h.close
y += 26

s = PdfStyle.new(fns).set_size(12).set_bold
canvas.draw_text('Bold text', 72, y, s.handle)
s.close
y += 18

s = PdfStyle.new(fns).set_size(12).set_italic
canvas.draw_text('Italic text', 72, y, s.handle)
s.close
y += 18

s = PdfStyle.new(fns).set_size(12).set_bold.set_italic
canvas.draw_text('Bold italic text', 72, y, s.handle)
s.close
y += 28

# Colours
h = PdfStyle.new(fns).set_size(18).set_bold
canvas.draw_text('Colour', 72, y, h.handle)
h.close
y += 26

[[220, 0, 0, 'Red'], [0, 160, 0, 'Green'], [0, 0, 200, 'Blue'], [128, 128, 128, 'Gray']].each do |r, g, b, label|
  s = PdfStyle.new(fns).set_size(12).set_color(r, g, b)
  canvas.draw_text("#{label} text (r=#{r}, g=#{g}, b=#{b})", 72, y, s.handle)
  s.close
  y += 18
end
y += 10

# Alignment
h = PdfStyle.new(fns).set_size(18).set_bold
canvas.draw_text('Alignment', 72, y, h.handle)
h.close
y += 26

box_width = PAGE_A4[0] - 144

s = PdfStyle.new(fns).set_size(12).set_alignment(ALIGN_LEFT)
canvas.draw_text('Left-aligned text', 72, y, s.handle)
s.close
y += 18

s = PdfStyle.new(fns).set_size(12).set_alignment(ALIGN_CENTER)
canvas.draw_textbox('Centre-aligned text', 72, y, box_width, 20, s.handle)
s.close
y += 22

s = PdfStyle.new(fns).set_size(12).set_alignment(ALIGN_RIGHT)
canvas.draw_textbox('Right-aligned text', 72, y, box_width, 20, s.handle)
s.close
y += 28

# Decorations
h = PdfStyle.new(fns).set_size(18).set_bold
canvas.draw_text('Decoration', 72, y, h.handle)
h.close
y += 26

s = PdfStyle.new(fns).set_size(12).set_decoration(DECOR_UNDERLINE)
canvas.draw_text('Underlined text', 72, y, s.handle)
s.close
y += 18

s = PdfStyle.new(fns).set_size(12).set_decoration(DECOR_STRIKETHROUGH)
canvas.draw_text('Strikethrough text', 72, y, s.handle)
s.close
y += 18

s = PdfStyle.new(fns).set_size(12).set_decoration(DECOR_OVERLINE)
canvas.draw_text('Overline text', 72, y, s.handle)
s.close

canvas.close
out = File.join(output_dir, 'example_02_text_styles.pdf')
doc.save(out)
doc.close

puts "Written to #{out}"
