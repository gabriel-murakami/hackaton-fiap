require "pdf-reader"
require "stringio"

module ReportAnalyzer
  class FileProcessor
    SUPPORTED_TYPES = %w[.pdf .png .jpg .jpeg]

    def self.validate!(file, filename)
      raise "Arquivo vazio" if file.blank?

      ext = File.extname(filename).downcase

      raise "Formato não suportado" unless SUPPORTED_TYPES.include?(ext)
    end

    def self.process(file, filename)
      ext = File.extname(filename).downcase

      case ext
      when ".pdf"
        {
          type: :text,
          content: extract_text_from_pdf(file)
        }
      when ".png", ".jpg", ".jpeg"
        {
          type: :image,
          content: file
        }
      else
        raise "Formato inválido"
      end
    end

    def self.extract_text_from_pdf(file)
      reader = ::PDF::Reader.new(StringIO.new(file))
      reader.pages.map(&:text).join("\n")
    end
  end
end
