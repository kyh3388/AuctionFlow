<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>


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
	String loginMemberName = (String) request.getAttribute("LOGIN_M_NAME");

	String activeMyPageMenu = (String) request.getAttribute("ACTIVE_MY_PAGE_MENU");

	if (loginMemberName == null || loginMemberName.isBlank()) {

		loginMemberName = "회원";
	}

	if (activeMyPageMenu == null) {

		activeMyPageMenu = "REGISTER_AUCTION_HISTORY";
	}
%>


<aside class="mypage-sidebar">

	<div class="mypage-member-area">
	
			<strong class="mypage-member-name"><%= escapeHtml(loginMemberName) %>
				<span>님</span>
			</strong>
	</div>

	<nav class="mypage-sidebar-navigation" aria-label="마이페이지 메뉴">

		<div class="mypage-menu-group">

			<h2 class="mypage-menu-group-title">온라인경매관리</h2>

			<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/registerAuctionHistory" class="mypage-menu-link <%= "REGISTER_AUCTION_HISTORY".equals(activeMyPageMenu) ? "active" : "" %>">경매 등록 내역</a>

			<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/bidHistory" class="mypage-menu-link <%= "BID_HISTORY".equals(activeMyPageMenu) ? "active" : "" %>">입찰 내역</a>

			<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/purchaseHistory" class="mypage-menu-link <%= "PURCHASE_HISTORY".equals(activeMyPageMenu) ? "active" : "" %>">결제/구매 내역</a>
		</div>

		<div class="mypage-menu-group">

			<h2 class="mypage-menu-group-title">회원정보관리</h2>

			<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/editProfile" class="mypage-menu-link <%= "EDIT_PROFILE".equals(activeMyPageMenu) ? "active" : "" %>">회원정보 수정</a>

			<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/changePassword" class="mypage-menu-link <%= "CHANGE_PASSWORD".equals(activeMyPageMenu) ? "active" : "" %>">비밀번호 변경</a>
		</div>
	</nav>
</aside>