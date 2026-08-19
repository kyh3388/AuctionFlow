package auctionFlow.controller;

import auctionFlow.service.MemberService;
import coreframe.annotations.beans.Inject;
import coreframe.annotations.http.Controller;
import coreframe.annotations.http.UrlMapping;
import coreframe.data.DataSet;
import coreframe.http.RequestData;
import coreframe.http.ViewMeta;

@Controller(urlPattern = "/api/auctionFlow/member")
public class MemberController {
	
	@Inject
	private MemberService memberService;
	
	private static final String ADMIN_ID = "admin";
	private static final String ADMIN_PW = "admin";
	
	//1. 회원가입 화면 진입
	@UrlMapping("/joinForm")
	public void memberRegisterForm(ViewMeta view) {
		view.setTemplatePage("view/member/join");
	}
	
	//2. 회원가입 시 아이디 중복 확인
	@UrlMapping("/idCheck")
	public void memberIdCheck(RequestData data, ViewMeta view) {

		try {
			DataSet params = data.getParameters();
			String memberId = params.getText("M_ID");
			
			setRegisterFormValues(params, view);
			if (isEmpty(memberId)) {
				view.setAttribute("ID_CHECK_MESSAGE", "아이디를 입력해 주세요.");
				view.setAttribute("ID_CHECK_STATUS", "EMPTY");
				view.setTemplatePage("view/member/join");
				return;
			}
			
			memberId = memberId.trim();
			
			int memberIdCount = memberService.memberIdCheck(memberId);
			view.setAttribute("M_ID", memberId);
			
			if (memberIdCount == 0) {
				view.setAttribute("ID_CHECK_MESSAGE", "사용 가능한 아이디입니다.");
				view.setAttribute("ID_CHECK_STATUS", "AVAILABLE");
			} else {
				view.setAttribute("ID_CHECK_MESSAGE", "이미 사용 중인 아이디입니다.");
				view.setAttribute("ID_CHECK_STATUS", "DUPLICATE");
			}
			
			view.setTemplatePage("view/member/join");
		} catch (Exception e) {
			throw new RuntimeException("아이디 중복 확인 중 오류가 발생했습니다.", e);
		}
	}
	
	//3. 회원가입 처리
	@UrlMapping("/join")
	public void memberRegister(RequestData data, ViewMeta view) {

		try {
			DataSet params = data.getParameters();

			String memberId = params.getText("M_ID");
			String rawPassword = params.getText("M_PW");
			String rawPasswordConfirm = params.getText("M_PW_CONFIRM");
			String memberName = params.getText("M_NAME");
			String memberPhoneNumber = params.getText("M_PHONE_NUMBER");
			String memberEmail = params.getText("M_EMAIL");
			String memberAddress = params.getText("M_ADDRESS");
			
			//입력 실패시 다시 화면에 보여줄 값 세팅
			setRegisterFormValues(params, view);

			if (isEmpty(memberId) || rawPassword == null || rawPassword.isEmpty() || rawPasswordConfirm == null || rawPasswordConfirm.isEmpty() || isEmpty(memberName) || isEmpty(memberPhoneNumber) || isEmpty(memberEmail) || isEmpty(memberAddress)) {
				view.setAttribute("REGISTER_MESSAGE", "회원가입 정보를 모두 입력해 주세요.");
				view.setTemplatePage("view/member/join");
				return;
			}

			if (!rawPassword.equals(rawPasswordConfirm)) {
				view.setAttribute("REGISTER_MESSAGE", "비밀번호와 비밀번호 확인이 일치하지 않습니다.");
				view.setTemplatePage("view/member/join");
				return;
			}

			memberId = memberId.trim();
			memberName = memberName.trim();
			memberPhoneNumber = memberPhoneNumber.trim();
			memberEmail = memberEmail.trim();
			memberAddress = memberAddress.trim();

			if (!memberPhoneNumber.matches("^010-\\d{4}-\\d{4}$")) {
				view.setAttribute("REGISTER_MESSAGE", "휴대폰 번호는 010-0000-0000 형식으로 입력해 주세요.");
				view.setTemplatePage("view/member/join");
				return;
			}

			boolean isRegisterSuccess = memberService.memberRegister(memberId, rawPassword, memberName, memberPhoneNumber, memberEmail, memberAddress);

			if (!isRegisterSuccess) {
				view.setAttribute("REGISTER_MESSAGE", "아이디 중복 확인을 해주세요.");
				view.setTemplatePage("view/member/join");
				return;
			}

			data.getSession().setAttribute("JOIN_SUCCESS_ALERT", "Y");

			view.setRedirectUrl("loginForm");
			
			return;
		} catch (Exception e) {
			throw new RuntimeException("회원가입 처리 중 오류가 발생했습니다.", e);
		}
	}
	
	//3-1. 회원가입 실패시 입력 값 유지
	private void setRegisterFormValues(DataSet params, ViewMeta view) {
		view.setAttribute("M_ID", getTextOrEmpty(params, "M_ID"));
		view.setAttribute("M_NAME", getTextOrEmpty(params, "M_NAME"));
		view.setAttribute("M_PHONE_NUMBER", getTextOrEmpty(params, "M_PHONE_NUMBER"));
		view.setAttribute("M_EMAIL", getTextOrEmpty(params, "M_EMAIL"));
		view.setAttribute("M_ADDRESS", getTextOrEmpty(params, "M_ADDRESS"));
	}
	
	//3-2. DataSet 값 null 방지
	private String getTextOrEmpty(DataSet params, String fieldName) {
		String value = params.getText(fieldName);
		if (value == null) {
			return "";
		}
		return value;
	}

	//3-3. 빈 문자열 검사
	private boolean isEmpty(String value) {
		return value == null || value.isBlank();
	}
	
	//4. 로그인 화면 진입
	@UrlMapping("/loginForm")
	public void memberLoginForm(RequestData data, ViewMeta view) {
		
		Object joinSuccessAlert = data.getSession().getAttribute("JOIN_SUCCESS_ALERT");
		
		if ("Y".equals(joinSuccessAlert)) {
			view.setAttribute("JOIN_SUCCESS_ALERT", "Y");
			data.getSession().removeAttribute("JOIN_SUCCESS_ALERT"); //새로고침하면 alert가 반복되지 않게 제거
		}
		
		view.setTemplatePage("view/member/login");
	}
	
	//5. 로그인 처리
	@UrlMapping("/login")
	public void memberLogin(RequestData data, ViewMeta view) {
		
		try {
			DataSet params = data.getParameters();
			
			String memberId = params.getText("M_ID");
			String rawPassword = params.getText("M_PW");
			
			setLoginFormValues(params, view);
			
			if (isEmpty(memberId) || isEmpty(rawPassword)) {
				view.setAttribute("LOGIN_MESSAGE", "아이디와 비밀번호를 입력해 주세요.");
				view.setTemplatePage("view/member/login");
				return;
			}
			
			memberId = memberId.trim();
			
			view.setAttribute("M_ID", memberId);
			
			//관리자 로그인 처리
			if (ADMIN_ID.equals(memberId) && ADMIN_PW.equals(rawPassword)) {
				clearLoginSession(data);
				data.getSession().setAttribute("LOGIN_ADMIN", Boolean.TRUE);
				view.setRedirectUrl("../admin/dashboard");
				return;
			}
			
			DataSet loginMember = memberService.memberLogin(memberId, rawPassword);

			if (loginMember == null) {
			    view.setAttribute("LOGIN_MESSAGE", "아이디 또는 비밀번호가 일치하지 않습니다.");
			    view.setTemplatePage("view/member/login");
			    return;
			}

			/* =========================
			   로그인 전 세션 상태 확인
			   ========================= */
			System.out.println("===== LOGIN BEFORE =====");
			System.out.println("SESSION ID = " + data.getSession().getId());
			System.out.println("LOGIN_MEMBER_NO = " + data.getSession().getAttribute("LOGIN_MEMBER_NO"));
			System.out.println("LOGIN_MEMBER_ID = " + data.getSession().getAttribute("LOGIN_MEMBER_ID"));
			System.out.println("========================");

			//기존 일반 회원 로그인 세션 제거
			clearLoginSession(data);

			//기존 관리자 로그인 세션 제거
			data.getSession().removeAttribute("LOGIN_ADMIN");

			data.getSession().setAttribute("LOGIN_MEMBER_NO", loginMember.getLong("M_NO"));
			data.getSession().setAttribute("LOGIN_MEMBER_ID", loginMember.getText("M_ID"));
			data.getSession().setAttribute("LOGIN_MEMBER_NAME", loginMember.getText("M_NAME"));

			/* =========================
			   로그인 후 세션 상태 확인
			   ========================= */
			System.out.println("===== LOGIN AFTER =====");
			System.out.println("SESSION ID = " + data.getSession().getId());
			System.out.println("LOGIN_MEMBER_NO = " + data.getSession().getAttribute("LOGIN_MEMBER_NO"));
			System.out.println("LOGIN_MEMBER_ID = " + data.getSession().getAttribute("LOGIN_MEMBER_ID"));
			System.out.println("LOGIN_MEMBER_NAME = " + data.getSession().getAttribute("LOGIN_MEMBER_NAME"));
			System.out.println("=======================");
			
			//로그인 성공 팝업을 위한 1회성 세션값
			data.getSession().setAttribute("LOGIN_SUCCESS_ALERT", "Y");
			
			view.setRedirectUrl("../main");
			return;
		} catch (Exception e) {
			throw new RuntimeException("로그인 처리 중 오류가 발생했습니다.", e);
		}
	}
	
	//5-1. 로그인 실패시 아이디 유지
	private void setLoginFormValues(DataSet params, ViewMeta view) {
		view.setAttribute("M_ID", getTextOrEmpty(params, "M_ID"));
	}
	
	//5-2. 로그인 세션 값 정리
	private void clearLoginSession(RequestData data) {
		data.getSession().removeAttribute("LOGIN_MEMBER_NO");
		data.getSession().removeAttribute("LOGIN_MEMBER_ID");
		data.getSession().removeAttribute("LOGIN_MEMBER_NAME");
	}
	
	//6. 로그아웃 처리
	@UrlMapping("/logout")
	public void memberLogout(RequestData data, ViewMeta view) {
		try {
			data.getSession().invalidate();
			view.setRedirectUrl("../member/loginForm");
		} catch (Exception e) {
			throw new RuntimeException("로그아웃 처리 중 오류가 발생했습니다.", e);
		}
	}
	
	//7. 아이디 찾기 화면 진입
	@UrlMapping("/findIdForm")
	public void memberFindIdForm(ViewMeta view) {
		view.setTemplatePage("view/member/findId");
	}
	
	//8. 아이디 찾기 처리
	@UrlMapping("/findId")
	public void memberFindId(RequestData data, ViewMeta view) {
		
		try {
			DataSet params = data.getParameters();
			
			String findType = params.getText("FIND_TYPE");
			String memberName = params.getText("M_NAME");			
			String memberPhoneNumber = params.getText("M_PHONE_NUMBER");			
			String memberEmail = params.getText("M_EMAIL");
			
			if (isEmpty(findType)) {
				findType = "PHONE";
			}
			
			setFindIdFormValues(params, view);
			
			view.setAttribute("FIND_TYPE", findType);
			
			if (isEmpty(memberName)) {
				view.setAttribute("FIND_ID_MESSAGE", "이름을 입력해 주세요.");
				view.setTemplatePage("view/member/findId");
				return;
			}
			memberName = memberName.trim();
			
			String findValue = null;
			
			if ("PHONE".equals(findType)) {
				
				if (isEmpty(memberPhoneNumber)) {
					view.setAttribute("FIND_ID_MESSAGE", "휴대폰 번호를 입력해 주세요.");
					view.setTemplatePage("view/member/findId");
					return;
				}
				memberPhoneNumber = memberPhoneNumber.trim();
				
				findValue = memberPhoneNumber;
				
				view.setAttribute("M_PHONE_NUMBER", memberPhoneNumber);
				view.setAttribute("M_EMAIL", "");
			} else if ("EMAIL".equals(findType)) {
				
				if (isEmpty(memberEmail)) {
					view.setAttribute("FIND_ID_MESSAGE", "이메일을 입력해 주세요.");
					view.setTemplatePage("view/member/findId");
					return;
				}
				memberEmail = memberEmail.trim();
				
				findValue = memberEmail;
				view.setAttribute("M_EMAIL", memberEmail);
				view.setAttribute("M_PHONE_NUMBER", "");
			} else {
				view.setAttribute("FIND_ID_MESSAGE", "아이디 찾기 방식을 다시 선택해 주세요.");
				view.setAttribute("FIND_TYPE", "PHONE");
				
				view.setTemplatePage("view/member/findId");
				return;
			}
			
			view.setAttribute("M_NAME", memberName);
			
			DataSet foundMemberIdList = memberService.memberFindId(findType, memberName, findValue);
			
			if (foundMemberIdList == null || foundMemberIdList.getCount("M_ID") <= 0) {
				view.setAttribute("FIND_ID_MESSAGE", "일치하는 회원 정보를 찾을 수 없습니다.");
				
				view.setTemplatePage("view/member/findId");
				return;
			}

			view.setAttribute("FOUND_MEMBER_ID_LIST", foundMemberIdList);
			
			view.setTemplatePage("view/member/findId");
		} catch (Exception e) {
			throw new RuntimeException("아이디 찾기 처리 중 오류가 발생했습니다.", e);
		}
	}
	
	//8-1. 아이디 찾기 실패 시 입력값 유지
	private void setFindIdFormValues(DataSet params, ViewMeta view) {
		
		String findType = params.getText("FIND_TYPE");
		
		if (findType == null || findType.isBlank()) {
			findType = "PHONE";
		}
		
		view.setAttribute("FIND_TYPE", findType);
		view.setAttribute("M_NAME", getTextOrEmpty(params, "M_NAME"));
		view.setAttribute("M_PHONE_NUMBER", getTextOrEmpty(params, "M_PHONE_NUMBER"));
		view.setAttribute("M_EMAIL", getTextOrEmpty(params, "M_EMAIL"));
	}
	
	//9. 비밀번호 찾기 화면 이동
	@UrlMapping("/findPasswordForm")
	public void memberFindPasswordPage(RequestData data, ViewMeta view) {
		view.setTemplatePage("view/member/findPassword");
	}
	
	//10. 비밀번호 찾기 처리
	@UrlMapping("/findPassword")
	public void memberFindPasswordProcess(RequestData data, ViewMeta view) {
		
		try {
			DataSet params = data.getParameters();
			
			String findType = params.getText("FIND_TYPE");
			String memberId = params.getText("M_ID");
			String memberName = params.getText("M_NAME");
			String findPhone = params.getText("FIND_PHONE");
			String findEmail = params.getText("FIND_EMAIL");
			
			String findValue = null;
			
			if ("EMAIL".equals(findType)) {
				findValue = findEmail;
			} else {
				findType = "PHONE";
				findValue = findPhone;
			}
			
			setFindPasswordFormValue(findType, memberId, memberName, findPhone, findEmail, view);
			
			if (isEmpty(memberId) || isEmpty(memberName) || isEmpty(findValue)) {
				view.setAttribute("FIND_PASSWORD_MESSAGE", "비밀번호 찾기 정보를 모두 입력해 주세요.");
				
				view.setTemplatePage("view/member/findPassword");
				return;
			}
			
			memberId = memberId.trim();
			memberName = memberName.trim();
			findValue = findValue.trim();
			
			//휴대폰 번호 입력 양식 지정
			if ("PHONE".equals(findType) && !findValue.matches("^010-\\d{4}-\\d{4}$")) {
				view.setAttribute("FIND_PASSWORD_MESSAGE", "휴대폰 번호는 010-0000-0000 형식으로 입력해 주세요.");
				
				view.setTemplatePage("view/member/findPassword");
				return;
			}
			
			String tempPassword = memberService.memberTempPassword(findType, memberId, memberName, findValue);
			
			if (tempPassword == null || tempPassword.isBlank()) {
				view.setAttribute("FIND_PASSWORD_MESSAGE", "입력하신 정보와 일치하는 회원을 찾을 수 없습니다.");
				
				view.setTemplatePage("view/member/findPassword");
				return;
			}
			
			view.setAttribute("TEMP_PASSWORD", tempPassword);
			view.setAttribute("FIND_PASSWORD_MESSAGE", "임시 비밀번호가 발급되었습니다.");
			
			view.setTemplatePage("view/member/findPassword");
			return;
		} catch (Exception e) {
			throw new RuntimeException("비밀번호 찾기 처리 중 오류가 발생했습니다.", e);
		}
	}
	
	//10-1. 비밀번호 찾기 화면에 입력한 값에 문제가 있으면 다시 반환해주는 메서드
	private void setFindPasswordFormValue(String findType, String memberId, String memberName, String findPhone, String findEmail, ViewMeta view) {
		view.setAttribute("FIND_TYPE", findType);
		view.setAttribute("M_ID", memberId);
		view.setAttribute("M_NAME", memberName);
		view.setAttribute("FIND_PHONE", findPhone);
		view.setAttribute("FIND_EMAIL", findEmail);
	}
}