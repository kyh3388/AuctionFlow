package auctionFlow.service;

import auctionFlow.common.security.PasswordHash;
import coreframe.annotations.beans.Bean;
import coreframe.annotations.beans.Inject;
import coreframe.data.DataSet;
import coreframe.data.Interaction;
import coreframe.data.InteractionFactory;

@Bean
public class MyPageService {
	
	@Inject
	private PasswordHash passwordHash;

	//1. 마이페이지 공통 회원정보 조회
	//사이드바에서 사용할 회원 이름과 아이디를 조회
	public DataSet myPageSelectMemberSummary(long memberNo) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);

		Interaction interaction = InteractionFactory.getInteraction();
		DataSet output = interaction.execute("member/myPage/common/memberSummary", input);

		return output;
	}
	
	//2. 경매 등록 내역 조회
	public DataSet myPageSelectRegisterAuctionHistory(long memberNo) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		
		//마이페이지 목록 조회 전에 경매 상태 확정
		DataSet closeExpiredInput = DataSet.newDefault();
		interaction.execute("auction/closeExpired", closeExpiredInput);
		
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);
		
		DataSet output = interaction.execute("member/myPage/01/registerHistory", input);
		return output;
	}
	
	//3. 입찰 내역 조회
	public DataSet myPageSelectBidHistory(long memberNo) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		
		//입찰 내역 조회 전에 경매의 상태를 갱신
		DataSet closeExpiredInput = DataSet.newDefault();
		interaction.execute("auction/closeExpired", closeExpiredInput);
		
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);
		
		return interaction.execute("member/myPage/02/bidHistory", input);
	}
	
	//4. 회원의 현재 비밀번호 확인
	public boolean myPageCheckPassword(long memberNo, String rawPassword) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);

		Interaction interaction = InteractionFactory.getInteraction();
		
		DataSet passwordData = interaction.execute("member/myPage/common/checkPassword", input);
		if (passwordData == null || passwordData.getCount("M_NO") == 0) {
			return false;
		}

		String storedPassword = passwordData.getText("M_PW", 0);
		if (storedPassword == null || storedPassword.isBlank()) {
			return false;
		}

		//로그인과 동일한 비밀번호 검증 방식 사용
		return passwordHash.matches(rawPassword, storedPassword);
	}
	
	//5. 회원정보 수정 화면 조회
	public DataSet myPageSelectProfile(long memberNo) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("M_NO", memberNo);

		Interaction interaction = InteractionFactory.getInteraction();

		return interaction.execute("member/myPage/04/profileSelect", input);
	}

	//6. 회원정보 수정 처리
	public void myPageUpdateProfile(long memberNo, String memberName, String memberPhoneNumber, String memberEmail, String memberAddress) throws Exception {

		DataSet input = DataSet.newDefault();
		//수정 가능한 정보만 전달
		input.put("M_NO", memberNo);
		input.put("M_NAME", memberName);
		input.put("M_PHONE_NUMBER", memberPhoneNumber);
		input.put("M_EMAIL", memberEmail);
		input.put("M_ADDRESS", memberAddress);

		Interaction interaction = InteractionFactory.getInteraction();
		interaction.execute("member/myPage/04/profileUpdate", input);
	}
	
	//7. 비밀번호 변경 처리
	public void myPageUpdatePassword(long memberNo, String rawNewPassword) throws Exception {

		//회원가입과 동일한 방식으로 새 비밀번호 해시 처리
		String hashedNewPassword = passwordHash.hash(rawNewPassword);

		DataSet input = DataSet.newDefault();
		input.put("M_PW", hashedNewPassword);
		//화면에서 받은 회원 번호가 아닌 로그인 세션의 회원 번호 사용
		input.put("M_NO", memberNo);
		
		Interaction interaction = InteractionFactory.getInteraction();
		interaction.execute("member/myPage/05/updatePassword", input);
	}
	
	//7. 결제/구매 내역 조회
	public DataSet myPagePurchaseHistory(long memberNo) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();

		//종료 시간이 지난 경매를 SOLD 또는 UNSOLD로 먼저 확정
		DataSet closeExpiredInput = DataSet.newDefault();
		interaction.execute("auction/closeExpired", closeExpiredInput);

		DataSet input = DataSet.newDefault();
		input.put("HIGHEST_BIDDER_M_NO", memberNo);

		return interaction.execute("member/myPage/03/purchaseHistory", input);
	}

	//8. 구매 완료 처리
	public boolean myPageCompletePurchase(long auctionNo, long memberNo) throws Exception {
		//현재 로그인 회원의 구매 내역을 조회하여 실제 구매 가능한 낙찰 상품인지 먼저 확인
		DataSet purchaseHistoryList = myPagePurchaseHistory(memberNo);

		if (purchaseHistoryList == null) return false;

		int purchaseHistoryCount = purchaseHistoryList.getCount("A_NO");
		boolean purchaseAvailable = false;

		for (int i = 0; i < purchaseHistoryCount; i++) {
			long selectedAuctionNo = purchaseHistoryList.getLong("A_NO", i);
			String purchasedDatetime = purchaseHistoryList.getText("A_PURCHASED_DATETIME", i);

			if (selectedAuctionNo == auctionNo && (purchasedDatetime == null || purchasedDatetime.isBlank())) {
				purchaseAvailable = true;
				break;
			}
		}

		if (!purchaseAvailable) return false;

		DataSet input = DataSet.newDefault();
		input.put("A_NO", auctionNo);
		//회원 번호는 로그인 세션에서 조회한 값 사용
		input.put("HIGHEST_BIDDER_M_NO", memberNo);

		Interaction interaction = InteractionFactory.getInteraction();
		interaction.execute("member/myPage/03/purchaseComplete", input);

		return true;
	}
}