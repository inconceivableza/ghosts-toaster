#!/bin/bash
# Script to back up all Ghost sites and databases

# Set backup directory with current date
BACKUP_DIR="backups/$(date +%Y-%m-%d)"
mkdir -p $BACKUP_DIR

# Back up MySQL
echo "Backing up all databases..."
MYSQL_ROOT_PASSWORD=$(grep MYSQL_ROOT_PASSWORD ghosts-toaster.env | cut -d= -f2)
docker exec mysql mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --all-databases > $BACKUP_DIR/all-databases.sql

# Back up Ghost content
echo "Backing up all Ghost content..."
for site in $(grep SITE_NAME= sites/*/site.env | cut -d= -f2); do
  echo "- Backing up content for $site..."
  mkdir -p $BACKUP_DIR/ghost_content_$site
  docker run --rm \
    -v ghosts-toaster_ghost_content_$site:/source \
    -v $(pwd)/$BACKUP_DIR/ghost_content_$site:/backup \
    alpine tar -czf /backup/content.tar.gz -C /source .
done

echo "Backup completed in $BACKUP_DIR"
