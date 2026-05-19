class CreateDocuments < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :documents, id: :uuid do |t|
      t.string :title

      t.timestamps
    end
  end
end
