package auctionFlow.exception;

/**
 * 입찰 처리 중 발생하는 업무상 예외를 표현하는 클래스.
 *
 * 일반 시스템 오류와 달리, 본인 입찰, 경매 종료, 가격 변경, 중복 요청 등
 * 예상 가능한 입찰 실패 사유를 구분하기 위해 사용한다.
 *
 * code    : 프로그램이 실패 원인을 구분하기 위한 값
 * message : 사용자에게 보여줄 오류 메시지
 */
public class BidException extends RuntimeException {
	private static final long serialVersionUID = 1L;
	
	//입찰 실패 사유 코드
	public static final String AUCTION_NOT_FOUND = "AUCTION_NOT_FOUND";
	public static final String SELF_BID = "SELF_BID";
	public static final String AUCTION_CANCELED = "AUCTION_CANCELED";
	public static final String AUCTION_ENDED = "AUCTION_ENDED";
	public static final String AUCTION_CLOSED = "AUCTION_CLOSED";
	public static final String INVALID_BID_PRICE = "INVALID_BID_PRICE";
	public static final String PRICE_CHANGED = "PRICE_CHANGED";
	public static final String DUPLICATE_REQUEST = "DUPLICATE_REQUEST";
	public static final String BID_PROCESS_FAILED = "BID_PROCESS_FAILED";
	
	//프로그램에서 입찰 실패 원인을 구분하기 위한 코드
	private final String code;
	
	//입찰 실패 코드와 사용자에게 보여줄 메세지를 함께 저장
	public BidException(String code, String message) {
		super(message);
		this.code = code;
	}
	
	//입찰 실패 사유 코드 반환
	public String getCode() {
		return code;
	}
}