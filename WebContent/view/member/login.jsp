<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
	String loginMessage = (String) request.getAttribute("LOGIN_MESSAGE");
	String loginSuccess = (String) request.getAttribute("LOGIN_SUCCESS");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>로그인 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/login.css">
</head>

<body class="login-page">

<!-- 공통 HEADER -->
<jsp:include page="/view/common/header.jsp" />

<main class="main">

	<section class="login">
	
		<div class="login-inner">
		
			<h1>로그인</h1>
			
			<form action="${pageContext.request.contextPath}/api/auctionFlow/member/login" method="post" class="login-form">
				
				<div class="form-row">
					
					<label for="memberId" class="blind">아이디</label>
					
					<input type="text" id="memberId" name="M_ID" class="input" placeholder="아이디 입력하기">
				</div>
				
				<div class="form-row">
					
					<label for="memberPassword" class="blind">비밀번호</label>
					
					<input type="password" id="memberPassword" name="M_PW" class="input" placeholder="비밀번호 입력하기">
				</div>
				
				<div class="save-id">
					
					<input type="checkbox" id="saveId" name="SAVE_ID" value="Y" class="check">
					
					<label for="saveId" class="check-label">아이디 저장</label>
				</div>
				
				<%
					if (loginMessage != null && !loginMessage.isBlank()) {
				%>
					<p class="message login-message"><%= loginMessage %></p>
				<%
					}
				%>
				
				<button type="submit" class="btn btn-login">로그인</button>
			</form>
			
			<nav class="login-menu">
				
				<a href="${pageContext.request.contextPath}/api/auctionFlow/member/findIdForm" class="login-link">아이디 찾기</a>		
				<span class="divider">|</span>
				
				<a href="${pageContext.request.contextPath}/api/auctionFlow/member/findPasswordForm" class="login-link">비밀번호 찾기</a>		
				<span class="divider">|</span>
				
				<a href="${pageContext.request.contextPath}/api/auctionFlow/member/joinForm" class="login-link">회원가입</a>		
			</nav>
		</div>
	</section>
</main>

<!-- 공통 FOOTER -->
<jsp:include page="/view/common/footer.jsp" />

<script type="text/javascript">
	
	if ("${JOIN_SUCCESS_ALERT}" === "Y") {

		alert("회원가입을 완료했습니다.");
	}
</script>
</body>
</html>