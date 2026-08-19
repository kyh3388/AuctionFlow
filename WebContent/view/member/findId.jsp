<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>

<%
	boolean isLogin = session.getAttribute("LOGIN_MEMBER_NO") != null;
%>

<%
	String findIdMessage = (String) request.getAttribute("FIND_ID_MESSAGE");
	DataSet foundMemberIdList = (DataSet) request.getAttribute("FOUND_MEMBER_ID_LIST");
	
	int foundMemberIdCount = 0;
	if (foundMemberIdList != null) {
		foundMemberIdCount = foundMemberIdList.getCount("M_ID");
	}
	
	String findType = (String) request.getAttribute("FIND_TYPE");
	if (findType == null || findType.isBlank()) {
		findType = "PHONE";
	}
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>아이디 찾기 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/findId.css">
</head>

<body class="find-id-page">

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
				<button type="button" class="search-open-btn" id="searchOpenBtn" aria-label="검색 열기">
					<img src="<%= request.getContextPath() %>/static/img/search-icon.png" alt="search-icon" class="search-icon">
				</button>
			</div>
		</div>
	</div>
	
	<div class="header-bottom">
		<nav class="nav">
			<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/registerForm" class="nav-link">경매 등록</a>	
			<a href="${pageContext.request.contextPath}/api/auctionFlow/main" class="nav-link">진행 경매</a>
			<a href="${pageContext.request.contextPath}/api/auctionFlow/auction/pastList" class="nav-link">지난 경매</a>
		</nav>
	</div>
</header>










<!--########################################## 이하부터 수정 ##########################################-->
<main class="main">
	
	<section class="find-id">
		
		<div class="find-id-inner">
			
			<h1 class="find-id-title">아이디 찾기</h1>
			
			<div class="find-id-guide">
				<p class="find-id-guide-text">· 회원정보에 등록된 정보로 아이디를 찾을 수 있습니다.</p>
				<p class="find-id-guide-text">· 가입 시 입력한 정보를 입력하신 후<strong>아이디 찾기 버튼을 클릭해 주세요.</strong></p>
			</div>
			
			<form action="${pageContext.request.contextPath}/api/auctionFlow/member/findId" method="post" class="find-id-form">
			
				<div class="find-id-method">
					<label for="findTypePhone" class="find-id-radio-label">
						<input type="radio" id="findTypePhone" name="FIND_TYPE" value="PHONE" class="find-id-radio" <%= "PHONE".equals(findType) ? "checked" : "" %>>
						<span class="find-id-radio-text">휴대폰 번호로 찾기</span>
					</label>
						
					<label for="findTypeEmail" class="find-id-label">
						<input type="radio" id="findTypeEmail" name="FIND_TYPE" value="EMAIL" class="find-id-radio" <%= "EMAIL".equals(findType) ? "checked" : "" %>>
						<span class="find-id-radio-text">이메일로 찾기</span>
					</label>	
				</div>
				
				<div class="find-id-input-area">

					<div class="find-id-row">
						<label for="memberName" class="find-id-label">이름</label>
						<input type="text" id="memberName" name="M_NAME" class="find-id-input" value="${M_NAME}" required>
					</div>

					<div class="find-id-row <%= "EMAIL".equals(findType) ? "is-hidden" : "" %>" id="phoneRow">
						<label for="memberPhoneNumber" class="find-id-label">휴대폰 번호</label>
						<input
							type="text" id="memberPhoneNumber"
							name="M_PHONE_NUMBER" class="find-id-input phone-auto-format"
							value="${M_PHONE_NUMBER}" placeholder="010-0000-0000"
							maxlength="13" inputmode="numeric"
							<%= "EMAIL".equals(findType) ? "disabled" : "" %>>
					</div>

					<div class="find-id-row <%= "PHONE".equals(findType) ? "is-hidden" : "" %>" id="emailRow">
						<label for="memberEmail" class="find-id-label">이메일 주소</label>
						<input
							type="email" id="memberEmail"
							name="M_EMAIL" class="find-id-input"
							value="${M_EMAIL}" placeholder="example@email.com"
							<%= "PHONE".equals(findType) ? "disabled" : "" %>>
					</div>
				</div>

				<%
					if (findIdMessage != null && !findIdMessage.isBlank() && foundMemberIdCount == 0) {
				%>
					<p class="find-id-message"><%= findIdMessage %></p>
				<%
					}
				%>

				<div class="find-id-button-area">
					<button type="submit" class="find-id-btn">아이디 찾기</button>
				</div>
			</form>

			<div class="find-id-notice">
				<h2 class="find-id-notice-title">안내사항</h2>
				<p class="find-id-notice-text">· 아이디를 찾으실 수 없을 경우, 가입 시 입력한 정보를 다시 확인해 주세요.</p>
				<p class="find-id-notice-text">· 휴대폰 번호 또는 이메일이 변경된 경우 아이디 찾기가 제한될 수 있습니다.</p>
			</div>
		</div>
	</section>
	
	<%
		if (foundMemberIdCount > 0) {
	%>
		<dialog class="find-id-dialog" id="findIdDialog">
	
			<div class="find-id-dialog-inner">
	
				<h2 class="find-id-dialog-title">
					
					회원정보와 일치하는 아이디입니다.
					
					<%
						for (int i = 0; i < foundMemberIdCount; i++) {
							String foundMemberId = foundMemberIdList.getText("M_ID", i);
					%>
						<br>
						<strong><%= foundMemberId %></strong>
					<%
						}
					%>
				</h2>
	
				<div class="find-id-dialog-guide">
					<p class="find-id-dialog-text">· 입력한 정보와 일치하는 아이디를 모두 표시했습니다.</p>
					<p class="find-id-dialog-text">· 사용할 아이디를 확인한 후 로그인해 주세요.</p>
				</div>
	
				<div class="find-id-dialog-button-area">
					<button type="button" class="find-id-dialog-confirm-btn" id="findIdDialogConfirmBtn">확인</button>
				</div>
			</div>
		</dialog>
	<%
		}
	%>
</main>
<!--################################################################################################-->










<!-- FOOTER -->
<footer class="footer">
	<div class="footer-inner">
		<nav class="footer-menu">
			<a href="#" class="footer-link">개인정보처리방침</a>
			<a href="#" class="footer-link">경매약관</a>
			<a href="#" class="footer-link">내부관리규정</a>
		</nav>
		<p class="footer-text">AuctionFlow는 학습 및 프로젝트 목적으로 구현하는 온라인 경매 서비스입니다.</p>
	</div>
</footer>
</body>

<script type="text/javascript">
	(function () {

		const findTypePhone = document.getElementById("findTypePhone");
		const findTypeEmail = document.getElementById("findTypeEmail");

		const phoneRow = document.getElementById("phoneRow");
		const emailRow = document.getElementById("emailRow");

		const phoneInput = document.getElementById("memberPhoneNumber");
		const emailInput = document.getElementById("memberEmail");

		if (!findTypePhone || !findTypeEmail || !phoneRow || !emailRow || !phoneInput || !emailInput) {
			return;
		}

		function changeFindType() {

			if (findTypePhone.checked) {
				phoneRow.classList.remove("is-hidden");
				emailRow.classList.add("is-hidden");

				phoneInput.disabled = false;
				emailInput.disabled = true;
			} else {
				phoneRow.classList.add("is-hidden");
				emailRow.classList.remove("is-hidden");

				phoneInput.disabled = true;
				emailInput.disabled = false;
			}
		}
		
		findTypePhone.addEventListener("change", changeFindType);
		findTypeEmail.addEventListener("change", changeFindType);

		changeFindType();
	})();
</script>

<script>
	(function () {
		const findIdDialog = document.getElementById("findIdDialog");
		const findIdDialogCloseBtn = document.getElementById("findIdDialogCloseBtn");
		const findIdDialogConfirmBtn = document.getElementById("findIdDialogConfirmBtn");

		if (findIdDialog) {
			findIdDialog.showModal();
		}

		function closeFindIdDialog() {
			if (findIdDialog) {
				findIdDialog.close();
			}
		}

		if (findIdDialogCloseBtn) {
			findIdDialogCloseBtn.addEventListener("click", closeFindIdDialog);
		}

		if (findIdDialogConfirmBtn) {
			findIdDialogConfirmBtn.addEventListener("click", function () {
				window.location.href = "${pageContext.request.contextPath}/api/auctionFlow/member/loginForm";
			});
		}
	})();
</script>

<script type="text/javascript">
	(function () {
		const phoneInputs = document.querySelectorAll(".phone-auto-format");

		function formatPhoneNumber(value) {
			let phoneNumber = value.replace(/[^0-9]/g, "");

			if (phoneNumber.length > 11) {
				phoneNumber = phoneNumber.substring(0, 11);
			}
			if (phoneNumber.length <= 3) {
				return phoneNumber;
			}
			if (phoneNumber.length <= 7) {
				return (phoneNumber.substring(0, 3) + "-" + phoneNumber.substring(3));
			}

			return (phoneNumber.substring(0, 3) + "-" + phoneNumber.substring(3, 7) + "-" + phoneNumber.substring(7));
		}

		phoneInputs.forEach(function (phoneInput) {
			
			phoneInput.addEventListener("input", function () {
				phoneInput.value = formatPhoneNumber(phoneInput.value);
			});
		});
	})();
</script>
</html>