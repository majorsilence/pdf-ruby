#!/usr/bin/env ruby
# Example 10 — Dashboard
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_10_dashboard.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89
margin = 40.0

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Q4 2025 Sales Dashboard')
canvas = doc.add_page(w, h)

# Title bar
canvas.draw_rect(0, 0, w, 52, fill_rgb: [30, 30, 50])
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(18).set_bold.set_color(255, 255, 255)
canvas.draw_text('Q4 2025  ·  Sales Dashboard', margin, 16, s.handle); s.close
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(9).set_color(160, 180, 220)
canvas.draw_text('Generated 2025-12-31', margin, 38, s.handle); s.close

# KPI tiles
kpis = [
  ['Total Revenue', '$4.2M',  '+12%', [26,  86,  160]],
  ['New Customers', '1,840',  '+8%',  [0,   140, 80]],
  ['Avg Order',     '$2,283', '+5%',  [180, 80,  0]],
  ['NPS Score',     '72',     '+4pt', [120, 0,   160]],
]
tile_w, tile_h = 110, 75
kpis.each_with_index do |(title, value, delta, color), i|
  col, row = i % 2, i / 2
  bx = margin + col * (tile_w + 8); by = 62 + row * (tile_h + 8)
  canvas.draw_rect(bx, by, tile_w, tile_h, fill_rgb: color)
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(8).set_color(200, 220, 255)
  canvas.draw_text(title, bx + 6, by + 10, s.handle); s.close
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(20).set_bold.set_color(255, 255, 255)
  canvas.draw_text(value, bx + 6, by + 34, s.handle); s.close
  s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(9).set_color(200, 255, 200)
  canvas.draw_text(delta, bx + 6, by + 58, s.handle); s.close
end

# Regional table
table_x = margin + 2 * (tile_w + 8) + 16
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_bold
canvas.draw_text('Regional Breakdown', table_x, 64, s.handle); s.close

table = MajorsilencePdf::PdfTable.new(lib, [110, 60, 60, 50])
table.set_header_bg(30, 30, 50)
table.set_alternate_bg(245, 245, 250)
table.set_border(210, 210, 210, 0.4)
table.set_cell_padding(4)
table.add_row('Region',        'Revenue', 'Units', 'Chg')
table.add_row('North America', '$1.7M',   '612',   '+14%')
table.add_row('Europe',        '$1.2M',   '441',   '+9%')
table.add_row('Asia Pacific',  '$0.9M',   '320',   '+18%')
table.add_row('LATAM',         '$0.3M',   '110',   '+6%')
table.add_row('Other',         '$0.1M',   '40',    '+2%')
canvas.draw_table(table, table_x, 78)
table.close

# Bar chart
chart_top = 230.0
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_bold
canvas.draw_text('Quarterly Revenue', margin, chart_top, s.handle); s.close
chart_top += 16
chart_h   = 120.0; chart_bot = chart_top + chart_h
bar_w     = 40.0;  gap       = 20.0
revenues  = [2.2, 2.8, 3.5, 4.2]
quarters  = %w[Q1 Q2 Q3 Q4]
max_rev   = revenues.max
canvas.draw_line(margin, chart_top, margin, chart_bot, 150, 150, 150, 0.5)
canvas.draw_line(margin, chart_bot, margin + revenues.size * (bar_w + gap) + gap, chart_bot, 150, 150, 150, 0.5)
lbl = MajorsilencePdf::PdfStyle.new(lib); lbl.set_size(9).set_color(80, 80, 80)
revenues.each_with_index do |rev, i|
  bx = margin + gap + i * (bar_w + gap)
  bh = chart_h * rev / max_rev
  by = chart_bot - bh
  canvas.draw_rect(bx, by, bar_w, bh, fill_rgb: [26, 86, 160])
  canvas.draw_text("$#{rev}M", bx + 2, by - 12, lbl.handle)
  canvas.draw_text(quarters[i], bx + 12, chart_bot + 6, lbl.handle)
end
lbl.close

# Product mix
mix_y = chart_bot + 40
s = MajorsilencePdf::PdfStyle.new(lib); s.set_size(11).set_bold
canvas.draw_text('Product Mix (% of Revenue)', margin, mix_y, s.handle); s.close
mix_y += 14
products = [
  ['PDF Library',   42, [26,  86,  160]],
  ['Report Engine', 28, [0,   140, 80]],
  ['Integration',   18, [220, 120, 0]],
  ['Support',       12, [160, 0,   80]],
]
bar_total_w = w - 2 * margin; x_cur = margin
ws = MajorsilencePdf::PdfStyle.new(lib); ws.set_size(8).set_color(255, 255, 255)
products.each do |_name, pct, color|
  seg_w = bar_total_w * pct / 100.0
  canvas.draw_rect(x_cur, mix_y, seg_w, 22, fill_rgb: color)
  canvas.draw_text("#{pct}%", x_cur + 4, mix_y + 7, ws.handle) if seg_w > 30
  x_cur += seg_w
end
ws.close
mix_y += 30
ls = MajorsilencePdf::PdfStyle.new(lib); ls.set_size(9)
products.each_with_index do |(name, pct, color), i|
  lx = margin + i * 115
  canvas.draw_rect(lx, mix_y, 10, 10, fill_rgb: color)
  canvas.draw_text("#{name} (#{pct}%)", lx + 14, mix_y + 2, ls.handle)
end
ls.close

canvas.close
doc.save(File.join(output_dir, 'example_10_dashboard.pdf'))
doc.close
puts "Written to #{output_dir}/example_10_dashboard.pdf"
