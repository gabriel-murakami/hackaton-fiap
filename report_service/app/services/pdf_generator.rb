require "prawn"
require "prawn/table"

class PdfGenerator
  COLORS = {
    primary:    "1A237E",
    accent:     "3949AB",
    danger:     "B71C1C",
    success:    "1B5E20",
    light_gray: "F5F5F5",
    mid_gray:   "9E9E9E",
    dark:       "212121"
  }.freeze

  def self.call(report)
    new(report).generate
  end

  def initialize(report)
    @report = report
    @result = report.result&.transform_keys(&:to_s)
  end

  def generate
    return unless @result

    Prawn::Document.new(page_size: "A4", margin: [ 40, 50, 40, 50 ]) do |pdf|
      render_header(pdf)
      render_meta(pdf)
      render_summary(pdf)
      render_confidence(pdf)
      render_components(pdf)
      render_risks(pdf)
      render_best_practices(pdf)
      render_recommendations(pdf)
      render_footer(pdf)
    end.render
  end

  private

  def render_header(pdf)
    pdf.fill_color COLORS[:primary]
    pdf.fill_rectangle [ pdf.bounds.left - 50, pdf.cursor + 10 ], pdf.bounds.width + 100, 55
    pdf.fill_color "FFFFFF"
    pdf.move_down 12
    pdf.text "Relatório de Análise de Arquitetura", size: 20, style: :bold, align: :center
    pdf.fill_color COLORS[:dark]
    pdf.move_down 22
  end

  def render_meta(pdf)
    pdf.fill_color COLORS[:mid_gray]
    pdf.text "Documento: #{@report.document_name}", size: 9
    generated = @result["generated_at"]
    if generated
      time = generated.is_a?(String) ? Time.parse(generated) : generated
      pdf.text "Gerado em: #{time.strftime('%d/%m/%Y às %H:%M')}", size: 9
    end
    pdf.fill_color COLORS[:dark]
    pdf.stroke_color COLORS[:accent]
    pdf.stroke_horizontal_rule
    pdf.move_down 14
  end

  def render_summary(pdf)
    section_title(pdf, "Descrição da Arquitetura")
    pdf.text @result["summary"].to_s, size: 10, leading: 4
    pdf.move_down 12
  end

  def render_confidence(pdf)
    value = @result["confidence"]
    return unless value

    section_title(pdf, "Confiança da Análise")
    pdf.text value.to_s, size: 10, leading: 4
    pdf.move_down 12
  end

  def render_components(pdf)
    components = Array(@result["components"])
    return if components.empty?

    section_title(pdf, "Componentes Identificados")
    table_data = [ [ "Componente" ] ] + components.map { |c| [ c.to_s ] }
    pdf.table(table_data, column_widths: [ pdf.bounds.width ], cell_style: { size: 9, padding: [ 4, 6 ] }) do
      row(0).background_color = COLORS[:accent]
      row(0).text_color = "FFFFFF"
      row(0).font_style = :bold
      rows(1..-1).background_color = COLORS[:light_gray]
    end
    pdf.move_down 12
  end

  def render_risks(pdf)
    risks = Array(@result["risks"])
    return if risks.empty?

    section_title(pdf, "Riscos Identificados", color: COLORS[:danger])
    risks.each_with_index do |risk, i|
      pdf.fill_color COLORS[:danger]
      pdf.text "#{i + 1}. #{risk}", size: 10, leading: 3
    end
    pdf.fill_color COLORS[:dark]
    pdf.move_down 12
  end

  def render_best_practices(pdf)
    practices = Array(@result["best_practices"])
    return if practices.empty?

    section_title(pdf, "Boas Práticas", color: COLORS[:accent])
    practices.each_with_index do |practice, i|
      pdf.text "#{i + 1}. #{practice}", size: 10, leading: 3
    end
    pdf.move_down 12
  end

  def render_recommendations(pdf)
    recs = Array(@result["recommendations"])
    return if recs.empty?

    section_title(pdf, "Recomendações", color: COLORS[:success])
    recs.each_with_index do |rec, i|
      pdf.fill_color COLORS[:success]
      pdf.text "#{i + 1}. #{rec}", size: 10, leading: 3
    end
    pdf.fill_color COLORS[:dark]
    pdf.move_down 12
  end

  def render_footer(pdf)
    pdf.repeat(:all) do
      pdf.bounding_box([ 0, pdf.bounds.absolute_bottom + 20 ], width: pdf.bounds.width) do
        pdf.stroke_color COLORS[:mid_gray]
        pdf.stroke_horizontal_rule
        pdf.move_down 4
        pdf.fill_color COLORS[:mid_gray]
        pdf.text "Report Service — gerado automaticamente", size: 8, align: :center
        pdf.fill_color COLORS[:dark]
      end
    end
  end

  def section_title(pdf, title, color: COLORS[:accent])
    pdf.fill_color color
    pdf.text title, size: 13, style: :bold
    pdf.fill_color COLORS[:dark]
    pdf.move_down 6
  end
end
