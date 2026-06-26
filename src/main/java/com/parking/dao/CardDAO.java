package com.parking.dao;

import com.parking.entity.Card;
import com.parking.util.DBUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Card DAO - Data Access Object for Card table
 */
public class CardDAO {

    /**
     * Insert a new card
     */
    public boolean insert(Card card) {
        String sql = "INSERT INTO Card (卡号, 车牌号, 车主姓名, 联系电话, 车卡状态) VALUES (?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, card.get卡号());
            ps.setString(2, card.get车牌号());
            ps.setString(3, card.get车主姓名());
            ps.setString(4, card.get联系电话());
            ps.setString(5, normalizeStatus(card.get车卡状态()));
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Find card by card ID
     */
    public Card findByCardId(String 卡号) {
        String sql = "SELECT * FROM Card WHERE 卡号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 卡号);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractCard(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    /**
     * Find card by plate number
     */
    public Card findByPlate(String 车牌号) {
        String sql = "SELECT * FROM Card WHERE 车牌号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 车牌号);
            rs = ps.executeQuery();
            if (rs.next()) {
                return extractCard(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return null;
    }

    /**
     * Get all cards
     */
    public List<Card> findAll() {
        List<Card> list = new ArrayList<>();
        String sql = "SELECT * FROM Card ORDER BY 卡号";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(extractCard(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return list;
    }

    /**
     * Update card information, not status.
     */
    public boolean update(Card card) {
        String sql = "UPDATE Card SET 车牌号 = ?, 车主姓名 = ?, 联系电话 = ? WHERE 卡号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, card.get车牌号());
            ps.setString(2, card.get车主姓名());
            ps.setString(3, card.get联系电话());
            ps.setString(4, card.get卡号());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    public boolean updateStatus(String 卡号, String 车卡状态) {
        String sql = "UPDATE Card SET 车卡状态 = ? WHERE 卡号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 车卡状态);
            ps.setString(2, 卡号);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Physical deletion is kept only for old compatibility and is not used by the UI.
     */
    public boolean delete(String 卡号) {
        String sql = "DELETE FROM Card WHERE 卡号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 卡号);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    /**
     * Check if card exists
     */
    public boolean exists(String 卡号) {
        String sql = "SELECT COUNT(*) FROM Card WHERE 卡号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, 卡号);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return false;
    }

    private Card extractCard(ResultSet rs) throws SQLException {
        Card card = new Card();
        card.set卡号(rs.getString("卡号"));
        card.set车牌号(rs.getString("车牌号"));
        card.set车主姓名(rs.getString("车主姓名"));
        card.set联系电话(rs.getString("联系电话"));
        card.set车卡状态(normalizeStatus(rs.getString("车卡状态")));
        return card;
    }

    private String normalizeStatus(String status) {
        return (status == null || status.trim().isEmpty()) ? "正常" : status;
    }
}
