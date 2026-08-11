<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
	String adminMenu = (String) request.getAttribute("ADMIN_MENU");

	if (adminMenu == null) {
		adminMenu = "";
	}
	String contextPath = request.getContextPath();
%>

<aside class="admin-sidebar">
	<div class="admin-sidebar-header">
		<a href="<%= contextPath %>/api/auctionFlow/admin/dashboard" class="admin-logo">AUCTIONFLOW</a>
		<p class="admin-logo-subtitle">ADMIN</p>
	</div>

	<nav class="admin-sidebar-menu">
		<a href="<%= contextPath %>/api/auctionFlow/admin/dashboard" class="admin-sidebar-link <%= "DASHBOARD".equals(adminMenu) ? "active" : "" %>">통계</a>
		<a href="<%= contextPath %>/api/auctionFlow/admin/member" class="admin-sidebar-link <%= "MEMBER".equals(adminMenu) ? "active" : "" %>">회원 관리</a>
		<a href="<%= contextPath %>/api/auctionFlow/admin/auction" class="admin-sidebar-link <%= "AUCTION".equals(adminMenu) ? "active" : "" %>">경매 관리</a>
	</nav>

	<div class="admin-sidebar-footer">
		<a href="<%= contextPath %>/api/auctionFlow/member/logout" class="admin-logout-link">로그아웃</a>
	</div>
</aside>