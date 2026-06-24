#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 05 — PDF Merge
#
# Creates two PDF documents in memory and merges them into a single file.
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_05_merge.rb

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

def make_page(fns, title, body)
  doc    = PdfDocument.new(fns)
  doc.set_title(title)
  canvas = doc.add_page(*PAGE_A4)

  h = PdfStyle.new(fns).set_size(20).set_bold
  canvas.draw_text(title, 72, 80, h.handle)
  h.close

  b = PdfStyle.new(fns).set_size(12)
  canvas.draw_text(body, 72, 120, b.handle)
  b.close

  canvas.close
  bytes = doc.save_to_memory
  doc.close
  bytes
end

pdf1 = make_page(fns, 'Document 1 — Cover',    'This is the first document, rendered into memory.')
pdf2 = make_page(fns, 'Document 2 — Appendix', 'This is the second document, also rendered into memory.')

merger = PdfMerger.new(fns)
merger.add_bytes(pdf1)
merger.add_bytes(pdf2)

out = File.join(output_dir, 'example_05_merge.pdf')
merger.save(out)
merger.close

puts "Merged PDF written to #{out}"
