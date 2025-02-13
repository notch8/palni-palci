namespace :db do
  desc 'Dump each tenant schema to a separate file in the /tmp/postgres directory'
  task dump_schemas: :environment do
    # Database configuration
    db_config = Rails.configuration.database_configuration[Rails.env]

    pg_user = db_config['username']
    pg_host = db_config['host']
    pg_port = db_config['port'] || '5432'
    db_name = db_config['database']
    dump_dir = "/tmp/postgres"  # Directory to store dumps

    # Ensure the dump directory exists
    FileUtils.mkdir_p(dump_dir)

    # Set the PGPASSWORD environment variable
    ENV['PGPASSWORD'] = db_config['password']

    # Fetch all schemas except system schemas
    schemas = ActiveRecord::Base.connection.execute("
      SELECT schema_name 
      FROM information_schema.schemata 
      WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
    ").map { |row| row['schema_name'] }

    schemas.each do |schema_name|
      next if schema_name.blank? # Skip if schema_name is empty

      # Output message
      puts "Dumping schema: #{schema_name}"

      # Define the dump file path
      dump_file = File.join(dump_dir, "#{schema_name}.dump")

      # Construct the pg_dump command
      command = "pg_dump -U #{pg_user} -h #{pg_host} -p #{pg_port} -d #{db_name} -n #{schema_name} -F c -f #{dump_file}"

      # Execute the command
      system(command)

      # Check if the command was successful
      if $?.exitstatus == 0
        puts "Successfully dumped schema: #{schema_name} to #{dump_file}"
      else
        puts "Failed to dump schema: #{schema_name}", :stderr
      end
    end
  end
end
