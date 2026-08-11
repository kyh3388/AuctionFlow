package auctionFlow.controller;

import auctionFlow.service.AdminService;
import auctionFlow.websocket.AuctionWebSocketManager;
import coreframe.annotations.beans.Inject;
import coreframe.annotations.http.Controller;
import coreframe.annotations.http.UrlMapping;
import coreframe.data.DataSet;
import coreframe.http.RequestData;
import coreframe.http.ViewMeta;

@Controller(urlPattern = "/api/auctionFlow/admin")
public class AdminController {

	@Inject
	private AdminService adminService;

	//0. 관리자 세션 확인
	private boolean isAdminLogin(RequestData data) {
		Object loginAdmin = data.getSession().getAttribute("LOGIN_ADMIN");
		return Boolean.TRUE.equals(loginAdmin);
	}

	//1. 관리자 대시보드 화면
	@UrlMapping("/dashboard")
	public void dashboard(RequestData data, ViewMeta view) {

		try {

			//관리자 세션이 없으면 공통 오류 화면 출력
			if (!isAdminLogin(data)) {
				view.setTemplatePage("view/error/error");
				return;
			}
			
			//총 낙찰액, 총 수수료, 미결제 수수료, 미결제 건수 조회
			DataSet dashboardSummary = adminService.adminDashboardSummary();
			
			//최근 7일 일일 경매 등록 현황 조회
			DataSet auctionRegisterGraph = adminService.adminAuctionRegisterGraph();
			
			//경매 상태에 따른 개수를 조회
			DataSet auctionStatusGraph = adminService.adminAuctionStatusGraph();

			long totalSoldAmount = 0L;
			long totalFeeAmount = 0L;
			long unpaidFeeAmount = 0L;
			long unpaidCount = 0L;

			if (dashboardSummary != null && dashboardSummary.getCount("TOTAL_SOLD_AMOUNT") > 0) {
				totalSoldAmount = dashboardSummary.getLong("TOTAL_SOLD_AMOUNT", 0);
				totalFeeAmount = dashboardSummary.getLong("TOTAL_FEE_AMOUNT", 0);
				unpaidFeeAmount = dashboardSummary.getLong("UNPAID_FEE_AMOUNT", 0);
				unpaidCount = dashboardSummary.getLong("UNPAID_COUNT", 0);
			}

			view.setAttribute("TOTAL_SOLD_AMOUNT", totalSoldAmount);
			view.setAttribute("TOTAL_FEE_AMOUNT", totalFeeAmount);
			view.setAttribute("UNPAID_FEE_AMOUNT", unpaidFeeAmount);
			view.setAttribute("UNPAID_COUNT", unpaidCount);
			
			//막대그래프 데이터 전달
			view.setAttribute("AUCTION_REGISTER_GRAPH", auctionRegisterGraph);
			
			//원형그래프 데이터 전달
			view.setAttribute("AUCTION_STATUS_GRAPH", auctionStatusGraph);

			view.setAttribute("ADMIN_MENU", "DASHBOARD");

			view.setTemplatePage("view/admin/dashboard/dashboard");
		} catch (Exception e) {
			throw new RuntimeException("관리자 대시보드 조회 중 오류가 발생했습니다.", e);
		}
	}

	//2. 회원 목록 화면
	@UrlMapping("/member")
	public void memberList(RequestData data, ViewMeta view) {

		try {
			//관리자 세션이 없으면 공통 오류 화면 출력
			if (!isAdminLogin(data)) {
				view.setTemplatePage("view/error/error");
				return;
			}

			DataSet memberList = adminService.adminMemberList();

			view.setAttribute("MEMBER_LIST", memberList);
			view.setAttribute("ADMIN_MENU", "MEMBER");
			
			view.setTemplatePage("view/admin/member/memberList");
		} catch (Exception e) {
			throw new RuntimeException("관리자 회원 목록 조회 중 오류가 발생했습니다.", e);
		}
	}

	//3. 회원 상세 화면
	@UrlMapping("/member/detail")
	public void memberDetail(RequestData data, ViewMeta view) {

		try {
			//관리자 세션이 없으면 공통 오류 화면 출력
			if (!isAdminLogin(data)) {
				view.setTemplatePage("view/error/error");
				return;
			}

			DataSet params = data.getParameters();

			String memberNoText = params.getText("M_NO");

			//회원 번호가 없으면 공통 오류 화면 출력
			if (memberNoText == null || memberNoText.isBlank()) {

				view.setTemplatePage("view/error/error");
				return;
			}

			long memberNo;

			try {
				memberNo = Long.parseLong(memberNoText.trim());
			} catch (NumberFormatException e) {
				view.setTemplatePage("view/error/error");
				return;
			}

			//회원 번호가 정상적인 양수가 아니면 접근 차단
			if (memberNo <= 0) {
				view.setTemplatePage("view/error/error");
				return;
			}

			DataSet memberDetail = adminService.adminMemberDetail(memberNo);

			//조회된 회원이 없으면 공통 오류 화면 출력
			if (memberDetail == null || memberDetail.getCount("M_NO") <= 0) {
				view.setTemplatePage("view/error/error");
				return;
			}

			String selectedTab = normalizeMemberDetailTab(params.getText("TAB"));

			view.setAttribute("MEMBER_DETAIL", memberDetail);
			view.setAttribute("SELECTED_TAB", selectedTab);

			//개인정보 탭은 MEMBER_DETAIL만 사용하고, 경매 등록 및 입찰 탭은 선택한 경우에만 추가 조회한다.
			if ("AUCTION".equals(selectedTab)) {
				DataSet memberAuctionList = adminService.adminMemberAuctionList(memberNo);
				view.setAttribute("MEMBER_AUCTION_LIST", memberAuctionList);
			} else if ("BID".equals(selectedTab)) {
				DataSet memberBidList = adminService.adminMemberBidList(memberNo);
				view.setAttribute("MEMBER_BID_LIST", memberBidList);
			}

			view.setAttribute("ADMIN_MENU", "MEMBER");
			view.setTemplatePage("view/admin/member/memberDetail");
		} catch (Exception e) {
			throw new RuntimeException("관리자 회원 상세 조회 중 오류가 발생했습니다.", e);
		}
	}

	//5. 회원 상세 탭 검증
	private String normalizeMemberDetailTab(String selectedTab) {
		if ("AUCTION".equals(selectedTab)) {
			return "AUCTION";
		}
		if ("BID".equals(selectedTab)) {
			return "BID";
		}
		//값이 없거나 허용되지 않은 값이면 개인정보 탭
		return "PROFILE";
	}
	
	//7. 관리자 경매 목록 화면
	@UrlMapping("/auction")
	public void auctionList(RequestData data, ViewMeta view) {

		try {
			//관리자 세션이 없으면 공통 오류 화면 출력
			if (!isAdminLogin(data)) {
				view.setTemplatePage("view/error/error");
				return;
			}

			DataSet auctionList = adminService.adminAuctionList();

			view.setAttribute("AUCTION_LIST", auctionList);

			Object auctionMessage = data.getSession().getAttribute("ADMIN_AUCTION_MESSAGE");

			if (auctionMessage != null) {
				view.setAttribute("ADMIN_AUCTION_MESSAGE", auctionMessage.toString());
				data.getSession().removeAttribute("ADMIN_AUCTION_MESSAGE");
			}

			view.setAttribute("ADMIN_MENU", "AUCTION");
			view.setTemplatePage("view/admin/auction/auctionList");
		} catch (Exception e) {
			throw new RuntimeException("관리자 경매 목록 조회 중 오류가 발생했습니다.", e);
		}
	}

	//8. 관리자 경매 취소
	@UrlMapping("/auction/cancel")
	public void auctionCancel(RequestData data, ViewMeta view) {

		try {

			//관리자 세션이 없으면 공통 오류 화면 출력
			if (!isAdminLogin(data)) {
				view.setTemplatePage("view/error/error");
				return;
			}

			DataSet params = data.getParameters();

			Long auctionNo = parseAdminAuctionNo(params.getText("A_NO"));

			String adminReason = params.getText("A_ADMIN_REASON");

			if (auctionNo == null) {
				redirectAuctionList(data, view, "경매 번호가 올바르지 않습니다.");
				return;
			}

			if (adminReason == null) {
				adminReason = "";
			}

			//공백만 입력한 사유를 차단
			adminReason = adminReason.trim();

			if (adminReason.isBlank()) {
				redirectAuctionList(data, view, "경매 취소 사유를 입력해 주세요.");
				return;
			}

			String resultCode = adminService.adminAuctionCancel(auctionNo, adminReason);
			
			if ("CANCELED".equals(resultCode)) {
				AuctionWebSocketManager.broadcastToAuction(auctionNo, "AUCTION_CANCELED|A_NO=" + auctionNo);
			}

			redirectAuctionList(data, view, createAuctionActionMessage(resultCode));
		} catch (Exception e) {
			throw new RuntimeException("관리자 경매 취소 처리 중 오류가 발생했습니다.", e);
		}
	}

	//관리자 경매 번호 검증
	private Long parseAdminAuctionNo(String auctionNoText) {

		if (auctionNoText == null || auctionNoText.isBlank()) {
			return null;
		}

		try {

			long auctionNo = Long.parseLong(auctionNoText.trim());

			if (auctionNo <= 0) {
				return null;
			}

			return auctionNo;

		} catch (NumberFormatException e) {
			return null;
		}
	}

	//관리자 경매 목록으로 메시지와 함께 이동
	private void redirectAuctionList(RequestData data, ViewMeta view, String message) {
		data.getSession().setAttribute("ADMIN_AUCTION_MESSAGE", message);
		view.setRedirectUrl("../auction");
	}

	//관리자 경매 조치 결과 메시지
	private String createAuctionActionMessage(String resultCode) { 

		if ("SOLD".equals(resultCode)) {
			return "경매가 조기 종료되어 낙찰 처리되었습니다.";
		}
		if ("UNSOLD".equals(resultCode)) {
			return "경매가 조기 종료되어 미낙찰 처리되었습니다.";
		}
		if ("CANCELED".equals(resultCode)) {
			return "경매가 취소되었습니다.";
		}
		if ("NOT_FOUND".equals(resultCode)) {
			return "해당 경매를 찾을 수 없습니다.";
		}
		if ("NOT_ONGOING".equals(resultCode)) {
			return "이미 종료되었거나 취소된 경매입니다.";
		}
		if ("EXPIRED".equals(resultCode)) {
			return "이미 예정 종료 시간이 지난 경매입니다.";
		}
		if ("INVALID_ACTION".equals(resultCode)) {
			return "관리자 경매 조치 유형이 올바르지 않습니다.";
		}
		return "경매 조치 처리에 실패했습니다.";
	}
}