package com.parking.dao;

import com.parking.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AuditLogDAO {

    public List<Map<String, Object>> findLatest(int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT * FROM AuditLog ORDER BY 操作时间 DESC LIMIT ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setInt(1, limit);
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("审计编号", rs.getLong("审计编号"));
                row.put("表名", rs.getString("表名"));
                row.put("操作类型", rs.getString("操作类型"));
                row.put("操作时间", rs.getTimestamp("操作时间"));
                row.put("操作员", rs.getString("操作员"));
                row.put("记录内容", rs.getString("记录内容"));
                list.add(row);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }
}
