<%@ page contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" %>

<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>

<%
	boolean isAdminLogin =
		Boolean.TRUE.equals(
			session.getAttribute("LOGIN_ADMIN")
		);

	if (!isAdminLogin) {
%>

	<jsp:forward page="/view/error/error.jsp" />

<%
		return;
	}

	request.setAttribute(
		"ADMIN_MENU",
		"MEMBER"
	);
%>

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
	DataSet memberDetail =
		(DataSet) request.getAttribute(
			"MEMBER_DETAIL"
		);

	if (
		memberDetail == null
		|| memberDetail.getCount("M_NO") == 0
	) {
%>

	<jsp:forward page="/view/error/error.jsp" />

<%
		return;
	}

	String selectedTab =
		(String) request.getAttribute(
			"SELECTED_TAB"
		);

	if (selectedTab == null) {

		selectedTab = "PROFILE";
	}

	long memberNo =
		memberDetail.getLong(
			"M_NO",
			0
		);

	String memberId =
		memberDetail.getText(
			"M_ID",
			0
		);

	String memberName =
		memberDetail.getText(
			"M_NAME",
			0
		);

	String memberPhoneNumber =
		memberDetail.getText(
			"M_PHONE_NUMBER",
			0
		);

	String memberEmail =
		memberDetail.getText(
			"M_EMAIL",
			0
		);

	String memberAddress =
		memberDetail.getText(
			"M_ADDRESS",
			0
		);

	String createdDatetime =
		memberDetail.getText(
			"CREATED_DATETIME",
			0
		);

	String updatedDatetime =
		memberDetail.getText(
			"UPDATED_DATETIME",
			0
		);

	DataSet memberAuctionList =
		(DataSet) request.getAttribute(
			"MEMBER_AUCTION_LIST"
		);

	DataSet memberBidList =
		(DataSet) request.getAttribute(
			"MEMBER_BID_LIST"
		);

	int memberAuctionCount = 0;

	if (memberAuctionList != null) {

		memberAuctionCount =
			memberAuctionList.getCount("A_NO");
	}

	int memberBidCount = 0;

	if (memberBidList != null) {

		memberBidCount =
			memberBidList.getCount("BID_NO");
	}

	DecimalFormat priceFormat =
		new DecimalFormat("#,###");

	String contextPath =
		request.getContextPath();

	String detailUrl =
		contextPath
		+ "/api/auctionFlow/admin/member/detail?M_NO="
		+ memberNo;
%>

<!DOCTYPE html>
<html lang="ko">

<head>
	<meta charset="UTF-8">

	<title>AuctionFlow 회원 상세</title>

	<link
		rel="stylesheet"
		href="<%= contextPath %>/static/css/admin/common/sidebar.css">

	<link
		rel="stylesheet"
		href="<%= contextPath %>/static/css/admin/member/memberDetail.css">
</head>

<body>

	<div class="admin-layout">

		<jsp:include
			page="/view/admin/common/sidebar.jsp" />

		<main class="admin-content">

			<div class="admin-page-header">

				<div>

					<h1 class="admin-page-title">
						회원 상세
					</h1>

					<p class="admin-page-description">
						회원의 개인정보와 경매 활동 내역을 확인합니다.
					</p>

				</div>

				<a
					href="<%= contextPath %>/api/auctionFlow/admin/member"
					class="admin-button admin-button-secondary">
					목록으로
				</a>

			</div>

			<section class="member-summary">

				<div class="member-summary-item">

					<span class="member-summary-label">
						회원 번호
					</span>

					<strong class="member-summary-value">
						<%= memberNo %>
					</strong>

				</div>

				<div class="member-summary-item">

					<span class="member-summary-label">
						아이디
					</span>

					<strong class="member-summary-value">
						<%= escapeHtml(memberId) %>
					</strong>

				</div>

				<div class="member-summary-item">

					<span class="member-summary-label">
						이름
					</span>

					<strong class="member-summary-value">
						<%= escapeHtml(memberName) %>
					</strong>

				</div>

			</section>

			<nav class="member-detail-tabs">

				<a
					href="<%= detailUrl %>&TAB=PROFILE"
					class="member-detail-tab <%= "PROFILE".equals(selectedTab) ? "active" : "" %>">
					개인정보
				</a>

				<a
					href="<%= detailUrl %>&TAB=AUCTION"
					class="member-detail-tab <%= "AUCTION".equals(selectedTab) ? "active" : "" %>">
					경매 등록 내역
				</a>

				<a
					href="<%= detailUrl %>&TAB=BID"
					class="member-detail-tab <%= "BID".equals(selectedTab) ? "active" : "" %>">
					입찰 내역
				</a>

			</nav>

			<%
				if ("PROFILE".equals(selectedTab)) {
			%>

				<section class="admin-panel">

					<div class="admin-panel-header">

						<h2 class="admin-panel-title">
							개인정보
						</h2>

					</div>

					<dl class="member-profile-list">

						<div class="member-profile-row">
							<dt>회원 번호</dt>
							<dd><%= memberNo %></dd>
						</div>

						<div class="member-profile-row">
							<dt>아이디</dt>
							<dd><%= escapeHtml(memberId) %></dd>
						</div>

						<div class="member-profile-row">
							<dt>이름</dt>
							<dd><%= escapeHtml(memberName) %></dd>
						</div>

						<div class="member-profile-row">
							<dt>휴대폰 번호</dt>
							<dd><%= escapeHtml(memberPhoneNumber) %></dd>
						</div>

						<div class="member-profile-row">
							<dt>이메일</dt>
							<dd><%= escapeHtml(memberEmail) %></dd>
						</div>

						<div class="member-profile-row">
							<dt>주소</dt>
							<dd><%= escapeHtml(memberAddress) %></dd>
						</div>

						<div class="member-profile-row">
							<dt>가입일</dt>
							<dd><%= escapeHtml(createdDatetime) %></dd>
						</div>

						<div class="member-profile-row">
							<dt>최종 수정일</dt>
							<dd><%= escapeHtml(updatedDatetime) %></dd>
						</div>

					</dl>

				</section>

			<%
				} else if ("AUCTION".equals(selectedTab)) {
			%>

				<section class="admin-panel">

					<div class="admin-panel-header">

						<h2 class="admin-panel-title">
							경매 등록 내역
						</h2>

						<p class="admin-panel-count">
							총
							<strong><%= memberAuctionCount %></strong>
							건
						</p>

					</div>

					<div class="admin-table-wrap">

						<table class="admin-table member-auction-table">

							<thead>
								<tr>
									<th>경매 번호</th>
									<th>분류</th>
									<th>제목</th>
									<th>시작가</th>
									<th>현재가·낙찰가</th>
									<th>입찰 수</th>
									<th>상태</th>
									<th>종료일</th>
									<th>등록일</th>
								</tr>
							</thead>

							<tbody>

								<%
									if (memberAuctionCount == 0) {
								%>

									<tr>
										<td
											colspan="9"
											class="admin-table-empty">
											등록한 경매가 없습니다.
										</td>
									</tr>

								<%
									} else {

										for (
											int i = 0;
											i < memberAuctionCount;
											i++
										) {

											long auctionNo =
												memberAuctionList.getLong(
													"A_NO",
													i
												);

											String auctionCategory =
												memberAuctionList.getText(
													"A_CATEGORY",
													i
												);

											String auctionTitle =
												memberAuctionList.getText(
													"A_TITLE",
													i
												);

											long auctionStartPrice =
												memberAuctionList.getLong(
													"A_START_PRICE",
													i
												);

											long auctionCurrentPrice =
												memberAuctionList.getLong(
													"A_CURRENT_PRICE",
													i
												);

											long auctionBidCount =
												memberAuctionList.getLong(
													"A_BID_COUNT",
													i
												);

											String auctionStatus =
												memberAuctionList.getText(
													"A_STATUS",
													i
												);

											String auctionEndDatetime =
												memberAuctionList.getText(
													"A_END_DATETIME",
													i
												);

											String auctionCreatedDatetime =
												memberAuctionList.getText(
													"CREATED_DATETIME",
													i
												);
								%>

									<tr>
										<td>
											<%= auctionNo %>
										</td>

										<td>
											<%= escapeHtml(auctionCategory) %>
										</td>

										<td class="member-auction-title-cell">

											<a
												href="<%= contextPath %>/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>"
												class="admin-table-link">

												<%= escapeHtml(auctionTitle) %>

											</a>

										</td>

										<td>
											<%= priceFormat.format(auctionStartPrice) %>원
										</td>

										<td>
											<%= priceFormat.format(auctionCurrentPrice) %>원
										</td>

										<td>
											<%= auctionBidCount %>
										</td>

										<td>
											<span class="status-badge status-<%= escapeHtml(auctionStatus == null ? "" : auctionStatus.toLowerCase()) %>">
												<%= escapeHtml(statusText(auctionStatus)) %>
											</span>
										</td>

										<td>
											<%= escapeHtml(auctionEndDatetime) %>
										</td>

										<td>
											<%= escapeHtml(auctionCreatedDatetime) %>
										</td>
									</tr>

								<%
										}
									}
								%>

							</tbody>

						</table>

					</div>

				</section>

			<%
				} else {
			%>

				<section class="admin-panel">

					<div class="admin-panel-header">

						<h2 class="admin-panel-title">
							입찰 내역
						</h2>

						<p class="admin-panel-count">
							총
							<strong><%= memberBidCount %></strong>
							건
						</p>

					</div>

					<div class="admin-table-wrap">

						<table class="admin-table member-bid-table">

							<thead>
								<tr>
									<th>입찰 번호</th>
									<th>경매 번호</th>
									<th>경매 제목</th>
									<th>입찰 금액</th>
									<th>현재가·낙찰가</th>
									<th>입찰 일시</th>
									<th>경매 상태</th>
									<th>낙찰 여부</th>
								</tr>
							</thead>

							<tbody>

								<%
									if (memberBidCount == 0) {
								%>

									<tr>
										<td
											colspan="8"
											class="admin-table-empty">
											입찰 내역이 없습니다.
										</td>
									</tr>

								<%
									} else {

										for (
											int i = 0;
											i < memberBidCount;
											i++
										) {

											long bidNo =
												memberBidList.getLong(
													"BID_NO",
													i
												);

											long auctionNo =
												memberBidList.getLong(
													"A_NO",
													i
												);

											String auctionTitle =
												memberBidList.getText(
													"A_TITLE",
													i
												);

											long bidPrice =
												memberBidList.getLong(
													"BID_PRICE",
													i
												);

											long currentPrice =
												memberBidList.getLong(
													"A_CURRENT_PRICE",
													i
												);

											long isWinner =
												memberBidList.getLong(
													"IS_WINNER",
													i
												);

											String auctionStatus =
												memberBidList.getText(
													"A_STATUS",
													i
												);

											String bidDatetime =
												memberBidList.getText(
													"BID_DATETIME",
													i
												);
								%>

									<tr>
										<td>
											<%= bidNo %>
										</td>

										<td>
											<%= auctionNo %>
										</td>

										<td class="member-bid-title-cell">

											<a
												href="<%= contextPath %>/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>"
												class="admin-table-link">

												<%= escapeHtml(auctionTitle) %>

											</a>

										</td>

										<td>
											<%= priceFormat.format(bidPrice) %>원
										</td>

										<td>
											<%= priceFormat.format(currentPrice) %>원
										</td>

										<td>
											<%= escapeHtml(bidDatetime) %>
										</td>

										<td>
											<span class="status-badge status-<%= escapeHtml(auctionStatus == null ? "" : auctionStatus.toLowerCase()) %>">
												<%= escapeHtml(statusText(auctionStatus)) %>
											</span>
										</td>

										<td>
											<%
												if (isWinner == 1) {
											%>

												<span class="winner-badge">
													낙찰
												</span>

											<%
												} else {
											%>

												<span class="normal-bid-text">
													-
												</span>

											<%
												}
											%>
										</td>
									</tr>

								<%
										}
									}
								%>

							</tbody>

						</table>

					</div>

				</section>

			<%
				}
			%>

		</main>

	</div>

</body>
</html>