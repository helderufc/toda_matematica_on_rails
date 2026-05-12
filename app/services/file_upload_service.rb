class FileUploadService
  UPLOAD_DIR = ENV.fetch("UPLOAD_DIR", Rails.root.join("storage", "uploads").to_s)

  PDF_MAGIC  = "%PDF"
  JPEG_MAGIC = "\xFF\xD8\xFF".b
  PNG_MAGIC  = "\x89PNG".b
  GIF_MAGIC  = "GIF8"
  RIFF_MAGIC = "RIFF"
  WEBP_TAG   = "WEBP"

  def self.save_pdf(uploaded_file)
    validate_pdf!(uploaded_file)
    store(uploaded_file, "pdfs")
  end

  def self.save_image(uploaded_file)
    validate_image!(uploaded_file)
    store(uploaded_file, "images")
  end

  def self.validate_pdf!(uploaded_file)
    header = File.binread(uploaded_file.path, 4)
    raise ArgumentError, "Arquivo deve ser um PDF válido" unless header == PDF_MAGIC
  end

  def self.validate_image!(uploaded_file)
    header = File.binread(uploaded_file.path, 12)
    jpeg  = header[0, 3] == JPEG_MAGIC
    png   = header[0, 4] == PNG_MAGIC
    gif   = header[0, 4] == GIF_MAGIC
    webp  = header[0, 4] == RIFF_MAGIC && header[8, 4] == WEBP_TAG

    raise ArgumentError, "Imagem deve ser JPEG, PNG, GIF ou WEBP" unless jpeg || png || gif || webp
  end

  def self.store(uploaded_file, subdir)
    dir = File.join(UPLOAD_DIR, subdir)
    FileUtils.mkdir_p(dir)

    ext      = File.extname(uploaded_file.original_filename)
    filename = "#{SecureRandom.uuid}#{ext}"
    dest     = File.join(dir, filename)

    FileUtils.cp(uploaded_file.path, dest)
    File.join(subdir, filename)
  end
  private_class_method :store
end
