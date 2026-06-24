#!/usr/bin/env ruby
# Example 09 — Invoice
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_09_invoice.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89
margin = 60.0
br, bg, bb = 26, 86, 160

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Invoice #INV-2025-042')
doc.set_author('Acme Corporation')
canvas = doc.add_page(w, h)

# Header band
canvas.draw_rect(0, 0, w, 100, fill_rgb: [br, bg, bb])
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(28).set_bold.set_color(255, 255, 255)
canvas.draw_text('ACME CORPORATION', margin, 30, s.handle); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_color(180, 210, 255)
canvas.draw_text('123 Enterprise Drive · Silicon Valley, CA 94025', margin, 62, s.handle)
canvas.draw_text('billing@acme.example  ·  +1 (800) 555-0100', margin, 78, s.handle); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(22).set_bold.set_color(255, 255, 255)
canvas.draw_text('INVOICE', w - 160, 40, s.handle); s.close

# Metadata
y_meta    = 118.0
meta_right = w - margin - 140
label_s = MajorsilencePdf::PdfStyle.new(lib); label_s.set_size(9).set_color(100, 100, 100)
value_s = MajorsilencePdf::PdfStyle.new(lib); value_s.set_size(10).set_bold
[
  ['Invoice No.', 'INV-2025-042'],
  ['Date',        '2025-11-15'],
  ['Due Date',    '2025-12-15'],
  ['Currency',    'USD'],
].each do |k, v|
  canvas.draw_text(k, meta_right, y_meta, label_s.handle)
  canvas.draw_text(v, meta_right + 70, y_meta, value_s.handle)
  y_meta += 16
end
label_s.close; value_s.close

# Bill To
y_bill = 118.0
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(9).set_bold.set_color(br, bg, bb)
canvas.draw_text('BILL TO', margin, y_bill, s.handle); s.close
y_bill += 14
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10).set_bold
canvas.draw_text('Globex Enterprises Ltd.', margin, y_bill, s.handle); s.close
y_bill += 14
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(10)
['Attn: Mr. H. J. Simpson', '742 Evergreen Terrace', 'Springfield, IL 62701'].each do |line|
  canvas.draw_text(line, margin, y_bill, s.handle); y_bill += 14
end; s.close

# Divider and table
y = 220.0
canvas.draw_line(margin, y, w - margin, y, 200, 200, 200, 0.5)
y += 12

table = MajorsilencePdf::PdfTable.new(lib, [210, 50, 80, 80, 80])
table.set_header_bg(br, bg, bb)
table.set_alternate_bg(245, 248, 255)
table.set_border(210, 210, 210, 0.5)
table.set_cell_padding(5)
table.add_row('Description',     'Qty', 'Unit Price', 'Discount', 'Line Total')
table.add_row('PDF Library Pro',  '3',   '$400.00',    '10%',      '$1,080.00')
table.add_row('Report Designer',  '1',   '$250.00',    '—',        '$250.00')
table.add_row('Integration Pack', '2',   '$180.00',    '—',        '$360.00')
table.add_row('Priority Support', '1',   '$500.00',    '—',        '$500.00')
canvas.draw_table(table, margin, y)
table.close
y += 185

# Totals
canvas.draw_line(w - 220, y, w - margin, y, br, bg, bb, 0.5)
y += 6
[
  ['Subtotal',  '$2,190.00', false],
  ['Tax (8%)',  '$175.20',   false],
  ['Total Due', '$2,365.20', true],
].each do |lbl, amt, is_total|
  s = MajorsilencePdf::PdfStyle.new(lib)
  s.set_size(is_total ? 11 : 10)
  s.set_bold if is_total
  canvas.draw_text(lbl, w - 220, y, s.handle)
  canvas.draw_text(amt, w - margin - 60, y, s.handle)
  s.close; y += 18
end
canvas.draw_line(w - 220, y, w - margin, y, br, bg, bb, 1.0)

# Footer
canvas.draw_line(margin, h - 60, w - margin, h - 60, 200, 200, 200, 0.5)
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(8).set_color(130, 130, 130)
canvas.draw_text('Payment terms: Net 30. Make cheques payable to Acme Corporation.', margin, h - 48, s.handle)
canvas.draw_text('Bank: First National · Routing 021000021 · Account 123456789', margin, h - 36, s.handle)
s.close

canvas.close
doc.save(File.join(output_dir, 'example_09_invoice.pdf'))
doc.close
puts "Written to #{output_dir}/example_09_invoice.pdf"
