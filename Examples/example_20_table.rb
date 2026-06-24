#!/usr/bin/env ruby
# frozen_string_literal: true

# Example 04 — Table
#
# Creates a styled table with a header, alternating row colours, and a border.
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_04_table.rb

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
doc.set_title('Table Example')
canvas = doc.add_page(*PAGE_A4)

heading = PdfStyle.new(fns).set_size(18).set_bold
canvas.draw_text('Table Layout', 72, 40, heading.handle)
heading.close

label = PdfStyle.new(fns).set_size(10)
canvas.draw_text('Sales report — styled table with header and alternating rows:', 72, 76, label.handle)
label.close

table = PdfTable.new(fns, [180, 80, 90, 90])
table.set_header_bg(26, 86, 160)
     .set_alternate_bg(240, 245, 252)
     .set_border(200, 200, 200, 0.5)
     .set_cell_padding(5)
     .add_row('Product', 'Qty', 'Unit Price', 'Total')
     .add_row('PDF Library Pro', '3', '$400.00', '$1,200.00')
     .add_row('Report Designer', '1', '$250.00', '$250.00')
     .add_row('Integration Pack', '2', '$180.00', '$360.00')
     .add_row('Support (12 mo.)', '1', '$500.00', '$500.00')
     .add_row('', '', 'Total:', '$2,310.00')

canvas.draw_table(table.handle, 72, 92)
table.close

label2 = PdfStyle.new(fns).set_size(10)
canvas.draw_text('Borderless table:', 72, 330, label2.handle)
label2.close

report_table = PdfTable.new(fns, [200, 100, 100])
report_table.set_alternate_bg(245, 245, 245)
            .set_border(0, 0, 0, 0)
            .set_cell_padding(4)
            .add_row('Region', 'Revenue', 'Growth')
            .add_row('North America', '$1.24M', '+12%')
            .add_row('Europe', '$0.89M', '+8%')
            .add_row('Asia Pacific', '$0.45M', '+18%')
            .add_row('Other', '$0.12M', '+3%')

canvas.draw_table(report_table.handle, 72, 346)
report_table.close

canvas.close
out = File.join(output_dir, 'example_04_table.pdf')
doc.save(out)
doc.close

puts "Written to #{out}"
