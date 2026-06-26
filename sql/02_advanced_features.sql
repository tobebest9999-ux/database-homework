-- Residential Parking Management System
-- 02_advanced_features.sql
-- Run after 01_schema_and_seed.sql.
-- Covered techniques: function, monthly stored procedure, trigger, view, index,
-- window function, audit log, full-text search, backup/restore support.

USE parking_system;
SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS sp_checkout_vehicle;
DROP VIEW IF EXISTS v_card_masked;
DROP TRIGGER IF EXISTS trg_card_encrypt_bi;
DROP TRIGGER IF EXISTS trg_card_encrypt_bu;
DROP TRIGGER IF EXISTS trg_record_fee_bu;
DROP TABLE IF EXISTS ParkingRecordArchive;

DROP FUNCTION IF EXISTS fn_calculate_parking_fee;
DELIMITER $$
CREATE FUNCTION fn_calculate_parking_fee(p_minutes INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE v_fee DECIMAL(10,2);
  IF p_minutes IS NULL OR p_minutes < 0 THEN
    SET v_fee = 0.00;
  ELSEIF p_minutes <= 29 THEN
    SET v_fee = 5.00;
  ELSEIF p_minutes <= 179 THEN
    SET v_fee = 20.00;
  ELSEIF p_minutes <= 1439 THEN
    SET v_fee = 50.00;
  ELSE
    SET v_fee = 100.00;
  END IF;
  RETURN v_fee;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_generate_monthly_charge_summary;
DELIMITER $$
CREATE PROCEDURE sp_generate_monthly_charge_summary(
  IN p_year_month CHAR(7),
  OUT p_total_records INT,
  OUT p_total_fee DECIMAL(12,2)
)
BEGIN
  SELECT COUNT(*), COALESCE(SUM(收费数额), 0)
  INTO p_total_records, p_total_fee
  FROM ParkingRecord
  WHERE DATE_FORMAT(出库时间, '%Y-%m') = p_year_month
    AND 出库时间 IS NOT NULL;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_card_audit_ai;
DROP TRIGGER IF EXISTS trg_card_audit_au;
DROP TRIGGER IF EXISTS trg_card_audit_ad;
DROP TRIGGER IF EXISTS trg_space_audit_au;
DROP TRIGGER IF EXISTS trg_record_audit_ai;
DROP TRIGGER IF EXISTS trg_record_audit_au;

DELIMITER $$
CREATE TRIGGER trg_card_audit_ai
AFTER INSERT ON Card
FOR EACH ROW
BEGIN
  INSERT INTO AuditLog(表名, 操作类型, 操作员, 记录内容)
  VALUES('Card', 'INSERT', 'DB_TRIGGER', CONCAT('新增车卡：卡号=', NEW.卡号, '，车牌=', NEW.车牌号, '，车主=', NEW.车主姓名));
END$$

CREATE TRIGGER trg_card_audit_au
AFTER UPDATE ON Card
FOR EACH ROW
BEGIN
  INSERT INTO AuditLog(表名, 操作类型, 操作员, 记录内容)
  VALUES('Card', 'UPDATE', 'DB_TRIGGER', CONCAT('修改车卡：卡号=', NEW.卡号, '，车牌 ', OLD.车牌号, ' -> ', NEW.车牌号));
END$$

CREATE TRIGGER trg_card_audit_ad
AFTER DELETE ON Card
FOR EACH ROW
BEGIN
  INSERT INTO AuditLog(表名, 操作类型, 操作员, 记录内容)
  VALUES('Card', 'DELETE', 'DB_TRIGGER', CONCAT('删除车卡：卡号=', OLD.卡号, '，车牌=', OLD.车牌号));
END$$

CREATE TRIGGER trg_space_audit_au
AFTER UPDATE ON ParkingSpace
FOR EACH ROW
BEGIN
  IF OLD.车位状态 <> NEW.车位状态 OR COALESCE(OLD.当前停放车牌, '') <> COALESCE(NEW.当前停放车牌, '') OR COALESCE(OLD.固定车位卡号, '') <> COALESCE(NEW.固定车位卡号, '') THEN
    INSERT INTO AuditLog(表名, 操作类型, 操作员, 记录内容)
    VALUES('ParkingSpace', 'UPDATE', 'DB_TRIGGER', CONCAT('车位=', NEW.车位编号, '，状态 ', OLD.车位状态, ' -> ', NEW.车位状态));
  END IF;
END$$

CREATE TRIGGER trg_record_audit_ai
AFTER INSERT ON ParkingRecord
FOR EACH ROW
BEGIN
  INSERT INTO AuditLog(表名, 操作类型, 操作员, 记录内容)
  VALUES('ParkingRecord', 'INSERT', 'DB_TRIGGER', CONCAT('车辆入库：记录=', NEW.记录编号, '，卡号=', NEW.卡号, '，车位=', NEW.停放车位编号));
END$$

CREATE TRIGGER trg_record_audit_au
AFTER UPDATE ON ParkingRecord
FOR EACH ROW
BEGIN
  IF OLD.出库时间 IS NULL AND NEW.出库时间 IS NOT NULL THEN
    INSERT INTO AuditLog(表名, 操作类型, 操作员, 记录内容)
    VALUES('ParkingRecord', 'UPDATE', 'DB_TRIGGER', CONCAT('车辆出库：记录=', NEW.记录编号, '，卡号=', NEW.卡号, '，费用=', NEW.收费数额, '元'));
  END IF;
END$$
DELIMITER ;

CREATE OR REPLACE VIEW v_space_stats AS
SELECT
  COUNT(*) AS 车位总数,
  SUM(CASE WHEN 车位状态 = '空闲' THEN 1 ELSE 0 END) AS 空闲车位数,
  SUM(CASE WHEN 车位状态 = '有车' THEN 1 ELSE 0 END) AS 已占用车位数,
  CONCAT(ROUND(SUM(CASE WHEN 车位状态 = '有车' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2), '%') AS 使用率
FROM ParkingSpace;

CREATE OR REPLACE VIEW v_free_space_stats AS
SELECT
  COUNT(*) AS 车位总数,
  SUM(CASE WHEN 车位状态 = '空闲' THEN 1 ELSE 0 END) AS 空闲车位数,
  SUM(CASE WHEN 车位状态 = '有车' THEN 1 ELSE 0 END) AS 已占用车位数,
  CONCAT(ROUND(SUM(CASE WHEN 车位状态 = '有车' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100, 2), '%') AS 使用率
FROM ParkingSpace
WHERE 车位编号 LIKE 'B-%';

CREATE OR REPLACE VIEW v_fixed_space_status AS
SELECT
  ps.车位编号,
  c.车牌号,
  ps.车位状态,
  CASE WHEN ps.车位状态 = '有车' THEN '在位' ELSE '不在位' END AS 是否在位,
  ps.固定车位卡号
FROM ParkingSpace ps
LEFT JOIN Card c ON ps.固定车位卡号 = c.卡号
WHERE ps.车位编号 LIKE 'A-%';

CREATE OR REPLACE VIEW v_active_parking_detail AS
SELECT
  pr.记录编号,
  pr.卡号,
  c.车主姓名,
  c.车牌号,
  pr.停放车位编号,
  pr.入库时间,
  TIMESTAMPDIFF(MINUTE, pr.入库时间, NOW()) AS 已停分钟数,
  fn_calculate_parking_fee(TIMESTAMPDIFF(MINUTE, pr.入库时间, NOW())) AS 当前应收费用
FROM ParkingRecord pr
JOIN Card c ON pr.卡号 = c.卡号
WHERE pr.出库时间 IS NULL;

CREATE OR REPLACE VIEW v_monthly_charge_summary AS
SELECT
  DATE_FORMAT(出库时间, '%Y-%m') AS 收费月份,
  COUNT(*) AS 出库次数,
  COALESCE(SUM(收费数额), 0) AS 收费合计,
  COALESCE(AVG(收费数额), 0) AS 平均收费
FROM ParkingRecord
WHERE 出库时间 IS NOT NULL
GROUP BY DATE_FORMAT(出库时间, '%Y-%m');


CREATE OR REPLACE VIEW v_parking_fee_rank AS
SELECT
  卡号,
  记录编号,
  停放车位编号,
  入库时间,
  出库时间,
  收费数额,
  ROW_NUMBER() OVER (PARTITION BY 卡号 ORDER BY 收费数额 DESC, 出库时间 DESC) AS 单卡费用排名,
  SUM(COALESCE(收费数额, 0)) OVER (PARTITION BY 卡号 ORDER BY COALESCE(出库时间, 入库时间)) AS 单卡累计消费
FROM ParkingRecord;

SET @sql := IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ParkingRecord' AND INDEX_NAME = 'idx_record_card_active') = 0, 'CREATE INDEX idx_record_card_active ON ParkingRecord(卡号, 出库时间, 入库时间)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ParkingRecord' AND INDEX_NAME = 'idx_record_space_time') = 0, 'CREATE INDEX idx_record_space_time ON ParkingRecord(停放车位编号, 入库时间)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ParkingSpace' AND INDEX_NAME = 'idx_space_status_id') = 0, 'CREATE INDEX idx_space_status_id ON ParkingSpace(车位状态, 车位编号)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'AuditLog' AND INDEX_NAME = 'idx_audit_time') = 0, 'CREATE INDEX idx_audit_time ON AuditLog(操作时间)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sql := IF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'AuditLog' AND INDEX_NAME = 'ft_audit_content') = 0, 'CREATE FULLTEXT INDEX ft_audit_content ON AuditLog(记录内容)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

