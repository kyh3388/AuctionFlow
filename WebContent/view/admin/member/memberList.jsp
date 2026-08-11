<%@ page contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" %>

<%@ page import="coreframe.data.DataSet" %>

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
%>

<%
	DataSet memberList =
		(DataSet) request.getAttribute(
			"MEMBER_LIST"
		);

	if (memberList == null) {
%>

	<jsp:forward page="/view/error/error.jsp" />

<%
		return;
	}

	int memberCount =
		memberList.getCount("M_NO");

	String contextPath =
		request.getContextPath();
%>

<!DOCTYPE html>
<html lang="ko">

<head>
	<meta charset="UTF-8">

	<title>AuctionFlow 회원 관리</title>

	<link
		rel="stylesheet"
		href="<%= contextPath %>/static/css/admin/common/sidebar.css">

	<link
		rel="stylesheet"
		href="<%= contextPath %>/static/css/admin/member/memberList.css">
</head>

<body>

	<div class="admin-layout">

		<jsp:include
			page="/view/admin/common/sidebar.jsp" />

		<main class="admin-content">

			<div class="admin-page-header">

				<div>

					<h1 class="admin-page-title">
						회원 관리
					</h1>

					<p class="admin-page-description">
						AuctionFlow 회원과 활동 현황을 확인합니다.
					</p>

				</div>

			</div>

			<section class="admin-panel member-list-panel">

				<div class="admin-panel-header">

					<h2 class="admin-panel-title">
						회원 목록
					</h2>

					<p class="admin-panel-count">
						총
						<strong><%= memberCount %></strong>
						명
					</p>

				</div>

				<div class="admin-table-wrap">

					<table class="admin-table member-list-table">

						<colgroup>
							<col class="member-col-number">
							<col class="member-col-id">
							<col class="member-col-name">
							<col class="member-col-phone">
							<col class="member-col-email">
							<col class="member-col-count">
							<col class="member-col-count">
							<col class="member-col-count">
							<col class="member-col-date">
						</colgroup>

						<thead>
							<tr>
								<th scope="col">회원 번호</th>
								<th scope="col">아이디</th>
								<th scope="col">이름</th>
								<th scope="col">휴대폰 번호</th>
								<th scope="col">이메일</th>
								<th scope="col">등록 경매</th>
								<th scope="col">입찰</th>
								<th scope="col">낙찰</th>
								<th scope="col">가입일</th>
							</tr>
						</thead>

						<tbody>

							<%
								if (memberCount == 0) {
							%>

								<tr>
									<td
										colspan="9"
										class="admin-table-empty">
										조회된 회원이 없습니다.
									</td>
								</tr>

							<%
								} else {

									for (
										int i = 0;
										i < memberCount;
										i++
									) {

										long memberNo =
											memberList.getLong(
												"M_NO",
												i
											);

										String memberId =
											memberList.getText(
												"M_ID",
												i
											);

										String memberName =
											memberList.getText(
												"M_NAME",
												i
											);

										String memberPhoneNumber =
											memberList.getText(
												"M_PHONE_NUMBER",
												i
											);

										String memberEmail =
											memberList.getText(
												"M_EMAIL",
												i
											);

										long registerAuctionCount =
											memberList.getLong(
												"REGISTER_AUCTION_COUNT",
												i
											);

										long bidCount =
											memberList.getLong(
												"BID_COUNT",
												i
											);

										long winCount =
											memberList.getLong(
												"WIN_COUNT",
												i
											);

										String createdDatetime =
											memberList.getText(
												"CREATED_DATETIME",
												i
											);

										String memberDetailUrl =
											contextPath
											+ "/api/auctionFlow/admin/member/detail?M_NO="
											+ memberNo;
							%>

								<tr
									class="member-row-link"
									tabindex="0"
									role="link"
									aria-label="<%= escapeHtml(memberName) %> 회원 상세보기"
									data-detail-url="<%= memberDetailUrl %>"
									onclick="window.location.href=this.dataset.detailUrl;"
									onkeydown="
										if (
											event.key === 'Enter'
											|| event.key === ' '
										) {
											event.preventDefault();
											window.location.href =
												this.dataset.detailUrl;
										}
									">

									<td>
										<%= memberNo %>
									</td>

									<td class="member-id-cell">
										<%= escapeHtml(memberId) %>
									</td>

									<td>
										<%= escapeHtml(memberName) %>
									</td>

									<td>
										<%= escapeHtml(memberPhoneNumber) %>
									</td>

									<td>
										<%= escapeHtml(memberEmail) %>
									</td>

									<td>
										<%= registerAuctionCount %>
									</td>

									<td>
										<%= bidCount %>
									</td>

									<td>
										<%= winCount %>
									</td>

									<td>
										<%= escapeHtml(createdDatetime) %>
									</td>

								</tr>

							<%
									}
								}
							%>

						</tbody>

					</table>

				</div>

				<div class="admin-pagination">
					<!-- 페이징 구현 시 사용 -->
				</div>

			</section>

		</main>

	</div>

</body>
</html>