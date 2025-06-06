#!/bin/bash

# Cấu hình
BUCKET="<tên bucket của bạn"   # 🔁 thay bằng tên bucket thật
LOCAL_DIR="/home/ubuntu/backups"

mkdir -p "$LOCAL_DIR"

# Tìm file SQL và Volume mới nhất trên S3
LATEST_SQL=$(aws s3 ls s3://$BUCKET/ | grep 'n8n_db_.*\.sql' | sort | tail -n 1 | awk '{print $4}')
LATEST_VOL=$(aws s3 ls s3://$BUCKET/ | grep 'n8n_data_.*\.tar.gz' | sort | tail -n 1 | awk '{print $4}')

# Tải về máy
echo "📥 Tải file từ S3..."
aws s3 cp s3://$BUCKET/$LATEST_SQL $LOCAL_DIR/
aws s3 cp s3://$BUCKET/$LATEST_VOL $LOCAL_DIR/

# Đường dẫn local
SQL_FILE="$LOCAL_DIR/$LATEST_SQL"
VOL_FILE="$LOCAL_DIR/$LATEST_VOL"

echo "🛠 Khôi phục từ:"
echo " - SQL   : $SQL_FILE"
echo " - Volume: $VOL_FILE"
read -p "❓ Tiếp tục? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" ]] && echo "❌ Huỷ." && exit 1

# Tạo volume mới
docker volume create n8n_data

# Restore dữ liệu volume
docker run --rm \
  -v n8n_data:/data \
  -v $LOCAL_DIR:/backup \
  alpine tar xzf /backup/$(basename $VOL_FILE) -C /data

# Khởi động PostgreSQL
docker compose up -d postgres
sleep 5

# Khôi phục PostgreSQL
cat $SQL_FILE | docker exec -i postgres psql -U n8n -d n8ndb

# Khởi động toàn bộ hệ thống
docker compose up -d

echo "✅ Đã khôi phục xong!"

