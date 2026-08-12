<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="coreframe.data.DataSet" %>

<%!
	private String escapeHtml(String value) {
	
		if (value == null) { return ""; }
		return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
	}
%>

<%
	String editProfileStep = (String) request.getAttribute("EDIT_PROFILE_STEP");

	if (editProfileStep == null) {
		editProfileStep = "PASSWORD";
	}

	String editProfileMessage = (String) request.getAttribute("EDIT_PROFILE_MESSAGE");
	String editProfileMessageType = (String) request.getAttribute("EDIT_PROFILE_MESSAGE_TYPE");

	if (editProfileMessage == null) {
		editProfileMessage = "";
	}

	if (editProfileMessageType == null) {
		editProfileMessageType = "";
	}

	DataSet profileData = (DataSet) request.getAttribute("PROFILE_DATA");

	String memberId = "";
	String memberName = "";
	String memberPhoneNumber = "";
	String memberEmail = "";
	String memberAddress = "";

	if (profileData != null && profileData.getCount("M_NO") > 0) {
		memberId = profileData.getText("M_ID", 0);
		memberName = profileData.getText("M_NAME", 0);
		memberPhoneNumber = profileData.getText("M_PHONE_NUMBER", 0);
		memberEmail = profileData.getText("M_EMAIL", 0);
		memberAddress = profileData.getText("M_ADDRESS", 0);
	}
%>

<!DOCTYPE html>
<html lang="ko">
<head>
	<meta charset="UTF-8">
	<title>회원정보 수정</title>
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/common/sidebar.css">
	<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/member/myPage/editProfile.css">
</head>

<body class="mypage-body edit-profile-page">

<jsp:include page="/view/common/header.jsp" />

<main class="mypage-main">

	<div class="mypage-layout">

		<jsp:include page="/view/member/myPage/common/sidebar.jsp" />

		<section class="mypage-content">
			<div class="mypage-content-header">
				<h1 class="mypage-page-title">회원정보 수정</h1>
				
				<%
					if ("PASSWORD".equals(editProfileStep)) {
				%>
					<p class="mypage-page-description">회원정보 수정을 위해 본인 확인이 필요합니다. 회원님의 비밀번호를 다시 한번 입력해 주세요.</p>
				<%
					} else {
				%>
					<p class="mypage-page-description">회원정보를 확인하고 수정할 수 있습니다.</p>
				<%
					}
				%>
			</div>

			<%
				if ("PASSWORD".equals(editProfileStep)) {
			%>
				<div class="edit-profile-password-panel">
					<div class="edit-profile-password-guide">
						<strong class="edit-profile-password-guide-title">회원정보를 안전하게 보호합니다.</strong>
						<p class="edit-profile-password-guide-text">회원정보 수정을 위해 현재 비밀번호를 입력해 주세요.</p>
					</div>

					<form
						action="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/editProfileCheck"
						method="post"
						id="editProfilePasswordForm"
						class="edit-profile-password-form"
						novalidate>

						<div class="edit-profile-password-row">
							<label for="currentPassword" class="edit-profile-password-label">비밀번호</label>
							<div class="edit-profile-password-field">
								<input type="password" id="currentPassword" name="CURRENT_PASSWORD"
									   class="edit-profile-input" autocomplete="current-password" required>
								<p id="currentPasswordMessage" class="edit-profile-validation-message" <%= escapeHtml(editProfileMessageType) %> aria-live="polite"><%= escapeHtml(editProfileMessage) %></p>
							</div>
						</div>

						<div class="edit-profile-button-area">
							<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/registerAuctionHistory" class="edit-profile-button cancel">취소</a>
							<button type="submit" id="passwordCheckButton" class="edit-profile-button submit">회원정보 수정</button>
						</div>
					</form>
				</div>
			<%
				} else {
			%>
				<div class="edit-profile-panel">
					<div class="edit-profile-required-guide">
						<p id="editProfileMessage" class="edit-profile-message <%= escapeHtml(editProfileMessageType) %>" aria-live="polite"><%= escapeHtml(editProfileMessage) %></p>
						<span class="edit-profile-required-text"><span class="edit-profile-required">*</span>필수 입력</span>
					</div>

					<form action="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/editProfileProcess"
						  method="post" id="editProfileForm" class="edit-profile-form" novalidate>
						<div class="edit-profile-row">
							<label for="memberId" class="edit-profile-label">아이디</label>
							<div class="edit-profile-field">
								<input type="text" id="memberId" class="edit-profile-input readonly"
									   value="<%= escapeHtml(memberId) %>" readonly aria-readonly="true">
								<p class="edit-profile-field-description">아이디는 변경할 수 없습니다.</p>
							</div>
						</div>

						<div class="edit-profile-row">
							<label for="memberName" class="edit-profile-label">이름<span class="edit-profile-required">*</span></label>
							<div class="edit-profile-field">
								<!-- 이름을 수정 가능한 필수 입력값으로 변경 -->
								<input type="text" id="memberName" name="M_NAME" class="edit-profile-input"
									value="<%= escapeHtml(memberName) %>" placeholder="이름을 입력해 주세요." autocomplete="name" required>
								<p id="memberNameMessage" class="edit-profile-validation-message"></p>
							</div>
						</div>

						<div class="edit-profile-row">
							<label for="memberPhoneNumber" class="edit-profile-label">휴대폰 번호<span class="edit-profile-required">*</span></label>
							<div class="edit-profile-field">
								<input type="text" id="memberPhoneNumber" name="M_PHONE_NUMBER" class="edit-profile-input"
									   value="<%= escapeHtml(memberPhoneNumber) %>" placeholder="010-0000-0000"
									   maxlength="13" inputmode="numeric" autocomplete="tel" required>
								<p id="memberPhoneNumberMessage" class="edit-profile-validation-message"></p>
							</div>
						</div>

						<div class="edit-profile-row">
							<label for="memberEmail" class="edit-profile-label">이메일<span class="edit-profile-required">*</span></label>
							<div class="edit-profile-field">
								<input type="email" id="memberEmail" name="M_EMAIL" class="edit-profile-input"
									   value="<%= escapeHtml(memberEmail) %>" placeholder="example@email.com" autocomplete="email" required>
								<p id="memberEmailMessage" class="edit-profile-validation-message"></p>
							</div>
						</div>

						<div class="edit-profile-row">
							<label for="memberAddress" class="edit-profile-label">주소
								<span class="edit-profile-required">*</span>
							</label>
							<div class="edit-profile-field">
								<input type="text" id="memberAddress" name="M_ADDRESS" class="edit-profile-input"
									   value="<%= escapeHtml(memberAddress) %>" placeholder="주소를 입력해 주세요." autocomplete="street-address" required>
								<p id="memberAddressMessage" class="edit-profile-validation-message"></p>
							</div>
						</div>

						<div class="edit-profile-button-area form-buttons">
							<a href="${pageContext.request.contextPath}/api/auctionFlow/member/myPage/registerAuctionHistory" class="edit-profile-button cancel">취소</a>
							<button type="submit" id="editProfileSubmitButton" class="edit-profile-button submit">회원정보 수정</button>
						</div>
					</form>
				</div>
			<%
				}
			%>
		</section>
	</div>
</main>

<jsp:include page="/view/common/footer.jsp" />

<script>
	"use strict";

	document.addEventListener("DOMContentLoaded", function () {

		const passwordForm = document.getElementById("editProfilePasswordForm");

		if (passwordForm) {
			const currentPassword = document.getElementById("currentPassword");
			const currentPasswordMessage = document.getElementById("currentPasswordMessage");
			const passwordCheckButton = document.getElementById("passwordCheckButton");
			passwordForm.addEventListener("submit", function (event) {
					currentPassword.classList.remove("input-error");
					currentPasswordMessage.textContent = "";

					if (currentPassword.value.trim() === "") {
						event.preventDefault();
						currentPassword.classList.add("input-error");
						currentPasswordMessage.textContent = "현재 비밀번호를 입력해 주세요.";
						currentPassword.focus();
						return;
					}
					passwordCheckButton.disabled = true;
					passwordCheckButton.textContent = "확인 중...";
				});

			currentPassword.addEventListener("input", function () {
					this.classList.remove("input-error");
					currentPasswordMessage.textContent = "";
				});
		}


		const editProfileForm = document.getElementById("editProfileForm");

		if (!editProfileForm) {
			return;
		}

		const memberName = document.getElementById("memberName");
		const memberPhoneNumber = document.getElementById("memberPhoneNumber");
		const memberEmail = document.getElementById("memberEmail");
		const memberAddress = document.getElementById("memberAddress");
		const memberNameMessage = document.getElementById("memberNameMessage");
		const memberPhoneNumberMessage = document.getElementById("memberPhoneNumberMessage");
		const memberEmailMessage = document.getElementById("memberEmailMessage");
		const memberAddressMessage = document.getElementById("memberAddressMessage");
		
		const editProfileMessage = document.getElementById("editProfileMessage");
		const editProfileResetButton = document.getElementById("editProfileResetButton");
		const editProfileSubmitButton = document.getElementById("editProfileSubmitButton");
		
		const initialName = memberName.value.trim();
		const initialPhoneNumber = memberPhoneNumber.value.trim();
		const initialEmail = memberEmail.value.trim();
		const initialAddress = memberAddress.value.trim();

		function formatPhoneNumber(value) {
			let phoneNumber = value.replace(/[^0-9]/g, "");
			
			if (phoneNumber.length > 11) {
				phoneNumber = phoneNumber.substring(0, 11);
			}
			if (phoneNumber.length <= 3) {
				return phoneNumber;
			}
			if (phoneNumber.length <= 7) {
				return phoneNumber.substring(0, 3) + "-" + phoneNumber.substring(3);
			}
			return phoneNumber.substring(0, 3) + "-" + phoneNumber.substring(3, 7) + "-" + phoneNumber.substring(7, 11);
		}

		function clearValidation(input, messageElement) {
			input.classList.remove("input-error");
			messageElement.textContent = "";
		}


		function setValidation(input, messageElement, message) {
			input.classList.add("input-error");
			messageElement.textContent = message;
		}

		memberName.addEventListener("input", function () {
				clearValidation(this, memberNameMessage);
			});

		memberPhoneNumber.addEventListener("input", function () {
				this.value = formatPhoneNumber(this.value);
				clearValidation(this, memberPhoneNumberMessage);
			});


		memberEmail.addEventListener("input", function () {
				clearValidation(this, memberEmailMessage);
			});


		memberAddress.addEventListener("input", function () {
				clearValidation(this, memberAddressMessage);
			});


		editProfileResetButton.addEventListener("click", function () {
			
				window.setTimeout(function () {
						clearValidation(memberName, memberNameMessage);
						clearValidation(memberPhoneNumber, memberPhoneNumberMessage);
						clearValidation(memberEmail, memberEmailMessage);
						clearValidation(memberAddress, memberAddressMessage);
						editProfileMessage.textContent = "";
						editProfileMessage.classList.remove("success", "error");
						memberPhoneNumber.value = formatPhoneNumber(memberPhoneNumber.value);
					}, 0);
			});

		editProfileForm.addEventListener("submit", function (event) {
				clearValidation(memberName, memberNameMessage);
				clearValidation(memberPhoneNumber, memberPhoneNumberMessage);
				clearValidation(memberEmail, memberEmailMessage);
				clearValidation(memberAddress, memberAddressMessage);
				memberName.value = memberName.value.trim();
				memberPhoneNumber.value = formatPhoneNumber(memberPhoneNumber.value);
				memberEmail.value = memberEmail.value.trim();
				memberAddress.value = memberAddress.value.trim();

				let isValid = true;

				//이름 필수 검증 추가
				if (memberName.value === "") {
					setValidation(memberName, memberNameMessage, "이름을 입력해 주세요.");
					isValid = false;
				}

				if (!/^010-\d{4}-\d{4}$/.test(memberPhoneNumber.value)) {
					setValidation(memberPhoneNumber, memberPhoneNumberMessage, "휴대폰 번호는 010-0000-0000 형식으로 입력해 주세요.");
					isValid = false;
				}

				if (memberEmail.value === "" || !/^[^\s@]+@[^\s@]+$/.test(memberEmail.value)) {
					setValidation(memberEmail, memberEmailMessage, "@ 앞뒤에 문자를 한 글자 이상 입력해 주세요.");
					isValid = false;
				}

				if (memberAddress.value === "") {
					setValidation(memberAddress, memberAddressMessage, "주소를 입력해 주세요.");
					isValid = false;
				}

				if (!isValid) {
					event.preventDefault();
					return;
				}

				//이름 변경 여부도 검사
				const isChanged = memberName.value !== initialName || memberPhoneNumber.value !== initialPhoneNumber || memberEmail.value !== initialEmail || memberAddress.value !== initialAddress;

				if (!isChanged) {
					event.preventDefault();
					editProfileMessage.textContent = "변경된 회원정보가 없습니다.";
					editProfileMessage.classList.remove("success");
					editProfileMessage.classList.add("error");
					return;
				}

				editProfileSubmitButton.disabled = true;
				editProfileSubmitButton.textContent = "수정 중...";
			});
	});
</script>

</body>
</html>