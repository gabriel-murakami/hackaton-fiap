module ReportAnalyzer
  class Orchestrator
    def self.call(file:, filename:, report:)
      FileProcessor.validate!(file, filename)

      report.processing!

      processed_input = FileProcessor.process(file, filename)

      ai_response = AiClient.analyze(
        content: processed_input,
        prompt: PromptBuilder.build
      )

      validated = OutputValidator.validate!(ai_response)

      ReportFormatter.format(validated)
    end
  end
end
