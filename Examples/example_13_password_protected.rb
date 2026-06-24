#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 06 — Password Protection (Security)
#
# Creates an AES-256 password-protected PDF.
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_06_security.rb

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
doc.set_title('Password Protected Document')
doc.set_author('Majorsilence PDF')
doc.set_security(
  user_password:  'userpass',
  owner_password: 'ownerpass',
  permissions:    PERM_PRINT | PERM_COPY_TEXT | PERM_PRINT_HIGH_QUALITY,
  aes256:         true
)

canvas = doc.add_page(*PAGE_A4)

heading = PdfStyle.new(fns).set_size(20).set_bold
canvas.draw_text('Password Protected PDF', 72, 80, heading.handle)
heading.close

body = PdfStyle.new(fns).set_size(12)
canvas.draw_text('This document is encrypted with AES-256.', 72, 120, body.handle)
canvas.draw_text('Open it with password: userpass', 72, 140, body.handle)
canvas.draw_text('Full editing requires password: ownerpass', 72, 160, body.handle)
canvas.draw_text('Allowed operations: Print, CopyText, PrintHighQuality', 72, 180, body.handle)
body.close

canvas.close

out = File.join(output_dir, 'example_06_security.pdf')
doc.save(out)
doc.close

puts "Password-protected PDF written to #{out}"
puts 'User password: userpass   |   Owner password: ownerpass'
