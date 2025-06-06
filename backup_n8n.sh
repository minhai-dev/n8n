#!/bin/bash

DATE=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/home/ubuntu/backups"
mkdir -p $BACKUP_DIR

echo "👉 Bắt đầu backup lúc $DATE"

# Backup PostgreSQL
echo "🛢️ Backup PostgreSQL..."
docker exec -t postgres pg_dump -U n8n n8ndb > $BACKUP_DIR/n8n_db_$DATE.sql

# Backup volume n8n_data
echo "💾 Backup n8n_data volume..."
docker run --rm \
  -v n8n_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/n8n_data_$DATE.tar.gz -C /data .

# Backup docker-compose.yml (cấu hình hệ thống)
echo "⚙️ Backup docker-compose.yml..."
cp /home/ubuntu/docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml

# Xóa backup cũ hơn 7 ngày
echo "🧹 Xóa backup cũ hơn 7 ngày..."
find $BACKUP_DIR -type f -mtime +7 -delete

echo "✅ Backup hoàn tất: $BACKUP_DIR"

# ☁️ Đồng bộ lên S3
echo "☁️  Đang đồng bộ lên S3..."
aws s3 sync $BACKUP_DIR s3://n8n-backup-vietthanhai --region us-east-1
