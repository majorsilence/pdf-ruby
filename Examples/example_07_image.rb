#!/usr/bin/env ruby
# Example 07 — Image
#
# Usage:
#   PDFNATIVE_LIB=/path/to/libpdfnative.so ruby example_07_image.rb
#   PDFNATIVE_LIB=... JPEG_PATH=/path/to/photo.jpg ruby example_07_image.rb

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_pdf'

lib_path  = ENV['PDFNATIVE_LIB'] or abort 'Set PDFNATIVE_LIB.'
jpeg_path = ENV['JPEG_PATH'].to_s
output_dir = File.join(__dir__, 'output')
FileUtils.mkdir_p(output_dir)

lib    = MajorsilencePdf::PdfLibrary.load(lib_path)
w, h   = 595.28, 841.89

def make_gradient(pw, ph)
  pixels = String.new
  ph.times do |py|
    pw.times do |px|
      pixels << [(255 * px / pw).to_i, (255 * py / ph).to_i, 180].pack('CCC')
    end
  end
  pixels
end

def make_checkerboard(pw, ph, cell = 20)
  pixels = String.new
  ph.times do |py|
    pw.times do |px|
      v = ((px / cell) + (py / cell)).even? ? 255 : 60
      pixels << [v, v, v].pack('CCC')
    end
  end
  pixels
end

doc    = MajorsilencePdf::PdfDocument.new(lib)
doc.set_title('Image Embedding')
canvas = doc.add_page(w, h)

heading = MajorsilencePdf::PdfStyle.new(lib); heading.set_size(18).set_bold
canvas.draw_text('Image Embedding', 72, 40, heading.handle); heading.close

label = MajorsilencePdf::PdfStyle.new(lib); label.set_size(10)
y     = 70.0

# Gradient
canvas.draw_text('Synthetic gradient (raw RGB24, 300×150 pixels):', 72, y, label.handle); y += 14
grad = make_gradient(300, 150)
canvas.draw_image(grad, 300, 150, 72, y, 300, 150, is_jpeg: false); y += 165

# Checkerboard
canvas.draw_text('Checkerboard pattern (raw RGB24, 200×100):', 72, y, label.handle); y += 14
checker = make_checkerboard(200, 100)
canvas.draw_image(checker, 200, 100, 72, y, 200, 100, is_jpeg: false); y += 115

# Scaled
canvas.draw_text('Same gradient at different scales:', 72, y, label.handle); y += 14
x_pos = 72
[[80, 40], [120, 60], [160, 80]].each do |dw, dh|
  canvas.draw_image(grad, 300, 150, x_pos, y, dw, dh, is_jpeg: false)
  canvas.draw_text("#{dw}×#{dh} pts", x_pos, y + dh + 2, label.handle)
  x_pos += dw + 10
end
y += 100

# JPEG from disk
if !jpeg_path.empty? && File.exist?(jpeg_path)
  canvas.draw_text("JPEG from disk: #{File.basename(jpeg_path)}", 72, y, label.handle); y += 14
  canvas.draw_image(File.binread(jpeg_path), 0, 0, 72, y, 200, 150, is_jpeg: true)
else
  canvas.draw_text('Set JPEG_PATH=/path/to/photo.jpg to embed a JPEG from disk.', 72, y, label.handle)
end

label.close
canvas.close
doc.save(File.join(output_dir, 'example_07_image.pdf'))
doc.close
puts "Written to #{output_dir}/example_07_image.pdf"
