<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>

<%!
	private String escapeHtml(String value) {
		if (value == null) { return ""; }
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}

	private String statusText(String status) {
		if ("ONGOING".equals(status)) { return "진행중"; }
		if ("SOLD".equals(status)) { return "낙찰"; }
		if ("UNSOLD".equals(status) || "CANCELED".equals(status)) { return "미낙찰"; }
		return "상태 확인";
	}

	private String statusClass(String status) {
		if ("ONGOING".equals(status)) { return "ongoing"; }
		if ("SOLD".equals(status)) { return "sold"; }
		if ("UNSOLD".equals(status) || "CANCELED".equals(status)) { return "unsold"; }
		return "unknown";
	}
	private String statusReasonText(String status) {
		if ("UNSOLD".equals(status)) { return "입찰자 없음"; }
		if ("CANCELED".equals(status)) { return "관리자 취소"; }
		return "";
	}

	private String priceLabel(String status) {
		if ("SOLD".equals(status)) { return "낙찰가"; }
		if ("UNSOLD".equals(status)) { return "시작가"; }
		if ("CANCELED".equals(status)) { return "최종가"; }
		return "현재가";
	}
%>

<%
	DataSet registerAuctionHistoryList = (DataSet) request.getAttribute("REGISTER_AUCTION_HISTORY_LIST");

	int auctionCount = 0;

	List<Integer> ongoingAuctionIndexes = new ArrayList<>();
	List<Integer> endedAuctionIndexes = new ArrayList<>();

	if (registerAuctionHistoryList != null) {
		auctionCount = registerAuctionHistoryList.getCount("A_NO");

		for (int i = 0; i < auctionCount; i++) {
			String auctionStatus = registerAuctionHistoryList.getText("A_STATUS", i);

			if ("ONGOING".equals(auctionStatus)) {
				ongoingAuctionIndexes.add(i);
			} else {
				endedAuctionIndexes.add(i);
			}
		}
	}
	
	int ongoingAuctionCount = ongoingAuctionIndexes.size();
	int endedAuctionCount = endedAuctionIndexes.size();
	
	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>


<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>경매 등록 내역</title>
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/sidebar.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/auctionRealtime.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/registerHistory.css">
</head>

<body
	class="mypage-body register-auction-history-page"
	data-context-path="${pageContext.request.contextPath}">

<jsp:include page="/view/common/header.jsp" />

<main class="mypage-main">

	<div class="mypage-layout">

		<jsp:include page="/view/member/myPage/common/sidebar.jsp" />

		<section class="mypage-content">

			<div class="mypage-content-header register-history-header">
				<div>
					<h1 class="mypage-page-title">경매 등록 내역</h1>
					<p class="mypage-page-description">내가 등록한 경매 상품과 진행 상태를 확인합니다.</p>
				</div>
				<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/register" class="register-auction-button">경매 등록하기</a>
			</div>

			<div class="register-history-summary">
				<p class="register-history-count">총 <strong><%= auctionCount %></strong>건</p>
			</div>
			
			<%
				if (auctionCount == 0) {
			%>
				<div class="register-history-empty">
					<strong class="register-history-empty-title">등록한 경매가 없습니다.</strong>
					<p class="register-history-empty-text">경매 상품을 등록하면 이곳에서 진행 상태를 확인할 수 있습니다.</p>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/registerForm" class="register-history-empty-button">경매 등록하기</a>
				</div>
			<%
				} else {
			
					for (int sectionIndex = 0; sectionIndex < 2; sectionIndex++) {
						boolean ongoingSection = sectionIndex == 0;
						List<Integer> sectionAuctionIndexes = ongoingSection ? ongoingAuctionIndexes : endedAuctionIndexes;
						String sectionTitle = ongoingSection ? "진행 중인 경매" : "종료된 경매";
						String sectionDescription = ongoingSection ? "현재 입찰이 진행 중인 등록 경매입니다." : "낙찰, 유찰 또는 관리자 취소로 종료된 경매입니다.";
						String emptyMessage = ongoingSection ? "현재 진행 중인 등록 경매가 없습니다." : "종료된 등록 경매가 없습니다.";
			%>
				<section class="register-history-section <%= ongoingSection ? "ongoing-section" : "ended-section" %>">
			
					<div class="register-history-section-header">
						<div>
							<h2 class="register-history-section-title"><%= sectionTitle %> : <span class="register-history-section-count"><%= sectionAuctionIndexes.size() %>건</span></h2>
							<p class="register-history-section-description"><%= sectionDescription %></p>
						</div>
					</div>
			
					<%
						if (sectionAuctionIndexes.isEmpty()) {
					%>
						<div class="register-history-section-empty">
							<%= emptyMessage %>
						</div>
					<%
						} else {
					%>
			
						<div class="register-history-table-wrap">
			
							<table class="register-history-table">
			
								<colgroup>
									<col class="register-history-col-product">
									<col class="register-history-col-created">
									<col class="register-history-col-start-price">
									<col class="register-history-col-current-price">
									<col class="register-history-col-bid-count">
									<col class="register-history-col-status">
									<col class="register-history-col-end-date">
									<col class="register-history-col-detail">
								</colgroup>
			
								<thead>
									<tr>
										<th scope="col">상품</th>
										<th scope="col">등록일</th>
										<th scope="col">시작가</th>
										<th scope="col">현재가/낙찰가</th>
										<th scope="col">입찰</th>
										<th scope="col">상태</th>
										<th scope="col">종료일</th>
										<th scope="col">관리</th>
									</tr>
								</thead>

								<tbody>
									<%
										for (int listIndex = 0; listIndex < sectionAuctionIndexes.size(); listIndex++) {
											
											int i = sectionAuctionIndexes.get(listIndex);
											
											long auctionNo =registerAuctionHistoryList.getLong("A_NO", i);
											String auctionTitle = registerAuctionHistoryList.getText("A_TITLE", i);
											long auctionStartPrice = registerAuctionHistoryList.getLong("A_START_PRICE", i);
											long auctionCurrentPrice = registerAuctionHistoryList.getLong("A_CURRENT_PRICE", i);
											long auctionBidCount = registerAuctionHistoryList.getLong("A_BID_COUNT", i);
											String auctionStatus = registerAuctionHistoryList.getText("A_STATUS", i);
											String auctionAdminReason = registerAuctionHistoryList.getText("A_ADMIN_REASON", i);
											String createdDatetime = registerAuctionHistoryList.getText("CREATED_DATETIME", i);
											String auctionEndDatetime = registerAuctionHistoryList.getText("A_END_DATETIME", i);
											String imageStoredName = registerAuctionHistoryList.getText("IMG_STORED_NAME", i);
											String displayStatusText = statusText(auctionStatus);
											String displayStatusClass = statusClass(auctionStatus);
											String displayStatusReason = statusReasonText(auctionStatus);
											String displayPriceLabel = priceLabel(auctionStatus);
			
											long displayPrice = "UNSOLD".equals(auctionStatus) ? auctionStartPrice : auctionCurrentPrice;
									%>
										<tr
											class="<%= ongoingSection ? "mypage-auction-realtime-item" : "" %>"
											data-auction-no="<%= auctionNo %>"
											data-auction-status="<%= escapeHtml(auctionStatus) %>"
											<%= ongoingSection ? "data-auction-realtime-item=\"true\"" : "" %>>
			
											<td class="register-history-product-cell">
			
												<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="register-history-product-link">
			
													<div class="register-history-image-box">

														<%
															if (imageStoredName != null && !imageStoredName.isBlank()) {
														%>
															<img
																src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>"
																alt="<%= escapeHtml(auctionTitle) %>" class="register-history-image">
														<%
															} else {
														%>
															<div class="register-history-image-placeholder">
																NO IMAGE
															</div>
														<%
															}
														%>
													</div>
			
													<div class="register-history-product-info">
														<span class="register-history-auction-number">NO. <%= auctionNo %></span>
														<strong class="register-history-product-title"><%= escapeHtml(auctionTitle) %></strong>
													</div>
												</a>
											</td>
			
											<td class="register-history-date-cell">
												<%= escapeHtml(createdDatetime) %>
											</td>
			
											<td class="register-history-price-cell">
												<strong><%= priceFormat.format(auctionStartPrice) %>원</strong>
											</td>
			
											<td class="register-history-price-cell current">
												<span class="register-history-price-label"><%= escapeHtml(displayPriceLabel) %></span>
												<strong data-realtime-current-price><%= priceFormat.format(displayPrice) %>원</strong>
											</td>
			
											<td class="register-history-bid-cell">
												<strong data-realtime-bid-count><%= auctionBidCount %></strong>건
											</td>
			
											<td class="register-history-status-cell">
												<div class="register-history-status-content">
													<span class="register-history-status <%= displayStatusClass %>"><%= escapeHtml(displayStatusText) %></span>
													<%
														if (displayStatusReason != null && !displayStatusReason.isBlank()) {
													%>
														<span class="register-history-status-reason"><%= escapeHtml(displayStatusReason) %></span>
													<%
														}

														if ("CANCELED".equals(auctionStatus) && auctionAdminReason != null && !auctionAdminReason.isBlank()) {
													%>
														<span class="register-history-status-detail" title="<%= escapeHtml(auctionAdminReason) %>"><%= escapeHtml(auctionAdminReason) %></span>
													<%
														}
													%>
												</div>
											</td>
			
											<td class="register-history-date-cell">
												<%= escapeHtml(auctionEndDatetime) %>
											</td>
											
											<td>
												<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="register-history-detail-button">상세보기</a>
											</td>
										</tr>
									<%
										}
									%>
								</tbody>
							</table>
						</div>
					<%
						}
					%>
				</section>
			<%
					}
				}
			%>
		</section>
	</div>
</main>

<jsp:include page="/view/common/footer.jsp" />

<script type="text/javascript">
(function () {

	"use strict";

	/* =========================
	   초기화
	   ========================= */

	function initializeMyPageAuctionRealtime() {

		const realtimeItemElements = document.querySelectorAll('[data-auction-realtime-item="true"][data-auction-no]');

		if (realtimeItemElements.length === 0) {
			return;
		}

		const contextPath = document.body.dataset.contextPath || "";
		const priceFormatter = new Intl.NumberFormat("ko-KR");
		const webSocketProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
		const auctionItemMap = new Map();
		const webSocketStateMap = new Map();
		const realtimeRequestSequenceMap = new Map();
		const priceAnimationFrameMap = new WeakMap();
		const bidCountAnimationQueueMap = new WeakMap();
		const bidCountValueMap = new WeakMap();

		let pageClosing = false;


		/* =========================
		   공통 숫자 처리
		   ========================= */
		function readDisplayedNumber(element) {
			if (!element) {
				return 0;
			}
			const numberText = element.textContent.replace(/[^0-9]/g, "");
			const parsedNumber = Number(numberText);
			return Number.isFinite(parsedNumber) ? parsedNumber : 0;
		}

		function setFormattedPrice(element, price) {
			if (!element || !Number.isFinite(price)) {
				return;
			}
			element.textContent = priceFormatter.format(price) + "원";
		}


		/* =========================
		   현재가 카운트업
		   ========================= */
		function animatePriceCountUp(element, endPrice) {
			
			if ( !element || !Number.isFinite(endPrice)) {
				return;
			}

			const runningFrameId = priceAnimationFrameMap.get(element);
			if (runningFrameId !== undefined) {
				window.cancelAnimationFrame(runningFrameId);
				priceAnimationFrameMap.delete(element);
			}

			const startPrice = readDisplayedNumber(element);

			/*
			 * 현재가는 정상적인 입찰 흐름에서는 증가한다.
			 * 값이 같거나 더 작게 내려온 경우에는 효과 없이 서버의 확정값으로 바로 맞춘다.
			 */
			if (endPrice <= startPrice) {
				setFormattedPrice(element, endPrice);
				return;
			}

			const animationDuration = 850;
			let animationStartTime = null;

			function drawPriceFrame(currentTime) {

				if (animationStartTime === null) {
					animationStartTime = currentTime;
				}

				const elapsedTime = currentTime - animationStartTime;
				const progress = Math.min(elapsedTime / animationDuration, 1);

				//초반에는 빠르게 증가하고 마지막 가격 부근에서 부드럽게 감속하는 ease-out 곡선이다.
				const easedProgress = 1 - Math.pow(1 - progress, 3);
				const displayPrice = Math.round(startPrice + (endPrice - startPrice) * easedProgress);

				setFormattedPrice(element, displayPrice);

				if (progress < 1) {
					const nextFrameId = window.requestAnimationFrame(drawPriceFrame);
					priceAnimationFrameMap.set(element, nextFrameId);
					return;
				}

				//반올림 오차가 남지 않도록 마지막 프레임은 서버가 반환한 정확한 현재가로 고정한다.
				setFormattedPrice(element, endPrice);
				priceAnimationFrameMap.delete(element);
			}

			const firstFrameId = window.requestAnimationFrame(drawPriceFrame);
			priceAnimationFrameMap.set(element, firstFrameId);
		}


		/* =========================
		   입찰 건수 롤링
		   ========================= */
		function setBidCountImmediately(element, bidCount) {

			if (!element || !Number.isSafeInteger(bidCount)) {
				return;
			}
			
			element.textContent = String(bidCount);
			bidCountValueMap.set(element, bidCount);
		}

		async function runSingleBidCountRoll(element, startCount, endCount) {

			const oldValueElement = document.createElement("span");
			oldValueElement.className = "mypage-bid-count-roll-value";
			oldValueElement.textContent = String(startCount);

			const newValueElement = document.createElement("span");
			newValueElement.className = "mypage-bid-count-roll-value";
			newValueElement.textContent = String(endCount);

			const trackElement = document.createElement("span");
			trackElement.className = "mypage-bid-count-roll-track";
			trackElement.appendChild(oldValueElement);
			trackElement.appendChild(newValueElement);

			element.classList.add("mypage-bid-count-rolling");
			element.replaceChildren(trackElement);

			const oldValueRectangle = oldValueElement.getBoundingClientRect();
			const newValueRectangle = newValueElement.getBoundingClientRect();

			const rowHeight = Math.max(oldValueRectangle.height, newValueRectangle.height, 1);
			const rowWidth = Math.max(oldValueRectangle.width, newValueRectangle.width, 1);

			element.style.height = Math.ceil(rowHeight) + "px";
			element.style.minWidth = Math.ceil(rowWidth) + "px";

			const rollAnimation =
				trackElement.animate(
					[
						{
							transform: "translateY(0)"
						},
						{
							transform: "translateY(-" + rowHeight + "px)"
						}
					],
					{
						duration: 320, easing: "cubic-bezier(0.22, 1, 0.36, 1)", fill: "forwards"
					});

			try {
				await rollAnimation.finished;
			} catch (error) {
				console.debug("[MYPAGE BID COUNT ROLL CANCELED]", error);
			}

			element.classList.remove("mypage-bid-count-rolling");
			element.style.removeProperty("height");
			element.style.removeProperty("min-width");

			setBidCountImmediately(element, endCount);
		}

		function animateBidCountRoll(element, endCount) {

			if (!element || !Number.isSafeInteger(endCount)) {
				return;
			}

			const previousQueue = bidCountAnimationQueueMap.get(element) || Promise.resolve();
			const nextQueue = previousQueue.catch(function () {
				
						//이전 효과의 오류가 다음 실시간 갱신을 막지 않도록 큐를 계속 이어간다.
					}).then(async function () {

						const storedCount = bidCountValueMap.get(element);
						const startCount = Number.isSafeInteger(storedCount) ? storedCount : readDisplayedNumber(element);

						if (endCount <= startCount) {
							setBidCountImmediately(element, endCount);
							return;
						}

						/*
						 * 짧은 시간에 여러 건이 반영되면 3 → 4 → 5 순서로 한 칸씩 굴린다.
						 * 차이가 지나치게 크면 최종 숫자로 한 번만 이동한다.
						 */
						if (endCount - startCount > 5) {
							await runSingleBidCountRoll(element, startCount, endCount);
							return;
						}

						for (let count = startCount + 1; count <= endCount; count++) {
							await runSingleBidCountRoll(element, count - 1, count);
						}
					});

			bidCountAnimationQueueMap.set(element, nextQueue);
		}


		/* =========================
		   경매 항목 수집
		   ========================= */
		realtimeItemElements.forEach(
			function (itemElement) {

				const auctionNo = String(itemElement.dataset.auctionNo || "").trim();

				if (!/^[1-9][0-9]*$/.test(auctionNo)) {
					console.warn("[MYPAGE AUCTION REALTIME] 잘못된 경매번호", itemElement.dataset.auctionNo);
					return;
				}
				if (!auctionItemMap.has(auctionNo)) {
					auctionItemMap.set(auctionNo, []);
				}
				auctionItemMap.get(auctionNo).push(itemElement);

				const bidCountElement = itemElement.querySelector("[data-realtime-bid-count]");

				if (bidCountElement) {
					bidCountValueMap.set(bidCountElement, readDisplayedNumber(bidCountElement));
				}
			});

		if (auctionItemMap.size === 0) {
			return;
		}


		/* =========================
		   실시간 조회 결과 적용
		   ========================= */
		function applyRealtimeAuctionData(auctionNo, realtimeData) {

			if (!realtimeData) {
				return;
			}

			if (String(realtimeData.auctionNo) !== String(auctionNo)) {
				console.warn("[MYPAGE AUCTION REALTIME] 다른 경매 데이터", realtimeData);
				return;
			}

			const auctionStatus = realtimeData.status == null ? "" : String(realtimeData.status).trim().toUpperCase();

			//진행 상태가 끝났다면 현재가와 입찰 건수 외에도 상태 문구와 관리 버튼 구성이 바뀌므로 서버 렌더링을 다시 받아 화면 전체를 맞춘다.
			if (auctionStatus !== "ONGOING") {
				window.location.reload();
				return;
			}

			const currentPrice = Number(realtimeData.currentPrice);

			const bidCount = Number(realtimeData.bidCount);

			const itemElements = auctionItemMap.get(String(auctionNo)) || [];

			itemElements.forEach(function (itemElement) {
					const currentPriceElement = itemElement.querySelector("[data-realtime-current-price]");
					const bidCountElement = itemElement.querySelector("[data-realtime-bid-count]");

					if (Number.isFinite(currentPrice)) {
						animatePriceCountUp(currentPriceElement, currentPrice);
					}
					if (Number.isSafeInteger(bidCount)) {
						animateBidCountRoll(bidCountElement, bidCount);
					}
				});
		}


		async function refreshRealtimeAuction(auctionNo) {

			const previousSequence = realtimeRequestSequenceMap.get(auctionNo) || 0;
			const currentSequence = previousSequence + 1;

			realtimeRequestSequenceMap.set(auctionNo, currentSequence);

			const realtimeUrl = contextPath + "/api/auctionFlow/auction/realtime?A_NO=" + encodeURIComponent(auctionNo);

			try {
				const response = await fetch(realtimeUrl,
						{
							method: "GET",
							headers: {
								"Accept": "application/json"
							}, cache: "no-store"
						});

				if (!response.ok) {
					throw new Error("HTTP_STATUS_" + response.status);
				}

				const realtimeData = await response.json();

				if (currentSequence !== realtimeRequestSequenceMap.get(auctionNo)) {
					return;
				}

				applyRealtimeAuctionData(auctionNo, realtimeData);
			} catch (error) {
				console.error("[MYPAGE AUCTION REALTIME FAILED]" + " A_NO=" + auctionNo, error);
			}
		}


		/* =========================
		   WebSocket
		   ========================= */
		function parseWebSocketMessage(message) {
			const messageParts = String(message).split("|");
			const parsedMessage = {
				type: messageParts[0] || "",
				auctionNo: null
			};

			for (let index = 1; index < messageParts.length; index++) {
				const messagePart = messageParts[index];
				if (messagePart.startsWith("A_NO=")) {
					parsedMessage.auctionNo = messagePart.substring("A_NO=".length);
				}
			}
			return parsedMessage;
		}

		function scheduleReconnect(auctionNo) {

			if (pageClosing) {
				return;
			}

			const state = webSocketStateMap.get(auctionNo);

			if (!state || state.reconnectTimer !== null) {
				return;
			}

			state.reconnectTimer = window.setTimeout(function () {
						state.reconnectTimer = null;
						connectAuctionWebSocket(auctionNo);
					}, 2500);
		}


		function connectAuctionWebSocket(auctionNo) {
			if (pageClosing) {
				return;
			}

			const previousState = webSocketStateMap.get(auctionNo);

			if (previousState && previousState.socket && (previousState.socket.readyState === WebSocket.OPEN || previousState.socket.readyState === WebSocket.CONNECTING)) {
				return;
			}

			const webSocketUrl = webSocketProtocol + "//" + window.location.host + contextPath + "/ws/auction/" + encodeURIComponent(auctionNo);
			const auctionWebSocket = new WebSocket(webSocketUrl);

			const state = previousState || {
					socket: null, reconnectTimer: null
				};

			state.socket = auctionWebSocket;

			webSocketStateMap.set(auctionNo, state);

			auctionWebSocket.addEventListener("open", function () {
					//페이지가 열린 직후 또는 재연결 직후 놓친 입찰이 있을 수 있으므로 최신 상태를 한 번 동기화한다.
					refreshRealtimeAuction(auctionNo);
				});

			auctionWebSocket.addEventListener("message", function (event) {

					const parsedMessage = parseWebSocketMessage(event.data);

					if (parsedMessage.auctionNo !== null && String(parsedMessage.auctionNo) !== String(auctionNo)) {
						return;
					}

					if (parsedMessage.type === "BID_UPDATED") {
						refreshRealtimeAuction(auctionNo);
						return;
					}

					if (parsedMessage.type === "AUCTION_CANCELED") {
						window.location.reload();
					}
				});

			auctionWebSocket.addEventListener("close", function () {
					scheduleReconnect(auctionNo);
				});

			auctionWebSocket.addEventListener("error", function (event) {
					console.error("[MYPAGE AUCTION WS ERROR]" + " A_NO=" + auctionNo, event);
				});
		}

		auctionItemMap.forEach(function (itemElements, auctionNo) {
				connectAuctionWebSocket(auctionNo);
			});


		window.addEventListener("beforeunload", function () {

				pageClosing = true;

				webSocketStateMap.forEach(function (state) {

						if (state.reconnectTimer !== null) {
							window.clearTimeout(state.reconnectTimer);
						}

						if (state.socket && (state.socket.readyState === WebSocket.OPEN || state.socket.readyState === WebSocket.CONNECTING)) {
							state.socket.close();
						}
					});
			});
	}


	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", initializeMyPageAuctionRealtime);
	} else {
		initializeMyPageAuctionRealtime();
	}
})();
</script>

</body>
</html>