namespace :search do
  desc 'Delete old unsaved searches for multiple tenants in batches'
  task delete_old_searches: :environment do
    days_old = ENV['DAYS_OLD'].to_i
    batch_size = ENV['BATCH_SIZE'].to_i
    tenant_ids = Account.pluck(:id)

    if days_old <= 0 || batch_size <= 0
      puts 'Valid DAYS_OLD and BATCH_SIZE are required.'
      exit 1
    end

    tenant_ids.each do |tenant_id|
      account = Account.find(tenant_id)
      next if account.nil?

      # Switch tenant context
      switch!(account)

      # Run the delete_old_searches method in batches
      loop do
        old_searches = Search.where(['created_at < ? AND user_id IS NULL', Time.zone.today - days_old])
                             .limit(batch_size)

        break if old_searches.empty?

        old_searches.delete_all
        puts "Deleted #{old_searches.size} searches in batch for tenant #{tenant_id}."
        sleep(1)  # Optional: add a short delay to reduce load
      end

      # Perform VACUUM FULL on the searches table in the specified schema
      schema_name = account.tenant
      ActiveRecord::Base.connection.execute("VACUUM FULL \"#{schema_name}\".searches;")
      puts "Performed VACUUM FULL on searches table for tenant #{tenant_id}."

      puts "Completed deletion of old searches older than #{days_old} days for tenant #{tenant_id}."
    end
  end
end
