<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>

<%!
	private String escapeHtml(String value) {
		if (value == null) {
			return "";
		}
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}

	private String escapeHtmlWithBreaks(String value) {
		return escapeHtml(value).replace("\r\n", "<br>").replace("\n", "<br>").replace("\r", "<br>");
	}

	private String escapeJavaScript(String value) {
		if (value == null) {
			return "";
		}
		return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'").replace("\r", "\\r").replace("\n", "\\n").replace("</", "<\\/");
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
			return "관리자 취소";
		}
		return status == null ? "" : status;
	}
%>

<%
	DataSet auctionDetail = (DataSet) request.getAttribute("AUCTION_DETAIL");
	DataSet auctionImageList = (DataSet) request.getAttribute("AUCTION_IMAGE_LIST");
	DataSet auctionBidList = (DataSet) request.getAttribute("AUCTION_BID_LIST");

	int bidListCount = 0;

	if (auctionBidList != null) {
		bidListCount = auctionBidList.getCount("BID_NO");
	}

	int detailCount = 0;

	if (auctionDetail != null) {
		detailCount = auctionDetail.getCount("A_NO");
	}

	boolean hasDetail = detailCount > 0;

	long auctionNo = 0L;
	String auctionCategory = "";
	String auctionTitle = "";
	String auctionContent = "";
	long auctionStartPrice = 0L;
	long auctionCurrentPrice = 0L;
	long auctionBidCount = 0L;

	String auctionStatus = "";
	String auctionAdminReason = "";
	String auctionEndDatetime = "";
	String auctionClosedDatetime = "";

	if (hasDetail) {
		auctionNo = auctionDetail.getLong("A_NO", 0);
		auctionCategory = auctionDetail.getText("A_CATEGORY", 0);
		auctionTitle = auctionDetail.getText("A_TITLE", 0);
		auctionContent = auctionDetail.getText("A_CONTENT", 0);
		auctionStartPrice = auctionDetail.getLong("A_START_PRICE", 0);
		auctionCurrentPrice = auctionDetail.getLong("A_CURRENT_PRICE", 0);
		auctionBidCount = auctionDetail.getLong("A_BID_COUNT", 0);
		auctionStatus = auctionDetail.getText("A_STATUS", 0);
		auctionAdminReason = auctionDetail.getText("A_ADMIN_REASON", 0);
		auctionEndDatetime = auctionDetail.getText("A_END_DATETIME", 0);
		auctionClosedDatetime = auctionDetail.getText("A_CLOSED_DATETIME", 0);
	}

	//호가 단위: 시작가의 10%, 최소 50,000원.

	long bidUnit = Math.max(auctionStartPrice / 10L, 50000L);

	//최초 입찰은 시작가, 이후 입찰은 현재가 + 호가 단위.
	boolean isFirstBid = auctionBidCount == 0L;

	long nextBidPrice = isFirstBid ? auctionStartPrice : auctionCurrentPrice + bidUnit;

	int imageCount = 0;

	if (auctionImageList != null) {
		imageCount = auctionImageList.getCount("IMG_STORED_NAME");
	}

	String mainImageStoredName = "";

	if (auctionImageList != null) {

		for (int index = 0; index < imageCount; index++) {

			String imageStoredName = auctionImageList.getText("IMG_STORED_NAME", index);
			String imageType = auctionImageList.getText("IMG_TYPE", index);

			if (imageStoredName == null || imageStoredName.isBlank()) {
				continue;
			}

			if (mainImageStoredName.isBlank() || "MAIN".equals(imageType)) {
				mainImageStoredName = imageStoredName;
			}

			if ("MAIN".equals(imageType)) {
				break;
			}
		}
	}

	Object loginMemberNoObject = session.getAttribute("LOGIN_MEMBER_NO");

	boolean isLogin = loginMemberNoObject != null;
	boolean isOngoing = "ONGOING".equals(auctionStatus);
	boolean isSold = "SOLD".equals(auctionStatus);
	boolean isUnsold = "UNSOLD".equals(auctionStatus);
	boolean isCanceled = "CANCELED".equals(auctionStatus);

	String detailStatusClass = "";

	if (isOngoing) {
		detailStatusClass = "ongoing";

	} else if (isSold) {
		detailStatusClass = "sold";

	} else if (isUnsold) {
		detailStatusClass = "unsold";

	} else if (isCanceled) {
		detailStatusClass = "canceled";
	}

	String detailDatetimeLabel = "마감일";
	String detailDatetime = auctionEndDatetime;

	if (isSold || isUnsold) {
		detailDatetimeLabel = "종료일";
		detailDatetime = auctionClosedDatetime;
	} else if (isCanceled) {
		detailDatetimeLabel = "취소일";
		detailDatetime = auctionClosedDatetime;
	}

	//과거 데이터에 A_CLOSED_DATETIME이 없으면 예정 종료 일시를 대신 표시한다.
	if (detailDatetime == null || detailDatetime.isBlank()) {
		detailDatetime = auctionEndDatetime;
	}

	DecimalFormat priceFormat = new DecimalFormat("#,###");

	String bidMessage = (String) request.getAttribute("AUCTION_BID_MESSAGE");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title><%= hasDetail ? escapeHtml(auctionTitle) : "경매 상세" %></title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/auction/detail.css">
</head>

<body class="detail-page">

<jsp:include page="/view/common/header.jsp" />

<main class="main">

	<div class="detail-inner">

		<%
			if (!hasDetail) {
		%>
			<div class="detail-empty">
				<h1 class="detail-empty-title">경매 상품을 찾을 수 없습니다.</h1>
				<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/ongoing" class="detail-empty-link">진행 경매로 돌아가기</a>
			</div>
		<%
			} else {
		%>

			<section class="detail-top">

				<div class="detail-thumbnail-column">

					<%
						if (auctionImageList != null) {

							for (int index = 0; index < imageCount; index++) {
								String imageStoredName = auctionImageList.getText("IMG_STORED_NAME", index);

								if (imageStoredName == null || imageStoredName.isBlank()) {
									continue;
								}
					%>
								<button type="button" class="detail-thumbnail-button" data-image-src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>">
									<img src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>" alt="<%= escapeHtml(auctionTitle) %> 이미지" class="detail-thumbnail-image">
								</button>
					<%
							}
						}
					%>
				</div>

				<div class="detail-main-image-area">
					<div class="detail-main-image-box">
						<%
							if (mainImageStoredName != null && !mainImageStoredName.isBlank()) {
						%>
							<img
								src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(mainImageStoredName) %>"
								alt="<%= escapeHtml(auctionTitle) %>"
								class="detail-main-image"
								id="detailMainImage">
						<%
							} else {
						%>
							<div class="detail-image-placeholder">
								NO IMAGE
							</div>
						<%
							}
						%>
					</div>
				</div>

				<div class="detail-information">

					<div class="detail-lot-row">
						<span class="detail-status <%= detailStatusClass %>" id="detailStatus"><%= escapeHtml(statusText(auctionStatus)) %></span>
					</div>

					<p class="detail-category"><%= escapeHtml(auctionCategory) %></p>

					<h1 class="detail-title"><%= escapeHtml(auctionTitle) %></h1>

					<div class="detail-price-section">

						<div class="detail-price-row">
							<span class="detail-price-label">시작가</span>
							<strong class="detail-price-value"><%= priceFormat.format(auctionStartPrice) %>원</strong>
						</div>

						<div class="detail-price-row current">

							<%
								if (isOngoing) {
							%>
								<span class="detail-price-label" id="detailPriceStatusLabel">현재가</span>
								<strong class="detail-price-value current" id="detailCurrentPrice"><%= priceFormat.format(auctionCurrentPrice) %>원</strong>
							<%
								} else {
							%>
								<span class="detail-price-label" id="detailPriceStatusLabel">경매 결과</span>

								<strong class="detail-price-value result <%= detailStatusClass %>" id="detailCurrentPrice">
									<%
										if (isSold) {
									%>
										낙찰 : <%= priceFormat.format(auctionCurrentPrice) %>원
									<%
										} else if (isUnsold) {
									%>
										입찰자 없음
									<%
										} else if (isCanceled) {
									%>
										관리자 취소
									<%
										}
									%>
								</strong>
							<%
								}
							%>
						</div>

						<div class="detail-price-row">
							<span class="detail-price-label">입찰</span>
							<strong class="detail-price-value" id="detailBidCount"><%= auctionBidCount %>건</strong>
						</div>

						<div class="detail-price-row">
							<span class="detail-price-label" id="detailDatetimeLabel"><%= detailDatetimeLabel %></span>
							<strong class="detail-price-value end-date" id="detailDatetime"><%= escapeHtml(detailDatetime) %></strong>
						</div>
					</div>

					<button type="button" class="detail-bid-button" id="bidOpenButton" <%= isOngoing ? "" : "disabled" %>>
						<%
							if (isOngoing) {
						%>
							입찰하기

						<%
							} else if (isSold) {
						%>
							낙찰된 경매

						<%
							} else if (isUnsold) {
						%>
							미낙찰 경매

						<%
							} else if (isCanceled) {
						%>
							취소된 경매
						<%
							}
						%>
					</button>

					<p class="detail-bid-guide" id="detailBidGuide">
						<%
							if (isSold) {
						%>
							낙찰이 완료된 경매입니다.
						<%
							} else if (isUnsold) {
						%>
							입찰자가 없어 미낙찰된 경매입니다.
						<%
							} else if (isCanceled) {
						%>
							관리자에 의해 취소된 경매입니다.
						<%
							} else if (isFirstBid) {
						%>
							최초 입찰가는 시작가입니다.
						<%
							} else {
						%>
							입찰 단위는 <%= priceFormat.format(bidUnit) %>원입니다.
						<%
							}
						%>
					</p>
				</div>
			</section>

			<div id="detailCancelContainer">

				<%
					if (isCanceled) {
				%>
					<section class="detail-cancel-section" id="detailCancelSection">

						<h2 class="detail-cancel-title">관리자 취소 안내</h2>

						<p class="detail-cancel-message">이 경매는 관리자에 의해 취소되었습니다. 기존 입찰은 모두 무효 처리되었습니다.</p>

						<div class="detail-cancel-row">
							<span class="detail-cancel-label">취소 사유 : </span>
							<span id="detailCancelReason">
								<%
									if (auctionAdminReason == null || auctionAdminReason.isBlank()) {
								%>
									관리자에게 문의 바랍니다.
								<%
									} else {
								%>
									<%= escapeHtmlWithBreaks(auctionAdminReason) %>
								<%
									}
								%>
							</span>
						</div>

						<div class="detail-cancel-row">
							<span class="detail-cancel-label">취소 일시 :</span>
							<span id="detailCancelDatetime">
								<%
									if (auctionClosedDatetime == null || auctionClosedDatetime.isBlank()) {
								%>
									관리자에게 문의 바랍니다.
								<%
									} else {
								%>
									<%= escapeHtml(auctionClosedDatetime) %>
								<%
									}
								%>
							</span>
						</div>
					</section>
				<%
					}
				%>
			</div>

			<section class="detail-description-section">
				<h2 class="detail-description-title">작품 정보</h2>
				<div class="detail-description-content">
					<%= escapeHtmlWithBreaks(auctionContent) %>
				</div>
			</section>
		<%
			}
		%>
	</div>
</main>

<%
	if (hasDetail && isOngoing) {
%>
	<dialog class="bid-dialog" id="bidDialog" data-end-datetime="<%= escapeHtml(auctionEndDatetime) %>">

		<div class="bid-dialog-inner">

			<div class="bid-dialog-header">
				<h2 class="bid-dialog-lot-title">LOT <%= auctionNo %></h2>
				<button type="button" class="bid-dialog-close" id="bidCloseButton" aria-label="입찰 팝업 닫기">×</button>
			</div>

			<div class="bid-dialog-body">

				<div class="bid-dialog-left">

					<div class="bid-dialog-image-wrap">
						<%
							if (mainImageStoredName != null && !mainImageStoredName.isBlank()) {
						%>
							<img src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(mainImageStoredName) %>" alt="<%= escapeHtml(auctionTitle) %>" class="bid-dialog-product-image">
						<%
							} else {
						%>
							<div class="bid-dialog-image-placeholder">
								NO IMAGE
							</div>
						<%
							}
						%>
					</div>

					<section class="bid-flow-panel" id="bidFlowPanel" aria-label="동시 입찰 처리 시각화">

						<div class="bid-flow-panel-header">
							<strong class="bid-flow-panel-title">동시 입찰 처리</strong>
							
							<span class="bid-flow-panel-divider">|</span>
						
							<div class="bid-flow-counter-grid" aria-live="polite">
								<div class="bid-flow-counter is-success">
									<span class="bid-flow-counter-label">성공</span>
									<strong class="bid-flow-counter-value" id="bidFlowSuccessCount">0</strong>
								</div>
								<div class="bid-flow-counter is-rejected">
									<span class="bid-flow-counter-label">거절</span>
									<strong class="bid-flow-counter-value" id="bidFlowRejectedCount">0</strong>
								</div>
								<div class="bid-flow-counter is-pending">
									<span class="bid-flow-counter-label">대기</span>
									<strong class="bid-flow-counter-value" id="bidFlowPendingCount">0</strong>
								</div>
							</div>
						</div>

						<div class="bid-flow-stage" id="bidFlowStage">
							<svg class="bid-flow-track" viewBox="0 0 300 132" preserveAspectRatio="none" aria-hidden="true">
								<path class="bid-flow-track-line" d="M8 12 H62 C108 12 128 40 174 57 H202"></path>
								<path class="bid-flow-track-line" d="M8 120 H62 C108 120 128 92 174 75 H202"></path>

								<line class="bid-flow-lock-gate" x1="207" y1="31" x2="207" y2="101"></line>
								
								<line class="bid-flow-track-line" x1="213" y1="57" x2="292" y2="57"></line>
								<line class="bid-flow-track-line" x1="213" y1="75" x2="292" y2="75"></line>
							</svg>

							<div class="bid-flow-token-layer" id="bidFlowTokenLayer" aria-hidden="true">
							</div>
						</div>
						
						<div class="bid-demo-count-control">
							<label for="bidDemoRequestCountInput" class="bid-demo-count-label">시연 요청 수</label>
							<input type="number" id="bidDemoRequestCountInput" class="bid-demo-count-input" value="100" min="1" step="1" inputmode="numeric" autocomplete="off">
						</div>
					</section>
				</div>
				
				<div class="bid-dialog-right">

					<div class="bid-dialog-top-info">
						<div class="bid-dialog-time-box">
							<span class="bid-dialog-top-label">남은 시간</span>
							<strong id="bidRemainingTime">계산 중</strong>
						</div>

						<div class="bid-dialog-unit-box">
							<span class="bid-dialog-top-label">호가 단위 :</span>
							<strong>KRW <%= priceFormat.format(bidUnit) %></strong>
						</div>
					</div>

					<div class="bid-history-summary">
						<span class="bid-history-summary-label">현재가</span>
						<strong class="bid-history-summary-price" id="bidHistorySummaryPrice">KRW <%= priceFormat.format(auctionCurrentPrice) %></strong>
						<span class="bid-history-summary-count" id="bidHistorySummaryCount">(입찰 <%= auctionBidCount %>건)</span>
					</div>

					<div class="bid-history-list" id="bidHistoryList">
						<%
							if (bidListCount == 0) {
						%>
							<div class="bid-history-empty">
								아직 입찰 내역이 없습니다.
							</div>
						<%
							} else {

								for (int index = 0; index < bidListCount; index++) {
									long historyBidNo = auctionBidList.getLong("BID_NO", index);
									String bidderMemberId = auctionBidList.getText("M_ID", index);
									long historyBidPrice = auctionBidList.getLong("BID_PRICE", index);
									String historyBidDatetime = auctionBidList.getText("BID_DATETIME", index);
						%>
									<div class="bid-history-item" data-bid-no="<%= historyBidNo %>">
										<span class="bid-history-member-id"><%= escapeHtml(bidderMemberId) %></span>
										<strong class="bid-history-price"><%= priceFormat.format(historyBidPrice) %></strong>
										<span class="bid-history-datetime"><%= escapeHtml(historyBidDatetime) %></span>
									</div>
						<%
								}
							}
						%>
					</div>

					<div class="bid-dialog-action-type">
						<button type="button" class="bid-type-button active">1회 입찰</button>
					</div>

					<div class="bid-dialog-notice">
						<p>* 1회 입찰은 현재가에서 호가 단위만큼 증가한 금액으로 입찰합니다.</p>
						<p>* 동시 입찰이 발생한 경우 DB 락을 획득한 순서대로 처리됩니다.</p>
						<p class="bid-dialog-notice-warning">* 아래 입찰하기 버튼을 누르면 입찰이 접수되며 취소할 수 없습니다.</p>
					</div>

					<form action="${pageContext.request.contextPath}/api/auctionFlow/auction/bid" method="post" class="bid-form" id="bidForm">
						<input type="hidden" name="A_NO" value="<%= auctionNo %>">
						<input type="hidden" name="BID_PRICE" id="bidPriceInput" value="<%= nextBidPrice %>">
						<input type="hidden" name="BID_REQUEST_ID" id="bidRequestId" value="" autocomplete="off">
						
						<button type="submit" class="bid-submit-button" id="bidSubmitButton">KRW <%= priceFormat.format(nextBidPrice) %> 입찰하기</button>
					</form>

					<div class="bid-demo-action">		
						<button type="button" class="bid-demo-button" id="bidDemoBatchButton">동시 요청 100건 시연</button>
					</div>
				</div>
			</div>
		</div>
	</dialog>

<%
	}
%>

<jsp:include page="/view/common/footer.jsp" />

<script type="text/javascript">
(function () {

	"use strict";

	function initializeAuctionDetail() {

		const thumbnailButtons = document.querySelectorAll(".detail-thumbnail-button");
		const mainImage = document.getElementById("detailMainImage");
		const bidOpenButton = document.getElementById("bidOpenButton");
		const bidDialog = document.getElementById("bidDialog");
		const bidCloseButton = document.getElementById("bidCloseButton");
		const bidForm = document.getElementById("bidForm");
		const bidSubmitButton = document.getElementById("bidSubmitButton");
		const bidPriceInput = document.getElementById("bidPriceInput");
		const bidRequestIdInput = document.getElementById("bidRequestId");
		const bidRemainingTime = document.getElementById("bidRemainingTime");

		const isLogin = <%= isLogin ? "true" : "false" %>;

		const loginUrl = "${pageContext.request.contextPath}" + "/api/auctionFlow/member/loginForm";

		let isSubmitting = false;
		let remainingTimeIntervalId = null;

		/* =========================
		   썸네일
		   ========================= */
		thumbnailButtons.forEach(function (thumbnailButton) {

				thumbnailButton.addEventListener("click", function () {

						if (!mainImage) {
							return;
						}

						const imageSrc = thumbnailButton.dataset.imageSrc;

						if (!imageSrc) {
							return;
						}

						mainImage.src = imageSrc;

						thumbnailButtons.forEach(function (button) {
								button.classList.remove("active");
							});

						thumbnailButton.classList.add("active");
					});
			});

		/* =========================
		   남은 시간
		   ========================= */
		function parseDatabaseDatetime(datetimeText) {
			if (!datetimeText) {
				return null;
			}
			const normalizedDatetime = datetimeText.trim();
			const matchedDatetime = normalizedDatetime.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$/);
			if (!matchedDatetime) {
				return null;
			}
			return new Date(Number(matchedDatetime[1]), Number(matchedDatetime[2]) - 1, Number(matchedDatetime[3]), Number(matchedDatetime[4]), Number(matchedDatetime[5]), Number(matchedDatetime[6]));
		}

		function formatRemainingTime(remainingMilliseconds) {
			const totalSeconds = Math.max(0, Math.floor(remainingMilliseconds / 1000));
			const days = Math.floor(totalSeconds / 86400);
			const hours = Math.floor((totalSeconds % 86400) / 3600);
			const minutes = Math.floor((totalSeconds % 3600) / 60);
			const seconds = totalSeconds % 60;

			const timeText = [
				String(hours).padStart(2, "0"),
				String(minutes).padStart(2, "0"),
				String(seconds).padStart(2, "0")
			].join(":");

			return days > 0 ? days + "일 " + timeText : timeText;
		}

		function stopRemainingTimeTimer() {
			if (remainingTimeIntervalId !== null) {
				window.clearInterval(remainingTimeIntervalId);
				remainingTimeIntervalId = null;
			}
		}

		function updateRemainingTime() {
			if (!bidDialog || !bidRemainingTime) {
				return;
			}

			const endDatetime = parseDatabaseDatetime(bidDialog.dataset.endDatetime);
			if (!endDatetime) {
				bidRemainingTime.textContent = "종료 시간 확인 불가";
				stopRemainingTimeTimer();
				return;
			}

			const remainingMilliseconds = endDatetime.getTime() - Date.now();
			if (remainingMilliseconds <= 0) {
				bidRemainingTime.textContent = "종료";
				stopRemainingTimeTimer();
				
				window.setTimeout(function () {
						window.location.reload();
					}, 300);
				return;
			}

			bidRemainingTime.textContent = formatRemainingTime(remainingMilliseconds);
		}

		function startRemainingTimeTimer() {
			stopRemainingTimeTimer();
			updateRemainingTime();
			remainingTimeIntervalId = window.setInterval(updateRemainingTime, 1000);
		}

		/* =========================
		   입찰 요청 식별번호
		   ========================= */

		function createBidRequestId() {

			if (window.crypto && typeof window.crypto.randomUUID === "function") {
				return window.crypto.randomUUID();
			}

			const randomValues = new Uint8Array(16);

			if (window.crypto && typeof window.crypto.getRandomValues === "function") {
				window.crypto.getRandomValues(randomValues);
			} else {
				for (let index = 0; index < randomValues.length; index++) {
					randomValues[index] = Math.floor(Math.random() * 256);
				}
			}

			randomValues[6] = (randomValues[6] & 0x0f) | 0x40;
			randomValues[8] = (randomValues[8] & 0x3f) | 0x80;

			const hexValues = Array.from(randomValues, function (value) {
				return value.toString(16).padStart(2, "0");
			});

			return [
				hexValues.slice(0, 4).join(""),
				hexValues.slice(4, 6).join(""),
				hexValues.slice(6, 8).join(""),
				hexValues.slice(8, 10).join(""),
				hexValues.slice(10, 16).join("")
			].join("-");
		}

		function ensureBidRequestId() {
			if (!bidRequestIdInput) {
				return false;
			}
			if (!/^[0-9a-fA-F-]{36}$/.test(bidRequestIdInput.value)) {
				bidRequestIdInput.value = createBidRequestId();
			}
			return /^[0-9a-fA-F-]{36}$/.test(bidRequestIdInput.value);
		}

		window.createAuctionBidRequestId = createBidRequestId;

		/* =========================
		   입찰 팝업
		   ========================= */
		if (bidOpenButton) {

			bidOpenButton.addEventListener("click", function () {

				if (!isLogin) {
					window.alert("로그인 후 입찰할 수 있습니다.");
					window.location.href = loginUrl;
					return;
				}

				if (!bidDialog) {
					return;
				}

				isSubmitting = false;

				if (bidSubmitButton) {
					bidSubmitButton.disabled = false;
				}

				if (bidRequestIdInput) {
					bidRequestIdInput.value = createBidRequestId();
				}

				if (typeof bidDialog.showModal === "function") {
					bidDialog.showModal();

				} else {
					bidDialog.setAttribute("open", "open");
				}

				startRemainingTimeTimer();

				if (typeof window.refreshRealtimeAuction === "function") {
					window.refreshRealtimeAuction();
				}
			});
		}

		function closeBidDialog() {
			if (!bidDialog) {
				return;
			}
			stopRemainingTimeTimer();
			
			if (
				typeof bidDialog.close === "function" && bidDialog.open) {
				bidDialog.close();
				return;
			}
			bidDialog.removeAttribute("open");
		}

		if (bidCloseButton) {
			bidCloseButton.addEventListener("click", closeBidDialog);
		}

		if (bidDialog) {
			bidDialog.addEventListener("cancel", function (event) {
				event.preventDefault();
				closeBidDialog();
		});

		bidDialog.addEventListener("click", function (event) {
				if (event.target !== bidDialog) {
					return;
				}
				closeBidDialog();
			});
		}

		/* =========================
		   실제 입찰 제출
		   ========================= */
		if (bidForm && bidSubmitButton) {

			bidForm.addEventListener("submit", function (event) {

				if (isSubmitting) {
					event.preventDefault();
					return;
				}

				if (!ensureBidRequestId()) {
					event.preventDefault();
					window.alert("입찰 요청 정보를 생성하지 못했습니다. " + "입찰 팝업을 다시 열어 주세요.");
					return;
				}

				if (!bidPriceInput) {
					event.preventDefault();
					window.alert("최신 입찰 금액을 확인하지 못했습니다.");
					return;
				}

				const currentBidPrice = Number(bidPriceInput.value);
				if (!Number.isSafeInteger(currentBidPrice) || currentBidPrice <= 0) {
					event.preventDefault();
					window.alert("입찰 금액이 올바르지 않습니다.");
					return;
				}

				const confirmed = window.confirm(currentBidPrice.toLocaleString("ko-KR") + "원으로 입찰하시겠습니까?");
				if (!confirmed) {
					event.preventDefault();
					return;
				}

				isSubmitting = true;
				bidSubmitButton.disabled = true;

				bidSubmitButton.textContent = "입찰 처리 중...";
			});
		}
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", initializeAuctionDetail,
			{
				once: true
			});
	} else {
		initializeAuctionDetail();
	}
})();
</script>

<%
	if (bidMessage != null && !bidMessage.isBlank()) {
%>

	<script type="text/javascript">window.alert("<%= escapeJavaScript(bidMessage) %>");</script>
	
<%
	}
%>

<%
	if (hasDetail && isOngoing) {
%>

<script type="text/javascript">
document.addEventListener("DOMContentLoaded", function () {
	
    "use strict";
    
    /*
     * =========================
     * 기본 설정
     * =========================
     */
    const auctionNo = "<%= auctionNo %>";
    const contextPath = "${pageContext.request.contextPath}";
    const webSocketProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
    const webSocketUrl = webSocketProtocol + "//" + window.location.host + contextPath + "/ws/auction/" + encodeURIComponent(auctionNo);
    const realtimeUrl = contextPath + "/api/auctionFlow/auction/realtime?A_NO=" + encodeURIComponent(auctionNo);
    const bidDemoSingleUrl = contextPath + "/api/auctionFlow/auction/bidDemoSingle";
    const bidDemoStartUrl = contextPath + "/api/auctionFlow/auction/bidDemoStart";
    const bidDemoFinishUrl = contextPath + "/api/auctionFlow/auction/bidDemoFinish";
    const priceFormatter = new Intl.NumberFormat("ko-KR");
    const BID_DEMO_DEFAULT_REQUEST_COUNT = 100;
    const BID_DEMO_COOLDOWN_MS = 5000;
    const BID_DEMO_RUNNING_TIMEOUT_MS = 10 * 60 * 1000;
    const BID_FLOW_REJECT_HOLD_MS = 1500;
    const BID_FLOW_STALE_TOKEN_MS = 8000;
    const BID_FLOW_FORCE_CLEANUP_MS = 1500;
    const AUCTION_WS_RECONNECT_DELAY_MS = 2500;
    
    //WebSocket 이벤트가 누락되거나 HTTP 요청과 겹쳐도 화면이 반드시 DB 최신값을 따라가도록 짧은 주기로 보정한다.
    const REALTIME_SYNC_INTERVAL_MS = 500;
    const AUCTION_START_PRICE = <%= auctionStartPrice %>;
    const AUCTION_BID_UNIT = <%= bidUnit %>;
    let appliedBidCount = <%= auctionBidCount %>;
    let appliedCurrentPrice = <%= auctionCurrentPrice %>;
    let latestRealtimeSnapshot = null;
    let lastQueuedRealtimeSignature = null;
    let realtimeAnimationRunning = false;
    let realtimeRefreshRunning = false;
    let realtimeRefreshRequested = false;
    let realtimePollTimerId = null;
    
    /*
     * =========================
     * 화면 요소
     * =========================
     */
    const detailCurrentPrice = document.getElementById("detailCurrentPrice");
    const detailBidCount = document.getElementById("detailBidCount");
    const bidDialog = document.getElementById("bidDialog");
    const bidHistorySummaryPrice = document.getElementById("bidHistorySummaryPrice");
    const bidHistorySummaryCount = document.getElementById("bidHistorySummaryCount");
    const bidHistoryList = document.getElementById("bidHistoryList");
    const bidPriceInput = document.getElementById("bidPriceInput");
    const bidSubmitButton = document.getElementById("bidSubmitButton");
    const bidDemoBatchButton = document.getElementById("bidDemoBatchButton");
    const bidDemoRequestCountInput = document.getElementById("bidDemoRequestCountInput");
    const bidFlowPanel = document.getElementById("bidFlowPanel");
    const bidFlowStage = document.getElementById("bidFlowStage");
    const bidFlowTokenLayer = document.getElementById("bidFlowTokenLayer");
    const bidFlowPendingCount = document.getElementById("bidFlowPendingCount");
    const bidFlowSuccessCount = document.getElementById("bidFlowSuccessCount");
    const bidFlowRejectedCount = document.getElementById("bidFlowRejectedCount");
    
    /*
     * =========================
     * 숫자 공통 처리
     * =========================
     */
    function readDisplayedNumber(element) {
        if (!element) {
            return 0;
        }
        const numberText = element.textContent.replace(/[^0-9]/g, "");
        const parsedNumber = Number(numberText);
        return Number.isFinite(parsedNumber) ? parsedNumber : 0;
    }
    function setFormattedPrice(element, price, prefix, suffix) {
        if (!element || !Number.isFinite(price)) {
            return;
        }
        element.textContent = prefix + priceFormatter.format(price) + suffix;
    }
    
    /*
     * =========================
     * 현재가 카운트업
     * =========================
     */
    const priceAnimationStateMap = new WeakMap();
    function animatePriceCountUp(element, endPrice, prefix, suffix) {
        return new Promise(function (resolve) {
            if (!element || !Number.isFinite(endPrice)) {
                resolve();
                return;
            }
            const runningState = priceAnimationStateMap.get(element);
            if (runningState) {
                window.cancelAnimationFrame(runningState.frameId);
                runningState.finish();
            }
            const startPrice = readDisplayedNumber(element);
            if (endPrice <= startPrice) {
                setFormattedPrice(element, endPrice, prefix, suffix);
                resolve();
                return;
            }
            const animationDuration = 420;
            let animationStartTime = null;
            let finished = false;
            const animationState = {
                frameId: null,
                finish: function () {
                    if (finished) {
                        return;
                    }
                    finished = true;
                    if (priceAnimationStateMap.get(element) === animationState) {
                        priceAnimationStateMap.delete(element);
                    }
                    resolve();
                }
            };
            function drawPriceFrame(currentTime) {
                if (finished) {
                    return;
                }
                if (animationStartTime === null) {
                    animationStartTime = currentTime;
                }
                const elapsedTime = currentTime - animationStartTime;
                const progress = Math.min(elapsedTime / animationDuration, 1);
                const easedProgress = 1 - Math.pow(1 - progress, 3);
                const displayPrice = Math.round(startPrice + (endPrice - startPrice) * easedProgress);
                setFormattedPrice(element, displayPrice, prefix, suffix);
                if (progress < 1) {
                    animationState.frameId = window.requestAnimationFrame(drawPriceFrame);
                    return;
                }
                setFormattedPrice(element, endPrice, prefix, suffix);
                animationState.finish();
            }
            priceAnimationStateMap.set(element, animationState);
            animationState.frameId = window.requestAnimationFrame(drawPriceFrame);
        });
    }
    
    /*
     * =========================
     * 입찰 건수 롤링
     * 마이페이지의 검증된 큐 방식을 동일하게 사용
     * =========================
     */
    const bidCountAnimationQueueMap = new WeakMap();
    const bidCountValueMap = new WeakMap();
    
    function setFormattedBidCount(element, bidCount, prefix, suffix) {
        if (!element || !Number.isSafeInteger(bidCount)) {
            return;
        }
        element.textContent = prefix + String(bidCount) + suffix;
        bidCountValueMap.set(element, bidCount);
    }
    
    async function runSingleBidCountRoll(element, startCount, endCount, prefix, suffix) {
        const oldValueElement = document.createElement("span");
        oldValueElement.className = "bid-count-roll-value";
        oldValueElement.textContent = String(startCount);
        const newValueElement = document.createElement("span");
        newValueElement.className = "bid-count-roll-value";
        newValueElement.textContent = String(endCount);
        const trackElement = document.createElement("span");
        trackElement.className = "bid-count-roll-track";
        trackElement.appendChild(oldValueElement);
        trackElement.appendChild(newValueElement);
        const viewportElement = document.createElement("span");
        viewportElement.className = "bid-count-roll-viewport";
        viewportElement.appendChild(trackElement);
        element.replaceChildren(document.createTextNode(prefix), viewportElement, document.createTextNode(suffix));
        void viewportElement.offsetHeight;
        const oldRectangle = oldValueElement.getBoundingClientRect();
        const newRectangle = newValueElement.getBoundingClientRect();
        const rowHeight = Math.max(oldRectangle.height, newRectangle.height, 1);
        const rowWidth = Math.max(oldRectangle.width, newRectangle.width, 1);
        viewportElement.style.height = Math.ceil(rowHeight) + "px";
        viewportElement.style.minWidth = Math.ceil(rowWidth) + "px";
        const rollAnimation = trackElement.animate([
            {
                transform: "translateY(0)"
            },
            {
                transform: "translateY(-" + rowHeight + "px)"
            }
        ], {
            duration: 320,
            easing: "cubic-bezier(0.22, 1, 0.36, 1)",
            fill: "forwards"
        });
        try {
            await rollAnimation.finished;
        }
        catch (error) {
            console.debug("[DETAIL BID COUNT ROLL CANCELED]", error);
        }
        setFormattedBidCount(element, endCount, prefix, suffix);
    }
    
    function animateBidCountRoll(element, endCount, prefix, suffix) {
        if (!element || !Number.isSafeInteger(endCount)) {
            return Promise.resolve();
        }
        const previousQueue = bidCountAnimationQueueMap.get(element) || Promise.resolve();
        const nextQueue = previousQueue.catch(function () {
        	
        //이전 애니메이션 오류가 다음 실시간 갱신을 막지 않는다.
        }).then(async function () {
            const storedCount = bidCountValueMap.get(element);
            const startCount = Number.isSafeInteger(storedCount) ? storedCount : readDisplayedNumber(element);
            if (endCount <= startCount) {
                setFormattedBidCount(element, endCount, prefix, suffix);
                return;
            }
            if (endCount - startCount > 5) {
                await runSingleBidCountRoll(element, startCount, endCount, prefix, suffix);
                return;
            }
            for (let count = startCount + 1; count <= endCount; count++) {
                await runSingleBidCountRoll(element, count - 1, count, prefix, suffix);
            }
        });
        bidCountAnimationQueueMap.set(element, nextQueue);
        return nextQueue;
    }
    if (detailBidCount) {
        bidCountValueMap.set(detailBidCount, readDisplayedNumber(detailBidCount));
    }
    if (bidHistorySummaryCount) {
        bidCountValueMap.set(bidHistorySummaryCount, readDisplayedNumber(bidHistorySummaryCount));
    }
    
    /*
     * =========================
     * 입찰 이력 행 생성
     * =========================
     */
    function createBidKey(memberId, bidPrice, bidDatetime) {
        return String(memberId == null ? "" : memberId) + "|" + String(Number.isFinite(Number(bidPrice)) ? Number(bidPrice) : 0) + "|" + String(bidDatetime == null ? "" : bidDatetime);
    }
    
    function getBidKeyFromData(bid) {
        if (bid && bid.bidNo !== null && bid.bidNo !== undefined) {
            return "BID_NO|" + String(bid.bidNo);
        }
        return createBidKey(bid ? bid.memberId : "", bid ? bid.bidPrice : 0, bid ? bid.bidDatetime : "");
    }
    
    function getBidKeyFromElement(itemElement) {
        if (itemElement.dataset.bidNo) {
            return "BID_NO|" + itemElement.dataset.bidNo;
        }
        const memberIdElement = itemElement.querySelector(".bid-history-member-id");
        const priceElement = itemElement.querySelector(".bid-history-price");
        const datetimeElement = itemElement.querySelector(".bid-history-datetime");
        return createBidKey(memberIdElement ? memberIdElement.textContent.trim() : "", priceElement ? readDisplayedNumber(priceElement) : 0, datetimeElement ? datetimeElement.textContent.trim() : "");
    }
    
    function createBidHistoryItem(bid) {
        const itemElement = document.createElement("div");
        itemElement.className = "bid-history-item";
        itemElement.dataset.bidKey = getBidKeyFromData(bid);
        if (bid.bidNo !== null && bid.bidNo !== undefined) {
            itemElement.dataset.bidNo = String(bid.bidNo);
        }
        const memberIdElement = document.createElement("span");
        memberIdElement.className = "bid-history-member-id";
        memberIdElement.textContent = bid.memberId == null ? "" : String(bid.memberId);
        const priceElement = document.createElement("strong");
        priceElement.className = "bid-history-price";
        const bidPrice = Number(bid.bidPrice);
        priceElement.textContent = Number.isFinite(bidPrice) ? priceFormatter.format(bidPrice) : "0";
        const datetimeElement = document.createElement("span");
        datetimeElement.className = "bid-history-datetime";
        datetimeElement.textContent = bid.bidDatetime == null ? "" : String(bid.bidDatetime);
        itemElement.appendChild(memberIdElement);
        itemElement.appendChild(priceElement);
        itemElement.appendChild(datetimeElement);
        return itemElement;
    }
    
    function createBidHistoryEmptyElement() {
        const emptyElement = document.createElement("div");
        emptyElement.className = "bid-history-empty";
        emptyElement.textContent = "\uC544\uC9C1 \uC785\uCC30 \uB0B4\uC5ED\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.";
        return emptyElement;
    }
    
    /*
     * =========================
     * 입찰 이력 상태·애니메이션
     * =========================
     */
    const knownBidKeySet = new Set();
    let bidHistoryAnimationQueue = Promise.resolve();
    let bidHistoryUpdateVersion = 0;
    
    function initializeKnownBidKeys() {
        if (!bidHistoryList) {
            return;
        }
        const currentItems = bidHistoryList.querySelectorAll(".bid-history-item");
        currentItems.forEach(function (itemElement) {
            const bidKey = getBidKeyFromElement(itemElement);
            itemElement.dataset.bidKey = bidKey;
            knownBidKeySet.add(bidKey);
        });
    }
    
    function renderBidHistorySnapshot(bidList) {
        if (!bidHistoryList) {
            return;
        }
        bidHistoryList.replaceChildren();
        knownBidKeySet.clear();
        if (!Array.isArray(bidList) || bidList.length === 0) {
            bidHistoryList.appendChild(createBidHistoryEmptyElement());
            return;
        }
        const fragment = document.createDocumentFragment();
        bidList.forEach(function (bid) {
            const itemElement = createBidHistoryItem(bid);
            knownBidKeySet.add(itemElement.dataset.bidKey);
            fragment.appendChild(itemElement);
        });
        bidHistoryList.appendChild(fragment);
        bidHistoryList.scrollTop = 0;
    }
    
    function removeBidHistoryEmptyElement() {
        if (!bidHistoryList) {
            return;
        }
        const emptyElement = bidHistoryList.querySelector(".bid-history-empty");
        if (emptyElement) {
            emptyElement.remove();
        }
    }
    
    function waitForAnimation(animation) {
        if (!animation || !animation.finished) {
            return Promise.resolve();
        }
        return animation.finished.catch(function () {
            //애니메이션 취소 시에도 다음 갱신을 이어간다.
        });
    }
    
    async function animateNewBidHistoryItem(bid, shouldAnimate) {
        if (!bidHistoryList) {
            return;
        }
        removeBidHistoryEmptyElement();
        const itemElement = createBidHistoryItem(bid);
        const bidKey = itemElement.dataset.bidKey;
        if (knownBidKeySet.has(bidKey)) {
            return;
        }
        knownBidKeySet.add(bidKey);
        if (!shouldAnimate) {
            bidHistoryList.prepend(itemElement);
            bidHistoryList.scrollTop = 0;
            return;
        }
        const placeholderElement = document.createElement("div");
        placeholderElement.className = "bid-history-placeholder";
        bidHistoryList.prepend(placeholderElement);
        bidHistoryList.appendChild(itemElement);
        const itemHeight = Math.max(itemElement.getBoundingClientRect().height, 42);
        itemElement.remove();
        const flyingElement = createBidHistoryItem(bid);
        flyingElement.classList.add("bid-history-flying-item");
        flyingElement.style.top = Math.max(8, bidHistoryList.clientHeight - itemHeight) + "px";
        bidHistoryList.appendChild(flyingElement);
        const placeholderAnimation = placeholderElement.animate([
            {
                height: "0px"
            },
            {
                height: itemHeight + "px"
            }
        ], {
            duration: 340,
            easing: "cubic-bezier(0.22, 1, 0.36, 1)",
            fill: "forwards"
        });
        const startTop = parseFloat(flyingElement.style.top) || 0;
        const endTop = 8;
        const flyingAnimation = flyingElement.animate([
            {
                transform: "translateY(0)"
            },
            {
                transform: "translateY(" + (endTop - startTop) + "px)"
            }
        ], {
            duration: 520,
            easing: "cubic-bezier(0.22, 1, 0.36, 1)",
            fill: "forwards"
        });
        await Promise.all([
            waitForAnimation(placeholderAnimation),
            waitForAnimation(flyingAnimation)
        ]);
        flyingElement.remove();
        placeholderElement.replaceWith(itemElement);
        bidHistoryList.scrollTop = 0;
    }
    
    function normalizeBidList(bidList) {
        if (!Array.isArray(bidList)) {
            return [];
        }
        return bidList.filter(function (bid) {
            return bid && Number.isFinite(Number(bid.bidPrice));
        });
    }
    
    function queueBidHistoryUpdate(bidList) {
        if (!bidHistoryList) {
            return;
        }
        const normalizedBidList = normalizeBidList(bidList);
        const updateVersion = ++bidHistoryUpdateVersion;
        const newBidList = normalizedBidList.filter(function (bid) {
            return !knownBidKeySet.has(getBidKeyFromData(bid));
        });
        const shouldAnimate = Boolean(bidDialog && bidDialog.open && newBidList.length > 0);
        newBidList.slice().reverse().forEach(function (bid) {
            bidHistoryAnimationQueue = bidHistoryAnimationQueue.catch(function () {
            	
                //이전 행 애니메이션 오류를 다음 행에 전파하지 않는다.
            }).then(function () {
                return animateNewBidHistoryItem(bid, shouldAnimate);
            });
        });
        bidHistoryAnimationQueue = bidHistoryAnimationQueue.then(function () {
            if (updateVersion !== bidHistoryUpdateVersion) {
                return;
            }
            renderBidHistorySnapshot(normalizedBidList);
        });
    }
    initializeKnownBidKeys();
    
    /*
     * =========================
     * 실시간 데이터 적용
     * =========================
     */
    function normalizeRealtimeSnapshot(realtimeData) {
        if (!realtimeData) {
            return null;
        }
        if (String(realtimeData.auctionNo) !== String(auctionNo)) {
            console.warn("[AUCTION REALTIME] \uB2E4\uB978 \uACBD\uB9E4 \uB370\uC774\uD130", realtimeData);
            return null;
        }
        const auctionStatus = realtimeData.status == null ? "" : String(realtimeData.status).trim().toUpperCase();
        if (auctionStatus !== "" && auctionStatus !== "ONGOING") {
            window.location.reload();
            return null;
        }
        const currentPrice = Number(realtimeData.currentPrice);
        const bidCount = Number(realtimeData.bidCount);
        const nextBidPrice = realtimeData.nextBidPrice == null ? null : Number(realtimeData.nextBidPrice);
        const demoState = realtimeData.demoState == null ? "READY" : String(realtimeData.demoState).trim().toUpperCase();
        const demoRemainingMillis = Number(realtimeData.demoRemainingMillis);
        if (!Number.isFinite(currentPrice) || !Number.isSafeInteger(bidCount) || bidCount < 0) {
            console.warn("[AUCTION REALTIME] \uC798\uBABB\uB41C \uC22B\uC790 \uB370\uC774\uD130", realtimeData);
            return null;
        }
        return {
            auctionNo: String(auctionNo),
            status: auctionStatus,
            currentPrice: currentPrice,
            bidCount: bidCount,
            nextBidPrice: Number.isSafeInteger(nextBidPrice) ? nextBidPrice : null,
            demoState: (demoState === "RUNNING" || demoState === "COOLDOWN" || demoState === "READY") ? demoState : "READY",
            demoRemainingMillis: Number.isFinite(demoRemainingMillis) ? Math.max(0, demoRemainingMillis) : 0,
            bidList: Array.isArray(realtimeData.bidList) ? realtimeData.bidList : []
        };
    }
    
    function updateBidActionFromSnapshot(snapshot) {
        if (!snapshot) {
            return;
        }
        const nextBidPrice = snapshot.nextBidPrice;
        if (bidPriceInput && Number.isSafeInteger(nextBidPrice) && nextBidPrice > 0) {
            bidPriceInput.value = String(nextBidPrice);
        }
        if (bidSubmitButton && !bidSubmitButton.disabled && Number.isSafeInteger(nextBidPrice) && nextBidPrice > 0) {
            bidSubmitButton.textContent = "KRW " + priceFormatter.format(nextBidPrice) + " \uC785\uCC30\uD558\uAE30";
        }
    }
    
    function calculatePriceForBidCount(bidCount, targetSnapshot) {
        if (targetSnapshot && bidCount === targetSnapshot.bidCount) {
            return targetSnapshot.currentPrice;
        }
        if (bidCount <= 1) {
            return AUCTION_START_PRICE;
        }
        return AUCTION_START_PRICE + (bidCount - 1) * AUCTION_BID_UNIT;
    }
    
    async function animateRealtimeStep(nextPrice, nextBidCount) {
        const animations = [];
        if (detailCurrentPrice && Number.isFinite(nextPrice)) {
            animations.push(animatePriceCountUp(detailCurrentPrice, nextPrice, "", "\uC6D0"));
        }
        if (detailBidCount) {
            animations.push(animateBidCountRoll(detailBidCount, nextBidCount, "", "\uAC74"));
        }
        if (bidDialog && bidDialog.open) {
            if (bidHistorySummaryPrice) {
                animations.push(animatePriceCountUp(bidHistorySummaryPrice, nextPrice, "KRW ", ""));
            }
            if (bidHistorySummaryCount) {
                animations.push(animateBidCountRoll(bidHistorySummaryCount, nextBidCount, "(\uC785\uCC30 ", "\uAC74)"));
            }
        }
        else {
            setFormattedPrice(bidHistorySummaryPrice, nextPrice, "KRW ", "");
            setFormattedBidCount(bidHistorySummaryCount, nextBidCount, "(\uC785\uCC30 ", "\uAC74)");
        }
        await Promise.all(animations);
    }
    
    function applyBidHistorySnapshot(snapshot) {
        try {
            queueBidHistoryUpdate(snapshot.bidList);
        }
        catch (error) {
            console.error("[AUCTION BID HISTORY UPDATE FAILED]", error);
        }
    }
    
    async function processRealtimeSnapshots() {
        if (realtimeAnimationRunning) {
            return;
        }
        realtimeAnimationRunning = true;
        try {
            while (latestRealtimeSnapshot) {
                const snapshot = latestRealtimeSnapshot;
                if (snapshot.bidCount < appliedBidCount) {
                    if (latestRealtimeSnapshot === snapshot) {
                        latestRealtimeSnapshot = null;
                    }
                    continue;
                }
                if (snapshot.bidCount > appliedBidCount) {
                    const nextBidCount = appliedBidCount + 1;
                    const nextPrice = calculatePriceForBidCount(nextBidCount, snapshot);
                    await animateRealtimeStep(nextPrice, nextBidCount);
                    appliedBidCount = nextBidCount;
                    appliedCurrentPrice = nextPrice;
                    continue;
                }
                if (snapshot.currentPrice !== appliedCurrentPrice) {
                    await animateRealtimeStep(snapshot.currentPrice, snapshot.bidCount);
                    appliedCurrentPrice = snapshot.currentPrice;
                }
                updateBidActionFromSnapshot(snapshot);
                applyBidHistorySnapshot(snapshot);
                console.log("[AUCTION REALTIME APPLIED]", snapshot);
                if (latestRealtimeSnapshot === snapshot) {
                    latestRealtimeSnapshot = null;
                }
            }
        }
        catch (error) {
            console.error("[AUCTION REALTIME ANIMATION FAILED]", error);
        }
        finally {
            realtimeAnimationRunning = false;
            if (latestRealtimeSnapshot) {
                processRealtimeSnapshots();
            }
        }
    }
    
    function applyRealtimeAuctionData(realtimeData) {
        const snapshot = normalizeRealtimeSnapshot(realtimeData);
        if (!snapshot) {
            return;
        }
        syncBidDemoUiFromSnapshot(snapshot);
        
        //실제 입찰 버튼에는 애니메이션 완료 전이라도 서버가 확정한 최신 다음 입찰가를 즉시 넣는다.
        updateBidActionFromSnapshot(snapshot);
        const latestBid = snapshot.bidList.length > 0 ? snapshot.bidList[0] : null;
        const realtimeSignature = String(snapshot.bidCount) + "|" + String(snapshot.currentPrice) + "|" + String(latestBid && latestBid.bidNo != null ? latestBid.bidNo : "");
        if (realtimeSignature === lastQueuedRealtimeSignature) {
            return;
        }
        lastQueuedRealtimeSignature = realtimeSignature;
        if (latestRealtimeSnapshot && snapshot.bidCount < latestRealtimeSnapshot.bidCount) {
            return;
        }
        latestRealtimeSnapshot = snapshot;
        processRealtimeSnapshots();
    }
    
    /*
     * =========================
     * 최신 데이터 조회
     * 이벤트가 겹치면 요청을 버리지 않고 직렬 처리한다.
     * =========================
     */
    async function loadBidDemoRealtimeSnapshot() {
        const response = await fetch(realtimeUrl, {
            method: "GET",
            headers: {
                "Accept": "application/json"
            },
            cache: "no-store"
        });
        if (!response.ok) {
            throw new Error("BID_DEMO_REALTIME_HTTP_" + response.status);
        }
        const realtimeData = await response.json();
        const snapshot = normalizeRealtimeSnapshot(realtimeData);
        if (!snapshot) {
            throw new Error("BID_DEMO_REALTIME_INVALID");
        }
        return {
            rawData: realtimeData,
            snapshot: snapshot
        };
    }
    
    async function refreshRealtimeAuction(reason) {
        realtimeRefreshRequested = true;
        if (realtimeRefreshRunning) {
            return;
        }
        realtimeRefreshRunning = true;
        try {
            while (realtimeRefreshRequested) {
                realtimeRefreshRequested = false;
                try {
                    console.log("[AUCTION REALTIME REQUEST] REASON=" + (reason || "UNKNOWN"), realtimeUrl);
                    const response = await fetch(realtimeUrl, {
                        method: "GET",
                        headers: {
                            "Accept": "application/json"
                        },
                        cache: "no-store"
                    });
                    if (!response.ok) {
                        throw new Error("HTTP_STATUS_" + response.status);
                    }
                    const realtimeData = await response.json();
                    applyRealtimeAuctionData(realtimeData);
                }
                catch (error) {
                    console.error("[AUCTION REALTIME FAILED]", error);
                }
            }
        }
        finally {
            realtimeRefreshRunning = false;
            if (realtimeRefreshRequested) {
                refreshRealtimeAuction("PENDING");
            }
        }
    }
    
    function startRealtimePolling() {
        if (realtimePollTimerId !== null) {
            return;
        }
        realtimePollTimerId = window.setInterval(function () {
            if (document.visibilityState === "visible") {
                refreshRealtimeAuction("POLL");
            }
        }, REALTIME_SYNC_INTERVAL_MS);
    }
    
    function stopRealtimePolling() {
        if (realtimePollTimerId === null) {
            return;
        }
        window.clearInterval(realtimePollTimerId);
        realtimePollTimerId = null;
    }
    window.refreshRealtimeAuction = function () {
        refreshRealtimeAuction("EXTERNAL");
    };
    
    /*
     * =========================
     * 비관적 락 처리 흐름 시각화
     * - 실제 요청과 화면 애니메이션을 분리한다.
     * - 요청은 서버로 동시에 전송한다.
     * - 화면에서는 공이 순차적으로 발사된다.
     * - 공은 깔대기 '선'이 아니라 위/아래 경계 사이 공간을 통과한다.
     * - LOCK 앞에서는 막힌 구슬처럼 삼각형/피라미드 형태로 쌓인다.
     * - 실제 SUCCESS 요청만 LOCK을 통과한다.
     * - REJECTED 요청은 쌓인 자리에서 X로 바뀐 뒤 사라진다.
     * =========================
     */
    const bidFlowTokenMap = new Map();
    const bidFlowTokenExpiryTimerMap = new Map();
    const bidFlowVisualStateMap = new Map();
    const bidFlowAllRequestIds = new Set();
    const bidFlowSuccessRequestIds = new Set();
    const bidFlowRejectedRequestIds = new Set();
    const bidFlowRejectedVisibleRequestIds = new Set();
    const bidFlowResolvedRequestIds = new Set();
    const bidFlowSuccessQueue = [];
    const bidFlowLaunchTimerIds = new Set();
    let bidFlowGeneration = 0;
    let bidFlowSuccessAnimatingGeneration = null;
    let bidFlowRejectTimer = null;
    let bidFlowForceCleanupTimer = null;
    
    //공이 LOCK 앞에 쌓이는 순서를 부여한다.
    let bidFlowPileSequence = 0;
    
    //짧은 시간에 요청이 몰리면 공을 1개씩 발사하기 위한 버스트 상태
    let bidFlowLastRequestedAt = 0;
    let bidFlowBurstLaunchIndex = 0;
    
    //현재 브라우저에서 재생 중인 동시 요청 시연 정보
    let activeBidDemoId = null;
    let activeBidDemoRequestIds = [];
    let activeBidDemoSpawnPromise = Promise.resolve();
    
    //동시 시연 UI 상태 : READY / STARTING / RUNNING / COOLDOWN
    let bidDemoUiState = "READY";
    let bidDemoCooldownEndsAt = 0;
    let bidDemoCooldownIntervalId = null;
    let bidDemoRunningTimeoutId = null;
    const BID_FLOW_SPAWN_INTERVAL_MS = 24;
    const BID_FLOW_FIRST_MOVE_MS = 480;
    const BID_FLOW_SECOND_MOVE_MS = 500;
    const BID_FLOW_LOCK_HOLD_MS = 180;
    
    function waitForBidFlowAnimation(milliseconds) {
        return new Promise(function (resolve) {
            window.setTimeout(resolve, milliseconds);
        });
    }
    
    function moveBidFlowToken(tokenElement, x, y) {
        if (!tokenElement) {
            return;
        }
        tokenElement.style.transform = "translate(" + x + "px, " + y + "px)";
    }
    
    //SVG는 viewBox="0 0 300 132" 좌표계를 사용하고, 공은 HTML span 요소이므로 SVG 논리 좌표를 실제 px 좌표로 변환한다.
    function getBidFlowScreenPosition(tokenElement, logicalX, logicalY) {
        if (!bidFlowStage || !tokenElement) {
            return { x: 0, y: 0 };
        }
        const stageWidth = bidFlowStage.clientWidth;
        const stageHeight = bidFlowStage.clientHeight;
        const tokenSize = tokenElement.offsetWidth;
        return {
            x: (logicalX / 300) * stageWidth - tokenSize / 2,
            y: (logicalY / 132) * stageHeight - tokenSize / 2
        };
    }
    
    /*
     * 현재 깔대기 모양의 논리 좌표.
     * 왼쪽: y=12 \\~ 120
     * LOCK 직전: y=57 \\~ 75
     * x=62 \\~ 174 구간에서 점점 좁아진다.
     *
     * 실제 SVG는 곡선이지만 공 배치용 경계는 약간 안쪽으로 잡아
     * 공이 선을 뚫고 보이지 않게 한다.
     */
    function getBidFlowFunnelBounds(logicalX) {
        if (logicalX <= 62) {
            return {
                top: 12,
                bottom: 120
            };
        }
        if (logicalX >= 174) {
            return {
                top: 57,
                bottom: 75
            };
        }
        const ratio = (logicalX - 62) / (174 - 62);
        
        //직선 보간보다 약간 자연스럽게 좁아지도록 smoothstep 사용
        const smoothRatio = ratio * ratio * (3 - 2 * ratio);
        return {
            top: 12 + (57 - 12) * smoothRatio,
            bottom: 120 + (75 - 120) * smoothRatio
        };
    }
    
    function clampBidFlowLogicalY(logicalX, logicalY, padding) {
        const bounds = getBidFlowFunnelBounds(logicalX);
        const safePadding = padding == null ? 3 : padding;
        return Math.max(bounds.top + safePadding, Math.min(bounds.bottom - safePadding, logicalY));
    }
    //왼쪽 출발선. 위/아래 선 자체가 아니라 그 사이 공간의 랜덤 위치에서 출발한다.
    function getBidFlowEntryLogicalPosition() {
        const minY = 20;
        const maxY = 112;
        return {
            x: 12,
            y: minY + Math.random() * (maxY - minY)
        };
    }
    
    /*
     * 깔대기 중간 통과 지점.
     * 출발 Y를 어느 정도 유지하면서 중앙(y=66) 쪽으로 서서히 모은다.
     * 랜덤 오차를 조금 줘서 모든 공이 같은 레일을 타지 않게 한다.
     */
    function getBidFlowMiddleLogicalPosition(entryLogicalY) {
        const logicalX = 108;
        let logicalY = 66 + (entryLogicalY - 66) * 0.52 + (Math.random() * 8 - 4);
        logicalY = clampBidFlowLogicalY(logicalX, logicalY, 4);
        return {
            x: logicalX,
            y: logicalY
        };
    }
    
    function getBidFlowTokenSize(requestCount) {
        if (requestCount <= 20) {
            return 6;
        }
        if (requestCount <= 100) {
            return 4;
        }
        if (requestCount <= 200) {
            return 3;
        }
        if (requestCount <= 500) {
            return 3;
        }
        return 2;
    }
    
    function updateBidFlowTokenDensity() {
        if (!bidFlowPanel) {
            return;
        }
        const tokenSize = getBidFlowTokenSize(bidFlowTokenMap.size);
        bidFlowPanel.style.setProperty("--bid-flow-token-size", tokenSize + "px");
    }
    
    function updateBidFlowCounters() {
        const pendingCount = Math.max(0, bidFlowAllRequestIds.size - bidFlowResolvedRequestIds.size);
        if (bidFlowSuccessCount) {
            bidFlowSuccessCount.textContent = String(bidFlowSuccessRequestIds.size);
        }
        if (bidFlowRejectedCount) {
            bidFlowRejectedCount.textContent = String(bidFlowRejectedRequestIds.size);
        }
        if (bidFlowPendingCount) {
            bidFlowPendingCount.textContent = String(pendingCount);
        }
    }
    
    function clearBidFlowTokenExpiry(requestId) {
        const timerId = bidFlowTokenExpiryTimerMap.get(requestId);
        if (timerId !== undefined) {
            window.clearTimeout(timerId);
            bidFlowTokenExpiryTimerMap.delete(requestId);
        }
    }
    
    function clearBidFlowLaunchTimers() {
        bidFlowLaunchTimerIds.forEach(function (timerId) {
            window.clearTimeout(timerId);
        });
        bidFlowLaunchTimerIds.clear();
    }
    
    function removeBidFlowToken(requestId) {
        clearBidFlowTokenExpiry(requestId);
        const tokenElement = bidFlowTokenMap.get(requestId);
        if (tokenElement) {
            tokenElement.remove();
        }
        bidFlowTokenMap.delete(requestId);
        bidFlowVisualStateMap.delete(requestId);
        bidFlowRejectedVisibleRequestIds.delete(requestId);
    }
    
    function resetBidFlowVisualization() {
        bidFlowGeneration += 1;
        if (bidFlowRejectTimer !== null) {
            window.clearTimeout(bidFlowRejectTimer);
            bidFlowRejectTimer = null;
        }
        if (bidFlowForceCleanupTimer !== null) {
            window.clearTimeout(bidFlowForceCleanupTimer);
            bidFlowForceCleanupTimer = null;
        }
        clearBidFlowLaunchTimers();
        bidFlowTokenExpiryTimerMap.forEach(function (timerId) {
            window.clearTimeout(timerId);
        });
        bidFlowTokenExpiryTimerMap.clear();
        bidFlowTokenMap.clear();
        bidFlowVisualStateMap.clear();
        bidFlowAllRequestIds.clear();
        bidFlowSuccessRequestIds.clear();
        bidFlowRejectedRequestIds.clear();
        bidFlowRejectedVisibleRequestIds.clear();
        bidFlowResolvedRequestIds.clear();
        bidFlowSuccessQueue.length = 0;
        bidFlowSuccessAnimatingGeneration = null;
        bidFlowPileSequence = 0;
        bidFlowLastRequestedAt = 0;
        bidFlowBurstLaunchIndex = 0;
        if (bidFlowTokenLayer) {
            bidFlowTokenLayer.replaceChildren();
        }
        updateBidFlowTokenDensity();
        updateBidFlowCounters();
    }
    
    /*
     * LOCK 앞 구슬 더미 좌표 계산.
     *
     * column 0 : LOCK 바로 앞 1개
     * column 1 : 그 뒤 2개
     * column 2 : 그 뒤 3개
     * ...
     *
     * 단, 실제 깔대기 폭보다 많은 공은 넣지 않는다.
     * 그래서 오른쪽은 좁고 왼쪽으로 갈수록 넓어지는
     * 삼각형/피라미드 형태가 자연스럽게 만들어진다.
     */
    function getBidFlowPileLogicalPosition(tokenElement, pileIndex) {
        const stageWidth = bidFlowStage ? bidFlowStage.clientWidth : 300;
        const tokenSizePx = Math.max(2, tokenElement.offsetWidth);
        /* 화면 px 크기를 SVG 논리 좌표 크기로 환산 */
        const tokenSizeLogical = (tokenSizePx / Math.max(stageWidth, 1)) * 300;
        const horizontalSpacing = Math.max(4.2, tokenSizeLogical + 0.9);
        const verticalSpacing = Math.max(4, tokenSizeLogical + 0.7);
        const pileFrontX = 198;
        const centerY = 66;
        const boundaryPadding = 3.5;
        let remainingIndex = pileIndex;
        for (let columnIndex = 0; columnIndex < 80; columnIndex++) {
            const logicalX = pileFrontX - columnIndex * horizontalSpacing;
            const bounds = getBidFlowFunnelBounds(logicalX);
            const usableHeight = Math.max(0, bounds.bottom - bounds.top - boundaryPadding * 2);
            const maximumFitCount = Math.max(1, Math.floor(usableHeight / verticalSpacing) + 1);
            /*
             * 피라미드 규칙:
             * LOCK에서 멀어질수록 1,2,3,4...개까지 허용.
             */
            const desiredCount = columnIndex + 1;
            const columnCapacity = Math.max(1, Math.min(desiredCount, maximumFitCount));
            if (remainingIndex < columnCapacity) {
                const columnHeight = (columnCapacity - 1) * verticalSpacing;
                let logicalY = centerY - columnHeight / 2 + remainingIndex * verticalSpacing;
                logicalY = clampBidFlowLogicalY(logicalX, logicalY, boundaryPadding);
                return {
                    x: logicalX,
                    y: logicalY
                };
            }
            remainingIndex -= columnCapacity;
        }
        /* 매우 큰 요청 수에 대한 안전 fallback */
        return {
            x: 70,
            y: 66
        };
    }
    
    function getBidFlowBurstLaunchDelay() {
        const now = performance.now();
        if (now - bidFlowLastRequestedAt > 120) {
            bidFlowBurstLaunchIndex = 0;
        }
        else {
            bidFlowBurstLaunchIndex += 1;
        }
        bidFlowLastRequestedAt = now;
        return Math.min(bidFlowBurstLaunchIndex * BID_FLOW_SPAWN_INTERVAL_MS, 2200);
    }
    
    function createBidFlowVisualState(requestId) {
        const visualState = {
            requestId: requestId,
            pileIndex: bidFlowPileSequence++,
            spawned: false,
            settled: false,
            resultApplied: false,
            result: null,
            reason: null,
            entryLogicalY: null
        };
        bidFlowVisualStateMap.set(requestId, visualState);
        return visualState;
    }
    
    function enqueueBidFlowRequest(requestId, deferRender) {
        if (!bidFlowTokenLayer || !requestId || bidFlowTokenMap.has(requestId)) {
            return;
        }
        const tokenElement = document.createElement("span");
        tokenElement.className = "bid-flow-token";
        tokenElement.dataset.requestId = requestId;
        tokenElement.dataset.result = "PENDING";
        /* 실제 발사 전까지 왼쪽 위에 보이지 않도록 숨긴다. */
        tokenElement.style.visibility = "hidden";
        bidFlowTokenLayer.appendChild(tokenElement);
        bidFlowTokenMap.set(requestId, tokenElement);
        bidFlowAllRequestIds.add(requestId);
        const visualState = createBidFlowVisualState(requestId);
        /*
         * 일반 단건 입찰 시각화만 STALE 타이머를 사용한다.
         *
         * 동시 요청 시연(deferRender=true)은
         * BID_DEMO_FINISHED가 최종 결과를 결정하므로
         * 임의로 8초 뒤 REJECTED 처리하지 않는다.
         */
        if (deferRender !== true) {
            const expiryTimerId = window.setTimeout(function () {
                if (bidFlowResolvedRequestIds.has(requestId)) {
                    return;
                }
                resolveBidFlowRequest(requestId, "REJECTED", "STALE_EVENT");
            }, BID_FLOW_STALE_TOKEN_MS);
            bidFlowTokenExpiryTimerMap.set(requestId, expiryTimerId);
        }
        updateBidFlowTokenDensity();
        updateBidFlowCounters();
        if (deferRender === true) {
            return;
        }
        const launchDelay = getBidFlowBurstLaunchDelay();
        const timerId = window.setTimeout(function () {
            bidFlowLaunchTimerIds.delete(timerId);
            startBidFlowTokenFlight(requestId, visualState.pileIndex, bidFlowGeneration);
        }, launchDelay);
        bidFlowLaunchTimerIds.add(timerId);
    }
    
    //공 1개의 기본 이동: 왼쪽 랜덤 출발 → 깔대기 중간 → LOCK 앞의 자기 pile 자리.
    async function startBidFlowTokenFlight(requestId, pileIndex, animationGeneration) {
        const tokenElement = bidFlowTokenMap.get(requestId);
        const visualState = bidFlowVisualStateMap.get(requestId);
        if (!tokenElement || !visualState || animationGeneration !== bidFlowGeneration) {
            return;
        }
        const entryLogicalPosition = getBidFlowEntryLogicalPosition();
        visualState.entryLogicalY = entryLogicalPosition.y;
        const entryPosition = getBidFlowScreenPosition(tokenElement, entryLogicalPosition.x, entryLogicalPosition.y);
        /* 첫 위치는 순간이동: 화면 밖에서 날아오는 현상을 막는다. */
        tokenElement.style.transition = "none";
        tokenElement.style.visibility = "visible";
        moveBidFlowToken(tokenElement, entryPosition.x, entryPosition.y);
        /* 강제 reflow 후 원래 CSS transition 복구 */
        tokenElement.offsetWidth;
        tokenElement.style.transition = "";
        visualState.spawned = true;
        const middleLogicalPosition = getBidFlowMiddleLogicalPosition(entryLogicalPosition.y);
        const middlePosition = getBidFlowScreenPosition(tokenElement, middleLogicalPosition.x, middleLogicalPosition.y);
        window.requestAnimationFrame(function () {
            moveBidFlowToken(tokenElement, middlePosition.x, middlePosition.y);
        });
        await waitForBidFlowAnimation(BID_FLOW_FIRST_MOVE_MS);
        if (animationGeneration !== bidFlowGeneration || !bidFlowTokenMap.has(requestId)) {
            return;
        }
        const pileLogicalPosition = getBidFlowPileLogicalPosition(tokenElement, pileIndex);
        const pilePosition = getBidFlowScreenPosition(tokenElement, pileLogicalPosition.x, pileLogicalPosition.y);
        moveBidFlowToken(tokenElement, pilePosition.x, pilePosition.y);
        await waitForBidFlowAnimation(BID_FLOW_SECOND_MOVE_MS);
        if (animationGeneration !== bidFlowGeneration || !bidFlowTokenMap.has(requestId)) {
            return;
        }
        visualState.settled = true;
        applyBidFlowVisualResult(requestId);
    }
    
    /*
     * 서버 결과는 공보다 먼저 도착할 수 있다.
     * 이 함수는 공이 LOCK 앞 pile까지 도착한 뒤에만
     * SUCCESS/REJECTED 시각 효과를 실행한다.
     */
    function applyBidFlowVisualResult(requestId) {
        const visualState = bidFlowVisualStateMap.get(requestId);
        const tokenElement = bidFlowTokenMap.get(requestId);
        if (!visualState || !tokenElement || !visualState.settled || visualState.resultApplied || !visualState.result) {
            return;
        }
        visualState.resultApplied = true;
        if (visualState.result === "SUCCESS") {
            bidFlowSuccessQueue.push(requestId);
            playNextBidFlowSuccess();
            return;
        }
        tokenElement.classList.remove("is-processing", "is-success");
        tokenElement.classList.add("is-rejected");
        tokenElement.dataset.result = "REJECTED";
        tokenElement.dataset.reason = visualState.reason || "REJECTED";
        bidFlowRejectedVisibleRequestIds.add(requestId);
        scheduleRejectedBidFlowRemoval();
    }
    
    async function animateSuccessfulBidFlow(requestId, animationGeneration) {
        const tokenElement = bidFlowTokenMap.get(requestId);
        if (!tokenElement || animationGeneration !== bidFlowGeneration) {
            return;
        }
        tokenElement.classList.remove("is-rejected");
        tokenElement.classList.add("is-processing");
        
        //pile의 가장 앞 공이 아니더라도 실제 SUCCESS requestId의 공을 LOCK 바로 앞으로 끌어온다.
        const lockPosition = getBidFlowScreenPosition(tokenElement, 203, 66);
        moveBidFlowToken(tokenElement, lockPosition.x, lockPosition.y);
        await waitForBidFlowAnimation(520);
        if (animationGeneration !== bidFlowGeneration || !bidFlowTokenMap.has(requestId)) {
            return;
        }
        await waitForBidFlowAnimation(BID_FLOW_LOCK_HOLD_MS);
        if (animationGeneration !== bidFlowGeneration || !bidFlowTokenMap.has(requestId)) {
            return;
        }
        tokenElement.classList.remove("is-processing");
        tokenElement.classList.add("is-success");
        tokenElement.dataset.result = "SUCCESS";
        
        //실제 성공 공만 LOCK(x=207)을 넘어 성공 통로 끝으로 이동
        const successPosition = getBidFlowScreenPosition(tokenElement, 286, 66);
        moveBidFlowToken(tokenElement, successPosition.x, successPosition.y);
        await waitForBidFlowAnimation(520);
        if (animationGeneration !== bidFlowGeneration || !bidFlowTokenMap.has(requestId)) {
            return;
        }
        tokenElement.classList.add("is-leaving");
        await waitForBidFlowAnimation(220);
        removeBidFlowToken(requestId);
    }
    
    async function playNextBidFlowSuccess() {
        const animationGeneration = bidFlowGeneration;
        if (bidFlowSuccessAnimatingGeneration === animationGeneration || bidFlowSuccessQueue.length === 0) {
            return;
        }
        const requestId = bidFlowSuccessQueue.shift();
        bidFlowSuccessAnimatingGeneration = animationGeneration;
        try {
            await animateSuccessfulBidFlow(requestId, animationGeneration);
        }
        catch (error) {
            console.error("[BID FLOW SUCCESS ANIMATION FAILED]", error);
        }
        finally {
            if (bidFlowSuccessAnimatingGeneration === animationGeneration) {
                bidFlowSuccessAnimatingGeneration = null;
            }
            if (animationGeneration === bidFlowGeneration) {
                playNextBidFlowSuccess();
            }
        }
    }
    
    function animateRejectedBidFlowTokens(requestIds) {
        requestIds.forEach(function (requestId) {
            const tokenElement = bidFlowTokenMap.get(requestId);
            if (!tokenElement) {
                return;
            }
            tokenElement.classList.add("is-leaving");
            window.setTimeout(function () {
                removeBidFlowToken(requestId);
            }, 240);
        });
    }
    
    function removeRejectedBidFlowTokens() {
        bidFlowRejectTimer = null;
        const rejectedRequestIds = Array.from(bidFlowRejectedVisibleRequestIds);
        if (rejectedRequestIds.length === 0) {
            return;
        }
        animateRejectedBidFlowTokens(rejectedRequestIds);
    }
    
    function scheduleRejectedBidFlowRemoval() {
        if (bidFlowRejectTimer !== null) {
            window.clearTimeout(bidFlowRejectTimer);
        }
        bidFlowRejectTimer = window.setTimeout(removeRejectedBidFlowTokens, BID_FLOW_REJECT_HOLD_MS);
    }
    
    function forceCleanupRemainingBidFlowTokens() {
        bidFlowForceCleanupTimer = null;
        const unresolvedRequestIds = Array.from(bidFlowTokenMap.keys()).filter(function (requestId) {
            return !bidFlowResolvedRequestIds.has(requestId);
        });
        unresolvedRequestIds.forEach(function (requestId) {
            resolveBidFlowRequest(requestId, "REJECTED", "FORCE_CLEANUP");
        });
        if (bidFlowRejectedVisibleRequestIds.size > 0) {
            removeRejectedBidFlowTokens();
        }
    }
    
    function scheduleBidFlowForceCleanup() {
        if (bidFlowForceCleanupTimer !== null) {
            window.clearTimeout(bidFlowForceCleanupTimer);
        }
        bidFlowForceCleanupTimer = window.setTimeout(forceCleanupRemainingBidFlowTokens, BID_FLOW_FORCE_CLEANUP_MS);
    }
    
    /*
     * 서버 결과 처리.
     * 중요한 점:
     * 결과가 빨리 와도 바로 X/성공 애니메이션을 실행하지 않는다.
     * 공이 LOCK 앞 pile까지 도착한 뒤 applyBidFlowVisualResult()가 표현한다.
     */
    function promoteSuccessfulBidFlowTokenToFront(requestId) {
        const successState = bidFlowVisualStateMap.get(requestId);
        if (!successState || successState.settled || successState.pileIndex === 0) {
            return;
        }
        const frontEntry = Array.from(bidFlowVisualStateMap.entries()).find(function (entry) {
            const state = entry[1];
            return state && !state.settled && state.pileIndex === 0;
        });
        if (!frontEntry) {
            return;
        }
        const frontState = frontEntry[1];
        const originalSuccessPileIndex = successState.pileIndex;
        successState.pileIndex = 0;
        frontState.pileIndex = originalSuccessPileIndex;
    }
    
    function resolveBidFlowRequest(requestId, result, reason) {
        if (!requestId || bidFlowResolvedRequestIds.has(requestId)) {
            return;
        }
        if (!bidFlowTokenMap.has(requestId)) {
            enqueueBidFlowRequest(requestId, false);
        }
        bidFlowAllRequestIds.add(requestId);
        bidFlowResolvedRequestIds.add(requestId);
        clearBidFlowTokenExpiry(requestId);
        const normalizedResult = result === "SUCCESS" ? "SUCCESS" : "REJECTED";
        let visualState = bidFlowVisualStateMap.get(requestId);
        if (!visualState) {
            visualState = createBidFlowVisualState(requestId);
        }
        visualState.result = normalizedResult;
        visualState.reason = reason || normalizedResult;
        if (normalizedResult === "SUCCESS") {
            bidFlowSuccessRequestIds.add(requestId);
            promoteSuccessfulBidFlowTokenToFront(requestId);
        }
        else {
            bidFlowRejectedRequestIds.add(requestId);
        }
        updateBidFlowCounters();
        
        //공이 이미 LOCK 앞에 도착했다면 즉시 결과를 표현한다.
        applyBidFlowVisualResult(requestId);
    }
    
    /*
     * =========================
     * 동시 입찰 요청 시연
     * =========================
     */
    function createBidDemoVisualRequestId(demoId, index) {
        return ("DEMO-" + demoId + "-" + index);
    }
    
    //서버가 BID_DEMO_STARTED를 보내면 모든 브라우저가 자기 화면에서 똑같은 개수의 공을 생성한다.
    function startBidDemoVisualization(demoId, requestCount) {
        const normalizedRequestCount = Number(requestCount);
        if (!demoId || !Number.isSafeInteger(normalizedRequestCount) || normalizedRequestCount < 1) {
            return;
        }
        
        //같은 START 이벤트가 중복으로 와도 다시 생성하지 않는다.
        if (activeBidDemoId === demoId && activeBidDemoRequestIds.length === normalizedRequestCount) {
            return;
        }
        resetBidFlowVisualization();
        activeBidDemoId = demoId;
        activeBidDemoRequestIds = [];
        const requestDefinitions = [];
        for (let index = 0; index < normalizedRequestCount; index++) {
            const visualRequestId = createBidDemoVisualRequestId(demoId, index);
            activeBidDemoRequestIds.push(visualRequestId);
            enqueueBidFlowRequest(visualRequestId, true);
            requestDefinitions.push({
                requestId: visualRequestId
            });
        }
        updateBidFlowTokenDensity();
        updateBidFlowCounters();
        const animationGeneration = bidFlowGeneration;
        activeBidDemoSpawnPromise = playBidFlowDemoSpawnSequence(requestDefinitions, animationGeneration).catch(function (error) {
            console.error("[BID DEMO VISUAL START FAILED]", error);
        });
    }
    
    //서버가 BID_DEMO_FINISHED를 보내면 모든 브라우저에서 동일한 공을 동일한 SUCCESS / REJECTED 수로 처리한다.
    function finishBidDemoVisualization(demoId, successCount, rejectedCount) {
        if (!demoId || activeBidDemoId !== demoId) {
            return;
        }
        const totalCount = activeBidDemoRequestIds.length;
        let normalizedSuccessCount = Number(successCount);
        let normalizedRejectedCount = Number(rejectedCount);
        if (!Number.isSafeInteger(normalizedSuccessCount) || normalizedSuccessCount < 0) {
            normalizedSuccessCount = 0;
        }
        if (!Number.isSafeInteger(normalizedRejectedCount) || normalizedRejectedCount < 0) {
            normalizedRejectedCount = 0;
        }
        normalizedSuccessCount = Math.min(normalizedSuccessCount, totalCount);
        
        //서버에서 받은 성공 + 거절 합계가 공 개수와 다르면 나머지는 거절로 맞춘다.
        if (normalizedSuccessCount + normalizedRejectedCount !== totalCount) {
            normalizedRejectedCount = totalCount - normalizedSuccessCount;
        }
        activeBidDemoRequestIds.forEach(function (requestId, index) {
            if (index < normalizedSuccessCount) {
                resolveBidFlowRequest(requestId, "SUCCESS", "DEMO_SUCCESS");
                return;
            }
            resolveBidFlowRequest(requestId, "REJECTED", "DEMO_REJECTED");
        });
        updateBidFlowCounters();
    }
    
    //시연 시작/종료용 Controller 호출
    async function sendBidDemoControlRequest(requestUrl, requestValues) {
        const requestBody = new URLSearchParams();
        Object.keys(requestValues).forEach(function (key) {
            requestBody.set(key, String(requestValues[key]));
        });
        const response = await fetch(requestUrl, {
            method: "POST",
            credentials: "same-origin",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Accept": "application/json"
            },
            body: requestBody.toString()
        });
        let resultData = null;
        try {
            resultData = await response.json();
        }
        catch (error) {
            console.error("[BID DEMO CONTROL INVALID JSON]", error);
        }
        if (!response.ok || !resultData || resultData.result !== "SUCCESS") {
            const requestError = new Error("\uB3D9\uC2DC \uC785\uCC30 \uC2DC\uC5F0 \uB3D9\uAE30\uD654 \uC694\uCCAD \uC2E4\uD328");
            requestError.result = resultData ? resultData.result : "UNKNOWN_ERROR";
            requestError.remainingMillis = resultData ? Number(resultData.remainingMillis) : 0;
            throw requestError;
        }
        return resultData;
    }
    
    function readBidDemoRequestCount() {
        if (!bidDemoRequestCountInput) {
            return BID_DEMO_DEFAULT_REQUEST_COUNT;
        }
        const requestCountText = bidDemoRequestCountInput.value.trim();
        if (!/^[0-9]+$/.test(requestCountText)) {
            return null;
        }
        const requestCount = Number(requestCountText);
        if (!Number.isSafeInteger(requestCount) || requestCount < 1) {
            return null;
        }
        return requestCount;
    }
    
    function clearBidDemoCooldownTimer() {
        if (bidDemoCooldownIntervalId !== null) {
            window.clearInterval(bidDemoCooldownIntervalId);
            bidDemoCooldownIntervalId = null;
        }
    }
    
    function clearBidDemoRunningTimeout() {
        if (bidDemoRunningTimeoutId !== null) {
            window.clearTimeout(bidDemoRunningTimeoutId);
            bidDemoRunningTimeoutId = null;
        }
    }
    
    function lockBidDemoControls(buttonText) {
        if (bidDemoBatchButton) {
            bidDemoBatchButton.disabled = true;
            if (buttonText) {
                bidDemoBatchButton.textContent = buttonText;
            }
        }
        if (bidDemoRequestCountInput) {
            bidDemoRequestCountInput.disabled = true;
        }
    }
    
    function releaseBidDemoControls() {
        clearBidDemoCooldownTimer();
        clearBidDemoRunningTimeout();
        bidDemoUiState = "READY";
        bidDemoCooldownEndsAt = 0;
        if (bidDemoBatchButton) {
            bidDemoBatchButton.disabled = false;
        }
        if (bidDemoRequestCountInput) {
            bidDemoRequestCountInput.disabled = false;
        }
        updateBidDemoButtonLabel();
    }
    
    function setBidDemoStartingUi() {
        clearBidDemoCooldownTimer();
        clearBidDemoRunningTimeout();
        bidDemoUiState = "STARTING";
        bidDemoCooldownEndsAt = 0;
        lockBidDemoControls("\uC2DC\uC5F0 \uC2DC\uC791 \uD655\uC778 \uC911...");
    }
    
    function setBidDemoRunningUi() {
        clearBidDemoCooldownTimer();
        clearBidDemoRunningTimeout();
        bidDemoUiState = "RUNNING";
        bidDemoCooldownEndsAt = 0;
        lockBidDemoControls("\uC2DC\uC5F0 \uC9C4\uD589 \uC911...");
        
        //FINISH 이벤트가 오지 않는 비정상 상황에서도 서버의 RUNNING 만료시간과 맞춰 영구 잠금을 방지한다.
        bidDemoRunningTimeoutId = window.setTimeout(function () {
            if (bidDemoUiState === "RUNNING") {
                releaseBidDemoControls();
            }
        }, BID_DEMO_RUNNING_TIMEOUT_MS + 500);
    }
    
    function startBidDemoCooldown(cooldownMilliseconds) {
        if (bidDemoUiState === "COOLDOWN" && bidDemoCooldownEndsAt > Date.now()) {
            return;
        }
        clearBidDemoCooldownTimer();
        clearBidDemoRunningTimeout();
        let normalizedCooldown = Number(cooldownMilliseconds);
        if (!Number.isFinite(normalizedCooldown) || normalizedCooldown < 0) {
            normalizedCooldown = BID_DEMO_COOLDOWN_MS;
        }
        bidDemoUiState = "COOLDOWN";
        bidDemoCooldownEndsAt = Date.now() + normalizedCooldown;
        lockBidDemoControls("\uB2E4\uC2DC \uC2DC\uC5F0 \uAC00\uB2A5\uAE4C\uC9C0 5\uCD08");
        
        function renderCooldown() {
            const remainingMilliseconds = Math.max(0, bidDemoCooldownEndsAt - Date.now());
            if (remainingMilliseconds <= 0) {
                releaseBidDemoControls();
                return;
            }
            const remainingSeconds = Math.ceil(remainingMilliseconds / 1000);
            if (bidDemoBatchButton) {
                bidDemoBatchButton.textContent = "\uB2E4\uC2DC \uC2DC\uC5F0 \uAC00\uB2A5\uAE4C\uC9C0 " + remainingSeconds + "\uCD08";
            }
        }
        renderCooldown();
        bidDemoCooldownIntervalId = window.setInterval(renderCooldown, 200);
    }
    
    function syncBidDemoUiFromSnapshot(snapshot) {
        if (!snapshot) {
            return;
        }
        if (snapshot.demoState === "RUNNING") {

			//이미 WebSocket으로 RUNNING 상태라면 500ms polling마다 타이머를 다시 만들 필요가 없다.
            if (bidDemoUiState !== "RUNNING") {
                setBidDemoRunningUi();
            }
            return;
        }
        if (snapshot.demoState === "COOLDOWN") {
            if (snapshot.demoRemainingMillis > 0) {
                startBidDemoCooldown(snapshot.demoRemainingMillis);
            }
            return;
        }
        
        /*
         * READY는 일반적인 신규 접속 상태다.
         *
         * STARTING이나 RUNNING을 READY 응답 하나로 강제로 풀면
         * START 직전 발생했던 오래된 /realtime 응답이 뒤늦게 도착해
         * 버튼을 잘못 활성화할 수 있으므로 여기서는 건드리지 않는다.
         *
         * COOLDOWN 종료는 기존 countdown timer가 직접 READY로 돌린다.
         */
    }
    
    function updateBidDemoButtonLabel() {
        if (!bidDemoBatchButton || bidDemoBatchButton.disabled) {
            return;
        }
        const requestCount = readBidDemoRequestCount();
        bidDemoBatchButton.textContent = requestCount === null ? "\uC2DC\uC5F0 \uC694\uCCAD \uC218\uB97C \uD655\uC778\uD558\uC138\uC694" : "\uB3D9\uC2DC \uC694\uCCAD " + requestCount + "\uAC74 \uC2DC\uC5F0";
    }
    
    //시연 공을 1개씩 화면에 발사한다. HTTP 요청의 동시성과는 별개
    async function playBidFlowDemoSpawnSequence(requestDefinitions, animationGeneration) {
        const flightPromises = [];
        for (let index = 0; index < requestDefinitions.length; index++) {
            if (animationGeneration !== bidFlowGeneration) {
                break;
            }
            const requestId = requestDefinitions[index].requestId;
            const visualState = bidFlowVisualStateMap.get(requestId);
            if (visualState) {
                flightPromises.push(startBidFlowTokenFlight(requestId, visualState.pileIndex, animationGeneration));
            }
            await waitForBidFlowAnimation(BID_FLOW_SPAWN_INTERVAL_MS);
        }
        await Promise.all(flightPromises);
    }
    if (bidDemoRequestCountInput) {
        bidDemoRequestCountInput.value = String(BID_DEMO_DEFAULT_REQUEST_COUNT);
        bidDemoRequestCountInput.addEventListener("input", updateBidDemoButtonLabel);
    }
    updateBidDemoButtonLabel();
    if (bidDemoBatchButton) {
        bidDemoBatchButton.addEventListener("click", async function () {
            if (bidDemoBatchButton.disabled || !bidPriceInput) {
                return;
            }
            const demoRequestCount = readBidDemoRequestCount();
            if (demoRequestCount === null) {
                window.alert("\uC2DC\uC5F0 \uC694\uCCAD \uC218\uB294 1 \uC774\uC0C1\uC758 \uC815\uC218\uB85C \uC785\uB825\uD574 \uC8FC\uC138\uC694.");
                if (bidDemoRequestCountInput) {
                    bidDemoRequestCountInput.focus();
                }
                return;
            }
            const bidPrice = Number(bidPriceInput.value);
            if (!Number.isSafeInteger(bidPrice) || bidPrice <= 0) {
                window.alert("\uCD5C\uC2E0 \uC785\uCC30 \uAE08\uC561\uC744 \uD655\uC778\uD558\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.");
                return;
            }
            const confirmed = window.confirm(priceFormatter.format(bidPrice) + "\uC6D0\uC73C\uB85C \uC785\uCC30 \uC694\uCCAD " + demoRequestCount + "\uAC74\uC744 \uB3D9\uC2DC\uC5D0 \uBC1C\uC0DD\uC2DC\uD0A4\uACA0\uC2B5\uB2C8\uAE4C?\n" + "\uC2E4\uC81C \uC785\uCC30 1\uAC74\uC774 \uBC18\uC601\uB420 \uC218 \uC788\uC2B5\uB2C8\uB2E4.");
            if (!confirmed) {
                return;
            }
            if (typeof window.createAuctionBidRequestId !== "function") {
                console.error("[BID DEMO] \uC694\uCCAD \uC2DD\uBCC4\uBC88\uD638 \uC0DD\uC131 \uD568\uC218 \uC5C6\uC74C");
                window.alert("\uC785\uCC30 \uC694\uCCAD \uC2DD\uBCC4\uBC88\uD638 \uC0DD\uC131 \uAE30\uB2A5\uC744 \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.");
                return;
            }
            const demoId = window.createAuctionBidRequestId();
            async function loadBidDemoRealtimeSnapshotWithRetry(maxAttempts, delayMilliseconds) {
                let lastError = null;
                for (let attempt = 1; attempt <= maxAttempts; attempt++) {
                    try {
                        return await loadBidDemoRealtimeSnapshot();
                    }
                    catch (error) {
                        lastError = error;
                        console.warn("[BID DEMO REALTIME RETRY]" + " ATTEMPT=" + attempt + "/" + maxAttempts, error);
                        if (attempt < maxAttempts) {
                            await waitForBidFlowAnimation(delayMilliseconds);
                        }
                    }
                }
                throw lastError;
            }
            setBidDemoStartingUi();
            if (bidSubmitButton) {
                bidSubmitButton.disabled = true;
            }
            try {
                /*
                 * 시연 직전 DB의 실제 입찰 건수를 저장한다.
                 * HTTP 응답 개수가 아니라 DB 변화량으로
                 * 실제 성공 건수를 판단하기 위한 기준값이다.
                 */
                const demoStartRealtime = await loadBidDemoRealtimeSnapshotWithRetry(5, 300);
                const demoStartBidCount = demoStartRealtime.snapshot.bidCount;
                if (bidDemoBatchButton) {
                    bidDemoBatchButton.textContent = "\uB3D9\uC2DC \uC694\uCCAD \uC2DC\uC5F0 \uC900\uBE44 \uC911...";
                }
                /* 서버에서 동일 경매의 시연 실행권을 획득한다. */
                await sendBidDemoControlRequest(bidDemoStartUrl, {
                    A_NO: auctionNo,
                    DEMO_ID: demoId,
                    REQUEST_COUNT: demoRequestCount
                });
                setBidDemoRunningUi();
                /* 자기 WebSocket START가 늦게 도착하는 경우를 위한 fallback. */
                startBidDemoVisualization(demoId, demoRequestCount);
                const requestDefinitions = [];
                for (let requestIndex = 0; requestIndex < demoRequestCount; requestIndex++) {
                    requestDefinitions.push({
                        requestId: window.createAuctionBidRequestId()
                    });
                }
                
                const requestPromises = requestDefinitions.map(function (requestDefinition) {
                    const requestId = requestDefinition.requestId;
                    const requestBody = new URLSearchParams();
                    requestBody.set("A_NO", auctionNo);
                    requestBody.set("BID_PRICE", String(bidPrice));
                    requestBody.set("BID_REQUEST_ID", requestId);
                    return fetch(bidDemoSingleUrl, {
                        method: "POST",
                        credentials: "same-origin",
                        headers: {
                            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                            "Accept": "application/json"
                        },
                        body: requestBody.toString()
                    }).then(async function (response) {
                        let resultData = null;
                        try {
                            resultData = await response.json();
                        }
                        catch (parseError) {
                            resultData = {
                                result: "REJECTED",
                                requestId: requestId,
                                reason: "INVALID_RESPONSE"
                            };
                        }
                        return {
                            ok: response.ok,
                            data: resultData
                        };
                    }).catch(function (error) {
                        console.error("[BID DEMO SINGLE FAILED]", error);
                        return {
                            ok: false,
                            data: {
                                result: "REJECTED",
                                requestId: requestId,
                                reason: "REQUEST_ERROR"
                            }
                        };
                    });
                });
                const requestResults = await Promise.all(requestPromises);
                const demoEndRealtime = await loadBidDemoRealtimeSnapshotWithRetry(10, 300);
                const demoEndBidCount = demoEndRealtime.snapshot.bidCount;
                const successCount = Math.max(0, Math.min(demoRequestCount, demoEndBidCount - demoStartBidCount));
                const rejectedCount = demoRequestCount - successCount;
                console.log("[BID DEMO RESULT]", {
                    requestCount: demoRequestCount,
                    beforeBidCount: demoStartBidCount,
                    afterBidCount: demoEndBidCount,
                    success: successCount,
                    rejected: rejectedCount
                });
                applyRealtimeAuctionData(demoEndRealtime.rawData);
                const failedHttpCount = requestResults.filter(function (requestResult) {
                    return (!requestResult.ok);
                }).length;
                if (failedHttpCount > 0) {
                    console.warn("[BID DEMO HTTP ERROR COUNT]", failedHttpCount);
                }
                await activeBidDemoSpawnPromise;
                let finishBroadcastSucceeded = true;
                try {
                    await sendBidDemoControlRequest(bidDemoFinishUrl, {
                        A_NO: auctionNo,
                        DEMO_ID: demoId,
                        SUCCESS_COUNT: successCount,
                        REJECTED_COUNT: rejectedCount
                    });
                }
                catch (error) {
                    finishBroadcastSucceeded = false;
                    console.error("[BID DEMO FINISH BROADCAST FAILED]", error);
                }
                finishBidDemoVisualization(demoId, successCount, rejectedCount);
                startBidDemoCooldown(BID_DEMO_COOLDOWN_MS);
                await refreshRealtimeAuction();
                if (!finishBroadcastSucceeded) {
                    console.warn("[BID DEMO] FINISH WebSocket \uB3D9\uAE30\uD654 \uC2E4\uD328");
                }
                await waitForBidFlowAnimation(1000);
            }
            catch (error) {
                console.error("[BID DEMO FAILED]", error);
                if (error && error.result === "DEMO_ALREADY_RUNNING") {
                    setBidDemoRunningUi();
                    window.alert("\uD604\uC7AC \uC774 \uACBD\uB9E4\uC5D0\uC11C \uB2E4\uB978 \uB3D9\uC2DC \uC694\uCCAD \uC2DC\uC5F0\uC774 \uC9C4\uD589 \uC911\uC785\uB2C8\uB2E4.");
                }
                else if (error && error.result === "DEMO_COOLDOWN") {
                    startBidDemoCooldown(error.remainingMillis);
                    window.alert("\uC774 \uACBD\uB9E4\uB294 \uBC29\uAE08 \uC2DC\uC5F0\uC774 \uC885\uB8CC\uB418\uC5B4 \uC7A0\uC2DC \uD6C4 \uB2E4\uC2DC \uC2DC\uC5F0\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.");
                }
                else {
                    if (bidDemoUiState === "STARTING") {
                        releaseBidDemoControls();
                    }
                    window.alert("\uB3D9\uC2DC \uC694\uCCAD \uC2DC\uC5F0 \uCC98\uB9AC \uC911 \uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4.");
                }
            }
            finally {
                //시연 버튼/요청 수 입력창은 READY/RUNNING/COOLDOWN 상태 함수가 관리한다.
                if (bidSubmitButton) {
                    bidSubmitButton.disabled = false;
                }
                if (bidDemoUiState === "READY") {
                    updateBidDemoButtonLabel();
                }
            }
        });
    }
    
    /*
     * =========================
     * WebSocket
     * 마이페이지의 연결·재연결 구조를 동일하게 적용
     * =========================
     */
    let auctionWebSocket = null;
    let auctionWebSocketReconnectTimerId = null;
    let auctionWebSocketClosedByPage = false;
    
    function parseAuctionWebSocketMessage(rawMessage) {
        const messageParts = String(rawMessage).split("|");
        const parsedMessage = { type: messageParts[0] || "", values: {} };
        for (let index = 1; index < messageParts.length; index++) {
            const messagePart = messageParts[index];
            const equalsIndex = messagePart.indexOf("=");
            if (equalsIndex <= 0) {
                continue;
            }
            const key = messagePart.substring(0, equalsIndex);
            const value = messagePart.substring(equalsIndex + 1);
            parsedMessage.values[key] = value;
        }
        return parsedMessage;
    }
    
    function runBidFlowSafely(actionName, action) {
        try {
            action();
        }
        catch (error) {
            console.error("[AUCTION BID FLOW FAILED] ACTION=" + actionName, error);
        }
    }
    
    function handleAuctionWebSocketMessage(event) {
        const parsedMessage = parseAuctionWebSocketMessage(event.data);
        const messageType = parsedMessage.type;
        const messageValues = parsedMessage.values;
        console.log("[AUCTION WS MESSAGE]", String(event.data));
        const messageAuctionNo = messageValues.A_NO == null ? null : String(messageValues.A_NO);
        if (messageAuctionNo !== null && messageAuctionNo !== String(auctionNo)) {
            console.warn("[AUCTION WS MESSAGE IGNORED] " + "CURRENT_A_NO=" + auctionNo + ", MESSAGE_A_NO=" + messageAuctionNo);
            return;
        }
        if (messageType === "BID_DEMO_STARTED") {
            //팝업이 닫혀 있어도 같은 경매 상세페이지라면 시연 버튼은 즉시 잠근다.
            setBidDemoRunningUi();
            if (bidDialog && bidDialog.open) {
                runBidFlowSafely("BID_DEMO_STARTED", function () {
                    startBidDemoVisualization(messageValues.DEMO_ID, Number(messageValues.COUNT));
                });
            }
            return;
        }
        if (messageType === "BID_DEMO_FINISHED") {
            if (bidDialog && bidDialog.open) {
                runBidFlowSafely("BID_DEMO_FINISHED", function () {
                    finishBidDemoVisualization(messageValues.DEMO_ID, Number(messageValues.SUCCESS), Number(messageValues.REJECTED));
                });
            }
            startBidDemoCooldown(Number(messageValues.COOLDOWN_MS));
            return;
        }
        if (messageType === "BID_FLOW_REQUESTED") {
            if (bidDialog && bidDialog.open) {
                runBidFlowSafely("BID_FLOW_REQUESTED", function () {
                    enqueueBidFlowRequest(messageValues.REQUEST_ID, false);
                });
            }
            return;
        }
        if (messageType === "BID_FLOW_RESOLVED") {
            if (bidDialog && bidDialog.open) {
                runBidFlowSafely("BID_FLOW_RESOLVED", function () {
                    resolveBidFlowRequest(messageValues.REQUEST_ID, messageValues.RESULT, messageValues.REASON);
                });
            }
            
            //성공 결과 이벤트도 즉시 최신값을 조회한다. 뒤의 BID_UPDATED 메시지가 유실돼도 화면이 멈추지 않는다.
            if (messageValues.RESULT === "SUCCESS") {
                refreshRealtimeAuction("BID_FLOW_SUCCESS");
            }
            return;
        }
        if (messageType === "BID_UPDATED") {
            refreshRealtimeAuction("BID_UPDATED");
            return;
        }
        if (messageType === "AUCTION_ENDED") {
            refreshRealtimeAuction("AUCTION_ENDED");
            return;
        }
        if (messageType === "AUCTION_CANCELED") {
            window.alert("\uAD00\uB9AC\uC790\uC5D0 \uC758\uD574 \uACBD\uB9E4\uAC00 " + "\uCDE8\uC18C\uB418\uC5C8\uC2B5\uB2C8\uB2E4.");
            window.location.reload();
        }
    }
    
    function scheduleAuctionWebSocketReconnect() {
        if (auctionWebSocketClosedByPage || auctionWebSocketReconnectTimerId !== null) {
            return;
        }
        console.log("[AUCTION WS RECONNECT SCHEDULED] " + AUCTION_WS_RECONNECT_DELAY_MS + "ms");
        auctionWebSocketReconnectTimerId = window.setTimeout(function () {
            auctionWebSocketReconnectTimerId = null;
            connectAuctionWebSocket();
        }, AUCTION_WS_RECONNECT_DELAY_MS);
    }
    
    function connectAuctionWebSocket() {
        if (auctionWebSocketClosedByPage) {
            return;
        }
        if (auctionWebSocket && (auctionWebSocket.readyState === WebSocket.OPEN || auctionWebSocket.readyState === WebSocket.CONNECTING)) {
            return;
        }
        console.log("[AUCTION WS CONNECTING]", webSocketUrl);
        const socket = new WebSocket(webSocketUrl);
        auctionWebSocket = socket;
        window.auctionWebSocket = socket;
        socket.addEventListener("open", function () {
            if (socket !== auctionWebSocket) {
                return;
            }
            console.log("[AUCTION WS OPEN] A_NO=" + auctionNo);
            
            //최초 연결·재연결 중 놓친 이벤트를 서버 최신값으로 즉시 보정한다.
            refreshRealtimeAuction("WEBSOCKET_OPEN");
        });
        socket.addEventListener("message", function (event) {
            if (socket !== auctionWebSocket) {
                return;
            }
            handleAuctionWebSocketMessage(event);
        });
        socket.addEventListener("close", function (event) {
            if (socket !== auctionWebSocket) {
                return;
            }
            console.log("[AUCTION WS CLOSE] CODE=" + event.code + ", REASON=" + event.reason);
            auctionWebSocket = null;
            window.auctionWebSocket = null;
            scheduleAuctionWebSocketReconnect();
        });
        socket.addEventListener("error", function (event) {
            if (socket !== auctionWebSocket) {
                return;
            }
            console.error("[AUCTION WS ERROR]", event);
            try {
                socket.close();
            }
            catch (error) {
                console.error("[AUCTION WS CLOSE FAILED]", error);
                scheduleAuctionWebSocketReconnect();
            }
        });
    }
    connectAuctionWebSocket();
    startRealtimePolling();
    refreshRealtimeAuction("INITIAL");
    
    document.addEventListener("visibilitychange", function () {
        if (document.visibilityState === "visible") {
            refreshRealtimeAuction("VISIBILITY");
            connectAuctionWebSocket();
        }
    });
    
    window.addEventListener("beforeunload", function () {
        auctionWebSocketClosedByPage = true;
        stopRealtimePolling();
        if (auctionWebSocketReconnectTimerId !== null) {
            window.clearTimeout(auctionWebSocketReconnectTimerId);
            auctionWebSocketReconnectTimerId = null;
        }
        if (auctionWebSocket && (auctionWebSocket.readyState === WebSocket.OPEN || auctionWebSocket.readyState === WebSocket.CONNECTING)) {
            auctionWebSocket.close();
        }
    });
}, {
    once: true
});
</script>

<%
	}
%>

</body>
</html>