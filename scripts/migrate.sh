#!/bin/bash

#
# Migrate old Hitchwiki database into the new system
#
# [!] Existing database will be dropped, so use with caution
#

if [ ! -f Vagrantfile ]; then # an arbirtrary file that appears only once in the whole repository tree
    echo "ERROR: Bad working directory ($(pwd))."
    echo "Scripts have to be run from the root directory of the hitchwiki repository."
    echo "Aborting."
    exit 1
fi

source "scripts/path_resolve.sh"
source "$SCRIPTDIR/settings.sh"

echo "Drop database and recreate it..."
mysql -u$HW__db__username -p$HW__db__password -e "DROP DATABASE IF EXISTS $HW__db__database"
mysql -u$HW__db__username -p$HW__db__password -e "CREATE DATABASE $HW__db__database CHARACTER SET utf8 COLLATE utf8_general_ci"
echo ""

echo "Import old Hitchwiki SQL dump..."
DUMPFILE="$ROOTDIR/dumps/old-hitchwiki_en.sql"
if [ ! -f "$DUMPFILE" ]; then
    echo "File $DUMPFILE not found"
    exit 1
fi
cat "$DUMPFILE" | mysql -u$HW__db__username -p$HW__db__password $HW__db__database
echo ""

echo "Update MediaWiki..."
cd "$WIKIDIR"
php maintenance/update.php --quick --conf "$MWCONFFILE"
echo ""

# Pre-populate the antispoof (MW extension) table with your wiki's existing usernames
echo "Pre-populate antispoof table..."
cd "$WIKIDIR"
php extensions/AntiSpoof/maintenance/batchAntiSpoof.php
echo ""

# Import Semantic pages
cd "$ROOTDIR"
bash $SCRIPTDIR/import_pages.sh

echo "Import interwiki table..."
mysql -u$HW__db__username -p$HW__db__password $HW__db__database < "$SCRIPTDIR/configs/interwiki.sql"
echo ""