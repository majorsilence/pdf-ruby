#!/usr/bin/env ruby
# Example 08 — Annotations (Hyperlinks)
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_08_annotations.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Annotations')
doc.set_subject('Hyperlink annotation demo')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Hyperlink Annotations', 72, 50, heading.handle); heading.close

body = MajorsilencePdf::PdfStyle.new(lib); body.set_size(11)
canvas.draw_text(
  'Click the links below. The blue underlined text is overlaid with a URI annotation.',
  72, 80, body.handle
); body.close

y = 120.0
links = [
  ['Majorsilence GitHub',          'https://github.com/majorsilence'],
  ['Majorsilence Reporting',        'https://github.com/majorsilence/Reporting'],
  ['PDF Specification (ISO 32000)', 'https://pdfa.org/resource/pdf-specification-archive/'],
  ['Wikipedia — PDF',               'https://en.wikipedia.org/wiki/PDF'],
]

link_style = MajorsilencePdf::PdfStyle.new(lib)
link_style.set_size(13).set_color(26, 86, 160).set_decoration(MajorsilencePdf::DECOR_UNDERLINE)
links.each do |text, uri|
  canvas.draw_text(text, 72, y, link_style.handle)
  approx_width = text.length * 7.5
  canvas.add_link(72, y - 13, approx_width, 18, uri)
  y += 28
end
link_style.close

y += 10
note = MajorsilencePdf::PdfStyle.new(lib); note.set_size(10).set_color(100, 100, 100)
canvas.draw_text('Links use pdf_canvas_add_link(canvas, x, y, width, height, uri).', 72, y, note.handle)
y += 16
canvas.draw_text('The annotation rectangle is placed over the rendered text.', 72, y, note.handle)
note.close

canvas.close
doc.save(File.join(output_dir, 'example_08_annotations.pdf'))
doc.close
puts "Written to #{output_dir}/example_08_annotations.pdf"
