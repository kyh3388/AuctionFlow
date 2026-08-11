package auctionFlow.websocket;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import jakarta.websocket.Session;

//경매번호별 WebSocket Session 관리
//구조: 경매번호 → 해당 경매 상세 화면에 접속한 Session 목록
public final class AuctionWebSocketManager {

	//여러 WebSocket 연결이 동시에 추가, 제거될 수 있으므로 일반 HashMap이 아니라 ConcurrentHashMap을 사용
	//예: 26 → [Session A, Session B], 27 → [Session C]
	private static final ConcurrentMap<Long, Set<Session>> AUCTION_SESSION_MAP = new ConcurrentHashMap<>();

	//객체를 생성하지 못하게 한다. 이 클래스는 상태 관리용 정적 메서드만 사용한다.
	private AuctionWebSocketManager() {
	}

	//특정 경매의 WebSocket Session을 등록한다.
	public static void addSession(long auctionNo, Session session) {

		//해당 경매의 Set이 없으면 새로 만든다.
		//computeIfAbsent는 같은 경매번호에 여러 연결이 동시에 들어오는 상황에서도 안전하게 동작한다.
		Set<Session> auctionSessions = AUCTION_SESSION_MAP.computeIfAbsent(auctionNo, key -> ConcurrentHashMap.newKeySet());

		auctionSessions.add(session);

		System.out.println("[AUCTION WS SESSION ADDED]" + " A_NO=" + auctionNo + ", SESSION_ID=" + session.getId() + ", SESSION_COUNT=" + auctionSessions.size());
	}

	//특정 경매의 WebSocket Session을 제거한다.
	public static void removeSession(long auctionNo, Session session) {

		Set<Session> auctionSessions = AUCTION_SESSION_MAP.get(auctionNo);

		if (auctionSessions == null) {
			return;
		}

		auctionSessions.remove(session);

		int remainingSessionCount = auctionSessions.size();

		//해당 경매를 보고 있는 사용자가 아무도 없으면 Map에서 경매번호 자체도 제거한다.
		//빈 Set이 계속 남는 것을 방지한다.
		if (auctionSessions.isEmpty()) {
			AUCTION_SESSION_MAP.remove(auctionNo, auctionSessions);
		}

		System.out.println("[AUCTION WS SESSION REMOVED]" + " A_NO=" + auctionNo + ", SESSION_ID=" + session.getId() + ", SESSION_COUNT=" + remainingSessionCount);
	}

	//테스트 및 로그 확인용. 특정 경매에 현재 몇 개의 WebSocket 연결이 있는지 반환
	public static int getSessionCount(long auctionNo) {

		Set<Session> auctionSessions = AUCTION_SESSION_MAP.get(auctionNo);

		if (auctionSessions == null) {
			return 0;
		}
		return auctionSessions.size();
	}
	
	//특정 경매를 보고 있는 모든 WebSocket Session에 동일한 텍스트 메시지를 전송
	public static void broadcastToAuction(long auctionNo, String message) {

		Set<Session> auctionSessions = AUCTION_SESSION_MAP.get(auctionNo);

		//해당 경매에 접속자가 없으면 전송할 대상이 없으므로 종료
		if (auctionSessions == null || auctionSessions.isEmpty()) {
			System.out.println("[AUCTION WS BROADCAST SKIPPED]" + " A_NO=" + auctionNo + ", REASON=NO_SESSION");
			return;
		}

		System.out.println("[AUCTION WS BROADCAST START]" + " A_NO=" + auctionNo + ", SESSION_COUNT=" + auctionSessions.size() + ", MESSAGE=" + message);

		//현재 경매에 등록된 모든 Session을 순회
		for (Session currentSession : auctionSessions) {
			//이미 닫힌 연결이라면 메시지를 보내지 않고 Session 저장소에서도 제거
			if (!currentSession.isOpen()) {
				removeSession(auctionNo, currentSession);
				continue;
			}

			//비동기로 메시지를 전송한다. 전송 결과가 실패하면 더 이상 정상적인 연결로 볼 수 없으므로 저장소에서 제거
			currentSession.getAsyncRemote().sendText(message, sendResult -> {

						if (!sendResult.isOK()) {
							System.err.println("[AUCTION WS BROADCAST FAILED]" + " A_NO=" + auctionNo + ", SESSION_ID=" + currentSession.getId() + ", MESSAGE=" + sendResult.getException().getMessage());
							removeSession(auctionNo, currentSession);
							return;
						}
						System.out.println("[AUCTION WS BROADCAST SENT]" + " A_NO=" + auctionNo + ", SESSION_ID=" + currentSession.getId());
					}
				);
		}
	}
}