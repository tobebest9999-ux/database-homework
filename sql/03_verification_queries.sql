-- 当前版本验证查询
-- 可在执行 01_schema_and_seed.sql 和 02_advanced_features.sql 后运行。

USE parking_system;
SET NAMES utf8mb4;

-- 1. 基础表检查。
SHOW FULL TABLES;

-- 2. 车位数量检查：应为 200 个，其中 A-00 到 A-99 为固定车位，B-00 到 B-99 为自由车位。
SELECT COUNT(*) AS 车位总数 FROM ParkingSpace;
SELECT LEFT(车位编号, 1) AS 车位类型, COUNT(*) AS 数量
FROM ParkingSpace
GROUP BY LEFT(车位编号, 1)
ORDER BY 车位类型;
SELECT MIN(车位编号) AS A区最小编号, MAX(车位编号) AS A区最大编号
FROM ParkingSpace
WHERE 车位编号 LIKE 'A-%';
SELECT MIN(车位编号) AS B区最小编号, MAX(车位编号) AS B区最大编号
FROM ParkingSpace
WHERE 车位编号 LIKE 'B-%';

-- 3. 车卡状态检查。
SELECT 车卡状态, COUNT(*) AS 数量
FROM Card
GROUP BY 车卡状态;

-- 4. 当前在场车辆检查。
SELECT *
FROM v_active_parking_detail
ORDER BY 入库时间 DESC
LIMIT 20;

-- 5. 收费记录检查。
SELECT *
FROM v_charge_record_detail
ORDER BY 收费时间 DESC
LIMIT 20;

-- 6. 审计日志检查。
SELECT 审计编号, 表名, 操作类型, 操作时间, 操作员, 记录内容
FROM AuditLog
ORDER BY 操作时间 DESC
LIMIT 20;

-- 7. 常用查询索引验证。
EXPLAIN SELECT *
FROM ParkingRecord
WHERE 卡号 = 'C1000001' AND 出库时间 IS NULL
ORDER BY 入库时间 DESC;

EXPLAIN SELECT *
FROM ParkingSpace
WHERE 车位状态 = '空闲' AND 车位编号 LIKE 'B-%';
