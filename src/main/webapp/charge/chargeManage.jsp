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
        .container { max-width: 980px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .section h3 { color: #2c3e50; margin-bottom: 15px; border-left: 4px solid #3498db; padding-left: 12px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 120px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 250px; font-size: 14px; }
        .btn { padding: 10px 28px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.3s; margin: 5px 5px 5px 0; }
        .btn-primary { background: #3498db; color: white; }
        .btn-success { background: #2ecc71; color: white; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-warning { background: #f39c12; color: white; }
        .msg { padding: 12px 18px; border-radius: 8px; margin: 10px 0; }
        .msg-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .msg-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .msg-info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .msg-warning { background: #fff3cd; color: #856404; border: 1px solid #ffeeba; }
        .result-area { margin-top: 15px; padding: 20px; background: white; border-radius: 10px; border: 1px solid #ddd; display: none; }
        .result-area.show { display: block; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .info-grid .item { padding: 8px 0; border-bottom: 1px solid #eee; }
        .info-grid .item strong { display: inline-block; width: 130px; }
        .fee-display { background: #fff3cd; border: 2px solid #f39c12; border-radius: 10px; padding: 15px 20px; margin: 15px 0; text-align: center; }
        .fee-display .amount { font-size: 34px; font-weight: bold; color: #e67e22; }
        .fee-display .label { font-size: 16px; color: #555; }
        .record-box { border: 1px solid #3498db; border-radius: 10px; padding: 18px; margin-top: 15px; background: #f8fbff; }
        .record-box h4 { color: #2c3e50; margin-bottom: 10px; }
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
            <input type="text" id="cardId" placeholder="请输入卡号">
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
    let currentFee = 0;
    let lastChargeInfo = null;
    let lastChargeRecord = null;

    function queryCharge() {
        const cardId = document.getElementById('cardId').value.trim();
        if (!cardId) {
            showQuery('msg-error', '请输入卡号');
            hideChargeArea();
            return;
        }
        currentCardId = cardId;
        lastChargeRecord = null;

        fetch('<%= ctx %>/charge?action=getChargeInfo&cardId=' + encodeURIComponent(cardId))
            .then(res => res.json())
            .then(data => {
                if (data.code === 200) {
                    displayChargeInfo(data.data);
                } else {
                    showQuery(data.code === 404 ? 'msg-error' : 'msg-info', data.msg);
                    hideChargeArea();
                }
            })
            .catch(err => {
                showQuery('msg-error', '服务器错误： ' + err.message);
                hideChargeArea();
            });
    }

    function displayChargeInfo(info) {
        lastChargeInfo = info;
        currentRecordId = info.recordId;
        currentFee = info.fee || 0;

        let warning = '';
        if (info.cardStatus === '挂失' || info.cardStatus === '注销') {
            warning = '<div class="msg msg-warning">该车卡当前为' + escapeHtml(info.cardStatus) + '状态，但车辆已经在场，允许正常办理出库。</div>';
        }

        const content = document.getElementById('chargeContent');
        content.innerHTML =
            warning +
            '<h3>车辆与收费信息</h3>' +
            '<div class="info-grid">' +
            '<div class="item"><strong>卡号：</strong>' + escapeHtml(info.cardId) + '</div>' +
            '<div class="item"><strong>车牌号：</strong>' + escapeHtml(info.plate || '未知') + '</div>' +
            '<div class="item"><strong>车主姓名：</strong>' + escapeHtml(info.ownerName || '未知') + '</div>' +
            '<div class="item"><strong>联系电话：</strong>' + escapeHtml(info.phone || '未知') + '</div>' +
            '<div class="item"><strong>车位编号：</strong>' + escapeHtml(info.spaceId) + '</div>' +
            '<div class="item"><strong>车卡状态：</strong>' + escapeHtml(info.cardStatus || '正常') + '</div>' +
            '<div class="item"><strong>入库时间：</strong>' + escapeHtml(info.entryTime) + '</div>' +
            '<div class="item"><strong>当前时间：</strong>' + escapeHtml(info.currentTime) + '</div>' +
            '<div class="item"><strong>停车时长：</strong>' + escapeHtml(info.durationDisplay) + '</div>' +
            '<div class="item"><strong>停车分钟数：</strong>' + escapeHtml(info.minutes) + ' 分钟</div>' +
            '</div>' +
            '<div class="fee-display"><div class="label">应收总金额</div><div class="amount">¥' + escapeHtml(info.feeDisplay) + '</div></div>';

        document.getElementById('actionArea').innerHTML =
            '<div class="btn-group">' +
            '<button class="btn btn-success" onclick="doCheckout()">办理出库</button>' +
            '<button class="btn btn-warning" onclick="showInvoice()">发票</button>' +
            '<button class="btn btn-danger" onclick="cancelOperation()">取消</button>' +
            '</div>' +
            '<div id="actionResult"></div>';

        showQuery('msg-success', '已找到在场车辆');
        document.getElementById('chargeArea').className = 'result-area show';
    }

    function doCheckout() {
        if (!confirm('确定办理出库吗？系统将生成收费记录。')) return;

        fetch('<%= ctx %>/charge?action=checkout&recordId=' + encodeURIComponent(currentRecordId))
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('actionResult');
                if (data.code === 200) {
                    lastChargeRecord = data.chargeRecord;
                    resultDiv.innerHTML = '<div class="msg msg-success">出库成功，收费记录已生成。</div>' + renderChargeRecord(data.chargeRecord);
                    showQuery('msg-success', '已完成出库，卡号： ' + currentCardId);
                    document.getElementById('actionArea').querySelector('.btn-success').disabled = true;
                } else {
                    resultDiv.innerHTML = '<div class="msg msg-error">' + escapeHtml(data.msg) + '</div>';
                }
            });
    }

    function renderChargeRecord(record) {
        if (!record) return '';
        return '<div class="record-box">' +
            '<h4>收费记录</h4>' +
            '<div class="info-grid">' +
            '<div class="item"><strong>收费编号：</strong>' + escapeHtml(record.chargeId) + '</div>' +
            '<div class="item"><strong>停车记录编号：</strong>' + escapeHtml(record.recordId) + '</div>' +
            '<div class="item"><strong>卡号：</strong>' + escapeHtml(record.cardId) + '</div>' +
            '<div class="item"><strong>车位编号：</strong>' + escapeHtml(record.spaceId) + '</div>' +
            '<div class="item"><strong>停车时长：</strong>' + escapeHtml(record.durationDisplay) + '</div>' +
            '<div class="item"><strong>收费金额：</strong>¥' + escapeHtml(record.feeDisplay) + '</div>' +
            '<div class="item"><strong>收费时间：</strong>' + escapeHtml(record.chargeTime) + '</div>' +
            '<div class="item"><strong>支付状态：</strong>' + escapeHtml(record.payStatus) + '</div>' +
            '</div></div>';
    }

    function showInvoice() {
        const info = lastChargeInfo;
        if (!info) return;
        const record = lastChargeRecord;
        let text = '停车收费发票\n' +
            '卡号：' + info.cardId + '\n' +
            '车牌号：' + (info.plate || '未知') + '\n' +
            '车主姓名：' + (info.ownerName || '未知') + '\n' +
            '联系电话：' + (info.phone || '未知') + '\n' +
            '车位编号：' + info.spaceId + '\n' +
            '停车时长：' + info.durationDisplay + '\n' +
            '收费金额：¥' + info.feeDisplay;
        if (record) {
            text += '\n收费编号：' + record.chargeId + '\n支付状态：' + record.payStatus;
        }
        alert(text);
    }

    function cancelOperation() {
        hideChargeArea();
        document.getElementById('queryResult').innerHTML = '';
        document.getElementById('cardId').value = '';
    }

    function showQuery(cls, msg) {
        document.getElementById('queryResult').innerHTML = '<div class="msg ' + cls + '">' + escapeHtml(msg) + '</div>';
    }

    function hideChargeArea() {
        document.getElementById('chargeArea').className = 'result-area';
        document.getElementById('chargeContent').innerHTML = '';
        document.getElementById('actionArea').innerHTML = '';
    }

    function escapeHtml(str) {
        var div = document.createElement('div');
        div.textContent = str == null ? '' : String(str);
        return div.innerHTML;
    }

    document.getElementById('cardId').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') queryCharge();
    });
</script>
</body>
</html>
