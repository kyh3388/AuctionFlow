<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>회원가입 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/join.css">
</head>

<body class="register-page">

<!-- 공통 HEADER -->
<jsp:include page="/view/common/header.jsp" />

<main class="main">
	<section class="register">
		<div class="register-inner">
			<div class="title-box">
				<h1 class="title">회원가입</h1>
			</div>

			<form action="${pageContext.request.contextPath}/api/auctionFlow/member/join" method="post" class="form" id="joinForm">

				<div class="form-row">
					<label for="memberId" class="label">아이디</label>
					<div class="input-wrap">
						<input type="text" id="memberId" name="M_ID" class="input" value="${M_ID}" placeholder="아이디를 입력해 주세요." required>
						<!-- 아이디 중복확인 버튼 -->
						<button type="submit" id="idCheckBtn" class="btn-id-check" formaction="${pageContext.request.contextPath}/api/auctionFlow/member/idCheck" formmethod="post" formnovalidate>중복확인</button>
					</div>
					<p class="message id-message ${ID_CHECK_STATUS}">${ID_CHECK_MESSAGE}</p>
				</div>

				<div class="form-row">
					<label for="memberPw" class="label">비밀번호</label>
					<input type="password" id="memberPw" name="M_PW" class="input" placeholder="비밀번호를 입력해 주세요." required>
				</div>

				<div class="form-row">
					<label for="memberPwConfirm" class="label">비밀번호 확인</label>
					<input type="password" id="memberPwConfirm" name="M_PW_CONFIRM" class="input" placeholder="비밀번호를 다시 입력해 주세요." required>
					<p id="pwCheckMessage" class="message pw-check-message" style="color: #d93025"></p>
				</div>

				<div class="form-row">
					<label for="memberName" class="label">이름</label>
					<input type="text" id="memberName" name="M_NAME" class="input" value="${M_NAME}" placeholder="이름을 입력해 주세요." required>
				</div>

				<div class="form-row">
					<label for="memberPhoneNumber" class="label">휴대폰 번호</label>
					<input type="text" id="memberPhoneNumber" name="M_PHONE_NUMBER" class="input phone-auto-format" value="${M_PHONE_NUMBER}" placeholder="010-0000-0000" maxlength="13" inputmode="numeric" required>
				</div>

				<div class="form-row">
					<label for="memberEmail" class="label">이메일</label>
					<input type="email" id="memberEmail" name="M_EMAIL" class="input" value="${M_EMAIL}" placeholder="example@email.com">
				</div>

				<div class="form-row">
					<label for="memberAddress" class="label">주소</label>
					<input type="text" id="memberAddress" name="M_ADDRESS" class="input" value="${M_ADDRESS}" placeholder="주소를 입력해 주세요." required>
				</div>

				<p class="message register-message">${REGISTER_MESSAGE}</p>

				<div class="button-area">
					<button type="submit" class="btn btn-submit">회원가입</button>
					<a href="${pageContext.request.contextPath}/api/auctionFlow/main" class="btn btn-cancel">취소</a>
				</div>
			</form>
		</div>
	</section>
</main>

<!-- 공통 FOOTER -->
<jsp:include page="/view/common/footer.jsp" />

<script type="text/javascript">

	//이유 : 휴대폰 번호를 010-0000-0000 양식으로 입력 받기 위해서
	(function () {

		const phoneInputs = document.querySelectorAll(".phone-auto-format");

		function formatPhoneNumber(value) {
			let phoneNumber = value.replace(/[^0-9]/g, ""); //숫자가 아닌 문자 모두 "" 처리

			if (phoneNumber.length > 11) { //숫자가 11개 넘어가면 자름
				phoneNumber = phoneNumber.substring(0, 11);
			}
			if (phoneNumber.length <= 3) {
				return phoneNumber;
			}
			if (phoneNumber.length <= 7) {
				return (phoneNumber.substring(0, 3) + "-" + phoneNumber.substring(3));
			}
			return (phoneNumber.substring(0, 3) + "-" + phoneNumber.substring(3, 7) + "-" + phoneNumber.substring(7)); //결론적으로 010-0000-0000 형태로 완성됨
		}

		phoneInputs.forEach(function (phoneInput) {
			phoneInput.addEventListener("input", function () {
				phoneInput.value = formatPhoneNumber(phoneInput.value); //사용자가 input에 입력하는 텍스트를 실시간으로 formatPhoneNumber로 전달함.
			});
		});
	})();
</script>

<script type="text/javascript">

	(function () {

		const joinForm = document.getElementById("joinForm");
		const pwInput = document.getElementById("memberPw");
		const pwConfirmInput = document.getElementById("memberPwConfirm");
		const pwCheckMessage = document.getElementById("pwCheckMessage");
		
		function setpwMessage(message, statusClass) {
			pwCheckMessage.textContent = message;
			pwCheckMessage.className = "message pw-check-message " + statusClass;
			
		} function clearpwMessage() {
			pwCheckMessage.textContent = "";
			pwCheckMessage.className = "message pw-check-message";
		}
		
		pwInput.addEventListener("input", clearpwMessage);
		pwConfirmInput.addEventListener("input", clearpwMessage);
		
		joinForm.addEventListener("submit", function (event) {
			const submitter = event.submitter;
			
			if (submitter && submitter.classList.contains("btn-id-check")) {
				return;
			}
			if (pwInput.value !== pwConfirmInput.value) {
				event.preventDefault();
				setpwMessage( "비밀번호와 비밀번호 확인이 일치하지 않습니다.", "ERROR" );
				pwConfirmInput.focus(); return false;
			}
		});
	})();
</script>

</body>
</html>