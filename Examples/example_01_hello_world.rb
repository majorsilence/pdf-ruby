#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 01 — Hello World
#
# Creates a single A4 page PDF with a title and body text.
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_01_hello_world.rb

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

doc = PdfDocument.new(fns)
doc.set_title('Hello World')
doc.set_author('Majorsilence PDF')

canvas = doc.add_page(*PAGE_A4)

heading = PdfStyle.new(fns).set_size(24).set_bold
canvas.draw_text('Hello, PDF!', 72, 80, heading.handle)
heading.close

body = PdfStyle.new(fns).set_size(12)
canvas.draw_text('This PDF was created with the Majorsilence pdfnative library.', 72, 120, body.handle)
canvas.draw_text('No .NET runtime is required — the engine runs in-process via FFI.', 72, 140, body.handle)
body.close

canvas.close

out = File.join(output_dir, 'example_01_hello_world.pdf')
doc.save(out)
doc.close

puts "Written to #{out}"
