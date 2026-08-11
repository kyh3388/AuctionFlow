package auctionFlow.websocket;

import java.io.IOException;

import jakarta.websocket.CloseReason;
import jakarta.websocket.OnClose;
import jakarta.websocket.OnError;
import jakarta.websocket.OnOpen;
import jakarta.websocket.Session;
import jakarta.websocket.server.PathParam;
import jakarta.websocket.server.ServerEndpoint;

//경매 상세 화면 WebSocket 연결 테스트, 접속 주소:  /ws/auction/{경매번호}
@ServerEndpoint("/ws/auction/{auctionNo}")
public class AuctionWebSocketEndpoint {

	// 브라우저와 WebSocket 연결이 성립했을 때 실행
	@OnOpen
	public void onOpen(Session session, @PathParam("auctionNo") String auctionNoText) throws IOException {
		
		long auctionNo;
		
		try {
			auctionNo = Long.parseLong(auctionNoText);
		} catch (NumberFormatException e) {
			session.close(new CloseReason(CloseReason.CloseCodes.CANNOT_ACCEPT, "INVALID_A_NO"));
			return;
		}
		
		if (auctionNo <= 0) {
			session.close(new CloseReason(CloseReason.CloseCodes.CANNOT_ACCEPT, "INVALID_A_NO"));
			return;
		}
		
		//연결 종료 시 경매번호를 확인할 수 있도록 WebSocket 세션에 저장
		session.getUserProperties().put("A_NO", auctionNo);
		
		//경매 번호별 세션 저장소에 현재 연결을 등록
		AuctionWebSocketManager.addSession(auctionNo, session);
		
		System.out.println("[AUCTION WS OPEN]" + " A_NO=" + auctionNo + ", SESSION_ID=" + session.getId());
	}

	//브라우저가 상세 화면을 벗어나거나 WebSocket 연결이 정상적으로 종료됐을 때 실행
	@OnClose
	public void onClose(Session session, CloseReason closeReason) {
		Object auctionNoObject = session.getUserProperties().get("A_NO");
	
		//정상적으로 경매 번호가 저장된 연결만 세션 저장소에서 제거
		if (auctionNoObject instanceof Number) {
			long auctionNo = ((Number) auctionNoObject).longValue();
			AuctionWebSocketManager.removeSession(auctionNo, session);
			System.out.println("[AUCTION WS CLOSE]" + "A_NO=" + auctionNoObject + ", SESSION_ID=" + session.getId() + ", REASON=" + closeReason.getReasonPhrase());
		}
	}

	//WebSocket 연결 중 오류가 발생했을 때 실행
	@OnError
	public void onError(Session session, Throwable throwable) {
		String sessionId = session == null ? "null" : session.getId();
		Object auctionNo = session == null ? null : session.getUserProperties().get("A_NO");
		System.err.println("[AUCTION WS ERROR]" + " A_NO=" + auctionNo + ", SESSION_ID=" + sessionId + ", EXCEPTION=" + throwable.getClass().getName() + ", MESSAGE=" + throwable.getMessage());
		throwable.printStackTrace();
	}
}