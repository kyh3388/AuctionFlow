<%@ page contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>

<%
	boolean isAdminLogin = Boolean.TRUE.equals(session.getAttribute("LOGIN_ADMIN"));

	if (!isAdminLogin) {
%>

	<jsp:forward page="/view/error/error.jsp" />

<%
		return;
	}
	request.setAttribute("ADMIN_MENU", "AUCTION");
%>

<%!
	private String escapeHtml(String value) {

		if (value == null) {
			return "";
		}

		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}

	private String statusText(String status) {
		
		if ("ONGOING".equals(status)) {
			return "진행중";
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
		if ("CLOSED".equals(status)) {
			return "종료";
		}
		return status == null ? "" : status;
	}

	private String displayText(String value) {
		if (value == null || value.isBlank()) {
			return "-";
		}
		return value;
	}
%>

<%
	DataSet auctionList = (DataSet) request.getAttribute("AUCTION_LIST");

	if (auctionList == null) {
%>

	<jsp:forward page="/view/error/error.jsp" />

<%
		return;
	}
	int auctionCount = auctionList.getCount("A_NO");
	String auctionMessage = (String) request.getAttribute("ADMIN_AUCTION_MESSAGE");
	String contextPath = request.getContextPath();
	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>AuctionFlow 경매 관리</title>
	<link rel="stylesheet" href="<%= contextPath %>/static/css/admin/common/sidebar.css">
	<link rel="stylesheet" href="<%= contextPath %>/static/css/admin/auction/auctionList.css">
</head>

<body>

	<div class="admin-layout">

		<jsp:include page="/view/admin/common/sidebar.jsp" />

		<main class="admin-content">
			<div class="admin-page-header">
				<div>
					<h1 class="admin-page-title">경매 관리</h1>
					<p class="admin-page-description">등록된 경매를 확인하고 문제가 있는 경매를 취소합니다.</p>
				</div>
			</div>

			<%
				if (auctionMessage != null && !auctionMessage.isBlank()) {
			%>
				<div class="admin-action-message"><%= escapeHtml(auctionMessage) %></div>
			<%
				}
			%>

			<section class="admin-panel">
				<div class="admin-panel-header">
					<h2 class="admin-panel-title">경매 목록</h2>
					<p class="admin-panel-count">총<strong><%= auctionCount %></strong>건</p>
				</div>

				<div class="admin-table-wrap">
					<table class="admin-table auction-list-table">
						<thead>
							<tr>
								<th>경매 번호</th>
								<th>분류</th>
								<th>경매 제목</th>
								<th>판매자</th>
								<th>시작가</th>
								<th>현재가·낙찰가</th>
								<th>입찰 수</th>
								<th>상태</th>
								<th>예정 종료일</th>
								<th>실제 종료일</th>
								<th>관리자 사유</th>
								<th>관리</th>
							</tr>
						</thead>

						<tbody>
							<%
								if (auctionCount == 0) {
							%>
								<tr>
									<td colspan="12" class="admin-table-empty">등록된 경매가 없습니다.</td>
								</tr>
							<%
								} else {
									
									for (int i = 0; i < auctionCount; i++) {
										long auctionNo = auctionList.getLong("A_NO", i);
										String auctionCategory = auctionList.getText("A_CATEGORY", i);
										String auctionTitle = auctionList.getText("A_TITLE", i);
										long sellerMemberNo = auctionList.getLong("SELLER_M_NO", i);
										String sellerMemberId = auctionList.getText("SELLER_M_ID", i);
										String sellerMemberName = auctionList.getText("SELLER_M_NAME", i);
										long auctionStartPrice = auctionList.getLong("A_START_PRICE", i);
										long auctionCurrentPrice = auctionList.getLong("A_CURRENT_PRICE", i);
										long auctionBidCount = auctionList.getLong("A_BID_COUNT", i);
										String auctionStatus = auctionList.getText("A_STATUS", i);
										String auctionEndDatetime = auctionList.getText("A_END_DATETIME", i);
										String auctionClosedDatetime = auctionList.getText("A_CLOSED_DATETIME", i);
										String adminReason = auctionList.getText("A_ADMIN_REASON", i);
										boolean isOngoing = "ONGOING".equals(auctionStatus);
							%>
								<tr>
									<td><%= auctionNo %></td>
									<td><%= escapeHtml(auctionCategory) %></td>
									<td>
										<a href="<%= contextPath %>/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="admin-table-link">
											<%= escapeHtml(auctionTitle) %>
										</a>
									</td>

									<td>
										<a href="<%= contextPath %>/api/auctionFlow/admin/member/detail?M_NO=<%= sellerMemberNo %>" class="admin-table-link">
											<%= escapeHtml(sellerMemberId) %>(<%= escapeHtml(sellerMemberName) %>)
										</a>
									</td>
									<td><%= priceFormat.format(auctionStartPrice) %>원</td>
									<td><%= priceFormat.format(auctionCurrentPrice) %>원</td>
									<td><%= auctionBidCount %></td>
									<td><%= escapeHtml(statusText(auctionStatus)) %></td>
									<td><%= escapeHtml(displayText(auctionEndDatetime)) %></td>
									<td><%= escapeHtml(displayText(auctionClosedDatetime)) %></td>
									<td><%= escapeHtml(displayText(adminReason)) %></td>
									<td>
										<%
											if (isOngoing) {
										%>
											<button type="button" class="auction-action-button" data-action-type="CANCEL"
												    data-auction-no="<%= auctionNo %>" data-auction-title="<%= escapeHtml(auctionTitle) %>">
												경매 취소
											</button>
										<%
											} else if ("CANCELED".equals(auctionStatus)) {
										%>
											<span style="color: #D3D3D3">강제 취소</span>
										<%
											} else {
										%>
											<span style="color: #175cd3">정상 종료</span>
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
		</main>
	</div>

	<dialog id="auctionActionDialog">

		<form id="auctionActionForm" method="post" action="<%= contextPath %>/api/auctionFlow/admin/auction/cancel">

			<h2 id="auctionActionDialogTitle">경매 취소</h2>
			
			<p id="auctionActionTarget"></p>

			<input type="hidden" id="auctionActionNo" name="A_NO">

			<div>
				<label for="auctionAdminReason">취소 사유(최대 50자)</label>
				<textarea id="auctionAdminReason" name="A_ADMIN_REASON" rows="2" maxlength="50" required></textarea>
			</div>

			<div>
				<button type="button" id="auctionActionCloseButton">닫기</button>
				<button type="submit" id="auctionActionSubmitButton">경매 취소</button>
			</div>
		</form>
	</dialog>

	<script>
	(function () {

		const dialog = document.getElementById("auctionActionDialog");
		const form = document.getElementById("auctionActionForm");
		const actionTarget = document.getElementById("auctionActionTarget");
		const auctionNoInput = document.getElementById("auctionActionNo");
		const reasonInput = document.getElementById("auctionAdminReason");
		const closeButton = document.getElementById("auctionActionCloseButton");
		const cancelButtons = document.querySelectorAll(".auction-action-button");

		cancelButtons.forEach(function (button) {

			button.addEventListener("click", function () {

					const auctionNo = button.dataset.auctionNo;

					const auctionTitle = button.dataset.auctionTitle;

					auctionNoInput.value = auctionNo;

					reasonInput.value = "";

					actionTarget.textContent = "경매 번호 : " + auctionNo + " | 경매 상품 : " + auctionTitle;

					dialog.showModal();

					reasonInput.focus();
				}
			);
		});

		closeButton.addEventListener("click", function () {
				dialog.close();
			}
		);

		form.addEventListener("submit", function (event) {

				if (!reasonInput.value.trim()) {
					event.preventDefault();
					alert("경매 취소 사유를 입력해 주세요.");
					reasonInput.focus();
					return;
				}

				const isConfirmed = confirm("해당 경매를 취소하시겠습니까?\n" + "취소된 경매의 입찰은 모두 무효 처리됩니다.");

				if (!isConfirmed) {
					event.preventDefault();
				}
			}
		);
	})();
</script>

</body>
</html>