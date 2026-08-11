<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>
<%@ page import="java.text.DecimalFormat" %>

<%!
	private String escapeHtml(String value) {

		if (value == null) { return ""; }

		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}
	private String auctionStatusText(String status) {
		if ("ONGOING".equals(status)) { return "진행중"; }
		if ("SOLD".equals(status)) { return "낙찰"; }
		if ("UNSOLD".equals(status) || "CANCELED".equals(status)) { return "미낙찰"; }
		return "상태 확인";
	}

	private String auctionStatusClass(String status) {
		if ("ONGOING".equals(status)) { return "ongoing"; }
		if ("SOLD".equals(status)) { return "sold"; }
		if ("UNSOLD".equals(status) || "CANCELED".equals(status)) { return "unsold"; }
		return "unknown";
	}

	private String currentPriceLabel(String status) {
		if ("SOLD".equals(status)) { return "낙찰가"; }
		if ("CANCELED".equals(status)) { return "취소 시 가격"; }
		if ("UNSOLD".equals(status)) { return "최종가"; }
		return "현재가";
	}

	private String bidResultText(String status, String isHighestBidder) {

		boolean isHighest = "Y".equals(isHighestBidder);

		if ("ONGOING".equals(status)) { return isHighest ? "최고 입찰 중" : "최고 입찰 아님"; }
		if ("SOLD".equals(status)) { return isHighest ? "낙찰" : "패찰"; }
		if ("CANCELED".equals(status)) { return "경매 취소"; }
		if ("UNSOLD".equals(status)) { return "미낙찰"; }
		return "결과 확인";
	}


	private String bidResultClass(String status, String isHighestBidder) {

		boolean isHighest = "Y".equals(isHighestBidder);

		if ("ONGOING".equals(status)) { return isHighest ? "leading" : "outbid"; }
		if ("SOLD".equals(status)) { return isHighest ? "won" : "lost"; }
		if ("CANCELED".equals(status)) { return "canceled"; }
		if ("UNSOLD".equals(status)) { return "lost"; }
		return "unknown";
	}
%>

<%
	DataSet bidHistoryList = (DataSet) request.getAttribute("BID_HISTORY_LIST");

	int bidHistoryCount = 0;

	if (bidHistoryList != null) {

		bidHistoryCount = bidHistoryList.getCount("A_NO");
	}

	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>입찰 내역</title>
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/sidebar.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/auctionRealtime.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/bidHistory.css">
</head>

<body
	class="mypage-body bid-history-page"
	data-context-path="${pageContext.request.contextPath}">

<jsp:include page="/view/common/header.jsp" />

<main class="mypage-main">

	<div class="mypage-layout">

		<jsp:include page="/view/member/myPage/common/sidebar.jsp" />

		<section class="mypage-content">

			<div class="mypage-content-header">

				<h1 class="mypage-page-title">입찰 내역</h1>

				<p class="mypage-page-description">내가 참여한 경매와 현재 입찰 결과를 확인합니다.</p>
			</div>

			<div class="bid-history-summary">

				<p class="bid-history-count">총 <strong><%= bidHistoryCount %></strong>건</p>
			</div>

			<%
				if (bidHistoryCount == 0) {
			%>

				<div class="bid-history-empty">

					<strong class="bid-history-empty-title">입찰한 경매가 없습니다.</strong>

					<p class="bid-history-empty-text">관심 있는 경매에 입찰하면 이곳에서 결과를 확인할 수 있습니다.</p>

					<a href="${pageContext.request.contextPath}/api/auctionFlow/main" class="bid-history-empty-button">경매 둘러보기</a>
				</div>
			<%
				} else {
			%>

				<div class="bid-history-table-wrap">

					<table class="bid-history-table">

						<colgroup>
							<col class="bid-history-col-product">
							<col class="bid-history-col-my-price">
							<col class="bid-history-col-current-price">
							<col class="bid-history-col-count">
							<col class="bid-history-col-date">
							<col class="bid-history-col-status">
							<col class="bid-history-col-result">
							<col class="bid-history-col-management">
						</colgroup>

						<thead>
							<tr>
								<th scope="col">상품</th>
								<th scope="col">최고 입찰가</th>
								<th scope="col">현재</th>
								<th scope="col">나의 입찰횟수</th>
								<th scope="col">최근 입찰일</th>
								<th scope="col">경매상태</th>
								<th scope="col">나의 입찰결과</th>
								<th scope="col">관리</th>
							</tr>
						</thead>
						<tbody>

						<%
							for (int i = 0; i < bidHistoryCount; i++) {

								long auctionNo = bidHistoryList.getLong("A_NO", i);
								String auctionTitle = bidHistoryList.getText("A_TITLE", i);
								long myHighestBidPrice = bidHistoryList.getLong("MY_HIGHEST_BID_PRICE", i);
								long currentPrice = bidHistoryList.getLong("A_CURRENT_PRICE", i);
								long auctionBidCount = bidHistoryList.getLong("A_BID_COUNT", i);
								long myBidCount = bidHistoryList.getLong("MY_BID_COUNT", i);
								String myLastBidDatetime = bidHistoryList.getText("MY_LAST_BID_DATETIME", i);
								String auctionStatus = bidHistoryList.getText("A_STATUS", i);
								String isHighestBidder = bidHistoryList.getText("IS_HIGHEST_BIDDER", i);
								String auctionAdminReason = bidHistoryList.getText("A_ADMIN_REASON", i);
								String imageStoredName = bidHistoryList.getText("IMG_STORED_NAME", i);
								String displayAuctionStatus = auctionStatusText(auctionStatus);
								String displayAuctionStatusClass = auctionStatusClass(auctionStatus);
								String displayCurrentPriceLabel = currentPriceLabel(auctionStatus);
								String displayBidResult = bidResultText(auctionStatus, isHighestBidder);
								String displayBidResultClass = bidResultClass(auctionStatus, isHighestBidder);
						%>

							<tr
								class="<%= "ONGOING".equals(auctionStatus) ? "mypage-auction-realtime-item" : "" %>"
								data-auction-no="<%= auctionNo %>"
								data-auction-status="<%= escapeHtml(auctionStatus) %>"
								<%= "ONGOING".equals(auctionStatus) ? "data-auction-realtime-item=\"true\"" : "" %>>

								<td class="bid-history-product-cell">

									<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="bid-history-product-link">

										<div class="bid-history-image-box">

											<%
												if (imageStoredName != null && !imageStoredName.isBlank()) {
											%>

												<img src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>"
													 alt="<%= escapeHtml(auctionTitle) %>"
													 class="bid-history-image">

											<%
												} else {
											%>

												<div class="bid-history-image-placeholder">
													NO IMAGE
												</div>

											<%
												}
											%>
										</div>

										<div class="bid-history-product-info">

											<span class="bid-history-auction-number">
												NO. <%= auctionNo %>
											</span>

											<strong class="bid-history-product-title">
												<%= escapeHtml(auctionTitle) %>
											</strong>
										</div>
									</a>
								</td>

								<td class="bid-history-price-cell my-price">

									<strong>
										<%= priceFormat.format(myHighestBidPrice) %>원
									</strong>
								</td>

								<td class="bid-history-price-cell current-price">

									<span class="bid-history-price-label">
										<%= escapeHtml(displayCurrentPriceLabel) %>
									</span>

									<strong data-realtime-current-price><%= priceFormat.format(currentPrice) %>원</strong>

									<span class="bid-history-total-bid-count">
										전체 입찰 <span data-realtime-bid-count><%= auctionBidCount %></span>건
									</span>
								</td>

								<td class="bid-history-count-cell">

									<strong><%= myBidCount %></strong>회
								</td>

								<td class="bid-history-date-cell">

									<%= escapeHtml(myLastBidDatetime) %>
								</td>

								<td class="bid-history-status-cell">

									<span class="bid-history-status <%= displayAuctionStatusClass %>">

										<%= escapeHtml(displayAuctionStatus) %>
									</span>
								</td>

								<td class="bid-history-result-cell">

									<div class="bid-history-result-content">

										<span class="bid-history-result <%= displayBidResultClass %>">

											<%= escapeHtml(displayBidResult) %>
										</span>

										<%
											if ("CANCELED".equals(auctionStatus) && auctionAdminReason != null && !auctionAdminReason.isBlank()) {
										%>

											<span class="bid-history-result-reason" title="<%= escapeHtml(auctionAdminReason) %>">
												<%= escapeHtml(auctionAdminReason) %>
											</span>
										<%
											}
										%>
									</div>
								</td>

								<td>

									<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="bid-history-detail-button">상세보기</a>
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

		const realtimeItemElements =
			document.querySelectorAll(
				'[data-auction-realtime-item="true"][data-auction-no]'
			);

		if (realtimeItemElements.length === 0) {
			return;
		}

		const contextPath =
			document.body.dataset.contextPath || "";

		const priceFormatter =
			new Intl.NumberFormat("ko-KR");

		const webSocketProtocol =
			window.location.protocol === "https:"
				? "wss:"
				: "ws:";

		const auctionItemMap =
			new Map();

		const webSocketStateMap =
			new Map();

		const realtimeRequestSequenceMap =
			new Map();

		const priceAnimationFrameMap =
			new WeakMap();

		const bidCountAnimationQueueMap =
			new WeakMap();

		const bidCountValueMap =
			new WeakMap();

		let pageClosing = false;


		/* =========================
		   공통 숫자 처리
		   ========================= */

		function readDisplayedNumber(element) {

			if (!element) {
				return 0;
			}

			const numberText =
				element.textContent.replace(
					/[^0-9]/g,
					""
				);

			const parsedNumber =
				Number(numberText);

			return Number.isFinite(parsedNumber)
				? parsedNumber
				: 0;
		}


		function setFormattedPrice(
			element,
			price
		) {

			if (
				!element
				|| !Number.isFinite(price)
			) {
				return;
			}

			element.textContent =
				priceFormatter.format(price)
				+ "원";
		}


		/* =========================
		   현재가 카운트업
		   ========================= */

		function animatePriceCountUp(
			element,
			endPrice
		) {

			if (
				!element
				|| !Number.isFinite(endPrice)
			) {
				return;
			}

			const runningFrameId =
				priceAnimationFrameMap.get(element);

			if (runningFrameId !== undefined) {

				window.cancelAnimationFrame(
					runningFrameId
				);

				priceAnimationFrameMap.delete(
					element
				);
			}

			const startPrice =
				readDisplayedNumber(element);

			/*
			 * 현재가는 정상적인 입찰 흐름에서는 증가한다.
			 * 값이 같거나 더 작게 내려온 경우에는 효과 없이
			 * 서버의 확정값으로 바로 맞춘다.
			 */
			if (endPrice <= startPrice) {

				setFormattedPrice(
					element,
					endPrice
				);

				return;
			}

			const animationDuration = 850;
			let animationStartTime = null;

			function drawPriceFrame(currentTime) {

				if (animationStartTime === null) {
					animationStartTime = currentTime;
				}

				const elapsedTime =
					currentTime - animationStartTime;

				const progress =
					Math.min(
						elapsedTime / animationDuration,
						1
					);

				/*
				 * 초반에는 빠르게 증가하고 마지막 가격 부근에서
				 * 부드럽게 감속하는 ease-out 곡선이다.
				 */
				const easedProgress =
					1 - Math.pow(1 - progress, 3);

				const displayPrice =
					Math.round(
						startPrice
						+ (endPrice - startPrice)
						* easedProgress
					);

				setFormattedPrice(
					element,
					displayPrice
				);

				if (progress < 1) {

					const nextFrameId =
						window.requestAnimationFrame(
							drawPriceFrame
						);

					priceAnimationFrameMap.set(
						element,
						nextFrameId
					);

					return;
				}

				/*
				 * 반올림 오차가 남지 않도록 마지막 프레임은
				 * 서버가 반환한 정확한 현재가로 고정한다.
				 */
				setFormattedPrice(
					element,
					endPrice
				);

				priceAnimationFrameMap.delete(
					element
				);
			}

			const firstFrameId =
				window.requestAnimationFrame(
					drawPriceFrame
				);

			priceAnimationFrameMap.set(
				element,
				firstFrameId
			);
		}


		/* =========================
		   입찰 건수 롤링
		   ========================= */

		function setBidCountImmediately(
			element,
			bidCount
		) {

			if (
				!element
				|| !Number.isSafeInteger(bidCount)
			) {
				return;
			}

			element.textContent =
				String(bidCount);

			bidCountValueMap.set(
				element,
				bidCount
			);
		}


		async function runSingleBidCountRoll(
			element,
			startCount,
			endCount
		) {

			const oldValueElement =
				document.createElement("span");

			oldValueElement.className =
				"mypage-bid-count-roll-value";

			oldValueElement.textContent =
				String(startCount);

			const newValueElement =
				document.createElement("span");

			newValueElement.className =
				"mypage-bid-count-roll-value";

			newValueElement.textContent =
				String(endCount);

			const trackElement =
				document.createElement("span");

			trackElement.className =
				"mypage-bid-count-roll-track";

			trackElement.appendChild(
				oldValueElement
			);

			trackElement.appendChild(
				newValueElement
			);

			element.classList.add(
				"mypage-bid-count-rolling"
			);

			element.replaceChildren(
				trackElement
			);

			const oldValueRectangle =
				oldValueElement.getBoundingClientRect();

			const newValueRectangle =
				newValueElement.getBoundingClientRect();

			const rowHeight =
				Math.max(
					oldValueRectangle.height,
					newValueRectangle.height,
					1
				);

			const rowWidth =
				Math.max(
					oldValueRectangle.width,
					newValueRectangle.width,
					1
				);

			element.style.height =
				Math.ceil(rowHeight) + "px";

			element.style.minWidth =
				Math.ceil(rowWidth) + "px";

			const rollAnimation =
				trackElement.animate(
					[
						{
							transform:
								"translateY(0)"
						},
						{
							transform:
								"translateY(-"
								+ rowHeight
								+ "px)"
						}
					],
					{
						duration: 320,
						easing:
							"cubic-bezier(0.22, 1, 0.36, 1)",
						fill: "forwards"
					}
				);

			try {
				await rollAnimation.finished;
			} catch (error) {
				console.debug(
					"[MYPAGE BID COUNT ROLL CANCELED]",
					error
				);
			}

			element.classList.remove(
				"mypage-bid-count-rolling"
			);

			element.style.removeProperty(
				"height"
			);

			element.style.removeProperty(
				"min-width"
			);

			setBidCountImmediately(
				element,
				endCount
			);
		}


		function animateBidCountRoll(
			element,
			endCount
		) {

			if (
				!element
				|| !Number.isSafeInteger(endCount)
			) {
				return;
			}

			const previousQueue =
				bidCountAnimationQueueMap.get(element)
				|| Promise.resolve();

			const nextQueue =
				previousQueue
					.catch(function () {
						/*
						 * 이전 효과의 오류가 다음 실시간 갱신을
						 * 막지 않도록 큐를 계속 이어간다.
						 */
					})
					.then(async function () {

						const storedCount =
							bidCountValueMap.get(element);

						const startCount =
							Number.isSafeInteger(storedCount)
								? storedCount
								: readDisplayedNumber(element);

						if (endCount <= startCount) {

							setBidCountImmediately(
								element,
								endCount
							);

							return;
						}

						/*
						 * 짧은 시간에 여러 건이 반영되면
						 * 3 → 4 → 5 순서로 한 칸씩 굴린다.
						 * 차이가 지나치게 크면 최종 숫자로 한 번만 이동한다.
						 */
						if (endCount - startCount > 5) {

							await runSingleBidCountRoll(
								element,
								startCount,
								endCount
							);

							return;
						}

						for (
							let count = startCount + 1;
							count <= endCount;
							count++
						) {

							await runSingleBidCountRoll(
								element,
								count - 1,
								count
							);
						}
					});

			bidCountAnimationQueueMap.set(
				element,
				nextQueue
			);
		}


		/* =========================
		   경매 항목 수집
		   ========================= */

		realtimeItemElements.forEach(
			function (itemElement) {

				const auctionNo =
					String(
						itemElement.dataset.auctionNo || ""
					).trim();

				if (!/^[1-9][0-9]*$/.test(auctionNo)) {

					console.warn(
						"[MYPAGE AUCTION REALTIME] 잘못된 경매번호",
						itemElement.dataset.auctionNo
					);

					return;
				}

				if (!auctionItemMap.has(auctionNo)) {
					auctionItemMap.set(auctionNo, []);
				}

				auctionItemMap.get(auctionNo).push(
					itemElement
				);

				const bidCountElement =
					itemElement.querySelector(
						"[data-realtime-bid-count]"
					);

				if (bidCountElement) {

					bidCountValueMap.set(
						bidCountElement,
						readDisplayedNumber(
							bidCountElement
						)
					);
				}
			}
		);

		if (auctionItemMap.size === 0) {
			return;
		}


		/* =========================
		   실시간 조회 결과 적용
		   ========================= */

		function applyRealtimeAuctionData(
			auctionNo,
			realtimeData
		) {

			if (!realtimeData) {
				return;
			}

			if (
				String(realtimeData.auctionNo)
				!== String(auctionNo)
			) {

				console.warn(
					"[MYPAGE AUCTION REALTIME] 다른 경매 데이터",
					realtimeData
				);

				return;
			}

			const auctionStatus =
				realtimeData.status == null
					? ""
					: String(realtimeData.status)
						.trim()
						.toUpperCase();

			/*
			 * 진행 상태가 끝났다면 현재가와 입찰 건수 외에도
			 * 상태 문구와 관리 버튼 구성이 바뀌므로 서버 렌더링을
			 * 다시 받아 화면 전체를 맞춘다.
			 */
			if (auctionStatus !== "ONGOING") {
				window.location.reload();
				return;
			}

			const currentPrice =
				Number(realtimeData.currentPrice);

			const bidCount =
				Number(realtimeData.bidCount);

			const itemElements =
				auctionItemMap.get(String(auctionNo))
				|| [];

			itemElements.forEach(
				function (itemElement) {

					const currentPriceElement =
						itemElement.querySelector(
							"[data-realtime-current-price]"
						);

					const bidCountElement =
						itemElement.querySelector(
							"[data-realtime-bid-count]"
						);

					if (Number.isFinite(currentPrice)) {

						animatePriceCountUp(
							currentPriceElement,
							currentPrice
						);
					}

					if (Number.isSafeInteger(bidCount)) {

						animateBidCountRoll(
							bidCountElement,
							bidCount
						);
					}
				}
			);
		}


		async function refreshRealtimeAuction(
			auctionNo
		) {

			const previousSequence =
				realtimeRequestSequenceMap.get(auctionNo)
				|| 0;

			const currentSequence =
				previousSequence + 1;

			realtimeRequestSequenceMap.set(
				auctionNo,
				currentSequence
			);

			const realtimeUrl =
				contextPath
				+ "/api/auctionFlow/auction/realtime?A_NO="
				+ encodeURIComponent(auctionNo);

			try {

				const response =
					await fetch(
						realtimeUrl,
						{
							method: "GET",
							headers: {
								"Accept": "application/json"
							},
							cache: "no-store"
						}
					);

				if (!response.ok) {

					throw new Error(
						"HTTP_STATUS_"
						+ response.status
					);
				}

				const realtimeData =
					await response.json();

				if (
					currentSequence
					!== realtimeRequestSequenceMap.get(auctionNo)
				) {
					return;
				}

				applyRealtimeAuctionData(
					auctionNo,
					realtimeData
				);

			} catch (error) {

				console.error(
					"[MYPAGE AUCTION REALTIME FAILED]"
					+ " A_NO="
					+ auctionNo,
					error
				);
			}
		}


		/* =========================
		   WebSocket
		   ========================= */

		function parseWebSocketMessage(message) {

			const messageParts =
				String(message).split("|");

			const parsedMessage = {
				type: messageParts[0] || "",
				auctionNo: null
			};

			for (
				let index = 1;
				index < messageParts.length;
				index++
			) {

				const messagePart =
					messageParts[index];

				if (messagePart.startsWith("A_NO=")) {

					parsedMessage.auctionNo =
						messagePart.substring(
							"A_NO=".length
						);
				}
			}

			return parsedMessage;
		}


		function scheduleReconnect(auctionNo) {

			if (pageClosing) {
				return;
			}

			const state =
				webSocketStateMap.get(auctionNo);

			if (!state || state.reconnectTimer !== null) {
				return;
			}

			state.reconnectTimer =
				window.setTimeout(
					function () {

						state.reconnectTimer = null;
						connectAuctionWebSocket(auctionNo);
					},
					2500
				);
		}


		function connectAuctionWebSocket(auctionNo) {

			if (pageClosing) {
				return;
			}

			const previousState =
				webSocketStateMap.get(auctionNo);

			if (
				previousState
				&& previousState.socket
				&& (
					previousState.socket.readyState
					=== WebSocket.OPEN
					|| previousState.socket.readyState
					=== WebSocket.CONNECTING
				)
			) {
				return;
			}

			const webSocketUrl =
				webSocketProtocol
				+ "//"
				+ window.location.host
				+ contextPath
				+ "/ws/auction/"
				+ encodeURIComponent(auctionNo);

			const auctionWebSocket =
				new WebSocket(webSocketUrl);

			const state =
				previousState || {
					socket: null,
					reconnectTimer: null
				};

			state.socket = auctionWebSocket;

			webSocketStateMap.set(
				auctionNo,
				state
			);

			auctionWebSocket.addEventListener(
				"open",
				function () {

					/*
					 * 페이지가 열린 직후 또는 재연결 직후 놓친 입찰이
					 * 있을 수 있으므로 최신 상태를 한 번 동기화한다.
					 */
					refreshRealtimeAuction(auctionNo);
				}
			);

			auctionWebSocket.addEventListener(
				"message",
				function (event) {

					const parsedMessage =
						parseWebSocketMessage(event.data);

					if (
						parsedMessage.auctionNo !== null
						&& String(parsedMessage.auctionNo)
							!== String(auctionNo)
					) {
						return;
					}

					if (parsedMessage.type === "BID_UPDATED") {

						refreshRealtimeAuction(auctionNo);
						return;
					}

					if (parsedMessage.type === "AUCTION_CANCELED") {
						window.location.reload();
					}
				}
			);

			auctionWebSocket.addEventListener(
				"close",
				function () {
					scheduleReconnect(auctionNo);
				}
			);

			auctionWebSocket.addEventListener(
				"error",
				function (event) {

					console.error(
						"[MYPAGE AUCTION WS ERROR]"
						+ " A_NO="
						+ auctionNo,
						event
					);
				}
			);
		}


		auctionItemMap.forEach(
			function (itemElements, auctionNo) {
				connectAuctionWebSocket(auctionNo);
			}
		);


		window.addEventListener(
			"beforeunload",
			function () {

				pageClosing = true;

				webSocketStateMap.forEach(
					function (state) {

						if (state.reconnectTimer !== null) {
							window.clearTimeout(
								state.reconnectTimer
							);
						}

						if (
							state.socket
							&& (
								state.socket.readyState
								=== WebSocket.OPEN
								|| state.socket.readyState
								=== WebSocket.CONNECTING
							)
						) {
							state.socket.close();
						}
					}
				);
			}
		);
	}


	if (document.readyState === "loading") {

		document.addEventListener(
			"DOMContentLoaded",
			initializeMyPageAuctionRealtime
		);

	} else {

		initializeMyPageAuctionRealtime();
	}

})();
</script>

</body>
</html>