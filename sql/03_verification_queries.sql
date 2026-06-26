-- Residential Parking Management System
-- 03_verification_queries.sql
-- Run after 01_schema_and_seed.sql and 02_advanced_features.sql.

USE parking_system;
SET NAMES utf8mb4;

-- 1. Check database objects.
SHOW FULL TABLES;
SHOW PROCEDURE STATUS WHERE Db = 'parking_system';
SHOW TRIGGERS;

-- 2. Basic data verification.
SELECT COUNT(*) AS 车位总数 FROM ParkingSpace;
SELECT LEFT(车位编号, 1) AS 编号前缀, COUNT(*) AS 数量 FROM ParkingSpace GROUP BY LEFT(车位编号, 1) ORDER BY 编号前缀;
SELECT MIN(车位编号) AS 最小编号, MAX(车位编号) AS 最大编号 FROM ParkingSpace WHERE 车位编号 LIKE 'A-%';
SELECT MIN(车位编号) AS 最小编号, MAX(车位编号) AS 最大编号 FROM ParkingSpace WHERE 车位编号 LIKE 'B-%';

-- 3. View verification.
SELECT * FROM v_space_stats;
SELECT * FROM v_free_space_stats;
SELECT * FROM v_fixed_space_status ORDER BY 车位编号 LIMIT 20;
SELECT * FROM v_monthly_charge_summary ORDER BY 收费月份 DESC;
SELECT * FROM v_parking_fee_rank ORDER BY 卡号, 单卡费用排名;

-- 4. Index optimization verification. Compare key/rows in EXPLAIN.
EXPLAIN SELECT * FROM ParkingRecord WHERE 卡号 = 'C1000001' AND 出库时间 IS NULL ORDER BY 入库时间 DESC;
EXPLAIN SELECT * FROM ParkingSpace WHERE 车位状态 = '空闲' AND 车位编号 LIKE 'B-%';

-- 5. Function and trigger demo.
SELECT fn_calculate_parking_fee(90) AS 停车90分钟费用;
INSERT IGNORE INTO Card (卡号, 车牌号, 车主姓名, 联系电话) VALUES ('CDEMO001', '粤D88888', '演示用户', '13900000000');
SET @record_id = CONCAT(DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), 'CDEMO001');
UPDATE ParkingSpace SET 车位状态 = '空闲', 当前停放车牌 = NULL WHERE 车位编号 = 'B-99';
INSERT INTO ParkingRecord (记录编号, 卡号, 停放车位编号, 入库时间) VALUES (@record_id, 'CDEMO001', 'B-99', DATE_SUB(NOW(), INTERVAL 90 MINUTE));
UPDATE ParkingSpace SET 车位状态 = '有车', 当前停放车牌 = '粤D88888' WHERE 车位编号 = 'B-99';
UPDATE ParkingRecord
SET 出库时间 = NOW(), 收费数额 = fn_calculate_parking_fee(TIMESTAMPDIFF(MINUTE, 入库时间, NOW()))
WHERE 记录编号 = @record_id;
UPDATE ParkingSpace SET 车位状态 = '空闲', 当前停放车牌 = NULL WHERE 车位编号 = 'B-99';
SELECT * FROM ParkingRecord WHERE 记录编号 = @record_id;
SELECT * FROM ParkingSpace WHERE 车位编号 = 'B-99';

-- 6. Full-text search demo.
SELECT 审计编号, 表名, 操作类型, 操作时间, 记录内容
FROM AuditLog
WHERE MATCH(记录内容) AGAINST('车辆 出库' IN NATURAL LANGUAGE MODE)
ORDER BY 操作时间 DESC
LIMIT 10;

-- 7. Monthly summary procedure with IN/OUT parameters.
SET @cnt = 0;
SET @total = 0;
CALL sp_generate_monthly_charge_summary(DATE_FORMAT(NOW(), '%Y-%m'), @cnt, @total);
SELECT @cnt AS 本月出库次数, @total AS 本月收费合计;
