package com.parking.util;

import java.sql.*;

public class LogUtil {

    /**
     * 手动记录审计日志（用于Java代码调用）
     * @param tableName 表名
     * @param operation 操作类型 INSERT/UPDATE/DELETE
     * @param operator 操作员
     * @param content 记录内容
     */
    public static void log(String tableName, String operation, String operator, String content) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            String sql = "INSERT INTO AuditLog (表名, 操作类型, 操作员, 记录内容) VALUES (?, ?, ?, ?)";
            ps = conn.prepareStatement(sql);
            ps.setString(1, tableName);
            ps.setString(2, operation);
            ps.setString(3, operator == null ? "系统" : operator);
            ps.setString(4, content);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * 记录入库日志
     */
    public static void logCheckIn(String cardId, String spaceId, String ownerName) {
        String content = "车辆入库：卡号=" + cardId +
                "，车主=" + (ownerName == null ? "未知" : ownerName) +
                "，车位=" + spaceId;
        log("ParkingRecord", "INSERT", ownerName, content);
    }

    /**
     * 记录出库日志
     */
    public static void logCheckOut(String cardId, String spaceId, String ownerName, double fee) {
        String content = "车辆出库：卡号=" + cardId +
                "，车主=" + (ownerName == null ? "未知" : ownerName) +
                "，车位=" + spaceId +
                "，费用=" + fee + "元";
        log("ParkingRecord", "UPDATE", ownerName, content);
    }
}