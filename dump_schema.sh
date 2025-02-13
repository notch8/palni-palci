# run this against the old database you are dumping from
# after you execute shell in db run this script

DB_NAME="pals-production-hyku"  # Replace with your database name
DB_USER="postgres"              # Replace with your database username
DUMP_DIR="/tmp/postgres"        # Replace with your desired directory to store dump files

# Create dump directory if it doesn't exist
mkdir -p $DUMP_DIR

# Get the list of schemas excluding system schemas
SCHEMAS=$(psql -U $DB_USER -d $DB_NAME -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast');")

# Loop through each schema and dump it
for SCHEMA in $SCHEMAS; do
    # Remove leading/trailing whitespace from schema name
    SCHEMA=$(echo $SCHEMA | xargs)

    # Output message
    echo "Dumping schema: $SCHEMA"

    # Dump the schema
    pg_dump -U $DB_USER -d $DB_NAME -n $SCHEMA -F c -f "$DUMP_DIR/${SCHEMA}.dump"

    # Check if the dump was successful
    if [ $? -eq 0 ]; then
        echo "Successfully dumped schema: $SCHEMA"
    else
        echo "Failed to dump schema: $SCHEMA" >&2
    fi
done
