<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>

<%!
	private String escapeHtml(String value) {
	
		if (value == null) {
			return "";
		}
		return value
				.replace("&", "&amp;")
				.replace("<", "&lt;")
				.replace(">", "&gt;")
				.replace("\"", "&quot;")
				.replace("'", "&#39;");
	}
	private String statusText(String status) {
		
		if ("ONGOING".equals(status)) {
			return "진행중";
		}
		if ("CLOSED".equals(status)) {
			return "종료";
		}
		if ("SOLD".equals(status)) {
			return "낙찰";
		}
		if ("UNSOLD".equals(status)) {
			return "미낙찰";
		}
		if ("CANCELED".equals(status)) {
			return "취소";
		}
		return status == null ? "" : status;
	}
%>

<%
	DataSet auctionList = (DataSet) request.getAttribute("AUCTION_LIST");
	
	int auctionCount = 0;
	
	if (auctionList != null) {
		auctionCount = auctionList.getCount("A_NO");
	}
	
	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>

<%
	String searchKeyword = (String) request.getAttribute("SEARCH_KEYWORD");

	if (searchKeyword == null) {
		searchKeyword = "";
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
<title>검색된 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/main.css">
</head>

<body class="main-page">

<!-- 공통 HEADER -->
<jsp:include page="/view/common/header.jsp" />

<main class="main">

	<div class="main-inner">

		<section class="auction-section">

			<div class="auction-section-header">

				<div class="section-title-wrap">

					<span class="section-badge">Search</span>

					<h1 class="auction-section-title">'<%= escapeHtml(searchKeyword) %>'검색 결과</h1>
				</div>

				<div class="auction-section-actions">
				
					<p class="auction-section-count">총 <%= auctionCount %>건</p>
				
					<form action="${pageContext.request.contextPath}/api/auctionFlow/auction/search" method="get" class="sort-form">
						
						<input type="hidden" name="KEYWORD" value="<%= escapeHtml(searchKeyword) %>">
						
						<label for="auctionSort" class="blind">검색 결과 정렬</label>
						
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

					<p class="empty-title">검색 결과가 없습니다.</p>
					
					<p class="empty-text">'<%= escapeHtml(searchKeyword) %>'과 일치하는 진행 경매 상품이 없습니다.</p>
				</div>
			<%
				} else {
			%>

				<div class="auction-grid">

					<%
						for (int i = 0; i < auctionCount; i++) {

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

</body>
</html>