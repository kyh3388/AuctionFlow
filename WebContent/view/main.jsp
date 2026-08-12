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

	private String displayDateTime(String value) {

		if (value == null || value.isBlank()) {
			return "-";
		}
		if (value.length() >= 16) {
			return value.substring(5, 16).replace("-", ".");
		}
		return value;
	}
%>

<%
	DataSet topPriceList = (DataSet) request.getAttribute("TOP_PRICE_LIST");
	DataSet todayAuctionList = (DataSet) request.getAttribute("TODAY_AUCTION_LIST");
	DataSet calendarAuctionList = (DataSet) request.getAttribute("CALENDAR_AUCTION_LIST");

	int topPriceCount = 0;
	int todayAuctionCount = 0;
	int calendarAuctionCount = 0;

	if (topPriceList != null) {
		topPriceCount = topPriceList.getCount("A_NO");
	}
	if (todayAuctionList != null) {
		todayAuctionCount = todayAuctionList.getCount("A_NO");
	}
	if (calendarAuctionList != null) {
		calendarAuctionCount = calendarAuctionList.getCount("A_NO");
	}

	String calendarYear = (String) request.getAttribute("CALENDAR_YEAR");

	String calendarMonth = (String) request.getAttribute("CALENDAR_MONTH");

	if (calendarYear == null || calendarYear.isBlank()) {
		calendarYear = "2026";
	}
	if (calendarMonth == null || calendarMonth.isBlank()) {
		calendarMonth = "1";
	}

	boolean loginSuccessAlert = "Y".equals(request.getAttribute("LOGIN_SUCCESS_ALERT"));
	boolean auctionRegisterSuccessAlert = "Y".equals(request.getAttribute("AUCTION_REGISTER_SUCCESS_ALERT"));

	int todayPageSize = 7;
	int todayPageCount = (todayAuctionCount + todayPageSize - 1) / todayPageSize;
	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>AuctionFlow</title>
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/main.css">
</head>

<body class="main-page">

	<jsp:include page="/view/common/header.jsp" />

	<main class="main">
		<div class="main-inner">
		
			<!-- =========================
			     현재가 TOP 3
			========================= -->
			<section class="main-section main-top-price-section">

				<div class="main-section-header">
					<div class="main-section-title-wrap">
						<h1 class="main-section-title">Auction TOP 3</h1>
					</div>
					<p class="main-section-description">현재 진행 중인 경매 가운데 현재가가 가장 높은 상품입니다.</p>
				</div>
				<%
					if (topPriceCount <= 0) {
				%>
					<div class="main-empty-box">
						<strong class="main-empty-title">진행 중인 경매가 없습니다.</strong>
						<p class="main-empty-text">경매가 등록되면 현재가 순위가 표시됩니다.</p>
					</div>
				<%
					} else {
				%>
					<div class="main-top-price-grid">
						<%
							for (int rowIndex = 0; rowIndex < topPriceCount; rowIndex++) {
								long auctionNo = topPriceList.getLong("A_NO", rowIndex);
								String auctionTitle = topPriceList.getText("A_TITLE", rowIndex);
								long currentPrice = topPriceList.getLong("A_CURRENT_PRICE", rowIndex);
								long bidCount = topPriceList.getLong("A_BID_COUNT", rowIndex);
								String endDatetime = topPriceList.getText("A_END_DATETIME", rowIndex);
								String imageStoredName = topPriceList.getText("IMG_STORED_NAME", rowIndex);
								int ranking = rowIndex + 1;
						%>
							<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="main-top-price-card rank-<%= ranking %>">

								<div class="main-top-price-rank">
									<%= ranking %>
								</div>

								<div class="main-top-price-image-box">
									<%
										if (imageStoredName != null && !imageStoredName.isBlank()) {
									%>
										<img src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>" alt="<%= escapeHtml(auctionTitle) %>" class="main-top-price-image">
									<%
										} else {
									%>
										<div class="main-image-placeholder">NO IMAGE</div>
									<%
										}
									%>
								</div>

								<div class="main-top-price-information">
									<h2 class="main-top-price-title"><%= escapeHtml(auctionTitle) %></h2>
									<p class="main-top-price-label">현재가</p>
									<strong class="main-top-price-value"><%= priceFormat.format(currentPrice) %>원</strong>
									<div class="main-top-price-meta">
										<span>입찰 <%= bidCount %>건</span>
										<span>종료 <%= escapeHtml(displayDateTime(endDatetime)) %></span>
									</div>
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

			<!-- =========================
			     오늘 등록된 경매
			     ========================= -->
			<section class="main-section main-today-section">
				<div class="main-section-header main-section-header-row">
					<div>
						<div class="main-section-title-wrap">
							<h2 class="main-section-title">Today Aucton</h2>
						</div>
						<p class="main-section-description">오늘 새롭게 등록된 경매 상품입니다.</p>
					</div>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/ongoing" class="main-section-more-link">진행 경매 전체 보기</a>
				</div>
				<%
					if (todayAuctionCount <= 0) {
				%>
					<div class="main-empty-box">
						<strong class="main-empty-title">오늘 등록된 경매가 없습니다.</strong>
						<p class="main-empty-text">진행 중인 다른 경매를 확인해 보세요.</p>
						<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/ongoing" class="main-empty-link">진행 경매 보기</a>
					</div>
				<%
					} else {
				%>
					<div class="main-today-carousel">
						<button type="button" id="mainTodayPreviousButton" class="main-carousel-button previous" aria-label="이전 경매" <%= todayPageCount <= 1 ? "disabled" : "" %>>‹</button>
						<div class="main-today-viewport">
							<div id="mainTodayPageContainer" class="main-today-page-container">
								<%
									for (int pageIndex = 0; pageIndex < todayPageCount; pageIndex++) {
										int startIndex = pageIndex * todayPageSize;
										int endIndex = Math.min(startIndex + todayPageSize, todayAuctionCount);
								%>
									<div class="main-today-page <%= pageIndex == 0 ? "is-active" : "" %>" data-page-index="<%= pageIndex %>" <%= pageIndex == 0 ? "" : "hidden" %>>
										<%
											for (int rowIndex = startIndex; rowIndex < endIndex; rowIndex++) {
												long auctionNo = todayAuctionList.getLong("A_NO", rowIndex);
												String auctionTitle = todayAuctionList.getText("A_TITLE", rowIndex);
												long currentPrice = todayAuctionList.getLong("A_CURRENT_PRICE", rowIndex);
												long bidCount = todayAuctionList.getLong("A_BID_COUNT", rowIndex);
												String endDatetime = todayAuctionList.getText("A_END_DATETIME", rowIndex);
												String imageStoredName = todayAuctionList.getText("IMG_STORED_NAME", rowIndex);
										%>
											<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/detail?A_NO=<%= auctionNo %>" class="main-today-card">
												<div class="main-today-image-box">
													<%
														if (imageStoredName != null && !imageStoredName.isBlank()) {
													%>
														<img src="${pageContext.request.contextPath}/api/auctionFlow/auction/image?IMG_STORED_NAME=<%= escapeHtml(imageStoredName) %>" alt="<%= escapeHtml(auctionTitle) %>" class="main-today-image">
													<%
														} else {
													%>
														<div class="main-image-placeholder">
															NO IMAGE
														</div>
													<%
														}
													%>

												</div>

												<div class="main-today-information">
													<h3 class="main-today-title"><%= escapeHtml(auctionTitle) %></h3>
													<strong class="main-today-price"><%= priceFormat.format(currentPrice) %>원</strong>
													<div class="main-today-meta">
														<span>입찰 <%= bidCount %>건</span>
														<span><%= escapeHtml(displayDateTime(endDatetime)) %></span>
													</div>
												</div>
											</a>
										<%
											}
										%>
									</div>
								<%
									}
								%>
							</div>
						</div>
						<button type="button" id="mainTodayNextButton" class="main-carousel-button next" aria-label="다음 경매" <%= todayPageCount <= 1 ? "disabled" : "" %>>›</button>
					</div>

					<div class="main-carousel-pagination">
						<span id="mainTodayCurrentPage">1</span>
						<span>/</span>
						<span><%= todayPageCount %></span>
					</div>
				<%
					}
				%>
			</section>

			<!-- 경매 종료 캘린더 -->
			<section class="main-section main-calendar-section">
				<div class="main-section-header">
					<div class="main-section-title-wrap">
						<h2 class="main-section-title">Auction Calendar</h2>
					</div>
					<p class="main-section-description">점이 표시된 날짜를 선택하면 해당 날짜에 종료되는 경매를 확인할 수 있습니다.</p>
				</div>

				<div class="main-calendar-panel">

					<!-- 월간 달력 -->
					<div id="mainCalendarView" class="main-calendar-view" data-calendar-year="<%= escapeHtml(calendarYear) %>" data-calendar-month="<%= escapeHtml(calendarMonth) %>">

						<div class="main-calendar-navigation">
							<div class="main-calendar-month-control">
								<button type="button" id="mainCalendarPreviousButton" class="main-calendar-month-button" aria-label="이전 달"><</button>
								<h3 id="mainCalendarMonthTitle" class="main-calendar-month-title"></h3>
								<button type="button" id="mainCalendarNextButton" class="main-calendar-month-button" aria-label="다음 달">></button>
							</div>
							
							<div class="main-calendar-legend">
								<span class="main-calendar-legend-dot"></span>
								<span>종료 예정</span>
							</div>
						</div>

						<div class="main-calendar-weekdays">
							<span class="sunday">일</span>
							<span>월</span>
							<span>화</span>
							<span>수</span>
							<span>목</span>
							<span>금</span>
							<span class="saturday">토</span>
						</div>

						<div id="mainCalendarDateGrid" class="main-calendar-date-grid">
						</div>
						
						<div class="main-calendar-empty-message-space">
							<p id="mainCalendarEmptyMessage" class="main-calendar-empty-message" hidden>이 달에 종료 예정인 경매가 없습니다.</p>
						</div>
					</div>

					<!-- 선택 날짜의 종료 예정 경매 -->
					<div id="mainCalendarAuctionView" class="main-calendar-auction-view" hidden>

						<div class="main-calendar-auction-header">
							<button type="button" id="mainCalendarBackButton" class="main-calendar-back-button" aria-label="캘린더로 돌아가기">←</button>
							<h3 id="mainCalendarSelectedDateTitle" class="main-calendar-selected-date-title"></h3>
						</div>

						<div id="mainCalendarAuctionList" class="main-calendar-auction-list">
						</div>
					</div>
				</div>
			</section>
		</div>
	</main>

<!-- 캘린더 JavaScript용 경매 데이터 -->
<div id="mainCalendarData" hidden>

	<%
		for (int rowIndex = 0; rowIndex < calendarAuctionCount; rowIndex++) {
			long auctionNo = calendarAuctionList.getLong("A_NO", rowIndex);
			String auctionTitle = calendarAuctionList.getText("A_TITLE", rowIndex);
			long currentPrice = calendarAuctionList.getLong("A_CURRENT_PRICE", rowIndex);
			long bidCount = calendarAuctionList.getLong("A_BID_COUNT", rowIndex);
			String endDate = calendarAuctionList.getText("A_END_DATE", rowIndex);
			String endDatetime = calendarAuctionList.getText("A_END_DATETIME", rowIndex);
			String imageStoredName = calendarAuctionList.getText("IMG_STORED_NAME", rowIndex);
	%>
		<div
			class="main-calendar-auction-data"
			data-auction-no="<%= auctionNo %>"
			data-auction-title="<%= escapeHtml(auctionTitle) %>"
			data-current-price="<%= currentPrice %>"
			data-bid-count="<%= bidCount %>"
			data-end-date="<%= escapeHtml(endDate) %>"
			data-end-datetime="<%= escapeHtml(endDatetime) %>"
			data-image-stored-name="<%= escapeHtml(imageStoredName) %>">
		</div>
	<%
		}
	%>

</div>

<jsp:include page="/view/common/footer.jsp" />

<script>
	(function () {
		const loginSuccessAlert = <%= loginSuccessAlert ? "true" : "false" %>;
		const auctionRegisterSuccessAlert = <%= auctionRegisterSuccessAlert ? "true" : "false" %>;

		if (loginSuccessAlert) {
			window.alert("로그인되었습니다.");
		}
		if (auctionRegisterSuccessAlert) {
			window.alert("경매가 등록되었습니다.");
		}
		
	})();
</script>

<script>
	(function () {
		const pageElements = Array.from(document.querySelectorAll(".main-today-page"));
		const previousButton = document.getElementById("mainTodayPreviousButton");
		const nextButton = document.getElementById("mainTodayNextButton");
		const currentPageText = document.getElementById("mainTodayCurrentPage");

		if (pageElements.length <= 0 || previousButton === null || nextButton === null || currentPageText === null) {
			return;
		}

		let currentPageIndex = 0;

		function renderTodayPage() {

			pageElements.forEach(function (pageElement, pageIndex) {

					const isCurrentPage = pageIndex === currentPageIndex;
					pageElement.hidden = !isCurrentPage;
					pageElement.classList.toggle("is-active", isCurrentPage);
				}
			);
			previousButton.disabled = currentPageIndex <= 0;
			nextButton.disabled = currentPageIndex >= pageElements.length - 1;
			currentPageText.textContent = String(currentPageIndex + 1);
		}

		previousButton.addEventListener("click", function () {
				if (currentPageIndex <= 0) {
					return;
				}
				currentPageIndex--;
				renderTodayPage();
			}
		);

		nextButton.addEventListener("click", function () {
				if (currentPageIndex >= pageElements.length - 1) {
					return;
				}
				currentPageIndex++;
				renderTodayPage();
			}
		);
		renderTodayPage();
	})();
</script>

<script>
	(function () {
		const contextPath = "<%= request.getContextPath() %>";

		/* =========================
		   ELEMENT
		   ========================= */
		const calendarView = document.getElementById("mainCalendarView");
		const calendarAuctionView = document.getElementById("mainCalendarAuctionView");
		const calendarDateGrid = document.getElementById("mainCalendarDateGrid");
		const calendarMonthTitle = document.getElementById("mainCalendarMonthTitle");
		const previousMonthButton = document.getElementById("mainCalendarPreviousButton");
		const nextMonthButton = document.getElementById("mainCalendarNextButton");
		const calendarEmptyMessage = document.getElementById("mainCalendarEmptyMessage");
		const calendarBackButton = document.getElementById("mainCalendarBackButton");
		const selectedDateTitle = document.getElementById("mainCalendarSelectedDateTitle");
		const calendarAuctionListElement = document.getElementById("mainCalendarAuctionList");

		if (calendarView === null || calendarAuctionView === null || calendarDateGrid === null || calendarMonthTitle === null || previousMonthButton === null || nextMonthButton === null || calendarEmptyMessage === null || calendarBackButton === null || selectedDateTitle === null || calendarAuctionListElement === null) {
			return;
		}

		/* =========================
		   DATE
		   ========================= */
		const today = new Date();
		const currentYear = today.getFullYear();
		const currentMonth = today.getMonth() + 1;
		const currentDay = today.getDate();

		let displayedYear = Number(calendarView.dataset.calendarYear);
		let displayedMonth = Number(calendarView.dataset.calendarMonth);
		let isCalendarLoading = false;

		/* =========================
		   INITIAL AUCTION DATA
		   ========================= */
		const initialAuctionDataElements = Array.from(document.querySelectorAll(".main-calendar-auction-data"));

		let auctionList = initialAuctionDataElements.map(function (element) {

					return {
						auctionNo: String(element.dataset.auctionNo || ""),
						auctionTitle: element.dataset.auctionTitle || "",
						currentPrice: Number(element.dataset.currentPrice || 0),
						bidCount: Number(element.dataset.bidCount || 0),
						endDate: element.dataset.endDate || "",
						endDatetime: element.dataset.endDatetime || "",
						imageStoredName: element.dataset.imageStoredName || ""
					};
				});

		let auctionMapByDate = createAuctionMapByDate(auctionList);


		/* =========================
		   AUCTION DATE MAP
		   ========================= */
		function createAuctionMapByDate(auctions) {
			const auctionMap = new Map();
			auctions.forEach(function (auction) {
					if (!auction.endDate) {
						return;
					}
					if (!auctionMap.has(auction.endDate)) {
						auctionMap.set(auction.endDate, []);
					}
					auctionMap.get(auction.endDate).push(auction);
				});
			return auctionMap;
		}


		/* =========================
		   DATE KEY
		   ========================= */
		function createDateKey(year, month, day) {
			return String(year) + "-" + String(month).padStart(2, "0") + "-" + String(day).padStart(2, "0");
		}

		
		/* =========================
		   YEAR / MONTH NORMALIZE
		   ========================= */
		function normalizeYearMonth(year, month) {
			const normalizedDate = new Date(year, month - 1, 1);
			return {
				year: normalizedDate.getFullYear(),
				month: normalizedDate.getMonth() + 1
			};
		}


		/* =========================
		   PRICE FORMAT
		   ========================= */
		function formatPrice(price) {
			return Number(price).toLocaleString("ko-KR") + "원";
		}


		/* =========================
		   DATETIME FORMAT
		   ========================= */
		function formatEndDatetime(endDatetime) {
			if (!endDatetime || endDatetime.length < 16) {
				return endDatetime || "-";
			}
			const month = Number(endDatetime.substring(5, 7));
			const day = Number(endDatetime.substring(8, 10));
			const time = endDatetime.substring(11, 16);
			return month + "월 " + day + "일 " + time;
		}


		/* =========================
		   PAST MONTH CHECK
		   ========================= */
		function isPastMonth(year, month) {
			if (year < currentYear) {
				return true;
			}
			if (year === currentYear && month < currentMonth) {
				return true;
			}
			return false;
		}


		/* =========================
		   BUTTON STATE
		   ========================= */
		function updateCalendarButtonState() {
			const isCurrentMonth = displayedYear === currentYear && displayedMonth === currentMonth;
			previousMonthButton.disabled = isCalendarLoading || isCurrentMonth;
			nextMonthButton.disabled = isCalendarLoading;
		}


		/* =========================
		   LOADING STATE
		   ========================= */
		function setCalendarLoading(isLoading) {
			isCalendarLoading = isLoading;
			calendarView.setAttribute("aria-busy", isLoading ? "true" : "false");
			updateCalendarButtonState();
		}


		/* =========================
		   MONTH DATA LOAD
		   ========================= */
		async function loadCalendarMonth(targetYear, targetMonth) {
			if (isCalendarLoading) {
				return;
			}
			const normalizedYearMonth = normalizeYearMonth(targetYear, targetMonth);

			//현재 월보다 이전 월은 조회하지 않는다.
			if (isPastMonth(normalizedYearMonth.year, normalizedYearMonth.month)) {
				return;
			}
			setCalendarLoading(true);

			try {
				const requestUrl = contextPath + "/api/auctionFlow/main/calendar" + "?YEAR=" + encodeURIComponent(normalizedYearMonth.year) + "&MONTH=" + encodeURIComponent(normalizedYearMonth.month);
				const response = await fetch(requestUrl,
						{
							method: "GET",
							headers: {
								"Accept": "application/json"
							}
						});
				let result;

				try {
					result = await response.json();
				} catch (jsonError) {
					throw new Error("서버 응답 형식이 올바르지 않습니다.");
				}

				if (!response.ok || !result.success) {
					throw new Error(result.message || "캘린더 정보를 불러오지 못했습니다.");
				}

				displayedYear = Number(result.year);
				displayedMonth = Number(result.month);

				auctionList = Array.isArray(result.auctions) ? result.auctions.map(
							function (auction) {
								return {
									auctionNo: String(auction.auctionNo || ""),
									auctionTitle: auction.auctionTitle || "",
									currentPrice: Number(auction.currentPrice || 0),
									bidCount: Number(auction.bidCount || 0),
									endDate: auction.endDate || "",
									endDatetime: auction.endDatetime || "",
									imageStoredName: auction.imageStoredName || ""
								};
							}) : [];

				auctionMapByDate = createAuctionMapByDate(auctionList);

				calendarAuctionView.hidden = true;
				calendarView.hidden = false;

				renderCalendar();
			} catch (error) {
				window.alert(error.message || "캘린더 정보를 불러오지 못했습니다.");
			} finally {
				setCalendarLoading(false);
			}
		}


		/* =========================
		   SELECTED DATE LIST
		   ========================= */
		function showAuctionList(year, month, day, auctions) {
			calendarAuctionListElement.replaceChildren();
			selectedDateTitle.textContent = year + "년 " + month + "월 " + day + "일 종료 예정 경매";

			auctions.forEach(function (auction) {
					const auctionLink = document.createElement("a");
					auctionLink.className = "main-calendar-auction-item";
					auctionLink.href = contextPath + "/api/auctionFlow/auction/detail" + "?A_NO=" + encodeURIComponent(auction.auctionNo);

					//이미지 영역
					const imageBox = document.createElement("div");
					imageBox.className = "main-calendar-auction-image-box";

					if (auction.imageStoredName && auction.imageStoredName.trim()) {
						const image = document.createElement("img");
						image.className = "main-calendar-auction-image";
						image.src = contextPath + "/api/auctionFlow/auction/image" + "?IMG_STORED_NAME=" + encodeURIComponent(auction.imageStoredName);
						image.alt = auction.auctionTitle;
						imageBox.appendChild(image);
					} else {
						const placeholder = document.createElement("div");
						placeholder.className = "main-image-placeholder";
						placeholder.textContent = "NO IMAGE";
						imageBox.appendChild(placeholder);
					}


					//정보 영역
					const information = document.createElement("div");
					information.className = "main-calendar-auction-information";

					const title = document.createElement("h4");
					title.className = "main-calendar-auction-title";
					title.textContent = auction.auctionTitle;

					const priceRow = document.createElement("p");
					priceRow.className = "main-calendar-auction-meta";
					priceRow.textContent = "현재가 " + formatPrice(auction.currentPrice);

					const bidRow = document.createElement("p");
					bidRow.className = "main-calendar-auction-meta";
					bidRow.textContent = "입찰 " + auction.bidCount + "건";

					const endRow = document.createElement("p");
					endRow.className = "main-calendar-auction-meta";
					endRow.textContent = "종료 " + formatEndDatetime(auction.endDatetime);
					information.append(title, priceRow, bidRow, endRow);
					auctionLink.append(imageBox, information);
					calendarAuctionListElement.appendChild(auctionLink);
				});

			calendarView.hidden = true;
			calendarAuctionView.hidden = false;
		}


		/* =========================
		   CALENDAR RENDER
		   ========================= */
		function renderCalendar() {
			calendarDateGrid.replaceChildren();
			calendarMonthTitle.textContent = displayedYear + "년 " + displayedMonth + "월";
			calendarEmptyMessage.hidden = auctionList.length > 0;

			const firstWeekday = new Date(displayedYear, displayedMonth - 1, 1).getDay();
			const currentMonthLastDate = new Date(displayedYear, displayedMonth, 0).getDate();
			const previousMonthLastDate = new Date(displayedYear, displayedMonth - 1, 0).getDate();

			//달력 칸 수 계산
			const calendarCellCount = 42;

			for (let cellIndex = 0; cellIndex < calendarCellCount; cellIndex++) {
				let dayNumber = 0;
				let isDisplayedMonth = false;

				if (cellIndex < firstWeekday) {
					dayNumber = previousMonthLastDate - firstWeekday + cellIndex + 1;
				} else if (cellIndex < firstWeekday + currentMonthLastDate) {
					dayNumber = cellIndex - firstWeekday + 1;
					isDisplayedMonth = true;
				} else {
					dayNumber = cellIndex - firstWeekday - currentMonthLastDate + 1;
				}

				const dateButton = document.createElement("button");
				dateButton.type = "button";
				dateButton.className = "main-calendar-date";

				const weekdayIndex = cellIndex % 7;

				if (weekdayIndex === 0) {
					dateButton.classList.add("sunday");
				}

				if (weekdayIndex === 6) {
					dateButton.classList.add("saturday");
				}

				const dayText = document.createElement("span");
				dayText.className = "main-calendar-day-number";
				dayText.textContent = String(dayNumber);
				dateButton.appendChild(dayText);


				//이전 달·다음 달 날짜
				if (!isDisplayedMonth) {
					dateButton.classList.add("outside-month");
					dateButton.disabled = true;
					calendarDateGrid.appendChild(dateButton);
					continue;
				}

				const isPastDate = displayedYear === currentYear && displayedMonth === currentMonth && dayNumber < currentDay;
				const isToday = displayedYear === currentYear && displayedMonth === currentMonth && dayNumber === currentDay;

				if (isPastDate) {
					dateButton.classList.add("past-date");
					dateButton.disabled = true;
				}

				if (isToday) {
					dateButton.classList.add("today");
				}

				const dateKey = createDateKey(displayedYear, displayedMonth, dayNumber);
				const dateAuctions = auctionMapByDate.get(dateKey);

				if (!isPastDate && dateAuctions && dateAuctions.length > 0) {
					dateButton.classList.add("has-auction");
					const dot = document.createElement("span");
					dot.className = "main-calendar-date-dot";
					dateButton.appendChild(dot);
					dateButton.addEventListener("click", function () {
							showAuctionList(displayedYear, displayedMonth, dayNumber, dateAuctions);
						});
				} else {
					dateButton.disabled = true;
				}
				calendarDateGrid.appendChild(dateButton);
			}
			updateCalendarButtonState();
		}


		/* =========================
		   PREVIOUS MONTH
		   ========================= */
		previousMonthButton.addEventListener("click", function () {
				if (previousMonthButton.disabled || isCalendarLoading) {
					return;
				}
				loadCalendarMonth(displayedYear, displayedMonth - 1);
			});


		/* =========================
		   NEXT MONTH
		   ========================= */
		nextMonthButton.addEventListener("click", function () {
				if (nextMonthButton.disabled || isCalendarLoading) {
					return;
				}
				loadCalendarMonth(displayedYear, displayedMonth + 1);
			});


		/* =========================
		   BACK TO CALENDAR
		   ========================= */
		calendarBackButton.addEventListener("click", function () {
				calendarAuctionView.hidden = true;
				calendarView.hidden = false;
			});


		/* =========================
		   INITIAL RENDER
		   ========================= */
		renderCalendar();
	})();
</script>

</body>
</html>
