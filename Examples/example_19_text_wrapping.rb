#!/usr/bin/env ruby
# Example 19 — Text Wrapping
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_19_text_wrapping.rb

# frozen_string_literal: true
$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89
margin = 60.0
tw     = w - 2 * margin

lorem = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod ' \
        'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, ' \
        'quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo ' \
        'consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse ' \
        'cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non ' \
        'proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Text Wrapping')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Text Wrapping with draw_textbox', margin, 44, heading.handle); heading.close

y     = 70.0
lbl_s = MajorsilencePdf::PdfStyle.new(lib); lbl_s.set_size(9).set_bold.set_color(26, 86, 160)

[
  ['Left-aligned (full width)', MajorsilencePdf::ALIGN_LEFT],
  ['Centred',                   MajorsilencePdf::ALIGN_CENTER],
  ['Right-aligned',             MajorsilencePdf::ALIGN_RIGHT],
].each do |label, align|
  canvas.draw_text(label, margin, y, lbl_s.handle); y += 12
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_alignment(align)
  canvas.draw_textbox(lorem, margin, y, tw, 80, s.handle); s.close
  canvas.draw_rect(margin, y, tw, 80, stroke_rgb: [200, 200, 200], stroke_width: 0.3)
  y += 92
end

# Narrow two-column layout
canvas.draw_text('Narrow column (160 pt wide)', margin, y, lbl_s.handle); y += 12
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_alignment(MajorsilencePdf::ALIGN_LEFT)
canvas.draw_textbox(lorem, margin, y, 160, 200, s.handle); s.close
canvas.draw_rect(margin, y, 160, 200, stroke_rgb: [200, 200, 200], stroke_width: 0.3)

s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_alignment(MajorsilencePdf::ALIGN_LEFT)
canvas.draw_textbox(lorem, margin + 180, y, 160, 200, s.handle); s.close
canvas.draw_rect(margin + 180, y, 160, 200, stroke_rgb: [200, 200, 200], stroke_width: 0.3)

lbl_s.close
canvas.close
doc.save(File.join(output_dir, 'example_19_text_wrapping.pdf'))
doc.close
puts "Written to #{output_dir}/example_19_text_wrapping.pdf"
