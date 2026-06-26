<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>收费管理</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .section h3 { color: #2c3e50; margin-bottom: 15px; border-left: 4px solid #3498db; padding-left: 12px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 120px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 250px; font-size: 14px; }
        .btn { padding: 10px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.3s; margin: 5px 5px 5px 0; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-success { background: #2ecc71; color: white; }
        .btn-success:hover { background: #27ae60; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-danger:hover { background: #c0392b; }
        .btn-warning { background: #f39c12; color: white; }
        .btn-warning:hover { background: #e67e22; }
        .msg { padding: 12px 18px; border-radius: 8px; margin: 10px 0; }
        .msg-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .msg-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .msg-info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .result-area { margin-top: 15px; padding: 20px; background: white; border-radius: 10px; border: 1px solid #ddd; display: none; }
        .result-area.show { display: block; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .info-grid .item { padding: 8px 0; border-bottom: 1px solid #eee; }
        .info-grid .item strong { display: inline-block; width: 130px; }
        .fee-display { background: #fff3cd; border: 2px solid #f39c12; border-radius: 10px; padding: 15px 20px; margin: 15px 0; text-align: center; }
        .fee-display .amount { font-size: 36px; font-weight: bold; color: #e67e22; }
        .fee-display .label { font-size: 16px; color: #555; }
        .invoice-box { border: 2px dashed #3498db; border-radius: 10px; padding: 20px; margin: 15px 0; background: #f8f9fa; }
        .invoice-box h4 { text-align: center; color: #2c3e50; margin-bottom: 15px; }
        .invoice-box .row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #eee; }
        .invoice-box .row.total { border-bottom: none; font-weight: bold; font-size: 18px; color: #e74c3c; }
        .btn-group { margin-top: 15px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>收费管理</h1>

    <div class="section">
        <h3>输入卡号</h3>
        <div class="form-group">
            <label>卡号：</label>
            <input type="text" id="cardId" placeholder="请输入卡号" style="width:250px;">
            <button class="btn btn-primary" onclick="queryCharge()">查询</button>
        </div>
        <div id="queryResult"></div>
    </div>

    <div id="chargeArea" class="result-area">
        <div id="chargeContent"></div>
        <div id="actionArea"></div>
    </div>
</div>

<script>
    let currentCardId = '';
    let currentRecordId = '';
    let current收费金额 = 0;

    function queryCharge() {
        const cardId = document.getElementById('cardId').value.trim();
        if (!cardId) {
            document.getElementById('queryResult').innerHTML =
                '<div class="msg msg-error">❌ 请输入卡号</div>';
            document.getElementById('chargeArea').className = 'result-area';
            return;
        }
        currentCardId = cardId;

        console.log("=== queryCharge 开始 ===");
        console.log("cardId:", cardId);

        fetch('<%= ctx %>/parking?action=getActive&cardId=' + encodeURIComponent(cardId))
            .then(res => {
                console.log("getActive 响应状态:", res.status);
                return res.json();
            })
            .then(data => {
                console.log("getActive 返回数据:", data);

                if (data.code === 200) {
                    console.log("卡在库内，获取收费信息...");
                    return fetch('<%= ctx %>/charge?action=getChargeInfo&cardId=' + encodeURIComponent(cardId));
                } else {
                    document.getElementById('queryResult').innerHTML =
                        '<div class="msg msg-info">ℹ️ 该车卡车辆当前不在场，无需结算费用。</div>';
                    document.getElementById('chargeArea').className = 'result-area';
                    return null;
                }
            })
            .then(res => {
                if (!res) return null;
                console.log("getChargeInfo 响应状态:", res.status);
                return res.json();
            })
            .then(data => {
                if (!data) return;
                console.log("getChargeInfo 返回数据:", data);

                if (data.code === 200) {
                    console.log("收费信息获取成功，调用 displayChargeInfo");
                    displayChargeInfo(data.data);
                } else {
                    console.log("收费信息获取失败:", data.msg);
                    document.getElementById('queryResult').innerHTML =
                        '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                    document.getElementById('chargeArea').className = 'result-area';
                }
            })
            .catch(err => {
                console.error("请求出错:", err);
                document.getElementById('queryResult').innerHTML =
                    '<div class="msg msg-error">❌ 服务器错误： ' + err.message + '</div>';
            });
    }

    function displayChargeInfo(info) {
        console.log("=== displayChargeInfo 被调用 ===");
        console.log("info 对象:", info);

        if (!info) {
            document.getElementById('queryResult').innerHTML =
                '<div class="msg msg-error">❌ 未获取到收费信息</div>';
            document.getElementById('chargeArea').className = 'result-area';
            return;
        }

        currentRecordId = info.recordId;
        current收费金额 = info.fee || 0;

        // 安全获取字段值
        var cardId = info.cardId || '暂无';
        var spaceId = info.spaceId || '暂无';
        var entry时间 = info.entryTime || '暂无';
        var current时间 = info.currentTime || '暂无';
        var durationDisplay = info.durationDisplay || '暂无';
        var minutes = info.minutes || 0;
        var feeDisplay = info.feeDisplay || '0.00';

        const content = document.getElementById('chargeContent');
        content.innerHTML =
            '<h3>📋 车辆与收费信息</h3>' +
            '<div class="info-grid">' +
            '   <div class="item"><strong>卡号：</strong> ' + cardId + '</div>' +
            '   <div class="item"><strong>车位编号：</strong> ' + spaceId + '</div>' +
            '   <div class="item"><strong>入库时间：</strong> ' + entry时间 + '</div>' +
            '   <div class="item"><strong>当前时间：</strong> ' + current时间 + '</div>' +
            '   <div class="item"><strong>停车时长：</strong> ' + durationDisplay + '</div>' +
            '   <div class="item"><strong>停车分钟数：</strong> ' + minutes + ' 分钟</div>' +
            '</div>' +
            '<div class="fee-display">' +
            '   <div class="label">💰 应收总金额</div>' +
            '   <div class="amount">¥' + feeDisplay + '</div>' +
            '</div>';

        const action = document.getElementById('actionArea');
        action.innerHTML =
            '<div class="btn-group">' +
            '   <button class="btn btn-success" onclick="doCheckout()">办理出库</button>' +
            '   <button class="btn btn-warning" onclick="showInvoice()">发票</button>' +
            '   <button class="btn btn-danger" onclick="cancelOperation()">取消</button>' +
            '</div>' +
            '<div id="actionResult"></div>';

        document.getElementById('queryResult').innerHTML =
            '<div class="msg msg-success">✅ 已找到在场车辆</div>';
        document.getElementById('chargeArea').className = 'result-area show';
    }

    function doCheckout() {
        if (!confirm('⚠️ 确定办理出库吗？系统将收取本次停车费用。')) return;

        fetch('<%= ctx %>/charge?action=checkout&recordId=' + encodeURIComponent(currentRecordId))
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('actionResult');
                if (data.code === 200) {
                    resultDiv.innerHTML =
                        '<div class="msg msg-success">✅ 出库成功！ 收费金额： ¥' + current收费金额.toFixed(2) + '</div>';

                    setTimeout(function() {
                        if (confirm('🧾 是否打印发票？')) {
                            showInvoice();
                        }
                    }, 300);

                    document.getElementById('chargeArea').className = 'result-area';
                    document.getElementById('queryResult').innerHTML =
                        '<div class="msg msg-success">✅ 已完成出库，卡号： ' + currentCardId + '</div>';
                } else {
                    resultDiv.innerHTML = '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                }
            });
    }

    function showInvoice() {
        fetch('<%= ctx %>/charge?action=getChargeInfo&cardId=' + encodeURIComponent(currentCardId))
            .then(res => res.json())
            .then(data => {
                if (data.code === 200) {
                    var info = data.data;
                    var invoiceHTML =
                        '<div class="invoice-box">' +
                        '   <h4>🧾 停车收费发票</h4>' +
                        '   <div class="row"><span>卡号</span><span>' + info.cardId + '</span></div>' +
                        '   <div class="row"><span>车位编号</span><span>' + info.spaceId + '</span></div>' +
                        '   <div class="row"><span>入库时间</span><span>' + info.entryTime + '</span></div>' +
                        '   <div class="row"><span>出库时间</span><span>' + info.currentTime + '</span></div>' +
                        '   <div class="row"><span>停车时长</span><span>' + info.durationDisplay + '</span></div>' +
                        '   <div class="row"><span>收费金额</span><span>¥' + info.feeDisplay + '</span></div>' +
                        '   <div class="row total"><span>合计</span><span>¥' + info.feeDisplay + '</span></div>' +
                        '   <div style="text-align:center; margin-top:10px; color:#888; font-size:12px;">' +
                        '       生成时间：' + info.currentTime +
                        '   </div>' +
                        '</div>';

                    var content = document.getElementById('chargeContent');
                    var existingInvoice = content.querySelector('.invoice-box');
                    if (existingInvoice) {
                        existingInvoice.remove();
                    }
                    content.insertAdjacentHTML('beforeend', invoiceHTML);

                    alert(
                        '═══════════════════════════════\n' +
                        '        停车收费发票\n' +
                        '═══════════════════════════════\n' +
                        '  卡号    : ' + info.cardId + '\n' +
                        '  车位编号   : ' + info.spaceId + '\n' +
                        '  入库时间 : ' + info.entryTime + '\n' +
                        '  出库时间  : ' + info.currentTime + '\n' +
                        '  停车时长   : ' + info.durationDisplay + '\n' +
                        '  收费金额        : ¥' + info.feeDisplay + '\n' +
                        '═══════════════════════════════\n' +
                        '  谢谢使用！'
                    );
                }
            });
    }

    function cancelOperation() {
        document.getElementById('chargeArea').className = 'result-area';
        document.getElementById('queryResult').innerHTML = '';
        document.getElementById('cardId').value = '';
    }

    document.getElementById('cardId').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') queryCharge();
    });
</script>
</body>
</html>