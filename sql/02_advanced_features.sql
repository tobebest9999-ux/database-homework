-- 当前版本数据库辅助对象
-- 说明：本文件只保留当前项目仍在使用的索引和查询视图。
-- 已移除：车牌加密、分区归档表、数据库账号权限脚本、出库存储过程。

USE parking_system;
SET NAMES utf8mb4;

CREATE OR REPLACE VIEW v_space_usage_summary AS
SELECT
  COUNT(*) AS 车位总数,
  SUM(CASE WHEN 车位编号 LIKE 'A-%' THEN 1 ELSE 0 END) AS 固定车位数,
  SUM(CASE WHEN 车位编号 LIKE 'B-%' THEN 1 ELSE 0 END) AS 自由车位数,
  SUM(CASE WHEN 车位状态 = '空闲' THEN 1 ELSE 0 END) AS 空闲车位数,
  SUM(CASE WHEN 车位状态 = '有车' THEN 1 ELSE 0 END) AS 已占用车位数,
  ROUND(SUM(CASE WHEN 车位状态 = '有车' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2) AS 使用率
FROM ParkingSpace;

CREATE OR REPLACE VIEW v_active_parking_detail AS
SELECT
  pr.记录编号,
  pr.卡号,
  c.车牌号,
  c.车主姓名,
  c.联系电话,
  c.车卡状态,
  pr.停放车位编号,
  pr.入库时间,
  TIMESTAMPDIFF(MINUTE, pr.入库时间, NOW()) AS 已停车分钟数,
  CASE
    WHEN TIMESTAMPDIFF(MINUTE, pr.入库时间, NOW()) <= 29 THEN 5.00
    WHEN TIMESTAMPDIFF(MINUTE, pr.入库时间, NOW()) <= 179 THEN 20.00
    WHEN TIMESTAMPDIFF(MINUTE, pr.入库时间, NOW()) <= 1439 THEN 50.00
    ELSE 100.00
  END AS 当前预估费用
FROM ParkingRecord pr
JOIN Card c ON pr.卡号 = c.卡号
WHERE pr.出库时间 IS NULL;

CREATE OR REPLACE VIEW v_charge_record_detail AS
SELECT
  cr.收费编号,
  cr.停车记录编号,
  cr.卡号,
  c.车牌号,
  c.车主姓名,
  c.联系电话,
  cr.车位编号,
  cr.停车时长,
  cr.收费金额,
  cr.收费时间,
  cr.支付状态
FROM ChargeRecord cr
JOIN Card c ON cr.卡号 = c.卡号;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ParkingRecord' AND INDEX_NAME = 'idx_record_card_active') = 0,
  'CREATE INDEX idx_record_card_active ON ParkingRecord(卡号, 出库时间, 入库时间)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ParkingRecord' AND INDEX_NAME = 'idx_record_space_time') = 0,
  'CREATE INDEX idx_record_space_time ON ParkingRecord(停放车位编号, 入库时间)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ParkingSpace' AND INDEX_NAME = 'idx_space_status_id') = 0,
  'CREATE INDEX idx_space_status_id ON ParkingSpace(车位状态, 车位编号)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ChargeRecord' AND INDEX_NAME = 'idx_charge_card_time') = 0,
  'CREATE INDEX idx_charge_card_time ON ChargeRecord(卡号, 收费时间)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'AuditLog' AND INDEX_NAME = 'idx_audit_time') = 0,
  'CREATE INDEX idx_audit_time ON AuditLog(操作时间)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

