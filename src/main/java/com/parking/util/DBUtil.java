package com.parking.util;

import java.sql.*;

public class DBUtil {

    // ========== 请修改为您的实际数据库配置 ==========
    private static final String URL = "jdbc:mysql://localhost:3306/parking_system?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf8&allowPublicKeyRetrieval=true";
    private static final String USER = "root";        // 改成您的MySQL用户名
    private static final String PASSWORD = "123456";  // 改成您的MySQL密码
    // ==============================================

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("✅ MySQL驱动加载成功！");
        } catch (ClassNotFoundException e) {
            System.err.println("❌ MySQL驱动加载失败！");
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    public static void close(ResultSet rs, Statement stmt, Connection conn) {
        close(rs);
        close(stmt);
        close(conn);
    }

    public static void close(Statement stmt, Connection conn) {
        close(stmt);
        close(conn);
    }

    public static void close(ResultSet rs) {
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    public static void close(Statement stmt) {
        if (stmt != null) {
            try { stmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    public static void close(Connection conn) {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
}