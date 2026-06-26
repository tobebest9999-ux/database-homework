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
        .invoice-box { border: 2px dashed #3498db; border-radius: 10px; padding: 18px 22px; margin-top: 16px; background: #fbfdff; }
        .invoice-box h4 { text-align: center; color: #2c3e50; margin-bottom: 14px; font-size: 18px; }
        .invoice-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; gap: 20px; }
        .invoice-row span:last-child { text-align: right; }
        .invoice-row.total { border-bottom: none; color: #e74c3c; font-weight: bold; font-size: 18px; }
        .invoice-time { text-align: center; color: #777; font-size: 12px; margin-top: 18px; }
        .btn-group { margin-top: 15px; }
        .modal-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.45); display: none; align-items: center; justify-content: center; padding: 20px; z-index: 1000; }
        .modal-mask.show { display: flex; }
        .modal-card { width: min(760px, 100%); max-height: 90vh; overflow-y: auto; background: white; border-radius: 14px; padding: 24px; box-shadow: 0 16px 50px rgba(0,0,0,0.28); }
        .modal-card h3 { text-align: center; color: #2c3e50; margin-bottom: 12px; }
        .modal-tip { text-align: center; color: #666; margin-bottom: 12px; }
        .modal-actions { display: flex; justify-content: center; gap: 12px; margin-top: 18px; }
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

<div id="invoiceModal" class="modal-mask">
    <div class="modal-card">
        <h3>发票预览</h3>
        <div class="modal-tip">请先核对发票内容，确认无误后点击“确定生成”。</div>
        <div id="invoicePreview"></div>
        <div class="modal-actions">
            <button class="btn btn-warning" onclick="confirmInvoice()">确定生成</button>
            <button class="btn btn-danger" onclick="closeInvoiceModal()">取消</button>
        </div>
    </div>
</div>

<script>
    let currentCardId = '';
    let currentRecordId = '';
    let currentFee = 0;
    let lastChargeInfo = null;
    let pendingInvoiceHtml = '';

    function queryCharge() {
        const cardId = document.getElementById('cardId').value.trim();
        if (!cardId) {
            showQuery('msg-error', '请输入卡号');
            hideChargeArea();
            return;
        }
        currentCardId = cardId;

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
        pendingInvoiceHtml = '';

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
            '<div class="fee-display"><div class="label">应收总金额</div><div class="amount">¥' + escapeHtml(info.feeDisplay) + '</div></div>' +
            '<div id="invoiceArea"></div>';

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
        if (!confirm('确定要办理出库吗？系统将自动计算费用并生成收费记录。')) return;

        fetch('<%= ctx %>/charge?action=checkout&recordId=' + encodeURIComponent(currentRecordId))
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('actionResult');
                if (data.code === 200 && data.chargeRecord) {
                    resultDiv.innerHTML = '<div class="msg msg-success">出库成功，正在打开收费记录页面。</div>';
                    const chargeId = encodeURIComponent(data.chargeRecord.chargeId);
                    window.location.href = '<%= ctx %>/charge/chargeRecord.jsp?chargeId=' + chargeId;
                } else {
                    resultDiv.innerHTML = '<div class="msg msg-error">' + escapeHtml(data.msg || '出库失败') + '</div>';
                }
            })
            .catch(err => {
                document.getElementById('actionResult').innerHTML = '<div class="msg msg-error">服务器错误： ' + escapeHtml(err.message) + '</div>';
            });
    }

    function showInvoice() {
        const info = lastChargeInfo;
        if (!info) return;
        pendingInvoiceHtml = buildInvoiceHtml(info, formatDateTime(new Date()));
        document.getElementById('invoicePreview').innerHTML = pendingInvoiceHtml;
        document.getElementById('invoiceModal').className = 'modal-mask show';
    }

    function confirmInvoice() {
        if (!pendingInvoiceHtml) return;
        document.getElementById('invoiceArea').innerHTML = pendingInvoiceHtml;
        closeInvoiceModal();
    }

    function closeInvoiceModal() {
        document.getElementById('invoiceModal').className = 'modal-mask';
    }

    function buildInvoiceHtml(info, invoiceTime) {
        return '<div class="invoice-box">' +
            '<h4>停车收费发票</h4>' +
            '<div class="invoice-row"><span>卡号</span><span>' + escapeHtml(info.cardId) + '</span></div>' +
            '<div class="invoice-row"><span>车位编号</span><span>' + escapeHtml(info.spaceId) + '</span></div>' +
            '<div class="invoice-row"><span>入库时间</span><span>' + escapeHtml(info.entryTime) + '</span></div>' +
            '<div class="invoice-row"><span>出库时间</span><span>' + escapeHtml(invoiceTime) + '</span></div>' +
            '<div class="invoice-row"><span>停车时长</span><span>' + escapeHtml(info.durationDisplay) + '</span></div>' +
            '<div class="invoice-row"><span>收费金额</span><span>¥' + escapeHtml(info.feeDisplay) + '</span></div>' +
            '<div class="invoice-row total"><span>合计</span><span>¥' + escapeHtml(info.feeDisplay) + '</span></div>' +
            '<div class="invoice-time">生成时间：' + escapeHtml(invoiceTime) + '</div>' +
            '</div>';
    }

    function formatDateTime(date) {
        const pad = n => String(n).padStart(2, '0');
        return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + 'T' +
            pad(date.getHours()) + ':' + pad(date.getMinutes()) + ':' + pad(date.getSeconds());
    }

    function cancelOperation() {
        closeInvoiceModal();
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
