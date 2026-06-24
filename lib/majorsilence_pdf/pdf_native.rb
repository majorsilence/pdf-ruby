# frozen_string_literal: true

require 'fiddle'
require 'fiddle/import'
require 'tempfile'

# Ruby Fiddle wrapper for the pdfnative shared library.
#
# Loads the Majorsilence PDF engine in-process via Fiddle — no subprocess
# is spawned, no .NET runtime is required on the host.
#
# Platform-specific library filenames:
#   Linux:   libpdfnative.so
#   macOS:   libpdfnative.dylib
#   Windows: pdfnative.dll
#
# Usage:
#   require 'majorsilence_pdf/pdf_native'
#
#   lib = PdfLibrary.load('/path/to/libpdfnative.so')
#
#   doc = PdfDocument.new(lib)
#   doc.set_title('My Report')
#   canvas = doc.add_page(595.28, 841.89)
#   canvas.draw_text('Hello, PDF!', 72, 100)
#   canvas.close
#   doc.save('/tmp/output.pdf')
#   doc.close
#
# Page sizes (points):
#   A4     = [595.28, 841.89]    Letter = [612.0, 792.0]
#   A3     = [841.89, 1190.55]   Legal  = [612.0, 1008.0]
#   A5     = [419.53, 595.28]    Tabloid= [792.0, 1224.0]

# ── Page size constants ────────────────────────────────────────────────────────

PAGE_A4      = [595.28, 841.89].freeze
PAGE_A3      = [841.89, 1190.55].freeze
PAGE_A5      = [419.53, 595.28].freeze
PAGE_LETTER  = [612.0,  792.0].freeze
PAGE_LEGAL   = [612.0,  1008.0].freeze
PAGE_TABLOID = [792.0,  1224.0].freeze

# ── Style alignment constants ──────────────────────────────────────────────────

ALIGN_LEFT   = 0
ALIGN_CENTER = 1
ALIGN_RIGHT  = 2

# ── Text decoration constants ──────────────────────────────────────────────────

DECOR_NONE          = 0
DECOR_UNDERLINE     = 1
DECOR_STRIKETHROUGH = 2
DECOR_OVERLINE      = 3

# ── Encryption permission flags ───────────────────────────────────────────────

PERM_PRINT              =    4
PERM_MODIFY_CONTENT     =    8
PERM_COPY_TEXT          =   16
PERM_ADD_ANNOTATIONS    =   32
PERM_FILL_FORMS         =  256
PERM_EXTRACT_TEXT       =  512
PERM_ASSEMBLE           = 1024
PERM_PRINT_HIGH_QUALITY = 2048
PERM_ALL                =   -1

module PdfLibrary
  # Load the pdfnative shared library and initialize the engine.
  # Returns a Hash of bound Fiddle::Function objects.
  # Call this once per process before creating any PdfDocument instances.
  def self.load(lib_path)
    lib_path = File.expand_path(lib_path)
    lib_dir  = File.dirname(lib_path)

    ENV['PDFNATIVE_LIB_DIR'] = lib_dir

    # Pre-load all shared libraries in the directory with RTLD_GLOBAL so that
    # .NET 10+ runtime components are globally visible.
    ext = RUBY_PLATFORM =~ /darwin/ ? '*.dylib' : '*.so'
    Dir.glob(File.join(lib_dir, ext)).sort.each do |f|
      begin Fiddle.dlopen(f) rescue Fiddle::DLError; end
    end

    handle = Fiddle.dlopen(lib_path)

    fns = {
      pdf_init: Fiddle::Function.new(handle['pdf_init'], [], Fiddle::TYPE_INT),

      pdf_doc_create:       Fiddle::Function.new(handle['pdf_doc_create'],       [],                                                         Fiddle::TYPE_VOIDP),
      pdf_doc_set_title:    Fiddle::Function.new(handle['pdf_doc_set_title'],    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],                    Fiddle::TYPE_INT),
      pdf_doc_set_author:   Fiddle::Function.new(handle['pdf_doc_set_author'],   [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],                    Fiddle::TYPE_INT),
      pdf_doc_set_subject:  Fiddle::Function.new(handle['pdf_doc_set_subject'],  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],                    Fiddle::TYPE_INT),
      pdf_doc_set_creator:  Fiddle::Function.new(handle['pdf_doc_set_creator'],  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],                    Fiddle::TYPE_INT),
      pdf_doc_set_security: Fiddle::Function.new(handle['pdf_doc_set_security'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_doc_add_page:     Fiddle::Function.new(handle['pdf_doc_add_page'],     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT], Fiddle::TYPE_VOIDP),
      pdf_doc_save_file:    Fiddle::Function.new(handle['pdf_doc_save_file'],    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],                    Fiddle::TYPE_INT),
      pdf_doc_close:        Fiddle::Function.new(handle['pdf_doc_close'],        [Fiddle::TYPE_VOIDP],                                        Fiddle::TYPE_VOID),

      pdf_canvas_draw_text:    Fiddle::Function.new(handle['pdf_canvas_draw_text'],    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT),
      pdf_canvas_draw_textbox: Fiddle::Function.new(handle['pdf_canvas_draw_textbox'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT], Fiddle::TYPE_INT),
      pdf_canvas_draw_line:    Fiddle::Function.new(handle['pdf_canvas_draw_line'],    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_FLOAT], Fiddle::TYPE_INT),
      pdf_canvas_draw_rect:    Fiddle::Function.new(handle['pdf_canvas_draw_rect'],    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_canvas_draw_ellipse: Fiddle::Function.new(handle['pdf_canvas_draw_ellipse'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_canvas_draw_table:   Fiddle::Function.new(handle['pdf_canvas_draw_table'],   [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT],                    Fiddle::TYPE_INT),
      pdf_canvas_add_link:     Fiddle::Function.new(handle['pdf_canvas_add_link'],     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_FLOAT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT),
      pdf_canvas_close:        Fiddle::Function.new(handle['pdf_canvas_close'],        [Fiddle::TYPE_VOIDP],                                                                                Fiddle::TYPE_VOID),

      pdf_style_create:         Fiddle::Function.new(handle['pdf_style_create'],         [],                                              Fiddle::TYPE_VOIDP),
      pdf_style_set_font_family:Fiddle::Function.new(handle['pdf_style_set_font_family'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],         Fiddle::TYPE_INT),
      pdf_style_set_font_file:  Fiddle::Function.new(handle['pdf_style_set_font_file'],  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],         Fiddle::TYPE_INT),
      pdf_style_set_size:       Fiddle::Function.new(handle['pdf_style_set_size'],       [Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT],          Fiddle::TYPE_INT),
      pdf_style_set_color:      Fiddle::Function.new(handle['pdf_style_set_color'],      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_style_set_bold:       Fiddle::Function.new(handle['pdf_style_set_bold'],       [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],            Fiddle::TYPE_INT),
      pdf_style_set_italic:     Fiddle::Function.new(handle['pdf_style_set_italic'],     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],            Fiddle::TYPE_INT),
      pdf_style_set_alignment:  Fiddle::Function.new(handle['pdf_style_set_alignment'],  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],            Fiddle::TYPE_INT),
      pdf_style_set_decoration: Fiddle::Function.new(handle['pdf_style_set_decoration'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],            Fiddle::TYPE_INT),
      pdf_style_close:          Fiddle::Function.new(handle['pdf_style_close'],          [Fiddle::TYPE_VOIDP],                              Fiddle::TYPE_VOID),

      pdf_table_create:         Fiddle::Function.new(handle['pdf_table_create'],         [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],            Fiddle::TYPE_VOIDP),
      pdf_table_set_header_bg:  Fiddle::Function.new(handle['pdf_table_set_header_bg'],  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_table_set_alternate_bg:Fiddle::Function.new(handle['pdf_table_set_alternate_bg'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_table_set_border:     Fiddle::Function.new(handle['pdf_table_set_border'],     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_FLOAT], Fiddle::TYPE_INT),
      pdf_table_set_cell_padding:Fiddle::Function.new(handle['pdf_table_set_cell_padding'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_FLOAT],         Fiddle::TYPE_INT),
      pdf_table_stage_cell:     Fiddle::Function.new(handle['pdf_table_stage_cell'],     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],          Fiddle::TYPE_INT),
      pdf_table_commit_row:     Fiddle::Function.new(handle['pdf_table_commit_row'],     [Fiddle::TYPE_VOIDP],                              Fiddle::TYPE_INT),
      pdf_table_close:          Fiddle::Function.new(handle['pdf_table_close'],          [Fiddle::TYPE_VOIDP],                              Fiddle::TYPE_VOID),

      pdf_merge_create:    Fiddle::Function.new(handle['pdf_merge_create'],    [],                                               Fiddle::TYPE_VOIDP),
      pdf_merge_add_bytes: Fiddle::Function.new(handle['pdf_merge_add_bytes'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT),
      pdf_merge_save_file: Fiddle::Function.new(handle['pdf_merge_save_file'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],          Fiddle::TYPE_INT),
      pdf_merge_close:     Fiddle::Function.new(handle['pdf_merge_close'],     [Fiddle::TYPE_VOIDP],                              Fiddle::TYPE_VOID),

      pdf_last_error: Fiddle::Function.new(handle['pdf_last_error'], [], Fiddle::TYPE_VOIDP),
    }

    ret = fns[:pdf_init].call
    raise "pdf_init failed: #{last_error_str(fns)}" unless ret.zero?

    fns
  end

  def self.last_error_str(fns)
    ptr = fns[:pdf_last_error].call
    return 'unknown error' if ptr.nil? || ptr.zero?

    Fiddle::Pointer.new(ptr).to_s
  end
end

class PdfDocument
  def initialize(fns)
    @fns = fns
    h = fns[:pdf_doc_create].call
    raise "pdf_doc_create failed: #{last_error}" if h.nil? || h.zero?

    @handle = h
  end

  def set_title(title)    = check(@fns[:pdf_doc_set_title].call(@handle,   c_str(title)),   'pdf_doc_set_title')
  def set_author(author)  = check(@fns[:pdf_doc_set_author].call(@handle,  c_str(author)),  'pdf_doc_set_author')
  def set_subject(subject)= check(@fns[:pdf_doc_set_subject].call(@handle, c_str(subject)), 'pdf_doc_set_subject')
  def set_creator(creator)= check(@fns[:pdf_doc_set_creator].call(@handle, c_str(creator)), 'pdf_doc_set_creator')

  # Apply password-based AES encryption.
  #   user_password  - password to open; empty string = no open password
  #   owner_password - full-control password; nil = same as user_password
  #   permissions    - bitmask of PERM_* constants; -1 = allow all
  #   aes256         - true = AES-256 (default), false = AES-128
  def set_security(user_password: '', owner_password: nil, permissions: PERM_ALL, aes256: true)
    enc_version = aes256 ? 0 : 1
    owner_ptr   = owner_password ? c_str(owner_password) : Fiddle::NULL
    check(
      @fns[:pdf_doc_set_security].call(@handle, c_str(user_password), owner_ptr, permissions, enc_version),
      'pdf_doc_set_security'
    )
    self
  end

  # Add a page and return a PdfCanvas for drawing.
  # width / height in points. A4 = 595.28 x 841.89.
  def add_page(width = 595.28, height = 841.89)
    h = @fns[:pdf_doc_add_page].call(@handle, width.to_f, height.to_f)
    raise "pdf_doc_add_page failed: #{last_error}" if h.nil? || h.zero?

    PdfCanvas.new(@fns, h)
  end

  # Write the completed document to path.
  def save(path)
    check(@fns[:pdf_doc_save_file].call(@handle, c_str(path)), 'pdf_doc_save_file')
  end

  # Write to a temp file and return the PDF bytes.
  def save_to_memory
    tmp = Tempfile.new(['pdfnative', '.pdf'], binmode: true)
    tmp_path = tmp.path
    tmp.close
    begin
      save(tmp_path)
      File.binread(tmp_path)
    ensure
      File.delete(tmp_path) if File.exist?(tmp_path)
    end
  end

  def close
    return unless @handle

    @fns[:pdf_doc_close].call(@handle)
    @handle = nil
  end

  private

  def c_str(str) = Fiddle::Pointer[str.encode('UTF-8') + "\0"]

  def last_error
    PdfLibrary.last_error_str(@fns)
  end

  def check(ret, fn)
    raise "#{fn} failed: #{last_error}" unless ret.zero?

    self
  end
end

class PdfCanvas
  def initialize(fns, handle)
    @fns    = fns
    @handle = handle
  end

  # Draw text with its baseline at (x, y).
  # style_handle is the raw handle from PdfStyle#handle, or nil for default.
  def draw_text(text, x, y, style_handle = nil)
    style_ptr = style_handle || Fiddle::NULL
    check(@fns[:pdf_canvas_draw_text].call(@handle, c_str(text), x.to_f, y.to_f, style_ptr), 'pdf_canvas_draw_text')
  end

  # Draw word-wrapped text in a box. Returns overflow char offset.
  def draw_textbox(text, x, y, width, height, style_handle = nil, line_spacing = 0.0)
    style_ptr = style_handle || Fiddle::NULL
    ret = @fns[:pdf_canvas_draw_textbox].call(@handle, c_str(text), x.to_f, y.to_f, width.to_f, height.to_f, style_ptr, line_spacing.to_f)
    raise "pdf_canvas_draw_textbox failed: #{last_error}" if ret < 0

    ret
  end

  # Draw a line from (x1,y1) to (x2,y2). r, g, b are 0-255.
  def draw_line(x1, y1, x2, y2, r: 0, g: 0, b: 0, width: 1.0)
    check(@fns[:pdf_canvas_draw_line].call(@handle, x1.to_f, y1.to_f, x2.to_f, y2.to_f, r, g, b, width.to_f), 'pdf_canvas_draw_line')
  end

  # Draw a rectangle. fill_rgb and stroke_rgb are [r, g, b] arrays or nil.
  def draw_rect(x, y, width, height, fill_rgb: nil, stroke_rgb: nil, stroke_width: 1.0)
    fr, fg, fb = fill_rgb   || [0, 0, 0]
    sr, sg, sb = stroke_rgb || [0, 0, 0]
    check(
      @fns[:pdf_canvas_draw_rect].call(
        @handle, x.to_f, y.to_f, width.to_f, height.to_f,
        fr, fg, fb, fill_rgb ? 1 : 0,
        sr, sg, sb, stroke_width.to_f, stroke_rgb ? 1 : 0
      ),
      'pdf_canvas_draw_rect'
    )
  end

  # Draw an ellipse bounded by the given rectangle.
  def draw_ellipse(x, y, width, height, fill_rgb: nil, stroke_rgb: nil, stroke_width: 1.0)
    fr, fg, fb = fill_rgb   || [0, 0, 0]
    sr, sg, sb = stroke_rgb || [0, 0, 0]
    check(
      @fns[:pdf_canvas_draw_ellipse].call(
        @handle, x.to_f, y.to_f, width.to_f, height.to_f,
        fr, fg, fb, fill_rgb ? 1 : 0,
        sr, sg, sb, stroke_width.to_f, stroke_rgb ? 1 : 0
      ),
      'pdf_canvas_draw_ellipse'
    )
  end

  # Draw a PdfTable at (x, y). Pass the table's handle via table.handle.
  def draw_table(table_handle, x, y)
    check(@fns[:pdf_canvas_draw_table].call(@handle, table_handle, x.to_f, y.to_f), 'pdf_canvas_draw_table')
  end

  # Add a clickable hyperlink over the given rectangle.
  def add_link(x, y, width, height, uri)
    check(@fns[:pdf_canvas_add_link].call(@handle, x.to_f, y.to_f, width.to_f, height.to_f, c_str(uri)), 'pdf_canvas_add_link')
  end

  def close
    return unless @handle

    @fns[:pdf_canvas_close].call(@handle)
    @handle = nil
  end

  # Expose the raw handle so PdfDocument#add_page callers can pass it to draw_table.
  def handle = @handle

  private

  def c_str(str) = Fiddle::Pointer[str.encode('UTF-8') + "\0"]

  def last_error = PdfLibrary.last_error_str(@fns)

  def check(ret, fn)
    raise "#{fn} failed: #{last_error}" unless ret.zero?

    self
  end
end

# A text style handle. Defaults: Helvetica 12 pt black left-aligned.
# Call close when done.
class PdfStyle
  attr_reader :handle

  def initialize(fns)
    @fns = fns
    h = fns[:pdf_style_create].call
    raise "pdf_style_create failed: #{PdfLibrary.last_error_str(fns)}" if h.nil? || h.zero?

    @handle = h
  end

  def set_font_family(family) = tap { @fns[:pdf_style_set_font_family].call(@handle, c_str(family)) }
  def set_font_file(path)     = tap { @fns[:pdf_style_set_font_file].call(@handle, c_str(path)) }
  def set_size(points)        = tap { @fns[:pdf_style_set_size].call(@handle, points.to_f) }
  def set_color(r, g, b)      = tap { @fns[:pdf_style_set_color].call(@handle, r, g, b) }
  def set_bold(bold = true)   = tap { @fns[:pdf_style_set_bold].call(@handle, bold ? 1 : 0) }
  def set_italic(ital = true) = tap { @fns[:pdf_style_set_italic].call(@handle, ital ? 1 : 0) }

  # alignment: 0 = left, 1 = center, 2 = right. Use ALIGN_* constants.
  def set_alignment(alignment) = tap { @fns[:pdf_style_set_alignment].call(@handle, alignment) }

  # decoration: 0 = none, 1 = underline, 2 = strikethrough, 3 = overline. Use DECOR_* constants.
  def set_decoration(decoration) = tap { @fns[:pdf_style_set_decoration].call(@handle, decoration) }

  def close
    return unless @handle

    @fns[:pdf_style_close].call(@handle)
    @handle = nil
  end

  private

  def c_str(str) = Fiddle::Pointer[str.encode('UTF-8') + "\0"]
end

# A table layout handle. Call close when done.
#
# Usage:
#   table = PdfTable.new(fns, [180, 80, 90, 90])
#   table.set_header_bg(26, 86, 160)
#         .set_alternate_bg(240, 245, 252)
#         .set_border(200, 200, 200, 0.5)
#         .add_row('Product', 'Qty', 'Unit Price', 'Total')
#         .add_row('Widget', '3', '$10.00', '$30.00')
#   canvas.draw_table(table.handle, 72, 100)
#   table.close
class PdfTable
  attr_reader :handle

  def initialize(fns, col_widths)
    @fns = fns
    # Pack column widths as a native float array.
    packed = col_widths.map(&:to_f).pack('f*')
    ptr    = Fiddle::Pointer[packed]
    h = fns[:pdf_table_create].call(ptr, col_widths.length)
    raise "pdf_table_create failed: #{PdfLibrary.last_error_str(fns)}" if h.nil? || h.zero?

    @handle = h
    # Keep packed alive so the pointer remains valid during the call.
    @_col_widths_packed = packed
  end

  def set_header_bg(r, g, b)   = tap { @fns[:pdf_table_set_header_bg].call(@handle, r, g, b) }
  def set_alternate_bg(r, g, b)= tap { @fns[:pdf_table_set_alternate_bg].call(@handle, r, g, b) }
  def set_border(r, g, b, w)   = tap { @fns[:pdf_table_set_border].call(@handle, r, g, b, w.to_f) }
  def set_cell_padding(padding) = tap { @fns[:pdf_table_set_cell_padding].call(@handle, padding.to_f) }

  # Stage all cells and commit them as a single row.
  def add_row(*cells)
    cells.each do |cell|
      ret = @fns[:pdf_table_stage_cell].call(@handle, c_str(cell.to_s))
      raise "pdf_table_stage_cell failed: #{PdfLibrary.last_error_str(@fns)}" unless ret.zero?
    end
    ret = @fns[:pdf_table_commit_row].call(@handle)
    raise "pdf_table_commit_row failed: #{PdfLibrary.last_error_str(@fns)}" unless ret.zero?

    self
  end

  def close
    return unless @handle

    @fns[:pdf_table_close].call(@handle)
    @handle = nil
  end

  private

  def c_str(str) = Fiddle::Pointer[str.encode('UTF-8') + "\0"]
end

# Merges multiple PDF documents into one. Call close when done.
#
# Usage:
#   merger = PdfMerger.new(fns)
#   merger.add_bytes(File.binread('a.pdf'))
#   merger.add_bytes(File.binread('b.pdf'))
#   merger.save('/tmp/merged.pdf')
#   merger.close
class PdfMerger
  def initialize(fns)
    @fns = fns
    h = fns[:pdf_merge_create].call
    raise "pdf_merge_create failed: #{PdfLibrary.last_error_str(fns)}" if h.nil? || h.zero?

    @handle = h
  end

  # Add PDF bytes to the merge queue.
  def add_bytes(data)
    ptr = Fiddle::Pointer[data]
    ret = @fns[:pdf_merge_add_bytes].call(@handle, ptr, data.bytesize)
    raise "pdf_merge_add_bytes failed: #{PdfLibrary.last_error_str(@fns)}" unless ret.zero?

    self
  end

  def save(path)
    ret = @fns[:pdf_merge_save_file].call(@handle, c_str(path))
    raise "pdf_merge_save_file failed: #{PdfLibrary.last_error_str(@fns)}" unless ret.zero?
  end

  # Merge and return PDF bytes.
  def save_to_memory
    tmp = Tempfile.new(['pdfnative', '.pdf'], binmode: true)
    tmp_path = tmp.path
    tmp.close
    begin
      save(tmp_path)
      File.binread(tmp_path)
    ensure
      File.delete(tmp_path) if File.exist?(tmp_path)
    end
  end

  def close
    return unless @handle

    @fns[:pdf_merge_close].call(@handle)
    @handle = nil
  end

  private

  def c_str(str) = Fiddle::Pointer[str.encode('UTF-8') + "\0"]
end
