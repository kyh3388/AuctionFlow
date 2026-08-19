<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>

<%!
	private String escapeHtml(String value) {
		if (value == null) {
			return "";
		}
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}
%>

<%!
	private String auctionResultText(String status) {
		
		if ("SOLD".equals(status)) {
			return "낙찰";
		}
		if ("UNSOLD".equals(status)) {	
			return "미낙찰";
		}
		if ("CANCELED".equals(status)) {
			return "관리자 취소";
		}
		return "";
	}

	private String auctionResultClass(String status) {
		
		if ("SOLD".equals(status)) {
			return "sold";
		}
		if ("UNSOLD".equals(status)) {	
			return "unsold";
		}
		if ("CANCELED".equals(status)) {
			return "canceled";
		}
		return "";
	}
	
	private String displayText(String value) {
		//보여줄 값이 없을 경우 - 보여줌
		if (value == null || value.isBlank()) {
			return "-";
		}
		return value;
	}
%>

<%
	DataSet auctionList = (DataSet) request.getAttribute("AUCTION_PAST_LIST");

	int auctionCount = 0;

	if (auctionList != null) {
		auctionCount = auctionList.getCount("A_NO");
	}

	String selectedSort = (String) request.getAttribute("SELECTED_SORT");

	if (selectedSort == null || selectedSort.isBlank()) {
		selectedSort = "LATEST";
	}
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>지난 경매 조회 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/auction/pastList.css">
</head>

<body class="past-list-page">

<!-- 공통 HEADER -->
<jsp:include page="/view/common/header.jsp" />

<main class="main">

	<div class="main-inner">

		<section class="auction-section">

			<div class="auction-section-header">

				<div class="section-title-wrap">
					<span class="section-badge past">Closed</span>
					<h1 class="auction-section-title">지난 경매</h1>
				</div>

				<div class="auction-section-actions">

					<p class="auction-section-count">총 <%= auctionCount %>건</p>

					<form action="${pageContext.request.contextPath}/api/auctionFlow/auction/pastList" method="get" class="sort-form">
						<label for="auctionSort" class="blind">지난 경매 정렬</label>

						<select name="SORT" id="auctionSort" class="sort-select" onchange="this.form.submit();">
							<option value="LATEST" <%= "LATEST".equals(selectedSort) ? "selected" : "" %>>최신 등록순</option>
							<option value="OLDEST" <%= "OLDEST".equals(selectedSort) ? "selected" : "" %>>오래된 등록순</option>
							<option value="PRICE_HIGH" <%= "PRICE_HIGH".equals(selectedSort) ? "selected" : "" %>>현재가 높은순</option>
							<option value="PRICE_LOW" <%= "PRICE_LOW".equals(selectedSort) ? "selected" : "" %>>현재가 낮은순</option>
						</select>
					</form>
				</div>
			</div>

			<%
				if (auctionCount == 0) {
			%>
				<div class="empty-box">
					<p class="empty-title">지난 경매가 없습니다.</p>
					<p class="empty-text">종료된 경매가 생기면 지난 경매 목록에 표시됩니다.</p>
				</div>
			<%
				} else {
			%>
				<div class="auction-grid">
					<%
						for (int i=0; i<auctionCount; i++) {

							long auctionNo = auctionList.getLong("A_NO", i);						
							String auctionTitle = auctionList.getText("A_TITLE", i);
							String auctionStatus = auctionList.getText("A_STATUS", i);
							String auctionEndDatetime = auctionList.getText("A_END_DATETIME", i);
							String auctionClosedDatetime = auctionList.getText("A_CLOSED_DATETIME", i);
							String imageStoredName = auctionList.getText("IMG_STORED_NAME", i);
							boolean isCanceled = "CANCELED".equals(auctionStatus);
							
							String displayDatetime = auctionClosedDatetime;
							if (displayDatetime == null || displayDatetime.isBlank()) {
								displayDatetime = auctionEndDatetime;
							}
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
								<h2 class="auction-title"><%= escapeHtml(auctionTitle) %></h2>
								<p class="auction-price-label">경매 상태</p>
								<p class="auction-price auction-result <%= auctionResultClass(auctionStatus) %>"><%= escapeHtml(auctionResultText(auctionStatus)) %></p>
								<p class="auction-end-date"><%= isCanceled ? "취소일" : "종료일" %> <%= escapeHtml(displayText(displayDatetime)) %></p>
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

</body>
</html>