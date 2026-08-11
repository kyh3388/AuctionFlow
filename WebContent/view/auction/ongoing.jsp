<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>

<%!
	private String escapeHtml(String value) {
	
		if (value == null) return "";
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}
	private String statusText(String status) {
		
		if ("ONGOING".equals(status)) return "진행중";
		if ("CLOSED".equals(status)) return "종료";
		if ("SOLD".equals(status)) return "낙찰";
		if ("UNSOLD".equals(status)) return "미낙찰";
		if ("CANCELED".equals(status)) return "취소";
		return status == null ? "" : status;
	}
%>

<%
	DataSet auctionList = (DataSet) request.getAttribute("AUCTION_LIST");
	
	int auctionCount = 0;
	String selectedSort = (String) request.getAttribute("SELECTED_SORT");
	
	if (auctionList != null) auctionCount = auctionList.getCount("A_NO");
	if (selectedSort == null || selectedSort.isBlank()) selectedSort = "LATEST";
	
	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>온라인 경매 사이트</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/auction/ongoing.css">
</head>

<body class="ongoing-page">

<!-- 공통 HEADER -->
<jsp:include page="/view/common/header.jsp" />

<!-- MAIN -->
<main class="ongoing">

	<div class="ongoing-inner">

		<section class="auction-section">

			<div class="auction-section-header">

				<div class="section-title-wrap">

					<span class="section-badge">Now</span>

					<h1 class="auction-section-title">진행 경매</h1>
				</div>
				
				<div class="auction-section-actions">
				
					<p class="auction-section-count">총 <%= auctionCount %>건</p>
				
					<form action="${pageContext.request.contextPath}/api/auctionFlow/auction/ongoing" method="get" class="sort-form">
						
						<label for="auctionSort" class="blind">경매 정렬</label>
						
						<select name="SORT" id="auctionSort" class="sort-select" onchange="this.form.submit();">
							<option value="LATEST" <%= "LATEST".equals(selectedSort) ? "selected" : "" %>>최신 등록순</option>
							<option value="OLDEST" <%= "OLDEST".equals(selectedSort) ? "selected" : "" %>>오래된 등록순</option>
							<option value="PRICE_HIGH" <%= "PRICE_HIGH".equals(selectedSort) ? "selected" : "" %>>시작가 높은순</option>
							<option value="PRICE_LOW" <%= "PRICE_LOW".equals(selectedSort) ? "selected" : "" %>>시작가 낮은순</option>
						</select>
					</form>
				</div>
			</div>

			<%
				if (auctionCount == 0) {
			%>
				<div class="empty-box">

					<p class="empty-title">진행 중인 경매가 없습니다.</p>
					<p class="empty-text">상품을 등록하면 진행 경매 목록에 표시됩니다.</p>
				</div>
			<%
				} else {
			%>

				<div class="auction-grid">

					<%
						for (int i=0; i<auctionCount; i++) {

							long auctionNo = auctionList.getLong("A_NO", i);						
							String auctionTitle = auctionList.getText("A_TITLE", i);
							long currentPrice = auctionList.getLong("A_CURRENT_PRICE", i);
							String auctionStatus = auctionList.getText("A_STATUS", i);
							String auctionEndDatetime = auctionList.getText("A_END_DATETIME", i);
							String imageStoredName = auctionList.getText("IMG_STORED_NAME", i);
					%>

						<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="auction-card">

							<div class="auction-image-box">

								<%
									if (imageStoredName != null && !imageStoredName.isBlank()) {
								%>

									<img src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>"
										alt="<%= escapeHtml(auctionTitle) %>" class="auction-image">
								<%
									} else {
								%>

									<div class="auction-image-placeholder">NO IMAGE</div>
								<%
									}
								%>
							</div>

							<div class="auction-info">

								<div class="auction-meta-row">

									<span class="auction-status ongoing"><%= escapeHtml(statusText(auctionStatus)) %></span>

								</div>

								<h2 class="auction-title"><%= escapeHtml(auctionTitle) %></h2>

								<p class="auction-price-label">현재가</p>

								<p class="auction-price"><%= priceFormat.format(currentPrice) %>원</p>
								
								<p class="auction-end-date">종료일 <%= escapeHtml(auctionEndDatetime) %></p>
							</div>
						</a>
					<%
						}
					%>
				</div>
			<%
				}
			%>
		</section>
	</div>
</main>

<!-- 공통 FOOTER -->
<jsp:include page="/view/common/footer.jsp" />

<%
	String loginSuccessAlert = (String) request.getAttribute("LOGIN_SUCCESS_ALERT");

	if ("Y".equals(loginSuccessAlert)) {
%>
	<script type="text/javascript">
		alert("로그인에 성공했습니다.");
	</script>
<%
	}
	
	String auctionRegisterSuccessAlert = (String) request.getAttribute("AUCTION_REGISTER_SUCCESS_ALERT");
	
	if ("Y".equals(auctionRegisterSuccessAlert)) {
%>
	<script type="text/javascript">
		alert("경매 상품이 등록되었습니다.");
	</script>
<%
	}
%>
</body>
</html>