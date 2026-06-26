package com.parking.entity;

public class Card {
    private String 卡号;
    private String 车牌号;
    private String 车主姓名;
    private String 联系电话;

    public Card() {}

    public Card(String 卡号, String 车牌号, String 车主姓名, String 联系电话) {
        this.卡号 = 卡号;
        this.车牌号 = 车牌号;
        this.车主姓名 = 车主姓名;
        this.联系电话 = 联系电话;
    }

    public String get卡号() { return 卡号; }
    public void set卡号(String 卡号) { this.卡号 = 卡号; }

    public String get车牌号() { return 车牌号; }
    public void set车牌号(String 车牌号) { this.车牌号 = 车牌号; }

    public String get车主姓名() { return 车主姓名; }
    public void set车主姓名(String 车主姓名) { this.车主姓名 = 车主姓名; }

    public String get联系电话() { return 联系电话; }
    public void set联系电话(String 联系电话) { this.联系电话 = 联系电话; }
}