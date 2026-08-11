<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>AuctionFlow</title>

<style>
	html,
	body {
		margin: 0;
		padding: 0;
		width: 100%;
		height: 100%;
		background-color: #ffffff;
		font-family: "Malgun Gothic", Arial, sans-serif;
	}

	.error-page {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 16px;
		width: 100%;
		height: 100%;
	}

	.error-message {
		margin: 0;
		color: #333333;
		font-size: 16px;
		font-weight: 400;
	}
	
	.error-link {
		color: #333333;
		font-size: 14px;
		font-weight: 400;
		text-decoration: underline;
	}
	
	.error-link:hover {
		color: #000000;
	}
</style>

</head>

<body>
	<div class="error-page">
		<p class="error-message">이 화면이 보이면 관리자에게 문의해 주세요.</p>
		
		<a href="${pageContext.request.contextPath}/api/auctionFlow/main" class="error-link">홈페이지로 돌아가기</a>
	</div>
</body>
</html>