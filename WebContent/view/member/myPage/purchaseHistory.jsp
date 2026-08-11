<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.NumberFormat" %>

<%!
	private String escapeHtml(String value) {

		if (value == null) return "";
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}
%>

<%
	DataSet purchaseHistoryList = (DataSet) request.getAttribute("PURCHASE_HISTORY_LIST");

	String purchaseResult = (String) request.getAttribute("PURCHASE_RESULT");
	String purchaseMessage = (String) request.getAttribute("PURCHASE_MESSAGE");
	String purchaseMessageType = (String) request.getAttribute("PURCHASE_MESSAGE_TYPE");

	if (purchaseResult == null) {
		purchaseResult = "";
	}

	if (purchaseMessage == null) {
		purchaseMessage = "";
	}

	if (purchaseMessageType == null) {
		purchaseMessageType = "";
	}

	int purchaseHistoryCount = 0;
	int waitingPurchaseCount = 0;
	int completedPurchaseCount = 0;

	if (purchaseHistoryList != null) {
		purchaseHistoryCount = purchaseHistoryList.getCount("A_NO");

		for (int rowIndex = 0; rowIndex < purchaseHistoryCount; rowIndex++) {

			String purchasedDatetime = purchaseHistoryList.getText("A_PURCHASED_DATETIME", rowIndex);

			if (purchasedDatetime == null || purchasedDatetime.isBlank()) {
				waitingPurchaseCount++;
			} else {
				completedPurchaseCount++;
			}
		}
	}

	NumberFormat moneyFormat = NumberFormat.getIntegerInstance();
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>결제/구매 내역</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/sidebar.css">	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/purchaseHistory.css">
</head>

<body class="mypage-body purchase-history-page">

<jsp:include page="/view/common/header.jsp" />

<main class="mypage-main">

	<div class="mypage-layout">

		<jsp:include
			page="/view/member/myPage/common/sidebar.jsp" />

		<section class="mypage-content">

			<div class="mypage-content-header">

				<h1 class="mypage-page-title">결제/구매 내역</h1>

				<p class="mypage-page-description">낙찰받은 상품의 구매 상태와 최종 구매금액을 확인할 수 있습니다.</p>
			</div>

			<div id="purchaseMessage" class="purchase-message <%= escapeHtml(purchaseMessageType) %>" aria-live="polite">
				<%= escapeHtml(purchaseMessage) %>
			</div>

			<!-- 구매 대기 영역 -->
			<section class="purchase-section">

				<div class="purchase-section-header">

					<div>

						<h2 class="purchase-section-title">구매 대기</h2>

						<p class="purchase-section-description">낙찰받은 상품의 구매를 진행해 주세요.</p>
					</div>

					<span class="purchase-section-count"><%= waitingPurchaseCount %>건</span>
				</div>

				<div class="purchase-table-wrapper">

					<table class="purchase-table">

						<colgroup>
							<col class="purchase-col-product">
							<col class="purchase-col-price">
							<col class="purchase-col-fee">
							<col class="purchase-col-total">
							<col class="purchase-col-date">
							<col class="purchase-col-management">
						</colgroup>

						<thead>

							<tr>
								<th scope="col">상품</th>
								<th scope="col">낙찰가</th>
								<th scope="col">수수료</th>
								<th scope="col">구매금액</th>
								<th scope="col">낙찰일</th>
								<th scope="col">관리</th>
							</tr>

						</thead>

						<tbody>

						<%
							if (purchaseHistoryList == null || waitingPurchaseCount == 0) {
						%>
							<tr>
								<td colspan="6" class="purchase-empty-cell">구매 대기 중인 상품이 없습니다.</td>
							</tr>
						<%
							} else {

								for (int rowIndex = 0; rowIndex < purchaseHistoryCount; rowIndex++) {

									String purchasedDatetime = purchaseHistoryList.getText("A_PURCHASED_DATETIME", rowIndex);

									if (purchasedDatetime != null && !purchasedDatetime.isBlank()) {
										continue;
									}

									long auctionNo = purchaseHistoryList.getLong("A_NO", rowIndex);
									String auctionTitle = purchaseHistoryList.getText("A_TITLE", rowIndex);
									long winningPrice = purchaseHistoryList.getLong("A_CURRENT_PRICE", rowIndex);
									long purchaseFee = purchaseHistoryList.getLong("PURCHASE_FEE", rowIndex);
									long purchasePrice = purchaseHistoryList.getLong("PURCHASE_PRICE", rowIndex);
									String closedDatetime = purchaseHistoryList.getText("A_CLOSED_DATETIME", rowIndex);
						%>

							<tr>

								<td class="purchase-product-cell">

									<button
										type="button"
										class="purchase-product-link"
										onclick="window.open(
											'${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>',
											'auctionDetail',
											'width=1100,height=800,scrollbars=yes,resizable=yes'
										);">

										<%= escapeHtml(auctionTitle) %>
									</button>
								</td>

								<td class="purchase-price-cell">
									<%= moneyFormat.format(winningPrice) %>원
								</td>

								<td class="purchase-fee-cell">
									<%= moneyFormat.format(purchaseFee) %>원
								</td>

								<td class="purchase-total-cell">
									<%= moneyFormat.format(purchasePrice) %>원
								</td>

								<td class="purchase-date-cell">
									<%= escapeHtml(closedDatetime) %>
								</td>

								<td class="purchase-management-cell">

									<form
										action="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/purchaseComplete"
										method="post"
										class="purchase-complete-form">

										<input
											type="hidden"
											name="A_NO"
											value="<%= auctionNo %>">

										<button
											type="submit"
											class="purchase-button"
											data-purchase-title="<%= escapeHtml(auctionTitle) %>"
											data-purchase-price="<%= purchasePrice %>">

											구매하기

										</button>
									</form>
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


			<!-- 구매 완료 영역 -->
			<section class="purchase-section completed">

				<div class="purchase-section-header">

					<div>

						<h2 class="purchase-section-title">구매 완료</h2>

						<p class="purchase-section-description">구매가 완료된 낙찰 상품입니다.</p>
					</div>
					<span class="purchase-section-count"><%= completedPurchaseCount %>건</span>
				</div>

				<div class="purchase-table-wrapper">

					<table class="purchase-table">

						<colgroup>
							<col class="purchase-col-product">
							<col class="purchase-col-price">
							<col class="purchase-col-fee">
							<col class="purchase-col-total">
							<col class="purchase-col-date">
							<col class="purchase-col-management">
						</colgroup>

						<thead>

							<tr>
								<th scope="col">상품</th>
								<th scope="col">낙찰가</th>
								<th scope="col">수수료</th>
								<th scope="col">구매금액</th>
								<th scope="col">구매일</th>
								<th scope="col">상태</th>
							</tr>
						</thead>

						<tbody>

						<%
							if (purchaseHistoryList == null || completedPurchaseCount == 0) {
						%>

							<tr>
								<td colspan="6" class="purchase-empty-cell">구매 완료한 상품이 없습니다.</td>
							</tr>

						<%
							} else {

								for (int rowIndex = 0; rowIndex < purchaseHistoryCount; rowIndex++) {

									String purchasedDatetime = purchaseHistoryList.getText("A_PURCHASED_DATETIME", rowIndex);

									if (
										purchasedDatetime == null
										|| purchasedDatetime.isBlank()
									) {

										continue;
									}

									long auctionNo =
										purchaseHistoryList.getLong(
											"A_NO",
											rowIndex
										);

									String auctionTitle = purchaseHistoryList.getText("A_TITLE", rowIndex);

									long winningPrice = purchaseHistoryList.getLong("A_CURRENT_PRICE", rowIndex);
									long purchaseFee = purchaseHistoryList.getLong("PURCHASE_FEE", rowIndex);
									long purchasePrice = purchaseHistoryList.getLong("PURCHASE_PRICE", rowIndex);
						%>

							<tr>

								<td class="purchase-product-cell">

									<button type="button" class="purchase-product-link" onclick="window.open('${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>', 'auctionDetail', 'width=1100,height=800,scrollbars=yes,resizable=yes');">
										<%= escapeHtml(auctionTitle) %>
									</button>
								</td>
								<td class="purchase-price-cell"><%= moneyFormat.format(winningPrice) %>원</td>
								<td class="purchase-fee-cell"><%= moneyFormat.format(purchaseFee) %>원</td>
								<td class="purchase-total-cell"><%= moneyFormat.format(purchasePrice) %>원</td>
								<td class="purchase-date-cell"><%= escapeHtml(purchasedDatetime) %></td>
								<td class="purchase-management-cell">

									<span class="purchase-completed-badge">
										구매 완료
									</span>
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
		</section>
	</div>
</main>

<jsp:include page="/view/common/footer.jsp" />

<script>
	"use strict";

	document.addEventListener("DOMContentLoaded", function () {

		const purchaseResult = "<%= escapeHtml(purchaseResult) %>";

		//구매 완료 후 팝업을 띄우고 RESULT 파라미터가 없는 구매 내역 화면으로 교체한다.
		if (purchaseResult === "SUCCESS") {

			alert("구매가 완료되었습니다.");

			window.history.replaceState(null, "", "${pageContext.request.contextPath}/api/auctionFlow/member/myPage/purchaseHistory");
		}

		const purchaseCompleteForms = document.querySelectorAll(".purchase-complete-form");

		purchaseCompleteForms.forEach(function (purchaseCompleteForm) {

				purchaseCompleteForm.addEventListener("submit", function (event) {

						const purchaseButton = purchaseCompleteForm.querySelector(".purchase-button");
						const purchaseTitle = purchaseButton.dataset.purchaseTitle;
						const purchasePrice = Number(purchaseButton.dataset.purchasePrice).toLocaleString("ko-KR");
						const purchaseConfirmed = window.confirm("상품명: " + purchaseTitle + "\n최종 구매금액: " + purchasePrice + "원\n\n해당 상품을 구매하시겠습니까?");

						if (!purchaseConfirmed) {
							event.preventDefault();
							return;
						}

						purchaseButton.disabled = true;
						purchaseButton.textContent = "처리 중...";
					}
				);
			}
		);
	});
</script>

</body>
</html>