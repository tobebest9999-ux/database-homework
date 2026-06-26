package com.parking.dao;

import com.parking.entity.ParkingRecord;
import com.parking.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ParkingRecord DAO - Data Access Object for ParkingRecord table
 */
public class ParkingRecordDAO {

    /**
     * Insert parking record (check-in)
     */
    public boolean insert(ParkingRecord record) {
        String sql = "INSERT INTO ParkingRecord (记录编号, 卡号, 停放车位编号, 入库时间, 出库时间, 收费数额) " +
                "VALUES (?, ?, ?, ?, NULL, NULL)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, record.get记录编号());
            ps.setString(2, record.get卡号());
            ps.setString(3, record.get停放车位编号());
            ps.setTimestamp(4, record.get入库时间());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Find active (check-in) record by card ID (exit_time is NULL)
     */
    public ParkingRecord findActiveByCardId(String 卡号) {
        String sql = "SELECT * FROM ParkingRecord WHERE 卡号 = ? AND 出库时间 IS NULL ORDER BY 入库时间 DESC LIMIT 1";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 卡号);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractRecord(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    /**
     * Find record by record ID
     */
    public ParkingRecord findByRecordId(String 记录编号) {
        String sql = "SELECT * FROM ParkingRecord WHERE 记录编号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 记录编号);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractRecord(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    /**
     * Update exit time and fee using normal Java business flow.
     */
    public boolean updateExit(String 记录编号, Timestamp 出库时间, double 收费数额) {
        String sql = "UPDATE ParkingRecord SET 出库时间 = ?, 收费数额 = ? WHERE 记录编号 = ? AND 出库时间 IS NULL";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setTimestamp(1, 出库时间);
            ps.setDouble(2, 收费数额);
            ps.setString(3, 记录编号);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Get all records by card ID
     */
    public List<ParkingRecord> findByCardId(String 卡号) {
        List<ParkingRecord> list = new ArrayList<>();
        String sql = "SELECT * FROM ParkingRecord WHERE 卡号 = ? ORDER BY 入库时间 DESC";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 卡号);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractRecord(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Get all active (check-in) records
     */
    public List<ParkingRecord> findAllActive() {
        List<ParkingRecord> list = new ArrayList<>();
        String sql = "SELECT * FROM ParkingRecord WHERE 出库时间 IS NULL";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractRecord(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Extract ParkingRecord from ResultSet
     */
    private ParkingRecord extractRecord(ResultSet rs) throws SQLException {
        ParkingRecord record = new ParkingRecord();
        record.set记录编号(rs.getString("记录编号"));
        record.set卡号(rs.getString("卡号"));
        record.set停放车位编号(rs.getString("停放车位编号"));
        record.set入库时间(rs.getTimestamp("入库时间"));
        record.set出库时间(rs.getTimestamp("出库时间"));
        Double fee = rs.getDouble("收费数额");
        record.set收费数额(rs.wasNull() ? null : fee);
        return record;
    }
}