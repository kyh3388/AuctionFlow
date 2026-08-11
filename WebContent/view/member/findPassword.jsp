<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
	String tempPassword = (String) request.getAttribute("TEMP_PASSWORD");
%>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>비밀번호 찾기 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/findPassword.css">
</head>

<body class="find-password-page">

<!-- 공통 HEADER -->
<jsp:include page="/view/common/header.jsp" />

<main class="main">

	<section class="find-password">

		<div class="find-password-inner">

			<div class="title-box">
				<h1 class="title">비밀번호 찾기</h1>
			</div>

			<div class="guide-box">

				<p class="guide-text">
					- 비밀번호의 경우, 암호화 저장되어 기존 비밀번호를 확인할 수 없습니다.
				</p>

				<p class="guide-text highlight">
					- 회원정보가 일치하면 임시 비밀번호를 발급해 드립니다.
				</p>

				<p class="guide-text">
					- 발급된 임시 비밀번호로 로그인한 뒤, 마이페이지에서 반드시 비밀번호를 변경해 주세요.
				</p>

			</div>

			<form
				action="${pageContext.request.contextPath}/api/auctionFlow/member/findPassword"
				method="post" class="find-password-form" id="findPasswordForm">

				<div class="find-type-area">

					<label class="find-type-label">
						<input type="radio" name="FIND_TYPE" id="findTypePhone" 
						value="PHONE" ${FIND_TYPE == 'EMAIL' ? '' : 'checked'}>
						<span>휴대폰 번호로 찾기</span>
					</label>

					<label class="find-type-label">
						<input type="radio" name="FIND_TYPE" id="findTypeEmail" 
						value="EMAIL" ${FIND_TYPE == 'EMAIL' ? 'checked' : ''}>
						<span>이메일로 찾기</span>
					</label>

				</div>

				<div class="form-row">

					<label for="memberId" class="label">아이디</label>

					<input type="text" id="memberId" name="M_ID" class="input" value="${M_ID}" required>

				</div>

				<div class="form-row">

					<label for="memberName" class="label">이름</label>

					<input type="text" id="memberName" name="M_NAME" class="input" value="${M_NAME}" required>

				</div>

				<div class="form-row ${FIND_TYPE == 'EMAIL' ? 'is-hidden' : ''}" id="phoneRow">

					<label for="memberPhoneNumber" class="label">휴대폰 번호</label>

					<input
						type="text" id="memberPhoneNumber" name="FIND_PHONE"
						class="input phone-auto-format" value="${FIND_PHONE}"
						placeholder="010-0000-0000" maxlength="13"
						inputmode="numeric" ${FIND_TYPE == 'EMAIL' ? 'disabled' : ''}>
				</div>

				<div class="form-row ${FIND_TYPE == 'EMAIL' ? '' : 'is-hidden'}" id="emailRow">

					<label for="memberEmail" class="label">이메일</label>

					<input
						type="email" id="memberEmail" name="FIND_EMAIL" class="input" value="${FIND_EMAIL}" placeholder="example@email.com" ${FIND_TYPE == 'EMAIL' ? '' : 'disabled'}>

				</div>

				<p class="message find-password-message">${FIND_PASSWORD_MESSAGE}</p>

				<div class="button-area">

					<button type="submit" class="btn btn-submit">비밀번호 찾기</button>
				</div>
			</form>
		</div>
	</section>
	
	<%
		if (tempPassword != null && !tempPassword.isBlank()) {
	%>
	
		<dialog class="find-password-dialog" id="findPasswordDialog">
		
			<div class="find-password-dialog-inner">
			
				<h2 class="find-password-dialog-title">임시 비밀번호가 발급되었습니다 : <Strong><%= tempPassword %></Strong></h2>
				
				<div class="find-password-dialog-guide">
					
					<p class="find-password-dialog-text">· 발급된 임시 비밀번호로 로그인해 주세요.</p>
					<p class="find-password-dialog-text">· 로그인 후 마이페이지에서 반드시 비밀번호를 변경해 주세요.</p>
				</div>
				
				<div class="find-password-dialog-button-area">
					
					<button type="button" class="find-password-dialog-confirm-btn" id="findPasswordDialogConfirmBtn">확인</button>
				</div>
			</div>
		</dialog>
	<%
		}
	%>
</main>

<!-- 공통 FOOTER -->
<jsp:include page="/view/common/footer.jsp" />

<script type="text/javascript">
	(function () {

		const findTypePhone = document.getElementById("findTypePhone");

		const findTypeEmail = document.getElementById("findTypeEmail");

		const phoneRow = document.getElementById("phoneRow");

		const emailRow = document.getElementById("emailRow");

		const phoneInput = document.getElementById("memberPhoneNumber");

		const emailInput = document.getElementById("memberEmail");

		function changeFindType() {

			if (findTypePhone.checked) {

				phoneRow.classList.remove("is-hidden");
				emailRow.classList.add("is-hidden");

				phoneInput.disabled = false;
				emailInput.disabled = true;

				emailInput.value = "";

				return;
			}

			phoneRow.classList.add("is-hidden");
			emailRow.classList.remove("is-hidden");

			phoneInput.disabled = true;
			emailInput.disabled = false;

			phoneInput.value = "";
		}

		findTypePhone.addEventListener("change", changeFindType);

		findTypeEmail.addEventListener("change", changeFindType);

		changeFindType();
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

<script type="text/javascript">

	(function () {

		const findPasswordDialog = document.getElementById("findPasswordDialog");

		const findPasswordDialogCloseBtn = document.getElementById("findPasswordDialogCloseBtn");

		const findPasswordDialogConfirmBtn = document.getElementById("findPasswordDialogConfirmBtn");

		if (findPasswordDialog) {

			findPasswordDialog.showModal();
		}

		function closeFindPasswordDialog() {

			if (findPasswordDialog) {

				findPasswordDialog.close();
			}
		}

		if (findPasswordDialogCloseBtn) {

			findPasswordDialogCloseBtn.addEventListener("click", closeFindPasswordDialog);
		}

		if (findPasswordDialogConfirmBtn) {

			findPasswordDialogConfirmBtn.addEventListener("click", function () {

				window.location.href = "${pageContext.request.contextPath}/api/auctionFlow/member/loginForm";
			});
		}
	})();
</script>

</body>
</html>