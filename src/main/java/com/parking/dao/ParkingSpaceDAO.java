package com.parking.dao;

import com.parking.entity.ParkingSpace;
import com.parking.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ParkingSpace DAO - Data Access Object for ParkingSpace table
 */
public class ParkingSpaceDAO {

    /**
     * Get all parking spaces
     */
    public List<ParkingSpace> findAll() {
        List<ParkingSpace> list = new ArrayList<>();
        String sql = "SELECT * FROM ParkingSpace ORDER BY 车位编号";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                ParkingSpace space = new ParkingSpace();
                space.set车位编号(rs.getString("车位编号"));
                space.set车位状态(rs.getString("车位状态"));
                space.set当前停放车牌(rs.getString("当前停放车牌"));
                space.set固定车位卡号(rs.getString("固定车位卡号"));
                list.add(space);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Find parking space by space ID
     */
    public ParkingSpace findBySpaceId(String 车位编号) {
        String sql = "SELECT * FROM ParkingSpace WHERE 车位编号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 车位编号);
            rs = ps.executeQuery();
            if (rs.next()) {
                ParkingSpace space = new ParkingSpace();
                space.set车位编号(rs.getString("车位编号"));
                space.set车位状态(rs.getString("车位状态"));
                space.set当前停放车牌(rs.getString("当前停放车牌"));
                space.set固定车位卡号(rs.getString("固定车位卡号"));
                return space;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    /**
     * Update parking space status (check-in / check-out)
     */
    public boolean updateStatus(String 车位编号, String 车位状态, String 当前停放车牌) {
        String sql = "UPDATE ParkingSpace SET 车位状态 = ?, 当前停放车牌 = ? WHERE 车位编号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 车位状态);
            ps.setString(2, 当前停放车牌);
            ps.setString(3, 车位编号);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Update fixed space bound card ID (only allowed when space is idle)
     */
    public boolean updateFixedCard(String 车位编号, String 固定车位卡号) {
        String sql = "UPDATE ParkingSpace SET 固定车位卡号 = ? WHERE 车位编号 = ? AND 车位状态 = '空闲' AND 车位编号 LIKE 'A-%'";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 固定车位卡号);
            ps.setString(2, 车位编号);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Count total free spaces (B-xxx)
     */
    public int countFreeSpaces() {
        String sql = "SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'B-%'";
        return countBySql(sql);
    }

    /**
     * Count idle free spaces (B-xxx and status = '空闲')
     */
    public int countFreeIdleSpaces() {
        String sql = "SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'B-%' AND 车位状态 = '空闲'";
        return countBySql(sql);
    }

    /**
     * Count total fixed spaces (A-xxx)
     */
    public int countFixedSpaces() {
        String sql = "SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'A-%'";
        return countBySql(sql);
    }

    /**
     * Count occupied fixed spaces (A-xxx and status = '有车')
     */
    public int countFixedOccupied() {
        String sql = "SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'A-%' AND 车位状态 = '有车'";
        return countBySql(sql);
    }

    /**
     * Generic count method
     */
    private int countBySql(String sql) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return 0;
    }

    /**
     * Get all fixed spaces (A-xxx)
     */
    public List<ParkingSpace> findFixedSpaces() {
        List<ParkingSpace> list = new ArrayList<>();
        String sql = "SELECT * FROM ParkingSpace WHERE 车位编号 LIKE 'A-%' ORDER BY 车位编号";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                ParkingSpace space = new ParkingSpace();
                space.set车位编号(rs.getString("车位编号"));
                space.set车位状态(rs.getString("车位状态"));
                space.set当前停放车牌(rs.getString("当前停放车牌"));
                space.set固定车位卡号(rs.getString("固定车位卡号"));
                list.add(space);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Get all free spaces (B-xxx)
     */
    public List<ParkingSpace> findFreeSpaces() {
        List<ParkingSpace> list = new ArrayList<>();
        String sql = "SELECT * FROM ParkingSpace WHERE 车位编号 LIKE 'B-%' ORDER BY 车位编号";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                ParkingSpace space = new ParkingSpace();
                space.set车位编号(rs.getString("车位编号"));
                space.set车位状态(rs.getString("车位状态"));
                space.set当前停放车牌(rs.getString("当前停放车牌"));
                space.set固定车位卡号(rs.getString("固定车位卡号"));
                list.add(space);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }
}