package auctionFlow.controller;

import auctionFlow.service.MyPageService;
import coreframe.annotations.beans.Inject;
import coreframe.annotations.http.Controller;
import coreframe.annotations.http.UrlMapping;
import coreframe.data.DataSet;
import coreframe.http.RequestData;
import coreframe.http.ViewMeta;

@Controller(urlPattern = "/api/auctionFlow/member/myPage")
public class MyPageController {

	@Inject
	private MyPageService myPageService;

	//1. 경매 등록 내역(마이페이지 최초 진입 화면)
	@UrlMapping("/registerAuctionHistory")
	public void registerAuctionHistory(RequestData data, ViewMeta view) {
		
		try {
			//마이페이지 공통 로그인 및 회원정보 처리
			if (!prepareMyPageCommonData(data, view)) {
				return;
			}
			
			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			//현재 로그인 회원이 등록한 경매 목록 조회
			DataSet registerAuctionHistoryList = myPageService.myPageSelectRegisterAuctionHistory(loginMemberNo);
			view.setAttribute("REGISTER_AUCTION_HISTORY_LIST", registerAuctionHistoryList);

			//경매 등록 내역 메뉴 활성화
			view.setAttribute("ACTIVE_MY_PAGE_MENU", "REGISTER_AUCTION_HISTORY");
			view.setTemplatePage("view/member/myPage/registerHistory");
		} catch (Exception e) {
			throw new RuntimeException("경매 등록 내역 화면 조회 중 오류가 발생했습니다.", e);
		}
	}

	//2. 입찰 내역
	@UrlMapping("/bidHistory")
	public void bidHistory(RequestData data, ViewMeta view) {

		try {
			//마이페이지 공통 로그인 및 회원정보 처리
			if (!prepareMyPageCommonData(data, view)) {
				return;
			}

			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			//현재 로그인 회원의 경매별 입찰 내역 조회
			DataSet bidHistoryList = myPageService.myPageSelectBidHistory(loginMemberNo);
			
			view.setAttribute("BID_HISTORY_LIST", bidHistoryList);
			view.setAttribute("ACTIVE_MY_PAGE_MENU", "BID_HISTORY");

			view.setTemplatePage("view/member/myPage/bidHistory");
		} catch (Exception e) {
			throw new RuntimeException("입찰 내역 화면 조회 중 오류가 발생했습니다.", e);
		}
	}

	//3. 결제/구매 내역
	@UrlMapping("/purchaseHistory")
	public void purchaseHistory(RequestData data, ViewMeta view) {

		try {
			if (!prepareMyPageCommonData(data, view)) {
				return;
			}

			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			//현재 로그인 회원이 낙찰받은 상품 조회
			DataSet purchaseHistoryList = myPageService.myPagePurchaseHistory(loginMemberNo);
			view.setAttribute("PURCHASE_HISTORY_LIST", purchaseHistoryList);

			DataSet params = data.getParameters();

			String result = params.getText("RESULT");
			view.setAttribute("PURCHASE_RESULT", result);

			if ("INVALID_REQUEST".equals(result)) {
				view.setAttribute("PURCHASE_MESSAGE", "구매할 수 없는 상품이거나 이미 구매가 완료된 상품입니다.");
				view.setAttribute("PURCHASE_MESSAGE_TYPE", "error");
			}

			view.setAttribute("ACTIVE_MY_PAGE_MENU", "PURCHASE_HISTORY");

			view.setTemplatePage("view/member/myPage/purchaseHistory");
		} catch (Exception e) {
			throw new RuntimeException("결제/구매 내역 화면 조회 중 오류가 발생했습니다.", e);
		}
	}

	//3-1. 구매 완료 처리
	@UrlMapping("/purchaseComplete")
	public void purchaseComplete(RequestData data, ViewMeta view) {

		try {
			if (!prepareMyPageCommonData(data, view)) {
				return;
			}

			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			DataSet params = data.getParameters();
			String auctionNoText = params.getText("A_NO");
			
			if (auctionNoText == null || auctionNoText.isBlank()) {
				view.setRedirectUrl("./purchaseHistory?RESULT=INVALID_REQUEST");
				return;
			}

			long auctionNo;

			try {
				auctionNo = Long.parseLong(auctionNoText);
			} catch (NumberFormatException e) {
				view.setRedirectUrl("./purchaseHistory?RESULT=INVALID_REQUEST");
				return;
			}

			if (auctionNo <= 0) {
				view.setRedirectUrl("./purchaseHistory?RESULT=INVALID_REQUEST");
				return;
			}

			//Service에서 현재 회원이 실제 낙찰자인지, 구매 전 상품인지 확인한 뒤 구매 완료 처리
			boolean purchaseCompleted = myPageService.myPageCompletePurchase(auctionNo, loginMemberNo);

			if (!purchaseCompleted) {
				view.setRedirectUrl("./purchaseHistory?RESULT=INVALID_REQUEST");
				return;
			}

			view.setRedirectUrl("./purchaseHistory?RESULT=SUCCESS");
		} catch (Exception e) {
			throw new RuntimeException("구매 완료 처리 중 오류가 발생했습니다.", e);
		}
	}

	//4. 회원정보 수정
	@UrlMapping("/editProfile")
	public void editProfile(RequestData data, ViewMeta view) {

		try {
			if (!prepareMyPageCommonData(data, view)) {
				return;
			}

			Long loginMemberNo = getLoginMemberNo(data);
			
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			boolean editProfileVerified = isEditProfileVerified(data, loginMemberNo);

			//비밀번호 확인 전에는 비밀번호 입력 화면을 표시하고, 확인 후에는 회원정보 수정 폼을 표시한다.
			if (editProfileVerified) {
				DataSet profileData = myPageService.myPageSelectProfile(loginMemberNo);

				if (profileData == null || profileData.getCount("M_NO") == 0) {
					view.setRedirectUrl("../loginForm");
					return;
				}

				view.setAttribute("EDIT_PROFILE_STEP", "FORM");
				view.setAttribute("PROFILE_DATA", profileData);
			} else {
				view.setAttribute("EDIT_PROFILE_STEP", "PASSWORD");
			}

			DataSet params = data.getParameters();
			String result = params.getText("RESULT");

			setEditProfileResultMessage(result, view);
			view.setAttribute("ACTIVE_MY_PAGE_MENU", "EDIT_PROFILE");

			//실제 JSP 경로 반영
			view.setTemplatePage("view/member/myPage/editProfile");
		} catch (Exception e) {
			throw new RuntimeException("회원정보 수정 화면 조회 중 오류가 발생했습니다.", e);
		}
	}
	
	//4-1. 회원정보 수정 본인 확인
	@UrlMapping("/editProfileCheck")
	public void editProfileCheck(RequestData data, ViewMeta view) {

		try {
			if (!prepareMyPageCommonData(data, view)) return;
			
			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			DataSet params = data.getParameters();
			
			String currentPassword = params.getText("CURRENT_PASSWORD");

			if (currentPassword == null || currentPassword.isBlank()) {
				clearEditProfileVerification(data);
				view.setRedirectUrl("./editProfile?RESULT=PASSWORD_EMPTY");
				return;
			}

			boolean passwordMatched = myPageService.myPageCheckPassword(loginMemberNo, currentPassword);

			if (!passwordMatched) {
				clearEditProfileVerification(data);
				view.setRedirectUrl("./editProfile?RESULT=PASSWORD_MISMATCH");
				return;
			}

			//비밀번호 확인 시각과 회원 번호를 함께 저장한다. 확인 결과는 10분 동안 유효하다.
			data.getSession().setAttribute("EDIT_PROFILE_VERIFIED_MEMBER_NO", loginMemberNo);
			data.getSession().setAttribute("EDIT_PROFILE_VERIFIED_AT", System.currentTimeMillis());

			view.setRedirectUrl("./editProfile");
		} catch (Exception e) {
			throw new RuntimeException("회원정보 수정 본인 확인 중 오류가 발생했습니다.", e);
		}
	}

	//4-2. 회원정보 수정 처리
	@UrlMapping("/editProfileProcess")
	public void editProfileProcess(RequestData data, ViewMeta view) {
		
		try {
			if (!prepareMyPageCommonData(data, view)) return;

			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			//비밀번호 본인 확인을 거치지 않은 요청 차단
			if (!isEditProfileVerified(data, loginMemberNo)) {
				clearEditProfileVerification(data);
				view.setRedirectUrl("./editProfile?RESULT=VERIFICATION_REQUIRED");
				return;
			}

			DataSet params = data.getParameters();

			//이름도 수정 파라미터로 받음
			String memberName = params.getText("M_NAME");
			String memberPhoneNumber = params.getText("M_PHONE_NUMBER");
			String memberEmail = params.getText("M_EMAIL");
			String memberAddress = params.getText("M_ADDRESS");

			if (isEmpty(memberName) || isEmpty(memberPhoneNumber) || isEmpty(memberEmail) || isEmpty(memberAddress)) {
				view.setRedirectUrl("./editProfile?RESULT=EMPTY");
				return;
			}

			memberName = memberName.trim();
			memberPhoneNumber = memberPhoneNumber.trim();
			memberEmail = memberEmail.trim();
			memberAddress = memberAddress.trim();

			//휴대폰 번호 서버 검증
			if (!memberPhoneNumber.matches("^010-\\d{4}-\\d{4}$")) {
				view.setRedirectUrl("./editProfile?RESULT=INVALID_PHONE");
				return;
			}

			// 이메일 서버 검증
			if (!memberEmail.matches("^[^\\s@]+@[^\\s@]+$")) {
				view.setRedirectUrl("./editProfile?RESULT=INVALID_EMAIL");
				return;
			}

			//이름, 휴대폰 번호, 이메일, 주소를 수정한다.
			myPageService.myPageUpdateProfile(loginMemberNo, memberName, memberPhoneNumber, memberEmail, memberAddress);

			// 본인 확인 유효시간 갱신
			data.getSession().setAttribute("EDIT_PROFILE_VERIFIED_AT", System.currentTimeMillis());

			view.setRedirectUrl("./editProfile?RESULT=SUCCESS");
		} catch (Exception e) {
			throw new RuntimeException("회원정보 수정 처리 중 오류가 발생했습니다.", e);
		}
	}

	//4-3. 회원정보 수정 본인 확인 유효 여부
	private boolean isEditProfileVerified(RequestData data, long loginMemberNo) {
		Object verifiedMemberNoObject = data.getSession().getAttribute("EDIT_PROFILE_VERIFIED_MEMBER_NO");
		Object verifiedAtObject = data.getSession().getAttribute("EDIT_PROFILE_VERIFIED_AT");

		if (verifiedMemberNoObject == null || verifiedAtObject == null) {
			return false;
		}

		long verifiedMemberNo;
		long verifiedAt;

		try {
			if (verifiedMemberNoObject instanceof Number) {
				verifiedMemberNo = ((Number) verifiedMemberNoObject).longValue();
			} else {
				verifiedMemberNo = Long.parseLong(verifiedMemberNoObject.toString());
			}

			if (verifiedAtObject instanceof Number) {
				verifiedAt = ((Number) verifiedAtObject).longValue();
			} else {
				verifiedAt = Long.parseLong(verifiedAtObject.toString());
			}
		} catch (Exception e) {
			clearEditProfileVerification(data);
			return false;
		}

		if (verifiedMemberNo != loginMemberNo) {
			clearEditProfileVerification(data);
			return false;
		}

		long elapsedTime = System.currentTimeMillis() - verifiedAt;
		
		long verificationValidTime = 5L * 60L * 1000L; //5분 유지

		if (elapsedTime < 0 || elapsedTime > verificationValidTime) {
			clearEditProfileVerification(data);
			return false;
		}
		return true;
	}

	//4-4. 회원정보 수정 본인 확인 세션 삭제
	private void clearEditProfileVerification(RequestData data) {
		data.getSession().removeAttribute("EDIT_PROFILE_VERIFIED_MEMBER_NO");
		data.getSession().removeAttribute("EDIT_PROFILE_VERIFIED_AT");
	}

	//4-5. 회원정보 수정 결과 메시지 설정
	private void setEditProfileResultMessage(String result, ViewMeta view) {

		if ("SUCCESS".equals(result)) {
			view.setAttribute("EDIT_PROFILE_MESSAGE", "회원정보가 수정되었습니다.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "success");
			return;
		}

		if ("PASSWORD_EMPTY".equals(result)) {
			view.setAttribute("EDIT_PROFILE_MESSAGE", "비밀번호를 입력해 주세요.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "error");
			return;
		}

		if ("PASSWORD_MISMATCH".equals(result)) {
			view.setAttribute("EDIT_PROFILE_MESSAGE", "비밀번호가 일치하지 않습니다.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "error");
			return;
		}

		if ("VERIFICATION_REQUIRED".equals(result)) {
			view.setAttribute("EDIT_PROFILE_MESSAGE", "회원정보 수정을 위해 비밀번호를 다시 확인해 주세요.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "error");
			return;
		}

		if ("EMPTY".equals(result)) {
			//이름을 필수 입력 항목에 추가
			view.setAttribute("EDIT_PROFILE_MESSAGE", "이름, 휴대폰 번호, 이메일, 주소를 모두 입력해 주세요.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "error");
			return;
		}

		if ("INVALID_PHONE".equals(result)) {
			view.setAttribute("EDIT_PROFILE_MESSAGE", "휴대폰 번호는 010-0000-0000 형식으로 입력해 주세요.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "error");
			return;
		}

		if ("INVALID_EMAIL".equals(result)) {
			view.setAttribute("EDIT_PROFILE_MESSAGE", "@ 앞뒤에 문자를 한 글자 이상 입력해 주세요.");
			view.setAttribute("EDIT_PROFILE_MESSAGE_TYPE", "error");
		}
	}

	//4-6. 빈 문자열 확인
	private boolean isEmpty(String value) {
		return value == null || value.isBlank();
	}

	//5. 비밀번호 변경 화면
	@UrlMapping("/changePassword")
	public void changePassword(RequestData data, ViewMeta view) {

		try {
			if (!prepareMyPageCommonData(data, view)) return;

			DataSet params = data.getParameters();
			String result = params.getText("RESULT");

			//처리 결과에 따른 안내 메시지 설정
			setChangePasswordResultMessage(result, view);
			view.setAttribute("ACTIVE_MY_PAGE_MENU", "CHANGE_PASSWORD");

			view.setTemplatePage("view/member/myPage/changePassword");
		} catch (Exception e) {
			throw new RuntimeException("비밀번호 변경 화면 조회 중 오류가 발생했습니다.", e);
		}
	}

	//5-1. 비밀번호 변경 처리
	@UrlMapping("/changePasswordProcess")
	public void changePasswordProcess(RequestData data, ViewMeta view) {
		try {
			if (!prepareMyPageCommonData(data, view)) return;

			Long loginMemberNo = getLoginMemberNo(data);
			if (loginMemberNo == null) {
				view.setRedirectUrl("../loginForm");
				return;
			}

			DataSet params = data.getParameters();

			String currentPassword = params.getText("CURRENT_PASSWORD");
			String newPassword = params.getText("NEW_PASSWORD");
			String newPasswordConfirm = params.getText("NEW_PASSWORD_CONFIRM");

			//현재 비밀번호 공백 검사
			if (isEmpty(currentPassword)) {
				view.setRedirectUrl("./changePassword?RESULT=CURRENT_PASSWORD_EMPTY");
				return;
			}

			//새 비밀번호 공백 검사
			if (isEmpty(newPassword)) {
				view.setRedirectUrl("./changePassword?RESULT=NEW_PASSWORD_EMPTY");
				return;
			}

			//새 비밀번호 확인 공백 검사
			if (isEmpty(newPasswordConfirm)) {
				view.setRedirectUrl("./changePassword?RESULT=NEW_PASSWORD_CONFIRM_EMPTY");
				return;
			}

			//현재 비밀번호를 검증
			boolean currentPasswordMatched = myPageService.myPageCheckPassword(loginMemberNo, currentPassword);

			if (!currentPasswordMatched) {
				view.setRedirectUrl("./changePassword?RESULT=CURRENT_PASSWORD_MISMATCH");
				return;
			}

			//새 비밀번호와 새 비밀번호 확인 일치 검사
			if (!newPassword.equals(newPasswordConfirm)) {
				view.setRedirectUrl("./changePassword?RESULT=NEW_PASSWORD_MISMATCH");
				return;
			}

			//현재 비밀번호와 동일한 비밀번호 사용 차단
			if (currentPassword.equals(newPassword)) {
				view.setRedirectUrl("./changePassword?RESULT=SAME_PASSWORD");
				return;
			}

			//Service에서 새 비밀번호를 해시한 뒤 DB 수정
			myPageService.myPageUpdatePassword(loginMemberNo, newPassword);

			//비밀번호 변경 전에 회원정보 수정 인증을 받았더라도 기존 본인 확인 상태를 삭제
			clearEditProfileVerification(data);

			view.setRedirectUrl("./changePassword?RESULT=SUCCESS");
		} catch (Exception e) {
			throw new RuntimeException("비밀번호 변경 처리 중 오류가 발생했습니다.", e);
		}
	}

	//5-2. 비밀번호 변경 결과 메시지 설정
	private void setChangePasswordResultMessage(String result, ViewMeta view) {
		if ("SUCCESS".equals(result)) {
			view.setAttribute("CHANGE_PASSWORD_MESSAGE_TYPE", "success");
			return;
		}
		if ("CURRENT_PASSWORD_EMPTY".equals(result)) {
			view.setAttribute("CURRENT_PASSWORD_MESSAGE", "현재 비밀번호를 입력해 주세요.");
			return;
		}
		if ("CURRENT_PASSWORD_MISMATCH".equals(result)) {
			view.setAttribute("CURRENT_PASSWORD_MESSAGE", "현재 비밀번호가 일치하지 않습니다.");
			return;
		}
		if ("NEW_PASSWORD_EMPTY".equals(result)) {
			view.setAttribute("NEW_PASSWORD_MESSAGE", "새 비밀번호를 입력해 주세요.");
			return;
		}
		if ("NEW_PASSWORD_CONFIRM_EMPTY".equals(result)) {
			view.setAttribute("NEW_PASSWORD_CONFIRM_MESSAGE", "새 비밀번호 확인을 입력해 주세요.");
			return;
		}
		if ("NEW_PASSWORD_MISMATCH".equals(result)) {
			view.setAttribute("NEW_PASSWORD_CONFIRM_MESSAGE", "새 비밀번호가 일치하지 않습니다.");
			return;
		}
		if ("SAME_PASSWORD".equals(result)) {
			view.setAttribute("NEW_PASSWORD_MESSAGE", "현재 비밀번호와 다른 비밀번호를 입력해 주세요.");
		}
	}


	//6. 마이페이지 공통 데이터 설정
	private boolean prepareMyPageCommonData(RequestData data, ViewMeta view) throws Exception {

		Long loginMemberNo = getLoginMemberNo(data); //현재 세션에서 로그인 회원 번호 조회, 없으면 null

		if (loginMemberNo == null) {
			view.setRedirectUrl("../loginForm");
			return false;
		}

		DataSet memberSummary = myPageService.myPageSelectMemberSummary(loginMemberNo);

		if (memberSummary == null || memberSummary.getCount("M_NO") == 0) {
			view.setRedirectUrl("../loginForm");
			return false;
		}

		view.setAttribute("LOGIN_M_NO", memberSummary.getLong("M_NO", 0));
		view.setAttribute("LOGIN_M_ID", memberSummary.getLong("M_ID", 0));
		view.setAttribute("LOGIN_M_NAME", memberSummary.getText("M_NAME", 0));
		return true;
	}


	//7. 로그인 회원 번호 조회
	private Long getLoginMemberNo(RequestData data) {

		Object loginMemberNoObject = data.getSession().getAttribute("LOGIN_MEMBER_NO");

		if (loginMemberNoObject == null) {
			return null;
		}

		if (loginMemberNoObject instanceof Number) {
			return ((Number) loginMemberNoObject).longValue();
		}

		try {
			return Long.parseLong(loginMemberNoObject.toString());
		} catch (Exception e) {
			return null;
		}
	}
}