package auctionFlow.service;

import java.security.SecureRandom;

import auctionFlow.common.security.PasswordHash;
import coreframe.annotations.beans.Bean;
import coreframe.annotations.beans.Inject;
import coreframe.data.DataSet;
import coreframe.data.Interaction;
import coreframe.data.InteractionFactory;

@Bean
public class MemberService {
	
	@Inject
	private PasswordHash passwordHash;
	
	private final SecureRandom secureRandom = new SecureRandom();
	
	//1. 아이디 중복 확인
	public int memberIdCheck(String memberId) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("M_ID", memberId);
		
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet output = interaction.execute("member/idCheck", input);
		
		return output.getInt("M_ID_COUNT"); //반환 값이 1이면 중복, 0이면 중복아님
	}
	
	//2. 회원가입 처리
	public boolean memberRegister(String memberId, String rawPassword, String memberName, String memberPhoneNumber, String memberEmail, String memberAddress) throws Exception {
		int memberIdCount = memberIdCheck(memberId);
		if (memberIdCount > 0) {
			return false;
		}
		
		String hashedPassword = passwordHash.hash(rawPassword);
		
		DataSet input = DataSet.newDefault();
		input.put("M_ID", memberId);
		input.put("M_PW", hashedPassword);
		input.put("M_NAME", memberName);
		input.put("M_PHONE_NUMBER", memberPhoneNumber);
		input.put("M_EMAIL", memberEmail);
		input.put("M_ADDRESS", memberAddress);
		
		Interaction interaction = InteractionFactory.getInteraction();
		interaction.execute("member/join", input);
		
		return true;
	}
	
	//3. 로그인 처리
	public DataSet memberLogin(String memberId, String rawPassword) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("M_ID", memberId);
		
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet output = interaction.execute("member/login", input);
		
		//ID로 회원 테이블을 조회해서, 가져온 PW 값의 유무로 해당 ID의 회원이 있는지 없는지 판단
		String storedPasswordHash = output.getText("M_PW");
		
		if (storedPasswordHash == null || storedPasswordHash.isBlank()) {
			return null;
		}
		
		//회원이 있다고 판단되면, 로그인 화면에서 입력한 PW와 DB에 저장된 PW를 비교
		//이때 DB에 해싱된 PW는 솔트 정보를 결합해 가지고 있고 그걸 로그인 화면에서 입력한 PW랑 결합해 해싱을 해서 해싱된 값이 서로 동일한지 판단한다.
		boolean isPasswordMatched = passwordHash.matches(rawPassword, storedPasswordHash);
		
		if (!isPasswordMatched) { return null; }
		
		output.remove("M_PW");
		
		return output;
	}
	
	//4. 아이디 찾기
	public DataSet memberFindId(String findType, String memberName, String findValue) throws Exception {
		
		DataSet input = DataSet.newDefault();
		
		input.put("M_NAME", memberName); 
		input.put("FIND_TYPE", findType);
		input.put("FIND_VALUE", findValue);
		
		Interaction interaction = InteractionFactory.getInteraction();
		
		return interaction.execute("member/findId", input);
	}
	
	//5. 임시 비밀번호 발급
	public String memberTempPassword(String findType, String memberId, String memberName, String findValue) throws Exception {
		
		DataSet input = DataSet.newDefault();
		
		input.put("M_ID", memberId);
		input.put("M_NAME", memberName);
		input.put("FIND_TYPE", findType);
		input.put("FIND_VALUE", findValue);
		
		Interaction interaction = InteractionFactory.getInteraction();
		
		DataSet output = interaction.execute("member/findPasswordCheck", input);
		
		int memberCount = output.getInt("MEMBER_COUNT");
		
		if (memberCount <= 0) {
			return null;
		}
		
		String tempPassword = createTempPassword();
		
		System.out.println("*******************체크입니다 : " + tempPassword);
		
		String hashedTempPassword = passwordHash.hash(tempPassword);
		
		System.out.println("*******************체크입니다 : " + hashedTempPassword);
		
		DataSet updateInput = DataSet.newDefault();
		
		updateInput.put("M_PW", hashedTempPassword);
		updateInput.put("M_ID", memberId);
		updateInput.put("M_NAME", memberName);
		updateInput.put("FIND_TYPE", findType);
		updateInput.put("FIND_VALUE", findValue);
		
		interaction.execute("member/updateTempPassword", updateInput);
		
		return tempPassword;
	}
	
	//임시 비밀번호 생성
	private String createTempPassword() {
		final String passwordChar = "ABCDEFG" + "abcdefg" + "23456789";
		final int passwordLength = 6;
		
		StringBuilder tempPassword = new StringBuilder();
		
		for (int i=0; i<passwordLength; i++) {
			int randomIndex = secureRandom.nextInt(passwordChar.length());
			tempPassword.append(passwordChar.charAt(randomIndex));
		}
		return tempPassword.toString();
	}
}




























