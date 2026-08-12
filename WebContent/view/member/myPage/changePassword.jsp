<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%!
	private String escapeHtml(String value) {
		if (value == null) {
			return "";
		}
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}
%>

<%
	String changePasswordMessageType = (String) request.getAttribute("CHANGE_PASSWORD_MESSAGE_TYPE");
	String currentPasswordMessage = (String) request.getAttribute("CURRENT_PASSWORD_MESSAGE");
	String newPasswordMessage = (String) request.getAttribute("NEW_PASSWORD_MESSAGE");
	String newPasswordConfirmMessage = (String) request.getAttribute("NEW_PASSWORD_CONFIRM_MESSAGE");

	if (changePasswordMessageType == null) {
		changePasswordMessageType = "";
	}

	if (currentPasswordMessage == null) {
		currentPasswordMessage = "";
	}

	if (newPasswordMessage == null) {
		newPasswordMessage = "";
	}

	if (newPasswordConfirmMessage == null) {
		newPasswordConfirmMessage = "";
	}
%>

<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>비밀번호 변경</title>
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/sidebar.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/changePassword.css">
</head>

<body class="mypage-body change-password-page">

<jsp:include page="/view/common/header.jsp" />

<main class="mypage-main">

	<div class="mypage-layout">

		<jsp:include page="/view/member/myPage/common/sidebar.jsp" />

		<section class="mypage-content">

			<div class="mypage-content-header">
				<h1 class="mypage-page-title">비밀번호 변경</h1>
				<p class="mypage-page-description">새로운 비밀번호로 변경해 주세요.</p>
			</div>

			<form
				action="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/changePasswordProcess"
				method="post"
				id="changePasswordForm"
				class="change-password-form"
				novalidate>

				<div class="change-password-row">
					<label for="currentPassword" class="change-password-label">현재 비밀번호
						<span class="change-password-required">*</span>
					</label>

					<div class="change-password-field">
						<input type="password" id="currentPassword" name="CURRENT_PASSWORD"
							   class="change-password-input <%= currentPasswordMessage.isBlank() ? "" : "input-error" %>" autocomplete="current-password">
						<p id="currentPasswordMessage" class="change-password-validation-message"><%= escapeHtml(currentPasswordMessage) %></p>
					</div>
				</div>

				<div class="change-password-row">
					<label for="newPassword" class="change-password-label">새 비밀번호
						<span class="change-password-required">*</span>
					</label>

					<div class="change-password-field">
						<input type="password" id="newPassword" name="NEW_PASSWORD"
							   class="change-password-input <%= newPasswordMessage.isBlank() ? "" : "input-error" %>" autocomplete="new-password">
						<p id="newPasswordMessage" class="change-password-validation-message"><%= escapeHtml(newPasswordMessage) %></p>
					</div>
				</div>

				<div class="change-password-row">
					<label for="newPasswordConfirm" class="change-password-label">새 비밀번호 확인
						<span class="change-password-required">*</span>
					</label>

					<div class="change-password-field">
						<input type="password" id="newPasswordConfirm" name="NEW_PASSWORD_CONFIRM"
							   class="change-password-input <%= newPasswordConfirmMessage.isBlank() ? "" : "input-error" %>" autocomplete="new-password">
						<p id="newPasswordConfirmMessage" class="change-password-validation-message"><%= escapeHtml(newPasswordConfirmMessage) %></p>
					</div>
				</div>

				<div class="change-password-button-area">
					<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/registerAuctionHistory" class="change-password-button cancel">취소</a>
					<button type="submit" id="changePasswordSubmitButton" class="change-password-button submit">확인</button>
				</div>
			</form>
		</section>
	</div>
</main>

<jsp:include page="/view/common/footer.jsp" />

<script>
	"use strict";

	document.addEventListener("DOMContentLoaded", function () {

		const passwordChangeSuccess = <%= "success".equals(changePasswordMessageType) %>;

		//비밀번호 변경 성공 시 팝업을 표시한 뒤 메인 화면으로 이동한다.
		if (passwordChangeSuccess) {
			alert("비밀번호가 변경되었습니다.");
			window.location.replace("${pageContext.request.contextPath}/api/auctionFlow/main");
			return;
		}

		const changePasswordForm = document.getElementById("changePasswordForm");

		if (!changePasswordForm) {
			return;
		}

		const currentPassword = document.getElementById("currentPassword");
		const newPassword = document.getElementById("newPassword");
		const newPasswordConfirm = document.getElementById("newPasswordConfirm");
		const currentPasswordMessage = document.getElementById("currentPasswordMessage");
		const newPasswordMessage = document.getElementById("newPasswordMessage");
		const newPasswordConfirmMessage = document.getElementById("newPasswordConfirmMessage");
		const changePasswordSubmitButton = document.getElementById("changePasswordSubmitButton");

		function clearValidation(input, messageElement) {
			input.classList.remove("input-error");
			messageElement.textContent = "";
		}

		function setValidation(input, messageElement, message) {
			input.classList.add("input-error");
			messageElement.textContent = message;
		}

		currentPassword.addEventListener("input", function () {
			clearValidation(this, currentPasswordMessage);
		});

		newPassword.addEventListener("input", function () {
			clearValidation(this, newPasswordMessage);
			clearValidation(newPasswordConfirm, newPasswordConfirmMessage);
		});


		newPasswordConfirm.addEventListener("input", function () {
			clearValidation(this, newPasswordConfirmMessage);
		});


		changePasswordForm.addEventListener("submit", function (event) {
			clearValidation(currentPassword, currentPasswordMessage);
			clearValidation(newPassword, newPasswordMessage);
			clearValidation(newPasswordConfirm, newPasswordConfirmMessage);

			let isValid = true;
			let firstInvalidInput = null;

			if (currentPassword.value.trim() === "") {
				setValidation(currentPassword, currentPasswordMessage, "현재 비밀번호를 입력해 주세요.");
				firstInvalidInput = currentPassword;
				isValid = false;
			}

			if (newPassword.value.trim() === "") {
				
				setValidation(newPassword, newPasswordMessage, "새 비밀번호를 입력해 주세요.");

				if (!firstInvalidInput) {
					firstInvalidInput = newPassword;
				}

				isValid = false;
			}

			if (newPasswordConfirm.value.trim() === "") {
				setValidation(newPasswordConfirm, newPasswordConfirmMessage, "새 비밀번호 확인을 입력해 주세요.");

				if (!firstInvalidInput) {
					firstInvalidInput = newPasswordConfirm;
				}

				isValid = false;
			}

			if (newPassword.value !== "" && newPasswordConfirm.value !== "" && newPassword.value !== newPasswordConfirm.value) {
				setValidation(newPasswordConfirm, newPasswordConfirmMessage, "새 비밀번호가 일치하지 않습니다.");

				if (!firstInvalidInput) {
					firstInvalidInput = newPasswordConfirm;
				}
				isValid = false;
			}

			if (currentPassword.value !== "" && newPassword.value !== "" && currentPassword.value === newPassword.value) {
				setValidation(newPassword, newPasswordMessage, "현재 비밀번호와 다른 비밀번호를 입력해 주세요.");

				if (!firstInvalidInput) {
					firstInvalidInput = newPassword;
				}
				isValid = false;
			}

			if (!isValid) {
				event.preventDefault();

				if (firstInvalidInput) {
					firstInvalidInput.focus();
				}
				return;
			}

			changePasswordSubmitButton.disabled = true;
			changePasswordSubmitButton.textContent = "변경 중...";
		});
	});
</script>
</body>
</html>