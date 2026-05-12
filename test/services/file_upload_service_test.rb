require "test_helper"

class FileUploadServiceTest < ActiveSupport::TestCase
  setup { @tempfiles = [] }

  teardown { @tempfiles.each(&:close!) }

  def make_upload(bytes, filename)
    file = Tempfile.new([ "upload_test", File.extname(filename) ])
    @tempfiles << file
    file.binmode
    file.write(bytes)
    file.flush
    file.rewind
    ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: filename)
  end

  # ---------- PDFs ----------

  test "save_pdf aceita PDF válido" do
    upload = make_upload("%PDF-1.4 conteúdo", "doc.pdf")
    path = FileUploadService.save_pdf(upload)
    assert path.end_with?(".pdf")
    assert File.exist?(File.join(FileUploadService::UPLOAD_DIR, path))
  end

  test "save_pdf rejeita arquivo sem magic bytes PDF" do
    upload = make_upload("não é um PDF", "doc.pdf")
    assert_raises(ArgumentError) { FileUploadService.save_pdf(upload) }
  end

  # ---------- Imagens ----------

  test "save_image aceita JPEG" do
    jpeg_bytes = [ 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10 ].pack("C*") + " jpeg payload"
    upload = make_upload(jpeg_bytes, "foto.jpg")
    path = FileUploadService.save_image(upload)
    assert path.start_with?("images/")
    assert File.exist?(File.join(FileUploadService::UPLOAD_DIR, path))
  end

  test "save_image aceita PNG" do
    png_bytes = [ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A ].pack("C*") + "payload"
    upload = make_upload(png_bytes, "img.png")
    path = FileUploadService.save_image(upload)
    assert path.start_with?("images/")
  end

  test "save_image aceita GIF" do
    upload = make_upload("GIF89a payload", "anim.gif")
    path = FileUploadService.save_image(upload)
    assert path.start_with?("images/")
  end

  test "save_image aceita WEBP" do
    header = "RIFF\x00\x00\x00\x00WEBP payload"
    upload = make_upload(header, "img.webp")
    path = FileUploadService.save_image(upload)
    assert path.start_with?("images/")
  end

  test "save_image rejeita arquivo com conteúdo arbitrário" do
    upload = make_upload("isso não é imagem alguma", "fake.jpg")
    assert_raises(ArgumentError) { FileUploadService.save_image(upload) }
  end

  # ---------- Unicidade ----------

  test "dois uploads geram caminhos distintos" do
    a = FileUploadService.save_pdf(make_upload("%PDF-1.4 a", "a.pdf"))
    b = FileUploadService.save_pdf(make_upload("%PDF-1.4 b", "b.pdf"))
    assert_not_equal a, b
  end
end
