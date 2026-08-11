<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="coreframe.data.DataSet" %>

<%
	boolean isAdminLogin = Boolean.TRUE.equals(session.getAttribute("LOGIN_ADMIN"));
	//관리자 세션 없이 JSP 주소로 직접 접근한 경우 차단
	if (!isAdminLogin) {
%>

	<jsp:forward page="/view/error/error.jsp" />

<%
		return;
	}

	//현재 활성화할 사이드바 메뉴
	request.setAttribute("ADMIN_MENU", "DASHBOARD");
	Object totalSoldAmountObject = request.getAttribute("TOTAL_SOLD_AMOUNT");
	Object totalFeeAmountObject = request.getAttribute("TOTAL_FEE_AMOUNT");
	Object unpaidFeeAmountObject = request.getAttribute("UNPAID_FEE_AMOUNT");
	Object unpaidCountObject = request.getAttribute("UNPAID_COUNT");

	long totalSoldAmount = 0L;
	long totalFeeAmount = 0L;
	long unpaidFeeAmount = 0L;
	long unpaidCount = 0L;

	if (totalSoldAmountObject instanceof Number) {
		totalSoldAmount = ((Number) totalSoldAmountObject).longValue();
	}
	if (totalFeeAmountObject instanceof Number) {
		totalFeeAmount = ((Number) totalFeeAmountObject).longValue();
	}
	if (unpaidFeeAmountObject instanceof Number) {
		unpaidFeeAmount = ((Number) unpaidFeeAmountObject).longValue();
	}
	if (unpaidCountObject instanceof Number) {
		unpaidCount = ((Number) unpaidCountObject).longValue();
	}
	DecimalFormat priceFormat = new DecimalFormat("#,###");
%>

<%
	/* 막대 그래프 */
	
	//최근 7일 일일 경매 등록 현황
	DataSet auctionRegisterGraph = (DataSet) request.getAttribute("AUCTION_REGISTER_GRAPH");

	//그래프 조회 행 수 : 정상 조회 시 최근 7일이므로 7개다.
	int auctionRegisterGraphCount = 0;

	if (auctionRegisterGraph != null) {
		auctionRegisterGraphCount = auctionRegisterGraph.getCount("REGISTER_DATE");
	}

	//최근 7일 중 등록 건수가 가장 큰 날짜의 건수, 이 값이 막대그래프 Y축의 기준이 된다.
	long maxRegisterCount = 0L;

	for (int i=0; i<auctionRegisterGraphCount; i++) {

		long registerCount = auctionRegisterGraph.getLong("REGISTER_COUNT", i);

		if (registerCount > maxRegisterCount) {
			maxRegisterCount = registerCount;
		}
	}

	/* 
	 * Y축 최대값 결정
	 * 
	 * 1의 자리 : 10, 10의 자리 : 100, 100의 자리 1000 ...
	 */
	long graph_Y_Max = 10L;

	if (maxRegisterCount > 0L) {
		long tempCount = maxRegisterCount;
		graph_Y_Max = 1L;
		
		while (tempCount > 0L) {
			graph_Y_Max *= 10L;
			tempCount /= 10L;
		}
	}

	//Y축 5등분 눈금
	long graph_Y_80 = graph_Y_Max * 4L / 5L;
	long graph_Y_60 = graph_Y_Max * 3L / 5L;
	long graph_Y_40 = graph_Y_Max * 2L / 5L;
	long graph_Y_20 = graph_Y_Max / 5L;

	//CSS 막대 높이에 사용할 백분율 형식
	DecimalFormat percentageFormat = new DecimalFormat("0.##");
%>

<%	
	/* 도넛 그래프 */
	DataSet auctionStatusGraph = (DataSet) request.getAttribute("AUCTION_STATUS_GRAPH");

	//경매 상태별 개수
	long ongoingCount = 0L;
	long soldCount = 0L;
	long unsoldCount = 0L;
	long canceledCount = 0L;
	
	//상태별 통계 조회 행 수
	int auctionStatusGraphCount = 0;
	
	if (auctionStatusGraph != null) {
		auctionStatusGraphCount = auctionStatusGraph.getCount("STATUS_CODE");
	}
	
	//조회된 상태별 건수를 각 변수에 저장
	for (int i = 0; i < auctionStatusGraphCount; i++) {
		
		String statusCode = auctionStatusGraph.getText("STATUS_CODE", i);
		long statusCount = auctionStatusGraph.getLong("STATUS_COUNT", i);

		if ("ONGOING".equals(statusCode)) {
			ongoingCount = statusCount;
		} else if ("SOLD".equals(statusCode)) {
			soldCount = statusCount;
		} else if ("UNSOLD".equals(statusCode)) {
			unsoldCount = statusCount;
		} else if ("CANCELED".equals(statusCode)) {
			canceledCount = statusCount;
		}
	}

	//전체 경매 건수
	long totalStatusCount = ongoingCount + soldCount + unsoldCount + canceledCount;
	
	//각 상태가 전체에서 차지하는 비율
	double ongoingRate = 0.0;
	double soldRate = 0.0;
	double unsoldRate = 0.0;
	double canceledRate = 0.0;

	//도넛그래프의 누적 종료 지점
	double ongoingEndRate = 0.0;
	double soldEndRate = 0.0;
	double unsoldEndRate = 0.0;

	if (totalStatusCount > 0L) {
		ongoingRate = ((double) ongoingCount / totalStatusCount) * 100.0;
		soldRate = ((double) soldCount / totalStatusCount) * 100.0;
		unsoldRate = ((double) unsoldCount / totalStatusCount) * 100.0;
		canceledRate = ((double) canceledCount / totalStatusCount) * 100.0;

		/*
		 * conic-gradient에 사용할 누적 종료 지점
		 *
		 * 예:
		 * 진행 중 40%
		 * 낙찰 30%
		 * 유찰 20%
		 * 취소 10%
		 *
		 * 진행 중: 0% ~ 40%
		 * 낙찰:    40% ~ 70%
		 * 유찰:    70% ~ 90%
		 * 취소:    90% ~ 100%
		 */
		ongoingEndRate = ongoingRate;
		soldEndRate = ongoingEndRate + soldRate;
		unsoldEndRate = soldEndRate + unsoldRate;
	}
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>관리자 통계</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/admin/common/sidebar.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/admin/dashboard/dashboard.css">
</head>
<body>

	<div class="admin-layout">

		<jsp:include page="/view/admin/common/sidebar.jsp" />

		<main class="admin-content">

			<div class="admin-page-header">

				<h1 class="admin-page-title">통계</h1>

				<p class="admin-page-description">AuctionFlow의 주요 운영 현황을 확인합니다.</p>
			</div>

			<!-- 주요 통계 카드 -->
			<section class="admin-stat-card-list" aria-label="주요 통계">

				<article class="admin-stat-card">

					<p class="admin-stat-card-title">총 낙찰액</p>

					<p class="admin-stat-card-value">

						<%= priceFormat.format(totalSoldAmount) %><span class="admin-stat-card-unit">원</span>
					</p>

					<p class="admin-stat-card-description">낙찰 완료된 경매의 낙찰가 합계</p>
				</article>

				<article class="admin-stat-card">
					<p class="admin-stat-card-title">총 수수료</p>
					<p class="admin-stat-card-value"><%= priceFormat.format(totalFeeAmount) %><span class="admin-stat-card-unit">원</span></p>
					<p class="admin-stat-card-description">낙찰 금액의 10%<br>(소수점 자리 버림)</p>
				</article>

				<article class="admin-stat-card">
					<p class="admin-stat-card-title">미결제 수수료</p>
					<p class="admin-stat-card-value"><%= priceFormat.format(unpaidFeeAmount) %><span class="admin-stat-card-unit">원</span></p>
					<p class="admin-stat-card-description">미결제<strong> <%= priceFormat.format(unpaidCount) %>건</strong></p>
				</article>
			</section>

			<!-- 그래프 영역 -->
			<section class="admin-chart-grid" aria-label="경매 통계 그래프">

				<!-- 일일 경매 등록 막대그래프 -->
				<article class="admin-chart-card admin-chart-card-bar">

					<div class="admin-chart-card-header">

						<div>

							<h2 class="admin-chart-card-title">일일 경매 등록 현황</h2>

							<p class="admin-chart-card-description">최근 7일간 등록된 경매 수</p>
						</div>

						<span class="admin-chart-card-unit">단위: 건</span>
					</div>

					<div class="admin-bar-chart" role="img" aria-label="경매 등록 현황 막대그래프">

						<!-- Y축 숫자 -->
						<div class="admin-bar-y-axis">
							<span><%= graph_Y_Max %>건</span>
							<span><%= graph_Y_80 %>건</span>
							<span><%= graph_Y_60 %>건</span>
							<span><%= graph_Y_40 %>건</span>
							<span><%= graph_Y_20 %>건</span>
							<span>0건</span>
						</div>

						<!-- 막대그래프 실제 영역 -->
						<div class="admin-bar-plot">

							<!-- 가로 기준선 -->
							<div class="admin-bar-grid-lines">
								<span></span>
								<span></span>
								<span></span>
								<span></span>
								<span></span>
								<span></span>
							</div>
							
							<!-- 날짜별 막대 -->
							<div class="admin-bar-list">
								<%
									for (int i = 0; i < auctionRegisterGraphCount; i++) {

										String registerDate = auctionRegisterGraph.getText("REGISTER_DATE", i);
										long registerCount = auctionRegisterGraph.getLong("REGISTER_COUNT", i);

										/*
										 * 막대 높이를 백분율로 계산
										 *
										 * 예:
										 * Y축 최대 10건
										 * 현재 등록 7건
										 *
										 * 7 / 10 × 100 = 70%
										 */
										double barHeightRate = ((double) registerCount / graph_Y_Max) * 100.0;
								%>

									<div class="admin-bar-item">

										<div class="admin-bar-slot">

											<div class="admin-bar" style="height: <%= percentageFormat.format(barHeightRate) %>%">

												<span class="admin-bar-value"><%= registerCount %>건</span>
											</div>
										</div>

										<span class="admin-bar-date"><%= registerDate %></span>
									</div>
								<%
									}
								%>
							</div>
						</div>
					</div>
				</article>

				<article class="admin-chart-card admin-chart-card-pie">
				
					<div class="admin-chart-card-header">
						<div>
							<h2 class="admin-chart-card-title">경매 상태 현황</h2>
							<p class="admin-chart-card-description">상태별 전체 경매 건수</p>
						</div>
					</div>

					<div class="admin-chart-pending">
						
						<!-- 도넛그래프 -->
						<div class="admin-donut-chart-wrap">
				
							<div class="admin-donut-chart<%= totalStatusCount == 0L ? " is-empty" : "" %>"
								style="
									--ongoing-end: <%= percentageFormat.format(ongoingEndRate) %>%;
									--sold-end: <%= percentageFormat.format(soldEndRate) %>%;
									--unsold-end: <%= percentageFormat.format(unsoldEndRate) %>%;">
							</div>
				
							<!-- 도넛 가운데 전체 건수 -->
							<div class="admin-donut-center">
				
								<span class="admin-donut-center-label">전체</span>
								<strong class="admin-donut-center-value">
									<%= priceFormat.format(totalStatusCount) %><span>건</span>
								</strong>
							</div>
						</div>
				
						<!-- 도넛그래프 범례 -->
						<ul class="admin-donut-legend" aria-label="경매 상태별 건수">
				
							<li class="admin-donut-legend-item">
				
								<span class="admin-donut-legend-color admin-donut-legend-color-ongoing"></span>
								<span class="admin-donut-legend-name">진행 중</span>
								<span class="admin-donut-legend-result">
				
									<strong><%= priceFormat.format(ongoingCount) %>건</strong>
									<small><%= percentageFormat.format(ongoingRate) %>%</small>
								</span>
							</li>
				
							<li class="admin-donut-legend-item">
								<span class="admin-donut-legend-color admin-donut-legend-color-sold"></span>
								<span class="admin-donut-legend-name">낙찰</span>
								<span class="admin-donut-legend-result">
				
									<strong><%= priceFormat.format(soldCount) %>건</strong>
									<small><%= percentageFormat.format(soldRate) %>%</small>
								</span>
							</li>
				
							<li class="admin-donut-legend-item">
				
								<span class="admin-donut-legend-color admin-donut-legend-color-unsold"></span>
								<span class="admin-donut-legend-name">유찰</span>
								<span class="admin-donut-legend-result">
				
									<strong><%= priceFormat.format(unsoldCount) %>건</strong>
									<small><%= percentageFormat.format(unsoldRate) %>%</small>
								</span>
							</li>
				
							<li class="admin-donut-legend-item">
				
								<span class="admin-donut-legend-color admin-donut-legend-color-canceled"></span>
								<span class="admin-donut-legend-name">취소</span>
								<span class="admin-donut-legend-result">
				
									<strong><%= priceFormat.format(canceledCount) %>건</strong>
									<small><%= percentageFormat.format(canceledRate) %>%</small>
								</span>
							</li>
						</ul>
					</div>
				</article>
			</section>
		</main>
	</div>
</body>
</html>