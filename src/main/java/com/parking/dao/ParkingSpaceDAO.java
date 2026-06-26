package com.parking.dao;

import com.parking.entity.ParkingSpace;
import com.parking.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ParkingSpaceDAO {

    public List<ParkingSpace> findAll() {
        return findBySql("SELECT * FROM ParkingSpace ORDER BY 车位编号");
    }

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
                return extractSpace(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    public ParkingSpace findIdleFixedSpaceByCardId(String 卡号) {
        String sql = "SELECT * FROM ParkingSpace WHERE 车位编号 LIKE 'A-%' AND 固定车位卡号 = ? AND 车位状态 = '空闲' ORDER BY 车位编号 LIMIT 1";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 卡号);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractSpace(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    public List<ParkingSpace> findIdleFreeSpaces() {
        return findBySql("SELECT * FROM ParkingSpace WHERE 车位编号 LIKE 'B-%' AND 车位状态 = '空闲' ORDER BY 车位编号");
    }

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

    public int countFreeSpaces() {
        return countBySql("SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'B-%'");
    }

    public int countFreeIdleSpaces() {
        return countBySql("SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'B-%' AND 车位状态 = '空闲'");
    }

    public int countFixedSpaces() {
        return countBySql("SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'A-%'");
    }

    public int countFixedOccupied() {
        return countBySql("SELECT COUNT(*) FROM ParkingSpace WHERE 车位编号 LIKE 'A-%' AND 车位状态 = '有车'");
    }

    public List<ParkingSpace> findFixedSpaces() {
        return findBySql("SELECT * FROM ParkingSpace WHERE 车位编号 LIKE 'A-%' ORDER BY 车位编号");
    }

    public List<ParkingSpace> findFreeSpaces() {
        return findBySql("SELECT * FROM ParkingSpace WHERE 车位编号 LIKE 'B-%' ORDER BY 车位编号");
    }

    private List<ParkingSpace> findBySql(String sql) {
        List<ParkingSpace> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractSpace(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }

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

    private ParkingSpace extractSpace(ResultSet rs) throws SQLException {
        ParkingSpace space = new ParkingSpace();
        space.set车位编号(rs.getString("车位编号"));
        space.set车位状态(rs.getString("车位状态"));
        space.set当前停放车牌(rs.getString("当前停放车牌"));
        space.set固定车位卡号(rs.getString("固定车位卡号"));
        return space;
    }
}
