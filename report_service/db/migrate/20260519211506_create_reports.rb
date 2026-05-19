class CreateReports < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :reports, id: :uuid do |t|
      t.text :result
      t.uuid :document_id, null: false

      t.timestamps
    end
  end
end
