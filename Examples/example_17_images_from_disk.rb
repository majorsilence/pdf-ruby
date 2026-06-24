#!/usr/bin/env ruby
# Example 17 — Images from Disk
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so IMAGE_DIR=/path/to/photos ruby example_17_images_from_disk.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path   = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
image_dir  = ENV['IMAGE_DIR'].to_s
image_path = ENV['IMAGE_PATH'].to_s
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89
margin = 50.0

def synthetic_rgb(pw, ph, r_base, g_base, b_base)
  pixels = String.new
  ph.times do |py|
    pw.times do |px|
      pixels << [[r_base + px * 2, 255].min, [g_base + py * 2, 255].min, b_base].pack('CCC')
    end
  end
  pixels
end

jpeg_paths =
  if !image_path.empty? && File.exist?(image_path)
    [image_path]
  elsif !image_dir.empty? && File.directory?(image_dir)
    (Dir.glob(File.join(image_dir, '*.jpg')) + Dir.glob(File.join(image_dir, '*.jpeg'))).sort.first(6)
  else
    []
  end

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Images from Disk')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Images from Disk', margin, 40, heading.handle); heading.close

cap_s = MajorsilencePdf::PdfStyle.new(lib); cap_s.set_size(8).set_color(80, 80, 80)
y     = 68.0

if jpeg_paths.any?
  info = MajorsilencePdf::PdfStyle.new(lib); info.set_size(9).set_color(80, 80, 80)
  canvas.draw_text("Embedding #{jpeg_paths.size} JPEG(s)", margin, y, info.handle); info.close
  y += 14

  thumb_w, thumb_h = 140, 105
  cols = 3
  jpeg_paths.each_with_index do |path, i|
    col, row = i % cols, i / cols
    bx = margin + col * (thumb_w + 8)
    by = y + row * (thumb_h + 24)
    canvas.draw_image(File.binread(path), 0, 0, bx, by, thumb_w, thumb_h, is_jpeg: true)
    canvas.draw_text(File.basename(path), bx, by + thumb_h + 4, cap_s.handle)
  end
else
  info = MajorsilencePdf::PdfStyle.new(lib); info.set_size(10).set_color(160, 80, 0)
  canvas.draw_text('IMAGE_DIR or IMAGE_PATH not set. Using synthetic images.', margin, y, info.handle)
  info.close
  y += 18

  synthetics = [
    ['Red-gradient',    200, 80,  0],
    ['Blue-gradient',   0,   80,  200],
    ['Green-gradient',  0,   160, 80],
    ['Purple-gradient', 120, 0,   160],
  ]
  thumb_w, thumb_h = 100, 60
  synthetics.each_with_index do |(label, r, g, b), i|
    data = synthetic_rgb(thumb_w, thumb_h, r, g, b)
    bx   = margin + i * (thumb_w + 10)
    canvas.draw_image(data, thumb_w, thumb_h, bx, y, thumb_w, thumb_h, is_jpeg: false)
    canvas.draw_text(label, bx, y + thumb_h + 4, cap_s.handle)
  end
  y += thumb_h + 24

  note = MajorsilencePdf::PdfStyle.new(lib); note.set_size(9).set_color(130, 130, 130)
  canvas.draw_textbox(
    'Set IMAGE_DIR=/path/to/photos to embed real JPEG images, ' \
    'or IMAGE_PATH=/path/to/photo.jpg for a single image.',
    margin, y, w - 2 * margin, 50, note.handle
  ); note.close
end
cap_s.close

canvas.close
doc.save(File.join(output_dir, 'example_17_images_from_disk.pdf'))
doc.close
puts "Written to #{output_dir}/example_17_images_from_disk.pdf"
