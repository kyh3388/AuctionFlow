package auctionFlow.service;

import coreframe.annotations.beans.Bean;
import coreframe.data.DataSet;
import coreframe.data.Interaction;
import coreframe.data.InteractionFactory;

@Bean
public class AdminService {

	//1. 회원 목록 조회
	public DataSet adminMemberList() throws Exception {
		DataSet input = DataSet.newDefault();
		Interaction interaction = InteractionFactory.getInteraction();
		
		return interaction.execute("admin/member/memberList", input);
	}

	//2. 회원 개인정보 조회
	public DataSet adminMemberDetail(long memberNo) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);
		Interaction interaction = InteractionFactory.getInteraction();
		
		return interaction.execute("admin/member/memberDetail", input);
	}

	//3. 회원 경매 등록 내역 조회
	public DataSet adminMemberAuctionList(long memberNo) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		
		DataSet closeExpiredInput = DataSet.newDefault(); //목록 조회 전에 종료된 경매 상태 확정
		interaction.execute("auction/closeExpired", closeExpiredInput);
		
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);
		
		return interaction.execute("admin/member/memberAuctionList", input);
	}

	//4. 회원 입찰 내역 조회
	public DataSet adminMemberBidList(long memberNo) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();

		DataSet closeExpiredInput = DataSet.newDefault(); //목록 조회 전에 종료된 경매 상태 확정
		interaction.execute("auction/closeExpired", closeExpiredInput);
		
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);
		
		return interaction.execute("admin/member/memberBidList", input);
	}
	
	//5. 관리자 경매 목록 조회
	public DataSet adminAuctionList() throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();

		DataSet closeExpiredInput = DataSet.newDefault(); //목록 조회 전에 종료 시간이 지난 경매 상태 확정
		interaction.execute("auction/closeExpired", closeExpiredInput);
		
		DataSet input = DataSet.newDefault();
		return interaction.execute("admin/auction/auctionList", input);
	}

	//6. 관리자 경매 취소
	public String adminAuctionCancel(long auctionNo, String adminReason) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet auctionCheck = adminAuctionActionCheck(interaction, auctionNo);
		String validationResult = validateAdminAuctionAction(auctionCheck);
		
		if (validationResult != null) {
			return validationResult;
		}
		String finalStatus = "CANCELED";
		DataSet input = DataSet.newDefault();

		//경매 상태 변경
		input.put("A_STATUS_UPDATE", finalStatus);
		input.put("A_ADMIN_REASON_UPDATE", adminReason);
		input.put("A_NO_UPDATE", auctionNo);
		input.put("A_STATUS_CURRENT_CHECK", "ONGOING");

		DataSet actionOutput = interaction.execute("admin/auction/auctionCancel", input);

		if (isAdminAuctionActionSuccess(actionOutput, finalStatus, adminReason)) {
			return finalStatus;
		}
		return resolveAdminAuctionActionFailure(interaction, auctionNo);
	}

	//관리자 경매 조치 대상 조회
	private DataSet adminAuctionActionCheck(Interaction interaction, long auctionNo) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("A_NO", auctionNo);

		return interaction.execute("admin/auction/auctionActionCheck", input);
	}

	//관리자 경매 조치 가능 여부 검증
	private String validateAdminAuctionAction(DataSet auctionCheck) {
		if (auctionCheck == null || auctionCheck.getCount("A_NO") <= 0) {
			return "NOT_FOUND";
		}

		String auctionStatus = auctionCheck.getText("A_STATUS");
		if (!"ONGOING".equals(auctionStatus)) {
			return "NOT_ONGOING";
		}

		long isEnded = auctionCheck.getLong("IS_ENDED");
		if (isEnded == 1L) {
			return "EXPIRED";
		}

		return null;
	}

	//경매 조치 적용 결과 검증
	private boolean isAdminAuctionActionSuccess(DataSet actionOutput, String expectedStatus, String expectedReason) {
		if (actionOutput == null || actionOutput.getCount("RESULT_STATUS") <= 0) {
			return false;
		}

		String resultStatus = actionOutput.getText("RESULT_STATUS");
		String resultReason = actionOutput.getText("RESULT_REASON");
		long isClosed = actionOutput.getLong("IS_CLOSED");

		return expectedStatus.equals(resultStatus) && expectedReason.equals(resultReason) && isClosed == 1L;
	}

	//상태 변경이 반영되지 않은 경우 최신 상태 재조회
	private String resolveAdminAuctionActionFailure(Interaction interaction, long auctionNo) throws Exception {
		DataSet afterCheck = adminAuctionActionCheck(interaction, auctionNo);

		String validationResult = validateAdminAuctionAction(afterCheck);
		if (validationResult != null) {
			return validationResult;
		}

		return "FAILED";
	}
	
	//7. 관리자 대시보드 요약 통계 조회
	public DataSet adminDashboardSummary() throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		
		DataSet closeExpiredInput = DataSet.newDefault(); //통계 조회 전에 종료 시간이 지난 경매 상태 확정
		interaction.execute("auction/closeExpired", closeExpiredInput);
		
		DataSet input = DataSet.newDefault();
		
		return interaction.execute("admin/dashboard/dashboardSummary", input);
	}
	
	//8. 최근 7일 일일 경매 등록 현황 조회(막대 그래프)
	public DataSet adminAuctionRegisterGraph() throws Exception {
		DataSet input = DataSet.newDefault();
		Interaction interaction = InteractionFactory.getInteraction();
		
		return interaction.execute("admin/dashboard/auctionRegisterGraph", input);
	}
	
	//9. 경매 상태에 따른 개수를 조회(도넛 그래프)
	public DataSet adminAuctionStatusGraph() throws Exception {
		DataSet input = DataSet.newDefault();
		Interaction interaction = InteractionFactory.getInteraction();
		
		return interaction.execute("admin/dashboard/auctionStatusGraph", input);
	}
}