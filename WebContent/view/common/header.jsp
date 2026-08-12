<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
	boolean isLogin = session.getAttribute("LOGIN_MEMBER_NO") != null;
%>

<!-- HEADER -->
<header class="header">
	<div class="header-top">
		<div class="header-top-inner">
			<div class="header-left">
				<a href="${pageContext.request.contextPath}/api/auctionFlow/main" class="logo">AUCTIONFLOW</a>
			</div>
		
			<div class="user-menu">
				<%
					if (isLogin) {
				%>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/member/logout" class="user-link">로그아웃</a>
					<span class="user-divider">|</span>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/registerAuctionHistory" class="user-link">마이페이지</a>
				<%
					} else {
				%>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/member/loginForm" class="user-link">로그인</a>
					<span class="user-divider">|</span>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/member/joinForm" class="user-link">회원가입</a>
				<%
					}
				%>
				
				<div class="search-wrap" id="searchWrap">
					<button type="button" class="search-open-btn" id="searchOpenBtn" aria-label="검색 열기" aria-expanded="false">
						<img src="<%= request.getContextPath() %>/static/img/search-icon.png" alt="search-icon" class="search-icon">
					</button>
					
					<div class="search-panel" id="searchPanel" aria-hidden="true">
						<form action="${pageContext.request.contextPath}/api/auctionFlow/auction/search" method="get" class="search-form" id="searchForm">
							<input type="search" name="KEYWORD" id="searchKeyword" class="search-input" placeholder="작품명으로 검색" autocomplete="off" maxlength="100">
							<button type="submit" class="search-submit-btn" aria-label="검색 실행">
								<img src="<%= request.getContextPath() %>/static/img/search-icon.png" alt="search-icon" class="search-icon">
							</button>
						</form>
					</div>
				</div>
			</div>
		</div>
	</div>
	
	<div class="header-bottom">
		<nav class="nav">
			<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/registerForm" class="nav-link" id="auctionRegisterLink">경매 등록</a>
			<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/ongoing" class="nav-link">진행 경매</a>
			<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/pastList" class="nav-link">지난 경매</a>
		</nav>
	</div>
</header>

<script type="text/javascript">
document.addEventListener("DOMContentLoaded", function () {

	const searchWrap = document.getElementById("searchWrap");
	const searchOpenBtn = document.getElementById("searchOpenBtn");
	const searchPanel = document.getElementById("searchPanel");
	const searchForm = document.getElementById("searchForm");
	const searchKeyword = document.getElementById("searchKeyword");

	if (!searchWrap || !searchOpenBtn || !searchPanel || !searchForm|| !searchKeyword) {
		return;
	}

	function openSearchPanel() {
		searchPanel.classList.add("open");
		searchOpenBtn.setAttribute("aria-expanded", "true");
		searchPanel.setAttribute("aria-hidden", "false");
		
		window.setTimeout(function () {
			searchKeyword.focus();
		}, 50);
	}

	function closeSearchPanel() {
		searchPanel.classList.remove("open");
		searchOpenBtn.setAttribute("aria-expanded", "false");
		searchPanel.setAttribute("aria-hidden", "true");
	}

	function toggleSearchPanel() {
		if (searchPanel.classList.contains("open")) {
			closeSearchPanel();
		} else {
			openSearchPanel();
		}
	}

	searchOpenBtn.addEventListener("click", function (event) {
			event.stopPropagation();
			toggleSearchPanel();
		});

	searchPanel.addEventListener("click", function (event) {
			event.stopPropagation();
		});

	document.addEventListener("click", function (event) {
			if (!searchWrap.contains(event.target)) {
				closeSearchPanel();
			}
		});

	document.addEventListener("keydown", function (event) {
			if (event.key === "Escape") {
				closeSearchPanel();
				searchOpenBtn.focus();
			}
		});

	searchForm.addEventListener("submit", function (event) {
			const keyword = searchKeyword.value.trim();

			if (keyword.length === 0) {
				event.preventDefault();
				searchKeyword.value = "";
				searchKeyword.focus();
				return;
			}

			searchKeyword.value = keyword;
		});
});
</script>

<script>
(function () {
	const auctionRegisterLink = document.getElementById("auctionRegisterLink");
	const isLogin = <%= isLogin ? "true" : "false" %>;
	
	if (!auctionRegisterLink) {
		return
	}
	
	auctionRegisterLink.addEventListener("click", function (event) {
		
		//로그인 상태일 경우
		if (isLogin) {
			return;
		}
		
		//비로그인 상태일 경우
		event.preventDefault();
		alert("로그인 후 경매를 등록할 수 있습니다.");
		window.location.href = "${pageContext.request.contextPath}/api/auctionFlow/member/loginForm";
	});
})();
</script>